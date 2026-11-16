// Reproduz a navegação que causou a perda de dado em produção, contra a regra
// pura — sem servidor, sem Prisma.
import assert from "node:assert/strict";
import {
  montarDadosDoContrato,
  montarHorasPorMes,
  ContratoInvalidoError,
  type ContratoGuardado,
  progressoDoProjeto,
  AVANCO_POR_STATUS,
  type DemandaDoProgresso,
} from "@/lib/contrato";

const guardado = (p: Partial<ContratoGuardado> = {}): ContratoGuardado => ({
  tipo: "ams",
  horasContratadas: 40,
  cicloHoras: "mensal",
  sla: [{ severidade: "Crítica", primeiraRespostaHoras: 1, resolucaoHoras: 4 }],
  projetoNome: "",
  projetoEscopo: "",
  inicioEm: null,
  fimPrevistoEm: null,
  ...p,
});

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

caso("trocar de tipo nao zera as horas (o bug do centric)", () => {
  const d = montarDadosDoContrato({ tipo: "projeto" }, guardado());
  assert.equal(d.horasContratadas, 40);
});

caso("trocar de tipo nao reinicia o SLA", () => {
  const d = montarDadosDoContrato({ tipo: "projeto" }, guardado());
  assert.equal(d.sla.length, 1);
  assert.equal(d.sla[0].severidade, "Crítica");
});

caso("voltar pro tipo original devolve tudo como estava", () => {
  const paraProjeto = montarDadosDoContrato({ tipo: "projeto" }, guardado());
  const devolta = montarDadosDoContrato({ tipo: "ams" }, guardado({ ...paraProjeto, tipo: "projeto" }));
  assert.equal(devolta.horasContratadas, 40);
  assert.equal(devolta.sla.length, 1);
});

caso("dado de projeto sobrevive a uma passagem por AMS", () => {
  const g = guardado({ tipo: "projeto", projetoNome: "Migracao CRM", projetoEscopo: "12 Flows" });
  const emAms = montarDadosDoContrato({ tipo: "ams" }, g);
  assert.equal(emAms.projetoNome, "Migracao CRM");
  assert.equal(emAms.projetoEscopo, "12 Flows");
});

caso("salvar um campo nao apaga os outros", () => {
  const d = montarDadosDoContrato({ tipo: "ams", horasContratadas: 80 }, guardado());
  assert.equal(d.horasContratadas, 80);
  assert.equal(d.sla.length, 1, "o SLA guardado tem que continuar");
  assert.equal(d.cicloHoras, "mensal");
});

caso("contrato novo nasce com o SLA padrao, nao vazio", () => {
  const d = montarDadosDoContrato({ tipo: "ams" }, null);
  assert.equal(d.horasContratadas, 0);
  assert.equal(d.sla.length, 4, "as quatro severidades do rascunho");
});

caso("SLA explicitamente vazio e respeitado, nao reposto", () => {
  const d = montarDadosDoContrato({ tipo: "ams", sla: [] }, guardado());
  assert.equal(d.sla.length, 0);
});

caso("horas fora da faixa continuam recusadas", () => {
  assert.throws(
    () => montarDadosDoContrato({ tipo: "ams", horasContratadas: 99999 }, null),
    ContratoInvalidoError
  );
  assert.throws(
    () => montarDadosDoContrato({ tipo: "ams", horasContratadas: -1 }, null),
    ContratoInvalidoError
  );
});

caso("tipo invalido continua recusado", () => {
  assert.throws(() => montarDadosDoContrato({ tipo: "outro" }, null), ContratoInvalidoError);
});

caso("data invalida vira null em vez de quebrar", () => {
  const d = montarDadosDoContrato({ tipo: "projeto", inicioEm: "nao e data" }, null);
  assert.equal(d.inicioEm, null);
});

caso("ciclo vazio cai no padrao", () => {
  const d = montarDadosDoContrato({ tipo: "ams", cicloHoras: "   " }, guardado());
  assert.equal(d.cicloHoras, "mensal");
});

caso("horas por mês usam o mês de São Paulo, não o UTC", () => {
  // 31/10 às 22h em SP = 01/11 01:00 UTC: trabalho de outubro.
  const r = montarHorasPorMes(
    [{ inicioEm: new Date("2026-11-01T01:00:00Z"), minutos: 60 }],
    40, "mensal", new Date("2026-11-15T12:00:00Z"), 2
  );
  assert.deepEqual(r.map((m) => [m.mes, m.horasGastas]), [["2026-10", 1], ["2026-11", 0]]);
});

caso("trimestral: o mês carrega o acumulado do ciclo contra o teto do ciclo", () => {
  const h = (iso: string, min: number) => ({ inicioEm: new Date(iso), minutos: min });
  const r = montarHorasPorMes(
    [h("2026-07-10T12:00:00Z", 50 * 60), h("2026-08-10T12:00:00Z", 50 * 60), h("2026-09-10T12:00:00Z", 50 * 60), h("2026-10-05T12:00:00Z", 10 * 60)],
    120, "trimestral", new Date("2026-10-20T12:00:00Z"), 3
  );
  assert.deepEqual(
    r.map((m) => [m.mes, m.horasGastas, m.horasNoCiclo, m.horasContratadas]),
    [["2026-08", 50, 100, 120], ["2026-09", 50, 150, 120], ["2026-10", 10, 10, 120]]
  );
});

// --- Progresso automático, das demandas ----------------------------------

const ent = (id: string, peso: number, concluido = false) => ({ id, peso, concluido });
const dem = (status: string, entregavelId: string | null = null, tipo = "projeto") =>
  ({ status, tipo, entregavelId }) as DemandaDoProgresso;

caso("progresso: sem demanda, vale a marcação manual do entregável", () => {
  const p = progressoDoProjeto([ent("a", 3, true), ent("b", 1)]);
  assert.equal(p.pct, 75);
  assert.equal(p.concluidos, 1);
  assert.equal(p.porEntregavel.a.automatico, false);
});

caso("progresso: entregável com demanda segue as demandas, não a marcação", () => {
  const p = progressoDoProjeto([ent("a", 2, true)], [dem("build", "a"), dem("entregue", "a")]);
  assert.equal(p.porEntregavel.a.automatico, true);
  assert.equal(p.porEntregavel.a.fracao, 0.75);
  assert.equal(p.pct, 75);
  assert.equal(p.concluidos, 0);
});

caso("progresso: entregável conclui sozinho quando todas as demandas são entregues", () => {
  const p = progressoDoProjeto([ent("a", 2)], [dem("entregue", "a"), dem("entregue", "a")]);
  assert.equal(p.pct, 100);
  assert.equal(p.concluidos, 1);
});

caso("progresso: homologação pendente não é entrega", () => {
  const p = progressoDoProjeto([], [dem("aguardando_homologacao")]);
  assert.equal(p.pct, 85);
  assert.equal(p.demandasEntregues, 0);
});

caso("progresso: demanda de projeto sem entregável conta como peso 1", () => {
  const p = progressoDoProjeto([ent("a", 1, true)], [dem("backlog"), dem("entregue")]);
  assert.equal(p.pesoTotal, 3);
  assert.equal(p.pct, 67);
});

caso("progresso: cancelada e sustentação ficam fora", () => {
  const p = progressoDoProjeto([ent("a", 1)], [dem("cancelada", "a"), dem("entregue", null, "sustentacao")]);
  assert.equal(p.demandas, 0);
  assert.equal(p.pct, 0);
  assert.equal(p.porEntregavel.a.automatico, false);
});

caso("progresso: toda etapa tem avanço entre 0 e 1 e não anda para trás", () => {
  const ordem = ["analise", "aguardando_gate_analise", "design", "aguardando_gate_design", "build",
    "aguardando_gate_build", "qa", "aguardando_homologacao", "release", "entregue"] as const;
  ordem.forEach((s, i) => {
    assert.ok(AVANCO_POR_STATUS[s] > 0 && AVANCO_POR_STATUS[s] <= 1);
    if (i) assert.ok(AVANCO_POR_STATUS[s] > AVANCO_POR_STATUS[ordem[i - 1]]);
  });
});

console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
