/**
 * EPLAST-33. Fabrica de dados de teste dos sinais comerciais.
 * Todos os campos que as validation rules ativas de Order apontam sao preenchidos (Protheus, filial,
 * transportadora, tipo de operacao, datas, volume, especie, frete).
 */
@IsTest
public class CommercialSignalTestFactory {

    public class OrderSpec {
        public Id accountId;
        public String status;
        public Date effectiveDate;
        public Decimal amount;
        public Id productId;
        public OrderSpec(Id accountId, String status, Date effectiveDate, Decimal amount, Id productId) {
            this.accountId = accountId;
            this.status = status;
            this.effectiveDate = effectiveDate;
            this.amount = amount;
            this.productId = productId;
        }
    }

    private static Id typeOperationId;
    private static Id shippingCompanyId;
    private static Id branchId;
    private static Map<Id, Id> entryByProduct = new Map<Id, Id>();

    public static List<Account> createAccounts(Integer count, String industry, String prefix) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = prefix + ' ' + i,
                Industry = industry,
                ProtheusId__c = prefix + '-' + i
            ));
        }
        // AccountTrigger valida CNPJ e enfileira consulta a BrasilAPI por conta (limite de 50 jobs);
        // a fixture usa o bypass oficial da org (TriggerUtility) so durante o insert e o restaura.
        Boolean previous = TriggerUtility.bypassTrigger;
        TriggerUtility.bypassTrigger = true;
        insert accounts;
        TriggerUtility.bypassTrigger = previous;
        return accounts;
    }

    public static List<Product2> createProducts(Integer count) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < count; i++) {
            products.add(new Product2(Name = 'Produto CS ' + i, IsActive = true));
        }
        insert products;
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 p : products) {
            entries.add(new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 1, IsActive = true
            ));
        }
        insert entries;
        for (PricebookEntry e : entries) {
            entryByProduct.put(e.Product2Id, e.Id);
        }
        return products;
    }

    private static void ensureLookups() {
        if (typeOperationId != null) {
            return;
        }
        TypeOperation__c t = new TypeOperation__c(Code__c = 'CS1');
        insert t;
        typeOperationId = t.Id;
        ShippingCompany__c s = new ShippingCompany__c(Code__c = 'CS1');
        insert s;
        shippingCompanyId = s.Id;
        Branch__c b = new Branch__c();
        insert b;
        branchId = b.Id;
    }

    private static String firstActive(Schema.SObjectField field) {
        for (Schema.PicklistEntry e : field.getDescribe().getPicklistValues()) {
            if (e.isActive()) {
                return e.getValue();
            }
        }
        return null;
    }

    private static User integrationUser;

    /**
     * Usuario "integracao*" com perfil administrador. OrderTrigger nao envia ao Protheus quando o username
     * comeca com 'integracao' (e e o que a integracao real faz), e CheckUserCanSetStatus so libera a
     * mudanca de status para administrador. Sem isso o envio enfileirado falha no teste (sem Opportunity,
     * sem mock de callout).
     */
    private static User integrationUser() {
        if (integrationUser == null) {
            Profile p = [
                SELECT Id FROM Profile WHERE Name IN ('Administrador do sistema', 'System Administrator') LIMIT 1
            ];
            String uname = 'integracao.cs33.' + Datetime.now().getTime() + '@example.com.invalid';
            integrationUser = new User(
                Alias = 'intcs33', Email = uname, Username = uname, LastName = 'Integracao CS33', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Sao_Paulo', LocaleSidKey = 'pt_BR', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'pt_BR'
            );
            insert integrationUser;
        }
        return integrationUser;
    }

    /**
     * Cria pedidos com um item cada (valor total = amount) e leva ao status final. O pedido nasce como
     * rascunho ('Revisao de Pedido'), recebe o item e so entao muda de status, como no processo real.
     */
    public static List<Order> createOrders(List<OrderSpec> specs) {
        ensureLookups();
        User iu = integrationUser();
        List<Order> orders = new List<Order>();
        System.runAs(iu) {
            for (OrderSpec sp : specs) {
                orders.add(new Order(
                    AccountId = sp.accountId,
                    Status = 'Revisao de Pedido',
                    EffectiveDate = sp.effectiveDate,
                    Pricebook2Id = Test.getStandardPricebookId(),
                    DeliveryDate__c = sp.effectiveDate,
                    ExpectedSaleDate__c = sp.effectiveDate,
                    DispatchBranch__c = branchId,
                    TypeOperation__c = typeOperationId,
                    ShippingCompany__c = shippingCompanyId,
                    Species1__c = 'Caixa',
                    Volume1__c = '1',
                    TypeShipping__c = firstActive(Order.TypeShipping__c)
                ));
            }
            insert orders;
            List<OrderItem> items = new List<OrderItem>();
            for (Integer i = 0; i < specs.size(); i++) {
                items.add(new OrderItem(
                    OrderId = orders[i].Id,
                    PricebookEntryId = entryByProduct.get(specs[i].productId),
                    Quantity = 1,
                    UnitPrice = specs[i].amount
                ));
            }
            insert items;
            List<Order> toUpdate = new List<Order>();
            for (Integer i = 0; i < specs.size(); i++) {
                if (specs[i].status != 'Revisao de Pedido') {
                    orders[i].Status = specs[i].status;
                    if (specs[i].status == 'Cancelado') {
                        orders[i].ReasonCancellation__c = firstActive(Order.ReasonCancellation__c);
                    }
                    toUpdate.add(orders[i]);
                }
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
        return orders;
    }

    public static CommercialSignalService.Settings settings() {
        return new CommercialSignalService.Settings();
    }

    public static List<CommercialSignal__c> signals(Id accountId, String type) {
        return [
            SELECT Id, Type__c, Product__c, DaysWithoutPurchase__c, VariationPercent__c, BasePeriodAmount__c,
                   CurrentPeriodAmount__c, LastPurchaseDate__c, Reason__c, CalculationDate__c, SignalKey__c
            FROM CommercialSignal__c
            WHERE Account__c = :accountId AND Type__c = :type
        ];
    }
}
