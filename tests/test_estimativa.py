"""Estimativa por demanda: horas vêm do artefato, custo vem da telemetria."""

from __future__ import annotations

import pytest

from salesforce_agents import demands, estimativa


@pytest.fixture
def repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    monkeypatch.setattr(demands, "CLIENTS_ROOT", tmp_path / "clients")
    return tmp_path


def _demanda(status="aguardando_gate_analise"):
    d = demands.create("acme", "Campo novo", "texto")
    d.status = status
    d.save()
    return d


def test_horas_da_analise_em_faixa(repo):
    d = _demanda()
    (d.path / "01-analise.md").write_text("## Esforço\n**Estimativa de esforço:** 4–8 h (premissas...)\n")
    assert estimativa.horas(d) == {"min": 4.0, "max": 8.0, "fonte": "01-analise.md"}


def test_design_vence_a_analise(repo):
    d = _demanda("aguardando_gate_design")
    (d.path / "01-analise.md").write_text("**Estimativa de esforço:** 4-8 h\n")
    (d.path / "03-design.md").write_text("**Estimativa de esforço:** 10 a 12,5 h\n")
    assert estimativa.horas(d) == {"min": 10.0, "max": 12.5, "fonte": "03-design.md"}


def test_sem_linha_nao_inventa(repo):
    d = _demanda()
    (d.path / "01-analise.md").write_text("# Análise\nsem estimativa\n")
    assert estimativa.horas(d) is None


def test_etapas_restantes_a_partir_do_gate():
    assert estimativa.etapas_restantes("backlog") == ["analise", "design", "build", "qa", "release"]
    assert estimativa.etapas_restantes("aguardando_gate_design") == ["build", "qa", "release"]
    assert estimativa.etapas_restantes("entregue") == []


def _linha(demanda, etapa, custo, client="acme"):
    return {"client": client, "demand_id": demanda, "etapa": etapa, "cost_usd": str(custo)}


def test_custo_gasto_e_restante_com_historico(repo):
    d = _demanda("aguardando_gate_design")
    linhas = [
        _linha(d.id, "analise", 0.2), _linha(d.id, "design", 1.0), _linha(d.id, "design", 0.5),
        _linha("X-1", "build", 1.0, "outro"), _linha("X-2", "build", 3.0, "outro"),
        _linha("X-3", "build", 2.0, "outro"),
        {"client": "acme", "demand_id": "-assessment-", "etapa": "assessment", "cost_usd": "9"},
    ]
    r = estimativa.custo_agente(d, linhas)
    assert r["gastoUsd"] == 1.7  # assessment não conta
    # build: mediana de 3 amostras = 2.0; qa e release sem histórico → partida
    assert r["restanteUsd"] == pytest.approx(
        2.0 + estimativa.PARTIDA_USD["qa"] + estimativa.PARTIDA_USD["release"]
    )
    assert r["amostras"] == 3


def test_horas_de_agente_pela_duracao_das_sessoes(repo):
    d = _demanda("aguardando_gate_design")
    hora = 3_600_000
    linhas = [
        {"client": "acme", "demand_id": d.id, "etapa": "analise", "duration_ms": str(hora // 2)},
        {"client": "acme", "demand_id": d.id, "etapa": "design", "duration_ms": str(hora)},
    ] + [
        {"client": "o", "demand_id": f"X-{i}", "etapa": "build", "duration_ms": str(hora * i)}
        for i in (1, 2, 3)
    ]
    r = estimativa.horas_agente(d, linhas)
    assert r["gastoH"] == 1.5
    assert r["restanteH"] == pytest.approx(
        2.0 + estimativa.PARTIDA_HORAS_AGENTE["qa"] + estimativa.PARTIDA_HORAS_AGENTE["release"]
    )
