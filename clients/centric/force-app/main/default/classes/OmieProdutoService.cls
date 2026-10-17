/**
 * Operações do endpoint /geral/produtos/ do Omie.
 *
 * Camada fina: traduz "o que eu quero fazer" em uma chamada ao OmieApiClient.
 * Não faz SOQL, não faz DML, não conhece Product2 — isso é do Mapper e do
 * Queueable. Assim esta classe fica testável e reutilizável.
 */
public with sharing class OmieProdutoService {

    private static final String EP = OmieApiClient.ENDPOINT_PRODUTOS;

    // -----------------------------------------------------------------
    // Nomes dos "call". Centralizados: se o Omie renomear, muda só aqui.
    // -----------------------------------------------------------------
    private static final String CALL_LISTAR      = 'ListarProdutos';
    private static final String CALL_CONSULTAR   = 'ConsultarProduto';
    private static final String CALL_INCLUIR     = 'IncluirProduto';
    private static final String CALL_ALTERAR     = 'AlterarProduto';
    private static final String CALL_UPSERT      = 'UpsertProduto';

    // -----------------------------------------------------------------
    // Limites do Omie
    // -----------------------------------------------------------------
    /** Máximo de registros por página em ListarProdutos (limite oficial). */
    public static final Integer MAX_REGISTROS_PAGINA = 100;


    // =================================================================
    // CONSULTA
    // =================================================================

    /**
     * Filtros de ListarProdutos. Os nomes são os do JSON do Omie;
     * o que ficar null não é enviado.
     */
    public class Filtro {
        public Integer pagina                 = 1;
        public Integer registros_por_pagina   = MAX_REGISTROS_PAGINA;
        public String  apenas_importado_api   = 'N';
        public String  filtrar_apenas_omiepdv = 'N';
        public String  exibir_caracteristicas;      // 'S' para trazer o array caracteristicas
        public String  filtrar_por_status;          // 'A' ativo / 'I' inativo
        public String  filtrar_por_data_de;         // dd/MM/yyyy
        public String  filtrar_por_data_ate;        // dd/MM/yyyy
        public String  filtrar_por_hora_de;         // HH:mm:ss
        public String  filtrar_por_hora_ate;
        public String  filtrar_apenas_inclusao;     // 'S'
        public String  filtrar_apenas_alteracao;    // 'S'
        public Long    filtrar_apenas_familia;

        public Filtro() {}

        public Filtro(Integer pagina, Integer porPagina) {
            this.pagina = pagina;
            this.registros_por_pagina = porPagina;
        }

        /** Carga incremental: só o que mudou desde uma data. */
        public Filtro alteradosDesde(Datetime dt) {
            this.filtrar_por_data_de = dt.format('dd/MM/yyyy');
            this.filtrar_por_hora_de = dt.format('HH:mm:ss');
            return this;
        }
    }

    /** Uma página do catálogo, com todos os campos do produto preenchidos. */
    public static OmieProduto.ListaResponse listar(Filtro f) {
        if (f == null) f = new Filtro();
        if (f.pagina == null || f.pagina < 1) f.pagina = 1;
        if (f.registros_por_pagina == null || f.registros_por_pagina > MAX_REGISTROS_PAGINA) {
            f.registros_por_pagina = MAX_REGISTROS_PAGINA;   // o Omie rejeita acima de 100
        }
        return (OmieProduto.ListaResponse) OmieApiClient.postAndParse(
            EP, CALL_LISTAR, f, OmieProduto.ListaResponse.class);
    }

    public static OmieProduto.ListaResponse listar(Integer pagina, Integer porPagina) {
        return listar(new Filtro(pagina, porPagina));
    }

    /**
     * Percorre TODAS as páginas de produtos ATIVOS do Omie.
     *
     * Uma página de 100 = um callout. Um catálogo de 5.000 produtos custa 50
     * callouts, ainda dentro dos 100 por transação do Salesforce. Acima disso,
     * pagine manualmente com listar(Filtro) em execuções separadas.
     */
    public static List<OmieProduto> listarTodosAtivos() {
        List<OmieProduto> todos = new List<OmieProduto>();

        Filtro f = new Filtro();
        //f.filtrar_por_status = 'A';

        Integer totalPaginas = 1;
        do {
            OmieProduto.ListaResponse r = listar(f);
            if (r == null || r.produto_servico_cadastro == null) break;

            todos.addAll(r.produto_servico_cadastro);
            totalPaginas = (r.total_de_paginas == null) ? 1 : r.total_de_paginas;
            f.pagina++;
        } while (f.pagina <= totalPaginas);

        return todos;
    }

    public static OmieProduto consultarPorCodigoOmie(Long codigoProduto) {
        return consultar(new Map<String, Object>{ 'codigo_produto' => codigoProduto });
    }

    public static OmieProduto consultarPorSku(String codigo) {
        return consultar(new Map<String, Object>{ 'codigo' => codigo });
    }

    /** Consulta pelo Id do Product2 (usado como codigo_produto_integracao). */
    public static OmieProduto consultarPorIdSalesforce(Id productId) {
        return consultar(new Map<String, Object>{
            'codigo_produto_integracao' => String.valueOf(productId) });
    }

    private static OmieProduto consultar(Map<String, Object> chave) {
        return (OmieProduto) OmieApiClient.postAndParse(
            EP, CALL_CONSULTAR, chave, OmieProduto.class);
    }


    // =================================================================
    // GRAVAÇÃO UNITÁRIA
    // =================================================================

    public static OmieProduto.StatusResponse incluir(OmieProduto p) {
        return gravar(CALL_INCLUIR, p);
    }

    public static OmieProduto.StatusResponse alterar(OmieProduto p) {
        return gravar(CALL_ALTERAR, p);
    }

    /**
     * Inclui se não existir, altera se já existir (pelo codigo_produto_integracao).
     *
     * É o ÚNICO caminho de gravação disponível: o Omie depreciou os métodos de
     * lote do endpoint /geral/produtos/ (UpsertProdutoLote e o retorno
     * produto_servico_lote_response). Quem precisa enviar muitos produtos chama
     * este método uma vez por produto e respeita os 100 callouts por transação
     * do Salesforce — é o que o OmieProdutoSyncQueueable faz.
     */
    public static OmieProduto.StatusResponse upsertProduto(OmieProduto p) {
        return gravar(CALL_UPSERT, p);
    }

    private static OmieProduto.StatusResponse gravar(String metodo, OmieProduto p) {
        return (OmieProduto.StatusResponse) OmieApiClient.postAndParse(
            EP, metodo, p, OmieProduto.StatusResponse.class);
    }
}