/**
 * DTO do cadastro de produto do Omie (produto_servico_cadastro).
 *
 * Os nomes dos atributos são EXATAMENTE os do JSON do Omie — é isso que permite
 * usar JSON.serialize/deserialize direto, sem mapeamento manual campo a campo.
 *
 * O MESMO objeto serve para leitura e escrita:
 *  - na leitura, o Omie preenche o que tiver;
 *  - na escrita, o OmieApiClient serializa suprimindo nulos, então só sai o que
 *    o mapper preencheu.
 *
 * PARA ESTENDER: basta adicionar um `public <tipo> nome_do_campo;` com o nome
 * idêntico ao do JSON. Nada mais precisa ser alterado. Campos que o Omie
 * retorna e não existem aqui são ignorados silenciosamente.
 */
public class OmieProduto {

    // =================================================================
    // Identificação
    // =================================================================
    public Long    codigo_produto;              // ID interno do Omie (PK)
    public String  codigo_produto_integracao;   // nossa chave (usamos o Id do Product2)
    public String  codigo;                      // SKU / código do produto
    public String  descricao;                   // nome que sai na NF-e
    public String  descr_detalhada;
    public String  unidade;                     // UN, PC, KG...
    public String  ncm;
    public String  ean;
    public String  cest;
    public String  marca;
    public String  modelo;
    public String  tipoItem;                    // '00' mercadoria, '04' matéria-prima, etc.
    public String  obs_internas;

    // =================================================================
    // Situação
    // =================================================================
    public String  inativo;                     // 'S' / 'N'
    public String  bloqueado;                   // 'S' / 'N'
    public String  bloquear_exclusao;           // 'S' / 'N'
    public String  importado_api;               // 'S' / 'N'

    // =================================================================
    // Comercial
    // =================================================================
    public Decimal valor_unitario;
    public String  exibir_descricao_nfe;        // 'S' / 'N'
    public String  exibir_descricao_pedido;     // 'S' / 'N'

    // =================================================================
    // Família
    // =================================================================
    public Long    codigo_familia;
    public String  codInt_familia;
    public String  descricao_familia;

    // =================================================================
    // Estoque e logística
    // =================================================================
    public Decimal quantidade_estoque;
    public Decimal estoque_minimo;
    public Decimal peso_bruto;
    public Decimal peso_liq;
    public Decimal altura;
    public Decimal largura;
    public Decimal profundidade;

    // =================================================================
    // Fiscal
    // =================================================================
    public String  cfop;
    public String  cst_icms;
    public String  csosn_icms;
    public String  modalidade_icms;
    public Decimal aliquota_icms;
    public Decimal red_base_icms;
    public String  motivo_deson_icms;
    public String  cst_pis;
    public Decimal aliquota_pis;
    public String  cst_cofins;
    public Decimal aliquota_cofins;
    public String  cst_ipi;
    public Decimal aliquota_ipi;
    public String  codigo_enquadramento_ipi;

    // =================================================================
    // Blocos aninhados
    // =================================================================
    public RecomendacoesFiscais recomendacoes_fiscais;
    public DadosIbpt            dadosIbpt;
    public CasasDecimais        casas_decimais;
    public Info                 info;
    public List<Caracteristica> caracteristicas;   // só vem com exibir_caracteristicas = 'S'
    public List<Imagem>         imagens;
    public List<Video>          videos;

    // -----------------------------------------------------------------
    public class RecomendacoesFiscais {
        public String origem_mercadoria;
        public String id_cest;
        public String cupom_fiscal;
        public String market_place;
        public String indicador_escala;
        public String codigo_beneficio_fiscal;
        public Long   id_preco_tabelado;
    }

    public class DadosIbpt {
        public Decimal aliqFederal;
        public Decimal aliqEstadual;
        public Decimal aliqMunicipal;
        public Decimal valorTributos;
        public String  chave;
        public String  fonte;
        public String  versao;
    }

    public class CasasDecimais {
        public Integer nFatConv;
        public String  cFatConv;
        public Integer nCasasDecEstoque;
        public Integer nCasasDecQtd;
    }

    /** Auditoria de inclusão/alteração devolvida pelo Omie. */
    public class Info {
        public String dInc;      // dd/MM/yyyy
        public String hInc;
        public String uInc;
        public String dAlt;
        public String hAlt;
        public String uAlt;
        public String cImpAPI;   // 'S' se o registro foi criado via API
    }

    public class Caracteristica {
        public Long   nCodCaract;
        public String cNomeCaract;
        public String cConteudo;
        public String cExibirItemNF;
        public String cExibirItemPedido;
    }

    public class Imagem { public String url_imagem; }
    public class Video  { public String url_video;  }


    // =================================================================
    // Wrappers de requisição / resposta
    // =================================================================

    /** Retorno de ListarProdutos. */
    public class ListaResponse {
        public Integer pagina;
        public Integer total_de_paginas;
        public Integer registros;
        public Integer total_de_registros;
        public List<OmieProduto> produto_servico_cadastro;
    }

    /**
     * Retorno de IncluirProduto / AlterarProduto / UpsertProduto.
     *
     * Não há mais wrapper de lote: o Omie depreciou UpsertProdutoLote e o
     * produto_servico_lote_response. Cada gravação responde um StatusResponse.
     */
    public class StatusResponse {
        public Long   codigo_produto;
        public String codigo_produto_integracao;
        public String codigo;
        public String codigo_status;     // '0' = sucesso
        public String descricao_status;

        public Boolean isSucesso() {
            return codigo_produto != null &&
                   (codigo_status == null || codigo_status == '0');
        }
    }
}