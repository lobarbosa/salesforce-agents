import assert from "node:assert/strict";
import { emailDoCliente, emailDoTime, type ParadaComCliente } from "../lib/cobranca";
import { exigeRiscoAceito } from "../lib/qa-veredito";

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

const p = (o: Partial<ParadaComCliente>): ParadaComCliente => ({
  cliente: "Somos",
  clientId: "c1",
  code: "S-1",
  titulo: "t",
  acoes: [],
  diasNaEtapa: 5,
  qaReprovado: false,
  ...o,
});

caso("cliente só recebe o que é dele, na linguagem dele", () => {
  const e = emailDoCliente({ email: "j@x", nome: "Juliana Mendes" }, "Somos", [
    p({ code: "A", acoes: [{ quem: "cliente", oque: "aprovar horas" }] }),
    p({ code: "B", acoes: [{ quem: "time", oque: "revisar PR" }] }),
  ], "u")!;
  assert.match(e.texto, /A — t: aprovar a estimativa de horas/);
  assert.doesNotMatch(e.texto, /\bB\b/);
  assert.match(e.texto, /^Olá, Juliana\./);
});
caso("sem nada para o cliente, não manda", () => {
  assert.equal(emailDoCliente({ email: "j@x", nome: "" }, "Somos", [p({ acoes: [{ quem: "time", oque: "revisar PR" }] })], "u"), null);
});
caso("time só é cobrado do que passou de 2 dias", () => {
  assert.equal(emailDoTime({ email: "l@x" }, [p({ diasNaEtapa: 1, acoes: [{ quem: "time", oque: "aprovar análise" }] })], "u"), null);
  const e = emailDoTime({ email: "l@x" }, [p({ acoes: [{ quem: "time", oque: "aprovar análise" }], qaReprovado: true })], "u")!;
  assert.match(e.assunto, /1 com o time, 0 com clientes/);
  assert.match(e.texto, /QA reprovou/);
});
caso("homologar com falha crítica exige risco aceito", () => {
  const base = { status: "aguardando_homologacao", artefatoNome: "05-testes.md" };
  assert.ok(exigeRiscoAceito({ ...base, artefatoConteudo: "### FALHA 1 (crítica) — CPU" }));
  assert.ok(!exigeRiscoAceito({ ...base, artefatoConteudo: "### FALHA 3 (branda) — null" }));
  assert.ok(!exigeRiscoAceito({ ...base, status: "aguardando_gate_build", artefatoConteudo: "### FALHA 1 (crítica) — x" }));
});

if (falhas) {
  console.log(`${falhas} falha(s)`);
  process.exit(1);
}
