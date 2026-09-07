"""Telemetria de custo por invocação de agente.

Pré-requisito pra qualquer decisão futura de roteamento de modelo, caching ou
Batch API — sem isso, "otimizar custo" é achismo com planilha (council de
2026-09-07, ver `CLAUDE.md` § Seleção de modelo por agente). Só grava
metadata e contagens de token, nunca conteúdo da demanda: mesmo guardrail de
LGPD que vale pro resto do projeto (`CLAUDE.md` guardrail #2).
"""

from __future__ import annotations

import csv
from collections.abc import Iterator
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_PATH = Path("logs/custos_agentes.csv")

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


def log_usage(client: str, demand_id: str, etapa: str, result: Any) -> None:
    """Registra o custo/uso de uma sessão de agente.

    `result` é o `ResultMessage` final do Claude Agent SDK (ou qualquer
    objeto com os mesmos atributos: `session_id`, `duration_ms`, `num_turns`,
    `is_error`, `model_usage`, `usage`, `total_cost_usd`). Uma linha por
    modelo usado na sessão — uma demanda que passar por um único sub-agente
    gera uma linha; se o orquestrador e o sub-agente usarem modelos
    diferentes, gera uma linha por modelo.
    """
    rows = list(_rows_from_result(client, demand_id, etapa, result))
    if rows:
        _append_rows(rows)


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


def _append_rows(rows: list[dict[str, Any]]) -> None:
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    is_new = not LOG_PATH.exists()
    with LOG_PATH.open("a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        if is_new:
            writer.writeheader()
        writer.writerows(rows)
