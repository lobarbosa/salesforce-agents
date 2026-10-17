/**
 * Testes do OmieServicoSyncQueueable e do OmieServicoRetryBatch.
 *
 * O RetryBatch entra aqui porque o único papel dele é devolver Ids para este
 * Queueable depois da espera de 31 minutos.
 */
@IsTest
private class OmieServicoSyncQueueableTest {

    @IsTest
    static void gravaOCodigoRetornadoNoProduto() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(4811189079L, '0', 'Cadastrado'));

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{ p.Id }));
        Test.stopTest();

        Product2 depois = [
            SELECT Id_Codigo_de_Servico__c, Omie_FlagIntegrado__c, Omie_Data_da_ltima_Integra_o__c
            FROM Product2 WHERE Id = :p.Id
        ];
        Assert.areEqual('4811189079', depois.Id_Codigo_de_Servico__c,
            'O nCodServ do retorno deve ser gravado.');
        Assert.isTrue(depois.Omie_FlagIntegrado__c, 'Sucesso marca o serviço como integrado.');
        Assert.isNotNull(depois.Omie_Data_da_ltima_Integra_o__c, 'A data de integração deve ser gravada.');
    }

    @IsTest
    static void enviaUmPorRequisicao() {
        List<Product2> servicos = new List<Product2>{
            OmieTestData.servico('SRV1'), OmieTestData.servico('SRV2')
        };
        insert servicos;
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{
            servicos[0].Id, servicos[1].Id }));
        Test.stopTest();

        Assert.areEqual(2, m.chamadas, 'O endpoint de serviços não tem lote: dois serviços, duas requisições.');
        Assert.isTrue(m.requisicoes[0].contains('UpsertCadastroServico'), 'O envio usa o Upsert.');
    }

    @IsTest
    static void invalidoNaoViraRequisicaoNemGravacao() {
        Product2 p = OmieTestData.servico('SRV1');
        p.ProductCode = 'A'.repeat(21);          // acima do limite do Omie
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{ p.Id }));
        Test.stopTest();

        Assert.areEqual(0, m.chamadas, 'Validar antes do callout evita o bloqueio de 30 minutos.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id]
                        .Id_Codigo_de_Servico__c,
            'Registro que nunca foi enviado não deve ser marcado.');
    }

    @IsTest
    static void recusaDoOmieNaoGravaNemZeraOCodigoAnterior() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = '999';
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(0L, '101', 'Servico invalido'));

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{ p.Id }));
        Test.stopTest();

        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'Erro não pode zerar o código que já estava no registro.');
    }

    @IsTest
    static void erroDeDadoNaoInterrompeOsDemais() {
        List<Product2> servicos = new List<Product2>{
            OmieTestData.servico('SRV1'), OmieTestData.servico('SRV2')
        };
        insert servicos;
        OmieTestData.Mock m = OmieTestData.instalar(new List<String>{
            OmieTestData.statusServico(0L, '101', 'invalido'),
            OmieTestData.statusServico(4811189079L, '0', 'ok')
        });

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{
            servicos[0].Id, servicos[1].Id }));
        Test.stopTest();

        Assert.areEqual(2, m.chamadas, 'A recusa de um não pode parar o outro.');
        Assert.areEqual(1, [
            SELECT COUNT() FROM Product2 WHERE Id_Codigo_de_Servico__c = '4811189079'
        ], 'Só o aceito deve ter código gravado.');
    }

    @IsTest
    static void bloqueioDoOmieInterrompeOEnvio() {
        List<Product2> servicos = new List<Product2>{
            OmieTestData.servico('SRV1'), OmieTestData.servico('SRV2'), OmieTestData.servico('SRV3')
        };
        insert servicos;
        OmieTestData.Mock m = OmieTestData.instalarErro(425, 'Consumo indevido');

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>{
            servicos[0].Id, servicos[1].Id, servicos[2].Id }));
        Test.stopTest();

        Assert.areEqual(1, m.chamadas,
            'Depois do 425, insistir só prorroga o castigo: os demais voltam para a fila.');
    }

    @IsTest
    static void listaVaziaENulaNaoFazemNada() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        System.enqueueJob(new OmieServicoSyncQueueable(new List<Id>()));
        System.enqueueJob(new OmieServicoSyncQueueable(null));
        Test.stopTest();

        Assert.areEqual(0, m.chamadas, 'Sem Ids não há o que enviar.');
    }

    @IsTest
    static void retryBatchReenfileiraOsPendentes() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(4811189079L, '0', 'ok'));

        Test.startTest();
        Database.executeBatch(new OmieServicoRetryBatch(new List<Id>{ p.Id }));
        Test.stopTest();

        // O finish() enfileira o Queueable, que roda dentro do stopTest e envia.
        Assert.areEqual('4811189079',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'A espera de 31 minutos existe para que o envio aconteça depois — e ele acontece.');
    }
}