/**
 * Orquestra o envio de produtos do Salesforce para o Omie, um produto por
 * requisição (UpsertProduto).
 *
 * Por que um a um: o Omie DEPRECIOU o método de lote do endpoint
 * /geral/produtos/. Não existe mais como mandar N produtos em uma requisição,
 * então quem dita o tamanho da transação passou a ser o limite de callouts do
 * Salesforce, e não mais o tamanho do lote.
 *
 * Uso:
 *   System.enqueueJob(new OmieProdutoSyncQueueable(listaDeIds));
 */
public with sharing class OmieProdutoSyncQueueable implements Queueable, Database.AllowsCallouts {

    /**
     * Um produto = um callout. O Salesforce permite 100 callouts por transação;
     * os 10 de folga cobrem qualquer chamada extra que a transação faça.
     *
     * Vale checar também o tempo: são 120s de callout TOTAL por transação, ou
     * seja ~1,3s de média por produto. Se o Omie estiver lento, baixe este
     * número em vez de aumentar o timeout do OmieApiClient.
     */
    private static final Integer PRODUTOS_POR_TRANSACAO = 90;

    /**
     * O Omie bloqueia IP + App Key + Método por 30 minutos na 10ª requisição com
     * erro. Com o método unitário, cada produto recusado é uma requisição com
     * erro — antes, 50 produtos ruins custavam UMA. Por isso paramos na metade
     * do caminho: insistir depois de vários erros é o que dispara o bloqueio.
     */
    private static final Integer MAX_ERROS_OMIE = 5;

    private List<Id> pendentes;

    public OmieProdutoSyncQueueable(List<Id> productIds) {
        this.pendentes = (productIds == null) ? new List<Id>() : productIds;
    }

    // -----------------------------------------------------------------
    public void execute(QueueableContext ctx) {
        if (pendentes.isEmpty()) return;

        List<Id> daVez  = new List<Id>();
        List<Id> sobras = new List<Id>();

        for (Integer i = 0; i < pendentes.size(); i++) {
            if (i < PRODUTOS_POR_TRANSACAO) daVez.add(pendentes[i]); else sobras.add(pendentes[i]);
        }

        List<Product2> produtos = Database.query(
            'SELECT ' + OmieProdutoMapper.CAMPOS_SOQL +
            ' FROM Product2 WHERE Id IN :daVez'
        );

        Map<Id, Product2> atualizacoes = new Map<Id, Product2>();

        // 1) Valida ANTES de qualquer callout: inválido não vira requisição.
        OmieProdutoMapper.Resultado sep = OmieProdutoMapper.separarValidos(produtos);
        for (Id pid : sep.erros.keySet()) {
            atualizacoes.put(pid, marcar(pid, 'Inválido', sep.erros.get(pid), null));
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
                OmieProduto.StatusResponse s =
                    OmieProdutoService.upsertProduto(OmieProdutoMapper.toOmie(p));

                if (s != null && s.isSucesso()) {
                    atualizacoes.put(p.Id, marcar(p.Id, 'Sincronizado', null, s.codigo_produto));
                } else {
                    erros++;
                    atualizacoes.put(p.Id, marcar(p.Id, 'Erro',
                        (s == null) ? 'O Omie não retornou status para o produto.'
                                    : s.descricao_status, null));
                }

            } catch (OmieApiClient.OmieException e) {
                if (e.bloqueante) {
                    bloqueado = true;
                    sobras.add(p.Id);              // não é culpa do dado: tenta depois
                } else {
                    erros++;
                    atualizacoes.put(p.Id, marcar(p.Id, 'Erro', e.getMessage(), null));
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
                System.scheduleBatch(new OmieProdutoRetryBatch(sobras), 'Omie Retry', 31);
            } else {
                System.enqueueJob(new OmieProdutoSyncQueueable(sobras));
            }
        }
    }

    // -----------------------------------------------------------------
    private Product2 marcar(Id productId, String status, String erro, Long codigoOmie) {
        Product2 p = new Product2(
            Id                  = productId
            //Omie_Sync_Status__c = status,
            //Omie_Sync_Erro__c   = (erro == null) ? null: (erro.length() > 255 ? erro.substring(0, 255) : erro)
            //Omie_Ultima_Sync__c = System.now()
        );
        // Só grava o ID do Omie quando ele veio. Em caso de erro, preserva o valor
        // que já estava no registro em vez de zerá-lo.
        if (codigoOmie != null) {
            p.Id_Codigo_de_Servico__c = String.valueOf(codigoOmie);
        }
        return p;
    }
}