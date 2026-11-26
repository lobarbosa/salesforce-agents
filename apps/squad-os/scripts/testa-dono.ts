import assert from "node:assert/strict";
import { donoInicial, lerDonoDoCorpo, nomeDoDono, podeSerDono, primeiroNome } from "../lib/dono";
import { emailDoTime, type ParadaComCliente } from "../lib/cobranca";

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

caso("só o time pode ser dono", () => {
  assert.ok(podeSerDono("admin"));
  assert.ok(podeSerDono("consultor"));
  assert.ok(!podeSerDono("cliente"));
  assert.ok(!podeSerDono("financeiro"));
});

caso("quem cria é o dono, se for do time", () => {
  assert.equal(donoInicial({ id: "u1", role: "consultor" }), "u1");
  assert.equal(donoInicial({ id: "u2", role: "cliente" }), null);
});

caso("corpo do PUT: só donoId, string de id ou null", () => {
  assert.deepEqual(lerDonoDoCorpo({ donoId: "ckx1" }), { ok: true, donoId: "ckx1" });
  assert.deepEqual(lerDonoDoCorpo({ donoId: null }), { ok: true, donoId: null });
  assert.equal(lerDonoDoCorpo({ donoId: "x' OR 1=1" }).ok, false);
  assert.equal(lerDonoDoCorpo({ donoId: 3 }).ok, false);
  assert.equal(lerDonoDoCorpo({ donoId: "u1", autor: "outra pessoa" }).ok, false);
  assert.equal(lerDonoDoCorpo([]).ok, false);
  assert.equal(lerDonoDoCorpo(null).ok, false);
});

caso("nome na tela: nome, ou e-mail de quem não tem nome", () => {
  assert.equal(nomeDoDono({ nome: "Ana Souza", email: "a@x" }), "Ana Souza");
  assert.equal(nomeDoDono({ nome: " ", email: "a@x" }), "a@x");
  assert.equal(nomeDoDono(null), "");
  assert.equal(primeiroNome({ nome: "Ana Souza", email: "a@x" }), "Ana");
  assert.equal(primeiroNome({ nome: "", email: "a@x" }), "a@x");
});

const p = (o: Partial<ParadaComCliente>): ParadaComCliente => ({
  cliente: "Somos",
  clientId: "c1",
  code: "S-1",
  titulo: "t",
  acoes: [{ quem: "time", oque: "aprovar análise" }],
  diasNaEtapa: 5,
  qaReprovado: false,
  ...o,
});

caso("cobrança do time: o que é seu vem primeiro, e o assunto diz quanto", () => {
  const e = emailDoTime({ email: "Ana@x" }, [p({ code: "A", donoEmail: "ana@x" }), p({ code: "B", donoEmail: "beto@x" })], "u")!;
  assert.match(e.assunto, /^Esteira: 1 sua · 2 com o time/);
  assert.match(e.texto, /^Com você como dono \(1\):\n- Somos · A/);
  // A lista inteira continua abaixo.
  assert.match(e.texto, /Esperando o time \(2\):/);
});

caso("cobrança do time: demanda sem dono é marcada; sem saber, não", () => {
  const e = emailDoTime({ email: "l@x" }, [p({ code: "A", donoEmail: null }), p({ code: "B" })], "u")!;
  assert.match(e.texto, /A — t: .* — sem dono/);
  assert.doesNotMatch(e.texto, /B — t: [^\n]*sem dono/);
  assert.doesNotMatch(e.assunto, /sua/);
});

if (falhas) {
  console.log(`${falhas} falha(s)`);
  process.exit(1);
}
