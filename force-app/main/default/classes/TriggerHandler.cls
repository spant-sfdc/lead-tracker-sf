/**
 * Abstract base class for all trigger handlers.
 * Provides recursion prevention, bypass control, and a standard dispatch loop.
 *
 * Usage:
 *   public class MyTriggerHandler extends TriggerHandler {
 *       protected override void beforeInsert() { ... }
 *   }
 *   // In trigger: new MyTriggerHandler().run();
 */
public abstract class TriggerHandler {

    // ── Bypass registry ───────────────────────────────────────────────────────
    private static Set<String> bypassedHandlers = new Set<String>();

    /** Prevent a handler from executing for the remainder of the transaction. */
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    /** Re-enable a previously bypassed handler. */
    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    // ── Recursion guard ───────────────────────────────────────────────────────
    private static Map<String, Integer> executionCount = new Map<String, Integer>();
    private static final Integer MAX_EXECUTIONS = 1;

    // ── Handler identity ──────────────────────────────────────────────────────
    private String handlerName;

    public TriggerHandler() {
        this.handlerName = getHandlerName();
    }

    private String getHandlerName() {
        return String.valueOf(this).substringBefore(':');
    }

    // ── Main entry point ──────────────────────────────────────────────────────
    /** Call this from the trigger body: new MyHandler().run(); */
    public void run() {
        if (!validateRun()) {
            return;
        }

        incrementExecutionCount();

        switch on Trigger.operationType {
            when BEFORE_INSERT  { beforeInsert(); }
            when BEFORE_UPDATE  { beforeUpdate(); }
            when BEFORE_DELETE  { beforeDelete(); }
            when AFTER_INSERT   { afterInsert(); }
            when AFTER_UPDATE   { afterUpdate(); }
            when AFTER_DELETE   { afterDelete(); }
            when AFTER_UNDELETE { afterUndelete(); }
        }
    }

    // ── Overridable handler methods ───────────────────────────────────────────
    protected virtual void beforeInsert()  {}
    protected virtual void beforeUpdate()  {}
    protected virtual void beforeDelete()  {}
    protected virtual void afterInsert()   {}
    protected virtual void afterUpdate()   {}
    protected virtual void afterDelete()   {}
    protected virtual void afterUndelete() {}

    // ── Internal helpers ──────────────────────────────────────────────────────
    private Boolean validateRun() {
        if (!Trigger.isExecuting) {
            throw new TriggerHandlerException('TriggerHandler.run() called outside of a trigger context.');
        }
        if (isBypassed(handlerName)) {
            return false;
        }
        if (getExecutionCount() >= MAX_EXECUTIONS) {
            return false;
        }
        return true;
    }

    private Integer getExecutionCount() {
        return executionCount.containsKey(handlerName) ? executionCount.get(handlerName) : 0;
    }

    private void incrementExecutionCount() {
        executionCount.put(handlerName, getExecutionCount() + 1);
    }

    // ── Inner exception ───────────────────────────────────────────────────────
    public class TriggerHandlerException extends Exception {}
}
