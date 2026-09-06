import { prisma } from "@/lib/prisma";

export function getClients() {
  return prisma.client.findMany({ orderBy: { nome: "asc" } });
}

export function getClientById(id: string) {
  return prisma.client.findUnique({ where: { id } });
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
