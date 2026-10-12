import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { destinoSeguro } from "@/lib/destino";

// Callback do magic link do Supabase Auth — troca o `code` por sessão e
// grava os cookies antes de redirecionar. O proxy.ts cuida da allowlist
// na próxima navegação.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  // Sem a validação, `next=.evil.com` montava `https://os.acxya.com.evil.com`
  // e `next=//evil.com` saía do domínio — ver lib/destino.ts.
  const next = destinoSeguro(searchParams.get("next"));

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/login?error=auth_failed`);
}
