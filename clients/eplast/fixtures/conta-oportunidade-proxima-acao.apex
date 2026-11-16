// Fixture EPLAST-27 (provada na dev em 2026-11-15): massa sintetica para o Flow Account_Agente_ProximaAcao.
// Cria: Branch__c e PaymentTerms__c 'TESTE EPLAST-27', 7 Account (C1..C7), oportunidades Industria (abertas e ganhas) e Tasks concluidas.
// Exige: usuario de execucao Administrador (Risk__c so muda por admin/Financeiro) com User.ProtheusSellerId__c preenchido
//        (valor sintetico 'TESTE27'; registre o anterior e devolva ao final). Usa TriggerUtility.bypassTrigger = true.
// Atencao: Risk__c nasce com 'E' por padrao; o script zera nas contas que nao devem ter risco.
// Apagar: DELETE de Task/Opportunity/Account/Branch__c/PaymentTerms__c com Name LIKE 'TESTE EPLAST-27%' e devolver ProtheusSellerId__c.
// Rodar em duas etapas: (1) bloco SELLER, (2) bloco MASSA (ambos Apex anonimo, org de dev explicita).
// --- (1) SELLER (rodar antes; DML em User nao pode misturar com objetos de negocio na mesma transacao) ---
// User u=[SELECT Id FROM User WHERE Id=:UserInfo.getUserId()]; u.ProtheusSellerId__c='TESTE27'; update u;
// --- (2) MASSA ---
TriggerUtility.bypassTrigger = true;
insert new Branch__c(Name='TESTE EPLAST-27 Filial', CodeERP__c='T27');
insert new PaymentTerms__c(Name='TESTE EPLAST-27 Cond', Codigo__c='T27');
Id me=UserInfo.getUserId();
Id rt=[SELECT Id FROM RecordType WHERE SobjectType='Opportunity' AND DeveloperName='Industria' LIMIT 1].Id;
Id br=[SELECT Id FROM Branch__c WHERE Name='TESTE EPLAST-27 Filial' LIMIT 1].Id;
Id pt=[SELECT Id FROM PaymentTerms__c WHERE Name='TESTE EPLAST-27 Cond' LIMIT 1].Id;
Id other=[SELECT Id FROM User WHERE IsActive=true AND Id!=:me AND UserType='Standard' LIMIT 1].Id;
List<String> names=new List<String>{'C1 A1 risco+parada','C2 A2 parada','C3 A3 inativo','C4 NONE','C5 NODATA','C6 NOT_OWNER','C7 risco fora da lista'};
List<Account> accs=new List<Account>();
for(Integer i=0;i<7;i++){
 accs.add(new Account(Name='TESTE EPLAST-27 '+names[i],OwnerId=(i==5?other:me),
  CNAE__c='0000000',CompanyName__c='TESTE EPLAST-27 SA',Email__c='teste27@example.invalid',Store__c='001',Phone='(11)99999999',
  BillingStreet='Rua Teste 1',BillingCity='Teste',BillingState='SP',BillingPostalCode='01000000',BillingNeighborhood__c='Centro'));
}
Database.DMLOptions dml=new Database.DMLOptions(); dml.DuplicateRuleHeader.allowSave=true; Database.insert(accs,dml); // allowSave: a QAS tem regra de duplicidade (provado na QA 2026-11-16)
accs[0].Risk__c='E'; accs[6].Risk__c='A';
update new List<Account>{accs[0],accs[6]};
List<Opportunity> opps=new List<Opportunity>();
Integer[] open_idx=new Integer[]{0,1,3,6};
for(Integer i:open_idx) opps.add(new Opportunity(Name='TESTE EPLAST-27 opp aberta '+names[i],AccountId=accs[i].Id,StageName='Qualificação',CloseDate=Date.today().addDays(30),RecordTypeId=rt,OwnerId=accs[i].OwnerId));
insert opps;
List<Opportunity> won=new List<Opportunity>();
won.add(new Opportunity(Name='TESTE EPLAST-27 ganha C3',AccountId=accs[2].Id,StageName='Fechado/Ganho',CloseDate=Date.today().addDays(-91),RecordTypeId=rt,Branch__c=br,PaymentTermId__c=pt,Formas_de_Pagamento__c='AV'));
won.add(new Opportunity(Name='TESTE EPLAST-27 ganha C4',AccountId=accs[3].Id,StageName='Fechado/Ganho',CloseDate=Date.today().addDays(-10),RecordTypeId=rt,Branch__c=br,PaymentTermId__c=pt,Formas_de_Pagamento__c='AV'));
insert won;
Map<Integer,Integer> days=new Map<Integer,Integer>{0=>45,1=>31,3=>5,6=>45};
List<Task> ts=new List<Task>();
for(Opportunity o:opps){
 for(Integer i:open_idx) if(accs[i].Id==o.AccountId) ts.add(new Task(Subject='TESTE EPLAST-27 atividade',WhatId=o.Id,Status='Completed',ActivityDate=Date.today().addDays(-days.get(i)),OwnerId=me));
}
insert ts;
for(Account a:accs) System.debug('ACC '+a.Name+' '+a.Id);
// Zera o Risk__c padrao ('E') nas contas C2..C6 (passo feito a parte na verificacao; rodar apos a massa).
List<Account> semRisco=new List<Account>();
for(Account a:accs) if(a.Name.contains(' C2 ')||a.Name.contains(' C3 ')||a.Name.contains(' C4 ')||a.Name.contains(' C5 ')||a.Name.contains(' C6 ')){a.Risk__c=null;semRisco.add(a);}
update semRisco;
