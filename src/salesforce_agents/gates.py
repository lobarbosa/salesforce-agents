"""O log de aprovações humanas — escrito por código, não pedido ao agente.

`gates.md` sempre esteve na estrutura de artefatos do CLAUDE.md, mas quem o
escrevia era o agente, por instrução no prompt. Instrução é a camada mais fraca
que existe: um modelo pode esquecer, e o único registro do gate bloqueante da
doutrina ficava dependendo disso. Achado do council de 2026-09-11.

Aqui ele vira mecânico, e ganha a parte que faltava: **o que** foi revisado.
"Leonardo aprovou o design em 11/09" não diz nada se `03-design.md` mudou
depois. Cada registro carrega o sha256 de cada artefato que estava na mesa no
momento da aprovação — então "o arquivo mudou desde que foi aprovado" passa a
ser uma pergunta que se responde, e não uma que se debate.

Não é anti-fraude (quem tem push pode reescrever o arquivo); é anti-ambiguidade,
que é o problema real de quem precisa auditar uma entrega meses depois.
"""

from __future__ import annotations

import hashlib
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from .demands import REQUIRED_ARTIFACTS, STAGES_EXECUCAO, Demand

NOME_ARQUIVO = "gates.md"

CABECALHO = """# Gates

Log de aprovações humanas desta demanda. Escrito por `sfagents`, não à mão:
cada bloco registra quem aprovou, quando, e o hash de cada artefato que estava
na mesa naquele momento.

Se um hash aqui não bate mais com o arquivo em disco, o artefato mudou **depois**
da aprovação — o que não é necessariamente errado, mas significa que o que está
no repositório hoje não é o que aquela pessoa aprovou.
"""


def etapa_do_gate(gate: str) -> str | None:
    """A etapa de agente que este gate está revisando (a imediatamente anterior)."""
    if gate not in STAGES_EXECUCAO:
        return None
    i = STAGES_EXECUCAO.index(gate)
    return STAGES_EXECUCAO[i - 1] if i > 0 else None


def artefatos_do_gate(gate: str) -> tuple[str, ...]:
    """O que este gate tem sob revisão.

    Deriva de `REQUIRED_ARTIFACTS` em vez de repetir a lista: a mesma tabela que
    impede avançar sem o artefato é a que diz o que o humano está aprovando. Se
    as duas saíssem de sincronia, o gate registraria evidência de outra coisa.
    """
    etapa = etapa_do_gate(gate)
    return REQUIRED_ARTIFACTS.get(etapa or "", ())


def _sha(caminho: Path) -> str:
    return hashlib.sha256(caminho.read_bytes()).hexdigest()


def commit_atual() -> str | None:
    """SHA do HEAD, quando houver git. Conveniência, não a evidência principal —
    o hash de cada artefato vale sozinho, mesmo fora de um repositório."""
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=10, check=False,
        )
    except (FileNotFoundError, subprocess.SubprocessError):
        return None
    return proc.stdout.strip() or None


def registrar(demand: Demand, gate: str, autor: str, *, quando: str | None = None) -> Path:
    """Acrescenta o bloco deste gate em `gates.md` e devolve o caminho."""
    caminho = demand.path / NOME_ARQUIVO
    if not caminho.exists():
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text(CABECALHO, encoding="utf-8")

    quando = quando or datetime.now(timezone.utc).isoformat()
    linhas = [
        "",
        f"## {gate}",
        "",
        f"- **Aprovado por:** {autor}",
        f"- **Quando:** {quando}",
    ]
    commit = commit_atual()
    if commit:
        linhas.append(f"- **Commit:** `{commit}`")

    esperados = artefatos_do_gate(gate)
    if not esperados:
        # Nem todo gate tem artefato numerado sob revisão — `aguardando_gate_analise`
        # tem, `aguardando_homologacao` tem. Se um dia existir um que não tenha, o
        # registro continua válido: diz quem aprovou o quê pelo nome do gate.
        linhas.append("- **Artefatos:** nenhum artefato numerado corresponde a este gate.")
    else:
        linhas.append("- **Artefatos revisados:**")
        for nome in esperados:
            alvo = demand.path / nome
            if alvo.exists():
                linhas.append(f"  - `{nome}` — sha256 `{_sha(alvo)[:16]}` ({alvo.stat().st_size} bytes)")
            else:
                # Não deveria acontecer: `transition` recusa avançar sem o artefato.
                # Se acontecer, o registro precisa dizer isso em vez de omitir a linha.
                linhas.append(f"  - `{nome}` — **AUSENTE em disco no momento da aprovação**")

    with caminho.open("a", encoding="utf-8") as fh:
        fh.write("\n".join(linhas) + "\n")
    return caminho


def registrados(demand: Demand) -> list[str]:
    """Gates que já têm aprovação registrada nesta demanda, na ordem do fluxo."""
    caminho = demand.path / NOME_ARQUIVO
    if not caminho.exists():
        return []
    texto = caminho.read_text(encoding="utf-8")
    return [g for g in STAGES_EXECUCAO if g.startswith("aguardando_") and f"\n## {g}\n" in texto]


def conferir(demand: Demand, gate: str) -> list[str]:
    """Artefatos cujo conteúdo mudou desde a aprovação registrada deste gate.

    Lista vazia = o que está em disco é o que foi aprovado. Usada por quem for
    auditar a entrega; não bloqueia nada por si.
    """
    caminho = demand.path / NOME_ARQUIVO
    if not caminho.exists():
        return []
    texto = caminho.read_text(encoding="utf-8")
    bloco = texto.split(f"\n## {gate}\n")
    if len(bloco) < 2:
        return []
    # Último registro deste gate — um gate pode ser reaprovado depois de correção.
    corpo = bloco[-1].split("\n## ")[0]

    divergentes = []
    for nome in artefatos_do_gate(gate):
        marca = f"`{nome}` — sha256 `"
        if marca not in corpo:
            continue
        registrado = corpo.split(marca, 1)[1].split("`", 1)[0]
        alvo = demand.path / nome
        if not alvo.exists() or _sha(alvo)[:16] != registrado:
            divergentes.append(nome)
    return divergentes
