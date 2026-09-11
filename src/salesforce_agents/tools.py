"""Ferramentas custom (MCP in-process) usadas pelos agentes especialistas Salesforce.

Duas famílias de ferramentas:
  - spec_read: leitura de anexos de uma demanda (md, pdf, docx) em texto plano. A
    própria demanda (demandas/<ID>/demanda.md) é lida com a ferramenta Read padrão;
    isso serve para documentos complementares referenciados na demanda.
  - sf_*: wrapper fino sobre a Salesforce CLI (`sf`) para orgs autenticados por alias
    (um alias por cliente, ver clients/<nome>/README.md).
"""

from __future__ import annotations

from pathlib import Path

from claude_agent_sdk import create_sdk_mcp_server, tool

from .guarda import CliAusenteError, recusa_de_alias, recusa_de_escrita, sf


def _text_result(text: str) -> dict:
    return {"content": [{"type": "text", "text": text}]}


@tool(
    "spec_read",
    "Lê um arquivo anexo de uma demanda (.md, .pdf ou .docx) e retorna o texto extraído.",
    {"path": str},
)
async def spec_read(args: dict) -> dict:
    path = Path(args["path"]).expanduser().resolve()
    if not path.exists():
        return _text_result(f"Arquivo não encontrado: {path}")

    suffix = path.suffix.lower()
    if suffix in (".md", ".txt"):
        return _text_result(path.read_text(encoding="utf-8"))

    if suffix == ".pdf":
        from pypdf import PdfReader

        reader = PdfReader(str(path))
        text = "\n\n".join(page.extract_text() or "" for page in reader.pages)
        return _text_result(text)

    if suffix == ".docx":
        import docx

        doc = docx.Document(str(path))
        text = "\n".join(p.text for p in doc.paragraphs)
        return _text_result(text)

    return _text_result(f"Formato não suportado: {suffix}")


def _run_sf(args: list[str]) -> dict:
    try:
        proc = sf(args)
    except CliAusenteError:
        return _text_result(
            "Salesforce CLI ('sf') não encontrada no PATH. Instale com "
            "'npm install -g @salesforce/cli' e autentique o org do cliente."
        )
    output = proc.stdout.strip() or proc.stderr.strip()
    status = "OK" if proc.returncode == 0 else f"ERRO (exit {proc.returncode})"
    return _text_result(f"[{status}] sf {' '.join(args)}\n\n{output}")


@tool(
    "sf_deploy",
    "Faz deploy de metadata de um diretório do projeto (force-app) para o org do cliente via Salesforce CLI.",
    {"source_dir": str, "target_org": str, "check_only": bool},
)
async def sf_deploy(args: dict) -> dict:
    recusa = recusa_de_escrita(args.get("target_org", ""))
    if recusa:
        return _text_result(recusa)
    cli_args = [
        "project", "deploy", "start",
        "--source-dir", args["source_dir"],
        "--target-org", args["target_org"],
        "--json",
    ]
    if args.get("check_only"):
        cli_args.append("--dry-run")
    return _run_sf(cli_args)


@tool(
    "sf_retrieve",
    "Recupera metadata existente do org do cliente para o diretório local do projeto.",
    {"metadata": str, "target_org": str, "output_dir": str},
)
async def sf_retrieve(args: dict) -> dict:
    # Só a forma do alias: retrieve não escreve na org. Mas puxar metadata de
    # produção pro workspace de um cliente é o caminho mais curto pra alguém
    # fazer deploy disso de volta sem perceber de onde veio.
    recusa = recusa_de_alias(args.get("target_org", ""))
    if recusa:
        return _text_result(recusa)
    return _run_sf([
        "project", "retrieve", "start",
        "--metadata", args["metadata"],
        "--target-org", args["target_org"],
        "--output-dir", args["output_dir"],
        "--json",
    ])


@tool(
    "sf_query",
    "Executa uma consulta SOQL no org do cliente (útil para checar dados/config existentes antes de implementar).",
    {"soql": str, "target_org": str},
)
async def sf_query(args: dict) -> dict:
    # SOQL contra produção é o cenário do guardrail #2: a org de produção é a
    # que tem CPF, e-mail e telefone de verdade pra vazar pro contexto.
    recusa = recusa_de_alias(args.get("target_org", ""))
    if recusa:
        return _text_result(recusa)
    return _run_sf([
        "data", "query",
        "--query", args["soql"],
        "--target-org", args["target_org"],
        "--json",
    ])


@tool(
    "sf_org_list",
    "Lista os orgs Salesforce autenticados (aliases) disponíveis nesta máquina.",
    {},
)
async def sf_org_list(_args: dict) -> dict:
    return _run_sf(["org", "list", "--json"])


salesforce_tools_server = create_sdk_mcp_server(
    name="salesforce-tools",
    version="0.1.0",
    tools=[spec_read, sf_deploy, sf_retrieve, sf_query, sf_org_list],
)
