import PDFDocument from "pdfkit";
import { blocos, type Bloco, type ItemLista, type Trecho } from "@/lib/markdown";

// PDF do roteiro de teste do cliente (2026-11-14): o passo a passo que o agente
// de QA escreve em 05-roteiro-cliente.md, no mesmo desenho do espelho de horas
// (lib/espelho-horas-pdf.ts) — marca, faixa azul e laranja, título, rodapé com
// emissor e página. A4 em pé, porque aqui é texto corrido e não tabela larga.
//
// A entrada é o markdown do agente, lido por lib/markdown.ts: a mesma gramática
// que o card renderiza, e nada além dela. pdfkit com as fontes padrão
// (Helvetica cobre o português) e fora do bundle (serverExternalPackages).

const COR = { texto: "#0A0E24", suave: "#5C5A79", azul: "#3E46FA", laranja: "#FA511E", borda: "#DEDCEC", fundo: "#F6F5FB" };
const M = 48;
const PAG_L = 595.28;
const PAG_A = 841.89;
const LARG = PAG_L - 2 * M;
const RODAPE = 30; // faixa reservada ao rodapé, acima da margem
const BASE = PAG_A - M - RODAPE;
const CORPO = 10.5;
const ENTRELINHA = 3.5;

type Doc = InstanceType<typeof PDFDocument>;

export interface CabecalhoDoRoteiro {
  clienteNome: string;
  /** Código da demanda, ex.: "EPLAST-47". */
  codigo: string;
  titulo: string;
  /** Quem emite (nome que aparece no rodapé). */
  emissor: string;
  /** Dia de São Paulo em que foi gerado, "YYYY-MM-DD". */
  geradoEm: string;
}

const dataBr = (dia: string) => dia.split("-").reverse().join("/");

// As fontes padrão do PDF só têm o conjunto WinAnsi. Seta, sinal de comparação
// e caixa de seleção que o agente às vezes escreve sairiam como lixo: troca
// pelos equivalentes e descarta o resto.
const TROCAS: [RegExp, string][] = [
  [/[→➜➔⇒]/g, "->"],
  [/[←]/g, "<-"],
  [/≤/g, "<="],
  [/≥/g, ">="],
  [/≠/g, "!="],
  [/[✓✔✅]/g, "(ok)"],
  [/[✗✘❌]/g, "(x)"],
  [/[☐□]/g, "[ ]"],
  [/[☑☒]/g, "[x]"],
  [/ /g, " "],
];
const FORA_DO_WINANSI = /[^\x09\x0a\x20-\x7e¡-ÿ€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ]/g;

export function textoParaPdf(texto: string): string {
  let t = texto;
  for (const [de, para] of TROCAS) t = t.replace(de, para);
  return t.replace(FORA_DO_WINANSI, "");
}

interface Corrida {
  texto: string;
  forte: boolean;
  enfase: boolean;
  codigo: boolean;
}

function corridas(trechos: Trecho[], forte = false, enfase = false): Corrida[] {
  return trechos.flatMap((t): Corrida[] => {
    if (t.tipo === "texto") return [{ texto: t.texto, forte, enfase, codigo: false }];
    if (t.tipo === "codigo") return [{ texto: t.texto, forte, enfase, codigo: true }];
    if (t.tipo === "forte") return corridas(t.filhos, true, enfase);
    return corridas(t.filhos, forte, true);
  });
}

const textoPuro = (trechos: Trecho[]) => textoParaPdf(corridas(trechos).map((c) => c.texto).join(""));

function fonteDe(c: Corrida, negritoBase: boolean): string {
  const forte = c.forte || negritoBase;
  if (c.codigo) return forte ? "Courier-Bold" : "Courier";
  if (forte && c.enfase) return "Helvetica-BoldOblique";
  if (forte) return "Helvetica-Bold";
  return c.enfase ? "Helvetica-Oblique" : "Helvetica";
}

/** Escreve trechos com negrito, itálico e código, quebrando linha dentro de `largura`. */
function escrever(
  doc: Doc,
  trechos: Trecho[],
  x: number,
  largura: number,
  estilo: { tamanho?: number; cor?: string; negrito?: boolean } = {}
) {
  const tamanho = estilo.tamanho ?? CORPO;
  const partes = corridas(trechos)
    .map((c) => ({ ...c, texto: textoParaPdf(c.texto) }))
    .filter((c) => c.texto.length > 0);
  if (partes.length === 0) return;
  doc.fillColor(estilo.cor ?? COR.texto).fontSize(tamanho);
  partes.forEach((c, i) => {
    const opcoes = { width: largura, lineGap: ENTRELINHA, continued: i < partes.length - 1 };
    doc.font(fonteDe(c, estilo.negrito ?? false));
    if (i === 0) doc.text(c.texto, x, doc.y, opcoes);
    else doc.text(c.texto, opcoes);
  });
  doc.x = M;
}

/** Abre página nova quando o que vem a seguir não cabe até o rodapé. */
function garantir(doc: Doc, altura: number) {
  if (doc.y + altura > BASE) doc.addPage();
}

function titulo(doc: Doc, b: Extract<Bloco, { tipo: "titulo" }>) {
  const tamanho = b.nivel === 1 ? 15 : b.nivel === 2 ? 12.5 : 11;
  doc.y += b.nivel === 3 ? 6 : 12;
  // O título não fica sozinho no pé da página: leva junto o começo do que segue.
  garantir(doc, tamanho + 44);
  if (b.nivel === 2) {
    doc.rect(M, doc.y + 1, 3, tamanho).fill(COR.azul);
    escrever(doc, b.trechos, M + 10, LARG - 10, { tamanho, negrito: true });
  } else {
    escrever(doc, b.trechos, M, LARG, { tamanho, negrito: true });
  }
  doc.y += 4;
}

function item(doc: Doc, it: ItemLista, marcador: string) {
  const recuo = 20;
  garantir(doc, CORPO + ENTRELINHA + 4);
  const y = doc.y;
  if (it.marcado === null) {
    doc.font("Helvetica").fontSize(CORPO).fillColor(COR.suave).text(marcador, M + 2, y, { width: recuo - 4, lineBreak: false });
  } else {
    // Caixa desenhada: é para a pessoa marcar no papel ou no leitor de PDF.
    doc.rect(M + 3, y + 0.5, 8.5, 8.5).lineWidth(0.8).strokeColor(COR.suave).stroke();
    if (it.marcado) {
      doc.moveTo(M + 5, y + 5).lineTo(M + 7, y + 7.5).lineTo(M + 10, y + 2.5).lineWidth(1).strokeColor(COR.azul).stroke();
    }
  }
  doc.y = y;
  escrever(doc, it.trechos, M + recuo, LARG - recuo);
  if (doc.y < y + CORPO + ENTRELINHA) doc.y = y + CORPO + ENTRELINHA;
  doc.y += 2;
}

function tabela(doc: Doc, b: Extract<Bloco, { tipo: "tabela" }>) {
  const colunas = Math.max(b.cabecalho.length, ...b.linhas.map((l) => l.length), 1);
  const larg = LARG / colunas;
  const folga = 5;
  const linha = (celulas: Trecho[][], cabecalho: boolean) => {
    const fonte = cabecalho ? "Helvetica-Bold" : "Helvetica";
    doc.font(fonte).fontSize(9);
    const textos = Array.from({ length: colunas }, (_, i) => textoPuro(celulas[i] ?? []));
    const altura = Math.max(...textos.map((t) => doc.heightOfString(t || " ", { width: larg - 2 * folga, lineGap: 2 }))) + 2 * folga;
    garantir(doc, altura);
    const y = doc.y;
    if (cabecalho) doc.rect(M, y, LARG, altura).fill(COR.fundo);
    textos.forEach((t, i) => {
      doc.font(fonte).fontSize(9).fillColor(cabecalho ? COR.suave : COR.texto);
      doc.text(t, M + i * larg + folga, y + folga, { width: larg - 2 * folga, lineGap: 2 });
    });
    doc.moveTo(M, y + altura).lineTo(M + LARG, y + altura).lineWidth(0.5).strokeColor(COR.borda).stroke();
    doc.x = M;
    doc.y = y + altura;
  };
  doc.y += 4;
  if (b.cabecalho.length) linha(b.cabecalho, true);
  for (const l of b.linhas) linha(l, false);
  doc.y += 8;
}

function codigo(doc: Doc, texto: string) {
  const t = textoParaPdf(texto);
  doc.font("Courier").fontSize(8.5);
  const altura = doc.heightOfString(t, { width: LARG - 16, lineGap: 2 }) + 12;
  garantir(doc, Math.min(altura, 120));
  const y = doc.y;
  if (y + altura <= BASE) doc.rect(M, y, LARG, altura).fill(COR.fundo);
  doc.font("Courier").fontSize(8.5).fillColor(COR.texto).text(t, M + 8, y + 6, { width: LARG - 16, lineGap: 2 });
  doc.x = M;
  doc.y += 12;
}

function corpo(doc: Doc, lista: Bloco[]) {
  for (const b of lista) {
    if (b.tipo === "titulo") titulo(doc, b);
    else if (b.tipo === "paragrafo") {
      garantir(doc, CORPO + ENTRELINHA);
      escrever(doc, b.trechos, M, LARG);
      doc.y += 6;
    } else if (b.tipo === "lista") {
      b.itens.forEach((it, i) => item(doc, it, b.ordenada ? `${i + 1}.` : "•"));
      doc.y += 5;
    } else if (b.tipo === "tabela") tabela(doc, b);
    else if (b.tipo === "codigo") codigo(doc, b.texto);
    else {
      garantir(doc, 14);
      doc.moveTo(M, doc.y + 4).lineTo(M + LARG, doc.y + 4).lineWidth(0.5).strokeColor(COR.borda).stroke();
      doc.y += 14;
    }
  }
}

/** Captura de tela que entra no fim do documento (evidências de teste). */
export interface ImagemDoDocumento {
  legenda: string;
  dados: Buffer;
}

/** O que muda entre o roteiro do cliente e as evidências de teste (lib/evidencias-anexo.ts). */
export interface TipoDeDocumento {
  /** Rótulo no canto do cabeçalho e no título do PDF. */
  rotulo: string;
  /** Depois do cliente e do código, na linha abaixo do título. */
  contexto: string;
  /** Texto do rodapé, entre o código e a data. */
  rodape: string;
  /** Mensagem quando não há conteúdo. */
  vazio: string;
  imagens?: ImagemDoDocumento[];
}

const ROTEIRO: TipoDeDocumento = {
  rotulo: "Roteiro de teste",
  contexto: "homologação",
  rodape: "roteiro de teste para homologação",
  vazio: "Este roteiro está vazio.",
};

/** Capturas de tela, uma por bloco: legenda e imagem ajustada à largura da página. */
function capturas(doc: Doc, imagens: ImagemDoDocumento[]) {
  const ALTURA_MAX = 330;
  doc.addPage();
  doc.font("Helvetica-Bold").fontSize(12.5).fillColor(COR.texto);
  doc.rect(M, doc.y + 1, 3, 12.5).fill(COR.azul);
  doc.fillColor(COR.texto).text("Capturas de tela", M + 10, doc.y, { width: LARG - 10 });
  doc.x = M;
  doc.y += 8;
  imagens.forEach((img, i) => {
    garantir(doc, ALTURA_MAX + 34);
    doc.font("Helvetica-Bold").fontSize(9.5).fillColor(COR.suave);
    doc.text(textoParaPdf(`${i + 1}. ${img.legenda || "Tela"}`), M, doc.y, { width: LARG, lineGap: 2 });
    doc.y += 4;
    const y = doc.y;
    try {
      // pdfkit não devolve a altura desenhada: mede antes para avançar o cursor.
      const medida = (doc as unknown as { openImage: (b: Buffer) => { width: number; height: number } }).openImage(img.dados);
      const escala = Math.min(LARG / medida.width, ALTURA_MAX / medida.height, 1);
      const largura = medida.width * escala;
      const altura = medida.height * escala;
      doc.image(img.dados, M, y, { width: largura, height: altura });
      doc.rect(M, y, largura, altura).lineWidth(0.5).strokeColor(COR.borda).stroke();
      doc.y = y + altura + 16;
    } catch {
      doc.font("Helvetica-Oblique").fontSize(9).fillColor(COR.suave).text("(imagem ilegível)", M, y);
      doc.y += 12;
    }
    doc.x = M;
  });
}

export function gerarPdfRoteiro(
  markdown: string,
  cab: CabecalhoDoRoteiro,
  logo: Buffer | null,
  tipo: TipoDeDocumento = ROTEIRO
): Promise<Buffer> {
  const doc = new PDFDocument({
    size: "A4",
    margins: { top: M, left: M, right: M, bottom: M + RODAPE },
    bufferPages: true,
    info: { Title: textoParaPdf(`${tipo.rotulo} — ${cab.codigo} — ${cab.clienteNome}`), Author: cab.emissor },
  });
  const partes: Buffer[] = [];
  doc.on("data", (b: Buffer) => partes.push(b));
  const pronto = new Promise<Buffer>((ok) => doc.on("end", () => ok(Buffer.concat(partes))));

  // Cabeçalho da primeira página, como no espelho de horas.
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
  doc.font("Helvetica").fontSize(9).fillColor(COR.suave).text(tipo.rotulo, M, M + 8, { width: LARG, align: "right", lineBreak: false });
  doc.rect(M, M + 34, LARG / 2, 3).fill(COR.azul);
  doc.rect(M + LARG / 2, M + 34, LARG / 2, 3).fill(COR.laranja);

  doc.font("Helvetica-Bold").fontSize(17).fillColor(COR.texto);
  doc.text(textoParaPdf(cab.titulo), M, M + 50, { width: LARG, lineGap: 2 });
  doc.font("Helvetica").fontSize(10).fillColor(COR.suave);
  doc.text(textoParaPdf(`${cab.clienteNome}  ·  ${cab.codigo}  ·  ${tipo.contexto}`), M, doc.y + 4, { width: LARG });
  doc.x = M;
  doc.y += 14;

  // O agente abre o arquivo com um título próprio, que repetiria o cabeçalho.
  const lista = blocos(markdown);
  if (lista[0]?.tipo === "titulo" && lista[0].nivel === 1) lista.shift();
  if (lista.length === 0) {
    doc.font("Helvetica").fontSize(11).fillColor(COR.suave).text(tipo.vazio, M, doc.y);
  } else {
    corpo(doc, lista);
  }
  if (tipo.imagens?.length) capturas(doc, tipo.imagens);

  // Rodapé em todas as páginas (só depois de saber quantas são).
  const paginas = doc.bufferedPageRange();
  for (let i = 0; i < paginas.count; i++) {
    doc.switchToPage(paginas.start + i);
    doc.page.margins.bottom = 0; // senão o texto do rodapé, rente à margem, abre página nova
    const y = PAG_A - M - 8;
    doc.font("Helvetica").fontSize(8).fillColor(COR.suave);
    doc.text(textoParaPdf(`${cab.emissor}  ·  ${cab.codigo}  ·  ${tipo.rodape}  ·  gerado em ${dataBr(cab.geradoEm)}`), M, y, {
      width: LARG - 60,
      lineBreak: false,
    });
    doc.text(`${i + 1} / ${paginas.count}`, M + LARG - 60, y, { width: 60, align: "right", lineBreak: false });
  }
  doc.end();
  return pronto;
}
