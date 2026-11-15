// Fixture EPLAST-36 (reusavel). Cria dado SINTETICO na dev (sbx-eplast-dev):
//  - 1 Branch__c (CodeERP__c) e 1 PaymentTerms__c, exigidos pela validation rule de Opp Fechado/Ganho
//  - 5 Contas (Type/BillingState/Sector__c variados), cada uma com 1 Contato; A1 tem 2o contato com HasOptedOutOfEmail=true
//  - Oportunidades Fechado/Ganho (RecordType Industria) para alimentar o rollup Account.LastPurchase__c
// Exige: Account.Owner.ProtheusSellerId__c preenchido (validation CheckAccountOwnerHasProtheusSellerId).
//   Preencha ANTES no usuario de execucao (so na dev), registre o valor anterior e devolva ao final:
//   UPDATE User SET ProtheusSellerId__c='TESTE36' WHERE Username = <usuario do job>
// Usa TriggerUtility.bypassTrigger=true para nao disparar integracao (Protheus) nas triggers.
// Apagar: DELETE [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-36%']; (cascata em Contact/Opp)
//         DELETE [SELECT Id FROM Branch__c WHERE Name LIKE 'TESTE EPLAST-36%'];
//         DELETE [SELECT Id FROM PaymentTerms__c WHERE Name LIKE 'TESTE EPLAST-36%'];
TriggerUtility.bypassTrigger = true;
Branch__c br = new Branch__c(Name='TESTE EPLAST-36 Filial', CodeERP__c='T36'); insert br;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-36 Prazo', Codigo__c='T36'); insert pt;
// nome, tipo, UF, setor, dias desde ultima compra (null = sem compra)
List<List<Object>> spec = new List<List<Object>>{
  new List<Object>{'A1','Recorrente','SP','Alimentos',30},
  new List<Object>{'A2','Recorrente','MG','Bebidas',120},
  new List<Object>{'A3','Inativo','SP','Alimentos',200},
  new List<Object>{'A4','Sazonal','RJ','Industrial',400},
  new List<Object>{'A5','Recorrente','SP','Alimentos',null}
};
List<Account> accs = new List<Account>();
for (List<Object> s : spec) accs.add(new Account(Name='TESTE EPLAST-36 '+(String)s[0], Type=(String)s[1], BillingState=(String)s[2], BillingCity='Cidade Teste', BillingStreet='Rua Teste 1', BillingPostalCode='01000000', BillingNeighborhood__c='Bairro Teste', Sector__c=(String)s[3], CNAE__c='0000000', CompanyName__c='TESTE EPLAST-36 Ltda', Email__c='teste36'+(String)s[0]+'@example.invalid', Phone='(11)3999000'+String.valueOf(accs.size()), Store__c='01'));
Database.DMLOptions dml = new Database.DMLOptions(); dml.DuplicateRuleHeader.allowSave = true; // QAS tem regra de duplicidade e dado real copiado
List<Database.SaveResult> srs = Database.insert(accs, dml); for (Database.SaveResult sr : srs) if (!sr.isSuccess()) throw new DmlException(String.valueOf(sr.getErrors()));
List<Contact> cons = new List<Contact>();
for (Account a : accs) cons.add(new Contact(AccountId=a.Id, LastName=a.Name, Email='teste36@example.invalid'));
cons.add(new Contact(AccountId=accs[0].Id, LastName='TESTE EPLAST-36 A1 optout', Email='teste36optout@example.invalid', HasOptedOutOfEmail=true));
Database.insert(cons, dml);
Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
List<Opportunity> opps = new List<Opportunity>();
for (Integer i=0;i<spec.size();i++) { if (spec[i][4]==null) continue;
  opps.add(new Opportunity(Name='TESTE EPLAST-36 Opp '+(String)spec[i][0], AccountId=accs[i].Id, RecordTypeId=rt, StageName='Fechado/Ganho', CloseDate=Date.today().addDays(-(Integer)spec[i][4]), Branch__c=br.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV', FinancialAnalysis__c=true, TaxAnalysis__c=true)); }
insert opps;
System.debug('FIXTURE_OK accs='+accs.size()+' cons='+cons.size()+' opps='+opps.size());
