public with sharing class clsCadNegociacaoComercial {
     private final Negociacao_Comercial__c NegoCom;
     public String idNegociacao {get;set;}
     public String idProduto {get;set;}
     public String idServico {get;set;}
     public String idContrato {get;set;}
     public String idLocacao {get;set;}
     public String Redict {get;set;}
     public String Excluir {get;set;}
     public String Tipo {get;set;}
     public String Idex {get;set;}
     public String Mesagem {get;set;}
     public Boolean showProdutos {get; set;}
     public String ObjectName{get;set;}
     public List<sObject> sObjectList{get;set;}
     public String QueryString;
     public Boolean myFlag{get; set;}
     public String Mostrar{get;set;}
     public String ReadOnly{get;set;}
     public String DisabledField{get;set;}
     public String mPedido{get;set;}
     public String mBotao{get;set;}
     public String mBotaoImprimir{get;set;}
     public String Travar{get;set;}
     public String msgSincronia{get;set;}
     public String Sinc {get;set;}
     public String idContaFatProd {get;set;}
     public String idContaFatServ {get;set;}
     public String idContaFatLoc {get;set;}
     public String idContaFatCont {get;set;}
     public String prodCambio{get;set;}
     public String prodCambioVenda{get;set;}
     public String CambioGlobal{get;set;}
     
     public String VisuEspecial{get;set;}
         
     public clsCadNegociacaoComercial(ApexPages.StandardController controller) {
        //Gets do sistema
        idNegociacao = ApexPages.currentPage().getParameters().get('id');
        idProduto = ApexPages.currentPage().getParameters().get('idProduto');
        idServico = ApexPages.currentPage().getParameters().get('idServico');
        idContrato = ApexPages.currentPage().getParameters().get('idContrato');
        idLocacao = ApexPages.currentPage().getParameters().get('idLocacao');
        prodCambio = ApexPages.currentPage().getParameters().get('prodCambio');
        prodCambioVenda = ApexPages.currentPage().getParameters().get('prodCambioVenda');
        
        idContaFatProd = ApexPages.currentPage().getParameters().get('idContaFatProd');
        idContaFatServ = ApexPages.currentPage().getParameters().get('idContaFatServ');
        idContaFatLoc = ApexPages.currentPage().getParameters().get('idContaFatLoc');
        idContaFatCont = ApexPages.currentPage().getParameters().get('idContaFatCont');

        Sinc = Apexpages.currentPage().getParameters().get('Sinc');
        Travar='0';
        User us=[Select Visualiazacao_Especial__c from user where id=:System.Userinfo.getUserId()];
        VisuEspecial=(us.Visualiazacao_Especial__c==false?'none':'block');
        
        //=====================================================================
        //System.debug('O valor de excluir: ' + Excluir + ' Tipo:' + Tipo + ' Idex=' + Idex);
        if (idProduto!=null && idProduto!=''){
            Redict='0';
        }
        if (idServico!=null && idServico!=''){
            Redict='0';
        }
         if (idContrato!=null && idContrato!=''){
            Redict='0';
        }
        if(idLocacao!=null && idLocacao != ''){
                Redict='0';
        }
       
        if(Sinc=='1'){
                msgSincronia='Não foram encontrados Serviços, Produtos, Contrato de Locação para essa negociação';
        }
        else if (Sinc=='OK'){
                msgSincronia='Sincronização executada com sucesso';
        }
        else if(Sinc=='NOK'){
                msgSincronia='Houve erros na sincronização por favor consultar o Objeto Logs NewAge para mais detalhes';
        }
        else if (Sinc=='NSINC'){
                msgSincronia='Se deve sincronizar a negociação antes de converte-la';
        }
        else if (Sinc =='3'){
                msgSincronia='Sincronização não permitida para contrato de suporte';
        
        }
        else if (Sinc =='2'){
                msgSincronia='Nenhum produto cadastrado dentro do contrato de locação';
        
        }
        this.NegoCom = (Negociacao_Comercial__c)controller.getRecord();
         Opportunity op = [Select Cambio_Global__c from Opportunity where id =:this.NegoCom.Oportunidade__c];
         CambioGlobal= String.valueof(op.Cambio_Global__c);
        Mostrar=(this.NegoCom.id!=null?'block':'none');
        ReadOnly=(this.NegoCom.Status_Negociacao__c=='Convertido' || this.NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
        DisabledField=(this.NegoCom.Status_Negociacao__c=='Convertido' || this.NegoCom.Status_Negociacao__c=='Historico'?'true':'false');
        mPedido=(this.NegoCom.Status_Negociacao__c=='Convertido'?'block':'none');
        mBotao=(this.NegoCom.Status_Negociacao__c=='Convertido' || this.NegoCom.Status_Negociacao__c=='Historico'?'none':'block');
        mBotaoImprimir = 'none';
        if(this.NegoCom.Status_Negociacao__c=='Convertido' || this.NegoCom.Status_Negociacao__c=='Historico'){
                mBotaoImprimir = 'none';
        }
        else if(NegoCom.Sincronizado__c==true){
                mBotaoImprimir = 'block';
        }
        
        //Re-render
        showProdutos=true;
         myFlag=false;
        //=======================================
        if(idNegociacao==null || idNegociacao==''){
                //Verifica se já temos conversão de negociação para está oportunidade
                Negociacao_Comercial__c[] negCom = [Select      Id 
                                                                                        From    Negociacao_Comercial__c 
                                                                                        where   Oportunidade__c=: this.NegoCom.Oportunidade__c
                                                                                                        and Status_Negociacao__c='Convertido'];
                if(negCom.size()>0){
                        Mesagem='Não se pode criar uma negociação para está oportunidade pois já temos uma negociação convertida';
                        Travar='1';
                }
                //Verifica se temos negociações sem estar sincronizada 
                Negociacao_Comercial__c[] negComSin = [Select   Id 
                                                                                        From    Negociacao_Comercial__c 
                                                                                        where   Oportunidade__c=: this.NegoCom.Oportunidade__c
                                                                                                        and Sincronizado__c=false];
                if(negComSin.size()>0){
                        Mesagem='É necessario sincronizar as negociações comerciais antes de realizar um novo cadastro.';
                        Travar='1';
                }
        }
    }
    public PageReference RemoverItem(){
        Excluir = ApexPages.currentPage().getParameters().get('Excluir');
        Tipo = ApexPages.currentPage().getParameters().get('Tipo');
        Idex = ApexPages.currentPage().getParameters().get('Idex');
        System.debug('O valor de excluir: ' + Excluir + ' O valor do tipo: ' + tipo + ' o valor do idex: ' + idex);
        if(tipo=='Prod'){
          ObjectName = 'Produto_Pedido__c';  
        }
        else if (tipo=='Serv'){
                ObjectName = 'Servico_x_Pedido__c';
                
        }
        else if (tipo=='Cont'){
                ObjectName = 'Contrato_Suporte__c';
                
                
        }
        else if (tipo=='Loc'){
                ObjectName = 'Locacao_x_Pedido__c';
        }
        QueryString ='Select id ,name from '+ObjectName+ ' where id = :Idex';
        sObjectList = Database.Query(QueryString);
        if(sObjectList.size()>0){
                if(tipo=='Cont'){
                        //Procura os produtos cadastrados para remover
                        for(Produto_x_Contrato_Suporte__c ps :[Select   id 
                                                                                                        from    Produto_x_Contrato_Suporte__c 
                                                                                                        where   Contrato_Suporte__c=:Idex]){
                        
                                                                                                        
                                delete ps;
                        }
                        //Procura os recursos cadastrados para remover
                        for(Recurso_x_Contrato_de_Suporte__c rec :[Select       id 
                                                                                                                from    Recurso_x_Contrato_de_Suporte__c 
                                                                                                                where   Contrato_Suporte__c=:Idex]){
                                                                                                        
                                delete rec;
                        }
                }
                else if(tipo=='Loc'){
                
                        //Procura os produtos cadastrados para remover
                        for(Produto_x_Locacao__c ps :[Select    id 
                                                                                                        from    Produto_x_Locacao__c 
                                                                                                        where   Locacao_x_Pedido__c=:Idex]){
                        
                                                                                                        
                                delete ps;
                        }
                }
                        delete sObjectList[0];
        }
        myFlag=false;
        CalculcarObjetos();
        NegoCom.Sincronizado__c=false;
        update NegoCom;
        Pagereference reference = new Pagereference('/apex/cadNegociacaoComercial?id=' + idNegociacao + '&Ex=OK');
        reference.setRedirect(true); 
        return reference;
    }
    
    public clsCadNegociacaoComercial(){
    this.NegoCom = new Negociacao_Comercial__c();
        NegoCom.Id=null;
     myFlag=false;
    }
    public void CalculcarObjetos(){
        if (myFlag==false&& idNegociacao !='' && idNegociacao!=null){
    //CAPTURA A OPORTUNIDADE PARA REALIZAR O CALCULO DOS PRODUTOS.
    Opportunity op = [Select Id,
                                                StageName,
                                                Probability,
                                                Total_da_Locacao__c,
                                                Total_dos_Produtos__c,
                                                Total_dos_Servicos__c,
                                                Total_Mao_de_Obra_Contrato_Suporte__c,
                                                Total_dos_Produtos_Contrato_Suporte__c
                                        from Opportunity where id =:NegoCom.oportunidade__c];           
         // Variaveis de composição
         //Produto
         Decimal TotalProdutos=0;
         Decimal vlrTotalReceitaProd=0;
         Decimal vlrTotalCustoProd=0;
         Decimal vlrImpostosApuradosProd=0;
         Decimal vlrINSSProd=0;
         Decimal vlrRentabilidadeBrutaProd=0;
         Decimal vlrPercRentBrutaProd=0;
         Decimal vlrComissaoNewAgeProd=0;
         Decimal vlrRentabilidadeLiquidaProd=0;
         Decimal vlrPercRentLiqProd=0;
         Decimal vlrVendaUnitariaProd=0;
         Decimal vlrVendaTotalProd=0;
         //Servico
         Decimal TotalServicos=0;
         Decimal TotalRentBrutaServicos=0;
         Decimal TotalRentLiquiServicos=0;
         Decimal vlrTotalReceitaServ=0;
         Decimal vlrTotalCustoServ=0;
         Decimal vlrImpostosApuradosServ=0;
         Decimal vlrINSSServ=0;
         Decimal vlrPercRentBrutaServ=0;
         Decimal vlrComissaoNewAgeServ=0;
         Decimal vlrRentabilidadeLiquidaServ=0;
         Decimal vlrPercRentLiqServ=0;
         Decimal vlrVendaUnitariaServ=0;
         Decimal vlrVendaTotalServ=0;
         //Contrato de Suporte
         Decimal TotalContProd=0;
         Decimal TotalContRec=0;
         //Locacao
         Decimal TotalLocacao=0;
         Decimal vlrTotalReceitaLoc=0;
         Decimal vlrTotalCustoLoc=0;
         Decimal vlrImpostosApuradosLoc=0;
         Decimal vlrINSSLoc=0;
         Decimal vlrRentabilidadeBrutaLoc=0;
         Decimal vlrPercRentBrutaLoc=0;
         Decimal vlrComissaoNewAgeLoc=0;
         Decimal vlrRentabilidadeLiquidaLoc=0;
         Decimal vlrPercRentLiqLoc=0;
         Decimal vlrVendaUnitariaLoc=0;
         Decimal vlrVendaTotalLoc=0;
         //=========================
    //Calcula os  totais dos produtos
    List<aggregateResult> vlrProd = [     SELECT  Sum(Venda_Total_Dolar__c) vlrProducao,
                                                                                        Sum(Total_Receita__c) vlrTotalReceita,
                                                                                        Sum(Total_Custo__c) vlrTotalCusto,
                                                                                        Sum(Impostos_Apurados__c) vlrImpostosApurados,
                                                                                        Sum(INSS__c) vlrINSS,
                                                                                        Sum(Rentabilidade_Bruta__c) vlrRentabilidadeBruta,
                                                                                        Sum(Percentual_Rentabilidade_Bruta__c) vlrPercRentBruta,
                                                                                        Sum(Comissao_New_Age__c) vlrComissaoNewAge,
                                                                                        Sum(Rentabilidade_Liquida__c) vlrRentabilidadeLiquida, 
                                                                                        Sum(Percentual_Rentabilidade_Liquida__c) vlrPercRentLiq, 
                                                                                        Sum(Venda_Unitaria__c) vlrVendaUnitaria, 
                                                                                        Sum(Venda_Total__c) vlrVendaTotal
                                                                        FROM    Produto_Pedido__c 
                                                                        WHERE   Negociacao_Comercial__c = :idNegociacao ];
    if(!vlrProd.isEmpty()){
                TotalProdutos = Double.valueOf((vlrProd[0].get('vlrProducao')==null?0:vlrProd[0].get('vlrProducao')));
                vlrTotalReceitaProd = Double.valueOf((vlrProd[0].get('vlrTotalReceita')==null?0:vlrProd[0].get('vlrTotalReceita')));
                vlrTotalCustoProd = Double.valueOf((vlrProd[0].get('vlrTotalCusto')==null?0:vlrProd[0].get('vlrTotalCusto')));
                vlrImpostosApuradosProd = Double.valueOf((vlrProd[0].get('vlrImpostosApurados')==null?0:vlrProd[0].get('vlrImpostosApurados')));
                vlrINSSProd = Double.valueOf((vlrProd[0].get('vlrINSS')==null?0:vlrProd[0].get('vlrINSS')));
                vlrRentabilidadeBrutaProd = Double.valueOf((vlrProd[0].get('vlrRentabilidadeBruta')==null?0:vlrProd[0].get('vlrRentabilidadeBruta')));
                vlrPercRentBrutaProd = Double.valueOf((vlrProd[0].get('vlrPercRentBruta')==null?0:vlrProd[0].get('vlrPercRentBruta')));
                vlrComissaoNewAgeProd = Double.valueOf((vlrProd[0].get('vlrComissaoNewAge')==null?0:vlrProd[0].get('vlrComissaoNewAge')));
                vlrRentabilidadeLiquidaProd = Double.valueOf((vlrProd[0].get('vlrRentabilidadeLiquida')==null?0:vlrProd[0].get('vlrRentabilidadeLiquida')));
                vlrPercRentLiqProd = Double.valueOf((vlrProd[0].get('vlrPercRentLiq')==null?0:vlrProd[0].get('vlrPercRentLiq')));
                vlrVendaUnitariaProd = Double.valueOf((vlrProd[0].get('vlrVendaUnitaria')==null?0:vlrProd[0].get('vlrVendaUnitaria')));
                vlrVendaTotalProd = Double.valueOf((vlrProd[0].get('vlrVendaTotal')==null?0:vlrProd[0].get('vlrVendaTotal')));
        }	
    //Calcula os totais de servico
    List<aggregateResult> vlrServ = [     SELECT  Sum(Total_dos_Servicos__c) vlrServicos,
                                                                                        Sum(Rentabilidade_bruta__c)  vlrRentBruta,
                                                                                        Sum(Rentabilidade_liquida__c)  vlrRentLiqui,
                                                                                        Sum(Total_Receita__c) vlrTotalReceita,
                                                                                        Sum(Total_do_custo__c) vlrTotalCusto,
                                                                                        Sum(Impostos_Apurados__c) vlrImpostosApurados,
                                                                                        Sum(INSS__c) vlrINSS,
                                                                                        Sum(Percentual_Rentabilidade_Bruta__c) vlrPercRentBruta,
                                                                                        Sum(Comissoa_New_Age__c) vlrComissaoNewAge,
                                                                                        Sum(Percentual_Rentabilidade_Liquida__c) vlrPercRentLiq, 
                                                                                        Sum(Valor_venda_unitaria__c) vlrVendaUnitaria, 
                                                                                        Sum(Valor_venda_total__c) vlrVendaTotal
                                                                        FROM    Servico_x_Pedido__c 
                                                                        WHERE   Negociacao_Comercial__c = :idNegociacao ];
    if(!vlrServ.isEmpty()){
                TotalServicos = Double.valueOf((vlrServ[0].get('vlrServicos')==null?0:vlrServ[0].get('vlrServicos')));
                TotalRentBrutaServicos = Double.valueOf((vlrServ[0].get('vlrRentBruta')==null?0:vlrServ[0].get('vlrRentBruta')));
                TotalRentLiquiServicos = Double.valueOf((vlrServ[0].get('vlrRentLiqui')==null?0:vlrServ[0].get('vlrRentLiqui')));
                vlrTotalReceitaServ = Double.valueOf((vlrServ[0].get('vlrTotalReceita')==null?0:vlrServ[0].get('vlrTotalReceita')));
                vlrTotalCustoServ = Double.valueOf((vlrServ[0].get('vlrTotalCusto')==null?0:vlrServ[0].get('vlrTotalCusto')));
                vlrImpostosApuradosServ = Double.valueOf((vlrServ[0].get('vlrImpostosApurados')==null?0:vlrServ[0].get('vlrImpostosApurados')));
                vlrINSSServ = Double.valueOf((vlrServ[0].get('vlrINSS')==null?0:vlrServ[0].get('vlrINSS')));
                vlrPercRentBrutaServ = Double.valueOf((vlrServ[0].get('vlrPercRentBruta')==null?0:vlrServ[0].get('vlrPercRentBruta')));
                vlrComissaoNewAgeServ = Double.valueOf((vlrServ[0].get('vlrComissaoNewAge')==null?0:vlrServ[0].get('vlrComissaoNewAge')));
                vlrPercRentLiqServ = Double.valueOf((vlrServ[0].get('vlrPercRentLiq')==null?0:vlrServ[0].get('vlrPercRentLiq')));
                vlrVendaUnitariaServ = Double.valueOf((vlrServ[0].get('vlrVendaUnitaria')==null?0:vlrServ[0].get('vlrVendaUnitaria')));
                vlrVendaTotalServ = Double.valueOf((vlrServ[0].get('vlrVendaTotal')==null?0:vlrServ[0].get('vlrVendaTotal')));
        }
        //Calcula o total dos Produtos
        List<aggregateResult> vlrTotProd = [      Select  Sum(Valor_Total_Dos_Produtos__c) vlrContProd
                                                        from    Contrato_Suporte__c 
                                                        where   Negociacao_Comercial__c =:idNegociacao];
        if(!vlrTotProd.isEmpty()){TotalContProd = Double.valueOf((vlrTotProd[0].get('vlrContProd')==null?0:vlrTotProd[0].get('vlrContProd')));}
        //Calcula o total dos recursos
        List<aggregateResult> vlrTotRec = [       Select  Sum(Valor_Total_dos_Recursos__c) vlrContRec
                                                        from    Contrato_Suporte__c 
                                                        where   Negociacao_Comercial__c =:idNegociacao];
        if(!vlrTotRec.isEmpty()){TotalContRec = Double.valueOf( (vlrTotRec[0].get('vlrContRec')==null?0:vlrTotRec[0].get('vlrContRec')) );}     
        
        List<aggregateResult> vlrLoc = [  SELECT  Sum(Total_geral_locacao__c) vlrLocacao,
                                                                                                Sum(Total_da_receita__c) vlrTotalReceita,
                                                                                                Sum(Total_do_custo__c) vlrTotalCusto,
                                                                                                Sum(Impostos_Apurados__c) vlrImpostosApurados,
                                                                                                Sum(INSS__c) vlrINSS,
                                                                                                Sum(Rentabilidade_Bruta__c) vlrRentabilidadeBruta,
                                                                                                Sum(Percentual_Rentabilidade_Bruta__c) vlrPercRentBruta,
                                                                                                Sum(Comissao_New_Age__c) vlrComissaoNewAge,
                                                                                                Sum(Rentabilidade_Liquida__c) vlrRentabilidadeLiquida, 
                                                                                                Sum(Percentual_Rentabilidade_Liquida__c) vlrPercRentLiq, 
                                                                                                Sum(Venda_Unitaria__c) vlrVendaUnitaria, 
                                                                                                Sum(Venda_Total__c) vlrVendaTotal
                                                                                FROM    Locacao_x_Pedido__c
                                                                                WHERE   Negociacao_Comercial__c = :idNegociacao ];
                if(!vlrLoc.isEmpty()){
                        TotalLocacao = Double.valueOf((vlrLoc[0].get('vlrLocacao')==null ?0:vlrLoc[0].get('vlrLocacao')) );
                        vlrTotalReceitaLoc = Double.valueOf((vlrLoc[0].get('vlrTotalReceita')==null?0:vlrLoc[0].get('vlrTotalReceita')));
                vlrTotalCustoLoc = Double.valueOf((vlrLoc[0].get('vlrTotalCusto')==null?0:vlrLoc[0].get('vlrTotalCusto')));
                vlrImpostosApuradosLoc = Double.valueOf((vlrLoc[0].get('vlrImpostosApurados')==null?0:vlrLoc[0].get('vlrImpostosApurados')));
                vlrINSSLoc = Double.valueOf((vlrLoc[0].get('vlrINSS')==null?0:vlrLoc[0].get('vlrINSS')));
                vlrRentabilidadeBrutaLoc = Double.valueOf((vlrLoc[0].get('vlrRentabilidadeBruta')==null?0:vlrLoc[0].get('vlrRentabilidadeBruta')));
                vlrPercRentBrutaLoc = Double.valueOf((vlrLoc[0].get('vlrPercRentBruta')==null?0:vlrLoc[0].get('vlrPercRentBruta')));
                vlrComissaoNewAgeLoc = Double.valueOf((vlrLoc[0].get('vlrComissaoNewAge')==null?0:vlrLoc[0].get('vlrComissaoNewAge')));
                vlrRentabilidadeLiquidaLoc = Double.valueOf((vlrLoc[0].get('vlrRentabilidadeLiquida')==null?0:vlrLoc[0].get('vlrRentabilidadeLiquida')));
                vlrPercRentLiqLoc = Double.valueOf((vlrLoc[0].get('vlrPercRentLiq')==null?0:vlrLoc[0].get('vlrPercRentLiq')));
                vlrVendaUnitariaLoc = Double.valueOf((vlrLoc[0].get('vlrVendaUnitaria')==null?0:vlrLoc[0].get('vlrVendaUnitaria')));
                vlrVendaTotalLoc = Double.valueOf((vlrLoc[0].get('vlrVendaTotal')==null?0:vlrLoc[0].get('vlrVendaTotal')));
                }
                //Negociacao_Comercial__c nc =[Select Id from Negociacao_Comercial__c where id= :idNegociacao];
                //Produtos
                NegoCom.Total_dos_Produtos__c=TotalProdutos;
                NegoCom.Total_Receita_Geral_Produto__c=vlrTotalReceitaProd;
                NegoCom.Total_Custo_Geral_Produto__c=vlrTotalCustoProd;
                NegoCom.Impostos_Apurados_Produto__c=vlrImpostosApuradosProd;
                NegoCom.Total_Rentabilidade_Bruta_Produto__c=vlrRentabilidadeBrutaProd;
                NegoCom.Total_Rentabilidade_Liquida_Produto__c=vlrRentabilidadeLiquidaProd;
                //Servicos
                NegoCom.Total_dos_Servicos__c=TotalServicos;
                NegoCom.Total_Rentabilidade_Liquida_Servico__c=TotalRentLiquiServicos;
                NegoCom.Total_Rentabilidade_Bruta_Servico__c=TotalRentBrutaServicos;
                NegoCom.Total_Receita_Geral_Servico__c=vlrTotalReceitaServ;
                NegoCom.Total_Custo_Geral_Servico__c=vlrTotalCustoServ;
                //NegoCom.Impostos_Apurados_Servico__c=vlrImpostosApuradosServ;
                //Contrato de Suporte
                NegoCom.Total_dos_Produtos_Contrato_Suporte__c=TotalContProd;
                NegoCom.Total_Mao_de_Obra_Contrato_Suporte__c=TotalContRec;
                //Locação
                NegoCom.Total_da_Locacao__c = TotalLocacao;
                NegoCom.Total_Receita_Geral_Locacao__c=vlrTotalReceitaLoc;
                NegoCom.Total_Custo_Geral_Locacao__c=vlrTotalCustoLoc;
                //NegoCom.Impostos_Apurados_Locacao__c=vlrImpostosApuradosLoc;
                NegoCom.Total_Rentabilidade_Bruta_Locacao__c=vlrRentabilidadeBrutaLoc;
                NegoCom.Total_Rentabilidade_Liquida_Locacao__c=vlrRentabilidadeLiquidaLoc;
                //Produtos OP
                op.Total_dos_Produtos__c=TotalProdutos;
                op.Total_Receita_Geral_Produto__c=vlrTotalReceitaProd;
                op.Total_Custo_Geral_Produto__c=vlrTotalCustoProd;
                //op.Impostos_Apurados_Produto__c=vlrImpostosApuradosProd;
                op.Total_Rentabilidade_Bruta_Produto__c=vlrRentabilidadeBrutaProd;
                op.Total_Rentabilidade_Liquida_Produto__c=vlrRentabilidadeLiquidaProd;
                //Serviços OP
                op.Total_dos_Servicos__c=TotalServicos;
                op.Total_Rentabilidade_Liquida_Servico__c=TotalRentLiquiServicos;
                op.Total_Rentabilidade_Bruta_Servico__c=TotalRentBrutaServicos;
                op.Total_Receita_Geral_Servico__c=vlrTotalReceitaServ;
                op.Total_Custo_Geral_Servico__c=vlrTotalCustoServ;
                //op.Impostos_Apurados_Servico__c=vlrImpostosApuradosServ;
                //Contrato de Suporte OP
                op.Total_dos_Produtos_Contrato_Suporte__c=TotalContProd;
                op.Total_Mao_de_Obra_Contrato_Suporte__c=TotalContRec;
                //Locacao OP
                op.Total_da_Locacao__c=TotalLocacao;
                op.Total_Receita_Geral_Locacao__c=vlrTotalReceitaLoc;
                op.Total_Custo_Geral_Locacao__c=vlrTotalCustoLoc;
                //op.Impostos_Apurados_Locacao__c=vlrImpostosApuradosLoc;
                op.Total_Rentabilidade_Bruta_Locacao__c=vlrRentabilidadeBrutaLoc;
                op.Total_Rentabilidade_Liquida_Locacao__c=vlrRentabilidadeLiquidaLoc;
                
                update NegoCom;
                update op;
            //Nessa parte iremos realizar a integração com o web-service.
            //===========================================================
        //return null;
        myFlag=true;
                }
                else{
                        myFlag=true;
                }
    }
    
    public Pagereference ConverterNegociacao(){
        Pagereference reference;
        if(NegoCom.Sincronizado__c==true){
                //Realiza o redirect para a pagina de conversão
                reference = new Pagereference('/apex/cadPedido?idNegociacao=' + NegoCom.Id + '&Conv=1');
                reference.setRedirect(true);
        }
        else{
                reference = new Pagereference('/apex/cadNegociacaoComercial?id=' + NegoCom.Id + '&Sinc=NSINC');
                reference.setRedirect(true);
                //return;
        }
        return reference;
    }
    public Pagereference SincronizarNegociacao(){
        Pagereference reference;
        String Mensagem='';
        
        
        SincronizaNewAge sc = new SincronizaNewAge();
        Integer RetValid=sc.VerificaSinc(idNegociacao);
        if(RetValid!=0){
                reference = new Pagereference('/apex/cadNegociacaoComercial?id=' + NegoCom.Id + '&Sinc=' + String.valueof(RetValid));
                reference.setRedirect(true);
                //Mensagem='Sincronização não permitida para contrato de suporte';
                return reference;
        }
        Mensagem+=sc.RetornoIncluir(idNegociacao,'CALCULO');
        if (Mensagem==''){
                reference = new Pagereference('/apex/cadNegociacaoComercial?id=' + NegoCom.Id + '&Sinc=OK');
                reference.setRedirect(true);
         }
         else{
                reference = new Pagereference('/apex/cadNegociacaoComercial?id=' + NegoCom.Id + '&Sinc=NOK');
                reference.setRedirect(true);
         }
        return reference;
    }
    public  String CriaNegociacao(String idOportunidade){
        String idNegociacao='';
        Integer totOp=0;
        NegoCom.Oportunidade__c=idOportunidade;
        //Negociacao_Comercial__c ncN= new Negociacao_Comercial__c();
        if(NegoCom.id==null){
            
            //Inativa a antiga negociacao
            Negociacao_Comercial__c[] nc = [Select  id 
                                            from    Negociacao_Comercial__c 
                                            where   Oportunidade__c = :this.NegoCom.Oportunidade__c
                                                    and  Status_Negociacao__c='Ativo'
                                            ];
                        totOp=[Select Count() From Negociacao_Comercial__c where Oportunidade__c = :this.NegoCom.Oportunidade__c ];
                        totOp += 1;
            if(nc.size() >0){
                nc[0].Status_Negociacao__c='Historico';
                update nc[0];
            }
            //===========================
            negocom.Status_Negociacao__c='Ativo';
            NegoCom.Versao_da_Negociacao__c=String.valueof(totOp);
            insert NegoCom;
            
        }
        idNegociacao = NegoCom.id;
        return idNegociacao;
    
    }
    

}