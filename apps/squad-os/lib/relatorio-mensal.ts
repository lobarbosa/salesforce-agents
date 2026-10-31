import { chaveDia } from "@/lib/horas";
import type { MesDeHoras, Progresso } from "@/lib/contrato";

// Relatório mensal ao cliente (2026-10-31): no dia 1, cada cliente recebe o
// que foi concluído no mês anterior e como está o contrato — AMS (horas do
// ciclo contra o contratado) ou projeto (progresso ponderado e horas
// acumuladas). Puro: quem consulta e envia é app/api/cron/relatorio-mensal.
// Leva só o que a aba Contrato e o quadro já mostram ao próprio cliente.

const MESES = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];

export function nomeDoMes(chave: string): string {
  const [ano, mes] = chave.split("-");
  return `${MESES[Number(mes) - 1]} de ${ano}`;
}

const h = (n: number) => `${Math.round(n * 10) / 10}`.replace(".", ",") + " h";

/** Demandas que chegaram a "entregue" dentro do mês (horário de São Paulo). */
export function entreguesNoMes<T extends { status: string; historico: unknown }>(demandas: T[], mes: string): T[] {
  return demandas.filter((d) => {
    if (d.status !== "entregue") return false;
    const hist = Array.isArray(d.historico) ? (d.historico as { para?: string; em?: string }[]) : [];
    const ultima = [...hist].reverse().find((x) => x?.para === "entregue" && x.em);
    return !!ultima && chaveDia(new Date(ultima.em!)).slice(0, 7) === mes;
  });
}

export interface EntregueDetalhe {
  code: string;
  titulo: string;
  /** AAAA-MM-DD (São Paulo). Só no PDF. */
  entregueEm?: string;
  /** Horas aprovadas pelo cliente (estimativa debitada), quando houver. */
  horasAprovadas?: number | null;
  /** Horas lançadas no timesheet da demanda. */
  horasLancadas?: number;
}

export interface EntregavelDetalhe {
  titulo: string;
  peso: number;
  concluido: boolean;
  demandas: { total: number; entregues: number };
}

export interface DadosRelatorio {
  clienteNome: string;
  mes: string;
  entregues: EntregueDetalhe[];
  contrato:
    | { tipo: "ams"; cicloHoras: string; doMes: MesDeHoras | null; historico?: MesDeHoras[] }
    | {
        tipo: "projeto";
        nome: string;
        progresso: Progresso;
        horasDoMes: number;
        horasAcumuladas: number;
        horasContratadas: number;
        entregaveisConcluidos: string[];
        entregaveis?: EntregavelDetalhe[];
        historico?: MesDeHoras[];
        fimPrevisto?: string | null;
      }
    | null;
  url: string;
}

/**
 * Corpo do e-mail: só o principal, em tópicos. O detalhe vai no PDF anexo
 * (lib/relatorio-pdf.ts) — preferência do dono (2026-10-31).
 */
export function textoDoRelatorio(d: DadosRelatorio): { assunto: string; texto: string } {
  const mesNome = nomeDoMes(d.mes);
  const b: string[] = [];
  b.push(`• Demandas concluídas: ${d.entregues.length}${d.entregues.length ? ` (${d.entregues.map((e) => e.code).join(", ")})` : ""}`);

  const c = d.contrato;
  if (c?.tipo === "ams") {
    const m = c.doMes;
    b.push(`• Horas consumidas no mês: ${h(m?.horasGastas ?? 0)}`);
    if (m && m.horasContratadas > 0) {
      const ciclo = c.cicloHoras === "mensal" ? "do mês" : "do ciclo";
      b.push(`• Consumo ${ciclo}: ${h(m.horasNoCiclo)} de ${h(m.horasContratadas)} (${Math.round((m.horasNoCiclo / m.horasContratadas) * 100)}%)`);
      const saldo = m.horasContratadas - m.horasNoCiclo;
      b.push(saldo >= 0 ? `• Saldo: ${h(saldo)}` : `• Excedente: ${h(-saldo)} acima do contratado`);
    }
  } else if (c?.tipo === "projeto") {
    b.push(`• Progresso do projeto: ${c.progresso.pct}% (${c.progresso.concluidos} de ${c.progresso.total} entregáveis)`);
    b.push(`• Horas no mês: ${h(c.horasDoMes)}`);
    b.push(
      c.horasContratadas > 0
        ? `• Horas acumuladas: ${h(c.horasAcumuladas)} de ${h(c.horasContratadas)} (${Math.round((c.horasAcumuladas / c.horasContratadas) * 100)}%)`
        : `• Horas acumuladas: ${h(c.horasAcumuladas)}`
    );
  }

  const texto = [
    "Olá,",
    "",
    `Segue o resumo de ${mesNome} da ${d.clienteNome}:`,
    "",
    ...b,
    "",
    "O relatório completo, com o detalhe de cada demanda e do contrato, está no PDF em anexo.",
    `Também dá para acompanhar pelo portal: ${d.url}`,
    "",
    "Abraço,",
    "Konecta",
  ].join("\n");
  return { assunto: `${d.clienteNome} — resumo de ${mesNome}`, texto };
}

export const formatarHoras = h;
