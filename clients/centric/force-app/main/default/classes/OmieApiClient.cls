/**
 * Cliente HTTP genérico das APIs REST do Omie.
 *
 * Responsabilidade única: montar o envelope { call, app_key, app_secret, param },
 * executar o callout e traduzir erro HTTP em exceção tipada.
 * Não conhece Produto, Cliente ou Pedido -> serve para qualquer endpoint do Omie.
 */
public with sharing class OmieApiClient {

    // ------------------------------------------------------------------
    // Endpoints (acrescente novos conforme a integração crescer)
    // ------------------------------------------------------------------
    public static final String ENDPOINT_PRODUTOS = 'https://app.omie.com.br/api/v1/geral/produtos/';//'callout:Omie_API/v1/geral/produtos/';
    public static final String ENDPOINT_CLIENTES = 'https://app.omie.com.br/api/v1/geral/clientes/';//'callout:Omie_API/v1/geral/clientes/';
    public static final String ENDPOINT_SERVICOS = 'https://app.omie.com.br/api/v1/servicos/servico/';

    /**
     * 20s por callout. O Salesforce permite no máximo 120s de tempo TOTAL de
     * callout por transação, então timeout curto garante que várias chamadas
     * caibam na mesma execução sem estourar o limite.
     */
    private static final Integer TIMEOUT_MS = 20000;

    // ------------------------------------------------------------------
    // Exceção
    // ------------------------------------------------------------------
    public class OmieException extends Exception {
        public Integer statusCode;
        public String  faultCode;
        public String  faultString;
        /** true quando o Omie aplicou rate limit / bloqueio: pare o lote imediatamente. */
        public Boolean bloqueante = false;
    }

    // ------------------------------------------------------------------
    // API pública
    // ------------------------------------------------------------------

    /**
     * Executa uma chamada e devolve o corpo bruto da resposta.
     *
     * @param endpoint uma das constantes ENDPOINT_*
     * @param metodo   nome do call (ex.: 'ListarProdutos')
     * @param param    objeto serializado como param[0] (Map ou DTO)
     */
    public static String post(String endpoint, String metodo, Object param) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_MS);
        req.setBody(buildBody(metodo, param));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw buildException(metodo, res);
    }

    /**
     * Executa a chamada e já desserializa no tipo esperado.
     *
     * Usa JSON.deserialize (NÃO deserializeStrict) de propósito: o Omie adiciona
     * campos novos nas respostas sem aviso, e o modo strict quebraria a integração.
     *
     * A segunda tentativa existe por outro hábito do Omie: mandar "" em campo
     * numérico. Só entra em ação quando a primeira falha, para não cobrar o
     * custo da limpeza das respostas que vêm bem formadas.
     */
    public static Object postAndParse(String endpoint, String metodo,
                                      Object param, System.Type tipoRetorno) {
        String body = post(endpoint, metodo, param);
        try {
            return JSON.deserialize(body, tipoRetorno);
        } catch (JSONException e) {
            return JSON.deserialize(semVazios(body), tipoRetorno);
        }
    }

    // ------------------------------------------------------------------
    // Interno
    // ------------------------------------------------------------------

    /**
     * O mesmo JSON, sem as chaves cujo valor é string vazia.
     *
     * O Omie usa "" para "não preenchido" mesmo em campo numérico — um
     * {"nIdNBS":""} faz o parse tipado estourar com 'For input string: ""'.
     * Removendo a chave, o campo fica null no DTO, que é exatamente o que "não
     * preenchido" quer dizer. Campo de texto não sente a diferença: '' e null
     * são ambos vazios para String.isBlank.
     */
    private static String semVazios(String body) {
        return JSON.serialize(semVazios(JSON.deserializeUntyped(body)));
    }

    /** Percorre mapas e listas aninhados; devolve o resto como está. */
    private static Object semVazios(Object valor) {
        if (valor instanceof Map<String, Object>) {
            Map<String, Object> limpo = new Map<String, Object>();
            for (String chave : ((Map<String, Object>) valor).keySet()) {
                Object v = ((Map<String, Object>) valor).get(chave);
                if (v instanceof String && String.isBlank((String) v)) continue;
                limpo.put(chave, semVazios(v));
            }
            return limpo;
        }
        if (valor instanceof List<Object>) {
            List<Object> itens = new List<Object>();
            for (Object v : (List<Object>) valor) itens.add(semVazios(v));
            return itens;
        }
        return valor;
    }

    @TestVisible
    private static String buildBody(String metodo, Object param) {
        Credenciais c = getCredenciais();

        Map<String, Object> envelope = new Map<String, Object>{
            'call'       => metodo,
            'app_key'    => c.appKey,
            'app_secret' => c.appSecret,
            'param'      => new List<Object>{ param }
        };

        // suppressApexObjectNulls = true: só vai para o Omie o que foi preenchido
        // no DTO. É o que permite usar o MESMO objeto OmieProduto para leitura
        // e escrita sem enviar dezenas de campos nulos.
        return JSON.serialize(envelope, true);
    }

    private static OmieException buildException(String metodo, HttpResponse res) {
        Integer sc = res.getStatusCode();
        String faultCode;
        String faultString;

        // Erros de negócio do Omie vêm como {"faultstring":"...","faultcode":"..."}
        try {
            Map<String, Object> err =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            faultString = (String) err.get('faultstring');
            faultCode   = (String) err.get('faultcode');
        } catch (Exception ignore) {
            // corpo não-JSON (HTML de proxy, timeout de gateway etc.)
        }

        String detalhe = String.isNotBlank(faultString) ? faultString : res.getBody();

        OmieException ex = new OmieException(
            'Omie ' + metodo + ' [HTTP ' + sc + '] ' + detalhe);
        ex.statusCode  = sc;
        ex.faultCode   = faultCode;
        ex.faultString = faultString;

        // 425 = bloqueio de 30 min por consumo indevido (10 requisições com erro)
        // 429 = rate limit estourado (240/min por IP+AppKey+Método)
        ex.bloqueante = (sc == 425 || sc == 429);

        return ex;
    }

    // ------------------------------------------------------------------
    // Credenciais (Custom Metadata Omie_Config__mdt, registro "Default")
    // ------------------------------------------------------------------
    public class Credenciais {
        public String appKey;
        public String appSecret;
    }

    /** Permite injetar credenciais falsas nos testes. */
    @TestVisible
    private static Credenciais credenciaisMock;

    private static Credenciais getCredenciais() {
        if (credenciaisMock != null) return credenciaisMock;

        Omie_Config__mdt cfg = Omie_Config__mdt.getInstance('Default');
        if (cfg == null) {
            throw new OmieException('Custom Metadata Omie_Config__mdt com DeveloperName "Default" não encontrado.');
        }

        Credenciais c = new Credenciais();
        c.appKey    = cfg.App_Key__c;
        c.appSecret = cfg.App_Secret__c;
        return c;
    }
}