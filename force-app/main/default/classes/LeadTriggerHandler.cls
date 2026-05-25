/**
 * Trigger handler for the Lead object.
 * Extends TriggerHandler base class — recursion prevention and bypass control inherited.
 * All business rules are bulk-safe; no SOQL or DML inside loops.
 */
public with sharing class LeadTriggerHandler extends TriggerHandler {

    // ── Before Insert ─────────────────────────────────────────────────────────

    protected override void beforeInsert() {
        Application_Config__mdt cfg = new PipelineStageSelector().getDefaultAppConfig();
        String defaultPipeline = (cfg != null && String.isNotBlank(cfg.Default_Pipeline__c))
                                 ? cfg.Default_Pipeline__c : null;

        for (Lead l : (List<Lead>) Trigger.new) {
            if (String.isBlank(l.Current_Stage__c) && String.isNotBlank(l.Status)) {
                l.Current_Stage__c = l.Status;
            }
            if (String.isBlank(l.Pipeline_Type__c) && String.isNotBlank(defaultPipeline)) {
                l.Pipeline_Type__c = defaultPipeline;
            }
        }
    }

    // ── Before Update ─────────────────────────────────────────────────────────

    protected override void beforeUpdate() {
        Map<Id, Lead> oldMap = (Map<Id, Lead>) Trigger.oldMap;

        for (Lead l : (List<Lead>) Trigger.new) {
            Lead old = oldMap.get(l.Id);
            if (old == null) { continue; }

            // Sync Current_Stage__c when Status is changed via standard UI (not pipeline board)
            if (l.Status != old.Status && l.Current_Stage__c == old.Current_Stage__c) {
                l.Current_Stage__c = l.Status;
            }

            // Clear stale flag when activity date is refreshed
            if (l.Last_Activity_Date__c != old.Last_Activity_Date__c
                    && l.Last_Activity_Date__c != null
                    && l.Is_Stale__c == true) {
                l.Is_Stale__c = false;
            }
        }
    }

    // ── After Insert ──────────────────────────────────────────────────────────

    protected override void afterInsert() {
        List<Lead_Audit__c> audits = new List<Lead_Audit__c>();
        for (Lead l : (List<Lead>) Trigger.new) {
            audits.add(LeadAuditService.buildCreationRecord(l.Id, l.Current_Stage__c));
        }
        LeadAuditService.bulkLog(audits);
    }

    // ── After Update ──────────────────────────────────────────────────────────

    protected override void afterUpdate() {
        Map<Id, Lead> oldMap = (Map<Id, Lead>) Trigger.oldMap;
        List<Lead_Audit__c> audits = new List<Lead_Audit__c>();

        for (Lead l : (List<Lead>) Trigger.new) {
            Lead old = oldMap.get(l.Id);
            if (old == null) { continue; }

            if (l.Current_Stage__c != old.Current_Stage__c) {
                audits.add(LeadAuditService.buildStageChangeRecord(
                    l.Id, old.Current_Stage__c, l.Current_Stage__c));
            }
            if (l.Status != old.Status) {
                audits.add(LeadAuditService.buildStatusUpdateRecord(
                    l.Id, old.Status, l.Status));
            }
            if (l.Lead_Health__c != old.Lead_Health__c) {
                audits.add(LeadAuditService.buildHealthUpdateRecord(
                    l.Id, old.Lead_Health__c, l.Lead_Health__c));
            }
            if (l.OwnerId != old.OwnerId) {
                audits.add(LeadAuditService.buildOwnerChangeRecord(
                    l.Id, String.valueOf(old.OwnerId), String.valueOf(l.OwnerId)));
            }
            if (l.Is_Stale__c != old.Is_Stale__c) {
                if (l.Is_Stale__c == true) {
                    audits.add(LeadAuditService.buildStaleRecord(l.Id));
                } else {
                    audits.add(LeadAuditService.buildStaleClearedRecord(l.Id));
                }
            }
        }

        LeadAuditService.bulkLog(audits);
    }
}
