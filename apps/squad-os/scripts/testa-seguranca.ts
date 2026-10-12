// Regras puras de segurança (revisão de 2026-10-12): destino de redirect
// pós-login, allowlist de upload e limites do copiloto.
import assert from "node:assert/strict";
import { destinoSeguro } from "@/lib/destino";

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

caso("destino: caminho interno passa intacto", () => {
  assert.equal(destinoSeguro("/clients/abc?x=1#y"), "/clients/abc?x=1#y");
  assert.equal(destinoSeguro("/"), "/");
});

caso("destino: vazio/nulo vira /", () => {
  assert.equal(destinoSeguro(null), "/");
  assert.equal(destinoSeguro(undefined), "/");
  assert.equal(destinoSeguro(""), "/");
});

caso("destino: javascript:, URL absoluta e protocolo-relativa são recusados", () => {
  for (const ruim of [
    "javascript:alert(1)",
    "JavaScript:alert(1)",
    "https://evil.com",
    "//evil.com",
    "/\\evil.com",
    "\\\\evil.com",
    ".evil.com",
    "evil.com",
    "/ok\nSet-Cookie:x",
    "/\tfoo",
  ]) {
    assert.equal(destinoSeguro(ruim), "/", ruim);
  }
});

// FIM-CASOS

if (falhas > 0) {
  console.log(`\n${falhas} caso(s) falharam`);
  process.exit(1);
}
console.log("\ntodos os casos passaram");
