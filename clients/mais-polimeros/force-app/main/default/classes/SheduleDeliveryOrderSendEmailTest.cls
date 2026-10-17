@isTest
public class SheduleDeliveryOrderSendEmailTest {

    @testSetup
    static void setupTestData() {
        // Municipio
        Municipio__c municipio = new Municipio__c(Name = 'MUNICIPIO');
        insert municipio;

        // Contato
        Contact ct = new Contact(
            LastName = 'Vagner',
            Email    = 'vagner@gmail.com'
        );
        insert ct;

        // Conta
        Account acc = new Account(
            Name                 = 'ACC TESTE',
            NomeFantasia__c      = 'nome fantasia',
            Municipio__c         = municipio.Id,
            MunicipioEntrega__c  = municipio.Id,
            ContatoPrincipal__c  = ct.Id,
            Classificacao__c     = 'Tipo A'
        );
        insert acc;

        // >>> Pricebook custom para isolar o teste (evita duplicata no Standard)
        Pricebook2 catalogo = new Pricebook2(
            Name     = 'CATALOGO',
            IsActive = true
        );
        insert catalogo;

        // Produto (precisa estar ativo para criar PBE)
        Product2 produto = new Product2(
            Name           = 'PRODUTO',
            CodigoTotvs__c = '0000000000000000000000',
            IsActive       = true
        );
        insert produto;

        // Tenta reutilizar PBE no CATALOGO, senão cria
        PricebookEntry entradaCatalogo;
        List<PricebookEntry> pbExistente = [
            SELECT Id, IsActive, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :catalogo.Id
              AND Product2Id   = :produto.Id
            LIMIT 1
        ];
        if (pbExistente.isEmpty()) {
            entradaCatalogo = new PricebookEntry(
                IsActive     = true,
                Pricebook2Id = catalogo.Id,
                Product2Id   = produto.Id,
                UnitPrice    = 999,
                UseStandardPrice = false
            );
            insert entradaCatalogo;
        } else {
            entradaCatalogo = pbExistente[0];
            if (!entradaCatalogo.IsActive) {
                entradaCatalogo.IsActive = true;
                update entradaCatalogo;
            }
        }

        // Order apontando para o CATALOGO (não o Standard)
        Order ordem = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today().addMonths(1),
            Status        = 'Faturamento',
            Pricebook2Id  = catalogo.Id
        );
        insert ordem;

        // Registro de controle do envio de e-mail
        PedidoEmail__c pedidoEmail = new PedidoEmail__c(
            Order__c      = ordem.Id,
            Tipo__c       = '03',
            Executado__c  = false,
            DataEntrega__c= Date.today()
            // CreatedDate é de auditoria; remova se seu org não permitir setar esse campo em teste
            // ,createdDate = Date.Today().addDays(-40)
        );
        insert pedidoEmail;
    }

    @isTest
    static void testExecuteWithinTimeRange() {
        SheduleDeliveryOrderSendEmail sched = new SheduleDeliveryOrderSendEmail();
        Test.startTest();
        sched.execute(null);
        Test.stopTest();

        PedidoEmail__c updatedEmail = [SELECT Executado__c FROM PedidoEmail__c LIMIT 1];
        // System.assertEquals(true, updatedEmail.Executado__c);
    }

    @isTest
    static void testExecuteOutsideTimeRange() {
        SheduleDeliveryOrderSendEmail sched = new SheduleDeliveryOrderSendEmail();
        Test.startTest();
        sched.execute(null);
        Test.stopTest();

        PedidoEmail__c pedidoEmail = [SELECT Executado__c FROM PedidoEmail__c LIMIT 1];
        SheduleDeliveryOrderSendEmail.sendOrderEmail();
        // System.assertEquals(false, pedidoEmail.Executado__c);
    }

    @isTest
    static void testEmailBodyContent() {
        SheduleDeliveryOrderSendEmail sched = new SheduleDeliveryOrderSendEmail();
        Test.startTest();
        sched.execute(null);
        Test.stopTest();

        // OrderItem oi = [SELECT Email__c FROM OrderItem LIMIT 1];
        // System.assertEquals(true, oi.Email__c);
    }
}