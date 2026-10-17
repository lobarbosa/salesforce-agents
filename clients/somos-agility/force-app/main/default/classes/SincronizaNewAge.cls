public with sharing class SincronizaNewAge {
    
    public SincronizaNewAge(){}
    
    
    public Integer VerificaSinc(String idNegociacao){
        /*
        0 = OK
        1 = Nenhum serviço / produto / locação cadastrada / contrato de suporte cadastrado
        2 = Nenhum produto cadastrado dentro do contrato de locação
        3 = Não se pode realizar sincronização para contrato de suporte
        */
            Boolean Sinc=false;
            Integer cntProd=0;
            Integer cntServ=0;
            Integer cntLocPed=0;
            Integer cntContSup=0;
            Boolean Prod=false;
            Boolean Serv=false;
            Boolean CSup=false;
            Boolean ContLoc=false;
            List<aggregateResult> cProd = [ Select  Count(id) ContProd
                                                from    Produto_Pedido__c 
                                                where   Negociacao_Comercial__c =:idNegociacao];
        if(!cProd.isEmpty()){cntProd = Integer.valueOf( (cProd[0].get('ContProd')==null?0:cProd[0].get('ContProd')) );}
        
            List<aggregateResult> cServ = [ Select  Count(id) ContServ
                                                from    Servico_x_Pedido__c 
                                                where   Negociacao_Comercial__c =:idNegociacao];
        if(!cServ.isEmpty()){cntServ = Integer.valueOf( (cServ[0].get('ContServ')==null?0:cServ[0].get('ContServ')) );}
            //Captura as locações dentro da negocia
            Locacao_x_Pedido__c[] cLoc = [  Select  id
                                                from    Locacao_x_Pedido__c 
                                                where   Negociacao_Comercial__c =:idNegociacao];
        for(Locacao_x_Pedido__c loc : cLoc){
            
            List<aggregateResult> cntLocPed2 = [    Select  Count(id) ContLocPed
                                                from    Produto_x_Locacao__c 
                                                where   Locacao_x_Pedido__c =:loc.Id];
            if(!cntLocPed2.isEmpty()){cntLocPed = Integer.valueOf( (cntLocPed2[0].get('ContLocPed')==null?0:cntLocPed2[0].get('ContLocPed')) );}
            if(cntLocPed==0){
                return 2;
            }
        }
        
        List<aggregateResult> cCont = [ Select  Count(id) ContSup
                                                from    Contrato_Suporte__c 
                                                where   Negociacao_Comercial__c =:idNegociacao];
        if(!cCont.isEmpty()){cntContSup = Integer.valueOf( (cCont[0].get('ContSup')==null?0:cCont[0].get('ContSup')) );}
        
        
        if(cntProd!=0){
            Prod=true;
        }
        if(cntServ!=0){
            Serv=true;
        }
        if(cntLocPed!=0){
            ContLoc=true;
        }
        if(cntContSup!=0){
            CSup=true;
        }
        
        if(Prod == false && Serv == false && ContLoc == false && CSup ==true){
            return 3;
        }
        else if(Prod == false && Serv == false && ContLoc == false && CSup ==false){
            return 1;
        }
        return 0;
    }
    
    
    public String RetonoDetalheProduto(String idProd){
            String DescProd='{B}';
            if(idProd!='' && idProd!=null && idProd!='000000000000000'){
                Produto_NewAge__c prod = [Select id,
                                                Codigo_do_Fabricante__c,
                                                Nome_do_Fabricante__c,
                                                Cod_Linha_Negocios__c,
                                                Desc_Linha_Negocios__c,
                                                Cod_Sublinha_de_Produtos__c,
                                                Desc_Sublinha_de_Produtos__c,
                                                Dt_Ultima_Atualizacao__c,
                                                NCM__c,
                                                Descricao__c
                                            from Produto_NewAge__c
                                            where id = :idProd];
                    DescProd='Cod Fabricante: ' + (prod.Codigo_do_Fabricante__c==null || prod.Codigo_do_Fabricante__c=='' ?'': prod.Codigo_do_Fabricante__c ) + ' {B} ';
                    DescProd+='Nome do Fabricante: ' + (prod.Nome_do_Fabricante__c==null || prod.Nome_do_Fabricante__c=='' ? '' : prod.Nome_do_Fabricante__c) + ' {B} ';
                    DescProd+='Cod Linha Negocios: ' + (prod.Cod_Linha_Negocios__c==null || prod.Cod_Linha_Negocios__c=='' ? '': prod.Cod_Linha_Negocios__c) + ' {B} ';
                    DescProd+='Linha de Negocios : ' + (prod.Desc_Linha_Negocios__c==null || prod.Desc_Linha_Negocios__c=='' ? '' : prod.Desc_Linha_Negocios__c) + ' {B} ';
                    DescProd+='Cod Sub-linha: ' + (prod.Cod_Sublinha_de_Produtos__c==null || prod.Cod_Sublinha_de_Produtos__c=='' ? '' : prod.Cod_Sublinha_de_Produtos__c) + ' {B} ';
                    DescProd+='Sub Linha de Produto: ' + (prod.Desc_Sublinha_de_Produtos__c==null || prod.Desc_Sublinha_de_Produtos__c=='' ? '' : prod.Desc_Sublinha_de_Produtos__c)  + ' {B} ';
                    DescProd+='Dt Ult. Atualização: ' + (prod.Dt_Ultima_Atualizacao__c==null  ? '' : String.valueof(prod.Dt_Ultima_Atualizacao__c))  + ' {B} ';
                    DescProd+='NCM: ' + (prod.NCM__c==null || prod.NCM__c=='' ? '' : prod.NCM__c)  + ' {B} ';
                    DescProd+='Descrição: ' + (prod.Descricao__c==null || prod.Descricao__c=='' ? '' : prod.Descricao__c) + ' {B} ';
            }
        return DescProd;
    }
    
    
    public List<selectOption> getMoedaGenerico() {
        List<selectOption> options = new List<selectOption>(); 
        options.add(new selectOption('Real', 'Real')); 
        options.add(new selectOption('Dolar', 'Dolar')); 
        
        return options;
    }
    
    public String RetonoDetalheFornecedor(String idAcc){
            String DescProd='{B}';
            if(idAcc!='' && idAcc!=null && idAcc!='000000000000000'){
                Account Acc = [Select id,CNPJ__c, Name,BillingCity
                                            from Account
                                            where id = :idAcc];
                    DescProd='Nome : ' + (Acc.Name==null || acc.Name=='' ?'': acc.Name ) + ' {B} ';
                    DescProd+='CNPJ : ' + (Acc.CNPJ__c==null || Acc.CNPJ__c=='' ? '' : acc.CNPJ__c) + ' {B} ';
                    DescProd+='Cidade / UF : ' + (Acc.BillingCity==null || Acc.BillingCity=='' ? '' : acc.BillingCity) + ' {B} ';
                    
            }
        return DescProd;
    }
    
    public Boolean ValidaMarkup(String idConta,Decimal vlrMarkup,String idUsuario){
        Boolean vlrOK=true;
        Account AccMark = [Select id, Markup_Minimo__c from Account where id =:idConta];
        User us = [Select id, Cadastro_Markup_Inferior__c from User where id =:idUsuario];
        if((vlrMarkup < AccMark.Markup_Minimo__c) && us.Cadastro_Markup_Inferior__c==false ){
            vlrOK=false;
        }
        return vlrOK;
    
    }
    
    @future(callout=true)
    public static void sincronizarContato (String CNPJ, String WS_SN_CLIENTE, String WS_SN_FORN, String WS_PESS, 
                                            String WS_P_SERVICOS,String Ativo, String Nome_Fantasia, String Razao_Social, 
                                            String Vazio, String Endereco_Cobranca,String Numero_Cobranca, String Complemento,
                                            String CEP_Cobranca, String Bairro_Cobranca,String Cidade_Cobranca, 
                                            String Estado_Prov_Cobranca, Integer Codigo_pais, String Email,
                                            Integer Codigo_Ramo_Atividade, Integer Categoria_Cliente, 
                                            String Inscricao_Estadual,String DDD,String Telefone,
                                            String Logradouro, String Inscricao_Municipal, String Contr_IPI
                                            
                                            ){
                String Mensagem='';
                wsSalesForce.Retorno ret;
                System.debug('O CNPJ é: ' + CNPJ);
                Account conta = [Select Id from Account where cnpj__c=:CNPJ];
                CNPJ = CNPJ.replace('.','');
                CNPJ = CNPJ.replace('/','');
                CNPJ = CNPJ.replace('-','');
            //try{
            //Realiza a comunicação com o serviço e envia as informações para ele
            
            wsSalesForce.wsSalesforceNewAgeSoap conectar = new wsSalesForce.wsSalesforceNewAgeSoap();
            conectar.timeout_x=120000;
            ret=conectar.CadastrarCliente(  CNPJ, WS_SN_CLIENTE, WS_SN_FORN, WS_PESS, WS_P_SERVICOS, Ativo, Nome_Fantasia, 
                                        Razao_Social, Vazio, Endereco_Cobranca, Numero_Cobranca, Complemento, CEP_Cobranca, 
                                        Bairro_Cobranca, Cidade_Cobranca, Estado_Prov_Cobranca, Codigo_pais, Email, 
                                        Codigo_Ramo_Atividade, Categoria_Cliente, Inscricao_Estadual,DDD,telefone,
                                        Logradouro,Inscricao_Municipal,Contr_IPI);
            Mensagem=ret.Mensagem;
            //}
            //catch(System.CalloutException excall){
            //    Mensagem=excall.getMessage();
            //}
            //catch(Exception ex){
             //       Mensagem=ex.getMessage();   
              //  }
            Log_NewAge__c lg = new Log_NewAge__c();
            lg.Acao__c='Chamada Cliente';
            lg.Codigo__c=(ret.cod_retorno!=null?ret.cod_retorno:1);
            lg.Mensagem__c = Mensagem;
            lg.conta__c=conta.id;
            insert lg;
            //lg.Negociacao_Comercial__c=id;
                                    
    
    }
    
    public String RetornoIncluir(String id, String Status){
        String Mensagem='';
        wsSalesForce.ArrayOfPedidoRetorno Pedret = new wsSalesForce.ArrayOfPedidoRetorno() ;
        clsRetornoProcesso ret = new clsRetornoProcesso();
        //try{
            wsSalesForce.wsSalesforceNewAgeSoap conectar = new wsSalesForce.wsSalesforceNewAgeSoap();
            
            //Monta cabeçalho da Negociacao
            
            //Prod = AgrupaProdutosNegociacao(id);
            wsSalesForce.ArrayOfPedido objPedido = AgrupaProdutosNegociacao(id,status);
            conectar.timeout_x=120000;
            Pedret = conectar.IncluirPedido(objPedido);
            System.debug('O retorno é : ' + Pedret);
            ret = ProcessaRetorno(Pedret,id,Status);
            if(ret.Cod_Retorno!=0){
                    Mensagem=ret.Mensagem;
                    
                }
            //}
            //catch(System.CalloutException excall){
            //    Mensagem=excall.getMessage();
            //}
            //catch(Exception ex){
            //        Mensagem=ex.getMessage();   
            //    }
            //Registra o log dentro do sistema
            Log_NewAge__c lg = new Log_NewAge__c();
            lg.Acao__c=Status;
            lg.Codigo__c=(ret.Cod_Retorno!=null?ret.Cod_Retorno:1);
            lg.Mensagem__c = Mensagem;
            lg.Negociacao_Comercial__c=id;
            insert lg;
            if(lg.Codigo__c==0){
                Negociacao_Comercial__c nego = [Select id,Sincronizado__c from Negociacao_Comercial__c where id =:id];
                 nego.Sincronizado__c=true;
                 update nego;
            }
        return Mensagem;
    }
    
    
    public clsRetornoProcesso ProcessaRetorno(wsSalesForce.ArrayOfPedidoRetorno ArPedRet,String id_negociacao,String strStatus){
        clsRetornoProcesso Retorno = new clsRetornoProcesso();
        String Mensagem='';
        String codRetorno='';
        Negociacao_Comercial__c nego;
        Pedido__c ped;
        for(wsSalesForce.PedidoRetorno PedRet : ArPedRet.PedidoRetorno){
            wsSalesForce.ArrayOfProduto_PedidoRetorno arProdPedRet = PedRet.Produto_PedidoRet;
            System.debug('O valor de pedret é : ' + PedRet.Produto_PedidoRet);
            //Varre os produtos
            system.debug('O valor de ar prod é : ' + arProdPedRet);
            try{
                if(arProdPedRet != null ){
                for(wsSalesForce.Produto_PedidoRetorno ProdPedRet : arProdPedRet.Produto_PedidoRetorno){
                    Mensagem = Mensagem + ProdPedRet.WS_DESCRICAO;
                    //Captura os objetos de pedido retornados
                    String strNome = ProdPedRet.ID_SF_Produto;
                    System.debug('ID_Prod_ret : ' + strNome);
                    if(strNome!=null && strNome!=''){
                        strNome = strNome.substring(0, 4);
                        System.debug('Sub_ID_Prod_ret : ' + strNome);
                        if (strNome.toLowerCase() == 'prod')
                        {
                            Produto_Pedido__c prodpedido = [SELECT Id,
                                                Total_Receita__c,
                                                Total_Custo__c,
                                                Outros_Custos__c,
                                                Impostos_Apurados_Venda__c,
                                                Impostos_Apurados_Compra__c,
                                                INSS__c,
                                                Rentabilidade_Bruta__c,
                                                Percentual_Rentabilidade_Bruta__c,
                                                Comissao_New_Age__c,
                                                Rentabilidade_Liquida__c,
                                                Percentual_Rentabilidade_Liquida__c,
                                                Impostos_Apurados_Venda_Dolar__c,
                                                Impostos_Apurados_Compra_Dolar__c,
                                                INSS_Dolar__c,
                                                Rentabilidade_Bruta_Dolar__c,
                                                Rentabilidade_Liquida_Dolar__c,
                                                Total_Receita_Dolar__c,
                                                Total_Custo_Dolar__c,
                                                Outros_Custos_Dolar__c,
                                                Venda_Unitaria__c,
                                                Venda_Total__c,
                                                Venda_Unitaria_Dolar__c,
                                                Venda_Total_Dolar__c
                                                FROM  Produto_Pedido__c
                                                WHERE Name = :ProdPedRet.ID_SF_Produto];            
                            
                            prodpedido.Total_Receita__c = ProdPedRet.Total_Receitas;
                            prodpedido.Total_Custo__c = ProdPedRet.Total_Custos;
                            prodpedido.Outros_Custos__c = ProdPedRet.Outros_Custos;
                            prodpedido.Impostos_Apurados_Venda__c = ProdPedRet.Impostos_Apurados_Venda;
                            prodpedido.Impostos_Apurados_Compra__c = ProdPedRet.Impostos_Apurados_Compra;
                            prodpedido.INSS__c = ProdPedRet.INSS;
                            prodpedido.Rentabilidade_Bruta__c = ProdPedRet.Rentabilidade_Bruta_Item;
                            prodpedido.Percentual_Rentabilidade_Bruta__c = ProdPedRet.Percentual_Rentabilidade_Liquida_Item;
                            prodpedido.Comissao_New_Age__c = ProdPedRet.Comissoes;
                            prodpedido.Rentabilidade_Liquida__c = ProdPedRet.Rentabilidade_Liquida_Item;
                            prodpedido.Percentual_Rentabilidade_Liquida__c = ProdPedRet.Percentual_Rentabilidade_Liquida_Item;
                            prodpedido.Venda_Unitaria__c=ProdPedRet.Valor_venda_unitaria;
                            prodpedido.Venda_Total__c=ProdPedRet.Valor_venda_total;
                            prodpedido.Custo_Unitario_Ajustado__c = ProdPedRet.Custo_ajustado;
                            
                            prodpedido.Total_Receita_Dolar__c = ProdPedRet.Total_Receitas_Dolar;
                            prodpedido.Total_Custo_Dolar__c = ProdPedRet.Total_Custos_Dolar;
                            prodpedido.Outros_Custos_Dolar__c = ProdPedRet.Outros_Custos_Dolar;
                            prodpedido.Impostos_Apurados_Venda_Dolar__c = ProdPedRet.Impostos_Apurados_Venda_Dolar;
                            prodpedido.Impostos_Apurados_Compra_Dolar__c = ProdPedRet.Impostos_Apurados_Compra_Dolar;
                            prodpedido.INSS_Dolar__c = ProdPedRet.INSS_Dolar;
                            prodpedido.Rentabilidade_Bruta_Dolar__c = ProdPedRet.Rentabilidade_Bruta_Item_Dolar;
                            prodpedido.Rentabilidade_Liquida_Dolar__c = ProdPedRet.Rentabilidade_Liquida_Item_Dolar;
                            prodpedido.Venda_Unitaria__c=ProdPedRet.Valor_venda_unitaria;
                            prodpedido.Venda_Total__c=ProdPedRet.Valor_venda_total;
                            prodpedido.Venda_Unitaria_Dolar__c=ProdPedRet.Valor_venda_unitaria_Dolar;
                            prodpedido.Venda_Total_Dolar__c=ProdPedRet.Valor_venda_total_Dolar;
                            prodpedido.Custo_Unitario_Ajustado_Dolar__c = ProdPedRet.Custo_ajustado_Dolar;
                            
                            update prodpedido;
                             
                        }
                        else if (strNome.toLowerCase() == 'serv')
                        {
                            Servico_x_Pedido__c servPedido = [SELECT Id,
                                                Total_Receita__c,
                                                Total_do_custo__c,
                                                Outros_Custos__c,
                                                Impostos_Apurados__c,
                                                INSS__c,
                                                Rentabilidade_Bruta__c,
                                                Percentual_Rentabilidade_Bruta__c,
                                                Comissao_Intermediaria__c,
                                                Rentabilidade_Liquida__c,
                                                Percentual_Rentabilidade_Liquida__c,
                                                Custo_Unitario_Ajustado__c,
                                                Total_Receita_Dolar__c,
                                                Total_do_custo_Dolar__c,
                                                Outros_Custos_Dolar__c,
                                                Impostos_Apurados_Venda_Dolar__c,
                                                Impostos_Apurados_Compra_Dolar__c,
                                                INSS_Dolar__c,
                                                Rentabilidade_Bruta_Dolar__c,
                                                Rentabilidade_Liquida_Dolar__c,
                                                Custo_Unitario_Ajustado_Dolar__c
                                                FROM  Servico_x_Pedido__c
                                                WHERE Name = :ProdPedRet.ID_SF_Produto];
                                                
                            servPedido.Total_Receita__c = ProdPedRet.Total_Receitas;
                            servPedido.Total_do_custo__c = ProdPedRet.Total_Custos;
                            servPedido.Outros_Custos__c = ProdPedRet.Outros_Custos;
                            servPedido.Impostos_Apurados_Venda__c = ProdPedRet.Impostos_Apurados_Venda;
                            servPedido.Impostos_Apurados_Compra__c = ProdPedRet.Impostos_Apurados_Compra;
                            servPedido.INSS__c = ProdPedRet.INSS;
                            //servPedido.Rentabilidade_Bruta__c = ProdPedRet.Rentabilidade_Bruta_Item;
                            servPedido.Percentual_Rentabilidade_Bruta__c = ProdPedRet.Percentual_Rentabilidade_Item;
                            //servPedido.Comissoa_New_Age__c = ProdPedRet.Comissoes;
                            //servPedido.Rentabilidade_Liquida__c = ProdPedRet.Rentabilidade_Liquida_Item;
                            //servPedido.Percentual_Rentabilidade_Liquida__c = ProdPedRet.Percentual_Rentabilidade_Liquida_Item;
                            //servPedido.Valor_venda_unitaria__c=ProdPedRet.Valor_venda_unitaria;
                            //servPedido.Valor_venda_total__c=ProdPedRet.Valor_venda_total;
                            //servPedido.Custo_Unitario_Ajustado__c = ProdPedRet.Custo_ajustado;
                            
                            //servPedido.Total_Receita_Dolar__c = ProdPedRet.Total_Receitas_Dolar;
                            //servPedido.Total_do_custo_Dolar__c = ProdPedRet.Total_Custos_Dolar;
                            //servPedido.Outros_Custos_Dolar__c = ProdPedRet.Outros_Custos_Dolar;
                            servPedido.Impostos_Apurados_Venda_Dolar__c = ProdPedRet.Impostos_Apurados_Venda_Dolar;
                            servPedido.Impostos_Apurados_Compra_Dolar__c = ProdPedRet.Impostos_Apurados_Venda_Dolar;
                            servPedido.INSS_Dolar__c = ProdPedRet.INSS_Dolar;
                            //servPedido.Rentabilidade_Bruta_Dolar__c = ProdPedRet.Rentabilidade_Bruta_Item_Dolar;
                            //servPedido.Rentabilidade_Liquida_Dolar__c = ProdPedRet.Rentabilidade_Liquida_Item_Dolar;
                            //servPedido.Valor_venda_unitaria_Dolar__c=ProdPedRet.Valor_venda_unitaria_Dolar;
                            //servPedido.Valor_venda_total_Dolar__c=ProdPedRet.Valor_venda_total_Dolar;
                            //servPedido.Custo_Unitario_Ajustado_Dolar__c = ProdPedRet.Custo_ajustado_Dolar;
                            
                            update servPedido;
                            
                        }
                        else if (strNome.toLowerCase() == 'prlc')
                        {
                            Produto_x_Locacao__c prodLocacao = [SELECT Id,
                                                Total_Receita__c,
                                                Total_custo__c,
                                                Outros_Custos__c,
                                                Impostos_Apurados_Venda__c,
                                                Impostos_Apurados_Compra__c,
                                                INSS__c,
                                                Rentabilidade_Bruta__c,
                                                Percentual_Rentabilidade_Bruta__c,
                                                Comissao_Intermediaria__c,
                                                Rentabilidade_Liquida__c,
                                                Percentual_Rentabilidade_Liquida__c,
                                                
                                                Total_Receita_Dolar__c,
                                                Total_custo_Dolar__c,
                                                Outros_Custos_Dolar__c,
                                                Impostos_Apurados_Venda_Dolar__c,
                                                Impostos_Apurados_Compra_Dolar__c,
                                                INSS_Dolar__c,
                                                Rentabilidade_Bruta_Dolar__c,
                                                Rentabilidade_Liquida_Dolar__c,
                                                
                                                Locacao_x_Pedido__c
                                                FROM  Produto_x_Locacao__c
                                                WHERE Name = :ProdPedRet.ID_SF_Produto];
                                                
                            prodLocacao.Total_Receita__c = ProdPedRet.Total_Receitas;
                            prodLocacao.Total_custo__c = ProdPedRet.Total_Custos;
                            prodLocacao.Outros_Custos__c = ProdPedRet.Outros_Custos;
                            prodLocacao.Impostos_Apurados_Venda__c = ProdPedRet.Impostos_Apurados_Venda;
                            prodLocacao.Impostos_Apurados_Compra__c = ProdPedRet.Impostos_Apurados_Compra;
                           prodLocacao.INSS__c = ProdPedRet.INSS;
                            prodLocacao.Rentabilidade_Bruta__c = ProdPedRet.Rentabilidade_Bruta_Item;
                            prodLocacao.Percentual_Rentabilidade_Bruta__c = ProdPedRet.Percentual_Rentabilidade_Item;
                            prodLocacao.Comissao_New_Age__c = ProdPedRet.Comissoes;
                            prodLocacao.Rentabilidade_Liquida__c = ProdPedRet.Rentabilidade_Liquida_Item;
                            prodLocacao.Percentual_Rentabilidade_Liquida__c = ProdPedRet.Percentual_Rentabilidade_Liquida_Item;
                            prodLocacao.Venda_Unitaria__c=ProdPedRet.Valor_venda_unitaria;
                            prodLocacao.Venda_Total__c=ProdPedRet.Valor_venda_total;
                            prodLocacao.Custo_Unitario_Ajustado__c = ProdPedRet.Custo_ajustado;
                            
                            prodLocacao.Total_Receita_Dolar__c = ProdPedRet.Total_Receitas_Dolar;
                            prodLocacao.Total_custo_Dolar__c = ProdPedRet.Total_Custos_Dolar;
                            prodLocacao.Outros_Custos_Dolar__c = ProdPedRet.Outros_Custos_Dolar;
                            prodLocacao.Impostos_Apurados_Venda_Dolar__c = ProdPedRet.Impostos_Apurados_Venda_Dolar;
                            prodLocacao.Impostos_Apurados_Compra_Dolar__c = ProdPedRet.Impostos_Apurados_Compra_Dolar;
                            prodLocacao.INSS_Dolar__c = ProdPedRet.INSS_Dolar;
                            prodLocacao.Rentabilidade_Bruta_Dolar__c = ProdPedRet.Rentabilidade_Bruta_Item_Dolar;
                            prodLocacao.Rentabilidade_Liquida_Dolar__c = ProdPedRet.Rentabilidade_Liquida_Item_Dolar;
                            prodLocacao.Venda_Unitaria_Dolar__c=ProdPedRet.Valor_venda_unitaria_Dolar;
                            prodLocacao.Venda_Total_Dolar__c=ProdPedRet.Valor_venda_total_Dolar;
                            prodLocacao.Custo_Unitario_Ajustado_Dolar__c = ProdPedRet.Custo_ajustado_Dolar;
                            
                            update prodLocacao;
                            //Atualiza a Locao
                            Locacao_x_Pedido__c LocPed= new Locacao_x_Pedido__c();
                             LocPed.id=prodLocacao.Locacao_x_Pedido__c;
                            List<aggregateResult> vlrLoc = [    SELECT  
                                                                        Sum(Total_Receita__c) vlrTotalReceita,
                                                                        Sum(Total_custo__c) vlrTotalCusto,
                                                                        Sum(Impostos_Apurados__c) vlrImpostosApurados,
                                                                        Sum(INSS__c) vlrINSS,
                                                                        Sum(Rentabilidade_Bruta__c) vlrRentabilidadeBruta,
                                                                        Sum(Percentual_Rentabilidade_Bruta__c) vlrPercRentBruta,
                                                                        Sum(Comissao_New_Age__c) vlrComissaoNewAge,
                                                                        Sum(Rentabilidade_Liquida__c) vlrRentabilidadeLiquida, 
                                                                        Sum(Percentual_Rentabilidade_Liquida__c) vlrPercRentLiq, 
                                                                        Sum(Venda_Unitaria__c) vlrVendaUnitaria, 
                                                                        Sum(Venda_Total__c) vlrVendaTotal,
                                                                        sum(Custo_Unitario_Ajustado__c) vlrcustoAjust
                                                                FROM    Produto_x_Locacao__c
                                                                WHERE   Locacao_x_Pedido__c = :prodLocacao.Locacao_x_Pedido__c ];
                            
                            if(!vlrLoc.isEmpty()){
                                    //LocPed.Total_da_receita__c = Double.valueOf((vlrLoc[0].get('vlrTotalReceita')==null?0:vlrLoc[0].get('vlrTotalReceita')));
                                   // LocPed.Total_do_custo__c = Double.valueOf((vlrLoc[0].get('vlrTotalCusto')==null?0:vlrLoc[0].get('vlrTotalCusto')));
                                    //LocPed.Impostos_apurados__c = Double.valueOf((vlrLoc[0].get('vlrImpostosApurados')==null?0:vlrLoc[0].get('vlrImpostosApurados')));
                                    //LocPed.INSS__c = Double.valueOf((vlrLoc[0].get('vlrINSS')==null?0:vlrLoc[0].get('vlrINSS')));
                                    //LocPed.Rentabilidade_bruta__c = Double.valueOf((vlrLoc[0].get('vlrRentabilidadeBruta')==null?0:vlrLoc[0].get('vlrRentabilidadeBruta')));
                                    //LocPed.Percentual_rentabilidade_bruta__c = Double.valueOf((vlrLoc[0].get('vlrPercRentBruta')==null?0:vlrLoc[0].get('vlrPercRentBruta')));
                                   // LocPed.Comissao_New_Age__c = Double.valueOf((vlrLoc[0].get('vlrComissaoNewAge')==null?0:vlrLoc[0].get('vlrComissaoNewAge')));
                                    //LocPed.Rentabilidade_liquida__c = Double.valueOf((vlrLoc[0].get('vlrRentabilidadeLiquida')==null?0:vlrLoc[0].get('vlrRentabilidadeLiquida')));
                                    //LocPed.Percentual_rentabilidade_liquida__c = Double.valueOf((vlrLoc[0].get('vlrPercRentLiq')==null?0:vlrLoc[0].get('vlrPercRentLiq')));
                                    LocPed.Venda_Unitaria__c = Double.valueOf((vlrLoc[0].get('vlrVendaUnitaria')==null?0:vlrLoc[0].get('vlrVendaUnitaria')));
                                    LocPed.Venda_Total__c = Double.valueOf((vlrLoc[0].get('vlrVendaTotal')==null?0:vlrLoc[0].get('vlrVendaTotal')));
                                    LocPed.Custo_Unitario_Ajustado__c = Double.valueOf((vlrLoc[0].get('vlrcustoAjust')==null?0:vlrLoc[0].get('vlrcustoAjust')));
                                    update LocPed;
                                }
                        }
                    }
                    }
                }
            }
             catch(System.CalloutException excall){
                //Mensagem=excall.getMessage();
            }
            catch(Exception ex){
                    //Mensagem=ex.getMessage(); 
                }
            
            //Atualiza a negociacao
            nego = [Select  id, 
                            Custo_TechCenter__c,
                            Impostos_Apurados_Produto__c,
                            Percentual_Rentabilidade_Bruta__c,
                            Percentual_Rentabilidade_Liquida__c,
                            Rentabilidade_Bruta__c,
                            Rentabilidade_Liquida__c,
                            Total_Comissao_Intermediaria__c,
                            Total_Custo__c,
                            Total_de_Impostos__c,
                            Total_Receita__c
                    from    Negociacao_Comercial__c
                    where id =:id_negociacao];
            nego.Total_Receita__c = PedRet.Total_Custos;
            nego.Custo_TechCenter__c = PedRet.Custo_TechCenter;
            nego.Total_de_Impostos__c = PedRet.Total_Impostos;
            nego.Total_Comissao_Intermediaria__c = PedRet.Total_Comissao_Intermediaria;
            nego.Rentabilidade_Bruta__c = PedRet.Rentabilidade_Bruta;
            nego.Percentual_Rentabilidade_Bruta__c = PedRet.Percentual_Rentabilidade;
            nego.Rentabilidade_Liquida__c = PedRet.Rentabilidade_Liquida;
            nego.Percentual_Rentabilidade_Liquida__c = PedRet.Percentual_Rentabilidade_liquida;
            System.debug('O valor dentro de strstatus é: ' + strStatus);
            //Veririca se é uma inclusão
            if(strStatus=='INCLUSAO'){
               ped = [Select    id, 
                            Percentual_Rentabilidade_Bruta__c,
                            Percentual_Rentabilidade_Liquida__c,
                            Custo_TechCenter__c,
                            Rentabilidade_Bruta__c,
                            Rentabilidade_Liquida__c,
                            Total_Comissao_Intermediaria__c,
                            Total_Custo__c,
                            Total_de_Impostos__c,
                            Total_Receita__c
                    from    Pedido__c
                    where name =:PedRet.ID_SF]; 
                ped.Total_Receita__c = PedRet.Total_Custos;
                ped.Custo_TechCenter__c = PedRet.Custo_TechCenter;
                ped.Total_de_Impostos__c = PedRet.Total_Impostos;
                ped.Total_Comissao_Intermediaria__c = PedRet.Total_Comissao_Intermediaria;
                ped.Rentabilidade_Bruta__c = PedRet.Rentabilidade_Bruta;
                ped.Percentual_Rentabilidade_Bruta__c = PedRet.Percentual_Rentabilidade;
                ped.Rentabilidade_Liquida__c = PedRet.Rentabilidade_Liquida;
                ped.Percentual_Rentabilidade_Liquida__c = PedRet.Percentual_Rentabilidade_liquida;  
             }
             Mensagem = Mensagem + PedRet.WS_DESCRICAO; 
             codRetorno = PedRet.Status;
        
        }
        Retorno.Mensagem=Mensagem;
        Retorno.Cod_Retorno=(codRetorno!='OK'?2:0);

        return Retorno;
    
    }
    
    public wsSalesForce.Pedido MontaCabecalho(wsSalesForce.ArrayOfProduto_Pedido Prod,String Status,String id){
         wsSalesForce.Pedido Pedidos = new wsSalesForce.Pedido();
         //wsSalesForce.ArrayOfProduto_Pedido Prod = new wsSalesForce.ArrayOfProduto_Pedido();
         
         //Agrupa os produtos por categoria / CNPJ
         //if(Status=='CALCULO'){
            //Prod = AgrupaProdutosNegociacao(id);
         //}
         /*else if(Status=='INCLUSAO'){
         
         }*/
         String CNPJ_Ant='';
         String Condicao_venda_Ant='';
         //MONTA O CABEÇALHO
         for(wsSalesForce.Produto_Pedido objProd : Prod.Produto_Pedido){
         	System.debug('O valor dentro do for é: ' + objProd.ID_SF_Produto);
            if(objProd.CNPJ_Destino != CNPJ_Ant &&   objProd.Operacao_CFOP_Venda != Condicao_venda_Ant ){
                Account nego = [Select id,createddate,CreatedById from Account where CNPJ__c =:objProd.CNPJ_Destino Limit 1];
                User usuario = [Select id,Id_Usuario_New_Age__c from User where id =:nego.CreatedById];
                System.debug('O usuario é: ' + usuario.Id);
                String idProdtes = objProd.ID_SF_Produto;
                System.debug('Id do produto Antes : ' + idProdtes);
                idProdtes = idProdtes.substring(0,3);
                idProdtes = idProdtes.replace('-','');
                idProdtes = idProdtes.replace('0','');
                System.debug('Id do produto : ' + idProdtes);
                if(idProdtes!=''){
                
                    wsSalesForce.Pedido objPed = new wsSalesForce.Pedido();
                    objPed.WS_PESQUISA_PEDIDO='COD';
                    objPed.WS_PESQUISA_EMPRESA='CGC';
                    objPed.WS_PESQUISA_CLIENTE='CGC';
                    objPed.ID_Pedido =objProd.id_pedido;
                    if(usuario.Id_Usuario_New_Age__c != null && usuario.Id_Usuario_New_Age__c != ''){
                    //Coloca o id do usuario
                        objPed.Id_usuario_new_age=usuario.Id_Usuario_New_Age__c;
                    }
                    else{
                    // o id fixo
                        objPed.Id_usuario_new_age='002';
                    }
                    /*
                    Dentro do WS_tipo se deve informar os seguintes campos:
                    
                        CODIGO DESCR--------------------------------------------- 
                        1      Contrato Mensal                                    
                        2      Venda de Produto                                   
                        3      Serviço Esporádico                                 
                        4      Contrato de Locação
                    */
                    System.debug('Id do produto: ' + idProdtes);
                    System.debug('Index of do Pro:  ' + idProdtes.indexOf('Pro'));
                    System.debug('Index of do Ser:  ' + idProdtes.indexOf('Ser'));
                    System.debug('Index of do LP:  ' + idProdtes.indexOf('LP'));
                    System.debug('Index of do PrL:  ' + idProdtes.indexOf('PrL'));
                    if(idProdtes.indexOf('LP')>=0 || idProdtes.indexOf('PrL')>=0){
                        objPed.WS_TIPO='4';
                    }
                    else if(idProdtes.indexOf('Pro')>=0){ 
                        objPed.WS_TIPO='2';
                    }
                    else if(idProdtes.indexOf('Ser')>=0){ 
                        objPed.WS_TIPO='3';
                    }
                    else{
                        objPed.WS_TIPO='S';
                    }
                    
                    objPed.ID_Agility_NewAge =objProd.CNPJ_Faturamento;
                    objPed.CNPJ =objProd.CNPJ_Destino;
                    objPed.WS_TAB_PRECO='1';
                    Datetime dt = System.now();
                    String sDT=dt.format('MM/dd/yyyy');
                    String sHR = dt.format('HH:mm:ss');
                    objPed.CreatedDate=sDT;
                    objPed.CreatedHour=sHR;
                    objPed.WS_COD_COB='R';
                    objPed.Condicao_Pagamento_Compra =objProd.Condicao_Pagamento_Compra;
                    objPed.Condicao_Pagamento_Venda =objProd.Condicao_Pagamento_venda;
                    objPed.WS_CODRESP=1;
                    objPed.Status =Status;
                    objPed.Prazo_Contrato=Integer.valueof( objProd.Prazo_contrato);
                    objPed.Indice_Ajuste=objProd.Indice_Reajuste;
                    
                    //Passsa o cambio_global para o programa.
                    Negociacao_Comercial__c NC = [SELECT   Oportunidade__r.Cambio_Global__c
                                               FROM     Negociacao_Comercial__c
                                               where    id=:id];
                         
                    //Double vlr=nc.Oportunidade__r.Cambio_Global__c;
                    objPed.Cambio_Global=nc.Oportunidade__r.Cambio_Global__c;
                    CNPJ_Ant = objProd.CNPJ_Destino;
                    Condicao_venda_Ant=objProd.Operacao_CFOP_Venda;
                    objPed.Produto_x_Pedido=DividirProdutoPedido(Prod,CNPJ_Ant,Condicao_venda_Ant);
                    Pedidos=objPed;
                }
            }
            
         }
         //wsSalesForce.ArrayOfPedido Ped = new wsSalesForce.ArrayOfPedido();
         //ped.Pedido=Pedidos;
         return Pedidos;
    }
    public wsSalesForce.ArrayOfProduto_Pedido DividirProdutoPedido(wsSalesForce.ArrayOfProduto_Pedido arProd,String CNPJ,String Cond_Venda){
        wsSalesForce.Produto_Pedido[] Prod = new List<wsSalesForce.Produto_Pedido>();
        for(wsSalesForce.Produto_Pedido obProd : arProd.Produto_Pedido){
        	System.debug('O valor dentro do for de Dividir é: ' + obProd.ID_SF_Produto);
        	System.debug('O valor do CNPJ de produto de Dividir é : ' + obProd.CNPJ_Destino);
        	System.debug('O valor do CNPJ de Dividir é : ' + CNPJ);
        	
        	System.debug('O cod de venda é : ' + Cond_Venda);
        	System.debug('O cod de venda dentro do produto é : ' + obProd.Condicao_Pagamento_venda);
            //if(obProd.CNPJ_Destino == CNPJ &&   obProd.Operacao_CFOP_Venda == Cond_Venda ){
             if(obProd.CNPJ_Destino == CNPJ){
                wsSalesForce.Produto_Pedido Oprod = new wsSalesForce.Produto_Pedido();
                Oprod=obProd;
                Prod.add(Oprod);
            }
        }
        wsSalesForce.ArrayOfProduto_Pedido ProdAr = new wsSalesForce.ArrayOfProduto_Pedido();
        Prodar.Produto_Pedido=Prod;
        return Prodar;
        
    }
    public wsSalesForce.ArrayOfPedido AgrupaProdutosNegociacao(String id,String Status){
            
            
            
            wsSalesForce.Pedido[] Pedidos = new List<wsSalesForce.Pedido>();
           //Captura os CNPJ's de acordo com a negociação / produto
            AggregateResult[] groupedResults= [SELECT   CNPJ_de_Destino__c
                                               FROM     Produto_Pedido__c
                                               where    Negociacao_Comercial__c=:id
                                                        GROUP BY    CNPJ_de_Destino__c];
                                                                    //Categoria_de_Compra__c,
                                                                    //Categoria__c];
            for (AggregateResult ar : groupedResults){
            	List<wsSalesForce.Produto_Pedido> Prodp = new List<wsSalesForce.Produto_Pedido>();
            	string nome_ped_ant='';
            	Produto_Pedido__c[] arPed= [SELECT   CNPJ_de_Destino__r.name,
                                                        CNPJ_de_Destino__r.cnpj__c,
                                                        Categoria__r.Codigo_NewAge__c, 
                                                        Categoria_de_Compra__r.Codigo_NewAge__c, 
                                                        Comissao_Intermediaria__c, 
                                                        Condicao_de_Pagamento__c, 
                                                        Condicao_de_Pagamento_Compra__c, 
                                                        Cotacao_Compra__c, 
                                                        Cotacao_do_Dolar__c, 
                                                        CreatedDate, 
                                                        Descricao__c, 
                                                        Fornecedor__r.name,
                                                        Fornecedor__r.Cnpj__c,
                                                        Id, 
                                                        Moeda__c, 
                                                        Moeda_Compra__c, 
                                                        Negociacao_Comercial__r.name, 
                                                        Name, 
                                                        produto_newage__r.Id_NewAge_Prodruto__c, 
                                                        Quantidade__c, 
                                                        Valor_da_Cotacao__c, 
                                                        Valor_de_Compra__c,
                                                        CNPJ_de_Faturamento__r.Cnpj__c,
                                                        markup__c,
                                                        Condicao_de_Pagamento__r.Codigo__c,
                                                        Condicao_de_Pagamento_Compra__r.Codigo__c,
                                                        Pedido__r.name,
                                                        Valor_do_produto__c 
                                                FROM    Produto_Pedido__c
                                                where   Negociacao_Comercial__c=:id 
                                                        and CNPJ_de_Destino__c =:String.valueof(ar.get('CNPJ_de_Destino__c'))];
                                                        //and Categoria_de_Compra__c =:String.valueof(ar.get('Categoria_de_Compra__c'))
                                                        //and Categoria__c =:String.valueof(ar.get('Categoria__c'))  ];
                                                        //and name<>:nome_ped_ant]
                
                for (Produto_Pedido__c ped :arPed){
                                 //objProd = new wsSalesForce.Produto_Pedido();
                				wsSalesForce.Produto_Pedido objProd= new wsSalesForce.Produto_Pedido();                
                                nome_ped_ant=ped.name;
                                objProd.id_pedido=ped.Negociacao_Comercial__r.name;
                                if (ped.Pedido__r.name != null && ped.Pedido__r.name!=''){
                                    objProd.id_pedido=ped.Pedido__r.name;
                                }
                               // System.debug('O valor da Categoria compra é: ' + String.valueof(ar.get('Categoria_de_Compra__c')) );
                               // System.debug('O valor da Categoria venda é: ' + String.valueof(ar.get('Categoria__c')) );
                                System.debug('O valor do CNPJ venda é: ' + String.valueof(ar.get('CNPJ_de_Destino__c')) );
                                System.debug('O nome do produto é: ' + ped.name);
                                
                                objProd.ID_SF_Produto=ped.name;
                                objProd.CNPJ_Destino=ped.CNPJ_de_Destino__r.cnpj__c;
                                objProd.CNPJ_Faturamento=ped.CNPJ_de_Faturamento__r.Cnpj__c;
                                objProd.Condicao_Pagamento_venda=ped.Condicao_de_Pagamento__r.Codigo__c;
                                objProd.Condicao_Pagamento_Compra=ped.Condicao_de_Pagamento_Compra__r.Codigo__c;
                                objProd.Prazo_contrato='0';
                                objProd.Indice_Reajuste='0';
                                
                                objProd.Alimentacao=0;
                                objProd.Cambio_Compra = Ped.Cotacao_Compra__c;
                                objProd.Cambio_Venda =  ped.Cotacao_do_Dolar__c;
                                objProd.Cod_Produto = String.valueof(ped.produto_newage__r.Id_NewAge_Prodruto__c);
                                objProd.Quantidade =Integer.valueOf(ped.Quantidade__c);
                                objProd.WS_QUAN_CONV = 0;
                                objProd.WS_QUAN_REM = 0;
                                objProd.WS_QUAN_REMCO = 0;
                                objProd.WS_ACUMULADO = 0;
                                objProd.WS_CARTEIRA = 0;
                                objProd.WS_RESERVA = 0;
                                objProd.Valor_de_Compra = ped.Valor_do_produto__c;
                                objProd.WS_VALOR_CONV = ped.Valor_do_produto__c;
                                objProd.Moeda_Compra = ped.Moeda_Compra__c;
                                objProd.Operacao_CFOP_Compra = ped.Categoria_de_Compra__r.Codigo_NewAge__c;
                                objProd.Fornecedor = ped.Fornecedor__r.Cnpj__c;
                                objProd.Cambio_Compra = ped.Cotacao_Compra__c;
                                objProd.Moeda_Venda = ped.Moeda__c;
                                objProd.Cambio_Venda = ped.Cotacao_do_Dolar__c;
                                objProd.Operacao_CFOP_Venda = ped.Categoria__r.Codigo_NewAge__c;
                                objProd.Descricao = ped.Descricao__c;
                                objProd.WS_PESO = '0';
                                objProd.WS_UNID = 'UN';
                                objProd.WS_UNID_CONV = 'UN';
                                objProd.WS_CUSTO = 0;
                                objProd.markup = ped.markup__c;
                                objProd.Comissao_Intermediaria = ped.Comissao_Intermediaria__c;
                                objProd.WS_DESCTO=0;
                                objProd.Estacionamento=0;
                                objProd.Pedagio=0;
                                objProd.Passagens=0;
                                objProd.Transporte=0;
                                objProd.Hospedagem=0;
                                objProd.Servicos_Terceiros=0;
                                objProd.Outros=0;
                                objProd.Leasing=false;
                                objProd.Custo_Servico_SF=0;
                                System.debug('O nome do produto no array é: ' + objProd.ID_SF_Produto);
                                Prodp.add(objProd);
                                
                }
               //wsSalesForce.ArrayOfProduto_Pedido ProdAr = new wsSalesForce.ArrayOfProduto_Pedido();
           	   // Prodar.Produto_Pedido=Prod;
               	wsSalesForce.ArrayOfProduto_Pedido Prp = new wsSalesForce.ArrayOfProduto_Pedido();
         		Prp.Produto_Pedido=Prodp;
         		
                Pedidos.add(MontaCabecalho(Prp,Status,id));
                
            }
            system.debug('O tamanho de Pedidos é: ' + Pedidos.size());
            //=Captura os serviços de acordo com a categoria / cnpj
            AggregateResult[] groupedServ= [SELECT  CNPJ_Destino__c,Operacao_CFOP__c
                                           FROM     Servico_x_Pedido__c
                                           where    Negociacao_Comercial__c=:id
                                                    GROUP BY    CNPJ_Destino__c,
                                                                Operacao_CFOP__c];
            for (AggregateResult ar : groupedServ){
            	wsSalesForce.Produto_Pedido[] Prods = new List<wsSalesForce.Produto_Pedido>();
                            for ( Servico_x_Pedido__c serv : [SELECT    Alimentacao__c, 
                                                                        CNPJ_Destino__r.cnpj__c, 
                                                                        CNPJ_de_Faturamento__r.cnpj__c, 
                                                                        Comissao_Intermediaria__c, 
                                                                        Name, 
                                                                        Operacao_CFOP__r.Codigo_NewAge__c, 
                                                                        Operacao_CFOP_Compra__r.Codigo_NewAge__c,
                                                                        Outros__c, 
                                                                        Outros_custos__c, 
                                                                        Passagens__c, 
                                                                        Pedagio__c, 
                                                                        Pedido__c, 
                                                                        Servicos_de_terceiros__c, 
                                                                        Transporte__c, 
                                                                        Hospedagem__c, 
                                                                        Estacionamento__c, 
                                                                        Desconto__c, 
                                                                        Quantidade_Analistas__c, 
                                                                        Condicao_de_Pagamento__c, 
                                                                        Codigo_Fiscal_do_Servico__r.Id_NewAge_Prodruto__c,
                                                                        Codigo_Fiscal_do_Servico__r.Descricao__c,
                                                                        Condicao_de_Pagamento__r.Codigo__c,
                                                                        Condicao_de_Pagamento_Compra__r.Codigo__c,
                                                                        Cambio__c, 
                                                                        Moeda__c,
                                                                        Total_dos_Servicos__c,
                                                                        Negociacao_Comercial__r.name,
                                                                        Pedido__r.name,
                                                                        Total_do_Custo__c,
                                                              			Verba_Pre_alocada_para_deslocamento__c
                                                                FROM Servico_x_Pedido__c
                                                                where   CNPJ_Destino__c =:String.valueof(ar.get('CNPJ_Destino__c'))
                                                                        and Operacao_CFOP__c =:String.valueof(ar.get('Operacao_CFOP__c'))
                                                                        and Negociacao_Comercial__c=:id
                                                                    ]){
                                            wsSalesForce.Produto_Pedido objProd = new wsSalesForce.Produto_Pedido();
                                            
                                            objProd.id_pedido=serv.Negociacao_Comercial__r.name;
                                            if (serv.Pedido__r.name != null && serv.Pedido__r.name!=''){
                                                objProd.id_pedido=serv.Pedido__r.name;
                                            }
                                            objProd.ID_SF_Produto=serv.name;
                                            objProd.CNPJ_Destino=serv.CNPJ_Destino__r.cnpj__c;
                                            objProd.CNPJ_Faturamento=serv.CNPJ_de_Faturamento__r.Cnpj__c;
                                            objProd.Condicao_Pagamento_venda=serv.Condicao_de_Pagamento__r.Codigo__c;
                                            //objProd.Condicao_Pagamento_Compra=serv.Condicao_de_Pagamento_Compra__r.Codigo__c;
                                            objProd.Condicao_Pagamento_Compra='';
                                            objProd.Prazo_contrato='0';
                                            objProd.Indice_Reajuste='0';
                                            
                                            objProd.Alimentacao=serv.Alimentacao__c;
                                            objProd.Cambio_Compra = 0;
                                            objProd.Cambio_Venda =  serv.Cambio__c;
                                            objProd.Cod_Produto = String.valueof(serv.Codigo_Fiscal_do_Servico__r.Id_NewAge_Prodruto__c);
                                            objProd.Quantidade =1;
                                            objProd.WS_QUAN_CONV = 0;
                                            objProd.WS_QUAN_REM = 0;
                                            objProd.WS_QUAN_REMCO = 0;
                                            objProd.WS_ACUMULADO = 0;
                                            objProd.WS_CARTEIRA = 0;
                                            objProd.WS_RESERVA = 0;
                                            objProd.Valor_de_Compra = serv.Total_dos_Servicos__c;
                                            objProd.WS_VALOR_CONV = serv.Total_dos_Servicos__c;
                                            objProd.Moeda_Compra = serv.Moeda__c;
                                            //objProd.Operacao_CFOP_Compra = serv.Operacao_CFOP_Compra__r.Codigo_NewAge__c;
                                            objProd.Operacao_CFOP_Compra = '';
                                            objProd.Fornecedor = '0';
                                            objProd.Cambio_Compra =0;
                                            objProd.Moeda_Venda = serv.Moeda__c;
                                            objProd.Cambio_Venda = serv.Cambio__c;
                                            objProd.Operacao_CFOP_Venda = serv.Operacao_CFOP__r.Codigo_NewAge__c;
                                            //objProd.Descricao = (serv.Codigo_Fiscal_do_Servico__r.Descricao__c != null && serv.Codigo_Fiscal_do_Servico__r.Descricao__c  != '' && serv.Codigo_Fiscal_do_Servico__r.Descricao__c != 'null'  ? 'SEM DESCRICAO':serv.Codigo_Fiscal_do_Servico__r.Descricao__c);
                                            objProd.Descricao = 'SEM DESCRICAO';
                                            objProd.WS_PESO = '0';
                                            objProd.WS_UNID = 'UN';
                                            objProd.WS_UNID_CONV = 'UN';
                                            objProd.WS_CUSTO = 0;
                                            objProd.markup = 0;
                                            objProd.Comissao_Intermediaria = 0;
                                            objProd.WS_DESCTO=serv.Desconto__c;
                                            objProd.Estacionamento=serv.Estacionamento__c;
                                            objProd.Pedagio=serv.Pedagio__c;
                                            objProd.Passagens=serv.Passagens__c;
                                            objProd.Transporte=(serv.Verba_Pre_alocada_para_deslocamento__c!=null &&  serv.Verba_Pre_alocada_para_deslocamento__c!=0 ? serv.Verba_Pre_alocada_para_deslocamento__c : serv.Transporte__c) ;
                                            objProd.Hospedagem=serv.Hospedagem__c;
                                            objProd.Servicos_Terceiros=serv.Servicos_de_terceiros__c;
                                            objProd.Outros=serv.Outros__c;
                                            objProd.Leasing=false;
                                            objProd.Custo_Servico_SF=0;
                                            Prods.add(objProd);
                            }
                            //Pedidos.add(MontaCabecalho(Prods,Status,id));
                            wsSalesForce.ArrayOfProduto_Pedido Prs = new wsSalesForce.ArrayOfProduto_Pedido();
			         		Prs.Produto_Pedido=Prods;
			                Pedidos.add(MontaCabecalho(Prs,Status,id));
                        }
                
            AggregateResult[] groupedLocacao= [SELECT   Locacao_x_Pedido__r.CNPJ_Destino__c CNPJ_dest,
                                                        Locacao_x_Pedido__r.Operacao_CFOP__c Operacao_CFOP
                                               FROM     Produto_x_Locacao__c
                                               where    Negociacao_Comercial__c=:id
                                                        GROUP BY    Locacao_x_Pedido__r.CNPJ_Destino__c,
                                                                    Locacao_x_Pedido__r.Operacao_CFOP__c];
            for (AggregateResult ar : groupedLocacao){
            	wsSalesForce.Produto_Pedido[] Prodl = new List<wsSalesForce.Produto_Pedido>();
                for ( Produto_x_Locacao__c ped : [SELECT    
                                                        Locacao_x_Pedido__r.CNPJ_Destino__r.name,
                                                        Locacao_x_Pedido__r.CNPJ_Destino__r.cnpj__c,
                                                        Locacao_x_Pedido__r.name,
                                                        Categoria_vend__r.Codigo_NewAge__c, 
                                                        Categoria_de_Compra__r.Codigo_NewAge__c, 
                                                        Comissao_Intermediaria__c, 
                                                        Condicao_de_Pagamento__c, 
                                                        Condicao_de_Pagamento_Compra__c, 
                                                        Cotacao_Compra__c, 
                                                        Cotacao_do_Dolar__c, 
                                                        CreatedDate, 
                                                        Descricao__c, 
                                                        Fornecedor__r.name,
                                                        Fornecedor__r.Cnpj__c,
                                                        Id, 
                                                        Moeda__c, 
                                                        Moeda_Compra__c, 
                                                        Negociacao_Comercial__r.name, 
                                                        Name, 
                                                        Produto_NewAgePr__r.Id_NewAge_Prodruto__c, 
                                                        Quantidade__c, 
                                                        Valor_da_Cotacao__c, 
                                                        Valor_de_Compra__c,
                                                        Valor_do_produto__c,
                                                        Locacao_x_Pedido__r.CNPJ_de_Faturamento__r.Cnpj__c,
                                                        Locacao_x_Pedido__r.markup__c,
                                                        Locacao_x_Pedido__r.Leasing__c,
                                                        Locacao_x_Pedido__r.Pedido__r.name,
                                                        Condicao_de_Pagamento__r.Codigo__c,
                                                        Condicao_de_Pagamento_Compra__r.Codigo__c,
                                                        Locacao_x_Pedido__r.Valor_Total_dos_Produtos__c,
                                                        Locacao_x_Pedido__r.Prazo_de_Duracao__r.Name,
                                                        Locacao_x_Pedido__r.Valor_total_locacao__c,
                                                        Locacao_x_Pedido__r.Parcela_com_juros__c,
                                                        Locacao_x_Pedido__r.Margem_Bruta__c,
                                                        Locacao_x_Pedido__r.Juros__c
                                                        //Locacao_x_Pedido__r.markup__c
                                                        //Locacao_x_Pedido__r.Valor_total_produtos_1_ano__c  
                                                FROM    Produto_x_Locacao__c
                                                where   Negociacao_Comercial__c=:id 
                                                        and Locacao_x_Pedido__r.CNPJ_Destino__c=:String.valueof(ar.get('CNPJ_dest'))
                                                        and Locacao_x_Pedido__r.Operacao_CFOP__c =:String.valueof(ar.get('Operacao_CFOP')) 
                                                        ]){
                                wsSalesForce.Produto_Pedido objProd = new wsSalesForce.Produto_Pedido();
                                
                                objProd.id_pedido=ped.Negociacao_Comercial__r.name;
                                if (ped.Locacao_x_Pedido__r.Pedido__r.name != null && ped.Locacao_x_Pedido__r.Pedido__r.name!=''){
                                    objProd.id_pedido=ped.Locacao_x_Pedido__r.Pedido__r.name;
                                }
                                objProd.ID_SF_Produto=ped.name;
                                objProd.CNPJ_Destino=ped.Locacao_x_Pedido__r.CNPJ_Destino__r.cnpj__c;
                                objProd.CNPJ_Faturamento=ped.Locacao_x_Pedido__r.CNPJ_de_Faturamento__r.Cnpj__c;
                                objProd.Condicao_Pagamento_venda=ped.Condicao_de_Pagamento__r.Codigo__c;
                                objProd.Condicao_Pagamento_Compra=ped.Condicao_de_Pagamento_Compra__r.Codigo__c;
                                objProd.Prazo_contrato=ped.Locacao_x_Pedido__r.Prazo_de_Duracao__r.Name;
                                objProd.Indice_Reajuste='0';
                                
                                objProd.Alimentacao=ped.Locacao_x_Pedido__r.Valor_total_locacao__c;//Total da locação
                                objProd.Cambio_Compra = Ped.Cotacao_Compra__c;
                                objProd.Cambio_Venda =  ped.Cotacao_do_Dolar__c;
                                objProd.Cod_Produto = String.valueof(ped.Produto_NewAgePr__r.Id_NewAge_Prodruto__c);
                                objProd.Quantidade =Integer.valueOf(ped.Quantidade__c);
                                objProd.WS_QUAN_CONV = 0;
                                objProd.WS_QUAN_REM = 0;
                                objProd.WS_QUAN_REMCO = 0;
                                objProd.WS_ACUMULADO = 0;
                                objProd.WS_CARTEIRA = 0;
                                objProd.WS_RESERVA = 0;
                                objProd.Valor_de_Compra = ped.Valor_do_produto__c;
                                objProd.WS_VALOR_CONV = ped.Valor_do_produto__c;
                                objProd.Moeda_Compra = ped.Moeda_Compra__c;
                                objProd.Operacao_CFOP_Compra = ped.Categoria_de_Compra__r.Codigo_NewAge__c;
                                objProd.Fornecedor = ped.Fornecedor__r.Cnpj__c;
                                objProd.Cambio_Compra = ped.Cotacao_Compra__c;
                                objProd.Moeda_Venda = ped.Moeda__c;
                                objProd.Cambio_Venda = ped.Cotacao_do_Dolar__c;
                                objProd.Operacao_CFOP_Venda = ped.Categoria_vend__r.Codigo_NewAge__c;
                                objProd.Descricao = ped.Descricao__c;
                                objProd.WS_PESO = '0';
                                objProd.WS_UNID = 'UN';
                                objProd.WS_UNID_CONV = 'UN';
                                objProd.WS_CUSTO = 0;
                                objProd.markup = ped.Locacao_x_Pedido__r.markup__c;
                                objProd.Comissao_Intermediaria = 0;
                                objProd.WS_DESCTO=0;
                                
                                objProd.Estacionamento=ped.Locacao_x_Pedido__r.Parcela_com_juros__c;//Parcela de locação
                                objProd.Pedagio=0;
                                objProd.Passagens=0;
                                objProd.Transporte=0;
                                objProd.Hospedagem=0;
                                objProd.Servicos_Terceiros=0;
                                objProd.Outros=ped.Locacao_x_Pedido__r.Juros__c; //Juros
                                
                                objProd.Leasing=(ped.Locacao_x_Pedido__r.Leasing__c=='Sim'?true:false);
                                objProd.Custo_Servico_SF=0;
                                Prodl.add(objProd);
                }
                
                
                //Pedidos.add(MontaCabecalho(Prodl,Status,id));
                
                wsSalesForce.ArrayOfProduto_Pedido Prl = new wsSalesForce.ArrayOfProduto_Pedido();
         		Prl.Produto_Pedido=Prodl;
                Pedidos.add(MontaCabecalho(Prl,Status,id));
            }
            //wsSalesForce.ArrayOfProduto_Pedido ProdAr = new wsSalesForce.ArrayOfProduto_Pedido();
           // Prodar.Produto_Pedido=Prod;
            
         wsSalesForce.ArrayOfPedido Ped = new wsSalesForce.ArrayOfPedido();
         ped.Pedido=Pedidos;
         return Ped;
                                
        //return ProdAr;
    }

}