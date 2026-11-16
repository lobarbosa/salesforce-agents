// Recorte por papel da demanda (lib/visao-cliente.ts) — sem servidor, sem Prisma.
// O que desce como prop vai inteiro pro navegador: estes casos garantem que
// estimativa e custo de agente não vazam pro cliente, e custo não vaza pro
// consultor.
import assert from "node:assert/strict";
import type { DemandaCompleta } from "@/lib/data";
import { caminhoDasEvidencias, caminhoDoRoteiro, demandaParaCliente, ehAnexoDasEvidencias, ehAnexoDoQa, ehAnexoDoRoteiro, semCustoAgente } from "@/lib/visao-cliente";

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

const base = {
  id: "d1",
  status: "aguardando_gate_design",
  artefatoNome: "03-design.md",
  artefatoConteudo: "interno",
  artefatoTruncado: false,
  roteiroCliente: "passo a passo",
  perguntas: [],
  historico: [{ de: "a" }],
  ultimoRunUrl: "https://run",
  ultimoResultado: "success",
  estimativaHorasMin: 4,
  estimativaHorasMax: 8,
  estimativaHorasFonte: "03-design.md",
  estimativaConsultorHoras: 10,
  estimativaConsultorPor: "Consultora",
  sugestaoConsultorHoras: 9,
  agenteHorasGasto: 0.5,
  agenteHorasRestante: 1.2,
  custoAgenteGastoUsd: 1.5,
  custoAgenteRestanteUsd: 3,
  custoAgenteAmostras: 5,
  estimativaCalibrada: { min: 8, max: 14, calibracao: { fator: 1.5, amostras: 4, escopo: "cliente" } },
  subtarefas: [],
  checklist: [],
  tempos: [],
} as unknown as DemandaCompleta;

caso("cliente não recebe a faixa crua do agente nem custo de agente", () => {
  const d = demandaParaCliente(base);
  assert.equal(d.estimativaHorasMin, null);
  assert.equal(d.estimativaHorasMax, null);
  assert.equal(d.agenteHorasGasto, null);
  assert.equal(d.sugestaoConsultorHoras, null);
  assert.equal(d.estimativaConsultorPor, "");
  assert.equal(d.agenteHorasRestante, null);
  assert.equal(d.custoAgenteGastoUsd, null);
  assert.equal(d.custoAgenteRestanteUsd, null);
});

// A estimativa oficial do consultor é o número que o cliente aprova (e que
// debita do contrato no build) — ele a vê depois da análise, nunca antes.
caso("cliente vê a estimativa oficial só depois da análise", () => {
  const comOficial = { ...base, estimativaConsultorHoras: 12 } as DemandaCompleta;
  assert.equal(demandaParaCliente(comOficial).estimativaConsultorHoras, 12);
  const antes = demandaParaCliente({ ...comOficial, status: "analise" } as DemandaCompleta);
  assert.equal(antes.estimativaConsultorHoras, null);
});

caso("cliente vê só a faixa calibrada depois da análise, sem o fator", () => {
  const d = demandaParaCliente(base);
  assert.deepEqual([d.estimativaCalibrada!.min, d.estimativaCalibrada!.max], [8, 14]);
  assert.equal(d.estimativaCalibrada!.calibracao.amostras, 0);
  const antes = demandaParaCliente({ ...base, status: "analise" } as DemandaCompleta);
  assert.equal(antes.estimativaCalibrada, null);
});

caso("recorte do cliente continua escondendo artefato e run", () => {
  const d = demandaParaCliente(base);
  assert.equal(d.artefatoConteudo, "");
  assert.equal(d.ultimoRunUrl, "");
  assert.deepEqual(d.historico, []);
});

caso("cliente só vê o anexo do roteiro de teste da homologação em diante", () => {
  const roteiro = { id: "a1", demandaId: "d1", caminho: caminhoDoRoteiro("d1"), nome: "Roteiro de teste - X-1.pdf" };
  const outro = { id: "a2", demandaId: "d1", caminho: "d1/9f3c-print.png", nome: "print.png" };
  const comAnexos = { ...base, anexos: [roteiro, outro] } as unknown as DemandaCompleta;
  assert.equal(ehAnexoDoRoteiro(roteiro), true);
  assert.equal(ehAnexoDoRoteiro(outro), false);

  assert.deepEqual(demandaParaCliente(comAnexos).anexos.map((a) => a.id), ["a2"]);
  for (const status of ["aguardando_homologacao", "release", "entregue"]) {
    const d = demandaParaCliente({ ...comAnexos, status } as DemandaCompleta);
    assert.deepEqual(d.anexos.map((a) => a.id), ["a1", "a2"], status);
  }
  // o texto do roteiro é insumo do PDF: nunca desce para o cliente
  assert.equal(demandaParaCliente({ ...comAnexos, status: "entregue" } as DemandaCompleta).roteiroCliente, "");
  assert.equal(semCustoAgente(comAnexos).anexos.length, 2);
});

caso("evidências de teste seguem a regra do roteiro: o cliente só as vê da homologação em diante", () => {
  const evidencias = { id: "a3", demandaId: "d1", caminho: caminhoDasEvidencias("d1"), nome: "Evidências de teste - X-1.pdf" };
  const outro = { id: "a2", demandaId: "d1", caminho: "d1/9f3c-print.png", nome: "print.png" };
  const comAnexos = { ...base, anexos: [evidencias, outro] } as unknown as DemandaCompleta;
  assert.equal(ehAnexoDasEvidencias(evidencias), true);
  assert.equal(ehAnexoDoQa(evidencias), true);
  assert.equal(ehAnexoDoQa(outro), false);
  assert.deepEqual(demandaParaCliente(comAnexos).anexos.map((a) => a.id), ["a2"]);
  const d = demandaParaCliente({ ...comAnexos, status: "aguardando_homologacao" } as DemandaCompleta);
  assert.deepEqual(d.anexos.map((a) => a.id), ["a3", "a2"]);
});

caso("consultor mantém horas mas perde custo de agente", () => {
  const d = semCustoAgente(base);
  assert.equal(d.estimativaHorasMax, 8);
  assert.equal(d.agenteHorasRestante, 1.2);
  assert.equal(d.custoAgenteGastoUsd, null);
  assert.equal(d.custoAgenteRestanteUsd, null);
  assert.equal(d.artefatoConteudo, "interno");
});

if (falhas) {
  console.log(`\n${falhas} falha(s)`);
  process.exit(1);
}
