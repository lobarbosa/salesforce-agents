#!/usr/bin/env python3
"""Monta os argumentos de deploy do que uma demanda mudou no force-app do cliente.

Usado pelo `run-demand.yml` no começo da etapa de QA: o build só toca a sandbox
de dev e o QA só testa, então alguém tem de levar o pacote para a sandbox de QA
antes do teste. Até 2026-11-15 ninguém levava (achado EPLAST-47: o QA reprovou
em um minuto porque o build não estava lá, e a demanda ficou rodando em círculo
entre QA e build).

Lê da entrada padrão os caminhos alterados pela branch (um por linha, relativos
à raiz do repositório, como saem de `git diff --name-only`) e imprime, um por
linha, os argumentos para `sf project deploy start`, relativos à pasta do
cliente:

    --source-dir
    force-app/main/default/flows/X.flow-meta.xml
    --test-level
    NoTestRun

Só entra o que a demanda mudou e ainda existe; arquivo removido é avisado, não
implantado (remoção destrutiva na org é decisão de gente). Sem Apex não roda
teste; com Apex, só as classes de teste da própria demanda (`<Classe>Test`,
convenção do CLAUDE.md) — a suíte inteira da org do cliente tem teste legado
quebrado sem relação com a demanda.

Saída: 0 com argumentos; 3 se a demanda não mudou nada implantável; 2 se há
Apex sem classe de teste dedicada.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_APEX = re.compile(r"/(classes|triggers)/[^/]+\.(cls|trigger)$")


class ApexSemTeste(Exception):
    pass


def alterados_do_cliente(caminhos: list[str], cliente: str) -> list[str]:
    """Os caminhos do force-app deste cliente, relativos à pasta dele."""
    prefixo = f"clients/{cliente}/"
    return sorted(
        {c[len(prefixo):] for c in (l.strip() for l in caminhos) if c.startswith(f"{prefixo}force-app/")}
    )


def _testes(apex: list[str], pasta_do_cliente: Path) -> list[str]:
    testes: set[str] = set()
    faltam: list[str] = []
    for caminho in apex:
        arquivo = pasta_do_cliente / caminho
        nome = arquivo.stem
        classes = arquivo.parent.parent / "classes"
        if arquivo.suffix == ".cls" and "@istest" in arquivo.read_text(encoding="utf-8", errors="ignore").lower():
            testes.add(nome)
        elif (classes / f"{nome}Test.cls").exists():
            testes.add(f"{nome}Test")
        elif arquivo.suffix == ".cls":
            faltam.append(caminho)
        # Trigger sem <Nome>Test costuma ser coberto pelo teste do handler.
    if faltam:
        raise ApexSemTeste(
            "sem classe de teste dedicada (<Classe>Test.cls): " + ", ".join(faltam)
        )
    if not testes:
        raise ApexSemTeste("a demanda muda Apex e não traz nenhuma classe de teste que o cubra")
    return sorted(testes)


def argumentos(alterados: list[str], pasta_do_cliente: Path) -> tuple[list[str], list[str]]:
    """(argumentos do deploy, arquivos removidos que ficaram de fora)."""
    existentes = [c for c in alterados if (pasta_do_cliente / c).exists()]
    removidos = [c for c in alterados if c not in existentes]
    if not existentes:
        return [], removidos
    args: list[str] = []
    for caminho in existentes:
        args += ["--source-dir", caminho]
    apex = [c for c in existentes if _APEX.search(c)]
    if not apex:
        args += ["--test-level", "NoTestRun"]
    else:
        args += ["--test-level", "RunSpecifiedTests"]
        for teste in _testes(apex, pasta_do_cliente):
            args += ["--tests", teste]
    return args, removidos


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("uso: pacote_da_demanda.py <cliente>  (caminhos alterados na entrada padrão)", file=sys.stderr)
        return 64
    cliente = argv[1]
    pasta = Path("clients") / cliente
    alterados = alterados_do_cliente(sys.stdin.read().splitlines(), cliente)
    try:
        args, removidos = argumentos(alterados, pasta)
    except ApexSemTeste as exc:
        print(f"::error::{exc}", file=sys.stderr)
        return 2
    for caminho in removidos:
        print(f"::warning::{caminho} foi removido na demanda e não é implantado nem apagado da org.", file=sys.stderr)
    if not args:
        return 3
    print("\n".join(args))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
