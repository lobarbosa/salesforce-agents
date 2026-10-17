/**
 * Ferramentas compartilhadas pelos testes da integração Omie.
 *
 * Existe para que nenhum teste precise repetir mock de callout nem montagem de
 * Product2. Quem mexer no de-para altera a fábrica aqui e todos os testes
 * acompanham.
 */
@IsTest
public class OmieTestData {

    /**
     * Devolve os corpos na ordem em que foram enfileirados; o último se repete.
     *
     * O "último se repete" é o que deixa um teste de paginação enfileirar UMA
     * resposta em vez de uma por página.
     */
    public class Mock implements HttpCalloutMock {
        private List<String> corpos;
        private Integer status;
        public Integer chamadas = 0;
        public List<String> requisicoes = new List<String>();

        public Mock(List<String> corpos, Integer status) {
            this.corpos = corpos;
            this.status = status;
        }

        public HttpResponse respond(HttpRequest req) {
            requisicoes.add(req.getBody());
            HttpResponse res = new HttpResponse();
            res.setStatusCode(status);
            res.setBody(corpos[Math.min(chamadas, corpos.size() - 1)]);
            chamadas++;
            return res;
        }
    }

    public static Mock instalar(String corpo) {
        return instalar(new List<String>{ corpo }, 200);
    }

    public static Mock instalar(List<String> corpos) {
        return instalar(corpos, 200);
    }

    public static Mock instalar(List<String> corpos, Integer status) {
        credenciais();
        Mock m = new Mock(corpos, status);
        Test.setMock(HttpCalloutMock.class, m);
        return m;
    }

    public static final String APP_KEY    = 'app-key-de-teste';
    public static final String APP_SECRET = 'app-secret-de-teste';

    /**
     * Injeta credenciais falsas no client.
     *
     * Sem isto o client leria o Omie_Config__mdt da org, e a suíte passaria a
     * depender de um registro de metadata existir com o DeveloperName certo —
     * verde nesta sandbox, vermelha numa scratch org. Teste não deve depender do
     * ambiente. Chamado pelo instalar(), então todo teste de callout já vem
     * coberto; só quem exercita o buildBody direto precisa chamar à mão.
     */
    public static void credenciais() {
        OmieApiClient.Credenciais c = new OmieApiClient.Credenciais();
        c.appKey    = APP_KEY;
        c.appSecret = APP_SECRET;
        OmieApiClient.credenciaisMock = c;
    }

    /** Erro de negócio do Omie: faultstring com o status HTTP dado. */
    public static Mock instalarErro(Integer status, String faultstring) {
        String corpo = '{"faultstring":"' + faultstring + '","faultcode":"SOAP-ENV:Client-101"}';
        return instalar(new List<String>{ corpo }, status);
    }


    // =================================================================
    // Fábricas de Product2
    // =================================================================

    /** Produto válido para o mapper: Unidade e MCN são lidos pelo toOmie. */
    public static Product2 produto(String codigo) {
        return new Product2(
            Name        = 'Produto ' + codigo,
            ProductCode = codigo,
            Description = 'Descrição de ' + codigo,
            Family      = 'Produto',
            IsActive    = true,
            Unidade__c  = 'un',
            MCN__c      = '85176255'
        );
    }

    /** Serviço válido para o OmieServicoMapper. */
    public static Product2 servico(String codigo) {
        return new Product2(
            Name        = 'Serviço ' + codigo,
            ProductCode = codigo,
            Description = 'Descrição de ' + codigo,
            Family      = OmieServicoMapper.FAMILY_SERVICO,
            IsActive    = true,
            Valor__c    = 250
        );
    }


    // =================================================================
    // Corpos de resposta do Omie
    // =================================================================

    /** Retorno de ListarProdutos com um produto. */
    public static String listaProdutos(Integer totalPaginas, Long codigoProduto,
                                       String chaveIntegracao, String codigo) {
        return '{"pagina":1,"total_de_paginas":' + totalPaginas + ',"registros":1,'
             + '"total_de_registros":1,"produto_servico_cadastro":['
             + '{"codigo_produto":' + codigoProduto
             + ',"codigo_produto_integracao":"' + chaveIntegracao + '"'
             + ',"codigo":"' + codigo + '","descricao":"Produto","inativo":"N"}]}';
    }

    /** Retorno de IncluirProduto / UpsertProduto. */
    public static String statusProduto(Long codigoProduto, String codigoStatus, String descricao) {
        return '{"codigo_produto":' + codigoProduto
             + ',"codigo_status":"' + codigoStatus + '"'
             + ',"descricao_status":"' + descricao + '"}';
    }

    /** Retorno de ListarCadastroServico com um serviço. */
    public static String listaServicos(Integer totalPaginas, Long nCodServ,
                                       String cCodIntServ, String cCodigo) {
        return '{"nPagina":1,"nTotPaginas":' + totalPaginas + ',"nRegistros":1,'
             + '"nTotRegistros":1,"cadastros":['
             + '{"intListar":{"cCodIntServ":"' + cCodIntServ + '","nCodServ":' + nCodServ + '},'
             + '"cabecalho":{"cCodigo":"' + cCodigo + '","cDescricao":"Serviço","nPrecoUnit":250},'
             + '"info":{"inativo":"N"}}]}';
    }

    /** Retorno de Incluir / Alterar / UpsertCadastroServico. */
    public static String statusServico(Long nCodServ, String cCodStatus, String descricao) {
        return '{"nCodServ":' + nCodServ
             + ',"cCodStatus":"' + cCodStatus + '"'
             + ',"cDescStatus":"' + descricao + '"}';
    }
}