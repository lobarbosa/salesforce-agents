#!/usr/bin/env python3
"""Confere no DNS público a autenticação do domínio de envio de e-mail (SPF, DMARC, DKIM).

Primeira evidência automática da skill `mc-arquitetura-da-conta` (2026-11-28): o agente não se
conecta à conta do Marketing Cloud, mas o DNS do domínio de envio é público. Lê os registros
TXT com `dig` (presente nas máquinas do GitHub Actions) e, sem ele, por DNS sobre HTTPS.

Uso: mc_dns_remetente.py <domínio> [--seletor-dkim <seletor> ...]
Imprime uma tabela em markdown (item, valor encontrado, situação, severidade se falha) e sai 0.
Nada aqui é dado pessoal: são registros públicos do domínio.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request

_DOMINIO = re.compile(r"^(?=.{1,253}$)([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$")
_SELETOR = re.compile(r"^[A-Za-z0-9_-]{1,63}$")
# Mecanismos do SPF que custam consulta de DNS (RFC 7208, limite de 10).
_CONSULTA = re.compile(r"^[+~?-]?(include:|a\b|a:|mx\b|mx:|ptr\b|ptr:|exists:|redirect=)", re.I)


def juntar(linha: str) -> str:
    """Um registro TXT longo vem em pedaços entre aspas, que se juntam sem espaço (RFC 7208)."""
    partes = re.findall(r'"((?:[^"\\]|\\.)*)"', linha)
    return "".join(partes) if partes else linha.strip()


def txt(nome: str) -> list[str]:
    """Registros TXT do nome, com os pedaços de cada registro já juntos."""
    if shutil.which("dig"):
        saida = subprocess.run(["dig", "+short", "TXT", nome], capture_output=True, text=True, timeout=20, check=False).stdout
        return [juntar(linha) for linha in saida.splitlines() if linha.strip()]
    url = "https://dns.google/resolve?" + urllib.parse.urlencode({"name": nome, "type": "TXT"})
    with urllib.request.urlopen(url, timeout=20) as r:  # noqa: S310 (URL fixa)
        dados = json.load(r)
    return [juntar(a["data"]) for a in dados.get("Answer", []) if a.get("type") == 16]


def avaliar_spf(registros: list[str]) -> tuple[str, str, str]:
    spfs = [r for r in registros if r.lower().startswith("v=spf1")]
    if not spfs:
        return "", "ausente", "crítica"
    if len(spfs) > 1:
        return " | ".join(spfs), "mais de um registro SPF (inválido)", "crítica"
    spf = spfs[0]
    consultas = sum(1 for termo in spf.split()[1:] if _CONSULTA.match(termo))
    if consultas > 10:
        return spf, f"{consultas} consultas de DNS (limite 10)", "alta"
    if re.search(r"[+?]all\b", spf) or not re.search(r"[~-]all\b|redirect=", spf):
        return spf, "termina sem ~all ou -all", "alta"
    return spf, "atende", ""


def avaliar_dmarc(registros: list[str]) -> tuple[str, str, str]:
    dmarcs = [r for r in registros if r.lower().startswith("v=dmarc1")]
    if not dmarcs:
        return "", "ausente", "alta"
    d = dmarcs[0]
    politica = re.search(r"\bp=(\w+)", d, re.I)
    p = politica.group(1).lower() if politica else ""
    if p not in {"none", "quarantine", "reject"}:
        return d, "sem política p= válida", "alta"
    if p == "none":
        return d, "p=none: só monitora" + ("" if "rua=" in d.lower() else ", e sem relatório rua"), "média"
    return d, f"atende (p={p})", ""


def avaliar_dkim(registros: list[str]) -> tuple[str, str, str]:
    chaves = [r for r in registros if "p=" in r.lower()]
    if not chaves:
        return "", "ausente para este seletor", "crítica"
    if re.search(r"\bp=\s*(;|$)", chaves[0]):
        return chaves[0][:80], "chave revogada (p vazio)", "crítica"
    return chaves[0][:80] + ("…" if len(chaves[0]) > 80 else ""), "atende", ""


def main(argv: list[str]) -> int:
    if not argv or not _DOMINIO.match(argv[0]):
        print(__doc__, file=sys.stderr)
        return 2
    dominio = argv[0].lower()
    seletores = [argv[i + 1] for i, a in enumerate(argv[:-1]) if a == "--seletor-dkim"]
    if any(not _SELETOR.match(s) for s in seletores):
        print("seletor DKIM inválido", file=sys.stderr)
        return 2
    linhas = [("SPF", dominio, *avaliar_spf(txt(dominio))), ("DMARC", f"_dmarc.{dominio}", *avaliar_dmarc(txt(f"_dmarc.{dominio}")))]
    for s in seletores:
        nome = f"{s}._domainkey.{dominio}"
        linhas.append((f"DKIM ({s})", nome, *avaliar_dkim(txt(nome))))
    print(f"## Autenticação do domínio de envio: `{dominio}`\n")
    print("| Item | Registro | Encontrado | Situação | Severidade |\n| --- | --- | --- | --- | --- |")
    for item, nome, valor, situacao, sev in linhas:
        valor = valor.replace("|", "\\|") or "—"
        print(f"| {item} | `{nome}` | `{valor}` | {situacao} | {sev or '—'} |")
    if not seletores:
        print("\nDKIM não conferido: informe o seletor (está na configuração do domínio na conta ou no cabeçalho de um e-mail enviado).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
