// Cria 4 Leads sinteticos "TESTE ..." (Company='TESTE <ID>') na dev. Exige: nada alem de Status/Sector__c/LeadSource validos;
// validation rules de Lead (Celular, Telefone) so reprovam telefone mal formatado, entao deixe Phone/MobilePhone vazios.
// Apagar: delete [SELECT Id FROM Lead WHERE Company = 'TESTE EPLAST-26'];
// Rodar: sf apex run --target-org sbx-eplast-dev -f fixtures/lead.apex
List<Lead> ls = new List<Lead>{
 new Lead(LastName='TESTE EPLAST-26 L1', Company='TESTE EPLAST-26', Status='Contatado', Sector__c='Alimentos', LeadSource='Campanha'),
 new Lead(LastName='TESTE EPLAST-26 L2', Company='TESTE EPLAST-26', Status='Aberto - Não contatado', Sector__c='Alimentos')
};
insert ls;
