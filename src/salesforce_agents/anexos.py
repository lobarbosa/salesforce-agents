"""Anexos da demanda que um humano liberou para o agente ler.

Até 2026-10-16 o anexo do card (print do erro, especificação em PDF) ficava só
no Storage do Squad OS e nunca chegava a sessão nenhuma — achado real:
SOMOSAGILITY-14 ("segue anexo o print com o erro") teve a análise travada
porque o agente só via o texto do card.

O caminho agora: alguém de delivery **libera** cada anexo no card, declarando
que ele não tem dado pessoal de cliente (guardrail #2 — print de tela do
Salesforce costuma mostrar nome, e-mail, valor). O job (`run-demand.yml`)
baixa só os liberados para `demandas/<ID>/anexos/` no runner, antes da
sessão. A pasta está no `.gitignore`: o anexo vive o tempo do job e nunca
vira commit, nem entra no RAG (que só lê `.md` versionado).

Este módulo só diz ao agente o que existe ali e como ler. Não baixa nada.
"""

from __future__ import annotations

from pathlib import Path

PASTA = "anexos"

_IMAGEM = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
_SPEC_READ = {".pdf", ".docx", ".md"}


def listar(client: str, demand_id: str, raiz: Path = Path("clients")) -> list[Path]:
    pasta = raiz / client / "demandas" / demand_id / PASTA
    if not pasta.is_dir():
        return []
    return sorted(p for p in pasta.iterdir() if p.is_file())


def nota_para_o_prompt(client: str, demand_id: str, raiz: Path = Path("clients")) -> str:
    """Parágrafo pro prompt da sessão — vazio quando não há anexo liberado."""
    arquivos = listar(client, demand_id, raiz)
    if not arquivos:
        return ""

    linhas = []
    for arq in arquivos:
        rel = f"demandas/{demand_id}/{PASTA}/{arq.name}"
        sufixo = arq.suffix.lower()
        if sufixo in _IMAGEM:
            como = "imagem — abra com Read"
        elif sufixo in _SPEC_READ:
            como = "documento — leia com spec_read"
        else:
            como = "leia com Read se for texto; senão registre que não conseguiu ler"
        linhas.append(f"  - {rel} ({como})")

    return (
        "Anexos do card liberados por uma pessoa de delivery para esta sessão:\n"
        + "\n".join(linhas)
        + "\n\nLeia-os antes de analisar ou desenhar — são parte da demanda. Eles foram "
        "liberados como sem dado pessoal, mas se ainda assim aparecer nome, e-mail, CPF, "
        "telefone ou valor de cliente, **não transcreva** para nenhum artefato: descreva "
        "o que importa (mensagem de erro, tela, campo, passo) sem o dado (guardrail #2). "
        "Não copie o arquivo para fora desta pasta.\n\n"
    )
