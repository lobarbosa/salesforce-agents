import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Este módulo é o único lugar que instancia o cliente de service role. Vale
// pra Storage (bucket privado de anexos) e pra Auth admin (convite de usuário
// novo, ver app/api/admin/usuarios/route.ts) — as duas coisas que o app faz
// com autoridade própria, fora da sessão de quem está logado.
//
// Bucket **privado** — precisa ser criado uma vez no painel do Supabase
// (Storage → New bucket → "anexos-demanda", Public desmarcado).
export const BUCKET_ANEXOS = "anexos-demanda";

export function serviceRoleConfigurado(): boolean {
  return Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY
  );
}

// Service role de propósito, e só aqui no servidor. O bucket não tem policy
// de RLS nenhuma: quem autoriza é `resolverDemanda`, que sabe o cliente da
// demanda. Uma policy genérica de `authenticated` no bucket deixaria o papel
// `cliente` do cliente A baixar anexo do cliente B — exatamente o isolamento
// que o resto do app existe pra manter. Nunca exponha esta chave ao browser
// (o download sai por URL assinada e curta, ver [anexoId]/route.ts).
export function createServiceClient(): SupabaseClient {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } }
  );
}

