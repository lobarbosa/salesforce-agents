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
import os
import uuid
from pathlib import Path
from urllib.parse import quote

from claude_agent_sdk import create_sdk_mcp_server, tool

from . import evidencias
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


# Tudo o que uma ferramenta devolve é relido pelo modelo a cada turno até o fim
# da sessão: 93% dos tokens da esteira são releitura (medido em 2026-11-14).
# Uma saída de 200 KB de `sf` custa 200 KB vezes o número de turnos seguintes.
# O corte guarda o começo e o fim e diz ao agente para refinar o comando.
LIMITE_SAIDA_SF = 12_000


def _cortar(texto: str, limite: int = LIMITE_SAIDA_SF) -> str:
    if len(texto) <= limite:
        return texto
    cabeca, cauda = texto[: limite * 3 // 4], texto[-(limite // 4):]
    return (
        f"{cabeca}\n\n... [saída cortada: {len(texto)} caracteres no total, mostrando o começo e o fim. "
        "Refine o comando — campos específicos na query, --metadata mais estreito, LIMIT — em vez de "
        "pedir tudo de novo.] ...\n\n"
        f"{cauda}"
    )


def _run_sf(args: list[str]) -> dict:
    try:
        proc = sf(args)
    except CliAusenteError:
        return _text_result(
            "Salesforce CLI ('sf') não encontrada no PATH. Instale com "
            "'npm install -g @salesforce/cli' e autentique o org do cliente."
        )
    output = _cortar(proc.stdout.strip() or proc.stderr.strip())
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


# Papéis que o agente quer dizer quando pede "clique em X". A ordem importa: opção
# de rádio e caixa de seleção primeiro, porque no Lightning o texto delas também
# aparece em outros pontos da tela (achado EPLAST-30, 2026-11-16: o clique por texto
# não mudou o rádio do Screen Flow e o QA reprovou sem defeito no build).
_PAPEIS_CLICAVEIS = ("radio", "checkbox", "button", "tab", "menuitem", "option", "link")
_PAPEIS_PREENCHIVEIS = ("textbox", "combobox", "spinbutton", "searchbox")


async def _primeiro_visivel(localizador):
    """Primeiro elemento visível do localizador, ou None."""
    for i in range(min(await localizador.count(), 20)):
        item = localizador.nth(i)
        try:
            if await item.is_visible():
                return item
        except Exception:  # noqa: BLE001 — elemento saiu da página entre o count e o teste
            continue
    return None


async def _achar_clicavel(page, texto: str):
    """(elemento, papel) para o texto pedido: por papel acessível, nome exato antes de parcial."""
    for exato in (True, False):
        for papel in _PAPEIS_CLICAVEIS:
            item = await _primeiro_visivel(page.get_by_role(papel, name=texto, exact=exato))
            if item is not None:
                return item, papel
    return None, ""


async def _achar_campo(page, rotulo: str):
    """Campo de entrada com este rótulo. Nunca o botão de ajuda ao lado dele.

    Achado EPLAST-41 (2026-11-16): `get_by_label(rotulo).first` devolvia o botão de
    ajuda do campo (aria-label "Ajuda: <rótulo>"), que vem antes do campo no DOM.
    """
    for exato in (True, False):
        for papel in _PAPEIS_PREENCHIVEIS:
            item = await _primeiro_visivel(page.get_by_role(papel, name=rotulo, exact=exato))
            if item is not None:
                return item
    candidatos = page.get_by_label(rotulo, exact=False)
    for i in range(min(await candidatos.count(), 20)):
        item = candidatos.nth(i)
        try:
            if not await item.is_visible():
                continue
            preenchivel = await item.evaluate(
                "e => ['INPUT','TEXTAREA','SELECT'].includes(e.tagName) || e.isContentEditable"
            )
        except Exception:  # noqa: BLE001
            continue
        if preenchivel:
            return item
    return None


async def _marcar(page, item, texto: str) -> bool:
    """Marca rádio ou caixa de seleção e devolve se ficou marcado.

    Três tentativas, da mais direta à que imita a pessoa. Achado EPLAST-30
    (2026-11-16, rodada 4): no Screen Flow do Lightning, marcar o `<input>` escondido
    com `force` falhou com "Clicking the checkbox did not change its state".
    """
    tentativas = (
        lambda: item.check(timeout=5_000, force=True),
        lambda: item.evaluate("e => e.click()"),
        lambda: _clicar_rotulo(page, item, texto),
    )
    for tentar in tentativas:
        try:
            await tentar()
        except Exception:  # noqa: BLE001 — a próxima tentativa decide
            pass
        try:
            if await item.is_checked():
                return True
        except Exception:  # noqa: BLE001
            return False
    return False


async def _clicar_rotulo(page, item, texto: str) -> None:
    """Clica no rótulo desenhado da opção: o `label[for]` do input ou, sem ele, o texto ao lado."""
    ident = await item.get_attribute("id")
    if ident:
        rotulo = page.locator(f'label[for="{ident}"]')
        if await rotulo.count():
            await rotulo.first.click(timeout=5_000)
            return
    await item.locator("xpath=..").get_by_text(texto, exact=False).first.click(timeout=5_000)


@tool(
    "qa_browser_click",
    "Clica no elemento com este texto visível, na sessão aberta por qa_browser_open: opção "
    "de rádio, caixa de seleção, botão, aba, item de menu ou link com esse nome; se não "
    "houver, o primeiro texto igual na página. Em rádio e caixa de seleção, marca a opção e "
    "diz se ficou marcada. Devolve o texto da página depois do clique.",
    {"session_id": str, "texto": str},
)
async def qa_browser_click(args: dict) -> dict:
    sessao = _SESSOES.get(args["session_id"])
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já foi fechada.")
    _, _, page = sessao
    aviso = ""
    try:
        item, papel = await _achar_clicavel(page, args["texto"])
        if item is None:
            await page.get_by_text(args["texto"], exact=False).first.click(timeout=10_000)
        elif papel in ("radio", "checkbox"):
            # No Lightning o <input> fica escondido atrás do rótulo desenhado: o clique
            # comum é interceptado. `force` marca o próprio input, e o estado é conferido.
            marcado = await _marcar(page, item, args["texto"])
            aviso = f"[{papel} {args['texto']!r}: {'marcado' if marcado else 'NÃO ficou marcado'}]\n\n"
        else:
            await item.click(timeout=10_000)
        await page.wait_for_load_state("load", timeout=10_000)
    except Exception as exc:  # noqa: BLE001
        return _text_result(f"Não consegui clicar em {args['texto']!r}: {exc}")
    return _text_result(aviso + await _texto_visivel(page))


@tool(
    "qa_browser_fill",
    "Preenche o campo de entrada (texto, área de texto, número ou lista) cujo rótulo bate "
    "com este texto, na sessão aberta por qa_browser_open. Confere o valor depois de "
    "preencher.",
    {"session_id": str, "rotulo": str, "valor": str},
)
async def qa_browser_fill(args: dict) -> dict:
    sessao = _SESSOES.get(args["session_id"])
    if not sessao:
        return _text_result(f"Sessão {args['session_id']!r} não existe ou já foi fechada.")
    _, _, page = sessao
    try:
        campo = await _achar_campo(page, args["rotulo"])
        if campo is None:
            return _text_result(
                f"Não achei campo de entrada com o rótulo {args['rotulo']!r}. Confira o rótulo "
                "exato no texto da página."
            )
        if await campo.evaluate("e => e.tagName === 'SELECT'"):
            await campo.select_option(label=args["valor"], timeout=10_000)
            eh_lista = True
        else:
            await campo.fill(args["valor"], timeout=10_000)
            eh_lista = False
        try:
            obtido = await campo.input_value()
        except Exception:  # noqa: BLE001 — campo editável sem value (contenteditable)
            obtido = args["valor"]
    except Exception as exc:  # noqa: BLE001
        return _text_result(f"Não consegui preencher {args['rotulo']!r}: {exc}")
    if obtido != args["valor"] and not eh_lista:
        return _text_result(
            f"Preenchi {args['rotulo']!r}, mas o campo ficou com {obtido!r} em vez de {args['valor']!r}."
        )
    return _text_result(f"[OK] {args['rotulo']!r} preenchido com {args['valor']!r}.")


def _pasta_da_demanda() -> Path | None:
    """Pasta da demanda do job (CLIENT e DEMAND_ID vêm do run-demand.yml), se existir."""
    cliente, demanda = os.environ.get("CLIENT", ""), os.environ.get("DEMAND_ID", "")
    if not cliente or not demanda:
        return None
    pasta = Path("clients") / cliente / "demandas" / demanda
    return pasta if pasta.is_dir() else None


@tool(
    "qa_browser_screenshot",
    "Tira um screenshot da sessão aberta por qa_browser_open e o guarda como evidência da "
    "demanda (pasta evidencias/): as capturas vão para o PDF 'Evidências de teste' anexado ao "
    "card. 'legenda' diz o que a tela prova (ex.: 'CA-03: rascunho gerado para a conta de "
    "teste'). Cite no 05-testes.md o arquivo devolvido. Nunca screenshote uma tela com dado "
    "real de cliente (guardrail #2 do CLAUDE.md): use só registros de teste que você mesmo "
    "criou, nunca abra um Contact/Account real pra olhar.",
    {"session_id": str, "legenda": str},
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

    # A evidência guardada é JPEG: cabe no sync e no PDF. O agente continua vendo o PNG.
    aviso = "Captura não guardada: sem pasta de demanda neste processo."
    pasta = _pasta_da_demanda()
    if pasta is not None:
        try:
            jpeg = await page.screenshot(type="jpeg", quality=60)
            caminho = evidencias.salvar_captura(pasta, jpeg, str(args.get("legenda") or "tela"))
            aviso = f"[OK] evidência guardada em demandas/{pasta.name}/{evidencias.PASTA}/{caminho.name}"
        except Exception as exc:  # noqa: BLE001 — guardar a evidência nunca derruba o teste
            aviso = f"Captura não guardada: {exc}"
    return {
        "content": [
            {"type": "text", "text": aviso},
            {"type": "image", "data": base64.b64encode(png).decode("ascii"), "mimeType": "image/png"},
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
