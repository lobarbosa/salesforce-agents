// Allowlist de acesso ao Squad OS — só o time interno (nenhum cliente final
// autentica aqui). Duas formas de configurar, combináveis:
//   ALLOWED_EMAIL_DOMAIN=empresa.com          -> qualquer @empresa.com
//   ALLOWED_EMAILS=a@x.com,b@y.com            -> lista explícita (p/ contas fora do domínio)
export function isEmailAllowed(email: string | null | undefined): boolean {
  if (!email) return false;
  const normalized = email.toLowerCase().trim();

  const domain = process.env.ALLOWED_EMAIL_DOMAIN?.toLowerCase().trim();
  if (domain && normalized.endsWith("@" + domain)) return true;

  const explicitList = (process.env.ALLOWED_EMAILS ?? "")
    .split(",")
    .map((e) => e.toLowerCase().trim())
    .filter(Boolean);
  if (explicitList.includes(normalized)) return true;

  return false;
}
