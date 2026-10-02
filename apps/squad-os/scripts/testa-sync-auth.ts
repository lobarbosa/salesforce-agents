// autorizarSync (lib/sync-auth.ts): token por cliente com fallback pro
// global — achado do council de 2026-10-01 (token único vazado compromete
// os 6 clientes de uma vez).
import assert from "node:assert/strict";
import type { NextRequest } from "next/server";
import { autorizarSync } from "@/lib/sync-auth";

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

function pedido(bearer: string | null): NextRequest {
  return {
    headers: { get: (nome: string) => (nome.toLowerCase() === "authorization" ? bearer : null) },
  } as unknown as NextRequest;
}

const ENV_GLOBAL = "SQUAD_OS_SYNC_TOKEN";
const ENV_ACXYA = "SQUAD_OS_SYNC_TOKEN_ACXYA";

function limparEnv() {
  delete process.env[ENV_GLOBAL];
  delete process.env[ENV_ACXYA];
}

caso("sem nenhum token configurado, a rota fica fechada (503), nunca aberta", () => {
  limparEnv();
  const resp = autorizarSync(pedido("Bearer qualquer-coisa"), "acxya");
  assert.equal(resp?.status, 503);
});

caso("só token global configurado: aceita pra qualquer cliente", () => {
  limparEnv();
  process.env[ENV_GLOBAL] = "token-global";
  assert.equal(autorizarSync(pedido("Bearer token-global"), "acxya"), null);
  assert.equal(autorizarSync(pedido("Bearer token-global"), "eplast"), null);
  assert.equal(autorizarSync(pedido("Bearer token-global")), null); // sem clientSlug nenhum
});

caso("token errado é recusado (401), com ou sem token por cliente", () => {
  limparEnv();
  process.env[ENV_GLOBAL] = "token-global";
  assert.equal(autorizarSync(pedido("Bearer errado"), "acxya")?.status, 401);
  assert.equal(autorizarSync(pedido(null), "acxya")?.status, 401);
});

caso("cliente migrado (token por cliente configurado) para de aceitar o token global", () => {
  limparEnv();
  process.env[ENV_GLOBAL] = "token-global";
  process.env[ENV_ACXYA] = "token-so-da-acxya";

  // O token global antigo não abre mais a porta da acxya — é o ponto inteiro
  // da segmentação: migrar um cliente reduz o raio de um vazamento do token
  // global, não soma mais uma chave que também funciona.
  assert.equal(autorizarSync(pedido("Bearer token-global"), "acxya")?.status, 401);
  assert.equal(autorizarSync(pedido("Bearer token-so-da-acxya"), "acxya"), null);

  // Cliente que não migrou continua aceitando o token global normalmente.
  assert.equal(autorizarSync(pedido("Bearer token-global"), "eplast"), null);
  assert.equal(autorizarSync(pedido("Bearer token-so-da-acxya"), "eplast")?.status, 401);
});

caso("nome da env var por cliente normaliza hífen e caixa", () => {
  limparEnv();
  process.env["SQUAD_OS_SYNC_TOKEN_SOMOS_AGILITY"] = "token-somos-agility";
  assert.equal(autorizarSync(pedido("Bearer token-somos-agility"), "somos-agility"), null);
  assert.equal(autorizarSync(pedido("Bearer token-somos-agility"), "SOMOS-AGILITY"), null);
});

limparEnv();
console.log(falhas === 0 ? "\ntodos ok" : `\n${falhas} falha(s)`);
process.exit(falhas ? 1 : 0);
