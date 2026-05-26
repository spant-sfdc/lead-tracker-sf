import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBoardData from '@salesforce/apex/LeadController.getBoardData';
import moveLead from '@salesforce/apex/LeadController.moveLead';
import setLeadStale from '@salesforce/apex/LeadController.setLeadStale';

export default class LtPipelineWorkspace extends LightningElement {
    @track boardData = null;
    @track isLoading = true;
    @track errorMessage = '';
    @track _filterCriteria = { searchTerm: '', healthFilter: [], showStaleOnly: false };
    @track selectedLeadId = null;
    @track selectedCard   = null;

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    connectedCallback() {
        this._loadBoardData();
    }

    // ── Data loading ──────────────────────────────────────────────────────────

    async _loadBoardData() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            this.boardData = await getBoardData();
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load pipeline board.';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError() {
        return !this.isLoading && !!this.errorMessage;
    }

    get skeletonCols() {
        return [1, 2, 3, 4];
    }

    get stageOptions() {
        if (!this.boardData || !this.boardData.stages) return [];
        return this.boardData.stages.map(col => ({
            stageKey: col.stageKey,
            stageLabel: col.stageLabel,
            color: col.color,
            isClosed: col.isClosed,
            sequence: col.sequence
        }));
    }

    get filteredStages() {
        if (!this.boardData || !this.boardData.stages) return [];
        const { searchTerm, healthFilter, showStaleOnly } = this._filterCriteria;
        const search = (searchTerm || '').toLowerCase();
        const filterHealth = healthFilter && healthFilter.length > 0;

        return this.boardData.stages.map(col => {
            const filtered = (col.leads || []).filter(card => {
                if (search) {
                    const n = (card.name || '').toLowerCase();
                    const c = (card.company || '').toLowerCase();
                    if (!n.includes(search) && !c.includes(search)) return false;
                }
                if (filterHealth && !healthFilter.includes(card.leadHealth)) return false;
                if (showStaleOnly && !card.isStale) return false;
                return true;
            });
            return { ...col, leads: filtered, leadCount: filtered.length };
        });
    }

    // ── Event handlers ────────────────────────────────────────────────────────

    handleRefresh() {
        this._loadBoardData();
    }

    handleFilterChange(event) {
        this._filterCriteria = { ...event.detail };
    }

    handleLeadMove(event) {
        const { leadId, fromStageKey, toStageKey } = event.detail;
        this._performMove(leadId, fromStageKey, toStageKey);
    }

    handleQuickAction(event) {
        const { type, leadId, stageKey } = event.detail;
        if (type === 'move' && stageKey) {
            const fromStageKey = this._findLeadStageKey(leadId);
            if (fromStageKey && fromStageKey !== stageKey) {
                this._performMove(leadId, fromStageKey, stageKey);
            }
        } else if (type === 'markStale') {
            this._performSetStale(leadId, true);
        } else if (type === 'clearStale') {
            this._performSetStale(leadId, false);
        }
    }

    handleLeadSelect(event) {
        const { leadId } = event.detail;
        this.selectedLeadId = leadId;
        this.selectedCard   = this._findCard(leadId);
    }

    handleDrawerClose() {
        this.selectedLeadId = null;
        this.selectedCard   = null;
    }

    // ── Stage move (optimistic) ───────────────────────────────────────────────

    async _performMove(leadId, fromStageKey, toStageKey) {
        const snapshot = this._cloneBoard();
        this.boardData = this._optimisticMove(this.boardData, leadId, fromStageKey, toStageKey);

        try {
            const result = await moveLead({ leadId, stageKey: toStageKey });
            if (result && result.success === false) {
                this.boardData = snapshot;
                this._showToast('Move Failed', result.message || 'Stage move failed.', 'error');
            }
        } catch (e) {
            this.boardData = snapshot;
            this._showToast('Error', e.body?.message || 'Failed to move lead.', 'error');
        }
    }

    async _performSetStale(leadId, isStale) {
        const snapshot = this._cloneBoard();
        this.boardData = this._optimisticSetStale(this.boardData, leadId, isStale);

        try {
            await setLeadStale({ leadId, isStale });
        } catch (e) {
            this.boardData = snapshot;
            this._showToast('Error', e.body?.message || 'Failed to update stale flag.', 'error');
        }
    }

    // ── Board mutation helpers ────────────────────────────────────────────────

    _findCard(leadId) {
        if (!this.boardData || !this.boardData.stages) return {};
        for (const col of this.boardData.stages) {
            const card = (col.leads || []).find(c => c.leadId === leadId);
            if (card) return card;
        }
        return {};
    }

    _cloneBoard() {
        return JSON.parse(JSON.stringify(this.boardData));
    }

    _findLeadStageKey(leadId) {
        if (!this.boardData || !this.boardData.stages) return null;
        for (const col of this.boardData.stages) {
            if (col.leads && col.leads.some(c => c.leadId === leadId)) {
                return col.stageKey;
            }
        }
        return null;
    }

    _optimisticMove(data, leadId, fromStageKey, toStageKey) {
        let movedCard = null;
        const stages = data.stages.map(col => {
            if (col.stageKey === fromStageKey) {
                const newLeads = col.leads.filter(c => {
                    if (c.leadId === leadId) { movedCard = c; return false; }
                    return true;
                });
                return { ...col, leads: newLeads, leadCount: newLeads.length };
            }
            return col;
        });

        if (movedCard) {
            const updatedCard = { ...movedCard, currentStage: toStageKey };
            stages.forEach((col, i) => {
                if (col.stageKey === toStageKey) {
                    const newLeads = [...col.leads, updatedCard];
                    stages[i] = { ...col, leads: newLeads, leadCount: newLeads.length };
                }
            });
        }

        return { ...data, stages };
    }

    _optimisticSetStale(data, leadId, isStale) {
        const stages = data.stages.map(col => {
            const leads = col.leads.map(c =>
                c.leadId === leadId ? { ...c, isStale } : c
            );
            return { ...col, leads };
        });
        const staleCount = stages.reduce(
            (sum, col) => sum + col.leads.filter(c => c.isStale).length, 0
        );
        return { ...data, stages, staleCount };
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
