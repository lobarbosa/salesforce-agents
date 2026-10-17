@isTest
public class SheduleCreateInvoiceDeliveryTest {

    @testSetup
    static void setupTestData() {
        // Garante que o Standard Price Book está ativo e obtem o Id
        Id stdPbId = Test.getStandardPricebookId();

        // Conta
        Account acc = new Account(
            Name = 'Test Account',
            beeCnpj__CNPJ__c = '12345678901234',
            NomeFantasia__c = 'Test Account'
        );
        insert acc;

        // Produto
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            CodigoTotvs__c = 'TEST0909'
        );
        insert product;

        // PricebookEntry: tenta achar um existente antes de criar
        PricebookEntry pbe;
        List<PricebookEntry> existingPbes = [
            SELECT Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :stdPbId
              AND Product2Id  = :product.Id
            LIMIT 1
        ];
        if (existingPbes.isEmpty()) {
            pbe = new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id   = product.Id,
                UnitPrice    = 101.00,
                IsActive     = true
            );
            insert pbe;
        } else {
            pbe = existingPbes[0];
            // Se por algum motivo estiver inativo, ativa
            if (!pbe.IsActive) {
                pbe.IsActive = true;
                update pbe;
            }
        }

        // Order (aponta para o Standard Price Book)
        Order ord = new Order(
            AccountId    = acc.Id,
            CodigoTOTVS__c = 'TOTVS123',
            EffectiveDate  = Date.today(),
            Pricebook2Id   = stdPbId,
            Status         = 'Draft'
        );
        insert ord;

        // Nota Fiscal (custom)
        NotaFiscal__c notaFiscal = new NotaFiscal__c(
            Chave__c          = '654322 /1 - 0100408601802be000000PFAhAAO',
            ChaveNFe__c       = '35240807228128000156550010006543221553033392',
            Conta__c          = acc.Id,
            DataEmissao__c    = Date.today(),
            NumeroNota__c     = '654322 /1 - 0100408601',
            Status__c         = 'Faturado',
            valorTotalNota__c = 1523.56
        );
        insert notaFiscal;

        // OrderItem (usa o PBE do Standard)
        OrderItem oi = new OrderItem(
            OrderId         = ord.Id,
            PricebookEntryId= pbe.Id,
            UnitPrice       = 100.00,
            Quantity        = 1,
            Status__c       = 'Faturado',
            DataEmissaoNota__c = Date.today(),
            Email__c        = false,
            NotaFiscal__c   = notaFiscal.Id,
            DataEntrega__c  = Date.today().addDays(7)
        );
        insert oi;
    }

    @isTest
    static void testSendOrderEmail() {
        Test.startTest();
        SheduleCreateInvoiceDelivery.sendOrderEmail();
        Test.stopTest();
    }

    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        SheduleCreateInvoiceDelivery scheduleJob = new SheduleCreateInvoiceDelivery();
        String jobId = System.schedule('Test Job', '0 0 0 ? * * *', scheduleJob);
        Test.stopTest();

        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('WAITING', ct.State, 'O job agendado deve estar no estado WAITING.');
    }
}