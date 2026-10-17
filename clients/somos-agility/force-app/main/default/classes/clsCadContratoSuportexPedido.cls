global  with sharing class clsCadContratoSuportexPedido {
		public String idNegociacao {get;set;}
		public String idOportunidade {get;set;}
		public String idContrato {get;set;}
		public String idProduto {get;set;}
		public String idRecurso {get;set;}
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
	 	public static String DescForn{get;set;}
		private final Contrato_Suporte__c ContSup;
		public String ReadOnly{get;set;}
		public String DisabledField{get;set;}
		public String mBotao{get;set;}
		public String idContaFatCont{get;set;}
		public String SeguraCampo{get;set;}
	 public clsCadContratoSuportexPedido(ApexPages.StandardController controller) {
	 			//Campos para serem realizados os requests
				idContrato = ApexPages.currentPage().getParameters().get('id');
                idNegociacao = ApexPages.currentPage().getParameters().get('IdNegociacao');
                idOportunidade = ApexPages.currentPage().getParameters().get('idOportunidade');
                idProduto = ApexPages.currentPage().getParameters().get('idProduto');
                idRecurso = ApexPages.currentPage().getParameters().get('idRecurso');
                Redict = ApexPages.currentPage().getParameters().get('Redict');
                Editar = ApexPages.currentPage().getParameters().get('Editar');
                idContaFatCont = ApexPages.currentPage().getParameters().get('idContaFatCont');
                SeguraCampo = ApexPages.currentPage().getParameters().get('SeguraCampo');
                if(idNegociacao!='' && idNegociacao !=null){
	            	Negociacao_Comercial__c NegoCom = [Select id,Status_Negociacao__c from Negociacao_Comercial__c where id=:idNegociacao];
	            	ReadOnly=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
					DisabledField=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
					mBotao=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'none':'block');
            	}
                //================================================================
                mostrarAdendo='none';
                this.ContSup=(Contrato_Suporte__c)controller.getRecord();
                if (Redict!='0' && idContrato!= null && idContrato!='' && SeguraCampo!='1'){
                	Negociacao_Comercial__c nc = [Select id from Negociacao_Comercial__c where id=:ContSup.Negociacao_Comercial__c];
                	idNegociacao=nc.id;
                	Redict='1';
                }
                
                if(SeguraCampo=='1'){
                	this.ContSup.id=null;
                	idContrato=null;
                	this.ContSup.Celula_de_Servicos__c=null;
                	this.ContSup.Nivel_do_Suporte__c=null;
                	this.ContSup.Disponibilidade__c=null;
                	this.ContSup.Prazo_do_contrato__c=null;
                	this.ContSup.Descricao_Prazo_de_Duracao__c=null;
                	this.ContSup.Tipo_de_Faturamento__c=null;
                	this.ContSup.Descricao_Tipo_de_Faturamento__c=null;
                	this.ContSup.Custo_direto_do_Contrato_Recurso__c=null;
                	this.ContSup.Custo_direto_do_Contrato_Produto__c=null;
                }
                idContaFatCont=this.ContSup.CNPJ_de_Faturamento__c;
                
                if(Editar=='1' && idProduto!='' && idProduto !=null){
                    Produto_x_Contrato_Suporte__c pcs = [Select id,
                    											Moeda__c,
                    											Produto_NewAge__c,
                    											Cambio__c,
                    											Valor_do_produto__c,
                    											Inclui_RMA_de_Hardware__c,
                    											Ativos_Cobertos__c 
                    									from 	Produto_x_Contrato_Suporte__c
                    									where id =:idProduto];
                	ContSup.Moeda_1_Produto__c=pcs.Moeda__c;
         			ContSup.Produto_1__c=pcs.Produto_NewAge__c ;
         			ContSup.Cotacao_do_Dolar_1_Produto__c=pcs.Cambio__c ;
         			ContSup.Valor_1_Produto__c=pcs.Valor_do_produto__c;
         			ContSup.Inclui_RMA_de_Hardware__c=pcs.Inclui_RMA_de_Hardware__c;
         			ContSup.Ativos_Cobertos__c=pcs.Ativos_Cobertos__c;
                }
                if(Editar=='1' && idRecurso!='' && idRecurso !=null){
                    Recurso_x_Contrato_de_Suporte__c rcs = [Select id,
                    											Moeda__c,
                    											Produto__c,
                    											Cambio__c,
                    											Valor_do_recurso__c,
                    											Descricao__c 
                    									from 	Recurso_x_Contrato_de_Suporte__c
                    									where id =:idRecurso];
				 	ContSup.Moeda_1_Mao_de_Obra__c=rcs.Moeda__c;
				 	ContSup.Produto_2__c=rcs.Produto__c;
				 	ContSup.Cotacao_do_Dolar_1_Mao_de_Obra__c=rcs.Cambio__c;
				 	ContSup.Valor_1_Mao_de_Obra__c=rcs.Valor_do_recurso__c;
				 	Contsup.Descricao_1_Mao_de_Obra__c=rcs.Descricao__c;
                }
                if(ContSup.id!=null){
                	mostrarAdendo='block';
                }
                
                

    }
      public clsCadContratoSuportexPedido() {

    }
    
     public List<selectOption> getMoedaCont() {
    	SincronizaNewAge sinc = new SincronizaNewAge();
        List<selectOption> options = sinc.getMoedaGenerico(); 
        return options; //return the picklist options
    }
    
    public PageReference SalvarContratoSuportexPedido(){
         Pagereference reference;
             //Metodo para realizar a gravação da nova negociação;
             if(idNegociacao==null || idNegociacao.trim()==''){
                    // Será necessario criar uma negociacao nova dentro do sistema
                    clsCadNegociacaoComercial NegociacaoComercial = new clsCadNegociacaoComercial();
                    idNegociacao = NegociacaoComercial.CriaNegociacao(idOportunidade);
                    ContSup.Negociacao_Comercial__c=idNegociacao;
             }
             else{
             	ContSup.Negociacao_Comercial__c=idNegociacao;
             }
             if(idContrato!=null && idContrato!=''){
         			ContSup.Id=idContrato;
         			//SeguraCampo='1';
         	}
         	 Negociacao_Comercial__c nego = [Select id,Sincronizado__c,Oportunidade__c from Negociacao_Comercial__c where id =:idNegociacao];
         	 nego.Sincronizado__c=false;
         	 update nego;
         	 ContSup.oportunidade__c=nego.Oportunidade__c;
             upsert ContSup;
             if(ContSup.id!=null){
             	msgRetorno='Cadastro realizado com sucesso !';
             	reference = new Pagereference('/apex/cadContratoSuportexPedido?idNegociacao=' + idNegociacao + '&id=' +ContSup.id  + '&SeguraCampo='+SeguraCampo);
             	
             }
             else{
             	msgRetorno='Cadastro não realizado com sucesso !';
             }
             //ContSup.Id=null;
             reference.setRedirect(true);
             return reference;
    }
    public Decimal CalcularProduto(){
    	Decimal TotalContProd=0;
    	//Calcula o total dos Produtos
    	List<aggregateResult> vlrTotProd = [	SELECT 	Sum(Valor_do_produto__c) vlrContProd
						    					FROM 	Produto_x_Contrato_Suporte__c 
						    					WHERE 	Contrato_Suporte__c = :ContSup.Id ];
		if(!vlrTotProd.isEmpty()){TotalContProd += Double.valueOf((vlrTotProd[0].get('vlrContProd')==null?0:vlrTotProd[0].get('vlrContProd')));}
		return TotalContProd;
    }
    public Decimal CalcularRecurso(){
    	Decimal TotalContRec=0;
    	List<aggregateResult> vlrTotRec = [	SELECT 	Sum(Valor_do_recurso__c) vlrContRec
						    					FROM 	Recurso_x_Contrato_de_Suporte__c 
						    					WHERE 	Contrato_Suporte__c = :ContSup.Id ];
	   if(!vlrTotRec.isEmpty()){TotalContRec += Double.valueOf( (vlrTotRec[0].get('vlrContRec')==null?0:vlrTotRec[0].get('vlrContRec')) );}
	  return TotalContRec;
    }
    public PageReference SalvarContratoSuporteProduto(){
         Pagereference reference;
         //Cria o objeto de produto para ser cadastrado dentro do sistema.
         Produto_x_Contrato_Suporte__c pcs = new Produto_x_Contrato_Suporte__c();
         pcs.Contrato_Suporte__c= ContSup.id;
         pcs.Negociacao_Comercial__c = ContSup.Negociacao_Comercial__c;
         pcs.Moeda__c = ContSup.Moeda_1_Produto__c;
         pcs.Produto_NewAge__c = ContSup.Produto_1__c;
         pcs.Cambio__c = ContSup.Cotacao_do_Dolar_1_Produto__c;
         pcs.Valor_do_produto__c = ContSup.Valor_1_Produto__c;
         pcs.Inclui_RMA_de_Hardware__c=ContSup.Inclui_RMA_de_Hardware__c;
         pcs.Ativos_Cobertos__c=ContSup.Ativos_Cobertos__c;
         if(idProduto!=null && idProduto!=''){
         	pcs.Id=idProduto;
         }
         Negociacao_Comercial__c nego = [Select id,Sincronizado__c,Oportunidade__c from Negociacao_Comercial__c where id =:idNegociacao];
         nego.Sincronizado__c=false;
         update nego;
         pcs.oportunidade__c=nego.Oportunidade__c;
         upsert pcs;
         
         ContSup.Valor_Total_Dos_Produtos__c=CalcularProduto();
         update ContSup;
         
         if(pcs.id!=null){
             	msgRetorno='Cadastro realizado com sucesso !';
             	
             }
         else{
             	msgRetorno='Cadastro não realizado com sucesso !';
         }
         ContSup.Moeda_1_Produto__c=null;
         ContSup.Produto_1__c=null;
         ContSup.Cotacao_do_Dolar_1_Produto__c=null;
         ContSup.Valor_1_Produto__c=null;
         ContSup.Inclui_RMA_de_Hardware__c=null;
         ContSup.Ativos_Cobertos__c=null;
         //ContSup.id=null;
         update ContSup;
         pcs.id=null;
         reference = new Pagereference('/apex/cadContratoSuportexPedido?idNegociacao=' + idNegociacao + '&id=' + idContrato + '&Redict=0' );
         reference.setRedirect(true);
         return reference;
    }
    public PageReference SalvarContratoSuporteRecurso(){
         Pagereference reference;
         //Cria o objeto de produto para ser cadastrado dentro do sistema.
         Recurso_x_Contrato_de_Suporte__c rcs = new Recurso_x_Contrato_de_Suporte__c();
         rcs.Contrato_Suporte__c= ContSup.id;
         rcs.Negociacao_Comercial__c = ContSup.Negociacao_Comercial__c;
         rcs.Moeda__c = ContSup.Moeda_1_Mao_de_Obra__c;
         rcs.Produto__c = ContSup.Produto_2__c;
         rcs.Cambio__c = ContSup.Cotacao_do_Dolar_1_Mao_de_Obra__c;
         rcs.Valor_do_recurso__c = ContSup.Valor_1_Mao_de_Obra__c;
         rcs.Descricao__c = Contsup.Descricao_1_Mao_de_Obra__c;
         if(idRecurso!=null && idRecurso!=''){
         	rcs.Id=idRecurso;
         }
         Negociacao_Comercial__c nego = [Select id,Sincronizado__c,oportunidade__c from Negociacao_Comercial__c where id =:idNegociacao];
         nego.Sincronizado__c=false;
         update nego;
         rcs.oportunidade__c=nego.Oportunidade__c;
         upsert rcs;
         ContSup.Valor_Total_dos_Recursos__c=CalcularRecurso();
         update ContSup;
         
         if(rcs.id!=null){
             	msgRetorno='Cadastro realizado com sucesso !';
             	
             }
         else{
             	msgRetorno='Cadastro não realizado com sucesso !';
         }
         ContSup.Moeda_1_Mao_de_Obra__c=null;
         ContSup.Produto_2__c=null;
         ContSup.Cotacao_do_Dolar_1_Mao_de_Obra__c=null;
         ContSup.Valor_1_Mao_de_Obra__c=null;
         //ContSup.id=null;
         update ContSup;
         rcs.id=null;
         reference = new Pagereference('/apex/cadContratoSuportexPedido?idNegociacao=' + idNegociacao + '&id=' + idContrato + '&Redict=0' );
         reference.setRedirect(true);
         return reference;
    }
    
    	public List<selectOption> getOrigemFat() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Account comp : [SELECT Id, Name FROM Account where (Conta_de_Faturamento_Servicos_Agility__c=true
        	or Conta_de_Faturamento_Agility__c=true) and name not in ('Agility Networks Tecnologia ES','Agility Networks Tecnologia SP')
        	]) { 
            options.add(new selectOption(comp.id, comp.Name)); 
        }
        return options; //return the picklist options
    }
	
	public PageReference Excluir(){
        Tipo = ApexPages.currentPage().getParameters().get('Tipo');
        Idex = ApexPages.currentPage().getParameters().get('Idex');
        //System.debug('O valor de excluir: ' + Excluir + ' O valor do tipo: ' + tipo + ' o valor do idex: ' + idex);
        if(tipo=='Prod'){
          ObjectName = 'Produto_x_Contrato_Suporte__c';  
        }
        else if (tipo=='Rec'){
        	ObjectName = 'Recurso_x_Contrato_de_Suporte__c';
       		
        }
        
        QueryString ='Select id ,name from '+ObjectName+ ' where id = :Idex';
        sObjectList = Database.Query(QueryString);
        if(sObjectList.size()>0){
        	delete sObjectList[0];
        }
        ContSup.Valor_Total_dos_Recursos__c=CalcularRecurso();
        ContSup.Valor_Total_Dos_Produtos__c=CalcularProduto();
        update ContSup;
        Negociacao_Comercial__c nego = [Select id,Sincronizado__c from Negociacao_Comercial__c where id =:idNegociacao];
        nego.Sincronizado__c=false;
        update nego;
        Pagereference reference = new Pagereference('/apex/cadContratoSuportexPedido?idNegociacao=' + idNegociacao + '&id=' + idContrato + '&Redict=0' );
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
    global static string RetornaCNPJDest(String idCnpj){
    		DescForn='';
    		SincronizaNewAge sinc = new SincronizaNewAge();
    		DescForn=sinc.RetonoDetalheFornecedor(idCnpj);
    		return DescForn;
    }
}