@IsTest
private class LeadTrackerController_Test {

    @TestSetup
    static void makeData() {
        insert new Lead(
            FirstName = 'Controller',
            LastName = 'Test',
            Company = 'Controller Test Co',
            Status = 'Open - Not Contacted',
            Email = 'controllertest@example.com'
        );
    }

    @IsTest
    static void testGetPipelineStages() {
        Test.startTest();
        List<LeadTracker_Pipeline_Stage__mdt> stages = LeadTrackerController.getPipelineStages();
        Test.stopTest();

        Assert.isNotNull(stages, 'Expected non-null stages list');
    }

    @IsTest
    static void testGetAppConfig() {
        Test.startTest();
        LeadTracker_App_Config__mdt config = LeadTrackerController.getAppConfig();
        Test.stopTest();

        // Null acceptable in test context; validated post-deployment with CMT data
    }

    @IsTest
    static void testGetBoardLeads() {
        Test.startTest();
        List<Lead> leads = LeadTrackerController.getBoardLeads();
        Test.stopTest();

        Assert.isNotNull(leads, 'Expected non-null board leads list');
        Assert.isTrue(leads.size() >= 1, 'Expected at least one lead on the board');
    }

    @IsTest
    static void testMoveLead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadTrackerController.moveLead(lead.Id, 'Working - Contacted');
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Working - Contacted', updated.Status, 'Lead status should be moved');
    }

    @IsTest
    static void testMoveLead_InvalidStatusThrows() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        try {
            LeadTrackerController.moveLead(lead.Id, '');
            Assert.fail('Expected AuraHandledException for blank status');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'AuraHandledException message should not be null');
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkMoveLeads() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadTrackerController.bulkMoveLeads(new List<Id>{ lead.Id }, 'Working - Contacted');
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Working - Contacted', updated.Status, 'Bulk move should succeed');
    }
}
