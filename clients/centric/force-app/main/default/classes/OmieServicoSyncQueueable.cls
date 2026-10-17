/**
 * Orquestra o envio de serviços do Salesforce para o Omie, um serviço por
 * requisição (UpsertCadastroServico).
 *
 * Espelha o OmieProdutoSyncQueueable — inclusive no motivo de ser um a um: o
 * endpoint /servicos/servico/ não tem método de lote, então quem dita o tamanho
 * da transação é o limite de callouts do Salesforce.
 *
 * Uso:
 *   System.enqueueJob(new OmieServicoSyncQueueable(listaDeIds));
 */
public with sharing class OmieServicoSyncQueueable implements Queueable, Database.AllowsCallouts {

    /**
     * Um serviço = um callout. O Salesforce permite 100 callouts por transação;
     * os 10 de folga cobrem qualquer chamada extra que a transação faça.
     */
    private static final Integer SERVICOS_POR_TRANSACAO = 90;

    /**
     * O Omie bloqueia IP + App Key + Método por 30 minutos na 10ª requisição com
     * erro. Paramos na metade do caminho: insistir depois de vários erros é o
     * que dispara o bloqueio.
     */
    private static final Integer MAX_ERROS_OMIE = 5;

    private List<Id> pendentes;

    public OmieServicoSyncQueueable(List<Id> productIds) {
        this.pendentes = (productIds == null) ? new List<Id>() : productIds;
    }

    // -----------------------------------------------------------------
    public void execute(QueueableContext ctx) {
        if (pendentes.isEmpty()) return;

        List<Id> daVez  = new List<Id>();
        List<Id> sobras = new List<Id>();

        for (Integer i = 0; i < pendentes.size(); i++) {
            if (i < SERVICOS_POR_TRANSACAO) daVez.add(pendentes[i]); else sobras.add(pendentes[i]);
        }

        List<Product2> servicos = Database.query(
            'SELECT ' + OmieServicoMapper.CAMPOS_SOQL +
            ' FROM Product2 WHERE Id IN :daVez'
        );

        Map<Id, Product2> atualizacoes = new Map<Id, Product2>();

        // 1) Valida ANTES de qualquer callout: inválido não vira requisição.
        //
        // O Product2 não tem campo de erro, então o log É o registro do problema.
        // Inválido também não entra no DML: marcar um registro que nunca chegou
        // a ser enviado só sujaria a data de integração.
        OmieServicoMapper.Resultado sep = OmieServicoMapper.separarValidos(servicos);
        for (Id pid : sep.erros.keySet()) {
            System.debug(LoggingLevel.WARN, 'Serviço inválido ' + pid + ': ' + sep.erros.get(pid));
        }

        // 2) Envia os válidos, um por requisição.
        Boolean bloqueado = false;
        Integer erros     = 0;

        for (Product2 p : sep.validos) {
            if (bloqueado) {                       // rate limit: devolve para a fila
                sobras.add(p.Id);
                continue;
            }
            try {
                OmieServico.StatusResponse s =
                    OmieServicoService.upsertServico(OmieServicoMapper.toOmie(p));

                if (s != null && s.isSucesso()) {
                    atualizacoes.put(p.Id, marcar(p.Id, s.nCodServ));
                } else {
                    erros++;
                    System.debug(LoggingLevel.WARN, 'Omie recusou o serviço ' + p.Id + ': ' +
                        ((s == null) ? 'sem status no retorno' : s.cDescStatus));
                }

            } catch (OmieApiClient.OmieException e) {
                if (e.bloqueante) {
                    bloqueado = true;
                    sobras.add(p.Id);              // não é culpa do dado: tenta depois
                } else {
                    erros++;
                    System.debug(LoggingLevel.WARN, 'Erro no serviço ' + p.Id + ': ' + e.getMessage());
                }
            }

            // Para antes de levar o bloqueio de 30 minutos. O que sobrou volta
            // pela mesma via do rate limit: esperar é mais barato que insistir.
            if (erros >= MAX_ERROS_OMIE) bloqueado = true;
        }

        if (!atualizacoes.isEmpty()) {
            Database.update(atualizacoes.values(), false);
        }

        // 3) Continuação
        if (!sobras.isEmpty() && !Test.isRunningTest()) {
            if (bloqueado) {
                // HTTP 425 = 30 minutos de bloqueio. Reenviar agora só prorroga.
                System.scheduleBatch(new OmieServicoRetryBatch(sobras), 'Omie Servico Retry', 31);
            } else {
                System.enqueueJob(new OmieServicoSyncQueueable(sobras));
            }
        }
    }

    // -----------------------------------------------------------------
    /** Só é chamado no sucesso — por isso o código do Omie é sempre conhecido. */
    private Product2 marcar(Id productId, Long codigoOmie) {
        return new Product2(
            Id                                = productId,
            Id_Codigo_de_Servico__c           = String.valueOf(codigoOmie),
            Omie_FlagIntegrado__c             = true,
            Omie_Data_da_ltima_Integra_o__c   = System.now()
        );
    }
}