// Sem dependência de banco: testável em scripts/testa-seguranca.ts.

/** Puro (testável): maior sufixo numérico de `<PREFIXO>-<n>` + 1. */
export function proximoSufixo(prefix: string, codes: string[]): number {
  const re = new RegExp(`^${prefix.replace(/[^A-Z0-9]/g, "")}-(\\d+)$`);
  let maior = 0;
  for (const c of codes) {
    const m = re.exec(c);
    if (m) maior = Math.max(maior, Number(m[1]));
  }
  return maior + 1;
}
