"""Esteira ao vivo: o que a sessão de agente está fazendo agora (2026-10-21).

Até aqui o Squad OS só sabia de uma execução quando ela terminava
(`/api/sync/demanda` e `/api/sync/execucao`, ambos no fim do job). Quem
liberava um gate ficava minutos olhando um card parado sem saber se o agente
tinha começado, em que subagente estava, ou se tinha travado.

Este módulo manda eventos pequenos para `/api/sync/evento` enquanto a sessão
roda: começou, qual subagente entrou, que ferramenta chamou, quanto custou o
turno, terminou. **Só metadata** (guardrail #2): nome de ferramenta, nome de
subagente, nome de arquivo sem caminho, as três primeiras palavras de um
comando — nunca texto do modelo, conteúdo de arquivo, argumento de SOQL ou
saída de comando.

Best-effort por desenho: sem URL/token configurados vira no-op; falha de rede
vira aviso no log e nunca derruba a sessão. Os eventos saem em lote, por uma
thread, a cada poucos segundos — a sessão nunca espera o Squad OS.
"""

from __future__ import annotations

import json
import os
import threading
import time
from datetime import datetime, timezone
from pathlib import PurePath
from urllib import error, request as urlrequest

INTERVALO_S = 3.0
MAX_DETALHE = 120

# Ferramentas cujo argumento útil é um caminho: mostra só o nome do arquivo.
_COM_ARQUIVO = {"Read", "Write", "Edit", "MultiEdit", "NotebookEdit"}


def url_de_eventos() -> str:
    """`SQUAD_OS_SYNC_EVENTO_URL`, ou derivada de `SQUAD_OS_SYNC_URL`
    (…/api/sync/demanda → …/api/sync/evento) pra não exigir secret novo."""
    explicita = os.environ.get("SQUAD_OS_SYNC_EVENTO_URL", "").strip()
    if explicita:
        return explicita
    base = os.environ.get("SQUAD_OS_SYNC_URL", "").strip()
    if base.endswith("/api/sync/demanda"):
        return base[: -len("demanda")] + "evento"
    return ""


def resumir_ferramenta(nome: str, entrada: dict | None) -> str:
    """Descrição curta e sem dado: o que dá pra saber da chamada sem o conteúdo."""
    entrada = entrada or {}
    if nome in _COM_ARQUIVO:
        caminho = entrada.get("file_path") or entrada.get("notebook_path") or ""
        return PurePath(str(caminho)).name[:MAX_DETALHE] if caminho else ""
    if nome == "Bash":
        # "sf project deploy ...", "git commit ..." — três palavras dizem o que
        # é sem levar argumento (que pode ter consulta, nome de registro etc.).
        palavras = str(entrada.get("command", "")).split()
        return " ".join(palavras[:3])[:MAX_DETALHE]
    if nome in ("Task", "Agent"):
        return str(entrada.get("subagent_type", ""))[:MAX_DETALHE]
    if nome in ("Glob", "Grep"):
        return ""  # padrão de busca pode carregar termo de negócio
    return ""


def nome_curto_de_ferramenta(nome: str) -> str:
    # mcp__salesforce-tools__sf_query → sf_query
    return nome.rsplit("__", 1)[-1][:60]


class Emissor:
    """Junta eventos e manda em lote. `emitir` nunca bloqueia nem levanta."""

    def __init__(self, client: str, demand_id: str, etapa: str, *, url: str | None = None,
                 token: str | None = None, run_id: str | None = None, run_url: str | None = None):
        self.client = client
        self.demand_id = demand_id
        self.etapa = etapa
        self.url = url if url is not None else url_de_eventos()
        self.token = token if token is not None else os.environ.get("SQUAD_OS_SYNC_TOKEN", "")
        self.run_id = run_id or os.environ.get("GITHUB_RUN_ID") or f"local-{int(time.time())}"
        servidor = os.environ.get("GITHUB_SERVER_URL", "")
        repo = os.environ.get("GITHUB_REPOSITORY", "")
        self.run_url = run_url if run_url is not None else (
            f"{servidor}/{repo}/actions/runs/{self.run_id}" if servidor and repo else ""
        )
        self.ativo = bool(self.url and self.token)
        self._fila: list[dict] = []
        self._lock = threading.Lock()
        self._parar = threading.Event()
        self._avisou = False
        self._thread: threading.Thread | None = None
        # tool_use_id da chamada Task → subagente, pra atribuir as ferramentas
        # que vêm de dentro dele (parent_tool_use_id) ao agente certo.
        self._subagentes: dict[str, str] = {}

    # -- ciclo de vida -------------------------------------------------------
    def __enter__(self) -> "Emissor":
        if self.ativo:
            self._thread = threading.Thread(target=self._laco, daemon=True)
            self._thread.start()
        self.emitir("inicio")
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.emitir("fim", detalhe="ok" if exc_type is None else "erro")
        self._parar.set()
        if self._thread:
            self._thread.join(timeout=10)
        self._enviar()

    # -- eventos -------------------------------------------------------------
    def emitir(self, tipo: str, *, agente: str = "", ferramenta: str = "", detalhe: str = "",
               custo_usd: float | None = None) -> None:
        if not self.ativo:
            return
        evento = {
            "tipo": tipo,
            "agente": agente[:60],
            "ferramenta": ferramenta[:60],
            "detalhe": detalhe[:MAX_DETALHE],
            "em": datetime.now(timezone.utc).isoformat(),
        }
        if custo_usd is not None:
            evento["custoUsd"] = round(float(custo_usd), 4)
        with self._lock:
            self._fila.append(evento)

    def ferramenta(self, tool_use_id: str, nome: str, entrada: dict | None, pai: str | None) -> None:
        """Uma chamada de ferramenta vista no stream do SDK."""
        agente = self._subagentes.get(pai or "", "orquestrador")
        if nome in ("Task", "Agent"):
            sub = str((entrada or {}).get("subagent_type", "")) or "subagente"
            self._subagentes[tool_use_id] = sub
            self.emitir("agente", agente=sub)
            return
        self.emitir("ferramenta", agente=agente, ferramenta=nome_curto_de_ferramenta(nome),
                    detalhe=resumir_ferramenta(nome, entrada))

    def turno(self, custo_usd: float | None) -> None:
        self.emitir("turno", custo_usd=custo_usd)

    # -- transporte ----------------------------------------------------------
    def _laco(self) -> None:
        while not self._parar.wait(INTERVALO_S):
            self._enviar()

    def _enviar(self) -> None:
        with self._lock:
            lote, self._fila = self._fila, []
        if not lote or not self.ativo:
            return
        corpo = {
            "client": self.client,
            "demandaId": self.demand_id,
            "etapa": self.etapa,
            "runId": str(self.run_id),
            "runUrl": self.run_url,
            "eventos": lote,
        }
        req = urlrequest.Request(
            self.url,
            data=json.dumps(corpo).encode("utf-8"),
            headers={"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urlrequest.urlopen(req, timeout=10):
                pass
        except (error.URLError, TimeoutError, OSError) as exc:
            if not self._avisou:
                print(f"::warning::Esteira ao vivo indisponível ({exc}) — a sessão segue normalmente.")
                self._avisou = True
