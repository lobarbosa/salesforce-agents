import assert from "node:assert/strict";
import { checklist, competenciaPadrao, ehTipoDoc, tipoPeloNome } from "../lib/contabilidade";

function caso(nome: string, fn: () => void) {
  fn();
  console.log(`ok    ${nome}`);
}

caso("checklist conta balancete ou DRE no mesmo item", () => {
  const c = checklist(["dre", "guia_imposto", "guia_imposto", "outro"]);
  assert.deepEqual(c.map((i) => i.recebidos), [1, 2, 0]);
});

caso("checklist vazio mostra tudo faltando", () => {
  assert.ok(checklist([]).every((i) => i.recebidos === 0));
});

caso("tipo pelo nome do arquivo", () => {
  assert.equal(tipoPeloNome("Balancete Set-2026.pdf"), "balancete");
  assert.equal(tipoPeloNome("DRE_09_2026.xlsx"), "dre");
  assert.equal(tipoPeloNome("DARF IRPJ.pdf"), "guia_imposto");
  assert.equal(tipoPeloNome("Guia ISS setembro.pdf"), "guia_imposto");
  assert.equal(tipoPeloNome("Relação de notas.csv"), "relacao_notas");
  assert.equal(tipoPeloNome("carta.docx"), "outro");
});

caso("competência padrão é o mês anterior", () => {
  assert.equal(competenciaPadrao("2026-09"), "2026-08");
  assert.equal(competenciaPadrao("2026-01"), "2025-12");
});

caso("tipo válido", () => {
  assert.ok(ehTipoDoc("dre"));
  assert.ok(!ehTipoDoc("boleto"));
});

console.log("\ntodos ok");
