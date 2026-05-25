import { LightningElement, api } from 'lwc';
import { formatDate } from 'c/ltBase';

const RATING_ICON_MAP = {
    Hot: 'utility:fire',
    Warm: 'utility:trending_up',
    Cold: 'utility:frozen'
};

export default class LtLeadCard extends LightningElement {
    @api lead = {};

    get formattedDate() {
        return formatDate(this.lead?.LastModifiedDate);
    }

    get ratingIcon() {
        return RATING_ICON_MAP[this.lead?.Rating] || 'standard:lead';
    }

    handleClick() {
        this.dispatchEvent(
            new CustomEvent('leadselect', {
                bubbles: true,
                composed: true,
                detail: { leadId: this.lead.Id }
            })
        );
    }
}
