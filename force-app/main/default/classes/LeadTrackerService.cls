public with sharing class LeadTrackerService {

    public static Map<String, List<Lead>> getLeadsByPipelineStage() {
        List<LeadTracker_Pipeline_Stage__mdt> stages = LeadTrackerSelector.getActivePipelineStages();
        List<Lead> allLeads = LeadTrackerSelector.getAllActiveLeads();

        Map<String, List<Lead>> pipelineMap = new Map<String, List<Lead>>();
        for (LeadTracker_Pipeline_Stage__mdt stage : stages) {
            pipelineMap.put(stage.Stage_Name__c, new List<Lead>());
        }

        for (Lead l : allLeads) {
            if (pipelineMap.containsKey(l.Status)) {
                pipelineMap.get(l.Status).add(l);
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
        update as user leads;
    }

    public static void bulkUpdateLeadStatus(List<Id> leadIds, String newStatus) {
        if (String.isBlank(newStatus) || leadIds == null || leadIds.isEmpty()) {
            throw new LeadTrackerException('Invalid parameters for bulk status update.');
        }

        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>(leadIds));
        for (Lead l : leads) {
            l.Status = newStatus;
        }

        if (!leads.isEmpty()) {
            update as user leads;
        }
    }
}
