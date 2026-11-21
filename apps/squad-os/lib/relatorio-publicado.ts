import { prisma } from "@/lib/prisma";
import { BUCKET_FINANCEIRO, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { montarRelatorioDoCliente } from "@/lib/relatorio-mensal-data";
import { mesesPublicaveis } from "@/lib/relatorio-mensal";
import { chaveDia } from "@/lib/horas";

// Relatório mensal publicado na página do cliente (2026-11-21, decisão do
// responsável): todo mês fechado ganha o PDF de resumo (demandas concluídas,
// contrato e horas) na aba Contrato, para o cliente e o time, sem depender do
// envio por e-mail.
//
// - O cron do fechamento (/api/cron/relatorio-mensal) publica o mês que fechou
//   no primeiro dia útil, para todo cliente ativo.
// - Mês fechado que ainda não tem PDF (outubro de 2026, o primeiro, ou um
//   cliente novo) é gerado e guardado no primeiro acesso.
// - O envio por e-mail regrava com o PDF que foi enviado: a página mostra o
//   mesmo que chegou ao cliente.
// Uma vez guardado, o PDF não muda sozinho: horas editadas depois só entram se
// alguém reenviar o relatório.

export const caminhoDoRelatorio = (clientId: string, mes: string) => `relatorios-mensais/${clientId}/${mes}.pdf`;

/** Guarda o PDF e registra a publicação. Devolve false se o armazenamento falhou. */
export async function publicarRelatorio(clientId: string, mes: string, pdf: Buffer): Promise<boolean> {
  if (!serviceRoleConfigurado()) return false;
  const arquivo = caminhoDoRelatorio(clientId, mes);
  const { error } = await createServiceClient()
    .storage.from(BUCKET_FINANCEIRO)
    .upload(arquivo, pdf, { contentType: "application/pdf", upsert: true });
  if (error) {
    console.error("relatorio-publicado: falha ao guardar", { clientId, mes, erro: error.message });
    return false;
  }
  await prisma.relatorioPublicado.upsert({
    where: { clientId_mes: { clientId, mes } },
    create: { clientId, mes, arquivo },
    update: { arquivo, publicadoEm: new Date() },
  });
  return true;
}

/** Gera e publica o mês, se ainda não estiver publicado. */
export async function garantirPublicado(clientId: string, mes: string): Promise<"ja" | "publicado" | "falhou"> {
  const existe = await prisma.relatorioPublicado.findUnique({ where: { clientId_mes: { clientId, mes } } });
  if (existe) return "ja";
  const r = await montarRelatorioDoCliente(clientId, mes);
  if (!r) return "falhou";
  return (await publicarRelatorio(clientId, mes, r.pdf)) ? "publicado" : "falhou";
}

/** Os meses que aparecem na página do cliente, do mais recente ao mais antigo. */
export async function relatoriosDoCliente(clientId: string, criadoEm: Date): Promise<{ mes: string; publicadoEm: Date | null }[]> {
  const publicados = await prisma.relatorioPublicado.findMany({ where: { clientId }, select: { mes: true, publicadoEm: true } });
  const quando = new Map(publicados.map((p) => [p.mes, p.publicadoEm]));
  const meses = new Set([...mesesPublicaveis(chaveDia(criadoEm).slice(0, 7), chaveDia(new Date())), ...quando.keys()]);
  return [...meses].sort().reverse().map((mes) => ({ mes, publicadoEm: quando.get(mes) ?? null }));
}

/** O PDF do mês, gerando e guardando no primeiro acesso. Null se o mês não é publicável. */
export async function relatorioPublicado(
  clientId: string,
  criadoEm: Date,
  mes: string
): Promise<{ pdf: Buffer; nome: string } | null> {
  const nome = `relatorio-${mes}.pdf`;
  const existe = await prisma.relatorioPublicado.findUnique({ where: { clientId_mes: { clientId, mes } } });
  if (existe && serviceRoleConfigurado()) {
    const { data, error } = await createServiceClient().storage.from(BUCKET_FINANCEIRO).download(existe.arquivo);
    if (!error && data) return { pdf: Buffer.from(await data.arrayBuffer()), nome };
  }
  if (!existe && !mesesPublicaveis(chaveDia(criadoEm).slice(0, 7), chaveDia(new Date())).includes(mes)) return null;
  const r = await montarRelatorioDoCliente(clientId, mes);
  if (!r) return null;
  if (!existe) await publicarRelatorio(clientId, mes, r.pdf);
  return { pdf: r.pdf, nome: r.nomeArquivo };
}
