public with sharing class LeadTrackerService {

    public static Map<String, List<Lead>> getLeadsByPipelineStage() {
        Application_Config__mdt config = LeadTrackerSelector.getApplicationConfig();
        String pipelineType = config != null ? config.Default_Pipeline__c : null;

        List<Pipeline_Stage__mdt> stages = String.isNotBlank(pipelineType)
            ? LeadTrackerSelector.getPipelineStagesByType(pipelineType)
            : LeadTrackerSelector.getAllPipelineStages();

        List<Lead> allLeads = String.isNotBlank(pipelineType)
            ? LeadTrackerSelector.getLeadsByPipelineType(pipelineType)
            : LeadTrackerSelector.getAllActiveLeads();

        Map<String, List<Lead>> pipelineMap = new Map<String, List<Lead>>();
        for (Pipeline_Stage__mdt stage : stages) {
            pipelineMap.put(stage.Stage_Key__c, new List<Lead>());
        }

        for (Lead l : allLeads) {
            String key = String.isNotBlank(l.Current_Stage__c) ? l.Current_Stage__c : l.Status;
            if (pipelineMap.containsKey(key)) {
                pipelineMap.get(key).add(l);
            }
        }

        return pipelineMap;
    }

    public static void updateLeadStatus(Id leadId, String newStatus) {
        if (String.isBlank(newStatus)) {
            throw new LeadTrackerException('Status cannot be blank.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>{ leadId });
        if (leads.isEmpty()) {
            throw new LeadTrackerException('Lead not found: ' + leadId);
        }

        leads[0].Status = newStatus;
        leads[0].Current_Stage__c = newStatus;
        update as user leads;
    }

    public static void moveLeadToStage(Id leadId, String stageKey) {
        if (String.isBlank(stageKey)) {
            throw new LeadTrackerException('Stage key cannot be blank.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>{ leadId });
        if (leads.isEmpty()) {
            throw new LeadTrackerException('Lead not found: ' + leadId);
        }

        leads[0].Current_Stage__c = stageKey;
        update as user leads;
    }

    public static void bulkUpdateLeadStatus(List<Id> leadIds, String newStatus) {
        if (String.isBlank(newStatus) || leadIds == null || leadIds.isEmpty()) {
            throw new LeadTrackerException('Invalid parameters for bulk status update.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>(leadIds));
        for (Lead l : leads) {
            l.Status = newStatus;
            l.Current_Stage__c = newStatus;
        }

        if (!leads.isEmpty()) {
            update as user leads;
        }
    }

    public static void bulkMoveLeadsToStage(List<Id> leadIds, String stageKey) {
        if (String.isBlank(stageKey) || leadIds == null || leadIds.isEmpty()) {
            throw new LeadTrackerException('Invalid parameters for bulk stage move.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>(leadIds));
        for (Lead l : leads) {
            l.Current_Stage__c = stageKey;
        }

        if (!leads.isEmpty()) {
            update as user leads;
        }
    }

    public static void updateEngagementScore(Id leadId, Integer score) {
        if (score < 0 || score > 100) {
            throw new LeadTrackerException('Engagement score must be between 0 and 100.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>{ leadId });
        if (leads.isEmpty()) {
            throw new LeadTrackerException('Lead not found: ' + leadId);
        }

        Lead l = leads[0];
        Integer oldScore = l.Engagement_Score__c != null ? l.Engagement_Score__c.intValue() : null;
        l.Engagement_Score__c = score;
        l.Lead_Health__c = computeHealth(score, l.Is_Stale__c);
        update as user new List<Lead>{ l };

        LeadAuditService.log(
            leadId, 'Score Update',
            'Engagement score updated to ' + score,
            oldScore != null ? String.valueOf(oldScore) : null,
            String.valueOf(score)
        );
    }

    private static String computeHealth(Integer score, Boolean isStale) {
        if (Boolean.valueOf(isStale)) return 'Critical';
        if (score == null) return 'Healthy';
        if (score >= 70) return 'Healthy';
        if (score >= 40) return 'At Risk';
        return 'Critical';
    }
}
