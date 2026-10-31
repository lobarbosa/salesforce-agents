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

// --- Versão estilizada (2026-10-31) ----------------------------------------
// E-mail HTML com a marca: tabela + estilo inline, que é o que Gmail/Outlook
// renderizam de forma confiável (sem <style>, sem flex/grid, sem webfont).
// O texto puro acima continua indo junto como alternativa.

const COR = {
  fundo: "#F6F5FB",
  cartao: "#FFFFFF",
  borda: "#DEDCEC",
  texto: "#0A0E24",
  suave: "#5C5A79",
  azul: "#3E46FA",
  azulSuave: "#E7E8F8",
  laranja: "#D63505",
  verde: "#2B7A45",
  trilho: "#EEEDF6",
};
const FONTE = "'Trebuchet MS', Verdana, Arial, sans-serif";

const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

function kpi(valor: string, rotulo: string, cor = COR.texto): string {
  return `<td width="33%" style="padding:6px" valign="top"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${COR.cartao};border:1px solid ${COR.borda};border-radius:10px"><tr><td style="padding:14px 16px;font-family:${FONTE}">
<div style="font-size:24px;font-weight:bold;color:${cor};line-height:1.1">${esc(valor)}</div>
<div style="font-size:12px;color:${COR.suave};margin-top:4px">${esc(rotulo)}</div></td></tr></table></td>`;
}

function barra(pct: number, cor: string): string {
  const p = Math.max(0, Math.min(100, Math.round(pct)));
  const resto = 100 - p;
  return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-radius:6px;overflow:hidden"><tr>
${p > 0 ? `<td width="${p}%" style="background:${cor};height:10px;font-size:0;line-height:0">&nbsp;</td>` : ""}
${resto > 0 ? `<td width="${resto}%" style="background:${COR.trilho};height:10px;font-size:0;line-height:0">&nbsp;</td>` : ""}
</tr></table>`;
}

function linha(rotulo: string, valor: string, corValor = COR.texto): string {
  return `<tr><td style="padding:6px 0;font-family:${FONTE};font-size:14px;color:${COR.suave}">${esc(rotulo)}</td><td align="right" style="padding:6px 0;font-family:${FONTE};font-size:14px;color:${corValor};font-weight:bold">${esc(valor)}</td></tr>`;
}

export function htmlDoRelatorio(d: DadosRelatorio, logoUrl: string | null): string {
  const mesNome = nomeDoMes(d.mes);
  const c = d.contrato;

  let kpis = kpi(String(d.entregues.length), d.entregues.length === 1 ? "demanda concluída" : "demandas concluídas", COR.verde);
  let blocoContrato = "";
  if (c?.tipo === "ams") {
    const m = c.doMes;
    const contratadas = m?.horasContratadas ?? 0;
    const noCiclo = m?.horasNoCiclo ?? 0;
    const pct = contratadas > 0 ? (noCiclo / contratadas) * 100 : 0;
    const estourou = contratadas > 0 && noCiclo > contratadas;
    kpis += kpi(h(m?.horasGastas ?? 0), "horas no mês", COR.azul);
    kpis += kpi(contratadas > 0 ? `${Math.round(pct)}%` : "—", c.cicloHoras === "mensal" ? "do contratado" : "do ciclo", estourou ? COR.laranja : COR.texto);
    blocoContrato = `
<div style="font-family:${FONTE};font-size:13px;font-weight:bold;letter-spacing:.04em;text-transform:uppercase;color:${COR.suave};margin:0 0 10px">Contrato de sustentação (AMS)</div>
${contratadas > 0 ? barra(pct, estourou ? COR.laranja : COR.azul) : ""}
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px">
${linha(`Horas em ${mesNome}`, h(m?.horasGastas ?? 0))}
${contratadas > 0 ? linha(c.cicloHoras === "mensal" ? "Consumo do mês" : "Consumo do ciclo", `${h(noCiclo)} de ${h(contratadas)}`) : ""}
${contratadas > 0 ? (estourou ? linha("Excedente", h(noCiclo - contratadas), COR.laranja) : linha("Saldo", h(contratadas - noCiclo), COR.verde)) : ""}
</table>`;
  } else if (c?.tipo === "projeto") {
    const pctHoras = c.horasContratadas > 0 ? (c.horasAcumuladas / c.horasContratadas) * 100 : 0;
    kpis += kpi(`${c.progresso.pct}%`, "do escopo entregue", COR.azul);
    kpis += kpi(h(c.horasDoMes), "horas no mês");
    blocoContrato = `
<div style="font-family:${FONTE};font-size:13px;font-weight:bold;letter-spacing:.04em;text-transform:uppercase;color:${COR.suave};margin:0 0 10px">Projeto${c.nome ? ` · ${esc(c.nome)}` : ""}</div>
<div style="font-family:${FONTE};font-size:13px;color:${COR.suave};margin:0 0 6px">Escopo: ${c.progresso.concluidos} de ${c.progresso.total} entregáveis</div>
${barra(c.progresso.pct, COR.azul)}
${c.horasContratadas > 0 ? `<div style="font-family:${FONTE};font-size:13px;color:${COR.suave};margin:14px 0 6px">Horas: ${h(c.horasAcumuladas)} de ${h(c.horasContratadas)}</div>${barra(pctHoras, pctHoras > 100 ? COR.laranja : COR.verde)}` : ""}
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px">
${linha(`Horas em ${mesNome}`, h(c.horasDoMes))}
${linha("Horas acumuladas", h(c.horasAcumuladas))}
</table>
${c.entregaveisConcluidos.length ? `<div style="font-family:${FONTE};font-size:13px;color:${COR.suave};margin:12px 0 4px">Entregáveis concluídos</div><div style="font-family:${FONTE};font-size:14px;color:${COR.texto};line-height:1.6">${c.entregaveisConcluidos.map((t) => `✓ ${esc(t)}`).join("<br>")}</div>` : ""}`;
  }

  const listaEntregues = d.entregues.length
    ? d.entregues
        .map(
          (e) => `<tr><td style="padding:10px 0;border-bottom:1px solid ${COR.borda};font-family:${FONTE}">
<span style="font-family:Consolas,Menlo,monospace;font-size:12px;color:${COR.azul};background:${COR.azulSuave};padding:2px 6px;border-radius:4px">${esc(e.code)}</span>
<span style="font-size:14px;color:${COR.texto};padding-left:8px">${esc(e.titulo)}</span></td></tr>`
        )
        .join("")
    : `<tr><td style="padding:10px 0;font-family:${FONTE};font-size:14px;color:${COR.suave}">Nenhuma demanda foi concluída neste mês.</td></tr>`;

  const cartao = (conteudo: string) =>
    `<tr><td style="padding:8px 6px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${COR.cartao};border:1px solid ${COR.borda};border-radius:12px"><tr><td style="padding:20px 22px">${conteudo}</td></tr></table></td></tr>`;

  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${esc(d.clienteNome)} — ${esc(mesNome)}</title></head>
<body style="margin:0;padding:0;background:${COR.fundo}">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${COR.fundo}"><tr><td align="center" style="padding:24px 12px">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%">
<tr><td style="padding:0 6px 4px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
<td style="font-family:${FONTE}">${logoUrl ? `<img src="${esc(logoUrl)}" alt="Konecta" height="34" style="display:block;height:34px;border:0">` : `<span style="font-size:20px;font-weight:bold;color:${COR.azul}">Squad OS</span>`}</td>
<td align="right" style="font-family:${FONTE};font-size:12px;color:${COR.suave}">Resumo mensal</td></tr></table>
</td></tr>
<tr><td style="padding:14px 6px 2px;font-family:${FONTE}">
<div style="height:4px;background:${COR.azul};background-image:linear-gradient(90deg,${COR.azul},#FA511E);border-radius:2px;margin-bottom:18px"></div>
<div style="font-size:13px;color:${COR.suave}">${esc(d.clienteNome)}</div>
<div style="font-size:26px;font-weight:bold;color:${COR.texto};margin-top:2px">${esc(mesNome.charAt(0).toUpperCase() + mesNome.slice(1))}</div>
</td></tr>
<tr><td style="padding:10px 0"><table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>${kpis}</tr></table></td></tr>
${cartao(`<div style="font-family:${FONTE};font-size:13px;font-weight:bold;letter-spacing:.04em;text-transform:uppercase;color:${COR.suave};margin:0 0 4px">Demandas concluídas</div><table role="presentation" width="100%" cellpadding="0" cellspacing="0">${listaEntregues}</table>`)}
${blocoContrato ? cartao(blocoContrato) : ""}
<tr><td align="center" style="padding:18px 6px">
<a href="${esc(d.url)}" style="display:inline-block;background:${COR.azul};color:#FFFFFF;font-family:${FONTE};font-size:14px;font-weight:bold;text-decoration:none;padding:12px 22px;border-radius:8px">Ver detalhes no portal</a>
</td></tr>
<tr><td align="center" style="padding:4px 6px 0;font-family:${FONTE};font-size:11px;color:${COR.suave}">Enviado automaticamente pelo Squad OS no início de cada mês.</td></tr>
</table></td></tr></table></body></html>`;
}
