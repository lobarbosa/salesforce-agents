/**
 * Preenche o Id_Codigo_de_Servico__c (nCodServ do Omie) nos Product2 de serviço
 * que ainda não têm esse vínculo.
 *
 * Mesma ideia do OmieProdutoVinculo: os dois cadastros nasceram separados e há
 * serviço no Salesforce que já existe no Omie sem o código gravado do lado de
 * cá. Roda uma vez para casar; depois o OmieServicoSyncQueueable mantém.
 *
 * Uso (Execute Anonymous):
 *   System.debug(OmieServicoVinculo.vincularAtivos());
 */
public with sharing class OmieServicoVinculo {

    /**
     * Para cada serviço do Salesforce, procura o código dele no Omie:
     *   1. cCodIntServ == Product2.Id — a chave que nós mesmos gravamos no
     *      Omie, então é inequívoca;
     *   2. cCodigo == ProductCode — o código do serviço, para o que nasceu no
     *      Omie e nunca passou pela nossa integração.
     *
     * Os callouts vêm ANTES de qualquer DML de propósito: o Apex proíbe callout
     * depois de gravação na mesma transação.
     */
    public static Resultado vincularAtivos() {
        OmieServicoService.Codigos omie = OmieServicoService.codigosAtivos();

        // Só serviços: produto é assunto do OmieProdutoVinculo, e o filtro
        // mantém a query pequena.
        List<Product2> servicos = [
            SELECT Id, ProductCode, Id_Codigo_de_Servico__c
            FROM Product2
            WHERE Family = :OmieServicoMapper.FAMILY_SERVICO
        ];

        // Código repetido aqui não serve para casar: dois serviços do Salesforce
        // apontando para o mesmo cadastro do Omie brigariam na sincronização.
        // Set.add devolve false quando o valor já estava lá.
        Set<String> vistos    = new Set<String>();
        Set<String> repetidos = new Set<String>();
        for (Product2 p : servicos) {
            if (String.isNotBlank(p.ProductCode) && !vistos.add(p.ProductCode)) {
                repetidos.add(p.ProductCode);
            }
        }

        Resultado r = new Resultado();
        r.totalOmie = omie.lidos;
        List<Product2> paraAtualizar = new List<Product2>();

        for (Product2 p : servicos) {
            // Código ambíguo vira null: aí só a chave de integração salva o match.
            String codigo = repetidos.contains(p.ProductCode) ? null : p.ProductCode;

            Long codigoOmie = omie.buscar(String.valueOf(p.Id), codigo);
            if (codigoOmie == null) {
                r.semMatch++;
                continue;
            }

            String novo = String.valueOf(codigoOmie);
            if (novo == p.Id_Codigo_de_Servico__c) {
                r.jaVinculados++;
                continue;
            }
            paraAtualizar.add(new Product2(Id = p.Id, Id_Codigo_de_Servico__c = novo));
        }

        if (!paraAtualizar.isEmpty()) {
            // allOrNone = false: um registro que falhe (validação, trigger) não
            // pode desfazer o vínculo de todos os outros.
            for (Database.SaveResult sr : Database.update(paraAtualizar, false)) {
                if (sr.isSuccess()) r.vinculados++; else r.erros++;
            }
        }
        return r;
    }

    // -----------------------------------------------------------------
    /** Resumo da execução: dá para conferir tudo em um System.debug só. */
    public class Resultado {
        public Integer totalOmie    = 0;   // serviços ativos lidos do Omie
        public Integer vinculados   = 0;   // Product2 atualizados agora
        public Integer jaVinculados = 0;   // já tinham o mesmo código gravado
        public Integer semMatch     = 0;   // sem par no Omie
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