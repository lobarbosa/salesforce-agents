import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Cliente Supabase para Server Components e Route Handlers — lê/escreve a
// sessão via cookies do request atual. Precisa ser recriado a cada request
// (não é um singleton), como orienta o próprio pacote.
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // chamado a partir de um Server Component sem acesso de escrita a
            // cookies — inofensivo enquanto o proxy.ts também renova a sessão.
          }
        },
      },
    }
  );
}
