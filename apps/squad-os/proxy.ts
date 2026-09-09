import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { resolveUsuario } from "@/lib/auth";

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
  const isPublic = PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + "/"));

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

  function redirectTo(pathname: string, search?: Record<string, string>) {
    const url = request.nextUrl.clone();
    url.pathname = pathname;
    url.search = "";
    if (search) for (const [k, v] of Object.entries(search)) url.searchParams.set(k, v);
    return withRefreshedCookies(NextResponse.redirect(url));
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    if (isPublic) return withRefreshedCookies(NextResponse.next({ request }));
    return redirectTo("/login", { next: pathname });
  }

  const usuario = user.email ? await resolveUsuario(user.email) : null;

  if (!usuario) {
    await supabase.auth.signOut();
    if (isPublic) return withRefreshedCookies(NextResponse.next({ request }));
    return redirectTo("/login", { error: "not_allowed" });
  }

  const homeFor = (id: string | null) => (usuario.role === "cliente" ? `/clients/${id}` : "/");

  if (isPublic) {
    return redirectTo(homeFor(usuario.clientId));
  }

  // /admin é só do admin.
  const isAdminRoute =
    pathname === "/admin" || pathname.startsWith("/admin/") || pathname.startsWith("/api/admin");
  if (isAdminRoute && usuario.role !== "admin") {
    return redirectTo(homeFor(usuario.clientId));
  }

  // role=cliente só enxerga o próprio cliente — sem Visão Geral cross-cliente,
  // sem navegar pra outro /clients/<id>.
  if (usuario.role === "cliente") {
    if (pathname === "/") {
      return redirectTo(`/clients/${usuario.clientId}`);
    }
    const clientMatch = pathname.match(/^\/clients\/([^/]+)/);
    if (clientMatch && clientMatch[1] !== usuario.clientId) {
      return redirectTo(`/clients/${usuario.clientId}`);
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
