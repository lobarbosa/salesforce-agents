public with sharing class clsCadPedido {
    public String Conv {set;get;}
    public String idNegociacao {set;get;}
    public List<Produto_Pedido__c> Produtos {get;set;}
    public List<Servico_x_Pedido__c> Servicos {get;set;}
    public List<Contrato_Suporte__c> ContratoSuportes {get;set;}
    public List<Locacao_x_Pedido__c> Locacoes {get;set;}
    public List<Pedido__c> Pedido {get;set;}
    public String Mensagem{get;set;}
    public String ConvertidoOK{get;set;}
    public String Barras{get;set;}
   public clsCadPedido() {
   		//Gets para serem realizados
   		idNegociacao=Apexpages.currentPage().getParameters().get('idNegociacao');
   		Conv=Apexpages.currentPage().getParameters().get('Conv');
   		ConvertidoOK=Apexpages.currentPage().getParameters().get('ConvertidoOK');
   		ConvertidoOK=(ConvertidoOK=='' || ConvertidoOK==null ?'none':ConvertidoOK);
   		Barras=(ConvertidoOK=='none'?'true':'false');
   		//==============================================
   		System.debug('IdNegociacao : ' + idNegociacao);
   		Pedido = [Select Name,id from Pedido__c where Negociacao_Comercial__c =:idNegociacao]; 
   			
   			//Cria os array como sendo zeros:
			Produtos = new List<Produto_Pedido__c>();
			Servicos= new List<Servico_x_Pedido__c>();
			ContratoSuportes= new List<Contrato_Suporte__c>();
			Locacoes= new List<Locacao_x_Pedido__c>();
	   		//Captura todos os objetos caso tenha o idNegociacao;
   		if (idNegociacao!='' && idNegociacao!=null && (Conv=='1'||Conv=='2')){
   			//Captura os CNPJ's
			AggregateResult[] groupedResults= [SELECT 	CNPJ_de_Destino__c,Categoria_de_Compra__c,Categoria__c
											   FROM 	Produto_Pedido__c
											   where 	Negociacao_Comercial__c=:idNegociacao
											      		GROUP BY 	CNPJ_de_Destino__c,
											      					Categoria_de_Compra__c,
											      					Categoria__c];
			
			for (AggregateResult ar : groupedResults)  {
				Produto_Pedido__c ped = new Produto_Pedido__c();
				Ped= [SELECT 	id,
								CNPJ_de_Destino__c,
								CNPJ_de_Destino__r.name,
								CNPJ_de_Destino__r.CNPJ__c,
								Envolve_Trade_In__c,
								Descricao_Trade_in__c,
								Requer_Acao_Emergencial_na_Pos_Venda__c,
								Descricao_Acao_Emergencial__c,
								Categoria_de_Compra__c,
								Categoria__c,
								Categoria_de_Compra__r.Codigo_NewAge__c,
								Categoria__r.Codigo_NewAge__c,
								Produto_NewAge__r.name,
								Categoria_de_Compra__r.descricao__c,
								Categoria__r.descricao__c
						FROM 	Produto_Pedido__c 
						where 	Negociacao_Comercial__c=:idNegociacao 
								and CNPJ_de_Destino__c =:String.valueof(ar.get('CNPJ_de_Destino__c'))
								and Categoria_de_Compra__c =:String.valueof(ar.get('Categoria_de_Compra__c'))
								and Categoria__c =:String.valueof(ar.get('Categoria__c'))
								Limit 1];
			    Produtos.add(Ped);
			}
			//Servicos
			AggregateResult[] groupedServ= [SELECT 	CNPJ_Destino__c,Operacao_CFOP__c
										   FROM 	Servico_x_Pedido__c
										   where 	Negociacao_Comercial__c=:idNegociacao
										      		GROUP BY 	CNPJ_Destino__c,
										      					Operacao_CFOP__c];
			for (AggregateResult ar : groupedServ){
				
				Servicos = [SELECT 	id,
									Name,
									CNPJ_Destino__c,
									CNPJ_Destino__r.name,
									CNPJ_Destino__r.CNPJ__c,
									Objetivo_do_Projeto__c,
									Data_ideal_Primeiro_Contato__c,
									Instrucoes_Adicionais__c,
									Requer_Acao_Emergencial_na_Pos_Venda__c,
									Descricao_Acao_Emergencial__c,
									Operacao_CFOP__c 
							FROM 	Servico_x_Pedido__c 
							where 	CNPJ_Destino__c =:String.valueof(ar.get('CNPJ_Destino__c'))
									and Operacao_CFOP__c =:String.valueof(ar.get('Operacao_CFOP__c'))
									and Negociacao_Comercial__c =:idNegociacao
									order by CNPJ_Destino__c];
			}
			//Contratos de Suporte
			ContratoSuportes = [SELECT 	id,
										Name,
										CNPJ_de_Destino__c,
										CNPJ_de_Destino__r.name,
										CNPJ_de_Destino__r.CNPJ__c, 
										Prazo_do_contrato__c, 
										Indice_de_Reajuste__c,
										Descricao_do_Indice__c,
										Minuta__c,
										Clausulas_com_acordos_Especiais__c,
										Descricao_Acordos_Especiais__c,
										Usuario_Principal_no_Cliente__c,
										Ativacao_do_Contrato__c,
										Tipo_de_Faturamento__c,
										Descricao_Tipo_de_Faturamento__c,
										Instrucoes_Adicionais__c,
										Requer_Acao_Emergencial_na_Pos_Venda__c,
										Descricao_Acao_Emergencial__c
								FROM 	Contrato_Suporte__c 
								where 	Negociacao_Comercial__c=:idNegociacao 
										order by CNPJ_de_Destino__c];
			//Locações
			AggregateResult[] groupedLocacao= [SELECT 	CNPJ_Destino__c,
														Operacao_CFOP__c
											   FROM 	Locacao_x_Pedido__c
											   where 	Negociacao_Comercial__c=:idNegociacao
											      		GROUP BY 	CNPJ_Destino__c,
											      					Operacao_CFOP__c];
			
			for (AggregateResult ar : groupedLocacao){
				Locacoes = [SELECT 	id,
									Name, 
									CNPJ_Destino__c,
									CNPJ_Destino__r.name,
									CNPJ_Destino__r.CNPJ__c,
									Prazo_de_Duracao__c, 
									Indice_de_Reajuste__c,
									Descricao_Indice_Reajuste__c,
									Minuta__c,
									Modificar_Clausula_Padrao_de_Cancelamane__c,
									Justificativa_Clausula_Padrao__c,
									Clausulas_com_acordos_Especiais__c,
									Descritivo_Clausulas_com_Acordo__c,
									Usuario_Principal_no_Cliente__c,
									Ativacao_do_Suporte_Referente_a_Locacao__c,
									Tipo_de_Faturamento__c,
									Parcela_Final_de_Opcao_de_Compra__c,
									Descricao_Parcela_Final__c,
									Instrucoes_Adicionais__c,
									Requer_Acao_Emergencial_na_Pos_Venda__c,
									Descricao_Acao_Emergencial__c,
									Operacao_CFOP__c
							FROM 	Locacao_x_Pedido__c 
							where 	Negociacao_Comercial__c=:idNegociacao 
									and CNPJ_Destino__c=:String.valueof(ar.get('CNPJ_Destino__c'))
									and Operacao_CFOP__c =:String.valueof(ar.get('Operacao_CFOP__c'))
									order by CNPJ_Destino__c];
					}
   		}
   		//==================================================;
    }
   private String GeraPedido(String idNego,String idConta,String CFOP_Compra,String CFOP_Venda){
    		String idPedido='';
    		//Verifica se já possui IdPedido cadastrado e retorna o mesmo para o sistema
    		Pedido__c[] pedi = [Select id 
    							From Pedido__c 
    							where 	Negociacao_Comercial__c=:idNego 
    									/*and CNPJ_ENTREGA__c =:idConta
    									and Operaracao_CFOP_Compra__c=:CFOP_Compra
    									and Operacao_CFOP_Venda__c=:CFOP_Venda*/
    									];
    		if(pedi.size() > 0){
    			idPedido = pedi[0].id;
    		}
    		else{
    			Pedido__c pnew = new Pedido__c();
    			pnew.Negociacao_Comercial__c=idNego;
    			//pnew.CNPJ_ENTREGA__c=idConta;
    			//pnew.Operaracao_CFOP_Compra__c=(CFOP_Compra==null||CFOP_Compra==''?null:CFOP_Compra);
    			//pnew.Operacao_CFOP_Venda__c=(CFOP_Venda==null||CFOP_Venda==''?null:CFOP_Venda);
    			insert pnew;
    			idPedido=pnew.id;
    		} 
    		return idPedido;
    }
    public PageReference SalvarPedido(){
    	String error='';
    	Savepoint sp;
    	
    	if (!Test.isRunningTest())
    	{
    		sp = Database.setSavepoint();
    	}
    	
    	Pagereference reference;
    	//Grava os produtos
    	for(Produto_Pedido__c prod : Produtos ){
			String idPedProd='';
    		System.debug('Entro no for');
    		//if(idPedProd!=''){
    			System.debug('Entro no if');
	    		//Captura os produtos
	    		for (Produto_Pedido__c listProd :[SELECT 	id,
															CNPJ_de_Destino__c,
															CNPJ_de_Destino__r.name,
															CNPJ_de_Destino__r.CNPJ__c,
															Envolve_Trade_In__c,
															Descricao_Trade_in__c,
															Requer_Acao_Emergencial_na_Pos_Venda__c,
															Descricao_Acao_Emergencial__c  
													FROM 	Produto_Pedido__c 
													where 	Negociacao_Comercial__c=:idNegociacao 
															and CNPJ_de_Destino__c =:String.valueof(prod.CNPJ_de_Destino__c)
															and Categoria_de_Compra__c =:prod.Categoria_de_Compra__c
															and Categoria__c =:prod.Categoria__c
															]){
	    		
		    			try{
		    				
		    				if (listProd.Envolve_Trade_In__c == 'Sim' && (listProd.Descricao_Trade_in__c=='' || listProd.Descricao_Trade_in__c==null) ){
		    					//error+='Informe a Descrição do Trade in';
		    				}
		    				
		    				if (listProd.Requer_Acao_Emergencial_na_Pos_Venda__c == 'Sim' && (listProd.Descricao_Acao_Emergencial__c=='' || listProd.Descricao_Acao_Emergencial__c==null) ){
		    					//error+='Informe a Descrição Ação Emergencial';
		    				}
		    				if(error==''){
							 idPedProd=GeraPedido(idNegociacao,prod.CNPJ_de_Destino__c,
    									prod.Categoria_de_Compra__c,prod.Categoria__c);
		    				}
		    				if(error==''){
		    					
			    				listProd.Envolve_Trade_In__c=prod.Envolve_Trade_In__c;
			    				listProd.Descricao_Trade_in__c=prod.Descricao_Trade_in__c;
			    				listProd.Requer_Acao_Emergencial_na_Pos_Venda__c=prod.Requer_Acao_Emergencial_na_Pos_Venda__c;
			    				listProd.Descricao_Acao_Emergencial__c=prod.Descricao_Acao_Emergencial__c;
			    				listProd.Pedido__c=idPedProd;
			    				update listProd;
		    				}
		    			}
		    			catch(Exception ex){
		    				error+='Descrição do erro: ' + ex.getMessage() + '. Ao salvar o produto: '+String.valueof(listProd.Name)+' <br/>';	
		    				break;
		    			}
		    		}
				//}
    		//else{
    		//	error+='Erro de criação / associação do Pedido em produtos <br/>';
    		//	break;
    		//}
    	}
    	//Grava os Serviços
    	for(Servico_x_Pedido__c serv : Servicos ){
    		String idPedServ=GeraPedido(idNegociacao,serv.CNPJ_Destino__c,'',serv.Operacao_CFOP__c);
    		if(idPedServ!=''){
    			try{
	    			serv.Pedido__c=idPedServ;
	    			update serv;
    			}
    			catch(Exception ex){
    				error+='Descrição do erro: ' + ex.getMessage() + '. Ao salvar o serviço: '+String.valueof(serv.Name)+'<br/>';
    				break;	
    				
    			}
    		}
    		else{
    			error+='Erro de criação / associação  do Pedido em serviços <br/>';
    			break;
    		}
    	}
    	//Grava os Contratos de Suporte
    	for(Contrato_Suporte__c cs : ContratoSuportes ){
    		String idPedCont=GeraPedido(idNegociacao,cs.CNPJ_de_Destino__c,'','');
    		if(idPedCont!=''){
    			try{
	    			cs.Pedido__c=idPedCont;
	    			update cs;
    			}
    			catch(Exception ex){
    				error+='Descrição do erro: ' + ex.getMessage() + '. Ao salvar o contrato de suporte: '+cs.Name+' <br/>';	
    				break;
    				
    			}
    		}
    		else{
    			error+='Erro de criação / associação  do Pedido em Contrato de Suporte<br/>';
    			break;
    		}
    	}
    	//Grava as Locações
    	for(Locacao_x_Pedido__c loc : Locacoes ){
    		String idPedLoc=GeraPedido(idNegociacao,loc.CNPJ_Destino__c,'',loc.Operacao_CFOP__c);
    		if(idPedLoc!=''){
    			try{
	    			loc.Pedido__c=idPedLoc;
	    			update loc;
    			}
    			catch(Exception ex){
    				error+='Descrição do erro: ' + ex.getMessage() + '. Ao salvar o contrato de locação: '+loc.Name+' <br/>';
    				break;	
    				
    			}
    		}
    		else{
    			error+='Erro de criação / associação  do Pedido em Contrato de Locações<br/>';
    			break;
    		}
    	}
    	//=================
    	Mensagem=error;
    	
    	  
    	 if(error!=''){
	    	 	
    	 	if (!Test.isRunningTest())
    	 	{
    	 		Database.rollback(sp);
    	 	}
    	 }
    	 else{
    	 	
    	 	
    	 	if(idNegociacao!=null && idNegociacao!=	''){
		    		Negociacao_Comercial__c nc = [Select id,oportunidade__c from Negociacao_Comercial__c where id=:idNegociacao];
		    	 	nc.Status_Negociacao__c='Convertido';
		    	 	update nc;
		    	 	Opportunity op = [Select Id,StageName,Probability from Opportunity where id =:nc.oportunidade__c];
		    	 	
		    	 	op.StageName='6 - Fechado/Ganho';
		    	 	op.Probability=100;
		    	 	op.Motivo__c='Melhor solução';
		    	 	update op;
	    	
	    		}
    	 	
    	 	reference=new Pagereference('/apex/cadPedido?idNegociacao='+idNegociacao+'&Conv=2');
    	 	reference.setRedirect(true);
    	 }
    	 Sincronizarped(idNegociacao);
         return reference;
    }
    @future(callout=true)
    public static void Sincronizarped(String idNegociacao){
    	String Mensagem='';
    	 SincronizaNewAge sc = new SincronizaNewAge();
    	 if(sc.VerificaSinc(idNegociacao)==0){
    	 	if (!Test.isRunningTest())
    	 	{
    			Mensagem+=sc.RetornoIncluir(idNegociacao,'INCLUSAO');
    	 	}
    	 	else{
    	 		Mensagem+='';
    	 	}
    	  }
    
    }
    public PageReference AbreOportunidade(String idOportunidade,String idPedido){
    	
         Pagereference reference;
         return reference;
    }

}