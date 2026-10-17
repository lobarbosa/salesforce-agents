@isTest
private class AgentforceControllerTest {

    private static final String FAKE_SESSION_ID    = 'fake-session-id-12345';
    private static final String FAKE_AGENT_RESPONSE = 'Ola! Como posso te ajudar?';
    private static final String FAKE_TOKEN          = 'eyJfake.jwt.token';

    // Resposta do token OAuth (sempre primeiro callout)
    private static HttpResponse tokenResponse() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token":"' + FAKE_TOKEN + '","token_format":"jwt","token_type":"Bearer"}');
        return res;
    }

    // Mock generico que responde token na 1a chamada e delega a 2a para subclasse
    private abstract class BaseMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            if (callCount == 1) {
                // Primeira chamada: sempre obtencao do token
                System.assert(req.getEndpoint().contains('/services/oauth2/token'), 'Primeiro callout deve ser para o token');
                return tokenResponse();
            }
            return respondSecond(req);
        }
        protected abstract HttpResponse respondSecond(HttpRequest req);
    }

    // Mock: createSession com sucesso
    private class MockCreateSessionSuccess extends BaseMock {
        protected override HttpResponse respondSecond(HttpRequest req) {
            System.assert(req.getEndpoint().contains('/agents/'), 'Endpoint deve conter /agents/');
            System.assert(req.getEndpoint().contains('/sessions'), 'Endpoint deve conter /sessions');
            System.assertEquals('POST', req.getMethod(), 'Metodo deve ser POST');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"sessionId":"' + FAKE_SESSION_ID + '"}');
            return res;
        }
    }

    // Mock: sendMessage com sucesso
    private class MockSendMessageSuccess extends BaseMock {
        protected override HttpResponse respondSecond(HttpRequest req) {
            System.assert(req.getEndpoint().contains('/messages'), 'Endpoint deve conter /messages');
            System.assertEquals('POST', req.getMethod(), 'Metodo deve ser POST');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"messages":[{"type":"Text","text":"' + FAKE_AGENT_RESPONSE + '"}]}');
            return res;
        }
    }

    // Mock: sendMessage com resposta vazia
    private class MockSendMessageEmptyResponse extends BaseMock {
        protected override HttpResponse respondSecond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"messages":[]}');
            return res;
        }
    }

    // Mock: erro HTTP no segundo callout (API)
    private class MockApiError extends BaseMock {
        protected override HttpResponse respondSecond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad Request"}');
            return res;
        }
    }

    // Mock: erro no token (falha no primeiro callout)
    private class MockTokenError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error":"invalid_client"}');
            return res;
        }
    }

    // Mock: DELETE com sucesso
    private class MockDeleteSuccess extends BaseMock {
        protected override HttpResponse respondSecond(HttpRequest req) {
            System.assertEquals('DELETE', req.getMethod(), 'Metodo deve ser DELETE');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(204);
            res.setBody('');
            return res;
        }
    }

    // ─── createSession ────────────────────────────────────────────────────────

    @isTest
    static void testCreateSession_Success() {
        Test.setMock(HttpCalloutMock.class, new MockCreateSessionSuccess());
        Test.startTest();
        String sessionId = AgentforceController.createSession();
        Test.stopTest();
        System.assertEquals(FAKE_SESSION_ID, sessionId, 'Session ID deve ser retornado corretamente');
    }

    @isTest
    static void testCreateSession_TokenError() {
        Test.setMock(HttpCalloutMock.class, new MockTokenError());
        Test.startTest();
        try {
            AgentforceController.createSession();
            System.assert(false, 'Deveria ter lancado excecao');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Excecao deve ter mensagem');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSession_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockApiError());
        Test.startTest();
        try {
            AgentforceController.createSession();
            System.assert(false, 'Deveria ter lancado excecao');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Excecao deve ter mensagem');
        }
        Test.stopTest();
    }

    // ─── sendMessage ──────────────────────────────────────────────────────────

    @isTest
    static void testSendMessage_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSendMessageSuccess());
        Test.startTest();
        String response = AgentforceController.sendMessage(FAKE_SESSION_ID, 'Ola agente!');
        Test.stopTest();
        System.assertEquals(FAKE_AGENT_RESPONSE, response, 'Resposta do agente deve ser retornada corretamente');
    }

    @isTest
    static void testSendMessage_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new MockSendMessageEmptyResponse());
        Test.startTest();
        String response = AgentforceController.sendMessage(FAKE_SESSION_ID, 'Ola agente!');
        Test.stopTest();
        System.assertEquals('Sem resposta do agente.', response, 'Deve retornar mensagem padrao quando resposta vazia');
    }

    @isTest
    static void testSendMessage_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockApiError());
        Test.startTest();
        try {
            AgentforceController.sendMessage(FAKE_SESSION_ID, 'Ola agente!');
            System.assert(false, 'Deveria ter lancado excecao');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Excecao deve ter mensagem');
        }
        Test.stopTest();
    }

    // ─── endSession ───────────────────────────────────────────────────────────

    @isTest
    static void testEndSession_Success() {
        Test.setMock(HttpCalloutMock.class, new MockDeleteSuccess());
        Test.startTest();
        AgentforceController.endSession(FAKE_SESSION_ID);
        Test.stopTest();
        System.assert(true, 'endSession deve executar sem erros');
    }

    @isTest
    static void testEndSession_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockApiError());
        Test.startTest();
        AgentforceController.endSession(FAKE_SESSION_ID);
        Test.stopTest();
        System.assert(true, 'endSession deve engolir erros sem lancar excecao');
    }
}