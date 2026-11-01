"""Assessment da org entra no prompt de toda etapa de demanda (2026-11-01)."""

import json

from salesforce_agents.assessment import nota_para_o_prompt


def test_sem_assessment_nao_acrescenta_nada(tmp_path):
    (tmp_path / "x").mkdir()
    assert nota_para_o_prompt("x", raiz=tmp_path) == ""


def test_assessment_vai_com_saude_resumo_e_recomendacoes(tmp_path):
    (tmp_path / "x").mkdir()
    (tmp_path / "x" / "assessment.json").write_text(
        json.dumps(
            {
                "saude": "vermelho",
                "resumo": "31 automações em Oportunidade.",
                "recomendacoes": [{"titulo": "Consolidar automações", "severidade": "alta", "area": "automação"}],
            }
        ),
        encoding="utf-8",
    )
    nota = nota_para_o_prompt("x", raiz=tmp_path)
    assert "**vermelho**" in nota
    assert "31 automações em Oportunidade." in nota
    assert "[alta] Consolidar automações (automação)" in nota
    assert "guardrail #3" in nota


def test_json_quebrado_nao_derruba_a_sessao(tmp_path):
    (tmp_path / "x").mkdir()
    (tmp_path / "x" / "assessment.json").write_text("{nao é json", encoding="utf-8")
    assert nota_para_o_prompt("x", raiz=tmp_path) == ""
