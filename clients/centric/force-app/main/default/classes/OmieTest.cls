public class OmieTest {

    private static final String PATH_PRODUTOS = 'https://app.omie.com.br/api/v1/geral/produtos/';
    private static final Integer TIMEOUT_MS = 60000;

    // ---------- Wrappers de resposta ----------
    public class ListaProdutosResult {
        public Integer pagina;
        public Integer total_de_paginas;
        public Integer registros;
        public Integer total_de_registros;
        public List<Produto> produto_servico_cadastro;
    }

    public class Produto {
        public Long    codigo_produto;              // ID interno Omie
        public String  codigo_produto_integracao;   // chave de integração
        public String  codigo;                      // SKU
        public String  descricao;
        public String  descr_detalhada;
        public String  unidade;
        public String  ncm;
        public String  ean;
        public String  marca;
        public Decimal valor_unitario;
        public String  tipoItem;
        public String  inativo;                     // 'S' / 'N'
    }

    public class OmieException extends Exception {}

    // ---------- Métodos públicos ----------
    public static ListaProdutosResult listarProdutos(Integer pagina, Integer registrosPorPagina) {
        Map<String, Object> param = new Map<String, Object>{
            'pagina'                 => pagina,
            'registros_por_pagina'   => registrosPorPagina,
            'apenas_importado_api'   => 'N',
            'filtrar_apenas_omiepdv' => 'N'
        };
        String body = callOmie('ListarProdutos', param);
        return (ListaProdutosResult) JSON.deserialize(body, ListaProdutosResult.class);
    }

    public static Produto consultarPorCodigoOmie(Long codigoProduto) {
        String body = callOmie('ConsultarProduto',
            new Map<String, Object>{ 'codigo_produto' => codigoProduto });
        return (Produto) JSON.deserialize(body, Produto.class);
    }

    public static Produto consultarPorSku(String codigo) {
        String body = callOmie('ConsultarProduto',
            new Map<String, Object>{ 'codigo' => codigo });
        return (Produto) JSON.deserialize(body, Produto.class);
    }

    // ---------- Callout ----------
    private static String callOmie(String metodo, Map<String, Object> param) {
        //Omie_Config__mdt cfg = Omie_Config__mdt.getInstance('Default');

        Map<String, Object> payload = new Map<String, Object>{
            'call'       => metodo,
            'app_key'    => '882386450946',
            'app_secret' => '5f5a55965f015de5dcf8ebe469da645a',
            'param'      => new List<Object>{ param }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(PATH_PRODUTOS);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_MS);
        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            // Erros da Omie vêm como {"faultstring":"...","faultcode":"..."}
            String msg = res.getBody();
            try {
                Map<String, Object> err =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (err.containsKey('faultstring')) {
                    msg = (String) err.get('faultstring');
                }
            } catch (Exception ignore) { /* corpo não-JSON */ }
            throw new OmieException(
                'Omie ' + metodo + ' falhou [HTTP ' + res.getStatusCode() + ']: ' + msg);
        }
        return res.getBody();
    }
}