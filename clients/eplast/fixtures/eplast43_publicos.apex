// EPLAST-43 - massa fictícia para os públicos de marketing. Só dev/QA. Números e e-mails fictícios.
Id owner = [SELECT Id FROM User WHERE Username LIKE 'projetos@konectabr.com%' AND IsActive = true LIMIT 1].Id;
List<Account> accs = new List<Account>();
for (Integer i = 1; i <= 2; i++) {
    accs.add(new Account(Name = 'EPLAST43-TESTE Conta ' + i, Sector__c = 'Alimentos', Type = 'Recorrente', BillingState = 'SP', OwnerId = owner));
}
insert accs;
List<Contact> cs = new List<Contact>();
for (Integer i = 1; i <= 4; i++) {
    Contact c = new Contact(FirstName = 'EPLAST43-TESTE', LastName = 'Contato ' + i, AccountId = accs[Math.mod(i, 2)].Id,
        Email = 'eplast43.c' + i + '@example.com', OwnerId = owner);
    if (i <= 3) c.MobilePhone = '(11) 91234-000' + i;
    if (i == 2) c.HasOptedOutOfEmail = true;
    if (i == 3) c.et4ae5__HasOptedOutOfMobile__c = true;
    cs.add(c);
}
insert cs;
List<Lead> ls = new List<Lead>();
for (Integer i = 1; i <= 6; i++) {
    Lead l = new Lead(FirstName = 'EPLAST43-TESTE', LastName = 'Lead ' + i, Company = 'EPLAST43-TESTE Empresa ' + i,
        Email = 'eplast43.l' + i + '@example.com', State = 'SP', OwnerId = owner);
    if (i <= 5) { l.MobilePhone = '(11)91234500' + i; l.Sector__c = 'Alimentos'; l.LeadSource = 'Web'; }
    if (i == 2) l.HasOptedOutOfEmail = true;
    if (i == 3) l.et4ae5__HasOptedOutOfMobile__c = true;
    if (i == 4) l.Status = 'Fechado - Não convertido';
    ls.add(l);
}
insert ls;
// Lead 5: convertido, sem Opportunity, para uma das contas de teste.
Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(ls[4].Id);
lc.setAccountId(accs[0].Id);
lc.setDoNotCreateOpportunity(true);
lc.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
Database.convertLead(lc);
// Limpeza (descomente): delete [SELECT Id FROM Lead WHERE Company LIKE 'EPLAST43-TESTE%'];
// delete [SELECT Id FROM Contact WHERE FirstName = 'EPLAST43-TESTE']; delete [SELECT Id FROM Account WHERE Name LIKE 'EPLAST43-TESTE%'];
