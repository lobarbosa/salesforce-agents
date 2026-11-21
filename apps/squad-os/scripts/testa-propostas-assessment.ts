import assert from "node:assert/strict";
import {
  idDaRecomendacao,
  lerRecomendacoes,
  melhoriasDoAssessment,
  propostaPendente,
  type DemandaDaProposta,
} from "../lib/assessment-propostas";
import { acoesPendentes, estadoDoClienteDemanda, motivoSemDrop, situacaoParaCliente } from "../lib/demandas";

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

const recs = lerRecomendacoes([
  { titulo: "Cobertura de testes Apex abaixo de 75%", severidade: "alta", area: "Código" },
  { titulo: "Flows ativos sem descrição", severidade: "baixa", area: "Automação" },
  { titulo: "Perfis com Modify All Data", severidade: "critica", area: "Segurança" },
  { titulo: "", severidade: "alta", area: "x" },
  "lixo",
]);
const [testes, flows, perfis] = recs;
const demanda = (d: Partial<DemandaDaProposta>): DemandaDaProposta => ({
  code: "X-1",
  titulo: "t",
  status: "backlog",
  origemAssessmentId: "",
  propostaClienteEm: null,
  propostaDecisao: "",
  ...d,
});

caso("lê só recomendações com título", () => {
  assert.equal(recs.length, 3);
});
caso("id é estável e ignora acento, caixa e pontuação", () => {
  assert.equal(idDaRecomendacao(testes), idDaRecomendacao({ titulo: "cobertura de TESTES apex abaixo de 75%!", area: "codigo" }));
  assert.notEqual(idDaRecomendacao(testes), idDaRecomendacao(flows));
  assert.match(idDaRecomendacao(testes), /^rec-[0-9a-f]{8}$/);
});
caso("sem demanda: todas livres, por severidade", () => {
  const m = melhoriasDoAssessment(recs, []);
  assert.deepEqual(m.map((x) => x.titulo), [perfis.titulo, testes.titulo, flows.titulo]);
  assert.ok(m.every((x) => x.situacao.tipo === "livre"));
});
caso("proposta pendente, aprovada e recusada não voltam a ser livres", () => {
  const m = melhoriasDoAssessment(recs, [
    demanda({ code: "A-1", origemAssessmentId: idDaRecomendacao(testes), propostaClienteEm: new Date() }),
    demanda({ code: "A-2", origemAssessmentId: idDaRecomendacao(flows), propostaClienteEm: new Date(), propostaDecisao: "recusada", status: "cancelada" }),
    demanda({ code: "A-3", origemAssessmentId: idDaRecomendacao(perfis), propostaClienteEm: new Date(), propostaDecisao: "aprovada" }),
  ]);
  const por = Object.fromEntries(m.map((x) => [x.titulo, x.situacao]));
  assert.deepEqual(por[testes.titulo], { tipo: "proposta", code: "A-1", decisao: "pendente" });
  assert.deepEqual(por[flows.titulo], { tipo: "proposta", code: "A-2", decisao: "recusada" });
  assert.deepEqual(por[perfis.titulo], { tipo: "proposta", code: "A-3", decisao: "aprovada" });
});
caso("demanda sem proposta ligada à recomendação conta como demanda", () => {
  const m = melhoriasDoAssessment([testes], [demanda({ code: "A-9", origemAssessmentId: idDaRecomendacao(testes), status: "build" })]);
  assert.deepEqual(m[0].situacao, { tipo: "demanda", code: "A-9", status: "build" });
});
caso("propostaPendente só sem decisão", () => {
  assert.equal(propostaPendente({ propostaClienteEm: new Date(), propostaDecisao: "" }), true);
  assert.equal(propostaPendente({ propostaClienteEm: new Date(), propostaDecisao: "aprovada" }), false);
  assert.equal(propostaPendente({ propostaClienteEm: null, propostaDecisao: "" }), false);
});

const backlog = { status: "backlog", estimativaConsultorHoras: null, estimativaAprovadaHoras: null, disparos: [] };
caso("proposta pendente: o cliente age e vê 'esperando você'", () => {
  const d = { ...backlog, propostaClienteEm: new Date(), propostaDecisao: "" };
  assert.deepEqual(acoesPendentes(d).map((a) => `${a.quem}:${a.oque}`), ["cliente:aprovar proposta"]);
  assert.equal(estadoDoClienteDemanda(d), "voce");
  assert.match(situacaoParaCliente(d), /aprovar a melhoria/);
});
caso("proposta aprovada: volta a ser backlog comum, do time", () => {
  const d = { ...backlog, propostaClienteEm: new Date(), propostaDecisao: "aprovada" };
  assert.deepEqual(acoesPendentes(d), []);
  assert.equal(estadoDoClienteDemanda(d), "recebida");
});
caso("proposta pendente não vai para a esteira; aprovada vai", () => {
  assert.match(motivoSemDrop({ status: "backlog", materializadoEm: null, propostaClienteEm: new Date(), propostaDecisao: "" }, "analise") ?? "", /aprovação do cliente/);
  assert.equal(motivoSemDrop({ status: "backlog", materializadoEm: null, propostaClienteEm: new Date(), propostaDecisao: "aprovada" }, "analise"), null);
  assert.equal(motivoSemDrop({ status: "backlog", materializadoEm: null }, "analise"), null);
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
