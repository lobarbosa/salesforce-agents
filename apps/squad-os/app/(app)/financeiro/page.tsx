import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { listarContas } from "@/lib/contas-data";
import { bloqueio, formatarReais } from "@/lib/contas";
import { contarDivergenciasAbertas, kpisAtuais, type Kpi } from "@/lib/ops";
import { defKpi, tendencia } from "@/lib/kpis";
import { rotuloOrigem } from "@/lib/divergencias";
import { checklist, competenciaPadrao, rotuloMes } from "@/lib/contabilidade";
import { horasPorCliente } from "@/lib/horas-data";
import { chaveDia } from "@/lib/horas";
import { prisma } from "@/lib/prisma";
import { margemPorContrato, resultadoPorMes, ultimoRelatorioFinanceiro } from "@/lib/ops";
import { formatarPct, rotuloMesCurto } from "@/lib/margem";
import { MargemChart } from "@/components/MargemChart";
import { SAUDE } from "@/lib/saude";
import { dataBr as dataRel } from "@/lib/relatorio-financeiro";
import { ResultadoChart } from "@/components/ResultadoChart";
import { CaixaChart } from "@/components/CaixaChart";
import { compromissoMensal } from "@/lib/recorrencias";
import { listarModelos } from "@/lib/recorrencias-data";

// Painel financeiro: a porta de entrada do papel financeiro. Primeiro o que
// precisa de alguém (cada linha leva à tela onde se resolve); depois os números
// que os agentes calculam (caixa e resultado).

function dataBr(iso: string) {
  return `${iso.slice(8, 10)}/${iso.slice(5, 7)}/${iso.slice(0, 4)}`;
}

function somaDias(dia: string, n: number) {
  const d = new Date(`${dia}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

export default async function PainelFinanceiroPage() {
  const usuario = await usuarioDaArea("financeiro");
  const hoje = chaveDia(new Date());
  const mesAtual = hoje.slice(0, 7);
  const compContabil = competenciaPadrao(mesAtual);

  const [contas, divergencias, kpis, docsContabeis, horas, resultadoMensal, relatorio, modelos, margens] = await Promise.all([
    listarContas(),
    contarDivergenciasAbertas(),
    kpisAtuais(),
    prisma.documentoContabil.findMany({ where: { competencia: compContabil, removidoEm: null }, select: { tipo: true } }),
    horasPorCliente(mesAtual),
    resultadoPorMes(6),
    ultimoRelatorioFinanceiro(),
    listarModelos(hoje),
    margemPorContrato(),
  ]);
  const compromisso = compromissoMensal(modelos, hoje);
  const saudeRel = relatorio ? (relatorio.saude ? SAUDE[relatorio.saude] : null) : null;

  const quem = { role: usuario.role, email: usuario.email };
  const decidir = contas.filter((c) => c.status === "aguardando_aprovacao" && bloqueio("aprovar", c, quem) === null);
  const abertas = contas.filter((c) => c.status === "aguardando_aprovacao" || c.status === "aprovada");
  const vencidas = abertas.filter((c) => c.vencimento < hoje);
  const pagarLogo = contas.filter((c) => c.status === "aprovada" && c.vencimento >= hoje && c.vencimento <= somaDias(hoje, 3));
  const faltamDocs = checklist(docsContabeis.map((d) => d.tipo)).filter((i) => !i.recebidos);
  const estourados = horas.filter((h) => h.situacao === "estourado" || h.situacao === "atencao");
  const soma = (l: { valor: number }[]) => formatarReais(l.reduce((s, c) => s + c.valor, 0));

  const pendencias: { href: string; titulo: string; detalhe: string; tag: string }[] = [];
  if (decidir.length)
    pendencias.push({ href: "/financeiro/aprovacoes", titulo: `${decidir.length} conta${decidir.length > 1 ? "s" : ""} para você aprovar`, detalhe: soma(decidir), tag: "aprovação" });
  if (vencidas.length)
    pendencias.push({ href: "/financeiro/contas?ver=abertas", titulo: `${vencidas.length} conta${vencidas.length > 1 ? "s vencidas" : " vencida"} sem pagamento`, detalhe: soma(vencidas), tag: "vencida" });
  if (pagarLogo.length)
    pendencias.push({ href: "/financeiro/contas?ver=a_pagar", titulo: `${pagarLogo.length} conta${pagarLogo.length > 1 ? "s aprovadas vencem" : " aprovada vence"} em até 3 dias`, detalhe: soma(pagarLogo), tag: "pagar" });
  for (const d of divergencias ?? [])
    pendencias.push({ href: `/financeiro/divergencias?origem=${d.origem}`, titulo: `${d.total} divergência${d.total > 1 ? "s abertas" : " aberta"}`, detalhe: rotuloOrigem(d.origem), tag: "divergência" });
  if (faltamDocs.length)
    pendencias.push({ href: `/financeiro/contabilidade?mes=${compContabil}`, titulo: `Contabilidade de ${rotuloMes(compContabil)}: falta${faltamDocs.length > 1 ? "m" : ""} ${faltamDocs.length} documento${faltamDocs.length > 1 ? "s" : ""}`, detalhe: faltamDocs.map((i) => i.item).join(", "), tag: "documentos" });
  if (estourados.length)
    pendencias.push({ href: "/financeiro/horas", titulo: `${estourados.length} contrato${estourados.length > 1 ? "s" : ""} AMS em atenção ou estourado`, detalhe: estourados.map((h) => h.clientNome).join(", "), tag: "horas" });

  const grupo = (g: "caixa" | "resultado") =>
    (kpis ?? []).filter((k) => defKpi(k.metrica).grupo === g).sort((a, b) => defKpi(a.metrica).ordem - defKpi(b.metrica).ordem);
  const cartao = (k: Kpi) => {
    const def = defKpi(k.metrica);
    const t = tendencia(k.valor, k.anterior, def.subirEhRuim);
    return (
      <div key={k.metrica} className={`kpi${k.metrica.startsWith("caixa") && k.valor < 0 ? " kpi-alerta" : ""}`}>
        <span className="kpi-rotulo">{def.rotulo}</span>
        <span className="kpi-valor num">{formatarReais(k.valor)}</span>
        <span className="kpi-nota">
          {t ? `${t} · ` : ""}ref. {dataBr(k.referencia)}
        </span>
      </div>
    );
  };
  const caixa = grupo("caixa").slice(0, 6);
  const resultado = grupo("resultado");
  const projecaoCaixa = caixa
    .filter((k) => /^caixa_\d+d$/.test(k.metrica))
    .map((k) => ({ dias: Number(k.metrica.match(/\d+/)![0]), valor: k.valor }))
    .sort((a, b) => a.dias - b.dias);

  return (
    <>
      <div className="overview-header">
        <h1>Painel financeiro</h1>
        <p>O que precisa de alguém hoje e os números que os agentes calcularam.</p>
      </div>

      <div className="overview-section">
        <h2>Saúde financeira</h2>
        <Link className="overview-row" href="/financeiro/saude">
          {relatorio ? (
            <>
              {saudeRel ? (
                <span className={`saude ${saudeRel.classe}`}>
                  <span aria-hidden="true">{saudeRel.simbolo}</span> {saudeRel.rotulo}
                </span>
              ) : (
                <span className="saude pendente">desconhecida</span>
              )}
              <span className="oc-title">
                Relatório de {dataRel(relatorio.referencia)}
                <span className="sub">{relatorio.motivos[0] ?? "ver indicadores, riscos e recomendações"}</span>
              </span>
            </>
          ) : (
            <span className="oc-title">
              Relatório diário do agente CFO
              <span className="sub">{relatorio === null ? "aparece quando o banco dos agentes estiver ligado" : "nenhum relatório gravado ainda"}</span>
            </span>
          )}
          <span aria-hidden="true">→</span>
        </Link>
      </div>

      <div className="overview-section">
        <h2>Precisa de atenção</h2>
        {pendencias.length === 0 ? (
          <div className="overview-empty ok">Nada pendente: contas em dia, sem divergências abertas e documentos do mês recebidos.</div>
        ) : (
          <div className="overview-list">
            {pendencias.map((p) => (
              <Link key={p.href + p.titulo} className="overview-row" href={p.href}>
                <span className="oc-client">{p.tag}</span>
                <span className="oc-title">
                  {p.titulo}
                  <span className="sub">{p.detalhe}</span>
                </span>
                <span aria-hidden="true">→</span>
              </Link>
            ))}
          </div>
        )}
      </div>

      <div className="overview-section">
        <h2>Compromisso mensal recorrente</h2>
        {compromisso.quantidade === 0 ? (
          <Link className="overview-row" href="/financeiro/recorrentes">
            <span className="oc-title">
              Nenhuma despesa recorrente cadastrada
              <span className="sub">cadastre assinaturas, salários e aluguel para ver o compromisso fixo do mês</span>
            </span>
            <span aria-hidden="true">→</span>
          </Link>
        ) : (
          <div className="kpis">
            <Link href="/financeiro/recorrentes" className="kpi kpi-link">
              <span className="kpi-rotulo">Total por mês</span>
              <span className="kpi-valor num">{formatarReais(compromisso.total)}</span>
              <span className="kpi-nota">
                {compromisso.quantidade} despesa{compromisso.quantidade === 1 ? "" : "s"} recorrente
                {compromisso.quantidade === 1 ? "" : "s"} ativa{compromisso.quantidade === 1 ? "" : "s"}
              </span>
            </Link>
            <Link href="/financeiro/contas?ver=todas&natureza=fixo" className="kpi kpi-link">
              <span className="kpi-rotulo">Despesa fixa por mês</span>
              <span className="kpi-valor num">{formatarReais(compromisso.fixo)}</span>
              <span className="kpi-nota">operação</span>
            </Link>
            <Link href="/financeiro/contas?ver=todas&natureza=direto" className="kpi kpi-link">
              <span className="kpi-rotulo">Custo direto por mês</span>
              <span className="kpi-valor num">{formatarReais(compromisso.direto)}</span>
              <span className="kpi-nota">serviço prestado a cliente</span>
            </Link>
          </div>
        )}
      </div>

      <div className="overview-section">
        <h2>Caixa</h2>
        {kpis === null ? (
          <div className="overview-empty">Os números de caixa e resultado aparecem quando o banco dos agentes estiver ligado a este Squad OS.</div>
        ) : caixa.length === 0 ? (
          <div className="overview-empty">O cashflow_monitor ainda não gravou a projeção de caixa.</div>
        ) : (
          <>
            {projecaoCaixa.length > 1 && <CaixaChart dados={projecaoCaixa} />}
            <div className="kpis">{caixa.map(cartao)}</div>
          </>
        )}
      </div>

      {kpis !== null && (
        <div className="overview-section">
          <h2>Resultado do último mês fechado</h2>
          {resultado.length === 0 ? (
            <div className="overview-empty">O finance_report_agent grava a DRE no dia 5 de cada mês.</div>
          ) : (
            <>
              {resultadoMensal && resultadoMensal.length > 1 && <ResultadoChart dados={resultadoMensal} />}
              <div className="kpis">{resultado.map(cartao)}</div>
            </>
          )}
        </div>
      )}

      {margens !== null && (
        <div className="overview-section">
          <h2>Margem por contrato</h2>
          {margens.length === 0 ? (
            <div className="overview-empty">A margem por contrato aparece quando a view ops.margem_contratos estiver no banco.</div>
          ) : (
            <>
              <div className="kpis">
                {margens.map((c) => {
                  const u = c.ultima;
                  const atual = c.linhas.at(-1)!;
                  return (
                    <Link
                      key={c.clientId}
                      href="/financeiro/horas"
                      className={`kpi kpi-link${u && u.margem! < 0 ? " kpi-negativo" : ""}`}
                    >
                      <span className="kpi-rotulo">{c.cliente}</span>
                      <span className="kpi-valor num">{u ? formatarReais(u.margem!) : "—"}</span>
                      <span className="kpi-nota">
                        {u
                          ? `${formatarPct(u.margemPct)} em ${rotuloMesCurto(u.mes)} · ${u.situacao}`
                          : `${rotuloMesCurto(atual.mes)}: ${atual.situacao}`}
                      </span>
                    </Link>
                  );
                })}
              </div>
              <MargemChart contratos={margens} />
              <div className="tabela-wrap">
                <table className="tabela">
                  <caption className="sr-only">Margem de contribuição por contrato e mês</caption>
                  <thead>
                    <tr>
                      <th scope="col">Contrato</th>
                      <th scope="col">Mês</th>
                      <th scope="col" className="num">Receita</th>
                      <th scope="col" className="num">Custo direto</th>
                      <th scope="col" className="num">Margem</th>
                      <th scope="col" className="num">Margem %</th>
                      <th scope="col" className="num">Horas</th>
                      <th scope="col" className="num">Receita/h</th>
                      <th scope="col" className="num">Custo/h</th>
                      <th scope="col">Situação</th>
                    </tr>
                  </thead>
                  <tbody>
                    {margens.flatMap((c) =>
                      c.linhas.map((m) => (
                        <tr key={`${c.clientId}-${m.mes}`}>
                          <th scope="row">
                            <Link href="/financeiro/horas">{c.cliente}</Link>
                          </th>
                          <td className="data">{rotuloMesCurto(m.mes)}</td>
                          <td className="num">{/nota/.test(m.situacao) ? "—" : formatarReais(m.receita)}</td>
                          <td className="num">{m.situacao === "sem custo direto lançado" ? "—" : formatarReais(m.custoDireto)}</td>
                          <td className={`num${m.margem !== null && m.margem < 0 ? " negativo" : ""}`}>
                            {m.margem === null ? "—" : formatarReais(m.margem)}
                          </td>
                          <td className={`num${m.margemPct !== null && m.margemPct < 0 ? " negativo" : ""}`}>{formatarPct(m.margemPct)}</td>
                          <td className="num">
                            {m.horas ? `${m.horas.toLocaleString("pt-BR")}${m.horasContratadas ? ` / ${m.horasContratadas}` : ""} h` : "—"}
                          </td>
                          <td className="num">{m.receitaHora === null ? "—" : formatarReais(m.receitaHora)}</td>
                          <td className="num">{m.custoHora === null ? "—" : formatarReais(m.custoHora)}</td>
                          <td>{m.situacao}{m.notas ? ` · NFS-e ${m.notas}` : ""}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      )}
    </>
  );
}
