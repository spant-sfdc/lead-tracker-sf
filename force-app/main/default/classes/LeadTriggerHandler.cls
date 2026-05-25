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
    }

    private static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
    }

    private static void onBeforeDelete(List<Lead> oldLeads) {
    }

    private static void onAfterInsert(List<Lead> newLeads, Map<Id, Lead> newLeadMap) {
    }

    private static void onAfterUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap, Map<Id, Lead> newLeadMap) {
    }

    private static void onAfterDelete(List<Lead> oldLeads, Map<Id, Lead> oldLeadMap) {
    }

    private static void onAfterUndelete(List<Lead> newLeads, Map<Id, Lead> newLeadMap) {
    }
}
