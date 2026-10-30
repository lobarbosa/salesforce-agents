import { acoesPendentes, type AcaoPendente } from "@/lib/demandas";
import { lerVereditoQa } from "@/lib/qa-veredito";

// "Tem algo parado?" (2026-10-30) — a pergunta que o dono fazia ao agente
// várias vezes por dia. Responde com o que o quadro já sabe (quem age) mais o
// que ele não mostrava: há quanto tempo a demanda está na etapa atual, lido
// do histórico, sem coluna nova no banco. Usada pela ferramenta
// `consultar_parados` do copiloto (só time).

export interface DemandaParaParada {
  code: string;
  titulo: string;
  status: string;
  congeladaDe: string | null;
  criadoEm: Date;
  historico: unknown;
  estimativaConsultorHoras: number | null;
  estimativaAprovadaHoras: number | null;
  estimativaDebitadaEm: Date | null;
  artefatoNome: string;
  artefatoConteudo: string;
  disparos: { tipo: string; gate: string; disparadoEm: Date | null; concluidoEm: Date | null }[];
  client: { nome: string };
}

export interface Parada {
  cliente: string;
  code: string;
  titulo: string;
  acoes: AcaoPendente[];
  diasNaEtapa: number;
  qaReprovado: boolean;
}

/** Quando a demanda entrou no status atual (última transição para ele). */
export function entrouNaEtapaEm(d: { status: string; criadoEm: Date; historico: unknown }): Date {
  const hist = Array.isArray(d.historico) ? (d.historico as { para?: string; em?: string }[]) : [];
  for (let i = hist.length - 1; i >= 0; i--) {
    const h = hist[i];
    if (h?.para === d.status && h.em && !Number.isNaN(Date.parse(h.em))) {
      // Re-sync no mesmo status (de X para X) não reinicia o relógio.
      let j = i;
      while (j > 0 && hist[j - 1]?.para === d.status) j--;
      return new Date(hist[j].em ?? h.em);
    }
  }
  return d.criadoEm;
}

export function paradas(demandas: DemandaParaParada[], agora = new Date()): Parada[] {
  return demandas
    .map((d) => {
      const acoes = acoesPendentes(d);
      const dias = (agora.getTime() - entrouNaEtapaEm(d).getTime()) / 86_400_000;
      const qaReprovado =
        d.artefatoNome === "05-testes.md" && !!d.artefatoConteudo && lerVereditoQa(d.artefatoConteudo).veredito === "reprovado";
      return {
        cliente: d.client.nome,
        code: d.code,
        titulo: d.titulo,
        acoes,
        diasNaEtapa: Math.round(dias * 10) / 10,
        qaReprovado,
      };
    })
    .filter((p) => p.acoes.length > 0)
    .sort((a, b) => b.diasNaEtapa - a.diasNaEtapa);
}
