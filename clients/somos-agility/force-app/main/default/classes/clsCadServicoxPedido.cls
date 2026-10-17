global with sharing class clsCadServicoxPedido {
        public String idNegociacao {get;set;}
        public String idOportunidade {get;set;}
        public String idServico {get;set;}
        public String Redict{get;set;}
        public String msgRetorno {get;set;}
        //public Boolean reCalc{get;set;}
        public static String vlr{get;set;}
        public static String DescForn{get;set;}
        public String ReadOnly{get;set;}
        public String DisabledField{get;set;}
        public String mBotao{get;set;}
        public String strCFOP{get;set;}
        public String SeguraCampo{get;set;}
        public String idContaFatServ{get;set;}
        public String CambioGlobal{get;set;}
        
        private final Servico_x_Pedido__c ServPed;
        public clsCadServicoxPedido(ApexPages.StandardController controller) {
                //Variaveis de get
                idServico = ApexPages.currentPage().getParameters().get('id');
                idNegociacao = ApexPages.currentPage().getParameters().get('IdNegociacao');
                idOportunidade = ApexPages.currentPage().getParameters().get('idOportunidade');
                idContaFatServ = ApexPages.currentPage().getParameters().get('idContaFatServ');
                Redict = ApexPages.currentPage().getParameters().get('Redict');
                SeguraCampo = ApexPages.currentPage().getParameters().get('SeguraCampo');
                CambioGlobal = ApexPages.currentPage().getParameters().get('CambioGlobal');
                 if(idNegociacao!='' && idNegociacao !=null){
                    Negociacao_Comercial__c NegoCom = [Select id,Status_Negociacao__c from Negociacao_Comercial__c where id=:idNegociacao];
                    ReadOnly=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
                    DisabledField=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
                    mBotao=(NegoCom.Status_Negociacao__c=='Convertido' || NegoCom.Status_Negociacao__c=='Historico'?'none':'block');
                }
                //==============================================================
                this.ServPed=(Servico_x_Pedido__c)controller.getRecord();
                if (Redict!='0' && idServico!= null && idServico!='' && SeguraCampo!='1'){
                    Negociacao_Comercial__c nc = [Select id from Negociacao_Comercial__c where id=:ServPed.Negociacao_comercial__c];
                    idNegociacao=nc.id;
                    Redict='1';
                }
                if(ServPed.id==null){
                    Categoria__c cat = [select id,Codigo_NewAge__c from Categoria__c where Codigo_NewAge__c='2.01.01' and TIpo__c='Serviço' limit 1];
                    //Categoria__c catCompra = [select id,Codigo_NewAge__c from Categoria__c where Codigo_NewAge__c='1.01.16' limit 1];
                    ServPed.Operacao_CFOP__c = cat.id;
                    //servped.Operacao_CFOP_Compra__c = catCompra.Id;
                    strCFOP = cat.Codigo_NewAge__c;
                }
                else{
                    Categoria__c cat = [select id,Codigo_NewAge__c from Categoria__c where id=:ServPed.Operacao_CFOP__c];
                    //ServPed.Operacao_CFOP__c = cat.id;
                    strCFOP = cat.Codigo_NewAge__c;
                }
                if(CambioGlobal!=null && ServPed.Cambio__c==null){
                        try{
                        Double dCambio=Double.valueof(CambioGlobal);
                    List<String> args = new String[]{'0','number','###,###,##0.00'};
                    CambioGlobal= String.format(dCambio.format(), args);
                        }
                        catch(exception ex){}
                   }
                   else{
                        List<String> args = new String[]{'0','number','###,###,##0.00'};
                    CambioGlobal= String.format(ServPed.Cambio__c.format(), args);
                   }
                //Limpa a variavel para um novo cadastro
                if(SeguraCampo=='1'){
                    this.ServPed.id=null;
                    idServico=null;
                    this.ServPed.Codigo_Fiscal_do_Servico__c=null;
                    this.ServPed.Competencia__c=null;
                    this.ServPed.Fase_da_Metodologia__c=null;
                    this.ServPed.Qtd_Horas_Horario_Comercial__c=null;
                    this.ServPed.Qtd_Horas_Extraordinario__c=null;
                    this.ServPed.Quantidade_Analistas__c=null;
                    this.ServPed.Local_da_Prestacao_de_Servicos__c=null;
                    this.ServPed.Verba_Pre_alocada_para_deslocamento__c=null;
                    this.ServPed.Instrucao_de_Cobranca__c=null;
                    this.ServPed.Passagens__c=null;
                    this.ServPed.Transporte__c=null;
                    this.ServPed.Pedagio__c=null;
                    this.ServPed.Alimentacao__c=null;
                    this.ServPed.Hospedagem__c=null;
                    this.ServPed.Alimentacao__c=null;
                    this.ServPed.Outros__c=null;
                    this.ServPed.Observacao__c=null;
                    this.ServPed.Desconto__c=null;
                    this.ServPed.Subcontratacao_de_Terceiros__c=null;
                    this.ServPed.CNPJ_de_Contratacao_Terceiros__c=null;
                    this.ServPed.Servicos_de_terceiros__c=null;
                }
                idContaFatServ=this.ServPed.CNPJ_de_Faturamento__c;
                    
                    
                    

        }
      public clsCadServicoxPedido() {

        }
        
         @RemoteAction
    global static string RetornaCNPJDest(String idCnpj){
            DescForn='';
            SincronizaNewAge sinc = new SincronizaNewAge();
            DescForn=sinc.RetonoDetalheFornecedor(idCnpj);
            return DescForn;
    }
    public List<selectOption> getOrigemFat() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Account comp : [SELECT Id, 
                                    Name 
                            FROM    Account 
                            where   Conta_de_Faturamento_Servicos_Agility__c=true 
                                    or Conta_de_Faturamento_Agility__c=true ]) { 
            options.add(new selectOption(comp.id, comp.Name)); 
        }
        return options; //return the picklist options
    }
    
    
    public List<selectOption> getMoedaServ() {
        SincronizaNewAge sinc = new SincronizaNewAge();
        List<selectOption> options = sinc.getMoedaGenerico(); 
        return options; //return the picklist options
    }
    
    @RemoteAction
    global static string CalculaVerba(String qtdAnalista,String qtdHorasExtra,String qtdHorasNormais,String local){
            //A formula de calculo é a que se segue:
            //(((Horas Exta * 1.5)+Horas Normais)/8) * Vlr Local * Qtd Analistas
            Decimal Verbatotal=0;
            Decimal DqtdAnalista=Decimal.valueof(qtdAnalista);
            Decimal DqtdHorasExtra=Decimal.valueof(qtdHorasExtra);
            Decimal DqtdHorasNormais=Decimal.valueof(qtdHorasNormais);
            Decimal vlrLocal=0;
                Local_Prestacao__c lp = [Select Id,Custo_Deslocamento__c From Local_Prestacao__c where Name = :local];
                vlrLocal=lp.Custo_Deslocamento__c;
            /*if(local=='São Paulo - Capital'){
                vlrLocal=50;
            }
            else if(local=='Grande São Paulo'){
                vlrLocal=100;
            }*/
            
            Verbatotal = (((DqtdHorasExtra*1.5)+DqtdHorasNormais)/8) * vlrLocal * DqtdAnalista ;
            //ServPed.Verba_Pre_alocada_para_deslocamento__c=Verbatotal;
            //vlr = String.valueof(Verbatotal);
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            vlr= String.format(Verbatotal.format(), args);
            //vlr='1.350,00';
        
        return vlr;
    }
    public Decimal CalcularValorServicoFinal(){
        Decimal TotalHorasNormais=0;
        Decimal TotalHorasExtra=0;
        Decimal TotalDeslocamento=0;
        Decimal TotalFinal=0;
        Decimal vlrLocal=0;
           Local_Prestacao__c lp = [Select Id,Custo_Deslocamento__c From Local_Prestacao__c where Name = :ServPed.Local_da_Prestacao_de_Servicos__c];
                vlrLocal=lp.Custo_Deslocamento__c;
            /*if(local=='São Paulo - Capital'){
                vlrLocal=50;
            }
            else if(local=='Grande São Paulo'){
                vlrLocal=100;
            }*/
        //Captura o valor do tipo de competencia selecionado;
        Competencia__c comp = [Select id,Valor_Competencia__c from Competencia__c where id = :ServPed.Competencia__c ];
        Decimal vlrTIpo=comp.Valor_Competencia__c;
         //Nessa parte iremos realizar os calculos de cada total
        TotalHorasNormais=ServPed.Qtd_Horas_Horario_Comercial__c *  vlrTIpo * ServPed.Quantidade_Analistas__c;
        TotalHorasExtra=(ServPed.Qtd_Horas_Extraordinario__c *1.5)*  vlrTIpo * ServPed.Quantidade_Analistas__c;
        TotalDeslocamento=(((ServPed.Qtd_Horas_Extraordinario__c *1.5)+ServPed.Qtd_Horas_Horario_Comercial__c)/8)*vlrLocal;
        TotalFinal = TotalHorasNormais+TotalHorasExtra+TotalDeslocamento;
        return TotalFinal;
    }
    public Decimal CalcularValorServico(){
        
        Decimal TotalFinal=0;
        Decimal totalCusto=0;
        Decimal totalVlrTerc=0;
        Decimal Desco=0;
        Desco=(servped.Desconto__c==null?0:servped.Desconto__c);
        totalCusto +=(servped.Passagens__c==null?0:servped.Passagens__c);
        totalCusto +=(servped.Transporte__c==null?0:servped.Transporte__c);
        totalCusto +=(servped.Pedagio__c==null?0:servped.Pedagio__c);
        totalCusto +=(servped.Alimentacao__c==null?0:servped.Alimentacao__c);
        totalCusto +=(servped.Hospedagem__c==null?0:servped.Hospedagem__c);
        totalCusto +=(servped.Alimentacao__c==null?0:servped.Alimentacao__c);
        totalCusto +=(servped.Outros__c==null?0:servped.Outros__c);
        totalVlrTerc=(servped.Servicos_de_terceiros__c==null?0:servped.Servicos_de_terceiros__c);
        TotalFinal=ServPed.Total_Final_dos_Servicos__c-((ServPed.Total_Final_dos_Servicos__c/100)*Desco)+totalVlrTerc+totalCusto;
        return TotalFinal;
    }
    public Decimal CalcularValorServicoRent(){
    	
    	 Account lp = [Select Aliquota_Conta__c,id From Account where id = :ServPed.CNPJ_de_Faturamento__c];
       	Decimal aliquota=lp.Aliquota_Conta__c/100;
    	System.debug('O valor da aliquota é: ' + String.valueof(aliquota));
        Decimal TotalFinal=0;
        Decimal totalCusto=0;
        Decimal totalVlrTerc=0;
        totalVlrTerc=(servped.Servicos_de_terceiros__c==null?0:servped.Servicos_de_terceiros__c);
        totalCusto +=(servped.Passagens__c==null?0:servped.Passagens__c);
        totalCusto +=(servped.Transporte__c==null?0:servped.Transporte__c);
        totalCusto +=(servped.Pedagio__c==null?0:servped.Pedagio__c);
        totalCusto +=(servped.Alimentacao__c==null?0:servped.Alimentacao__c);
        totalCusto +=(servped.Hospedagem__c==null?0:servped.Hospedagem__c);
        totalCusto +=(servped.Verba_Pre_alocada_para_deslocamento__c==null?0:servped.Verba_Pre_alocada_para_deslocamento__c);
        totalCusto +=(servped.Outros__c==null?0:servped.Outros__c);
        TotalFinal=ServPed.Total_dos_Servicos__c-(totalCusto+totalVlrTerc+(ServPed.Total_dos_Servicos__c*aliquota));
        return TotalFinal;
    }
    
    
    public Decimal CalcularValorServicoCusto(){
    	Account lp = [Select Aliquota_Conta__c,id From Account where id = :ServPed.CNPJ_de_Faturamento__c];
       	Decimal aliquota=lp.Aliquota_Conta__c/100;
        Decimal TotalFinal=0;
        TotalFinal=(ServPed.Total_dos_Servicos__c*aliquota);
        return TotalFinal;
    }
    
    public List<selectOption> getLocalPrest() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Local_Prestacao__c comp : [SELECT Id, Name FROM Local_Prestacao__c]) { 
            options.add(new selectOption(comp.Name, comp.Name)); 
        }
        return options; //return the picklist options
    }
    
  public List<selectOption> getCompetencia() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Competencia__c comp : [SELECT Id, Name FROM Competencia__c]) { 
            options.add(new selectOption(comp.id, comp.Name)); 
        }
        return options; //return the picklist options
    }
    
    public List<selectOption> getFasedaMetodlogia() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('', '- None -')); 
        for (Fase_da_Metodologia__c fase : [SELECT Id, Name FROM Fase_da_Metodologia__c]) { 
            options.add(new selectOption(fase.id, fase.Name)); 
        }
        return options; //return the picklist options
    }

    
    public PageReference SalvarPedidoxServico(){
            String Redic='2';
            Boolean Refresh=false;
            Pagereference reference;
             //Metodo para realizar a gravação da nova negociação;
             if(idNegociacao==null || idNegociacao.trim()==''){
                    // Será necessario criar uma negociacao nova dentro do sistema
                    clsCadNegociacaoComercial NegociacaoComercial = new clsCadNegociacaoComercial();
                    idNegociacao = NegociacaoComercial.CriaNegociacao(idOportunidade);
                    ServPed.Negociacao_Comercial__c=idNegociacao;
                    Refresh=true;
                    
             }
             else{
                ServPed.Negociacao_Comercial__c=idNegociacao;
             }
             if (ServPed.Competencia__c!=null && ServPed.Fase_da_Metodologia__c!=null){
                ServPed.Total_Final_dos_Servicos__c=CalcularValorServicoFinal();
                servped.Total_dos_Servicos__c=CalcularValorServico();
                servPed.Rentabilidade_bruta__c=CalcularValorServicoRent();
                servPed.Rentabilidade_liquida__c=CalcularValorServicoRent();
                ServPed.Total_do_custo__c = CalcularValorServicoCusto();
                 Negociacao_Comercial__c nego = [Select id,Sincronizado__c from Negociacao_Comercial__c where id =:idNegociacao];
                 nego.Sincronizado__c=false;
                 update nego;
                 servped.oportunidade__c=nego.Oportunidade__c;
                 upsert ServPed;
                 if(Refresh==false){
                        Redic='';
                        SeguraCampo='1';
                     }
                  else{
                    SeguraCampo='0';
                  }
                 if(ServPed.id!=null){
                    msgRetorno='Cadastro realizado com sucesso !';
                    reference = new Pagereference('/apex/cadServicoxPedido?idNegociacao=' + idNegociacao + '&Redict='+Redic + '&SeguraCampo='+SeguraCampo+'&id='+servped.id);
                    reference.setRedirect(true);
                 }
                 else{
                    msgRetorno='Cadastro não realizado com sucesso !';
                 }
                 ServPed.Id=null;
             }
             else{
                msgRetorno='Informe a competência e a Fase da Metodologia dentro do serviço';
                return null;
             }
             return reference;
        }

}