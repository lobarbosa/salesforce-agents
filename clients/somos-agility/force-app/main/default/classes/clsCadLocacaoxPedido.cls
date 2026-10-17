global with sharing class clsCadLocacaoxPedido {
		public String idNegociacao {get;set;}
		public String idOportunidade {get;set;}
		public String idLocacao {get;set;}
		public String idProduto {get;set;}
		public String Redict{get;set;}
		public String mostrarAdendo{get;set;}
		public String Editar{get;set;}
		public String msgRetorno {get;set;}
		public String Tipo {get;set;}
        public String Idex {get;set;}
        public String ObjectName{get;set;}
	 	public List<sObject> sObjectList{get;set;}
	 	public String QueryString;
	 	public List<string> fieldList{get;set;}
	 	public static String DescProd{get;set;}
		private final Locacao_x_Pedido__c LocPed;
        public String ReadOnly{get;set;}
		public String DisabledField{get;set;}
		public String mBotao{get;set;}
		public String strCFOP{get;set;}
		public static String DescForn{get;set;}
		public String idContaFatLoc{get;set;}
		public String CambioGlobal{get;set;}
        public clsCadLocacaoxPedido(ApexPages.StandardController controller) {
        	//Campos para serem realizados os requests
			idLocacao = ApexPages.currentPage().getParameters().get('id');
            idNegociacao = ApexPages.currentPage().getParameters().get('IdNegociacao');
            idOportunidade = ApexPages.currentPage().getParameters().get('idOportunidade');
            idProduto = ApexPages.currentPage().getParameters().get('idProduto');
            Redict = ApexPages.currentPage().getParameters().get('Redict');
            Editar = ApexPages.currentPage().getParameters().get('Editar');
            idContaFatLoc = ApexPages.currentPage().getParameters().get('idContaFatLoc');
            CambioGlobal = ApexPages.currentPage().getParameters().get('CambioGlobal');
            System.debug('IdNegociacao : ' + idNegociacao);
            if(idNegociacao!='' && idNegociacao !=null && idNegociacao!='null'){
            	Negociacao_Comercial__c NegoCom = [Select id,Status_Negociacao__c from Negociacao_Comercial__c where id=:idNegociacao];
            	ReadOnly=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
				DisabledField=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
				mBotao=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'none':'block');
            }
            //================================================================
			mostrarAdendo='none';
			this.LocPed=(Locacao_x_Pedido__c)controller.getRecord();
			//2.06.01
			if(LocPed.id==null){
                	Categoria__c cat = [select id,Codigo_NewAge__c from Categoria__c where Codigo_NewAge__c='2.06.01' limit 1];
                	//Categoria__c catCompra = [select id,Codigo_NewAge__c from Categoria__c where Codigo_NewAge__c='1.01.16' limit 1];
                	LocPed.Operacao_CFOP__c = cat.id;
                	//LocPed.Operacao_CFOP_Compra__c = catCompra.Id;
                	strCFOP = cat.Codigo_NewAge__c;
                }
                else{
                	Categoria__c cat = [select id,Codigo_NewAge__c from Categoria__c where id=:LocPed.Operacao_CFOP__c];
                	//ServPed.Operacao_CFOP__c = cat.id;
                	strCFOP = cat.Codigo_NewAge__c;
                	idContaFatLoc =LocPed.CNPJ_de_Faturamento__c;
                	//Categoria__c catCompra = [select id,Codigo_NewAge__c from Categoria__c where Codigo_NewAge__c='1.01.16' limit 1];
                	//LocPed.Operacao_CFOP_Compra__c = catCompra.Id;
                }
			 if (Redict!='0' && idLocacao!= null && idLocacao!=''){
                	Negociacao_Comercial__c nc = [Select id from Negociacao_Comercial__c where id=:LocPed.Negociacao_Comercial__c];
                	idNegociacao=nc.id;
                	Redict='1';
                }
                 
                if(Editar=='1' && idProduto!='' && idProduto !=null){
                    Produto_x_Locacao__c pcs = [Select  id,
                    									Produto_NewAgePr__c,
                    									Condicao_de_Pagamento_Compra__c,
                    									Fornecedor__c,
                    									Categoria_de_Compra__c,
                    									Moeda_Compra__c,
                    									Cotacao_Compra__c,
                    									Quantidade__c,
                    									Valor_do_produto__c,
                    									Condicao_de_Pagamento__c,
                    									Moeda__c,
                    									Cotacao_do_Dolar__c,
                    									Categoria_vend__c,
                    									Ativos_Cobertos__c,
                    									Inclui_RMA_de_Hardware__c,
                    									Leasing__c,
                    									Suporte_do_Item_Locado__c,
                    									valor_do_suporte__c 
                    							from 	Produto_x_Locacao__c
                    							where 	id =:idProduto];
                	LocPed.Produto_NewAge__c=pcs.Produto_NewAgePr__c;
         			LocPed.Condicao_de_Pagamento_Compra__c=pcs.Condicao_de_Pagamento_Compra__c ;
         			LocPed.Fornecedor__c=pcs.Fornecedor__c ;
         			LocPed.Categoria_de_Compra__c=pcs.Categoria_de_Compra__c;
         			LocPed.Moeda_Compra__c=pcs.Moeda_Compra__c;
         			LocPed.Cotacao_Compra__c=pcs.Cotacao_Compra__c;
         			LocPed.Quantidade__c=pcs.Quantidade__c;
         			LocPed.Valor_do_produto__c=pcs.Valor_do_produto__c;
         			LocPed.Condicao_de_Pagamento_Prod__c=pcs.Condicao_de_Pagamento__c;
         			LocPed.Moeda_Prod__c=pcs.Moeda__c;
         			LocPed.Cotacao_do_Dolar_Prod__c=pcs.Cotacao_do_Dolar__c;
         			LocPed.Categoria__c=pcs.Categoria_vend__c;
         			LocPed.Ativos_Cobertos__c=pcs.Ativos_Cobertos__c;
         			LocPed.Inclui_RMA_de_Hardware__c=pcs.Inclui_RMA_de_Hardware__c;
         			LocPed.Leasing__c=pcs.Leasing__c;
         			LocPed.Suporte_do_Item_Locado__c = pcs.Suporte_do_Item_Locado__c;
         			LocPed.Valor_do_Suporte_Produto__c = pcs.valor_do_suporte__c;
         			//CambioGlobal=pcs.Cotacao_do_Dolar__c;
                }
                
               if(CambioGlobal!=null && CambioGlobal.indexof(',') < 0 && CambioGlobal!='null' && CambioGlobal!=''){
                	Double dCambio=Double.valueof(CambioGlobal);
                    List<String> args = new String[]{'0','number','###,###,##0.00'};
                    CambioGlobal= String.format(dCambio.format(), args);
                   }
                   
                if(LocPed.id!=null){
                		mostrarAdendo='block';
                	}
    	}
      public clsCadLocacaoxPedido() {

    	}
    
     public List<selectOption> getMoedaLocacao() {
    	SincronizaNewAge sinc = new SincronizaNewAge();
        List<selectOption> options = sinc.getMoedaGenerico(); 
        return options; //return the picklist options
    }
    
    public List<selectOption> getOrigemFat() {
        List<selectOption> options = new List<selectOption>(); 
        //options.add(new selectOption('', '- None -')); 
        for (Account comp : [SELECT Id, Name FROM Account where Conta_de_Faturamento_Agility__c=true and Name NOT IN ('Agility Networks Support Services','Agility Networks Tecnologia ES')]) { 
            options.add(new selectOption(comp.id, comp.Name)); 
        }
        return options; //return the picklist options
    }
    public PageReference SalvarPedidoxLocacao(){
    	SincronizaNewAge sinc = new SincronizaNewAge();
          Pagereference reference;
             //Metodo para realizar a gravação da nova negociação;
             if(idNegociacao==null || idNegociacao.trim()==''){
                    // Será necessario criar uma negociacao nova dentro do sistema
                    clsCadNegociacaoComercial NegociacaoComercial = new clsCadNegociacaoComercial();
                    idNegociacao = NegociacaoComercial.CriaNegociacao(idOportunidade);
                    LocPed.Negociacao_Comercial__c=idNegociacao;
             }
             else{
             	LocPed.Negociacao_Comercial__c=idNegociacao;
             }
             if(idLocacao!=null && idLocacao!=''){
         			LocPed.Id=idLocacao;
         	}
         	
         	if(sinc.ValidaMarkup(locped.CNPJ_de_Faturamento__c, locped.Markup__c,Userinfo.getUserId())){
	         	Negociacao_Comercial__c nego = [Select id,Sincronizado__c,oportunidade__c from Negociacao_Comercial__c where id =:idNegociacao];
	         	nego.Sincronizado__c=false;
	         	update nego;
	         	locped.oportunidade__c=nego.Oportunidade__c;
	         	LocPed.Total_geral_locacao__c=CalcularLocacao();
	            LocPed.Valor_Total_dos_Produtos__c=CalcularTotProd();
	            Locacao_x_Pedido__c lc =CalculaValoresLocacao(LocPed);
         		upsert lc;
	            
	             if(LocPed.id!=null){
	             	msgRetorno='Cadastro realizado com sucesso !';
	             	reference = new Pagereference('/apex/cadLocacaoxPedido?idNegociacao=' + idNegociacao + '&id=' +LocPed.id +'&Redict=1&CambioGlobal=' + CambioGlobal  );
	             	
	             }
	             else{
	             	msgRetorno='Cadastro não realizado com sucesso !';
	             }
              }
                 else{
                 	msgRetorno='Cadastro não realizado com sucesso, markup abaixo do esperado !';
                 }
             //ContSup.Id=null;
             reference.setRedirect(true);
             return reference;
    	}
    public Decimal CalcularLocacao(){
    	Decimal vlrTotSuporte=0;
    	Decimal TotalProd=0;
    	Decimal total=0;
    	//vlrTotProd1An=(LocPed.Valor_total_produtos_1_ano__c==null?0:LocPed.Valor_total_produtos_1_ano__c);
    	//vlrTotSuporte=(LocPed.Valor_da_parcela_de_suporte__c==null?0:LocPed.Valor_da_parcela_de_suporte__c);
    	//Calcula o total dos Produtos
    	List<aggregateResult> vlrTotProd = [	SELECT 	Sum(Valor_do_produto__c) vlrProd,
    													Sum(Valor_do_Suporte__c) vlrSuporte
						    					FROM 	Produto_x_Locacao__c 
						    					WHERE 	Locacao_x_Pedido__c = :LocPed.Id ];
		if(!vlrTotProd.isEmpty()){TotalProd += Double.valueOf((vlrTotProd[0].get('vlrProd')==null?0:vlrTotProd[0].get('vlrProd')));}
		if(!vlrTotProd.isEmpty()){vlrTotSuporte += Double.valueOf((vlrTotProd[0].get('vlrSuporte')==null?0:vlrTotProd[0].get('vlrSuporte')));}
		total=TotalProd+vlrTotSuporte;
    	return total;
    }
   public Decimal CalcularTotProd(){
    	Decimal TotalProd=0;
    	Decimal ValorProd=0;
    	Decimal QTD=0;
    	//Calcula o total dos Produtos
    	List<aggregateResult> vlrTotProd = [	SELECT 	Sum(Valor_do_produto__c) vlrProd,sum(Quantidade__c) QTD
						    					FROM 	Produto_x_Locacao__c 
						    					WHERE 	Locacao_x_Pedido__c = :LocPed.Id 
						    					group by Produto_NewAgePr__c];
		for(aggregateResult agr : vlrTotProd){
			if(!vlrTotProd.isEmpty()){
				ValorProd=Double.valueOf((agr.get('vlrProd')==null?0:agr.get('vlrProd')));
				QTD=Double.valueOf((agr.get('QTD')==null?0:agr.get('QTD')));
					TotalProd += ValorProd*QTD;
			}
		}
    	return TotalProd;
    }
     public Decimal CalcularTotSuporte(){
    	Decimal TotalSuporte=0;
    	//Calcula o total dos Produtos
    	List<aggregateResult> vlrTotProd = [	SELECT 	Sum(Valor_do_Suporte__c) vlrSuporte
						    					FROM 	Produto_x_Locacao__c 
						    					WHERE 	Locacao_x_Pedido__c = :LocPed.Id ];
		if(!vlrTotProd.isEmpty()){TotalSuporte += Double.valueOf((vlrTotProd[0].get('vlrSuporte')==null?0:vlrTotProd[0].get('vlrSuporte')));}
    	return TotalSuporte;
    }
    public Locacao_x_Pedido__c CalculaValoresLocacao(Locacao_x_Pedido__c xLocPed){
    	Locacao_x_Pedido__c rLoc=xLocPed;
    	//Captura o prazo de duração para calculo
    	Prazo_do_contrato__c pc = [Select 	id,
    										Coeficiente_Locacao__c,
    										Imposto_Seguro_Ano__c,
    										INSS__c,
    										Verba_TC__c,
    										Name 
    								from 	Prazo_do_contrato__c 
    								where 	id=:rLoc.Prazo_de_Duracao__c];
    	Negociacao_Comercial__c nc = [Select 	id,
    											Negociacao_Comercial__c.Oportunidade__r.Imposto_Locacao__c
    								from 	Negociacao_Comercial__c 
    								where 	id=:rLoc.Negociacao_Comercial__c];
    	
		//Converte os valores em %
		Double coeficiente = Double.valueOf(pc.Coeficiente_Locacao__c/100);
		Double Imposto_Seguro_Ano = Double.valueOf(pc.Imposto_Seguro_Ano__c/100);
		Double INSS = Double.valueOf(pc.INSS__c/100);
		Double Verba_TC = Double.valueOf(pc.Verba_TC__c/100);
		Double Imposto_Locacao = Double.valueOf(nc.Oportunidade__r.Imposto_Locacao__c/100);
		Double Cambio = (rLoc.Cotacao_do_Dolar__c==0 || rLoc.Cotacao_do_Dolar__c==null?1: rLoc.Cotacao_do_Dolar__c);
		cambio=(rLoc.Cambio__c==0 || rLoc.Cambio__c==null?1: rLoc.Cambio__c);
		Decimal prazo = Decimal.valueOf(pc.name);
		if(rloc.Valor_Total_dos_Produtos__c != null && rloc.Valor_total_do_suporte__c !=null){
			//Realiza os devidos calculos:
			rLoc.Seguro_Ano__c= (Imposto_Seguro_Ano * rloc.Valor_Total_dos_Produtos__c)*Cambio;
			rLoc.Seguro_Mes__c= (rLoc.Seguro_Ano__c*((prazo/12)))/prazo;
			//rLoc.Seguro_Mes__c= rLoc.Seguro_Ano__c;
			rloc.Custo_Produtos__c = (rloc.Valor_Total_dos_Produtos__c * Cambio);
			rloc.Valor_total_sem_juros__c=rloc.Custo_Produtos__c*rloc.Markup__c;
			rloc.Parcela_sem_juros__c = rloc.Valor_total_sem_juros__c/prazo;
			rloc.Parcela_com_juros__c=(rloc.Valor_total_sem_juros__c*coeficiente)+rLoc.Seguro_Mes__c;
			rloc.Valor_total_locacao__c=rloc.Parcela_com_juros__c*prazo;
			rloc.Impostos_Locacao__c=(Imposto_Locacao*rloc.Valor_total_locacao__c)*(-1);
			rloc.Juros__c=rloc.Valor_total_sem_juros__c-rloc.Valor_total_locacao__c;
			rloc.INSS__c=((INSS+Verba_TC) * rloc.Valor_total_locacao__c)*(-1);
			rloc.Valor_total_produtos_1_ano__c=rloc.Parcela_com_juros__c+rloc.Valor_total_do_suporte__c;
			rloc.Margem_Bruta__c=rloc.Valor_total_locacao__c+rloc.Impostos_Locacao__c+rloc.Juros__c+(rloc.Custo_Produtos__c*(-1))+rloc.INSS__c;
			rloc.Rentabilidade_liquida__c=rloc.Margem_Bruta__c-(rloc.Margem_Bruta__c * 0.1);
			//rloc.Rentabilidade_liquida__c=25000;
		}
    	return rLoc;
    }
    public PageReference SalvarLocacaoProduto(){
    	Pagereference reference;
    	msgretorno='';
    	try{
         //Cria o objeto de produto para ser cadastrado dentro do sistema.
         Produto_x_Locacao__c pcs = new Produto_x_Locacao__c();
         pcs.Locacao_x_Pedido__c= LocPed.id;
         pcs.Negociacao_Comercial__c = LocPed.Negociacao_Comercial__c;
 			pcs.Produto_NewAgePr__c=LocPed.Produto_NewAge__c;
 			pcs.Condicao_de_Pagamento_Compra__c=LocPed.Condicao_de_Pagamento_Compra__c ;
 			pcs.Fornecedor__c=LocPed.Fornecedor__c ;
 			pcs.Categoria_de_Compra__c=LocPed.Categoria_de_Compra__c;
 			pcs.Moeda_Compra__c=LocPed.Moeda_Compra__c;
 			pcs.Cotacao_Compra__c=LocPed.Cotacao_Compra__c;
 			pcs.Quantidade__c=LocPed.Quantidade__c;
 			pcs.Valor_do_produto__c=LocPed.Valor_do_produto__c;
 			pcs.Condicao_de_Pagamento__c=LocPed.Condicao_de_Pagamento_Prod__c;
 			pcs.Moeda__c=LocPed.Moeda_Prod__c;
 			pcs.Cotacao_do_Dolar__c=LocPed.Cotacao_do_Dolar_Prod__c;
 			pcs.Categoria_vend__c=LocPed.Categoria__c;
 			pcs.Ativos_Cobertos__c=LocPed.Ativos_Cobertos__c;
 			pcs.Inclui_RMA_de_Hardware__c=LocPed.Inclui_RMA_de_Hardware__c;
 			pcs.Leasing__c=LocPed.Leasing__c;
 			pcs.Suporte_do_Item_Locado__c=LocPed.Suporte_do_Item_Locado__c;
 			pcs.valor_do_suporte__c=locped.valor_do_suporte_produto__c;
         if(idProduto!=null && idProduto!=''){
         	pcs.Id=idProduto;
         }
         //Realiza o calculo da locação
         
         Negociacao_Comercial__c nego = [Select id,Sincronizado__c,oportunidade__c from Negociacao_Comercial__c where id =:LocPed.Negociacao_Comercial__c];
     	nego.Sincronizado__c=false;
     	update nego;
     	pcs.oportunidade__c=nego.Oportunidade__c;
         upsert pcs;
         LocPed.Total_geral_locacao__c=CalcularLocacao();
         LocPed.Valor_Total_dos_Produtos__c=CalcularTotProd();
         LocPed.Valor_total_do_suporte__c=CalcularTotSuporte();
         LocPed.Cotacao_do_Dolar__c=locped.Cotacao_do_Dolar_Prod__c;
         LocPed.Cambio__c=locped.Cotacao_Compra__c;
         Locacao_x_Pedido__c lc =CalculaValoresLocacao(LocPed);
         
         update lc;
         if(pcs.id!=null){
             	msgRetorno='Cadastro realizado com sucesso !';
             	
             }
         else{
             	msgRetorno='Cadastro não realizado com sucesso !';
         }
         
        //LocPed.id=null;
        LocPed.Produto_NewAge__c=null;
 		LocPed.Condicao_de_Pagamento_Compra__c=null ;
 		LocPed.Fornecedor__c=null ;
 		LocPed.Categoria_de_Compra__c=null;
 		LocPed.Moeda_Compra__c=null;
 		LocPed.Cotacao_Compra__c=null;
 		LocPed.Quantidade__c=null;
 		LocPed.Valor_do_produto__c=null;
 		LocPed.Condicao_de_Pagamento_Prod__c=null;
 		LocPed.Moeda_Prod__c=null;
 		LocPed.Cotacao_do_Dolar_Prod__c=null;
 		LocPed.Categoria__c=null;
 		LocPed.Ativos_Cobertos__c=null;
 		LocPed.Inclui_RMA_de_Hardware__c=null;
 		LocPed.Leasing__c=null;
 		LocPed.Suporte_do_Item_Locado__c=null;
 		LocPed.valor_do_suporte_produto__c=null;
 		update LocPed;
         pcs.id=null;
         reference = new Pagereference('/apex/cadLocacaoxPedido?idNegociacao=' + idNegociacao + '&id=' + idLocacao + '&Redict=0&Editar=0&CambioGlobal=' + CambioGlobal );
         reference.setRedirect(true);
    	}
    	catch(Exception e){
		//msgRetorno+='Exception type caught: ' + e.getTypeName() + '<br/>';    
	    //msgRetorno='' + e.getMessage()+ ' O index of' + msgRetorno.indexof('Upsert');    
	    //msgRetorno+='Cause: ' + e.getCause()+ '<br/>';    // returns null
	    msgRetorno='' + e.getLineNumber()+ '';    
	    //msgRetorno+='Stack trace: ' + e.getStackTraceString()+ '<br/>';
	    
	    if(msgRetorno=='288'){
	    		msgRetorno='Erro o salvar o produto dentro da locação, produto invalido';
	    	} 
    	
    	}
         
         return reference;
    }
    public PageReference Excluir(){
        Tipo = ApexPages.currentPage().getParameters().get('Tipo');
        Idex = ApexPages.currentPage().getParameters().get('Idex');
        //System.debug('O valor de excluir: ' + Excluir + ' O valor do tipo: ' + tipo + ' o valor do idex: ' + idex);
        //if(tipo=='Prod'){
          ObjectName = 'Produto_x_Locacao__c';  
        //}
        QueryString ='Select id ,name from '+ObjectName+ ' where id = :Idex';
        sObjectList = Database.Query(QueryString);
        if(sObjectList.size()>0){
        	delete sObjectList[0];
        }
         LocPed.Total_geral_locacao__c=CalcularLocacao();
         LocPed.Valor_Total_dos_Produtos__c=CalcularTotProd();
         LocPed.Valor_total_do_suporte__c=CalcularTotSuporte();
         Locacao_x_Pedido__c lc =CalculaValoresLocacao(LocPed);
         update lc;
         try{
         Negociacao_Comercial__c nego = [Select id,Sincronizado__c from Negociacao_Comercial__c where id =:idNegociacao];
         nego.Sincronizado__c=false;
         update nego;
         }
         catch(Exception ex ){
         
         }
        Pagereference reference = new Pagereference('/apex/cadLocacaoxPedido?idNegociacao=' + idNegociacao + '&id=' + idLocacao + '&Redict=0&CambioGlobal=' + CambioGlobal );
        reference.setRedirect(true); 
        return reference;
    }
    @RemoteAction
    global static string RetornaDescricao(String idProd){
    		DescProd='';
    		SincronizaNewAge sinc = new SincronizaNewAge();
    		DescProd=sinc.RetonoDetalheProduto(idProd);
    		return DescProd;
    }
      @RemoteAction
    global static string RetornaFornecedor(String idFornecedor){
    		DescForn='';
    		SincronizaNewAge sinc = new SincronizaNewAge();
    		DescForn=sinc.RetonoDetalheFornecedor(idFornecedor);
    		return DescForn;
    }
	 @RemoteAction
    global static string RetornaCNPJDest(String idCnpj){
    		DescForn='';
    		SincronizaNewAge sinc = new SincronizaNewAge();
    		DescForn=sinc.RetonoDetalheFornecedor(idCnpj);
    		return DescForn;
    }
}