import { prisma } from "@/lib/prisma";

// `ambientes` vem junto em ambas: a Visão Geral precisa dele pra listar
// conexão pendente, e a aba Conexões renderiza um card por ambiente.
export function getClients() {
  return prisma.client.findMany({
    orderBy: { nome: "asc" },
    include: { ambientes: true },
  });
}

export function getClientById(id: string) {
  return prisma.client.findUnique({ where: { id }, include: { ambientes: true } });
}

// Só aqui o conteúdo do card vem junto: é a tela que abre o modal da demanda.
// getAllDemandas() alimenta a Visão Geral, que mostra só o resumo — carregar
// conversa, subtarefas e anexos de todas as demandas lá seria puxar o card
// inteiro de cada uma sem ninguém abrir nenhum.
export function getDemandasByClient(clientId: string) {
  return prisma.demanda.findMany({
    where: { clientId },
    orderBy: { criadoEm: "desc" },
    include: {
      comentarios: { orderBy: { criadoEm: "asc" } },
      subtarefas: { orderBy: { ordem: "asc" } },
      checklist: { orderBy: { ordem: "asc" } },
      tempos: { orderBy: { inicioEm: "desc" } },
      anexos: { orderBy: { criadoEm: "desc" } },
    },
  });
}

export function getAllDemandas() {
  return prisma.demanda.findMany({ orderBy: { criadoEm: "desc" } });
}

// O tipo que o modal (e tudo que passa a demanda pra ele) espera — definido
// a partir da query, e não à mão, pra que mudar o `include` acima quebre a
// compilação em vez de silenciosamente deixar um campo faltando na UI.
export type DemandaCompleta = Awaited<ReturnType<typeof getDemandasByClient>>[number];
