@IsTest
private class LeadAuditService_Test {

    @TestSetup
    static void makeData() {
        insert new Lead(
            FirstName = 'Audit',
            LastName = 'Test',
            Company = 'Audit Test Co',
            Status = 'Open - Not Contacted',
            Email = 'auditservice@example.com'
        );
    }

    @IsTest
    static void testBuildStageChangeRecord() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Lead_Audit__c audit = LeadAuditService.buildStageChangeRecord(
            lead.Id, 'initial_inquiry', 'discovery_call'
        );
        Test.stopTest();

        Assert.isNotNull(audit, 'Audit record should not be null');
        Assert.areEqual('Stage Change', audit.Audit_Type__c, 'Audit type should be Stage Change');
        Assert.areEqual('initial_inquiry', audit.Old_Value__c, 'Old value should be the previous stage');
        Assert.areEqual('discovery_call', audit.New_Value__c, 'New value should be the new stage');
        Assert.isTrue(audit.Message__c.contains('initial_inquiry'), 'Message should contain old stage');
    }

    @IsTest
    static void testBuildFieldUpdateRecord() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Lead_Audit__c audit = LeadAuditService.buildFieldUpdateRecord(
            lead.Id, 'Lead Health', 'Healthy', 'At Risk'
        );
        Test.stopTest();

        Assert.areEqual('Field Update', audit.Audit_Type__c, 'Audit type should be Field Update');
        Assert.areEqual('Healthy', audit.Old_Value__c);
        Assert.areEqual('At Risk', audit.New_Value__c);
    }

    @IsTest
    static void testBulkLog() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        List<Lead_Audit__c> audits = new List<Lead_Audit__c>{
            LeadAuditService.buildStageChangeRecord(lead.Id, 'initial_inquiry', 'discovery_call'),
            LeadAuditService.buildStageChangeRecord(lead.Id, 'discovery_call', 'needs_assessment')
        };

        Test.startTest();
        LeadAuditService.bulkLog(audits);
        Test.stopTest();

        List<Lead_Audit__c> inserted = [SELECT Id FROM Lead_Audit__c WHERE Lead__c = :lead.Id];
        Assert.areEqual(2, inserted.size(), 'Two audit records should have been inserted');
    }

    @IsTest
    static void testBulkLog_Empty() {
        Test.startTest();
        LeadAuditService.bulkLog(new List<Lead_Audit__c>());
        Test.stopTest();
        // No exception expected — empty list handled gracefully
    }

    @IsTest
    static void testLog_SingleRecord() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadAuditService.log(lead.Id, 'System Update', 'System initialized lead record.', null, null);
        Test.stopTest();

        List<Lead_Audit__c> audits = [SELECT Audit_Type__c FROM Lead_Audit__c WHERE Lead__c = :lead.Id];
        Assert.areEqual(1, audits.size(), 'One audit record should exist');
        Assert.areEqual('System Update', audits[0].Audit_Type__c);
    }

    @IsTest
    static void testBuildStaleRecord() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Lead_Audit__c audit = LeadAuditService.buildStaleRecord(lead.Id, 'initial_inquiry');
        Test.stopTest();

        Assert.areEqual('Stale Flagged', audit.Audit_Type__c);
        Assert.isTrue(audit.Message__c.contains('initial_inquiry'));
    }
}
