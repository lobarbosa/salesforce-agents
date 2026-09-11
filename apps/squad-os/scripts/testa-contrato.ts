// Reproduz a navegação que causou a perda de dado em produção, contra a regra
// pura — sem servidor, sem Prisma.
import assert from "node:assert/strict";
import {
  montarDadosDoContrato,
  ContratoInvalidoError,
  type ContratoGuardado,
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

console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
