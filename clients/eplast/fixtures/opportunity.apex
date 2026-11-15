// Fixture EPLAST-40 (provada na sbx-eplast-dev em 2026-11-15).
// Cria: Conta completa TESTE, catalogo Pricebook2 da conta, Oportunidades Industria em Qualificacao (3 variacoes de checkbox);
//       depois o bloco 2 cria Filial e Condicao de Pagamento TESTE e fecha (Fechado/Ganho) 2 Oportunidades (Industria e Sale).
// Exige: usuario de execucao com User.ProtheusSellerId__c preenchido (ajuste na dev e devolva ao final);
//        TriggerUtility.bypassTrigger=true evita consulta externa. Rode com: sf apex run -o sbx-eplast-dev -f <arquivo>
// Apagar: Case (Oportunidade__r.Name LIKE 'TESTE EPLAST-40%'), Opportunity, Lead, Pricebook2, Branch__c, PaymentTerms__c, Account com nome 'TESTE EPLAST-40%'.
// Limite: conversao de Lead nao passa no RT padrao Sale (regra PriceBook exige catalogo da Conta na criacao).
// ---- bloco 1 ----
// EPLAST-40 verificacao: setup + qualificacao
User u = [SELECT Id, ProtheusSellerId__c FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('ANTES_SELLER=' + u.ProtheusSellerId__c);
u.ProtheusSellerId__c = 'TESTE40';
update u;
TriggerUtility.bypassTrigger = true;
Account a = new Account(Name='TESTE EPLAST-40 Conta', ProtheusId__c='990040', CompanyDocument__c='34921036000120', CompanyName__c='TESTE EPLAST-40',
 BillingCountry='Test Country', BillingCity='TESTE', BillingState='Test State', BillingStreet='TESTE', BillingPostalCode='00000000', BillingNeighborhood__c='TESTE',
 CNAE__c='123456', Email__c='teste40@example.invalid', Phone='(99) 12341244', OwnerId=u.Id);
insert a;
a.Store__c='01'; update a;
Pricebook2 pb = new Pricebook2(Name='TESTE EPLAST-40 Catalogo', IsActive=true, Account__c=a.Id);
insert pb;
Id rt = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
List<Opportunity> os = new List<Opportunity>();
os.add(new Opportunity(Name='TESTE EPLAST-40 O1 ambos', StageName='Qualificação', CloseDate=Date.today(), AccountId=a.Id, RecordTypeId=rt, OwnerId=u.Id, Discovery_Completed__c=true, Budget_Confirmed__c=true));
os.add(new Opportunity(Name='TESTE EPLAST-40 O2 um', StageName='Qualificação', CloseDate=Date.today(), AccountId=a.Id, RecordTypeId=rt, OwnerId=u.Id, Discovery_Completed__c=true));
os.add(new Opportunity(Name='TESTE EPLAST-40 O3 nenhum', StageName='Qualificação', CloseDate=Date.today(), AccountId=a.Id, RecordTypeId=rt, OwnerId=u.Id));
insert os;
for (Opportunity o : [SELECT Name, StageName FROM Opportunity WHERE Name LIKE 'TESTE EPLAST-40%' ORDER BY Name]) System.debug('INS ' + o.Name + ' -> ' + o.StageName);
// ---- bloco 2 (rodar em outra execucao) ----
TriggerUtility.bypassTrigger = true;
Account a = [SELECT Id FROM Account WHERE Name='TESTE EPLAST-40 Conta'];
Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name='TESTE EPLAST-40 Catalogo'];
Branch__c b = new Branch__c(Name='TESTE EPLAST-40 Filial', CodeERP__c='T40'); insert b;
PaymentTerms__c pt = new PaymentTerms__c(Name='TESTE EPLAST-40 Cond', Codigo__c='T40'); insert pt;
String fp = Opportunity.Formas_de_Pagamento__c.getDescribe().getPicklistValues()[0].getValue();
List<Opportunity> os = new List<Opportunity>();
for (String rtn : new List<String>{'Industria','Sale'}) {
  Id rt = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(rtn).getRecordTypeId();
  os.add(new Opportunity(Name='TESTE EPLAST-40 FECH ' + rtn, StageName='Qualificado', CloseDate=Date.today(), AccountId=a.Id, RecordTypeId=rt, OwnerId=UserInfo.getUserId(), Pricebook2Id=pb.Id,
   PaymentTermId__c=pt.Id, Formas_de_Pagamento__c=fp, Branch__c=b.Id, TaxAnalysis__c=true, FinancialAnalysis__c=true));
}
insert os;
os = [SELECT Id, Name FROM Opportunity WHERE Name LIKE 'TESTE EPLAST-40 FECH%'];
for (Opportunity o : os) o.StageName = 'Fechado/Ganho';
update os;
System.debug('FECHADAS ' + os.size());
