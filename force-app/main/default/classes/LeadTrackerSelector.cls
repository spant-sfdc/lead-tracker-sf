public with sharing class LeadTrackerSelector {

    public static List<Lead> getAllActiveLeads() {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Is_Stale__c, Primary_Stakeholder__c, Organization_Size__c,
                   Current_CRM__c, Funding_Model__c, Closed_Reason__c
            FROM Lead
            WHERE IsConverted = false
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 2000
        ];
    }

    public static List<Lead> getLeadsByPipelineType(String pipelineType) {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Is_Stale__c, Organization_Size__c, Funding_Model__c
            FROM Lead
            WHERE Pipeline_Type__c = :pipelineType
            AND IsConverted = false
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 2000
        ];
    }

    public static List<Lead> getLeadsByStatus(Set<String> statuses) {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Status, LeadSource,
                   Email, Phone, Rating, Industry, AnnualRevenue,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Lead_Health__c,
                   Engagement_Score__c, Is_Stale__c
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
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Is_Stale__c, Primary_Stakeholder__c, Organization_Size__c,
                   Current_CRM__c, Funding_Model__c, Closed_Reason__c
            FROM Lead
            WHERE Id IN :leadIds
            WITH USER_MODE
        ];
    }

    public static List<Lead> getStaleLeadCandidates(String pipelineType) {
        return [
            SELECT Id, Name, Current_Stage__c, Pipeline_Type__c,
                   Last_Activity_Date__c, Is_Stale__c, Lead_Health__c, OwnerId
            FROM Lead
            WHERE Pipeline_Type__c = :pipelineType
            AND IsConverted = false
            AND Is_Stale__c = false
            WITH USER_MODE
            ORDER BY Last_Activity_Date__c ASC NULLS FIRST
            LIMIT 1000
        ];
    }

    // === Phase 1 CMT selectors (preserved for backward compatibility) ===

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

    // === Phase 2 CMT selectors ===

    public static List<Pipeline_Stage__mdt> getPipelineStagesByType(String pipelineType) {
        return [
            SELECT Id, DeveloperName, MasterLabel, Stage_Key__c, Stage_Label__c,
                   Sequence__c, Color__c, Icon__c, Is_Closed__c, Is_Won__c,
                   Requires_Activity__c, SLA_Days__c, Pipeline_Type__c, Card_Badge_Config__c
            FROM Pipeline_Stage__mdt
            WHERE Pipeline_Type__c = :pipelineType
            ORDER BY Sequence__c ASC
        ];
    }

    public static List<Pipeline_Stage__mdt> getAllPipelineStages() {
        return [
            SELECT Id, DeveloperName, MasterLabel, Stage_Key__c, Stage_Label__c,
                   Sequence__c, Color__c, Icon__c, Is_Closed__c, Is_Won__c,
                   Requires_Activity__c, SLA_Days__c, Pipeline_Type__c, Card_Badge_Config__c
            FROM Pipeline_Stage__mdt
            ORDER BY Pipeline_Type__c ASC, Sequence__c ASC
        ];
    }

    public static Application_Config__mdt getApplicationConfig() {
        List<Application_Config__mdt> configs = [
            SELECT Id, DeveloperName, MasterLabel, Company_Name__c, Theme_Color__c,
                   Default_Pipeline__c, Card_Density__c, Auto_Refresh_Interval__c,
                   Dashboard_Refresh_Minutes__c, Empty_State_Message__c
            FROM Application_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return configs.isEmpty() ? null : configs[0];
    }
}
