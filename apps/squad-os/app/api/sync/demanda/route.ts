import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { StatusDemanda } from "@/lib/generated/prisma/client";

// Fecha o laço na direção git → app. `status.yaml` no repositório é a fonte de
// verdade do estágio (guardrail #5 do CLAUDE.md raiz); o Postgres é espelho, e
// até agora esse espelho congelava no momento da materialização — o gate que
// estava esperando alguém ficava invisível justamente pra quem precisava vê-lo.
//
// Chamado por run-demand.yml no fim de cada execução, com `if: always()`:
// saber que a etapa falhou importa tanto quanto saber que passou.

const STATUS_VALIDOS = new Set<string>(Object.values(StatusDemanda));

// O lado Python já corta em 60k (revisao.LIMITE_CONTEUDO). Cortar de novo aqui
// não é desconfiança do nosso próprio CLI — é que esta rota aceita um corpo de
// fora do processo, e o tamanho da linha no banco não pode depender de quem
// chama estar bem-comportado.
const CONTEUDO_MAX = 80_000;

// A assinatura de índice é o que o Prisma exige pra aceitar isto como JSON de
// entrada, e é honesta: todo campo aqui é string. `resposta` sai sempre
// preenchida (vazia quando ninguém respondeu ainda) pelo mesmo motivo —
// `undefined` não sobrevive a uma ida ao banco.
interface PerguntaSync {
  id: string;
  texto: string;
  resposta: string;
  [campo: string]: string;
}

/** As pendências novas, mantendo o que já foi respondido.
 *
 * O `id` vem do hash do texto da pendência (revisao.py), então um re-run da
 * mesma etapa reencontra a resposta em vez de zerá-la — e quem já respondeu
 * não é obrigado a responder de novo porque o job rodou duas vezes.
 */
function comRespostasPreservadas(novas: unknown, atuais: unknown): PerguntaSync[] {
  if (!Array.isArray(novas)) return [];
  const respondidas = new Map(
    (Array.isArray(atuais) ? (atuais as PerguntaSync[]) : [])
      .filter((p) => p && typeof p.id === "string")
      .map((p) => [p.id, typeof p.resposta === "string" ? p.resposta : ""])
  );
  return novas
    .filter((p): p is Record<string, unknown> => !!p && typeof p === "object")
    .map((p) => {
      const id = String(p.id ?? "").slice(0, 64);
      return {
        id,
        texto: String(p.texto ?? "").slice(0, 1000),
        resposta: respondidas.get(id) ?? "",
      };
    })
    .filter((p) => p.id && p.texto);
}

export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  // O payload é o próprio status.yaml em JSON (`sfagents demanda status-json`)
  // mais dois campos que só o Actions sabe.
  const clientSlug = String(body.client ?? "");
  const code = String(body.id ?? "");
  const status = String(body.status ?? "");

  if (!clientSlug || !code) {
    return NextResponse.json({ error: "client e id são obrigatórios" }, { status: 400 });
  }
  if (!STATUS_VALIDOS.has(status)) {
    // Um status que o app não conhece significa que demands.py e o enum do
    // Prisma saíram de sincronia. Recusar é melhor que gravar lixo: o git
    // continua correto e o erro aparece no log do workflow.
    return NextResponse.json(
      { error: `status desconhecido: ${status}` },
      { status: 400 }
    );
  }

  const client = await prisma.client.findUnique({
    where: { slug: clientSlug },
    select: { id: true },
  });
  if (!client) {
    return NextResponse.json({ error: `cliente '${clientSlug}' não encontrado` }, { status: 404 });
  }

  const demanda = await prisma.demanda.findUnique({
    where: { clientId_code: { clientId: client.id, code } },
    select: { id: true, perguntas: true },
  });
  if (!demanda) {
    // Acontece quando a demanda nasceu pela CLI (`sfagents demanda nova`) e
    // não pelo Squad OS. Não é erro do chamador — só não há espelho a
    // atualizar. 202 pra o workflow não ficar amarelo por isso.
    return NextResponse.json(
      { aviso: `demanda '${code}' não existe no Squad OS — nada a espelhar` },
      { status: 202 }
    );
  }

  // Em gate, o payload traz o artefato que está sendo julgado e as pendências
  // que o agente deixou em aberto (ver revisao.py). Fora de gate não vem nada,
  // e aí as perguntas ficam como estão: apagá-las descartaria resposta que
  // alguém já digitou, e nada lê pergunta fora de gate mesmo.
  const artefato =
    body.artefato && typeof body.artefato === "object"
      ? (body.artefato as Record<string, unknown>)
      : null;

  const dadosDoArtefato = artefato
    ? {
        artefatoNome: String(artefato.nome ?? "").slice(0, 120),
        artefatoConteudo: String(artefato.conteudo ?? "").slice(0, CONTEUDO_MAX),
        artefatoTruncado: artefato.truncado === true,
        perguntas: comRespostasPreservadas(artefato.perguntas, demanda.perguntas),
      }
    : {};

  const atualizada = await prisma.demanda.update({
    where: { id: demanda.id },
    data: {
      status: status as StatusDemanda,
      // O histórico vem do status.yaml inteiro, não incrementado aqui: o git é
      // a fonte, e reconstruir a lista do zero evita divergência silenciosa.
      historico: Array.isArray(body.historico) ? body.historico : [],
      ultimaExecucaoEm: new Date(),
      ultimoResultado: String(body.resultado ?? "").slice(0, 40),
      ultimoRunUrl: String(body.run_url ?? "").slice(0, 500),
      ...dadosDoArtefato,
    },
  });

  return NextResponse.json({ id: atualizada.id, status: atualizada.status });
}
