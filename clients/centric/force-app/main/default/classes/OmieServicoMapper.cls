/**
 * Tradução entre Product2 (Salesforce) e OmieServico (Omie), nos dois sentidos,
 * mais a validação prévia.
 *
 * Serviço e produto moram no MESMO objeto Product2, separados pelo Family:
 * 'Serviço' é o que esta classe trata. O código do Omie vai para o
 * Id_Codigo_de_Servico__c — o campo já existe e já guarda o nCodServ.
 *
 * Toda regra de "de-para" mora AQUI.
 */
public with sharing class OmieServicoMapper {

    /** Valor de Product2.Family que marca um serviço. */
    public static final String FAMILY_SERVICO = 'Serviço';

    /** Limites do cadastro de serviço no Omie. */
    private static final Integer MAX_CODIGO    = 20;
    private static final Integer MAX_DESCRICAO = 100;

    /** Campos lidos do Product2. Reutilize no SOQL para não esquecer nenhum. */
    public static final String CAMPOS_SOQL =
        'Id, Name, ProductCode, Description, Family, IsActive, ' +
        'Id_Codigo_de_Servico__c, Valor__c';


    // =================================================================
    // Validação (rode SEMPRE antes do callout)
    // =================================================================

    /**
     * Por que validar antes: o Omie bloqueia IP + App Key + Método por 30
     * minutos (HTTP 425) na 10ª requisição com erro. Requisição que não sai não
     * conta.
     *
     * @return null se válido, ou a mensagem do primeiro problema encontrado.
     */
    public static String validar(Product2 p) {
        if (String.isBlank(p.ProductCode)) return 'ProductCode (código do serviço) é obrigatório.';
        if (String.isBlank(p.Name))        return 'Name (descrição) é obrigatório.';

        // Truncar o código criaria um serviço ERRADO no Omie e quebraria o
        // vínculo depois. Melhor recusar e deixar o dado ser corrigido aqui.
        if (p.ProductCode.length() > MAX_CODIGO) {
            return 'ProductCode tem ' + p.ProductCode.length() +
                   ' caracteres; o Omie aceita no máximo ' + MAX_CODIGO + '.';
        }
        return null;
    }

    /** Separa a lista em válidos e inválidos numa passada só. */
    public static Resultado separarValidos(List<Product2> servicos) {
        Resultado r = new Resultado();
        for (Product2 p : servicos) {
            String erro = validar(p);
            if (erro == null) {
                r.validos.add(p);
            } else {
                r.erros.put(p.Id, erro);
            }
        }
        return r;
    }

    public class Resultado {
        public List<Product2> validos = new List<Product2>();
        public Map<Id, String> erros  = new Map<Id, String>();
    }


    // =================================================================
    // Salesforce -> Omie
    // =================================================================

    public static OmieServico toOmie(Product2 p) {
        OmieServico s = new OmieServico();

        // intEditar é o bloco que o Upsert espera. O Id do Product2 é a chave de
        // integração: garante idempotência — reprocessar atualiza, não duplica.
        s.intEditar = new OmieServico.Chave(String.valueOf(p.Id), codigoOmieDe(p));

        s.cabecalho            = new OmieServico.Cabecalho();
        s.cabecalho.cCodigo    = p.ProductCode;
        s.cabecalho.cDescricao = truncar(p.Name, MAX_DESCRICAO);
        s.cabecalho.nPrecoUnit = p.Valor__c;

        if (String.isNotBlank(p.Description)) {
            s.descricao = new OmieServico.Descricao();
            s.descricao.cDescrCompleta = p.Description;
        }
        return s;
    }

    public static List<OmieServico> toOmie(List<Product2> servicos) {
        List<OmieServico> itens = new List<OmieServico>();
        for (Product2 p : servicos) itens.add(toOmie(p));
        return itens;
    }

    /**
     * O mesmo serviço, mas com o bloco que o IncluirCadastroServico espera.
     *
     * O nome do bloco de identificação muda por método — intIncluir na inclusão,
     * intEditar no alterar/upsert. Mandar o bloco errado faz o Omie criar o
     * cadastro SEM o cCodIntServ, e aí o vínculo se perde. Não vai nCodServ:
     * numa inclusão ele ainda não existe.
     */
    public static OmieServico paraIncluir(Product2 p) {
        OmieServico s = toOmie(p);
        s.intIncluir = new OmieServico.Chave(String.valueOf(p.Id), null);
        s.intEditar  = null;
        return s;
    }


    // =================================================================
    // Omie -> Salesforce  (para importar o cadastro do ERP)
    // =================================================================

    /**
     * Monta um Product2 a partir do retorno do Omie. Se o cCodIntServ for um Id
     * válido de Product2, preenche o Id para permitir update direto.
     */
    public static Product2 fromOmie(OmieServico s) {
        Product2 p = new Product2();

        String chave = s.chaveIntegracao();
        if (String.isNotBlank(chave)) {
            try {
                p.Id = Id.valueOf(chave);
            } catch (Exception ignore) {
                // chave criada fora do Salesforce: segue como registro novo
            }
        }

        p.Family   = FAMILY_SERVICO;
        p.IsActive = !s.isInativo();
        p.Id_Codigo_de_Servico__c = String.valueOf(s.codigoOmie());

        if (s.cabecalho != null) {
            p.Name        = s.cabecalho.cDescricao;
            p.ProductCode = s.cabecalho.cCodigo;
            p.Valor__c    = s.cabecalho.nPrecoUnit;
        }
        if (s.descricao != null) {
            p.Description = s.descricao.cDescrCompleta;
        }

        p.Omie_FlagIntegrado__c            = true;
        p.Omie_Data_da_ltima_Integra_o__c  = System.now();
        return p;
    }

    public static List<Product2> fromOmie(List<OmieServico> servicos) {
        List<Product2> lista = new List<Product2>();
        for (OmieServico s : servicos) lista.add(fromOmie(s));
        return lista;
    }


    // =================================================================
    private static Long codigoOmieDe(Product2 p) {
        if (String.isBlank(p.Id_Codigo_de_Servico__c)) return null;
        try {
            return Long.valueOf(p.Id_Codigo_de_Servico__c);
        } catch (Exception ignore) {
            return null;   // lixo no campo não pode derrubar o envio
        }
    }

    private static String truncar(String s, Integer max) {
        return (s != null && s.length() > max) ? s.substring(0, max) : s;
    }
}