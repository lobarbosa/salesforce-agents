"""Guardrail #1 em tempo de execução: para onde um comando `sf` pode apontar.

Mora aqui, e não em `tools.py`, por dois motivos. O primeiro é testabilidade:
`tools.py` importa o Claude Agent SDK no topo (os decoradores `@tool` rodam na
importação), então nada lá é testável sem o SDK instalado — e esta é a última
camada antes de escrever numa org de cliente, justamente o código que mais
precisa de teste. O segundo é que a regra não é das ferramentas MCP: é da
esteira, e qualquer caminho que monte comando `sf` deve passar por aqui.

**Por que existe além do hook.** `.claude/hooks/guard-prod.sh` é PreToolUse do
Bash e só enxerga o que passa pela ferramenta Bash. As ferramentas `sf_*`
chamam `sf` por subprocess, de dentro do Python — o hook nunca dispara nesse
caminho. Achado do council de 2026-09-11.

**Duas perguntas diferentes, as duas necessárias:**

1. O alias tem a forma da esteira? — `alias_permitido`, offline, sem custo.
2. A org **é** sandbox? — `Organization.IsSandbox`, uma chamada à org.

A (1) sozinha era o que existia, e é convenção de nome: uma org de produção
autenticada como `sbx-acxya-dev` passava limpo. A (2) é o destino de verdade —
a org se declarando. O nome nunca foi o problema; o destino sempre foi.
"""

from __future__ import annotations

import json
import subprocess

from .ambientes import alias_permitido


class CliAusenteError(Exception):
    """`sf` não está no PATH."""


def sf(args: list[str], timeout: int = 600) -> subprocess.CompletedProcess[str]:
    """Executa a Salesforce CLI. Único ponto do pacote que monta `sf` de verdade."""
    try:
        return subprocess.run(
            ["sf", *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as exc:
        raise CliAusenteError from exc


# Alias já confirmado como sandbox nesta sessão. Só o positivo é cacheado: uma
# falha de rede não pode virar "org liberada" pelo resto da sessão, e um alias
# não muda de org no meio de um job.
_SANDBOX_CONFIRMADA: set[str] = set()


def recusa_de_alias(target_org: str) -> str | None:
    """Pergunta 1. None quando o alias passa; senão, o motivo em texto."""
    alias = (target_org or "").strip()
    if alias_permitido(alias):
        return None
    return (
        f"Alias recusado: {alias!r}. A esteira só toca org cujo alias tenha a forma "
        f"`sbx-<cliente>-dev` ou `sbx-<cliente>-qa` (guardrail #1). Isto é uma "
        f"allowlist: não basta o alias não parecer de produção — ele precisa ser um "
        f"dos dois ambientes da esteira."
    )


def recusa_de_escrita(target_org: str, *, executor=None) -> str | None:
    """Perguntas 1 e 2. None quando a org está liberada para escrita.

    `executor` existe para teste: recebe a lista de argumentos e devolve algo
    com `.stdout`/`.stderr`/`.returncode`. Em produção é a `sf` de verdade.
    """
    alias = (target_org or "").strip()
    recusa = recusa_de_alias(alias)
    if recusa:
        return recusa
    if alias in _SANDBOX_CONFIRMADA:
        return None

    run = executor or sf
    try:
        # Só metadata: a consulta devolve um booleano, nenhum dado de negócio
        # (guardrail #2).
        proc = run([
            "data", "query",
            "--query", "SELECT IsSandbox FROM Organization",
            "--target-org", alias,
            "--json",
        ])
    except CliAusenteError:
        return (
            "Salesforce CLI ('sf') não encontrada no PATH — não dá pra confirmar que "
            f"{alias} é sandbox, e sem confirmar não se escreve na org."
        )

    try:
        is_sandbox = json.loads(proc.stdout or "{}")["result"]["records"][0]["IsSandbox"]
    except (json.JSONDecodeError, KeyError, IndexError, TypeError):
        erro = (proc.stderr or proc.stdout or "").strip()[:400]
        return (
            f"Não consegui confirmar se {alias} é sandbox (a consulta a Organization não "
            f"respondeu o esperado). Na dúvida, não escrevo. Saída: {erro or 'vazia'}"
        )

    if is_sandbox is not True:
        return (
            f"RECUSADO: a org autenticada como {alias} responde IsSandbox=false — é uma "
            f"org de produção com nome de sandbox. Nenhum agente escreve em produção "
            f"(guardrail #1). Confira em qual org o alias está autenticado antes de "
            f"qualquer outra coisa: org errada é o erro mais caro desta operação."
        )

    _SANDBOX_CONFIRMADA.add(alias)
    return None
