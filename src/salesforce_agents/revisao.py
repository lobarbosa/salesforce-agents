"""O que o humano precisa ter na frente para decidir um gate.

O gate bloqueante é a regra de ouro da doutrina, mas até 2026-09-14 ele chegava
oco ao Squad OS: o card dizia "aguarda consultor" e oferecia um botão de
aprovar, enquanto o que havia para julgar — o artefato que a etapa produziu —
existia só no git. Aprovar sem ler era o caminho mais curto, e nada na tela
sugeria que houvesse algo a ler.

Pior: o `ba-discovery` é instruído a nunca preencher lacuna com suposição e a
listar toda premissa pendente. Ele cumpriu (11 pendências na ACXYA-2) e o app
mostrou "0 perguntas", porque `perguntas` só era populado pela rota do agente
planejador. O modal já se recusa a aprovar com pergunta em aberto — a trava
existia e estava inerte por falta de quem enchesse o campo que ela confere.

Este módulo é o cano que faltava: descobre qual artefato está em julgamento,
lê o disco (o git segue sendo a fonte, guardrail #5) e transforma as pendências
marcadas em perguntas que a trava do modal entende.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path

from .demands import REQUIRED_ARTIFACTS, STAGES_EXECUCAO, Demand

# Um artefato grande não pode virar uma linha gigante no Postgres nem uma
# tela que não rola. Quem quiser o inteiro tem o arquivo no PR — o app mostra
# o suficiente para decidir, e diz quando cortou.
LIMITE_CONTEUDO = 60_000

# Item de checklist markdown ainda não resolvido. `- [x]` fica de fora de
# propósito: marcado é pendência que o próprio agente já fechou.
_PENDENCIA = re.compile(r"^\s*[-*]\s*\[ \]\s+(.+?)\s*$", re.M)


def artefato_do_gate(status: str) -> str | None:
    """Qual arquivo está sendo julgado neste gate.

    Derivado de `REQUIRED_ARTIFACTS` em vez de um segundo mapa escrito à mão:
    o gate julga o que a etapa imediatamente anterior produziu, e duas listas
    dizendo isso sairiam de sincronia na primeira etapa nova.

    Quando a etapa produz mais de um artefato (`design` produz recon e design),
    o que vai para a mesa é o último — o recon é insumo, a decisão está no
    design.
    """
    if not status.startswith("aguardando_"):
        return None
    try:
        i = STAGES_EXECUCAO.index(status)
    except ValueError:
        return None
    if i == 0:
        return None
    artefatos = REQUIRED_ARTIFACTS.get(STAGES_EXECUCAO[i - 1], ())
    return artefatos[-1] if artefatos else None


def pendencias(texto: str) -> list[dict]:
    """As premissas a validar que o agente deixou marcadas como pendentes.

    O formato é contrato, não adivinhação: `.claude/agents/ba-discovery.md`
    manda listar toda suposição em "Premissas a validar" marcada como pendente,
    e checklist markdown é como isso sai. Artefato sem checkbox devolve lista
    vazia e o gate segue como antes — degradar em silêncio aqui é melhor que
    inventar pergunta que ninguém escreveu.

    O `id` é derivado do próprio texto para que uma re-sincronização da mesma
    etapa reencontre a resposta que o humano já digitou, em vez de zerá-la.
    """
    vistos: set[str] = set()
    saida: list[dict] = []
    for texto_item in _PENDENCIA.findall(texto):
        # O agente escreve a pendência em negrito ("**Tipo de campo**: ..."),
        # que não ajuda quem lê num campo de formulário.
        limpo = texto_item.replace("**", "").strip()
        if not limpo:
            continue
        ident = hashlib.sha256(limpo.encode("utf-8")).hexdigest()[:12]
        if ident in vistos:
            continue
        vistos.add(ident)
        saida.append({"id": ident, "texto": limpo})
    return saida


def artefato_em_revisao(demanda: Demand) -> dict | None:
    """Nome, conteúdo e pendências do artefato que este gate põe na mesa.

    Devolve `None` fora de gate (nada a revisar) e quando o arquivo não existe
    — este módulo informa, não valida: quem recusa avançar sem artefato é
    `demands.transition`, e duplicar a recusa aqui só criaria uma segunda voz
    dizendo a mesma coisa com outras palavras.
    """
    nome = artefato_do_gate(demanda.status)
    if not nome:
        return None

    caminho: Path = demanda.path / nome
    if not caminho.exists():
        return None

    conteudo = caminho.read_text(encoding="utf-8")
    truncado = len(conteudo) > LIMITE_CONTEUDO
    return {
        "nome": nome,
        "conteudo": conteudo[:LIMITE_CONTEUDO],
        "truncado": truncado,
        "perguntas": pendencias(conteudo),
    }


def payload_de_sync(demanda: Demand) -> dict:
    """O `status.yaml` em JSON mais o que o gate precisa mostrar.

    Separado de `Demand.to_dict()` porque aquele é o que vai para o disco:
    artefato e perguntas são derivados, e gravá-los no `status.yaml` criaria
    uma segunda cópia do que já está no arquivo ao lado.
    """
    dados = demanda.to_dict()
    artefato = artefato_em_revisao(demanda)
    if artefato:
        dados["artefato"] = artefato
    return dados
