public with sharing class LeadTrackerSelector {

    public static List<Lead> getAllActiveLeads() {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate
            FROM Lead
            WHERE IsConverted = false
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 2000
        ];
    }

    public static List<Lead> getLeadsByStatus(Set<String> statuses) {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate
            FROM Lead
            WHERE Status IN :statuses
            AND IsConverted = false
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
        ];
    }

    public static List<Lead> getLeadsById(Set<Id> leadIds) {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate
            FROM Lead
            WHERE Id IN :leadIds
            WITH USER_MODE
        ];
    }

    public static List<LeadTracker_Pipeline_Stage__mdt> getActivePipelineStages() {
        return [
            SELECT Id, DeveloperName, MasterLabel, Stage_Name__c, Sort_Order__c,
                   Icon_Name__c, Color_Hex__c, Is_Closed__c, Is_Won__c,
                   Is_Active__c, Description__c
            FROM LeadTracker_Pipeline_Stage__mdt
            WHERE Is_Active__c = true
            ORDER BY Sort_Order__c ASC
        ];
    }

    public static LeadTracker_App_Config__mdt getAppConfig() {
        List<LeadTracker_App_Config__mdt> configs = [
            SELECT Id, DeveloperName, MasterLabel, App_Name__c, Primary_Color__c,
                   Secondary_Color__c, Logo_Static_Resource__c, Support_Email__c,
                   Default_Tab__c
            FROM LeadTracker_App_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return configs.isEmpty() ? null : configs[0];
    }
}
