import assert from "node:assert/strict";
import { buildBloqueado, gateDeBuildBloqueado } from "../lib/build-bloqueado";

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

caso("linha explícita decide", () => {
  assert.ok(buildBloqueado("**Resultado do build:** bloqueado\n\nFalta D1."));
  assert.ok(!buildBloqueado("**Resultado do build:** concluído\n\n## Execução bloqueada até confirmação"));
});
caso("planos antigos da Somos são lidos como bloqueados", () => {
  for (const t of [
    "**Resultado desta etapa: BUILD BLOQUEADO. Nenhum componente foi criado.**",
    "# 04 — Build: BLOQUEADO (não é um plano de build concluído)",
    "## Resultado desta tentativa: build não executado",
    "## Execução bloqueada até confirmação",
    "**Status: BUILD BLOQUEADO. Nenhum metadata foi criado ou alterado.**",
  ]) {
    assert.ok(buildBloqueado("# 04 — Plano de build\n\n" + t), t);
  }
});
caso("plano normal não é bloqueado", () => {
  assert.ok(!buildBloqueado("# 04 — Plano\n\n## Componentes\n- Flow X\n\nRisco: deploy bloqueado se faltar o campo."));
  assert.ok(!buildBloqueado("## O build não está bloqueado"));
});
caso("só vale no gate de build, com o plano na mesa", () => {
  const base = { status: "aguardando_gate_build", artefatoNome: "04-plano-build.md", artefatoConteudo: "**Resultado do build:** bloqueado" };
  assert.ok(gateDeBuildBloqueado(base));
  assert.ok(!gateDeBuildBloqueado({ ...base, status: "aguardando_gate_design" }));
  assert.ok(!gateDeBuildBloqueado({ ...base, artefatoNome: "05-testes.md" }));
  assert.ok(!gateDeBuildBloqueado({ ...base, artefatoConteudo: "" }));
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
console.log("\ntodos os casos passaram");
