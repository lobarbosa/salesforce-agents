"""Comentários do card que chegam à sessão do agente.

O card é onde cliente e consultor respondem as dúvidas da análise — e até
2026-10-17 isso nunca chegava à etapa seguinte (achado: SOMOSAGILITY-14 tinha a
resposta num comentário e a análise saiu travada do mesmo jeito).

`run-demand.yml` busca em `/api/sync/comentarios` (só lado + data + texto,
nunca nome ou e-mail de quem escreveu) e passa por aqui, que:

- **redige** CPF, e-mail e telefone com os mesmos padrões do scanner de PII
  (`scripts/verificar_pii.py`) — comentário é texto livre, e um cliente colando
  o e-mail de um colaborador é o caso comum, não o raro (guardrail #2);
- grava `demandas/<ID>/comentarios-do-card.md` **só no runner**: está no
  `.gitignore`, nunca vira commit, PR ou RAG (mesmo tratamento dos anexos).
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

ARQUIVO = "comentarios-do-card.md"
_SCANNER = Path(__file__).resolve().parents[2] / "scripts" / "verificar_pii.py"


def _padroes() -> dict:
    spec = importlib.util.spec_from_file_location("verificar_pii", _SCANNER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.PADROES


def redigir(texto: str, padroes: dict | None = None) -> tuple[str, int]:
    """Troca cada CPF/e-mail/telefone por um marcador. Devolve (texto, quantos)."""
    padroes = padroes or _padroes()
    total = 0
    for tipo, padrao in padroes.items():
        texto, n = padrao.subn(f"[{tipo} omitido]", texto)
        total += n
    return texto, total


def renderizar(comentarios: list[dict], padroes: dict | None = None) -> tuple[str, int]:
    padroes = padroes or _padroes()
    linhas = [
        "# Comentários do card",
        "",
        "Conversa registrada no card da demanda, em ordem cronológica. Dados pessoais",
        "foram omitidos antes de chegar aqui. Trate como complemento de `demanda.md`:",
        "respostas a dúvidas da análise costumam estar aqui.",
        "",
    ]
    omitidos = 0
    for c in comentarios:
        texto, n = redigir(str(c.get("texto", "")).strip(), padroes)
        omitidos += n
        lado = "Cliente" if c.get("papel") == "cliente" else "Equipe"
        linhas += [f"## {lado} — {str(c.get('em', ''))[:16].replace('T', ' ')}", "", texto, ""]
    return "\n".join(linhas), omitidos


def gravar(demanda_dir: Path, comentarios: list[dict]) -> tuple[Path | None, int]:
    if not comentarios:
        return None, 0
    conteudo, omitidos = renderizar(comentarios)
    destino = demanda_dir / ARQUIVO
    destino.write_text(conteudo, encoding="utf-8")
    return destino, omitidos


def nota_para_o_prompt(client: str, demand_id: str, raiz: Path = Path("clients")) -> str:
    if not (raiz / client / "demandas" / demand_id / ARQUIVO).exists():
        return ""
    return (
        f"O card tem comentários de cliente e equipe em demandas/{demand_id}/{ARQUIVO} — "
        "leia antes de analisar ou desenhar: respostas às dúvidas da análise anterior "
        "costumam estar lá. Dados pessoais já foram omitidos; não tente reconstruí-los.\n\n"
    )
