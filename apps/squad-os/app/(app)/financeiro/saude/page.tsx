import Link from "next/link";
import type { ReactNode } from "react";
import { usuarioDaArea } from "@/lib/area";
import { formatarReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { historicoRelatoriosFinanceiros, ultimoRelatorioFinanceiro } from "@/lib/ops";
import { SAUDE } from "@/lib/saude";
import {
  agruparInsights,
  dataBr,
  formatarCobertura,
  formatarPct,
  ROTULO_INSIGHT,
  rotuloFonte,
  type SaudeFinanceira,
} from "@/lib/relatorio-financeiro";

// Saúde financeira: o relatório diário do cfo_agent (ops.relatorios_financeiros).
// Os números são calculados em código pelo agente; o texto (resumo, insights)
// vem do modelo e o agente descarta o que cita número que não está nos
// indicadores. Aqui só se lê — nada nesta tela escreve.

const INDISPONIVEL = "indisponível";
const reais = (v: number | null | undefined) => (v === null || v === undefined ? "—" : formatarReais(v));
const horas = (v: number | null) => (v === null ? "—" : `${v.toLocaleString("pt-BR", { maximumFractionDigits: 1 })} h`);
const plural = (n: number, um: string, varios: string) => `${n} ${n === 1 ? um : varios}`;

function Selo({ saude }: { saude: SaudeFinanceira | null }) {
  const info = saude ? SAUDE[saude] : null;
  return info ? (
    <span className={`saude ${info.classe}`}>
      <span aria-hidden="true">{info.simbolo}</span> {info.rotulo}
    </span>
  ) : (
    <span className="saude pendente">desconhecida</span>
  );
}

function Cartao({ rotulo, valor, nota, alerta }: { rotulo: string; valor: ReactNode; nota?: ReactNode; alerta?: boolean }) {
  return (
    <div className={`kpi${alerta ? " kpi-alerta" : ""}`}>
      <span className="kpi-rotulo">{rotulo}</span>
      <span className="kpi-valor num">{valor}</span>
      {nota ? <span className="kpi-nota">{nota}</span> : null}
    </div>
  );
}

export default async function SaudeFinanceiraPage() {
  await usuarioDaArea("financeiro");
  const [rel, historico] = await Promise.all([ultimoRelatorioFinanceiro(), historicoRelatoriosFinanceiros(30)]);
  const hoje = chaveDia(new Date());

  const cabecalho = (
    <div className="overview-header">
      <h1>Saúde financeira</h1>
      <p>
        Relatório diário do agente CFO: receitas (Asaas), despesas (contas a pagar), projeção de caixa, comercial
        (Salesforce) e horas por contrato. Números calculados pelo agente; o texto é gerado a partir deles.
      </p>
    </div>
  );

  if (rel === null)
    return (
      <>
        {cabecalho}
        <div className="overview-empty">
          O relatório de saúde financeira aparece aqui quando o banco dos agentes estiver ligado a este Squad OS e a
          tabela <span className="mono">ops.relatorios_financeiros</span> existir.
        </div>
      </>
    );
  if (rel === undefined)
    return (
      <>
        {cabecalho}
        <div className="overview-empty">O agente CFO ainda não gravou nenhum relatório de saúde financeira.</div>
      </>
    );

  const { receitas: rec, despesas: desp, caixa, comercial, operacao, contabil } = rel.indicadores;
  const statusFonte = (f: string) => rel.fontes.find((x) => x.fonte === f)?.status;
  const motivoIndisp = (f: string) => {
    const s = statusFonte(f);
    return s && s !== "ok" ? `${rotuloFonte(f)}: ${s}` : `sem dados de ${rotuloFonte(f)} neste relatório`;
  };
  const temProjecao = !!caixa && (caixa.caixa30d !== null || caixa.caixa60d !== null || caixa.caixa90d !== null);
  const grupos = agruparInsights(rel.insights);
  const atrasado = rel.referencia < hoje;

  return (
    <>
      {cabecalho}

      <div className="overview-section">
        <div className="sf-topo">
          <Selo saude={rel.saude} />
          <span className="sf-data">
            Relatório de {dataBr(rel.referencia)}
            {atrasado ? " · não há relatório de hoje ainda" : ""}
          </span>
        </div>
        {rel.motivos.length > 0 && (
          <ul className="lista-texto" aria-label="Por que esta saúde">
            {rel.motivos.map((m) => (
              <li key={m}>{m}</li>
            ))}
          </ul>
        )}
        {rel.resumo && <p className="assessment-resumo">{rel.resumo}</p>}
      </div>

      <div className="overview-section">
        <h2>Receitas e despesas</h2>
        <div className="kpis">
          {rec ? (
            <>
              <Cartao
                rotulo="MRR"
                valor={reais(rec.mrr)}
                nota={[
                  rec.arr !== null ? `ARR ${reais(rec.arr)}` : null,
                  rec.assinaturasAtivas !== null ? plural(rec.assinaturasAtivas, "assinatura ativa", "assinaturas ativas") : null,
                ]
                  .filter(Boolean)
                  .join(" · ")}
              />
              <Cartao
                rotulo="Recebido no mês"
                valor={reais(rec.recebidoMesAtual)}
                nota={rec.recebidoMesAnterior !== null ? `mês anterior: ${reais(rec.recebidoMesAnterior)}` : undefined}
              />
              <Cartao
                rotulo="Inadimplência"
                valor={reais(rec.inadimplenciaTotal)}
                alerta={(rec.inadimplenciaTotal ?? 0) > 0}
                nota={
                  rec.inadimplenciaQtd
                    ? [
                        plural(rec.inadimplenciaQtd, "cobrança vencida", "cobranças vencidas"),
                        rec.inadimplenciaDiasMaisAntiga !== null ? `mais antiga há ${rec.inadimplenciaDiasMaisAntiga} dias` : null,
                        rec.inadimplenciaPctMrr !== null ? `${formatarPct(rec.inadimplenciaPctMrr)} do MRR` : null,
                      ]
                        .filter(Boolean)
                        .join(" · ")
                    : "nenhuma cobrança vencida"
                }
              />
            </>
          ) : (
            <Cartao rotulo="Receitas" valor={INDISPONIVEL} nota={motivoIndisp("asaas")} />
          )}
          {desp ? (
            <>
              <Cartao
                rotulo="Despesas pagas no mês"
                valor={reais(desp.pagasMesAtual)}
                nota={[
                  desp.pagasMesAnterior !== null ? `mês anterior: ${reais(desp.pagasMesAnterior)}` : null,
                  desp.mediaMensalPagas3m !== null ? `média 3 meses: ${reais(desp.mediaMensalPagas3m)}` : null,
                ]
                  .filter(Boolean)
                  .join(" · ")}
              />
              <Cartao
                rotulo="Contas em aberto"
                valor={reais(desp.emAbertoTotal)}
                alerta={(desp.vencidasNaoPagasQtd ?? 0) > 0}
                nota={[
                  desp.emAbertoQtd !== null ? plural(desp.emAbertoQtd, "conta", "contas") : null,
                  desp.vencidasNaoPagasQtd
                    ? `${plural(desp.vencidasNaoPagasQtd, "vencida", "vencidas")} sem pagamento (${reais(desp.vencidasNaoPagasTotal)})`
                    : null,
                  desp.aguardandoAprovacaoQtd
                    ? `${desp.aguardandoAprovacaoQtd} aguardando aprovação (${reais(desp.aguardandoAprovacaoTotal)})`
                    : null,
                  desp.aVencer30dTotal !== null ? `a vencer em 30 dias: ${reais(desp.aVencer30dTotal)}` : null,
                ]
                  .filter(Boolean)
                  .join(" · ")}
              />
            </>
          ) : (
            <Cartao rotulo="Despesas" valor={INDISPONIVEL} nota={motivoIndisp("squad_os")} />
          )}
          <Cartao
            rotulo="Cobertura MRR ÷ despesa mensal"
            valor={rel.indicadores.coberturaMrrDespesa === null ? INDISPONIVEL : formatarCobertura(rel.indicadores.coberturaMrrDespesa)}
            alerta={rel.indicadores.coberturaMrrDespesa !== null && rel.indicadores.coberturaMrrDespesa < 1}
            nota="MRR sobre a média mensal de despesas pagas (3 meses); abaixo de 1,00x a receita recorrente não cobre o custo"
          />
          {rel.indicadores.resultadoCaixaMesAnterior !== null && (
            <Cartao
              rotulo="Resultado de caixa do mês anterior"
              valor={reais(rel.indicadores.resultadoCaixaMesAnterior)}
              alerta={rel.indicadores.resultadoCaixaMesAnterior < 0}
              nota="recebido − pago no mês anterior"
            />
          )}
        </div>
      </div>

      <div className="overview-section">
        <h2>Projeção de caixa</h2>
        {temProjecao && caixa ? (
          <>
            <p className="sf-aviso">
              Sem saldo inicial: cada valor é entradas − saídas previstas até a data, sem o saldo bancário de abertura.
              Negativo quer dizer que sai mais do que entra no período, não que a conta fica no vermelho.
            </p>
            <div className="kpis">
              {(
                [
                  [30, caixa.caixa30d],
                  [60, caixa.caixa60d],
                  [90, caixa.caixa90d],
                ] as const
              ).map(([d, v]) => (
                <Cartao
                  key={d}
                  rotulo={`Entradas − saídas em ${d} dias`}
                  valor={v === null ? INDISPONIVEL : formatarReais(v)}
                  alerta={v !== null && v < 0}
                  nota={caixa.referencia ? `ref. ${dataBr(caixa.referencia)} · sem saldo inicial` : "sem saldo inicial"}
                />
              ))}
              {caixa.pipelinePonderado90d !== null && (
                <Cartao rotulo="Pipeline ponderado (90 dias)" valor={formatarReais(caixa.pipelinePonderado90d)} nota="não entra na projeção" />
              )}
            </div>
          </>
        ) : (
          <div className="overview-empty">Projeção {INDISPONIVEL}: o cashflow_monitor ainda não gravou a projeção usada neste relatório.</div>
        )}
      </div>

      <div className="overview-section">
        <h2>Comercial</h2>
        {comercial ? (
          <div className="kpis">
            <Cartao
              rotulo="Bookings no mês"
              valor={reais(comercial.bookingsMes)}
              nota={comercial.bookingsQtd !== null ? plural(comercial.bookingsQtd, "oportunidade ganha", "oportunidades ganhas") : undefined}
            />
            <Cartao
              rotulo="Pipeline aberto"
              valor={reais(comercial.pipelineAberto)}
              alerta={(comercial.oppsAtrasadas ?? 0) > 0}
              nota={[
                comercial.pipelineQtd !== null ? plural(comercial.pipelineQtd, "oportunidade", "oportunidades") : null,
                comercial.oppsAtrasadas ? `${comercial.oppsAtrasadas} com fechamento atrasado` : null,
              ]
                .filter(Boolean)
                .join(" · ")}
            />
          </div>
        ) : (
          <div className="overview-empty">Comercial {INDISPONIVEL} — {motivoIndisp("salesforce")}.</div>
        )}
      </div>

      {grupos.length > 0 && (
        <div className="overview-section">
          <h2>Análise</h2>
          {grupos.map((g) => (
            <div key={g.tipo} className="sf-insights">
              <h3 className="secao-titulo">
                <span aria-hidden="true">{ROTULO_INSIGHT[g.tipo].simbolo}</span> {ROTULO_INSIGHT[g.tipo].rotulo}
              </h3>
              <ul className="lista-texto">
                {g.itens.map((i, n) => (
                  <li key={`${g.tipo}-${n}`}>
                    {i.titulo && <strong>{i.titulo}</strong>}
                    {i.titulo && i.texto ? " — " : ""}
                    {i.texto}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      )}

      <div className="overview-section">
        <h2>Qualidade dos dados</h2>
        {rel.alertas.length === 0 ? (
          <div className="overview-empty ok">As validações de consistência do agente passaram.</div>
        ) : (
          <ul className="lista-texto" aria-label="Alertas de consistência">
            {rel.alertas.map((a) => (
              <li key={a}>{a}</li>
            ))}
          </ul>
        )}
        {rel.fontes.length > 0 && (
          <ul className="sf-fontes" aria-label="Situação das fontes">
            {rel.fontes.map((f) => (
              <li key={f.fonte}>
                <span className={`badge-status ${f.ok ? "st-paga" : "st-recusada"}`}>{f.ok ? "ok" : "falhou"}</span>{" "}
                <strong>{rotuloFonte(f.fonte)}</strong>
                {f.ok ? "" : ` — ${f.status}`}
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="overview-section">
        <h2>Horas por contrato</h2>
        {!operacao ? (
          <div className="overview-empty">Horas {INDISPONIVEL} — {motivoIndisp("squad_os")}.</div>
        ) : operacao.contratos.length === 0 ? (
          <div className="overview-empty">Nenhum contrato no relatório.</div>
        ) : (
          <>
            <div className="tabela-wrap">
              <table className="tabela">
                <caption className="sr-only">Horas lançadas no mês por contrato</caption>
                <thead>
                  <tr>
                    <th scope="col">Cliente</th>
                    <th scope="col">Contrato</th>
                    <th scope="col" className="num">Contratadas</th>
                    <th scope="col" className="num">Lançadas no mês</th>
                    <th scope="col" className="num">Uso</th>
                  </tr>
                </thead>
                <tbody>
                  {operacao.contratos.map((c) => (
                    <tr key={c.cliente + c.tipo}>
                      <th scope="row">{c.cliente}</th>
                      <td>
                        {c.tipo || "—"}
                        {c.ciclo ? ` · ${c.ciclo}` : ""}
                      </td>
                      <td className="num">{c.horasContratadas ? horas(c.horasContratadas) : "não definidas"}</td>
                      <td className="num">{horas(c.horasMes)}</td>
                      <td className="num">
                        {c.usoPct === null ? "—" : c.usoPct >= 100 ? <strong>{formatarPct(c.usoPct)}</strong> : formatarPct(c.usoPct)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="sf-aviso">
              {operacao.horasLancadasMes !== null ? `${horas(operacao.horasLancadasMes)} lançadas no mês. ` : ""}
              {operacao.contratosSemHorasDefinidas.length > 0 &&
                `Sem horas contratadas definidas: ${operacao.contratosSemHorasDefinidas.join(", ")}. `}
              Detalhe por ciclo em <Link href="/financeiro/horas">Horas por cliente</Link>.
            </p>
          </>
        )}
      </div>

      <div className="overview-section">
        <h2>Despesas por categoria (90 dias)</h2>
        {!desp ? (
          <div className="overview-empty">Despesas {INDISPONIVEL} — {motivoIndisp("squad_os")}.</div>
        ) : desp.porCategoria90d.length === 0 ? (
          <div className="overview-empty">Nenhuma despesa paga nos últimos 90 dias.</div>
        ) : (
          <>
            <div className="tabela-wrap">
              <table className="tabela">
                <caption className="sr-only">Despesas pagas por categoria nos últimos 90 dias</caption>
                <thead>
                  <tr>
                    <th scope="col">Categoria</th>
                    <th scope="col" className="num">Pago</th>
                    <th scope="col" className="num">Participação</th>
                  </tr>
                </thead>
                <tbody>
                  {desp.porCategoria90d.map((c) => {
                    const total = desp.pagas90d ?? desp.porCategoria90d.reduce((s, x) => s + x.valor, 0);
                    return (
                      <tr key={c.categoria}>
                        <th scope="row">{c.categoria}</th>
                        <td className="num">{formatarReais(c.valor)}</td>
                        <td className="num">{total > 0 ? formatarPct((c.valor / total) * 100) : "—"}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <p className="sf-aviso">
              {desp.pagas90d !== null ? `Total pago em 90 dias: ${formatarReais(desp.pagas90d)}. ` : ""}
              {desp.maiorFornecedor90d &&
                `Maior fornecedor: ${desp.maiorFornecedor90d.nome} (${reais(desp.maiorFornecedor90d.valor)}${
                  desp.maiorFornecedor90d.pct !== null ? `, ${formatarPct(desp.maiorFornecedor90d.pct)}` : ""
                }). `}
              {rec?.maiorCliente90d &&
                `Maior cliente na receita: ${rec.maiorCliente90d.nome} (${reais(rec.maiorCliente90d.valor)}${
                  rec.maiorCliente90d.pct !== null ? `, ${formatarPct(rec.maiorCliente90d.pct)}` : ""
                }).`}
            </p>
          </>
        )}
      </div>

      {contabil && (
        <div className="overview-section">
          <h2>Contabilidade</h2>
          <p className="sf-aviso">
            {contabil.ultimaConciliacao
              ? `Última conciliação: ${contabil.ultimaConciliacao.competencia.slice(5, 7)}/${contabil.ultimaConciliacao.competencia.slice(0, 4)}${
                  contabil.ultimaConciliacao.diferencaPct !== null
                    ? ` (diferença de ${formatarPct(contabil.ultimaConciliacao.diferencaPct)} no resultado)`
                    : ""
                }. `
              : "Nenhuma competência conciliada ainda. "}
            {contabil.divergenciasAbertas ? (
              <Link href="/financeiro/divergencias">{plural(contabil.divergenciasAbertas, "divergência aberta", "divergências abertas")}</Link>
            ) : (
              "Sem divergências abertas."
            )}
          </p>
        </div>
      )}

      {historico && historico.length > 0 && (
        <div className="overview-section">
          <h2>Histórico (últimos {historico.length} relatórios)</h2>
          <div className="tabela-wrap">
            <table className="tabela">
              <caption className="sr-only">Saúde financeira dos últimos relatórios</caption>
              <thead>
                <tr>
                  <th scope="col">Dia</th>
                  <th scope="col">Saúde</th>
                  <th scope="col">Principal motivo</th>
                  <th scope="col" className="num">MRR</th>
                  <th scope="col" className="num">Inadimplência</th>
                </tr>
              </thead>
              <tbody>
                {historico.map((h) => (
                  <tr key={h.referencia}>
                    <td className="data">{dataBr(h.referencia)}</td>
                    <td>
                      <Selo saude={h.saude} />
                    </td>
                    <td>{h.primeiroMotivo ?? "—"}</td>
                    <td className="num">{reais(h.mrr)}</td>
                    <td className="num">{reais(h.inadimplenciaTotal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <p className="sf-aviso">
        Gerado em {rel.atualizadoEm ? new Date(rel.atualizadoEm).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" }) : "—"}.
      </p>
    </>
  );
}
