"""qa_browser_click e qa_browser_fill contra marcação parecida com a do Lightning.

Achados que motivaram (2026-11-16): na EPLAST-41 o preenchimento caiu no botão de
ajuda do campo, e na EPLAST-30 o clique por texto não mudou a opção do rádio do
Screen Flow. As duas demandas foram reprovadas três vezes sem defeito no build.
"""

from __future__ import annotations

import asyncio
import os
import sys
import types

import pytest

pytest.importorskip("playwright")

# tools.py importa o SDK do agente só para registrar as ferramentas; aqui interessa
# o corpo delas, então um substituto mínimo basta quando o SDK não está instalado.
try:
    import claude_agent_sdk  # noqa: F401
except ImportError:
    falso = types.ModuleType("claude_agent_sdk")
    falso.tool = lambda *_a, **_k: (lambda f: f)
    falso.create_sdk_mcp_server = lambda **_k: None
    sys.modules["claude_agent_sdk"] = falso

from salesforce_agents import tools  # noqa: E402

PAGINA = """
<!doctype html><html><body>
<p>Escolha entre Proposta comercial, Follow-up e Argumentos comerciais.</p>
<fieldset>
  <legend>Tipo de texto</legend>
  <span class="slds-radio">
    <input type="radio" id="r1" name="tipo" value="proposta" checked
           style="position:absolute;opacity:0;width:1px;height:1px">
    <label for="r1"><span class="slds-radio_faux"></span><span>Proposta comercial</span></label>
  </span>
  <span class="slds-radio">
    <input type="radio" id="r2" name="tipo" value="followup"
           style="position:absolute;opacity:0;width:1px;height:1px">
    <label for="r2"><span class="slds-radio_faux"></span><span>Follow-up</span></label>
  </span>
</fieldset>
<fieldset>
  <legend>Canal preferido</legend>
  <!-- Como no Screen Flow: o clique direto no input não muda a opção; só pelo rótulo. -->
  <span class="slds-radio">
    <input type="radio" id="c1" name="canal_pref" value="email" checked
           style="position:absolute;opacity:0;width:1px;height:1px">
    <label for="c1"><span>Somente e-mail</span></label>
  </span>
  <span class="slds-radio">
    <input type="radio" id="c2" name="canal_pref" value="fone"
           style="position:absolute;opacity:0;width:1px;height:1px">
    <label for="c2" onmousedown="window.viaRotulo = true"><span>Somente telefone</span></label>
  </span>
  <script>
    document.getElementById('c2').addEventListener('click', (e) => { if (!window.viaRotulo) e.preventDefault(); });
  </script>
</fieldset>
<div>
  <button type="button" aria-label="Ajuda: Tipo e objetivo da mensagem">?</button>
  <label for="obj">Tipo e objetivo da mensagem</label>
  <textarea id="obj"></textarea>
</div>
<label for="canal">Canal</label>
<select id="canal"><option>E-mail</option><option>Telefone</option></select>
<button type="button" onclick="document.getElementById('saida').textContent='avançou'">Avançar</button>
<p id="saida"></p>
</body></html>
"""


def _chromium():
    """Chromium já instalado no ambiente (sessão na nuvem), se houver; senão o do Playwright."""
    caminho = os.environ.get("QA_BROWSER_CHROMIUM", "/opt/pw-browsers/chromium")
    return caminho if os.path.isfile(caminho) else None


async def _sessao():
    from playwright.async_api import async_playwright

    pw = await async_playwright().start()
    opcoes = {"headless": True, "args": ["--no-sandbox"]}
    executavel = _chromium()
    if executavel:
        opcoes["executable_path"] = executavel
    try:
        browser = await pw.chromium.launch(**opcoes)
    except Exception as exc:  # noqa: BLE001 — sem navegador no ambiente, o teste não se aplica
        await pw.stop()
        pytest.skip(f"Chromium indisponível: {exc}")
    page = await browser.new_page()
    await page.set_content(PAGINA)
    tools._SESSOES["t"] = (pw, browser, page)
    return pw, browser, page


async def _fechar(pw, browser):
    tools._SESSOES.pop("t", None)
    await browser.close()
    await pw.stop()


def _texto(resultado: dict) -> str:
    return resultado["content"][0]["text"]


def test_fill_preenche_o_campo_e_nao_o_botao_de_ajuda():
    async def rodar():
        pw, browser, page = await _sessao()
        try:
            r = await tools.qa_browser_fill(
                {"session_id": "t", "rotulo": "Tipo e objetivo da mensagem", "valor": "Reativar cliente"}
            )
            return _texto(r), await page.input_value("#obj")
        finally:
            await _fechar(pw, browser)

    texto, valor = asyncio.run(rodar())
    assert texto.startswith("[OK]"), texto
    assert valor == "Reativar cliente"


def test_fill_escolhe_opcao_de_lista():
    async def rodar():
        pw, browser, page = await _sessao()
        try:
            r = await tools.qa_browser_fill({"session_id": "t", "rotulo": "Canal", "valor": "Telefone"})
            return _texto(r), await page.input_value("#canal")
        finally:
            await _fechar(pw, browser)

    texto, valor = asyncio.run(rodar())
    assert texto.startswith("[OK]"), texto
    assert valor == "Telefone"


def test_fill_sem_campo_diz_que_nao_achou():
    async def rodar():
        pw, browser, _page = await _sessao()
        try:
            return _texto(await tools.qa_browser_fill({"session_id": "t", "rotulo": "Não existe", "valor": "x"}))
        finally:
            await _fechar(pw, browser)

    assert "Não achei campo de entrada" in asyncio.run(rodar())


def test_click_marca_o_radio_mesmo_com_o_texto_repetido_na_pagina():
    async def rodar():
        pw, browser, page = await _sessao()
        try:
            r = await tools.qa_browser_click({"session_id": "t", "texto": "Follow-up"})
            return _texto(r), await page.is_checked("#r2"), await page.is_checked("#r1")
        finally:
            await _fechar(pw, browser)

    texto, followup, proposta = asyncio.run(rodar())
    assert "[radio 'Follow-up': marcado]" in texto, texto[:200]
    assert followup and not proposta


def test_click_em_botao_continua_funcionando():
    async def rodar():
        pw, browser, page = await _sessao()
        try:
            await tools.qa_browser_click({"session_id": "t", "texto": "Avançar"})
            return await page.inner_text("#saida")
        finally:
            await _fechar(pw, browser)

    assert asyncio.run(rodar()) == "avançou"


def test_screenshot_guarda_a_evidencia_na_pasta_da_demanda(tmp_path, monkeypatch):
    pasta = tmp_path / "clients" / "x" / "demandas" / "X-1"
    pasta.mkdir(parents=True)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("CLIENT", "x")
    monkeypatch.setenv("DEMAND_ID", "X-1")

    async def rodar():
        pw, browser, _page = await _sessao()
        try:
            return await tools.qa_browser_screenshot({"session_id": "t", "legenda": "Tela de teste"})
        finally:
            await _fechar(pw, browser)

    r = asyncio.run(rodar())
    assert "evidencias/01-tela-de-teste.jpg" in r["content"][0]["text"]
    assert r["content"][1]["type"] == "image"
    salvo = pasta / "evidencias" / "01-tela-de-teste.jpg"
    assert salvo.read_bytes()[:2] == b"\xff\xd8"  # JPEG


def test_click_marca_o_radio_pelo_rotulo_quando_o_input_nao_aceita_o_clique():
    async def rodar():
        pw, browser, page = await _sessao()
        try:
            r = await tools.qa_browser_click({"session_id": "t", "texto": "Somente telefone"})
            return _texto(r), await page.is_checked("#c2")
        finally:
            await _fechar(pw, browser)

    texto, marcado = asyncio.run(rodar())
    assert marcado
    assert "[radio 'Somente telefone': marcado]" in texto, texto[:200]
