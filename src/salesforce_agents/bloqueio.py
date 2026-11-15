"""Build que não construiu nada não pode chegar ao gate de build.

Achado real (Somos Agility, 2026-11-12): cinco demandas estavam em "aguardando
homologação" sem nada construído. O design tinha perguntas sem resposta, o
agente de build declarou "BUILD BLOQUEADO" no `04-plano-build.md` — e, como o
arquivo existia, o fluxo avançou para o gate de build, alguém aprovou, o QA
registrou "nada a testar" e a demanda seguiu até o cliente.

O agente de build escreve `**Resultado do build:** concluído|bloqueado` no topo
do plano (ver `.claude/agents/`). Para os planos anteriores a essa regra, cai na
leitura de título ou destaque nas primeiras linhas. A mesma regra vive em
`apps/squad-os/lib/build-bloqueado.ts` — mude as duas juntas.
"""

from __future__ import annotations

import re

_EXPLICITO = re.compile(r"\*\*Resultado do build:\*\*\s*\**\s*(conclu[ií]do|bloqueado)", re.I)
_LEGADO = re.compile(
    r"build[^\n]{0,25}bloquead|bloquead[oa][^\n]{0,25}build|build n[ãa]o (foi )?executado"
    r"|execu[çc][ãa]o bloqueada|nenhum (metadata|componente) foi (criado|escrito)",
    re.I,
)
_NEGADO = re.compile(r"n[ãa]o (est[áa] |foi |h[áa] )?bloque", re.I)


def build_bloqueado(texto: str) -> bool:
    explicito = _EXPLICITO.search(texto)
    if explicito:
        return explicito.group(1).lower() == "bloqueado"
    # Só título, citação ou linha em destaque no começo do arquivo: "bloqueado"
    # no meio de um parágrafo de risco não é declaração de build bloqueado.
    for linha in texto.splitlines()[:40]:
        l = linha.strip()
        if l.startswith(("#", "**", ">")) and _LEGADO.search(l) and not _NEGADO.search(l):
            return True
    return False
