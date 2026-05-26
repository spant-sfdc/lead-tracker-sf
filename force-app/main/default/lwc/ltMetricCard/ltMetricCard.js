import { LightningElement, api } from 'lwc';

export default class LtMetricCard extends LightningElement {
    @api value    = '—';
    @api label    = '';
    @api icon     = 'utility:metrics';
    @api sublabel = '';
    @api variant  = 'default'; // default | success | warning | danger

    get cardClass() {
        return `mc-card mc-card--${this.variant || 'default'}`;
    }
}
