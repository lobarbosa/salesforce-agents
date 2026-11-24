"""Roteiro de teste do cliente: o passo a passo que quem homologa segue.

`05-testes.md` é a evidência do QA, escrita para quem aprova gate: consulta,
nome de API, contagem. Quem homologa é o cliente, e até 2026-11-14 era esse
arquivo que aparecia para ele no card. O `qa` passa a escrever um segundo
arquivo, em linguagem de usuário, com o que abrir, o que fazer e o que deve
aparecer.

Sai em toda rodada de QA, aprovada ou não (decisão de 2026-11-15): quando o
QA automático não consegue executar tudo, é com este roteiro que o time testa
à mão. O cliente só o vê da homologação em diante, e só chega lá com o QA
aprovado. Por variar com a rodada, não entra em `demands.REQUIRED_ARTIFACTS`:
é cobrado aqui, com a sessão ainda aberta, e apagado antes de cada QA para a
sessão não passar com o roteiro da rodada anterior.
"""

from __future__ import annotations

from pathlib import Path

NOME = "05-roteiro-cliente.md"
ROTEIRO_DO_QA = "05-testes.md"

# Mesmo teto do artefato de gate (revisao.LIMITE_CONTEUDO): vai para uma
# coluna do Postgres e para uma tela.
LIMITE_CONTEUDO = 60_000


def faltando(pasta: Path) -> list[str]:
    """O roteiro do cliente, se o QA escreveu o `05-testes.md` e não o escreveu."""
    if not (pasta / ROTEIRO_DO_QA).exists() or (pasta / NOME).exists():
        return []
    return [str(pasta / NOME)]


def descartar(pasta: Path) -> None:
    """Apaga o roteiro antes de uma nova rodada de QA: a sessão escreve outro."""
    (pasta / NOME).unlink(missing_ok=True)


def conteudo(pasta: Path) -> str:
    """O texto que o Squad OS mostra ao cliente; vazio quando não há roteiro."""
    caminho = pasta / NOME
    if not caminho.exists():
        return ""
    return caminho.read_text(encoding="utf-8")[:LIMITE_CONTEUDO]
