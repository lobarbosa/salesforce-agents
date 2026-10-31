// Envio de e-mail pela API HTTP do Resend (sem dependência nova). Sem
// RESEND_API_KEY e COBRANCA_REMETENTE, as rotas que usam isto ficam em dry
// run — calculam e devolvem a prévia, não falham.

export interface EmailSaida {
  para: string;
  assunto: string;
  texto: string;
  /** Cópia oculta — o time recebe o mesmo que o cliente viu. */
  cco?: string[];
}

export function emailConfigurado(): boolean {
  return !!process.env.RESEND_API_KEY?.trim() && !!process.env.COBRANCA_REMETENTE?.trim();
}

export async function enviarEmail(e: EmailSaida): Promise<boolean> {
  if (!emailConfigurado()) return false;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY!.trim()}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: process.env.COBRANCA_REMETENTE!.trim(),
      to: [e.para],
      ...(e.cco?.length ? { bcc: e.cco } : {}),
      subject: e.assunto,
      text: e.texto,
    }),
  }).catch(() => null);
  if (!res?.ok) console.error("email: envio falhou", res?.status);
  return !!res?.ok;
}

export const APP_URL = (process.env.APP_URL?.trim() || "https://os.acxya.com").replace(/\/$/, "");

export const mascarar = (email: string) => email.replace(/^(.).*@/, "$1***@");
