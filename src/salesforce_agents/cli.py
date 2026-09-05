"""CLI: sfagents run --client <nome> --spec <arquivo> [--deploy]"""

from __future__ import annotations

from pathlib import Path

import click

from .orchestrator import run_sync


@click.group()
def main() -> None:
    """Agentes especialistas Salesforce."""


@main.command()
@click.option("--client", required=True, help="Nome do cliente (deve existir clients/<client>/).")
@click.option("--spec", "spec_path", required=True, type=click.Path(exists=True), help="Caminho da spec de requisitos (.md, .pdf ou .docx).")
@click.option("--deploy/--no-deploy", default=False, help="Fazer deploy no org do cliente ao final (requer org autenticado com alias == nome do cliente).")
def run(client: str, spec_path: str, deploy: bool) -> None:
    """Implementa a spec de um cliente usando os agentes especialistas."""
    workspace = Path("clients") / client
    if not workspace.exists():
        raise click.ClickException(
            f"'{workspace}' não existe. Crie o workspace do cliente primeiro "
            f"(sfdx-project.json + force-app/), veja clients/README.md."
        )
    run_sync(str(Path(spec_path).resolve()), client, deploy)


if __name__ == "__main__":
    main()
