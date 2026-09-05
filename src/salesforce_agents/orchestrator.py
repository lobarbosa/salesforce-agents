"""Orquestrador: lê a spec de um cliente e delega para os agentes especialistas."""

from __future__ import annotations

import anyio
from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    ResultMessage,
    TextBlock,
)

from .agents import SPECIALISTS
from .tools import salesforce_tools_server

ORCHESTRATOR_SYSTEM_PROMPT = """\
Você orquestra a implementação de uma solução Salesforce para um cliente, a
partir de uma spec de requisitos. Seu workspace é clients/<client>/.

Fluxo obrigatório:
1. Leia a spec inteira (ferramenta spec_read) antes de qualquer implementação.
2. Delegue ao subagente 'solution-architect' para obter o plano de
   implementação (data model, declarativo vs. código, riscos).
3. Execute o plano delegando cada parte ao especialista certo:
   'declarative-builder' para Flow/config, 'apex-developer' para Apex,
   'lwc-developer' para Lightning Web Components.
4. Ao final, resuma o que foi implementado, o que ficou pendente e, se
   deploy foi solicitado, o resultado do 'sf_deploy'.

Nunca invente metadata que não foi pedido na spec. Se a spec for ambígua,
registre a suposição feita e siga em frente — não pare o fluxo esperando
resposta humana.
"""


async def run(spec_path: str, client: str, deploy: bool = False) -> None:
    workspace = f"clients/{client}"
    deploy_note = (
        f"Ao final, faça deploy via sf_deploy para o org de alias '{client}' "
        f"(target_org='{client}')." if deploy
        else "Não faça deploy — apenas gere os arquivos de metadata localmente."
    )

    options = ClaudeAgentOptions(
        system_prompt=ORCHESTRATOR_SYSTEM_PROMPT,
        cwd=workspace,
        mcp_servers={"salesforce-tools": salesforce_tools_server},
        agents=SPECIALISTS,
        allowed_tools=[
            "Read", "Write", "Edit", "Grep", "Glob", "Task",
            "mcp__salesforce-tools__spec_read",
            "mcp__salesforce-tools__sf_deploy",
            "mcp__salesforce-tools__sf_retrieve",
            "mcp__salesforce-tools__sf_query",
            "mcp__salesforce-tools__sf_org_list",
        ],
        permission_mode="acceptEdits",
    )

    prompt = (
        f"Implemente a spec do cliente '{client}' localizada em '{spec_path}' "
        f"(caminho absoluto ou relativo ao diretório atual, não a {workspace}). "
        f"{deploy_note}"
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


def run_sync(spec_path: str, client: str, deploy: bool = False) -> None:
    anyio.run(run, spec_path, client, deploy)
