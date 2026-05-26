import { LightningElement, api } from 'lwc';

export default class LtPipelineOverview extends LightningElement {
    @api stageMetrics   = [];
    @api totalLeads     = 0;
    @api healthyLeads   = 0;
    @api atRiskLeads    = 0;
    @api criticalLeads  = 0;
    @api conversionRate = 0;

    get hasMetrics() {
        return this.stageMetrics && this.stageMetrics.length > 0;
    }

    get enrichedMetrics() {
        return (this.stageMetrics || []).map(m => ({
            ...m,
            barStyle: `width:${Math.max(m.percentage || 0, 2)}%;background-color:${m.color || '#706E6B'}`
        }));
    }

    get _total() { return this.totalLeads || 0; }

    get healthyPct()  { return this._total > 0 ? Math.round((this.healthyLeads  / this._total) * 100) : 0; }
    get atRiskPct()   { return this._total > 0 ? Math.round((this.atRiskLeads   / this._total) * 100) : 0; }
    get criticalPct() { return this._total > 0 ? Math.round((this.criticalLeads / this._total) * 100) : 0; }

    get healthyBarStyle()  { return `width:${this.healthyPct}%`; }
    get atRiskBarStyle()   { return `width:${this.atRiskPct}%`; }
    get criticalBarStyle() { return `width:${this.criticalPct}%`; }

    get healthyLabel()  { return `${this.healthyLeads} Healthy (${this.healthyPct}%)`; }
    get atRiskLabel()   { return `${this.atRiskLeads} At Risk (${this.atRiskPct}%)`; }
    get criticalLabel() { return `${this.criticalLeads} Critical (${this.criticalPct}%)`; }
}
