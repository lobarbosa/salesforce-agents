import assert from "node:assert/strict";
import { entrouNaEtapaEm, paradas, type DemandaParaParada } from "../lib/esteira-parada";

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

const agora = new Date("2026-10-30T12:00:00Z");
const base: DemandaParaParada = {
  code: "X-1",
  titulo: "t",
  status: "aguardando_gate_analise",
  congeladaDe: null,
  criadoEm: new Date("2026-10-01T00:00:00Z"),
  historico: [],
  estimativaConsultorHoras: null,
  estimativaAprovadaHoras: null,
  estimativaDebitadaEm: null,
  artefatoNome: "",
  artefatoConteudo: "",
  disparos: [],
  client: { nome: "C" },
};

caso("re-sync no mesmo status não reinicia o relógio", () => {
  const d = {
    ...base,
    historico: [
      { para: "analise", em: "2026-10-20T00:00:00Z" },
      { para: "aguardando_gate_analise", em: "2026-10-21T12:00:00Z" },
      { para: "aguardando_gate_analise", em: "2026-10-21T12:05:00Z" },
    ],
  };
  assert.equal(entrouNaEtapaEm(d).toISOString(), "2026-10-21T12:00:00.000Z");
  assert.equal(paradas([d], agora)[0].diasNaEtapa, 9);
});
caso("sem histórico usa a criação", () => {
  assert.equal(entrouNaEtapaEm(base).getTime(), base.criadoEm.getTime());
});
caso("ordena da mais antiga e marca QA reprovado", () => {
  const velha = { ...base, code: "V", historico: [{ para: "aguardando_gate_analise", em: "2026-10-10T00:00:00Z" }] };
  const homolog = {
    ...base,
    code: "H",
    status: "aguardando_homologacao",
    historico: [{ para: "aguardando_homologacao", em: "2026-10-29T00:00:00Z" }],
    artefatoNome: "05-testes.md",
    artefatoConteudo: "### FALHA 1 (crítica) — CPU",
  };
  const r = paradas([homolog, velha], agora);
  assert.deepEqual(r.map((p) => p.code), ["V", "H"]);
  assert.equal(r[1].qaReprovado, true);
  assert.equal(r[1].acoes[0].quem, "cliente");
});

if (falhas) {
  console.log(`${falhas} falha(s)`);
  process.exit(1);
}
