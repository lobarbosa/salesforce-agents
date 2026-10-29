import assert from "node:assert/strict";
import { acoesPendentes, estadoDoClienteDemanda, situacaoParaCliente } from "../lib/demandas";

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

const base = { status: "aguardando_gate_design", estimativaConsultorHoras: 10, estimativaAprovadaHoras: null, disparos: [] };
const quem = (d: object) => acoesPendentes({ ...base, ...d }).map((a) => `${a.quem}:${a.oque}`);

caso("design sem horas aprovadas: time E cliente", () => {
  assert.deepEqual(quem({}), ["time:aprovar design", "cliente:aprovar horas"]);
});
caso("design com horas aprovadas: só o time", () => {
  assert.deepEqual(quem({ estimativaAprovadaHoras: 10 }), ["time:aprovar design"]);
});
caso("revisão do PR é do time", () => {
  assert.deepEqual(quem({ status: "aguardando_gate_build", estimativaAprovadaHoras: 10 }), ["time:revisar PR"]);
});
caso("homologação é do cliente", () => {
  assert.deepEqual(quem({ status: "aguardando_homologacao" }), ["cliente:homologar"]);
});
caso("etapa rodando: agente", () => {
  assert.deepEqual(quem({ status: "build" }), ["agente:rodando"]);
});
caso("aprovado e esperando a vez: na fila (sem pedir o gate de novo)", () => {
  const disparos = [{ tipo: "aprovar", gate: "aguardando_gate_design", disparadoEm: null, concluidoEm: null }];
  assert.deepEqual(quem({ estimativaAprovadaHoras: 10, disparos }), ["fila:na fila"]);
});
caso("disparo em voo conta como agente rodando", () => {
  const disparos = [{ tipo: "aprovar", gate: "aguardando_gate_design", disparadoEm: new Date(), concluidoEm: null }];
  assert.deepEqual(quem({ disparos }), ["agente:rodando"]);
});
caso("congelada e entregue", () => {
  assert.deepEqual(quem({ status: "standby" }), ["congelada:congelada"]);
  assert.deepEqual(quem({ status: "entregue" }), []);
});
caso("cliente: aprovar horas é a vez dele; gate interno é 'em revisão pela equipe'", () => {
  assert.equal(estadoDoClienteDemanda(base), "voce");
  assert.equal(situacaoParaCliente(base), "Sua vez: aprovar a estimativa de horas");
  const semPendencia = { ...base, estimativaAprovadaHoras: 10 };
  assert.equal(estadoDoClienteDemanda(semPendencia), "andamento");
  assert.equal(situacaoParaCliente(semPendencia), "Em revisão pela equipe");
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
console.log("\ntodos os casos passaram");
