#!/usr/bin/env python3
"""Monta o package.xml de uma promoção QA → DEV a partir de componentes nomeados.

Usado pelo `promover-qa-dev.yml` quando o que falta na DEV não é um agente
(que tem descoberta própria em `agentforce_dependencias.py`), e sim um
componente que já existe na QA e nunca foi trazido (achado EPLAST-49,
2026-11-21: o LWC `Central_Comercial` existe na QAS e não na DEV, e a demanda
pede um atalho dentro dele).

Uso: `manifest_componentes.py "<Tipo:Nome>[,<Tipo:Nome>...]" <saida.xml>`.
Exemplo: `"LightningComponentBundle:Central_Comercial,ApexClass:CentralComercialController"`.
O que o componente usa e não foi listado aparece na validação (dry-run) na DEV,
comentada no PR; aí se acrescenta à lista e roda de novo.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

API = "66.0"
_ITEM = re.compile(r"^[A-Za-z]+:[A-Za-z0-9_.\-]+$")


def ler(lista: str) -> dict[str, set[str]]:
    componentes: dict[str, set[str]] = {}
    for item in (p.strip() for p in lista.split(",")):
        if not item:
            continue
        if not _ITEM.match(item):
            raise ValueError(
                f"item inválido: {item!r} (use Tipo:Nome, ex.: LightningComponentBundle:Central_Comercial)"
            )
        tipo, nome = item.split(":", 1)
        componentes.setdefault(tipo, set()).add(nome)
    if not componentes:
        raise ValueError("nenhum componente informado")
    return componentes


def package_xml(componentes: dict[str, set[str]]) -> str:
    linhas = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
    ]
    for tipo in sorted(componentes):
        linhas.append("    <types>")
        linhas += [f"        <members>{n}</members>" for n in sorted(componentes[tipo])]
        linhas.append(f"        <name>{tipo}</name>")
        linhas.append("    </types>")
    linhas += [f"    <version>{API}</version>", "</Package>", ""]
    return "\n".join(linhas)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            'uso: manifest_componentes.py "<Tipo:Nome>[,...]" <saida.xml>',
            file=sys.stderr,
        )
        return 64
    try:
        componentes = ler(argv[1])
    except ValueError as exc:
        print(f"::error::{exc}", file=sys.stderr)
        return 65
    Path(argv[2]).write_text(package_xml(componentes), encoding="utf-8")
    print("## Componentes pedidos\n")
    for tipo in sorted(componentes):
        for nome in sorted(componentes[tipo]):
            print(f"- `{tipo}`: `{nome}`")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
