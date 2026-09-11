"""CLI: gerencia demandas por cliente e aciona os agentes de delivery.

Substitui o papel que comandos como /estoria, /design, /build teriam num fluxo
orientado a Jira: aqui a demanda é um registro no próprio repositório.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import click

from . import ambientes, demands, fluxo

# Quais estágios disparam sessão de agente vive em fluxo.py, junto com a regra
# de qual etapa vem depois de qual — eram dois lugares dizendo a mesma coisa.
DISPARA_SESSAO = fluxo.DISPARA_SESSAO


@click.group()
def main() -> None:
    """Agentes especialistas Salesforce — gestão de demandas por cliente."""


@main.group()
def cliente() -> None:
    """Ações no nível do cliente (não de uma demanda)."""


@cliente.command("assessment")
@click.option("--client", required=True, help="Nome do cliente (= clients/<client>/).")
@click.option(
    "--target-org",
    default=None,
    help="Alias da org. Por padrão, a org de dev do cliente (sbx-<client>-dev).",
)
@click.option(
    "--github-output",
    is_flag=True,
    help="Escreve saude/n_recomendacoes em $GITHUB_OUTPUT (uso do run-assessment.yml).",
)
def assessment_cmd(client: str, target_org: str | None, github_output: bool) -> None:
    """Diagnostica a saúde da org do cliente e grava assessment.md + .json.

    É a primeira coisa que roda quando um cliente é onboardado: ninguém desenha
    solução numa org que não conhece. Read-only — nada na org é alterado.
    """
    workspace = Path("clients") / client
    if not workspace.exists():
        raise click.ClickException(f"'{workspace}' não existe. Crie o workspace do cliente primeiro.")

    alias = target_org or ambientes.org_alias(client, "dev")
    if not ambientes.alias_permitido(alias):
        raise click.ClickException(
            f"Alias {alias!r} fora da esteira. Só `sbx-<cliente>-dev` e `sbx-<cliente>-qa` "
            f"(guardrail #1) — o assessment é read-only, mas ler produção é o guardrail #2."
        )
    click.echo(f"Assessment de {client} contra {alias}...")

    from . import assessment as assessment_mod

    assessment_mod.run_sync(client, alias)

    try:
        dados = assessment_mod.ler_resultado(client)
    except assessment_mod.AssessmentError as exc:
        raise click.ClickException(str(exc))

    recs = dados.get("recomendacoes", [])
    altas = sum(1 for r in recs if str(r.get("severidade", "")).lower() == "alta")
    click.echo(f"{client}: saúde {dados['saude']} — {len(recs)} recomendações ({altas} altas)")

    if github_output:
        destino = os.environ.get("GITHUB_OUTPUT")
        if not destino:
            raise click.ClickException("--github-output pedido, mas $GITHUB_OUTPUT não existe.")
        with open(destino, "a", encoding="utf-8") as fh:
            fh.write(f"saude={dados['saude']}\n")
            fh.write(f"recomendacoes={len(recs)}\n")
            fh.write(f"altas={altas}\n")


@cliente.command("planejar")
@click.option("--client", required=True, help="Nome do cliente (= clients/<client>/).")
@click.option(
    "--github-output",
    is_flag=True,
    help="Escreve n_demandas em $GITHUB_OUTPUT (uso do run-planejamento.yml).",
)
def planejar(client: str, github_output: bool) -> None:
    """Quebra os entregáveis contratados nas demandas que eles viram.

    Lê `contrato.md` (materializado pelo Squad OS) e grava
    `plano-demandas.json`. Não materializa nem executa nada — quem decide o que
    entra na esteira é o humano, no quadro.
    """
    workspace = Path("clients") / client
    if not workspace.exists():
        raise click.ClickException(f"'{workspace}' não existe. Crie o workspace do cliente primeiro.")

    from . import planejamento

    try:
        planejamento.run_sync(client)
        # Os ids válidos saem do próprio contrato.md, pra pegar id inventado.
        contrato = planejamento.caminho_contrato(client).read_text(encoding="utf-8")
        validos = set(re.findall(r"`id:\s*([A-Za-z0-9_-]+)`", contrato))
        dados = planejamento.ler_plano(client, validos or None)
    except planejamento.PlanejamentoError as exc:
        raise click.ClickException(str(exc))

    n = len(dados["demandas"])
    click.echo(f"{client}: {n} demandas propostas a partir do contrato")

    if github_output:
        destino = os.environ.get("GITHUB_OUTPUT")
        if not destino:
            raise click.ClickException("--github-output pedido, mas $GITHUB_OUTPUT não existe.")
        with open(destino, "a", encoding="utf-8") as fh:
            fh.write(f"n_demandas={n}\n")


@cliente.command("plano-json")
@click.option("--client", required=True)
def plano_json(client: str) -> None:
    """Imprime o plano-demandas.json, pro sync com o Squad OS."""
    from . import planejamento

    try:
        dados = planejamento.ler_plano(client)
    except planejamento.PlanejamentoError as exc:
        raise click.ClickException(str(exc))
    click.echo(json.dumps(dados, ensure_ascii=False))


@cliente.command("assessment-json")
@click.option("--client", required=True)
def assessment_json(client: str) -> None:
    """Imprime o assessment.json do cliente, pro sync com o Squad OS."""
    from . import assessment as assessment_mod

    try:
        dados = assessment_mod.ler_resultado(client)
    except assessment_mod.AssessmentError as exc:
        raise click.ClickException(str(exc))
    dados["client"] = client
    click.echo(json.dumps(dados, ensure_ascii=False))


@main.group()
def demanda() -> None:
    """Gerencia demandas (substitui o fluxo de estórias do Jira)."""


@demanda.command("nova")
@click.option("--client", required=True, help="Nome do cliente (deve existir clients/<client>/).")
@click.option("--titulo", required=True, help="Título curto da demanda.")
@click.option("--texto", required=True, type=click.Path(exists=True), help="Arquivo .md com a descrição da demanda (a história).")
@click.option("--tipo", type=click.Choice(["projeto", "sustentacao"]), default="sustentacao")
def nova(client: str, titulo: str, texto: str, tipo: str) -> None:
    """Registra uma nova demanda para um cliente, em estágio 'backlog'."""
    workspace = Path("clients") / client
    if not workspace.exists():
        raise click.ClickException(
            f"'{workspace}' não existe. Crie o workspace do cliente primeiro, "
            f"veja clients/README.md."
        )
    conteudo = Path(texto).read_text(encoding="utf-8")
    d = demands.create(client, titulo, conteudo, tipo)
    click.echo(f"Demanda criada: {d.id} (status: {d.status})")


@demanda.command("listar")
@click.option("--client", default=None, help="Filtra por cliente. Omitido lista todos.")
def listar(client: str | None) -> None:
    """Mostra as demandas e seu estágio atual (substitui /status)."""
    rows = demands.list_demands(client)
    if not rows:
        click.echo("Nenhuma demanda encontrada.")
        return
    for d in rows:
        click.echo(f"{d.id:14} {d.client:15} {d.status:25} {d.titulo}")


@demanda.command("avancar")
@click.option("--client", required=True)
@click.argument("demand_id")
@click.argument("novo_status", type=click.Choice(demands.STAGES))
@click.option("--autor", default="cli", help="Quem aprovou/registrou esta transição.")
def avancar(client: str, demand_id: str, novo_status: str, autor: str) -> None:
    """Move a demanda para um novo estágio e, se for de execução, aciona os agentes."""
    try:
        d = demands.transition(client, demand_id, novo_status, autor)
    except demands.ArtifactAusenteError as exc:
        raise click.ClickException(str(exc))
    click.echo(f"{d.id}: {d.historico[-1]['de']} -> {d.status}")
    if novo_status in DISPARA_SESSAO:
        # Import tardio de propósito: `orchestrator` puxa o Claude Agent SDK
        # inteiro, e os comandos de leitura (listar, ambiente) não precisam
        # dele. Sem isso, um step de CI que só quer saber em qual org a etapa
        # roda teria que instalar o SDK antes de perguntar.
        from .orchestrator import run_sync

        run_sync(client, demand_id, novo_status)


@demanda.command("rodar")
@click.option("--client", required=True)
@click.argument("demand_id")
@click.option(
    "--aprovar-gate",
    default=None,
    metavar="AUTOR",
    help="Aprova o gate humano em que a demanda está antes de rodar. É o que o "
    "Squad OS manda quando alguém clica em aprovar no card.",
)
@click.option(
    "--github-output",
    is_flag=True,
    help="Escreve o motivo da parada em $GITHUB_OUTPUT (uso do run-demand.yml).",
)
def rodar(client: str, demand_id: str, aprovar_gate: str | None, github_output: bool) -> None:
    """Roda a demanda a partir do estágio atual até o próximo gate humano.

    É o comando que run-demand.yml chama. Diferente de `avancar`, não recebe
    o estágio de destino: quem decide é o fluxo, lendo status.yaml. Assim não
    existe a possibilidade de alguém disparar a etapa errada por engano.
    """
    try:
        if aprovar_gate:
            d = fluxo.aprovar_gate(client, demand_id, aprovar_gate)
            click.echo(f"{demand_id}: gate aprovado por {aprovar_gate} -> {d.status}")
        parada = fluxo.rodar(client, demand_id)
    except (fluxo.FluxoError, demands.InvalidStatusError, demands.DemandNotFoundError) as exc:
        raise click.ClickException(str(exc))

    if parada.etapas_rodadas:
        click.echo(f"{demand_id}: rodou {', '.join(parada.etapas_rodadas)}")
    if parada.motivo == "gate":
        click.echo(f"{demand_id}: parado em '{parada.etapa}' — esperando aprovação humana.")
    else:
        click.echo(f"{demand_id}: {parada.motivo} em '{parada.etapa}'.")

    if github_output:
        destino = os.environ.get("GITHUB_OUTPUT")
        if not destino:
            raise click.ClickException("--github-output pedido, mas $GITHUB_OUTPUT não existe.")
        with open(destino, "a", encoding="utf-8") as fh:
            fh.write(parada.as_github_output() + "\n")


@demanda.command("status-json")
@click.option("--client", required=True)
@click.argument("demand_id")
def status_json(client: str, demand_id: str) -> None:
    """Imprime o status.yaml da demanda como JSON.

    Existe pro workflow mandar o estado novo de volta pro Squad OS sem ter que
    parsear YAML em bash. status.yaml continua sendo a fonte de verdade
    (guardrail #5); o Postgres é espelho.
    """
    try:
        d = demands.Demand.load(client, demand_id)
    except demands.DemandNotFoundError as exc:
        raise click.ClickException(str(exc))
    click.echo(json.dumps(d.to_dict(), ensure_ascii=False))


@demanda.command("ambiente")
@click.option("--client", required=True)
@click.argument("demand_id")
def ambiente(client: str, demand_id: str) -> None:
    """Diz em qual org o estágio atual da demanda roda (dev ou qa).

    Sai em `chave=valor`, uma por linha, pra ser redirecionado direto pro
    $GITHUB_OUTPUT de um step do Actions — é assim que run-demand.yml decide
    qual GitHub Environment abrir sem repetir a regra em YAML.
    """
    try:
        d = demands.Demand.load(client, demand_id)
    except demands.DemandNotFoundError as exc:
        raise click.ClickException(str(exc))
    amb = ambientes.ambiente_do_estagio(d.status)
    click.echo(f"etapa={d.status}")
    click.echo(f"ambiente={amb}")
    click.echo(f"org_alias={ambientes.org_alias(client, amb)}")
    click.echo(f"github_environment={ambientes.github_environment(client, amb)}")


@demanda.command("conferir-gates")
@click.option("--client", required=True)
@click.argument("demand_id")
def conferir_gates(client: str, demand_id: str) -> None:
    """Diz se os artefatos em disco ainda são os que os humanos aprovaram.

    Sai diferente de zero quando algum artefato mudou depois da aprovação. Não
    é acusação de nada — correção depois do gate é normal e às vezes é o certo.
    É a pergunta ficando respondível: hoje, quem auditasse a entrega meses
    depois só teria "fulano aprovou o design", sem saber qual design.
    """
    from . import gates as gates_mod

    try:
        d = demands.Demand.load(client, demand_id)
    except demands.DemandNotFoundError as exc:
        raise click.ClickException(str(exc))

    aprovados = gates_mod.registrados(d)
    if not aprovados:
        click.echo(f"{demand_id}: nenhum gate aprovado ainda.")
        return

    divergentes = {gate: gates_mod.conferir(d, gate) for gate in aprovados}
    divergentes = {gate: arquivos for gate, arquivos in divergentes.items() if arquivos}

    for gate, arquivos in divergentes.items():
        click.echo(f"{gate}: mudou depois da aprovação -> {', '.join(arquivos)}")

    if divergentes:
        raise click.ClickException(
            f"{len(divergentes)} de {len(aprovados)} gate(s) aprovaram um conteúdo que não "
            f"é mais o que está em disco."
        )
    click.echo(f"{demand_id}: {len(aprovados)} gate(s) conferem com o que está em disco.")


if __name__ == "__main__":
    main()
