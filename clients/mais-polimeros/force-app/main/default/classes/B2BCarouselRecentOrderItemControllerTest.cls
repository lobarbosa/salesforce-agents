@IsTest
public class B2BCarouselRecentOrderItemControllerTest {
    
    @TestSetup
    static void makeData(){
    //     CustAccountGroup__c cAGroup = new  CustAccountGroup__c(Name='Plant customer');
	// 	insert cAGroup;

    //     WebStore testWebStore = new WebStore(Name='MesserTest B2BL');
    //     insert testWebStore;

    //     Account filialAC = new Account(Name='ASU CUBATAO');
    //      filialAC.Customer__c= 'BR10XP4200';
    //      filialAC.CustAccountGroup__c = cAGroup.Id;
    //      insert filialAC;

    //    Account accFilial = new Account(
    //         Name = 'Conta de Teste',
    //         Customer__c = 'BR10XP4225',
    //         CnpjCpf__c = '46040242000178',
    //         CustAccountGroup__c = cAGroup.Id
    //     );
    //     insert accFilial;

    //     Account acc = new Account(
    //         Name = 'Conta de Teste',
    //       	CnpjCpf__c = '46040242000100',
    //         filial__c = accFilial.id
    //     );
    //     Database.Insert(acc);

    //     Contact ctt = new Contact(
    //         LastName = 'Testado',
    //         AccountId = acc.id,
    //         Email = 'teste.costa@teste.com.br',
    //         FuncaoOperacional__c = 'Contato para Pesquisa de Satisfação'
    //     );
    //     Database.Insert(ctt);

    //     Profile perfil = [ Select Id From Profile Where Name=: 'Administrador do sistema' OR Name=: 'System Administrator' Limit 1 ];

    //     User us = new User();
    //     us.Username = 'devtestuseritelios@it.com.br' + 'it12';
    //     us.Email = 'nome@sobrenome.com';
    //     us.LastName = 'Sobrenome';
    //     us.Alias = 'NSobre' + 'it';
    //     us.CommunityNickname = '123jjjuuu' + 'it12';
    //     us.EmailEncodingKey = 'ISO-8859-1';
    //     us.TimeZoneSidKey = 'GMT';
    //     us.LocaleSidKey = 'en_Us';
    //     us.LanguageLocaleKey = 'en_Us';
    //     us.ProfileId = perfil.Id;
    //     us.Phone = '+55 1337977103';
    //     Database.Insert(us);

    //     Case cs = new Case();
    //     cs.RecordTypeId = REC_TP;
    //     cs.cliente__c = 'Sim';
    //     cs.AccountId = acc.Id;
    //     cs.ContactId = ctt.Id;
    //     cs.OwnerId = us.Id;
    //     cs.Type = 'Tomada de Pedido';
    //     cs.motivoAux__c = 'Tomada de Pedido';
    //     cs.Origin = 'Telefone';
    //     cs.Status = 'Aberto';
    //     cs.fcr__c = 'Não';
    //     cs.MomentoAtribuicao__c = '1° Atribuição';
    //     cs.TipoOrdem__c = 'Pedido Gold';
    //     cs.alteraProprietario__c = true;
    //     Database.Insert(cs);

    //     Id standardPBID = Test.getStandardPricebookId();

    //     Product2 prod= new Product2();
    //     prod.Name = 'TesteProd';
    //     prod.IsActive = true;
    //     prod.ProductCode = 'Pro-X';
	// 	database.insert(prod);

    //     PricebookEntry PBE = new PricebookEntry();
    //     PBE.Pricebook2Id = Test.getStandardPricebookId();
    //     PBE.Product2Id=prod.id;
    //     PBE.UnitPrice=100;
    //     PBE.UseStandardPrice=false;
    //     PBE.isActive = true;
    //     Insert PBE;

    //     AbastecimentoLiquidos__c al = new AbastecimentoLiquidos__c();
    //     al.Name = 'BR-3798';
    //     al.Customer__c = acc.Id;
    //     al.Produto__c = prod.Id;
    //     al.PontoFixoEntrega__c = '8000';
    //     al.PontoMinimoEntrega__c = '4390';
    //     al.NivelStockOut__c = '1430';
    //     al.Capacidade_maxima_do_tanque__c = 14000;
    //     al.DFLT_DEPOT_ID__c = '218782';
    //     al.CustMaterial__c = 'BR104001132';
    //     al.Quantidade__c = 6;
    //     al.DeliveryPoint__c = 'BR-3798';
    //     al.NivelTanqueAtual__c = 14000;
    //     al.ResponsavelLeitura__c = 'Joao';
    //     al.DataHoraLeitura__c = system.Now();
    //     Database.Insert(al);

    //     Order od = new Order();

    //     od.AccountId = acc.Id;
    //     od.Status = 'Em análise';
    //     od.TipoOrdem__c = 'Pedido Gold';
    //     od.Caso__c = cs.Id;
    //     od.EffectiveDate = Date.today();
    //     od.OwnerId = us.Id;
    //     od.EndDate = Date.today();
    //     od.RFQColetiva__c = cs.fcr__c;
    //     od.NecessarioNPedidoNF__c = cs.NecessarioNPedidoNF__c;
    //     od.InformarNPedido__c = cs.InformarNPedido__c;
    //     od.NecessarioNItemXMLNF__c = cs.NecessarioNItemXMLNF__c;
    //     od.DataPedido__c = cs.DataPedido__c;
    //     od.NumeroOrdem__c = String.ValueOf(cs.numeroOrdem__c);
    //     od.OutrasInformacoesParaConstarNfe__c = cs.OutrasInformacoesParConstarNfe__c;
    //     od.InformacoesBloqueio__c = cs.informacaoBloqueio__c;
    //     od.Pricebook2Id = standardPBID;
    //     Database.Insert(od);

    //     OrderItem oi =  new OrderItem();
    //     oi.OrderId = od.Id;
    //     oi.Product2Id = prod.Id;
    //     oi.UnidadeMedida__c = 'M3';
    //     oi.PricebookEntryId = PBE.Id;
    //     oi.UnitPrice = 1.0;
    //     oi.Quantity = 7;
    //     oi.NivelTanque__c = 12000;
    //     oi.ModalidadePedida__c = 'Order Amount';
    //     Database.Insert(oi);
    }

    @isTest
    static void B2BCarouselRecentOrderItemControllerTest1(){
        Test.startTest();
        B2BCarouselRecentOrderItemController.provisoryCodeCoverage();
        B2BCarouselRecentOrderItemController.getRecentOrderProducts(3, 'Maior Quantidade', 12, 'http://testeURLLoja.com');
        B2BCarouselRecentOrderItemController.getRecentOrderProducts(3, 'Mais Pedidos', 12, 'http://testeURLLoja.com');
        B2BCarouselRecentOrderItemController.getRecentOrderProducts(3, 'Outros', 12, 'http://testeURLLoja.com');
        Test.stopTest();
    }
}