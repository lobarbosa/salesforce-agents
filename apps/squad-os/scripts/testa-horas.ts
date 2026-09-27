// Regras puras da grade "Minhas horas" (lib/horas.ts) — sem servidor, sem Prisma.
import assert from "node:assert/strict";
import {
  ancoraDoDia,
  chaveDia,
  diasDaSemana,
  ehChaveDia,
  formatarDuracao,
  inicioDaSemana,
  intervaloDaSemana,
  lerDuracao,
  parcelaDaGrade,
} from "@/lib/horas";

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

caso("formatos aceitos na celula", () => {
  assert.equal(lerDuracao("1:30"), 90);
  assert.equal(lerDuracao("1,5"), 90);
  assert.equal(lerDuracao("1.5"), 90);
  assert.equal(lerDuracao("1h30"), 90);
  assert.equal(lerDuracao("2h"), 120);
  assert.equal(lerDuracao("90m"), 90);
  assert.equal(lerDuracao("45min"), 45);
  assert.equal(lerDuracao(" 8 "), 480);
  assert.equal(lerDuracao("0,25"), 15);
});

caso("vazio e zero apagam a celula", () => {
  assert.equal(lerDuracao(""), 0);
  assert.equal(lerDuracao("0"), 0);
});

caso("texto que nao e duracao devolve null", () => {
  for (const s of ["abc", "1:75", "-1", "1:3", "100", "1,2,3"]) assert.equal(lerDuracao(s), null, s);
});

caso("formatacao h:mm", () => {
  assert.equal(formatarDuracao(90), "1:30");
  assert.equal(formatarDuracao(480), "8:00");
  assert.equal(formatarDuracao(5), "0:05");
  assert.equal(formatarDuracao(0), "");
});

caso("semana vai de segunda a domingo", () => {
  assert.equal(inicioDaSemana("2026-09-27"), "2026-09-21"); // domingo
  assert.equal(inicioDaSemana("2026-09-21"), "2026-09-21"); // segunda
  assert.equal(inicioDaSemana("2026-10-01"), "2026-09-28"); // quinta
  assert.deepEqual(diasDaSemana("2026-09-28").slice(-1), ["2026-10-04"]);
});

caso("dia e o de Sao Paulo, nao o do servidor em UTC", () => {
  // 01:30 UTC de terca = 22:30 de segunda em SP
  assert.equal(chaveDia(new Date("2026-09-29T01:30:00Z")), "2026-09-28");
  assert.equal(chaveDia(ancoraDoDia("2026-09-28")), "2026-09-28");
});

caso("intervalo da semana em instantes absolutos de SP", () => {
  const { desde, ate } = intervaloDaSemana("2026-09-28");
  assert.equal(desde.toISOString(), "2026-09-28T03:00:00.000Z");
  assert.equal(ate.toISOString(), "2026-10-05T03:00:00.000Z");
});

caso("validacao de chave de dia", () => {
  assert.ok(ehChaveDia("2026-02-28"));
  assert.ok(!ehChaveDia("2026-02-30"));
  assert.ok(!ehChaveDia("28/09/2026"));
});

caso("grade nao desce abaixo do que o cronometro ja lancou", () => {
  assert.equal(parcelaDaGrade(120, 45), 75);
  assert.equal(parcelaDaGrade(45, 45), 0);
  assert.ok(parcelaDaGrade(30, 45) < 0);
});

console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
