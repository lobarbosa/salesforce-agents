import { prisma } from "@/lib/prisma";
import { BUCKET_FINANCEIRO, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { montarRelatorioDoCliente } from "@/lib/relatorio-mensal-data";

// Relatório mensal publicado na página do cliente (2026-11-21). Só mês que foi
// ENVIADO ao cliente aparece lá: a página mostra o mesmo PDF que chegou no
// e-mail, guardado no envio. Envio de antes desta mudança não tem arquivo: o
// primeiro download gera o PDF de agora e guarda, e daí em diante é fixo.

export const caminhoDoRelatorio = (clientId: string, mes: string) => `relatorios-mensais/${clientId}/${mes}.pdf`;

export async function guardarRelatorio(clientId: string, mes: string, pdf: Buffer): Promise<string | null> {
  if (!serviceRoleConfigurado()) return null;
  const caminho = caminhoDoRelatorio(clientId, mes);
  const { error } = await createServiceClient()
    .storage.from(BUCKET_FINANCEIRO)
    .upload(caminho, pdf, { contentType: "application/pdf", upsert: true });
  if (error) {
    console.error("relatorio-publicado: falha ao guardar", { clientId, mes, erro: error.message });
    return null;
  }
  await prisma.relatorioEnviado.updateMany({ where: { clientId, mes }, data: { arquivo: caminho } });
  return caminho;
}

/** O PDF publicado do mês, ou null se o mês não foi enviado a este cliente. */
export async function relatorioPublicado(clientId: string, mes: string): Promise<{ pdf: Buffer; nome: string } | null> {
  const envio = await prisma.relatorioEnviado.findUnique({ where: { clientId_mes: { clientId, mes } } });
  if (!envio) return null;
  const nome = `relatorio-${mes}.pdf`;
  if (envio.arquivo && serviceRoleConfigurado()) {
    const { data, error } = await createServiceClient().storage.from(BUCKET_FINANCEIRO).download(envio.arquivo);
    if (!error && data) return { pdf: Buffer.from(await data.arrayBuffer()), nome };
  }
  const r = await montarRelatorioDoCliente(clientId, mes);
  if (!r) return null;
  await guardarRelatorio(clientId, mes, r.pdf);
  return { pdf: r.pdf, nome: r.nomeArquivo };
}
