import { LightningElement, api, track } from 'lwc';

export default class LtKanbanColumn extends LightningElement {
    @api column = {};
    @api stageOptions = [];
    @track isDragOver = false;

    _dragCounter = 0;

    // ── Computed ──────────────────────────────────────────────────────────────

    get columnClass() {
        return 'kc-column' + (this.isDragOver ? ' kc-column--drag-over' : '');
    }

    get headerAccentStyle() {
        const color = (this.column && this.column.color) || '#0176D3';
        return `border-bottom-color: ${color}`;
    }

    get dropHintStyle() {
        const color = (this.column && this.column.color) || '#1B3A6B';
        return `border-color: ${color}; background: ${color}1A`;
    }

    get isEmpty() {
        return !this.column || !this.column.leads || this.column.leads.length === 0;
    }

    // ── Drag & Drop ───────────────────────────────────────────────────────────

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDragEnter(event) {
        event.preventDefault();
        this._dragCounter++;
        this.isDragOver = true;
    }

    handleDragLeave() {
        this._dragCounter--;
        if (this._dragCounter <= 0) {
            this._dragCounter = 0;
            this.isDragOver = false;
        }
    }

    handleDrop(event) {
        event.preventDefault();
        this._dragCounter = 0;
        this.isDragOver = false;

        try {
            const data = JSON.parse(event.dataTransfer.getData('text/plain'));
            const { leadId, fromStageKey } = data;
            const toStageKey = this.column && this.column.stageKey;
            if (leadId && toStageKey && fromStageKey !== toStageKey) {
                this.dispatchEvent(
                    new CustomEvent('leadmove', {
                        bubbles: true,
                        composed: true,
                        detail: { leadId, fromStageKey, toStageKey }
                    })
                );
            }
        } catch (e) {
            // Ignore malformed drag data
        }
    }
}
