@IsTest
private class LeadController_Test {

    @TestSetup
    static void setup() {
        insert new Lead(
            FirstName = 'Controller',
            LastName  = 'Test',
            Company   = 'Test Org',
            Status    = 'Open - Not Contacted',
            Current_Stage__c    = 'prospecting',
            Pipeline_Type__c    = 'Nonprofit',
            Engagement_Score__c = 60,
            Lead_Health__c      = 'At Risk'
        );
    }

    @IsTest
    static void getBoardData_doesNotThrow() {
        Test.startTest();
        LeadTrackerDTO.BoardData board = LeadController.getBoardData();
        Test.stopTest();
        System.assertNotEquals(null, board);
    }

    @IsTest
    static void getBoardDataByPipelineType_blankThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            LeadController.getBoardDataByPipelineType('');
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected AuraHandledException for blank pipelineType');
    }

    @IsTest
    static void getAppConfig_doesNotThrow() {
        Test.startTest();
        LeadTrackerDTO.AppConfigData cfg = LeadController.getAppConfig();
        Test.stopTest();
        System.assertNotEquals(null, cfg);
    }

    @IsTest
    static void getStageOptions_doesNotThrow() {
        Test.startTest();
        List<LeadTrackerDTO.StageOption> opts = LeadController.getStageOptions('Nonprofit');
        Test.stopTest();
        System.assertNotEquals(null, opts);
    }

    @IsTest
    static void moveLead_nullArgs_throwsAuraHandled() {
        Boolean threw = false;
        Test.startTest();
        try {
            LeadController.moveLead(null, 'prospecting');
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw);
    }

    @IsTest
    static void moveLead_invalidStage_returnsFailed() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        LeadTrackerDTO.MoveResult result = LeadController.moveLead(l.Id, '__bad__');
        Test.stopTest();
        System.assertEquals(false, result.success);
    }

    @IsTest
    static void bulkMoveLeads_emptyList_throwsAuraHandled() {
        Boolean threw = false;
        Test.startTest();
        try {
            LeadController.bulkMoveLeads(new List<Id>(), 'prospecting');
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw);
    }

    @IsTest
    static void updateEngagementScore_nullArgs_throwsAuraHandled() {
        Boolean threw = false;
        Test.startTest();
        try {
            LeadController.updateEngagementScore(null, 50);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw);
    }

    @IsTest
    static void getLeadTimeline_nullId_throwsAuraHandled() {
        Boolean threw = false;
        Test.startTest();
        try {
            LeadController.getLeadTimeline(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw);
    }

    @IsTest
    static void getLeadTimeline_validId_returnsList() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        List<LeadTrackerDTO.AuditEntry> entries = LeadController.getLeadTimeline(l.Id);
        Test.stopTest();
        System.assertNotEquals(null, entries);
    }

    @IsTest
    static void getRecentActivity_doesNotThrow() {
        Test.startTest();
        List<LeadTrackerDTO.AuditEntry> entries = LeadController.getRecentActivity(10);
        Test.stopTest();
        System.assertNotEquals(null, entries);
    }
}
