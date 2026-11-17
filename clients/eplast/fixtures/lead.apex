// Fixture: Leads sinteticos para verificacao (EPLAST-29). Sem telefone (validation rules Celular/Telefone so checam formato).
// Cria: 'REG-TESTE-LEAD-01' (unico), 2 leads 'REG-TESTE-DUP' (ambiguidade entre leads; tambem usado com conta de mesmo nome),
//       'REG-TESTE-LEAD-CONV' (sera convertido na etapa seguinte do script, para o cenario de lead convertido).
// Conta 'REG-TESTE-DUP' e criada com TriggerUtility.bypassTrigger=true para nao acionar o AccountTrigger (Protheus).
// Rodar: sf apex run -o sbx-eplast-dev -f fixtures/lead.apex
// Apagar: DELETE [SELECT Id FROM Task WHERE Who.Name LIKE 'REG-TESTE%' OR What.Name LIKE 'REG-TESTE%'];
//         DELETE [SELECT Id FROM Lead WHERE LastName LIKE 'REG-TESTE%'];  DELETE [SELECT Id FROM Account WHERE Name LIKE 'REG-TESTE%'];
TriggerUtility.bypassTrigger = true;
List<Lead> leads = new List<Lead>{
  new Lead(FirstName='Teste', LastName='REG-TESTE-LEAD-01', Company='REG-TESTE Empresa 01'),
  new Lead(FirstName='Teste', LastName='REG-TESTE-DUP', Company='REG-TESTE Empresa Dup'),
  new Lead(FirstName='Teste', LastName='REG-TESTE-DUP', Company='REG-TESTE Empresa Dup'),
  new Lead(FirstName='Teste', LastName='REG-TESTE-LEAD-CONV', Company='REG-TESTE Empresa Conv')
};
insert leads;
insert new Account(Name='REG-TESTE-DUP');
// Conversao do lead sintetico (sem criar oportunidade). Se a org exigir outro status, ajustar o status abaixo.
LeadStatus conv = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(leads[3].Id);
lc.setConvertedStatus(conv.MasterLabel);
lc.setDoNotCreateOpportunity(true);
Database.LeadConvertResult r = Database.convertLead(lc);
System.debug('CONVERSAO ' + r.isSuccess());
for (Lead l : leads) System.debug('CRIADO ' + l.Id + ' ' + l.LastName);
