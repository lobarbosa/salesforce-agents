"""Promoção de agente QA → DEV (scripts/agentforce_dependencias.py e
scripts/resumo_validacao.py) — sem org, só as partes puras."""

import importlib.util
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def _carregar(nome):
    spec = importlib.util.spec_from_file_location(nome, RAIZ / "scripts" / f"{nome}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


dep = _carregar("agentforce_dependencias")
val = _carregar("resumo_validacao")


def test_package_xml_ordena_e_pula_tipo_vazio():
    xml = dep.package_xml({"GenAiPlugin": {"B", "A"}, "Flow": set(), "Bot": {"SFAgent2"}})
    assert xml.index("<name>Bot</name>") < xml.index("<name>GenAiPlugin</name>")
    assert "<members>A</members>\n        <members>B</members>" in xml
    assert "<name>Flow</name>" not in xml


def test_nomes_citados_por_palavra_inteira(tmp_path):
    f = tmp_path / "a.xml"
    f.write_text("<genAiPluginName>Topico_Vendas</genAiPluginName><invocationTarget>Flow_Resumo</invocationTarget>")
    citados = dep.nomes_citados([f], {"GenAiPlugin": {"Topico_Vendas", "Topico"}, "Flow": {"Flow_Resumo", "Resumo"}})
    assert citados == {"GenAiPlugin": {"Topico_Vendas"}, "Flow": {"Flow_Resumo"}}


def test_resumo_validacao_ok_e_falhas():
    assert "ok" in val.resumo({"status": 0, "result": {"details": {}}})
    texto = val.resumo(
        {
            "status": 1,
            "result": {"details": {"componentFailures": {"componentType": "GenAiFunction", "fullName": "X", "problem": "no Field a|b"}}},
        }
    )
    assert "| GenAiFunction | `X` | no Field a/b |" in texto
