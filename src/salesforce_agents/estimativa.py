"""Estimativa por demanda: horas de gente (dos agentes) e custo de agente (da telemetria).

Duas perguntas diferentes, com duas fontes diferentes de propósito:

- **Horas** é julgamento: quanto trabalho humano (consultor/dev revisando,
  configurando, homologando) a demanda vai pedir. Quem estima é o agente que
  acabou de entender a demanda — `ba-discovery` na análise, refinado pelo
  `arquiteto` no design — numa linha fixa do artefato
  (`**Estimativa de esforço:** 4–8 h`). Aqui só se lê; o design, quando existe,
  vence a análise, porque foi escrito sabendo o que existe na org.

- **Custo de agente** é conta, não opinião: o que já foi gasto nesta demanda
  (soma de `cost_usd` da telemetria, `costs.py`) mais, para cada etapa de agente
  que ainda falta, a mediana do que aquela etapa custou nas demandas já
  registradas. Sem histórico suficiente usa um valor de partida declarado — e
  diz que usou, pelo número de amostras.

O resultado vai no payload do sync (`revisao.payload_de_sync`). Quem decide
quem vê o quê é o Squad OS: custo de agente é só para admin.
"""

from __future__ import annotations

import re
import statistics
from collections import defaultdict
from collections.abc import Iterable

from . import costs, demands, fluxo

# Ponto de partida por etapa (USD) enquanto não há amostra: só para não mostrar
# zero. Substituído pela mediana real assim que existirem MIN_AMOSTRAS sessões.
PARTIDA_USD = {"analise": 0.30, "design": 1.50, "build": 2.00, "qa": 1.00, "release": 0.50}
MIN_AMOSTRAS = 3

_ARQUIVOS_HORAS = ("03-design.md", "01-analise.md")  # o primeiro que tiver, vence
_LINHA_HORAS = re.compile(
    r"estimativa de esfor[cç]o\**\s*:?\**\s*:?\s*"
    r"(\d+(?:[.,]\d+)?)\s*(?:h\s*)?(?:[–—-]|a|até)\s*(\d+(?:[.,]\d+)?)\s*h",
    re.IGNORECASE,
)
_LINHA_HORAS_UNICA = re.compile(
    r"estimativa de esfor[cç]o\**\s*:?\**\s*:?\s*(\d+(?:[.,]\d+)?)\s*h", re.IGNORECASE
)


def _num(txt: str) -> float:
    return float(txt.replace(",", "."))


def horas(demanda: demands.Demand) -> dict | None:
    """{'min', 'max', 'fonte'} da linha de estimativa do artefato mais recente."""
    for nome in _ARQUIVOS_HORAS:
        arq = demanda.path / nome
        if not arq.exists():
            continue
        texto = arq.read_text(encoding="utf-8")
        m = _LINHA_HORAS.search(texto)
        if m:
            lo, hi = sorted((_num(m.group(1)), _num(m.group(2))))
            return {"min": lo, "max": hi, "fonte": nome}
        m = _LINHA_HORAS_UNICA.search(texto)
        if m:
            v = _num(m.group(1))
            return {"min": v, "max": v, "fonte": nome}
    return None


def _custo_por_etapa_e_demanda(linhas: Iterable[dict]) -> dict[tuple[str, str, str], float]:
    soma: dict[tuple[str, str, str], float] = defaultdict(float)
    for r in linhas:
        etapa = r.get("etapa", "")
        if etapa not in fluxo.DISPARA_SESSAO:
            continue  # assessment, planejamento: não são etapa de demanda
        try:
            soma[(r.get("client", ""), r.get("demand_id", ""), etapa)] += float(r.get("cost_usd") or 0)
        except ValueError:
            continue
    return soma


def etapas_restantes(status: str) -> list[str]:
    """Etapas de agente que ainda vão rodar a partir de `status` (inclusive a atual)."""
    if status in demands.STAGES_TRIAGEM:
        inicio = 0
    elif status in demands.STAGES_EXECUCAO:
        inicio = demands.STAGES_EXECUCAO.index(status)
    else:
        return []
    return [e for e in demands.STAGES_EXECUCAO[inicio:] if e in fluxo.DISPARA_SESSAO]


def custo_agente(demanda: demands.Demand, linhas: Iterable[dict] | None = None) -> dict:
    linhas = list(costs.ler_todas_as_linhas() if linhas is None else linhas)
    por_chave = _custo_por_etapa_e_demanda(linhas)

    gasto = sum(v for (c, d, _), v in por_chave.items() if c == demanda.client and d == demanda.id)

    por_etapa: dict[str, list[float]] = defaultdict(list)
    for (_, _, etapa), v in por_chave.items():
        por_etapa[etapa].append(v)

    restante = 0.0
    amostras = 0
    for etapa in etapas_restantes(demanda.status):
        valores = por_etapa.get(etapa, [])
        if len(valores) >= MIN_AMOSTRAS:
            restante += statistics.median(valores)
            amostras += len(valores)
        else:
            restante += PARTIDA_USD[etapa]

    return {"gastoUsd": round(gasto, 4), "restanteUsd": round(restante, 4), "amostras": amostras}


def payload(demanda: demands.Demand) -> dict:
    return {"horas": horas(demanda), "custoAgente": custo_agente(demanda)}
