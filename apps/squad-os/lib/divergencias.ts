// Rótulos das divergências que os agentes gravam em ops.divergencias.
// Desconhecido aparece cru: agente novo não some da tela.

export const ROTULO_ORIGEM: Record<string, string> = {
  accounting_reconciliation_agent: "Conciliação contábil",
  recurring_billing_monitor: "Assinaturas × cobranças",
  nf_trigger_monitor: "Notas fiscais a emitir",
};

export const ROTULO_TIPO_DIVERGENCIA: Record<string, string> = {
  assinatura_sem_cobranca: "assinatura ativa sem cobrança gerada",
  cobranca_sem_nfse: "cobrança sem nota fiscal",
  guias_sem_contas_a_pagar: "guia de imposto sem conta a pagar",
  leitura_documento: "documento não lido",
};

export const rotuloOrigem = (o: string) => ROTULO_ORIGEM[o] ?? o.replace(/_/g, " ");
export const rotuloTipoDivergencia = (t: string) => ROTULO_TIPO_DIVERGENCIA[t] ?? t.replace(/_/g, " ");

export const ROTULO_STATUS_DIVERGENCIA = { aberta: "aberta", resolvida: "resolvida", ignorada: "ignorada" } as const;
