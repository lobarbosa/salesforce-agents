import { NextResponse, type NextRequest } from "next/server";
import { resolverDemanda } from "@/lib/demanda-access";
import { chaveDia, ehChaveDia, formatarDuracao, MINUTOS_MAX_DIA } from "@/lib/horas";
import { gravarCelula } from "@/lib/horas-data";

// Célula da grade "Minhas horas": a pessoa diz quanto trabalhou numa demanda
// num dia, e a grade guarda isso numa única linha `origem = "grade"` por
// pessoa+demanda+dia. Cronômetro e lançamento manual do card ficam intactos:
// se o dia já tem 0:45 de cronômetro e a pessoa digita 2:00, a grade grava
// 1:15. Abaixo do que já existe fora da grade a célula não desce — isso se
// corrige no card, onde dá para ver qual lançamento é qual.
//
// `somenteDelivery`: o papel `cliente` não lança hora (mesma regra do card).
export async function PUT(request: NextRequest) {
  const body = await request.json().catch(() => ({}));
  const demandaId = String(body.demandaId ?? "");
  const dia = String(body.dia ?? "");
  const minutos = Math.round(Number(body.minutos));

  if (!demandaId || !ehChaveDia(dia)) {
    return NextResponse.json({ error: "demanda e dia (AAAA-MM-DD) são obrigatórios" }, { status: 400 });
  }
  if (!Number.isFinite(minutos) || minutos < 0 || minutos > MINUTOS_MAX_DIA) {
    return NextResponse.json({ error: "a célula aceita de 0 a 24 horas" }, { status: 400 });
  }
  // Timesheet registra o que foi feito, não o que se planeja fazer.
  if (dia > chaveDia(new Date())) {
    return NextResponse.json({ error: "não dá para lançar hora num dia que ainda não chegou" }, { status: 400 });
  }

  const acesso = await resolverDemanda(demandaId, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const resultado = await gravarCelula({
    demandaId,
    dia,
    minutos,
    autor: usuario.nome.trim() || usuario.email,
    autorEmail: usuario.email,
  });

  if ("conflito" in resultado) {
    return NextResponse.json(
      {
        error:
          `este dia já tem ${formatarDuracao(resultado.conflito ?? 0)} lançadas por cronômetro ou no card da demanda; ` +
          "para ficar abaixo disso, ajuste os lançamentos na própria demanda",
        minimo: resultado.conflito,
      },
      { status: 409 }
    );
  }
  return NextResponse.json(resultado);
}
