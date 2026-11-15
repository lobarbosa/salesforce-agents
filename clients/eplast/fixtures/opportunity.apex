// Cria Account sintetica + Opportunity RT Industria na dev, sem disparar triggers (TriggerUtility.bypassTrigger; Flows ainda rodam).
// Exige ANTES: User executor com ProtheusSellerId__c preenchido (validation CheckAccountOwnerHasProtheusSellerId):
//   sf data update record --target-org sbx-eplast-dev --sobject User --record-id <005 do executor> --values "ProtheusSellerId__c='TESTE26'"
//   e devolver o valor anterior (vazio) ao final. RT Industria evita a validation PriceBook; evite Fechado/Ganho (exige filial, pagamento).
// Apagar: delete Opportunity 'TESTE EPLAST-26%' e Account 'TESTE EPLAST-26%'.
TriggerUtility.bypassTrigger = true;
Account a = new Account(Name='TESTE EPLAST-26 Conta', CompanyName__c='TESTE EPLAST-26', Phone='(11)30000000',
  BillingStreet='Rua Teste 1', BillingCity='Sao Paulo', BillingState='SP', BillingPostalCode='01000-000', BillingCountry='Brasil',
  BillingNeighborhood__c='Centro', Email__c='teste26@example.invalid', Store__c='01', CNAE__c='0000-0/00');
insert a;
Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
insert new Opportunity(Name='TESTE EPLAST-26 O1', AccountId=a.Id, RecordTypeId=rt, StageName='Qualificação', Probability=90, Amount=1000, CloseDate=Date.today().addDays(30), LeadSource='Campanha');
