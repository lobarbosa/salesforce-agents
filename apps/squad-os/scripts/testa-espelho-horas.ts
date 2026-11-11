// Espelho de horas (lib/espelho-horas.ts) e o PDF — sem servidor, sem Prisma.
import assert from "node:assert/strict";
import { dataBr, erroDoPeriodo, horasDoEspelho, janelaDaConsulta, montarEspelho, nomeDoArquivo, semanaPassada, type RegistroDoEspelho } from "../lib/espelho-horas";
import { gerarPdfEspelho } from "../lib/espelho-horas-pdf";

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

const r = (autor: string, quando: string, minutos: number | null, code = "G-1", titulo = "Projetos Salesforce"): RegistroDoEspelho => ({
  autor,
  inicioEm: new Date(quando),
  minutos,
  demanda: { code, titulo },
});

// Semana do modelo do Clockify: 28/09 a 04/10/2026, 8h por dia útil = 40h.
const semanaCheia = ["09-28", "09-29", "09-30", "10-01", "10-02"].map((d) => r("Eduardo Ribas", `2026-${d}T12:00:00Z`, 480));

caso("semana do modelo: 40h, 8h de segunda a sexta, fim de semana vazio", () => {
  const e = montarEspelho(semanaCheia, "2026-09-28", "2026-10-04");
  assert.equal(e.total, 2400);
  assert.equal(e.semanas.length, 1);
  const s = e.semanas[0];
  assert.deepEqual(s.dias, ["2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04"]);
  assert.deepEqual(s.fora, []);
  assert.equal(s.demandas.length, 1);
  assert.equal(s.demandas[0].consultores[0].consultor, "Eduardo Ribas");
  assert.equal(s.demandas[0].consultores[0].porDia["2026-10-01"], 480);
  assert.equal(s.porDia["2026-10-03"], undefined);
  assert.equal(horasDoEspelho(s.total), "40:00");
});

caso("o dia é o de São Paulo, não o UTC", () => {
  // 01:30Z de 29/09 = 22:30 de 28/09 em SP
  const e = montarEspelho([r("Ana", "2026-09-29T01:30:00Z", 60)], "2026-09-28", "2026-09-28");
  assert.equal(e.total, 60);
  assert.equal(e.semanas[0].porDia["2026-09-28"], 60);
});

caso("fora do período, sem duração e zerado ficam de fora", () => {
  const e = montarEspelho(
    [r("Ana", "2026-09-27T15:00:00Z", 60), r("Ana", "2026-10-05T15:00:00Z", 60), r("Ana", "2026-09-30T15:00:00Z", null), r("Ana", "2026-09-30T15:00:00Z", 0)],
    "2026-09-28",
    "2026-10-04"
  );
  assert.equal(e.total, 0);
  assert.equal(e.semanas.length, 0);
});

caso("vários consultores e demandas: somas batem em todos os níveis", () => {
  const e = montarEspelho(
    [
      r("Bia", "2026-10-05T15:00:00Z", 120, "G-2", "Suporte"),
      r("Ana", "2026-10-05T15:00:00Z", 90, "G-2", "Suporte"),
      r("Ana", "2026-10-05T18:00:00Z", 30, "G-2", "Suporte"),
      r("Ana", "2026-10-06T15:00:00Z", 45, "G-10", "Integração"),
      ...semanaCheia,
    ],
    "2026-09-28",
    "2026-10-11"
  );
  assert.equal(e.semanas.length, 2);
  const s2 = e.semanas[1];
  assert.deepEqual(s2.demandas.map((d) => d.code), ["G-2", "G-10"]); // ordem numérica
  assert.deepEqual(s2.demandas[0].consultores.map((c) => c.consultor), ["Ana", "Bia"]);
  assert.equal(s2.demandas[0].consultores[0].porDia["2026-10-05"], 120); // dois lançamentos no mesmo dia somam
  assert.equal(s2.demandas[0].porDia["2026-10-05"], 240);
  assert.equal(s2.total, 285);
  assert.equal(e.total, 2400 + 285);
  assert.equal(e.total, e.semanas.reduce((n, s) => n + s.total, 0));
  assert.equal(e.total, e.resumo.reduce((n, x) => n + x.minutos, 0));
  assert.equal(e.total, e.porConsultor.reduce((n, x) => n + x.minutos, 0));
  assert.equal(e.porConsultor[0].consultor, "Eduardo Ribas");
  for (const s of e.semanas) assert.equal(s.total, Object.values(s.porDia).reduce((n, x) => n + x, 0));
});

caso("período no meio da semana marca os dias de fora", () => {
  const e = montarEspelho([r("Ana", "2026-10-01T15:00:00Z", 60)], "2026-10-01", "2026-10-02");
  assert.deepEqual(e.semanas[0].fora, ["2026-09-28", "2026-09-29", "2026-09-30", "2026-10-03", "2026-10-04"]);
});

caso("validação do período", () => {
  const hoje = "2026-11-11";
  assert.equal(erroDoPeriodo("2026-09-28", "2026-10-04", hoje), null);
  assert.equal(erroDoPeriodo("2026-11-11", "2026-11-11", hoje), null);
  assert.ok(erroDoPeriodo(null, "2026-10-04", hoje));
  assert.ok(erroDoPeriodo("28/09/2026", "2026-10-04", hoje));
  assert.ok(erroDoPeriodo("2026-10-05", "2026-10-04", hoje));
  assert.ok(erroDoPeriodo("2026-11-12", "2026-11-13", hoje));
  assert.equal(erroDoPeriodo("2026-07-01", "2026-10-01", hoje), null); // 93 dias
  assert.ok(erroDoPeriodo("2026-07-01", "2026-10-02", hoje)); // 94
});

caso("formatos, janela, nome do arquivo e semana passada", () => {
  assert.equal(horasDoEspelho(0), "0:00");
  assert.equal(horasDoEspelho(485), "8:05");
  assert.equal(horasDoEspelho(6000), "100:00");
  assert.equal(dataBr("2026-09-28"), "28/09/2026");
  const j = janelaDaConsulta("2026-09-28", "2026-10-04");
  assert.equal(j.gte.toISOString(), "2026-09-27T00:00:00.000Z");
  assert.equal(j.lt.toISOString(), "2026-10-06T00:00:00.000Z");
  assert.equal(nomeDoArquivo("Gauge Solução S/A", "2026-09-28", "2026-10-04"), "espelho-horas-gauge-solucao-s-a-2026-09-28-a-2026-10-04.pdf");
  assert.equal(nomeDoArquivo("Gauge", "2026-09-28", "2026-10-04", "Eduardo Ribas"), "espelho-horas-gauge-eduardo-ribas-2026-09-28-a-2026-10-04.pdf");
  assert.deepEqual(semanaPassada("2026-11-11"), { desde: "2026-11-02", ate: "2026-11-08" });
  assert.deepEqual(semanaPassada("2026-11-09"), { desde: "2026-11-02", ate: "2026-11-08" }); // segunda
  assert.deepEqual(semanaPassada("2026-11-08"), { desde: "2026-10-26", ate: "2026-11-01" }); // domingo
});

async function principal() {
  const cab = { clienteNome: "Gauge", emissor: "Acxya", geradoEm: "2026-11-11" };
  const ehPdf = (b: Buffer) => b.subarray(0, 5).toString() === "%PDF-" && b.length > 800;
  const paginas = (b: Buffer) => (b.toString("latin1").match(/\/Type \/Page\b/g) ?? []).length;
  try {
    const um = await gerarPdfEspelho(montarEspelho(semanaCheia, "2026-09-28", "2026-10-04"), cab, null);
    assert.ok(ehPdf(um));
    assert.equal(paginas(um), 1);
    console.log("ok PDF de uma semana cabe em uma página");

    const vazio = await gerarPdfEspelho(montarEspelho([], "2026-09-28", "2026-10-04"), cab, null);
    assert.ok(ehPdf(vazio));
    console.log("ok PDF sem horas");

    // Trimestre com 12 consultores em 6 demandas: várias páginas, sem estourar.
    const muitos: RegistroDoEspelho[] = [];
    for (let dia = 0; dia < 90; dia++) {
      const quando = new Date(Date.parse("2026-07-01T15:00:00Z") + dia * 86_400_000).toISOString();
      for (let c = 0; c < 12; c++) muitos.push(r(`Consultor ${c} de nome bem comprido para cortar`, quando, 60 + c, `G-${c % 6}`, "Demanda de título bem comprido ".repeat(4)));
    }
    const grande = await gerarPdfEspelho(montarEspelho(muitos, "2026-07-01", "2026-09-28"), { ...cab, consultor: "Todos" }, null);
    assert.ok(ehPdf(grande));
    assert.ok(paginas(grande) > 5 && paginas(grande) < 40, `páginas: ${paginas(grande)}`);
    console.log(`ok PDF de um trimestre (${paginas(grande)} páginas)`);
  } catch (e) {
    falhas++;
    console.log(`FALHA PDF\n${(e as Error).message}`);
  }
  if (falhas) {
    console.log(`${falhas} falha(s)`);
    process.exit(1);
  }
}
void principal();
