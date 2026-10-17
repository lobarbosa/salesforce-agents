import { usuarioDaArea } from "@/lib/area";
import { formatarReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { compromissoMensal } from "@/lib/recorrencias";
import { clientesParaSelecao, gerarSeNecessario, listarModelos } from "@/lib/recorrencias-data";
import { DespesasRecorrentes } from "@/components/DespesasRecorrentes";

// Despesas recorrentes: o compromisso mensal fixo à vista, separado em
// despesa fixa (operação) e custo direto (serviço prestado a cliente) — é essa
// separação que o cfo_agent usa para a margem de contribuição. Cada modelo gera
// a conta a pagar da competência 30 dias antes do vencimento.
export default async function RecorrentesPage({ searchParams }: { searchParams: Promise<{ modelo?: string }> }) {
  await usuarioDaArea("financeiro");
  await gerarSeNecessario();
  const { modelo } = await searchParams;
  const hoje = chaveDia(new Date());
  const [modelos, clientes] = await Promise.all([listarModelos(hoje), clientesParaSelecao()]);
  const c = compromissoMensal(modelos, hoje);
  const categorias = [...new Set(modelos.map((m) => m.categoria).filter(Boolean))].sort();
  const modeloInicial = modelo && modelos.some((m) => m.id === modelo) ? modelo : undefined;

  return (
    <>
      <div className="overview-header">
        <h1>Despesas recorrentes</h1>
        <p>O que se repete todo mês (ou trimestre, semestre, ano). As contas são geradas sozinhas e seguem a aprovação normal.</p>
      </div>

      <div className="kpis">
        <div className="kpi">
          <span className="kpi-rotulo">Compromisso mensal recorrente</span>
          <span className="kpi-valor num">{formatarReais(c.total)}</span>
          <span className="kpi-nota">
            {c.quantidade} despesa{c.quantidade === 1 ? "" : "s"} ativa{c.quantidade === 1 ? "" : "s"}; trimestral, semestral e
            anual divididas por mês
          </span>
        </div>
        <div className="kpi">
          <span className="kpi-rotulo">Despesa fixa por mês</span>
          <span className="kpi-valor num">{formatarReais(c.fixo)}</span>
          <span className="kpi-nota">operação: software, salários administrativos, aluguel…</span>
        </div>
        <div className="kpi">
          <span className="kpi-rotulo">Custo direto por mês</span>
          <span className="kpi-valor num">{formatarReais(c.direto)}</span>
          <span className="kpi-nota">serviço prestado: consultores e terceiros alocados a cliente</span>
        </div>
      </div>

      <DespesasRecorrentes
        modelos={modelos}
        clientes={clientes}
        categorias={categorias}
        hoje={hoje}
        modeloInicial={modeloInicial}
      />
    </>
  );
}
