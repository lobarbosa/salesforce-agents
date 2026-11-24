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

import hashlib
import re
from pathlib import Path

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


# --- Build bloqueado de volta ao gate de design (2026-11-23) -----------------
#
# Achado SOMOSAGILITY-30: o build voltou bloqueado ao gate de design com uma
# pergunta para o arquiteto, e o gate foi aprovado sete vezes no mesmo dia sem
# a resposta. Cada aprovação rodava o construtor de novo, que bloqueava de novo
# com a mesma pergunta. Duas camadas:
#
# - o card mostra, no topo do design, o que o build disse que falta
#   (`revisao.artefato_em_revisao`, via `resumo`);
# - a esteira guarda uma impressão dos insumos do build no momento do bloqueio
#   (o design e os comentários de gente no card) e recusa uma nova aprovação
#   enquanto nenhum deles mudou (`fluxo.aprovar_gate`).

ARQUIVO_INSUMOS = "04-bloqueio-insumos.txt"
_DESIGN = "03-design.md"
_COMENTARIOS = "comentarios-do-card.md"
# Comentários que o próprio portal escreve ao aprovar: não são resposta.
_AUTOMATICO = re.compile(r"^(Aprovou o gate |Aprovou a estimativa )")
_LIMITE_RESUMO = 6000


def _comentarios_de_gente(texto: str) -> str:
    blocos = re.split(r"\n(?=## )", texto)
    corpo = []
    for bloco in blocos:
        if not bloco.startswith("## "):
            continue
        cabecalho, _, resto = bloco.partition("\n")
        resto = resto.strip()
        if resto and not _AUTOMATICO.match(resto):
            corpo.append(f"{cabecalho}\n{resto}")
    return "\n\n".join(corpo)


def insumos(pasta: Path) -> str:
    """Impressão do que o construtor leu para decidir: o design e os comentários de gente."""
    h = hashlib.sha256()
    design = pasta / _DESIGN
    h.update(design.read_bytes() if design.exists() else b"")
    h.update(b"\0")
    comentarios = pasta / _COMENTARIOS
    if comentarios.exists():
        h.update(_comentarios_de_gente(comentarios.read_text(encoding="utf-8")).encode("utf-8"))
    return h.hexdigest()


def registrar_insumos(pasta: Path) -> None:
    (pasta / ARQUIVO_INSUMOS).write_text(insumos(pasta) + "\n", encoding="utf-8")


def insumos_sem_mudanca(pasta: Path) -> bool:
    """O design e os comentários estão iguais aos do bloqueio registrado."""
    arquivo = pasta / ARQUIVO_INSUMOS
    if not arquivo.exists():
        return False
    return arquivo.read_text(encoding="utf-8").strip() == insumos(pasta)


def resumo(texto_do_plano: str) -> str:
    """O começo do plano bloqueado: resultado, motivo e a pergunta, até o primeiro título."""
    linhas = []
    for i, linha in enumerate(texto_do_plano.splitlines()):
        if i > 0 and linha.startswith("# "):
            break
        linhas.append(linha)
    corpo = "\n".join(linhas).strip()
    return corpo[:_LIMITE_RESUMO]
