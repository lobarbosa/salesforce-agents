// Regras de contas a pagar (lib/contas.ts): segregação, alçada, transições.
import assert from "node:assert/strict";
import { bloqueio, lerReais, prazo, type ContaParaRegra } from "@/lib/contas";

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

const conta = (p: Partial<ContaParaRegra> = {}): ContaParaRegra => ({
  status: "aguardando_aprovacao",
  valor: 1000,
  lancadoPorEmail: "ana@acxya.com",
  ...p,
});
const admin = { role: "admin" as const, email: "ceo@acxya.com" };
const fin = { role: "financeiro" as const, email: "bia@acxya.com" };

caso("quem lancou nao aprova a propria conta (segregacao)", () => {
  assert.match(bloqueio("aprovar", conta({ lancadoPorEmail: "CEO@acxya.com" }), admin, 0)!, /quem lançou/);
  assert.match(bloqueio("recusar", conta({ lancadoPorEmail: "bia@acxya.com" }), fin, 5000)!, /quem lançou/);
});

caso("admin aprova qualquer valor de conta alheia", () => {
  assert.equal(bloqueio("aprovar", conta({ valor: 999999 }), admin, 0), null);
});

caso("financeiro aprova so ate a alcada", () => {
  assert.equal(bloqueio("aprovar", conta({ valor: 5000 }), fin, 5000), null);
  assert.match(bloqueio("aprovar", conta({ valor: 5000.01 }), fin, 5000)!, /alçada/);
  assert.match(bloqueio("aprovar", conta({ valor: 1 }), fin, 0)!, /admin/);
});

caso("consultor e cliente nao agem", () => {
  assert.match(bloqueio("pagar", conta({ status: "aprovada" }), { role: "consultor", email: "x@a" }, 0)!, /financeiro/);
  assert.match(bloqueio("cancelar", conta(), { role: "cliente", email: "y@a" }, 0)!, /financeiro/);
});

caso("transicoes validas", () => {
  assert.match(bloqueio("pagar", conta(), admin, 0)!, /aprovada/);
  assert.equal(bloqueio("pagar", conta({ status: "aprovada" }), fin, 0), null);
  assert.match(bloqueio("aprovar", conta({ status: "paga" }), admin, 0)!, /não está aguardando/);
  assert.equal(bloqueio("cancelar", conta({ status: "aprovada" }), fin, 0), null);
  assert.match(bloqueio("cancelar", conta({ status: "paga" }), admin, 0)!, /não pode ser cancelada/);
});

caso("valor em reais digitado", () => {
  assert.equal(lerReais("1.234,56"), 1234.56);
  assert.equal(lerReais("R$ 1.234"), 1234);
  assert.equal(lerReais("1234.5"), 1234.5);
  assert.equal(lerReais("89,9"), 89.9);
  assert.equal(lerReais("0"), null);
  assert.equal(lerReais("abc"), null);
  assert.equal(lerReais("1,234,5"), null);
});

caso("prazo por texto", () => {
  assert.deepEqual(prazo("2026-09-27", "2026-09-27"), { texto: "vence hoje", vencida: false, urgente: true });
  assert.equal(prazo("2026-09-30", "2026-09-27").texto, "vence em 3 dias");
  assert.equal(prazo("2026-09-26", "2026-09-27").texto, "vencida há 1 dia");
  assert.equal(prazo("2026-10-10", "2026-09-27").urgente, false);
});

console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
