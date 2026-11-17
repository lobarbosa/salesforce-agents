/**
 * EPLAST-33, fase 2. Para cada lote de contas calcula os sinais (recuperacao, nunca comprou,
 * queda de volume por familia, historico insuficiente, cruzada), faz upsert por SignalKey__c e apaga
 * os sinais da conta que nao se repetiram. So le Account, Order, OrderItem e Product2; a unica escrita
 * e CommercialSignal__c.
 *
 * Os campos de data da compra e de familia vem do CMDT e so entram na consulta depois de validados
 * contra a lista permitida (CommercialSignalService.loadSettings); nenhum texto livre vira SOQL.
 *
 * without sharing: a cruzada usa estatistica da base inteira (fase 1) e o job precisa enxergar
 * todas as contas independente de quem o agenda. A visibilidade e aplicada na leitura, porque
 * CommercialSignal__c e controlado pelo pai (PA-17).
 */
public without sharing class CommercialSignalBatch implements Database.Batchable<SObject>, Database.Stateful {

    private final CommercialSignalService.Settings settings;
    private final Date today;
    private final Map<String, List<CommercialSignalService.Candidate>> qualifiedByGroup;
    private final String groupField;

    public Integer accountsProcessed = 0;
    public Integer signalsUpserted = 0;
    public Integer signalsDeleted = 0;
    public Integer failures = 0;

    public CommercialSignalBatch(
        CommercialSignalService.Settings settings, Date today,
        Map<String, List<CommercialSignalService.Candidate>> qualifiedByGroup
    ) {
        this.settings = settings;
        this.today = today;
        this.qualifiedByGroup = qualifiedByGroup == null
            ? new Map<String, List<CommercialSignalService.Candidate>>() : qualifiedByGroup;
        this.groupField = CommercialSignalService.resolveGroupField(settings.crossSellGroupField);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, ' + groupField + ' FROM Account');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        process((List<Account>) scope);
    }

    @TestVisible
    private void process(List<Account> accounts) {
        Map<Id, CommercialSignalService.AccountFacts> facts = new Map<Id, CommercialSignalService.AccountFacts>();
        for (Account a : accounts) {
            CommercialSignalService.AccountFacts f = new CommercialSignalService.AccountFacts();
            f.accountId = a.Id;
            f.groupValue = CommercialSignalService.groupKey(a.get(groupField));
            facts.put(a.Id, f);
        }
        loadLastPurchase(facts);
        loadFamilyVolume(facts);
        if (!qualifiedByGroup.isEmpty()) {
            loadRecentItems(facts);
        }

        List<CommercialSignal__c> desired = new List<CommercialSignal__c>();
        Set<String> desiredKeys = new Set<String>();
        for (CommercialSignalService.AccountFacts f : facts.values()) {
            for (CommercialSignal__c s : CommercialSignalService.buildSignals(f, today, settings, qualifiedByGroup)) {
                desired.add(s);
                desiredKeys.add(s.SignalKey__c);
            }
        }

        List<CommercialSignal__c> stale = new List<CommercialSignal__c>();
        List<CommercialSignal__c> existingSignals = [
            SELECT Id, SignalKey__c FROM CommercialSignal__c WHERE Account__c IN :facts.keySet()
        ];
        for (CommercialSignal__c existing : existingSignals) {
            if (!desiredKeys.contains(existing.SignalKey__c)) {
                stale.add(existing);
            }
        }

        // allOrNone=false: um bloqueio de linha numa conta nao derruba o lote; a proxima execucao recompoe.
        if (!desired.isEmpty()) {
            for (Database.UpsertResult r : Database.upsert(desired, CommercialSignal__c.SignalKey__c, false)) {
                if (r.isSuccess()) {
                    signalsUpserted++;
                } else {
                    failures++;
                }
            }
        }
        if (!stale.isEmpty()) {
            for (Database.DeleteResult r : Database.delete(stale, false)) {
                if (r.isSuccess()) {
                    signalsDeleted++;
                } else {
                    failures++;
                }
            }
        }
        accountsProcessed += accounts.size();
    }

    /** Ultima compra faturada por conta, pela data configurada (nao grava nada). */
    private void loadLastPurchase(Map<Id, CommercialSignalService.AccountFacts> facts) {
        String df = settings.purchaseDateField;
        Map<String, Object> binds = new Map<String, Object>{
            'accountIds' => facts.keySet(),
            'statuses' => settings.purchaseStatuses,
            'upper' => CommercialSignalService.bound(today.addDays(1), df)
        };
        String soql = 'SELECT AccountId acc, MAX(' + df + ') lastDate FROM Order'
            + ' WHERE AccountId IN :accountIds AND Status IN :statuses AND ' + df + ' < :upper GROUP BY AccountId';
        for (SObject row : Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE)) {
            AggregateResult ar = (AggregateResult) row;
            facts.get((Id) ar.get('acc')).lastPurchase = CommercialSignalService.asDate(ar.get('lastDate'));
        }
    }

    /**
     * Valor e quantidade por conta x familia x unidade x mes, na janela [1o dia do mes M-(N+1), 1o dia do
     * mes corrente). O ultimo mes fechado e o "atual"; os N meses anteriores formam a base.
     */
    private void loadFamilyVolume(Map<Id, CommercialSignalService.AccountFacts> facts) {
        String df = settings.purchaseDateField;
        Date currentStart = CommercialSignalService.currentMonthStart(today);
        String currentKey = CommercialSignalService.monthKey(currentStart.year(), currentStart.month());
        String fam = 'Product2.' + settings.familyField;
        Map<String, Object> binds = new Map<String, Object>{
            'accountIds' => facts.keySet(),
            'statuses' => settings.purchaseStatuses,
            'fromDate' => CommercialSignalService.bound(CommercialSignalService.baseStart(today, settings.volumeWindowMonths), df),
            'toDate' => CommercialSignalService.bound(CommercialSignalService.currentMonthEnd(today), df)
        };
        String soql = 'SELECT Order.AccountId acc, ' + fam + ' fam, Product2.QuantityUnitOfMeasure uom,'
            + ' CALENDAR_YEAR(Order.' + df + ') y, CALENDAR_MONTH(Order.' + df + ') m,'
            + ' SUM(TotalPrice) amt, SUM(Quantity) qty FROM OrderItem'
            + ' WHERE Order.AccountId IN :accountIds AND Order.Status IN :statuses'
            + ' AND Order.' + df + ' >= :fromDate AND Order.' + df + ' < :toDate'
            + ' GROUP BY Order.AccountId, ' + fam + ', Product2.QuantityUnitOfMeasure,'
            + ' CALENDAR_YEAR(Order.' + df + '), CALENDAR_MONTH(Order.' + df + ')';
        for (SObject row : Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE)) {
            AggregateResult ar = (AggregateResult) row;
            CommercialSignalService.AccountFacts f = facts.get((Id) ar.get('acc'));
            String family = CommercialSignalService.familyKey(ar.get('fam'));
            if (!f.families.containsKey(family)) {
                f.families.put(family, new CommercialSignalService.FamilyFacts(family));
            }
            CommercialSignalService.FamilyFacts ff = f.families.get(family);
            Decimal amount = (Decimal) ar.get('amt');
            Decimal quantity = (Decimal) ar.get('qty');
            amount = amount == null ? 0 : amount;
            quantity = quantity == null ? 0 : quantity;
            ff.units.add(CommercialSignalService.groupKey(ar.get('uom')) == null
                ? CommercialSignalService.UNIT_NONE : String.valueOf(ar.get('uom')).trim());
            String month = CommercialSignalService.monthKey(Integer.valueOf(ar.get('y')), Integer.valueOf(ar.get('m')));
            if (month == currentKey) {
                ff.currentAmount += amount;
                ff.currentQuantity += quantity;
            } else {
                ff.baseAmountTotal += amount;
                ff.baseQuantityTotal += quantity;
                ff.baseMonths.add(month);
            }
        }
    }

    /** Itens (familia ou produto) comprados na janela recente da cruzada. */
    private void loadRecentItems(Map<Id, CommercialSignalService.AccountFacts> facts) {
        String df = settings.purchaseDateField;
        String item = CommercialSignalService.itemExpression(settings);
        Map<String, Object> binds = new Map<String, Object>{
            'accountIds' => facts.keySet(),
            'statuses' => settings.purchaseStatuses,
            'fromDate' => CommercialSignalService.bound(today.addDays(-settings.crossSellRecentDays), df),
            'toDate' => CommercialSignalService.bound(today.addDays(1), df)
        };
        String soql = 'SELECT Order.AccountId acc, ' + item + ' item, COUNT(Id) n FROM OrderItem'
            + ' WHERE Order.AccountId IN :accountIds AND Order.Status IN :statuses'
            + ' AND Order.' + df + ' >= :fromDate AND Order.' + df + ' < :toDate'
            + ' GROUP BY Order.AccountId, ' + item;
        for (SObject row : Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE)) {
            AggregateResult ar = (AggregateResult) row;
            String key = CommercialSignalService.groupKey(ar.get('item'));
            if (key != null) {
                facts.get((Id) ar.get('acc')).recentItems.add(key);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'CommercialSignalBatch: contas=' + accountsProcessed
            + ' gravados=' + signalsUpserted + ' removidos=' + signalsDeleted + ' falhas=' + failures
            + (settings.warnings.isEmpty() ? '' : ' avisos=' + String.join(settings.warnings, ' | ')));
    }
}
