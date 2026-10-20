import assert from "node:assert/strict";
import { defKpi, tendencia } from "../lib/kpis";
import { formatarPct, normalizarMargem, porContrato, rotuloMesCurto } from "../lib/margem";

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
const linha = (cliente: string, mes: string, margem: number | null, situacao: string) =>
  normalizarMargem({ client_id: cliente, cliente, mes, receita: "50005.0", custo_direto: "46720.00",
    margem: margem === null ? null : String(margem), margem_pct: margem === null ? null : String(margem / 50005),
    horas: "513.0", horas_contratadas: 504, contrato: "ams", receita_hora: null, custo_hora: null, notas: "8", situacao });
caso("margem: agrupa por contrato, meses em ordem, último mês com margem", () => {
  const g = porContrato([
    linha("Gauge", "2026-10", null, "nota ainda não emitida"),
    linha("Gauge", "2026-08", 3285, "custo pelos consultores alocados"),
    linha("Centric", "2026-06", null, "sem custo direto lançado"),
    linha("Gauge", "2026-09", -3565, "completo"),
  ]);
  assert.deepEqual(g.map((c) => c.cliente), ["Centric", "Gauge"]);
  assert.deepEqual(g[1].linhas.map((l) => l.mes), ["2026-08", "2026-09", "2026-10"]);
  assert.equal(g[1].ultima?.mes, "2026-09");
  assert.equal(g[1].ultima?.margem, -3565);
  assert.equal(g[0].ultima, null);
});
caso("margem: valores da view viram número; nulo continua nulo", () => {
  const m = linha("Gauge", "2026-09", null, "sem custo direto lançado");
  assert.equal(m.receita, 50005);
  assert.equal(m.margem, null);
  assert.equal(m.margemPct, null);
  assert.equal(m.horasContratadas, 504);
});
caso("margem: rótulos", () => {
  assert.equal(rotuloMesCurto("2026-09"), "set/26");
  assert.equal(formatarPct(0.0657), "6,6%");
  assert.equal(formatarPct(-0.0826), "-8,3%");
  assert.equal(formatarPct(null), "—");
});
console.log("\ntodos ok");
