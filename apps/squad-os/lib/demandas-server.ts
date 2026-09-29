import { prisma } from "@/lib/prisma";
import { generateDemandCode } from "@/lib/slug";
import { canAccessClient } from "@/lib/auth";
import type { CurrentUsuario } from "@/lib/current-user";

/**
 * Único caminho de criação de demanda no Squad OS — a API (`POST /api/demandas`,
 * botão "+ nova demanda") e o copiloto de chat chamam esta mesma função, nunca
 * reimplementam a validação. Autor sempre sai de `usuario`, nunca de texto
 * livre: impede tanto a API quanto o copiloto de registrar em nome de outra
 * pessoa. Sempre nasce em `backlog` — não existe parâmetro pra pular isso.
 */
export async function criarDemanda({
  usuario,
  clientId,
  titulo,
  texto,
  tipo,
}: {
  usuario: CurrentUsuario;
  clientId: string;
  titulo: string;
  texto?: string;
  tipo?: string;
}) {
  const tituloLimpo = titulo.trim();
  if (!clientId || !tituloLimpo) {
    return { ok: false as const, status: 400, error: "clientId e titulo são obrigatórios" };
  }
  if (!canAccessClient(usuario.role, usuario.clientId, clientId)) {
    return { ok: false as const, status: 403, error: "sem permissão" };
  }

  const client = await prisma.client.findUnique({ where: { id: clientId } });
  if (!client) {
    return { ok: false as const, status: 404, error: "cliente não encontrado" };
  }

  const autor = usuario.nome.trim() || usuario.email;
  const tipoFinal = tipo === "projeto" ? "projeto" : "sustentacao";
  const code = await generateDemandCode(clientId, client.slug);

  const demanda = await prisma.demanda.create({
    data: {
      clientId,
      code,
      titulo: tituloLimpo,
      tipo: tipoFinal,
      texto: (texto ?? "").trim(),
      autor,
      status: "backlog",
      historico: [{ de: null, para: "backlog", autor, em: new Date().toISOString() }],
    },
  });

  return { ok: true as const, demanda };
}
