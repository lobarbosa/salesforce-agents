#!/usr/bin/env python3
"""Scanner de PII para clients/<cliente>/**.md (CLAUDE.md guardrail #2).

demanda.md e os artefatos das 7 etapas são texto livre — ninguém filtra o que
um consultor ou agente escreve ali. Este script é a rede de segurança técnica
que falta: roda em CI sobre todo arquivo .md novo ou alterado dentro de
clients/<cliente>/ e falha o PR se achar CPF, e-mail ou telefone formatados.

Não substitui a disciplina de quem escreve — complementa. Um CPF sem máscara
("12345678900") ou um nome de variável que pareça e-mail sem ser PII real
passam batido de propósito: o objetivo é pegar o padrão óbvio e formatado que
delata PII real colada direto de um sistema (planilha, e-mail do cliente,
print de tela), não fazer parsing semântico de texto livre.

Uso: verificar_pii.py <arquivo> [<arquivo> ...]
Saída: lista o que achou (mascarado, nunca o valor real) e sai 1 se algo foi
encontrado; 0 se os arquivos estão limpos.
"""

from __future__ import annotations

import re
import sys

CPF = re.compile(r"\b\d{3}\.\d{3}\.\d{3}-\d{2}\b")
EMAIL = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
# Telefone BR formatado: (11) 91234-5678, 11 91234-5678, +55 11 91234-5678.
TELEFONE = re.compile(r"\b(?:\+?55\s?)?\(?\d{2}\)?\s?9?\d{4}-\d{4}\b")

PADROES = {
    "CPF": CPF,
    "e-mail": EMAIL,
    "telefone": TELEFONE,
}


def mascarar(valor: str) -> str:
    """Só o suficiente pra identificar o tipo achado, nunca o dado em si."""
    if len(valor) <= 4:
        return "*" * len(valor)
    return valor[:2] + "*" * (len(valor) - 4) + valor[-2:]


def verificar(caminho: str) -> list[str]:
    try:
        with open(caminho, encoding="utf-8", errors="ignore") as f:
            linhas = f.readlines()
    except OSError as e:
        print(f"::warning::não consegui ler {caminho}: {e}")
        return []

    achados = []
    for n, linha in enumerate(linhas, start=1):
        for tipo, padrao in PADROES.items():
            for m in padrao.finditer(linha):
                achados.append(f"{caminho}:{n}: possível {tipo} ({mascarar(m.group())})")
    return achados


def main(argv: list[str]) -> int:
    arquivos = [a for a in argv if a.endswith(".md")]
    if not arquivos:
        return 0

    todos_achados = []
    for arquivo in arquivos:
        todos_achados.extend(verificar(arquivo))

    if todos_achados:
        print("Possível PII encontrada (guardrail #2, LGPD — CLAUDE.md):")
        for linha in todos_achados:
            print(f"  {linha}")
        print(
            "\nSe for falso positivo, ajuste o texto pra não bater o padrão "
            "(ex.: mascare o CPF ao citar um caso). Se for PII real, remova "
            "antes de commitar — nada aqui deveria ter CPF/e-mail/telefone de "
            "cliente (guardrail #2)."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
