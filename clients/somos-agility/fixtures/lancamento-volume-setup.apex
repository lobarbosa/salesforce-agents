// SOMOSAGILITY-30 - massa sintetica de volume. Cria: 1 Account, 1 Contact, 1 PPM_Project__c,
// SR A (Aprovado, 3 lancamentos de 10) e SR B (Pendente - Gestor, 150 lancamentos de 1).
// Exige: dev. Usa TriggerHandler.bypass('PPMProjectTriggerHandler'). Nomes "TESTE SOMOSAGILITY-30".
// Apagar: delete Lancamento_de_Despesas__c / Solicitacao_de_Reembolso__c / PPM_Project__c / Contact / Account com nome TESTE SOMOSAGILITY-30.
TriggerHandler.bypass('PPMProjectTriggerHandler');
Account a = new Account(Name = 'TESTE SOMOSAGILITY-30 Conta'); insert a;
List<Integer> d = new List<Integer>{9,0,0,0,0,0,3,0,0};
Integer s1=0; Integer p=10; for (Integer x : d) { s1 += x*p; p--; }
Integer r1 = Math.mod(s1,11); d.add(r1<2?0:11-r1);
Integer s2=0; p=11; for (Integer x : d) { s2 += x*p; p--; }
Integer r2 = Math.mod(s2,11); d.add(r2<2?0:11-r2);
String cpf=''; for (Integer x : d) cpf += String.valueOf(x);
Contact c = new Contact(AccountId=a.Id, LastName='TESTE SOMOSAGILITY-30 Contato', CPF__c=cpf,
  Data_de_Nascimento__c=Date.newInstance(1990,1,1), Contato_Trabalha_Atualmente_na_Empresa__c='Sim', Phone='1130000000');
insert c;
c = [SELECT Id, PIN__c FROM Contact WHERE Id=:c.Id];
PPM_Project__c pr = new PPM_Project__c(Conta__c=a.Id); insert pr;
Solicitacao_de_Reembolso__c sa = new Solicitacao_de_Reembolso__c(Solicitante__c=c.Id, PIN__c=c.PIN__c, Status__c='Rascunho',
  Possui_JOB_investimento_ou_treinamento__c='Não', Status_de_Aprovacao_e_Etapas__c='Aprovado');
Solicitacao_de_Reembolso__c sb = new Solicitacao_de_Reembolso__c(Solicitante__c=c.Id, PIN__c=c.PIN__c, Status__c='Rascunho',
  Possui_JOB_investimento_ou_treinamento__c='Não', Status_de_Aprovacao_e_Etapas__c='Pendente - Gestor');
insert new List<Solicitacao_de_Reembolso__c>{sa, sb};
List<Lancamento_de_Despesas__c> la = new List<Lancamento_de_Despesas__c>();
for (Integer i=0;i<3;i++) la.add(new Lancamento_de_Despesas__c(Solicitacao_de_Reembolso__c=sa.Id, Relacionado_ao_Projeto__c=pr.Id, Relacionado_a_Conta__c=a.Id, Tipo_da_Despesa__c='Alimentação', Valor_da_Despesa__c=10));
insert la;
List<Lancamento_de_Despesas__c> lb = new List<Lancamento_de_Despesas__c>();
for (Integer i=0;i<150;i++) lb.add(new Lancamento_de_Despesas__c(Solicitacao_de_Reembolso__c=sb.Id, Relacionado_ao_Projeto__c=pr.Id, Relacionado_a_Conta__c=a.Id, Tipo_da_Despesa__c='Alimentação', Valor_da_Despesa__c=1));
insert lb;
System.debug('RESULT PROJ=' + pr.Id + ' SRA=' + sa.Id + ' SRB=' + sb.Id);
