// Entrega manual (2026-11-25).
//
// Alguns cards são concluídos pelo consultor fora da esteira (tarefa manual na
// org, ajuste feito em reunião, trabalho que não é metadata). Até aqui o único
// caminho para `entregue` era o da esteira: QA aprovado na sandbox de QA mais
// o documento de entrega. A regra "nada é entregue sem evidência" (2026-11-14)
// continua valendo; o que muda é quem produz a evidência:
//
//   1. o consultor (ou admin) registra o que foi feito e anexa uma evidência;
//   2. o card vai para a homologação, marcado como entrega manual;
//   3. o cliente homologa, e só então o card vira `entregue`.
//
// Ninguém entrega sozinho: o consultor não encerra o card, e o cliente não
// homologa sem ver a descrição e a evidência. No repositório, o registro fica
// em `06-entrega-manual.md` (nome em ARQUIVO_ENTREGA_MANUAL), que a esteira
// aceita no lugar de `05-testes.md` + `06-entrega.md`
// (src/salesforce_agents/demands.py).

export const ARQUIVO_ENTREGA_MANUAL = "06-entrega-manual.md";
export const DESCRICAO_MINIMA = 30;

const ENCERRADAS = ["entregue", "cancelada"];

interface DemandaParaEntregaManual {
  status: string;
  entregaManualEm?: Date | string | null;
  disparos?: { concluidoEm: Date | string | null }[];
}

/** Por que este card não aceita entrega manual agora, ou null quando aceita. */
export function motivoSemEntregaManual(d: DemandaParaEntregaManual): string | null {
  if (ENCERRADAS.includes(d.status)) return "a demanda já está encerrada";
  if (d.status === "standby") return "a demanda está congelada — descongele antes de entregar";
  if (d.status === "aguardando_homologacao") {
    return d.entregaManualEm
      ? "a entrega manual já foi registrada — falta o cliente homologar"
      : "a demanda já está na homologação do cliente";
  }
  if ((d.disparos ?? []).some((x) => !x.concluidoEm)) {
    return "há uma execução da esteira em andamento ou na fila — espere ela terminar";
  }
  return null;
}

/** O que falta no registro, ou null quando está completo. */
export function erroDoRegistro(descricao: string, temEvidencia: boolean): string | null {
  if (descricao.trim().length < DESCRICAO_MINIMA) {
    return `descreva o que foi feito e onde (pelo menos ${DESCRICAO_MINIMA} caracteres)`;
  }
  if (!temEvidencia) return "anexe pelo menos uma evidência do que foi feito (print ou documento)";
  return null;
}

/** O registro que vai para o repositório e aparece no card. */
export function conteudoDaEntregaManual(e: {
  code: string;
  titulo: string;
  por: string;
  em: Date;
  descricao: string;
  evidencia: string;
}): string {
  return [
    "**Entrega manual:** registrada",
    `**Por:** ${e.por}`,
    `**Em:** ${e.em.toISOString()}`,
    `**Evidência:** ${e.evidencia}`,
    "",
    `# Entrega manual — ${e.code}: ${e.titulo}`,
    "",
    "Trabalho concluído pelo consultor fora da esteira de agentes. Não houve teste automático na sandbox de QA; a evidência é a anexada ao card.",
    "",
    "## O que foi feito",
    "",
    e.descricao.trim(),
    "",
  ].join("\n");
}
