@IsTest
private class LeadSelector_Test {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName  = 'Lead ' + i,
                Company   = 'Org ' + i,
                Status    = 'Open - Not Contacted',
                Current_Stage__c   = 'prospecting',
                Pipeline_Type__c   = 'Nonprofit',
                Engagement_Score__c = i * 10
            ));
        }
        insert leads;
    }

    @IsTest
    static void getBoardLeads_returnsNonConverted() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getBoardLeads();
        Test.stopTest();
        System.assert(!results.isEmpty(), 'Should return leads');
        for (Lead l : results) {
            System.assertEquals(false, l.IsConverted);
        }
    }

    @IsTest
    static void getBoardLeadsByPipelineType_filtersCorrectly() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getBoardLeadsByPipelineType('Nonprofit');
        Test.stopTest();
        for (Lead l : results) {
            System.assertEquals('Nonprofit', l.Pipeline_Type__c);
        }
    }

    @IsTest
    static void getBoardLeadsByPipelineType_blankDelegatesToAll() {
        Test.startTest();
        List<Lead> all    = new LeadSelector().getBoardLeads();
        List<Lead> blank  = new LeadSelector().getBoardLeadsByPipelineType('');
        Test.stopTest();
        System.assertEquals(all.size(), blank.size());
    }

    @IsTest
    static void getLeadsById_emptySet_returnsEmpty() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getLeadsById(new Set<Id>());
        Test.stopTest();
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void getLeadsById_validIds_returnsLeads() {
        List<Lead> all = [SELECT Id FROM Lead LIMIT 2];
        Set<Id> ids = new Map<Id, Lead>(all).keySet();
        Test.startTest();
        List<Lead> results = new LeadSelector().getLeadsById(ids);
        Test.stopTest();
        System.assertEquals(ids.size(), results.size());
    }

    @IsTest
    static void getStaleLeadCandidates_returnsNonStale() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getStaleLeadCandidates(30);
        Test.stopTest();
        for (Lead l : results) {
            System.assertEquals(false, l.Is_Stale__c);
        }
    }

    @IsTest
    static void getLeadsByStage_blankKey_returnsEmpty() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getLeadsByStage('');
        Test.stopTest();
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void getLeadsByStages_emptySet_returnsEmpty() {
        Test.startTest();
        List<Lead> results = new LeadSelector().getLeadsByStages(new Set<String>());
        Test.stopTest();
        System.assertEquals(0, results.size());
    }
}
