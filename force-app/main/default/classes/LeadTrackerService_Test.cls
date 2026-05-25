@IsTest
private class LeadTrackerService_Test {

    @TestSetup
    static void makeData() {
        insert new Lead(
            FirstName = 'Service',
            LastName = 'Test',
            Company = 'Service Test Co',
            Status = 'Open - Not Contacted',
            Email = 'servicetest@example.com'
        );
    }

    @IsTest
    static void testGetLeadsByPipelineStage() {
        Test.startTest();
        Map<String, List<Lead>> result = LeadTrackerService.getLeadsByPipelineStage();
        Test.stopTest();

        Assert.isNotNull(result, 'Expected non-null pipeline map');
    }

    @IsTest
    static void testUpdateLeadStatus() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadTrackerService.updateLeadStatus(lead.Id, 'Working - Contacted');
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Working - Contacted', updated.Status, 'Status should be updated');
    }

    @IsTest
    static void testUpdateLeadStatus_BlankThrows() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        try {
            LeadTrackerService.updateLeadStatus(lead.Id, '');
            Assert.fail('Expected LeadTrackerException to be thrown');
        } catch (LeadTrackerException e) {
            Assert.isTrue(e.getMessage().contains('blank'), 'Error message should mention blank');
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateLeadStatus() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadTrackerService.bulkUpdateLeadStatus(new List<Id>{ lead.Id }, 'Working - Contacted');
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Working - Contacted', updated.Status, 'Bulk status update should succeed');
    }

    @IsTest
    static void testBulkUpdateLeadStatus_InvalidParamsThrows() {
        Test.startTest();
        try {
            LeadTrackerService.bulkUpdateLeadStatus(new List<Id>(), '');
            Assert.fail('Expected LeadTrackerException for invalid params');
        } catch (LeadTrackerException e) {
            Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }
}
