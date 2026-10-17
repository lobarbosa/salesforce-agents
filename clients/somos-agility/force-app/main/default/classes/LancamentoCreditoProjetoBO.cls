public class LancamentoCreditoProjetoBO {
    
    public static void SumarizaLancamentoCreditoProjeto(Set<Id> idProjetos){
        List<PPM_Project__c> projetos = new List<PPM_Project__c>();
        Set<Id> projetosComLancamento = new Set<Id>();
        
        AggregateResult[] groupedResults = [SELECT Projetos__c, SUM(GP_Credito_HC__c),SUM(GP_Credito_HNC__c) ,SUM(Consultor_Credito_HC__c),
                                            SUM(Consultor_Credito_HNC__c),SUM(Analista_Credito_HC__c) ,SUM(Analista_Credito_HNC__c)
                                            FROM Lancamento_de_Creditos_em_Projeto__c
                                            where Projetos__c IN:idProjetos
                                            GROUP BY Projetos__c];
        
        for (AggregateResult ar : groupedResults)  {
            projetosComLancamento.add((Id)ar.get('Projetos__c'));
            projetos.add(new PPM_Project__c(Id=(Id)ar.get('Projetos__c'),GP_Credito_HC__c=double.valueOf(ar.get('expr0')),
                                           GP_Credito_HNC__c=double.valueOf(ar.get('expr1')),Consultor_Credito_HC__c=double.valueOf(ar.get('expr2')),
                                           Consultor_Credito_HNC__c=double.valueOf(ar.get('expr3')),Analista_Credito_HC__c=double.valueOf(ar.get('expr4')),
                                           Analista_Credito_HNC__c=double.valueOf(ar.get('expr5'))));
        }
        
        for(Id idProjeto : idProjetos){
            if(!projetosComLancamento.contains(idProjeto)){
            	projetos.add(new PPM_Project__c(Id=idProjeto,GP_Credito_HC__c=0,
                                        GP_Credito_HNC__c=0,Consultor_Credito_HC__c=0,
                                        Consultor_Credito_HNC__c=0,Analista_Credito_HC__c=0,
                                        Analista_Credito_HNC__c=0));
                         
        	}
    	}
		TriggerHandler.bypass('PPMProjectTriggerHandler');
		update projetos; 
        TriggerHandler.clearBypass('PPMProjectTriggerHandler');
    }
    
    public static void ConcatenaComentarios(Set<Id> idProjetos){
        Map<Id,PPM_Project__c> MapProjetos = new Map<Id,PPM_Project__c>();
        List<Lancamento_de_Creditos_em_Projeto__c> lancamentos = [SELECT id,Observa_o_da_ESU__c,Projetos__c 
                                                                  From Lancamento_de_Creditos_em_Projeto__c
                                                                  where Projetos__c IN:idProjetos
                                                                  Order By createdDate ASC
                                                                 ];
        for(Lancamento_de_Creditos_em_Projeto__c lancamento: lancamentos){
            if(MapProjetos.containsKey(lancamento.Projetos__c)){
                String observacao = MapProjetos.get(lancamento.Projetos__c).Observa_o_da_ESU__c +'\n'+lancamento.Observa_o_da_ESU__c;
                MapProjetos.put(lancamento.Projetos__c,new PPM_Project__c(Id=lancamento.Projetos__c,Observa_o_da_ESU__c=observacao));
            }else{
                MapProjetos.put(lancamento.Projetos__c,new PPM_Project__c(Id=lancamento.Projetos__c,Observa_o_da_ESU__c=lancamento.Observa_o_da_ESU__c));
            }
        }
        
        TriggerHandler.bypass('PPMProjectTriggerHandler');
		update MapProjetos.values(); 
        TriggerHandler.clearBypass('PPMProjectTriggerHandler');
    }

}