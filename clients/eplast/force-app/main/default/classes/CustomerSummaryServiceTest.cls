/**
 * CustomerSummaryServiceTest
 *
 * Cobre o SCAFFOLD BLOQUEADO de `CustomerSummaryService` (ver cabecalho daquela
 * classe e demandas/EPLAST-23/04-plano-build.md). Como a logica de consolidacao
 * real depende de respostas de negocio/compliance ainda nao registradas (D2-D6,
 * 03-design.md secao 7), nao ha caminho feliz de consolidacao para testar ainda --
 * o unico comportamento existente e falhar de forma explicita e previsivel.
 *
 * Cenarios cobertos (adaptados ao que a classe realmente faz hoje):
 *   1. Lista vazia -> devolve lista vazia, sem excecao (nada a processar).
 *   2. Request unico valido -> lanca CustomerSummaryPendingDecisionException com a
 *      mensagem citando D2-D6.
 *   3. Bulk de 200 requests validos -> mesma excecao, provando que o bloqueio e
 *      consistente em volume e que nao ha SOQL/DML (zero chamadas aos governadores
 *      mesmo com 200 registros).
 *   4. accountId nulo -> IllegalArgumentException (erro de uso, nao de negocio),
 *      distinto do bloqueio de pendencia.
 *   5. Usuario com perfil de acesso restrito (System.runAs) -> mesmo
 *      comportamento de bloqueio, porque a classe ainda nao executa nenhuma
 *      consulta dependente de FLS/OLS. Isso prova que o scaffold nao vaza nem
 *      depende de permissao de dado nenhuma hoje; o teste de permissao real
 *      (ex. runAs sem acesso a Case) soh faz sentido quando a consolidacao por
 *      categoria for implementada.
 *
 * Sem SeeAllData. Dados de teste via Test.createStandardSalesforceSite... nao
 * aplicavel aqui: a classe nao faz SOQL, entao nenhum registro e necessario para
 * os cenarios de bloqueio -- so o usuario de teste do cenario 5 precisa existir.
 */
@IsTest
private class CustomerSummaryServiceTest {

    @IsTest
    static void deveDevolverListaVaziaQuandoNaoHaRequests() {
        Test.startTest();
        List<CustomerSummaryService.CustomerSummaryResult> resultados =
            CustomerSummaryService.resumirCliente(new List<CustomerSummaryService.CustomerSummaryRequest>());
        Test.stopTest();

        System.assertNotEquals(null, resultados, 'Deveria devolver uma lista, nunca null.');
        System.assertEquals(0, resultados.size(), 'Lista de entrada vazia deve devolver lista de saida vazia.');
    }

    @IsTest
    static void deveBloquearRequestUnicoValidoComExcecaoDePendenciaDeNegocio() {
        CustomerSummaryService.CustomerSummaryRequest request = new CustomerSummaryService.CustomerSummaryRequest();
        request.accountId = fakeAccountId();

        Exception erroCapturado;
        Test.startTest();
        try {
            CustomerSummaryService.resumirCliente(
                new List<CustomerSummaryService.CustomerSummaryRequest>{ request }
            );
        } catch (Exception e) {
            erroCapturado = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, erroCapturado, 'Deveria lancar excecao de pendencia de negocio.');
        System.assert(
            erroCapturado instanceof CustomerSummaryService.CustomerSummaryPendingDecisionException,
            'Tipo de excecao esperado: CustomerSummaryPendingDecisionException. Recebido: ' + erroCapturado
        );
        System.assertEquals(
            CustomerSummaryService.MSG_BLOQUEADO_PENDENCIA_NEGOCIO,
            erroCapturado.getMessage(),
            'A mensagem deve citar explicitamente as pendencias D2-D6.'
        );
    }

    @IsTest
    static void deveBloquearLoteDe200RequestsSemSoqlNemDml() {
        List<CustomerSummaryService.CustomerSummaryRequest> lote =
            new List<CustomerSummaryService.CustomerSummaryRequest>();
        for (Integer i = 0; i < 200; i++) {
            CustomerSummaryService.CustomerSummaryRequest request = new CustomerSummaryService.CustomerSummaryRequest();
            request.accountId = fakeAccountId();
            lote.add(request);
        }

        Integer queriesAntes = Limits.getQueries();
        Integer dmlAntes = Limits.getDmlStatements();

        Exception erroCapturado;
        Test.startTest();
        try {
            CustomerSummaryService.resumirCliente(lote);
        } catch (Exception e) {
            erroCapturado = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, erroCapturado, 'Lote de 200 tambem deve ser bloqueado.');
        System.assert(
            erroCapturado instanceof CustomerSummaryService.CustomerSummaryPendingDecisionException,
            'Tipo de excecao esperado: CustomerSummaryPendingDecisionException. Recebido: ' + erroCapturado
        );
        System.assertEquals(
            queriesAntes,
            Limits.getQueries(),
            'O scaffold bloqueado nao deve executar nenhum SOQL, nem em lote.'
        );
        System.assertEquals(
            dmlAntes,
            Limits.getDmlStatements(),
            'O scaffold bloqueado nao deve executar nenhum DML, nem em lote.'
        );
    }

    @IsTest
    static void deveLancarIllegalArgumentQuandoAccountIdEhNulo() {
        CustomerSummaryService.CustomerSummaryRequest request = new CustomerSummaryService.CustomerSummaryRequest();
        request.accountId = null;

        Exception erroCapturado;
        Test.startTest();
        try {
            CustomerSummaryService.resumirCliente(
                new List<CustomerSummaryService.CustomerSummaryRequest>{ request }
            );
        } catch (Exception e) {
            erroCapturado = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, erroCapturado, 'accountId nulo deve lancar excecao.');
        System.assert(
            erroCapturado instanceof IllegalArgumentException,
            'accountId nulo deve lancar IllegalArgumentException (erro de uso), nao o bloqueio de negocio. Recebido: ' + erroCapturado
        );
    }

    @IsTest
    static void deveBloquearIgualmenteParaUsuarioComAcessoRestrito() {
        Profile perfilMinimo = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User usuarioRestrito = new User(
            Alias = 'eplcsr',
            Email = 'customer.summary.scaffold.test@eplast.invalid',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Teste Scaffold Resumo Cliente',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = perfilMinimo.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            UserName = 'customer.summary.scaffold.test@eplast.invalid.' + Crypto.getRandomInteger()
        );
        insert usuarioRestrito;

        CustomerSummaryService.CustomerSummaryRequest request = new CustomerSummaryService.CustomerSummaryRequest();
        request.accountId = fakeAccountId();

        Exception erroCapturado;
        Test.startTest();
        System.runAs(usuarioRestrito) {
            try {
                CustomerSummaryService.resumirCliente(
                    new List<CustomerSummaryService.CustomerSummaryRequest>{ request }
                );
            } catch (Exception e) {
                erroCapturado = e;
            }
        }
        Test.stopTest();

        System.assertNotEquals(null, erroCapturado, 'Mesmo sob perfil restrito, o scaffold deve bloquear.');
        System.assert(
            erroCapturado instanceof CustomerSummaryService.CustomerSummaryPendingDecisionException,
            'O bloqueio de pendencia de negocio independe do perfil, porque nenhuma consulta de dado ainda existe. Recebido: ' + erroCapturado
        );
    }

    /**
     * Id de Account sintetico (18 caracteres, prefixo '001'), sem nenhuma insercao
     * de registro: a classe-alvo nao faz SOQL, entao nenhum Account precisa existir
     * de fato para estes cenarios. Construido por concatenacao (em vez de literal)
     * para eliminar risco de erro de contagem de caracteres.
     */
    private static Id fakeAccountId() {
        String zeros = '';
        for (Integer i = 0; i < 12; i++) {
            zeros += '0';
        }
        return Id.valueOf('001' + zeros + 'AAA');
    }
}
