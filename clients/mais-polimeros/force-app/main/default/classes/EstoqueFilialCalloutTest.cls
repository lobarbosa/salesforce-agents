@IsTest
Global class EstoqueFilialCalloutTest {

    @testSetup static void setup() {

        List<Product2> lstProduct = new List<Product2>();
        lstProduct.add(new Product2(Name = 'BD-EB853/72',
                                    CodigoTotvs__c = 'BD-EB853/72',
                                    IsActive = true));
        insert lstProduct; 
    }

    @IsTest public static void test_method_one() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        EstoqueFilialCallout.botaoAtualizar();
        Test.stopTest();
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {	  

            HttpResponse res   = new HttpResponse();
            String endpoint    = 'http://200.182.100.227:9091/rest/ESTTOTAL';

            req.setEndpoint(endpoint);
            req.setMethod('GET');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ESTOQUE": [{"ITENS": [  {"PRODUTO":"BD-EB853/72","FILIAL":"01","QTDEATUAL":"20075","QTDERESERVA":"7025","QTDEDISPONIVEL":"13050","QTDECOMPRAS":"-24750","QTDESOLCOMPRAS":"24750","DATAULTIMASAI":"21/10/2019"}  	]}]}');

            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest public static void test_method_two() {
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account 1', NomeFantasia__c = 'Test Account 1'),
            new Account(Name = 'Test Account 2', NomeFantasia__c = 'Test Account 2')
        };
        insert testAccounts;

        Test.startTest();

        ApexPages.StandardSetController testController = new ApexPages.StandardSetController(testAccounts);
        EstoqueFilialCallout estoqueFilialCallout = new EstoqueFilialCallout(testController);

        System.assertNotEquals(null, estoqueFilialCallout, 'O objeto EstoqueFilialCallout não foi criado corretamente.');        
        Test.stopTest();
    }
}