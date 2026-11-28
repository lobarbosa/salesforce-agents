import importlib.util
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("coerencia", RAIZ / "scripts" / "coerencia_ativacao_flows.py")
coerencia = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(coerencia)

FLOW = "force-app/main/default/flows/Agendado.flow-meta.xml"
DEF = "force-app/main/default/flowDefinitions/Agendado.flowDefinition-meta.xml"


def _pacote(tmp_path, status="Active", ativa="0", com_flow=True):
    (tmp_path / FLOW).parent.mkdir(parents=True)
    (tmp_path / DEF).parent.mkdir(parents=True)
    (tmp_path / FLOW).write_text(f"<Flow><label>x</label><status>{status}</status></Flow>", encoding="utf-8")
    (tmp_path / DEF).write_text(f"<FlowDefinition><activeVersionNumber>{ativa}</activeVersionNumber></FlowDefinition>", encoding="utf-8")
    return ["--source-dir", FLOW, "--source-dir", DEF] if com_flow else ["--source-dir", DEF]


def test_flow_mandado_desativar_que_ia_ativo_vira_obsolete(tmp_path):
    """Achado EPLAST-47: definição em 0 e Flow Active criou versão nova ativa na QA."""
    nomes, corrigidos = coerencia.corrigir(tmp_path, coerencia.caminhos_do_pacote(_pacote(tmp_path)))
    assert nomes == ["Agendado"] and corrigidos == ["Agendado"]
    assert "<status>Obsolete</status>" in (tmp_path / FLOW).read_text(encoding="utf-8")


def test_flow_com_versao_ativa_pedida_nao_e_tocado(tmp_path):
    nomes, corrigidos = coerencia.corrigir(tmp_path, coerencia.caminhos_do_pacote(_pacote(tmp_path, ativa="3")))
    assert nomes == [] and corrigidos == []
    assert "<status>Active</status>" in (tmp_path / FLOW).read_text(encoding="utf-8")


def test_so_a_definicao_no_pacote_ainda_entra_na_conferencia(tmp_path):
    nomes, corrigidos = coerencia.corrigir(tmp_path, coerencia.caminhos_do_pacote(_pacote(tmp_path, com_flow=False)))
    assert nomes == ["Agendado"] and corrigidos == []
