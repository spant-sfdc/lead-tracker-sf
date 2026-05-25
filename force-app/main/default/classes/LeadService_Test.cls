@IsTest
private class LeadService_Test {

    @TestSetup
    static void setup() {
        insert new Lead(
            FirstName = 'Test',
            LastName  = 'Lead',
            Company   = 'Test Org',
            Status    = 'Open - Not Contacted',
            Current_Stage__c    = 'prospecting',
            Pipeline_Type__c    = 'Nonprofit',
            Engagement_Score__c = 50,
            Lead_Health__c      = 'At Risk'
        );
    }

    // ── computeHealth ─────────────────────────────────────────────────────────

    @IsTest
    static void computeHealth_stale_returnsCritical() {
        System.assertEquals('Critical', LeadService.computeHealth(90, true));
    }

    @IsTest
    static void computeHealth_highScore_returnsHealthy() {
        System.assertEquals('Healthy', LeadService.computeHealth(70, false));
        System.assertEquals('Healthy', LeadService.computeHealth(100, false));
    }

    @IsTest
    static void computeHealth_midScore_returnsAtRisk() {
        System.assertEquals('At Risk', LeadService.computeHealth(40, false));
        System.assertEquals('At Risk', LeadService.computeHealth(69, false));
    }

    @IsTest
    static void computeHealth_lowScore_returnsCritical() {
        System.assertEquals('Critical', LeadService.computeHealth(0, false));
        System.assertEquals('Critical', LeadService.computeHealth(39, false));
        System.assertEquals('Critical', LeadService.computeHealth(null, false));
    }

    // ── bulkMoveLeadsToStage ──────────────────────────────────────────────────

    @IsTest
    static void bulkMove_emptyList_returnsEmpty() {
        Test.startTest();
        List<LeadTrackerDTO.MoveResult> results =
            new LeadService().bulkMoveLeadsToStage(new List<Id>(), 'prospecting');
        Test.stopTest();
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void bulkMove_invalidStage_returnsFailure() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        List<LeadTrackerDTO.MoveResult> results =
            new LeadService().bulkMoveLeadsToStage(new List<Id>{ l.Id }, '__invalid__');
        Test.stopTest();
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void moveLeadToStage_invalidStage_returnsFailure() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        LeadTrackerDTO.MoveResult result =
            new LeadService().moveLeadToStage(l.Id, '__not_real__');
        Test.stopTest();
        System.assertEquals(false, result.success);
    }

    // ── updateEngagementScore ─────────────────────────────────────────────────

    @IsTest
    static void updateEngagementScore_outOfRange_throwsException() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Boolean threw = false;
        Test.startTest();
        try {
            new LeadService().updateEngagementScore(l.Id, 150);
        } catch (LeadTrackerException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected LeadTrackerException for score > 100');
    }

    @IsTest
    static void updateEngagementScore_valid_updatesHealth() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        new LeadService().updateEngagementScore(l.Id, 80);
        Test.stopTest();
        Lead updated = [SELECT Lead_Health__c, Engagement_Score__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(80, Integer.valueOf(updated.Engagement_Score__c));
        System.assertEquals('Healthy', updated.Lead_Health__c);
    }

    // ── markLeadsStale ────────────────────────────────────────────────────────

    @IsTest
    static void markLeadsStale_setsStaleAndCritical() {
        Lead l = [SELECT Id, Is_Stale__c, Lead_Health__c FROM Lead LIMIT 1];
        System.assertEquals(false, l.Is_Stale__c);
        Test.startTest();
        new LeadService().markLeadsStale(new List<Lead>{ l });
        Test.stopTest();
        Lead updated = [SELECT Is_Stale__c, Lead_Health__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(true, updated.Is_Stale__c);
        System.assertEquals('Critical', updated.Lead_Health__c);
    }

    @IsTest
    static void markLeadsStale_emptyList_doesNotThrow() {
        Test.startTest();
        new LeadService().markLeadsStale(new List<Lead>());
        Test.stopTest();
        System.assert(true);
    }
}
