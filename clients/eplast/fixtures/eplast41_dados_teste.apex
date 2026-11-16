// EPLAST-41 - dados sinteticos de teste. Rodar SOMENTE nas sandboxes da esteira (sbx-eplast-dev / sbx-eplast-qa):
//   sf apex run --file fixtures/eplast41_dados_teste.apex --target-org sbx-eplast-dev
// Idempotente: cria o que falta e nunca duplica. Conta A (1 oportunidade aberta + 1 ganha) e Conta B (sem oportunidade).
// Todo nome comeca por "TESTE EPLAST-41". So toca registro "TESTE EPLAST-41" criado aqui (na QA/Partial Copy, nunca outro).
// Sem contato nem CPF; e-mail e telefone sao ficticios (exigidos pelas validation rules de Opportunity/Account).
// PRE-REQUISITO das oportunidades: a regra CheckAccountOwnerHasProtheusSellerId exige ProtheusSellerId__c no
// proprietario da conta (usuario de execucao). Sem isso as oportunidades falham e o script so avisa (FIXTURE AVISO).
// Ver fixtures/README.md.
String P = 'TESTE EPLAST-41';
Map<String, Account> contas = new Map<String, Account>();
for (Account x : [SELECT Id, Name FROM Account WHERE Name LIKE :(P + '%')]) { contas.put(x.Name, x); }
String nA = P + ' Conta A'; String nB = P + ' Conta B sem oportunidade';
if (!contas.containsKey(nA)) { contas.put(nA, new Account(Name = nA, CompanyDocument__c = '11222333000181')); }
if (!contas.containsKey(nB)) { contas.put(nB, new Account(Name = nB, CompanyDocument__c = '11444777000161')); }
for (Account a : contas.values()) {
    a.Industry = 'Manufacturing'; a.Type = 'Customer';
    a.BillingStreet = 'Rua Teste 1'; a.BillingCity = (a.Name == nA ? 'Sao Paulo' : 'Campinas'); a.BillingState = 'SP';
    a.BillingPostalCode = '01000-000'; a.BillingNeighborhood__c = 'Centro'; a.BillingCountry = 'Brazil';
    a.CNAE__c = '0000-0/00'; a.CompanyName__c = a.Name; a.Email__c = 'teste.eplast41@example.invalid';
    a.Phone = '(11)99999999'; a.Store__c = '01';
}
// Na QA (Partial Copy) a regra de duplicidade de Account pode barrar a conta sintetica contra dado real copiado;
// por isso grava com allowSave (so as contas TESTE EPLAST-41 deste script).
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
List<Account> novasContas = new List<Account>(); List<Account> velhasContas = new List<Account>();
for (Account x : contas.values()) { if (x.Id == null) { novasContas.add(x); } else { velhasContas.add(x); } }
for (Database.SaveResult r : Database.insert(novasContas, dml)) {
    if (!r.isSuccess()) { System.debug('FIXTURE ERRO conta: ' + r.getErrors()); }
}
for (Database.SaveResult r : Database.update(velhasContas, dml)) {
    if (!r.isSuccess()) { System.debug('FIXTURE ERRO conta: ' + r.getErrors()); }
}
Account a = contas.get(nA);
if (a.Id == null) { return; }
String aberta = null; String ganha = null;
for (OpportunityStage s : [SELECT MasterLabel, IsWon, IsClosed FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder]) {
    if (!s.IsClosed && aberta == null) { aberta = s.MasterLabel; }
    if (s.IsWon && ganha == null) { ganha = s.MasterLabel; }
}
Id rt = null;
for (RecordType r : [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Industria' LIMIT 1]) { rt = r.Id; }
List<Opportunity> novas = new List<Opportunity>();
Set<String> ja = new Set<String>();
for (Opportunity o : [SELECT Name FROM Opportunity WHERE Name LIKE :(P + '%')]) { ja.add(o.Name); }
if (!ja.contains(P + ' Opp aberta')) { novas.add(new Opportunity(Name = P + ' Opp aberta', AccountId = a.Id, StageName = aberta, CloseDate = Date.today().addDays(30), RecordTypeId = rt)); }
if (!ja.contains(P + ' Opp ganha')) { novas.add(new Opportunity(Name = P + ' Opp ganha', AccountId = a.Id, StageName = ganha, CloseDate = Date.today().addDays(-30), RecordTypeId = rt)); }
for (Integer i = 0; i < novas.size(); i++) {
    Database.SaveResult r = Database.insert(novas[i], false);
    System.debug('FIXTURE opp ' + novas[i].Name + ': ' + r.isSuccess());
    for (Database.Error e : r.getErrors()) { System.debug('FIXTURE AVISO ' + novas[i].Name + ': ' + e.getMessage() + ' ' + e.getFields()); }
}
