/**
 * EPLAST-33, fase 1. Para as contas com segmento preenchido (Account.Sector__c, por parametro), mede o
 * tamanho de cada segmento e quantas contas do segmento compraram cada familia (ou produto, conforme
 * CrossSellLevel__c) na janela de historico. No finish, encadeia a fase 2 (CommercialSignalBatch)
 * levando so os itens que passam nos limites.
 *
 * without sharing: a participacao do segmento precisa da base inteira de contas, independente de quem
 * dispara o job. O resultado e agregado (contagens) e a visibilidade e aplicada na leitura, porque
 * CommercialSignal__c e controlado pelo pai (PA-17).
 */
public without sharing class CommercialSignalGroupStatsBatch implements Database.Batchable<SObject>, Database.Stateful {

    private final CommercialSignalService.Settings settings;
    private final String groupField;
    private final Date today;
    private final Boolean chainNext;

    @TestVisible private Map<String, Integer> groupSizes = new Map<String, Integer>();
    @TestVisible private Map<String, Map<String, Integer>> buyersByGroup = new Map<String, Map<String, Integer>>();

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

    /** Acumula tamanho de segmento e compradores por item para um lote de contas. */
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
        String df = settings.purchaseDateField;
        String item = CommercialSignalService.itemExpression(settings);
        Map<String, Object> binds = new Map<String, Object>{
            'accountIds' => groupByAccount.keySet(),
            'statuses' => settings.purchaseStatuses,
            'fromDate' => CommercialSignalService.bound(today.addMonths(-settings.crossSellLookbackMonths), df),
            'toDate' => CommercialSignalService.bound(today.addDays(1), df)
        };
        String soql = 'SELECT Order.AccountId acc, ' + item + ' item, COUNT(Id) n FROM OrderItem'
            + ' WHERE Order.AccountId IN :accountIds AND Order.Status IN :statuses'
            + ' AND Order.' + df + ' >= :fromDate AND Order.' + df + ' < :toDate'
            + ' GROUP BY Order.AccountId, ' + item;
        // Uma linha por (conta, item): cada conta pertence a um unico lote, entao nao conta em dobro.
        for (SObject row : Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE)) {
            AggregateResult ar = (AggregateResult) row;
            String key = CommercialSignalService.groupKey(ar.get('item'));
            String g = groupByAccount.get((Id) ar.get('acc'));
            if (g == null || key == null) {
                continue;
            }
            if (!buyersByGroup.containsKey(g)) {
                buyersByGroup.put(g, new Map<String, Integer>());
            }
            Map<String, Integer> byItem = buyersByGroup.get(g);
            byItem.put(key, (byItem.containsKey(key) ? byItem.get(key) : 0) + 1);
        }
    }

    /** Itens elegiveis por segmento, ja filtrados por tamanho minimo e participacao minima. */
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
