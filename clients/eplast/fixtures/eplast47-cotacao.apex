// EPLAST-47 (verificacao): cria cotacao padrao (Quote Approved) + SBQQ__Quote__c primaria para cada oportunidade "TESTE EPLAST-47 Opp %" que ainda nao e Fechado/Ganho.
// Exige: oportunidades da fixture eplast47-base.apex; sem isso o OpportunityFlow nao calcula AveragePurchasesThisYear__c (GetPrimeQuote vazio) e o Flow novo nao classifica.
// Rodar ANTES de salvar a oportunidade em Fechado/Ganho. Apagar: DELETE de SBQQ__Quote__c e Quote com Name LIKE TESTE EPLAST-47%, depois Case, Task, Order, Opportunity, Account, Branch__c, PaymentTerms__c.
List<Opportunity> os = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name LIKE 'TESTE EPLAST-47 Opp %' AND StageName <> 'Fechado/Ganho' ORDER BY Name];
List<Quote> qs = new List<Quote>();
for (Opportunity o: os) qs.add(new Quote(Name='TESTE EPLAST-47 Cot '+o.Name.substringAfterLast(' '), OpportunityId=o.Id, Status='Approved'));
insert qs;
List<SBQQ__Quote__c> cq = new List<SBQQ__Quote__c>();
for (Integer i=0;i<os.size();i++) cq.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c=os[i].Id, SBQQ__Primary__c=true, Quote__c=qs[i].Id));
insert cq;
Integer n=0; for (Opportunity o: [SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name LIKE 'TESTE EPLAST-47 Opp %']) if (o.SBQQ__PrimaryQuote__c!=null) n++;
System.debug('QUOTE ok '+qs.size()+' primary set on '+n);
