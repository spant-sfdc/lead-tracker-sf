/**
 * Selector for CMT-backed pipeline configuration:
 *   - Pipeline_Stage__mdt  — stage definitions per pipeline type
 *   - Application_Config__mdt — global app settings
 *
 * Custom Metadata records are not subject to sharing rules, so no WITH USER_MODE.
 */
public with sharing class PipelineStageSelector {

    // ── Pipeline_Stage__mdt ───────────────────────────────────────────────────

    /** Returns all pipeline stages ordered by sequence ascending. */
    public List<Pipeline_Stage__mdt> getAllActiveStages() {
        return [
            SELECT DeveloperName, MasterLabel,
                   Stage_Key__c, Stage_Label__c, Sequence__c,
                   Color__c, Icon__c, Is_Closed__c, Is_Won__c,
                   Requires_Activity__c, SLA_Days__c,
                   Pipeline_Type__c, Card_Badge_Config__c
            FROM   Pipeline_Stage__mdt
            ORDER  BY Sequence__c ASC
        ];
    }

    /** Returns stages for a specific pipeline type, ordered by sequence. */
    public List<Pipeline_Stage__mdt> getActiveStagesByPipelineType(String pipelineType) {
        if (String.isBlank(pipelineType)) {
            return getAllActiveStages();
        }
        return [
            SELECT DeveloperName, MasterLabel,
                   Stage_Key__c, Stage_Label__c, Sequence__c,
                   Color__c, Icon__c, Is_Closed__c, Is_Won__c,
                   Requires_Activity__c, SLA_Days__c,
                   Pipeline_Type__c, Card_Badge_Config__c
            FROM   Pipeline_Stage__mdt
            WHERE  Pipeline_Type__c = :pipelineType
            ORDER  BY Sequence__c ASC
        ];
    }

    /**
     * Returns the stage record that corresponds to a given Stage_Key__c value.
     * Returns null if no match is found — callers must guard against null.
     */
    public Pipeline_Stage__mdt getStageByKey(String stageKey) {
        if (String.isBlank(stageKey)) {
            return null;
        }
        List<Pipeline_Stage__mdt> results = [
            SELECT DeveloperName, MasterLabel,
                   Stage_Key__c, Stage_Label__c, Sequence__c,
                   Color__c, Icon__c, Is_Closed__c, Is_Won__c,
                   Requires_Activity__c, SLA_Days__c,
                   Pipeline_Type__c, Card_Badge_Config__c
            FROM   Pipeline_Stage__mdt
            WHERE  Stage_Key__c = :stageKey
            LIMIT  1
        ];
        return results.isEmpty() ? null : results[0];
    }

    /**
     * Returns a map of Stage_Key__c → Pipeline_Stage__mdt for all stages.
     * Used by service layer to avoid SOQL inside loops.
     */
    public Map<String, Pipeline_Stage__mdt> getActiveStageMapByKey() {
        Map<String, Pipeline_Stage__mdt> stageMap = new Map<String, Pipeline_Stage__mdt>();
        for (Pipeline_Stage__mdt stage : getAllActiveStages()) {
            if (String.isNotBlank(stage.Stage_Key__c)) {
                stageMap.put(stage.Stage_Key__c, stage);
            }
        }
        return stageMap;
    }

    /**
     * Returns a map of Stage_Key__c → Pipeline_Stage__mdt for a given pipeline type.
     */
    public Map<String, Pipeline_Stage__mdt> getStageMapByPipelineType(String pipelineType) {
        Map<String, Pipeline_Stage__mdt> stageMap = new Map<String, Pipeline_Stage__mdt>();
        for (Pipeline_Stage__mdt stage : getActiveStagesByPipelineType(pipelineType)) {
            if (String.isNotBlank(stage.Stage_Key__c)) {
                stageMap.put(stage.Stage_Key__c, stage);
            }
        }
        return stageMap;
    }

    // ── Application_Config__mdt ───────────────────────────────────────────────

    /**
     * Returns the Default Application_Config__mdt record.
     * Returns null if no Default record exists — callers must guard.
     */
    public Application_Config__mdt getDefaultAppConfig() {
        List<Application_Config__mdt> results = [
            SELECT DeveloperName, MasterLabel,
                   Company_Name__c, Theme_Color__c, Default_Pipeline__c,
                   Card_Density__c, Auto_Refresh_Interval__c,
                   Dashboard_Refresh_Minutes__c, Empty_State_Message__c
            FROM   Application_Config__mdt
            WHERE  DeveloperName = 'Default'
            LIMIT  1
        ];
        return results.isEmpty() ? null : results[0];
    }
}
