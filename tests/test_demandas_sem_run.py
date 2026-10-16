"""Varredura de disparo perdido: só backlog recente, sem branch."""

from __future__ import annotations

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "demandas_sem_run", Path(__file__).parents[1] / "scripts" / "demandas_sem_run.py"
)
mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod)

AGORA = 1_000_000


def _demanda(raiz: Path, cliente: str, demanda: str, status: str) -> None:
    pasta = raiz / cliente / "demandas" / demanda
    pasta.mkdir(parents=True)
    (pasta / "status.yaml").write_text(f"id: {demanda}\nstatus: {status}\n")


def test_so_backlog_recente_sem_branch(tmp_path, monkeypatch):
    _demanda(tmp_path, "acme", "ACME-1", "backlog")  # perdida: entra
    _demanda(tmp_path, "acme", "ACME-2", "backlog")  # já tem branch
    _demanda(tmp_path, "acme", "ACME-3", "aguardando_gate_analise")  # já andou
    _demanda(tmp_path, "beta", "BETA-1", "backlog")  # velha demais

    def git(*args):
        caminho = args[-1]
        return str(AGORA - (500 * 3600 if "BETA-1" in caminho else 3600))

    monkeypatch.setattr(mod, "_git", git)
    achadas = mod.candidatas(tmp_path, {"ACME-2"}, horas=72, agora=AGORA)
    assert achadas == [("acme", "ACME-1")]
