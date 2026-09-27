"""Ferramentas custom (MCP in-process) usadas pelos agentes especialistas Salesforce.

Três famílias de ferramentas:
  - spec_read: leitura de anexos de uma demanda (md, pdf, docx) em texto plano. A
    própria demanda (demandas/<ID>/demanda.md) é lida com a ferramenta Read padrão;
    isso serve para documentos complementares referenciados na demanda.
  - sf_*: wrapper fino sobre a Salesforce CLI (`sf`) para orgs autenticados por alias
    (um alias por cliente, ver clients/<nome>/README.md).
  - qa_browser_*: navegador (Playwright) pra testar a UI Lightning de verdade, usado
    pelo agente `qa`. Só `qa_browser_open` decide pra onde o navegador vai, e só
    depois de passar por `guarda.url_de_login` — as mesmas perguntas 1 e 2 de
    `sf_deploy` (alias tem a forma da esteira? a org confirma ser sandbox?). As
    ferramentas seguintes (click/fill/screenshot/close) operam só dentro da sessão já
    aberta: nenhuma delas aceita URL. Isso importa porque `--allowed-origins` do
    Playwright MCP oficial é documentado como "não é um limite de segurança e não
    afeta redirect" — não dava pra confiar nisso sozinho pra manter o guardrail #1,
    por isso este pacote não usa o servidor externo e embrulha o Playwright do
    mesmo jeito que embrulha o `sf`.
"""

from __future__ import annotations

import base64
import uuid
from pathlib import Path
from urllib.parse import quote

from claude_agent_sdk import create_sdk_mcp_server, tool

from .guarda import CliAusenteError, recusa_de_alias, recusa_de_escrita, sf, url_de_login


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


# Sessões de navegador abertas por qa_browser_open, vivas pelo tempo do processo do
# job — que é a vida inteira de um job de CI, então não precisa sobreviver a mais
# que isso. Chave é o session_id devolvido ao agente; valor é o trio que precisa ser
# fechado (Playwright, Browser, Page).
_SESSOES: dict[str, tuple] = {}

# Salesforce Lightning mantém conexão (long-polling/websocket) praticamente sempre
# aberta — esperar "networkidle" nela tende a estourar timeout à toa. "load" (DOM +
# recursos da própria navegação carregados) é o que um teste de UI aqui realmente
# precisa.
_LIMITE_TEXTO = 8_000


async def _texto_visivel(page) -> str:
    try:
        texto = (await page.inner_text("body")).strip()
    except Exception:  # noqa: BLE001 — extrair texto nunca deve derrubar a ferramenta
        return "(não consegui extrair o texto da página)"
    if len(texto) > _LIMITE_TEXTO:
        return texto[:_LIMITE_TEXTO] + f"\n... (cortado — {len(texto)} caracteres no total)"
    return texto


@tool(
    "qa_browser_open",
    "Abre uma sessão de navegador autenticada na sandbox do cliente pra testar a UI "
    "Lightning de verdade. Recusa se o alias não passar no guardrail de sandbox — a mesma "
    "checagem de sf_deploy (forma do alias + a org confirmar IsSandbox). 'path' é a rota "
    "Lightning relativa (ex.: '/lightning/o/Account/list') pra onde o login termina; sem "
    "isso, cai na Home. Devolve um session_id pra usar em qa_browser_click/qa_browser_fill/"
    "qa_browser_screenshot/qa_browser_close, e o texto visível da página inicial. Feche a "
    "sessão com qa_browser_close ao terminar — não deixe navegador aberto.",
    {"target_org": str, "path": str},
)
async def qa_browser_open(args: dict) -> dict:
    url, erro = url_de_login(args["target_org"])
    if erro:
        return _text_result(erro)

    caminho = args.get("path") or "/"
    if not caminho.startswith("/"):
        caminho = f"/{caminho}"
    separador = "&" if "?" in url else "?"
    destino = f"{url}{separador}retURL={quote(caminho, safe='')}"

    try:
        from playwright.async_api import async_playwright
    except ImportError:
        return _text_result(
            "Pacote 'playwright' não instalado neste ambiente. Instale com "
            "'pip install playwright' e 'playwright install --with-deps chromium' antes de "
            "testar a UI — ou, se a sandbox de QA ainda não conecta, use o roteiro escrito "
            "pra humano executar em vez desta ferramenta."
        )

    pw = await async_playwright().start()
    try:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page()
        await page.goto(destino, wait_until="load", timeout=30_000)
    except Exception as exc:  # noqa: BLE001 — reporta e fecha, nunca deixa processo pendurado
        await pw.stop()
        return _text_result(f"Não consegui abrir a sessão em {args['target_org']}: {exc}")

    session_id = uuid.uuid4().hex[:12]
    _SESSOES[session_id] = (pw, browser, page)
    titulo = await page.title()
    texto = await _texto_visivel(page)
    return _text_result(
        f"[OK] sessão {session_id} aberta em {page.url}\ntítulo: {titulo}\n\n{texto}"
    )


@tool(
    "qa_browser_click",
    "Clica no primeiro elemento com este texto visível, na sessão aberta por "
    "qa_browser_open. Devolve o texto da página depois do clique.",
    {"session_id": str, "texto": str},
)
async def qa_browser_click(args: dict) -> dict:
    sessao = _SESSOES.get(args["session_id"])
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já foi fechada.")
    _, _, page = sessao
    try:
        await page.get_by_text(args["texto"], exact=False).first.click(timeout=10_000)
        await page.wait_for_load_state("load", timeout=10_000)
    except Exception as exc:  # noqa: BLE001
        return _text_result(f"Não consegui clicar em {args['texto']!r}: {exc}")
    return _text_result(await _texto_visivel(page))


@tool(
    "qa_browser_fill",
    "Preenche o campo cujo rótulo (label) bate com este texto, na sessão aberta por "
    "qa_browser_open.",
    {"session_id": str, "rotulo": str, "valor": str},
)
async def qa_browser_fill(args: dict) -> dict:
    sessao = _SESSOES.get(args["session_id"])
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já foi fechada.")
    _, _, page = sessao
    try:
        campo = page.get_by_label(args["rotulo"], exact=False).first
        await campo.fill(args["valor"], timeout=10_000)
    except Exception as exc:  # noqa: BLE001
        return _text_result(f"Não consegui preencher {args['rotulo']!r}: {exc}")
    return _text_result(f"[OK] {args['rotulo']!r} preenchido com {args['valor']!r}.")


@tool(
    "qa_browser_screenshot",
    "Tira um screenshot da sessão aberta por qa_browser_open — evidência pra 05-testes.md. "
    "Nunca screenshote uma tela com dado real de cliente (guardrail #2 do CLAUDE.md): use só "
    "registros de teste que você mesmo criou, nunca abra um Contact/Account real pra olhar.",
    {"session_id": str},
)
async def qa_browser_screenshot(args: dict) -> dict:
    sessao = _SESSOES.get(args["session_id"])
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já foi fechada.")
    _, _, page = sessao
    try:
        png = await page.screenshot(type="png")
    except Exception as exc:  # noqa: BLE001
        return _text_result(f"Não consegui capturar o screenshot: {exc}")
    return {
        "content": [
            {"type": "image", "data": base64.b64encode(png).decode("ascii"), "mimeType": "image/png"}
        ]
    }


@tool(
    "qa_browser_close",
    "Fecha a sessão de navegador aberta por qa_browser_open e libera os recursos. Sempre "
    "chame ao terminar de testar — mesmo depois de um erro.",
    {"session_id": str},
)
async def qa_browser_close(args: dict) -> dict:
    sessao = _SESSOES.pop(args["session_id"], None)
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já estava fechada.")
    pw, browser, _ = sessao
    await browser.close()
    await pw.stop()
    return _text_result(f"[OK] sessão {args['session_id']} fechada.")


salesforce_tools_server = create_sdk_mcp_server(
    name="salesforce-tools",
    version="0.1.0",
    tools=[
        spec_read,
        sf_deploy,
        sf_retrieve,
        sf_query,
        sf_org_list,
        qa_browser_open,
        qa_browser_click,
        qa_browser_fill,
        qa_browser_screenshot,
        qa_browser_close,
    ],
)
