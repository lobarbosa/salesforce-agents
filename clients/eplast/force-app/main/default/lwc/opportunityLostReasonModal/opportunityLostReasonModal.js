import { api } from 'lwc';
import LightningModal from 'lightning/modal';
export default class OpportunityLostReasonModal extends LightningModal {
    @api opportunityId;
    loading = false;

    connectedCallback() {
        this.disableClose = true;
    }

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.loading = true;
    }

    handleSuccess(event) {
        this.disableClose = false;
        this.close();
    }

}