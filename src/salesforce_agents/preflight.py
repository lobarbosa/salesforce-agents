"""Pré-checagem: o que a esteira confere antes de a sessão do agente começar.

Os problemas de 15/11 na Eplast só apareceram no meio da execução, quando já
tinham custado uma sessão:

- EPLAST-27: o deploy na QA recusou alterar `SFAgent2_v4`, ativa lá.
- EPLAST-29 e EPLAST-34: as duas mexeram na mesma versão do agente na dev
  (`SFAgent2_v5`), junto com a 27, e nenhuma sabia das outras.
- EPLAST-33: a validação do PR falhou porque a classe tinha job agendado na dev.
- EPLAST-47: o teste da QA estava armado contando contas, e outra demanda
  podia entrar na mesma sandbox no meio.

Este passo roda antes da sessão e grava `00-preflight.md` na pasta da
demanda, que o agente lê no início. Só um achado bloqueia: outra demanda do
mesmo cliente em teste na sandbox de QA (guardrail #6). O resto é aviso, para
o agente agir sabendo, e consulta que falha vira "não conferido", nunca erro.

Só metadata e contagens: nenhuma consulta retorna dado de cliente (guardrail #2).
"""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from . import demands

NOME = "00-preflight.md"

# Demanda que ainda pode mexer na org ou no repositório.
_PARADAS = {"entregue", "cancelada", "standby", "backlog"}

_DEFAULT = re.compile(r"^clients/[^/]+/force-app/main/default/(.+)$")
_VERSAO_DO_AGENTE = re.compile(r"^(.+)_v\d+$")
_SEGURO = re.compile(r"^[A-Za-z0-9_]+$")


@dataclass
class Resultado:
    bloqueios: list[str] = field(default_factory=list)
    avisos: list[str] = field(default_factory=list)
    org: list[str] = field(default_factory=list)

    def markdown(self, demand_id: str, etapa: str, org_alias: str) -> str:
        linhas = [
            f"# Pré-checagem — {demand_id}",
            "",
            f"Etapa que vai rodar: `{etapa}` · org: `{org_alias}`. Gerado pela esteira antes da sessão; "
            "leia antes de agir e trate cada aviso no seu artefato.",
            "",
            "## Bloqueios",
            *(f"- {b}" for b in self.bloqueios or ["nenhum"]),
            "",
            "## Outras demandas mexendo nos mesmos componentes",
            *(f"- {a}" for a in self.avisos or ["nenhuma"]),
            "",
            "## Estado na org",
            *(f"- {o}" for o in self.org or ["nada a conferir: a demanda ainda não tem componentes no repositório"]),
            "",
        ]
        return "\n".join(linhas)


def componente(caminho: str) -> str | None:
    """Chave do componente de um arquivo de force-app, para comparar demandas.

    Agente vira uma chave só, qualquer que seja a versão (`bots/X` e
    `genAiPlannerBundles/X_v5` são o mesmo agente `X`): é a versão que as
    demandas disputam. Campo e regra ficam por item, não pelo objeto inteiro,
    senão toda demanda que toca Account colidiria com todas as outras.
    """
    m = _DEFAULT.match(caminho)
    if not m:
        return None
    partes = m.group(1).split("/")
    tipo = partes[0]
    if len(partes) < 2:
        return None
    nome = partes[1].split(".")[0]
    if tipo == "bots":
        return f"agente {nome}"
    if tipo == "genAiPlannerBundles":
        v = _VERSAO_DO_AGENTE.match(nome)
        return f"agente {v.group(1) if v else nome}"
    if tipo == "objects" and len(partes) >= 4:
        return f"objects/{nome}/{partes[2]}/{partes[3].split('.')[0]}"
    return f"{tipo}/{nome}"


def _git(*args: str) -> str:
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def componentes_da_branch(client: str, ref: str) -> set[str]:
    saida = _git("diff", "--name-only", f"origin/main...{ref}", "--", f"clients/{client}/force-app")
    return {c for c in (componente(linha) for linha in saida.splitlines()) if c}


def demandas_em_andamento(client: str, exceto: str) -> dict[str, str]:
    """ID → status das outras demandas do cliente, lido da branch de cada uma."""
    achadas: dict[str, str] = {}
    for ref in _git("for-each-ref", "--format=%(refname:short)", "refs/remotes/origin/feature/").split():
        demand_id = ref.rsplit("/", 1)[-1]
        if demand_id == exceto:
            continue
        texto = _git("show", f"{ref}:clients/{client}/demandas/{demand_id}/status.yaml")
        m = re.search(r"^status:\s*(\S+)", texto, re.M)
        if m and m.group(1) not in _PARADAS:
            achadas[demand_id] = m.group(1)
    return achadas


def _consulta(org_alias: str, soql: str) -> list[dict]:
    r = subprocess.run(
        ["sf", "data", "query", "--query", soql, "--target-org", org_alias, "--json"],
        capture_output=True,
        text=True,
    )
    dados = json.loads(r.stdout or "{}")
    if r.returncode != 0 or dados.get("status") not in (0, None):
        raise RuntimeError(dados.get("message") or r.stderr.strip() or "consulta falhou")
    return dados.get("result", {}).get("records", [])


def _lista(nomes: list[str]) -> str:
    return ", ".join(f"'{n}'" for n in nomes)


def conferir_org(org_alias: str, comps: set[str], consulta=_consulta) -> list[str]:
    """Versões ativas de agente e Flow, e jobs pendentes das classes da demanda."""
    agentes = sorted(c.split(" ", 1)[1] for c in comps if c.startswith("agente "))
    flows = sorted(c.split("/", 1)[1] for c in comps if c.startswith("flows/"))
    classes = sorted(c.split("/", 1)[1] for c in comps if c.startswith("classes/"))
    achados: list[str] = []

    for nome in agentes:
        if not _SEGURO.match(nome):
            continue
        try:
            versoes = consulta(
                org_alias,
                f"SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = '{nome}' "
                "ORDER BY VersionNumber",
            )
            ativa = [str(v.get("VersionNumber")) for v in versoes if v.get("Status") == "Active"]
            todas = [str(v.get("VersionNumber")) for v in versoes]
            if not versoes:
                achados.append(f"Agente `{nome}`: não existe nesta org.")
            else:
                achados.append(
                    f"Agente `{nome}`: versões {', '.join('v' + n for n in todas)}; ativa: "
                    f"{', '.join('v' + n for n in ativa) or 'nenhuma'}. Versão ativa não aceita deploy: "
                    "o build cria a seguinte, inativa (skill salesforce-doutrina)."
                )
        except Exception as exc:  # noqa: BLE001 - não conferido não é falha do job
            achados.append(f"Agente `{nome}`: não conferido ({exc}).")

    nomes_flow = [f for f in flows if _SEGURO.match(f)]
    if nomes_flow:
        try:
            linhas = consulta(
                org_alias,
                f"SELECT ApiName, ActiveVersionId FROM FlowDefinitionView WHERE ApiName IN ({_lista(nomes_flow)})",
            )
            ativos = {r.get("ApiName") for r in linhas if r.get("ActiveVersionId")}
            for f in nomes_flow:
                if f in ativos:
                    achados.append(f"Flow `{f}`: tem versão ativa nesta org — mudança entra como versão nova.")
                elif f in {r.get("ApiName") for r in linhas}:
                    achados.append(f"Flow `{f}`: existe nesta org, sem versão ativa.")
                else:
                    achados.append(f"Flow `{f}`: não existe nesta org.")
        except Exception as exc:  # noqa: BLE001
            achados.append(f"Flows {', '.join(nomes_flow)}: não conferidos ({exc}).")

    nomes_classe = [c for c in classes if _SEGURO.match(c)]
    if nomes_classe:
        try:
            jobs = consulta(
                org_alias,
                "SELECT ApexClass.Name, JobType, Status FROM AsyncApexJob "
                f"WHERE ApexClass.Name IN ({_lista(nomes_classe)}) "
                "AND Status IN ('Queued', 'Holding', 'Preparing', 'Processing')",
            )
            com_job = sorted({(j.get("ApexClass") or {}).get("Name", "?") for j in jobs})
            if com_job:
                achados.append(
                    f"Classes com job pendente nesta org: {', '.join(com_job)}. Classe com job pendente não "
                    "aceita deploy: desagende antes de implantar ou validar."
                )
            else:
                achados.append(f"Classes da demanda sem job pendente nesta org ({len(nomes_classe)} conferidas).")
        except Exception as exc:  # noqa: BLE001
            achados.append(f"Jobs das classes da demanda: não conferidos ({exc}).")
    return achados


def rodar(client: str, demand_id: str, etapa: str, org_alias: str, *, consulta=_consulta) -> Resultado:
    res = Resultado()
    outras = demandas_em_andamento(client, demand_id)

    if etapa == "qa":
        em_qa = sorted(i for i, s in outras.items() if s == "qa")
        if em_qa:
            res.bloqueios.append(
                f"{', '.join(em_qa)} está em teste na sandbox de QA. Uma demanda por vez, por cliente, na "
                "mesma sandbox (guardrail #6): esta espera aquela terminar."
            )

    meus = componentes_da_branch(client, "HEAD")
    for outra, status in sorted(outras.items()):
        comuns = sorted(meus & componentes_da_branch(client, f"origin/feature/{outra}"))
        if comuns:
            res.avisos.append(f"{outra} ({status}) também mexe em: {', '.join(comuns)}.")

    if meus and etapa in ("build", "verificacao", "qa"):
        res.org = conferir_org(org_alias, meus, consulta)
    return res


def gravar(client: str, demand_id: str, etapa: str, org_alias: str) -> Resultado:
    res = rodar(client, demand_id, etapa, org_alias)
    pasta = demands.Demand.load(client, demand_id).path
    (pasta / NOME).write_text(res.markdown(demand_id, etapa, org_alias), encoding="utf-8")
    return res


def nota_para_o_prompt(client: str, demand_id: str) -> str:
    if not (Path("clients") / client / "demandas" / demand_id / NOME).exists():
        return ""
    return (
        f"\n\nA esteira conferiu a org e as outras demandas antes desta sessão: leia "
        f"`demandas/{demand_id}/{NOME}` e repasse ao subagente. Componente que outra demanda também "
        "altera parte do que ela deixou; versão ativa de agente ou Flow não é alterada no lugar.\n"
    )
