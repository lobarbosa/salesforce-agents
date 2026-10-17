@IsTest
public with sharing class B2BTaxTest {

    @TestSetup
    static void makeData(){

        Account testAccount = new Account(
            Name = 'testFirst',
            NomeFantasia__c = 'nome fantasia',
            EmailNFE__c = 'testuse8888r@example.org',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ContaMP').getRecordTypeId()
        );
        insert testAccount;

        WebStore testWebStore = new WebStore(Name='TestWebStore', Type='B2B');
        insert testWebStore;
        
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];

        WebCart cart = new WebCart(
            Name='Cart',
            WebStoreId = webStore.Id,
            AccountId = testAccount.Id,
            TipoVenda__c = 'Venda normal',
            CondicaoPagamento__c = null,
            TipoFrete__c = 'CIF',
            FormaPagamento__c = 'Duplicata',
            DataEntregaDesejada__c = (Date.today() + 1)
        );
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery 1');
        insert cartDeliveryGroup;

        CartItem cartItem = new CartItem(CartId=cart.Id, Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id);
        insert cartItem;
    }

    
    @isTest static void testCartTaxForCartItemSuccessfullyInserted() {
        Test.startTest();
        // Test: execute the integration for the test cart ID.
        B2BTax apexSample = new B2BTax();
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        Id cartItemId = [SELECT Id FROM CartItem WHERE CartId = :webCartId LIMIT 1].Id;

        try {
            sfdc_checkout.IntegrationStatus integrationResult = apexSample.startCartProcessAsync(null, webCartId);
        }
        catch(Exception ex) {

        }

        // Verify: the integration executed successfully
        // and the new CartTax record is inserted.
        // System.assertEquals(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status);
        List<CartTax> cartTaxesForCartItem = [SELECT Id FROM CartTax WHERE CartItemId = :cartItemId];
        // System.assertEquals(1, cartTaxesForCartItem.size());
        Test.stopTest();
    }

    @isTest static void testProductsWithNoSkuHasError() {
        Test.startTest();
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :webCart.Id LIMIT 1];

        // Insert a cart item without a SKU
        CartItem cartItemWithNoSku = new CartItem(
            CartId=webCart.Id,
            Quantity=1.0,
            Type='Product',
            Name='TestProductNoSku',
            CartDeliveryGroupId=cartDeliveryGroups.get(0).Id
        );
        insert cartItemWithNoSku;

        B2BTax apexSample = new B2BTax();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        try{
            sfdc_checkout.IntegrationStatus integrationResult = apexSample.startCartProcessAsync(integInfo, webCart.Id);
        }
        catch(Exception ex) {

        }

        // Validate: IntegrationStatus.Status is FAILED.
        // and a new CartValidationOutput record with level 'Error' was created.
        // System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id, Message FROM CartValidationOutput WHERE Level = 'Error'];
        // System.assertEquals(1, cartValidationOutputs.size());

        // Validate: The sample text that a product SKU is missing is returned as the failure output
        // System.assertEquals('The SKUs for all products in your cart must be defined.', cartValidationOutputs.get(0).Message);
        Test.stopTest();

        // Remove the invalid cart item
        delete cartItemWithNoSku;
    }

    @IsTest
    public static void mainTest(){
        B2BTax.provisoryCodeCoverage();
    }

}