import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAppConfig      from '@salesforce/apex/LeadController.getAppConfig';
import getDashboardData  from '@salesforce/apex/LeadController.getDashboardData';

const EMPTY_DASHBOARD = {
    openLeads: 0, staleLeads: 0, conversionRate: 0, overdueFollowUps: 0,
    activitiesThisWeek: 0, avgEngagementScore: 0, totalLeads: 0,
    healthyLeads: 0, atRiskLeads: 0, criticalLeads: 0,
    stageMetrics: [], pipelineMetrics: []
};

export default class LtHomeWorkspace extends NavigationMixin(LightningElement) {
    @track dashboardData = EMPTY_DASHBOARD;
    @track isKpiLoading  = true;
    @track searchTerm    = '';
    @track refreshedAt   = '';

    _appName = 'Lead Tracker';

    @wire(getAppConfig)
    wiredConfig({ data }) {
        if (data && data.companyName) this._appName = data.companyName;
    }

    get appName() { return this._appName; }

    get kpi() {
        const d = this.dashboardData;
        return {
            openLeads:          d.openLeads          || 0,
            staleLeads:         d.staleLeads          || 0,
            conversionPct:      `${d.conversionRate   || 0}%`,
            overdueFollowUps:   d.overdueFollowUps    || 0,
            activitiesThisWeek: d.activitiesThisWeek  || 0,
            avgScore:           d.avgEngagementScore  || 0
        };
    }

    get staleVariant()   { return (this.dashboardData.staleLeads   || 0) > 0 ? 'warning' : 'default'; }
    get overdueVariant() { return (this.dashboardData.overdueFollowUps || 0) > 0 ? 'danger'  : 'default'; }

    connectedCallback() {
        this.loadDashboard();
    }

    async loadDashboard() {
        this.isKpiLoading = true;
        try {
            this.dashboardData = await getDashboardData();
            const ts = this.dashboardData.refreshedAt
                ? new Date(this.dashboardData.refreshedAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
                : '';
            this.refreshedAt = ts ? `Updated ${ts}` : '';
        } catch (e) {
            this.dashboardData = EMPTY_DASHBOARD;
        } finally {
            this.isKpiLoading = false;
        }
    }

    handleRefresh() {
        this.loadDashboard();
        // Trigger child panel refreshes via re-rendering (they have their own refresh buttons)
        // Dispatch a custom event for child panels to pick up if needed
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleCreateLead() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Lead', actionName: 'new' }
        });
    }

    handleLeadOpen(event) {
        const { leadId } = event.detail;
        if (!leadId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: leadId, objectApiName: 'Lead', actionName: 'view' }
        });
    }
}
