import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { resolveUsuario } from "@/lib/auth";
import { areaDaRota, inicioDo, podeVer } from "@/lib/permissoes";
import { mensagemDeConfiguracao, variaveisFaltando } from "@/lib/env";

// Next.js 16 renomeou middleware.ts -> proxy.ts (mesma função, novo nome —
// ver node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md).
// Proxy roda em runtime Node.js por padrão no Next 16 (diferente de versões
// anteriores, que rodavam em Edge) — por isso dá pra usar Prisma aqui direto,
// e este arquivo é o único lugar que faz as duas coisas: (1) confirma sessão
// Supabase válida, (2) resolve o Usuario (papel + cliente) via lib/auth.ts e
// aplica o roteamento por papel. O resultado vira headers `x-squad-os-*` no
// request — Server Components e Route Handlers leem via lib/current-user.ts
// em vez de repetir essa consulta.
// `/api/sync` é a única rota que não passa por sessão de usuário: quem chama é
// o GitHub Actions, que não tem cookie nem navegador. Ela se autentica com o
// bearer token SQUAD_OS_SYNC_TOKEN, validado dentro da própria rota — deixar
// passar aqui não a torna aberta, só troca o mecanismo de autenticação. Ver
// app/api/sync/demanda/route.ts.
const PUBLIC_PATHS = ["/login", "/auth/callback", "/api/sync"];

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  // Identidade só vem do proxy: header x-squad-os-* enviado pelo browser é
  // descartado em toda rota (inclusive as públicas, que não o reescrevem).
  for (const nome of [...request.headers.keys()]) {
    if (nome.toLowerCase().startsWith("x-squad-os-")) request.headers.delete(nome);
  }
  const isPublic = PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + "/"));

  // Antes de qualquer outra coisa: um proxy que lança derruba **toda** rota,
  // `/login` inclusive, e o Next devolve "Internal Server Error" em texto puro
  // sem dizer o motivo. Conferir aqui troca isso por uma resposta que nomeia a
  // variável que falta. Ver lib/env.ts — é uma resposta de operação, não uma
  // tela: 503 porque o app não subiu, não porque a requisição estava errada.
  const faltando = variaveisFaltando();
  if (faltando.length > 0) {
    return new NextResponse(mensagemDeConfiguracao(faltando), {
      status: 503,
      headers: {
        "content-type": "text/plain; charset=utf-8",
        // Configuração errada não pode ficar em cache de CDN e sobreviver ao
        // conserto da variável.
        "cache-control": "no-store",
      },
    });
  }

  // Supabase pode renovar o access token durante getUser() e escrever os
  // novos cookies aqui dentro de setAll — precisa sobreviver até a response
  // final, senão a renovação é descartada e o usuário reloga sem motivo.
  let refreshed = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          refreshed = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            refreshed.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // Aplica os cookies renovados (se houve) em cima de qualquer response que
  // este proxy decidir devolver — redirect ou next().
  function withRefreshedCookies<T extends NextResponse>(res: T): T {
    refreshed.cookies.getAll().forEach((c) => res.cookies.set(c));
    return res;
  }

  // Chamada de API não pode ser redirecionada para uma página de login: o
  // `fetch` segue o redirect, recebe 200 com HTML, e o app conclui "sem
  // conexão com o servidor" quando o que houve foi sessão expirada. Verificado
  // em 2026-09-11 (`PUT /api/clients/.../contrato` sem sessão → 200 text/html).
  // Para `/api/*` a resposta honesta é 401 com JSON, que o cliente sabe ler.
  const ehApi = pathname.startsWith("/api/");
  function naoAutenticado(motivo: string) {
    return withRefreshedCookies(
      NextResponse.json({ error: motivo, sessaoExpirada: true }, { status: 401 })
    );
  }

  function redirectTo(pathname: string, search?: Record<string, string>) {
    const url = request.nextUrl.clone();
    url.pathname = pathname;
    url.search = "";
    if (search) for (const [k, v] of Object.entries(search)) url.searchParams.set(k, v);
    return withRefreshedCookies(NextResponse.redirect(url));
  }

  // Falha de rede com o Supabase não pode virar 500 em toda rota: sem este
  // try/catch, uma indisponibilidade momentânea tira até o `/login` do ar e
  // ninguém consegue nem ver o que aconteceu. Tratar como deslogado **nega**
  // acesso, nunca concede — é a direção segura de errar.
  let user: Awaited<ReturnType<typeof supabase.auth.getUser>>["data"]["user"] = null;
  try {
    ({
      data: { user },
    } = await supabase.auth.getUser());
  } catch (err) {
    console.error("proxy: falha ao consultar a sessão no Supabase", err);
  }

  if (!user) {
    if (isPublic) return withRefreshedCookies(NextResponse.next({ request }));
    if (ehApi) return naoAutenticado("sua sessão expirou — entre de novo");
    return redirectTo("/login", { next: pathname });
  }

  const usuario = user.email ? await resolveUsuario(user.email) : null;

  if (!usuario) {
    await supabase.auth.signOut();
    if (isPublic) return withRefreshedCookies(NextResponse.next({ request }));
    if (ehApi) return naoAutenticado("este acesso não está mais liberado");
    return redirectTo("/login", { error: "not_allowed" });
  }

  const inicio = inicioDo(usuario.role, usuario.clientId);

  if (isPublic) {
    return redirectTo(inicio);
  }

  // Áreas por papel (lib/permissoes.ts): /financeiro, /operacao, /admin, /horas.
  // Isto é navegação; páginas e APIs checam de novo (o gate de verdade).
  const area = areaDaRota(pathname);
  if (area && !podeVer(usuario.role, area)) {
    if (ehApi) return NextResponse.json({ error: "sem permissão" }, { status: 403 });
    return redirectTo(inicio);
  }

  // Visão Geral e clientes são do time de entrega: o cliente só vê o próprio
  // cliente; o financeiro não vê briefing nem demandas.
  if (usuario.role === "cliente" || usuario.role === "financeiro") {
    if (pathname === "/") {
      return redirectTo(inicio);
    }
    const clientMatch = pathname.match(/^\/clients\/([^/]+)/);
    if (clientMatch && (usuario.role === "financeiro" || clientMatch[1] !== usuario.clientId)) {
      return redirectTo(inicio);
    }
  }

  // Vai no request encaminhado, não na response que volta pro browser — é o
  // request que Server Components/Route Handlers enxergam via `headers()`.
  request.headers.set("x-squad-os-usuario-id", usuario.id);
  request.headers.set("x-squad-os-usuario-email", usuario.email);
  request.headers.set("x-squad-os-usuario-nome", usuario.nome);
  request.headers.set("x-squad-os-usuario-role", usuario.role);
  request.headers.set("x-squad-os-usuario-client-id", usuario.clientId ?? "");

  return withRefreshedCookies(NextResponse.next({ request }));
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
