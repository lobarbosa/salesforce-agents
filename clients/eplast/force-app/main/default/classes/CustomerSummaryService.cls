/**
 * CustomerSummaryService
 *
 * Agent Action Apex invocavel ("ResumirCliente", ver demandas/EPLAST-23/03-design.md
 * secao 2.1) que, quando implementada, vai consolidar Contatos, Negociacoes, Pedidos
 * e Ocorrencias de uma Account para o resumo inteligente de cliente via Agentforce
 * (EPLAST-23).
 *
 * ESTADO ATUAL: SCAFFOLD BLOQUEADO, NAO IMPLEMENTADO.
 *
 * A arquitetura (agente de funcionario + Flow de busca + esta classe) foi aprovada
 * pelo arquiteto humano Carlos Sordi em 2026-10-06 (ver gates.md,
 * "aguardando_gate_design"). Essa aprovacao cobre SOMENTE a decisao arquitetural
 * (D1 em 03-design.md secao 7) -- nao cobre nenhuma das decisoes de negocio/
 * compliance abaixo, que seguem sem resposta registrada em qualquer artefato desta
 * demanda:
 *
 *   D2 - "Ocorrencia" e o objeto Case, SalesReturn__c, ou os dois?
 *   D3 - lista final de campos por categoria (e qual campo de credito usar:
 *        AvailableCreditLimit__c ou AvailableCreditLimitt__c?)
 *   D4 - valores de N (top-N) por categoria e janelas de tempo de "recente"
 *   D5 - criterios e limiares exatos da sintese de pontos de atencao
 *   D6 - pode enviar e-mail/telefone/WhatsApp de contato ao LLM, ou precisa
 *        mascarar por LGPD?
 *
 * Implementar qualquer consulta real aqui hoje significaria decidir essas 5
 * perguntas no lugar do negocio/compliance -- exatamente o que a doutrina deste
 * squad proibe (CLAUDE.md raiz, guardrail #3: "nao invente metadata nem regra de
 * negocio; se nao confirmou, declare a incerteza").
 *
 * Por isso esta classe documenta apenas o contrato publico ja aprovado em design
 * (assinatura @InvocableMethod, forma de entrada) e falha de modo explicito e
 * previsivel em vez de adivinhar valores. Ver demandas/EPLAST-23/04-plano-build.md
 * para o estado completo da demanda e a lista acionavel do que falta.
 *
 * Quando D2-D6 forem respondidos, substituir o corpo de `resumirCliente` pela
 * implementacao real descrita em 03-design.md secoes 1.2 e 2.4 (consolidacao por
 * categoria com status OK/VAZIO/SEM_ACESSO, WITH USER_MODE + stripInaccessible,
 * zero SOQL em loop, sinais de atencao calculados), mantendo a classe `with
 * sharing` e a assinatura publica de `CustomerSummaryRequest` ja definida aqui.
 */
public with sharing class CustomerSummaryService {

    /**
     * Mensagem usada sempre que a consolidacao e solicitada mas nao pode ser
     * executada porque D2-D6 (03-design.md secao 7) nao tem resposta registrada.
     */
    @TestVisible
    private static final String MSG_BLOQUEADO_PENDENCIA_NEGOCIO =
        'CustomerSummaryService ainda nao consolida o resumo: aguardando resposta de ' +
        'negocio/compliance para D2 (objeto de ocorrencia), D3 (campos por categoria e ' +
        'campo de credito), D4 (valores de N e janelas de tempo) e D5 (limiares da ' +
        'sintese de atencao), alem de D6 (mascaramento de dados pessoais de contato) ' +
        'antes de enviar qualquer dado de Contact ao LLM. Ver demandas/EPLAST-23/' +
        '03-design.md secao 7 e demandas/EPLAST-23/04-plano-build.md.';

    /**
     * Entrada do Agent Action `ResumirCliente` (03-design.md secao 2.1). O unico
     * campo e a Account ja identificada por uma etapa anterior (acao padrao do
     * Agent Builder ou o Flow `Account_AgentAction_BuscaCliente`, fora do escopo
     * desta classe).
     */
    public class CustomerSummaryRequest {
        @InvocableVariable(
            label='ID da Conta'
            description='Id da Account ja identificada pela busca previa (acao padrao ou Flow). Obrigatorio.'
            required=true
        )
        public Id accountId;
    }

    /**
     * Saida do Agent Action. A forma final (status/total/top-N por categoria mais
     * `sinaisAtencao[]`, ver 03-design.md secao 1.2 ponto 1) depende de D2-D6 e
     * ainda nao esta implementada aqui -- hoje o unico campo usado e `status`,
     * preenchido com `MSG_BLOQUEADO_PENDENCIA_NEGOCIO` quando a excecao de bloqueio
     * seria inadequada ao contexto do chamador (nao e o caso de nenhum metodo
     * publico atual, mas o campo fica definido para nao quebrar o contrato quando
     * a implementacao real chegar).
     */
    public class CustomerSummaryResult {
        @InvocableVariable(label='Status geral da consolidacao')
        public String status;
    }

    /**
     * Excecao lancada quando a consolidacao e solicitada antes de D2-D6 serem
     * respondidos. Distinta de `IllegalArgumentException` (erro de uso da API, ex.
     * accountId ausente) para que quem chamar consiga diferenciar "voce usou a API
     * errado" de "a API ainda nao pode ser usada".
     */
    public class CustomerSummaryPendingDecisionException extends Exception {}

    /**
     * Action `ResumirCliente`.
     *
     * NAO IMPLEMENTADO: nao faz nenhum SOQL nem DML. Para lista vazia, devolve
     * lista vazia (nada a processar). Para qualquer request com `accountId` nulo,
     * lanca `IllegalArgumentException` (erro de uso, nao de negocio). Para
     * qualquer request bem formado -- um unico ou em lote -- lanca
     * `CustomerSummaryPendingDecisionException`, porque a consolidacao de fato
     * depende de D2-D6 (ver classe acima).
     */
    @InvocableMethod(
        label='Resumir Cliente'
        description='Consolida Contatos, Negociacoes, Pedidos e Ocorrencias de uma Account. BLOQUEADO ate D2-D6 serem respondidos (ver demandas/EPLAST-23/03-design.md secao 7).'
    )
    public static List<CustomerSummaryResult> resumirCliente(List<CustomerSummaryRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<CustomerSummaryResult>();
        }

        for (CustomerSummaryRequest request : requests) {
            if (request.accountId == null) {
                throw new IllegalArgumentException(
                    'CustomerSummaryService.CustomerSummaryRequest.accountId e obrigatorio.'
                );
            }
        }

        throw new CustomerSummaryPendingDecisionException(MSG_BLOQUEADO_PENDENCIA_NEGOCIO);
    }
}
