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

from .tools import salesforce_tools_server

ALLOWED_TOOLS = [
    "Read", "Write", "Edit", "Grep", "Glob", "Bash", "Task",
    "mcp__salesforce-tools__spec_read",
    "mcp__salesforce-tools__sf_deploy",
    "mcp__salesforce-tools__sf_retrieve",
    "mcp__salesforce-tools__sf_query",
    "mcp__salesforce-tools__sf_org_list",
]


async def run(client: str, demand_id: str) -> None:
    workspace = f"clients/{client}"

    options = ClaudeAgentOptions(
        cwd=workspace,
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


def run_sync(client: str, demand_id: str) -> None:
    anyio.run(run, client, demand_id)
