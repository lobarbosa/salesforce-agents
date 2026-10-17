/**
 * Preenche o Id_Codigo_de_Servico__c (código do produto no Omie) nos Product2
 * que ainda não têm esse vínculo.
 *
 * Existe porque os dois catálogos nasceram separados: há produto no Salesforce
 * que já está cadastrado no Omie, só que sem o código gravado do lado de cá.
 * Roda uma vez para casar os cadastros; depois disso o OmieProdutoSyncQueueable
 * mantém o vínculo sozinho.
 *
 * Uso (Execute Anonymous):
 *   System.debug(OmieProdutoVinculo.vincularAtivos());
 */
public with sharing class OmieProdutoVinculo {

    /**
     * Lê todos os produtos ativos do Omie e grava o codigo_produto no Product2
     * correspondente.
     *
     * Ordem do match, do mais forte para o mais fraco:
     *   1. codigo_produto_integracao == Product2.Id  — a chave que nós mesmos
     *      gravamos no Omie, então é inequívoca;
     *   2. codigo == ProductCode — o SKU, para o produto que nasceu no Omie e
     *      nunca passou pela nossa integração.
     *
     * Os callouts vêm ANTES de qualquer DML de propósito: o Apex proíbe callout
     * depois de gravação na mesma transação.
     */
    public static Resultado vincularAtivos() {
        List<OmieProduto> doOmie = OmieProdutoService.listarTodosAtivos();

        // Sem filtro de IsActive: um produto inativo aqui que exista no Omie
        // também merece o vínculo. Atenção ao teto de 50.000 linhas por SOQL.
        Map<Id, Product2> porId = new Map<Id, Product2>([
            SELECT Id, ProductCode, Id_Codigo_de_Servico__c
            FROM Product2
        ]);

        // SKU repetido no Salesforce não dá para casar: escolher "o primeiro"
        // gravaria o código do Omie no produto errado. Melhor deixar de fora.
        Map<String, Product2> porCodigo = new Map<String, Product2>();
        Set<String> ambiguos = new Set<String>();

        for (Product2 p : porId.values()) {
            if (String.isBlank(p.ProductCode)) continue;
            if (porCodigo.containsKey(p.ProductCode)) ambiguos.add(p.ProductCode);
            porCodigo.put(p.ProductCode, p);
        }

        Resultado r = new Resultado();
        r.totalOmie = doOmie.size();
        Map<Id, Product2> paraAtualizar = new Map<Id, Product2>();

        for (OmieProduto o : doOmie) {
            if (o.codigo_produto == null) continue;

            Product2 p = casar(o, porId, porCodigo, ambiguos);
            if (p == null) {
                r.semMatch++;
                continue;
            }

            String codigoOmie = String.valueOf(o.codigo_produto);
            if (codigoOmie == p.Id_Codigo_de_Servico__c) {
                r.jaVinculados++;
                continue;
            }

            paraAtualizar.put(p.Id, new Product2(
                Id                      = p.Id,
                Id_Codigo_de_Servico__c = codigoOmie
            ));
        }

        if (!paraAtualizar.isEmpty()) {
            // allOrNone = false: um produto que falhe (validação, trigger) não
            // pode desfazer o vínculo de todos os outros.
            for (Database.SaveResult sr : Database.update(paraAtualizar.values(), false)) {
                if (sr.isSuccess()) r.vinculados++; else r.erros++;
            }
        }
        return r;
    }

    // -----------------------------------------------------------------
    /** Devolve o Product2 correspondente, ou null quando não há par confiável. */
    private static Product2 casar(OmieProduto o,
                                  Map<Id, Product2> porId,
                                  Map<String, Product2> porCodigo,
                                  Set<String> ambiguos) {

        if (String.isNotBlank(o.codigo_produto_integracao)) {
            try {
                Product2 p = porId.get(Id.valueOf(o.codigo_produto_integracao));
                if (p != null) return p;
            } catch (Exception ignore) {
                // chave de integração criada fora do Salesforce: tenta pelo SKU
            }
        }

        if (String.isNotBlank(o.codigo) && !ambiguos.contains(o.codigo)) {
            return porCodigo.get(o.codigo);
        }
        return null;
    }

    // -----------------------------------------------------------------
    /** Resumo da execução: dá para conferir tudo em um System.debug só. */
    public class Resultado {
        public Integer totalOmie    = 0;   // produtos ativos lidos do Omie
        public Integer vinculados   = 0;   // Product2 atualizados agora
        public Integer jaVinculados = 0;   // já tinham o mesmo código gravado
        public Integer semMatch     = 0;   // sem par no Salesforce
        public Integer erros        = 0;   // falharam no update

        public override String toString() {
            return 'Omie: ' + totalOmie +
                   ' | vinculados: '     + vinculados +
                   ' | ja vinculados: '  + jaVinculados +
                   ' | sem match: '      + semMatch +
                   ' | erros: '          + erros;
        }
    }
}