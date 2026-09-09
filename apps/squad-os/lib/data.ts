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

export function getDemandasByClient(clientId: string) {
  return prisma.demanda.findMany({
    where: { clientId },
    orderBy: { criadoEm: "desc" },
  });
}

export function getAllDemandas() {
  return prisma.demanda.findMany({ orderBy: { criadoEm: "desc" } });
}
