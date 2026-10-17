import { api, wire } from 'lwc';
import { CheckoutComponentBase, CheckoutInformationAdapter, notifyCheckout } from 'commerce/checkoutApi';
import { CartSummaryAdapter } from 'commerce/cartApi';
import { NavigationMixin } from "lightning/navigation";
import Toast from 'lightning/toast';
import ToastContainer from 'lightning/toastContainer';

import getInit from '@salesforce/apex/b2bCheckoutDataController.getInit';
import updateCartData from '@salesforce/apex/b2bCheckoutDataController.updateCartData';
import refreshTax from '@salesforce/apex/b2bCheckoutDataController.refreshTax';

import MAIN_TEMPLATE from "./b2bCheckoutData.html";
import STENCIL from "./b2bCheckoutDataStencil.html";

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bCheckoutData extends NavigationMixin(CheckoutComponentBase) {

    totalTaxAmount = 0;

    disableConfirm = true;
    isPreview = true;
    isLoading = true;
    errorLoading = false;

    bloquearPeriodoEntrega;
    bloquearEntregaSabado;
    inicioBloqueioDataEntrega;
    fimBloqueioDataEntrega;

    condicaoPagamento;
    condicaoAvista;
    formaPagamento;
    dataEntrega;
    observacaoRetirada;
    placaVeiculo;
    nomeMotorista;
    mensagemEspera = '';

    condicaoPagamentoList = [];
    formaPagamentoList = [
        {value: 'DP - Duplicata', label: 'Duplicata'},
        {value: 'DE- Depósito', label: 'Depósito'}
    ];

    get showMsgAvista() {
        return ((this.condicaoPagamento == this.condicaoAvista));
    }

    render() {
        if(this.isLoading){
            return STENCIL;
        }else{
            return MAIN_TEMPLATE;
        }
    }

    stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                this.dispatchUpdateErrorAsync({
                    groupId: 'Checkout'
                });
                return Promise.resolve(this.checkValidity());

            case CheckoutStage.REPORT_VALIDITY_SAVE:
                this.dispatchUpdateErrorAsync({
                    groupId: 'Checkout'
                });

                return Promise.resolve(this.reportValidity());

            default:
                return Promise.resolve(true);
        }
    }

    connectedCallback() {

        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        toastContainer.toastPosition = 'top-center';

        getInit()
        .then(result => {
            console.log('>> V3', result);

            this.condicaoPagamento = result.condicaoPagamento;
            this.formaPagamento = result.formaPagamento;
            this.observacaoRetirada = result.observacaoRetirada;
            this.placaVeiculo = result.placaVeiculo;
            this.nomeMotorista = result.nomeMotorista;
            this.condicaoPagamentoList = result.condicaoPagamentoList;
            this.condicaoAvista = result.condicaoAvista;
            this.bloquearPeriodoEntrega = result.bloquearPeriodoEntrega;
            this.bloquearEntregaSabado = result.bloquearEntregaSabado;
            this.inicioBloqueioDataEntrega = result.inicioBloqueioDataEntrega;
            this.fimBloqueioDataEntrega = result.fimBloqueioDataEntrega;

            this.checkValidity();
        }).catch(error => {
            console.error(error);
        });
    }

    @wire(CheckoutInformationAdapter, {})
    checkoutInfo({ error, data }) {
        this.isLoading = true;
        this.isPreview = this.isInSitePreview();
        if (!this.isPreview) {
            if (data) {
                if (data.checkoutStatus == 200) {
                    console.log('checkoutInfo data', data);
                    this.isLoading = false;
                    this.errorLoading = false;
                }
            } else if (error) {
                this.isLoading = false;
                this.errorLoading = true;
                console.error(error);
            }
        } else {
            this.isLoading = false;
        }
    }

    @wire(CartSummaryAdapter, {})
    cartSummary({ error, data }) {
        if (data) {
            console.log('cartSummary data: ', data);
            this.totalTaxAmount = data.totalTaxAmount;
        } else if (error) {
            console.error(error);
        }
    }

    // @api
    checkValidity(){
        var allValid = true;
        allValid = allValid && !this.isLoading;
        allValid = allValid && !this.errorLoading;
        allValid = allValid && this.refs.condicaoPagamento.reportValidity();
        allValid = allValid && this.refs.formaPagamento.reportValidity();
        allValid = allValid && this.refs.dataEntrega.reportValidity();
        return allValid;
    }

    reportValidity() {
        return this.checkValidity();
    }

    fillVariables(){
        this.condicaoPagamento = this.refs.condicaoPagamento.value;
        this.formaPagamento = this.refs.formaPagamento.value;
        this.dataEntrega = this.refs.dataEntrega.value;
        this.observacaoRetirada = this.refs.observacaoRetirada.value;
        this.placaVeiculo = this.refs.placaVeiculo.value;
        this.nomeMotorista = this.refs.nomeMotorista.value;
    }

    handleUpdateCart(event){

        // if(event.target.name == 'condicaoPagamento'){
        //     console.log('event.target.label',event.target.value);
        //     this.showMsgAvista = (event.target.value == this.condicaoAvista);
        // }

        // Valida critério para Data de Entrega
        if(event.target.name == 'dataEntrega'){
            if(event.target.value){ 
                event.target.setCustomValidity('');
   
                let dataEntrega = this.instanceDate(event.target.value);
                let gmtToday = new Date();
                gmtToday.setHours(0, 0, 0, 0);
                
                console.log(dataEntrega.getMonth()+'__'+gmtToday.getMonth());

                if(dataEntrega < gmtToday) {
                    event.target.setCustomValidity('Data de entrega não pode estar no passado');

                } else if(dataEntrega.getMonth() != gmtToday.getMonth()){
                    event.target.setCustomValidity('Data de entrega não pode estar fora do mês corrente');
                }else if(dataEntrega.getDay() == 0){
                    event.target.setCustomValidity('Não é possível entrega aos domingos');

                } else if(this.bloquearEntregaSabado && dataEntrega.getDay() == 6){
                    event.target.setCustomValidity('Não é possível entrega aos sábados');

                } else if(this.bloquearPeriodoEntrega){
                    let inicioBloqueio = this.instanceDate(this.inicioBloqueioDataEntrega);
                    let fimBloqueio = this.instanceDate(this.fimBloqueioDataEntrega);
                    if(dataEntrega >= inicioBloqueio && dataEntrega <= fimBloqueio){
                        console.log('inicioBloqueio', inicioBloqueio);
                        console.log('fimBloqueio', fimBloqueio);
                        if(inicioBloqueio.getTime() == fimBloqueio.getTime()){
                            event.target.setCustomValidity('Entregas suspensas em ' + inicioBloqueio.toLocaleDateString());
                        } else {
                            event.target.setCustomValidity('Entregas suspensas entre ' + inicioBloqueio.toLocaleDateString() + ' e ' + fimBloqueio.toLocaleDateString());
                        }
                    }
                }
            } else {
                event.target.setCustomValidity('Data inválida');
            }
    
            event.target.reportValidity();
        }

        if(this.checkValidity()) {

            this.mensagemEspera = 'Aguarde enquanto calculamos as taxas e impostos...';
            this.isLoading = true;
            this.fillVariables();

            updateCartData({    condicaoPagamento: this.condicaoPagamento,
                                formaPagamento: this.formaPagamento,
                                dataEntrega: this.dataEntrega,
                                placaVeiculo: this.placaVeiculo,
                                nomeMotorista: this.nomeMotorista,
                                observacaoRetirada: this.observacaoRetirada   })

            .then(result => {
                console.log('result - handleUpdateCart', result);
                let cartId = result;

                refreshTax({  cartId: cartId })
                .then(result => {
                    console.log('result - refreshTax', result);

                    notifyCheckout().then(() => {
                        this.disableConfirm = false;
                        this.mensagemEspera = '';
                        console.log("cart summary notifyCheckout refreshed");           
                    }).catch(error => {
                        this.mensagemEspera = '';
                        this.disableConfirm = true;
                        console.error(error);
                        console.error('notifyCheckout: ' + error.message);
                        this.showToast('Não foi possível calcular os impostos do pedido', 'Por favor tente mais tarde ou entre em contato com nossa central de atendimento', 'warning');
                    });;

                    // refreshCartSummary().then(() => {
                    //     this.disableConfirm = false;
                    //     this.mensagemEspera = '';
                    //     console.log("cart summary refreshed");
                    // });

                }).catch(error => {
                    this.isLoading = false;
                    this.mensagemEspera = '';
                    this.disableConfirm = true;
                    console.error(error);
                    console.error('refreshTax: ' + error.message);
                    this.showToast('Não foi possível calcular os impostos do pedido', 'Por favor, tente mais tarde ou entre em contato com nossa central de atendimento', 'warning');
                });

            }).catch(error => {
                this.isLoading = false;
                this.mensagemEspera = '';
                this.disableConfirm = true;
                console.error(error);
                console.error('updateCartData: ' + error.message);
                this.showToast('Não foi possível calcular os impostos do pedido', 'Por favor, tente mais tarde ou entre em contato com nossa central de atendimento', 'warning');
            });
        }
    }

    instanceDate(dateString){
        let parts = dateString.split('-');
        let date = new Date(parts[0], parts[1] - 1, parts[2]);
        return date;
    }

    handleConfirmar(){

        if(this.totalTaxAmount == null || this.totalTaxAmount <= 0){
            this.showToast('Não foi possível confirmar o valor dos impostos', 'Por favor, tente mais tarde ou entre em contato com nossa central de atendimento', 'warning');

        } else {
            if(this.checkValidity()){

                this.fillVariables();
                this.isLoading = true;
    
                updateCartData({  condicaoPagamento: this.condicaoPagamento,
                                    formaPagamento: this.formaPagamento,
                                    dataEntrega: this.dataEntrega,
                                    placaVeiculo: this.placaVeiculo,
                                    nomeMotorista: this.nomeMotorista,
                                    observacaoRetirada: this.observacaoRetirada
                })
                .then(result => {
                    this.dispatchFinalizeAsync().then(() => {
            
                        this.dispatchPlaceOrderAsync().then((result) => {
                            console.log('dispatchPlaceOrderAsync', result);
            
                            var ordeNumber = result.orderReferenceNumber;                        
                            this[NavigationMixin.Navigate](
                                {
                                    type: 'comm__namedPage',
                                    attributes: {
                                        name: 'Order'
                                    },
                                    state: {
                                        orderNumber: ordeNumber,
                                        isPaymentLink: ''
                                    }
                                },
                                true, // Replaces the current page in your browser history with the URL
                                );
            
                        }).catch((error) => {
                            this.isLoading = false;
                            console.error(error);           
                        });
            
                    }).catch((error) => {
                        this.isLoading = false;
                        console.error(error);           
                    });
                
                }).catch(error => {
                    this.isLoading = false;
                    console.error(error);
                });   
            }
        }

    }

    showToast(label, message, variant){
        this.showSpinner = false;
        Toast.show({
            label: label,
            message: message,
            variant: variant,
            mode: 'dismissible'
        }, this);
    }

    isInSitePreview() {
        let url = document.URL;

        return (
        url.indexOf("sitepreview") > 0 ||
        url.indexOf("livepreview") > 0 ||
        url.indexOf("live-preview") > 0 ||
        url.indexOf("live.") > 0 ||
        url.indexOf(".builder.") > 0
        );
    }
}