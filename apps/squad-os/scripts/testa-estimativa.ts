// Calibração da estimativa pelo timesheet (lib/estimativa.ts) — puro.
import assert from "node:assert/strict";
import { calibracaoPara, clienteVeEstimativa, estimativaCalibrada } from "@/lib/estimativa";

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

// estimado 4–8 h (ponto médio 6): lançar 9 h → razão 1,5
const am = (clientId: string, lancadoH: number) => ({ clientId, estimativaMin: 4, estimativaMax: 8, lancadoMin: lancadoH * 60 });

caso("sem 3 amostras não calibra", () => {
  assert.deepEqual(calibracaoPara("a", [am("a", 9), am("a", 9)]), { fator: 1, amostras: 0, escopo: "nenhum" });
});

caso("usa o próprio cliente quando tem histórico", () => {
  const c = calibracaoPara("a", [am("a", 9), am("a", 9), am("a", 12), am("b", 3), am("b", 3), am("b", 3)]);
  assert.equal(c.escopo, "cliente");
  assert.equal(c.fator, 1.5);
});

caso("cai no geral quando o cliente não tem histórico", () => {
  const c = calibracaoPara("novo", [am("a", 6), am("b", 12), am("c", 9)]);
  assert.equal(c.escopo, "geral");
  assert.equal(c.fator, 1.5);
});

caso("demanda sem apontamento não entra e outlier é preso", () => {
  const c = calibracaoPara("a", [am("a", 0), am("a", 600), am("a", 600), am("a", 600)]);
  assert.equal(c.amostras, 3);
  assert.equal(c.fator, 3);
});

caso("total = consultor calibrado + agente", () => {
  const e = estimativaCalibrada(
    { estimativaHorasMin: 4, estimativaHorasMax: 8, agenteHorasGasto: 0.5, agenteHorasRestante: 1.5 },
    { fator: 1.5, amostras: 3, escopo: "cliente" }
  );
  assert.deepEqual([e!.min, e!.max], [8, 14]);
});

caso("sem estimativa do consultor não há número pro cliente", () => {
  const e = estimativaCalibrada(
    { estimativaHorasMin: null, estimativaHorasMax: null, agenteHorasGasto: 1, agenteHorasRestante: 1 },
    { fator: 1, amostras: 0, escopo: "nenhum" }
  );
  assert.equal(e, null);
});

caso("cliente vê a partir do gate da análise", () => {
  assert.equal(clienteVeEstimativa("analise"), false);
  assert.equal(clienteVeEstimativa("backlog"), false);
  assert.equal(clienteVeEstimativa("aguardando_gate_analise"), true);
  assert.equal(clienteVeEstimativa("aguardando_gate_design"), true);
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
