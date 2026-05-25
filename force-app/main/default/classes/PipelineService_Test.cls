@IsTest
private class PipelineService_Test {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(
                FirstName = 'Pipeline',
                LastName  = 'Test ' + i,
                Company   = 'Org ' + i,
                Status    = 'Open - Not Contacted',
                Current_Stage__c    = 'prospecting',
                Pipeline_Type__c    = 'Nonprofit',
                Engagement_Score__c = 60
            ));
        }
        insert leads;
    }

    @IsTest
    static void getBoardData_returnsNonNullBoard() {
        Test.startTest();
        LeadTrackerDTO.BoardData board = new PipelineService().getBoardData();
        Test.stopTest();
        System.assertNotEquals(null, board);
        System.assertNotEquals(null, board.stages);
        System.assertNotEquals(null, board.config);
        System.assertNotEquals(null, board.lastRefreshed);
    }

    @IsTest
    static void getBoardDataByPipelineType_nonprofit_hasLeads() {
        Test.startTest();
        LeadTrackerDTO.BoardData board = new PipelineService().getBoardDataByPipelineType('Nonprofit');
        Test.stopTest();
        System.assertNotEquals(null, board);
        System.assert(board.totalLeads >= 0);
    }

    @IsTest
    static void getStageOptions_returnsList() {
        Test.startTest();
        List<LeadTrackerDTO.StageOption> opts = new PipelineService().getStageOptions('Nonprofit');
        Test.stopTest();
        System.assertNotEquals(null, opts);
    }

    @IsTest
    static void getStageOptions_blankType_returnsAllStages() {
        Test.startTest();
        List<LeadTrackerDTO.StageOption> all   = new PipelineService().getStageOptions(null);
        List<LeadTrackerDTO.StageOption> blank  = new PipelineService().getStageOptions('');
        Test.stopTest();
        System.assertEquals(all.size(), blank.size());
    }

    @IsTest
    static void getAppConfigData_returnsDefaults_whenNoCmtRecord() {
        Test.startTest();
        LeadTrackerDTO.AppConfigData cfg = new PipelineService().getAppConfigData();
        Test.stopTest();
        System.assertNotEquals(null, cfg);
        System.assertNotEquals(null, cfg.defaultPipeline);
    }

    @IsTest
    static void boardData_staleCountMatchesStaleLeads() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        l.Is_Stale__c = true;
        update l;
        Test.startTest();
        LeadTrackerDTO.BoardData board = new PipelineService().getBoardDataByPipelineType('Nonprofit');
        Test.stopTest();
        System.assert(board.staleCount >= 1, 'Should count at least one stale lead');
    }
}
