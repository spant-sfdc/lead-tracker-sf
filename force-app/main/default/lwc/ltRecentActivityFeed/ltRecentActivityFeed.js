import { LightningElement, track } from 'lwc';
import { relativeTime } from 'c/ltBase';
import getActivityFeed from '@salesforce/apex/LeadController.getActivityFeed';

const TYPE_META = {
    'Stage Change':   { icon: 'utility:forward',      bg: '#E8F0FE', color: '#1B3A6B' },
    'Lead Created':   { icon: 'utility:new',           bg: '#E8F5E9', color: '#2E7D32' },
    'Stale Flagged':  { icon: 'utility:warning',       bg: '#FFF3E0', color: '#E65100' },
    'Stale Cleared':  { icon: 'utility:check',         bg: '#E8F5E9', color: '#2E7D32' },
    'Health Update':  { icon: 'utility:heart',         bg: '#FCE4EC', color: '#C23934' },
    'Field Update':   { icon: 'utility:edit',          bg: '#F3E5F5', color: '#7B1FA2' },
    'Status Update':  { icon: 'utility:rotate',        bg: '#E0F7FA', color: '#00695C' },
    'Owner Change':   { icon: 'utility:user',          bg: '#FFF8E1', color: '#F57F17' },
    _default:         { icon: 'utility:activity',      bg: '#F4F5F8', color: '#706E6B' }
};

function groupByDay(entries) {
    const today     = new Date(); today.setHours(0,0,0,0);
    const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
    const thisWeek  = new Date(today); thisWeek.setDate(today.getDate() - 7);
    const groups    = [];
    const buckets   = { Today: [], Yesterday: [], 'This Week': [], Earlier: [] };

    for (const e of entries) {
        const d = new Date(e.performedOn); d.setHours(0,0,0,0);
        if      (d >= today)     buckets['Today'].push(e);
        else if (d >= yesterday) buckets['Yesterday'].push(e);
        else if (d >= thisWeek)  buckets['This Week'].push(e);
        else                     buckets['Earlier'].push(e);
    }
    for (const label of ['Today', 'Yesterday', 'This Week', 'Earlier']) {
        if (buckets[label].length) groups.push({ label, entries: buckets[label] });
    }
    return groups;
}

export default class LtRecentActivityFeed extends LightningElement {
    @track groups      = [];
    @track isLoading   = true;
    @track hasError    = false;
    @track errorMessage = '';

    connectedCallback() {
        this.loadFeed();
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.groups.length === 0;
    }

    async loadFeed() {
        this.isLoading = true;
        this.hasError  = false;
        try {
            const raw = await getActivityFeed({ maxRecords: 30 });
            const entries = (raw || []).map(e => {
                const meta = TYPE_META[e.auditType] || TYPE_META._default;
                return {
                    ...e,
                    icon:         meta.icon,
                    iconStyle:    `background:${meta.bg};color:${meta.color}`,
                    relativeTime: relativeTime(e.performedOn)
                };
            });
            this.groups = groupByDay(entries);
        } catch (e) {
            this.hasError     = true;
            this.errorMessage = e.body?.message || 'Failed to load activity feed.';
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.loadFeed();
    }

    handleLeadClick(event) {
        const leadId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('leadopen', {
            detail: { leadId },
            bubbles: true,
            composed: true
        }));
    }
}
