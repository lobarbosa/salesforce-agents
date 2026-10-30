import assert from "node:assert/strict";
import { lerVereditoQa, orgEhDeQa } from "../lib/qa-veredito";

let falhas = 0;
function caso(nome: string, fn: () => void) {
  try {
    fn();
    console.log(`ok ${nome}`);
  } catch (e) {
    falhas++;
    console.log(`FALHA ${nome}\n${(e as Error).message}`);
  }
}

caso("veredito explícito vence", () => {
  const v = lerVereditoQa("**Veredito:** aprovado\n\n### FALHA 1 (branda) — algo");
  assert.equal(v.veredito, "aprovado");
  assert.equal(v.falhas.length, 1);
});
caso("sem veredito, título FALHA reprova e marca crítica", () => {
  const v = lerVereditoQa("**Org de teste:** `sbx-somos-agility-qa` (x)\n\n### FALHA 1 (crítica) — CPU\n\n### FALHA 2 — fixture");
  assert.equal(v.veredito, "reprovado");
  assert.deepEqual(v.falhas.map((f) => f.critica), [true, false]);
  assert.equal(v.org, "sbx-somos-agility-qa");
  assert.ok(orgEhDeQa(v.org));
});
caso("seção '## Falhas' sem falha não reprova", () => {
  assert.equal(lerVereditoQa("## Falhas\n\nNenhuma.").veredito, "indefinido");
});
caso("org de dev não é de QA", () => {
  assert.ok(!orgEhDeQa("sbx-somos-agility-dev"));
});

if (falhas) {
  console.log(`${falhas} falha(s)`);
  process.exit(1);
}
