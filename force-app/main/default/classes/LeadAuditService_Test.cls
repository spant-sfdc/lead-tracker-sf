@IsTest
private class LeadAuditService_Test {

    @TestSetup
    static void setup() {
        insert new Lead(
            FirstName = 'Audit',
            LastName  = 'Test',
            Company   = 'Audit Test Co',
            Status    = 'Open - Not Contacted',
            Email     = 'auditservice@example.com',
            Current_Stage__c = 'prospecting',
            Pipeline_Type__c = 'Nonprofit'
        );
    }

    private static Lead getLead() {
        return [SELECT Id FROM Lead LIMIT 1];
    }

    @IsTest
    static void buildStageChangeRecord_setsFields() {
        Lead l = getLead();
        Lead_Audit__c a = LeadAuditService.buildStageChangeRecord(l.Id, 'initial_inquiry', 'discovery_call');
        System.assertNotEquals(null, a);
        System.assertEquals('Stage Change', a.Audit_Type__c);
        System.assertEquals('initial_inquiry', a.Old_Value__c);
        System.assertEquals('discovery_call', a.New_Value__c);
        System.assert(a.Message__c.contains('initial_inquiry'));
    }

    @IsTest
    static void buildFieldUpdateRecord_setsFields() {
        Lead l = getLead();
        Lead_Audit__c a = LeadAuditService.buildFieldUpdateRecord(l.Id, 'Lead Health', 'Healthy', 'At Risk');
        System.assertEquals('Field Update', a.Audit_Type__c);
        System.assertEquals('Healthy', a.Old_Value__c);
        System.assertEquals('At Risk', a.New_Value__c);
    }

    @IsTest
    static void buildStaleRecord_setsType() {
        Lead l = getLead();
        Lead_Audit__c a = LeadAuditService.buildStaleRecord(l.Id);
        System.assertEquals('Stale Flagged', a.Audit_Type__c);
        System.assertEquals('false', a.Old_Value__c);
        System.assertEquals('true', a.New_Value__c);
    }

    @IsTest
    static void buildStaleClearedRecord_setsType() {
        Lead l = getLead();
        Lead_Audit__c a = LeadAuditService.buildStaleClearedRecord(l.Id);
        System.assertEquals('Stale Cleared', a.Audit_Type__c);
    }

    @IsTest
    static void buildCreationRecord_nullOldValue() {
        Lead l = getLead();
        Lead_Audit__c a = LeadAuditService.buildCreationRecord(l.Id, 'prospecting');
        System.assertEquals('Lead Created', a.Audit_Type__c);
        System.assertEquals(null, a.Old_Value__c);
        System.assertEquals('prospecting', a.New_Value__c);
    }

    @IsTest
    static void bulkLog_insertsRecords() {
        Lead l = getLead();
        List<Lead_Audit__c> audits = new List<Lead_Audit__c>{
            LeadAuditService.buildStageChangeRecord(l.Id, 'a', 'b'),
            LeadAuditService.buildStaleRecord(l.Id)
        };
        Test.startTest();
        LeadAuditService.bulkLog(audits);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Lead_Audit__c WHERE Lead__c = :l.Id]);
    }

    @IsTest
    static void bulkLog_emptyList_doesNotThrow() {
        Test.startTest();
        LeadAuditService.bulkLog(new List<Lead_Audit__c>());
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void bulkLog_nullList_doesNotThrow() {
        Test.startTest();
        LeadAuditService.bulkLog(null);
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void log_singleRecord_inserts() {
        Lead l = getLead();
        Test.startTest();
        LeadAuditService.log(l.Id, 'System Update', 'System initialized lead record.', null, null);
        Test.stopTest();
        List<Lead_Audit__c> audits = [SELECT Audit_Type__c FROM Lead_Audit__c WHERE Lead__c = :l.Id];
        System.assertEquals(1, audits.size());
        System.assertEquals('System Update', audits[0].Audit_Type__c);
    }

    @IsTest
    static void getTimeline_returnsAuditEntries() {
        Lead l = getLead();
        LeadAuditService.log(l.Id, 'Stage Change', 'Moved', 'a', 'b');
        Test.startTest();
        List<LeadTrackerDTO.AuditEntry> timeline = LeadAuditService.getTimeline(l.Id);
        Test.stopTest();
        System.assertEquals(1, timeline.size());
        System.assertEquals('Stage Change', timeline[0].auditType);
    }

    @IsTest
    static void getTimeline_nullId_returnsEmpty() {
        Test.startTest();
        List<LeadTrackerDTO.AuditEntry> timeline = LeadAuditService.getTimeline(null);
        Test.stopTest();
        System.assertEquals(0, timeline.size());
    }

    @IsTest
    static void getRecentActivity_respectsLimit() {
        Lead l = getLead();
        for (Integer i = 0; i < 3; i++) {
            LeadAuditService.log(l.Id, 'Field Update', 'Update ' + i, 'old', 'new');
        }
        Test.startTest();
        List<LeadTrackerDTO.AuditEntry> activity = LeadAuditService.getRecentActivity(2);
        Test.stopTest();
        System.assertEquals(2, activity.size());
    }

    @IsTest
    static void longValues_areTruncatedTo255() {
        Lead l = getLead();
        String longStr = 'X'.repeat(300);
        Lead_Audit__c a = LeadAuditService.buildFieldUpdateRecord(l.Id, 'Field', longStr, longStr);
        System.assertEquals(255, a.Old_Value__c.length());
        System.assertEquals(255, a.New_Value__c.length());
    }
}
