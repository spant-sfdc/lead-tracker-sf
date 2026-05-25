import { LightningElement, api } from 'lwc';

export default class LtKanbanBoard extends LightningElement {
    @api stages = [];
    @api stageOptions = [];

    get isEmpty() {
        return !this.stages || this.stages.length === 0;
    }
}
