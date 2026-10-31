import assert from "node:assert/strict";

// Testa lib/email.ts com fetch falso: qual provedor é escolhido e o formato
// que vai para a Graph API. Nenhuma chamada de rede de verdade.
let falhas = 0;
async function caso(nome: string, fn: () => Promise<void>) {
  try {
    await fn();
    console.log(`ok ${nome}`);
  } catch (e) {
    falhas++;
    console.log(`FALHA ${nome}\n${(e as Error).message}`);
  }
}

type Chamada = { url: string; init: RequestInit };
const chamadas: Chamada[] = [];
globalThis.fetch = (async (url: string, init: RequestInit) => {
  chamadas.push({ url: String(url), init });
  if (String(url).includes("login.microsoftonline.com")) {
    return new Response(JSON.stringify({ access_token: "tok", expires_in: 3600 }), { status: 200 });
  }
  return new Response(null, { status: 202 });
}) as typeof fetch;

const LIMPAR = ["M365_TENANT_ID", "M365_CLIENT_ID", "M365_CLIENT_SECRET", "M365_REMETENTE", "RESEND_API_KEY", "COBRANCA_REMETENTE"];

async function principal() {
  const email = await import("../lib/email");
  const msg = { para: "cliente@x.com", assunto: "Resumo", texto: "oi", cco: ["adm@x.com"], anexos: [{ nome: "r.pdf", conteudo: Buffer.from("%PDF-") }] };

  await caso("sem provedor: não envia", async () => {
    for (const k of LIMPAR) delete process.env[k];
    assert.equal(email.emailConfigurado(), false);
    assert.equal(await email.enviarEmail(msg), false);
    assert.equal(chamadas.length, 0);
  });

  await caso("M365 tem prioridade e monta a mensagem da Graph", async () => {
    Object.assign(process.env, { M365_TENANT_ID: "t", M365_CLIENT_ID: "c", M365_CLIENT_SECRET: "s", M365_REMETENTE: "relatorios@acxya.com", RESEND_API_KEY: "r", COBRANCA_REMETENTE: "x" });
    assert.equal(await email.enviarEmail(msg), true);
    const envio = chamadas.find((c) => c.url.includes("graph.microsoft.com"))!;
    assert.equal(envio.url, "https://graph.microsoft.com/v1.0/users/relatorios%40acxya.com/sendMail");
    assert.equal((envio.init.headers as Record<string, string>).Authorization, "Bearer tok");
    const corpo = JSON.parse(String(envio.init.body));
    assert.equal(corpo.saveToSentItems, true);
    assert.deepEqual(corpo.message.toRecipients, [{ emailAddress: { address: "cliente@x.com" } }]);
    assert.deepEqual(corpo.message.bccRecipients, [{ emailAddress: { address: "adm@x.com" } }]);
    assert.equal(corpo.message.body.contentType, "Text");
    assert.equal(corpo.message.attachments[0].contentType, "application/pdf");
    assert.equal(Buffer.from(corpo.message.attachments[0].contentBytes, "base64").toString(), "%PDF-");
    assert.ok(!chamadas.some((c) => c.url.includes("resend")));
  });

  await caso("token é reaproveitado no lote", async () => {
    const antes = chamadas.filter((c) => c.url.includes("login.microsoftonline.com")).length;
    await email.enviarEmail(msg);
    assert.equal(chamadas.filter((c) => c.url.includes("login.microsoftonline.com")).length, antes);
  });

  await caso("sem M365, cai no Resend", async () => {
    for (const k of ["M365_TENANT_ID", "M365_CLIENT_ID", "M365_CLIENT_SECRET", "M365_REMETENTE"]) delete process.env[k];
    chamadas.length = 0;
    assert.equal(await email.enviarEmail(msg), true);
    assert.equal(chamadas[0].url, "https://api.resend.com/emails");
  });

  if (falhas) {
    console.log(`${falhas} falha(s)`);
    process.exit(1);
  }
}
void principal();
