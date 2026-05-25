import { LightningElement, api, track } from 'lwc';
import { formatDate } from 'c/ltBase';

const HEALTH_CSS = {
    'Healthy':  'lc-pill lc-health--healthy',
    'At Risk':  'lc-pill lc-health--at-risk',
    'Critical': 'lc-pill lc-health--critical'
};

const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;

export default class LtLeadCard extends LightningElement {
    @api card = {};
    @api stageOptions = [];
    @track showActions = false;
    @track isDragging = false;

    // ── Computed CSS ──────────────────────────────────────────────────────────

    get cardClass() {
        return 'lc-card' + (this.isDragging ? ' lc-card--dragging' : '');
    }

    get healthClass() {
        return HEALTH_CSS[this.card && this.card.leadHealth] || 'lc-pill lc-health--unknown';
    }

    get followUpClass() {
        const base = 'lc-meta-val';
        if (!this.card || !this.card.nextFollowUp) return base;
        const d = new Date(this.card.nextFollowUp);
        const now = Date.now();
        if (d.getTime() < now) return base + ' lc-meta-val--overdue';
        if (d.getTime() - now < THREE_DAYS_MS) return base + ' lc-meta-val--soon';
        return base;
    }

    // ── Derived values ────────────────────────────────────────────────────────

    get currentStageLabel() {
        if (!this.card || !this.stageOptions) return '';
        const opt = this.stageOptions.find(o => o.stageKey === this.card.currentStage);
        return opt ? opt.stageLabel : this.card.currentStage || '';
    }

    get formattedLastActivity() {
        return formatDate(this.card && this.card.lastActivityDate);
    }

    get formattedNextFollowUp() {
        return formatDate(this.card && this.card.nextFollowUp);
    }

    get hasScore() {
        return this.card && this.card.engagementScore != null && this.card.engagementScore > 0;
    }

    get scoreFillStyle() {
        const pct = Math.min(100, Math.max(0, this.card.engagementScore || 0));
        return `width: ${pct}%`;
    }

    get hasBadges() {
        return this.card && this.card.badges && this.card.badges.length > 0;
    }

    // ── Drag & Drop ───────────────────────────────────────────────────────────

    handleDragStart(event) {
        this.isDragging = true;
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData(
            'text/plain',
            JSON.stringify({ leadId: this.card.leadId, fromStageKey: this.card.currentStage })
        );
    }

    handleDragEnd() {
        this.isDragging = false;
    }

    // ── Interactions ──────────────────────────────────────────────────────────

    handleCardClick() {
        this.dispatchEvent(
            new CustomEvent('leadselect', {
                bubbles: true,
                composed: true,
                detail: { leadId: this.card.leadId }
            })
        );
    }

    handleActionToggle(event) {
        event.stopPropagation();
        this.showActions = !this.showActions;
        if (this.showActions) {
            // Close on any outside click after current event finishes
            setTimeout(() => {
                document.addEventListener('click', () => { this.showActions = false; }, { once: true });
            }, 0);
        }
    }

    handleQuickAction() {
        this.showActions = false;
        // Event continues bubbling (composed: true) to ltPipelineWorkspace
    }
}
