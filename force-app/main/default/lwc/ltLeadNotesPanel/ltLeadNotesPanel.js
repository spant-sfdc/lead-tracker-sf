import { LightningElement, api, track } from 'lwc';
import { relativeTime } from 'c/ltBase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeadNotes from '@salesforce/apex/LeadController.getLeadNotes';
import addNote      from '@salesforce/apex/LeadController.addNote';

export default class LtLeadNotesPanel extends LightningElement {
    @track notes = [];
    @track isLoading = false;
    @track isSaving  = false;
    @track errorMessage = '';
    @track draftBody = '';

    _leadId;

    @api
    get leadId() { return this._leadId; }
    set leadId(val) {
        this._leadId = val;
        if (val) this.handleLoad();
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError()        { return !this.isLoading && !!this.errorMessage; }
    get isEmpty()         { return !this.isLoading && !this.errorMessage && this.notes.length === 0; }
    get isSubmitDisabled(){ return this.isSaving || !this.draftBody.trim(); }

    // ── Load ──────────────────────────────────────────────────────────────────

    async handleLoad() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const raw = await getLeadNotes({ leadId: this._leadId });
            this.notes = (raw || []).map(n => ({
                ...n,
                ownerName:    n.Owner?.Name || '',
                relativeTime: relativeTime(n.CreatedDate)
            }));
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load notes.';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────────

    handleInput(event) {
        this.draftBody = event.target.value;
    }

    async handleAddNote() {
        const body = this.draftBody.trim();
        if (!body) return;
        this.isSaving = true;
        try {
            await addNote({ leadId: this._leadId, title: 'Note', body });
            this.draftBody = '';
            const textarea = this.template.querySelector('.np-textarea');
            if (textarea) textarea.value = '';
            this.dispatchEvent(new ShowToastEvent({ title: 'Note Saved', message: 'Your note has been added.', variant: 'success' }));
            await this.handleLoad();
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to save note.';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.errorMessage, variant: 'error' }));
        } finally {
            this.isSaving = false;
        }
    }
}
