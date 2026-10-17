public with sharing class ContasSemMovimentoController {

    public class FlowInputs{
        @InvocableVariable
        public Date dataInicio;

        @InvocableVariable
        public Boolean transferir;
  
        @InvocableVariable      
        public String papel;
    }

    																				// Recebe os dados do fluxo
    @InvocableMethod(label='Transferência de contas')
    public static void invocableCarregaArquivos(List<FlowInputs> parametros){
        Boolean transferir = (Boolean) parametros[0].transferir;

        if(transferir == true){
            transferirContas();
        } else {
            Date dataInicio = (Date) parametros[0].dataInicio;
            String papel = (String) parametros[0].papel;            
            List<String> lstPapeis = papel.split(';');
            carregarContas(dataInicio, lstPapeis);
        }    
    }
    																				// Se parametro transferir == false
    public static void carregarContas(Date dataInicio, List<String> lstPapeis){

        // Set<Id> setIdContaComMovimento = new Set<Id>();
        // for(Opportunity opp : [ SELECT  AccountId
        //                         FROM    Opportunity
        //                         WHERE   CreatedDate >= :dataInicio  ] ) {
        //     setIdContaComMovimento.add(opp.AccountId);}
        // // for(AggregateResult aggOrd : [  SELECT  AccountId
        // //                                 FROM    Order
        // //                                 WHERE   CreatedDate >= :dataInicio
        // //                                 GROUP   BY AccountId] ) {
        // //     Id accountId = (Id)aggOrd.get('AccountId');
        // //     setIdContaComMovimento.add(accountId);}
        // Set<Id> setIdContaSemMovimento = new Set<Id>();
        // for(Account acc : [ SELECT  Id, Name, ParentId, (SELECT Id FROM ChildAccounts)
        //                     FROM    Account
        //                     WHERE   Owner.Profile.Name IN ('Vendedor Interno', 'Representante de Vendas')   ]){
        //     Set<Id> setTempId = new Set<Id>();
        //     if(setIdContaComMovimento.contains(acc.Id) || setIdContaComMovimento.contains(acc.ParentId)){
        //         System.debug('CHECK 1');
        //         continue;
        //     } else {
        //         setTempId.add(acc.Id);
        //         System.debug('CHECK 2');
        //         for(Account accChild : acc.ChildAccounts){
        //             if(setIdContaComMovimento.contains(accChild.Id)){
        //                 System.debug('CHECK 3');
        //                 continue;
        //             } else {
        //                 System.debug('CHECK 4');
        //                 setTempId.add(accChild.Id);
        //             }}}
        //     if(!setTempId.isEmpty()){
        //         setIdContaSemMovimento.addAll(setTempId);}
        //     System.debug('setIdContaComMovimento: ' + setIdContaComMovimento);
        //     System.debug('setIdContaSemMovimento: ' + setIdContaSemMovimento);}
        // Seleciona id(GrupoEconômico - ID(Interno)) pela data de criação do registro(opp) e adiciona ao Set
        
        Set<Id> setIdContaComMovimento = new Set<Id>();
        for(Opportunity opp : [ SELECT  Account.GrupoEconomicoIdInterno__c
                                FROM    Opportunity
                                WHERE   CreatedDate >= :dataInicio  ] ) {

	        setIdContaComMovimento.add(opp.Account.GrupoEconomicoIdInterno__c);
        }

        // Seleciona Acc se GrupoEconomicoIdInterno não está no Set contas c/ movimento
        List<TransferenciaConta__c> lstInsertTransf = new List<TransferenciaConta__c>();
        for(Account acc : [ SELECT  Id
                            FROM    Account
                            WHERE   Owner.UserRole.Name IN :lstPapeis
                            AND     GrupoEconomicoIdInterno__c NOT IN :setIdContaComMovimento   ]){
            
            TransferenciaConta__c newTransferencia = new TransferenciaConta__c(
                Conta__c = acc.Id
            );
            lstInsertTransf.add(newTransferencia);
            
        }
        System.debug('lstInsertTransf ' + lstInsertTransf.size());        
        																				// Deleta contas da lista de transferencia
        List<TransferenciaConta__c> lstDeleteTransf = new List<TransferenciaConta__c>();
        lstDeleteTransf = [ SELECT Id FROM TransferenciaConta__c ];
        System.debug('lstDeleteTransf ' + lstDeleteTransf.size());
        
        if(!lstDeleteTransf.isEmpty()){
            Delete lstDeleteTransf;
        }
        if(!lstInsertTransf.isEmpty()){
            Insert lstInsertTransf;
        }
        
        // List<TransferenciaConta__c> lstInsertTransf = new List<TransferenciaConta__c>();
        // for(Id i : setIdContaSemMovimento){
		// 	TransferenciaConta__c newTransferencia = new TransferenciaConta__c(Conta__c = i );  
        //     lstInsertTransf.add(newTransferencia);
        // }

       

    }
    // Se transferir == true
    public static void transferirContas(){

        //Seleciona id do usuário
        Id idUsuario = [SELECT  Id
                        FROM    User
                        WHERE   Username Like 'daniela@maispolimeros.com.br%'
                        AND     LastName = 'Guerini'].Id;

        List<TransferenciaConta__c> lstUpdateTransf = new List<TransferenciaConta__c>();
        lstUpdateTransf = [SELECT Conta__c FROM TransferenciaConta__c];

        //Atualiza proprietário da conta
        List<Account> lstUpdateAccount = new List<Account>();
        for(TransferenciaConta__c trasnf : lstUpdateTransf){
            Account updAcc = new Account(
                Id = trasnf.Conta__c,
                OwnerID = idUsuario
            );
            lstUpdateAccount.add(updAcc);
        }
        //Chamada da innerClass assíncrona
        if(!lstUpdateAccount.isEmpty()){
            System.enqueueJob(new asyncTransfereConta(lstUpdateAccount));
        }

    }

    private class asyncTransfereConta implements Queueable {
        
        private List<Account> lstContas;
        private asyncTransfereConta(List<Account> plstContas){
            lstContas = plstContas;
        }

        public void execute(QueueableContext context){

            List<Account> lstContaAtualizada = lstContas.clone();
            Set<Id> setIdConta = new Set<Id>();

            List<Account> lstEnvio = new List<Account>();
            for(Integer i = 0; i < lstContas.size(); i++){

                lstEnvio.add(lstContas[i]);
                setIdConta.add(lstContas[i].Id);
                lstContaAtualizada.remove(0);

                if(i == 40 || i == (lstContas.size() - 1) ){

                    try{

                        List<TransferenciaConta__c> lstDeleteTransf = new List<TransferenciaConta__c>();
                        lstDeleteTransf = [SELECT Id FROM TransferenciaConta__c where Conta__c IN :setIdConta];

                        if(!lstDeleteTransf.isEmpty()){
                            Delete lstDeleteTransf;
                        }

                        update lstEnvio;

                    } catch (Exception ex){

                    }

                    if(!lstContaAtualizada.isEmpty()){
                        System.enqueueJob(new asyncTransfereConta(lstContaAtualizada));
                        return;
                    } else {

                        Id typeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'NotificaAlteracao'].Id;

                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setNotificationTypeId(typeId);
                        notification.setTitle('Transferência de Contas');
                        notification.setBody('A transferência de contas foi concluída');
                        notification.setTargetId('000000000000000AAA');
                        notification.send(new Set<String>{Userinfo.getUserId()});
                        
                    }
                }
            }
        }
    }

}