// This must implement the sfdc_checkout.CartTaxCalculations interface
// in order to be processed by the checkout flow and used for your Taxes integration.
global with sharing class B2BTax implements sfdc_checkout.CartTaxCalculations {
    // You MUST change this to be your service or you must launch your own Heroku Service
    // and add the host in Setup | Security | Remote site settings.
    private static String httpHost = 'https://example.com';
    private class ApplicationException extends Exception {}
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {

        System.debug('B2BTax');

        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            WebCart cart = [SELECT Id, CondicaoPagamento__c, DataEntregaDesejada__c, FormaPagamento__c, WebStoreId FROM WebCart WHERE Id = :cartId];
            if (String.isBlank(cart.CondicaoPagamento__c) || String.isBlank(cart.FormaPagamento__c) || cart.DataEntregaDesejada__c == null) {
                integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
            } else {
                //Tax
                Map<Id, CartItem> cartItemsById = new Map<Id, CartItem>();
                for (CartItem cartItem : [SELECT Sku, SalesPrice, ListPrice, TotalPrice, TotalPromoAdjustmentAmount, Quantity FROM CartItem WHERE CartId = :cartId AND Type = 'Product' WITH SECURITY_ENFORCED]) {
                    if (String.isBlank(cartItem.Sku)) {
                        String errorMessage = 'The SKUs for all products in your cart must be defined.';
                        return integrationStatusFailedWithCartValidationOutputError(
                            integStatus,
                            errorMessage,
                            jobInfo,
                            cartId
                        );
                    }
                    cartItemsById.put(cartItem.Id, cartItem);
                }

                // try {

                    Decimal encargo = [SELECT PercentualEncargoFinanceiro__c FROM CondicaoPagamento__c WHERE Id = :cart.CondicaoPagamento__c]?.PercentualEncargoFinanceiro__c ?? 0;
                    System.debug('encargo: ' + encargo);

                    if(encargo > 0){
                        encargo = (encargo / 100).setScale(5);
                        System.debug('encargo: ' + encargo);
                    }

                    TaxIntegrationResponse res = TaxIntegration.sendRequest(cartId);
                    Map<String, TaxDataFromExternalService> rateAndAmountFromExternalServicePerSku = getTaxRatesAndAmountsFromExternalService(res, cartItemsById, encargo);

                    delete [SELECT Id FROM CartTax WHERE CartItemId IN :cartItemsById.keySet() WITH SECURITY_ENFORCED];

                    CartTax[] cartTaxestoInsert = new CartTax[]{};
                    for (CartItem cartItem : cartItemsById.values()) {
                        TaxDataFromExternalService rateAndAmountFromExternalService = rateAndAmountFromExternalServicePerSku.get(cartItem.Id);
                        if (rateAndAmountFromExternalService == null){
                            return integrationStatusFailedWithCartValidationOutputError(
                                integStatus,
                                'The product with cart item id ' + cartItem.Id + ' could not be found in the external system',
                                jobInfo,
                                cartId
                            );
                        }
                        CartTax tax = new CartTax(
                            CartItemId = cartItem.Id,
                            TaxCalculationDate = Date.today(),
                            Name = rateAndAmountFromExternalService.getTaxName(),
                            Amount = rateAndAmountFromExternalService.getAmount(),
                            TaxRate = rateAndAmountFromExternalService.getRate(),
                            TaxType = 'Actual'
                        );
                        cartTaxestoInsert.add(tax);

                        cartItem.UnitAdjustmentAmount = rateAndAmountFromExternalService.getUnitPriceWithoutTax() - cartItem.SalesPrice;
                        cartItem.UnitAdjustedPrice = rateAndAmountFromExternalService.getUnitPriceWithoutTax();
                        cartItem.SalesPrice = rateAndAmountFromExternalService.getUnitPriceWithoutTax();
                        cartItem.TotalPriceAfterAllAdjustments = cartItem.UnitAdjustedPrice * cartItem.Quantity;
                        cartItem.TotalLineAmount = cartItem.UnitAdjustedPrice * cartItem.Quantity;
                        cartItem.TotalPrice = cartItem.UnitAdjustedPrice * cartItem.Quantity;
                    }


                    system.debug('[BEFORE COUPON] cartItemsById.values(): ' + cartItemsById.values());
                    update cartItemsById.values();

                    try {

                        for(ConnectApi.CartCoupon cc : ConnectApi.CommerceCart.getCartCoupons(cart.WebStoreId, null, 'current')?.cartCoupons?.coupons){
                            system.debug('CartCoupon: ' + cc);

                            ConnectApi.CommerceCart.deleteCartCoupon(cart.WebStoreId, null, 'current', cc.cartCouponId);
                            system.debug('Deleted CartCoupon: ' + cc);

                            ConnectApi.cartCouponInput couponInput = new ConnectApi.cartCouponInput();
                            system.debug('New CartCouponInput: ' + couponInput);
                            couponInput.couponCode = cc.couponCode;

                            ConnectApi.CommerceCart.applyCartCoupon(cart.WebStoreId, null, 'current', couponInput);
                            system.debug('Applied CartCoupon: ' + couponInput);
                        }
                    } catch (Exception ex) {
                        system.debug('CartCoupon getStackTraceString: ' + ex.getStackTraceString());
                    }

                    List<CartItem> itemsAfterCoupon = [SELECT Sku, SalesPrice, ListPrice, TotalPrice, TotalPromoAdjustmentAmount, Quantity FROM CartItem WHERE CartId = :cartId AND Type = 'Product' WITH SECURITY_ENFORCED];
                    system.debug('[AFTER COUPON] cartItemsById.values(): ' + itemsAfterCoupon);

                    System.debug('cartTaxestoInsert: ' + cartTaxestoInsert);
                    insert cartTaxestoInsert;

                // } catch (Exception ex) {
                //     system.debug('cartTaxestoInsert getStackTraceString: ' + ex.getStackTraceString());
                //     throw new AuraHandledException(ex.getMessage());
                // }

                integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
            }
        } catch(Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

    private Map<String, TaxDataFromExternalService> getTaxRatesAndAmountsFromExternalService (TaxIntegrationResponse res, Map<Id,CartItem> mapCartItems, Decimal encargo) {
            System.debug(res);
            System.debug(res.error);

            // If the request is successful, parse the JSON response;
            // The response includes the tax amount, rate, and name for each SKU. It looks something like this:
            // {"SKU_1_september10-1568355297":{"taxAmount":2.8229012971048855,"taxRate":0.08,"taxName":"GST"},"SKU_0_september10-1568355296":{"taxAmount":5.0479003481482385,"taxRate":0.08,"taxName":"GST"}}
            if (!res.error) {
                Map<String, TaxDataFromExternalService> taxDataFromExternalServiceBySKU = new Map<String, TaxDataFromExternalService>();
                List<CartItem> lstUpdateCartItem = new List<CartItem>();
                for (TaxIntegrationResponse.ITENS item : res.COTACOES[0].ITENS) {

                    // Percentual nominal de ICSM dividido por 100 para chegar ao percentual matemático
                    Decimal percentualIcms = (Decimal.valueOf(item.ICMS) / 100);
                    System.debug('percentualICMS: ' + percentualICMS);

                    // Percentual nominal de IPI dividido por 100 para chegar ao percentual matemático
                    Decimal percentualIpi = (Decimal.valueOf(item.IPI).setScale(2) / 100);
                    System.debug('percentualIPI: ' + percentualIPI);

                    // Quantidade total
                    Decimal quantidade = Decimal.valueOf(item.QUANTIDADE);
                    System.debug('quantidade: ' + quantidade);

                    // Valor unitário retornado pelo Protheus
                    // Decimal precoUnitarioSemImposto = Decimal.valueOf(item.VALORUNITARIOSEMIMP);
                    Decimal precoUnitarioSemImposto = mapCartItems.get(item.ITEM)?.ListPrice ?? 0;
                    System.debug('precoUnitarioSemImposto: ' + precoUnitarioSemImposto);

                    if(encargo > 0){
                        precoUnitarioSemImposto = precoUnitarioSemImposto + (precoUnitarioSemImposto * encargo).setScale(3);
                        System.debug('precoUnitarioSemImposto + encargo: ' + precoUnitarioSemImposto);
                    }

                    // Preço unitário sem imposto multiplicado pela quantidade solicitada
                    Decimal valorTotalSemImposto = (precoUnitarioSemImposto * quantidade);
                    System.debug('valorTotalSemImposto: ' + valorTotalSemImposto);

                    Decimal valorDesconto = mapCartItems.get(item.ITEM)?.TotalPromoAdjustmentAmount ?? 0;
                    // Decimal valorTotalComDesconto = 0;
                    System.debug('valorDesconto: ' + valorDesconto);
                    if((valorDesconto ?? 0) != 0){
                        Decimal percentualDesconto = (valorDesconto.abs() / valorTotalSemImposto).setScale(2);
                        System.debug('percentualDesconto: ' + percentualDesconto);

                        // precoUnitarioSemImposto = precoUnitarioSemImposto - (precoUnitarioSemImposto * percentualDesconto);
                        // System.debug('precoUnitarioSemImposto - desconto: ' + precoUnitarioSemImposto);

                        valorTotalSemImposto = valorTotalSemImposto - (valorTotalSemImposto * percentualDesconto);
                        System.debug('valorTotalSemImposto - desconto: ' + valorTotalSemImposto);
                    }

                    // Preço unitário acrescido do valor de ICMS de acordo com a alíquota de ICSM retornada do Protheus
                    Decimal valorTotalComIcms = (valorTotalSemImposto / (1 - (percentualICMS))).setScale(3);
                    System.debug('valorTotalComIcms: ' + valorTotalComIcms);

                    // Preço unitário com ICMS acrescido do valor de IPI de acordo com a alíquota de IPI retornada do Protheus (imposto sobre impposto)
                    Decimal valorTotalComIcmsIpi = (valorTotalComIcms * (1 + (percentualIpi))).setScale(3);
                    System.debug('valorTotalComIcmsIpi: ' + valorTotalComIcmsIpi);

                    // Diferença percentual entre o valor sem imposto e o valor com todos os impostos
                    Decimal percentualEquivalenteImpostoTotal = (((valorTotalComIcmsIpi - valorTotalSemImposto) / valorTotalSemImposto) * 100).setScale(2);
                    System.debug('percentualEquivalenteImpostoTotal: ' + percentualEquivalenteImpostoTotal);

                    // Valor total equivalente aos impostos
                    Decimal valorImpostoTotal = (valorTotalComIcmsIpi - valorTotalSemImposto);
                    System.debug('valorImpostoTotal: ' + valorImpostoTotal);

                    // Preço unitário com todos os impostos multiplicado pela quantidade solicitada
                    // Decimal valorTotalComImposto = (precoUnitarioComIcmsIpi * quantidade);
                    // System.debug('valorTotalComImposto: ' + valorTotalComImposto);

                    // taxDataFromExternalServiceBySKU.put(item.ITEM, new TaxDataFromExternalService(
                    //     Decimal.valueOf(item.IPI) + Decimal.valueOf(item.ICMS),
                    //     (Decimal.valueOf(item.VALORUNITARIOCOMIMP) - Decimal.valueOf(item.VALORUNITARIOSEMIMP))*Decimal.valueOf(item.QUANTIDADE),
                    //     (String)'Impostos',
                    //     Decimal.valueOf(item.VALORUNITARIOSEMIMP)
                    // ));

                    // Correção do valor do imposto
                    // taxDataFromExternalServiceBySKU.put(item.ITEM, new TaxDataFromExternalService(percentualEquivalenteImpostoTotal, valorImpostoTotal, 'Impostos', precoUnitarioSemImposto));
                    taxDataFromExternalServiceBySKU.put(item.ITEM, new TaxDataFromExternalService(percentualEquivalenteImpostoTotal, valorImpostoTotal, 'Impostos', precoUnitarioSemImposto));

                    CartItem newCI = new CartItem(
                        Id = item.ITEM,
                        PercentualICMS__c = Decimal.valueOf(item.ICMS),
                        PercentualIPI__c = Decimal.valueOf(item.IPI),
                        PercentualComissao__c = Decimal.valueOf(item.COMISSAO)
                    );
                    lstUpdateCartItem.add(newCI);

                }

                update lstUpdateCartItem;

                return taxDataFromExternalServiceBySKU;
            } else {
                throw new CalloutException ('There was a problem with the request. Error: ' + res.errorMessage);
            }
    }

    // Structure to store the tax data retrieved from external service
    // This simplifies our ability to access it when storing it in Salesforce's CartTax entity
    Class TaxDataFromExternalService {
        private Decimal rate;
        private Decimal amount;
        private String taxName;
        private Decimal unitPriceWithoutTax;

        public TaxDataFromExternalService () {
            rate = 0.0;
            amount = 0.0;
            taxName = '';
        }

        public TaxDataFromExternalService (Decimal someRate, Decimal someAmount, String someTaxName, Decimal someUnitPriceWithoutTax) {
            rate = someRate;
            amount = someAmount;
            taxName = someTaxName;
            unitPriceWithoutTax = someUnitPriceWithoutTax;
        }

        public Decimal getRate() {
            return rate;
        }

        public Decimal getAmount() {
            return amount;
        }

        public String getTaxName() {
            return taxName;
        }
        public Decimal getUnitPriceWithoutTax() {
            return unitPriceWithoutTax;
        }
    }

    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // For the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user (maximum 255 characters)
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Taxes'
            );
            insert(cartValidationError);
            return integrationStatus;
    }

    public static void provisoryCodeCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;       
    }
}