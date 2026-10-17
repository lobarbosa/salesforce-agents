@IsTest
global class ContaCategorizacaoTest {

    @TestSetup
    static void makeData() {

        String uniqueUserName = 'testuser' + DateTime.now().getTime() + '@testorg.com';
        Profile profile =   [   SELECT  Id 
                                FROM    Profile 
                                WHERE   Name = 'System Administrator' 
                                OR      Name = 'Administrador do sistema'   ];
   
        User user = new User( 

            Alias = 'polim'             , Email             = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8'  , LastName          ='Sistema', 
            LanguageLocaleKey = 'en_US' , LocaleSidKey      = 'en_US', 
            ProfileId = profile.Id      , TimeZoneSidKey    = 'America/Los_Angeles',
            UserName = uniqueUserName   , ByPassPB__c       = true

        );
        insert user;

		IntegrationParams__c param = new IntegrationParams__c(
            URI_API__c              = 'uri', 
            URI_PriceProcessor__c   = 'urip'

        );
		insert param;

        ParametrosGerais__c parametrosGerais = new ParametrosGerais__c(
            PercentualCorteClassificacao__c = 60.0,
            HorarioLimitePedido__c          = '17:30'

        );
        insert parametrosGerais;

        Municipio__c municipio = new Municipio__c(
            Name = 'MUNICIPIO'

        );
        insert municipio;

        Account acc = new Account(
            Name                = 'ACC TESTE',
            NomeFantasia__c = 'nome fantasia',
            Municipio__c        = municipio.Id, 
            MunicipioEntrega__c = municipio.Id,
            Classificacao__c    = 'Tipo A'
           
        );
        insert acc;

        acc.GrupoEconomicoIdInterno__c = acc.Id;
        update acc;
 
        Id pricebookId = Test.getStandardPricebookId();

        Pricebook2 catalogo = new Pricebook2(
            IsActive    = true,
            Name        = 'CATALOGO'

        ); 
        insert catalogo;

        Product2 produto = new Product2(
            Name            = 'PRODUTO',
            CodigoTotvs__c  = '0000000000000000000000'
        );
        insert produto;

        PricebookEntry entradaCatalogo = new PricebookEntry(
            IsActive            = true,
            Pricebook2Id        = catalogo.Id,
            Product2Id          = produto.Id,
            UnitPrice           = 10,
            UseStandardPrice    = false
        );
        insert entradaCatalogo;

    }

    global class MockHttpResponseAtt implements HttpCalloutMock {
		
		global HTTPResponse respond(HTTPRequest req) {	  

			HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [	SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c	];    
			String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_OrderProcessor__c');

			req.setEndpoint(endpoint + uriStorage);
			req.setMethod('POST');
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"CLIENTES": [{ "CLIENTE": [{ "CODIGO":"00000601", "EMAILNFE":"josef.plasticos@hotmail.com", "MENSAGEM":"Cliente Alterado com sucesso!" }] }] }');
			res.setStatusCode(201);
			return res;

	    }
	}

    @isTest
    public static void atualizarClassificacaoTestTipoA() { 

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1    ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 6; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(
                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem; 

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo A', contaAtualizada.Classificacao__c , 'TIPO A --> Grupo Econômico comprou em todos os últimos 6 meses, mantendo a média de volume');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoB_ComprouSeisMeses_NaoManteveVolume() { //ok

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1 ];
 
        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 6; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        Integer acrecentaVolume = 0;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(
                OrderId          = o.Id,
                Quantity         = 1000 + acrecentaVolume,
                UnitPrice        = 100,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            acrecentaVolume -= 166;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem; 

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo B', contaAtualizada.Classificacao__c , 'TIPO B --> Grupo Econômico comprou em todos os últimos 6 meses, mas não manteve a média de volume');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoB() {

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1 ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1 ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1    ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 5; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo B', contaAtualizada.Classificacao__c , 'TIPO B --> Grupo Econômico que nos últimos 6 meses, comprou em 5 meses');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoC() {

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1 ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1 ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1   ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 4; i++) {

            Order ordem = new Order(

                AccountId = acc.Id,
                EffectiveDate = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status = 'Faturamento',
                Pricebook2Id = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo C', contaAtualizada.Classificacao__c , 'TIPO C --> Grupo Econômico que nos últimos 6 meses, comprou em 4 meses.');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoD() {

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1 ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 3; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo D', contaAtualizada.Classificacao__c , 'TIPO D --> Grupo Econômico que nos últimos 6 meses, comprou conosco em 3 meses.');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoE_IncidenciaDeCompraDoisMeses() {

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1 ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 2; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo E', contaAtualizada.Classificacao__c , 'TIPO E --> Grupo Econômico que nos últimos 6 meses, comprou em 2 e ou 1 mês.');
 
    }

    @isTest
    public static void atualizarClassificacaoTestTipoE_IncidenciaDeCompraUmMes() {

        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1 ];

        Integer decrementoOrdem = -1;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 1; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo E', contaAtualizada.Classificacao__c , 'TIPO E --> Grupo Econômico que nos últimos 6 meses, comprou em 2 e ou 1 mês.');

    }

    @isTest
    public static void atualizarClassificacaoTestTipoSC() {


        User u                          = [ SELECT Id, ByPassPB__c FROM User WHERE Alias = 'polim' LIMIT 1  ];

        Account acc                     = [ SELECT Id FROM Account WHERE Name = 'ACC TESTE' LIMIT 1 ];

        Pricebook2 catalogo             = [ SELECT Id FROM Pricebook2 WHERE Name = 'CATALOGO' LIMIT 1   ];

        Product2 produto                = [ SELECT Id FROM Product2 LIMIT 1   ];

        PricebookEntry entradaCatalogo  = [ SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: catalogo.Id  LIMIT 1 ];

        Integer decrementoOrdem = -7;
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i < 1; i++) {

            Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(decrementoOrdem)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id

            );
            decrementoOrdem--;
            lstOrder.add(ordem);
        } 
        insert lstOrder;

        Integer decrementoItem = -7;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Order o : lstOrder) {

            OrderItem itemPedido = new OrderItem(

                OrderId          = o.Id,
                Quantity         = 10,
                UnitPrice        = 10,
                Product2Id       = produto.Id,
                Status__c        = 'Faturado',
                PricebookEntryId = entradaCatalogo.Id,
                DataEntrega__c   = System.today().addMonths(decrementoItem)

            );
            decrementoItem--;
            lstOrderItem.add(itemPedido);
        } 
        insert lstOrderItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAtt());
        System.runAs(u) {

            Test.startTest();
               ContaCategorizacao.atualizarClassificacao(true);
            Test.stopTest();
        } 

        Account contaAtualizada = [ SELECT Id, Name, Classificacao__c, GrupoEconomicoIdInterno__c FROM Account LIMIT 1 ];
        System.assertEquals('Tipo SC', contaAtualizada.Classificacao__c , 'Grupo Econômico que esta sem compras há mais de 6 meses. Se é cadastrado um grupo Econômico novo, esse entra direto no TIPO SC.');
        
    }
}