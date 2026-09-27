import assert from "node:assert/strict";
import { defKpi, tendencia } from "../lib/kpis";

function caso(nome: string, fn: () => void) {
  fn();
  console.log(`ok    ${nome}`);
}

caso("tendência de receita", () => {
  assert.equal(tendencia(110, 100), "subiu 10% (melhorou)");
  assert.equal(tendencia(90, 100), "caiu 10% (piorou)");
});
caso("tendência de despesa inverte o sentido", () => {
  assert.equal(tendencia(110, 100, true), "subiu 10% (piorou)");
});
caso("sem base não inventa tendência", () => {
  assert.equal(tendencia(10, null), null);
  assert.equal(tendencia(10, 0), null);
  assert.equal(tendencia(100.2, 100), "estável");
});
caso("métrica nova aparece com nome cru", () => {
  assert.equal(defKpi("margem_bruta").rotulo, "margem bruta");
  assert.equal(defKpi("caixa_30d").rotulo, "Caixa projetado em 30 dias");
});
console.log("\ntodos ok");
