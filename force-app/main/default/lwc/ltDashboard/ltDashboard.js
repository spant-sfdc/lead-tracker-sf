import { LightningElement, track } from 'lwc';
import getDashboardData from '@salesforce/apex/LeadController.getDashboardData';

export default class LtDashboard extends LightningElement {
    @track data         = null;
    @track isLoading    = true;
    @track errorMessage = '';

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    connectedCallback() {
        this._load();
    }

    // ── Data ──────────────────────────────────────────────────────────────────

    async _load() {
        this.isLoading    = true;
        this.errorMessage = '';
        try {
            const raw = await getDashboardData();
            this.data = {
                ...raw,
                stageMetrics: (raw.stageMetrics || []).map(sm => ({
                    ...sm,
                    dotStyle: `background-color:${sm.color || '#706E6B'}`,
                    barStyle: `width:${sm.percentage || 0}%;background-color:${sm.color || '#706E6B'}`
                })),
                pipelineMetrics: (raw.pipelineMetrics || []).map(pm => ({
                    ...pm,
                    pipelineBarStyle: `width:${pm.percentage || 0}%`
                }))
            };
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load analytics.';
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this._load();
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError() {
        return !this.isLoading && !!this.errorMessage;
    }

    get noStageData() {
        return !this.data?.stageMetrics?.length;
    }

    get noPipelineData() {
        return !this.data?.pipelineMetrics?.length;
    }

    get refreshedAtDisplay() {
        if (!this.data?.refreshedAt) return '';
        try {
            const d = new Date(this.data.refreshedAt.replace(' ', 'T'));
            return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch (e) {
            return '';
        }
    }

    get conversionRateDisplay() {
        return this.data ? `${this.data.conversionRate}%` : '—';
    }

    get conversionRateSublabel() {
        return this.data ? `${this.data.convertedLeads} converted` : '';
    }

    // ── Health bar styles ─────────────────────────────────────────────────────

    _pct(count) {
        const total = this.data?.totalLeads || 0;
        if (!total) return 0;
        return Math.round((count / total) * 100);
    }

    get healthyBarStyle()  { return `width:${this._pct(this.data?.healthyLeads  || 0)}%`; }
    get atRiskBarStyle()   { return `width:${this._pct(this.data?.atRiskLeads   || 0)}%`; }
    get criticalBarStyle() { return `width:${this._pct(this.data?.criticalLeads || 0)}%`; }

    get healthyPct()  { return this._pct(this.data?.healthyLeads  || 0); }
    get atRiskPct()   { return this._pct(this.data?.atRiskLeads   || 0); }
    get criticalPct() { return this._pct(this.data?.criticalLeads || 0); }

    get avgScoreStyle() {
        const score = Math.min(this.data?.avgEngagementScore || 0, 100);
        return `width:${score}%`;
    }
}
