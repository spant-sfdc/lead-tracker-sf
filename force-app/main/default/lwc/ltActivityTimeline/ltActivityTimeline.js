import { LightningElement, api, track } from 'lwc';
import { formatDate } from 'c/ltBase';
import getLeadTimeline from '@salesforce/apex/LeadController.getLeadTimeline';

const TYPE_CONFIG = {
    'Stage Change':   { icon: 'utility:stage',               color: '#0176D3' },
    'Field Update':   { icon: 'utility:edit',                color: '#706E6B' },
    'Status Update':  { icon: 'utility:change_record_type',  color: '#706E6B' },
    'Stale Flagged':  { icon: 'utility:clock',               color: '#B75000' },
    'Stale Cleared':  { icon: 'utility:check',               color: '#00875A' },
    'Health Update':  { icon: 'utility:activity',            color: '#0176D3' },
    'Owner Change':   { icon: 'utility:user',                color: '#706E6B' },
    'Lead Created':   { icon: 'utility:new',                 color: '#00875A' },
    'Score Update':   { icon: 'utility:metrics',             color: '#0176D3' }
};
const DEFAULT_CONFIG = { icon: 'utility:record', color: '#706E6B' };

export default class LtActivityTimeline extends LightningElement {
    @track _entries = [];
    @track isLoading = false;
    @track errorMessage = '';

    _leadId;

    @api
    get leadId() { return this._leadId; }
    set leadId(val) {
        this._leadId = val;
        if (val) this._load();
    }

    // ── Load ──────────────────────────────────────────────────────────────────

    async _load() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const raw = await getLeadTimeline({ leadId: this._leadId });
            this._entries = (raw || []).map(e => this._enrichEntry(e));
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load timeline.';
        } finally {
            this.isLoading = false;
        }
    }

    _enrichEntry(e) {
        const cfg = TYPE_CONFIG[e.auditType] || DEFAULT_CONFIG;
        return {
            ...e,
            icon:       cfg.icon,
            iconStyle:  `background-color: ${cfg.color}1A; color: ${cfg.color}`,
            relativeTime: this._relativeTime(e.performedOn),
            hasValues:  !!(e.oldValue || e.newValue)
        };
    }

    _relativeTime(dateString) {
        if (!dateString) return '';
        const ms = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(ms / 60000);
        if (mins < 1)  return 'just now';
        if (mins < 60) return `${mins}m ago`;
        const hrs = Math.floor(mins / 60);
        if (hrs  < 24) return `${hrs}h ago`;
        const days = Math.floor(hrs / 24);
        if (days < 7)  return `${days}d ago`;
        return formatDate(dateString);
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError() { return !this.isLoading && !!this.errorMessage; }
    get isEmpty()  { return !this.isLoading && !this.errorMessage && this._entries.length === 0; }
    get entryCount() { return this._entries.length; }

    get groupedEntries() {
        const today     = new Date().toDateString();
        const yesterday = new Date(Date.now() - 86400000).toDateString();
        const map       = {};
        const order     = [];

        for (const e of this._entries) {
            const d = e.performedOn ? new Date(e.performedOn) : new Date();
            let label;
            if (d.toDateString() === today)     label = 'Today';
            else if (d.toDateString() === yesterday) label = 'Yesterday';
            else label = formatDate(e.performedOn);

            if (!map[label]) { map[label] = []; order.push(label); }
            map[label].push(e);
        }

        return order.map(label => ({ label, entries: map[label] }));
    }

    // ── Handlers ──────────────────────────────────────────────────────────────

    handleRetry() { this._load(); }
}
