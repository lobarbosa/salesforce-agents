import PDFDocument from "pdfkit";
import { DIAS_SEMANA, rotuloDia } from "@/lib/horas";
import { dataBr, horasDoEspelho as h, type Espelho, type SemanaDoEspelho } from "@/lib/espelho-horas";

// PDF do espelho de horas (2026-11-11): o que o financeiro manda ao cliente no
// lugar do "Weekly report" do Clockify. A4 deitado, uma tabela por semana
// (demanda em negrito, consultores embaixo, total por dia) e, com mais de uma
// semana, um resumo do período no fim.
//
// Mesmas escolhas do relatório mensal (lib/relatorio-pdf.ts): pdfkit com as
// fontes padrão (Helvetica cobre o português) e fora do bundle
// (serverExternalPackages em next.config.ts).

const COR = { texto: "#0A0E24", suave: "#5C5A79", azul: "#3E46FA", laranja: "#FA511E", borda: "#DEDCEC", fundo: "#F6F5FB", apagado: "#B9B7CC" };
const M = 40;
const PAG_L = 841.89;
const PAG_A = 595.28;
const LARG = PAG_L - 2 * M;
const COL_DIA = 62;
const COL_TOTAL = 70;
const COL_NOME = LARG - 7 * COL_DIA - COL_TOTAL;
const ALT = 20; // altura de uma linha de tabela
const BASE = PAG_A - M - 22; // abaixo disso fica o rodapé

type Doc = InstanceType<typeof PDFDocument>;

export interface CabecalhoDoEspelho {
  clienteNome: string;
  /** Preenchido quando o espelho é de um consultor só. */
  consultor?: string;
  /** Quem emite (nome que aparece no rodapé). */
  emissor: string;
  /** Dia de São Paulo em que foi gerado, "YYYY-MM-DD". */
  geradoEm: string;
}

function linhaTabela(
  doc: Doc,
  y: number,
  nome: string,
  dias: string[],
  valor: (dia: string) => string,
  total: string,
  estilo: { negrito?: boolean; cor: string; recuo?: number; fundo?: boolean; fora?: string[] }
) {
  if (estilo.fundo) doc.rect(M, y, LARG, ALT).fill(COR.fundo);
  const fonte = estilo.negrito ? "Helvetica-Bold" : "Helvetica";
  doc.font(fonte).fontSize(9).fillColor(estilo.cor);
  doc.text(nome, M + 4 + (estilo.recuo ?? 0), y + 6, { width: COL_NOME - 8 - (estilo.recuo ?? 0), lineBreak: false, ellipsis: true });
  dias.forEach((dia, i) => {
    const fora = estilo.fora?.includes(dia);
    doc.font(fonte).fontSize(9).fillColor(fora ? COR.apagado : estilo.cor);
    doc.text(valor(dia), M + COL_NOME + i * COL_DIA, y + 6, { width: COL_DIA - 6, align: "right", lineBreak: false });
  });
  doc.font(fonte).fontSize(9).fillColor(estilo.cor);
  doc.text(total, M + COL_NOME + 7 * COL_DIA, y + 6, { width: COL_TOTAL - 4, align: "right", lineBreak: false });
  doc.moveTo(M, y + ALT).lineTo(M + LARG, y + ALT).lineWidth(0.5).strokeColor(COR.borda).stroke();
}

function alturaDaSemana(s: SemanaDoEspelho): number {
  const linhas = 1 + s.demandas.reduce((n, d) => n + 1 + d.consultores.length, 0) + 1;
  return 22 + linhas * ALT + 16;
}

function semana(doc: Doc, s: SemanaDoEspelho) {
  // A semana inteira vai junta para a página seguinte quando não cabe; só quebra
  // no meio a que, sozinha, é maior que uma página.
  const cabe = BASE - (M + 8);
  if (doc.y + Math.min(alturaDaSemana(s), cabe) > BASE) doc.addPage();

  doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.texto);
  doc.text(`Semana de ${dataBr(s.dias[0])} a ${dataBr(s.dias[6])}`, M, doc.y, { lineBreak: false });
  let y = doc.y + 16;

  const cabecalho = () => {
    linhaTabela(doc, y, "Demanda / Consultor", s.dias, (d) => `${DIAS_SEMANA[s.dias.indexOf(d)]} ${rotuloDia(d)}`, "Total", {
      negrito: true,
      cor: COR.suave,
      fundo: true,
      fora: s.fora,
    });
    y += ALT;
  };
  const novaLinha = () => {
    if (y + ALT > BASE) {
      doc.addPage();
      y = M + 8;
      cabecalho();
    }
  };
  const celula = (porDia: Record<string, number>) => (dia: string) => (porDia[dia] ? h(porDia[dia]) : "—");

  cabecalho();
  for (const d of s.demandas) {
    novaLinha();
    linhaTabela(doc, y, d.titulo ? `${d.code} — ${d.titulo}` : d.code, s.dias, celula(d.porDia), h(d.total), { negrito: true, cor: COR.texto, fora: s.fora });
    y += ALT;
    for (const c of d.consultores) {
      novaLinha();
      linhaTabela(doc, y, c.consultor, s.dias, celula(c.porDia), h(c.total), { cor: COR.suave, recuo: 14, fora: s.fora });
      y += ALT;
    }
  }
  novaLinha();
  linhaTabela(doc, y, "TOTAL DA SEMANA", s.dias, celula(s.porDia), h(s.total), { negrito: true, cor: COR.texto, fundo: true, fora: s.fora });
  doc.x = M;
  doc.y = y + ALT + 16;
}

function resumo(doc: Doc, e: Espelho) {
  const linhas = e.resumo.length + 2;
  if (doc.y + Math.min(22 + linhas * ALT, BASE - M - 8) > BASE) doc.addPage();
  doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.texto).text("Resumo do período", M, doc.y, { lineBreak: false });
  let y = doc.y + 16;
  const wCons = 220;
  const wDem = LARG - wCons - COL_TOTAL;
  const linha = (dem: string, cons: string, total: string, negrito: boolean, cor: string, fundo = false) => {
    if (y + ALT > BASE) {
      doc.addPage();
      y = M + 8;
    }
    if (fundo) doc.rect(M, y, LARG, ALT).fill(COR.fundo);
    doc.font(negrito ? "Helvetica-Bold" : "Helvetica").fontSize(9).fillColor(cor);
    doc.text(dem, M + 4, y + 6, { width: wDem - 8, lineBreak: false, ellipsis: true });
    doc.text(cons, M + wDem + 4, y + 6, { width: wCons - 8, lineBreak: false, ellipsis: true });
    doc.text(total, M + wDem + wCons, y + 6, { width: COL_TOTAL - 4, align: "right", lineBreak: false });
    doc.moveTo(M, y + ALT).lineTo(M + LARG, y + ALT).lineWidth(0.5).strokeColor(COR.borda).stroke();
    y += ALT;
  };
  linha("Demanda", "Consultor", "Horas", true, COR.suave, true);
  let anterior = "";
  for (const r of e.resumo) {
    linha(r.code === anterior ? "" : r.titulo ? `${r.code} — ${r.titulo}` : r.code, r.consultor, h(r.minutos), false, COR.texto);
    anterior = r.code;
  }
  linha("TOTAL DO PERÍODO", e.porConsultor.map((c) => `${c.consultor}: ${h(c.minutos)}`).join("  ·  "), h(e.total), true, COR.texto, true);
  doc.x = M;
  doc.y = y + 12;
}

export function gerarPdfEspelho(e: Espelho, cab: CabecalhoDoEspelho, logo: Buffer | null): Promise<Buffer> {
  const doc = new PDFDocument({
    size: "A4",
    layout: "landscape",
    margin: M,
    bufferPages: true,
    info: { Title: `Espelho de horas — ${cab.clienteNome} — ${dataBr(e.desde)} a ${dataBr(e.ate)}`, Author: cab.emissor },
  });
  const partes: Buffer[] = [];
  doc.on("data", (b: Buffer) => partes.push(b));
  const pronto = new Promise<Buffer>((ok) => doc.on("end", () => ok(Buffer.concat(partes))));

  // Cabeçalho da primeira página
  let comLogo = false;
  if (logo) {
    try {
      doc.image(logo, M, M, { height: 24 });
      comLogo = true;
    } catch {
      /* logo ilegível: cai no nome */
    }
  }
  if (!comLogo) doc.font("Helvetica-Bold").fontSize(15).fillColor(COR.azul).text(cab.emissor, M, M, { lineBreak: false });
  doc.font("Helvetica").fontSize(9).fillColor(COR.suave).text("Espelho de horas", M, M + 8, { width: LARG, align: "right", lineBreak: false });
  doc.rect(M, M + 34, LARG / 2, 3).fill(COR.azul);
  doc.rect(M + LARG / 2, M + 34, LARG / 2, 3).fill(COR.laranja);

  doc.font("Helvetica-Bold").fontSize(18).fillColor(COR.texto).text(cab.clienteNome, M, M + 48, { width: LARG - 190, lineBreak: false, ellipsis: true });
  doc.font("Helvetica").fontSize(10).fillColor(COR.suave);
  doc.text(`${dataBr(e.desde)} a ${dataBr(e.ate)}${cab.consultor ? `  ·  ${cab.consultor}` : ""}`, M, M + 72, { width: LARG - 190, lineBreak: false, ellipsis: true });
  doc.font("Helvetica").fontSize(9).fillColor(COR.suave).text("Total do período", M + LARG - 180, M + 48, { width: 180, align: "right", lineBreak: false });
  doc.font("Helvetica-Bold").fontSize(20).fillColor(COR.texto).text(h(e.total), M + LARG - 180, M + 60, { width: 180, align: "right", lineBreak: false });
  doc.x = M;
  doc.y = M + 100;

  if (e.semanas.length === 0) {
    doc.font("Helvetica").fontSize(11).fillColor(COR.suave).text("Nenhuma hora lançada neste período.", M, doc.y);
  } else {
    for (const s of e.semanas) semana(doc, s);
    if (e.semanas.length > 1 || e.resumo.length > 1) resumo(doc, e);
  }

  // Rodapé em todas as páginas (só depois de saber quantas são).
  const paginas = doc.bufferedPageRange();
  for (let i = 0; i < paginas.count; i++) {
    doc.switchToPage(paginas.start + i);
    doc.page.margins.bottom = 0; // senão o texto do rodapé, rente à margem, abre página nova
    const y = PAG_A - M - 8;
    doc.font("Helvetica").fontSize(8).fillColor(COR.suave);
    doc.text(`${cab.emissor}  ·  horas registradas no timesheet  ·  gerado em ${dataBr(cab.geradoEm)}`, M, y, { width: LARG - 80, lineBreak: false });
    doc.text(`${i + 1} / ${paginas.count}`, M + LARG - 80, y, { width: 80, align: "right", lineBreak: false });
  }
  doc.end();
  return pronto;
}
