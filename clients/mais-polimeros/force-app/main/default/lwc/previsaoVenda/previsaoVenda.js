import { LightningElement, wire} from 'lwc';
import { IsConsoleNavigation, getFocusedTabInfo, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPrevisoes from '@salesforce/apex/PrevisaoVendaController.getMesesPrevisao';
import getLogins from '@salesforce/apex/PrevisaoVendaController.getLogins';
import getPrevisao from '@salesforce/apex/PrevisaoVendaController.getPrevisao';
import saveProdutos from '@salesforce/apex/PrevisaoVendaController.saveProdutos';

const cols = [
                { label: 'Produto', fieldName: 'produtoCodigo', editable: false, sortable: true, hideDefaultActions: true, initialWidth: 150,
                    cellAttributes: {
                        class: "slds-theme_shade",
                    },
                },
                { label: 'Média SP', fieldName: 'mediaSP', type: 'number', editable: false, sortable: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },
                },
                { label: 'SP - Cajamar', fieldName: 'quantidadeSP', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true, 
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: 'Média PR', fieldName: 'mediaPR', type: 'number', editable: false, sortable: true, hideDefaultActions: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },                            
                },
                { label: 'PR - Piraquara', fieldName: 'quantidadePR', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true, 
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: 'Média GO', fieldName: 'mediaGO', type: 'number', editable: false, sortable: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },
                },
                { label: 'GO - Apar. de Goiânia', fieldName: 'quantidadeGO', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true, 
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: 'Média RS Caxias', fieldName: 'mediaRS', type: 'number', editable: false, sortable: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },
                },
                { label: 'RS - Caxias', fieldName: 'quantidadeRS', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true, 
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: 'Média RS Sapucaia', fieldName: 'mediaRS08', type: 'number', editable: false, sortable: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },
                },
                { label: 'RS - Sapucaia', fieldName: 'quantidadeRS08', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true,
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: 'Média SC', fieldName: 'mediaSC', type: 'number', editable: false, sortable: true, hideDefaultActions: true, 
                    cellAttributes: {
                        class: "slds-theme_shade",
                        alignment: 'right'
                    },
                },
                { label: 'SC - Itajai', fieldName: 'quantidadeSC', type: 'number', editable: {fieldName: 'controlEditField'}, hideDefaultActions: true,
                    typeAttributes: {
                        maximumFractionDigits: '0', step: '25', currencyCode: '', currencyDisplayAs: ''
                    }
                },
                { label: '', fieldName: 'blankSpace', editable: false, hideDefaultActions: true, initialWidth: 10 },
            ]

export default class PrevisaoVenda extends LightningElement {

    isLoading = false;
    checkboxVal = false;

    listMeses = [];
    listLogins = [];
    listItens = [];
    draftValues = [];

    wiredPrevisaoResults;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'produtoCodigo';

    hasRendered;
    columns;
    mesSelecionado;
    loginSelecionado;

    get isEditing() {        
        let df = this.refs.dataTable.draftValues;
        return (df.length > 0);
    }

    connectedCallback(){
        this.isLoading = true;
        this.setTabLabel();

        getPrevisoes()
        .then(data => {
            if(data){
                this.listMeses = data;
                for (let i = (data.length - 1); i >= 0; i--) {
                    if(data[i].description != '(Fechado)'){
                        this.mesSelecionado = data[i].value;
                        break;
                    }
                }
            }
            this.isLoading = false;
        })
        .catch(error => {
            this.listMeses = undefined;
            this.handleErrors(error);
        });
    }

    renderedCallback(){
        if(!this.hasRendered){
            this.handleColVisibility();
            this.hasRendered = true;
        }
    }

    @wire(IsConsoleNavigation) isConsoleNavigation;

    @wire(getLogins, {idPrevisao: '$mesSelecionado'})
    wiredLogins({error, data}){
        this.isLoading = true
        this.listLogins = [];
        if(data){
            this.listLogins = data;
            if(data.length > 0){
                this.loginSelecionado = data[0].value;
            }
        } else if(error){
            this.handleErrors(error);
            this.listLogins = undefined;
        }
        this.isLoading = false;
    }

    @wire(getPrevisao, {idPrevisao: '$mesSelecionado', idUsuario: '$loginSelecionado', todos: '$checkboxVal'})
    wiredPrevisao(result){
        this.isLoading = true
        this.wiredPrevisaoResults = result;

        if(result.data){
            const cloneData = [...result.data];
            cloneData.sort(this.sortBy(this.sortedBy, 1));
            this.listItens = cloneData;
            this.isLoading = false;
        } else if(result.error){
            this.handleErrors(result.error);
            this.listItens = undefined;
        }
    }

    handleChangeLogin(event) {
        this.listItens = [];
        this.draftValues = [];
        this.isLoading = true
        this.loginSelecionado = event.detail.value;
    }

    handleChangeMes(event) {
        this.listItens = [];
        this.draftValues = [];
        this.mesSelecionado = event.detail.value;
    }

    handleChangeTodosProdutos(event) {
        this.isLoading = true;
        this.checkboxVal = event.target.checked;
    }

    handleColVisibility(event){

        if(this.isEditing){
            this.showWarningToast('Salve os dados informados antes de alterar a visualização');
            event.target.checked = !event.target.checked;
        } else {

            this.isLoading = true;
            let filterdCols = cols;
    
            if(!this.refs.chkShowMedia.checked){
                filterdCols = filterdCols.filter(col => !col.fieldName.startsWith('media'));
            }
    
            if(!this.refs.chkShowSP.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadeSP' && col.fieldName != 'mediaSP');
            }
    
            if(!this.refs.chkShowPR.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadePR' && col.fieldName != 'mediaPR');
            }
    
            if(!this.refs.chkShowGO.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadeGO' && col.fieldName != 'mediaGO');
            }
    
            if(!this.refs.chkShowRSc.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadeRS' && col.fieldName != 'mediaRS');
            }
    
            if(!this.refs.chkShowRSs.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadeRS08' && col.fieldName != 'mediaRS08');
            }
    
            if(!this.refs.chkShowSC.checked){
                filterdCols = filterdCols.filter(col => col.fieldName != 'quantidadeSC' && col.fieldName != 'mediaSC');
            }
    
            setTimeout(() => {
                this.columns = filterdCols;
                this.isLoading = false;
            }, 1);
        }
    }

    handleCellChange(event){
        const recordInputs =  event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return {fields};
        });

        for (var property in recordInputs[0].fields){
            if(property != 'itemId'){
                let valor = recordInputs[0].fields[property];
                if(valor % 25 != 0){
                    this.showWarningToast('', 'O valor deve ser múltiplo de 25');
                }
            }
        }
    }

    handleSave(event) {
        this.isLoading = true;
        const recordInputs =  event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return {fields};
        });

        saveProdutos({
            idPrevisao: this.mesSelecionado,
            idUsuario: this.loginSelecionado,
            lstRecords: recordInputs
        })
        .then(() => {
            this.isLoading = false;
            this.showSuccessToast('Atualização efetuada');

            return refreshApex(this.wiredPrevisaoResults)
            .then(() => {
                this.draftValues = [];    
            })
            .catch((error) => {
                this.handleErrors(error);
            });
        })
        .catch((error) => {
            this.handleErrors(error);
        });
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listItens];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.listItens = cloneData;
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

    async setTabLabel() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        setTabLabel(tabId, 'Previsão de Venda');
    }

    async setTabIcon() {
        if (!this.isConsoleNavigation) {
            return;
        }

        const { tabId } = await getFocusedTabInfo();
        setTabIcon(tabId, 'utility:cart', {
            iconAlt: 'Account Insights'
        });
    }

    handleErrors(error){
 
        console.log(error);
        console.error(error);
        this.isLoading = false;

        if(error.body){

            if(error.body.message && error.body.message.length > 0) {
                this.showWarningToast(error.body.message);
            }

            if(error.body.pageErrors && error.body.pageErrors.length > 0) {
                var val = Object.values(error.body.pageErrors);
                this.showWarningToast(val[0].message);
            }

            if(error.body.fieldErrors){
                var val = Object.values(error.body.fieldErrors);
                this.showWarningToast(val[0][0]["message"]);
            }

            if(error.body.errors && error.body.errors.length > 0){
                console.log('errors');
                for(let index = 0; index < error.body.errors.length; index++) {
                    this.showErrorToast('Erro no preenchimento da previsão', error.body.errors[index].errorCode + '- ' + error.body.errors[index].message);
                }
            }
        }
    }

    showSuccessToast(message) {
        const evt = new ShowToastEvent({
            title: message,
            message: '',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showWarningToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

}