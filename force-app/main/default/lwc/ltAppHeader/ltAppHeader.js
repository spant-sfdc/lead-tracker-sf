import { LightningElement, api, wire } from 'lwc';
import LT_App_Title from '@salesforce/label/c.LT_App_Title';
import getAppConfig from '@salesforce/apex/LeadTrackerController.getAppConfig';

export default class LtAppHeader extends LightningElement {
    @api overrideTitle;

    label = { LT_App_Title };
    _primaryColor = '#032D60';

    @wire(getAppConfig)
    wiredConfig({ data }) {
        if (data) {
            this._primaryColor = data.Primary_Color__c || '#032D60';
            this.applyBrandColor();
        }
    }

    get appTitle() {
        return this.overrideTitle || this.label.LT_App_Title;
    }

    applyBrandColor() {
        this.template.host.style.setProperty('--lt-header-bg', this._primaryColor);
    }
}
