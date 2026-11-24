#!/usr/bin/env python3
"""Reduz perfis e permission sets do pacote de QA ao que a demanda acrescentou.

Usado pelo `scripts/implantar-build-qa.sh`, na cópia de trabalho do job (que é
descartada no fim), antes do deploy na sandbox de QA. Perfil e permission set
são arquivos grandes, trazidos inteiros da org de dev: levá-los inteiros à QA
derruba o deploy por qualquer item que exista só na dev (achado SOMOSAGILITY-26,
2026-11-20: o permission set `DiretorComercial` citava um app que a QA não
tem). A saída que o builder achou, enxugar os arquivos-fonte na branch, apagaria
o resto do conteúdo deles no merge para a `main`. Por isso o enxugamento é aqui,
na hora do deploy, e os arquivos-fonte continuam inteiros.

Uso: `permissoes_so_o_diff.py <ref-base> <cliente> <arquivo-de-argumentos>`.

Para cada `--source-dir` de `profiles/` ou `permissionsets/` que já existia na
ref base, regrava o arquivo só com os elementos de primeiro nível que não
existiam na base, idênticos, mais os campos que o deploy exige (`label`,
`description`, `license`, `hasActivationRequired` no permission set; `custom`
no perfil). Arquivo sem nada novo sai do pacote. Arquivo novo na branch fica
inteiro. Imprime um resumo, um arquivo por linha.
"""

from __future__ import annotations

import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

_PASTAS = ("/profiles/", "/permissionsets/")
_OBRIGATORIOS = {
    "PermissionSet": {"label", "description", "license", "hasActivationRequired"},
    "Profile": {"custom"},
}


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _canon(el: ET.Element) -> tuple:
    """Forma comparável de um elemento, sem espaços de formatação."""
    return (
        _local(el.tag),
        (el.text or "").strip(),
        tuple(sorted(el.attrib.items())),
        tuple(_canon(f) for f in el),
    )


def reduzir(base_xml: str, atual_xml: str) -> tuple[str | None, int, int]:
    """O XML só com o que é novo; None se não há nada novo. Devolve (xml, novos, total)."""
    base = ET.fromstring(base_xml)
    atual = ET.fromstring(atual_xml)
    vistos = {_canon(f) for f in base}
    obrigatorios = _OBRIGATORIOS.get(_local(atual.tag), set())
    filhos = list(atual)
    manter = []
    novos = 0
    for filho in filhos:
        if _canon(filho) not in vistos:
            manter.append(filho)
            novos += 1
        elif _local(filho.tag) in obrigatorios:
            manter.append(filho)
    if novos == 0:
        return None, 0, len(filhos)
    for filho in filhos:
        if filho not in manter:
            atual.remove(filho)
    ns = atual.tag[1:].split("}", 1)[0] if atual.tag.startswith("{") else ""
    if ns:
        ET.register_namespace("", ns)
    ET.indent(atual, space="    ")
    corpo = ET.tostring(atual, encoding="unicode")
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + corpo + "\n", novos, len(filhos)


def _na_base(ref: str, caminho: str) -> str | None:
    feito = subprocess.run(["git", "show", f"{ref}:{caminho}"], capture_output=True)
    return feito.stdout.decode("utf-8") if feito.returncode == 0 else None


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("uso: permissoes_so_o_diff.py <ref-base> <cliente> <arquivo-de-argumentos>", file=sys.stderr)
        return 64
    ref, cliente, arquivo = argv[1], argv[2], Path(argv[3])
    args = arquivo.read_text(encoding="utf-8").splitlines()
    saida: list[str] = []
    i = 0
    while i < len(args):
        if args[i] == "--source-dir" and i + 1 < len(args):
            caminho = args[i + 1]
            local = Path("clients") / cliente / caminho
            if any(p in "/" + caminho for p in _PASTAS) and local.is_file():
                base = _na_base(ref, local.as_posix())
                if base is None:
                    print(f"{caminho}: novo na demanda, vai inteiro")
                else:
                    reduzido, novos, total = reduzir(base, local.read_text(encoding="utf-8"))
                    if reduzido is None:
                        print(f"{caminho}: nada novo em relação à base, fora do pacote")
                        i += 2
                        continue
                    local.write_text(reduzido, encoding="utf-8")
                    print(f"{caminho}: {novos} de {total} elementos são da demanda")
            saida += args[i : i + 2]
            i += 2
        else:
            saida.append(args[i])
            i += 1
    arquivo.write_text("\n".join(saida) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
