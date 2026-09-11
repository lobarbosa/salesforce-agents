// As variáveis sem as quais o app não tem como funcionar, conferidas de uma vez
// só na borda (proxy.ts) em vez de cada uma explodir onde for usada.
//
// Por que isso existe (incidente de 2026-09-11): `NEXT_PUBLIC_SUPABASE_URL` não
// estava no escopo Preview da Vercel. `createServerClient` lança de forma
// síncrona quando a URL é `undefined`, e é a primeira coisa que o proxy faz —
// proxy que lança derruba **toda** rota, `/login` inclusive. O deploy ficou
// verde (o `next build` nunca avalia essas variáveis; o `!` é só do TypeScript)
// e o app devolvia "Internal Server Error" em texto puro, sem dizer o que
// faltava e sem nenhuma página alcançável onde alguém pudesse descobrir.
//
// Só o **nome** da variável aparece na resposta, nunca o valor.

export const VARIAVEIS_OBRIGATORIAS = [
  // Sem estas duas o cliente Supabase nem é construído.
  "NEXT_PUBLIC_SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  // Conferida aqui junto, e não só quando a primeira consulta acontecer: sem
  // ela o `/login` abriria normalmente e o app quebraria no instante seguinte,
  // que é mais difícil de diagnosticar do que não subir.
  "DATABASE_URL",
] as const;

export function variaveisFaltando(): string[] {
  return VARIAVEIS_OBRIGATORIAS.filter((nome) => !process.env[nome]?.trim());
}

export function mensagemDeConfiguracao(faltando: string[]): string {
  return [
    "Squad OS não subiu: faltam variáveis de ambiente neste deploy.",
    "",
    ...faltando.map((nome) => `  - ${nome}`),
    "",
    "Na Vercel, cada variável tem escopo por ambiente (Production / Preview /",
    "Development). Uma marcada só em Production deixa o Preview exatamente",
    "assim: build verde, e toda rota em erro — inclusive /login.",
    "",
    "O que cada uma é e onde pegar: docs/ativacao.md",
  ].join("\n");
}
