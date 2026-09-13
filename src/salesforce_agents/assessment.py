"""Assessment de org: o diagnóstico que antecede a primeira demanda do cliente.

Fica separado de `orchestrator.py` porque não é uma etapa de demanda — é por
cliente, roda uma vez no onboarding (e de novo quando a org mudar muito), e não
tem `status.yaml` nem gate. Compartilha o resto: mesmo workspace, mesmas
skills, mesma telemetria de custo.

Read-only por construção, em três camadas: o agente é instruído a não escrever
na org, a lista de ferramentas abaixo não inclui `sf_deploy`, e o hook
`guard-prod.sh` continua valendo. A primeira camada é instrução (um modelo pode
ignorar), a segunda é mecânica.
"""

from __future__ import annotations

import json
from pathlib import Path


# Sem `sf_deploy`: o assessment não altera a org, e tirar a ferramenta é mais
# forte do que pedir por escrito que não use.
ALLOWED_TOOLS = [
    "Read", "Write", "Edit", "Grep", "Glob", "Bash", "Task",
    "mcp__salesforce-tools__sf_retrieve",
    "mcp__salesforce-tools__sf_query",
    "mcp__salesforce-tools__sf_org_list",
]

# `demand_id` no log de custo — o assessment não tem demanda, e deixar vazio
# faria a coluna parecer dado faltando em vez de "não se aplica".
DEMAND_ID_SENTINELA = "-assessment-"

ETAPA = "assessment"


class AssessmentError(Exception):
    pass


def caminho_json(client: str) -> Path:
    return Path("clients") / client / "assessment.json"


def caminho_md(client: str) -> Path:
    return Path("clients") / client / "assessment.md"


def ler_resultado(client: str) -> dict:
    """Lê e valida o assessment.json que o agente gravou.

    Valida aqui, e não só no app, porque é aqui que dá pra falhar o job: um
    JSON malformado que chegasse ao Squad OS viraria um perfil de cliente
    mostrando "saúde: undefined" sem ninguém saber por quê.
    """
    caminho = caminho_json(client)
    if not caminho.exists():
        raise AssessmentError(
            f"{caminho} não existe — o agente não produziu o resultado estruturado. "
            f"Sem ele o Squad OS não tem o que mostrar no perfil do cliente."
        )
    try:
        dados = json.loads(caminho.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise AssessmentError(f"{caminho} não é JSON válido: {exc}") from exc

    saude = dados.get("saude")
    if saude not in ("verde", "amarelo", "vermelho"):
        raise AssessmentError(
            f"{caminho}: 'saude' precisa ser verde, amarelo ou vermelho — veio {saude!r}."
        )
    if not isinstance(dados.get("recomendacoes", []), list):
        raise AssessmentError(f"{caminho}: 'recomendacoes' precisa ser uma lista.")
    if not str(dados.get("resumo", "")).strip():
        raise AssessmentError(f"{caminho}: 'resumo' está vazio.")

    if not caminho_md(client).exists():
        raise AssessmentError(
            f"{caminho_md(client)} não existe — o relatório longo é o que sustenta o "
            f"resumo; sem ele o perfil mostra conclusão sem evidência."
        )

    return dados


def pendencias(client: str) -> list[str]:
    """O que ainda falta para este assessment estar entregue, em texto de log.

    Usado como critério de parada da sessão (`sessao.rodar`) e não só como
    validação no fim: um `assessment.json` ausente — ou presente e inválido — é
    cobrável enquanto o agente ainda está na linha, e é isso que evita a sessão
    terminar em "vou avisar quando estiver pronto".
    """
    try:
        ler_resultado(client)
    except AssessmentError as exc:
        return [str(exc)]
    return []


async def run(client: str, target_org: str) -> None:
    # Import tardio: o Claude Agent SDK só é necessário pra rodar o agente. As
    # funções de validação deste módulo são puras e precisam ser testáveis sem
    # ele — mesma disciplina do `orchestrator` na CLI.
    from claude_agent_sdk import ClaudeAgentOptions

    from . import sessao
    from .costs import log_usage
    from .tools import salesforce_tools_server

    workspace = f"clients/{client}"

    options = ClaudeAgentOptions(
        cwd=workspace,
        # Mesma escolha do orquestrador de demanda: Sonnet na sessão que
        # coordena, e o sub-agente segue o `model:` do próprio frontmatter
        # (org-assessment declara sonnet). Ver CLAUDE.md § Seleção de modelo.
        model="claude-sonnet-5",
        setting_sources=["project"],
        mcp_servers={"salesforce-tools": salesforce_tools_server},
        allowed_tools=ALLOWED_TOOLS,
        permission_mode="acceptEdits",
    )

    prompt = (
        f"Faça o assessment de saúde da org Salesforce do cliente {client}, acionando o "
        f"subagente `org-assessment` via Task e **esperando ele terminar**. O alias da org "
        f"é `{target_org}` — é uma sandbox de desenvolvimento, e o assessment é read-only: "
        f"nada na org pode ser alterado. Entregue `assessment.md` e `assessment.json` na "
        f"raiz deste workspace, exatamente no formato descrito em "
        f".claude/agents/org-assessment.md. Nenhum dado pessoal ou de negócio do cliente "
        f"pode entrar no relatório — só metadata e contagens agregadas.\n\n"
        f"{sessao.CONTRATO_DA_SESSAO}"
    )

    def registrar(message) -> None:
        print(f"\n--- turno concluído (custo: ${message.total_cost_usd:.4f}) ---")
        log_usage(client, DEMAND_ID_SENTINELA, ETAPA, message)

    await sessao.rodar(
        options,
        prompt,
        conferir=lambda: pendencias(client),
        ao_terminar=registrar,
    )


def run_sync(client: str, target_org: str) -> None:
    import anyio

    anyio.run(run, client, target_org)
