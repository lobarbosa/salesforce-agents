import { prisma } from "@/lib/prisma";
import { travar } from "@/lib/trava";
import { runsAtivosDoCliente, triggerRunDemand } from "@/lib/github";

// Fila de disparo por cliente — ver o comentário de DisparoEsteira no schema.
// Regra única: no máximo UM disparo em voo por cliente, e só se o Actions não
// tem nada rodando/na fila desse cliente. Assim o concurrency group nunca tem
// dois pendentes e nunca cancela ninguém.

/** Em voo sem sync de volta há mais que isso e sem run ativo: o run morreu (cancelado/nunca rodou). */
const EM_VOO_MAX_MS = 10 * 60 * 1000;

export async function enfileirar(d: {
  clientId: string;
  demandaId: string;
  tipo: "rodar" | "aprovar";
  gate?: string;
  autor?: string;
}) {
  return prisma.disparoEsteira.create({
    data: { clientId: d.clientId, demandaId: d.demandaId, tipo: d.tipo, gate: d.gate ?? "", autor: d.autor ?? "" },
  });
}

/** A execução desta demanda sincronizou: o que estava em voo pra ela terminou. */
export async function concluirEmVoo(demandaId: string) {
  await prisma.disparoEsteira.updateMany({
    where: { demandaId, disparadoEm: { not: null }, concluidoEm: null },
    data: { concluidoEm: new Date() },
  });
}

/**
 * Manda o próximo da fila deste cliente, se ele estiver livre. Idempotente e
 * seguro de chamar de qualquer lugar. `excetoRunUrl`: a execução que está
 * chamando (o sync de fim de run roda DENTRO dela, que ainda aparece ativa).
 */
export async function processarFila(clientId: string, opcoes: { excetoRunUrl?: string } = {}) {
  const client = await prisma.client.findUnique({ where: { id: clientId }, select: { slug: true } });
  if (!client) return;

  await prisma.$transaction(
    async (tx) => {
      await travar(tx, `fila-esteira:${clientId}`);

      const emVoo = await tx.disparoEsteira.findFirst({
        where: { clientId, disparadoEm: { not: null }, concluidoEm: null },
        include: { demanda: { select: { ultimaExecucaoEm: true } } },
      });
      const ativos = (await runsAtivosDoCliente(client.slug)).filter((u) => u !== opcoes.excetoRunUrl);

      if (emVoo) {
        if (ativos.length > 0) return;
        const idade = Date.now() - emVoo.disparadoEm!.getTime();
        if (idade < EM_VOO_MAX_MS) return; // pode ainda estar aparecendo no Actions
        const sincronizou = emVoo.demanda.ultimaExecucaoEm && emVoo.demanda.ultimaExecucaoEm > emVoo.disparadoEm!;
        await tx.disparoEsteira.update({
          where: { id: emVoo.id },
          data: sincronizou
            ? { concluidoEm: new Date() }
            : { disparadoEm: null, nota: "a execução não rodou (cancelada no Actions) — voltou para a fila" },
        });
      } else if (ativos.length > 0) {
        return; // algo de fora da fila (varredura, disparo manual) está rodando
      }

      const pendentes = await tx.disparoEsteira.findMany({
        where: { clientId, disparadoEm: null, concluidoEm: null },
        orderBy: { criadoEm: "asc" },
        include: { demanda: { select: { code: true, status: true } } },
      });
      for (const p of pendentes) {
        if (p.tipo === "aprovar" && p.demanda.status !== p.gate) {
          await tx.disparoEsteira.update({
            where: { id: p.id },
            data: { concluidoEm: new Date(), nota: `sem efeito: a demanda saiu de ${p.gate} antes de rodar` },
          });
          continue;
        }
        if (p.demanda.status === "standby" || p.demanda.status === "cancelada") {
          await tx.disparoEsteira.update({
            where: { id: p.id },
            data: { concluidoEm: new Date(), nota: `sem efeito: demanda ${p.demanda.status}` },
          });
          continue;
        }
        try {
          await triggerRunDemand(
            client.slug,
            p.demanda.code,
            p.tipo === "aprovar" ? { aprovarGate: p.autor, gateEsperado: p.gate } : {}
          );
        } catch (err) {
          await tx.disparoEsteira.update({
            where: { id: p.id },
            data: { nota: `falha ao disparar: ${(err as Error).message}`.slice(0, 300) },
          });
          return; // tenta de novo no próximo gatilho
        }
        await tx.disparoEsteira.update({ where: { id: p.id }, data: { disparadoEm: new Date(), nota: "" } });
        return;
      }
    },
    { timeout: 30000, maxWait: 10000 }
  );
}

/** Varredura (todos os clientes com algo aberto na fila). */
export async function processarTodas() {
  const clientes = await prisma.disparoEsteira.findMany({
    where: { concluidoEm: null },
    distinct: ["clientId"],
    select: { clientId: true },
  });
  const erros: string[] = [];
  for (const { clientId } of clientes) {
    await processarFila(clientId).catch((e) => erros.push(`${clientId}: ${(e as Error).message}`));
  }
  return { clientes: clientes.length, erros };
}
