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

  const [contas, divergencias, kpis, docsContabeis, horas] = await Promise.all([
    listarContas(),
    contarDivergenciasAbertas(),
    kpisAtuais(),
    prisma.documentoContabil.findMany({ where: { competencia: compContabil, removidoEm: null }, select: { tipo: true } }),
    horasPorCliente(mesAtual),
  ]);

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

  return (
    <>
      <div className="overview-header">
        <h1>Painel financeiro</h1>
        <p>O que precisa de alguém hoje e os números que os agentes calcularam.</p>
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
        <h2>Caixa</h2>
        {kpis === null ? (
          <div className="overview-empty">Os números de caixa e resultado aparecem quando o banco dos agentes estiver ligado a este Squad OS.</div>
        ) : caixa.length === 0 ? (
          <div className="overview-empty">O cashflow_monitor ainda não gravou a projeção de caixa.</div>
        ) : (
          <div className="kpis">{caixa.map(cartao)}</div>
        )}
      </div>

      {kpis !== null && (
        <div className="overview-section">
          <h2>Resultado do último mês fechado</h2>
          {resultado.length === 0 ? (
            <div className="overview-empty">O finance_report_agent grava a DRE no dia 5 de cada mês.</div>
          ) : (
            <div className="kpis">{resultado.map(cartao)}</div>
          )}
        </div>
      )}
    </>
  );
}
