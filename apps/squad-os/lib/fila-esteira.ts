import { prisma } from "@/lib/prisma";
import { travar } from "@/lib/trava";
import { runsAtivosDoCliente, triggerRunDemand } from "@/lib/github";
import { ambienteDoDisparo, decidirDisparo, ordemDaFila, type TipoDisparo } from "@/lib/fila-decisao";

// Fila de disparo por cliente e ambiente — ver o comentário de DisparoEsteira
// no schema. Regra: no máximo UM disparo em voo por cliente POR SANDBOX (dev e
// qa andam em paralelo, guardrail #6 é por sandbox), e só se o Actions não tem
// run desse cliente que a fila não conheça. O concurrency group do workflow é
// por cliente e ambiente, então nunca há dois pendentes no mesmo grupo.

/** Em voo sem sync de volta há mais que isso e sem run ativo: o run morreu (cancelado/nunca rodou). */
const EM_VOO_MAX_MS = 10 * 60 * 1000;

export async function enfileirar(d: {
  clientId: string;
  demandaId: string;
  tipo: TipoDisparo;
  gate?: string;
  autor?: string;
  liberarEm?: Date;
}) {
  return prisma.disparoEsteira.create({
    data: {
      clientId: d.clientId,
      demandaId: d.demandaId,
      tipo: d.tipo,
      gate: d.gate ?? "",
      autor: d.autor ?? "",
      liberarEm: d.liberarEm ?? null,
    },
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

      const emVoo = await tx.disparoEsteira.findMany({
        where: { clientId, disparadoEm: { not: null }, concluidoEm: null },
        include: { demanda: { select: { ultimaExecucaoEm: true } } },
      });
      const ativos = (await runsAtivosDoCliente(client.slug)).filter((u) => u !== opcoes.excetoRunUrl);

      // Run do cliente que a fila não disparou (varredura, disparo manual): não
      // dá para saber a sandbox dele, então nada sai até ele acabar.
      if (ativos.length > emVoo.length) return;

      // Em voo sem run nenhum no Actions há mais que o prazo: o run morreu.
      const vivos = [];
      for (const v of emVoo) {
        const idade = Date.now() - v.disparadoEm!.getTime();
        if (ativos.length === 0 && idade >= EM_VOO_MAX_MS) {
          const sincronizou = v.demanda.ultimaExecucaoEm && v.demanda.ultimaExecucaoEm > v.disparadoEm!;
          await tx.disparoEsteira.update({
            where: { id: v.id },
            data: sincronizou
              ? { concluidoEm: new Date() }
              : { disparadoEm: null, nota: "a execução não rodou (cancelada no Actions) — voltou para a fila" },
          });
        } else {
          vivos.push(v);
        }
      }
      // Disparo antigo, sem ambiente gravado: ocupa as duas sandboxes.
      const ocupados = new Set<string>(vivos.flatMap((v) => (v.ambiente ? [v.ambiente] : ["dev", "qa"])));
      if (ocupados.has("dev") && ocupados.has("qa")) return;

      const pendentes = await tx.disparoEsteira.findMany({
        where: {
          clientId,
          disparadoEm: null,
          concluidoEm: null,
          OR: [{ liberarEm: null }, { liberarEm: { lte: new Date() } }],
        },
        orderBy: { criadoEm: "asc" },
        include: {
          demanda: {
            select: {
              code: true, status: true, tipo: true, estimativaConsultorHoras: true, estimativaAprovadaHoras: true,
              client: { select: { contrato: { select: { tipo: true } } } },
            },
          },
        },
      });
      pendentes.sort(ordemDaFila);
      // Outra demanda do cliente em teste na sandbox de QA segura quem iria para lá.
      const emQa = await tx.demanda.findMany({ where: { clientId, status: "qa" }, select: { id: true, code: true } });
      for (const p of pendentes) {
        const ambiente = ambienteDoDisparo(p.tipo, p.gate, p.demanda.status);
        if (ocupados.has(ambiente)) continue;
        const outraEmQa = emQa.find((d) => d.id !== p.demandaId)?.code ?? null;
        const decisao = decidirDisparo(p, outraEmQa);
        if (decisao.acao === "descartar") {
          await tx.disparoEsteira.update({ where: { id: p.id }, data: { concluidoEm: new Date(), nota: decisao.nota } });
          continue;
        }
        if (decisao.acao === "esperar") {
          if (p.nota !== decisao.nota) {
            await tx.disparoEsteira.update({ where: { id: p.id }, data: { nota: decisao.nota } });
          }
          continue;
        }
        try {
          await triggerRunDemand(client.slug, p.demanda.code, decisao.opcoes);
        } catch (err) {
          await tx.disparoEsteira.update({
            where: { id: p.id },
            data: { nota: `falha ao disparar: ${(err as Error).message}`.slice(0, 300) },
          });
          return; // tenta de novo no próximo gatilho
        }
        await tx.disparoEsteira.update({ where: { id: p.id }, data: { disparadoEm: new Date(), nota: "", ambiente } });
        ocupados.add(ambiente);
        if (ocupados.has("dev") && ocupados.has("qa")) return;
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
