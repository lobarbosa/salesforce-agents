public class CNPJBrasilAPISearchResponse {
    public String uf { get; set; }
    public String cep { get; set; }
    public List<QSA> qsa { get; set; }
    // public String cnpj { get; set; }
    public String pais { get; set; }
    public String email { get; set; }
    // public String porte { get; set; }
    public String bairro { get; set; }
    public String numero { get; set; }
    // public String ddd_fax { get; set; }
    public String municipio { get; set; }
    public String logradouro { get; set; }
    public String cnae_fiscal { get; set; }
    // public String codigo_pais { get; set; }
    public String complemento { get; set; }
    // public String codigo_porte { get; set; }
    public String razao_social { get; set; }
    // public String nome_fantasia { get; set; }
    // public String capital_social { get; set; }
    public String ddd_telefone_1 { get; set; }
    // public String ddd_telefone_2 { get; set; }
    // public Boolean opcao_pelo_mei { get; set; }
    // public String descricao_porte { get; set; }
    // public String codigo_municipio { get; set; }
    // public List<CnaeSecundario> cnaes_secundarios { get; set; }
    // public String natureza_juridica { get; set; }
    // public String situacao_especial { get; set; }
    // public Boolean opcao_pelo_simples { get; set; }
    // public String situacao_cadastral { get; set; }
    // public String data_opcao_pelo_mei { get; set; }
    // public String data_exclusao_do_mei { get; set; }
    // public String cnae_fiscal_descricao { get; set; }
    // public String codigo_municipio_ibge { get; set; }
    public String data_inicio_atividade { get; set; }
    // public String data_situacao_especial { get; set; }
    // public String data_opcao_pelo_simples { get; set; }
    // public String data_situacao_cadastral { get; set; }
    // public String nome_cidade_no_exterior { get; set; }
    // public String codigo_natureza_juridica { get; set; }
    // public String data_exclusao_do_simples { get; set; }
    // public String motivo_situacao_cadastral { get; set; }
    // public String ente_federativo_responsavel { get; set; }
    // public String identificador_matriz_filial { get; set; }
    // public String qualificacao_do_responsavel { get; set; }
    // public String descricao_situacao_cadastral { get; set; }
    public String descricao_tipo_de_logradouro { get; set; }
    // public String descricao_motivo_situacao_cadastral { get; set; }
    // public String descricao_identificador_matriz_filial { get; set; }

    public class QSA {
        // public String pais { get; set; }
        public String nome_socio { get; set; }
        // public String codigo_pais { get; set; }
        // public String faixa_etaria { get; set; }
        // public String cnpj_cpf_do_socio { get; set; }
        public String qualificacao_socio { get; set; }
        // public String codigo_faixa_etaria { get; set; }
        // public String data_entrada_sociedade { get; set; }
        // public String identificador_de_socio { get; set; }
        // public String cpf_representante_legal { get; set; }
        // public String nome_representante_legal { get; set; }
        // public String codigo_qualificacao_socio { get; set; }
        // public String qualificacao_representante_legal { get; set; }
        // public String codigo_qualificacao_representante_legal { get; set; }
    }

    // public class CnaeSecundario {
    //     public String codigo { get; set; }
    //     public String descricao { get; set; }
    // }
}