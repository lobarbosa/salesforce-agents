#!/usr/bin/env python3
"""Diagnóstico de chave externa repetida numa org de sandbox, só com contagens.

Motivo (2026-11-26, Eplast): a integração de devoluções do Protheus passou a
receber HTTP 400 `DUPLICATE_EXTERNAL_ID` ao gravar `SalesReturn__c`, porque o
registro aponta a conta pelo `ProtheusId__c` e mais de uma conta tem o mesmo
valor. A pergunta que decide a correção é se essas contas são duplicatas de
verdade (mesmo código e mesma loja) ou lojas diferentes do mesmo cliente do
ERP (mesmo código, loja diferente). No Protheus o cliente é código + loja; a
integração grava o código em `ProtheusId__c` e a loja em `Store__c`
(`UpdateAccountWithProtheusInfo`), e os pedidos vão ao ERP com os dois
(`OrderAdapter`). Apagar o código de uma loja legítima quebraria os pedidos
dela.

Só leitura. Só metadata e contagens (guardrail #2): nenhum nome, documento,
contato ou valor. Para o código pedido em `--codigo`, lista os Ids das contas,
a loja e quantos pedidos, oportunidades e devoluções cada uma tem.

Uso: diagnostico_chave_externa.py --target-org sbx-<cliente>-<dev|qa>
     [--objeto Account] [--campo ProtheusId__c] [--loja Store__c]
     [--codigo 000922] [--ids 001...,001...]
Escreve o relatório em Markdown na saída padrão.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict

_NOME_API = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")
_CODIGO = re.compile(r"^[A-Za-z0-9._\-]{1,40}$")
_ID_SF = re.compile(r"^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$")
MAX_GRUPOS = 2000


# --- parte pura (testada sem org) -------------------------------------------


def classificar(pares: list[dict], campo: str, loja: str) -> dict:
    """Classifica cada código repetido pelas lojas das contas que o usam.

    `pares` = linhas de `SELECT campo, loja, COUNT(Id) n ... GROUP BY campo, loja`
    restritas aos códigos que aparecem em mais de uma conta.

    - lojas_diferentes: cada conta do código tem uma loja própria (provável
      cadastro legítimo de lojas do mesmo cliente do ERP);
    - mesma_loja: alguma combinação código + loja aparece em mais de uma conta
      (duplicata de verdade);
    - sem_loja: alguma conta do código não tem loja preenchida.
    """
    por_codigo: dict[str, list[tuple[str | None, int]]] = defaultdict(list)
    for linha in pares:
        por_codigo[str(linha.get(campo))].append((linha.get(loja), int(linha.get("n") or 0)))

    resultado = {"lojas_diferentes": [], "mesma_loja": [], "sem_loja": []}
    for codigo, grupos in sorted(por_codigo.items()):
        if any(l in (None, "") for l, _ in grupos):
            resultado["sem_loja"].append(codigo)
        elif any(n > 1 for _, n in grupos):
            resultado["mesma_loja"].append(codigo)
        else:
            resultado["lojas_diferentes"].append(codigo)
    return resultado


def contas_afetadas(pares: list[dict]) -> int:
    return sum(int(l.get("n") or 0) for l in pares)


# --- consultas -------------------------------------------------------------


def _consultar(org: str, soql: str) -> list[dict]:
    args = ["sf", "data", "query", "--query", soql, "--target-org", org, "--json"]
    proc = subprocess.run(args, capture_output=True, text=True, timeout=600, check=False)
    try:
        corpo = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        corpo = {}
    if proc.returncode != 0 or corpo.get("status") not in (0, None):
        msg = corpo.get("message") or proc.stderr.strip() or "falha sem mensagem"
        raise RuntimeError(f"consulta recusada: {msg[:300]}")
    registros = (corpo.get("result") or {}).get("records") or []
    for r in registros:
        r.pop("attributes", None)
    return registros


def _contar(org: str, soql_count: str) -> int:
    args = ["sf", "data", "query", "--query", soql_count, "--target-org", org, "--json"]
    proc = subprocess.run(args, capture_output=True, text=True, timeout=600, check=False)
    corpo = json.loads(proc.stdout or "{}")
    if proc.returncode != 0:
        raise RuntimeError(f"contagem recusada: {(corpo.get('message') or '')[:300]}")
    return int((corpo.get("result") or {}).get("totalSize") or 0)


def linhas_de_definicao(describe: dict, campos: list[str]) -> list[str]:
    """Tabela de definição dos campos a partir do `sf sobject describe --json`."""
    por_nome = {f.get("name"): f for f in (describe.get("result") or {}).get("fields") or []}
    out = [
        "## Definição dos campos",
        "",
        "| Campo | Tipo | Tamanho | Chave externa | Único | Diferencia maiúsculas |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for nome in campos:
        f = por_nome.get(nome)
        if not f:
            out.append(f"| `{nome}` | não existe nesta org | | | | |")
            continue
        sim = lambda v: "sim" if v else "não"
        out.append(
            f"| `{nome}` | {f.get('type')} | {f.get('length')} | {sim(f.get('externalId'))} | "
            f"{sim(f.get('unique'))} | {sim(f.get('caseSensitive'))} |"
        )
    return out + [""]


def definicao_dos_campos(org: str, obj: str, campos: list[str]) -> list[str]:
    proc = subprocess.run(
        ["sf", "sobject", "describe", "--sobject", obj, "--target-org", org, "--json"],
        capture_output=True, text=True, timeout=600, check=False,
    )
    try:
        return linhas_de_definicao(json.loads(proc.stdout or "{}"), campos)
    except json.JSONDecodeError:
        return ["_Definição dos campos indisponível._", ""]


def _lista_soql(valores: list[str]) -> str:
    return ",".join("'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'" for v in valores)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--target-org", required=True)
    ap.add_argument("--objeto", default="Account")
    ap.add_argument("--campo", default="ProtheusId__c")
    ap.add_argument("--loja", default="Store__c")
    ap.add_argument("--codigo", default="")
    ap.add_argument("--ids", default="")
    a = ap.parse_args(argv)

    if not re.match(r"^sbx-[a-z0-9-]+-(dev|qa)$", a.target_org):
        print(f"Recusado: '{a.target_org}' não é uma sandbox da esteira.", file=sys.stderr)
        return 2
    for nome in (a.objeto, a.campo, a.loja):
        if not _NOME_API.match(nome):
            print(f"Recusado: nome de API inválido '{nome}'.", file=sys.stderr)
            return 2
    if a.codigo and not _CODIGO.match(a.codigo):
        print("Recusado: código com caracteres inesperados.", file=sys.stderr)
        return 2
    ids = [i.strip() for i in a.ids.split(",") if i.strip()]
    if any(not _ID_SF.match(i) for i in ids):
        print("Recusado: Id de registro inválido.", file=sys.stderr)
        return 2

    org, obj, campo, loja = a.target_org, a.objeto, a.campo, a.loja
    out: list[str] = [f"# Diagnóstico de chave externa: `{obj}.{campo}` em `{org}`", ""]

    # 1. Como o campo está definido nesta org.
    out += definicao_dos_campos(org, obj, [campo, loja])

    # 2. Tamanho do problema.
    com_codigo = _contar(org, f"SELECT Id FROM {obj} WHERE {campo} != null")
    repetidos = _consultar(
        org,
        f"SELECT {campo}, COUNT(Id) n FROM {obj} WHERE {campo} != null "
        f"GROUP BY {campo} HAVING COUNT(Id) > 1 LIMIT {MAX_GRUPOS}",
    )
    codigos = [str(r[campo]) for r in repetidos]
    out += [
        "## Tamanho",
        "",
        f"- Registros com `{campo}` preenchido: **{com_codigo}**",
        f"- Códigos que aparecem em mais de um registro: **{len(codigos)}**"
        + (" (limite da consulta atingido)" if len(codigos) >= MAX_GRUPOS else ""),
        f"- Registros envolvidos nesses códigos: **{contas_afetadas(repetidos)}**",
        "",
    ]

    # 3. Duplicata de verdade ou lojas diferentes?
    if codigos:
        pares: list[dict] = []
        for i in range(0, len(codigos), 200):
            lote = codigos[i : i + 200]
            pares += _consultar(
                org,
                f"SELECT {campo}, {loja}, COUNT(Id) n FROM {obj} "
                f"WHERE {campo} IN ({_lista_soql(lote)}) GROUP BY {campo}, {loja}",
            )
        c = classificar(pares, campo, loja)
        out += [
            "## Natureza da repetição",
            "",
            "| Situação | Códigos |",
            "| --- | --- |",
            f"| Lojas diferentes do mesmo código (cadastro provavelmente legítimo) | {len(c['lojas_diferentes'])} |",
            f"| Mesmo código e mesma loja em mais de um registro (duplicata) | {len(c['mesma_loja'])} |",
            f"| Algum registro do código sem `{loja}` | {len(c['sem_loja'])} |",
            "",
        ]
        if a.codigo:
            for nome, lista in c.items():
                if a.codigo in lista:
                    out += [f"O código `{a.codigo}` está em: **{nome.replace('_', ' ')}**.", ""]

    # 4. O caso reportado, registro a registro (só Id, loja e contagens).
    alvo = []
    if a.codigo:
        alvo += _consultar(
            org,
            f"SELECT Id, {loja}, ParentId, CreatedDate, LastModifiedDate FROM {obj} "
            f"WHERE {campo} = {_lista_soql([a.codigo])} ORDER BY CreatedDate LIMIT 50",
        )
    if ids:
        ja = {r["Id"] for r in alvo}
        extra = [i for i in ids if i not in ja and i[:15] not in {x[:15] for x in ja}]
        if extra:
            alvo += _consultar(
                org,
                f"SELECT Id, {campo}, {loja}, ParentId, CreatedDate, LastModifiedDate FROM {obj} "
                f"WHERE Id IN ({_lista_soql(extra)})",
            )
        encontrados = {r["Id"][:15] for r in alvo}
        faltam = [i for i in ids if i[:15] not in encontrados]
    else:
        faltam = []

    if alvo and obj == "Account":
        ids_alvo = [r["Id"] for r in alvo]
        contagem: dict[str, dict[str, int]] = defaultdict(dict)
        for rotulo, soql in (
            ("pedidos", f"SELECT AccountId a, COUNT(Id) n FROM Order WHERE AccountId IN ({_lista_soql(ids_alvo)}) GROUP BY AccountId"),
            ("oportunidades", f"SELECT AccountId a, COUNT(Id) n FROM Opportunity WHERE AccountId IN ({_lista_soql(ids_alvo)}) GROUP BY AccountId"),
            ("devoluções", f"SELECT AccountId__c a, COUNT(Id) n FROM SalesReturn__c WHERE AccountId__c IN ({_lista_soql(ids_alvo)}) GROUP BY AccountId__c"),
            ("filhas", f"SELECT ParentId a, COUNT(Id) n FROM Account WHERE ParentId IN ({_lista_soql(ids_alvo)}) GROUP BY ParentId"),
        ):
            try:
                for r in _consultar(org, soql):
                    contagem[str(r["a"])][rotulo] = int(r["n"])
            except RuntimeError as e:
                out.append(f"_Contagem de {rotulo} indisponível: {e}_")
        titulo = f"`{a.codigo}`" if a.codigo else "os Ids informados"
        out += [
            f"## Registros de {titulo}",
            "",
            f"| Id | {campo} | Loja | Tem conta mãe | Criada | Pedidos | Oportunidades | Devoluções | Contas filhas |",
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
        for r in alvo:
            n = contagem.get(r["Id"], {})
            out.append(
                f"| `{r['Id']}` | {r.get(campo, a.codigo) or '—'} | {r.get(loja) or '—'} | "
                f"{'sim' if r.get('ParentId') else 'não'} | {str(r.get('CreatedDate'))[:10]} | "
                f"{n.get('pedidos', 0)} | {n.get('oportunidades', 0)} | {n.get('devoluções', 0)} | {n.get('filhas', 0)} |"
            )
        out.append("")
    if faltam:
        out += [f"Ids informados que não existem nesta org: {', '.join('`' + f + '`' for f in faltam)}.", ""]

    # 5. Devoluções sem conta (o efeito do erro, quando o registro entrou sem o vínculo).
    if obj == "Account":
        try:
            total_dev = _contar(org, "SELECT Id FROM SalesReturn__c")
            sem_conta = _contar(org, "SELECT Id FROM SalesReturn__c WHERE AccountId__c = null")
            out += ["## Devoluções", "", f"- Total de `SalesReturn__c`: **{total_dev}**; sem conta vinculada: **{sem_conta}**", ""]
        except (RuntimeError, json.JSONDecodeError) as e:
            out += [f"_Contagem de devoluções indisponível: {e}_", ""]

    # 6. As outras chaves que a devolução usa, e devoluções repetidas.
    if obj == "Account":
        out += ["## Outras chaves da devolução", "", "| Chave | Valores repetidos | Registros envolvidos |", "| --- | --- | --- |"]
        for rotulo, soql in OUTRAS_CHAVES:
            try:
                grupos = _consultar(org, soql)
                out.append(f"| {rotulo} | {len(grupos)} | {contas_afetadas(grupos)} |")
            except RuntimeError as e:
                out.append(f"| {rotulo} | indisponível: {str(e)[:80]} | |")
        out.append("")

    print("\n".join(out))
    return 0


# A devolução liga três registros (conta, filial e pedido) e é gravada por POST:
# `SalesReturn__c.ProtheusId__c` não é chave externa, então reenviar a mesma
# devolução cria outra. Estas contagens dizem se a filial também repete chave e
# se já há devolução gravada duas vezes (mesmo número e item).
OUTRAS_CHAVES = (
    ("`Branch__c.CodeERP__c` (filial)",
     "SELECT CodeERP__c, COUNT(Id) n FROM Branch__c WHERE CodeERP__c != null "
     f"GROUP BY CodeERP__c HAVING COUNT(Id) > 1 LIMIT {MAX_GRUPOS}"),
    ("`Account.CompanyDocument__c` (CNPJ)",
     "SELECT CompanyDocument__c, COUNT(Id) n FROM Account WHERE CompanyDocument__c != null "
     f"GROUP BY CompanyDocument__c HAVING COUNT(Id) > 1 LIMIT {MAX_GRUPOS}"),
    ("`SalesReturn__c` com mesmo `ProtheusId__c` e `Item__c`",
     "SELECT ProtheusId__c, Item__c, COUNT(Id) n FROM SalesReturn__c WHERE ProtheusId__c != null "
     f"GROUP BY ProtheusId__c, Item__c HAVING COUNT(Id) > 1 LIMIT {MAX_GRUPOS}"),
)


if __name__ == "__main__":
    sys.exit(main())
