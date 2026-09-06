import { createBrowserClient } from "@supabase/ssr";

// Cliente Supabase para Client Components — usado só para auth (login por
// magic link, logout). Toda leitura/escrita de dados passa pelas API routes
// (Prisma no servidor), não por este cliente.
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
