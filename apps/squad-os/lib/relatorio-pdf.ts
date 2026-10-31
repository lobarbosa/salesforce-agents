import PDFDocument from "pdfkit";
import { nomeDoMes, formatarHoras as h, type DadosRelatorio } from "@/lib/relatorio-mensal";

// PDF detalhado do relatório mensal (2026-10-31). O e-mail leva os tópicos
// principais; aqui vai o detalhe: cada demanda concluída com data e horas,
// e o contrato mês a mês (AMS) ou por entregável (projeto).
//
// pdfkit com as fontes padrão (Helvetica): sem webfont para empacotar, e o
// WinAnsi delas cobre acentuação do português. Símbolos fora dele (✓) ficam
// de fora de propósito. `next.config.ts` mantém o pdfkit fora do bundle
// (serverExternalPackages) porque ele lê as métricas das fontes do disco.

const COR = { texto: "#0A0E24", suave: "#5C5A79", azul: "#3E46FA", laranja: "#D63505", verde: "#2B7A45", borda: "#DEDCEC", trilho: "#EEEDF6", fundo: "#F6F5FB" };
const M = 48; // margem
const LARG = 595.28 - 2 * M; // A4

type Doc = InstanceType<typeof PDFDocument>;

function titulo(doc: Doc, t: string) {
  if (doc.y > 700) doc.addPage();
  doc.moveDown(1.2);
  doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.suave).text(t.toUpperCase(), M, doc.y, { characterSpacing: 0.8 });
  doc.moveTo(M, doc.y + 4).lineTo(M + LARG, doc.y + 4).lineWidth(0.6).strokeColor(COR.borda).stroke();
  doc.moveDown(0.8);
}

function barra(doc: Doc, pct: number, cor: string, rotulo: string) {
  const y = doc.y;
  doc.font("Helvetica").fontSize(9.5).fillColor(COR.suave).text(rotulo, M, y);
  const by = doc.y + 3;
  doc.roundedRect(M, by, LARG, 8, 4).fill(COR.trilho);
  const p = Math.max(0, Math.min(100, pct));
  if (p > 0) doc.roundedRect(M, by, (LARG * p) / 100, 8, 4).fill(cor);
  doc.y = by + 16;
}

/** Tabela simples: cabeçalho cinza, linhas com divisória. */
function tabela(doc: Doc, colunas: { t: string; w: number; alinhar?: "left" | "right" }[], linhas: string[][]) {
  const linha = (cel: string[], negrito: boolean, cor: string) => {
    if (doc.y > 760) doc.addPage();
    const y = doc.y;
    let x = M;
    let alt = 0;
    cel.forEach((v, i) => {
      const c = colunas[i];
      doc.font(negrito ? "Helvetica-Bold" : "Helvetica").fontSize(9.5).fillColor(cor);
      alt = Math.max(alt, doc.heightOfString(v, { width: c.w - 8 }));
      doc.text(v, x + 4, y + 5, { width: c.w - 8, align: c.alinhar ?? "left" });
      x += c.w;
    });
    doc.y = y + alt + 10;
    doc.moveTo(M, doc.y).lineTo(M + LARG, doc.y).lineWidth(0.5).strokeColor(COR.borda).stroke();
  };
  const y0 = doc.y;
  doc.rect(M, y0, LARG, 20).fill(COR.fundo);
  doc.y = y0;
  linha(colunas.map((c) => c.t), true, COR.suave);
  for (const l of linhas) linha(l, false, COR.texto);
}

function kpis(doc: Doc, itens: { valor: string; rotulo: string; cor?: string }[]) {
  const y = doc.y;
  const w = (LARG - 16) / itens.length;
  itens.forEach((k, i) => {
    const x = M + i * (w + 8);
    doc.roundedRect(x, y, w, 56, 8).lineWidth(0.8).strokeColor(COR.borda).stroke();
    doc.font("Helvetica-Bold").fontSize(18).fillColor(k.cor ?? COR.texto).text(k.valor, x + 12, y + 10, { width: w - 24 });
    doc.font("Helvetica").fontSize(9).fillColor(COR.suave).text(k.rotulo, x + 12, y + 34, { width: w - 24 });
  });
  doc.y = y + 64;
}

const dataBr = (iso?: string) => (iso ? iso.split("-").reverse().join("/") : "—");
const mesCurto = (chave: string) => {
  const [a, m] = chave.split("-");
  return `${["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"][Number(m) - 1]}/${a.slice(2)}`;
};

export function gerarPdfRelatorio(d: DadosRelatorio, logo: Buffer | null): Promise<Buffer> {
  const doc = new PDFDocument({ size: "A4", margin: M, info: { Title: `${d.clienteNome} — ${nomeDoMes(d.mes)}`, Author: "Konecta" } });
  const partes: Buffer[] = [];
  doc.on("data", (b: Buffer) => partes.push(b));
  const pronto = new Promise<Buffer>((ok) => doc.on("end", () => ok(Buffer.concat(partes))));

  // Cabeçalho
  if (logo) {
    try {
      doc.image(logo, M, M, { height: 26 });
    } catch {
      doc.font("Helvetica-Bold").fontSize(16).fillColor(COR.azul).text("Konecta", M, M);
    }
  } else {
    doc.font("Helvetica-Bold").fontSize(16).fillColor(COR.azul).text("Konecta", M, M);
  }
  doc.font("Helvetica").fontSize(9).fillColor(COR.suave).text("Relatório mensal", M, M + 8, { width: LARG, align: "right" });
  doc.rect(M, M + 38, LARG / 2, 3).fill(COR.azul);
  doc.rect(M + LARG / 2, M + 38, LARG / 2, 3).fill("#FA511E");
  doc.y = M + 54;
  doc.font("Helvetica").fontSize(11).fillColor(COR.suave).text(d.clienteNome, M);
  const mesNome = nomeDoMes(d.mes);
  doc.font("Helvetica-Bold").fontSize(22).fillColor(COR.texto).text(mesNome.charAt(0).toUpperCase() + mesNome.slice(1), M);
  doc.moveDown(0.8);

  // Indicadores
  const c = d.contrato;
  const ks: { valor: string; rotulo: string; cor?: string }[] = [
    { valor: String(d.entregues.length), rotulo: d.entregues.length === 1 ? "demanda concluída" : "demandas concluídas", cor: COR.verde },
  ];
  if (c?.tipo === "ams") {
    const m = c.doMes;
    ks.push({ valor: h(m?.horasGastas ?? 0), rotulo: "horas no mês", cor: COR.azul });
    if (m && m.horasContratadas > 0) {
      const pct = Math.round((m.horasNoCiclo / m.horasContratadas) * 100);
      ks.push({ valor: `${pct}%`, rotulo: c.cicloHoras === "mensal" ? "do contratado no mês" : "do ciclo", cor: pct > 100 ? COR.laranja : COR.texto });
    }
  } else if (c?.tipo === "projeto") {
    ks.push({ valor: `${c.progresso.pct}%`, rotulo: "do escopo entregue", cor: COR.azul });
    ks.push({ valor: h(c.horasDoMes), rotulo: "horas no mês" });
  }
  kpis(doc, ks);

  // Demandas concluídas
  titulo(doc, "Demandas concluídas no mês");
  if (d.entregues.length) {
    tabela(
      doc,
      [
        { t: "Demanda", w: 110 },
        { t: "Título", w: LARG - 110 - 70 - 70 - 70 },
        { t: "Entregue em", w: 70 },
        { t: "Aprovadas", w: 70, alinhar: "right" },
        { t: "Lançadas", w: 70, alinhar: "right" },
      ],
      d.entregues.map((e) => [
        e.code,
        e.titulo,
        dataBr(e.entregueEm),
        e.horasAprovadas != null ? h(e.horasAprovadas) : "—",
        e.horasLancadas != null ? h(e.horasLancadas) : "—",
      ])
    );
    doc.moveDown(0.4);
    doc.font("Helvetica").fontSize(8.5).fillColor(COR.suave).text(
      "Aprovadas: estimativa aprovada por você, que é o que debita do contrato. Lançadas: horas registradas pela equipe na demanda.",
      M,
      doc.y,
      { width: LARG }
    );
  } else {
    doc.font("Helvetica").fontSize(10).fillColor(COR.suave).text("Nenhuma demanda foi concluída neste mês.", M);
  }

  // Contrato
  if (c?.tipo === "ams") {
    titulo(doc, "Contrato de sustentação (AMS)");
    const m = c.doMes;
    if (m && m.horasContratadas > 0) {
      const pct = (m.horasNoCiclo / m.horasContratadas) * 100;
      barra(doc, pct, pct > 100 ? COR.laranja : COR.azul, `Consumo ${c.cicloHoras === "mensal" ? "do mês" : "do ciclo"}: ${h(m.horasNoCiclo)} de ${h(m.horasContratadas)}`);
      const saldo = m.horasContratadas - m.horasNoCiclo;
      doc.font("Helvetica-Bold").fontSize(10).fillColor(saldo >= 0 ? COR.verde : COR.laranja).text(saldo >= 0 ? `Saldo: ${h(saldo)}` : `Excedente: ${h(-saldo)} acima do contratado`, M);
    }
    if (c.historico?.length) {
      doc.moveDown(0.8);
      doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.texto).text("Últimos meses", M);
      doc.moveDown(0.4);
      tabela(
        doc,
        [
          { t: "Mês", w: LARG * 0.25 },
          { t: "Horas no mês", w: LARG * 0.25, alinhar: "right" },
          { t: "Contratadas", w: LARG * 0.25, alinhar: "right" },
          { t: "Uso", w: LARG * 0.25, alinhar: "right" },
        ],
        c.historico.map((x) => [
          mesCurto(x.mes),
          h(x.horasGastas),
          x.horasContratadas ? h(x.horasContratadas) : "—",
          x.horasContratadas ? `${Math.round((x.horasNoCiclo / x.horasContratadas) * 100)}%` : "—",
        ])
      );
    }
  } else if (c?.tipo === "projeto") {
    titulo(doc, `Projeto${c.nome ? ` · ${c.nome}` : ""}`);
    barra(doc, c.progresso.pct, COR.azul, `Escopo: ${c.progresso.concluidos} de ${c.progresso.total} entregáveis (${c.progresso.pct}%, ponderado pelo peso)`);
    if (c.horasContratadas > 0) {
      const pctH = (c.horasAcumuladas / c.horasContratadas) * 100;
      barra(doc, pctH, pctH > 100 ? COR.laranja : COR.verde, `Horas: ${h(c.horasAcumuladas)} de ${h(c.horasContratadas)} contratadas`);
    }
    if (c.fimPrevisto) {
      doc.font("Helvetica").fontSize(9.5).fillColor(COR.suave).text(`Término previsto: ${dataBr(c.fimPrevisto)}`, M);
    }
    if (c.entregaveis?.length) {
      doc.moveDown(0.8);
      doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.texto).text("Entregáveis", M);
      doc.moveDown(0.4);
      tabela(
        doc,
        [
          { t: "Entregável", w: LARG - 60 - 80 - 90 },
          { t: "Peso", w: 60, alinhar: "right" },
          { t: "Demandas", w: 80, alinhar: "right" },
          { t: "Situação", w: 90 },
        ],
        c.entregaveis.map((e) => [
          e.titulo,
          String(e.peso),
          e.demandas.total ? `${e.demandas.entregues}/${e.demandas.total}` : "—",
          e.concluido ? "Concluído" : e.demandas.entregues > 0 ? "Em andamento" : "A iniciar",
        ])
      );
    }
    if (c.historico?.length) {
      doc.moveDown(0.8);
      doc.font("Helvetica-Bold").fontSize(10).fillColor(COR.texto).text("Horas por mês", M);
      doc.moveDown(0.4);
      tabela(doc, [{ t: "Mês", w: LARG / 2 }, { t: "Horas", w: LARG / 2, alinhar: "right" }], c.historico.map((x) => [mesCurto(x.mes), h(x.horasGastas)]));
    }
  }

  doc.moveDown(1.5);
  doc.font("Helvetica").fontSize(8.5).fillColor(COR.suave).text(`Acompanhe pelo portal: ${d.url}`, M, doc.y, { width: LARG, link: d.url });
  doc.end();
  return pronto;
}
