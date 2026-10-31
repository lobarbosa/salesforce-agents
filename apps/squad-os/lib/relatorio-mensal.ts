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

export interface DadosRelatorio {
  clienteNome: string;
  mes: string;
  entregues: { code: string; titulo: string }[];
  contrato:
    | { tipo: "ams"; cicloHoras: string; doMes: MesDeHoras | null }
    | { tipo: "projeto"; nome: string; progresso: Progresso; horasDoMes: number; horasAcumuladas: number; horasContratadas: number; entregaveisConcluidos: string[] }
    | null;
  url: string;
}

export function textoDoRelatorio(d: DadosRelatorio): { assunto: string; texto: string } {
  const mesNome = nomeDoMes(d.mes);
  const linhas: string[] = [`Olá. Este é o resumo de ${mesNome} da ${d.clienteNome}.`, ""];

  linhas.push(`Demandas concluídas no mês (${d.entregues.length}):`);
  linhas.push(...(d.entregues.length ? d.entregues.map((e) => `- ${e.code} — ${e.titulo}`) : ["- nenhuma demanda foi concluída neste mês"]));
  linhas.push("");

  const c = d.contrato;
  if (c?.tipo === "ams") {
    const m = c.doMes;
    linhas.push("Contrato de sustentação (AMS):");
    if (m) {
      linhas.push(`- Horas consumidas em ${mesNome}: ${h(m.horasGastas)}`);
      if (m.horasContratadas > 0) {
        const ciclo = c.cicloHoras === "mensal" ? "no mês" : "no ciclo até o fim do mês";
        const saldo = m.horasContratadas - m.horasNoCiclo;
        linhas.push(`- Consumo ${ciclo}: ${h(m.horasNoCiclo)} de ${h(m.horasContratadas)} contratadas (${Math.round((m.horasNoCiclo / m.horasContratadas) * 100)}%)`);
        linhas.push(saldo >= 0 ? `- Saldo: ${h(saldo)}` : `- Excedente: ${h(-saldo)} acima do contratado`);
      }
    } else {
      linhas.push("- Sem horas lançadas no mês.");
    }
  } else if (c?.tipo === "projeto") {
    linhas.push(`Projeto${c.nome ? ` ${c.nome}` : ""}:`);
    linhas.push(`- Progresso: ${c.progresso.pct}% do escopo (${c.progresso.concluidos} de ${c.progresso.total} entregáveis)`);
    if (c.entregaveisConcluidos.length) linhas.push(`- Entregáveis concluídos até agora: ${c.entregaveisConcluidos.join("; ")}`);
    linhas.push(`- Horas em ${mesNome}: ${h(c.horasDoMes)}`);
    linhas.push(
      c.horasContratadas > 0
        ? `- Horas acumuladas no projeto: ${h(c.horasAcumuladas)} de ${h(c.horasContratadas)} contratadas (${Math.round((c.horasAcumuladas / c.horasContratadas) * 100)}%)`
        : `- Horas acumuladas no projeto: ${h(c.horasAcumuladas)}`
    );
  }

  linhas.push("", `Detalhes no portal: ${d.url}`, "", "— Squad OS");
  return { assunto: `${d.clienteNome} — resumo de ${mesNome}`, texto: linhas.join("\n") };
}
