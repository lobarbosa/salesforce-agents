"""Compara dois retrieves do mesmo manifest (QA e DEV) arquivo a arquivo e
escreve um relatório em markdown (promover-qa-dev.yml, modo comparar).

Achado de 2026-11-10 (Eplast): o agente foi migrado da QA para a DEV à mão, e
"está tudo lá?" não tem resposta sem olhar componente por componente. Só lê.

Diferenças só de espaço em branco não contam. Uso:
    python3 comparar_orgs.py <dir-qa> <dir-dev>
"""

from __future__ import annotations

import difflib
import re
import sys
from pathlib import Path

# Ação local de agente leva o Id do registro no nome da pasta
# (insights_comerciais_16jHa00000052kL): o mesmo componente migrado tem outro
# Id em cada org. Comparar com o Id trocado por * evita falso "faltando".
# Id de 15 posições: prefixo de 3 + instância de 2 + zeros + sequência.
_ID_SF = re.compile(r"_[0-9A-Za-z]{5}0{3}[0-9A-Za-z]{7}(?![0-9A-Za-z])")


def sem_ids(caminho: str) -> str:
    return _ID_SF.sub("_*", caminho)


def normalizar(texto: str) -> str:
    return re.sub(r"\s+", " ", texto).strip()


def arquivos(raiz: Path) -> dict[str, str]:
    """Caminho (com Ids de registro trocados por *) → conteúdo normalizado."""
    base = raiz / "force-app"
    if not base.is_dir():
        return {}
    return {
        sem_ids(str(p.relative_to(base))): _ID_SF.sub("_*", p.read_text(encoding="utf-8", errors="ignore"))
        for p in base.rglob("*")
        if p.is_file()
    }


def comparar(qa: dict[str, str], dev: dict[str, str]) -> dict[str, list[str]]:
    return {
        "faltando": sorted(k for k in qa if k not in dev),
        "diferente": sorted(k for k in qa if k in dev and normalizar(qa[k]) != normalizar(dev[k])),
        "igual": sorted(k for k in qa if k in dev and normalizar(qa[k]) == normalizar(dev[k])),
    }


def diferencas(qa: dict[str, str], dev: dict[str, str], chaves: list[str], max_linhas: int = 40) -> str:
    """Trecho do diff de cada arquivo diferente (QA → DEV), para saber o quê."""
    blocos = []
    for k in chaves:
        linhas = [
            l
            for l in difflib.unified_diff(
                [x.strip() for x in qa[k].splitlines() if x.strip()],
                [x.strip() for x in dev[k].splitlines() if x.strip()],
                "QA",
                "DEV",
                lineterm="",
                n=0,
            )
            if not l.startswith("@@")
        ]
        corte = linhas[:max_linhas] + ([f"... (+{len(linhas) - max_linhas} linhas)"] if len(linhas) > max_linhas else [])
        blocos.append(f"<details><summary><code>{k}</code></summary>\n\n```diff\n" + "\n".join(corte) + "\n```\n</details>")
    return "\n".join(blocos)


def acoes(raiz: Path) -> dict[str, tuple[str, str]]:
    """Ações do agente (tópico/ação) → (tipo, alvo) lidos do GenAiPlannerBundle.

    O alvo (Apex, Flow, prompt) é o que precisa existir na org para a ação
    funcionar; se a DEV aponta para o mesmo alvo, ele existe lá (a org não
    salva ação apontando para alvo inexistente).
    """
    saida: dict[str, tuple[str, str]] = {}
    for p in (raiz / "force-app").rglob("*.genAiPlannerBundle"):
        texto = p.read_text(encoding="utf-8", errors="ignore")
        for bloco in re.findall(r"<localActions>(.*?)</localActions>", texto, re.S):
            nome = re.search(r"<(?:localDeveloperName|developerName)>([^<]+)<", bloco)
            alvo = re.search(r"<invocationTarget>([^<]+)<", bloco)
            tipo = re.search(r"<invocationTargetType>([^<]+)<", bloco)
            if nome:
                saida[_ID_SF.sub("", nome.group(1))] = (tipo.group(1) if tipo else "?", alvo.group(1) if alvo else "?")
    return saida


def tabela_acoes(qa: dict[str, tuple[str, str]], dev: dict[str, tuple[str, str]]) -> str:
    if not qa and not dev:
        return ""
    linhas = ["#### Ações do agente e o que cada uma chama\n", "| Ação | QA | DEV | |", "|---|---|---|---|"]
    for nome in sorted(set(qa) | set(dev)):
        a, b = qa.get(nome), dev.get(nome)
        fmt = lambda x: f"{x[0]} `{x[1]}`" if x else "—"
        marca = "ok" if a == b else ("falta na DEV" if not b else ("só na DEV" if not a else "alvo diferente"))
        linhas.append(f"| `{nome}` | {fmt(a)} | {fmt(b)} | {marca} |")
    return "\n".join(linhas) + "\n"


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
    qa, dev = arquivos(Path(sys.argv[1])), arquivos(Path(sys.argv[2]))
    r = comparar(qa, dev)
    print(relatorio(r))
    print(tabela_acoes(acoes(Path(sys.argv[1])), acoes(Path(sys.argv[2]))))
    if r["diferente"]:
        print("#### O que muda em cada arquivo diferente\n")
        print(diferencas(qa, dev, r["diferente"]))
