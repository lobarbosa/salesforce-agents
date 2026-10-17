import { LightningElement,api,wire,track } from 'lwc';
import getRecentOrderProducts from '@salesforce/apex/B2BCarouselRecentOrderItemController.getRecentOrderProducts';

export default class b2BCarouselRecentOrderProduct extends LightningElement {
    @api quantidade;
    @api orderBy;
    @api mesesIntervalo;
    @track recentProducts = [];

    @wire(getRecentOrderProducts,{quantidade: '$quantidade',orderBy: '$orderBy',mesesIntervalo: '$mesesIntervalo', urlBaseLoja: window.location.href})
    wiredGetReports(response) {

        console.log('orderBy', this.orderBy);
        console.log('quantidade', this.quantidade);
        console.log('mesesIntervalo', this.mesesIntervalo);

        this._getResponse = response;
        let error = response && response.error;
        let data = response && response.data;

        if (data) {
            this.recentProducts = data;
            this.error = undefined;
        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }
}