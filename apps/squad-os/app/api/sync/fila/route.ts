import { NextResponse, type NextRequest } from "next/server";
import { autorizarSync } from "@/lib/sync-auth";
import { processarTodas } from "@/lib/fila-esteira";

// Varredura da fila de disparo (lib/fila-esteira.ts), chamada de hora em hora
// por varrer-demandas.yml. Cobre o que os gatilhos normais não cobrem: o
// GitHub cancelou uma execução antes de ela rodar (sem sync de volta), ou o
// disparo falhou na hora. Token global: atravessa todos os clientes, mas não
// devolve dado nenhum de cliente — só contagens.
export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;
  const r = await processarTodas();
  return NextResponse.json(r);
}
