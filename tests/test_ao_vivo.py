from salesforce_agents import ao_vivo


def test_url_deriva_do_sync_de_demanda(monkeypatch):
    monkeypatch.delenv("SQUAD_OS_SYNC_EVENTO_URL", raising=False)
    monkeypatch.setenv("SQUAD_OS_SYNC_URL", "https://os.exemplo/api/sync/demanda")
    assert ao_vivo.url_de_eventos() == "https://os.exemplo/api/sync/evento"
    monkeypatch.setenv("SQUAD_OS_SYNC_EVENTO_URL", "https://outro/x")
    assert ao_vivo.url_de_eventos() == "https://outro/x"


def test_resumo_nunca_leva_conteudo():
    assert ao_vivo.resumir_ferramenta("Write", {"file_path": "/a/b/03-design.md", "content": "CPF 123"}) == "03-design.md"
    assert ao_vivo.resumir_ferramenta("Bash", {"command": "sf data query -q 'SELECT Email FROM Contact'"}) == "sf data query"
    assert ao_vivo.resumir_ferramenta("Grep", {"pattern": "Joao Silva"}) == ""
    assert ao_vivo.resumir_ferramenta("mcp__salesforce-tools__sf_query", {"soql": "SELECT Phone FROM Lead"}) == ""
    assert ao_vivo.nome_curto_de_ferramenta("mcp__salesforce-tools__sf_query") == "sf_query"


def test_sem_configuracao_e_no_op(monkeypatch):
    monkeypatch.delenv("SQUAD_OS_SYNC_URL", raising=False)
    monkeypatch.delenv("SQUAD_OS_SYNC_EVENTO_URL", raising=False)
    with ao_vivo.Emissor("c", "C-1", "analise") as e:
        e.ferramenta("t1", "Read", {"file_path": "x.md"}, None)
    assert not e.ativo


def test_atribui_ferramenta_ao_subagente(monkeypatch):
    enviados = []
    e = ao_vivo.Emissor("c", "C-1", "design", url="https://x/api/sync/evento", token="t", run_id="9")
    monkeypatch.setattr(e, "_enviar", lambda: enviados.extend(e._fila) or e._fila.clear())
    with e:
        e.ferramenta("task1", "Task", {"subagent_type": "arquiteto", "prompt": "segredo"}, None)
        e.ferramenta("t2", "Read", {"file_path": "/w/01-analise.md"}, "task1")
        e.turno(0.1234)
    tipos = [(x["tipo"], x["agente"], x["ferramenta"], x["detalhe"]) for x in enviados]
    assert tipos[0][0] == "inicio"
    assert ("agente", "arquiteto", "", "") in tipos
    assert ("ferramenta", "arquiteto", "Read", "01-analise.md") in tipos
    assert enviados[-1]["tipo"] == "fim" and enviados[-1]["detalhe"] == "ok"
    assert all("segredo" not in str(x) for x in enviados)
