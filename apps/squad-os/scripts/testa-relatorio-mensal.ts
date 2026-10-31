import assert from "node:assert/strict";
import { entreguesNoMes, nomeDoMes, textoDoRelatorio } from "../lib/relatorio-mensal";
import { gerarPdfRelatorio } from "../lib/relatorio-pdf";

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

caso("entregue no mês pelo fuso de São Paulo, e só a última entrega conta", () => {
  const d = [
    { code: "A", status: "entregue", historico: [{ para: "entregue", em: "2026-10-31T23:30:00Z" }] }, // 20h30 de 31/10 em SP
    { code: "B", status: "entregue", historico: [{ para: "entregue", em: "2026-11-01T02:30:00Z" }] }, // 23h30 de 31/10 em SP
    { code: "C", status: "entregue", historico: [{ para: "entregue", em: "2026-10-10T12:00:00Z" }, { para: "aguardando_homologacao", em: "2026-10-29T00:00:00Z" }, { para: "entregue", em: "2026-11-03T12:00:00Z" }] },
    { code: "D", status: "aguardando_homologacao", historico: [{ para: "entregue", em: "2026-10-10T12:00:00Z" }] },
  ];
  assert.deepEqual(entreguesNoMes(d, "2026-10").map((x) => x.code), ["A", "B"]);
});
caso("nome do mês", () => assert.equal(nomeDoMes("2026-10"), "outubro de 2026"));
caso("AMS mostra consumo, percentual e excedente", () => {
  const { assunto, texto } = textoDoRelatorio({
    clienteNome: "Somos",
    mes: "2026-10",
    entregues: [{ code: "S-1", titulo: "Campo" }],
    contrato: { tipo: "ams", cicloHoras: "mensal", doMes: { mes: "2026-10", horasGastas: 44.5, horasNoCiclo: 44.5, horasContratadas: 40 } },
    url: "u",
  });
  assert.equal(assunto, "Somos — resumo de outubro de 2026");
  assert.match(texto, /• Demandas concluídas: 1 \(S-1\)/);
  assert.match(texto, /PDF em anexo/);
  assert.match(texto, /44,5 h de 40 h \(111%\)/);
  assert.match(texto, /Excedente: 4,5 h/);
});
caso("projeto mostra progresso e horas acumuladas", () => {
  const { texto } = textoDoRelatorio({
    clienteNome: "Eplast",
    mes: "2026-10",
    entregues: [],
    contrato: {
      tipo: "projeto",
      nome: "Ondas 1–2",
      progresso: { pct: 67, pesoConcluido: 8, pesoTotal: 12, concluidos: 8, total: 12 },
      horasDoMes: 30,
      horasAcumuladas: 68,
      horasContratadas: 120,
      entregaveisConcluidos: ["Diagnóstico"],
    },
    url: "u",
  });
  assert.match(texto, /• Demandas concluídas: 0\n/);
  assert.match(texto, /67% \(8 de 12 entregáveis\)/);
  assert.match(texto, /68 h de 120 h \(57%\)/);
});

async function principal() {
  const pdf = await gerarPdfRelatorio(
    {
      clienteNome: "Somos",
      mes: "2026-10",
      entregues: [{ code: "S-1", titulo: "Ação com acentuação: é, ç, ã", entregueEm: "2026-10-28", horasAprovadas: 5, horasLancadas: 6.5 }],
      contrato: { tipo: "ams", cicloHoras: "mensal", doMes: { mes: "2026-10", horasGastas: 10, horasNoCiclo: 10, horasContratadas: 40 }, historico: [] },
      url: "u",
    },
    null
  );
  caso("PDF é gerado", () => assert.equal(pdf.subarray(0, 5).toString(), "%PDF-"));
  if (falhas) {
    console.log(`${falhas} falha(s)`);
    process.exit(1);
  }
}
void principal();
