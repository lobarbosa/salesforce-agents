import { LightningElement, api, track, wire } from 'lwc';
import getImageUrl from '@salesforce/apex/CommerceCustomCarouselEnhancedController.getContentKey';

const EXIBIR_CARD = 'slds-show';
const OCULTAR_CARD = 'slds-hide';
const EXIBIR_CIRCULO = 'circulo-style exibir-circulo-style';
const OCULTAR_CIRCULO = 'circulo-style';
const SCROLL_TIME = 5000;

export default class CommerceCustomCarouselEnhanced extends LightningElement {
    @api contentKeys;
    @api contentRedirectURL;
    @api channelName;
    @api storeName;
    @api titulo;
    @api slideTime = SCROLL_TIME;
    @api trocaAutomatica;
    @api exibirTitulo;
    @api exibirSetas;
    @api exibirCirculos;
    @api trocaManual;
    @api altTextHyperLink = false;
    @track exibirBotoes;
    @track conteudo;
    @track timer;
    slideIndex = 1;
    colecoes = [];

    connectedCallback() {
        this.getColecao(this.contentKeys, this.channelName, this.storeName);
        if(this.trocaAutomatica) {
            this.timer = window.setInterval(() => {
                this.slideSelectionHandler(this.slideIndex + 1);
            }, Number(this.slideTime))
        }
    }

    disconnectedCallback() {
        if(this.trocaAutomatica) {
            window.clearInterval(this.timer);
        }
    }

    getColecao(listKeys, channel, storeName) {
        getImageUrl({keys: listKeys, channelName: channel, storeName: storeName})
        .then(result => {
            this.colecoes = JSON.parse(result);
            this.conteudo = this.colecoes != null ? true : false;
            this.exibirBotoes = this.colecoes.length > 1 ? true : false;
            let arrayRedirectUrl = this.contentRedirectURL != null ? this.contentRedirectURL.split(',') : [];
            this.colecoes = this.colecoes.map((item, index) => {
                return index === 0 ? {
                    ...item,
                    slideIndex: index + 1,
                    redirectUrl: arrayRedirectUrl.length > index ? arrayRedirectUrl[index] : '',
                    cardClass: EXIBIR_CARD,
                    dotClass: EXIBIR_CIRCULO
                }:{
                    ...item,
                    slideIndex: index + 1,
                    redirectUrl: arrayRedirectUrl.length > index ? arrayRedirectUrl[index] : '',
                    cardClass: OCULTAR_CARD,
                    dotClass: OCULTAR_CIRCULO
                }
            });
        })
        .catch(error => {
            console.error('ERROR getImageUrl ==>');
            console.error(error);
            this.error = error;
        })
    }

    prevCard() {
        if(this.trocaManual && this.exibirSetas) {
            let slideIndex = this.slideIndex - 1;
            this.slideSelectionHandler(slideIndex);
        }
    }
    
    nextCard() {
        if(this.trocaManual && this.exibirSetas) {
            let slideIndex = this.slideIndex + 1;
            this.slideSelectionHandler(slideIndex);
        }
    }

    selectCard(event) {
        if(this.trocaManual) {
            let slideIndex = Number(event.target.dataset.id);
            this.slideSelectionHandler(slideIndex);
        }
    }

    slideSelectionHandler(index) {
        if(index > this.colecoes.length) {
            this.slideIndex = 1;
        } else if(index < 1) {
            this.slideIndex = this.colecoes.length;
        } else {
            this.slideIndex = index;
        }

        this.colecoes = this.colecoes.map(item => {
            return this.slideIndex === item.slideIndex ? {
                ...item,
                cardClass: EXIBIR_CARD,
                dotClass: EXIBIR_CIRCULO
            }:{
                ...item,
                cardClass: OCULTAR_CARD,
                dotClass: OCULTAR_CIRCULO
            }
        });
    }
}