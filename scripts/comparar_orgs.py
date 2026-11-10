"""Compara dois retrieves do mesmo manifest (QA e DEV) arquivo a arquivo e
escreve um relatório em markdown (promover-qa-dev.yml, modo comparar).

Achado de 2026-11-10 (Eplast): o agente foi migrado da QA para a DEV à mão, e
"está tudo lá?" não tem resposta sem olhar componente por componente. Só lê.

Diferenças só de espaço em branco não contam. Uso:
    python3 comparar_orgs.py <dir-qa> <dir-dev>
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def normalizar(texto: str) -> str:
    return re.sub(r"\s+", " ", texto).strip()


def arquivos(raiz: Path) -> dict[str, str]:
    base = raiz / "force-app"
    if not base.is_dir():
        return {}
    return {
        str(p.relative_to(base)): normalizar(p.read_text(encoding="utf-8", errors="ignore"))
        for p in base.rglob("*")
        if p.is_file()
    }


def comparar(qa: dict[str, str], dev: dict[str, str]) -> dict[str, list[str]]:
    return {
        "faltando": sorted(k for k in qa if k not in dev),
        "diferente": sorted(k for k in qa if k in dev and qa[k] != dev[k]),
        "igual": sorted(k for k in qa if k in dev and qa[k] == dev[k]),
    }


def relatorio(r: dict[str, list[str]]) -> str:
    total = sum(len(v) for v in r.values())
    linhas = [f"### QA × DEV: {len(r['igual'])} de {total} arquivos iguais\n"]
    if not r["faltando"] and not r["diferente"]:
        linhas.append("Tudo o que compõe o agente na QA está na DEV, igual. Pode seguir com as construções na DEV.")
        return "\n".join(linhas) + "\n"
    if r["faltando"]:
        linhas.append(f"**Faltando na DEV ({len(r['faltando'])}):**")
        linhas += [f"- `{k}`" for k in r["faltando"]]
        linhas.append("")
    if r["diferente"]:
        linhas.append(f"**Diferente na DEV ({len(r['diferente'])}):**")
        linhas += [f"- `{k}`" for k in r["diferente"]]
        linhas.append("")
    linhas.append(
        "Um item pode faltar porque a DEV não tem o recurso habilitado (Agentforce/Einstein) "
        "ou porque não foi migrado. Diferença pode ser versão mais nova numa das duas."
    )
    return "\n".join(linhas) + "\n"


if __name__ == "__main__":
    print(relatorio(comparar(arquivos(Path(sys.argv[1])), arquivos(Path(sys.argv[2])))))
