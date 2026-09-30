"""RAG interno por cliente — base de conhecimento pro pipeline de agentes.

Nunca o copiloto do cliente em Squad OS (CLAUDE.md guardrail #2): o corpus
inclui demanda.md, artefatos de gate e briefing de conta, que é dado interno
de delivery, não algo que o cliente final acessa.

`criar_rag_tools_server(client)` é uma factory, não um servidor estático como
`salesforce_tools_server` em tools.py — o cliente vem do orchestrator (o mesmo
workspace da sessão), nunca de um argumento que o agente escolhe. É o que
impede a ferramenta de consultar o RAG de outro cliente mesmo que o prompt
seja manipulado pra pedir isso (guardrail #7, "nunca misture clientes") — a
pergunta "de qual cliente?" nunca chega a existir pro agente, igual ao
copiloto do cliente em Squad OS (lib/copilot/ferramentas.ts).

A ingestão (escrever no RAG) não é uma ferramenta de agente — acontece depois
que o job já commitou os artefatos, via curl no workflow (run-demand.yml),
igual aos outros /api/sync/*. Só a consulta (leitura) precisa estar disponível
DURANTE a sessão, que é por isso que ela — e só ela — vira ferramenta aqui.
"""

from __future__ import annotations

import json
import os
from urllib import error, request as urlrequest

from claude_agent_sdk import create_sdk_mcp_server, tool


def _text_result(text: str) -> dict:
    return {"content": [{"type": "text", "text": text}]}


def _post(url: str, token: str, payload: dict, timeout: float = 30.0) -> dict:
    corpo = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(
        url,
        data=corpo,
        method="POST",
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"},
    )
    with urlrequest.urlopen(req, timeout=timeout) as resp:  # noqa: S310 — URL vem de env, não de entrada do agente
        return json.loads(resp.read().decode("utf-8"))


def criar_rag_tools_server(client: str):
    @tool(
        "rag_consultar",
        "Busca trechos relevantes na base de conhecimento interna deste cliente "
        "(demandas anteriores, briefing de conta, assessment da org) — útil pra achar "
        "contexto histórico antes de analisar ou desenhar algo. Enxerga só este cliente; "
        "não tem como pedir dado de outro.",
        {"pergunta": str},
    )
    async def rag_consultar(args: dict) -> dict:
        url = os.environ.get("SQUAD_OS_RAG_QUERY_URL", "")
        token = os.environ.get("SQUAD_OS_SYNC_TOKEN", "")
        if not url or not token:
            return _text_result(
                "RAG não configurado nesta sessão (falta SQUAD_OS_RAG_QUERY_URL ou "
                "SQUAD_OS_SYNC_TOKEN) — siga sem esse contexto histórico. Se isso importar "
                "pra resposta, declare a incerteza em vez de inventar."
            )
        try:
            resposta = _post(url, token, {"clientSlug": client, "pergunta": args["pergunta"]})
        except Exception as exc:  # noqa: BLE001 — nunca derruba a sessão por causa do RAG
            return _text_result(
                f"Não consegui consultar o RAG agora ({exc}) — siga sem esse contexto "
                "histórico, ou declare a incerteza se isso importar pra resposta."
            )

        resultados = resposta.get("resultados") or []
        if not resultados:
            return _text_result("Nada relevante encontrado na base de conhecimento deste cliente.")

        blocos = [
            f"[{r['path']}] (similaridade {float(r['similaridade']):.2f})\n{r['trecho']}"
            for r in resultados
        ]
        return _text_result("\n\n---\n\n".join(blocos))

    return create_sdk_mcp_server(name="rag", version="0.1.0", tools=[rag_consultar])
