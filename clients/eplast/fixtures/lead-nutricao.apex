// Fixture EPLAST-45: 7 leads sinteticos de nutricao (L1 a L7). Org: sbx-eplast-dev (dev).
// Cria: Lead 'TESTE EPLAST-45 L1'..'L7', Company 'TESTE EPLAST-45', e-mail @example.com,
//   celular (11)999990001 (formato exigido pela validation rule Celular). L5 e convertido.
// Exige: nada alem dos campos Lead.MKT_* da EPLAST-45; Sector__c e LeadSource validos (Alimentos, Evento).
//   Faixa de prioridade e formula: Contatado+setor+origem = Alta; Aberto+setor+origem = Media; sem setor/origem = Sem dados.
// Rodar: sf apex run -o sbx-eplast-dev -f clients/eplast/fixtures/lead-nutricao.apex
// Apagar: DELETE [SELECT Id FROM Lead WHERE LastName LIKE 'TESTE EPLAST-45%']; (convertido: apagar tambem Account/Contact 'TESTE EPLAST-45%')
List<Lead> ls = new List<Lead>();
String[][] c = new String[][]{
 new String[]{'L1','Aberto - Não contatado','1','0','0'},
 new String[]{'L2','Contatado','1','0','0'},
 new String[]{'L3','Contatado','1','1','0'},
 new String[]{'L4','Contatado','1','0','1'},
 new String[]{'L5','Contatado','1','0','0'},
 new String[]{'L6','Contatado','0','0','0'},
 new String[]{'L7','Fechado - Não convertido','1','0','0'}};
for(String[] x: c){
 Lead l = new Lead(LastName='TESTE EPLAST-45 '+x[0], Company='TESTE EPLAST-45', Status=x[1],
   Email='teste.eplast45.'+x[0].toLowerCase()+'@example.com', MobilePhone='(11)999990001');
 if(x[2]=='1'){ l.Sector__c='Alimentos'; l.LeadSource='Evento'; }
 else { l.Email=null; l.MobilePhone=null; }
 l.HasOptedOutOfEmail = x[3]=='1';
 l.et4ae5__HasOptedOutOfMobile__c = x[4]=='1';
 ls.add(l);
}
insert ls;
System.debug('FIXTURE criados '+ls.size());
