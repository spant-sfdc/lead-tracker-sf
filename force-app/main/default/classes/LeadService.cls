/**
 * Core business-logic service for Lead stage management and health computation.
 * Uses LeadSelector for all reads; performs DML with sharing enforced.
 * All methods are bulk-safe — no SOQL or DML inside loops.
 */
public with sharing class LeadService {

    // ── Dependencies ──────────────────────────────────────────────────────────

    private LeadSelector          leadSelector;
    private PipelineStageSelector stageSelector;

    public LeadService() {
        this.leadSelector  = new LeadSelector();
        this.stageSelector = new PipelineStageSelector();
    }

    // ── Stage movement ────────────────────────────────────────────────────────

    /**
     * Moves a single lead to the specified stage key.
     * Returns a MoveResult indicating success or failure with a user-friendly message.
     */
    public LeadTrackerDTO.MoveResult moveLeadToStage(Id leadId, String newStageKey) {
        return bulkMoveLeadsToStage(new List<Id>{ leadId }, newStageKey).get(0);
    }

    /**
     * Bulk-moves a list of leads to the specified stage key.
     * Validates the stage exists in CMT before touching any records.
     * Partial success — failed saves do not roll back successful ones.
     */
    public List<LeadTrackerDTO.MoveResult> bulkMoveLeadsToStage(List<Id> leadIds, String newStageKey) {
        List<LeadTrackerDTO.MoveResult> results = new List<LeadTrackerDTO.MoveResult>();

        if (leadIds == null || leadIds.isEmpty() || String.isBlank(newStageKey)) {
            for (Id lid : (leadIds != null ? leadIds : new List<Id>())) {
                results.add(new LeadTrackerDTO.MoveResult(lid, false, 'Invalid arguments.', null));
            }
            return results;
        }

        // Validate target stage exists
        Pipeline_Stage__mdt targetStage = stageSelector.getStageByKey(newStageKey);
        if (targetStage == null) {
            for (Id lid : leadIds) {
                results.add(new LeadTrackerDTO.MoveResult(lid, false, 'Stage not found: ' + newStageKey, null));
            }
            return results;
        }

        // Fetch leads (one SOQL, outside any loop)
        Set<Id> idSet = new Set<Id>(leadIds);
        List<Lead> leads = leadSelector.getLeadsById(idSet);

        // Build update list and audit list together — no loops with SOQL/DML
        List<Lead>          toUpdate   = new List<Lead>();
        List<Lead_Audit__c> audits     = new List<Lead_Audit__c>();
        List<Integer>       auditIndex = new List<Integer>(); // tracks which toUpdate index maps to which audit

        Map<Id, Lead> leadMap = new Map<Id, Lead>(leads);
        for (Id lid : leadIds) {
            Lead l = leadMap.get(lid);
            if (l == null) {
                results.add(new LeadTrackerDTO.MoveResult(lid, false, 'Lead not found.', null));
                continue;
            }
            String oldStage = l.Current_Stage__c;
            l.Current_Stage__c      = newStageKey;
            l.Last_Activity_Date__c = Date.today();
            toUpdate.add(l);
            audits.add(LeadAuditService.buildStageChangeRecord(lid, oldStage, newStageKey));
            auditIndex.add(toUpdate.size() - 1);
        }

        // Single DML — sharing enforced by class declaration
        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(toUpdate, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Lead l = toUpdate[i];
                if (sr.isSuccess()) {
                    results.add(new LeadTrackerDTO.MoveResult(
                        l.Id, true, 'Moved to ' + targetStage.Stage_Label__c, newStageKey));
                } else {
                    String errMsg = sr.getErrors()[0].getMessage();
                    results.add(new LeadTrackerDTO.MoveResult(l.Id, false, errMsg, null));
                    audits.set(i, null); // nullify audit for the failed save
                }
            }
        }

        // Purge null entries before logging
        List<Lead_Audit__c> validAudits = new List<Lead_Audit__c>();
        for (Lead_Audit__c a : audits) {
            if (a != null) {
                validAudits.add(a);
            }
        }
        LeadAuditService.bulkLog(validAudits);

        return results;
    }

    // ── Engagement score ──────────────────────────────────────────────────────

    /**
     * Updates the Engagement_Score__c for a single lead and recalculates Lead_Health__c.
     * Score must be between 0 and 100.
     */
    public void updateEngagementScore(Id leadId, Integer score) {
        if (score == null || score < 0 || score > 100) {
            throw new LeadTrackerException('Engagement score must be between 0 and 100.');
        }
        List<Lead> leads = leadSelector.getLeadsById(new Set<Id>{ leadId });
        if (leads.isEmpty()) {
            throw new LeadTrackerException('Lead not found: ' + leadId);
        }
        Lead l = leads[0];
        String oldScore  = String.valueOf(l.Engagement_Score__c);
        String oldHealth = l.Lead_Health__c;

        l.Engagement_Score__c = score;
        l.Lead_Health__c      = computeHealth(score, l.Is_Stale__c);
        update as user l;

        List<Lead_Audit__c> audits = new List<Lead_Audit__c>();
        audits.add(LeadAuditService.buildFieldUpdateRecord(
            leadId, 'Engagement_Score__c', oldScore, String.valueOf(score)));
        if (l.Lead_Health__c != oldHealth) {
            audits.add(LeadAuditService.buildHealthUpdateRecord(leadId, oldHealth, l.Lead_Health__c));
        }
        LeadAuditService.bulkLog(audits);
    }

    // ── Stale flag management ─────────────────────────────────────────────────

    /**
     * Marks a set of leads as stale. Intended for use by the stale detection batch.
     * Recomputes Lead_Health__c to Critical for each stale lead.
     */
    public void markLeadsStale(List<Lead> candidates) {
        if (candidates == null || candidates.isEmpty()) {
            return;
        }
        List<Lead>          toUpdate = new List<Lead>();
        List<Lead_Audit__c> audits   = new List<Lead_Audit__c>();

        for (Lead l : candidates) {
            if (!l.Is_Stale__c) {
                l.Is_Stale__c    = true;
                l.Lead_Health__c = 'Critical';
                toUpdate.add(l);
                audits.add(LeadAuditService.buildStaleRecord(l.Id));
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
            LeadAuditService.bulkLog(audits);
        }
    }

    // ── Health computation ────────────────────────────────────────────────────

    /**
     * Derives Lead_Health__c picklist value from engagement score and stale flag.
     *   Stale          → Critical
     *   score >= 70    → Healthy
     *   score >= 40    → At Risk
     *   otherwise      → Critical
     */
    public static String computeHealth(Integer score, Boolean isStale) {
        if (isStale == true) {
            return 'Critical';
        }
        Integer s = (score == null ? 0 : score);
        if (s >= 70) { return 'Healthy'; }
        if (s >= 40) { return 'At Risk'; }
        return 'Critical';
    }

    // ── Config retrieval ──────────────────────────────────────────────────────

    /**
     * Returns the default pipeline type from Application_Config__mdt.
     * Falls back to 'Nonprofit' if no config record exists.
     */
    public String getDefaultPipelineType() {
        Application_Config__mdt cfg = stageSelector.getDefaultAppConfig();
        if (cfg != null && String.isNotBlank(cfg.Default_Pipeline__c)) {
            return cfg.Default_Pipeline__c;
        }
        return 'Nonprofit';
    }
}
