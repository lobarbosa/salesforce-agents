/**
 * Testes do OmieServicoService e dos atalhos do DTO OmieServico.
 *
 * O DTO entra aqui porque os atalhos dele (codigoOmie, chaveIntegracao,
 * isInativo) existem justamente para lidar com o formato que este service
 * devolve — o bloco de identificação que muda de nome por método.
 */
@IsTest
private class OmieServicoServiceTest {

    @IsTest
    static void listarDevolveAPaginaDesserializada() {
        OmieTestData.instalar(OmieTestData.listaServicos(1, 4811189079L, 'chave', 'SRV1'));

        Test.startTest();
        OmieServico.ListaResponse r = OmieServicoService.listar(1, 50);
        Test.stopTest();

        Assert.areEqual(1, r.cadastros.size(), 'O array do Omie chama cadastros.');
        Assert.areEqual(4811189079L, r.cadastros[0].codigoOmie(), 'O nCodServ é a PK do Omie.');
        Assert.areEqual('SRV1', r.cadastros[0].codigo(), 'O cCodigo deve chegar.');
        Assert.isFalse(r.cadastros[0].isInativo(), 'inativo = N significa ativo.');
    }

    @IsTest
    static void listarLimitaRegistrosPorPaginaAoMaximo() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.listaServicos(1, 1L, 'c', 'SRV1'));

        Test.startTest();
        OmieServicoService.listar(1, 5000);
        Test.stopTest();

        Map<String, Object> param = primeiroParam(m.requisicoes[0]);
        Assert.areEqual(OmieServicoService.MAX_REGISTROS_PAGINA, param.get('nRegPorPagina'),
            'O service precisa aparar antes de enviar.');
    }

    @IsTest
    static void listarCorrigePaginaInvalida() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.listaServicos(1, 1L, 'c', 'SRV1'));

        Test.startTest();
        OmieServicoService.listar(0, 50);
        Test.stopTest();

        Assert.areEqual(1, primeiroParam(m.requisicoes[0]).get('nPagina'),
            'Página inválida deve virar 1.');
    }

    @IsTest
    static void filtroAlteradosDesdeFormataData() {
        OmieServicoService.Filtro f = new OmieServicoService.Filtro()
            .alteradosDesde(Datetime.newInstance(2026, 3, 15, 14, 30, 0));

        Assert.areEqual('15/03/2026', f.dAlteracaoInicial, 'O Omie espera dd/MM/yyyy.');
    }

    // =================================================================
    // Paginação em fatias
    // =================================================================

    @IsTest
    static void codigosAtivosLeApenasAFatiaPedida() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.listaServicos(10, 1L, 'chave', 'SRV1'));

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(1, 3);
        Test.stopTest();

        Assert.areEqual(3, m.chamadas, 'Pedi 3 páginas de um cadastro de 10: só 3 callouts.');
        Assert.areEqual(4, c.proximaPagina, 'A próxima fatia começa na 4.');
        Assert.areEqual(10, c.totalPaginas, 'O total deve vir do retorno do Omie.');
    }

    @IsTest
    static void proximaPaginaNulaQuandoOCadastroAcaba() {
        OmieTestData.instalar(OmieTestData.listaServicos(2, 1L, 'chave', 'SRV1'));

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(1, 20);
        Test.stopTest();

        Assert.isNull(c.proximaPagina,
            'null é o sinal de fim: é o que interrompe o encadeamento do Queueable.');
        Assert.areEqual(2, c.lidos, 'Duas páginas de um serviço cada.');
    }

    @IsTest
    static void ultimaFatiaExataNaoPedeMaisUma() {
        OmieTestData.instalar(OmieTestData.listaServicos(4, 1L, 'chave', 'SRV1'));

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(3, 2);   // páginas 3 e 4
        Test.stopTest();

        Assert.isNull(c.proximaPagina, 'A fatia terminou exatamente na última página.');
    }

    @IsTest
    static void respostaVaziaEncerraSemErro() {
        OmieTestData.instalar('{"nPagina":1,"nTotPaginas":0,"nRegistros":0,"nTotRegistros":0}');

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(1, 5);
        Test.stopTest();

        Assert.areEqual(0, c.lidos, 'Cadastro vazio não traz nada.');
        Assert.isNull(c.proximaPagina, 'E não deve pedir mais páginas.');
    }

    @IsTest
    static void codigosIndexaPelasDuasChaves() {
        OmieTestData.instalar(OmieTestData.listaServicos(1, 4811189079L, 'chave-int', 'SRV1'));

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(1, 1);
        Test.stopTest();

        Assert.areEqual(4811189079L, c.buscar('chave-int', 'OUTRO'),
            'A chave de integração tem precedência.');
        Assert.areEqual(4811189079L, c.buscar('nao-existe', 'SRV1'),
            'Sem chave, o código resolve.');
        Assert.isNull(c.buscar('nao-existe', 'tambem-nao'), 'Sem nenhum dos dois, não há match.');
    }

    @IsTest
    static void idsSalesforceIgnoraChaveQueNaoEId() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(new List<String>{
            OmieTestData.listaServicos(2, 1L, String.valueOf(p.Id), 'SRV1'),
            OmieTestData.listaServicos(2, 2L, 'NAO-E-UM-ID', 'SRV2')
        });

        Test.startTest();
        OmieServicoService.Codigos c = OmieServicoService.codigosAtivos(1, 2);
        Test.stopTest();

        Set<Id> ids = c.idsSalesforce();
        Assert.areEqual(1, ids.size(), 'Só a chave que é Id de verdade deve entrar.');
        Assert.isTrue(ids.contains(p.Id), 'E deve ser o Id do Product2 inserido.');
    }

    // =================================================================
    // Consulta e gravação
    // =================================================================

    @IsTest
    static void consultarPorCodigoOmieEnviaONCodServ() {
        OmieTestData.Mock m = OmieTestData.instalar('{"intListar":{"nCodServ":123}}');

        Test.startTest();
        OmieServico s = OmieServicoService.consultarPorCodigoOmie(123L);
        Test.stopTest();

        Assert.areEqual(123, s.codigoOmie(), 'Deve desserializar o serviço.');
        Assert.isTrue(m.requisicoes[0].contains('ConsultarCadastroServico'), 'Deve usar o Consultar.');
        Assert.isTrue(m.requisicoes[0].contains('nCodServ'), 'A chave deve ir no param.');
    }

    @IsTest
    static void consultarPorIdSalesforceUsaAChaveDeIntegracao() {
        OmieTestData.Mock m = OmieTestData.instalar('{"intListar":{"nCodServ":123}}');
        Product2 p = OmieTestData.servico('SRV1');
        insert p;

        Test.startTest();
        OmieServicoService.consultarPorIdSalesforce(p.Id);
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('cCodIntServ'), 'Deve consultar pela chave.');
        Assert.isTrue(m.requisicoes[0].contains(String.valueOf(p.Id)), 'O Id deve ir no param.');
    }

    @IsTest
    static void upsertIncluirEAlterarUsamSeusProprios() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        OmieServicoService.incluir(new OmieServico());
        OmieServicoService.alterar(new OmieServico());
        OmieServico.StatusResponse s = OmieServicoService.upsertServico(new OmieServico());
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('IncluirCadastroServico'), 'O primeiro é Incluir.');
        Assert.isTrue(m.requisicoes[1].contains('AlterarCadastroServico'), 'O segundo é Alterar.');
        Assert.isTrue(m.requisicoes[2].contains('UpsertCadastroServico'), 'O terceiro é Upsert.');
        Assert.isTrue(s.isSucesso(), 'cCodStatus 0 com nCodServ é sucesso.');
    }

    @IsTest
    static void statusSemCodigoNaoESucesso() {
        OmieServico.StatusResponse s = new OmieServico.StatusResponse();
        Assert.isFalse(s.isSucesso(), 'Sem nCodServ não há sucesso.');

        s.nCodServ   = 1L;
        s.cCodStatus = '101';
        Assert.isFalse(s.isSucesso(), 'cCodStatus diferente de 0 é falha.');

        s.cCodStatus = '0';
        Assert.isTrue(s.isSucesso(), 'Com código e status 0 é sucesso.');
    }

    /**
     * A identificação chega em intListar na listagem e em intEditar no que nós
     * montamos. Os atalhos existem para ninguém repetir esse if.
     */
    @IsTest
    static void atalhosLeemOsDoisBlocosDeIdentificacao() {
        OmieServico daListagem = new OmieServico();
        daListagem.intListar = new OmieServico.Chave('chave-listar', 111L);
        Assert.areEqual(111L, daListagem.codigoOmie(), 'Deve ler do intListar.');
        Assert.areEqual('chave-listar', daListagem.chaveIntegracao(), 'Deve ler do intListar.');

        OmieServico paraGravar = new OmieServico();
        paraGravar.intEditar = new OmieServico.Chave('chave-editar', 222L);
        Assert.areEqual(222L, paraGravar.codigoOmie(), 'Deve cair para o intEditar.');
        Assert.areEqual('chave-editar', paraGravar.chaveIntegracao(), 'Deve cair para o intEditar.');

        OmieServico vazio = new OmieServico();
        Assert.isNull(vazio.codigoOmie(), 'Sem bloco nenhum, null em vez de exceção.');
        Assert.isNull(vazio.chaveIntegracao(), 'Idem para a chave.');
        Assert.isNull(vazio.codigo(), 'E para o código.');
        Assert.isFalse(vazio.isInativo(), 'Sem info, o serviço não é considerado inativo.');
    }

    // -----------------------------------------------------------------
    private static Map<String, Object> primeiroParam(String requisicao) {
        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(requisicao);
        return (Map<String, Object>) ((List<Object>) envelope.get('param'))[0];
    }
}