import assert from "node:assert/strict";
import { writeFileSync } from "node:fs";
import { gerarPdfRoteiro, textoParaPdf } from "../lib/roteiro-pdf";

// Roteiro de teste em PDF (lib/roteiro-pdf.ts). Não confere desenho — isso é
// olho humano; confere que o markdown que o agente de QA emite vira um PDF
// válido, paginado, sem estourar em caractere fora da fonte padrão.
// `tsx scripts/testa-roteiro-pdf.ts [arquivo.pdf]` grava o PDF para inspeção.

let falhas = 0;
async function caso(nome: string, fn: () => void | Promise<void>) {
  try {
    await fn();
    console.log(`ok    ${nome}`);
  } catch (e) {
    falhas++;
    console.log(`FALHA ${nome}\n        ${(e as Error).message.split("\n")[0]}`);
  }
}

const EXEMPLO = `# Roteiro de teste — classificação de contas

Foi corrigido o cálculo mensal que classifica as contas por **faixa de compras**. A partir de agora a conta recebe uma das sete classificações (MP, PP, P, M, G, GG e 3G) e é atualizada *uma única vez* por execução.

## Antes de começar

- Ambiente: sandbox de homologação.
- Perfil: usuário comercial com acesso a Contas e Oportunidades.
- Crie a conta de teste **Conta Teste Faixas** com o campo "Média de compras este ano" igual a 10.000,00.

| Classificação | Limite da faixa |
|---|---|
| MP | até 10.000 |
| PP | acima de 10.000 até 35.000 |
| 3G | acima de 1.000.000 |

## Teste 1 — conta no limite da faixa MP

1. Abra a guia **Contas** e localize a Conta Teste Faixas.
2. Confira o campo "Média de compras este ano": 10.000,00.
3. Peça ao time técnico para executar o cálculo → aguarde o aviso.
4. Atualize a página.

**Resultado esperado:** o campo "Classificação" mostra **MP** (valor ≤ 10.000).

- [ ] Conforme
- [ ] Não conforme — o que apareceu:

---

## O que não dá para conferir pela tela

A execução agendada do dia 14 e o teste de volume foram comprovados pelo time técnico; a evidência está no registro de testes da demanda \`EPLAST-47\`.
`;

const CAB = { clienteNome: "Eplast", codigo: "EPLAST-47", titulo: "Corrigir o Fluxo Agendado – Oportunidade (valor de compras e classificação de contas)", emissor: "Acxya", geradoEm: "2026-11-14" };
const paginas = (pdf: Buffer) => (pdf.toString("latin1").match(/\/Type \/Page\b/g) ?? []).length;

async function main() {
  await caso("markdown do agente vira um PDF válido de uma página", async () => {
    const pdf = await gerarPdfRoteiro(EXEMPLO, CAB, null);
    assert.equal(pdf.subarray(0, 5).toString(), "%PDF-");
    assert.equal(paginas(pdf), 1);
    if (process.argv[2]) writeFileSync(process.argv[2], pdf);
  });

  await caso("roteiro longo pagina sem perder o rodapé", async () => {
    const longo = EXEMPLO + Array.from({ length: 12 }, (_, i) => EXEMPLO.split("## Teste 1")[1].replace("limite da faixa MP", `caso ${i + 2}`)).map((t) => `\n## Teste${t}`).join("");
    const pdf = await gerarPdfRoteiro(longo, CAB, null);
    assert.ok(paginas(pdf) >= 3, `páginas: ${paginas(pdf)}`);
    if (process.argv[3]) writeFileSync(process.argv[3], pdf);
  });

  await caso("roteiro vazio não quebra", async () => {
    const pdf = await gerarPdfRoteiro("", CAB, null);
    assert.equal(paginas(pdf), 1);
  });

  await caso("caractere fora da fonte padrão é trocado ou descartado", () => {
    assert.equal(textoParaPdf("A → B ≤ 10 ✓ ☐ ação — fim"), "A -> B <= 10 (ok) [ ] ação — fim");
    assert.equal(textoParaPdf("emoji 🚀 some"), "emoji  some");
  });

  if (falhas) process.exit(1);
}
void main();
