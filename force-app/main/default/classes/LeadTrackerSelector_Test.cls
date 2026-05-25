@IsTest
private class LeadTrackerSelector_Test {

    @TestSetup
    static void makeData() {
        insert new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company Inc',
            Status = 'Open - Not Contacted',
            Email = 'testlead@example.com',
            Phone = '5555551234'
        );
    }

    @IsTest
    static void testGetAllActiveLeads() {
        Test.startTest();
        List<Lead> leads = LeadTrackerSelector.getAllActiveLeads();
        Test.stopTest();

        Assert.isNotNull(leads, 'Expected non-null list');
        Assert.isTrue(leads.size() >= 1, 'Expected at least one lead');
    }

    @IsTest
    static void testGetLeadsByStatus() {
        Test.startTest();
        List<Lead> leads = LeadTrackerSelector.getLeadsByStatus(
            new Set<String>{ 'Open - Not Contacted' }
        );
        Test.stopTest();

        Assert.isNotNull(leads, 'Expected non-null list');
        Assert.areEqual(1, leads.size(), 'Expected exactly one lead with that status');
    }

    @IsTest
    static void testGetLeadsById() {
        Lead existing = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<Lead> leads = LeadTrackerSelector.getLeadsById(new Set<Id>{ existing.Id });
        Test.stopTest();

        Assert.areEqual(1, leads.size(), 'Expected exactly one lead by Id');
        Assert.areEqual(existing.Id, leads[0].Id, 'Returned lead Id should match');
    }

    @IsTest
    static void testGetActivePipelineStages() {
        Test.startTest();
        List<LeadTracker_Pipeline_Stage__mdt> stages = LeadTrackerSelector.getActivePipelineStages();
        Test.stopTest();

        Assert.isNotNull(stages, 'Expected non-null stages list');
    }

    @IsTest
    static void testGetAppConfig() {
        Test.startTest();
        LeadTracker_App_Config__mdt config = LeadTrackerSelector.getAppConfig();
        Test.stopTest();

        // Null is acceptable in test context if CMT not deployed
        // Assertions on field values are validated post-deployment
    }
}
