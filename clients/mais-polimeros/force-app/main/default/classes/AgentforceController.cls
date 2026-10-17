public with sharing class AgentforceController {

    private static final String API_BASE = 'https://api.salesforce.com';

    private static Map<String, Object> getConfig() {
        return (Map<String, Object>) JSON.deserializeUntyped(System.Label.Agentforce_Config);
    }

    // Obtém token JWT via Client Credentials Flow do External Client App
    private static String getAccessToken(Map<String, Object> cfg) {
        String orgEndpoint    = (String) cfg.get('orgEndpoint');
        String consumerKey    = (String) cfg.get('consumerKey');
        String consumerSecret = (String) cfg.get('consumerSecret');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(orgEndpoint + '/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(15000);
        req.setBody(
            'grant_type=client_credentials' +
            '&client_id='     + EncodingUtil.urlEncode(consumerKey, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(consumerSecret, 'UTF-8')
        );

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('AgentforceController.getAccessToken status: ' + res.getStatusCode());
        System.debug('AgentforceController.getAccessToken body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) tokenMap.get('access_token');
        } else {
            throw new AuraHandledException('Erro ao obter token: ' + res.getBody());
        }
    }

    @AuraEnabled
    public static String createSession() {
        try {
            Map<String, Object> cfg = getConfig();
            String token    = getAccessToken(cfg);
            String agentId  = (String) cfg.get('agentId');
            String baseUrl  = (String) cfg.get('baseUrl');
            String endpoint = API_BASE + baseUrl + '/agents/' + agentId + '/sessions';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setTimeout(30000);

            Map<String, Object> body = new Map<String, Object>{
                'externalSessionKey' => 'session-' + UserInfo.getUserId() + '-' + System.currentTimeMillis(),
                'instanceConfig' => new Map<String, Object>{
                    'endpoint' => (String) cfg.get('orgEndpoint')
                },
                'streamingCapabilities' => new Map<String, Object>{
                    'chunkTypes' => new List<String>{ 'Text' }
                },
                'bypassUser' => true
            };

            req.setBody(JSON.serialize(body));

            System.debug('AgentforceController.createSession endpoint: ' + endpoint);
            System.debug('AgentforceController.createSession body: ' + JSON.serialize(body));

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('AgentforceController.createSession status: ' + res.getStatusCode());
            System.debug('AgentforceController.createSession body: ' + res.getBody());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) responseMap.get('sessionId');
            } else {
                throw new AuraHandledException('Erro ' + res.getStatusCode() + ': ' + res.getBody());
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Erro: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendMessage(String sessionId, String messageText) {
        try {
            Map<String, Object> cfg = getConfig();
            String token    = getAccessToken(cfg);
            String baseUrl  = (String) cfg.get('baseUrl');
            String endpoint = API_BASE + baseUrl + '/sessions/' + sessionId + '/messages';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setTimeout(60000);

            Map<String, Object> body = new Map<String, Object>{
                'message' => new Map<String, Object>{
                    'sequenceId' => 1,
                    'type'       => 'Text',
                    'text'       => messageText
                },
                'variables' => new List<Object>()
            };

            req.setBody(JSON.serialize(body));

            System.debug('AgentforceController.sendMessage endpoint: ' + endpoint);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('AgentforceController.sendMessage status: ' + res.getStatusCode());
            System.debug('AgentforceController.sendMessage response: ' + res.getBody());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> messages = (List<Object>) responseMap.get('messages');
                if (messages != null && !messages.isEmpty()) {
                    Map<String, Object> lastMessage = (Map<String, Object>) messages[messages.size() - 1];
                    // Tipo Text: campo 'text' direto
                    if (lastMessage.get('text') != null) {
                        return (String) lastMessage.get('text');
                    }
                    // Tipo Inform/outros: campo 'message'
                    if (lastMessage.get('message') != null) {
                        return (String) lastMessage.get('message');
                    }
                    // Fallback: staticContent.text
                    Map<String, Object> staticContent = (Map<String, Object>) lastMessage.get('staticContent');
                    if (staticContent != null && staticContent.get('text') != null) {
                        return (String) staticContent.get('text');
                    }
                }
                return 'Sem resposta do agente.';
            } else {
                throw new AuraHandledException('Erro ' + res.getStatusCode() + ': ' + res.getBody());
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Erro: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void endSession(String sessionId) {
        try {
            Map<String, Object> cfg = getConfig();
            String token    = getAccessToken(cfg);
            String baseUrl  = (String) cfg.get('baseUrl');
            String endpoint = API_BASE + baseUrl + '/sessions/' + sessionId;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('DELETE');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setTimeout(15000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('AgentforceController.endSession status: ' + res.getStatusCode());
        } catch (Exception e) {
            System.debug('Erro ao encerrar sessao: ' + e.getMessage());
        }
    }
}