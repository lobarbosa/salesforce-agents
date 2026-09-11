"""O log de gates: quem aprovou, e **o que** estava na mesa.

O que estes testes protegem é a diferença entre "Leonardo aprovou o design" e
"Leonardo aprovou *este* design" — a primeira frase não sustenta auditoria
nenhuma se o arquivo mudou depois.
"""

from __future__ import annotations

import os

import pytest

from salesforce_agents import demands, fluxo, gates


@pytest.fixture
def repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    monkeypatch.setattr(demands, "CLIENTS_ROOT", tmp_path / "clients")
    return tmp_path


def _demanda_no_gate(gate: str) -> demands.Demand:
    d = demands.create("acme", "Campo de origem no Lead", "texto")
    # Cria os artefatos de toda etapa até o gate pedido, senão `transition`
    # recusa avançar (ArtifactAusenteError) — que é o comportamento correto.
    alvo = demands.STAGES_EXECUCAO.index(gate)
    atual = d.status
    for etapa in demands.STAGES_EXECUCAO[: alvo + 1]:
        for nome in demands.REQUIRED_ARTIFACTS.get(atual, ()):
            (d.path / nome).write_text(f"conteúdo de {nome}\n", encoding="utf-8")
        d = demands.transition("acme", d.id, etapa, "pipeline")
        atual = etapa
    return d


def test_aprovar_gate_escreve_o_bloco_sem_ninguem_pedir(repo):
    """Mecânico, não instrução no prompt: o registro não depende de o agente
    lembrar de escrever."""
    d = _demanda_no_gate("aguardando_gate_design")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")

    texto = (d.path / "gates.md").read_text(encoding="utf-8")
    assert "aguardando_gate_design" in texto
    assert "Leonardo" in texto
    assert "03-design.md" in texto
    assert "02-recon.md" in texto


def test_o_bloco_carrega_o_hash_do_que_foi_revisado(repo):
    d = _demanda_no_gate("aguardando_gate_analise")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    assert gates.conferir(d, "aguardando_gate_analise") == []

    (d.path / "01-analise.md").write_text("outra coisa\n", encoding="utf-8")
    assert gates.conferir(d, "aguardando_gate_analise") == ["01-analise.md"]


def test_artefatos_do_gate_saem_da_mesma_tabela_que_bloqueia_o_avanco(repo):
    """Se as duas listas divergirem, o gate registra evidência de outra coisa."""
    for gate, etapa in (
        ("aguardando_gate_analise", "analise"),
        ("aguardando_gate_design", "design"),
        ("aguardando_gate_build", "build"),
        ("aguardando_homologacao", "qa"),
    ):
        assert gates.etapa_do_gate(gate) == etapa
        assert gates.artefatos_do_gate(gate) == demands.REQUIRED_ARTIFACTS[etapa]


def test_todo_gate_do_fluxo_sabe_o_que_esta_revisando(repo):
    """Gate que não soubesse o que revisa registraria aprovação sem evidência."""
    for gate in demands.STAGES_EXECUCAO:
        if not gate.startswith("aguardando_"):
            continue
        assert gates.artefatos_do_gate(gate), gate


def test_reaprovacao_confere_contra_o_registro_mais_recente(repo):
    """Gate reprovado, artefato corrigido, gate aprovado de novo: o que vale é
    o último registro, não o primeiro."""
    d = _demanda_no_gate("aguardando_gate_analise")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")

    demands.transition("acme", d.id, "aguardando_gate_analise", "Leonardo")  # recuo/correção
    (d.path / "01-analise.md").write_text("versão corrigida\n", encoding="utf-8")
    assert gates.conferir(d, "aguardando_gate_analise") == ["01-analise.md"]

    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    assert gates.conferir(d, "aguardando_gate_analise") == []


def test_gates_md_e_o_arquivo_que_o_claude_md_promete(repo):
    d = _demanda_no_gate("aguardando_gate_analise")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    assert (d.path / "gates.md").exists()
    assert gates.NOME_ARQUIVO == "gates.md"


def test_conferir_sem_registro_nao_inventa_divergencia(repo):
    d = _demanda_no_gate("aguardando_gate_analise")
    assert gates.conferir(d, "aguardando_gate_analise") == []
    assert gates.conferir(d, "aguardando_gate_build") == []


def test_commit_atual_nao_derruba_o_registro_fora_de_um_repo(repo):
    """`gates.md` precisa valer mesmo sem git — o hash do artefato é a evidência,
    o commit é conveniência."""
    os.environ.pop("GIT_DIR", None)
    d = _demanda_no_gate("aguardando_gate_analise")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    assert "Aprovado por" in (d.path / "gates.md").read_text(encoding="utf-8")


def test_registrados_lista_so_o_que_foi_aprovado(repo):
    d = _demanda_no_gate("aguardando_gate_design")
    assert gates.registrados(d) == []
    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    assert gates.registrados(d) == ["aguardando_gate_design"]
