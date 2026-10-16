"""Demandas materializadas cujo primeiro run nunca aconteceu.

O `run-demand.yml` tem fila por cliente (`concurrency: demanda-<cliente>`,
guardrail #6), e o GitHub guarda **um** run pendente por fila: um disparo novo
substitui o pendente anterior, que vira `cancelled` sem rodar nada. Achado real
(2026-10-16): várias demandas da somos-agility materializadas em sequência; só
a última rodou, e SOMOSAGILITY-9/-10 ficaram no quadro como "já materializada"
sem avançar.

Critério de "nunca rodou": status.yaml no main em `backlog` (é como a
materialização grava) e nenhuma branch `feature/<ID>` no remoto (o primeiro
run sempre cria). Recente (`--horas`) para não ressuscitar sozinho algo que
alguém deixou parado de propósito há dias.

Uso: python3 scripts/demandas_sem_run.py --horas 72
Saída: uma linha por candidata, `<cliente> <DEMAND-ID>`.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

import yaml


def _git(*args: str) -> str:
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def branches_remotas() -> set[str]:
    saida = _git("ls-remote", "--heads", "origin", "refs/heads/feature/*")
    return {linha.split("refs/heads/feature/", 1)[1] for linha in saida.splitlines() if linha}


def candidatas(raiz: Path, branches: set[str], horas: float, agora: float) -> list[tuple[str, str]]:
    achadas = []
    for status in sorted(raiz.glob("*/demandas/*/status.yaml")):
        dados = yaml.safe_load(status.read_text(encoding="utf-8")) or {}
        demanda_id = status.parent.name
        if dados.get("status") != "backlog" or demanda_id in branches:
            continue
        quando = _git("log", "-1", "--format=%ct", "--", str(status)).strip()
        if not quando or agora - int(quando) > horas * 3600:
            continue
        achadas.append((status.parents[2].name, demanda_id))
    return achadas


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--horas", type=float, default=72)
    ap.add_argument("--raiz", default="clients")
    args = ap.parse_args()
    for cliente, demanda in candidatas(Path(args.raiz), branches_remotas(), args.horas, time.time()):
        print(f"{cliente} {demanda}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
