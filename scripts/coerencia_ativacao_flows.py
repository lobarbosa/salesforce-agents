#!/usr/bin/env python3
"""Corrige no pacote da QA o Flow que a demanda manda desativar mas leva como ativo.

Achado EPLAST-47 (rodadas 4 e 5 de QA, 2026-11-17): o design pedia o Flow agendado
antigo desativado na QA. O pacote levava a definição com `activeVersionNumber` 0, mas o
`.flow-meta.xml` do mesmo Flow continuava com `<status>Active</status>`. A plataforma
criou uma versão nova já ativa, o `activeVersionNumber` 0 não prevaleceu, e o QA reprovou
duas vezes pelo mesmo motivo: o agendado antigo seguia armado na sandbox.

Lê os argumentos do deploy (saída de `pacote_da_demanda.py`, um por linha) e, para cada
`flowDefinitions/<Nome>.flowDefinition-meta.xml` do pacote com `activeVersionNumber` 0,
troca o status do `flows/<Nome>.flow-meta.xml` do mesmo pacote de `Active` para
`Obsolete`. Grava na cópia de trabalho do job; quem chama devolve o conteúdo commitado ao
sair (o mesmo cuidado do `permissoes_so_o_diff.py`).

Imprime, um por linha, os nomes dos Flows que o pacote manda desativar (corrigidos ou
não), para o deploy conferir na org depois e registrar em `05-deploy-qa.md`.

Uso: coerencia_ativacao_flows.py <pasta do cliente> <arquivo de argumentos>
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_DEFINICAO = re.compile(r"flowDefinitions/([^/]+)\.flowDefinition-meta\.xml$")
_ATIVA_ZERO = re.compile(r"<activeVersionNumber>\s*0\s*</activeVersionNumber>")
_STATUS_ATIVO = re.compile(r"<status>\s*Active\s*</status>")


def caminhos_do_pacote(argumentos: list[str]) -> list[str]:
    return [a.strip() for a in argumentos if a.strip().startswith("force-app/")]


def flows_a_desativar(pasta: Path, caminhos: list[str]) -> list[str]:
    nomes = []
    for c in caminhos:
        m = _DEFINICAO.search(c)
        if not m:
            continue
        arquivo = pasta / c
        if arquivo.is_file() and _ATIVA_ZERO.search(arquivo.read_text(encoding="utf-8")):
            nomes.append(m.group(1))
    return nomes


def corrigir(pasta: Path, caminhos: list[str]) -> tuple[list[str], list[str]]:
    """Devolve (Flows a desativar, Flows cujo XML estava ativo e foi corrigido)."""
    nomes = flows_a_desativar(pasta, caminhos)
    corrigidos = []
    no_pacote = set(caminhos)
    for nome in nomes:
        for c in no_pacote:
            if not c.endswith(f"/flows/{nome}.flow-meta.xml"):
                continue
            arquivo = pasta / c
            texto = arquivo.read_text(encoding="utf-8")
            if _STATUS_ATIVO.search(texto):
                arquivo.write_text(_STATUS_ATIVO.sub("<status>Obsolete</status>", texto, count=1), encoding="utf-8")
                corrigidos.append(nome)
    return nomes, corrigidos


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    pasta, args = Path(argv[0]), Path(argv[1])
    nomes, corrigidos = corrigir(pasta, caminhos_do_pacote(args.read_text(encoding="utf-8").splitlines()))
    for nome in corrigidos:
        print(
            f"::warning::{nome}: o pacote manda desativar (activeVersionNumber 0), mas o Flow ia como Active. "
            f"Implantado como Obsolete (achado EPLAST-47).",
            file=sys.stderr,
        )
    for nome in nomes:
        print(nome)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
