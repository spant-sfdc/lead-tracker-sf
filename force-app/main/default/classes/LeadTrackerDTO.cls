/**
 * Data Transfer Object container for all Lead Tracker LWC-facing wrapper classes.
 * All inner classes are @AuraEnabled so they serialize cleanly over the wire.
 */
public class LeadTrackerDTO {

    // ── Board ─────────────────────────────────────────────────────────────────

    /** Full board payload returned by LeadController.getBoardData(). */
    public class BoardData {
        @AuraEnabled public List<StageColumn> stages         { get; set; }
        @AuraEnabled public AppConfigData     config         { get; set; }
        @AuraEnabled public Integer           totalLeads     { get; set; }
        @AuraEnabled public Integer           staleCount     { get; set; }
        @AuraEnabled public String            lastRefreshed  { get; set; }

        public BoardData() {
            stages        = new List<StageColumn>();
            totalLeads    = 0;
            staleCount    = 0;
            lastRefreshed = String.valueOf(System.now());
        }
    }

    /** One column on the kanban board, representing a single pipeline stage. */
    public class StageColumn {
        @AuraEnabled public String        stageKey    { get; set; }
        @AuraEnabled public String        stageLabel  { get; set; }
        @AuraEnabled public Integer       sequence    { get; set; }
        @AuraEnabled public String        color       { get; set; }
        @AuraEnabled public String        icon        { get; set; }
        @AuraEnabled public Boolean       isClosed    { get; set; }
        @AuraEnabled public Boolean       isWon       { get; set; }
        @AuraEnabled public Integer       slaDays     { get; set; }
        @AuraEnabled public List<LeadCard> leads      { get; set; }
        @AuraEnabled public Integer       leadCount   { get; set; }

        public StageColumn() {
            leads     = new List<LeadCard>();
            leadCount = 0;
            isClosed  = false;
            isWon     = false;
        }
    }

    /** Compact lead representation for a kanban card. */
    public class LeadCard {
        @AuraEnabled public Id      leadId           { get; set; }
        @AuraEnabled public String  name             { get; set; }
        @AuraEnabled public String  company          { get; set; }
        @AuraEnabled public String  email            { get; set; }
        @AuraEnabled public String  phone            { get; set; }
        @AuraEnabled public String  currentStage     { get; set; }
        @AuraEnabled public String  pipelineType     { get; set; }
        @AuraEnabled public String  leadHealth       { get; set; }
        @AuraEnabled public Integer engagementScore  { get; set; }
        @AuraEnabled public Boolean isStale          { get; set; }
        @AuraEnabled public String  nextFollowUp     { get; set; }
        @AuraEnabled public String  lastActivityDate { get; set; }
        @AuraEnabled public String  ownerName        { get; set; }
        @AuraEnabled public String  organizationSize { get; set; }
        @AuraEnabled public String  currentCrm       { get; set; }
        @AuraEnabled public String  fundingModel     { get; set; }
        @AuraEnabled public String  primaryStakeholder { get; set; }
        @AuraEnabled public List<String> badges      { get; set; }

        public LeadCard() {
            isStale = false;
            badges  = new List<String>();
        }
    }

    // ── App Config ────────────────────────────────────────────────────────────

    /** Flattened Application_Config__mdt for the LWC. */
    public class AppConfigData {
        @AuraEnabled public String  companyName             { get; set; }
        @AuraEnabled public String  themeColor              { get; set; }
        @AuraEnabled public String  defaultPipeline         { get; set; }
        @AuraEnabled public String  cardDensity             { get; set; }
        @AuraEnabled public Integer autoRefreshInterval     { get; set; }
        @AuraEnabled public Integer dashboardRefreshMinutes { get; set; }
        @AuraEnabled public String  emptyStateMessage       { get; set; }
    }

    // ── Audit / Timeline ──────────────────────────────────────────────────────

    /** Single audit entry for the lead timeline component. */
    public class AuditEntry {
        @AuraEnabled public Id     auditId     { get; set; }
        @AuraEnabled public String auditType   { get; set; }
        @AuraEnabled public String message     { get; set; }
        @AuraEnabled public String oldValue    { get; set; }
        @AuraEnabled public String newValue    { get; set; }
        @AuraEnabled public String performedBy { get; set; }
        @AuraEnabled public String performedOn { get; set; }
    }

    // ── Stage Move ────────────────────────────────────────────────────────────

    /** Result of a single lead stage move. */
    public class MoveResult {
        @AuraEnabled public Id      leadId    { get; set; }
        @AuraEnabled public Boolean success   { get; set; }
        @AuraEnabled public String  message   { get; set; }
        @AuraEnabled public String  newStage  { get; set; }

        public MoveResult(Id leadId, Boolean success, String message, String newStage) {
            this.leadId   = leadId;
            this.success  = success;
            this.message  = message;
            this.newStage = newStage;
        }
    }

    /** Request payload for a bulk stage move. */
    public class StageMoveRequest {
        @AuraEnabled public List<Id> leadIds  { get; set; }
        @AuraEnabled public String   stageKey { get; set; }
        @AuraEnabled public String   reason   { get; set; }
    }

    // ── Pipeline Stage ────────────────────────────────────────────────────────

    /** Lightweight stage descriptor for dropdowns and navigation. */
    public class StageOption {
        @AuraEnabled public String  stageKey   { get; set; }
        @AuraEnabled public String  stageLabel { get; set; }
        @AuraEnabled public Integer sequence   { get; set; }
        @AuraEnabled public String  color      { get; set; }
        @AuraEnabled public Boolean isClosed   { get; set; }
    }
}
