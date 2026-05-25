/**
 * Append-only audit logging service for Lead Tracker.
 * Builds Lead_Audit__c records and persists them with partial-success DML.
 * Also provides timeline retrieval for the lead detail panel.
 *
 * Instance-based API — inject via constructor in service/handler classes.
 * Static builder signatures preserved for backward compatibility with LeadTriggerHandler.
 */
public with sharing class LeadAuditService {

    // ── Constants ─────────────────────────────────────────────────────────────

    private static final Integer MAX_VALUE_LENGTH = 255;

    // ── Static builder methods (backward-compat + trigger handler use) ────────

    public static Lead_Audit__c buildStageChangeRecord(Id leadId, String fromStage, String toStage) {
        String msg = 'Stage moved from \'' + safeStr(fromStage) + '\' to \'' + safeStr(toStage) + '\'';
        return buildRecord(leadId, 'Stage Change', msg, fromStage, toStage);
    }

    public static Lead_Audit__c buildFieldUpdateRecord(Id leadId, String fieldLabel,
                                                        String oldVal, String newVal) {
        String msg = fieldLabel + ' updated from \'' + safeStr(oldVal) + '\' to \'' + safeStr(newVal) + '\'';
        return buildRecord(leadId, 'Field Update', msg, oldVal, newVal);
    }

    public static Lead_Audit__c buildStatusUpdateRecord(Id leadId, String oldStatus, String newStatus) {
        String msg = 'Status changed from \'' + safeStr(oldStatus) + '\' to \'' + safeStr(newStatus) + '\'';
        return buildRecord(leadId, 'Status Update', msg, oldStatus, newStatus);
    }

    public static Lead_Audit__c buildStaleRecord(Id leadId) {
        return buildRecord(leadId, 'Stale Flagged',
            'Lead marked as stale due to inactivity', 'false', 'true');
    }

    public static Lead_Audit__c buildStaleClearedRecord(Id leadId) {
        return buildRecord(leadId, 'Stale Cleared',
            'Stale flag cleared after activity recorded', 'true', 'false');
    }

    public static Lead_Audit__c buildHealthUpdateRecord(Id leadId, String oldHealth, String newHealth) {
        String msg = 'Lead health changed from \'' + safeStr(oldHealth) + '\' to \'' + safeStr(newHealth) + '\'';
        return buildRecord(leadId, 'Health Update', msg, oldHealth, newHealth);
    }

    public static Lead_Audit__c buildOwnerChangeRecord(Id leadId, String oldOwnerId, String newOwnerId) {
        return buildRecord(leadId, 'Owner Change', 'Lead owner reassigned', oldOwnerId, newOwnerId);
    }

    public static Lead_Audit__c buildCreationRecord(Id leadId, String initialStage) {
        return buildRecord(leadId, 'Lead Created',
            'Lead entered pipeline at stage: ' + safeStr(initialStage), null, initialStage);
    }

    // ── Persistence ───────────────────────────────────────────────────────────

    /**
     * Persists a list of audit records using partial-success DML.
     * Failures are intentionally swallowed — audits must never break the calling transaction.
     */
    public static void bulkLog(List<Lead_Audit__c> audits) {
        if (audits == null || audits.isEmpty()) {
            return;
        }
        Database.insert(audits, false);
    }

    /** Convenience — logs a single custom audit entry. */
    public static void log(Id leadId, String auditType, String message,
                           String oldValue, String newValue) {
        Database.insert(buildRecord(leadId, auditType, message, oldValue, newValue), false);
    }

    // ── Timeline retrieval ────────────────────────────────────────────────────

    /**
     * Returns audit entries for a single lead, newest first.
     * Returns AuditEntry DTOs so LWC wires serialize correctly.
     */
    public static List<LeadTrackerDTO.AuditEntry> getTimeline(Id leadId) {
        if (leadId == null) {
            return new List<LeadTrackerDTO.AuditEntry>();
        }
        List<Lead_Audit__c> records = [
            SELECT Id, Audit_Type__c, Message__c, Old_Value__c,
                   New_Value__c, Performed_By__c, Performed_On__c
            FROM   Lead_Audit__c
            WHERE  Lead__c = :leadId
            WITH   USER_MODE
            ORDER  BY Performed_On__c DESC
            LIMIT  200
        ];
        return toAuditEntries(records);
    }

    /**
     * Returns recent audit entries across all leads for a global activity feed.
     */
    public static List<LeadTrackerDTO.AuditEntry> getRecentActivity(Integer maxRecords) {
        Integer lim = (maxRecords != null && maxRecords > 0 && maxRecords <= 500) ? maxRecords : 50;
        List<Lead_Audit__c> records = [
            SELECT Id, Audit_Type__c, Message__c, Old_Value__c,
                   New_Value__c, Performed_By__c, Performed_On__c, Lead__c
            FROM   Lead_Audit__c
            WITH   USER_MODE
            ORDER  BY Performed_On__c DESC
            LIMIT  :lim
        ];
        return toAuditEntries(records);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static Lead_Audit__c buildRecord(Id leadId, String auditType, String message,
                                              String oldValue, String newValue) {
        Lead_Audit__c a = new Lead_Audit__c();
        a.Lead__c         = leadId;
        a.Audit_Type__c   = auditType;
        a.Message__c      = message  != null ? message.abbreviate(MAX_VALUE_LENGTH)  : null;
        a.Old_Value__c    = oldValue != null ? oldValue.abbreviate(MAX_VALUE_LENGTH) : null;
        a.New_Value__c    = newValue != null ? newValue.abbreviate(MAX_VALUE_LENGTH) : null;
        a.Performed_By__c = UserInfo.getUserId();
        a.Performed_On__c = System.now();
        return a;
    }

    private static List<LeadTrackerDTO.AuditEntry> toAuditEntries(List<Lead_Audit__c> records) {
        List<LeadTrackerDTO.AuditEntry> entries = new List<LeadTrackerDTO.AuditEntry>();
        for (Lead_Audit__c a : records) {
            LeadTrackerDTO.AuditEntry e = new LeadTrackerDTO.AuditEntry();
            e.auditId     = a.Id;
            e.auditType   = a.Audit_Type__c;
            e.message     = a.Message__c;
            e.oldValue    = a.Old_Value__c;
            e.newValue    = a.New_Value__c;
            e.performedBy = a.Performed_By__c;
            e.performedOn = a.Performed_On__c != null ? String.valueOf(a.Performed_On__c) : null;
            entries.add(e);
        }
        return entries;
    }

    private static String safeStr(String val) {
        return String.isBlank(val) ? '(none)' : val;
    }
}
