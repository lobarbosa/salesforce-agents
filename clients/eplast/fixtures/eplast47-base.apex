// EPLAST-47 (verificacao): cria a base sintetica "TESTE EPLAST-47" para classificar conta ao salvar oportunidade.
// Cria: Branch__c, PaymentTerms__c, Account (com TriggerUtility.bypassTrigger), Oportunidade Industria em Qualificacao.
// Exige: ProtheusSellerId__c preenchido no usuario proprietario (VR CheckAccountOwnerHasProtheusSellerId);
//        o script NAO altera o usuario, isso e feito a parte e desfeito ao final.
// Apagar: DELETE de Opportunity, Account, Branch__c, PaymentTerms__c com Name LIKE 'TESTE EPLAST-47%'.
Branch__c br = new Branch__c(Name='TESTE EPLAST-47 Filial', CodeERP__c='T47');
insert br;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-47 Cond', Codigo__c='T47');
insert pt;
TriggerUtility.bypassTrigger = true;
Account a = new Account(Name='TESTE EPLAST-47 Conta A', Phone='(11)912345678', CNAE__c='0000000', CompanyName__c='TESTE EPLAST-47 LTDA',
  Email__c='teste47@example.com', Store__c='01', BillingStreet='Rua Teste 1', BillingCity='Sao Paulo', BillingState='SP',
  BillingPostalCode='01000-000', BillingNeighborhood__c='Centro');
insert a;
TriggerUtility.bypassTrigger = false;
Id rt = [SELECT Id FROM RecordType WHERE SobjectType='Opportunity' AND DeveloperName='Industria' LIMIT 1].Id;
Opportunity o = new Opportunity(Name='TESTE EPLAST-47 Opp 1', AccountId=a.Id, RecordTypeId=rt, StageName='Qualificação',
  CloseDate=Date.today().addDays(10), Amount=3000, Branch__c=br.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV');
insert o;
System.debug('FIXTURE acc=' + a.Id + ' opp=' + o.Id);
