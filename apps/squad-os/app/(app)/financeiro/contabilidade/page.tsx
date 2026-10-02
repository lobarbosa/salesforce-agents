import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { prisma } from "@/lib/prisma";
import { conciliacaoDo } from "@/lib/ops";
import { checklist, competenciaPadrao, rotuloMes } from "@/lib/contabilidade";
import { formatarReais } from "@/lib/contas";
import { chaveDia, ehChaveMes } from "@/lib/horas";
import { DocumentosContabeis } from "@/components/DocumentosContabeis";
import { ConciliacaoChart } from "@/components/ConciliacaoChart";

// Documentos da contabilidade por competência + resultado da conciliação que o
// accounting_reconciliation_agent grava em ops.conciliacoes (17:00).

function mesVizinho(mes: string, delta: number) {
  const [a, m] = mes.split("-").map(Number);
  return new Date(Date.UTC(a, m - 1 + delta, 1)).toISOString().slice(0, 7);
}

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

export default async function ContabilidadePage({ searchParams }: { searchParams: Promise<{ mes?: string }> }) {
  await usuarioDaArea("financeiro");
  const atual = chaveDia(new Date()).slice(0, 7);
  const pedido = (await searchParams).mes ?? "";
  const mes = ehChaveMes(pedido) && pedido <= atual ? pedido : competenciaPadrao(atual);

  const [docs, conc] = await Promise.all([
    prisma.documentoContabil.findMany({ where: { competencia: mes }, orderBy: { enviadoEm: "desc" } }),
    conciliacaoDo(mes),
  ]);
  const ativos = docs.filter((d) => !d.removidoEm);
  const itens = checklist(ativos.map((d) => d.tipo));
  const faltam = itens.filter((i) => !i.recebidos).length;
  const novosDepois = conc && ativos.some((d) => d.enviadoEm.toISOString() > conc.em);

  return (
    <>
      <div className="overview-header">
        <h1>Documentos da contabilidade</h1>
        <p>
          Competência {rotuloMes(mes)}. A contabilidade envia aqui os documentos do mês; o agente de conciliação lê às
          17:00 e compara com o Asaas e as contas pagas.
        </p>
      </div>

      <nav className="semana-nav" aria-label="Navegar entre competências">
        <Link className="btn-ghost" href={`/financeiro/contabilidade?mes=${mesVizinho(mes, -1)}`}>
          ← {rotuloMes(mesVizinho(mes, -1))}
        </Link>
        {mes < atual ? (
          <Link className="btn-ghost" href={`/financeiro/contabilidade?mes=${mesVizinho(mes, 1)}`}>
            {rotuloMes(mesVizinho(mes, 1))} →
          </Link>
        ) : (
          <span className="btn-ghost desabilitado" aria-disabled="true">
            Próxima →
          </span>
        )}
      </nav>

      <ul className="checklist-docs" aria-label="Documentos esperados no mês">
        {itens.map((i) => (
          <li key={i.item} className={i.recebidos ? "recebido" : "falta"}>
            <span className="check-marca" aria-hidden="true">
              {i.recebidos ? "✓" : "!"}
            </span>
            <span>
              {i.item}
              <span className="sub">{i.recebidos ? `recebido (${i.recebidos})` : "falta"}</span>
            </span>
          </li>
        ))}
      </ul>


      <DocumentosContabeis
        competencia={mes}
        documentos={docs.map((d) => ({
          id: d.id,
          tipo: d.tipo,
          nome: d.nome,
          tamanho: d.tamanho,
          enviadoPorEmail: d.enviadoPorEmail,
          enviadoEm: d.enviadoEm.toISOString(),
          removidoEm: d.removidoEm?.toISOString() ?? null,
          removidoPorEmail: d.removidoPorEmail,
        }))}
      />

      <section className="painel-conciliacao" aria-labelledby="titulo-conc">
        <h2 id="titulo-conc" className="secao-titulo">
          Conciliação de {rotuloMes(mes)}
        </h2>
        {conc === null ? (
          <p className="overview-empty">
            O resultado aparece aqui quando o banco dos agentes estiver ligado a este Squad OS.
          </p>
        ) : conc === undefined ? (
          <p className="overview-empty">
            {faltam
              ? `Ainda não conciliado. ${faltam === 1 ? "Falta 1 documento" : `Faltam ${faltam} documentos`} da lista acima.`
              : "Ainda não conciliado. O agente roda às 17:00 com os documentos enviados."}
          </p>
        ) : (
          <>
            {conc.resultadoContabil !== null && conc.resultadoGerencial !== null && (
              <ConciliacaoChart contabil={conc.resultadoContabil} gerencial={conc.resultadoGerencial} />
            )}
            <div className="kpis">
              <div className="kpi">
                <span className="kpi-rotulo">Resultado contábil</span>
                <span className="kpi-valor num">
                  {conc.resultadoContabil === null ? "—" : formatarReais(conc.resultadoContabil)}
                </span>
              </div>
              <div className="kpi">
                <span className="kpi-rotulo">Resultado gerencial (DRE dos agentes)</span>
                <span className="kpi-valor num">
                  {conc.resultadoGerencial === null ? "—" : formatarReais(conc.resultadoGerencial)}
                </span>
              </div>
              <div className={`kpi${conc.divergencias.length ? " kpi-alerta" : ""}`}>
                <span className="kpi-rotulo">Divergências</span>
                <span className="kpi-valor num">{conc.divergencias.length}</span>
                <span className="kpi-nota">
                  {conc.diferencaPct === null ? "" : `diferença de ${conc.diferencaPct.toLocaleString("pt-BR", { maximumFractionDigits: 1 })}% no resultado · `}
                  {conc.ok.length} conferências ok
                </span>
              </div>
            </div>
            <p className="save-note">
              Conciliado em {quando(conc.em)}.
              {novosDepois && " Chegaram documentos depois disso — o agente reprocessa às 17:00."}
            </p>
            {conc.divergencias.length > 0 && (
              <>
                <h3 className="subsecao">O que não bateu</h3>
                <ul className="lista-texto">
                  {conc.divergencias.map((d) => (
                    <li key={d}>{d}</li>
                  ))}
                </ul>
                <Link href="/financeiro/divergencias?origem=accounting_reconciliation_agent">
                  Tratar em Divergências →
                </Link>
              </>
            )}
            {conc.ok.length > 0 && (
              <details className="removidos">
                <summary>Conferido ({conc.ok.length})</summary>
                <ul className="lista-texto">
                  {conc.ok.map((d) => (
                    <li key={d}>{d}</li>
                  ))}
                </ul>
              </details>
            )}
          </>
        )}
      </section>
    </>
  );
}
