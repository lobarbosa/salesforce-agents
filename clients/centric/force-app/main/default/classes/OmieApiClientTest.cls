/**
 * Testes do OmieApiClient: envelope da requisição, tradução de erro HTTP e a
 * tolerância ao vazio que o Omie manda em campo numérico.
 */
@IsTest
private class OmieApiClientTest {

    @IsTest
    static void envelopeLevaCallEParamESuprimeNulos() {
        OmieTestData.credenciais();            // buildBody direto não passa pelo instalar()
        OmieProduto p = new OmieProduto();
        p.codigo = 'SKU1';                     // só este campo preenchido

        String body = OmieApiClient.buildBody('ListarProdutos', p);

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(body);
        Assert.areEqual('ListarProdutos', envelope.get('call'), 'O call deve ir no envelope.');
        Assert.isTrue(envelope.get('param') instanceof List<Object>,
            'O param vai como lista, é o formato do Omie.');

        List<Object> param = (List<Object>) envelope.get('param');
        Map<String, Object> primeiro = (Map<String, Object>) param[0];
        Assert.areEqual('SKU1', primeiro.get('codigo'), 'O campo preenchido deve ir.');
        Assert.isFalse(primeiro.containsKey('descricao'),
            'Campo nulo não deve ser enviado: é o que permite usar o mesmo DTO para ler e escrever.');
    }

    /**
     * As credenciais vêm do Omie_Config__mdt, e o envelope precisa levá-las — é o
     * que autentica a chamada.
     *
     * O que NÃO dá para cobrir aqui: a leitura do metadata em si e o erro de
     * registro ausente. Omie_Config__mdt.getInstance lê a org de verdade, sem
     * ponto de injeção, então o resultado dependeria de qual org roda a suíte. É
     * justamente por isso que o client expõe o credenciaisMock.
     */
    @IsTest
    static void credenciaisConfiguradasVaoNoEnvelope() {
        OmieTestData.credenciais();

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(
            OmieApiClient.buildBody('ListarProdutos', null));

        Assert.areEqual(OmieTestData.APP_KEY, envelope.get('app_key'),
            'A app_key configurada deve ir no envelope.');
        Assert.areEqual(OmieTestData.APP_SECRET, envelope.get('app_secret'),
            'O app_secret configurado deve ir no envelope.');
    }

    @IsTest
    static void postDevolveCorpoQuandoHttp200() {
        OmieTestData.instalar('{"ok":true}');

        Test.startTest();
        String body = OmieApiClient.post(OmieApiClient.ENDPOINT_PRODUTOS, 'ListarProdutos', null);
        Test.stopTest();

        Assert.areEqual('{"ok":true}', body, 'O corpo deve voltar intacto.');
    }

    @IsTest
    static void erroDeNegocioViraExcecaoComFaultstring() {
        OmieTestData.instalarErro(500, 'ERROR: Produto nao cadastrado!');

        Test.startTest();
        try {
            OmieApiClient.post(OmieApiClient.ENDPOINT_PRODUTOS, 'ConsultarProduto', null);
            Assert.fail('Deveria ter lançado OmieException.');
        } catch (OmieApiClient.OmieException e) {
            Assert.areEqual(500, e.statusCode, 'O status HTTP deve ser preservado.');
            Assert.areEqual('ERROR: Produto nao cadastrado!', e.faultString,
                'A faultstring do Omie deve ser extraída.');
            Assert.isFalse(e.bloqueante, 'Erro de dado não bloqueia a integração.');
        }
        Test.stopTest();
    }

    @IsTest
    static void rateLimitEBloqueioMarcamBloqueante() {
        for (Integer status : new List<Integer>{ 425, 429 }) {
            OmieTestData.instalarErro(status, 'bloqueado');
            try {
                OmieApiClient.post(OmieApiClient.ENDPOINT_PRODUTOS, 'ListarProdutos', null);
                Assert.fail('Deveria ter lançado OmieException para HTTP ' + status);
            } catch (OmieApiClient.OmieException e) {
                Assert.isTrue(e.bloqueante,
                    'HTTP ' + status + ' precisa parar o lote, não só falhar o item.');
            }
        }
    }

    @IsTest
    static void corpoNaoJsonNaoQuebraATraducaoDoErro() {
        OmieTestData.instalar(new List<String>{ '<html>Gateway Timeout</html>' }, 504);

        Test.startTest();
        try {
            OmieApiClient.post(OmieApiClient.ENDPOINT_PRODUTOS, 'ListarProdutos', null);
            Assert.fail('Deveria ter lançado OmieException.');
        } catch (OmieApiClient.OmieException e) {
            Assert.areEqual(504, e.statusCode, 'O status deve chegar mesmo sem corpo JSON.');
            Assert.isNull(e.faultString, 'Sem JSON não há faultstring para extrair.');
        }
        Test.stopTest();
    }

    /**
     * O Omie usa string vazia para "não preenchido", inclusive em campo
     * numérico. O parse tipado estoura, então o client limpa e repete.
     */
    @IsTest
    static void campoNumericoVazioNaoQuebraOParse() {
        OmieTestData.instalar(
            '{"intListar":{"nCodServ":123},"cabecalho":{"cCodigo":"S1","nPrecoUnit":""}}');

        Test.startTest();
        OmieServico s = (OmieServico) OmieApiClient.postAndParse(
            OmieApiClient.ENDPOINT_SERVICOS, 'ConsultarCadastroServico', null, OmieServico.class);
        Test.stopTest();

        Assert.areEqual(123, s.codigoOmie(), 'O resto do JSON deve ser aproveitado.');
        Assert.areEqual('S1', s.codigo(), 'O código deve chegar.');
        Assert.isNull(s.cabecalho.nPrecoUnit,
            'Numérico vazio deve virar null, que é o que o vazio significa.');
    }
}