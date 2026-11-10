"""Descobre o que compõe um agente do Agentforce numa org, para promover de
uma sandbox para outra (2026-11-10, Eplast: o agente foi construído direto na
QA e a DEV ficou para trás — sem trazer de volta, a esteira constrói em cima
de uma DEV que não tem o que já existe).

Só lê. Recebe o nome do agente (Bot) e uma org já autenticada, e faz uma
busca em largura pelos nomes que aparecem nos arquivos:

  Bot → GenAiPlannerBundle → GenAiPlugin (tópicos) → GenAiFunction (ações)
      → Flow / ApexClass / GenAiPromptTemplate que as ações chamam
      → Flow / ApexClass que esses chamam (+ a classe de teste <Classe>Test)

O vínculo é por nome: um componente entra quando o nome dele aparece num
arquivo já incluído. Pode trazer algo a mais (um nome que coincide) — por
isso o resultado vira PR para alguém revisar antes de ir para a DEV, e o
deploy de validação na DEV acusa o que faltar (campo, objeto, permissão).

Saída: package.xml no caminho pedido e um resumo em markdown no stdout.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

TIPOS_AGENTE = ["Bot", "GenAiPlannerBundle", "GenAiPlugin", "GenAiFunction", "GenAiPromptTemplate"]
TIPOS_CODIGO = ["Flow", "ApexClass"]
API = "64.0"


def sf(args: list[str]) -> dict:
    proc = subprocess.run(["sf", *args, "--json"], capture_output=True, text=True, timeout=900)
    try:
        return json.loads(proc.stdout or "{}")
    except ValueError:
        return {}


def listar(tipo: str, org: str) -> set[str]:
    res = sf(["org", "list", "metadata", "--metadata-type", tipo, "--target-org", org, "--api-version", API])
    itens = res.get("result") or []
    if isinstance(itens, dict):
        itens = [itens]
    # Só o que é da org (sem namespace de pacote gerenciado).
    return {i["fullName"] for i in itens if i.get("fullName") and not i.get("namespacePrefix")}


def package_xml(componentes: dict[str, set[str]]) -> str:
    linhas = ['<?xml version="1.0" encoding="UTF-8"?>', '<Package xmlns="http://soap.sforce.com/2006/04/metadata">']
    for tipo in sorted(componentes):
        nomes = sorted(componentes[tipo])
        if not nomes:
            continue
        linhas.append("    <types>")
        linhas += [f"        <members>{n}</members>" for n in nomes]
        linhas.append(f"        <name>{tipo}</name>")
        linhas.append("    </types>")
    linhas += [f"    <version>{API}</version>", "</Package>", ""]
    return "\n".join(linhas)


def retrieve(componentes: dict[str, set[str]], org: str, destino: Path) -> list[Path]:
    """Retrieve num projeto temporário; devolve os arquivos trazidos."""
    destino.mkdir(parents=True, exist_ok=True)
    (destino / "sfdx-project.json").write_text(
        json.dumps({"packageDirectories": [{"path": "force-app", "default": True}], "sourceApiVersion": API})
    )
    (destino / "force-app").mkdir(exist_ok=True)
    (destino / "package.xml").write_text(package_xml(componentes))
    subprocess.run(
        ["sf", "project", "retrieve", "start", "--manifest", "package.xml", "--target-org", org, "--wait", "30", "--json"],
        cwd=destino,
        capture_output=True,
        text=True,
        timeout=1800,
    )
    return [p for p in (destino / "force-app").rglob("*") if p.is_file()]


def nomes_citados(arquivos: list[Path], conhecidos: dict[str, set[str]]) -> dict[str, set[str]]:
    texto = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in arquivos)
    palavras = set(re.findall(r"[A-Za-z][A-Za-z0-9_]*", texto))
    return {tipo: nomes & palavras for tipo, nomes in conhecidos.items()}


def main() -> int:
    agente, org, saida = sys.argv[1], sys.argv[2], Path(sys.argv[3])
    conhecidos = {t: listar(t, org) for t in TIPOS_AGENTE + TIPOS_CODIGO}
    bots = conhecidos["Bot"]
    if agente not in bots:
        print(f"Agente `{agente}` não existe como Bot em {org}. Bots encontrados: {', '.join(sorted(bots)) or 'nenhum'}.")
        return 1

    incluidos: dict[str, set[str]] = {t: set() for t in conhecidos}
    incluidos["Bot"].add(agente)
    fronteira = {t: set(v) for t, v in incluidos.items()}
    tmp = Path(tempfile.mkdtemp(prefix="agentforce-"))
    for rodada in range(6):
        if not any(fronteira.values()):
            break
        arquivos = retrieve(fronteira, org, tmp / f"r{rodada}")
        novos = nomes_citados(arquivos, conhecidos)
        # Classe Apex citada traz a classe de teste dela, se existir.
        for c in list(novos["ApexClass"]):
            if f"{c}Test" in conhecidos["ApexClass"]:
                novos["ApexClass"].add(f"{c}Test")
        fronteira = {t: novos[t] - incluidos[t] for t in conhecidos}
        for t in conhecidos:
            incluidos[t] |= fronteira[t]
    shutil.rmtree(tmp, ignore_errors=True)

    saida.write_text(package_xml(incluidos))
    total = sum(len(v) for v in incluidos.values())
    print(f"### Componentes do agente `{agente}` em `{org}` ({total})\n")
    for tipo in TIPOS_AGENTE + TIPOS_CODIGO:
        if incluidos[tipo]:
            print(f"- **{tipo}** ({len(incluidos[tipo])}): " + ", ".join(f"`{n}`" for n in sorted(incluidos[tipo])))
    print("\nVínculo por nome: revise no PR se não veio algo a mais por coincidência de nome.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
