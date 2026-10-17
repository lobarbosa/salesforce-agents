@isTest
public class SheduleSeparatingOrderSendEmailTest {

    @testSetup
    static void setupTestData() {
        // Contato
        Contact ct = new Contact(
            LastName = 'Vagner',
            Email    = 'vagner@gmail.com'
        );
        insert ct;

        // Conta
        Account acc = new Account(
            Name                 = 'Teste Account',
            beeCnpj__CNPJ__c     = '12345678901234',
            ContatoPrincipal__c  = ct.Id,
            NomeFantasia__c      = 'Teste Account'
        );
        insert acc;

        // Price Book CUSTOM (evita conflito com o Standard)
        Pricebook2 pbCustom = new Pricebook2(
            Name     = 'CATALOGO TESTE',
            IsActive = true
        );
        insert pbCustom;

        // Produto (tem que estar ativo para PBE)
        Product2 prod = new Product2(
            Name           = 'Produto Teste',
            CodigoTotvs__c = '0000000000000000000000',
            IsActive       = true
        );
        insert prod;

        // PBE no PB CUSTOM (reutiliza se já existir)
        PricebookEntry pbe;
        List<PricebookEntry> existing = [
            SELECT Id, IsActive, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :pbCustom.Id
              AND Product2Id   = :prod.Id
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            pbe = new PricebookEntry(
                Pricebook2Id     = pbCustom.Id,
                Product2Id       = prod.Id,
                UnitPrice        = 100.00,
                IsActive         = true,
                UseStandardPrice = false
            );
            insert pbe;
        } else {
            pbe = existing[0];
            if (!pbe.IsActive) { pbe.IsActive = true; update pbe; }
        }

        // Order usando o PB CUSTOM
        Order ord = new Order(
            AccountId        = acc.Id,
            CodigoTOTVS__c   = 'TOTVS123',
            EffectiveDate    = Date.today(),
            TipoFrete__c     = 'F',
            FormaPagamento__c= 'DH- Dinheiro',
            Status           = 'Draft',
            Pricebook2Id     = pbCustom.Id
        );
        insert ord;

        // OrderItem vinculado ao PBE do PB CUSTOM
        OrderItem ordItem = new OrderItem(
            OrderId          = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = 100.00,
            Status__c        = 'Faturado'
        );
        insert ordItem;

        // Controle do envio (Tipo 01)
        PedidoEmail__c pedidoEmail = new PedidoEmail__c(
            Order__c       = ord.Id,
            Tipo__c        = '01',
            Executado__c   = false,
            NFNumero__c    = '1234',
            CodigoTOTVS__c = '247997',
            Link_NFe__c    = 'https://example.com'
        );
        insert pedidoEmail;

        // Ajusta CreatedDate (permitido em testes)
        Test.setCreatedDate(pedidoEmail.Id, DateTime.now().addMinutes(-10));
    }

    @isTest
    static void testSeparatingOrderSendEmail() {
        Test.startTest();
        SheduleSeparatingOrderSendEmail.sendOrderEmail();
        Test.stopTest();

        PedidoEmail__c result = [
            SELECT Executado__c, Tipo__c
            FROM PedidoEmail__c
            WHERE Tipo__c = '01'
            LIMIT 1
        ];
        // Adicione asserts conforme a sua lógica
        // System.assertEquals(true, result.Executado__c);
    }

    @isTest
    static void testScheduleSeparatingOrderJob() {
        Test.startTest();
        SheduleSeparatingOrderSendEmail scheduleJob = new SheduleSeparatingOrderSendEmail();
        String jobId = System.schedule('Test Separating Order Job', '0 0 0 ? * * *', scheduleJob);
        Test.stopTest();

        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        // System.assertEquals('WAITING', ct.State);
    }
}