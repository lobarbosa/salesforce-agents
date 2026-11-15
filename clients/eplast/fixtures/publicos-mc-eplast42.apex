// Fixture EPLAST-42 (variacao de lead-segmento.apex e conta-oportunidade-ganha.apex). Dado SINTETICO, prefixo 'EPLAST42 TESTE'.
// Modo: troque MODO para 'CRIAR' ou 'LIMPAR'. Rode so em sbx-eplast-dev (ou na QAS, sem tocar registro que o agente nao criou).
// Exige (CRIAR): Account.Owner.ProtheusSellerId__c preenchido no usuario de execucao (so na dev; devolva o valor ao final).
// Telefone, celular e WhatsApp ficam vazios (validation rules). E-mail em dominio example.invalid.
// Cria:
//  Leads: L1 SP opt-out de celular; L2 SP sem opt-out (referencia); L3 SP a converter (Database.convertLead);
//         L4 LeadSource=Evento; L5 sem origem e sem setor ("Sem dados suficientes"); L6 faixa Alta (setor, origem, Status=Contatado).
//  Contas Recorrente: C100 (ganha hoje-100), C400 (hoje-400), C365 (hoje-365, fronteira), cada uma com Contato;
//         C100 tem 2o Contato com HasOptedOutOfEmail=true e 3o com et4ae5__HasOptedOutOfMobile__c=true.
// Criterios: CA-02 a CA-06, PD-03, PD-04. Verifique PriorityBand__c de L6 (esperado Alta) e L5 (Sem dados suficientes) por SOQL agregado.
String MODO = 'CRIAR';
String P = 'EPLAST42 TESTE';
if (MODO == 'LIMPAR') {
  // Convertido gera Conta e Contato: a conta de teste do lead convertido leva o prefixo da empresa.
  delete [SELECT Id FROM Opportunity WHERE Name LIKE 'EPLAST42 TESTE%'];
  delete [SELECT Id FROM Account WHERE Name LIKE 'EPLAST42 TESTE%']; // cascata em Contact/Opp
  delete [SELECT Id FROM Lead WHERE Company LIKE 'EPLAST42 TESTE%']; // nao convertidos
  delete [SELECT Id FROM Branch__c WHERE Name LIKE 'EPLAST42 TESTE%'];
  delete [SELECT Id FROM PaymentTerms__c WHERE Name LIKE 'EPLAST42 TESTE%'];
  System.debug('FIXTURE_LIMPO');
} else {
  TriggerUtility.bypassTrigger = true;
  Database.DMLOptions dml = new Database.DMLOptions(); dml.DuplicateRuleHeader.AllowSave = true;
  List<Lead> ls = new List<Lead>{
    new Lead(LastName=P+' L1', Company=P+' L1', State='SP', Sector__c='Alimentos', Email='e42l1@example.invalid', et4ae5__HasOptedOutOfMobile__c=true),
    new Lead(LastName=P+' L2', Company=P+' L2', State='SP', Sector__c='Alimentos', Email='e42l2@example.invalid'),
    new Lead(LastName=P+' L3', Company=P+' L3', State='SP', Sector__c='Alimentos', Email='e42l3@example.invalid'),
    new Lead(LastName=P+' L4', Company=P+' L4', State='SP', Sector__c='Bebidas', LeadSource='Evento', Email='e42l4@example.invalid'),
    new Lead(LastName=P+' L5', Company=P+' L5', State='MG', Email='e42l5@example.invalid'),
    new Lead(LastName=P+' L6', Company=P+' L6', State='SP', Sector__c='Alimentos', LeadSource='Evento', Status='Contatado', Email='e42l6@example.invalid')};
  Database.insert(ls, dml);
  // Convertido (PD-03): o Contato gerado e de teste.
  Database.LeadConvert lc = new Database.LeadConvert();
  lc.setLeadId(ls[2].Id); lc.setDoNotCreateOpportunity(true);
  lc.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
  Database.convertLead(lc);
  Branch__c br = new Branch__c(Name=P+' Filial', CodeERP__c='T42'); insert br;
  PaymentTerms__c pt = new PaymentTerms__c(Name=P+' Prazo', Codigo__c='T42'); insert pt;
  List<List<Object>> spec = new List<List<Object>>{
    new List<Object>{'C100',100}, new List<Object>{'C400',400}, new List<Object>{'C365',365}};
  List<Account> accs = new List<Account>();
  for (List<Object> s : spec) accs.add(new Account(Name=P+' '+(String)s[0], Type='Recorrente', BillingState='SP', BillingCity='Cidade Teste', BillingStreet='Rua Teste 1', BillingPostalCode='01000000', BillingNeighborhood__c='Bairro Teste', Sector__c='Alimentos', CNAE__c='0000000', CompanyName__c=P+' Ltda', Email__c='e42@example.invalid', Store__c='01'));
  insert accs;
  List<Contact> cons = new List<Contact>();
  for (Account a : accs) cons.add(new Contact(AccountId=a.Id, LastName=a.Name, Email='e42@example.invalid'));
  cons.add(new Contact(AccountId=accs[0].Id, LastName=P+' C100 optout email', Email='e42oe@example.invalid', HasOptedOutOfEmail=true));
  cons.add(new Contact(AccountId=accs[0].Id, LastName=P+' C100 optout celular', Email='e42om@example.invalid', et4ae5__HasOptedOutOfMobile__c=true));
  insert cons;
  Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
  List<Opportunity> opps = new List<Opportunity>();
  for (Integer i=0;i<spec.size();i++)
    opps.add(new Opportunity(Name=P+' Opp '+(String)spec[i][0], AccountId=accs[i].Id, RecordTypeId=rt, StageName='Fechado/Ganho', CloseDate=Date.today().addDays(-(Integer)spec[i][1]), Branch__c=br.Id, PaymentTermId__c=pt.Id, Formas_de_Pagamento__c='AV', FinancialAnalysis__c=true, TaxAnalysis__c=true));
  insert opps;
  System.debug('FIXTURE_OK leads='+ls.size()+' accs='+accs.size()+' cons='+cons.size()+' opps='+opps.size());
}
