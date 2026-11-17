#!/usr/bin/env python3
"""Diz se um deploy em QA caiu só por trabalho Apex pendente, e quais são os trabalhos.

Usado pelo `scripts/implantar-build-qa.sh`. Uma demanda com classe agendável
ou batch deixa o trabalho armado na sandbox de QA (é o que o QA em duas fases
faz). Na rodada seguinte o deploy do mesmo pacote cai inteiro: a plataforma
recusa atualizar classe com trabalho pendente ou em andamento (achado
EPLAST-33, 2026-11-17: redesenho aprovado no gate de build e parado na QA
pelo `CronTrigger` da rodada anterior).

Lê o JSON do `sf project deploy start --json` (arquivo no primeiro argumento)
e imprime, um por linha, os Ids dos trabalhos citados nas falhas
(`CronTrigger`, prefixo 08e; `AsyncApexJob`, prefixo 707), os agendados
primeiro. Sai com 3 quando não é esse o caso: há outra falha junto, ou
nenhuma falha cita um Id. Só então a esteira cancela, e só o que a própria
plataforma apontou como trava das classes do pacote.
"""

from __future__ import annotations

import json
import re
import sys

# A mensagem vem no idioma do usuário que implanta; a Eplast está em português.
_PENDENTE = re.compile(
    r"pendentes? ou em andamento"
    r"|permitir implanta[cç][oõ]es com trabalhos do Apex"
    r"|pending or in progress"
    r"|allowing deployments with Apex jobs",
    re.IGNORECASE,
)
_ID = re.compile(r"\b(?:08e|707)[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?\b")


def falhas(deploy: dict) -> list[str]:
    """As mensagens de falha por componente do resultado do deploy."""
    resultado = deploy.get("result")
    detalhes = resultado.get("details") if isinstance(resultado, dict) else None
    brutas = detalhes.get("componentFailures") if isinstance(detalhes, dict) else None
    if isinstance(brutas, dict):
        brutas = [brutas]
    return [str(f.get("problem") or "") for f in brutas or [] if isinstance(f, dict)]


def trabalhos_que_travam(deploy: dict) -> list[str]:
    """Ids a cancelar, ou lista vazia se o deploy não caiu só por trabalho pendente."""
    problemas = falhas(deploy)
    if not problemas or not all(_PENDENTE.search(p) for p in problemas):
        return []
    ids: list[str] = []
    for problema in problemas:
        for achado in _ID.findall(problema):
            if achado not in ids:
                ids.append(achado)
    return sorted(ids, key=lambda i: (not i.startswith("08e"), ids.index(i)))


def main(argv: list[str]) -> int:
    try:
        with open(argv[1], encoding="utf-8") as arquivo:
            deploy = json.load(arquivo)
    except (IndexError, OSError, ValueError):
        return 3
    ids = trabalhos_que_travam(deploy if isinstance(deploy, dict) else {})
    if not ids:
        return 3
    print("\n".join(ids))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
