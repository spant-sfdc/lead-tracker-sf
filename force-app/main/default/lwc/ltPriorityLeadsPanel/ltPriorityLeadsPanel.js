import { LightningElement, track } from 'lwc';
import getPriorityLeads from '@salesforce/apex/LeadController.getPriorityLeads';

const HEALTH_COLORS = {
    Critical: '#C23934',
    'At Risk': '#E65100',
    Healthy:   '#2E7D32'
};

export default class LtPriorityLeadsPanel extends LightningElement {
    @track leads       = [];
    @track isLoading   = true;
    @track hasError    = false;
    @track errorMessage = '';

    connectedCallback() {
        this.loadLeads();
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.leads.length === 0;
    }

    async loadLeads() {
        this.isLoading  = true;
        this.hasError   = false;
        try {
            const raw = await getPriorityLeads();
            this.leads = (raw || []).map(l => ({
                ...l,
                isCritical:    l.leadHealth === 'Critical',
                isOverdue:     !!l.nextFollowUp && new Date(l.nextFollowUp) < new Date(),
                healthBarStyle: `background-color:${HEALTH_COLORS[l.leadHealth] || '#706E6B'}`
            }));
        } catch (e) {
            this.hasError    = true;
            this.errorMessage = e.body?.message || 'Failed to load priority leads.';
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.loadLeads();
    }

    handleLeadClick(event) {
        const leadId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('leadopen', {
            detail: { leadId },
            bubbles: true,
            composed: true
        }));
    }

    handleLeadKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        }
    }
}
