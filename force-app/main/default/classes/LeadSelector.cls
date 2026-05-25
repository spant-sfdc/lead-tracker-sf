/**
 * Enterprise selector for the Lead SObject.
 * All queries run WITH USER_MODE to enforce FLS and sharing automatically.
 * No SOQL is executed inside loops — callers pass filter sets.
 */
public with sharing class LeadSelector {

    // ── Active board leads ────────────────────────────────────────────────────

    /**
     * Returns all non-converted leads for the pipeline board.
     * Ordered by engagement score descending so highest-priority leads appear first.
     */
    public List<Lead> getBoardLeads() {
        return [
            SELECT Id, FirstName, LastName, Name, Company, Email, Phone,
                   Status, OwnerId, Owner.Name, IsConverted, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Closed_Reason__c, Is_Stale__c, Primary_Stakeholder__c,
                   Organization_Size__c, Current_CRM__c, Funding_Model__c
            FROM   Lead
            WHERE  IsConverted = false
            WITH   USER_MODE
            ORDER  BY Engagement_Score__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT  2000
        ];
    }

    /**
     * Returns non-converted leads filtered to a specific pipeline type.
     */
    public List<Lead> getBoardLeadsByPipelineType(String pipelineType) {
        if (String.isBlank(pipelineType)) {
            return getBoardLeads();
        }
        return [
            SELECT Id, FirstName, LastName, Name, Company, Email, Phone,
                   Status, OwnerId, Owner.Name, IsConverted, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Closed_Reason__c, Is_Stale__c, Primary_Stakeholder__c,
                   Organization_Size__c, Current_CRM__c, Funding_Model__c
            FROM   Lead
            WHERE  IsConverted = false
            AND    Pipeline_Type__c = :pipelineType
            WITH   USER_MODE
            ORDER  BY Engagement_Score__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT  2000
        ];
    }

    // ── By ID ─────────────────────────────────────────────────────────────────

    /** Fetches a set of leads by their Ids — used by service layer for DML operations. */
    public List<Lead> getLeadsById(Set<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) {
            return new List<Lead>();
        }
        return [
            SELECT Id, FirstName, LastName, Name, Company, Email, Phone,
                   Status, OwnerId, Owner.Name, IsConverted, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Closed_Reason__c, Is_Stale__c, Primary_Stakeholder__c,
                   Organization_Size__c, Current_CRM__c, Funding_Model__c
            FROM   Lead
            WHERE  Id IN :leadIds
            WITH   USER_MODE
        ];
    }

    // ── Stale detection ───────────────────────────────────────────────────────

    /**
     * Returns leads whose Last_Activity_Date__c is older than slaDays and are not already
     * marked stale. Called by the stale detection batch/scheduler.
     */
    public List<Lead> getStaleLeadCandidates(Integer slaDays) {
        Date cutoff = Date.today().addDays(-slaDays);
        return [
            SELECT Id, Name, Current_Stage__c, Pipeline_Type__c,
                   Last_Activity_Date__c, Is_Stale__c, Lead_Health__c,
                   Engagement_Score__c
            FROM   Lead
            WHERE  IsConverted = false
            AND    Is_Stale__c = false
            AND    Last_Activity_Date__c <= :cutoff
            WITH   USER_MODE
            ORDER  BY Last_Activity_Date__c ASC
            LIMIT  200
        ];
    }

    // ── Stage-based lookups ───────────────────────────────────────────────────

    /** Returns non-converted leads currently in a specific stage. */
    public List<Lead> getLeadsByStage(String stageKey) {
        if (String.isBlank(stageKey)) {
            return new List<Lead>();
        }
        return [
            SELECT Id, Name, Company, Current_Stage__c, Pipeline_Type__c,
                   Lead_Health__c, Engagement_Score__c, Is_Stale__c
            FROM   Lead
            WHERE  IsConverted = false
            AND    Current_Stage__c = :stageKey
            WITH   USER_MODE
            ORDER  BY Engagement_Score__c DESC NULLS LAST
            LIMIT  500
        ];
    }

    /** Returns non-converted leads in any of the provided stage keys. */
    public List<Lead> getLeadsByStages(Set<String> stageKeys) {
        if (stageKeys == null || stageKeys.isEmpty()) {
            return new List<Lead>();
        }
        return [
            SELECT Id, FirstName, LastName, Name, Company, Email, Phone,
                   Status, OwnerId, Owner.Name, IsConverted, LastModifiedDate,
                   Current_Stage__c, Pipeline_Type__c, Last_Activity_Date__c,
                   Next_Follow_Up__c, Lead_Health__c, Engagement_Score__c,
                   Closed_Reason__c, Is_Stale__c, Primary_Stakeholder__c,
                   Organization_Size__c, Current_CRM__c, Funding_Model__c
            FROM   Lead
            WHERE  IsConverted = false
            AND    Current_Stage__c IN :stageKeys
            WITH   USER_MODE
            ORDER  BY Engagement_Score__c DESC NULLS LAST
            LIMIT  2000
        ];
    }

    // ── Follow-up ─────────────────────────────────────────────────────────────

    /** Returns leads whose Next_Follow_Up__c is today or earlier and are not converted. */
    public List<Lead> getLeadsDueForFollowUp() {
        Date today = Date.today();
        return [
            SELECT Id, Name, Company, Email, Phone, Current_Stage__c,
                   Next_Follow_Up__c, Lead_Health__c, OwnerId, Owner.Name
            FROM   Lead
            WHERE  IsConverted = false
            AND    Next_Follow_Up__c <= :today
            WITH   USER_MODE
            ORDER  BY Next_Follow_Up__c ASC
            LIMIT  500
        ];
    }
}
