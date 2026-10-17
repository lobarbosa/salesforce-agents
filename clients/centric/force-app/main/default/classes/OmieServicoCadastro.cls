/**
 * Cadastra UM serviço no Omie e grava o nCodServ de volta no Product2.
 *
 * É o caminho de uma peça só, pensado para fechar o ciclo à mão: criar, guardar
 * o código e depois reconsultar pelo código guardado. Volume vai pelo
 * OmieServicoSyncQueueable, que faz upsert em lote de Ids.
 *
 * Uso (Execute Anonymous) — em DUAS execuções separadas:
 *   System.debug(OmieServicoCadastro.criar('01tHa000001abcdAAA'));
 *   System.debug(OmieServicoCadastro.consultar('01tHa000001abcdAAA').codigo());
 *
 * Duas execuções porque o criar() termina em DML e o consultar() começa em
 * callout: rodar os dois no mesmo script dá "You have uncommitted work pending".
 */
public with sharing class OmieServicoCadastro {

    /**
     * Inclui o serviço no Omie e grava o código retornado no Product2.
     *
     * É INCLUSÃO, não upsert: rodar duas vezes no mesmo produto faz o Omie
     * recusar o segundo, porque o cCodIntServ já existe. Para um caminho que
     * pode ser repetido à vontade, use o OmieServicoSyncQueueable.
     *
     * A ordem importa: SOQL, callout e só então DML — o Apex proíbe callout
     * depois de gravação na mesma transação.
     */
    public static Resultado criar(Id productId) {
        Product2 p = buscarProduto(productId);
        if (p == null) {
            return new Resultado(productId, null, 'Product2 não encontrado.');
        }

        // Valida antes de gastar requisição: o Omie bloqueia a App Key por 30
        // minutos na 10ª requisição com erro.
        String erro = OmieServicoMapper.validar(p);
        if (erro != null) {
            return new Resultado(productId, null, erro);
        }

        OmieServico.StatusResponse resp;
        try {
            resp = OmieServicoService.incluir(OmieServicoMapper.paraIncluir(p));
        } catch (OmieApiClient.OmieException e) {
            return new Resultado(productId, null, e.getMessage());
        }

        if (resp == null || !resp.isSucesso()) {
            return new Resultado(productId, null,
                (resp == null) ? 'O Omie não retornou status.' : resp.cDescStatus);
        }

        update new Product2(
            Id                                = p.Id,
            Id_Codigo_de_Servico__c           = String.valueOf(resp.nCodServ),
            Omie_FlagIntegrado__c             = true,
            Omie_Data_da_ltima_Integra_o__c   = System.now()
        );
        return new Resultado(productId, resp.nCodServ, resp.cDescStatus);
    }

    /**
     * Relê o serviço no Omie usando o código já gravado no Product2 — a outra
     * ponta do ciclo. Cai para a chave de integração quando o código ainda não
     * foi gravado, que é o caso de quem nunca passou pelo criar().
     */
    public static OmieServico consultar(Id productId) {
        Product2 p = buscarProduto(productId);
        if (p == null) return null;

        if (String.isNotBlank(p.Id_Codigo_de_Servico__c)) {
            return OmieServicoService.consultarPorCodigoOmie(
                Long.valueOf(p.Id_Codigo_de_Servico__c));
        }
        return OmieServicoService.consultarPorIdSalesforce(productId);
    }

    // -----------------------------------------------------------------
    private static Product2 buscarProduto(Id productId) {
        List<Product2> achados = Database.query(
            'SELECT ' + OmieServicoMapper.CAMPOS_SOQL +
            ' FROM Product2 WHERE Id = :productId LIMIT 1'
        );
        return achados.isEmpty() ? null : achados[0];
    }

    // -----------------------------------------------------------------
    /** O que aconteceu, em uma linha que cabe num System.debug. */
    public class Resultado {
        public Id      productId;
        public Long    codigoOmie;     // nCodServ; null quando falhou
        public Boolean ok;
        public String  mensagem;

        /** Deu certo é exatamente "voltou código": não há sucesso sem nCodServ. */
        Resultado(Id productId, Long codigoOmie, String mensagem) {
            this.productId  = productId;
            this.codigoOmie = codigoOmie;
            this.ok         = (codigoOmie != null);
            this.mensagem   = mensagem;
        }

        public override String toString() {
            return (ok ? 'OK' : 'FALHA') +
                   ' | produto: ' + productId +
                   ' | nCodServ: ' + codigoOmie +
                   ' | ' + mensagem;
        }
    }
}