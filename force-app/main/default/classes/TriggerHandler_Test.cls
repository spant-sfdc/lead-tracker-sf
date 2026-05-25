@IsTest
private class TriggerHandler_Test {

    // Minimal concrete subclass for testing the base dispatch
    private class TestHandler extends TriggerHandler {
        public Integer beforeInsertCalls  = 0;
        public Integer beforeUpdateCalls  = 0;
        public Integer afterInsertCalls   = 0;
        public Integer afterUpdateCalls   = 0;
        protected override void beforeInsert()  { beforeInsertCalls++; }
        protected override void beforeUpdate()  { beforeUpdateCalls++; }
        protected override void afterInsert()   { afterInsertCalls++; }
        protected override void afterUpdate()   { afterUpdateCalls++; }
    }

    @IsTest
    static void bypass_preventsExecution() {
        TriggerHandler.bypass('TestHandler');
        System.assert(TriggerHandler.isBypassed('TestHandler'));
        TriggerHandler.clearBypass('TestHandler');
        System.assert(!TriggerHandler.isBypassed('TestHandler'));
    }

    @IsTest
    static void clearAllBypasses_clearsAll() {
        TriggerHandler.bypass('A');
        TriggerHandler.bypass('B');
        TriggerHandler.clearAllBypasses();
        System.assert(!TriggerHandler.isBypassed('A'));
        System.assert(!TriggerHandler.isBypassed('B'));
    }

    @IsTest
    static void run_outsideTrigger_throwsException() {
        TestHandler h = new TestHandler();
        Boolean threw = false;
        try {
            h.run();
        } catch (TriggerHandler.TriggerHandlerException ex) {
            threw = true;
        }
        System.assert(threw, 'Expected TriggerHandlerException when called outside trigger context');
    }
}
