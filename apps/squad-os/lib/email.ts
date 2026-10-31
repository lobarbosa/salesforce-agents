// Envio de e-mail, sem dependência nova. Dois provedores, nesta ordem:
//
// 1. Microsoft 365 (2026-10-31) — Graph API, app registrado no Entra ID com
//    permissão de aplicativo `Mail.Send` (restrita por Application Access
//    Policy / RBAC for Applications à caixa remetente). Sai de uma caixa real
//    da empresa e fica nos Itens Enviados dela. Variáveis: M365_TENANT_ID,
//    M365_CLIENT_ID, M365_CLIENT_SECRET, M365_REMETENTE.
// 2. Resend — RESEND_API_KEY e COBRANCA_REMETENTE.
//
// Sem nenhum dos dois, as rotas que usam isto ficam em dry run — calculam e
// devolvem a prévia, não falham.

export interface EmailSaida {
  para: string;
  assunto: string;
  texto: string;
  /** Versão estilizada; o texto puro vai junto como alternativa. */
  html?: string;
  anexos?: { nome: string; conteudo: Buffer }[];
  /** Cópia oculta — o time recebe o mesmo que o cliente viu. */
  cco?: string[];
}

const env = (k: string) => process.env[k]?.trim() ?? "";

function m365Configurado(): boolean {
  return !!(env("M365_TENANT_ID") && env("M365_CLIENT_ID") && env("M365_CLIENT_SECRET") && env("M365_REMETENTE"));
}

function resendConfigurado(): boolean {
  return !!(env("RESEND_API_KEY") && env("COBRANCA_REMETENTE"));
}

export function emailConfigurado(): boolean {
  return m365Configurado() || resendConfigurado();
}

export async function enviarEmail(e: EmailSaida): Promise<boolean> {
  if (m365Configurado()) return enviarPorM365(e);
  if (resendConfigurado()) return enviarPorResend(e);
  return false;
}

// --- Microsoft 365 (Graph) -------------------------------------------------

// Token de aplicativo (client credentials) vale ~1h; guardado por instância
// da função para não pedir um a cada e-mail do lote.
let token: { valor: string; expiraEm: number } | null = null;

async function tokenM365(): Promise<string | null> {
  if (token && token.expiraEm > Date.now() + 60_000) return token.valor;
  const res = await fetch(`https://login.microsoftonline.com/${encodeURIComponent(env("M365_TENANT_ID"))}/oauth2/v2.0/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: env("M365_CLIENT_ID"),
      client_secret: env("M365_CLIENT_SECRET"),
      scope: "https://graph.microsoft.com/.default",
    }),
  }).catch(() => null);
  if (!res?.ok) {
    // Só o status e o código de erro do Entra — nunca o corpo inteiro.
    const corpo = (await res?.json().catch(() => null)) as { error?: string } | null;
    console.error("email: token M365 recusado", res?.status, corpo?.error ?? "");
    return null;
  }
  const j = (await res.json()) as { access_token: string; expires_in: number };
  token = { valor: j.access_token, expiraEm: Date.now() + j.expires_in * 1000 };
  return token.valor;
}

async function enviarPorM365(e: EmailSaida): Promise<boolean> {
  const t = await tokenM365();
  if (!t) return false;
  const endereco = (address: string) => ({ emailAddress: { address } });
  const res = await fetch(`https://graph.microsoft.com/v1.0/users/${encodeURIComponent(env("M365_REMETENTE"))}/sendMail`, {
    method: "POST",
    headers: { Authorization: `Bearer ${t}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        subject: e.assunto,
        body: e.html ? { contentType: "HTML", content: e.html } : { contentType: "Text", content: e.texto },
        toRecipients: [endereco(e.para)],
        ...(e.cco?.length ? { bccRecipients: e.cco.map(endereco) } : {}),
        ...(e.anexos?.length
          ? {
              attachments: e.anexos.map((a) => ({
                "@odata.type": "#microsoft.graph.fileAttachment",
                name: a.nome,
                contentType: a.nome.endsWith(".pdf") ? "application/pdf" : "application/octet-stream",
                contentBytes: a.conteudo.toString("base64"),
              })),
            }
          : {}),
      },
      // Fica nos Itens Enviados da caixa: o histórico do que cada cliente recebeu.
      saveToSentItems: true,
    }),
  }).catch(() => null);
  // Graph responde 202 Accepted sem corpo.
  if (!res?.ok) {
    const corpo = (await res?.json().catch(() => null)) as { error?: { code?: string } } | null;
    console.error("email: envio M365 falhou", res?.status, corpo?.error?.code ?? "");
  }
  return !!res?.ok;
}

// --- Resend ----------------------------------------------------------------

async function enviarPorResend(e: EmailSaida): Promise<boolean> {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${env("RESEND_API_KEY")}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: env("COBRANCA_REMETENTE"),
      to: [e.para],
      ...(e.cco?.length ? { bcc: e.cco } : {}),
      subject: e.assunto,
      text: e.texto,
      ...(e.html ? { html: e.html } : {}),
      ...(e.anexos?.length ? { attachments: e.anexos.map((a) => ({ filename: a.nome, content: a.conteudo.toString("base64") })) } : {}),
    }),
  }).catch(() => null);
  if (!res?.ok) console.error("email: envio Resend falhou", res?.status);
  return !!res?.ok;
}

export const APP_URL = (process.env.APP_URL?.trim() || "https://os.acxya.com").replace(/\/$/, "");

export const mascarar = (email: string) => email.replace(/^(.).*@/, "$1***@");
