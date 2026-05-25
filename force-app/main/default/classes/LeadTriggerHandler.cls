public with sharing class LeadTriggerHandler {

    public static void handle(
        List<Lead> newLeads,
        List<Lead> oldLeads,
        Map<Id, Lead> newLeadMap,
        Map<Id, Lead> oldLeadMap,
        System.TriggerOperation operationType
    ) {
        switch on operationType {
            when BEFORE_INSERT {
                onBeforeInsert(newLeads);
            }
            when BEFORE_UPDATE {
                onBeforeUpdate(newLeads, oldLeadMap);
            }
            when BEFORE_DELETE {
                onBeforeDelete(oldLeads);
            }
            when AFTER_INSERT {
                onAfterInsert(newLeads, newLeadMap);
            }
            when AFTER_UPDATE {
                onAfterUpdate(newLeads, oldLeadMap, newLeadMap);
            }
            when AFTER_DELETE {
                onAfterDelete(oldLeads, oldLeadMap);
            }
            when AFTER_UNDELETE {
                onAfterUndelete(newLeads, newLeadMap);
            }
        }
    }

    private static void onBeforeInsert(List<Lead> newLeads) {
        Application_Config__mdt appConfig = LeadTrackerSelector.getApplicationConfig();
        String defaultPipeline = appConfig != null ? appConfig.Default_Pipeline__c : null;

        for (Lead l : newLeads) {
            if (String.isBlank(l.Current_Stage__c) && String.isNotBlank(l.Status)) {
                l.Current_Stage__c = l.Status;
            }
            if (String.isBlank(l.Pipeline_Type__c) && String.isNotBlank(defaultPipeline)) {
                l.Pipeline_Type__c = defaultPipeline;
            }
        }
    }

    private static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        for (Lead l : newLeads) {
            Lead old = oldLeadMap.get(l.Id);
            if (old == null) continue;

            // Keep Current_Stage__c in sync when Status changes via standard UI
            if (l.Status != old.Status && l.Current_Stage__c == old.Current_Stage__c) {
                l.Current_Stage__c = l.Status;
            }
            // Clear stale flag when activity date is refreshed
            if (l.Last_Activity_Date__c != old.Last_Activity_Date__c
                && l.Last_Activity_Date__c != null
                && l.Is_Stale__c) {
                l.Is_Stale__c = false;
            }
        }
    }

    private static void onBeforeDelete(List<Lead> oldLeads) {
    }

    private static void onAfterInsert(List<Lead> newLeads, Map<Id, Lead> newLeadMap) {
        List<Lead_Audit__c> audits = new List<Lead_Audit__c>();
        for (Lead l : newLeads) {
            audits.add(LeadAuditService.buildFieldUpdateRecord(
                l.Id, 'Lead Created', null, l.Current_Stage__c
            ));
        }
        LeadAuditService.bulkLog(audits);
    }

    private static void onAfterUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap, Map<Id, Lead> newLeadMap) {
        List<Lead_Audit__c> audits = new List<Lead_Audit__c>();

        for (Lead l : newLeads) {
            Lead old = oldLeadMap.get(l.Id);
            if (old == null) continue;

            if (l.Current_Stage__c != old.Current_Stage__c) {
                audits.add(LeadAuditService.buildStageChangeRecord(
                    l.Id, old.Current_Stage__c, l.Current_Stage__c
                ));
            }
            if (l.Status != old.Status) {
                audits.add(LeadAuditService.buildStatusUpdateRecord(
                    l.Id, old.Status, l.Status
                ));
            }
            if (l.Lead_Health__c != old.Lead_Health__c) {
                audits.add(LeadAuditService.buildHealthUpdateRecord(
                    l.Id, old.Lead_Health__c, l.Lead_Health__c
                ));
            }
            if (l.OwnerId != old.OwnerId) {
                audits.add(LeadAuditService.buildFieldUpdateRecord(
                    l.Id, 'Owner', old.OwnerId, l.OwnerId
                ));
            }
            if (l.Is_Stale__c != old.Is_Stale__c) {
                if (l.Is_Stale__c) {
                    audits.add(LeadAuditService.buildStaleRecord(l.Id, l.Current_Stage__c));
                } else {
                    audits.add(LeadAuditService.buildStaleClearedRecord(l.Id));
                }
            }
        }

        LeadAuditService.bulkLog(audits);
    }

    private static void onAfterDelete(List<Lead> oldLeads, Map<Id, Lead> oldLeadMap) {
    }

    private static void onAfterUndelete(List<Lead> newLeads, Map<Id, Lead> newLeadMap) {
    }
}
