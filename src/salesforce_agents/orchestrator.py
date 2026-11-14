"""Orquestrador: aciona os agentes de .claude/agents para uma demanda de cliente.

Os agentes, skills, hooks e guardrails vivem no scaffold do projeto (.claude/ na raiz
do repo + CLAUDE.md em cada nível), carregados automaticamente pelo Claude Agent SDK
via setting_sources=["project"]. Este módulo só decide quando disparar uma sessão e
em qual workspace de cliente.
"""

from __future__ import annotations

from pathlib import Path

import anyio
from claude_agent_sdk import ClaudeAgentOptions

from . import anexos, ao_vivo, assessment, comentarios, demands, sessao
from .costs import log_usage
from .rag import criar_rag_tools_server
from .tools import salesforce_tools_server

ALLOWED_TOOLS = [
    "Read", "Write", "Edit", "Grep", "Glob", "Bash", "Task",
    "mcp__salesforce-tools__spec_read",
    "mcp__salesforce-tools__sf_deploy",
    "mcp__salesforce-tools__sf_retrieve",
    "mcp__salesforce-tools__sf_query",
    "mcp__salesforce-tools__sf_org_list",
    "mcp__salesforce-tools__qa_browser_open",
    "mcp__salesforce-tools__qa_browser_click",
    "mcp__salesforce-tools__qa_browser_fill",
    "mcp__salesforce-tools__qa_browser_screenshot",
    "mcp__salesforce-tools__qa_browser_close",
    "mcp__rag__rag_consultar",
]

# Note on permissions in headless runs: this grants whole tools (Bash included) at
# the SDK level, which is what lets an unattended session run without a human to
# answer an interactive prompt. That deliberately makes .claude/settings.json's
# fine-grained `allow` list redundant here — and redundant is fine, because it was
# never the safety boundary. Verified empirically (2026-09-06, untrusted workspace):
# the `deny` list (e.g. `git merge*`) and the guard-prod.sh PreToolUse hook both
# still fire and block regardless of workspace trust; only `allow` entries are
# ignored when untrusted, and this module never relied on them. Do not "fix" the
# workspace-trust warning by loosening this — it isn't gating anything that matters.


# Quem roda cada etapa. Vai no prompt para o orquestrador não gastar turnos
# lendo status.yaml e o fluxo para descobrir o que o fluxo.py já sabe.
SUBAGENTE_DA_ETAPA = {
    "analise": "O subagente desta etapa é `ba-discovery`.",
    "design": "O subagente desta etapa é `arquiteto` (ele faz o recon com a skill `org-recon` antes de desenhar).",
    "build": (
        "O subagente desta etapa é `builder-declarativo` quando o `03-design.md` decide por "
        "configuração/Flow, ou `dev-apex` quando decide por código — leia só a seção de decisão do design para escolher."
    ),
    "qa": "O subagente desta etapa é `qa`.",
    "release": "Os subagentes desta etapa são `release` e, em seguida, `doc`.",
}


def _quem_roda(etapa: str) -> str:
    return SUBAGENTE_DA_ETAPA.get(etapa, "Acione o subagente da etapa conforme o fluxo do CLAUDE.md.")


# 93% dos tokens da esteira são releitura de contexto (medido em 2026-11-14):
# tudo o que entra numa sessão é relido a cada turno. Estas regras valem para o
# orquestrador e são repassadas ao subagente no briefing.
ECONOMIA_DE_CONTEXTO = (
    "Economia de contexto (tudo o que você lê é relido e cobrado a cada turno seguinte):\n"
    "- Você é só o roteador: não leia os artefatos da demanda nem refaça o trabalho do "
    "subagente. Passe a ele este briefing inteiro e, quando ele voltar, confira apenas que "
    "os arquivos da etapa existem.\n"
    "- Repasse ao subagente: ler só o que a etapa precisa; usar `rag_consultar` ou Grep para "
    "achar um trecho em vez de abrir arquivo inteiro (assessment, designs antigos, demandas "
    "anteriores); não reler arquivo já lido na sessão; em `sf`, pedir campos e metadata "
    "específicos, com LIMIT, e nunca despejar describe ou retrieve inteiro na conversa; "
    "devolver ao final um resumo de poucas linhas, não o conteúdo do artefato.\n\n"
)


async def run(client: str, demand_id: str, etapa: str) -> None:
    workspace = f"clients/{client}"

    options = ClaudeAgentOptions(
        # Ver sessao.MAX_BUFFER_MENSAGEM.
        max_buffer_size=sessao.MAX_BUFFER_MENSAGEM,
        cwd=workspace,
        # Sem `model` explícito a sessão orquestradora herda o default (Opus 1M)
        # em todas as 7 etapas. Isso custava caro e, pior, cegava a telemetria:
        # `costs.py` grava uma linha por modelo, então o orquestrador Opus e o
        # arquiteto (`model: opus` no frontmatter) colapsavam na mesma linha —
        # impossível saber quanto foi decisão de arquitetura e quanto foi o loop
        # relendo CLAUDE.md. Com Sonnet aqui, os dois passam a ser linhas
        # distintas. Os subagentes seguem o frontmatter e não são afetados.
        model="claude-sonnet-5",
        setting_sources=["project"],
        # O servidor de RAG nasce aqui, por sessão, fechado sobre `client` — ao
        # contrário de salesforce_tools_server (singleton de módulo, sem
        # noção de cliente nenhuma). É de propósito: rag_consultar não tem
        # como um agente pedir dado de outro cliente, porque `client` nunca
        # foi argumento de ferramenta nenhuma (ver rag.py).
        mcp_servers={
            "salesforce-tools": salesforce_tools_server,
            "rag": criar_rag_tools_server(client),
        },
        allowed_tools=ALLOWED_TOOLS,
        permission_mode="acceptEdits",
    )

    # Os artefatos que esta etapa deve deixar no disco são os mesmos que
    # `demands.transition` vai exigir logo depois para deixar o status avançar.
    # Ler da mesma fonte é o que impede a sessão cobrar uma coisa e a transição
    # recusar por outra.
    pasta_da_demanda = Path("clients") / client / "demandas" / demand_id
    esperados = [
        Path("clients") / client / "demandas" / demand_id / nome
        for nome in demands.REQUIRED_ARTIFACTS.get(etapa, ())
    ]

    prompt = (
        f"Demanda {demand_id} do cliente {client}, etapa **{etapa}** (pasta "
        f"demandas/{demand_id}/). {_quem_roda(etapa)} Acione-o via Task, **espere ele "
        f"terminar** e pare: depois desta etapa vem um gate humano.\n\n"
        f"{ECONOMIA_DE_CONTEXTO}"
        f"{assessment.nota_para_o_prompt(client)}"
        f"{anexos.nota_para_o_prompt(client, demand_id)}"
        f"{comentarios.nota_para_o_prompt(client, demand_id)}"
        f"{sessao.CONTRATO_DA_SESSAO}"
    )

    with ao_vivo.Emissor(client, demand_id, etapa) as vivo:

        def registrar(message) -> None:
            print(f"\n--- turno concluído (custo: ${message.total_cost_usd:.4f}) ---")
            log_usage(client, demand_id, etapa, message)
            vivo.turno(message.total_cost_usd)

        await sessao.rodar(
            options,
            prompt,
            conferir=lambda: sessao.faltantes(esperados) + sessao.pii_nos_artefatos(pasta_da_demanda),
            ao_terminar=registrar,
            ao_usar_ferramenta=vivo.ferramenta,
        )


def run_sync(client: str, demand_id: str, etapa: str) -> None:
    anyio.run(run, client, demand_id, etapa)
