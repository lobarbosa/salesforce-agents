"""Transforma o JSON de `sf project deploy start --dry-run` num comentário de PR
(promover-qa-dev.yml): ok, ou a tabela do que falharia na org de destino."""

from __future__ import annotations

import json
import sys


def resumo(d: dict) -> str:
    r = d.get("result") or {}
    falhas = (r.get("details") or {}).get("componentFailures") or []
    if isinstance(falhas, dict):
        falhas = [falhas]
    if d.get("status") == 0 and not falhas:
        return (
            "### Validação na DEV: ok\n\n"
            "O deploy passaria na DEV sem erro. Pode aprovar o PR e rodar o workflow com `modo: implantar`.\n"
        )
    linhas = [f"### Validação na DEV: {len(falhas) or 'erro'} problema(s)\n", "| Tipo | Componente | Problema |", "|---|---|---|"]
    for f in falhas[:60]:
        problema = str(f.get("problem", "")).replace("|", "/").replace("\n", " ")[:300]
        linhas.append(f"| {f.get('componentType', '')} | `{f.get('fullName', '')}` | {problema} |")
    if not falhas:
        linhas.append(f"| — | — | {str(d.get('message', '')).replace('|', '/')[:300]} |")
    linhas.append(
        "\nO que falta na DEV (campo, objeto, licença ou recurso do Agentforce habilitado) "
        "precisa existir lá antes de implantar."
    )
    return "\n".join(linhas) + "\n"


if __name__ == "__main__":
    try:
        dados = json.load(open(sys.argv[1], encoding="utf-8"))
    except (OSError, ValueError):
        dados = {"status": 1, "message": "o sf não devolveu um resultado legível — veja o log do job"}
    print(resumo(dados))
