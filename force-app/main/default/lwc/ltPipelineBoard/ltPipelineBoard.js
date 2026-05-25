import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LT_Loading from '@salesforce/label/c.LT_Loading';
import LT_No_Leads_Found from '@salesforce/label/c.LT_No_Leads_Found';
import LT_Error_Generic from '@salesforce/label/c.LT_Error_Generic';
import getPipelineStages from '@salesforce/apex/LeadTrackerController.getPipelineStages';
import getBoardLeads from '@salesforce/apex/LeadTrackerController.getBoardLeads';

export default class LtPipelineBoard extends LightningElement {
    label = { LT_Loading, LT_No_Leads_Found, LT_Error_Generic };

    @track _stages = [];
    @track _leads = [];
    _stagesLoaded = false;
    _leadsLoaded = false;
    errorMessage;

    @wire(getPipelineStages)
    wiredStages({ data, error }) {
        if (data) {
            this._stages = data;
            this._stagesLoaded = true;
        } else if (error) {
            this.errorMessage = error?.body?.message || this.label.LT_Error_Generic;
            this._stagesLoaded = true;
        }
    }

    @wire(getBoardLeads)
    wiredLeads({ data, error }) {
        if (data) {
            this._leads = data;
            this._leadsLoaded = true;
        } else if (error) {
            this.errorMessage = error?.body?.message || this.label.LT_Error_Generic;
            this._leadsLoaded = true;
        }
    }

    get isLoading() {
        return !this._stagesLoaded || !this._leadsLoaded;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get pipelineColumns() {
        return this._stages.map((stage) => {
            const leads = this._leads.filter((l) => l.Status === stage.Stage_Name__c);
            return {
                ...stage,
                leads,
                cardCount: leads.length,
                hasLeads: leads.length > 0,
                headerStyle: `background-color: ${stage.Color_Hex__c || '#0176D3'}`
            };
        });
    }

    handleLeadMoved(event) {
        const { leadId, targetStatus } = event.detail;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Lead Moved',
                message: `Lead moved to ${targetStatus}`,
                variant: 'success'
            })
        );
        // Refresh wire adapters after mutation (Phase 2: add refreshApex)
        void leadId;
    }
}
