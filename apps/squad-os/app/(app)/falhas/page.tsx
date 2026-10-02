import { usuarioDaArea } from "@/lib/area";
import { listarFalhasRecentes } from "@/lib/execucoes-data";

// "O que pode ter falhado" pro consultor (council de 2026-10-01) — pra não
// ficar no escuro sobre qualquer cliente sem precisar abrir o GitHub
// Actions. Só falhas, sem dado de custo (isso é assunto do financeiro/admin,
// não de quem entrega) — admin também usa esta tela, além da visão completa
// em /operacao/execucoes.

const ROTULO_ORIGEM: Record<string, string> = {
  demanda: "demanda",
  assessment: "assessment",
  planejamento: "planejamento",
  conexao: "conexão",
};

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

export default async function FalhasPage() {
  await usuarioDaArea("delivery");
  const falhas = await listarFalhasRecentes(100);

  return (
    <>
      <div className="overview-header">
        <h1>Falhas</h1>
        <p>Execuções que não terminaram bem, de qualquer cliente — pra saber sem precisar abrir o GitHub Actions.</p>
      </div>

      {falhas.length === 0 ? (
        <div className="overview-empty ok">Nenhuma falha registrada. Tudo que rodou, terminou bem.</div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Falhas recentes</caption>
            <thead>
              <tr>
                <th scope="col">Quando</th>
                <th scope="col">Cliente</th>
                <th scope="col">Origem</th>
                <th scope="col">Etapa</th>
                <th scope="col">
                  <span className="sr-only">Log do run</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {falhas.map((f) => (
                <tr key={f.id}>
                  <td className="data">{quando(f.concluidoEm)}</td>
                  <td>
                    {f.clientNome}
                    {f.demandaCode && <span className="sub mono">{f.demandaCode}</span>}
                  </td>
                  <td>{ROTULO_ORIGEM[f.origem] ?? f.origem}</td>
                  <td className="mono-cel">
                    {f.etapa}
                    {f.motivo && <span className="sub">{f.motivo}</span>}
                  </td>
                  <td>{f.runUrl && <a href={f.runUrl} target="_blank" rel="noopener noreferrer">ver o run</a>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
