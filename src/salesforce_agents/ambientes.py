"""Qual org cada estágio da esteira toca, e como essa org se chama.

A esteira vai de dev até a sandbox de QA e o agente para ali. Produção não
existe neste módulo de propósito: o guardrail #1 do CLAUDE.md proíbe o agente
de tocar prod, e um mapeamento que soubesse o nome do ambiente de produção
seria o primeiro passo pra alguém "só passar o alias" um dia.

Esta é a única fonte de verdade da regra. Os workflows do GitHub Actions
perguntam pra cá (via `sfagents demanda ambiente`) em vez de repetirem a
condição em YAML, onde ela sairia de sincronia na primeira mudança.
"""

from __future__ import annotations

import re

from .demands import STAGES, STAGES_TRIAGEM

AMBIENTES = ("dev", "qa")

# Onde a linha é cortada: build e tudo antes acontece em dev; a partir de `qa`
# a demanda já vive na sandbox de QA, que é onde o agente roda o roteiro de
# teste, onde o humano homologa e onde o release entrega. Colocar o corte aqui
# (e não no `release`) é o que faz a homologação humana acontecer na org em
# que a coisa vai ser aceita — homologar em dev e só depois mover pra QA seria
# homologar uma coisa e entregar outra.
#
# Se um dia a decisão for empurrar o deploy pra QA mais pra frente, muda-se
# esta constante e nada mais: os workflows e a CLI derivam tudo daqui.
PRIMEIRO_ESTAGIO_QA = "qa"

# Estágios de execução, na ordem, a partir do primeiro que roda em QA.
_EXECUCAO_QA = ("qa", "aguardando_homologacao", "release", "entregue")


def ambiente_do_estagio(status: str) -> str:
    """Devolve 'dev' ou 'qa' para um estágio de demanda.

    Triagem responde 'dev' porque nada roda contra org nessa fase — é o
    default seguro, não uma afirmação de que a demanda está em dev.
    """
    if status not in STAGES:
        raise ValueError(f"estágio desconhecido: {status!r}")
    if status in STAGES_TRIAGEM:
        return "dev"
    return "qa" if status in _EXECUCAO_QA else "dev"


def org_alias(client: str, ambiente: str) -> str:
    """Alias da org no `sf` CLI — o mesmo que AmbienteOrg.orgAlias no Squad OS."""
    _validar(ambiente)
    return f"sbx-{client}-{ambiente}"


def github_environment(client: str, ambiente: str) -> str:
    """Nome do GitHub Environment que guarda os secrets dessa org.

    Um Environment por cliente POR ambiente (acxya-dev, acxya-qa): antes era
    um só por cliente, o que só comportava uma sandbox e misturava a
    credencial de dev com a de QA no mesmo cofre.
    """
    _validar(ambiente)
    return f"{client}-{ambiente}"


# Formato exato de alias que a esteira aceita: `sbx-<slug>-dev|qa`. É uma
# **allowlist**, não uma lista de proibidos — a diferença importa. Negar aliases
# que contenham "prod" deixa passar tudo que não usa essa palavra, e o problema
# nunca foi o nome: era o destino. Isto aqui fecha a forma; quem confere o
# destino de verdade é `tools.py`, perguntando à org se ela é sandbox.
ALIAS_RE = re.compile(r"^sbx-[a-z0-9][a-z0-9-]*-(dev|qa)$")


def alias_permitido(alias: str) -> bool:
    """True só para alias no formato da esteira.

    Usado pelo hook `guard-prod.sh` (que repete esta regex em bash — duplicação
    consciente: o hook precisa rodar sem Python no PATH) e por qualquer código
    que monte comando `sf`.
    """
    return bool(ALIAS_RE.match(alias or ""))


def _validar(ambiente: str) -> None:
    if ambiente not in AMBIENTES:
        raise ValueError(
            f"ambiente inválido: {ambiente!r} — a esteira só conhece {AMBIENTES}. "
            f"Produção não é modelada aqui (guardrail #1)."
        )
