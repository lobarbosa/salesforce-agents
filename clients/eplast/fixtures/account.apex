// Fixture: Account sintetica para verificacao (EPLAST-29).
// Cria: 1 Account 'TESTE EPLAST-29 Conta Unica' e 2 Accounts 'TESTE EPLAST-29 Conta Dup' (ambiguidade).
// Exige: nenhuma validation rule dispara sem campos de telefone; usa TriggerUtility.bypassTrigger=true
//        para nao chamar o Protheus (callout do AccountTrigger).
// Rodar: sf apex run -o sbx-eplast-dev -f fixtures/account.apex
// Apagar: DELETE [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-29%'];  (apagar Tasks WhatId antes)
TriggerUtility.bypassTrigger = true;
List<Account> l = new List<Account>{
  new Account(Name='TESTE EPLAST-29 Conta Unica'),
  new Account(Name='TESTE EPLAST-29 Conta Dup'),
  new Account(Name='TESTE EPLAST-29 Conta Dup')
};
insert l;
for (Account a : l) System.debug('CRIADA ' + a.Id + ' ' + a.Name);
