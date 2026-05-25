public with sharing class LeadTrackerController {

    @AuraEnabled(cacheable=true)
    public static List<LeadTracker_Pipeline_Stage__mdt> getPipelineStages() {
        try {
            return LeadTrackerSelector.getActivePipelineStages();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static LeadTracker_App_Config__mdt getAppConfig() {
        try {
            return LeadTrackerSelector.getAppConfig();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Lead> getBoardLeads() {
        try {
            return LeadTrackerSelector.getAllActiveLeads();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void moveLead(Id leadId, String targetStatus) {
        try {
            LeadTrackerService.updateLeadStatus(leadId, targetStatus);
        } catch (LeadTrackerException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void bulkMoveLeads(List<Id> leadIds, String targetStatus) {
        try {
            LeadTrackerService.bulkUpdateLeadStatus(leadIds, targetStatus);
        } catch (LeadTrackerException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
}
