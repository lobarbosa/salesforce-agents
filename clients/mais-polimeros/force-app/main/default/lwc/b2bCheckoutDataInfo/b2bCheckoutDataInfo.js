import { wire } from 'lwc';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import { CartSummaryAdapter } from 'commerce/cartApi';

export default class B2bCheckoutDataInfo extends CheckoutComponentBase {
    valorOriginal = 0;
    valor = 0;

    @wire(CartSummaryAdapter, {})
    checkoutInfo({ error, data }) {
        if (data) {
            console.log('data: ', data);
            var vlr = parseFloat(data.totalProductAmount) - parseFloat(data.totalProductListAmount);
            this.valorOriginal = parseFloat(data.totalProductListAmount).toFixed(2);
            this.valor = vlr.toFixed(2);
        } else if (error) {
            console.error(error);
        }
    }
}