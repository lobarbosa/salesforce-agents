"""O plano do agente vira cartão no quadro de um cliente. Um id de entregável
inventado ou uma demanda sem título não dão erro em lugar nenhum — viram lixo
que alguém limpa à mão depois."""

import json
from pathlib import Path

import pytest

from salesforce_agents import planejamento


@pytest.fixture
def repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    return tmp_path


def _grava(plano: dict):
    Path("clients/acme/plano-demandas.json").write_text(
        json.dumps(plano, ensure_ascii=False), encoding="utf-8"
    )


def _demanda(**extra):
    base = {"entregavelId": "e1", "titulo": "Criar campo de aniversário no Lead"}
    base.update(extra)
    return base


def test_plano_valido_passa(repo):
    _grava({"demandas": [_demanda(), _demanda(entregavelId="e2", titulo="Outra")]})
    dados = planejamento.ler_plano("acme", {"e1", "e2"})
    assert len(dados["demandas"]) == 2
    assert dados["cliente"] == "acme"


def test_arquivo_ausente_falha_com_mensagem_util(repo):
    with pytest.raises(planejamento.PlanejamentoError, match="não existe"):
        planejamento.ler_plano("acme")


def test_json_invalido_falha(repo):
    Path("clients/acme/plano-demandas.json").write_text("{ nao é json", encoding="utf-8")
    with pytest.raises(planejamento.PlanejamentoError, match="não é JSON válido"):
        planejamento.ler_plano("acme")


def test_lista_vazia_falha(repo):
    _grava({"demandas": []})
    with pytest.raises(planejamento.PlanejamentoError, match="não vazia"):
        planejamento.ler_plano("acme")


def test_demanda_sem_titulo_falha(repo):
    _grava({"demandas": [_demanda(titulo="   ")]})
    with pytest.raises(planejamento.PlanejamentoError, match="sem título"):
        planejamento.ler_plano("acme", {"e1"})


def test_demanda_sem_entregavel_falha(repo):
    """Demanda sem entregável é escopo que ninguém vendeu."""
    _grava({"demandas": [_demanda(entregavelId="")]})
    with pytest.raises(planejamento.PlanejamentoError, match="não aponta pra entregável"):
        planejamento.ler_plano("acme", {"e1"})


def test_entregavel_inventado_falha(repo):
    """O caso que mais importa: o agente devolve um id que não existe no
    contrato, e a demanda entraria no quadro pendurada em nada."""
    _grava({"demandas": [_demanda(entregavelId="e-inventado")]})
    with pytest.raises(planejamento.PlanejamentoError, match="inventou o id"):
        planejamento.ler_plano("acme", {"e1", "e2"})


def test_sem_lista_de_validos_nao_confere_id(repo):
    """`plano-json` roda depois da validação e não tem o contrato em mãos —
    nesse caso só as checagens estruturais valem."""
    _grava({"demandas": [_demanda(entregavelId="qualquer")]})
    assert len(planejamento.ler_plano("acme")["demandas"]) == 1


def test_teto_de_demandas(repo):
    _grava({"demandas": [_demanda() for _ in range(planejamento.MAX_DEMANDAS + 1)]})
    with pytest.raises(planejamento.PlanejamentoError, match="passa do teto"):
        planejamento.ler_plano("acme", {"e1"})
