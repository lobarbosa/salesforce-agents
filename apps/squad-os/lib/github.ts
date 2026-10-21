import { Octokit } from "@octokit/rest";
import { dump as dumpYaml, load as loadYaml } from "js-yaml";

// A ponte que fecha o gap descrito em docs/conexoes-e-setup.md §3 passo 7:
// materializa a demanda como clients/<slug>/demandas/<code>/{demanda.md,status.yaml}
// e dispara run-demand.yml — antes disso era manual (ler no OS, rodar `sfagents
// demanda nova` com o mesmo texto).

function octokit() {
  const token = process.env.GITHUB_TOKEN;
  if (!token) throw new Error("GITHUB_TOKEN não configurado — ver apps/squad-os/README.md");
  return new Octokit({ auth: token });
}

function repoConfig() {
  const owner = process.env.GITHUB_REPO_OWNER;
  const repo = process.env.GITHUB_REPO_NAME;
  const branch = process.env.GITHUB_REPO_BRANCH || "main";
  if (!owner || !repo) {
    throw new Error("GITHUB_REPO_OWNER/GITHUB_REPO_NAME não configurados — ver apps/squad-os/README.md");
  }
  return { owner, repo, branch };
}

async function putFile(path: string, content: string, message: string) {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();

  let sha: string | undefined;
  try {
    const existing = await gh.repos.getContent({ owner, repo, path, ref: branch });
    if (!Array.isArray(existing.data) && existing.data.type === "file") {
      sha = existing.data.sha;
    }
  } catch (err) {
    const status = (err as { status?: number }).status;
    if (status !== 404) throw err;
  }

  await gh.repos.createOrUpdateFileContents({
    owner,
    repo,
    branch,
    path,
    message,
    content: Buffer.from(content, "utf-8").toString("base64"),
    sha,
  });
}

export interface DemandaParaMaterializar {
  code: string; // ex.: ACXYA-1 — vira o `id` dentro de status.yaml, igual ao dataclass Demand em demands.py
  clientSlug: string;
  titulo: string;
  texto: string;
  tipo: string;
  status: string;
  criadoEm: Date;
  historico: unknown;
}

/** Já existe outra demanda com este código no repositório (criada pela CLI). */
export class CodigoOcupadoNoGitError extends Error {}

/** Conteúdo de um arquivo no branch configurado, ou null se não existe. */
async function lerArquivo(path: string): Promise<string | null> {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();
  try {
    const r = await gh.repos.getContent({ owner, repo, path, ref: branch });
    if (Array.isArray(r.data) || r.data.type !== "file") return "";
    return Buffer.from(r.data.content ?? "", "base64").toString("utf-8");
  } catch (err) {
    if ((err as { status?: number }).status === 404) return null;
    throw err;
  }
}

export async function materializeDemanda(d: DemandaParaMaterializar) {
  const base = `clients/${d.clientSlug}/demandas/${d.code}`;

  const demandaMd = `# ${d.titulo}\n\n${d.texto}\n`;

  // O código desta demanda foi gerado pelo banco, que não enxerga demanda
  // criada direto no git (`sfagents demanda nova`). Se já existe um
  // demanda.md diferente neste caminho, é OUTRA demanda com o mesmo número —
  // sobrescrever apagaria o pedido dela e misturaria as duas esteiras. Igual
  // ao que escreveríamos = tentativa anterior nossa que parou no meio: segue.
  const existente = await lerArquivo(`${base}/demanda.md`);
  if (existente !== null && existente !== demandaMd) {
    throw new CodigoOcupadoNoGitError(
      `já existe ${base}/demanda.md no repositório com outro conteúdo (demanda criada fora do Squad OS?) — ` +
        `materializar sobrescreveria aquela demanda. Renumere uma das duas antes.`
    );
  }
  await putFile(`${base}/demanda.md`, demandaMd, `${d.code}: registrar demanda via Squad OS`);

  const statusYaml = dumpYaml(
    {
      id: d.code,
      client: d.clientSlug,
      titulo: d.titulo,
      tipo: d.tipo,
      status: d.status,
      criado_em: d.criadoEm.toISOString(),
      historico: d.historico ?? [],
    },
    { sortKeys: false }
  );
  await putFile(`${base}/status.yaml`, statusYaml, `${d.code}: materializar status via Squad OS`);
}

// `aprovarGate` é o que fecha o laço humano -> agente: quando alguém aprova o
// gate no card, o workflow recebe o nome de quem aprovou, move o status.yaml
// pra etapa seguinte e roda a sessão. Sem isso, aprovar no app só mudava o
// Postgres e alguém ainda tinha que abrir o GitHub e disparar na mão.
export async function triggerRunDemand(
  clientSlug: string,
  demandCode: string,
  opts: { aprovarGate?: string; gateEsperado?: string } = {}
) {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();
  await gh.actions.createWorkflowDispatch({
    owner,
    repo,
    workflow_id: "run-demand.yml",
    ref: branch,
    inputs: {
      client: clientSlug,
      demand_id: demandCode,
      // Sempre presente (string vazia quando não é aprovação de gate): o
      // Actions rejeita input não declarado, mas aceita declarado e vazio.
      aprovar_gate: opts.aprovarGate ?? "",
      // O gate que a pessoa viu e aprovou. O workflow recusa aprovar se o
      // status.yaml já estiver em outro (ver run-demand.yml): é o que impede
      // um disparo duplicado na fila de aprovar o gate seguinte.
      gate_esperado: opts.aprovarGate ? (opts.gateEsperado ?? "") : "",
    },
  });
}

// O assessment é por cliente, não por demanda — workflow próprio, sem
// DEMAND_ID. Roda contra a org de dev (é onde a esteira trabalha) e é
// read-only por construção, ver .claude/agents/org-assessment.md.
export async function triggerAssessment(clientSlug: string) {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();
  await gh.actions.createWorkflowDispatch({
    owner,
    repo,
    workflow_id: "run-assessment.yml",
    ref: branch,
    inputs: { client: clientSlug },
  });
}

// Dispara o smoke test de JWT contra uma org do cliente. O resultado volta por
// /api/sync/conexao — é esse retorno que marca a org como conectada e, no caso
// da org de dev, acende o assessment de onboarding.
export async function triggerTestConnection(clientSlug: string, ambiente: "dev" | "qa") {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();
  await gh.actions.createWorkflowDispatch({
    owner,
    repo,
    workflow_id: "test-connection.yml",
    ref: branch,
    inputs: { client: clientSlug, ambiente },
  });
}

// Materializa o contrato como `clients/<slug>/contrato.md`. É o que o agente
// planejador lê — ele roda no repositório, não tem acesso ao Postgres. O `id`
// de cada entregável vai no texto de propósito: e o que amarra a demanda
// proposta de volta ao item vendido, e o CLI confere que o agente nao inventou
// um.
export async function materializeContrato(d: {
  clientSlug: string;
  clientNome: string;
  projetoNome: string;
  projetoEscopo: string;
  inicioEm: Date | null;
  fimPrevistoEm: Date | null;
  entregaveis: { id: string; titulo: string; descricao: string; peso: number; concluido: boolean }[];
}) {
  const data = (v: Date | null) => (v ? new Date(v).toISOString().slice(0, 10) : "a definir");

  const linhas = [
    `# Contrato — ${d.clientNome}`,
    "",
    "Materializado pelo Squad OS. Entrada do agente `planejador`; não editar à mão —",
    "a próxima materialização sobrescreve.",
    "",
    `**Projeto:** ${d.projetoNome || "(sem nome)"}`,
    `**Início:** ${data(d.inicioEm)} · **Fim previsto:** ${data(d.fimPrevistoEm)}`,
    "",
    "## Escopo contratado",
    "",
    d.projetoEscopo || "(não preenchido)",
    "",
    "## Entregáveis",
    "",
  ];

  if (d.entregaveis.length === 0) {
    linhas.push("(nenhum entregável cadastrado)");
  } else {
    for (const e of d.entregaveis) {
      linhas.push(`### ${e.titulo}`);
      linhas.push("");
      linhas.push(`\`id: ${e.id}\` · peso ${e.peso}${e.concluido ? " · **concluído**" : ""}`);
      if (e.descricao) {
        linhas.push("");
        linhas.push(e.descricao);
      }
      linhas.push("");
    }
  }

  await putFile(
    `clients/${d.clientSlug}/contrato.md`,
    linhas.join("\n"),
    `${d.clientSlug}: materializar contrato via Squad OS`
  );
}

export async function triggerPlanejamento(clientSlug: string) {
  const gh = octokit();
  const { owner, repo, branch } = repoConfig();
  await gh.actions.createWorkflowDispatch({
    owner,
    repo,
    workflow_id: "run-planejamento.yml",
    ref: branch,
    inputs: { client: clientSlug },
  });
}

/** A branch existe no repositório? */
async function branchExiste(nome: string): Promise<boolean> {
  const gh = octokit();
  const { owner, repo } = repoConfig();
  try {
    await gh.repos.getBranch({ owner, repo, branch: nome });
    return true;
  } catch (err) {
    if ((err as { status?: number }).status === 404) return false;
    throw err;
  }
}

// Congelar/cancelar/descongelar uma demanda já materializada precisa mudar o
// status.yaml — ele é a fonte de verdade, e o sync de volta sobrescreveria o
// Postgres com a etapa antiga na próxima execução. Escreve onde a esteira lê:
// feature/<code> quando a demanda já rodou alguma etapa, senão o branch base.
export async function registrarStatusNoGit(
  clientSlug: string,
  code: string,
  novoStatus: string,
  autor: string,
  motivo: string
) {
  const { branch: base } = repoConfig();
  const feature = `feature/${code}`;
  const ref = (await branchExiste(feature)) ? feature : base;
  const path = `clients/${clientSlug}/demandas/${code}/status.yaml`;

  const gh = octokit();
  const { owner, repo } = repoConfig();
  const atual = await gh.repos.getContent({ owner, repo, path, ref });
  if (Array.isArray(atual.data) || atual.data.type !== "file") {
    throw new Error(`${path} não é um arquivo em ${ref}`);
  }
  const doc = (loadYaml(Buffer.from(atual.data.content ?? "", "base64").toString("utf-8")) ?? {}) as {
    status?: string;
    historico?: unknown[];
  };
  const historico = Array.isArray(doc.historico) ? doc.historico : [];
  historico.push({ de: doc.status ?? "", para: novoStatus, autor, em: new Date().toISOString(), motivo });
  doc.status = novoStatus;
  doc.historico = historico;

  await gh.repos.createOrUpdateFileContents({
    owner,
    repo,
    branch: ref,
    path,
    message: `${code}: ${novoStatus} via Squad OS`,
    content: Buffer.from(dumpYaml(doc, { sortKeys: false }), "utf-8").toString("base64"),
    sha: atual.data.sha,
  });
}

const ESTADOS_ATIVOS = ["queued", "in_progress", "waiting", "pending", "requested"] as const;

/**
 * URLs das execuções de run-demand.yml ainda não concluídas deste cliente
 * (pelo título "Rodar demanda <slug> <ID>", o run-name do workflow).
 */
export async function runsAtivosDoCliente(clientSlug: string): Promise<string[]> {
  const gh = octokit();
  const { owner, repo } = repoConfig();
  const urls: string[] = [];
  for (const status of ESTADOS_ATIVOS) {
    const r = await gh.actions.listWorkflowRuns({ owner, repo, workflow_id: "run-demand.yml", status, per_page: 50 });
    for (const run of r.data.workflow_runs) {
      if ((run.display_title ?? "").startsWith(`Rodar demanda ${clientSlug} `)) urls.push(run.html_url);
    }
  }
  return urls;
}

export interface RunAtivo {
  url: string;
  clientSlug: string;
  demandaCode: string;
  status: string;
  criadoEm: string;
}

/** Todas as execuções de run-demand.yml não concluídas, de qualquer cliente. */
export async function runsAtivosDaEsteira(): Promise<RunAtivo[]> {
  const gh = octokit();
  const { owner, repo } = repoConfig();
  const runs: RunAtivo[] = [];
  for (const status of ESTADOS_ATIVOS) {
    const r = await gh.actions.listWorkflowRuns({ owner, repo, workflow_id: "run-demand.yml", status, per_page: 50 });
    for (const run of r.data.workflow_runs) {
      const m = /^Rodar demanda (\S+) (\S+)$/.exec(run.display_title ?? "");
      if (m) runs.push({ url: run.html_url, clientSlug: m[1], demandaCode: m[2], status: run.status ?? status, criadoEm: run.created_at });
    }
  }
  return runs;
}
