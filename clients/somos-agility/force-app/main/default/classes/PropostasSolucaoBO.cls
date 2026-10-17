public class PropostasSolucaoBO {

    public static void preencherHistoricoStatus(List<Propostas_de_Solucao__c> propostas, Map<Id, Propostas_de_Solucao__c> mapOld) {
        for(Propostas_de_Solucao__c p : propostas) {
            if(Trigger.isInsert || p.StatusPsl__c != mapOld.get(p.Id).StatusPsl__c) {
                HistoricoStatus h = new HistoricoStatus();
                h.dataEntrada = DateTime.now().addHours(-3);
                h.nome = p.StatusPsl__c; 

                List<HistoricoStatus> historicos = new List<HistoricoStatus>();
                if(p.HistoricoStatusPSLJSON__c != null) {
                    historicos = (List<HistoricoStatus>)JSON.deserialize(p.HistoricoStatusPSLJSON__c, List<HistoricoStatus>.class);
                    
                    if(historicos.get(historicos.size() - 1).nome == h.nome)
                        continue;

                    historicos.get(historicos.size() - 1).dataSaida = DateTime.now().addHours(-3);

                    Long milliseconds = historicos.get(historicos.size() - 1).dataSaida.getTime() - historicos.get(historicos.size() - 1).dataEntrada.getTime();
                    Long seconds = milliseconds / 1000;
                    Long minutes = seconds / 60;
                    Long days = minutes / 60 / 24 ;
                    Long hours = (minutes - days * 60 * 24) / 60 ;

                    historicos.get(historicos.size() - 1).dias = days;
                    historicos.get(historicos.size() - 1).horas = hours;
                    historicos.get(historicos.size() - 1).minutos = minutes;
                }
                
                historicos.add(h);

                p.HistoricoStatusPSL__c = '';

                for(HistoricoStatus his : historicos) {
                    if(his.dataSaida != null)
                        p.HistoricoStatusPSL__c += his.nome + ': ' + his.dias + ' dias e ' + his.horas + ' horas.\r\n';
                    else
                        p.HistoricoStatusPSL__c += his.nome + ': Aberto atualmente.\r\n';
                }

                p.HistoricoStatusPSLJSON__c = JSON.serialize(historicos);
            }
        }
    }

    public class HistoricoStatus {
        public DateTime dataEntrada;
        public DateTime dataSaida;
        public Long dias;
        public Long horas;
        public Long minutos;
        public String nome;
    }
}