/**
 * Reenfileira a sincronização de serviços depois do bloqueio de 30 minutos do
 * Omie (HTTP 425).
 *
 * Existe só porque System.scheduleBatch é a forma mais simples de "esperar N
 * minutos" em Apex — não há sleep. Não faz callout: apenas devolve os Ids
 * pendentes para o Queueable quando o tempo passar.
 */
public with sharing class OmieServicoRetryBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    private List<Id> pendentes;

    public OmieServicoRetryBatch(List<Id> productIds) {
        this.pendentes = productIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query mínima só para satisfazer a interface.
        List<Id> ids = pendentes;
        return Database.getQueryLocator([SELECT Id FROM Product2 WHERE Id IN :ids LIMIT 1]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // nada a fazer aqui
    }

    public void finish(Database.BatchableContext bc) {
        if (!pendentes.isEmpty()) {
            System.enqueueJob(new OmieServicoSyncQueueable(pendentes));
        }
    }
}