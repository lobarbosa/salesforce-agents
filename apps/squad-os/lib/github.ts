import { Octokit } from "@octokit/rest";
import { dump as dumpYaml } from "js-yaml";

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

export async function materializeDemanda(d: DemandaParaMaterializar) {
  const base = `clients/${d.clientSlug}/demandas/${d.code}`;

  const demandaMd = `# ${d.titulo}\n\n${d.texto}\n`;
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
  opts: { aprovarGate?: string } = {}
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
