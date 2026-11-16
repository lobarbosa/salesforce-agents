// EPLAST-39 fixture: 2 campanhas e 2 oportunidades Industria 'Fechado/Ganho' vinculadas a campanha.
// ATENCAO: a automacao da org cria Case "Pos-vendas: <opp>" na conta ao ganhar a oportunidade; apagar antes da conta: DELETE [SELECT Id FROM Case WHERE Account.Name LIKE 'TESTE EPLAST-39%']; (exige UserPermissionsMarketingUser=true para apagar Campaign).
// Cria: Account, Branch__c (CodeERP__c), PaymentTerms__c, Campaign 'TESTE EPLAST-39 Camp Com Custo' (ActualCost 1000)
//       e 'TESTE EPLAST-39 Camp Sem Custo' (ActualCost vazio), Opportunity ganha 2500 na primeira, 700 na segunda.
// Exige: proprietario da conta com User.ProtheusSellerId__c preenchido (CheckAccountOwnerHasProtheusSellerId);
//        usuario com UserPermissionsMarketingUser=true para criar Campaign. Fazer via sf data update antes (DML misto).
// Usa TriggerUtility.bypassTrigger. Registro Industria evita regras de Tax/PriceBook/FinancialAnalysis.
// Apagar: DELETE [SELECT Id FROM Opportunity WHERE Name LIKE 'TESTE EPLAST-39%']; DELETE [SELECT Id FROM Campaign WHERE Name LIKE 'TESTE EPLAST-39%'];
//         DELETE [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-39%']; DELETE [SELECT Id FROM Branch__c WHERE Name LIKE 'TESTE EPLAST-39%']; DELETE [SELECT Id FROM PaymentTerms__c WHERE Name LIKE 'TESTE EPLAST-39%'];
TriggerUtility.bypassTrigger = true;
Account a = new Account(Name='TESTE EPLAST-39 Conta Camp', CNAE__c='0000000', CompanyName__c='TESTE EPLAST-39', Email__c='teste39@example.invalid', Phone='(11)99999-9999', Store__c='01', BillingStreet='Rua Teste 1', BillingCity='Sao Paulo', BillingState='SP', BillingPostalCode='01000-000', BillingNeighborhood__c='Centro');
insert a;
Branch__c b = new Branch__c(Name='TESTE EPLAST-39 Filial', CodeERP__c='T39'); insert b;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-39 Cond', Codigo__c='T39'); insert pt;
Campaign c1 = new Campaign(Name='TESTE EPLAST-39 Camp Com Custo', ActualCost=1000, IsActive=true);
Campaign c2 = new Campaign(Name='TESTE EPLAST-39 Camp Sem Custo', IsActive=true);
insert new List<Campaign>{c1,c2};
Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
List<Opportunity> os = new List<Opportunity>{
 new Opportunity(Name='TESTE EPLAST-39 Opp 1', AccountId=a.Id, RecordTypeId=rt, StageName='Fechado/Ganho', CloseDate=Date.today(), Amount=2500, CampaignId=c1.Id, Branch__c=b.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV'),
 new Opportunity(Name='TESTE EPLAST-39 Opp 2', AccountId=a.Id, RecordTypeId=rt, StageName='Fechado/Ganho', CloseDate=Date.today(), Amount=700, CampaignId=c2.Id, Branch__c=b.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV')};
insert os;
System.debug('OK opps=' + os.size());
