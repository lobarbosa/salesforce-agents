"""Planejador: entregáveis contratados viram demandas propostas.

Mesmo formato do `assessment.py` — é por cliente, não por demanda, não tem
`status.yaml` nem gate, e termina num arquivo que o Squad OS lê. A diferença é
o sentido: o assessment olha pra org, isto olha pro contrato.

Sem ferramenta de org: o planejador não consulta Salesforce. O que existe na
org é assunto do recon, na etapa 2 do fluxo, com o `sf` CLI — e uma proposta de
demanda que afirma o que existe na org sem ter olhado é exatamente o tipo de
invenção que o guardrail #3 proíbe.
"""

from __future__ import annotations

import json
from pathlib import Path


# Nem `sf_deploy` nem `sf_query`: o planejador lê contrato e briefing, não org.
ALLOWED_TOOLS = ["Read", "Write", "Edit", "Grep", "Glob", "Task"]

DEMAND_ID_SENTINELA = "-planejamento-"
ETAPA = "planejamento"

# Teto de sanidade. Um projeto que gera mais que isso de uma vez não foi
# quebrado, foi picotado — e despejar 200 cartões num quadro que ninguém
# revisou é pior que não ter plano nenhum.
MAX_DEMANDAS = 60


class PlanejamentoError(Exception):
    pass


def caminho_plano(client: str) -> Path:
    return Path("clients") / client / "plano-demandas.json"


def caminho_contrato(client: str) -> Path:
    return Path("clients") / client / "contrato.md"


def ler_plano(client: str, entregaveis_validos: set[str] | None = None) -> dict:
    """Lê e valida o plano que o agente gravou.

    Valida aqui, onde dá pra falhar o job: um plano malformado que chegasse ao
    Squad OS viraria cartão vazio no quadro de um cliente, e alguém teria que
    limpar à mão.
    """
    caminho = caminho_plano(client)
    if not caminho.exists():
        raise PlanejamentoError(
            f"{caminho} não existe — o agente não produziu o plano. Sem ele não há o "
            f"que mandar pro quadro."
        )
    try:
        dados = json.loads(caminho.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise PlanejamentoError(f"{caminho} não é JSON válido: {exc}") from exc

    demandas = dados.get("demandas")
    if not isinstance(demandas, list) or not demandas:
        raise PlanejamentoError(f"{caminho}: 'demandas' precisa ser uma lista não vazia.")
    if len(demandas) > MAX_DEMANDAS:
        raise PlanejamentoError(
            f"{caminho}: {len(demandas)} demandas passa do teto de {MAX_DEMANDAS}. "
            f"O entregável provavelmente foi picotado em vez de quebrado."
        )

    for i, d in enumerate(demandas, 1):
        if not isinstance(d, dict):
            raise PlanejamentoError(f"{caminho}: demanda #{i} não é um objeto.")
        if not str(d.get("titulo", "")).strip():
            raise PlanejamentoError(f"{caminho}: demanda #{i} está sem título.")
        eid = str(d.get("entregavelId", "")).strip()
        if not eid:
            raise PlanejamentoError(
                f"{caminho}: demanda #{i} ('{d.get('titulo')}') não aponta pra entregável "
                f"nenhum — seria escopo que ninguém vendeu."
            )
        # Só confere contra a lista real quando ela foi passada (no CI ela é).
        if entregaveis_validos is not None and eid not in entregaveis_validos:
            raise PlanejamentoError(
                f"{caminho}: demanda #{i} aponta pro entregável '{eid}', que não está no "
                f"contrato. O agente inventou o id."
            )

    dados["cliente"] = client
    return dados


async def run(client: str) -> None:
    # Import tardio: o Claude Agent SDK só é necessário pra rodar o agente. As
    # funções de validação deste módulo são puras e precisam ser testáveis sem
    # ele — mesma disciplina do `orchestrator` na CLI.
    from claude_agent_sdk import (
        AssistantMessage,
        ClaudeAgentOptions,
        ClaudeSDKClient,
        ResultMessage,
        TextBlock,
    )

    from .costs import log_usage

    workspace = f"clients/{client}"
    if not caminho_contrato(client).exists():
        raise PlanejamentoError(
            f"{caminho_contrato(client)} não existe — o contrato precisa ser materializado "
            f"pelo Squad OS antes de planejar."
        )

    options = ClaudeAgentOptions(
        cwd=workspace,
        model="claude-sonnet-5",
        setting_sources=["project"],
        allowed_tools=ALLOWED_TOOLS,
        permission_mode="acceptEdits",
    )

    prompt = (
        f"Gere o plano de demandas do projeto do cliente {client}, acionando o subagente "
        f"`planejador` via Task. O contrato e os entregáveis estão em `contrato.md` na raiz "
        f"deste workspace, e o briefing da conta em `CLAUDE.md`. Entregue "
        f"`plano-demandas.json` exatamente no formato descrito em "
        f".claude/agents/planejador.md. Cada demanda precisa apontar pra um `entregavelId` "
        f"que exista no contrato — não invente id. Não decida declarativo vs. código: isso é "
        f"do arquiteto, no gate bloqueante."
    )

    async with ClaudeSDKClient(options=options) as sdk:
        await sdk.query(prompt)
        async for message in sdk.receive_response():
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        print(block.text)
            elif isinstance(message, ResultMessage):
                print(f"\n--- plano concluído (custo: ${message.total_cost_usd:.4f}) ---")
                log_usage(client, DEMAND_ID_SENTINELA, ETAPA, message)


def run_sync(client: str) -> None:
    import anyio

    anyio.run(run, client)
