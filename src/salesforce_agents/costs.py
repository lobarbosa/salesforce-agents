"""Telemetria de custo por invocação de agente.

Pré-requisito pra qualquer decisão futura de roteamento de modelo, caching ou
Batch API — sem isso, "otimizar custo" é achismo com planilha (council de
2026-09-07, ver `CLAUDE.md` § Seleção de modelo por agente). Só grava
metadata e contagens de token, nunca conteúdo da demanda: mesmo guardrail de
LGPD que vale pro resto do projeto (`CLAUDE.md` guardrail #2).

Um arquivo por sessão, nunca um CSV único crescendo (`logs/custos_agentes/`,
não `logs/custos_agentes.csv`) — achado real do council de 2026-10-01: dois
`run-demand.yml` de clientes diferentes, cada um na própria branch
`feature/<DEMAND-ID>`, appendando no fim do mesmo arquivo único, gera
conflito de merge quando os PRs batem na mesma região do arquivo (aconteceu
de verdade entre os PRs de somos-agility e eplast). Arquivo por sessão quebra
isso na raiz: cada branch só ADICIONA um arquivo novo e exclusivo, nunca edita
um que outra branch também toca — merge de qualquer quantidade de PRs, em
qualquer ordem, nunca conflita aqui. `ler_todas_as_linhas()` concatena tudo
pra quem precisa do agregado (skill `revisar-custos`).
"""

from __future__ import annotations

import csv
import re
from collections.abc import Iterator
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_DIR = Path("logs/custos_agentes")

# Arquivo único antigo, de antes desta mudança — só lido (histórico), nunca
# mais escrito. Sem isso a telemetria já gravada em produção desapareceria da
# agregação no dia em que este código for atualizado.
LOG_PATH_LEGADO = Path("logs/custos_agentes.csv")

FIELDS = [
    "timestamp",
    "client",
    "demand_id",
    "etapa",
    "session_id",
    "model",
    "input_tokens",
    "output_tokens",
    "cache_read_tokens",
    "cache_creation_tokens",
    "cost_usd",
    "duration_ms",
    "num_turns",
    "is_error",
]

_SANITIZAR = re.compile(r"[^A-Za-z0-9_.-]+")


def _slug(valor: str) -> str:
    return _SANITIZAR.sub("_", valor).strip("_") or "x"


def log_usage(client: str, demand_id: str, etapa: str, result: Any) -> None:
    """Registra o custo/uso de uma sessão de agente.

    `result` é o `ResultMessage` final do Claude Agent SDK (ou qualquer
    objeto com os mesmos atributos: `session_id`, `duration_ms`, `num_turns`,
    `is_error`, `model_usage`, `usage`, `total_cost_usd`). Uma linha por
    modelo usado na sessão — uma demanda que passar por um único sub-agente
    gera uma linha; se o orquestrador e o sub-agente usarem modelos
    diferentes, gera uma linha por modelo. Todas as linhas de uma mesma
    sessão vão pro mesmo arquivo (uma sessão não se divide entre arquivos).
    """
    rows = list(_rows_from_result(client, demand_id, etapa, result))
    if rows:
        _write_session_file(client, demand_id, etapa, getattr(result, "session_id", ""), rows)


def _rows_from_result(
    client: str, demand_id: str, etapa: str, result: Any
) -> Iterator[dict[str, Any]]:
    base = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "client": client,
        "demand_id": demand_id,
        "etapa": etapa,
        "session_id": getattr(result, "session_id", ""),
        "duration_ms": getattr(result, "duration_ms", ""),
        "num_turns": getattr(result, "num_turns", ""),
        "is_error": getattr(result, "is_error", ""),
    }

    model_usage = getattr(result, "model_usage", None)
    if model_usage:
        for model, mu in model_usage.items():
            yield {
                **base,
                "model": model,
                "input_tokens": mu.get("inputTokens", ""),
                "output_tokens": mu.get("outputTokens", ""),
                "cache_read_tokens": mu.get("cacheReadInputTokens", ""),
                "cache_creation_tokens": mu.get("cacheCreationInputTokens", ""),
                "cost_usd": mu.get("costUSD", ""),
            }
        return

    # Fallback pra SDKs sem `model_usage`: uma linha agregada a partir de
    # `usage`/`total_cost_usd`, sem quebra por modelo.
    usage = getattr(result, "usage", None) or {}
    yield {
        **base,
        "model": "desconhecido",
        "input_tokens": usage.get("input_tokens", ""),
        "output_tokens": usage.get("output_tokens", ""),
        "cache_read_tokens": usage.get("cache_read_input_tokens", ""),
        "cache_creation_tokens": usage.get("cache_creation_input_tokens", ""),
        "cost_usd": getattr(result, "total_cost_usd", ""),
    }


def _write_session_file(
    client: str, demand_id: str, etapa: str, session_id: str, rows: list[dict[str, Any]]
) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    nome = "__".join(_slug(p) for p in (client, demand_id, etapa, session_id or "sem-sessao"))
    caminho = LOG_DIR / f"{nome}.csv"
    with caminho.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def ler_todas_as_linhas() -> Iterator[dict[str, str]]:
    """Todas as linhas de telemetria já gravadas — arquivo legado + um por sessão.

    Usado por quem precisa do agregado (skill `revisar-custos`) sem se
    importar com o layout em disco.
    """
    if LOG_PATH_LEGADO.exists():
        with LOG_PATH_LEGADO.open(encoding="utf-8") as f:
            yield from csv.DictReader(f)

    if LOG_DIR.exists():
        for caminho in sorted(LOG_DIR.glob("*.csv")):
            with caminho.open(encoding="utf-8") as f:
                yield from csv.DictReader(f)
