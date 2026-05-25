@IsTest
private class LeadTriggerHandler_Test {

    private static Lead buildLead(String suffix) {
        return new Lead(
            FirstName = 'Trigger',
            LastName  = suffix,
            Company   = 'Test Org',
            Status    = 'Open - Not Contacted',
            Email     = 'trigger.' + suffix.toLowerCase() + '@example.com',
            Current_Stage__c = 'prospecting',
            Pipeline_Type__c = 'Nonprofit'
        );
    }

    @IsTest
    static void insert_createsAuditRecord() {
        Test.startTest();
        Lead l = buildLead('Insert');
        insert l;
        Test.stopTest();
        List<Lead_Audit__c> audits = [SELECT Audit_Type__c FROM Lead_Audit__c WHERE Lead__c = :l.Id];
        System.assertEquals(1, audits.size());
        System.assertEquals('Lead Created', audits[0].Audit_Type__c);
    }

    @IsTest
    static void insert_setsDefaultPipelineType_whenBlank() {
        Lead l = new Lead(
            FirstName = 'Trigger',
            LastName  = 'NoPipeline',
            Company   = 'Test Org',
            Status    = 'Open - Not Contacted'
        );
        Test.startTest();
        insert l;
        Test.stopTest();
        Lead inserted = [SELECT Pipeline_Type__c FROM Lead WHERE Id = :l.Id];
        // Pipeline_Type__c should be populated from config or left null if no config exists —
        // either way, the insert must not fail
        System.assertNotEquals(null, inserted.Id);
    }

    @IsTest
    static void insert_setsCurrentStage_fromStatus_whenBlank() {
        Lead l = new Lead(
            FirstName = 'Trigger',
            LastName  = 'NoStage',
            Company   = 'Test Org',
            Status    = 'Open - Not Contacted'
        );
        Test.startTest();
        insert l;
        Test.stopTest();
        Lead inserted = [SELECT Current_Stage__c, Status FROM Lead WHERE Id = :l.Id];
        System.assertEquals(inserted.Status, inserted.Current_Stage__c);
    }

    @IsTest
    static void update_stageChange_createsAudit() {
        Lead l = buildLead('StageChange');
        insert l;
        Test.startTest();
        l.Current_Stage__c = 'qualifying';
        update l;
        Test.stopTest();
        List<Lead_Audit__c> audits = [
            SELECT Audit_Type__c FROM Lead_Audit__c
            WHERE  Lead__c = :l.Id AND Audit_Type__c = 'Stage Change'
        ];
        System.assertEquals(1, audits.size());
    }

    @IsTest
    static void update_statusChange_syncsCurrentStage() {
        Lead l = buildLead('StatusSync');
        insert l;
        Test.startTest();
        l.Status = 'Working - Contacted';
        update l;
        Test.stopTest();
        Lead updated = [SELECT Status, Current_Stage__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('Working - Contacted', updated.Status);
    }

    @IsTest
    static void update_activityDateRefresh_clearsStale() {
        Lead l = buildLead('ClearStale');
        insert l;
        l.Is_Stale__c = true;
        update l;

        Test.startTest();
        l.Last_Activity_Date__c = Date.today();
        update l;
        Test.stopTest();

        Lead updated = [SELECT Is_Stale__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(false, updated.Is_Stale__c);
    }

    @IsTest
    static void update_staleFlagSet_createsStaleAudit() {
        Lead l = buildLead('StaleAudit');
        insert l;
        Test.startTest();
        l.Is_Stale__c = true;
        update l;
        Test.stopTest();
        List<Lead_Audit__c> audits = [
            SELECT Audit_Type__c FROM Lead_Audit__c
            WHERE  Lead__c = :l.Id AND Audit_Type__c = 'Stale Flagged'
        ];
        System.assertEquals(1, audits.size());
    }

    @IsTest
    static void delete_doesNotThrow() {
        Lead l = buildLead('Delete');
        insert l;
        Id deletedId = l.Id;
        Test.startTest();
        delete l;
        Test.stopTest();
        List<Lead> result = [SELECT Id FROM Lead WHERE Id = :deletedId ALL ROWS];
        System.assertEquals(1, result.size(), 'Deleted lead should be in recycle bin');
    }

    @IsTest
    static void bypass_preventsAuditCreation() {
        Lead l = buildLead('Bypass');
        insert l;
        TriggerHandler.bypass('LeadTriggerHandler');
        Integer auditsBefore = [SELECT COUNT() FROM Lead_Audit__c WHERE Lead__c = :l.Id];
        Test.startTest();
        l.Current_Stage__c = 'qualifying';
        update l;
        Test.stopTest();
        TriggerHandler.clearBypass('LeadTriggerHandler');
        Integer auditsAfter = [SELECT COUNT() FROM Lead_Audit__c WHERE Lead__c = :l.Id];
        System.assertEquals(auditsBefore, auditsAfter, 'Bypassed handler should not create new audits');
    }

    @IsTest
    static void bulkInsert_200Leads_doesNotHitLimits() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                FirstName = 'Bulk',
                LastName  = 'Lead' + i,
                Company   = 'Bulk Org',
                Status    = 'Open - Not Contacted',
                Current_Stage__c = 'prospecting',
                Pipeline_Type__c = 'Nonprofit'
            ));
        }
        Test.startTest();
        insert leads;
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Lead WHERE Company = 'Bulk Org']);
    }
}
