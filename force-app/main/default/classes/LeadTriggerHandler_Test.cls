@IsTest
private class LeadTriggerHandler_Test {

    @IsTest
    static void testTrigger_Insert() {
        Test.startTest();
        Lead testLead = new Lead(
            FirstName = 'Trigger',
            LastName = 'Insert',
            Company = 'Trigger Test Co',
            Status = 'Open - Not Contacted',
            Email = 'triggerinsert@example.com'
        );
        insert testLead;
        Test.stopTest();

        Lead inserted = [SELECT Id, Name FROM Lead WHERE Id = :testLead.Id];
        Assert.isNotNull(inserted.Id, 'Lead should be inserted without trigger errors');
    }

    @IsTest
    static void testTrigger_Update() {
        Lead testLead = new Lead(
            FirstName = 'Trigger',
            LastName = 'Update',
            Company = 'Trigger Test Co',
            Status = 'Open - Not Contacted',
            Email = 'triggerupdate@example.com'
        );
        insert testLead;

        Test.startTest();
        testLead.Status = 'Working - Contacted';
        update testLead;
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :testLead.Id];
        Assert.areEqual('Working - Contacted', updated.Status, 'Trigger update should succeed');
    }

    @IsTest
    static void testTrigger_Delete() {
        Lead testLead = new Lead(
            FirstName = 'Trigger',
            LastName = 'Delete',
            Company = 'Trigger Test Co',
            Status = 'Open - Not Contacted',
            Email = 'triggerdelete@example.com'
        );
        insert testLead;
        Id deletedId = testLead.Id;

        Test.startTest();
        delete testLead;
        Test.stopTest();

        List<Lead> result = [SELECT Id FROM Lead WHERE Id = :deletedId ALL ROWS];
        Assert.areEqual(1, result.size(), 'Deleted lead should still exist in recycle bin');
    }
}
