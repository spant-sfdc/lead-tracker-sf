import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUpcomingTasks from '@salesforce/apex/LeadController.getUpcomingTasks';
import completeTask     from '@salesforce/apex/LeadController.completeTask';

const TYPE_ICONS = {
    Call:    'utility:call',
    Email:   'utility:email',
    Meeting: 'utility:event',
    _default:'utility:task'
};

export default class LtUpcomingTasks extends LightningElement {
    @track groups      = [];
    @track isLoading   = true;
    @track hasError    = false;
    @track errorMessage = '';

    connectedCallback() {
        this.loadTasks();
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.groups.length === 0;
    }

    async loadTasks() {
        this.isLoading = true;
        this.hasError  = false;
        try {
            const raw   = await getUpcomingTasks();
            const tasks = (raw || []).map(t => {
                let dueDateLabel = t.activityDate
                    ? new Date(t.activityDate + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
                    : 'No date';
                if (t.isDueToday) dueDateLabel = 'Today';
                if (t.isOverdue)  dueDateLabel = `Overdue · ${dueDateLabel}`;
                return {
                    ...t,
                    typeIcon:     TYPE_ICONS[t.type] || TYPE_ICONS._default,
                    dueDateLabel,
                    itemClass:    `ut-task${t.isOverdue ? ' ut-task--overdue' : t.isDueToday ? ' ut-task--today' : ''}`
                };
            });

            const overdue  = tasks.filter(t => t.isOverdue);
            const today    = tasks.filter(t => !t.isOverdue && t.isDueToday);
            const upcoming = tasks.filter(t => !t.isOverdue && !t.isDueToday);
            const groups   = [];
            if (overdue.length)  groups.push({ label: 'Overdue',  tasks: overdue  });
            if (today.length)    groups.push({ label: 'Today',    tasks: today    });
            if (upcoming.length) groups.push({ label: 'Upcoming', tasks: upcoming });
            this.groups = groups;
        } catch (e) {
            this.hasError    = true;
            this.errorMessage = e.body?.message || 'Failed to load tasks.';
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.loadTasks();
    }

    async handleComplete(event) {
        const taskId = event.currentTarget.dataset.id;
        try {
            await completeTask({ taskId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Task completed', variant: 'success' }));
            this.loadTasks();
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: e.body?.message || 'Could not complete task.', variant: 'error'
            }));
        }
    }

    handleLeadClick(event) {
        const leadId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('leadopen', {
            detail: { leadId }, bubbles: true, composed: true
        }));
    }
}
