public with sharing class ProcessoAprovacaoOpp {
    @AuraEnabled
    public static String montarRelatorio(String userId){
        try {
            List<GroupMember> lstGroupID = [SELECT  GroupId  FROM GroupMember WHERE UserOrGroupId=:userId];

            List<String> lstIds = new List<String>();
            lstIds.add(userId);
            for(GroupMember gm: lstGroupID){
                lstIds.add(gm.GroupId);
            }

            List<ProcessInstance> lstProcInst = [SELECT TargetObjectId
                                                FROM ProcessInstance
                                                WHERE Status = 'Pending'];


            List<Id> lstIdOpp = new List<Id>();
            List<Id> lstIdProcInst = new List<Id>();

            for(ProcessInstance procInst: lstProcInst){
                lstIdOpp.add(procInst.TargetObjectId);
                lstIdProcInst.add(procInst.Id);
            }

                                                    
            List<Opportunity> lstOpps = [SELECT PrecoTotal_ICMS_IPI__c, Name,Classificacao__c,DivisaoNegocio__c, DivisaoNegocio__r.Name, Account.SaldoLimiteMaisPolimeros__c, QuantidadeTotal__c
                                        FROM Opportunity
                                        WHERE  Id IN :lstIdOpp];


            Map<Id, Opportunity> mapOppPInst = new Map<Id, Opportunity>();


            for(ProcessInstance procInst: lstProcInst){
                integer index=0;
                for(Integer i=0; i<lstOpps.size();i++ ){
                    if(procInst.TargetObjectId == lstOpps[i].Id){
                        mapOppPInst.put(procInst.Id, lstOpps[i]);
                        break;
                    }
                }
                
            }



            List<ProcessInstanceStep> lstProcStep = [SELECT  CreatedDate, OriginalActor.Name,StepNodeId, Comments, ProcessInstance.TargetObjectId, ProcessInstanceId
                                                    FROM ProcessInstanceStep  
                                                    WHERE  StepStatus NOT IN ('Approved') AND
                                                        ProcessInstanceId IN :lstIdProcInst];


            List<ProcessInstanceWorkitem> lstProcWork = [SELECT  CreatedDate, OriginalActor.Name,Actor.Name,ProcessInstanceId,ElapsedTimeInMinutes,
                                                        ProcessInstance.ProcessDefinition.Name, ProcessInstance.Status
                                                        FROM ProcessInstanceWorkitem  
                                                        WHERE   ProcessInstanceId IN :lstIdProcInst AND OriginalActorId IN :lstIds];

            Map<Id, ProcessInstanceWorkitem> mapWorkPInst = new Map<Id, ProcessInstanceWorkitem>();

            for(ProcessInstance procInst: lstProcInst){
                integer index=0;
                for(Integer i=0; i<lstProcWork.size();i++ ){
                    if(procInst.Id == lstProcWork[i].ProcessInstanceId){
                        mapWorkPInst.put(procInst.Id, lstProcWork[i]);
                        break;
                    }
                }
                
            }


            List<String> lstOpp = new List<String>();
            List<Processo> lstItens = new List<Processo>();
            for (ProcessInstanceStep proc: lstProcStep){
                    if(mapWorkPInst.containsKey(proc.ProcessInstanceId)){
                    Opportunity opp = mapOppPInst.get(proc.ProcessInstanceId);
                    ProcessInstanceWorkitem procWork = mapWorkPInst.get(proc.ProcessInstanceId);
                    Processo item = new Processo();
                    
                    item.opportunidadeId = '/'+String.valueOf(opp.Id);
                    item.opportunidade = opp.Name;
                    item.grupo = opp.Classificacao__c;
                    if(opp.DivisaoNegocio__c!=null){
                    item.divisao = opp.DivisaoNegocio__r.Name;
                    item.divisaoId = '/'+opp.DivisaoNegocio__c;
                    }
                    item.valorTotal = String.valueOf(opp.get('PrecoTotal_ICMS_IPI__c'));

                    item.id = procWork.Id;
                    item.atribuido = procWork.OriginalActor.Name;
                    item.step = procWork.ProcessInstance.ProcessDefinition.Name;
                    item.status = procWork.ProcessInstance.Status;
                    item.aprovador = procWork.Actor.Name;
                    item.quantidade = String.valueOf(opp.QuantidadeTotal__c.setScale(0))+' KG';
                    item.horasEspera = String.valueOf(procWork.ElapsedTimeInMinutes.setScale(0));
                    item.comments = proc.Comments;
                    Datetime data = proc.CreatedDate;
                    item.data = data.day() + '/' + data.month() + '/' + data.year();
                    lstItens.add(item); 
                }          
            }
            

            return JSON.serialize(lstItens);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String alterarStatus(String novoStatus, String userId, String comentario, String workItemId){

        Approval.ProcessWorkitemRequest req2 =  new Approval.ProcessWorkitemRequest();
        req2.setComments(comentario);
        req2.setAction(novoStatus);
        req2.setNextApproverIds(new Id[] {userId});
        
        // Use the ID from the newly created item to specify the item to be worked
        req2.setWorkitemId(workItemId);
        
        // Submit the request for approval
        Approval.ProcessResult result2 =  Approval.process(req2);
        return montarRelatorio(userId);
    }

    class Processo {
        String id {get;set;}
        String opportunidade {get;set;}
        String opportunidadeId {get;set;}
        String quantidade {get;set;}
        String horasEspera {get;set;}
        String aprovador {get;set;}
        String step {get;set;}
        String data {get;set;}
        String status {get;set;}
        String valorTotal {get;set;}
        String divisaoId {get;set;}
        String divisao {get;set;}
        String grupo {get;set;}
        String atribuido {get;set;}
        String comments {get;set;}
    }
}