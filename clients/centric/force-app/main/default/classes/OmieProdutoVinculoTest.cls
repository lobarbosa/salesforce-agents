/**
 * Testes do OmieProdutoVinculo: casar o catálogo do Omie com o Product2 e
 * gravar o código.
 */
@IsTest
private class OmieProdutoVinculoTest {

    @IsTest
    static void casaPelaChaveDeIntegracao() {
        Product2 p = OmieTestData.produto('SKU1');
        insert p;
        OmieTestData.instalar(
            OmieTestData.listaProdutos(1, 4811189079L, String.valueOf(p.Id), 'OUTRO-SKU'));

        Test.startTest();
        OmieProdutoVinculo.Resultado r = OmieProdutoVinculo.vincularAtivos();
        Test.stopTest();

        Assert.areEqual(1, r.vinculados, 'Deve vincular pelo codigo_produto_integracao.');
        Assert.areEqual('4811189079',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'A chave de integração é inequívoca, então casa mesmo com SKU diferente.');
    }

    @IsTest
    static void casaPeloSkuQuandoNaoHaChaveDeIntegracao() {
        Product2 p = OmieTestData.produto('SKU1');
        insert p;
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 999L, '', 'SKU1'));

        Test.startTest();
        OmieProdutoVinculo.Resultado r = OmieProdutoVinculo.vincularAtivos();
        Test.stopTest();

        Assert.areEqual(1, r.vinculados, 'Sem chave de integração, o SKU é o desempate.');
        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'O código do Omie deve ser gravado.');
    }

    @IsTest
    static void naoRegravaQuandoOCodigoJaEOMesmo() {
        Product2 p = OmieTestData.produto('SKU1');
        p.Id_Codigo_de_Servico__c = '999';
        insert p;
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 999L, '', 'SKU1'));

        Test.startTest();
        OmieProdutoVinculo.Resultado r = OmieProdutoVinculo.vincularAtivos();
        Test.stopTest();

        Assert.areEqual(1, r.jaVinculados, 'Código igual conta como já vinculado.');
        Assert.areEqual(0, r.vinculados, 'Não deve gastar DML para gravar o mesmo valor.');
    }

    @IsTest
    static void contaSemMatchQuandoOProdutoNaoExisteAqui() {
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 999L, '', 'SKU-QUE-NAO-TENHO'));

        Test.startTest();
        OmieProdutoVinculo.Resultado r = OmieProdutoVinculo.vincularAtivos();
        Test.stopTest();

        Assert.areEqual(1, r.semMatch, 'Produto do Omie sem par aqui deve ser contado.');
        Assert.areEqual(0, r.vinculados, 'Nada a vincular.');
    }

    /**
     * SKU repetido no Salesforce não dá para casar: escolher "o primeiro"
     * gravaria o código do Omie no produto errado.
     */
    @IsTest
    static void skuRepetidoNaoEVinculado() {
        List<Product2> produtos = new List<Product2>{
            OmieTestData.produto('SKU-DUPLICADO'),
            OmieTestData.produto('SKU-DUPLICADO')
        };
        insert produtos;
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 999L, '', 'SKU-DUPLICADO'));

        Test.startTest();
        OmieProdutoVinculo.Resultado r = OmieProdutoVinculo.vincularAtivos();
        Test.stopTest();

        Assert.areEqual(0, r.vinculados, 'Com SKU ambíguo é melhor não gravar nada.');
        Assert.areEqual(1, r.semMatch, 'O produto ambíguo do Omie deve ser contado como sem match.');
    }

    @IsTest
    static void resumoDaExecucaoEhLegivel() {
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 999L, '', 'NAO-EXISTE'));

        Test.startTest();
        String resumo = String.valueOf(OmieProdutoVinculo.vincularAtivos());
        Test.stopTest();

        Assert.isTrue(resumo.contains('sem match'),
            'O toString existe para caber em um System.debug: ' + resumo);
    }
}