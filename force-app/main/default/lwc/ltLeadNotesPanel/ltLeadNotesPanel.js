import { LightningElement, api, track } from 'lwc';
import { formatDate } from 'c/ltBase';
import getLeadNotes from '@salesforce/apex/LeadController.getLeadNotes';
import addNote     from '@salesforce/apex/LeadController.addNote';

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
                relativeTime: this._relativeTime(n.CreatedDate)
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
            await this.handleLoad();
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to save note.';
        } finally {
            this.isSaving = false;
        }
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    _relativeTime(dateString) {
        if (!dateString) return '';
        const ms   = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(ms / 60000);
        if (mins < 1)  return 'just now';
        if (mins < 60) return `${mins}m ago`;
        const hrs = Math.floor(mins / 60);
        if (hrs  < 24) return `${hrs}h ago`;
        const days = Math.floor(hrs / 24);
        if (days < 7)  return `${days}d ago`;
        return formatDate(dateString);
    }
}
