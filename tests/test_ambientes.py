"""A regra de qual etapa roda em qual org é lida por run-demand.yml pra decidir
qual GitHub Environment abrir — ou seja, qual credencial o job enxerga. Errar
aqui não dá erro de sintaxe em lugar nenhum: dá deploy na org errada."""

import pytest

from salesforce_agents import ambientes, demands


def test_build_e_tudo_antes_roda_em_dev():
    for etapa in ("analise", "aguardando_gate_analise", "design",
                  "aguardando_gate_design", "build", "aguardando_gate_build"):
        assert ambientes.ambiente_do_estagio(etapa) == "dev", etapa


def test_de_qa_em_diante_roda_na_sandbox_de_qa():
    for etapa in ("qa", "aguardando_homologacao", "release", "entregue"):
        assert ambientes.ambiente_do_estagio(etapa) == "qa", etapa


def test_triagem_cai_no_default_dev():
    for etapa in demands.STAGES_TRIAGEM:
        assert ambientes.ambiente_do_estagio(etapa) == "dev", etapa


def test_todo_estagio_conhecido_tem_ambiente():
    # Se alguém acrescentar um estágio em demands.STAGES e esquecer deste
    # módulo, o mapeamento silenciosamente responderia "dev" — este teste é
    # só pra garantir que nenhum estágio explode.
    for etapa in demands.STAGES:
        assert ambientes.ambiente_do_estagio(etapa) in ambientes.AMBIENTES


def test_estagio_desconhecido_falha_alto():
    with pytest.raises(ValueError):
        ambientes.ambiente_do_estagio("deploy_producao")


def test_alias_e_environment_seguem_a_convencao():
    assert ambientes.org_alias("acxya", "dev") == "sbx-acxya-dev"
    assert ambientes.org_alias("acxya", "qa") == "sbx-acxya-qa"
    assert ambientes.github_environment("centric", "qa") == "centric-qa"


@pytest.mark.parametrize("proibido", ["prod", "prd", "production", "PROD", ""])
def test_producao_nao_existe_neste_mapa(proibido):
    """Guardrail #1 vale aqui também: não dá pra pedir o alias de prod nem por
    engano — o erro acontece antes de qualquer comando `sf` ser montado."""
    with pytest.raises(ValueError):
        ambientes.org_alias("acxya", proibido)
    with pytest.raises(ValueError):
        ambientes.github_environment("acxya", proibido)
