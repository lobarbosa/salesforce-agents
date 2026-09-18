// Markdown → blocos tipados. Sem Prisma e sem React: atravessa Server e
// Client Component, e dá pra testar sem montar árvore nenhuma.
//
// Por que um parser próprio em vez de `marked`/`remark`: a restrição do
// artefato do gate é não passar conteúdo escrito por agente por um
// renderizador de HTML (ver DemandModal). Uma biblioteca de markdown devolve
// **string de HTML**, o que obriga a `dangerouslySetInnerHTML` mais um
// sanitizador — duas dependências e uma superfície de injeção pra manter. Aqui
// a saída é estrutura de dados: quem renderiza monta elemento React, e o React
// escapa texto por construção. A gramática coberta é exatamente a que os
// agentes emitem (inventariada nos artefatos reais de ACXYA-1): h1-h3,
// parágrafo, lista, checkbox, tabela, bloco de código, régua, e inline
// `código`, **forte** e *ênfase*.
//
// Link não é suportado de propósito: os agentes não emitem, e um link escrito
// por agente apontando pra qualquer lugar é mais uma coisa que a tela de quem
// aprova teria que confiar. Fica como texto literal.

// `forte` e `enfase` carregam filhos, não texto: negrito contendo código é
// comum nestes documentos (**somente leitura + `sf project deploy validate`**)
// e, sem reparsear o conteúdo, as crases saíam literais na tela. `codigo` é
// folha por definição — dentro de crase nada é marcação.
export type Trecho =
  | { tipo: "texto"; texto: string }
  | { tipo: "codigo"; texto: string }
  | { tipo: "forte"; filhos: Trecho[] }
  | { tipo: "enfase"; filhos: Trecho[] };

export type ItemLista = {
  trechos: Trecho[];
  /** null = item comum; true/false = checkbox marcado/desmarcado. */
  marcado: boolean | null;
};

export type Bloco =
  | { tipo: "titulo"; nivel: 1 | 2 | 3; trechos: Trecho[] }
  | { tipo: "paragrafo"; trechos: Trecho[] }
  | { tipo: "lista"; ordenada: boolean; itens: ItemLista[] }
  | { tipo: "tabela"; cabecalho: Trecho[][]; linhas: Trecho[][][] }
  | { tipo: "codigo"; texto: string }
  | { tipo: "regra" };

// Ordem importa: o código vem primeiro pra que `**` dentro de crase seja
// tratado como código, não como negrito.
const INLINE = /(`[^`]+`|\*\*[^*]+\*\*|\*[^*\s][^*]*\*)/g;

export function inline(texto: string): Trecho[] {
  const partes: Trecho[] = [];
  let fim = 0;
  for (const m of texto.matchAll(INLINE)) {
    const i = m.index ?? 0;
    if (i > fim) partes.push({ tipo: "texto", texto: texto.slice(fim, i) });
    const bruto = m[0];
    // A recursão termina sempre: o conteúdo é estritamente menor que o trecho.
    if (bruto.startsWith("`")) partes.push({ tipo: "codigo", texto: bruto.slice(1, -1) });
    else if (bruto.startsWith("**")) partes.push({ tipo: "forte", filhos: inline(bruto.slice(2, -2)) });
    else partes.push({ tipo: "enfase", filhos: inline(bruto.slice(1, -1)) });
    fim = i + bruto.length;
  }
  if (fim < texto.length) partes.push({ tipo: "texto", texto: texto.slice(fim) });
  return partes;
}

const TITULO = /^(#{1,6})\s+(.*)$/;
const ITEM = /^\s*[-*+]\s+(.*)$/;
const ITEM_NUM = /^\s*\d+[.)]\s+(.*)$/;
const CHECKBOX = /^\[([ xX])\]\s+(.*)$/;
const REGRA = /^\s*([-*_])\s*\1\s*\1[\s\-*_]*$/;
const CERCA = /^\s*```/;

/** Divide `| a | b |` nas células, sem as barras das pontas.
 *
 * `\|` é barra literal, não separador — é assim que se põe uma barra dentro
 * de célula, e os agentes usam: uma linha de saída de query com
 * `` `campo \| label \| date` `` dentro de uma célula de código. Um split
 * ingênuo em "|" quebrava essa linha em 11 células contra 7 do cabeçalho, e a
 * tabela inteira saía torta (achado real no 05-testes.md do ACXYA-1 — o
 * artefato que o cliente lê no gate de homologação).
 */
function celulas(linha: string): string[] {
  const dentro = linha.replace(/^\s*\|/, "").replace(/(?<!\\)\|\s*$/, "");
  const saida: string[] = [];
  let atual = "";
  for (let i = 0; i < dentro.length; i++) {
    if (dentro[i] === "\\" && dentro[i + 1] === "|") {
      atual += "|";
      i++;
    } else if (dentro[i] === "|") {
      saida.push(atual.trim());
      atual = "";
    } else {
      atual += dentro[i];
    }
  }
  saida.push(atual.trim());
  return saida;
}

const SEPARADOR_TABELA = /^\s*\|?[\s:|-]+\|[\s:|-]*$/;

export function blocos(fonte: string): Bloco[] {
  const linhas = fonte.replace(/\r\n?/g, "\n").split("\n");
  const saida: Bloco[] = [];
  let paragrafo: string[] = [];

  // Parágrafo hard-wrapped vira uma linha só: os agentes quebram a prosa por
  // volta da coluna 95, e preservar essas quebras deixaria a coluna de leitura
  // esfarrapada num container de largura diferente.
  const fecharParagrafo = () => {
    if (paragrafo.length === 0) return;
    saida.push({ tipo: "paragrafo", trechos: inline(paragrafo.join(" ")) });
    paragrafo = [];
  };

  for (let i = 0; i < linhas.length; i++) {
    const linha = linhas[i];

    if (CERCA.test(linha)) {
      fecharParagrafo();
      const corpo: string[] = [];
      i++;
      while (i < linhas.length && !CERCA.test(linhas[i])) corpo.push(linhas[i++]);
      saida.push({ tipo: "codigo", texto: corpo.join("\n") });
      continue;
    }

    if (linha.trim() === "") {
      fecharParagrafo();
      continue;
    }

    if (REGRA.test(linha)) {
      fecharParagrafo();
      saida.push({ tipo: "regra" });
      continue;
    }

    const t = TITULO.exec(linha);
    if (t) {
      fecharParagrafo();
      const nivel = Math.min(t[1].length, 3) as 1 | 2 | 3;
      saida.push({ tipo: "titulo", nivel, trechos: inline(t[2].trim()) });
      continue;
    }

    // Tabela: cabeçalho + separador (|---|) + corpo. Sem o separador na
    // segunda linha não é tabela — é texto que por acaso tem barra.
    if (linha.trimStart().startsWith("|") && SEPARADOR_TABELA.test(linhas[i + 1] ?? "")) {
      fecharParagrafo();
      const cabecalho = celulas(linha).map(inline);
      i += 2;
      const corpo: Trecho[][][] = [];
      while (i < linhas.length && linhas[i].trimStart().startsWith("|")) {
        const cels = celulas(linhas[i]);
        // Linha torta não derruba a tabela: sobra vira célula a menos, falta
        // vira célula vazia. Renderizar <td> a mais que <th> desalinha a
        // tabela inteira, e o documento é escrito por agente — não dá pra
        // supor que toda linha veio bem formada.
        while (cels.length < cabecalho.length) cels.push("");
        corpo.push(cels.slice(0, cabecalho.length).map(inline));
        i++;
      }
      i--;
      saida.push({ tipo: "tabela", cabecalho, linhas: corpo });
      continue;
    }

    const num = ITEM_NUM.exec(linha);
    const marc = num ? null : ITEM.exec(linha);
    if (num || marc) {
      fecharParagrafo();
      const ordenada = !!num;
      const brutos: string[] = [];
      while (i < linhas.length) {
        const atual = linhas[i];
        const m = ordenada ? ITEM_NUM.exec(atual) : ITEM.exec(atual);
        if (m) {
          brutos.push(m[1]);
          i++;
          continue;
        }
        // Continuação do item anterior: os agentes quebram o item por volta da
        // coluna 95, e tratar a segunda linha como parágrafo separado partia o
        // item em dois — pior, um `**negrito**` que abria na primeira linha e
        // fechava na segunda vazava como asterisco na tela.
        const continua =
          brutos.length > 0 &&
          atual.trim() !== "" &&
          !TITULO.test(atual) &&
          !REGRA.test(atual) &&
          !CERCA.test(atual) &&
          !atual.trimStart().startsWith("|");
        if (!continua) break;
        brutos[brutos.length - 1] += ` ${atual.trim()}`;
        i++;
      }
      i--;
      const itens: ItemLista[] = brutos.map((bruto) => {
        const check = CHECKBOX.exec(bruto);
        return check
          ? { trechos: inline(check[2]), marcado: check[1].toLowerCase() === "x" }
          : { trechos: inline(bruto), marcado: null };
      });
      saida.push({ tipo: "lista", ordenada, itens });
      continue;
    }

    paragrafo.push(linha.trim());
  }

  fecharParagrafo();
  return saida;
}
