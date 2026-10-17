global with sharing class clsCadProdutoxPedido {
                public String idNegociacao {get;set;}
                public String idOportunidade {get;set;}
                public String idProduto {get;set;}
                public String Redict{get;set;}
                public String msgRetorno {get;set;}
                private final Produto_Pedido__c ProdPed;
                public static String DescProd{get;set;}
                public static String DescForn{get;set;}
                public static String DescDest{get;set;}
                public static String ValorTotal{get;set;}
                                public String ReadOnly{get;set;}
                                public String DisabledField{get;set;}
                                public String mBotao{get;set;}
                                public String SeguraCampo{get;set;}
                                public String prodCambio{get;set;}
                                public String prodCambioVenda{get;set;}
                                public String CambioGlobal{get;set;}
        public clsCadProdutoxPedido(ApexPages.StandardController controller) {
                                        //Variaves de get
                        idProduto = ApexPages.currentPage().getParameters().get('id');
                        idNegociacao = ApexPages.currentPage().getParameters().get('IdNegociacao');
                        idOportunidade = ApexPages.currentPage().getParameters().get('idOportunidade');
                        SeguraCampo = ApexPages.currentPage().getParameters().get('SeguraCampo');
                        Redict = ApexPages.currentPage().getParameters().get('Redict');
                        prodCambio = ApexPages.currentPage().getParameters().get('prodCambio');
                        prodCambioVenda = ApexPages.currentPage().getParameters().get('prodCambioVenda');
                        CambioGlobal = ApexPages.currentPage().getParameters().get('CambioGlobal');
                        prodCambioVenda = (prodCambioVenda=='0' || prodCambioVenda=='' ?CambioGlobal:prodCambioVenda);
                        prodCambio = (prodCambio=='0' || prodCambio=='' ?CambioGlobal:prodCambio);
                        //=========================================================
                        this.ProdPed=(Produto_Pedido__c)controller.getRecord();
                        
                        if (Redict!='0' && idProduto!= null && idProduto!='' && SeguraCampo!='1'){
                                Negociacao_Comercial__c nc = [Select id,Oportunidade__c from Negociacao_Comercial__c where id=:ProdPed.Negociacao_Comercial__c];
                                idOportunidade = nc.Oportunidade__c;    
                                idNegociacao=nc.id;
                                Redict='1';
                        }
                        if(idNegociacao!='' && idNegociacao !=null){
                                Negociacao_Comercial__c NegoCom = [Select id,Status_Negociacao__c,Oportunidade__c from Negociacao_Comercial__c where id=:idNegociacao];
                                ReadOnly=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
                                                DisabledField=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
                                                mBotao=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'none':'block');
                        }
                        
                        //Limpa a variavel para um novo cadastro
                        if(SeguraCampo=='1'){
                                this.ProdPed.id=null;
                                idProduto=null;
                                this.ProdPed.Produto_NewAge__c=null;
                                this.ProdPed.Fornecedor__c=null;
                                this.ProdPed.Categoria_de_Compra__c=null;
                                this.ProdPed.Quantidade__c=null;
                                this.ProdPed.Valor_do_produto__c=null;
                                this.ProdPed.Valor_Rewards__c=null;
                                this.ProdPed.Categoria__c=null;
                                //this.ProdPed.Markup__c=null;
                                this.ProdPed.Comissao_Intermediaria__c=null;
                                
                        }
                                if(this.ProdPed.Cotacao_Compra__c!=null){
                                        List<String> args = new String[]{'0','number','###,###,##0,00'};
                                        						Double dCambio=Double.valueof((CambioGlobal!=null && CambioGlobal != ''?CambioGlobal:'0'));
                                                                prodCambio= String.format(this.ProdPed.Cotacao_Compra__c.format(), args);
                                                                prodCambioVenda= String.format(this.ProdPed.Cotacao_do_Dolar__c.format(), args);
                                                                CambioGlobal= String.format(dCambio.format(), args);
                                                                CambioGlobal = (CambioGlobal=='0' ? prodCambioVenda : CambioGlobal);
                                }
                                else{
                                	try{
                	Double dCambio=Double.valueof(CambioGlobal);
                    List<String> args = new String[]{'0','number','###,###,##0,00'};
                    CambioGlobal= String.format(dCambio.format(), args);
                	}
                	catch(exception ex){}
                                
                                }
        }
        
        public clsCadProdutoxPedido() {

        }
        
   public List<selectOption> getMoedaProd() {
        SincronizaNewAge sinc = new SincronizaNewAge();
        List<selectOption> options = sinc.getMoedaGenerico(); 
        return options; //return the picklist options
    }
            public PageReference SalvarPedidoxProduto(){
                
                
                SincronizaNewAge sinc = new SincronizaNewAge();
                
                //Ca
                 String Redic='2';
                 Boolean Refresh=false;
                 Pagereference reference;
                 //Metodo para realizar a gravação da nova negociação;
                 if(idNegociacao==null || idNegociacao.trim()==''){
                        // Será necessario criar uma negociacao nova dentro do sistema
                        clsCadNegociacaoComercial NegociacaoComercial = new clsCadNegociacaoComercial();
                        idNegociacao = NegociacaoComercial.CriaNegociacao(idOportunidade);
                        ProdPed.Negociacao_Comercial__c=idNegociacao;
                        //prodped.Oportunidade__c=prodPed.negociacao_comercial__r.oportunidade__c;
                        //idProd='0';
                        Refresh=true;
                 }
                 else{
                        ProdPed.Negociacao_Comercial__c=idNegociacao;
                        //prodped.Oportunidade__c=prodPed.negociacao_comercial__r.oportunidade__c;
                        
                 }
                 if(sinc.ValidaMarkup(ProdPed.CNPJ_de_Faturamento__c, ProdPed.Markup__c,Userinfo.getUserId())){
                
                
                                         Negociacao_Comercial__c nego = [Select id,Sincronizado__c,Oportunidade__c from Negociacao_Comercial__c where id =:idNegociacao];
                                         nego.Sincronizado__c=false;
                                         update nego;
                                         ProdPed.Oportunidade__c=nego.Oportunidade__c;
                                         prodCambio = String.valueof(ProdPed.Cotacao_Compra__c);
                                         prodCambioVenda = String.valueof(ProdPed.Cotacao_do_Dolar__c);
                                         
                         upsert ProdPed;
                         if(Refresh==false){
                                Redic='';
                                SeguraCampo='1';
                         }
                         else{
                                SeguraCampo='0';
                         }
                         if(ProdPed.id!=null){
                                msgRetorno='Cadastro realizado com sucesso !';
                                reference = new Pagereference('/apex/cadProdutoxPedido?idNegociacao=' +idNegociacao +'&Redict='+Redic + '&SeguraCampo='+SeguraCampo+'&id='+ProdPed.id  );
                                reference.setRedirect(true);
                         }
                         else{
                                msgRetorno='Cadastro não realizado com sucesso !';
                         }
                 }
                 else{
                        msgRetorno='Cadastro não realizado com sucesso, markup abaixo do esperado !';
                 }
                 ProdPed.Id=null;
                 return reference;
            }

        public List<selectOption> getOrigemFat() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Account comp : [SELECT Id, 
                                                                Name 
                                                FROM    Account 
                                                where   Conta_de_Faturamento_Agility__c=true
                                                                and name not in ('Agility Networks Support Services')
                                                        ]) { 
            options.add(new selectOption(comp.id, comp.Name)); 
        }
        return options; //return the picklist options
    }

        @RemoteAction
    global static string RetornaValor(String qtd,String valor){
                Decimal Verbatotal=0;
                valor=valor.replace('.','');
                valor=valor.replace(',','.');
                //List<String> argsVar = new String[]{'0','number','######.##'};
                //valor= String.format(valor.format(), argsVar);
                //valor = String.format(valor,argsVar);
                Decimal qtdProd=Decimal.valueof(qtd);
                //Decimal vlrUnit=Decimal.valueof(valor);
                
                Verbatotal = qtdProd*Decimal.valueOf(valor) ;
                List<String> args = new String[]{'0','number','###,###,##0.00'};
                        ValorTotal= String.format(Verbatotal.format(), args);
                return ValorTotal;
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