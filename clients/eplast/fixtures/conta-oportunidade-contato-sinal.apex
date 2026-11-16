// Fixture EPLAST-46 (sbx-eplast-dev). Cria dado SINTETICO de teste:
//  6 contas 'TESTE EPLAST-46 <A..F>' (Industry igual), oportunidades Fechado/Ganho com CloseDate controlada
//  (alimentam Account.LastPurchase__c), contatos com/sem opt-out e CommercialSignal__c Cruzada (inseridos direto).
// Exige: usuario de execucao com User.ProtheusSellerId__c preenchido (validation rule de Opportunity;
//  preencha antes, guarde o valor anterior e devolva depois); usa TriggerUtility.bypassTrigger = true
//  (evita a consulta externa da AccountTrigger). Produtos Product2 existentes com Group__c PREF.
// Rodar: sf apex run -o sbx-eplast-dev -f fixtures/conta-oportunidade-contato-sinal.apex
// Cria tambem Branch__c 'TESTE EPLAST-46 filial' (Opportunity exige Filial com CodeERP__c).
// Cria tambem PaymentTerms__c 'TESTE EPLAST-46 condicao' (Opportunity Fechado/Ganho exige condicao e forma de pagamento).
// Apagar, nesta ordem (Apex anonimo, com TriggerUtility.bypassTrigger = true): DELETE Case das contas de teste (a org cria um Case por conta
//  ao inserir; sai junto) e DELETE Opportunity 'TESTE EPLAST-46%' (oportunidade ganha impede apagar a conta); depois DELETE Account
//  WHERE Name LIKE 'TESTE EPLAST-46%' (apaga contatos e sinais em cascata)
//  DELETE Branch__c / PaymentTerms__c WHERE Name LIKE 'TESTE EPLAST-46%'; e CommercialSignal__c de contas de teste, se o master-detail nao cascatear.
TriggerUtility.bypassTrigger = true;
Branch__c br = new Branch__c(Name='TESTE EPLAST-46 filial', CodeERP__c='T46');
insert br;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-46 condicao', Codigo__c='T46');
insert pt;
String ind = Account.Industry.getDescribe().getPicklistValues()[0].getValue();
Id ownerId = UserInfo.getUserId();
Id rt = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
List<Product2> prods = [SELECT Id FROM Product2 WHERE Group__c = 'PREF' AND IsActive = true LIMIT 1];
Map<String,Integer> dias = new Map<String,Integer>{'A'=>100,'B'=>30,'D'=>30,'E'=>200,'F'=>200};
List<Account> accs = new List<Account>();
Integer i = 0;
for (String k : new List<String>{'A','B','C','D','E','F'}) {
  i++;
  accs.add(new Account(Name='TESTE EPLAST-46 '+k, Industry=ind, OwnerId=ownerId,
    BillingCountry='Brasil', BillingCity='Teste', BillingState='SP', BillingStreet='Rua Teste',
    BillingPostalCode='00000000', BillingNeighborhood__c='Teste',
    CompanyName__c='TESTE EPLAST-46 razao', CNAE__c='123456', Email__c='teste46@example.invalid', Phone='(99)12341244', Store__c='01'));
}
insert accs;
Map<String,Id> id = new Map<String,Id>();
for (Account a : accs) id.put(a.Name.right(1), a.Id);
List<Opportunity> opps = new List<Opportunity>();
for (String k : dias.keySet()) {
  opps.add(new Opportunity(Name='TESTE EPLAST-46 opp '+k, StageName='Fechado/Ganho',
    CloseDate=Date.today().addDays(-dias.get(k)), AccountId=id.get(k), RecordTypeId=rt, OwnerId=ownerId, Branch__c=br.Id,
    Formas_de_Pagamento__c='AV', PaymentTermId__c=pt.Id));
}
insert opps;
List<Contact> cs = new List<Contact>{
  new Contact(LastName='TESTE EPLAST-46 c1', AccountId=id.get('A'), Email='teste46c1@example.invalid', MobilePhone='(11)900000001', HasOptedOutOfEmail=true),
  new Contact(LastName='TESTE EPLAST-46 c2', AccountId=id.get('A'), Email='teste46c2@example.invalid', MobilePhone='(11)900000002', et4ae5__HasOptedOutOfMobile__c=true),
  new Contact(LastName='TESTE EPLAST-46 c3', AccountId=id.get('A'), Email='teste46c3@example.invalid', MobilePhone='(11)900000003'),
  new Contact(LastName='TESTE EPLAST-46 c4', AccountId=id.get('F'), Email='teste46c4@example.invalid', MobilePhone='(11)900000004', HasOptedOutOfEmail=true)
};
insert cs;
List<CommercialSignal__c> sg = new List<CommercialSignal__c>();
for (String k : new List<String>{'D','E'}) {
  sg.add(new CommercialSignal__c(Account__c=id.get(k), Product__c=prods[0].Id, Type__c='Cruzada', CalculationDate__c=Date.today()));
}
insert sg;
System.debug('FIXTURE_OK ' + id);
