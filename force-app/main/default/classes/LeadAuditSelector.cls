public with sharing class LeadAuditSelector {

    public static List<Lead_Audit__c> getAuditsByLeadId(Id leadId) {
        return [
            SELECT Id, Name, Lead__c, Audit_Type__c, Message__c,
                   Old_Value__c, New_Value__c,
                   Performed_By__c, Performed_By__r.Name,
                   Performed_On__c
            FROM Lead_Audit__c
            WHERE Lead__c = :leadId
            WITH USER_MODE
            ORDER BY Performed_On__c DESC
            LIMIT 500
        ];
    }

    public static List<Lead_Audit__c> getAuditsByLeadIds(Set<Id> leadIds) {
        return [
            SELECT Id, Name, Lead__c, Audit_Type__c, Message__c,
                   Old_Value__c, New_Value__c,
                   Performed_By__c, Performed_By__r.Name,
                   Performed_On__c
            FROM Lead_Audit__c
            WHERE Lead__c IN :leadIds
            WITH USER_MODE
            ORDER BY Performed_On__c DESC
        ];
    }

    public static List<Lead_Audit__c> getAuditsByType(String auditType, Integer maxRecords) {
        return [
            SELECT Id, Name, Lead__c, Lead__r.Name, Audit_Type__c, Message__c,
                   Old_Value__c, New_Value__c,
                   Performed_By__r.Name, Performed_On__c
            FROM Lead_Audit__c
            WHERE Audit_Type__c = :auditType
            WITH USER_MODE
            ORDER BY Performed_On__c DESC
            LIMIT :maxRecords
        ];
    }

    public static List<Lead_Audit__c> getRecentAudits(Integer maxRecords) {
        return [
            SELECT Id, Name, Lead__c, Lead__r.Name, Audit_Type__c, Message__c,
                   Old_Value__c, New_Value__c,
                   Performed_By__r.Name, Performed_On__c
            FROM Lead_Audit__c
            WITH USER_MODE
            ORDER BY Performed_On__c DESC
            LIMIT :maxRecords
        ];
    }

    public static List<AggregateResult> getStageChangeSummary() {
        return [
            SELECT New_Value__c stage, COUNT(Id) total
            FROM Lead_Audit__c
            WHERE Audit_Type__c = 'Stage Change'
            WITH USER_MODE
            GROUP BY New_Value__c
            ORDER BY COUNT(Id) DESC
        ];
    }
}
