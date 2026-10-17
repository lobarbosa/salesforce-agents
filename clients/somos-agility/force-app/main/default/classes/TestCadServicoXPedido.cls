@IsTest(SeeAllData=true)
public with sharing class TestCadServicoXPedido {
	
	static testMethod void testCadSerXPed()
	{
		Test.startTest();
		
		PageReference pageRef = Page.cadServicoxPedido;
		Test.setCurrentPage(pageRef);
		clsCadServicoxPedido const1 = new clsCadServicoxPedido();
		
		String idServico = '';
		String idNegociacao = '';
		String idOportunidade = '';
        String idContaFatServ = '';
        String redict = '';
        String seguraCampo = '';
        String cambioGlobal = '';
        
        Negociacao_Comercial__c negCom = [SELECT Id FROM Negociacao_Comercial__c LIMIT 1];
        
        idNegociacao = negCom.Id;
        redict = '1';
        idServico = '2';
        seguraCampo = '0';
        cambioGlobal = '125.55';
        
        Servico_x_Pedido__c servPed = new Servico_x_Pedido__c();
        
        servPed.Negociacao_comercial__c = negCom.Id;
        Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(servPed);
        ApexPages.currentPage().getParameters().put('id', idServico);
        ApexPages.currentPage().getParameters().put('IdNegociacao', idNegociacao);
        //ApexPages.currentPage().getParameters().put('idOportunidade', idOportunidade);
        //ApexPages.currentPage().getParameters().put('idContaFatServ', idContaFatServ);
        ApexPages.currentPage().getParameters().put('Redict', redict);
        ApexPages.currentPage().getParameters().put('SeguraCampo', seguraCampo);
        ApexPages.currentPage().getParameters().put('CambioGlobal', cambioGlobal);
        const1 = new clsCadServicoxPedido(controller);
        seguraCampo = '1';
        ApexPages.currentPage().getParameters().put('SeguraCampo', seguraCampo);
        const1 = new clsCadServicoxPedido(controller);
        
        Categoria__c cat = [SELECT Id FROM Categoria__c WHERE Operacao__c = 'Saída' AND TIPO__c = 'SERVIÇO' LIMIT 1];
        Servico_x_Pedido__c svPed = [SELECT Id FROM Servico_x_Pedido__c LIMIT 1];
        Competencia__c comp = [SELECT Id FROM Competencia__c LIMIT 1];
        
        servPed = new Servico_x_Pedido__c();
        servPed.Negociacao_comercial__c = negCom.Id;
        servPed.Operacao_CFOP__c = cat.Id;
        servPed.Id = svPed.Id;
        //servPed.Local_da_Prestacao_de_Servicos__c = 'São Paulo - Capital';
        servPed.Competencia__c = comp.Id;
        cambioGlobal = null;
        servPed.Cambio__c = 123.12;
        controller = new Apexpages.Standardcontroller(servPed);
        const1 = new clsCadServicoxPedido(controller);
        clsCadServicoxPedido.RetornaCNPJDest('');
        const1.getOrigemFat();
        const1.getMoedaServ();
        clsCadServicoxPedido.CalculaVerba('2','3','10','São Paulo - Capital');
        
        controller = new Apexpages.Standardcontroller(servPed);
        const1 = new clsCadServicoxPedido(controller);

		const1.getLocalPrest();
		const1.ServPed.Local_da_Prestacao_de_Servicos__c = 'São Paulo - Capital';
		const1.ServPed.Competencia__c = comp.Id;
		const1.ServPed.Qtd_Horas_Horario_Comercial__c = 2;
		const1.ServPed.Qtd_Horas_Extraordinario__c = 2;
		const1.ServPed.Quantidade_Analistas__c = 2;
        const1.CalcularValorServicoFinal();
        const1.ServPed.Total_Final_dos_Servicos__c = 10;
		const1.CalcularValorServico();
		const1.ServPed.Total_dos_Servicos__c = 10;
		ServPed.CNPJ_de_Faturamento__c='0015000000OZGSR';
        const1.CalcularValorServicoRent();
        const1.CalcularValorServicoCusto();
        
        const1.getCompetencia();
        const1.getFasedaMetodlogia();
        const1.SalvarPedidoxServico();
        
        const1.idNegociacao = null;
        
        try
        {
        	const1.SalvarPedidoxServico();
        }
        catch (Exception e){}
        
        
        Test.stopTest();
	}
}