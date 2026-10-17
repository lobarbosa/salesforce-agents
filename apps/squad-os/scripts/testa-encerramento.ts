// Encerrar × excluir cliente (lib/encerramento.ts) — sem servidor e sem banco.
// As regras puras são testadas direto; criarDemanda() e resolveUsuario() rodam
// de verdade contra um Prisma falso (lib/prisma.ts reaproveita
// globalThis.prisma quando existe), e a ligação das rotas com as regras é
// conferida no fonte — o que importa ali é que o gate exista em cada porta.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { Role } from "@/lib/generated/prisma/client";
import {
  bloqueioPorEncerramento,
  bloqueiosDeExclusao,
  enxergaCliente,
  nomeConfere,
  podeEncerrarCliente,
  usuarioPerdeAcesso,
  validarEncerramento,
  validarExclusao,
  validarReativacao,
  type HistoricoDoCliente,
} from "@/lib/encerramento";

let falhas = 0;
// Um caso por vez, inclusive os assíncronos: os do Prisma falso dividem o
// mesmo `banco` e não podem se intercalar.
let fila: Promise<void> = Promise.resolve();
function caso(nome: string, fn: () => void | Promise<void>) {
  fila = fila.then(async () => {
    try {
      await fn();
      console.log(`ok    ${nome}`);
    } catch (e) {
      falhas++;
      console.log(`FALHA ${nome}\n        ${(e as Error).message.split("\n")[0]}`);
    }
  });
}

const PAPEIS: Role[] = ["admin", "consultor", "financeiro", "cliente"];
const ENCERRADO = new Date("2026-10-10T15:00:00Z");
const ativo = { nome: "Acme", slug: "acme", encerradoEm: null };
const encerrado = { nome: "Acme", slug: "acme", encerradoEm: ENCERRADO };
const SEM_HISTORICO: HistoricoDoCliente = { demandas: 0, registrosTempo: 0, execucoes: 0, entregaveis: 0, horasContratadas: 0 };

// ── Permissão ───────────────────────────────────────────────────────────────

caso("permissão: só admin encerra, reativa e exclui", () => {
  for (const r of PAPEIS) assert.equal(podeEncerrarCliente(r), r === "admin", r);
});

caso("permissão: as três rotas perguntam podeEncerrarCliente antes de tudo", () => {
  const raiz = process.cwd();
  const encerramento = readFileSync(join(raiz, "app/api/clients/[id]/encerramento/route.ts"), "utf8");
  const cliente = readFileSync(join(raiz, "app/api/clients/[id]/route.ts"), "utf8");
  // POST (encerrar) + DELETE (reativar)
  assert.equal(encerramento.match(/!podeEncerrarCliente\(usuario\.role\)/g)?.length, 2);
  // DELETE (excluir)
  assert.match(cliente, /export async function DELETE[\s\S]*!podeEncerrarCliente\(usuario\.role\)/);
});

caso("visibilidade: encerrado só o admin enxerga; ativo, todo mundo", () => {
  for (const r of PAPEIS) {
    assert.equal(enxergaCliente(r, ativo), true, r);
    assert.equal(enxergaCliente(r, encerrado), r === "admin", r);
  }
});

caso("acesso: usuário cliente de cliente encerrado perde o login; os demais papéis não", () => {
  assert.equal(usuarioPerdeAcesso("cliente", encerrado), true);
  assert.equal(usuarioPerdeAcesso("cliente", ativo), false);
  assert.equal(usuarioPerdeAcesso("cliente", null), false);
  for (const r of ["admin", "consultor", "financeiro"] as Role[]) assert.equal(usuarioPerdeAcesso(r, encerrado), false, r);
});

// ── Bloqueios do encerrado ──────────────────────────────────────────────────

caso("bloqueio: ativo não bloqueia nada", () => {
  for (const a of ["demanda", "tempo", "agente", "sync", "acesso"] as const) assert.equal(bloqueioPorEncerramento(ativo, a), null);
  assert.equal(bloqueioPorEncerramento(null, "demanda"), null);
});

caso("bloqueio: encerrado recusa demanda, tempo, agente e sync com mensagem clara", () => {
  const d = bloqueioPorEncerramento(encerrado, "demanda");
  assert.ok(d && d.includes("Acme") && d.includes("10/10/2026") && d.includes("demanda nova"), String(d));
  assert.ok(bloqueioPorEncerramento(encerrado, "tempo")?.includes("horas"));
  assert.ok(bloqueioPorEncerramento(encerrado, "agente")?.includes("agente"));
  assert.ok(bloqueioPorEncerramento(encerrado, "sync")?.includes("sync"));
});

caso("bloqueio: as portas de horas e de agente estão ligadas à regra", () => {
  const ler = (p: string) => readFileSync(join(process.cwd(), p), "utf8");
  assert.match(ler("app/api/demandas/[id]/tempo/route.ts"), /clienteAtivo: "tempo"/);
  assert.match(ler("app/api/horas/route.ts"), /clienteAtivo: "tempo"/);
  for (const p of [
    "app/api/demandas/[id]/materialize/route.ts",
    "app/api/demandas/[id]/aprovar-gate/route.ts",
    "app/api/clients/[id]/contrato/plano/route.ts",
    "app/api/clients/[id]/assessment/route.ts",
    "app/api/clients/[id]/ambientes/[tipo]/test-connection/route.ts",
  ]) {
    assert.match(ler(p), /recusaSeEncerrado\(\w+(\.client)?, "agente"\)/, p);
  }
  for (const p of ["demanda", "plano", "assessment", "conexao", "rag", "rag-query", "anexos"]) {
    assert.match(ler(`app/api/sync/${p}/route.ts`), /recusaSeEncerrado(PorId)?\([^)]*"sync"\)/, p);
  }
  assert.match(ler("lib/assessment.ts"), /bloqueioPorEncerramento\(c, "agente"\)/);
  assert.match(ler("lib/data.ts"), /getClients\(\) \{\n\s+return prisma\.client\.findMany\(\{\n\s+where: \{ encerradoEm: null \}/);
});

// ── Encerrar / reativar ─────────────────────────────────────────────────────

caso("encerrar: exige motivo e cliente ativo", () => {
  assert.deepEqual(validarEncerramento(ativo, "saiu"), { ok: true });
  assert.equal(validarEncerramento(ativo, "   ").ok, false);
  assert.equal(validarEncerramento(ativo, "x".repeat(501)).ok, false);
  const jaEncerrado = validarEncerramento(encerrado, "de novo");
  assert.equal(jaEncerrado.ok, false);
  assert.equal(!jaEncerrado.ok && jaEncerrado.status, 409);
});

caso("reativar: só cliente encerrado", () => {
  assert.deepEqual(validarReativacao(encerrado), { ok: true });
  const r = validarReativacao(ativo);
  assert.equal(!r.ok && r.status, 409);
  // Reativado = encerradoEm nulo: nada mais bloqueia nem esconde.
  const reativado = { ...encerrado, encerradoEm: null };
  assert.equal(bloqueioPorEncerramento(reativado, "demanda"), null);
  assert.equal(enxergaCliente("consultor", reativado), true);
  assert.equal(usuarioPerdeAcesso("cliente", reativado), false);
});

// ── Excluir definitivamente ─────────────────────────────────────────────────

caso("excluir: recusado com histórico, listando o que bloqueia", () => {
  const h = { ...SEM_HISTORICO, demandas: 12, registrosTempo: 34 };
  const r = validarExclusao(encerrado, h, "Acme");
  assert.equal(r.ok, false);
  assert.equal(!r.ok && r.status, 409);
  assert.deepEqual(r.bloqueios, ["12 demandas", "34 registros de horas"]);
  assert.ok(!r.ok && r.error.includes("12 demandas, 34 registros de horas"));
});

caso("excluir: cada tipo de histórico bloqueia sozinho", () => {
  for (const campo of Object.keys(SEM_HISTORICO) as (keyof HistoricoDoCliente)[]) {
    assert.equal(bloqueiosDeExclusao({ ...SEM_HISTORICO, [campo]: 1 }).length, 1, campo);
  }
  assert.deepEqual(bloqueiosDeExclusao({ ...SEM_HISTORICO, demandas: 1, execucoes: 2 }), ["1 demanda", "2 execuções de agente"]);
});

caso("excluir: cliente ativo nunca é excluído, mesmo sem histórico", () => {
  const r = validarExclusao(ativo, SEM_HISTORICO, "Acme");
  assert.equal(!r.ok && r.status, 409);
});

caso("excluir: encerrado sem histórico passa só com o nome digitado", () => {
  assert.deepEqual(validarExclusao(encerrado, SEM_HISTORICO, "Acme"), { ok: true });
  assert.deepEqual(validarExclusao(encerrado, SEM_HISTORICO, "  acme "), { ok: true });
  for (const errado of ["", "Acm", "Acme Corp", "acme-x"]) {
    const r = validarExclusao(encerrado, SEM_HISTORICO, errado);
    assert.equal(!r.ok && r.status, 400, errado);
  }
  assert.equal(nomeConfere("", ""), false);
});

// ── Com Prisma falso: o código de verdade ──────────────────────────────────

type Linha = Record<string, unknown>;
const banco: { client: Linha | null; usuario: Linha | null; criadas: Linha[] } = { client: null, usuario: null, criadas: [] };
(globalThis as unknown as { prisma: unknown }).prisma = {
  client: { findUnique: async () => banco.client },
  usuario: {
    findUnique: async () => banco.usuario,
    create: async () => {
      throw new Error("não devia criar usuário");
    },
  },
  demanda: {
    findMany: async () => [],
    create: async ({ data }: { data: Linha }) => {
      banco.criadas.push(data);
      return { id: "d1", ...data };
    },
  },
};

const admin = { id: "u1", email: "a@acxya.com", nome: "Admin", role: "admin" as Role, clientId: null };

caso("criarDemanda: cliente encerrado recusa com 409 (API e copiloto passam por aqui)", async () => {
  const { criarDemanda } = await import("@/lib/demandas-server");
  banco.client = { id: "c1", ...encerrado };
  banco.criadas = [];
  const r = await criarDemanda({ usuario: admin, clientId: "c1", titulo: "ajuste" });
  assert.equal(r.ok, false);
  assert.equal(!r.ok && r.status, 409);
  assert.ok(!r.ok && r.error.includes("encerrado"));
  assert.equal(banco.criadas.length, 0);
});

caso("criarDemanda: cliente ativo (ou reativado) cria em backlog", async () => {
  const { criarDemanda } = await import("@/lib/demandas-server");
  banco.client = { id: "c1", ...ativo };
  banco.criadas = [];
  const r = await criarDemanda({ usuario: admin, clientId: "c1", titulo: "ajuste" });
  assert.equal(r.ok, true);
  assert.equal(banco.criadas.length, 1);
  assert.equal(banco.criadas[0].status, "backlog");
});

caso("resolveUsuario: cliente de encerrado não entra; consultor e cliente de ativo entram", async () => {
  const { resolveUsuario } = await import("@/lib/auth");
  banco.usuario = { id: "u2", email: "x@acme.com", role: "cliente", clientId: "c1", client: { encerradoEm: ENCERRADO } };
  assert.equal(await resolveUsuario("x@acme.com"), null);
  banco.usuario = { id: "u2", email: "x@acme.com", role: "cliente", clientId: "c1", client: { encerradoEm: null } };
  const ok = await resolveUsuario("x@acme.com");
  assert.equal(ok?.id, "u2");
  assert.equal("client" in (ok ?? {}), false);
  banco.usuario = { id: "u3", email: "c@acxya.com", role: "consultor", clientId: null, client: null };
  assert.equal((await resolveUsuario("c@acxya.com"))?.id, "u3");
});

// FIM-CASOS

fila.then(() => {
  if (falhas > 0) {
    console.log(`\n${falhas} caso(s) falharam`);
    process.exit(1);
  }
  console.log("\ntodos os casos passaram");
});
