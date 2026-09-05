"""CLI: gerencia demandas por cliente e aciona os agentes de delivery.

Substitui o papel que comandos como /estoria, /design, /build teriam num fluxo
orientado a Jira: aqui a demanda é um registro no próprio repositório.
"""

from __future__ import annotations

from pathlib import Path

import click

from . import demands
from .orchestrator import run_sync

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
    d = demands.transition(client, demand_id, novo_status, autor)
    click.echo(f"{d.id}: {d.historico[-1]['de']} -> {d.status}")
    if novo_status in DISPARA_SESSAO:
        run_sync(client, demand_id)


if __name__ == "__main__":
    main()
