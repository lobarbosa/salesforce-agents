import assert from "node:assert/strict";
import {
  agruparInsights,
  dataBr,
  formatarCobertura,
  formatarPct,
  normalizarFontes,
  normalizarIndicadores,
  normalizarInsights,
  saudeDe,
} from "../lib/relatorio-financeiro";

function caso(nome: string, fn: () => void) {
  fn();
  console.log(`ok    ${nome}`);
}

caso("seção ausente vira null, nunca zero", () => {
  const i = normalizarIndicadores({ despesas: { pagas_mes_atual: 100 } });
  assert.equal(i.receitas, null);
  assert.equal(i.comercial, null);
  assert.equal(i.despesas?.pagasMesAtual, 100);
  assert.equal(i.despesas?.emAbertoTotal, null);
  assert.equal(i.coberturaMrrDespesa, null);
});
caso("indicadores lixo não quebram", () => {
  for (const v of [null, undefined, "x", 3, [], { receitas: [] }]) {
    const i = normalizarIndicadores(v);
    assert.equal(i.receitas, null);
  }
});
caso("números como string e nulos", () => {
  const i = normalizarIndicadores({
    receitas: { mrr: "11061.82", inadimplencia_pct_mrr: null, maior_cliente_90d: { nome: "ACME", valor: 10, pct: 60 } },
    cobertura_mrr_despesa: 1.25,
  });
  assert.equal(i.receitas?.mrr, 11061.82);
  assert.equal(i.receitas?.inadimplenciaPctMrr, null);
  assert.deepEqual(i.receitas?.maiorCliente90d, { nome: "ACME", valor: 10, pct: 60 });
  assert.equal(i.coberturaMrrDespesa, 1.25);
});
caso("categorias ordenadas por valor, inválidas fora", () => {
  const i = normalizarIndicadores({ despesas: { por_categoria_90d: { Software: 100, Pessoal: 900, X: "abc" } } });
  assert.deepEqual(i.despesas?.porCategoria90d, [
    { categoria: "Pessoal", valor: 900 },
    { categoria: "Software", valor: 100 },
  ]);
});
caso("contratos sem horas e uso nulo", () => {
  const i = normalizarIndicadores({
    operacao: {
      contratos: [{ cliente: "A", tipo: "AMS", horas_contratadas: 0, ciclo: "mensal", horas_mes: 2.5, uso_pct: null }, { tipo: "x" }],
      contratos_sem_horas_definidas: ["A"],
      horas_lancadas_mes: 2.5,
    },
  });
  assert.equal(i.operacao?.contratos.length, 1);
  assert.equal(i.operacao?.contratos[0].usoPct, null);
  assert.deepEqual(i.operacao?.contratosSemHorasDefinidas, ["A"]);
});
caso("insights: tipo desconhecido descartado, agrupados na ordem insight → risco → recomendação", () => {
  const l = normalizarInsights([
    { tipo: "insight", titulo: "a", texto: "b" },
    { tipo: "risco", titulo: "c", texto: "d" },
    { tipo: "outro", titulo: "e", texto: "f" },
    { tipo: "recomendacao", titulo: "", texto: "" },
  ]);
  assert.equal(l.length, 2);
  assert.deepEqual(agruparInsights(l).map((g) => g.tipo), ["insight", "risco"]);
  assert.deepEqual(normalizarInsights("x"), []);
});
caso("fontes em ordem fixa e status", () => {
  const f = normalizarFontes({ salesforce: "erro: 401", outra: "ok", squad_os: "ok", asaas: "ok" });
  assert.deepEqual(f.map((x) => x.fonte), ["squad_os", "asaas", "salesforce", "outra"]);
  assert.equal(f[2].ok, false);
  assert.equal(f[2].status, "erro: 401");
});
caso("saúde fora do vocabulário vira null", () => {
  assert.equal(saudeDe("verde"), "verde");
  assert.equal(saudeDe("azul"), null);
});
caso("formatação pt-BR", () => {
  assert.equal(formatarCobertura(1.25), "1,25x");
  assert.equal(formatarPct(35.24), "35,2%");
  assert.equal(dataBr("2026-10-16"), "16/10/2026");
});
console.log("\ntodos ok");
