import assert from "node:assert/strict";
import { ambienteDoDisparo, decidirDisparo, NOTA_ESPERA_ESTIMATIVA, notaEsperaQa, type PedidoNaFila } from "../lib/fila-decisao";

let falhas = 0;
function caso(nome: string, fn: () => void) {
  try {
    fn();
    console.log(`ok ${nome}`);
  } catch (e) {
    falhas++;
    console.log(`FALHA ${nome}\n${(e as Error).message}`);
  }
}

const projeto = { contrato: { tipo: "projeto" } };
const p = (tipo: string, status: string, gate = "", extra: Partial<PedidoNaFila["demanda"]> = {}): PedidoNaFila => ({
  tipo,
  gate,
  autor: "Fulano",
  nota: "",
  demanda: { status, estimativaConsultorHoras: null, estimativaAprovadaHoras: null, client: projeto, ...extra },
});

caso("aprovação do gate de build espera a sandbox de QA livre", () => {
  const d = decidirDisparo(p("aprovar", "aguardando_gate_build", "aguardando_gate_build"), "EPLAST-47");
  assert.deepEqual(d, { acao: "esperar", nota: notaEsperaQa("EPLAST-47") });
});
caso("com a QA livre, a aprovação sai com o gate esperado", () => {
  const d = decidirDisparo(p("aprovar", "aguardando_gate_build", "aguardando_gate_build"), null);
  assert.deepEqual(d, { acao: "disparar", opcoes: { aprovarGate: "Fulano", gateEsperado: "aguardando_gate_build" } });
});
caso("QA ocupada não segura o que roda na dev", () => {
  assert.equal(decidirDisparo(p("aprovar", "aguardando_gate_design", "aguardando_gate_design"), "EPLAST-47").acao, "disparar");
  assert.equal(decidirDisparo(p("reverificar", "aguardando_gate_build"), "EPLAST-47").acao, "disparar");
  assert.equal(decidirDisparo(p("rodar", "qa"), "EPLAST-47").acao, "disparar");
});
caso("reverificação manda o input e só vale no gate de build", () => {
  assert.deepEqual(decidirDisparo(p("reverificar", "aguardando_gate_build"), null), {
    acao: "disparar",
    opcoes: { reverificar: "Fulano" },
  });
  assert.equal(decidirDisparo(p("reverificar", "build"), null).acao, "descartar");
});
caso("aprovação de gate que já passou é descartada", () => {
  assert.equal(decidirDisparo(p("aprovar", "build", "aguardando_gate_design"), null).acao, "descartar");
});
caso("AMS sem estimativa aprovada espera no gate de design", () => {
  const d = decidirDisparo(
    p("aprovar", "aguardando_gate_design", "aguardando_gate_design", { client: { contrato: { tipo: "ams" } }, estimativaConsultorHoras: 8 }),
    null
  );
  assert.deepEqual(d, { acao: "esperar", nota: NOTA_ESPERA_ESTIMATIVA });
});

caso("ambiente do disparo: sandbox da etapa que vai rodar", () => {
  assert.equal(ambienteDoDisparo("aprovar", "aguardando_gate_build", "aguardando_gate_build"), "qa");
  assert.equal(ambienteDoDisparo("aprovar", "aguardando_gate_design", "aguardando_gate_design"), "dev");
  assert.equal(ambienteDoDisparo("aprovar", "aguardando_gate_analise", "aguardando_gate_analise"), "dev");
  assert.equal(ambienteDoDisparo("aprovar", "aguardando_homologacao", "aguardando_homologacao"), "qa");
  assert.equal(ambienteDoDisparo("reverificar", "aguardando_gate_build", "aguardando_gate_build"), "dev");
  assert.equal(ambienteDoDisparo("rodar", "", "qa"), "qa");
  assert.equal(ambienteDoDisparo("rodar", "", "build"), "dev");
  assert.equal(ambienteDoDisparo("rodar", "", "backlog"), "dev");
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
