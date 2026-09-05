import pytest

from salesforce_agents import demands


@pytest.fixture(autouse=True)
def isolated_clients_root(tmp_path, monkeypatch):
    monkeypatch.setattr(demands, "CLIENTS_ROOT", tmp_path / "clients")
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    yield


def test_create_assigns_incrementing_id_per_client():
    d1 = demands.create("acme", "Primeira demanda", "texto 1")
    d2 = demands.create("acme", "Segunda demanda", "texto 2")

    assert d1.id == "ACME-1"
    assert d2.id == "ACME-2"
    assert d1.status == "backlog"
    assert (d1.path / "demanda.md").read_text(encoding="utf-8").strip() == (
        "# Primeira demanda\n\ntexto 1"
    )


def test_transition_updates_status_and_history():
    d = demands.create("acme", "Demanda", "texto")
    updated = demands.transition("acme", d.id, "analise", autor="leo")

    assert updated.status == "analise"
    assert updated.historico[-1] == {
        "de": "backlog",
        "para": "analise",
        "autor": "leo",
        "em": updated.historico[-1]["em"],
    }

    reloaded = demands.Demand.load("acme", d.id)
    assert reloaded.status == "analise"
    assert len(reloaded.historico) == 1


def test_transition_rejects_unknown_status():
    d = demands.create("acme", "Demanda", "texto")
    with pytest.raises(demands.InvalidStatusError):
        demands.transition("acme", d.id, "nao-existe", autor="leo")


def test_transition_missing_demand_raises():
    with pytest.raises(demands.DemandNotFoundError):
        demands.transition("acme", "ACME-999", "analise", autor="leo")


def test_list_demands_filters_by_client():
    demands.create("acme", "Demanda 1", "texto")
    (demands.CLIENTS_ROOT / "outro").mkdir(parents=True)
    demands.create("outro", "Demanda 2", "texto")

    todas = demands.list_demands()
    so_acme = demands.list_demands("acme")

    assert {d.client for d in todas} == {"acme", "outro"}
    assert [d.client for d in so_acme] == ["acme"]
