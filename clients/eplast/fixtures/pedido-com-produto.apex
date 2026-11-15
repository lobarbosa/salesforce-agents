// Fixture EPLAST-36: 1 Product2, 1 PricebookEntry (pricebook padrao), 1 Order com 1 OrderItem para a Conta 'TESTE EPLAST-36 A1'.
// Exige: Conta TESTE EPLAST-36 A1 (fixtures/conta-oportunidade-ganha.apex). Bypass de trigger para nao chamar Protheus.
// Apagar: DELETE [SELECT Id FROM Order WHERE Account.Name LIKE 'TESTE EPLAST-36%'] ; DELETE [SELECT Id FROM PricebookEntry WHERE Product2.Name LIKE 'TESTE EPLAST-36%']; DELETE [SELECT Id FROM Product2 WHERE Name LIKE 'TESTE EPLAST-36%'];
TriggerUtility.bypassTrigger = true;
Account a = [SELECT Id FROM Account WHERE Name='TESTE EPLAST-36 A1' LIMIT 1];
Product2 p = new Product2(Name='TESTE EPLAST-36 Produto', IsActive=true); insert p;
Id pb = [SELECT Id FROM Pricebook2 WHERE IsStandard=true LIMIT 1].Id;
PricebookEntry pe = new PricebookEntry(Pricebook2Id=pb, Product2Id=p.Id, UnitPrice=1, IsActive=true); insert pe;
Schema.Order o = new Schema.Order(AccountId=a.Id, Status='Revisao de Pedido', EffectiveDate=Date.today(), Pricebook2Id=pb); insert o;
insert new OrderItem(OrderId=o.Id, Product2Id=p.Id, PricebookEntryId=pe.Id, Quantity=1, UnitPrice=1);
System.debug('PEDIDO_OK');
