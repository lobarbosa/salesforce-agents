import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";

// As rotas de /api/sync são chamadas pelo GitHub Actions, que não tem cookie
// nem navegador — a autenticação é um bearer token compartilhado, não a
// sessão Supabase que o resto do app usa. proxy.ts deixa /api/sync passar
// por isso; quem tranca é esta função.
//
// Por cliente, com fallback pro token global (achado do council de
// 2026-10-01): até aqui só existia `SQUAD_OS_SYNC_TOKEN`, um único secret
// global usado pelos 6 clientes e pelas 4+ rotas de sync. Vazou uma vez,
// vaza tudo — a capacidade de "aprovar qualquer gate de qualquer cliente
// remotamente" nos 6 clientes ao mesmo tempo, sem passar por nenhum dos 3
// guardrails de produção (eles pressupõem que quem chega até eles já passou
// por aprovação humana legítima; um token vazado quebra essa premissa antes
// de qualquer guardrail rodar).
//
// `autorizarSync(request, clientSlug)` resolve o token esperado assim:
// 1. Existe `SQUAD_OS_SYNC_TOKEN_<CLIENTE>` (cliente já migrado)? Usa só ele
//    — o token global para de valer pra ESTE cliente. Migração real, não
//    "mais uma chave que também abre a porta".
// 2. Senão, usa o `SQUAD_OS_SYNC_TOKEN` global — comportamento de hoje,
//    sem exigir nenhum secret novo configurado. Migra cliente por cliente,
//    sem quebrar quem ainda não migrou.
//
// Comparação em tempo constante: `a === b` sai no primeiro byte diferente, e
// como este endpoint aceita chamada de qualquer origem, isso dá pra usar como
// oráculo pra descobrir o token byte a byte. Custa uma linha evitar.

function nomeVarPorCliente(clientSlug: string): string {
  const normalizado = clientSlug
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return `SQUAD_OS_SYNC_TOKEN_${normalizado}`;
}

function tokensIguais(esperado: string, recebido: string): boolean {
  const a = Buffer.from(recebido);
  const b = Buffer.from(esperado);
  // timingSafeEqual exige tamanhos iguais; comparar o tamanho antes já vaza o
  // tamanho, o que é inofensivo, e evita a exceção.
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * @param clientSlug Slug do cliente que a requisição afirma ser, quando a
 *   rota já sabe disso (lido do corpo antes de autorizar). Omitido, usa só o
 *   token global — mesmo comportamento de antes desta mudança.
 */
export function autorizarSync(request: NextRequest, clientSlug?: string): NextResponse | null {
  const tokenPorCliente = clientSlug ? process.env[nomeVarPorCliente(clientSlug)] : undefined;
  const tokenGlobal = process.env.SQUAD_OS_SYNC_TOKEN;
  const esperado = tokenPorCliente || tokenGlobal;

  if (!esperado) {
    // Sem token configurado a rota fica fechada, não aberta. O contrário
    // transformaria "esqueci de configurar" em "qualquer um escreve no banco".
    return NextResponse.json(
      { error: "sync não configurado (falta SQUAD_OS_SYNC_TOKEN ou o token deste cliente)" },
      { status: 503 }
    );
  }

  const header = request.headers.get("authorization") ?? "";
  const recebido = header.startsWith("Bearer ") ? header.slice(7) : "";

  if (!tokensIguais(esperado, recebido)) {
    return NextResponse.json({ error: "não autorizado" }, { status: 401 });
  }

  return null;
}
