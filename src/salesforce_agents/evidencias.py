"""Evidências de teste do QA: o que vira o anexo "Evidências de teste" no card.

Decisão do responsável (2026-11-16): além do roteiro do cliente, o card recebe um
arquivo com a evidência do que o QA executou. Até aqui a evidência ficava só no
git (`05-testes.md`), e a captura de tela era mostrada ao agente e descartada:
quem homologa ou audita não via a tela que o QA viu.

O arquivo é montado pelo Squad OS (lib/evidencias-anexo.ts) com:
- o roteiro executado (`05-testes.md`; se a rodada foi reprovada e arquivada, o
  `05-testes-rodada-<n>.md` mais recente), e
- as capturas de tela salvas por `qa_browser_screenshot` em `evidencias/`.

As capturas são da rodada: a pasta é esvaziada antes de cada sessão de QA, como
o roteiro do cliente. Só tela de registro de teste (guardrail #2).
"""

from __future__ import annotations

import base64
import hashlib
import json
import re
import unicodedata
from pathlib import Path

PASTA = "evidencias"
INDICE = "indice.json"
ROTEIRO_DO_QA = "05-testes.md"

# O payload do sync passa por uma função serverless (teto de 4,5 MB no corpo).
LIMITE_CONTEUDO = 80_000
MAX_IMAGENS = 12
MAX_BYTES_IMAGENS = 2_500_000


def pasta(demanda: Path) -> Path:
    return demanda / PASTA


def descartar(demanda: Path) -> None:
    """Esvazia as capturas antes de uma nova rodada de QA: a sessão tira outras."""
    alvo = pasta(demanda)
    if not alvo.is_dir():
        return
    for arquivo in alvo.iterdir():
        if arquivo.is_file():
            arquivo.unlink()
    try:
        alvo.rmdir()
    except OSError:
        pass


def _slug(texto: str) -> str:
    sem_acento = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "-", sem_acento.lower()).strip("-")[:40] or "tela"


def _ler_indice(alvo: Path) -> list[dict]:
    try:
        dados = json.loads((alvo / INDICE).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return []
    return [d for d in dados if isinstance(d, dict) and d.get("arquivo")] if isinstance(dados, list) else []


def salvar_captura(demanda: Path, imagem: bytes, legenda: str) -> Path:
    """Grava uma captura (JPEG) na pasta da demanda e registra a legenda. Devolve o caminho."""
    alvo = pasta(demanda)
    alvo.mkdir(parents=True, exist_ok=True)
    indice = _ler_indice(alvo)
    nome = f"{len(indice) + 1:02d}-{_slug(legenda)}.jpg"
    (alvo / nome).write_bytes(imagem)
    indice.append({"arquivo": nome, "legenda": legenda.strip()[:200]})
    (alvo / INDICE).write_text(json.dumps(indice, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return alvo / nome


def conteudo(demanda: Path) -> str:
    """O roteiro executado mais recente: o vigente ou, se foi reprovado, o último arquivado."""
    vigente = demanda / ROTEIRO_DO_QA
    if vigente.exists():
        return vigente.read_text(encoding="utf-8")[:LIMITE_CONTEUDO]

    def numero(p: Path) -> int:
        m = re.search(r"rodada-(\d+)\.md$", p.name)
        return int(m.group(1)) if m else 0

    rodadas = sorted(demanda.glob("05-testes-rodada-*.md"), key=numero)
    return rodadas[-1].read_text(encoding="utf-8")[:LIMITE_CONTEUDO] if rodadas else ""


def imagens(demanda: Path) -> list[dict]:
    """Capturas da rodada, na ordem em que foram tiradas, dentro do teto do payload."""
    alvo = pasta(demanda)
    saida: list[dict] = []
    total = 0
    for item in _ler_indice(alvo)[:MAX_IMAGENS]:
        arquivo = alvo / Path(str(item["arquivo"])).name
        if not arquivo.is_file():
            continue
        dados = arquivo.read_bytes()
        if total + len(dados) > MAX_BYTES_IMAGENS:
            break
        total += len(dados)
        saida.append(
            {
                "nome": arquivo.name,
                "legenda": str(item.get("legenda", "")),
                "jpeg_base64": base64.b64encode(dados).decode("ascii"),
            }
        )
    return saida


def payload(demanda: Path) -> dict:
    """Campos do sync: texto, capturas e um hash para o Squad OS só refazer o PDF se mudou."""
    texto = conteudo(demanda)
    capturas = imagens(demanda) if texto else []
    h = hashlib.sha256(texto.encode("utf-8"))
    for c in capturas:
        h.update(c["nome"].encode("utf-8"))
        h.update(c["legenda"].encode("utf-8"))
        h.update(c["jpeg_base64"].encode("ascii"))
    return {
        "evidencias_teste": texto,
        "evidencias_imagens": capturas,
        "evidencias_hash": h.hexdigest() if texto else "",
    }
