import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import OpportunityLostReasonModal from 'c/opportunityLostReasonModal';

export default class OpportunityLostReason extends LightningElement {

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Loss_Reason__c', 'Opportunity.StageName'] })
    getOpportunity({ error, data }) {
        if (data) {
            const stegaName = data.fields.StageName.value;
            const lostReason = data.fields.Loss_Reason__c.value;
            const isClosedAndLost = stegaName === 'Fechado/Perdido';
            if(!lostReason && isClosedAndLost) {
                OpportunityLostReasonModal.open({
                    opportunityId: this.recordId,
                    size: 'small'
                });
            }
        }
    }

}