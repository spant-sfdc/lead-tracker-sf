import { LightningElement, api, track } from 'lwc';
import { relativeTime } from 'c/ltBase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeadTasks   from '@salesforce/apex/LeadController.getLeadTasks';
import logActivity    from '@salesforce/apex/LeadController.logActivity';

const TYPE_ICON = {
    Call:    { icon: 'utility:call',  color: '#0176D3' },
    Email:   { icon: 'utility:email', color: '#5867E8' },
    Meeting: { icon: 'utility:event', color: '#00875A' },
    Other:   { icon: 'utility:task',  color: '#706E6B' }
};

function deriveType(subject) {
    if (!subject) return 'Other';
    const s = subject.toLowerCase();
    if (s.includes('call')) return 'Call';
    if (s.includes('email') || s.includes('send')) return 'Email';
    if (s.includes('meeting') || s.includes('review')) return 'Meeting';
    return 'Other';
}

export default class LtLeadActivitiesPanel extends LightningElement {
    @track tasks = [];
    @track isLoading = false;
    @track isSaving  = false;
    @track errorMessage = '';

    _subject     = '';
    _type        = 'Call';
    _date        = '';
    _description = '';
    _leadId;

    @api
    get leadId() { return this._leadId; }
    set leadId(val) {
        this._leadId = val;
        if (val) this.loadTasks();
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError()    { return !this.isLoading && !!this.errorMessage; }
    get isEmpty()     { return !this.isLoading && !this.errorMessage && this.tasks.length === 0; }
    get isSaveDisabled() { return this.isSaving || !this._subject.trim(); }

    // ── Data ──────────────────────────────────────────────────────────────────

    async loadTasks() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const raw = await getLeadTasks({ leadId: this._leadId });
            this.tasks = (raw || []).map(t => {
                const cfg = TYPE_ICON[deriveType(t.Subject)];
                return {
                    ...t,
                    typeIcon:    cfg.icon,
                    typeStyle:   `background-color: ${cfg.color}1A; color: ${cfg.color}`,
                    ownerName:   t.Owner?.Name || '',
                    relativeTime: relativeTime(t.CreatedDate)
                };
            });
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load activities.';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Form handlers ─────────────────────────────────────────────────────────

    handleSubjectInput(event) { this._subject     = event.target.value; }
    handleTypeChange(event)   { this._type        = event.target.value; }
    handleDateChange(event)   { this._date        = event.target.value; }
    handleDescInput(event)    { this._description = event.target.value; }

    handleFormToggle() { /* native <details> handles open/close */ }

    handleFormCancel() {
        this._resetForm();
        const details = this.template.querySelector('.ap-log-form');
        if (details) details.removeAttribute('open');
    }

    async handleLogActivity() {
        if (!this._subject.trim()) return;
        this.isSaving = true;
        const subjectLabel = this._subject.trim();
        try {
            await logActivity({
                leadId:       this._leadId,
                subject:      subjectLabel,
                description:  this._description,
                type:         this._type,
                activityDate: this._date || null
            });
            this._resetForm();
            const details = this.template.querySelector('.ap-log-form');
            if (details) details.removeAttribute('open');
            this.dispatchEvent(new ShowToastEvent({ title: 'Activity Logged', message: `"${subjectLabel}" recorded successfully.`, variant: 'success' }));
            await this.loadTasks();
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to log activity.';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.errorMessage, variant: 'error' }));
        } finally {
            this.isSaving = false;
        }
    }

    _resetForm() {
        this._subject = ''; this._type = 'Call'; this._date = ''; this._description = '';
        ['#ap-subject', '#ap-date', '#ap-desc'].forEach(sel => {
            const el = this.template.querySelector(sel);
            if (el) el.value = '';
        });
        const sel = this.template.querySelector('#ap-type');
        if (sel) sel.value = 'Call';
    }

}
