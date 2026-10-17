// Despesas recorrentes (lib/recorrencias.ts): competências devidas, horizonte
// de 30 dias, dia 31 em mês curto, início/fim, geração retroativa (desde o
// início, inclusive meses pausados) com freio de 24, vínculo da avulsa já
// lançada, idempotência, normalização mensal; a guarda da rota de cron
// (lib/cron-auth.ts); e a segregação com contas geradas pelo sistema.
import assert from "node:assert/strict";
import type { NextRequest } from "next/server";
import {
  aGerar,
  avulsaParaVincular,
  chaveOcorrencia,
  MAX_POR_PASSADA,
  normalizarFornecedor,
  type AvulsaCandidata,
  competenciasDevidas,
  compromissoMensal,
  EMAIL_RECORRENCIA,
  equivalenteMensal,
  proximaCompetencia,
  somaMeses,
  validarModelo,
  vencimentoDa,
  type ModeloParaRegra,
} from "@/lib/recorrencias";
import { autorizarCron } from "@/lib/cron-auth";
import { bloqueio, bloqueioValor } from "@/lib/contas";

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

const modelo = (p: Partial<ModeloParaRegra> = {}): ModeloParaRegra => ({
  periodicidade: "mensal",
  diaVencimento: 10,
  inicioEm: "2026-10-01",
  fimEm: null,
  ...p,
});
const comps = (m: ModeloParaRegra, hoje: string) => competenciasDevidas(m, hoje).map((d) => d.vencimento);
const HOJE = "2026-10-16"; // horizonte: até 2026-11-15
const chaves = (r: ReturnType<typeof aGerar>) => r.itens.map((g) => chaveOcorrencia(g.modelo.id, g.competencia));

caso("mensal: gera o mês corrente e o próximo que vence em até 30 dias", () => {
  assert.deepEqual(comps(modelo(), HOJE), ["2026-10-10", "2026-11-10"]);
});

caso("horizonte de 30 dias: vencimento depois de hoje+30 ainda não é gerado", () => {
  assert.deepEqual(comps(modelo({ diaVencimento: 20 }), HOJE), ["2026-10-20"]);
  assert.deepEqual(comps(modelo({ diaVencimento: 15 }), HOJE), ["2026-10-15", "2026-11-15"]);
  assert.deepEqual(comps(modelo({ diaVencimento: 16 }), HOJE), ["2026-10-16"]);
});

caso("dia 31 vence no último dia do mês curto (inclusive fevereiro bissexto)", () => {
  assert.equal(vencimentoDa("2026-11", 31), "2026-11-30");
  assert.equal(vencimentoDa("2027-02", 31), "2027-02-28");
  assert.equal(vencimentoDa("2028-02", 30), "2028-02-29");
  assert.equal(vencimentoDa("2026-12", 31), "2026-12-31");
  assert.deepEqual(comps(modelo({ diaVencimento: 31 }), "2027-01-31"), [
    "2026-10-31",
    "2026-11-30",
    "2026-12-31",
    "2027-01-31",
    "2027-02-28",
  ]);
});

caso("trimestral: só as competências alinhadas ao início", () => {
  const m = modelo({ periodicidade: "trimestral", inicioEm: "2026-08-01", diaVencimento: 5 });
  assert.deepEqual(comps(m, HOJE), ["2026-08-05", "2026-11-05"]);
  assert.deepEqual(comps(m, "2027-01-20"), ["2026-08-05", "2026-11-05", "2027-02-05"]);
  assert.deepEqual(comps(m, "2026-06-20"), []);
});

caso("anual: uma conta por ano, no mês do início", () => {
  const m = modelo({ periodicidade: "anual", inicioEm: "2026-03-01", diaVencimento: 1 });
  assert.deepEqual(comps(m, HOJE), ["2026-03-01"]);
  assert.deepEqual(comps(m, "2027-02-20"), ["2026-03-01", "2027-03-01"]);
});

caso("semestral", () => {
  const m = modelo({ periodicidade: "semestral", inicioEm: "2026-10-01", diaVencimento: 10 });
  assert.deepEqual(comps(m, HOJE), ["2026-10-10"]);
  assert.deepEqual(comps(m, "2027-03-20"), ["2026-10-10", "2027-04-10"]);
});

caso("fimEm: nada depois da última competência", () => {
  assert.deepEqual(comps(modelo({ fimEm: "2026-10-01" }), HOJE), ["2026-10-10"]);
  assert.deepEqual(comps(modelo({ fimEm: "2026-02-01", inicioEm: "2026-01-01" }), HOJE), ["2026-01-10", "2026-02-10"]);
});

caso("inicioEm no futuro: nada antes da primeira competência", () => {
  assert.deepEqual(comps(modelo({ inicioEm: "2027-01-01" }), HOJE), []);
  assert.deepEqual(comps(modelo({ inicioEm: "2026-11-01" }), HOJE), ["2026-11-10"]);
});

caso("retroativo: início no passado gera todos os meses desde o início", () => {
  const ms = [{ ...modelo({ inicioEm: "2026-06-01" }), id: "a", ativa: true }];
  assert.deepEqual(chaves(aGerar(ms, new Set(), HOJE)), [
    "a|2026-06",
    "a|2026-07",
    "a|2026-08",
    "a|2026-09",
    "a|2026-10",
    "a|2026-11",
  ]);
});

caso("pausado não gera; ao retomar, os meses pausados também saem", () => {
  const m = { ...modelo({ inicioEm: "2026-06-01" }), id: "a" };
  // Gerou junho e julho, foi pausado em agosto.
  const ate = new Set(["a|2026-06", "a|2026-07"]);
  assert.deepEqual(aGerar([{ ...m, ativa: false }], ate, HOJE).itens, []);
  assert.deepEqual(chaves(aGerar([{ ...m, ativa: true }], ate, HOJE)), ["a|2026-08", "a|2026-09", "a|2026-10", "a|2026-11"]);
});

caso("freio: no máximo 24 competências por modelo por passada, das mais antigas", () => {
  const m = { ...modelo({ inicioEm: "2023-01-01" }), id: "velho", ativa: true };
  const outro = { ...modelo(), id: "novo", ativa: true };
  const r = aGerar([m, outro], new Set(), HOJE);
  const doVelho = r.itens.filter((i) => i.modelo.id === "velho");
  assert.equal(doVelho.length, MAX_POR_PASSADA);
  assert.equal(doVelho[0].competencia, "2023-01");
  assert.equal(doVelho[23].competencia, "2024-12");
  // 2023-01..2026-11 = 47 competências; 23 ficam para a próxima passada.
  assert.deepEqual(r.limitados, [{ modeloId: "velho", faltando: 23 }]);
  assert.equal(r.itens.filter((i) => i.modelo.id === "novo").length, 2);
  // A passada seguinte continua de onde parou.
  const r2 = aGerar([m], new Set(chaves(r)), HOJE);
  assert.equal(r2.itens[0].competencia, "2025-01");
  assert.equal(r2.itens.length, 23);
  assert.deepEqual(r2.limitados, []);
});

caso("idempotente: o que já existe não é gerado de novo", () => {
  const ms = [
    { ...modelo(), id: "a", ativa: true },
    { ...modelo({ diaVencimento: 25 }), id: "b", ativa: true },
    { ...modelo(), id: "pausado", ativa: false },
  ];
  const primeira = aGerar(ms, new Set(), HOJE);
  assert.deepEqual(chaves(primeira), ["a|2026-10", "a|2026-11", "b|2026-10"]);
  assert.deepEqual(aGerar(ms, new Set(chaves(primeira)), HOJE).itens, []);
  // Conta ligada pelo "Tornar recorrente" ocupa a competência dela.
  assert.deepEqual(
    aGerar([ms[0]], new Set(["a|2026-10"]), HOJE).itens.map((g) => g.competencia),
    ["2026-11"]
  );
});

caso("vínculo: avulsa do mesmo fornecedor no mês vira a ocorrência em vez de duplicar", () => {
  const cands: AvulsaCandidata[] = [
    { id: "ms-set", fornecedor: "  microsoft ", vencimento: "2026-09-12", valor: 310, status: "paga" },
    { id: "ms-set-2", fornecedor: "Microsoft", vencimento: "2026-09-30", valor: 900, status: "aguardando_aprovacao" },
    { id: "ms-out-canc", fornecedor: "Microsoft", vencimento: "2026-10-10", valor: 300, status: "cancelada" },
    { id: "ms-out-rec", fornecedor: "Microsoft", vencimento: "2026-10-10", valor: 300, status: "recusada" },
    { id: "outro", fornecedor: "Microsoft Brasil", vencimento: "2026-11-10", valor: 300, status: "aprovada" },
  ];
  // Fornecedor sem diferença de caixa/espaço; mais de uma no mês = valor mais próximo.
  assert.equal(avulsaParaVincular(cands, "MICROSOFT", "2026-09", 300), "ms-set");
  // Cancelada e recusada não contam; fornecedor diferente não conta.
  assert.equal(avulsaParaVincular(cands, "Microsoft", "2026-10", 300), null);
  assert.equal(avulsaParaVincular(cands, "Microsoft", "2026-11", 300), null);
  // Já usada nesta passada: a próxima candidata.
  assert.equal(avulsaParaVincular(cands, "Microsoft", "2026-09", 300, new Set(["ms-set"])), "ms-set-2");
  assert.equal(normalizarFornecedor("  Stack   Force "), "stack force");
});

caso("próxima competência", () => {
  assert.deepEqual(proximaCompetencia(modelo(), HOJE), { competencia: "2026-11", vencimento: "2026-11-10" });
  assert.deepEqual(proximaCompetencia(modelo({ diaVencimento: 31 }), HOJE), { competencia: "2026-10", vencimento: "2026-10-31" });
  assert.equal(proximaCompetencia(modelo({ fimEm: "2026-10-01" }), HOJE), null);
  assert.equal(somaMeses("2026-11", 3), "2027-02");
  assert.equal(somaMeses("2026-01", -1), "2025-12");
});

caso("normalização mensal: trimestral/3, semestral/6, anual/12", () => {
  assert.equal(equivalenteMensal(300, "trimestral"), 100);
  assert.equal(equivalenteMensal(1000, "semestral"), 166.67);
  assert.equal(equivalenteMensal(1200, "anual"), 100);
  assert.equal(equivalenteMensal(89.9, "mensal"), 89.9);
});

caso("compromisso mensal: só ativas e não encerradas, separado em fixo e direto", () => {
  const c = compromissoMensal(
    [
      { valor: 1000, periodicidade: "mensal", natureza: "fixo", ativa: true, fim: null },
      { valor: 1200, periodicidade: "anual", natureza: "fixo", ativa: true, fim: "2026-12" },
      { valor: 9000, periodicidade: "trimestral", natureza: "direto", ativa: true, fim: null },
      { valor: 500, periodicidade: "mensal", natureza: "fixo", ativa: false, fim: null },
      { valor: 700, periodicidade: "mensal", natureza: "direto", ativa: true, fim: "2026-09" },
    ],
    HOJE
  );
  assert.deepEqual(c, { total: 4100, fixo: 1100, direto: 3000, quantidade: 3 });
});

caso("validação do modelo", () => {
  const base = { fornecedor: "Microsoft", valor: "1.234,56", periodicidade: "mensal", diaVencimento: 31, inicio: "2026-10", natureza: "fixo" };
  const ok = validarModelo(base);
  assert.equal(ok.erro, undefined);
  assert.equal(ok.dados?.valor, 1234.56);
  assert.match(validarModelo({ ...base, diaVencimento: 32 }).erro!, /1 a 31/);
  assert.match(validarModelo({ ...base, natureza: "" }).erro!, /natureza/);
  assert.match(validarModelo({ ...base, periodicidade: "semanal" }).erro!, /periodicidade/);
  assert.match(validarModelo({ ...base, fim: "2026-09" }).erro!, /antes da primeira/);
  assert.match(validarModelo({ ...base, inicio: "2026-13" }).erro!, /competência/);
  assert.equal(validarModelo({ ativa: false }, true).erro, undefined);
  assert.equal(validarModelo({ fim: "" }, true).dados?.fim, null);
});

function pedido(bearer: string | null): NextRequest {
  return {
    headers: { get: (nome: string) => (nome.toLowerCase() === "authorization" ? bearer : null) },
  } as unknown as NextRequest;
}

caso("cron: sem CRON_SECRET configurado a rota fica fechada (503)", () => {
  delete process.env.CRON_SECRET;
  assert.equal(autorizarCron(pedido("Bearer qualquer"))?.status, 503);
});

caso("cron: sem o segredo (ou com outro) → 401", () => {
  process.env.CRON_SECRET = "segredo-do-cron";
  assert.equal(autorizarCron(pedido(null))?.status, 401);
  assert.equal(autorizarCron(pedido("segredo-do-cron"))?.status, 401);
  assert.equal(autorizarCron(pedido("Bearer outro"))?.status, 401);
  assert.equal(autorizarCron(pedido("Bearer segredo-do-cro"))?.status, 401);
});

caso("cron: com o segredo certo passa", () => {
  process.env.CRON_SECRET = "segredo-do-cron";
  assert.equal(autorizarCron(pedido("Bearer segredo-do-cron")), null);
  delete process.env.CRON_SECRET;
});

const admin = { role: "admin" as const, email: "ceo@acxya.com" };
const fin = { role: "financeiro" as const, email: "bia@acxya.com" };
const gerada = { status: "aguardando_aprovacao" as const, valor: 500, lancadoPorEmail: EMAIL_RECORRENCIA };

caso("conta gerada pela recorrência: qualquer aprovador decide (respeitando a alçada)", () => {
  assert.equal(bloqueio("aprovar", gerada, admin, 0), null);
  assert.equal(bloqueio("aprovar", gerada, fin, 1000), null);
  assert.match(bloqueio("aprovar", gerada, fin, 100)!, /alçada/);
});

caso("quem corrigiu o valor não aprova a conta", () => {
  const corrigida = { ...gerada, valorAlteradoPor: ["CEO@acxya.com"] };
  assert.match(bloqueio("aprovar", corrigida, admin, 0)!, /corrigiu o valor/);
  assert.equal(bloqueio("aprovar", corrigida, fin, 1000), null);
  // Pagar não é decidir: quem corrigiu pode marcar como paga depois que outro aprovou.
  assert.equal(bloqueio("pagar", { ...corrigida, status: "aprovada" }, admin, 0), null);
});

caso("valor só é corrigido enquanto aguarda aprovação", () => {
  assert.equal(bloqueioValor("aguardando_aprovacao"), null);
  for (const s of ["aprovada", "paga", "recusada", "cancelada"] as const) assert.ok(bloqueioValor(s));
});

if (falhas) {
  console.log(`\n${falhas} caso(s) falharam`);
  process.exit(1);
}
console.log("\ntodos os casos passaram");
