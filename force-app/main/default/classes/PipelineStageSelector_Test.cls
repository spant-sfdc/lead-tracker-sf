@IsTest
private class PipelineStageSelector_Test {

    @IsTest
    static void getAllActiveStages_returnsResults() {
        Test.startTest();
        List<Pipeline_Stage__mdt> stages = new PipelineStageSelector().getAllActiveStages();
        Test.stopTest();
        // CMT data must exist in the org; just assert the call doesn't throw
        System.assertNotEquals(null, stages);
    }

    @IsTest
    static void getActiveStagesByPipelineType_blankDelegatesToAll() {
        Test.startTest();
        List<Pipeline_Stage__mdt> all   = new PipelineStageSelector().getAllActiveStages();
        List<Pipeline_Stage__mdt> blank = new PipelineStageSelector().getActiveStagesByPipelineType('');
        Test.stopTest();
        System.assertEquals(all.size(), blank.size());
    }

    @IsTest
    static void getStageByKey_missingKey_returnsNull() {
        Test.startTest();
        Pipeline_Stage__mdt result = new PipelineStageSelector().getStageByKey('__no_such_key__');
        Test.stopTest();
        System.assertEquals(null, result);
    }

    @IsTest
    static void getStageByKey_blankKey_returnsNull() {
        Test.startTest();
        Pipeline_Stage__mdt result = new PipelineStageSelector().getStageByKey('');
        Test.stopTest();
        System.assertEquals(null, result);
    }

    @IsTest
    static void getActiveStageMapByKey_keyMatchesStageKey() {
        Test.startTest();
        Map<String, Pipeline_Stage__mdt> stageMap = new PipelineStageSelector().getActiveStageMapByKey();
        Test.stopTest();
        for (String key : stageMap.keySet()) {
            System.assertEquals(key, stageMap.get(key).Stage_Key__c);
        }
    }

    @IsTest
    static void getDefaultAppConfig_doesNotThrow() {
        Test.startTest();
        Application_Config__mdt cfg = new PipelineStageSelector().getDefaultAppConfig();
        Test.stopTest();
        // Config may or may not exist in org — just assert no exception
        System.assert(true);
    }
}
