/**
 * Aggregates board data for the pipeline kanban view.
 * Combines CMT stage definitions with live lead data into BoardData DTOs.
 * No SOQL inside loops — all data is fetched upfront via selectors.
 */
public with sharing class PipelineService {

    // ── Dependencies ──────────────────────────────────────────────────────────

    private LeadSelector          leadSelector;
    private PipelineStageSelector stageSelector;

    public PipelineService() {
        this.leadSelector  = new LeadSelector();
        this.stageSelector = new PipelineStageSelector();
    }

    // ── Board assembly ────────────────────────────────────────────────────────

    /**
     * Assembles the full BoardData payload for the default pipeline type.
     * Fetches stages and leads with two SOQL queries, then builds DTOs in memory.
     */
    public LeadTrackerDTO.BoardData getBoardData() {
        Application_Config__mdt cfg = stageSelector.getDefaultAppConfig();
        String pipelineType = (cfg != null && String.isNotBlank(cfg.Default_Pipeline__c))
                              ? cfg.Default_Pipeline__c
                              : 'Nonprofit';
        return getBoardDataByPipelineType(pipelineType, cfg);
    }

    /**
     * Assembles BoardData for a specific pipeline type.
     */
    public LeadTrackerDTO.BoardData getBoardDataByPipelineType(String pipelineType) {
        Application_Config__mdt cfg = stageSelector.getDefaultAppConfig();
        return getBoardDataByPipelineType(pipelineType, cfg);
    }

    // ── Stage options ─────────────────────────────────────────────────────────

    /**
     * Returns a flat list of StageOption DTOs for a pipeline type.
     * Used by move-to-stage dropdowns in LWC.
     */
    public List<LeadTrackerDTO.StageOption> getStageOptions(String pipelineType) {
        List<Pipeline_Stage__mdt> stages = String.isBlank(pipelineType)
            ? stageSelector.getAllActiveStages()
            : stageSelector.getActiveStagesByPipelineType(pipelineType);

        List<LeadTrackerDTO.StageOption> options = new List<LeadTrackerDTO.StageOption>();
        for (Pipeline_Stage__mdt s : stages) {
            LeadTrackerDTO.StageOption opt = new LeadTrackerDTO.StageOption();
            opt.stageKey   = s.Stage_Key__c;
            opt.stageLabel = s.Stage_Label__c;
            opt.sequence   = s.Sequence__c != null ? Integer.valueOf(s.Sequence__c) : 0;
            opt.color      = s.Color__c;
            opt.isClosed   = s.Is_Closed__c;
            options.add(opt);
        }
        return options;
    }

    // ── App config ────────────────────────────────────────────────────────────

    /**
     * Returns AppConfigData DTO from the Default Application_Config__mdt record.
     */
    public LeadTrackerDTO.AppConfigData getAppConfigData() {
        Application_Config__mdt cfg = stageSelector.getDefaultAppConfig();
        return buildAppConfigData(cfg);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private LeadTrackerDTO.BoardData getBoardDataByPipelineType(String pipelineType,
                                                                 Application_Config__mdt cfg) {
        LeadTrackerDTO.BoardData board = new LeadTrackerDTO.BoardData();
        board.config = buildAppConfigData(cfg);

        // Fetch stages and leads — two queries, nothing inside loops
        List<Pipeline_Stage__mdt> stages = stageSelector.getActiveStagesByPipelineType(pipelineType);
        List<Lead> leads = leadSelector.getBoardLeadsByPipelineType(pipelineType);

        // Index leads by stage key
        Map<String, List<Lead>> leadsByStage = new Map<String, List<Lead>>();
        Integer staleCount = 0;
        for (Lead l : leads) {
            String key = String.isBlank(l.Current_Stage__c) ? '__unassigned__' : l.Current_Stage__c;
            if (!leadsByStage.containsKey(key)) {
                leadsByStage.put(key, new List<Lead>());
            }
            leadsByStage.get(key).add(l);
            if (l.Is_Stale__c == true) {
                staleCount++;
            }
        }

        // Build stage columns
        for (Pipeline_Stage__mdt s : stages) {
            LeadTrackerDTO.StageColumn col = buildStageColumn(s, leadsByStage);
            board.stages.add(col);
            board.totalLeads += col.leadCount;
        }

        board.staleCount    = staleCount;
        board.lastRefreshed = String.valueOf(System.now());
        return board;
    }

    private LeadTrackerDTO.StageColumn buildStageColumn(Pipeline_Stage__mdt stage,
                                                         Map<String, List<Lead>> leadsByStage) {
        LeadTrackerDTO.StageColumn col = new LeadTrackerDTO.StageColumn();
        col.stageKey   = stage.Stage_Key__c;
        col.stageLabel = stage.Stage_Label__c;
        col.sequence   = stage.Sequence__c != null ? Integer.valueOf(stage.Sequence__c) : 0;
        col.color      = stage.Color__c;
        col.icon       = stage.Icon__c;
        col.isClosed   = stage.Is_Closed__c;
        col.isWon      = stage.Is_Won__c;
        col.slaDays    = stage.SLA_Days__c != null ? Integer.valueOf(stage.SLA_Days__c) : null;

        List<Lead> stageleads = leadsByStage.containsKey(stage.Stage_Key__c)
                                ? leadsByStage.get(stage.Stage_Key__c)
                                : new List<Lead>();
        for (Lead l : stageLeads) {
            col.leads.add(buildLeadCard(l, stage));
        }
        col.leadCount = col.leads.size();
        return col;
    }

    private LeadTrackerDTO.LeadCard buildLeadCard(Lead l, Pipeline_Stage__mdt stage) {
        LeadTrackerDTO.LeadCard card = new LeadTrackerDTO.LeadCard();
        card.leadId            = l.Id;
        card.name              = l.Name;
        card.company           = l.Company;
        card.email             = l.Email;
        card.phone             = l.Phone;
        card.currentStage      = l.Current_Stage__c;
        card.pipelineType      = l.Pipeline_Type__c;
        card.leadHealth        = l.Lead_Health__c;
        card.engagementScore   = l.Engagement_Score__c != null ? Integer.valueOf(l.Engagement_Score__c) : 0;
        card.isStale           = l.Is_Stale__c;
        card.nextFollowUp      = l.Next_Follow_Up__c != null ? String.valueOf(l.Next_Follow_Up__c) : null;
        card.lastActivityDate  = l.Last_Activity_Date__c != null ? String.valueOf(l.Last_Activity_Date__c) : null;
        card.ownerName         = l.Owner != null ? l.Owner.Name : null;
        card.organizationSize  = l.Organization_Size__c;
        card.currentCrm        = l.Current_CRM__c;
        card.fundingModel      = l.Funding_Model__c;
        card.primaryStakeholder = l.Primary_Stakeholder__c;
        card.badges            = buildBadges(l, stage);
        return card;
    }

    private List<String> buildBadges(Lead l, Pipeline_Stage__mdt stage) {
        List<String> badges = new List<String>();
        if (l.Is_Stale__c == true) {
            badges.add('Stale');
        }
        if (l.Next_Follow_Up__c != null && l.Next_Follow_Up__c <= Date.today()) {
            badges.add('Follow-Up Due');
        }
        if (l.Lead_Health__c == 'Critical' && l.Is_Stale__c != true) {
            badges.add('Critical');
        }
        if (l.Engagement_Score__c != null && l.Engagement_Score__c >= 80) {
            badges.add('High Engagement');
        }
        return badges;
    }

    private LeadTrackerDTO.AppConfigData buildAppConfigData(Application_Config__mdt cfg) {
        LeadTrackerDTO.AppConfigData data = new LeadTrackerDTO.AppConfigData();
        if (cfg == null) {
            data.companyName             = 'Lead Tracker';
            data.themeColor              = '#0070d2';
            data.defaultPipeline         = 'Nonprofit';
            data.cardDensity             = 'comfortable';
            data.autoRefreshInterval     = 300;
            data.dashboardRefreshMinutes = 5;
            data.emptyStateMessage       = 'No leads found in this stage.';
            return data;
        }
        data.companyName             = cfg.Company_Name__c;
        data.themeColor              = cfg.Theme_Color__c;
        data.defaultPipeline         = cfg.Default_Pipeline__c;
        data.cardDensity             = cfg.Card_Density__c;
        data.autoRefreshInterval     = cfg.Auto_Refresh_Interval__c != null
                                       ? Integer.valueOf(cfg.Auto_Refresh_Interval__c) : 300;
        data.dashboardRefreshMinutes = cfg.Dashboard_Refresh_Minutes__c != null
                                       ? Integer.valueOf(cfg.Dashboard_Refresh_Minutes__c) : 5;
        data.emptyStateMessage       = cfg.Empty_State_Message__c;
        return data;
    }
}
