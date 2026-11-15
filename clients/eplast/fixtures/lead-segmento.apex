// Fixture EPLAST-36: 3 Leads SINTETICOS na dev. Nao exige campo extra; validation rules de Lead sao so de formato de telefone (nao preenchidos).
//  L1 SP/Alimentos; L2 SP/Alimentos com HasOptedOutOfEmail=true; L3 MG/Bebidas.
// Apagar: DELETE [SELECT Id FROM Lead WHERE Company LIKE 'TESTE EPLAST-36%'];
TriggerUtility.bypassTrigger = true;
Database.DMLOptions dml = new Database.DMLOptions(); dml.DuplicateRuleHeader.AllowSave = true; // regra de duplicidade da org barra leads de teste parecidos
List<Lead> ls = new List<Lead>{
 new Lead(LastName='TESTE EPLAST-36 L1', Company='TESTE EPLAST-36 L1', State='SP', Sector__c='Alimentos', Email='teste36l1@example.invalid'),
 new Lead(LastName='TESTE EPLAST-36 L2', Company='TESTE EPLAST-36 L2', State='SP', Sector__c='Alimentos', Email='teste36optout@example.invalid', HasOptedOutOfEmail=true),
 new Lead(LastName='TESTE EPLAST-36 L3', Company='TESTE EPLAST-36 L3', State='MG', Sector__c='Bebidas', Email='teste36l3@example.invalid')};
Database.insert(ls, dml);
