/**
 * DTO do cadastro de serviço do Omie (endpoint /servicos/servico/).
 *
 * Mesma ideia do OmieProduto: os nomes dos atributos são EXATAMENTE os do JSON,
 * então JSON.serialize/deserialize resolve sem mapeamento campo a campo.
 *
 * A diferença é a forma. O produto é um objeto plano; o serviço vem em blocos
 * (cabecalho, descricao, impostos, info) e a identificação muda de nome conforme
 * o método: intListar no retorno da listagem, intIncluir no IncluirCadastroServico
 * e intEditar no Alterar/UpsertCadastroServico. Os três são a MESMA dupla de
 * campos, por isso reaproveitam a classe Chave — e, como o OmieApiClient suprime
 * nulos, só vai para a API o bloco que foi preenchido.
 *
 * PARA ESTENDER: adicione o campo no bloco correspondente com o nome idêntico ao
 * do JSON. Campos que o Omie retorna e não existem aqui são ignorados.
 */
public class OmieServico {

    // =================================================================
    // Identificação (o nome do bloco muda conforme o método)
    // =================================================================
    public Chave intListar;    // vem preenchido no retorno de ListarCadastroServico
    public Chave intIncluir;   // IncluirCadastroServico
    public Chave intEditar;    // AlterarCadastroServico e UpsertCadastroServico

    public Cabecalho cabecalho;
    public Descricao descricao;
    public Impostos  impostos;
    public Info      info;

    // -----------------------------------------------------------------
    public class Chave {
        public String cCodIntServ;   // nossa chave (usamos o Id do Product2)
        public Long   nCodServ;      // ID interno do Omie (PK)

        public Chave() {}
        public Chave(String codIntegracao, Long codOmie) {
            this.cCodIntServ = codIntegracao;
            this.nCodServ    = codOmie;
        }
    }

    public class Cabecalho {
        public String  cCodigo;        // código do serviço (máx. 20)
        public String  cDescricao;     // descrição resumida (máx. 100)
        public Decimal nPrecoUnit;
        public String  cIdTrib;
        public String  cCodServMun;    // código do serviço no município
        public String  cCodLC116;
        public Long    nIdNBS;
        public String  cCodCateg;
    }

    public class Descricao {
        public String cDescrCompleta;
    }

    public class Impostos {
        public Decimal nAliqISS;
        public Decimal nAliqPIS;
        public Decimal nAliqCOFINS;
        public Decimal nAliqCSLL;
        public Decimal nAliqIR;
        public Decimal nAliqINSS;
        public String  cRetISS;        // 'S' / 'N'
        public String  cRetPIS;
        public String  cRetCOFINS;
        public String  cRetCSLL;
        public String  cRetIR;
        public String  cRetINSS;
    }

    /** Auditoria devolvida pelo Omie. O 'inativo' do serviço mora AQUI. */
    public class Info {
        public String dInc;      // dd/MM/yyyy
        public String hInc;
        public String uInc;
        public String dAlt;
        public String hAlt;
        public String uAlt;
        public String inativo;   // 'S' / 'N'
    }


    // =================================================================
    // Atalhos de leitura
    //
    // Existem porque a identificação chega ora em intListar, ora em intEditar.
    // Sem eles, todo consumidor repetiria o mesmo if.
    // =================================================================

    public Long codigoOmie() {
        if (intListar != null && intListar.nCodServ != null) return intListar.nCodServ;
        return (intEditar == null) ? null : intEditar.nCodServ;
    }

    public String chaveIntegracao() {
        if (intListar != null && String.isNotBlank(intListar.cCodIntServ)) return intListar.cCodIntServ;
        return (intEditar == null) ? null : intEditar.cCodIntServ;
    }

    public String codigo() {
        return (cabecalho == null) ? null : cabecalho.cCodigo;
    }

    public Boolean isInativo() {
        return info != null && info.inativo == 'S';
    }


    // =================================================================
    // Wrappers de requisição / resposta
    // =================================================================

    /** Retorno de ListarCadastroServico. */
    public class ListaResponse {
        public Integer nPagina;
        public Integer nTotPaginas;
        public Integer nRegistros;
        public Integer nTotRegistros;
        public List<OmieServico> cadastros;
    }

    /** Retorno de Incluir / Alterar / UpsertCadastroServico. */
    public class StatusResponse {
        public String cCodIntServ;
        public Long   nCodServ;
        public String cCodStatus;      // '0' = sucesso
        public String cDescStatus;

        public Boolean isSucesso() {
            return nCodServ != null && (cCodStatus == null || cCodStatus == '0');
        }
    }
}