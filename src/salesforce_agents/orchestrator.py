"""Orquestrador: aciona os agentes de .claude/agents para uma demanda de cliente.

Os agentes, skills, hooks e guardrails vivem no scaffold do projeto (.claude/ na raiz
do repo + CLAUDE.md em cada nível), carregados automaticamente pelo Claude Agent SDK
via setting_sources=["project"]. Este módulo só decide quando disparar uma sessão e
em qual workspace de cliente.
"""

from __future__ import annotations

import anyio
from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    ResultMessage,
    TextBlock,
)

from .costs import log_usage
from .tools import salesforce_tools_server

ALLOWED_TOOLS = [
    "Read", "Write", "Edit", "Grep", "Glob", "Bash", "Task",
    "mcp__salesforce-tools__spec_read",
    "mcp__salesforce-tools__sf_deploy",
    "mcp__salesforce-tools__sf_retrieve",
    "mcp__salesforce-tools__sf_query",
    "mcp__salesforce-tools__sf_org_list",
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


async def run(client: str, demand_id: str, etapa: str) -> None:
    workspace = f"clients/{client}"

    options = ClaudeAgentOptions(
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
        mcp_servers={"salesforce-tools": salesforce_tools_server},
        allowed_tools=ALLOWED_TOOLS,
        permission_mode="acceptEdits",
    )

    prompt = (
        f"Continue o ciclo de delivery da demanda {demand_id} do cliente {client}. "
        f"A história está em demandas/{demand_id}/demanda.md e o estágio atual em "
        f"demandas/{demand_id}/status.yaml. Siga o fluxo canônico descrito em CLAUDE.md "
        f"a partir do estágio atual, acionando o subagente correspondente via Task, e "
        f"pare no próximo gate humano."
    )

    async with ClaudeSDKClient(options=options) as client_sdk:
        await client_sdk.query(prompt)
        async for message in client_sdk.receive_response():
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        print(block.text)
            elif isinstance(message, ResultMessage):
                print(f"\n--- concluído (custo: ${message.total_cost_usd:.4f}) ---")
                log_usage(client, demand_id, etapa, message)


def run_sync(client: str, demand_id: str, etapa: str) -> None:
    anyio.run(run, client, demand_id, etapa)
