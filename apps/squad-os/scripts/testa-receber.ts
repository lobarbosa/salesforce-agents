// Regras de contas a receber (lib/receber.ts): nota = número + emissão,
// registro antigo, situação, validação do recebimento e totais.
import assert from "node:assert/strict";
import { lerReais } from "@/lib/contas";
import { chaveNota, consolidar, diferenca, lerChave, totais, validarRecebimento, type NotaPublicada, type RegistroRecebimento } from "@/lib/receber";

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

const HOJE = "2026-11-26";
const nota = (p: Partial<NotaPublicada>): NotaPublicada => ({
  numero: "10",
  data_emissao: "2026-10-01",
  cliente: "Mais Polímeros",
  valor: 1000,
  valor_liquido: 940,
  vencimento: "2026-10-20",
  ...p,
});
const registro = (p: Partial<RegistroRecebimento>): RegistroRecebimento => ({
  id: "r1",
  numero: "10",
  emissao: "2026-10-01",
  recebidoEm: "2026-10-22",
  valorRecebido: 940,
  forma: "pix",
  observacao: "",
  registradoPorEmail: "bia@acxya.com",
  registradoEm: "2026-11-26T12:00:00.000Z",
  estornadoEm: null,
  estornadoPorEmail: null,
  estornoMotivo: "",
  ...p,
});

caso("numeracao que recomecou: mesma nota so com numero e emissao iguais", () => {
  const l = consolidar([nota({}), nota({ data_emissao: "2026-11-03", vencimento: "2026-11-30" }), nota({})], [], {}, HOJE);
  assert.equal(l.length, 2);
  assert.deepEqual(l.map((n) => n.chave), ["10@2026-10-01", "10@2026-11-03"]);
});

caso("situacao: vencida, a vencer, sem vencimento", () => {
  const l = consolidar(
    [nota({}), nota({ numero: "11", vencimento: "2026-12-10" }), nota({ numero: "12", vencimento: null })],
    [],
    {},
    HOJE
  );
  assert.deepEqual(l.map((n) => [n.numero, n.situacao]).sort(), [["10", "vencida"], ["11", "a_vencer"], ["12", "sem_vencimento"]]);
});

caso("registro antigo so com o numero vale para a nota mais antiga", () => {
  const l = consolidar([nota({}), nota({ data_emissao: "2026-11-03", vencimento: "2026-11-19" })], [], { "010": "2026-10-20" }, HOJE);
  const [antiga, nova] = l;
  assert.equal(antiga.situacao, "recebida");
  assert.equal(antiga.recebimento?.origem, "registro_antigo");
  assert.equal(nova.situacao, "vencida");
});

caso("registro antigo numero@mes vale para a nota daquele mes", () => {
  const l = consolidar([nota({}), nota({ data_emissao: "2026-11-03", vencimento: "2026-11-19" })], [], { "10@2026-11": "2026-11-19" }, HOJE);
  assert.deepEqual(l.map((n) => n.situacao), ["vencida", "recebida"]);
});

caso("registro desta tela vence o antigo; desfeito volta a nota para aberta", () => {
  let [n] = consolidar([nota({})], [registro({})], {}, HOJE);
  assert.equal(n.recebimento?.origem, "squad_os");
  assert.equal(n.recebimento?.valor, 940);
  [n] = consolidar([nota({})], [registro({ estornadoEm: "2026-11-26T13:00:00.000Z", estornoMotivo: "nota errada" })], {}, HOJE);
  assert.equal(n.situacao, "vencida");
  assert.equal(n.historico.length, 1);
});

caso("esperado = liquido; sem liquido, o valor", () => {
  const [a, b] = consolidar([nota({}), nota({ numero: "11", valor_liquido: null })], [], {}, HOJE);
  assert.equal(a.esperado, 940);
  assert.equal(b.esperado, 1000);
});

caso("nota sem numero ou sem emissao fica de fora", () => {
  assert.equal(consolidar([nota({ numero: null }), nota({ data_emissao: null })], [], {}, HOJE).length, 0);
});

caso("validacao do recebimento", () => {
  const [n] = consolidar([nota({})], [], {}, HOJE);
  const ok = validarRecebimento(n, { recebidoEm: "2026-10-22", valorRecebido: "940,00", forma: "pix", observacao: " ok " }, HOJE, lerReais);
  assert.deepEqual(ok, { dados: { recebidoEm: "2026-10-22", valorRecebido: 940, forma: "pix", observacao: "ok" } });
  const erro = (e: object) => ("erro" in validarRecebimento(n, { recebidoEm: "2026-10-22", valorRecebido: "940", forma: "pix", ...e }, HOJE, lerReais));
  assert.ok(erro({ recebidoEm: "2026-12-01" }), "futuro");
  assert.ok(erro({ recebidoEm: "2026-09-30" }), "antes da emissao");
  assert.ok(erro({ valorRecebido: "abc" }), "valor");
  assert.ok(erro({ valorRecebido: "5.000,00" }), "muito acima");
  assert.ok(erro({ forma: "cheque" }), "forma");
});

caso("diferenca e totais", () => {
  const l = consolidar(
    [nota({}), nota({ numero: "11", vencimento: "2026-12-10", valor_liquido: 500 }), nota({ numero: "12", vencimento: "2027-03-01", valor_liquido: 300 })],
    [registro({ valorRecebido: 900, recebidoEm: "2026-11-05" })],
    {},
    HOJE
  );
  assert.equal(diferenca(l.find((n) => n.numero === "10")!), -40);
  const t = totais(l, HOJE);
  assert.deepEqual(t.abertas, { qtd: 2, valor: 800 });
  assert.deepEqual(t.vencidas, { qtd: 0, valor: 0 });
  assert.deepEqual(t.proximas30, { qtd: 1, valor: 500 });
  assert.deepEqual(t.recebidasMes, { qtd: 1, valor: 900 });
});

caso("chave ida e volta", () => {
  assert.equal(chaveNota("0010", "2026-10-01"), "10@2026-10-01");
  assert.deepEqual(lerChave("10@2026-10-01"), { numero: "10", emissao: "2026-10-01" });
  assert.equal(lerChave("10@2026-10"), null);
  assert.equal(lerChave("x@2026-10-01"), null);
});

if (falhas) {
  console.log(`\n${falhas} caso(s) falharam`);
  process.exit(1);
}
console.log("\ncontas a receber: tudo ok");
