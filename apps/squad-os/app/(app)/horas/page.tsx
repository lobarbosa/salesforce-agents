import Link from "next/link";
import { notFound } from "next/navigation";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { minhaSemana } from "@/lib/horas-data";
import {
  chaveDia,
  ehChaveDia,
  inicioDaSemana,
  proximaSemana,
  rotuloDia,
  semanaAnterior,
} from "@/lib/horas";
import { Timesheet } from "@/components/Timesheet";

// "Minhas horas": timesheet semanal (padrão Clockify/Tempo) sobre os mesmos
// RegistroTempo que o card da demanda já usa — substitui o Clockify. Cada
// pessoa vê e lança só as próprias horas. A semana vai na URL (?semana=) para
// o link colado no Slack abrir a mesma semana.
export default async function MinhasHorasPage({
  searchParams,
}: {
  searchParams: Promise<{ semana?: string }>;
}) {
  const usuario = await getCurrentUsuario();
  // proxy.ts já barra o papel `cliente` aqui; isto é defesa em profundidade.
  if (!usuario || !canManageClientData(usuario.role)) notFound();

  const hoje = chaveDia(new Date());
  const pedido = (await searchParams).semana ?? "";
  const segunda = inicioDaSemana(ehChaveDia(pedido) ? pedido : hoje);
  const estaSemana = inicioDaSemana(hoje);
  const semana = await minhaSemana(usuario.email, segunda);
  const domingo = semana.dias[6];

  return (
    <>
      <div className="overview-header">
        <h1>Minhas horas</h1>
        <p>
          Semana de {rotuloDia(segunda)} a {rotuloDia(domingo)}. Digite as horas no dia trabalhado — cada
          célula salva sozinha.
        </p>
      </div>

      <nav className="semana-nav" aria-label="Navegar entre semanas">
        <Link className="btn-ghost" href={`/horas?semana=${semanaAnterior(segunda)}`}>
          ← Semana anterior
        </Link>
        {segunda !== estaSemana && (
          <Link className="btn-ghost" href="/horas">
            Esta semana
          </Link>
        )}
        {segunda < estaSemana ? (
          <Link className="btn-ghost" href={`/horas?semana=${proximaSemana(segunda)}`}>
            Próxima semana →
          </Link>
        ) : (
          <span className="btn-ghost desabilitado" aria-disabled="true">
            Próxima semana →
          </span>
        )}
      </nav>

      {semana.rodando && (
        <div className="aviso-sua-vez" role="status">
          {/* Um span só: o aviso é flex, e cada pedaço de texto solto viraria um item quebrado. */}
          <span>
            Cronômetro rodando em{" "}
            <Link
              href={`/clients/${semana.rodando.demanda.clientId}?tab=demandas&demand=${semana.rodando.demanda.id}`}
            >
              {semana.rodando.demanda.code} — {semana.rodando.demanda.titulo}
            </Link>
            . Ele entra na grade quando você parar.
          </span>
        </div>
      )}

      {/* key: trocar de semana remonta a grade em vez de misturar rascunhos entre semanas. */}
      <Timesheet
        key={segunda}
        dias={semana.dias}
        hoje={hoje}
        linhasIniciais={semana.linhas}
        opcoes={semana.opcoes}
      />
    </>
  );
}
