import alterarStatus from '@salesforce/apex/ProcessoAprovacaoOpp.alterarStatus';
import montarRelatorio from '@salesforce/apex/ProcessoAprovacaoOpp.montarRelatorio';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, track } from 'lwc';

export default class AprovacaoOpp extends LightningElement {
    actions = [
        { label: 'Aprovar', name: 'Approve' },
        { label: 'Reprovar', name: 'Reject' },
    ];

    columns = [
        {label: 'Opportunidade',fieldName: 'opportunidadeId',type: 'url',sortable: true,
        typeAttributes: {label: { fieldName: 'opportunidade' }, target: '_blank'}
        },
        { label: 'Classificação Grupo Econ.', fieldName: 'grupo',sortable: true},
        { label: 'Quantidade', fieldName: 'quantidade',sortable: true},
        { label: 'Divisão de Negócio', fieldName: 'divisaoId',type: 'url',
                typeAttributes: {label: { fieldName: 'divisao' }, target: '_blank'}
                ,sortable: true},
        {label: 'Comentário', fieldName: 'comments',sortable: true },
        {label: 'Data', fieldName: 'data',sortable: true },
        { label: 'Provador de Fato', fieldName: 'aprovador',sortable: true},
        { label: 'Minutos em Espera', fieldName: 'horasEspera',sortable: true},
        
        {
            type: 'action',
            typeAttributes: { rowActions: this.actions },
        },
    ];

    @track data;
    showComentario = false;
    comentario = '';
    actionName = null;
    workItemId = '';
    row = null;


    connectedCallback (){

        montarRelatorio({userId:Id}).then((result) =>{
            result = JSON.parse(result);
            this.data = result;
        }).catch((error)=>{
            this.mostrarMensagem('error','Erro ao modificar o status',error);
          });
    }

    recarregarLista(){
        montarRelatorio({userId:Id}).then((result) =>{
            result = JSON.parse(result);
            this.data = result;
        }).catch((error)=>{
            this.mostrarMensagem('error','Erro ao modificar o status',error);
          });
    }

    alterarProcesso(){
        alterarStatus({ novoStatus: this.actionName,
                        userId: Id,
                        comentario: this.comentario,
                        workItemId: this.row['id']}).then((result) =>{
            result = JSON.parse(result);
            this.data = result;
            this.showComentario = false;
            this.mostrarMensagem('success','Sucesso','Solicitação '+novoStatus+' com sucesso!');
        }).catch((error)=>{
            this.mostrarMensagem('error','Erro ao modificar o status',error);
          });
        
        
    }

    digitarComentario(event){
        this.comentario = event.target.value;
    }

    handleRowAction(event){
        this.showComentario = true;
        this.actionName = event.detail.action.name;
        this.row = event.detail.row;
    }

    cancelarAcao(){
        this.showComentario = false;
        this.actionName = null;
        this.row = null;
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    mostrarMensagem(tipo,titulo, mensagem){
        msg = new ShowToastEvent({
                                    title: titulo,
                                    message: mensagem,
                                    variant: tipo
                                });
        this.dispatchEvent(msg);
    }
}