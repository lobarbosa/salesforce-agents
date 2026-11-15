/**
 * EPLAST-33, fase 2. Para cada lote de contas calcula os sinais (recuperacao, nunca comprou,
 * queda/alta de volume, cruzada), faz upsert por SignalKey__c e apaga os sinais da conta que
 * nao se repetiram. So le Account, Order e OrderItem; a unica escrita e CommercialSignal__c.
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
        Set<Id> accountIds = new Set<Id>(facts.keySet());
        List<String> statuses = settings.purchaseStatuses;
        Date currentFrom = today.addMonths(-settings.volumeWindowMonths);
        Date baseFrom = today.addMonths(-2 * settings.volumeWindowMonths);

        for (AggregateResult ar : [
            SELECT AccountId acc, MAX(EffectiveDate) lastDate
            FROM Order
            WHERE AccountId IN :accountIds AND Status IN :statuses
            GROUP BY AccountId
        ]) {
            facts.get((Id) ar.get('acc')).lastPurchase = (Date) ar.get('lastDate');
        }
        for (AggregateResult ar : [
            SELECT AccountId acc, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds AND Status IN :statuses
              AND EffectiveDate > :currentFrom AND EffectiveDate <= :today
            GROUP BY AccountId
        ]) {
            facts.get((Id) ar.get('acc')).currentAmount = (Decimal) ar.get('total');
        }
        for (AggregateResult ar : [
            SELECT AccountId acc, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds AND Status IN :statuses
              AND EffectiveDate > :baseFrom AND EffectiveDate <= :currentFrom
            GROUP BY AccountId
        ]) {
            facts.get((Id) ar.get('acc')).baseAmount = (Decimal) ar.get('total');
        }
        if (!qualifiedByGroup.isEmpty()) {
            Date recentFrom = today.addDays(-settings.crossSellRecentDays);
            for (AggregateResult ar : [
                SELECT Order.AccountId acc, Product2Id prod, COUNT(Id) n
                FROM OrderItem
                WHERE Order.AccountId IN :accountIds AND Order.Status IN :statuses
                  AND Order.EffectiveDate >= :recentFrom AND Order.EffectiveDate <= :today
                  AND Product2Id != null
                GROUP BY Order.AccountId, Product2Id
            ]) {
                facts.get((Id) ar.get('acc')).recentProducts.add((Id) ar.get('prod'));
            }
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
            SELECT Id, SignalKey__c FROM CommercialSignal__c WHERE Account__c IN :accountIds
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

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'CommercialSignalBatch: contas=' + accountsProcessed
            + ' gravados=' + signalsUpserted + ' removidos=' + signalsDeleted + ' falhas=' + failures);
    }
}
