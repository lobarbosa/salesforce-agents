import { usuarioDaArea } from "@/lib/area";
import { listarContas } from "@/lib/contas-data";
import { alcadaFinanceiro, bloqueio, formatarReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { ContasPagar } from "@/components/ContasPagar";

// Fila de aprovações (padrão Jira Service Management): primeiro o que a pessoa
// logada pode decidir; depois o que espera outra pessoa, com o motivo no detalhe.
export default async function AprovacoesPage() {
  const usuario = await usuarioDaArea("financeiro");
  const hoje = chaveDia(new Date());
  const contas = (await listarContas()).filter((c) => c.status === "aguardando_aprovacao");
  const quem = { role: usuario.role, email: usuario.email };
  const decidiveis = contas.filter((c) => bloqueio("aprovar", c, quem) === null).map((c) => c.id);
  const categorias = [...new Set(contas.map((c) => c.categoria).filter(Boolean))].sort();
  const alcada = alcadaFinanceiro();

  return (
    <>
      <div className="overview-header">
        <h1>Aprovações</h1>
        <p>
          {usuario.role === "admin"
            ? "Como admin, você aprova qualquer valor, exceto contas que você mesmo lançou."
            : alcada
              ? `Você aprova contas de até ${formatarReais(alcada)} que não tenha lançado.`
              : "Sem alçada configurada para o financeiro: toda aprovação é do admin."}
        </p>
      </div>
      <ContasPagar contas={contas} hoje={hoje} modo="aprovacoes" decidiveis={decidiveis} categorias={categorias} />
    </>
  );
}
