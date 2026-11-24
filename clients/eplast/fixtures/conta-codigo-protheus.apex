// Fixture EPLAST-27 (provada na dev em 2026-11-24): preenche ProtheusId__c/Store__c nas contas C1..C6 da fixture conta-oportunidade-proxima-acao.apex.
// Exige: massa daquela fixture ja criada. Usa TriggerUtility.bypassTrigger. Codigos: C1=927001, C2 e C3=927002 (lojas 001 e 002), C4=927004, C6=927006.
// Apagar: junto com a massa (DELETE das contas 'TESTE EPLAST-27%').
TriggerUtility.bypassTrigger = true;
Map<String,String> m = new Map<String,String>{'C1 A1'=>'927001','C2 A2'=>'927002','C3 A3'=>'927002','C4 NONE'=>'927004','C6 NOT'=>'927006'};
List<Account> up=new List<Account>();
for(Account a:[SELECT Id,Name FROM Account WHERE Name LIKE 'TESTE EPLAST-27%']){
 for(String k:m.keySet()) if(a.Name.contains(k)){a.ProtheusId__c=m.get(k); if(k=='C3 A3') a.Store__c='002'; up.add(a);}
}
update up; System.debug('UPD '+up.size());
