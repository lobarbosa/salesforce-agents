@isTest(SeeAllData=true)
private class clsTestCadtLocacaoxPedido {
	//Pega um produto da lista de produtos dentro do salesforce
	public static Produto_NewAge__c ProdNEw = [SELECT Cod_Linha_Negocios__c,Cod_Sublinha_de_Produtos__c,CreatedById, 
	        									Id_NewAge_Prodruto__c,Codigo_do_Fabricante__c,LastActivityDate, 
	        									LastModifiedDate,CreatedDate,Dt_Ultima_Atualizacao__c, 
	        									Descricao__c,Desc_Linha_Negocios__c,Desc_Sublinha_de_Produtos__c, 
	        									IsDeleted,OwnerId,Id,SystemModstamp, 
	        									NCM__c,Nome_do_Fabricante__c,Name, 
	        									PartNumber__c, Produto_Sel__c, Tipo__c, Tipo_de_Produto__c, 
	        									LastModifiedById 
	        							FROM 	Produto_NewAge__c where Tipo_de_Produto__c = 'Produto Acabado' Limit 1];
	//Captura uma oportunidade dentro do sistema
	public static Opportunity opp = [SELECT FiscalYear, Cargo__c, Categoria__c, ForecastCategoryName,CloseDate, 
											ForecastCategory, Contato__c, Contrato__c,  
											Data_Limite__c,
											Data_de_validade_da_Proposta_Comercial__c, Departamento__c, 
											Description, Cambio_Global__c, IsDeleted, FRM_Comercial_Proposta__c, 
											StageName, IsClosed, IsWon, CampaignId, AccountId, Pricebook2Id, 
											OwnerId, SyncedQuoteId, Imposto_Locacao__c, 
											Motivo_SE__c, Motivo__c, Negociacao_Comercial__c, Name, 
											N_mero_da_Oportunidade__c, Opp_Qualifica_para_KPI_de_Pipe__c, 
											LeadSource, Fiscal, Probability, Certeza_do_Fechamento__c, 
											Pr_ximo_Passo__c, Renova_ao_ano_anterior__c, Amount, 
											Rentabilidade_Final__c, Requisitar_SE_para_o_Projeto__c, 
											Respons_vel_pelo_Pr_ximo_Passo__c, SE_SA_Reponsavel__c, 
											HasOpportunityLineItem, Total_Custo_Geral_Locacao__c, 
											Total_Custo_Geral_Produto__c, Total_Custo_Geral_Servico__c, 
											Total_Receita_Geral_Locacao__c, Total_Receita_Geral_Produto__c, 
											Total_Receita_Geral_Servico__c, Total_Rentabilidade_Bruta_Locacao__c, 
											Total_Rentabilidade_Bruta_Produto__c, Total_Rentabilidade_Bruta_Servico__c, Total_Rentabilidade_Liquida_Locacao__c, 
											Total_Rentabilidade_Liquida_Produto__c, Total_Rentabilidade_Liquida_Servico__c, Total_da_Locacao__c, 
											Total_dos_Produtos_Contrato_Suporte__c, Total_dos_Produtos__c, Total_Mao_de_Obra_Contrato_Suporte__c, 
											Total_dos_Servicos__c 
											FROM Opportunity  
											where CreatedDate >= 2014-03-17T00:00:00.000z 
											and  CreatedDate <= 2014-03-24T00:00:00.000z 
											
											Limit 1];
	//Captura o fornecedor do produto;
	public static Account accFornecedor =[Select id,name from Account where Fornecedor__c=true limit 1];
	//Captura o Cliente;
	public static Account accCliente =[Select id,name from Account where Cliente__c=true limit 1];
	//Captura a Conta de Faturamento;
	public static Account accFat =[SELECT Id,Name 
	                         FROM   Account 
	                         where  Conta_de_Faturamento_Agility__c=true
	                                and name not in ('Agility Networks Support Services','Agility Networks Tecnologia ES') Limit 1];
	//Captura o Prazo de duração
	public 	static Prazo_do_contrato__c prazo=[Select id,name from Prazo_do_contrato__c Limit 1];
	//Captura o tipo de faturamento
	public 	static Tipo_de_Faturamento__c tpfat = [Select id,name from Tipo_de_Faturamento__c Limit 1];
	//Captura o CFOP de Compra
	public static Categoria__c catCompra=[Select id,name from Categoria__c where Codigo_NewAge__c='1.01.02' Limit 1];
	//Captura o CFOP de Venda
	public static Categoria__c catVenda=[Select id,name from Categoria__c where Codigo_NewAge__c='2.06.01' Limit 1];
	//Captura a condição de Pagamento
	public static Condicao_Pagamento__c CondPag = [Select id,name from Condicao_Pagamento__c Limit 1];
    static testMethod void TestCadLocacaoProd() {
    	//Opportunity opp = new Opportunity();
    	//opp = Objpp;
    	//opp.id=null;
    	//insert opp;
    	opp.Imposto_Locacao__c=1;
    	update opp;
    	clsCadLocacaoxPedido CadLoc = new clsCadLocacaoxPedido();
        CadLoc.idProduto=ProdNew.Id;
        CadLoc.idOportunidade=opp.Id;
        
        Pagereference testePage = Page.CadLocacaoxPedido;
        testePage.getParameters().put('idOportunidade', opp.id);
        testePage.getParameters().put('CambioGlobal', '4');
        Test.setCurrentPage(testePage);
        Test.StartTest();
        clsCadLocacaoxPedido controller = new clsCadLocacaoxPedido();
        //controller.getMoedaProd();
        controller.getOrigemFat();
        Locacao_x_Pedido__c locPed = new Locacao_x_Pedido__c();
        locPed.Cambio__c=0;
        locPed.Cotacao_do_Dolar__c=0;
        locPed.CNPJ_de_Faturamento__c=accFat.Id;
        locPed.CNPJ_Destino__c=accCliente.Id;
        locPed.Operacao_CFOP__c=catVenda.id;
        locPed.Condicao_de_Pagamento__c=CondPag.id;
        locPed.Markup__c=2;
        locped.Prazo_de_Duracao__c=prazo.id;
        locped.Tipo_de_Faturamento__c=tpfat.id;

		Apexpages.Standardcontroller SalvarClasse = new Apexpages.Standardcontroller(locPed);
		clsCadLocacaoxPedido clsSalvar = new clsCadLocacaoxPedido(SalvarClasse);
        clsSalvar.SalvarPedidoxLocacao();
        //Cria os produtos para a locação
        locped.Produto_NewAge__c=ProdNEw.id;
        locped.Fornecedor__c=accFornecedor.id;
        locped.Categoria_de_Compra__c=catCompra.id;
        locped.Moeda_Compra__c='Real';
        locped.Cotacao_Compra__c=0;
        locped.Quantidade__c=1;
        locped.Valor_do_produto__c=1000;
        locped.Condicao_de_Pagamento_Compra__c=CondPag.id;
        locped.Leasing__c='Não';
        locped.Condicao_de_Pagamento_Prod__c=condpag.id;
        locped.Categoria__c=catVenda.id;
        locped.Moeda_Prod__c='Real';
        locped.Cotacao_do_Dolar_Prod__c=0;
        locped.Condicao_de_Pagamento_Prod__c=condpag.id;
        locped.Valor_do_Suporte_Produto__c=200;
        clscadLocacaoxPedido.RetornaDescricao(ProdNew.id);
        clscadLocacaoxPedido.RetornaFornecedor(accFornecedor.id);
        clscadLocacaoxPedido.RetornaCNPJDest(accCliente.id);
        clsSalvar.SalvarLocacaoProduto();
        
        Test.StopTest();
        
    }
    
    
    static testMethod void TestCadLocacao(){
    	//Opportunity opp = new Opportunity();
    	//opp = Objpp;
    	//opp.id=null;
    	//insert opp;
    	opp.Imposto_Locacao__c=1;
    	update opp;
        clsCadLocacaoxPedido CadLoc = new clsCadLocacaoxPedido();
        CadLoc.idProduto=ProdNew.Id;
        CadLoc.idOportunidade=opp.Id;
        Pagereference testePage = Page.CadLocacaoxPedido;
        testePage.getParameters().put('idOportunidade', opp.id);
        Test.setCurrentPage(testePage);
        Test.StartTest();
        clsCadLocacaoxPedido controller = new clsCadLocacaoxPedido();
        //controller.getMoedaProd();
        controller.getOrigemFat();
        Locacao_x_Pedido__c locPed = new Locacao_x_Pedido__c();
        locPed.Cambio__c=0;
        locPed.Cotacao_do_Dolar__c=0;
        locPed.CNPJ_de_Faturamento__c=accFat.Id;
        locPed.CNPJ_Destino__c=accCliente.Id;
        locPed.Operacao_CFOP__c=catVenda.id;
        locPed.Condicao_de_Pagamento__c=CondPag.id;
        locPed.Markup__c=2;
        locped.Prazo_de_Duracao__c=prazo.id;
        locped.Tipo_de_Faturamento__c=tpfat.id;
        
        
		Apexpages.Standardcontroller SalvarClasse = new Apexpages.Standardcontroller(locPed);
		clsCadLocacaoxPedido clsSalvar = new clsCadLocacaoxPedido(SalvarClasse);
		
        clsSalvar.SalvarPedidoxLocacao();
        //clsCadProdutoxPedido.RetornaValor('2','1000');
        //clsCadProdutoxPedido.RetornaDescricao(ProdNew.id);
        //clsCadProdutoxPedido.RetornaFornecedor(accFornecedor.id);
        //clsCadProdutoxPedido.RetornaCNPJDest(accCliente.id);
        Test.StopTest();
      
    }
}