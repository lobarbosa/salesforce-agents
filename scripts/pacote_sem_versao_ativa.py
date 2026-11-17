#!/usr/bin/env python3
"""Tira do pacote de QA só as versões de agente que a plataforma recusou por estarem ativas.

Usado pelo `scripts/implantar-build-qa.sh`. Versão de agente ativa não aceita
reimplantação, e o deploy inteiro cai. Até 2026-11-17 a saída era reimplantar
sem nenhum arquivo de agente, e isso deixava de fora também a versão nova que
a demanda criou para corrigir a anterior (achado EPLAST-29: a v17 corrigia as
falhas do QA, a v16 ativa derrubou o deploy, o pacote foi sem agente nenhum e
o QA reprovou de novo porque a v17 não estava na sandbox).

Recebe o JSON do `sf project deploy start --json` e o arquivo de argumentos
do deploy (um por linha). Imprime os argumentos sem os arquivos das versões
citadas nas falhas:

- `BotVersion Bot.vN`  -> `bots/Bot/vN.botVersion-meta.xml`
- `GenAiPlannerBundle X` -> tudo em `genAiPlannerBundles/X/`
- `Bot Bot` -> tudo em `bots/Bot/`

Sai com 3 se alguma falha é de tipo que ele não sabe localizar, ou se nada
saiu do pacote: aí a esteira volta ao comportamento antigo.
"""

from __future__ import annotations

import json
import sys


def falhas(deploy: dict) -> list[tuple[str, str]]:
    """Pares (tipo, nome completo) das falhas por componente."""
    resultado = deploy.get("result")
    detalhes = resultado.get("details") if isinstance(resultado, dict) else None
    brutas = detalhes.get("componentFailures") if isinstance(detalhes, dict) else None
    if isinstance(brutas, dict):
        brutas = [brutas]
    return [
        (str(f.get("componentType") or ""), str(f.get("fullName") or ""))
        for f in brutas or []
        if isinstance(f, dict)
    ]


def trechos_recusados(falhas_do_deploy: list[tuple[str, str]]) -> list[str] | None:
    """Trechos de caminho das versões recusadas; None se há tipo desconhecido."""
    trechos: list[str] = []
    for tipo, nome in falhas_do_deploy:
        if tipo == "BotVersion" and "." in nome:
            bot, versao = nome.split(".", 1)
            trechos.append(f"/bots/{bot}/{versao}.botVersion-meta.xml")
        elif tipo == "GenAiPlannerBundle" and nome:
            trechos.append(f"/genAiPlannerBundles/{nome}/")
        elif tipo == "Bot" and nome:
            trechos.append(f"/bots/{nome}/")
        else:
            return None
    return trechos


def sem_as_recusadas(argumentos: list[str], trechos: list[str]) -> tuple[list[str], int]:
    """Os argumentos sem os `--source-dir` das versões recusadas, e quantos saíram."""
    saida: list[str] = []
    tirados = 0
    i = 0
    while i < len(argumentos):
        if argumentos[i] == "--source-dir" and i + 1 < len(argumentos):
            caminho = "/" + argumentos[i + 1].strip("/") + "/"
            if any(t in caminho or caminho.endswith(t.rstrip("/") + "/") for t in trechos):
                tirados += 1
            else:
                saida += argumentos[i : i + 2]
            i += 2
        else:
            saida.append(argumentos[i])
            i += 1
    return saida, tirados


def main(argv: list[str]) -> int:
    try:
        with open(argv[1], encoding="utf-8") as arquivo:
            deploy = json.load(arquivo)
        with open(argv[2], encoding="utf-8") as arquivo:
            argumentos = [linha.rstrip("\n") for linha in arquivo if linha.strip()]
    except (IndexError, OSError, ValueError):
        return 3
    trechos = trechos_recusados(falhas(deploy if isinstance(deploy, dict) else {}))
    if not trechos:
        return 3
    saida, tirados = sem_as_recusadas(argumentos, trechos)
    if tirados == 0 or "--source-dir" not in saida:
        return 3
    print("\n".join(saida))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
