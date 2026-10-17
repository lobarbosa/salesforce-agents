/**
 * Testes do OmieProdutoService e do DTO OmieProduto.
 *
 * O DTO entra aqui em vez de ter teste próprio porque a lógica dele
 * (isSucesso) só existe em função do que o service devolve.
 */
@IsTest
private class OmieProdutoServiceTest {

    @IsTest
    static void listarDevolveAPaginaDesserializada() {
        OmieTestData.instalar(OmieTestData.listaProdutos(1, 4811189079L, 'chave', 'SKU1'));

        Test.startTest();
        OmieProduto.ListaResponse r = OmieProdutoService.listar(1, 50);
        Test.stopTest();

        Assert.areEqual(1, r.produto_servico_cadastro.size(), 'Deve trazer o produto da página.');
        Assert.areEqual(4811189079L, r.produto_servico_cadastro[0].codigo_produto,
            'O codigo_produto é a PK do Omie.');
        Assert.areEqual('SKU1', r.produto_servico_cadastro[0].codigo, 'O SKU deve chegar.');
    }

    @IsTest
    static void listarLimitaRegistrosPorPaginaAoMaximoDoOmie() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.listaProdutos(1, 1L, 'c', 'SKU1'));

        Test.startTest();
        OmieProdutoService.listar(1, 5000);      // acima do limite de propósito
        Test.stopTest();

        Map<String, Object> envelope =
            (Map<String, Object>) JSON.deserializeUntyped(m.requisicoes[0]);
        Map<String, Object> param =
            (Map<String, Object>) ((List<Object>) envelope.get('param'))[0];
        Assert.areEqual(OmieProdutoService.MAX_REGISTROS_PAGINA, param.get('registros_por_pagina'),
            'O Omie rejeita acima de 100, então o service precisa aparar antes de enviar.');
    }

    @IsTest
    static void listarCorrigePaginaInvalida() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.listaProdutos(1, 1L, 'c', 'SKU1'));

        Test.startTest();
        OmieProdutoService.listar(0, 50);        // página zero não existe
        Test.stopTest();

        Map<String, Object> envelope =
            (Map<String, Object>) JSON.deserializeUntyped(m.requisicoes[0]);
        Map<String, Object> param =
            (Map<String, Object>) ((List<Object>) envelope.get('param'))[0];
        Assert.areEqual(1, param.get('pagina'), 'Página inválida deve virar 1.');
    }

    @IsTest
    static void filtroAlteradosDesdeFormataDataEHora() {
        Datetime quando = Datetime.newInstance(2026, 3, 15, 14, 30, 0);
        OmieProdutoService.Filtro f = new OmieProdutoService.Filtro().alteradosDesde(quando);

        Assert.areEqual('15/03/2026', f.filtrar_por_data_de, 'O Omie espera dd/MM/yyyy.');
        Assert.areEqual('14:30:00', f.filtrar_por_hora_de, 'O Omie espera HH:mm:ss.');
    }

    @IsTest
    static void listarTodosAtivosPercorreAsPaginas() {
        OmieTestData.instalar(OmieTestData.listaProdutos(3, 1L, 'chave', 'SKU1'));

        Test.startTest();
        List<OmieProduto> todos = OmieProdutoService.listarTodosAtivos();
        Test.stopTest();

        Assert.areEqual(3, todos.size(),
            'Três páginas de um produto cada devem render três produtos.');
    }

    @IsTest
    static void consultarPorSkuEnviaOCodigo() {
        OmieTestData.Mock m = OmieTestData.instalar('{"codigo_produto":123,"codigo":"SKU1"}');

        Test.startTest();
        OmieProduto p = OmieProdutoService.consultarPorSku('SKU1');
        Test.stopTest();

        Assert.areEqual(123, p.codigo_produto, 'Deve desserializar o produto.');
        Assert.isTrue(m.requisicoes[0].contains('ConsultarProduto'), 'Deve chamar o ConsultarProduto.');
        Assert.isTrue(m.requisicoes[0].contains('SKU1'), 'O SKU deve ir no param.');
    }

    @IsTest
    static void consultarPorIdSalesforceUsaAChaveDeIntegracao() {
        OmieTestData.Mock m = OmieTestData.instalar('{"codigo_produto":123}');
        Product2 p = OmieTestData.produto('SKU1');
        insert p;

        Test.startTest();
        OmieProdutoService.consultarPorIdSalesforce(p.Id);
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('codigo_produto_integracao'),
            'Consulta pelo Id do Salesforce usa a chave de integração.');
        Assert.isTrue(m.requisicoes[0].contains(String.valueOf(p.Id)), 'O Id deve ir no param.');
    }

    @IsTest
    static void upsertProdutoDevolveStatusDeSucesso() {
        OmieTestData.instalar(OmieTestData.statusProduto(4811189079L, '0', 'Cadastrado'));

        Test.startTest();
        OmieProduto.StatusResponse s = OmieProdutoService.upsertProduto(new OmieProduto());
        Test.stopTest();

        Assert.isTrue(s.isSucesso(), 'codigo_status 0 com codigo_produto é sucesso.');
        Assert.areEqual(4811189079L, s.codigo_produto, 'O código do Omie deve voltar.');
    }

    @IsTest
    static void incluirEAlterarUsamSeusProprios() {
        OmieTestData.Mock m = OmieTestData.instalar(
            new List<String>{ OmieTestData.statusProduto(1L, '0', 'ok') });

        Test.startTest();
        OmieProdutoService.incluir(new OmieProduto());
        OmieProdutoService.alterar(new OmieProduto());
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('IncluirProduto'), 'O primeiro é IncluirProduto.');
        Assert.isTrue(m.requisicoes[1].contains('AlterarProduto'), 'O segundo é AlterarProduto.');
    }

    /** Sem codigo_produto não houve gravação, mesmo que o status venha vazio. */
    @IsTest
    static void statusSemCodigoNaoESucesso() {
        OmieProduto.StatusResponse s = new OmieProduto.StatusResponse();
        Assert.isFalse(s.isSucesso(), 'Sem codigo_produto não há sucesso.');

        s.codigo_produto = 1L;
        s.codigo_status  = '101';
        Assert.isFalse(s.isSucesso(), 'codigo_status diferente de 0 é falha.');

        s.codigo_status = '0';
        Assert.isTrue(s.isSucesso(), 'Com código e status 0 é sucesso.');
    }
}