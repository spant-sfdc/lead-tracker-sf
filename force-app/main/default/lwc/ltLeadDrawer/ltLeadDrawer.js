import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const HEALTH_CSS = {
    'Healthy':  'ld-pill ld-health--healthy',
    'At Risk':  'ld-pill ld-health--at-risk',
    'Critical': 'ld-pill ld-health--critical'
};

const TAB_DEFS = [
    { id: 'timeline',   label: 'Timeline' },
    { id: 'details',    label: 'Details' },
    { id: 'activities', label: 'Activities' },
    { id: 'notes',      label: 'Notes' },
    { id: 'files',      label: 'Files' }
];

export default class LtLeadDrawer extends NavigationMixin(LightningElement) {
    @api card = {};
    @api leadId;
    @track activeTab = 'timeline';

    _panelFocused = false;
    _handleDocKeyDown = (event) => {
        if (event.key === 'Escape') this.handleClose();
    };

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    connectedCallback() {
        document.addEventListener('keydown', this._handleDocKeyDown);
    }

    disconnectedCallback() {
        document.removeEventListener('keydown', this._handleDocKeyDown);
    }

    renderedCallback() {
        if (!this._panelFocused) {
            const closeBtn = this.template.querySelector('.ld-icon-btn');
            if (closeBtn) { closeBtn.focus(); this._panelFocused = true; }
        }
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get leadName()    { return this.card && this.card.name    || ''; }
    get leadCompany() { return this.card && this.card.company || ''; }
    get leadHealth()  { return this.card && this.card.leadHealth || ''; }
    get isStale()     { return !!(this.card && this.card.isStale); }

    get healthClass() {
        return HEALTH_CSS[this.leadHealth] || 'ld-pill';
    }

    get tabs() {
        return TAB_DEFS.map(t => ({
            ...t,
            isActive: this.activeTab === t.id,
            cssClass: 'ld-tab' + (this.activeTab === t.id ? ' ld-tab--active' : '')
        }));
    }

    get isTimeline()   { return this.activeTab === 'timeline'; }
    get isDetails()    { return this.activeTab === 'details'; }
    get isActivities() { return this.activeTab === 'activities'; }
    get isNotes()      { return this.activeTab === 'notes'; }
    get isFiles()      { return this.activeTab === 'files'; }

    // ── Handlers ──────────────────────────────────────────────────────────────

    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('drawerclose', { bubbles: true, composed: true }));
    }

    handleOpenRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.leadId, objectApiName: 'Lead', actionName: 'view' }
        });
    }
}
