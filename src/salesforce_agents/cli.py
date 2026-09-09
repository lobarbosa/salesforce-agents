"""CLI: gerencia demandas por cliente e aciona os agentes de delivery.

Substitui o papel que comandos como /estoria, /design, /build teriam num fluxo
orientado a Jira: aqui a demanda é um registro no próprio repositório.
"""

from __future__ import annotations

from pathlib import Path

import click

from . import ambientes, demands

# Estágios de execução que, ao serem definidos, disparam uma sessão de agente.
# Os estágios "aguardando_*" são gates humanos puros — não disparam sessão.
DISPARA_SESSAO = {"analise", "design", "build", "qa", "release"}


@click.group()
def main() -> None:
    """Agentes especialistas Salesforce — gestão de demandas por cliente."""


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


if __name__ == "__main__":
    main()
