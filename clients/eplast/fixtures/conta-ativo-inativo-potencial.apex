// Fixture EPLAST-37 (provada na QA sbx-eplast-qa, 2026-11-15). 6 contas TESTE EPLAST-37 B1..B6 (30, 90, 91, 120 dias, sem compra, Prospect com 30 dias), contatos (B5 com um opt-out), oportunidades Fechado/Ganho, filial e condicao de pagamento.
// Exige: OwnerId de um usuario ativo com ProtheusSellerId__c preenchido (nao altere o usuario). Permite salvar duplicado de teste.
// Apagar: delete Opportunity/Account/Branch__c/PaymentTerms__c com Name LIKE 'TESTE EPLAST-37%' (com TriggerUtility.bypassTrigger=true).
TriggerUtility.bypassTrigger = true;
Database.DMLOptions dml = new Database.DMLOptions(); dml.DuplicateRuleHeader.allowSave = true;
Id own = '005Hp00000gijVrIAI';
Branch__c br = new Branch__c(Name='TESTE EPLAST-37 Filial', CodeERP__c='T37'); insert br;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-37 Prazo', Codigo__c='T37'); insert pt;
List<List<Object>> spec = new List<List<Object>>{
  new List<Object>{'B1','Recorrente',30},new List<Object>{'B2','Recorrente',90},new List<Object>{'B3','Recorrente',91},
  new List<Object>{'B4','Recorrente',120},new List<Object>{'B5','Recorrente',null},new List<Object>{'B6','Prospect',30}};
List<Account> accs = new List<Account>();
for (List<Object> s : spec) accs.add(new Account(OwnerId=own, Name='TESTE EPLAST-37 '+(String)s[0], Type=(String)s[1], BillingState='SP', BillingCity='Cidade Teste', BillingStreet='Rua Teste 1', BillingPostalCode='01000000', BillingNeighborhood__c='Bairro Teste', Sector__c='Alimentos', CNAE__c='0000000', CompanyName__c='TESTE EPLAST-37 Ltda', Email__c='teste37'+(String)s[0]+'@example.invalid', Phone='(11)3000000'+String.valueOf(spec.indexOf(s)), Store__c='01'));
Database.insert(accs, dml);
List<Contact> cons = new List<Contact>();
for (Account a : accs) cons.add(new Contact(AccountId=a.Id, LastName=a.Name, Email='teste37@example.invalid'));
cons.add(new Contact(AccountId=accs[4].Id, LastName='TESTE EPLAST-37 B5 optout', Email='teste37o@example.invalid', HasOptedOutOfEmail=true));
Database.insert(cons, dml);
Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
List<Opportunity> opps = new List<Opportunity>();
for (Integer i=0;i<spec.size();i++) { if (spec[i][2]==null) continue;
  opps.add(new Opportunity(OwnerId=own, Name='TESTE EPLAST-37 Opp '+(String)spec[i][0], AccountId=accs[i].Id, RecordTypeId=rt, StageName='Fechado/Ganho', CloseDate=Date.today().addDays(-(Integer)spec[i][2]), Branch__c=br.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV', FinancialAnalysis__c=true, TaxAnalysis__c=true)); }
insert opps;
System.debug('FIXTURE_OK accs='+accs.size()+' opps='+opps.size());
