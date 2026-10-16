// Despesas recorrentes (lib/recorrencias.ts): competências devidas, horizonte
// de 30 dias, dia 31 em mês curto, início/fim, sem enxurrada retroativa,
// idempotência, normalização mensal; a guarda da rota de cron
// (lib/cron-auth.ts); e a segregação com contas geradas pelo sistema.
import assert from "node:assert/strict";
import type { NextRequest } from "next/server";
import {
  aGerar,
  chaveOcorrencia,
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
  criadoEm: "2026-10-16",
  ...p,
});
const comps = (m: ModeloParaRegra, hoje: string) => competenciasDevidas(m, hoje).map((d) => d.vencimento);
const HOJE = "2026-10-16"; // horizonte: até 2026-11-15

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
  assert.deepEqual(comps(modelo({ diaVencimento: 31 }), "2027-01-31"), ["2027-01-31", "2027-02-28"]);
});

caso("trimestral: só as competências alinhadas ao início", () => {
  const m = modelo({ periodicidade: "trimestral", inicioEm: "2026-08-01", diaVencimento: 5, criadoEm: "2026-08-01" });
  assert.deepEqual(comps(m, HOJE), ["2026-11-05"]);
  assert.deepEqual(comps(m, "2027-01-20"), ["2027-02-05"]);
  assert.deepEqual(comps(m, "2026-12-20"), []);
});

caso("anual: uma conta por ano, no mês do início", () => {
  const m = modelo({ periodicidade: "anual", inicioEm: "2026-03-01", diaVencimento: 1, criadoEm: "2026-03-01" });
  assert.deepEqual(comps(m, HOJE), []);
  assert.deepEqual(comps(m, "2027-02-20"), ["2027-03-01"]);
});

caso("semestral", () => {
  const m = modelo({ periodicidade: "semestral", inicioEm: "2026-10-01", diaVencimento: 10 });
  assert.deepEqual(comps(m, HOJE), ["2026-10-10"]);
  assert.deepEqual(comps(m, "2027-03-20"), ["2027-04-10"]);
});

caso("fimEm: nada depois da última competência", () => {
  assert.deepEqual(comps(modelo({ fimEm: "2026-10-01" }), HOJE), ["2026-10-10"]);
  assert.deepEqual(comps(modelo({ fimEm: "2026-09-01", inicioEm: "2026-01-01" }), HOJE), []);
});

caso("inicioEm no futuro: nada antes da primeira competência", () => {
  assert.deepEqual(comps(modelo({ inicioEm: "2027-01-01" }), HOJE), []);
  assert.deepEqual(comps(modelo({ inicioEm: "2026-11-01" }), HOJE), ["2026-11-10"]);
});

caso("sem enxurrada: início antigo não gera os meses anteriores à criação", () => {
  assert.deepEqual(comps(modelo({ inicioEm: "2026-01-01" }), HOJE), ["2026-10-10", "2026-11-10"]);
});

caso("sem enxurrada: modelo antigo (ou retomado) não volta aos meses que passaram", () => {
  assert.deepEqual(comps(modelo({ inicioEm: "2026-01-01", criadoEm: "2026-01-05" }), HOJE), ["2026-10-10", "2026-11-10"]);
});

caso("idempotente: o que já existe não é gerado de novo", () => {
  const ms = [
    { ...modelo(), id: "a", ativa: true },
    { ...modelo({ diaVencimento: 25 }), id: "b", ativa: true },
    { ...modelo(), id: "pausado", ativa: false },
  ];
  const primeira = aGerar(ms, new Set(), HOJE);
  assert.deepEqual(
    primeira.map((g) => chaveOcorrencia(g.modelo.id, g.competencia)),
    ["a|2026-10", "a|2026-11", "b|2026-10"]
  );
  const existentes = new Set(primeira.map((g) => chaveOcorrencia(g.modelo.id, g.competencia)));
  assert.deepEqual(aGerar(ms, existentes, HOJE), []);
  // Conta ligada pelo "Tornar recorrente" ocupa a competência dela.
  assert.deepEqual(
    aGerar([ms[0]], new Set(["a|2026-10"]), HOJE).map((g) => g.competencia),
    ["2026-11"]
  );
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
