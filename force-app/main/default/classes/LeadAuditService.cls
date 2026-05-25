public with sharing class LeadAuditService {

    // Called from trigger handler — build record without DML, then call bulkLog()
    public static Lead_Audit__c buildStageChangeRecord(Id leadId, String oldStage, String newStage) {
        String msg = 'Stage changed from \'' + safeStr(oldStage) + '\' to \'' + safeStr(newStage) + '\'';
        return buildRecord(leadId, 'Stage Change', msg, oldStage, newStage);
    }

    public static Lead_Audit__c buildFieldUpdateRecord(Id leadId, String fieldLabel, String oldValue, String newValue) {
        String msg = fieldLabel + ' updated from \'' + safeStr(oldValue) + '\' to \'' + safeStr(newValue) + '\'';
        return buildRecord(leadId, 'Field Update', msg, oldValue, newValue);
    }

    public static Lead_Audit__c buildStatusUpdateRecord(Id leadId, String oldStatus, String newStatus) {
        String msg = 'Status changed from \'' + safeStr(oldStatus) + '\' to \'' + safeStr(newStatus) + '\'';
        return buildRecord(leadId, 'Status Update', msg, oldStatus, newStatus);
    }

    public static Lead_Audit__c buildStaleRecord(Id leadId, String stageName) {
        String msg = 'Lead flagged as stale in stage \'' + safeStr(stageName) + '\'. SLA exceeded.';
        return buildRecord(leadId, 'Stale Flagged', msg, null, 'true');
    }

    public static Lead_Audit__c buildStaleClearedRecord(Id leadId) {
        return buildRecord(leadId, 'Stale Cleared', 'Lead stale flag cleared after new activity logged.', 'true', 'false');
    }

    public static Lead_Audit__c buildHealthUpdateRecord(Id leadId, String oldHealth, String newHealth) {
        String msg = 'Lead health changed from \'' + safeStr(oldHealth) + '\' to \'' + safeStr(newHealth) + '\'';
        return buildRecord(leadId, 'Health Updated', msg, oldHealth, newHealth);
    }

    // Bulk insert — use partial success to avoid rollback on single audit failure
    public static void bulkLog(List<Lead_Audit__c> auditRecords) {
        if (auditRecords == null || auditRecords.isEmpty()) return;
        Database.insert(auditRecords, false);
    }

    // Single-record convenience method for service layer calls
    public static void log(Id leadId, String auditType, String message, String oldValue, String newValue) {
        Lead_Audit__c audit = buildRecord(leadId, auditType, message, oldValue, newValue);
        Database.insert(audit, false);
    }

    private static Lead_Audit__c buildRecord(Id leadId, String auditType, String message, String oldValue, String newValue) {
        return new Lead_Audit__c(
            Lead__c = leadId,
            Audit_Type__c = auditType,
            Message__c = message,
            Old_Value__c = String.isNotBlank(oldValue) ? oldValue.abbreviate(255) : null,
            New_Value__c = String.isNotBlank(newValue) ? newValue.abbreviate(255) : null,
            Performed_By__c = UserInfo.getUserId(),
            Performed_On__c = System.now()
        );
    }

    private static String safeStr(String val) {
        return String.isBlank(val) ? '(none)' : val;
    }
}
