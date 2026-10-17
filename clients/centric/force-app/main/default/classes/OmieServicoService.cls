/**
 * Operações do endpoint /servicos/servico/ do Omie.
 *
 * Mesmo papel do OmieProdutoService: traduz "o que eu quero fazer" em uma
 * chamada ao OmieApiClient. Não faz SOQL, não faz DML, não conhece Product2 —
 * isso é do Mapper e do Queueable.
 */
public with sharing class OmieServicoService {

    private static final String EP = OmieApiClient.ENDPOINT_SERVICOS;

    // -----------------------------------------------------------------
    // Nomes dos "call". Centralizados: se o Omie renomear, muda só aqui.
    // -----------------------------------------------------------------
    private static final String CALL_LISTAR    = 'ListarCadastroServico';
    private static final String CALL_CONSULTAR = 'ConsultarCadastroServico';
    private static final String CALL_INCLUIR   = 'IncluirCadastroServico';
    private static final String CALL_ALTERAR   = 'AlterarCadastroServico';
    private static final String CALL_UPSERT    = 'UpsertCadastroServico';

    /** Máximo de registros por página na listagem. */
    public static final Integer MAX_REGISTROS_PAGINA = 100;


    // =================================================================
    // CONSULTA
    // =================================================================

    /**
     * Filtros de ListarCadastroServico. Os nomes são os do JSON do Omie;
     * o que ficar null não é enviado.
     */
    public class Filtro {
        public Integer nPagina           = 1;
        public Integer nRegPorPagina     = MAX_REGISTROS_PAGINA;
        public String  cOrdenarPor;
        public String  cOrdemDecrescente;      // 'S' / 'N'
        public String  cDescricao;
        public String  cCodigo;
        public String  inativo;                // 'S' / 'N'
        public String  dInclusaoInicial;       // dd/MM/yyyy
        public String  dInclusaoFinal;
        public String  dAlteracaoInicial;
        public String  dAlteracaoFinal;

        public Filtro() {}

        public Filtro(Integer pagina, Integer porPagina) {
            this.nPagina       = pagina;
            this.nRegPorPagina = porPagina;
        }

        /** Carga incremental: só o que mudou desde uma data. */
        public Filtro alteradosDesde(Datetime dt) {
            this.dAlteracaoInicial = dt.format('dd/MM/yyyy');
            return this;
        }
    }

    /** Uma página do cadastro de serviços. */
    public static OmieServico.ListaResponse listar(Filtro f) {
        if (f == null) f = new Filtro();
        if (f.nPagina == null || f.nPagina < 1) f.nPagina = 1;
        if (f.nRegPorPagina == null || f.nRegPorPagina > MAX_REGISTROS_PAGINA) {
            f.nRegPorPagina = MAX_REGISTROS_PAGINA;
        }
        return (OmieServico.ListaResponse) OmieApiClient.postAndParse(
            EP, CALL_LISTAR, f, OmieServico.ListaResponse.class);
    }

    public static OmieServico.ListaResponse listar(Integer pagina, Integer porPagina) {
        return listar(new Filtro(pagina, porPagina));
    }

    /**
     * Lê uma FATIA de páginas dos serviços ativos e devolve só os códigos.
     *
     * Dois limites obrigam a fatiar, e os dois são por transação: 100 callouts
     * (uma página = um callout) e 6MB de heap. Por isso o método não tenta
     * percorrer o cadastro inteiro — quem precisa dele pede fatia por fatia,
     * uma transação por fatia, seguindo o proximaPagina do retorno.
     *
     * Dos cadastros só sobram os códigos: guardar os OmieServico completos, com
     * cabecalho, descricao, impostos e info, é o que estourava o heap.
     */
    public static Codigos codigosAtivos(Integer paginaInicial, Integer quantasPaginas) {
        Codigos c = new Codigos();

        Filtro f = new Filtro();
        f.inativo = 'N';

        Integer pagina = paginaInicial;
        Integer ultima = paginaInicial + quantasPaginas - 1;

        while (pagina <= ultima) {
            f.nPagina = pagina;
            OmieServico.ListaResponse r = listar(f);
            if (r == null || r.cadastros == null) break;

            for (OmieServico s : r.cadastros) c.adicionar(s);

            c.totalPaginas = (r.nTotPaginas == null) ? pagina : r.nTotPaginas;
            pagina++;
            if (pagina > c.totalPaginas) break;
        }

        // null = acabou o cadastro. É todo o estado que a paginação precisa.
        c.proximaPagina = (pagina > c.totalPaginas) ? null : pagina;
        return c;
    }

    /** O nCodServ dos serviços lidos, indexado pelas duas chaves de match. */
    public class Codigos {
        public Map<String, Long> porChaveIntegracao = new Map<String, Long>();
        public Map<String, Long> porCodigo          = new Map<String, Long>();
        public Integer lidos        = 0;
        public Integer totalPaginas = 0;
        public Integer proximaPagina;

        void adicionar(OmieServico s) {
            Long cod = s.codigoOmie();
            if (cod == null) return;

            lidos++;
            if (String.isNotBlank(s.chaveIntegracao())) porChaveIntegracao.put(s.chaveIntegracao(), cod);
            if (String.isNotBlank(s.codigo()))          porCodigo.put(s.codigo(), cod);
        }

        /**
         * A chave de integração vem primeiro: é o Id do Product2 que nós mesmos
         * gravamos no Omie, então é inequívoca. O código é o desempate.
         */
        public Long buscar(String idSalesforce, String productCode) {
            Long cod = porChaveIntegracao.get(idSalesforce);
            return (cod != null) ? cod : porCodigo.get(productCode);
        }

        /** Os cCodIntServ que são Id de Product2 — o resto nasceu fora daqui. */
        public Set<Id> idsSalesforce() {
            Set<Id> ids = new Set<Id>();
            for (String chave : porChaveIntegracao.keySet()) {
                try {
                    ids.add(Id.valueOf(chave));
                } catch (Exception ignore) {
                    // chave de integração que não é Id: só o código casa
                }
            }
            return ids;
        }
    }

    public static OmieServico consultarPorCodigoOmie(Long nCodServ) {
        return consultar(new Map<String, Object>{ 'nCodServ' => nCodServ });
    }

    /** Consulta pelo Id do Product2 (usado como cCodIntServ). */
    public static OmieServico consultarPorIdSalesforce(Id productId) {
        return consultar(new Map<String, Object>{ 'cCodIntServ' => String.valueOf(productId) });
    }

    private static OmieServico consultar(Map<String, Object> chave) {
        return (OmieServico) OmieApiClient.postAndParse(
            EP, CALL_CONSULTAR, chave, OmieServico.class);
    }


    // =================================================================
    // GRAVAÇÃO
    // =================================================================

    public static OmieServico.StatusResponse incluir(OmieServico s) {
        return gravar(CALL_INCLUIR, s);
    }

    public static OmieServico.StatusResponse alterar(OmieServico s) {
        return gravar(CALL_ALTERAR, s);
    }

    /**
     * Inclui se não existir, altera se já existir (pelo cCodIntServ).
     *
     * Assim como em produtos, é uma gravação por requisição: este endpoint
     * também não tem método de lote.
     */
    public static OmieServico.StatusResponse upsertServico(OmieServico s) {
        return gravar(CALL_UPSERT, s);
    }

    private static OmieServico.StatusResponse gravar(String metodo, OmieServico s) {
        return (OmieServico.StatusResponse) OmieApiClient.postAndParse(
            EP, metodo, s, OmieServico.StatusResponse.class);
    }
}