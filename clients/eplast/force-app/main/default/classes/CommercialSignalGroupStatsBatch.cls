/**
 * EPLAST-33, fase 1. Para as contas com grupo preenchido, mede o tamanho de cada grupo e quantas
 * contas do grupo compraram cada produto na janela de historico. No finish, encadeia a fase 2
 * (CommercialSignalBatch) levando so os produtos que passam nos limites.
 *
 * without sharing: a participacao do grupo precisa da base inteira de contas, independente de quem
 * dispara o job. O resultado e agregado (contagens) e a visibilidade e aplicada na leitura, porque
 * CommercialSignal__c e controlado pelo pai (PA-17).
 */
public without sharing class CommercialSignalGroupStatsBatch implements Database.Batchable<SObject>, Database.Stateful {

    private final CommercialSignalService.Settings settings;
    private final String groupField;
    private final Date today;
    private final Boolean chainNext;

    @TestVisible private Map<String, Integer> groupSizes = new Map<String, Integer>();
    @TestVisible private Map<String, Map<Id, Integer>> buyersByGroup = new Map<String, Map<Id, Integer>>();

    public CommercialSignalGroupStatsBatch() {
        this(CommercialSignalService.loadSettings(), Date.today(), true);
    }

    public CommercialSignalGroupStatsBatch(CommercialSignalService.Settings settings, Date today, Boolean chainNext) {
        this.settings = settings;
        this.today = today;
        this.chainNext = chainNext;
        this.groupField = CommercialSignalService.resolveGroupField(settings.crossSellGroupField);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, ' + groupField + ' FROM Account WHERE ' + groupField + ' != null');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        collect((List<Account>) scope);
    }

    /** Acumula tamanho de grupo e compradores por produto para um lote de contas. */
    @TestVisible
    private void collect(List<Account> accounts) {
        Map<Id, String> groupByAccount = new Map<Id, String>();
        for (Account a : accounts) {
            String g = CommercialSignalService.groupKey(a.get(groupField));
            if (g == null) {
                continue;
            }
            groupByAccount.put(a.Id, g);
            groupSizes.put(g, (groupSizes.containsKey(g) ? groupSizes.get(g) : 0) + 1);
        }
        if (groupByAccount.isEmpty()) {
            return;
        }
        Set<Id> accountIds = new Set<Id>(groupByAccount.keySet());
        List<String> statuses = settings.purchaseStatuses;
        Date fromDate = today.addMonths(-settings.crossSellLookbackMonths);
        // Uma linha por (conta, produto): cada conta pertence a um unico lote, entao nao conta em dobro.
        for (AggregateResult ar : [
            SELECT Order.AccountId acc, Product2Id prod, COUNT(Id) n
            FROM OrderItem
            WHERE Order.AccountId IN :accountIds
              AND Order.Status IN :statuses
              AND Order.EffectiveDate >= :fromDate
              AND Order.EffectiveDate <= :today
              AND Product2Id != null
            GROUP BY Order.AccountId, Product2Id
        ]) {
            String g = groupByAccount.get((Id) ar.get('acc'));
            if (g == null) {
                continue;
            }
            if (!buyersByGroup.containsKey(g)) {
                buyersByGroup.put(g, new Map<Id, Integer>());
            }
            Map<Id, Integer> byProduct = buyersByGroup.get(g);
            Id prod = (Id) ar.get('prod');
            byProduct.put(prod, (byProduct.containsKey(prod) ? byProduct.get(prod) : 0) + 1);
        }
    }

    /** Produtos elegiveis por grupo, ja filtrados por tamanho minimo e participacao minima. */
    @TestVisible
    private Map<String, List<CommercialSignalService.Candidate>> qualify() {
        Map<String, List<CommercialSignalService.Candidate>> result = new Map<String, List<CommercialSignalService.Candidate>>();
        for (String g : buyersByGroup.keySet()) {
            List<CommercialSignalService.Candidate> list1 =
                CommercialSignalService.qualifyGroup(groupSizes.get(g), buyersByGroup.get(g), settings);
            if (!list1.isEmpty()) {
                result.put(g, list1);
            }
        }
        return result;
    }

    public void finish(Database.BatchableContext bc) {
        if (chainNext) {
            Database.executeBatch(new CommercialSignalBatch(settings, today, qualify()), settings.batchSize);
        }
    }
}
