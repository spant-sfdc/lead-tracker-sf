import { LightningElement, api } from 'lwc';

export default class LtQuickActions extends LightningElement {
    @api card = {};
    @api stageOptions = [];

    get filteredStageOptions() {
        const currentKey = this.card && this.card.currentStage;
        return (this.stageOptions || [])
            .filter(o => o.stageKey !== currentKey)
            .map(o => ({
                stageKey: o.stageKey,
                stageLabel: o.stageLabel,
                dotStyle: `background-color: ${o.color || '#0176D3'}`
            }));
    }

    get hasStageOptions() {
        return this.filteredStageOptions.length > 0;
    }

    get isStale() {
        return !!(this.card && this.card.isStale);
    }

    handleItemKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        } else if (event.key === 'Escape') {
            this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        }
    }

    handleStageMove(event) {
        this._emit('move', { stageKey: event.currentTarget.dataset.key });
    }

    handleMarkStale() {
        this._emit('markStale', {});
    }

    handleClearStale() {
        this._emit('clearStale', {});
    }

    _emit(type, payload) {
        this.dispatchEvent(
            new CustomEvent('quickaction', {
                bubbles: true,
                composed: true,
                detail: { type, leadId: this.card && this.card.leadId, ...payload }
            })
        );
    }
}
