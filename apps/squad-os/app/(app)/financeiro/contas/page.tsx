import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { listarContas, type ContaVista } from "@/lib/contas-data";
import { formatarReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { ContasPagar } from "@/components/ContasPagar";
import { ContasSituacaoChart } from "@/components/ContasSituacaoChart";
import { clientesParaSelecao, gerarSeNecessario } from "@/lib/recorrencias-data";
import { ROTULO_NATUREZA } from "@/lib/recorrencias";

// Contas a pagar: substitui a lista do ClickUp (task = conta, due date =
// vencimento, campo "Valor", anexo = documento fiscal). Filtro no link, para
// o DM do payables_checker abrir direto na conta (?conta=<id>).

const FILTROS = {
  abertas: { rotulo: "Em aberto", vale: (c: ContaVista) => c.status === "aguardando_aprovacao" || c.status === "aprovada" },
  aguardando: { rotulo: "Aguardando aprovação", vale: (c: ContaVista) => c.status === "aguardando_aprovacao" },
  a_pagar: { rotulo: "Aprovadas, a pagar", vale: (c: ContaVista) => c.status === "aprovada" },
  pagas: { rotulo: "Pagas", vale: (c: ContaVista) => c.status === "paga" },
  todas: { rotulo: "Todas", vale: () => true },
} as const;
type Filtro = keyof typeof FILTROS;

// Recorrente × avulsa e natureza do custo: filtros que se somam ao de situação.
const TIPOS = {
  todas: { rotulo: "Recorrentes e avulsas", vale: () => true },
  recorrentes: { rotulo: "Recorrentes", vale: (c: ContaVista) => c.recorrenciaId !== null },
  avulsas: { rotulo: "Avulsas", vale: (c: ContaVista) => c.recorrenciaId === null },
} as const;
type Tipo = keyof typeof TIPOS;

const NATUREZAS_FILTRO = {
  todas: { rotulo: "Toda natureza", vale: () => true },
  fixo: { rotulo: ROTULO_NATUREZA.fixo, vale: (c: ContaVista) => c.natureza === "fixo" },
  direto: { rotulo: ROTULO_NATUREZA.direto, vale: (c: ContaVista) => c.natureza === "direto" },
  sem: { rotulo: "sem natureza", vale: (c: ContaVista) => c.natureza === null },
} as const;
type NaturezaFiltro = keyof typeof NATUREZAS_FILTRO;

export default async function ContasPage({
  searchParams,
}: {
  searchParams: Promise<{ ver?: string; conta?: string; tipo?: string; natureza?: string; recorrencia?: string }>;
}) {
  await usuarioDaArea("financeiro");
  // Gera as contas recorrentes devidas antes de listar (funciona mesmo sem o cron).
  await gerarSeNecessario();
  const { ver, conta, tipo: tipoParam, natureza: naturezaParam, recorrencia } = await searchParams;
  const filtro: Filtro = ver && ver in FILTROS ? (ver as Filtro) : "abertas";
  const tipo: Tipo = tipoParam && tipoParam in TIPOS ? (tipoParam as Tipo) : "todas";
  const natureza: NaturezaFiltro =
    naturezaParam && naturezaParam in NATUREZAS_FILTRO ? (naturezaParam as NaturezaFiltro) : "todas";
  const link = (mudar: { ver?: string; tipo?: string; natureza?: string }) => {
    const p = new URLSearchParams();
    const v = { ver: filtro, tipo, natureza, ...mudar };
    p.set("ver", v.ver);
    if (v.tipo !== "todas") p.set("tipo", v.tipo);
    if (v.natureza !== "todas") p.set("natureza", v.natureza);
    if (recorrencia && v.tipo === "recorrentes") p.set("recorrencia", recorrencia);
    return `/financeiro/contas?${p}`;
  };
  const hoje = chaveDia(new Date());
  const mes = hoje.slice(0, 7);

  const [todas, clientes] = await Promise.all([listarContas(), clientesParaSelecao()]);
  const soma = (l: ContaVista[]) => formatarReais(l.reduce((s, c) => s + c.valor, 0));
  const aguardando = todas.filter(FILTROS.aguardando.vale);
  const aPagar = todas.filter(FILTROS.a_pagar.vale);
  const vencidas = todas.filter((c) => FILTROS.abertas.vale(c) && c.vencimento < hoje);
  const pagasMes = todas.filter((c) => c.status === "paga" && c.pagoEm && chaveDia(new Date(c.pagoEm)).startsWith(mes));
  const categorias = [...new Set(todas.map((c) => c.categoria).filter(Boolean))].sort();
  const lista = todas.filter(
    (c) =>
      FILTROS[filtro].vale(c) &&
      TIPOS[tipo].vale(c) &&
      NATUREZAS_FILTRO[natureza].vale(c) &&
      (!recorrencia || tipo !== "recorrentes" || c.recorrenciaId === recorrencia)
  );
  // Conta pedida pelo link abre mesmo fora do filtro atual.
  const contaInicial = conta && todas.some((c) => c.id === conta) ? conta : undefined;

  const kpi = (href: string, rotulo: string, l: ContaVista[], alerta = false) => (
    <Link href={href} className={`kpi kpi-link${alerta && l.length ? " kpi-alerta" : ""}`}>
      <span className="kpi-rotulo">{rotulo}</span>
      <span className="kpi-valor num">{l.length}</span>
      <span className="kpi-nota num">{soma(l)}</span>
    </Link>
  );
  const somaValor = (l: ContaVista[]) => l.reduce((s, c) => s + c.valor, 0);
  const situacoes = [
    { rotulo: "aguardando", valor: somaValor(aguardando) },
    { rotulo: "a pagar", valor: somaValor(aPagar) },
    { rotulo: "vencidas", valor: somaValor(vencidas), alerta: true },
    { rotulo: "pagas no mês", valor: somaValor(pagasMes) },
  ].filter((s) => s.valor > 0);

  return (
    <>
      <div className="overview-header">
        <h1>Contas a pagar</h1>
        <p>Lance a conta com o documento fiscal; outra pessoa aprova e quem paga marca como paga.</p>
      </div>

      <div className="kpis">
        {kpi("/financeiro/contas?ver=aguardando", "Aguardando aprovação", aguardando)}
        {kpi("/financeiro/contas?ver=a_pagar", "Aprovadas, a pagar", aPagar)}
        {kpi("/financeiro/contas?ver=abertas", "Vencidas e não pagas", vencidas, true)}
        {kpi("/financeiro/contas?ver=pagas", `Pagas em ${mes.slice(5)}/${mes.slice(0, 4)}`, pagasMes)}
      </div>

      {situacoes.length > 1 && <ContasSituacaoChart dados={situacoes} />}

      <nav className="tabs" aria-label="Filtrar contas">
        {(Object.keys(FILTROS) as Filtro[]).map((f) => (
          <Link
            key={f}
            href={link({ ver: f })}
            className={`tab-btn${f === filtro ? " active" : ""}`}
            aria-current={f === filtro ? "page" : undefined}
          >
            {FILTROS[f].rotulo}
          </Link>
        ))}
      </nav>

      <div className="chips" role="group" aria-label="Filtrar por tipo">
        {(Object.keys(TIPOS) as Tipo[]).map((t) => (
          <Link key={t} href={link({ tipo: t })} className={`chip${t === tipo ? " ativo" : ""}`} aria-current={t === tipo ? "true" : undefined}>
            {TIPOS[t].rotulo}
          </Link>
        ))}
      </div>
      <div className="chips" role="group" aria-label="Filtrar por natureza">
        {(Object.keys(NATUREZAS_FILTRO) as NaturezaFiltro[]).map((n) => (
          <Link
            key={n}
            href={link({ natureza: n })}
            className={`chip${n === natureza ? " ativo" : ""}`}
            aria-current={n === natureza ? "true" : undefined}
          >
            {NATUREZAS_FILTRO[n].rotulo}
          </Link>
        ))}
      </div>
      {recorrencia && tipo === "recorrentes" && (
        <p className="save-note">
          Mostrando só as contas de uma recorrência. <Link href={link({ tipo: "todas" })}>Ver todas</Link>
        </p>
      )}

      <ContasPagar
        contas={lista}
        hoje={hoje}
        modo="contas"
        contaInicial={contaInicial}
        categorias={categorias}
        clientes={clientes}
      />
    </>
  );
}
