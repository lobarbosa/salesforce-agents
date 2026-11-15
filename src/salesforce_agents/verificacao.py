"""Verificação do build: o agente testa e evidencia antes de chamar o humano.

Até 2026-11-15 o gate de build chegava ao revisor sem ninguém ter exercitado o
que foi construído: o builder validava que a metadata era aceita, e o primeiro
teste de comportamento era o QA, depois do gate. Na EPLAST-47 o revisor foi
chamado para um Flow que nunca tinha rodado.

Regra (decisão do responsável, 2026-11-15): ainda na etapa de build, depois do
construtor, o agente `verificador` testa na sandbox de dev o que foi
construído, contra os critérios de aceite, e grava `04-verificacao.md` com a
evidência de cada caso. O gate humano só é chamado depois disso:

- `aprovada`     → segue para o gate de build, com a evidência junto do plano.
- `reprovada`    → a construção roda de novo, com a verificação reprovada
                   guardada como `04-verificacao-rodada-<n>.md` para o builder.
- `inconclusiva` → o agente não conseguiu exercitar (não há como disparar na
                   dev, depende de sistema externo). Não é defeito para o
                   builder corrigir, então refazer não adianta: segue para o
                   gate dizendo, sem rodeio, o que ficou sem prova.

Arquivo sem a linha de resultado, ou testado em org que não é a sandbox de dev
do cliente, conta como reprovada: sem evidência não há verificação.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from . import bloqueio

NOME = "04-verificacao.md"
PLANO = "04-plano-build.md"

_RESULTADO = re.compile(r"\*\*Verifica[çc][ãa]o:\*\*\s*\**\s*(aprovada|reprovada|inconclusiva)", re.I)
# A org vem com ou sem crase, e às vezes seguida de comentário entre parênteses:
# "`sbx-x-dev`", "sbx-x-dev" e "`sbx-x-dev` (Org ID ...)" são a mesma declaração.
# Achado EPLAST-28 (2026-11-15): sem crase, a verificação inconclusiva foi lida
# como reprovada e a construção rodou de novo à toa.
_ORG = re.compile(r"\*\*Org de teste:\*\*\s*`?([A-Za-z0-9_.\-]+)`?", re.I)


@dataclass(frozen=True)
class Resultado:
    estado: str  # "aprovada" | "reprovada" | "inconclusiva"
    motivo: str  # por que não passou; vazio quando aprovada


def ler(texto: str, org_de_dev: str) -> Resultado:
    explicito = _RESULTADO.search(texto)
    if not explicito:
        return Resultado("reprovada", "a verificação não declara `**Verificação:**` — sem resultado não há evidência")
    estado = explicito.group(1).lower()
    org = _ORG.search(texto)
    if not org or org.group(1).strip() != org_de_dev:
        onde = f"`{org.group(1).strip()}`" if org else "nenhuma org declarada"
        return Resultado("reprovada", f"a verificação tem de rodar em `{org_de_dev}` e declarou {onde}")
    if estado == "aprovada":
        return Resultado("aprovada", "")
    return Resultado(estado, f"verificação {estado}")


def da_pasta(pasta: Path, org_de_dev: str) -> Resultado:
    arquivo = pasta / NOME
    if not arquivo.exists():
        return Resultado("reprovada", f"falta {NOME}: o build não foi verificado")
    return ler(arquivo.read_text(encoding="utf-8"), org_de_dev)


def faltando(pasta: Path) -> list[str]:
    """A verificação, se o construtor concluiu o build e ninguém a gravou."""
    plano = pasta / PLANO
    if not plano.exists() or (pasta / NOME).exists():
        return []
    if bloqueio.build_bloqueado(plano.read_text(encoding="utf-8")):
        return []  # build bloqueado não construiu nada: não há o que verificar
    return [str(pasta / NOME)]


def rodadas_reprovadas(pasta: Path) -> int:
    return len(list(pasta.glob("04-verificacao-rodada-*.md")))


def arquivar_reprovada(pasta: Path) -> None:
    """Guarda a verificação reprovada para o builder ler e tira a atual do caminho."""
    arquivo = pasta / NOME
    if arquivo.exists():
        arquivo.rename(pasta / f"04-verificacao-rodada-{rodadas_reprovadas(pasta) + 1}.md")


def descartar(pasta: Path) -> None:
    """Antes de cada build: a verificação da construção anterior não vale para a nova."""
    (pasta / NOME).unlink(missing_ok=True)


def anexo_para_o_gate(pasta: Path) -> str:
    """A verificação, para aparecer junto do plano no card de quem revisa o build."""
    arquivo = pasta / NOME
    if not arquivo.exists():
        return ""
    return "\n\n---\n\n" + arquivo.read_text(encoding="utf-8")
