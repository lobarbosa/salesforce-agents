// Parser do artefato do gate, contra a gramática que os agentes realmente
// emitem — inventariada nos artefatos reais de clients/acxya/demandas/ACXYA-1.
// Sem React e sem DOM: o parser devolve estrutura de dados, e é isso que dá
// pra travar em teste.
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { blocos, inline, type Bloco, type Trecho } from "@/lib/markdown";

let falhas = 0;
function caso(nome: string, fn: () => void) {
  try {
    fn();
    console.log(`ok    ${nome}`);
  } catch (e) {
    falhas++;
    console.log(`FALHA ${nome}\n        ${(e as Error).message.split("\n")[0]}`);
  }
}

const plano = (trechos: Trecho[]): string =>
  trechos.map((t) => ("filhos" in t ? plano(t.filhos) : t.texto)).join("");
const texto = (b: Bloco): string => ("trechos" in b ? plano(b.trechos) : "");

caso("titulo por nivel, com teto em 3", () => {
  const b = blocos("# um\n\n## dois\n\n### tres\n\n#### quatro");
  assert.deepEqual(
    b.map((x) => (x.tipo === "titulo" ? x.nivel : null)),
    [1, 2, 3, 3]
  );
});

caso("paragrafo hard-wrapped vira uma linha so", () => {
  const b = blocos("uma frase que o agente\nquebrou no meio\n\noutra");
  assert.equal(b.length, 2);
  assert.equal(texto(b[0]), "uma frase que o agente quebrou no meio");
});

caso("tabela com cabecalho e corpo", () => {
  const b = blocos("| a | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |");
  assert.equal(b[0].tipo, "tabela");
  if (b[0].tipo !== "tabela") return;
  assert.equal(b[0].cabecalho.length, 2);
  assert.equal(b[0].linhas.length, 2);
  assert.equal(plano(b[0].linhas[1][1]), "4");
});

caso("barra escapada e conteudo, nao separador de celula", () => {
  // Achado real no 05-testes.md do ACXYA-1: célula de código com a saída de
  // uma query, `campo \| label \| date`. Sem honrar o escape, a linha virava
  // 5 células contra 3 do cabeçalho e a tabela saía torta.
  const b = blocos("| a | b | c |\n|---|---|---|\n| x | `p \\| q \\| r` | z |");
  assert.equal(b[0].tipo, "tabela");
  if (b[0].tipo !== "tabela") return;
  assert.equal(b[0].linhas[0].length, 3);
  assert.equal(plano(b[0].linhas[0][1]), "p | q | r");
});

caso("linha torta nao derruba a tabela", () => {
  const b = blocos("| a | b | c |\n|---|---|---|\n| so uma |\n| 1 | 2 | 3 | 4 |");
  assert.equal(b[0].tipo, "tabela");
  if (b[0].tipo !== "tabela") return;
  assert.deepEqual(b[0].linhas.map((l) => l.length), [3, 3]);
});

caso("barra sem separador nao vira tabela", () => {
  // Prosa com barra no meio acontece ("Flow | Apex"); sem a linha de |---|
  // embaixo não é tabela.
  const b = blocos("| isto e prosa com barra");
  assert.equal(b[0].tipo, "paragrafo");
});

caso("bloco de codigo preserva o conteudo literal", () => {
  const b = blocos("```bash\nsf org list\n**nao e negrito**\n```");
  assert.equal(b[0].tipo, "codigo");
  if (b[0].tipo !== "codigo") return;
  assert.equal(b[0].texto, "sf org list\n**nao e negrito**");
});

caso("lista ordenada e nao ordenada", () => {
  const b = blocos("- um\n- dois\n\n1. tres\n2. quatro");
  assert.equal(b[0].tipo, "lista");
  assert.equal(b[1].tipo, "lista");
  if (b[0].tipo !== "lista" || b[1].tipo !== "lista") return;
  assert.equal(b[0].ordenada, false);
  assert.equal(b[1].ordenada, true);
  assert.equal(b[0].itens.length, 2);
});

caso("checkbox vira item marcado, nao texto com colchete", () => {
  // É a mesma sintaxe que revisao.py lê pra extrair pendência do gate — se o
  // parser tratasse como texto comum, a tela mostraria "[ ] premissa".
  const b = blocos("- [ ] premissa aberta\n- [x] premissa resolvida");
  assert.equal(b[0].tipo, "lista");
  if (b[0].tipo !== "lista") return;
  assert.deepEqual(b[0].itens.map((i) => i.marcado), [false, true]);
  assert.equal(plano(b[0].itens[0].trechos), "premissa aberta");
});

caso("item de lista quebrado em duas linhas continua sendo um item", () => {
  // Achado real ao olhar o 05-testes.md renderizado: os agentes quebram o
  // item por volta da coluna 95. Sem juntar a continuação, o item virava dois
  // blocos e um **negrito** que abria numa linha e fechava na outra vazava
  // como asterisco na tela.
  const b = blocos("- **T-16** (3 Flows) — **passou,\n  consistente em 3 repetições**\n- outro");
  assert.equal(b.length, 1);
  if (b[0].tipo !== "lista") return;
  assert.equal(b[0].itens.length, 2);
  const fortes = b[0].itens[0].trechos.filter((t) => t.tipo === "forte");
  assert.equal(fortes.length, 2);
  assert.equal(plano([fortes[1]]), "passou, consistente em 3 repetições");
});

caso("continuacao para no que nao e continuacao", () => {
  const b = blocos("- um\n  continua\n\n## titulo");
  assert.equal(b.length, 2);
  assert.equal(b[1].tipo, "titulo");
});

caso("inline: codigo, forte e enfase", () => {
  const t = inline("veja `sf org list` e **isto** e *aquilo*");
  assert.deepEqual(
    t.filter((x) => x.tipo !== "texto").map((x) => [x.tipo, plano([x])]),
    [["codigo", "sf org list"], ["forte", "isto"], ["enfase", "aquilo"]]
  );
});

caso("negrito contendo codigo reparseia o conteudo", () => {
  // Achado real ao olhar o 03-design.md renderizado: "**somente leitura +
  // `sf project deploy validate`**". Sem reparsear o conteúdo do negrito, as
  // crases apareciam literais na tela dentro do texto em negrito.
  const t = inline("**leitura + `sf project deploy validate` (check-only)**");
  assert.equal(t.length, 1);
  assert.equal(t[0].tipo, "forte");
  if (t[0].tipo !== "forte") return;
  assert.deepEqual(
    t[0].filhos.map((f) => f.tipo),
    ["texto", "codigo", "texto"]
  );
  assert.equal(plano(t[0].filhos), "leitura + sf project deploy validate (check-only)");
});

caso("asterisco dentro de crase continua sendo codigo", () => {
  const t = inline("`a ** b`");
  assert.equal(t.length, 1);
  assert.equal(t[0].tipo, "codigo");
});

caso("html no fonte sobrevive como texto, nunca como marcacao", () => {
  // O conteúdo é escrito por agente. O parser não tem ramo que produza HTML:
  // o que entrar como texto sai como texto, e quem renderiza usa React, que
  // escapa. Este caso existe pra travar isso.
  const b = blocos("<script>alert(1)</script> e <b>bold</b>");
  assert.equal(b[0].tipo, "paragrafo");
  assert.equal(texto(b[0]), "<script>alert(1)</script> e <b>bold</b>");
});

// Os artefatos reais são o teste que importa: gramática inventariada neles.
// `../../../` sai de apps/squad-os/scripts até a raiz do repositório.
const reais = "../../../clients/acxya/demandas/ACXYA-1";
for (const nome of ["01-analise.md", "03-design.md", "05-testes.md", "06-entrega.md"]) {
  const caminho = new URL(`${reais}/${nome}`, import.meta.url).pathname;
  // Falha alto em vez de pular: um caso que some do relatório quando o
  // caminho quebra é pior que caso nenhum — passa a impressão de coberto.
  caso(`artefato real: ${nome}`, () => {
    assert.ok(existsSync(caminho), `não achei ${caminho}`);
    const doc = blocos(readFileSync(caminho, "utf8"));
    assert.ok(doc.length > 10, "documento vazio ou quase");
    // Nenhum bloco pode sair com trecho indefinido — é o sintoma de índice
    // solto no parser, e apareceria na tela como "undefined".
    for (const b of doc) {
      if ("trechos" in b) assert.equal(typeof plano(b.trechos), "string");
      if (b.tipo === "tabela") {
        for (const linha of b.linhas) {
          assert.equal(linha.length, b.cabecalho.length, `linha com nº de células diferente do cabeçalho em ${nome}`);
        }
      }
    }
  });
}

caso("03-design.md: as tabelas viram tabela mesmo", () => {
  const caminho = new URL(`${reais}/03-design.md`, import.meta.url).pathname;
  assert.ok(existsSync(caminho), `não achei ${caminho}`);
  const doc = blocos(readFileSync(caminho, "utf8"));
  const tabelas = doc.filter((b) => b.tipo === "tabela");
  assert.ok(tabelas.length >= 5, `esperava várias tabelas, achei ${tabelas.length}`);
});

console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
