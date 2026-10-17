trigger trgNegociacaoComercial on Negociacao_Comercial__c (before delete, after insert) {
	    Desabilita_trigger__c settings = Desabilita_trigger__c.getInstance();

if(settings.Ativo__c==false){
	if(trigger.isbefore && trigger.isDelete){
		for (Negociacao_Comercial__c objNeg: Trigger.old){
			//se o status da negociação for historico ou convertido trava a deleção
			if(objNeg.Status_Negociacao__c=='Convertido' || objNeg.Status_Negociacao__c=='Historico' || objNeg.Status_Negociacao__c=='Ativo'){
				
					objNeg.adderror('Esse registro não poder ser deletado pois está na situação : ' + objNeg.Status_Negociacao__c);
				}
			}
		}
	if(trigger.isAfter && trigger.isInsert){
		//verifica se já possui uma negociação convertida para a oportunidade;
		for (Negociacao_Comercial__c objNeg: Trigger.new){
			//se o status da negociação for historico ou convertido trava a deleção
			Negociacao_Comercial__c[] ng = [	Select 	id,Status_Negociacao__c 
											from 	Negociacao_Comercial__c where oportunidade__c =:objNeg.oportunidade__c
											and Status_Negociacao__c='Convertido'];
			if(ng.size()>0){
				
					//objNeg.adderror('Já existe negociações convertidas, para está oportunidade não se pode abrir uma nova negociação');
				}
			}
	}
}
	
}