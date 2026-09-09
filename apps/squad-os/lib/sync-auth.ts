import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";

// As rotas de /api/sync são chamadas pelo GitHub Actions, que não tem cookie
// nem navegador — a autenticação é um bearer token compartilhado
// (SQUAD_OS_SYNC_TOKEN, secret de repositório no GitHub e env var na Vercel),
// não a sessão Supabase que o resto do app usa. proxy.ts deixa /api/sync
// passar por isso; quem tranca é esta função.
//
// Comparação em tempo constante: `a === b` sai no primeiro byte diferente, e
// como este endpoint aceita chamada de qualquer origem, isso dá pra usar como
// oráculo pra descobrir o token byte a byte. Custa uma linha evitar.
export function autorizarSync(request: NextRequest): NextResponse | null {
  const esperado = process.env.SQUAD_OS_SYNC_TOKEN;
  if (!esperado) {
    // Sem token configurado a rota fica fechada, não aberta. O contrário
    // transformaria "esqueci de configurar" em "qualquer um escreve no banco".
    return NextResponse.json(
      { error: "sync não configurado (falta SQUAD_OS_SYNC_TOKEN)" },
      { status: 503 }
    );
  }

  const header = request.headers.get("authorization") ?? "";
  const recebido = header.startsWith("Bearer ") ? header.slice(7) : "";

  const a = Buffer.from(recebido);
  const b = Buffer.from(esperado);
  // timingSafeEqual exige tamanhos iguais; comparar o tamanho antes já vaza o
  // tamanho, o que é inofensivo, e evita a exceção.
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    return NextResponse.json({ error: "não autorizado" }, { status: 401 });
  }

  return null;
}
