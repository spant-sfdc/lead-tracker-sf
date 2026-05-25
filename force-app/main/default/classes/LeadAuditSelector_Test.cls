@IsTest
private class LeadAuditSelector_Test {

    @TestSetup
    static void makeData() {
        Lead lead = new Lead(
            FirstName = 'Audit',
            LastName = 'Selector',
            Company = 'Audit Selector Co',
            Status = 'Open - Not Contacted',
            Email = 'auditselector@example.com'
        );
        insert lead;

        List<Lead_Audit__c> audits = new List<Lead_Audit__c>{
            new Lead_Audit__c(
                Lead__c = lead.Id,
                Audit_Type__c = 'Stage Change',
                Message__c = 'Stage changed from initial_inquiry to discovery_call',
                Old_Value__c = 'initial_inquiry',
                New_Value__c = 'discovery_call',
                Performed_By__c = UserInfo.getUserId(),
                Performed_On__c = System.now()
            ),
            new Lead_Audit__c(
                Lead__c = lead.Id,
                Audit_Type__c = 'Field Update',
                Message__c = 'Lead Health updated from Healthy to At Risk',
                Old_Value__c = 'Healthy',
                New_Value__c = 'At Risk',
                Performed_By__c = UserInfo.getUserId(),
                Performed_On__c = System.now().addMinutes(-5)
            )
        };
        insert audits;
    }

    @IsTest
    static void testGetAuditsByLeadId() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<Lead_Audit__c> audits = LeadAuditSelector.getAuditsByLeadId(lead.Id);
        Test.stopTest();

        Assert.isNotNull(audits, 'Expected non-null list');
        Assert.areEqual(2, audits.size(), 'Expected 2 audit records for this lead');
    }

    @IsTest
    static void testGetAuditsByLeadIds() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<Lead_Audit__c> audits = LeadAuditSelector.getAuditsByLeadIds(new Set<Id>{ lead.Id });
        Test.stopTest();

        Assert.areEqual(2, audits.size(), 'Expected 2 audit records');
    }

    @IsTest
    static void testGetAuditsByType() {
        Test.startTest();
        List<Lead_Audit__c> audits = LeadAuditSelector.getAuditsByType('Stage Change', 10);
        Test.stopTest();

        Assert.areEqual(1, audits.size(), 'Expected 1 Stage Change audit');
        Assert.areEqual('Stage Change', audits[0].Audit_Type__c);
    }

    @IsTest
    static void testGetRecentAudits() {
        Test.startTest();
        List<Lead_Audit__c> audits = LeadAuditSelector.getRecentAudits(50);
        Test.stopTest();

        Assert.isNotNull(audits, 'Expected non-null list');
        Assert.isTrue(audits.size() >= 2, 'Expected at least 2 recent audits');
    }

    @IsTest
    static void testGetStageChangeSummary() {
        Test.startTest();
        List<AggregateResult> results = LeadAuditSelector.getStageChangeSummary();
        Test.stopTest();

        Assert.isNotNull(results, 'Expected non-null aggregate results');
    }
}
