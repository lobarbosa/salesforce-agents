import { LightningElement, api, wire } from 'lwc'
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi'
 
export default class ContadorDiasPSL extends LightningElement {
    @api recordId
    loading = true
    record
    historicoStatusPSL
    hasHistorico = false

    @wire(getRecord, { recordId: '$recordId', fields: ['Propostas_de_Solucao__c.HistoricoStatusPSLJSON__c'] }) wiredRecord({ error, data }) {
        if (error) {
            let message = 'Erro desconhecido'
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ')
            } else if (typeof error.body.message === 'string') {
                message = error.body.message
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erro ao buscar o caso',
                    message,
                    variant: 'error',
                }),
            )
        } else if (data) {
            this.record = data
            this.historicoStatusPSL = JSON.parse(getFieldValue(data, 'Propostas_de_Solucao__c.HistoricoStatusPSLJSON__c'))

            if(this.historicoStatusPSL) {
                this.historicoStatusPSL.forEach(h => {
                    if(h.dataSaida)
                        h.tempoFormatado = h.dias + ' dias e ' + h.horas + ' horas em ' + h.nome;
                    else
                        h.tempoFormatado = 'Aberto atualmente';
                });

                this.hasHistorico = true
            }

            this.loading = false
        }
    }
}