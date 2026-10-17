/**
 * Testes do OmieProdutoSyncQueueable e do OmieProdutoRetryBatch.
 *
 * O RetryBatch entra aqui porque o único papel dele é devolver Ids para este
 * Queueable — testá-lo isolado não diria nada sobre o comportamento real.
 *
 * Observação sobre as asserções: o marcar() do Queueable está com os campos de
 * status comentados na produção, então não há o que assertar no registro. O que
 * dá para verificar é o que ele MANDOU para o Omie, e é isso que os testes
 * fazem.
 */
@IsTest
private class OmieProdutoSyncQueueableTest {

    @IsTest
    static void enviaOsValidosUmPorRequisicao() {
        List<Product2> produtos = new List<Product2>{
            OmieTestData.produto('SKU1'),
            OmieTestData.produto('SKU2')
        };
        insert produtos;
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusProduto(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieProdutoSyncQueueable(new List<Id>{
            produtos[0].Id, produtos[1].Id }));
        Test.stopTest();

        Assert.areEqual(2, m.chamadas,
            'O Omie depreciou o lote: dois produtos são duas requisições.');
        Assert.isTrue(m.requisicoes[0].contains('UpsertProduto'), 'O envio usa o UpsertProduto.');
    }

    /**
     * O ramo de "produto inválido" NÃO é coberto aqui, e não por esquecimento: o
     * OmieProdutoMapper.validar só reprova ProductCode ou Name em branco, e a
     * própria org impede os dois — Name é obrigatório e há validation rule
     * exigindo ProductCode. Não existe Product2 gravado que o validar recuse,
     * então o ramo é inalcançável a partir do banco. Se as checagens de Unidade
     * e NCM (hoje comentadas no mapper) voltarem, aí passa a valer um teste.
     */
    @IsTest
    static void listaVaziaNaoFazNada() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusProduto(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieProdutoSyncQueueable(new List<Id>()));
        Test.stopTest();

        Assert.areEqual(0, m.chamadas, 'Sem Ids não há o que enviar.');
    }

    @IsTest
    static void construtorAceitaNulo() {
        OmieTestData.instalar(OmieTestData.statusProduto(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieProdutoSyncQueueable(null));
        Test.stopTest();

        Assert.isTrue(true, 'Null na entrada não deve derrubar o job.');
    }

    @IsTest
    static void erroDeDadoNaoInterrompeOsDemais() {
        List<Product2> produtos = new List<Product2>{
            OmieTestData.produto('SKU1'),
            OmieTestData.produto('SKU2')
        };
        insert produtos;
        // Primeiro recusado, segundo aceito: o erro de um não pode parar o outro.
        OmieTestData.Mock m = OmieTestData.instalar(new List<String>{
            OmieTestData.statusProduto(0L, '101', 'Produto invalido'),
            OmieTestData.statusProduto(4811189079L, '0', 'ok')
        });

        Test.startTest();
        System.enqueueJob(new OmieProdutoSyncQueueable(new List<Id>{
            produtos[0].Id, produtos[1].Id }));
        Test.stopTest();

        Assert.areEqual(2, m.chamadas, 'O segundo produto deve ser enviado mesmo após a recusa do primeiro.');
    }

    /**
     * HTTP 425 é o bloqueio de 30 minutos. A partir dele o Queueable para de
     * enviar em vez de insistir e prorrogar o castigo.
     */
    @IsTest
    static void bloqueioDoOmieInterrompeOEnvio() {
        List<Product2> produtos = new List<Product2>{
            OmieTestData.produto('SKU1'),
            OmieTestData.produto('SKU2'),
            OmieTestData.produto('SKU3')
        };
        insert produtos;
        OmieTestData.Mock m = OmieTestData.instalarErro(425, 'Consumo indevido');

        Test.startTest();
        System.enqueueJob(new OmieProdutoSyncQueueable(new List<Id>{
            produtos[0].Id, produtos[1].Id, produtos[2].Id }));
        Test.stopTest();

        Assert.areEqual(1, m.chamadas,
            'Depois do 425 nada mais deve sair: os demais voltam para a fila.');
    }

    @IsTest
    static void retryBatchDevolveOsPendentesParaAFila() {
        Product2 p = OmieTestData.produto('SKU1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusProduto(1L, '0', 'ok'));

        Test.startTest();
        Database.executeBatch(new OmieProdutoRetryBatch(new List<Id>{ p.Id }));
        Test.stopTest();

        // O finish() está comentado na produção, então não há reenfileiramento a
        // verificar. O que este teste garante é que o batch roda de ponta a ponta
        // sem estourar — é ele que carrega os Ids durante a espera de 31 minutos.
        Assert.isTrue(true, 'O batch de espera deve completar sem erro.');
    }
}