/**
 * Tradução entre Product2 (Salesforce) e OmieProduto (Omie), nos dois sentidos,
 * mais a validação prévia.
 *
 * Toda regra de "de-para" mora AQUI. Se amanhã o campo de NCM mudar de lugar,
 * só este arquivo é tocado.
 */
public with sharing class OmieProdutoMapper {

    /** Limite prático do campo Descrição no cadastro do Omie. */
    private static final Integer MAX_DESCRICAO = 120;
    private static final Integer MAX_DESCR_DETALHADA = 500;

    private static final Pattern NCM_PATTERN =
        Pattern.compile('^[0-9]{4}\\.?[0-9]{2}\\.?[0-9]{2}$');

    /** Campos lidos do Product2. Reutilize no SOQL para não esquecer nenhum. */
    public static final String CAMPOS_SOQL =
        'Id, Name, ProductCode, Description, Family, IsActive, ' +
        'Id_Codigo_de_Servico__c, MCN__c, Unidade__c';


    // =================================================================
    // Validação (rode SEMPRE antes do callout)
    // =================================================================

    /**
     * Por que validar antes: o Omie bloqueia a combinação IP + App Key + Método
     * por 30 minutos (HTTP 425) na 10ª requisição com erro. Dez produtos sem NCM
     * derrubam a integração inteira. Requisição que não sai não conta.
     *
     * @return null se válido, ou a mensagem do primeiro problema encontrado.
     */
    public static String validar(Product2 p) {
        if (String.isBlank(p.ProductCode))     return 'ProductCode (código do produto) é obrigatório.';
        if (String.isBlank(p.Name))            return 'Name (descrição) é obrigatório.';
        //if (String.isBlank(p.Omie_Unidade__c)) return 'Unidade é obrigatória (ex.: UN, PC, KG).';
        //if (String.isBlank(p.Omie_NCM__c))     return 'NCM é obrigatório.';
        //if (!NCM_PATTERN.matcher(p.Omie_NCM__c).matches()) {
            //return 'NCM inválido: use 8 dígitos (8517.62.55 ou 85176255).';
        //}
        return null;
    }

    /** Separa a lista em válidos e inválidos numa passada só. */
    public static Resultado separarValidos(List<Product2> produtos) {
        Resultado r = new Resultado();
        for (Product2 p : produtos) {
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

    public static OmieProduto toOmie(Product2 p) {
        OmieProduto o = new OmieProduto();

        // O Id do Product2 é a chave de integração: garante idempotência.
        // Reprocessar o mesmo registro atualiza em vez de duplicar.
        o.codigo_produto_integracao = String.valueOf(p.Id);
        o.codigo         = p.ProductCode;
        o.descricao      = truncar(p.Description, MAX_DESCRICAO);
        o.unidade        = p.Unidade__c.toUpperCase();
        o.ncm            = p.MCN__c;
        o.inativo        = p.IsActive ? 'N' : 'S';

        // Se já temos o ID do Omie, mandamos junto — torna o upsert inequívoco.
        if (p.Id_Codigo_de_Servico__c != null) {
            o.codigo_produto = Long.valueOf(String.valueOf(p.Id_Codigo_de_Servico__c));
        }
        //if (p.Preco_Venda__c != null)               o.valor_unitario   = p.Preco_Venda__c;
        //if (String.isNotBlank(p.Description))       o.descr_detalhada  = truncar(p.Description, MAX_DESCR_DETALHADA);
        //if (String.isNotBlank(p.Omie_EAN__c))       o.ean              = p.Omie_EAN__c;
        //if (String.isNotBlank(p.Omie_Marca__c))     o.marca            = p.Omie_Marca__c;
        //if (String.isNotBlank(p.Family))            o.obs_internas     = 'Família Salesforce: ' + p.Family;

        return o;
    }

    public static List<OmieProduto> toOmie(List<Product2> produtos) {
        List<OmieProduto> itens = new List<OmieProduto>();
        for (Product2 p : produtos) itens.add(toOmie(p));
        return itens;
    }


    // =================================================================
    // Omie -> Salesforce  (para importar o catálogo do ERP)
    // =================================================================

    /**
     * Monta um Product2 a partir do retorno do Omie. Se o codigo_produto_integracao
     * for um Id válido de Product2, preenche o Id para permitir update direto.
     */
    public static Product2 fromOmie(OmieProduto o) {
        Product2 p = new Product2();

        if (String.isNotBlank(o.codigo_produto_integracao)) {
            try {
                p.Id = Id.valueOf(o.codigo_produto_integracao);
            } catch (Exception ignore) {
                // chave de integração criada fora do Salesforce: segue como novo registro
            }
        }
        p.Name                    = o.descricao;
        p.ProductCode             = o.codigo;
        p.Description             = o.descr_detalhada;
        p.IsActive                = (o.inativo != 'S');
        p.Id_Codigo_de_Servico__c  = String.valueOf(o.codigo_produto);
        //p.Omie_Unidade__c         = o.unidade;
        //p.Omie_NCM__c             = o.ncm;
        //p.Omie_EAN__c             = o.ean;
        //p.Omie_Marca__c           = o.marca;
        //p.Preco_Venda__c          = o.valor_unitario;
        p.Omie_FlagIntegrado__c     = true;
        p.Omie_Data_da_ltima_Integra_o__c     = System.now();
        return p;
    }

    public static List<Product2> fromOmie(List<OmieProduto> produtos) {
        List<Product2> lista = new List<Product2>();
        for (OmieProduto o : produtos) lista.add(fromOmie(o));
        return lista;
    }


    // =================================================================
    private static String truncar(String s, Integer max) {
        return (s != null && s.length() > max) ? s.substring(0, max) : s;
    }
}