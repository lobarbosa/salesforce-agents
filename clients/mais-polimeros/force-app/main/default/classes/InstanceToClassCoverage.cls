/*
    @autor Lucas Oliveira
    @class Classe de Cobertura
*/

public class InstanceToClassCoverage {

	/* <<< INIT ESTOQUE >>> */	
	public static Product2 produto(String name){
		return new Product2( Name = name, isActive = true, CodigoTotvs__c = name );
	}

	public static UnidadeFilial__c filial(){
		return new UnidadeFilial__c( Codigo__c = '01' );
	}	

	public static Queue__c QUEUE_ESTOQUE(){
		return new Queue__c(
            EventName__c        		= 'ESTOQUE_SALESFORCE_TO_TOTVS',
            Status__c           		= 'CREATED',
            Payload__c          		= generateJSonEstoque(),
			IgnoredByTrigger__c 		= false,
			ExceptionStackTrace__c		= 'ExceptionStackTraceOhio'
        );
	}

	public static String generateJSonEstoque(){        
        return '{"ESTOQUE":[{"ITENS":[{"PRODUTO":"ABS-AE8000","FILIAL":"01","QTDEATUAL":"13750","QTDERESERVA":"0","QTDEDISPONIVEL":"13750","MENSAGEM":"OK"}]}]}';
    }
	/* <<< END ESTOQUE >>> */

	public static Account conta( String name ){
		return new Account( Name 	  = name,
							NomeFantasia__c = name,
							ObservacoesLogistica__c = 'test', 
							Codigo__c = '00000601',
							Type = 'S',
                           DisparaFluxoMensal__c = false,
                           Dispara_Flow__c = false
		
		);
	}

	public static Opportunity oportunidade( String name ){
		return new Opportunity( Name          = name,
								ObservacoesLogistica__c = 'test', 
								StageName      = 'Negociação',
								TipoTES__c	   = 'Normal',
								TES__c         = '521',
								TipoDeFrete__c = 'C- CIF',
								Coleta__c 	   = 'Não',
								CodigoTOTVS__c	= '001',
                               	Transportadora__c = 'Test',
								FormaDePagamento__c = 'DE- Depósito',
								CloseDate = System.today() 
								);
	}

	public static UnidadeFilial__c unidadeFilial( string name ){
		return new UnidadeFilial__c(
			Name = name,
			Codigo__c = '01'
		);
	}

	public static CondicaoPagamento__c condicaoPagamento(){
		return new CondicaoPagamento__c(
			Name 		 = 'Teste',
			codigo__c 	 = '01',
			descricao__c = 'Teste'
		);
	}
	
	public static Quote cotacao( String name ){
		return new Quote( Name = name, BloqueioFinanceiro__c = false, BloqueioFrete__c = false );
	}
	
	// public static Queue__c QUEUE_OPP(Id recordId, string payload){
	// 	Queue__c queue = new Queue__c(
    //         EventName__c        		= 'QUOTE_SALESFORCE_TO_TOTVS',
    //         Status__c           		= 'CREATED',
	// 		RecordId__c					= recordId,
    //         Payload__c          		= payload,
	// 		IgnoredByTrigger__c 		= false
    //     );

	// 	insert queue;
	// 	return queue;
	// }
}