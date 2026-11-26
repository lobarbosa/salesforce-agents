import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { formatarReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { totais, type NotaVista } from "@/lib/receber";
import { listarNotas } from "@/lib/receber-data";
import { ContasReceber } from "@/components/ContasReceber";

// Contas a receber: as NFS-e emitidas (lidas pela conciliação contábil dos
// documentos que a contabilidade anexa) e o registro de que cada uma foi
// recebida. Antes o recebimento era um registro à mão no banco dos agentes;
// agora o financeiro marca aqui e o CFO, o fluxo de caixa e a DRE leem daqui.

const FILTROS = {
  abertas: { rotulo: "Em aberto", vale: (n: NotaVista) => n.situacao !== "recebida" },
  vencidas: { rotulo: "Vencidas", vale: (n: NotaVista) => n.situacao === "vencida" },
  a_vencer: { rotulo: "A vencer", vale: (n: NotaVista) => n.situacao === "a_vencer" || n.situacao === "sem_vencimento" },
  recebidas: { rotulo: "Recebidas", vale: (n: NotaVista) => n.situacao === "recebida" },
  todas: { rotulo: "Todas", vale: () => true },
} as const;
type Filtro = keyof typeof FILTROS;

export default async function ContasReceberPage({
  searchParams,
}: {
  searchParams: Promise<{ ver?: string; nota?: string; cliente?: string }>;
}) {
  await usuarioDaArea("financeiro");
  const { ver, nota, cliente } = await searchParams;
  const filtro: Filtro = ver && ver in FILTROS ? (ver as Filtro) : "abertas";
  const hoje = chaveDia(new Date());
  const lista = await listarNotas(hoje);

  const cabecalho = (
    <div className="overview-header">
      <h1>Contas a receber</h1>
      <p>As notas fiscais emitidas e o registro de cada recebimento. Abra a nota para marcar que ela foi paga.</p>
    </div>
  );
  if (!lista) {
    return (
      <>
        {cabecalho}
        <div className="overview-empty">
          As notas aparecem aqui quando a conciliação contábil publicar as NFS-e lidas dos documentos da contabilidade.
          Anexe a relação de notas do mês em <Link href="/financeiro/contabilidade">Contabilidade</Link>.
        </div>
      </>
    );
  }

  const todas = lista.notas;
  const t = totais(todas, hoje);
  const clientes = [...new Set(todas.map((n) => n.cliente).filter(Boolean))].sort();
  const doCliente = cliente && clientes.includes(cliente) ? cliente : null;
  const visiveis = todas.filter((n) => FILTROS[filtro].vale(n) && (!doCliente || n.cliente === doCliente));
  const link = (mudar: { ver?: string; cliente?: string | null }) => {
    const p = new URLSearchParams();
    p.set("ver", mudar.ver ?? filtro);
    const c = mudar.cliente === undefined ? doCliente : mudar.cliente;
    if (c) p.set("cliente", c);
    return `/financeiro/receber?${p}`;
  };
  const notaInicial = nota && todas.some((n) => n.chave === nota) ? nota : undefined;
  const kpi = (href: string, rotulo: string, x: { qtd: number; valor: number }, alerta = false) => (
    <Link href={href} className={`kpi kpi-link${alerta && x.qtd ? " kpi-alerta" : ""}`}>
      <span className="kpi-rotulo">{rotulo}</span>
      <span className="kpi-valor num">{formatarReais(x.valor)}</span>
      <span className="kpi-nota">
        {x.qtd} nota{x.qtd === 1 ? "" : "s"}
      </span>
    </Link>
  );
  const mes = hoje.slice(0, 7);

  return (
    <>
      {cabecalho}
      <div className="kpis">
        {kpi(link({ ver: "abertas", cliente: null }), "Em aberto", t.abertas)}
        {kpi(link({ ver: "vencidas", cliente: null }), "Vencidas sem recebimento", t.vencidas, true)}
        {kpi(link({ ver: "a_vencer", cliente: null }), "Vencem em 30 dias", t.proximas30)}
        {kpi(link({ ver: "recebidas", cliente: null }), `Recebido em ${mes.slice(5)}/${mes.slice(0, 4)}`, t.recebidasMes)}
      </div>

      <nav className="tabs" aria-label="Filtrar notas">
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
      {clientes.length > 1 && (
        <div className="chips" role="group" aria-label="Filtrar por cliente">
          <Link href={link({ cliente: null })} className={`chip${!doCliente ? " ativo" : ""}`} aria-current={!doCliente ? "true" : undefined}>
            Todos os clientes
          </Link>
          {clientes.map((c) => (
            <Link key={c} href={link({ cliente: c })} className={`chip${c === doCliente ? " ativo" : ""}`} aria-current={c === doCliente ? "true" : undefined}>
              {c}
            </Link>
          ))}
        </div>
      )}

      <ContasReceber notas={visiveis} todas={todas} hoje={hoje} notaInicial={notaInicial} />

      <p className="save-note">
        Valor a receber = valor líquido da nota (depois das retenções) ou, quando a nota não traz, o valor dos serviços.
        {lista.atualizadoEm ? ` Notas lidas pela conciliação contábil em ${lista.atualizadoEm.slice(8, 10)}/${lista.atualizadoEm.slice(5, 7)}.` : ""}
      </p>
    </>
  );
}
