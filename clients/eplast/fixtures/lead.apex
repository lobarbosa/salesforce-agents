// EPLAST-39 fixture: Lead sinteticos para relatorios de origem/conversao.
// Cria: 8 leads 'TESTE EPLAST-39 ...' (2 Campanha, 1 WhatsApp, 1 Google Ads, 1 sem origem,
// 1 'Origem Inventada XYZ' fora da lista, 2 Campanha/WhatsApp convertidos via convertLead sem oportunidade).
// Exige: sandbox de dev; Lead so valida formato de Telefone/Celular (nao preenchidos); sem trigger em Lead.
// Usa TriggerUtility.bypassTrigger para a conta gerada na conversao nao disparar consulta externa.
// Apagar: DELETE [SELECT Id FROM Lead WHERE Company LIKE 'TESTE EPLAST-39%'];
//         DELETE [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-39%'];
TriggerUtility.bypassTrigger = true;
List<Lead> ls = new List<Lead>();
String[] srcs = new String[]{'Campanha','Campanha','WhatsApp','Google Ads',null,'Origem Inventada XYZ','Campanha','WhatsApp'};
for (Integer i=0;i<srcs.size();i++) {
  ls.add(new Lead(LastName='TESTE EPLAST-39 Lead '+i, Company='TESTE EPLAST-39 Empresa '+i, LeadSource=srcs[i]));
}
insert ls;
LeadStatus cs = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
for (Integer i : new Integer[]{6,7}) {
  Database.LeadConvert lc = new Database.LeadConvert();
  lc.setLeadId(ls[i].Id); lc.setConvertedStatus(cs.MasterLabel); lc.setDoNotCreateOpportunity(true);
  lcs.add(lc);
}
for (Database.LeadConvertResult r : Database.convertLead(lcs)) System.debug('conv=' + r.isSuccess() + ' ' + r.getErrors());
