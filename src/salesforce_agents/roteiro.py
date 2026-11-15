"""Roteiro de teste do cliente: o passo a passo que quem homologa segue.

`05-testes.md` é a evidência do QA, escrita para quem aprova gate: consulta,
nome de API, contagem. Quem homologa é o cliente, e até 2026-11-14 era esse
arquivo que aparecia para ele no card. O `qa` passa a escrever um segundo
arquivo, em linguagem de usuário, com o que abrir, o que fazer e o que deve
aparecer.

Só existe quando o QA aprova: roteiro para homologar o que foi reprovado não
tem leitor. Por isso não entra em `demands.REQUIRED_ARTIFACTS` (que vale para
a etapa inteira) e é cobrado aqui, com a sessão ainda aberta.
"""

from __future__ import annotations

from pathlib import Path

from . import veredito

NOME = "05-roteiro-cliente.md"
ROTEIRO_DO_QA = "05-testes.md"

# Mesmo teto do artefato de gate (revisao.LIMITE_CONTEUDO): vai para uma
# coluna do Postgres e para uma tela.
LIMITE_CONTEUDO = 60_000


def faltando(pasta: Path, org_de_qa: str) -> list[str]:
    """O roteiro do cliente, se o QA aprovou e não o escreveu."""
    testes = pasta / ROTEIRO_DO_QA
    if not testes.exists() or (pasta / NOME).exists():
        return []
    if not veredito.ler(testes.read_text(encoding="utf-8"), org_de_qa).aprovado:
        return []
    return [str(pasta / NOME)]


def descartar(pasta: Path) -> None:
    """Apaga o roteiro quando o QA não aprova: o que ele descrevia vai mudar."""
    (pasta / NOME).unlink(missing_ok=True)


def conteudo(pasta: Path) -> str:
    """O texto que o Squad OS mostra ao cliente; vazio quando não há roteiro."""
    caminho = pasta / NOME
    if not caminho.exists():
        return ""
    return caminho.read_text(encoding="utf-8")[:LIMITE_CONTEUDO]
