import assert from "node:assert/strict";
import { conteudoDaEntregaManual, erroDoRegistro, motivoSemEntregaManual } from "../lib/entrega-manual";

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

caso("aceita em gate, em triagem e em etapa parada sem execução", () => {
  for (const status of ["backlog", "aguardando_gate_design", "aguardando_gate_build", "build", "qa"]) {
    assert.equal(motivoSemEntregaManual({ status, disparos: [] }), null, status);
  }
});
caso("recusa encerrada, congelada e já na homologação", () => {
  assert.match(motivoSemEntregaManual({ status: "entregue" })!, /encerrada/);
  assert.match(motivoSemEntregaManual({ status: "cancelada" })!, /encerrada/);
  assert.match(motivoSemEntregaManual({ status: "standby" })!, /congelada/);
  assert.match(motivoSemEntregaManual({ status: "aguardando_homologacao" })!, /homologação/);
  assert.match(motivoSemEntregaManual({ status: "aguardando_homologacao", entregaManualEm: new Date() })!, /já foi registrada/);
});
caso("recusa com execução da esteira em andamento ou na fila", () => {
  assert.match(motivoSemEntregaManual({ status: "build", disparos: [{ concluidoEm: null }] })!, /execução/);
  assert.equal(motivoSemEntregaManual({ status: "build", disparos: [{ concluidoEm: new Date() }] }), null);
});
caso("registro exige descrição e evidência", () => {
  assert.match(erroDoRegistro("feito", true)!, /descreva/);
  assert.match(erroDoRegistro("Relatório semanal de leads desativado na org.", false)!, /evidência/);
  assert.equal(erroDoRegistro("Relatório semanal de leads desativado na org.", true), null);
});
caso("o registro traz os quatro campos que a esteira confere", () => {
  const texto = conteudoDaEntregaManual({
    code: "ACME-1",
    titulo: "Desativar relatório",
    por: "Consultora",
    em: new Date("2026-11-25T12:00:00Z"),
    descricao: "Relatório semanal de leads desativado na org.",
    evidencia: "print.png",
  });
  const linhas = texto.split("\n");
  assert.equal(linhas[0], "**Entrega manual:** registrada");
  assert.equal(linhas[1], "**Por:** Consultora");
  assert.equal(linhas[2], "**Em:** 2026-11-25T12:00:00.000Z");
  assert.equal(linhas[3], "**Evidência:** print.png");
  assert.ok(texto.includes("Relatório semanal de leads desativado na org."));
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
console.log("\ntodos os casos passaram");
