"""A chave privada nunca deve passar por stdout nem por chat de agente (achado
Centric, 2026-10-03) — estes testes cobrem a geração em disco e as recusas que
protegem o par já cadastrado numa Connected App."""

import pytest

from salesforce_agents import conexao


def test_gera_par_de_chaves_em_disco(tmp_path):
    (tmp_path / "acxya").mkdir()

    cred = conexao.gerar_par_de_chaves("acxya", "dev", base_dir=tmp_path)

    assert cred.alias == "sbx-acxya-dev"
    assert cred.github_environment == "acxya-dev"
    assert cred.key_path.is_file()
    assert cred.cert_path.is_file()
    assert "PRIVATE KEY" in cred.key_path.read_text()
    assert "BEGIN CERTIFICATE" in cred.cert_path.read_text()


def test_chave_privada_fica_so_legivel_pelo_dono(tmp_path):
    (tmp_path / "acxya").mkdir()

    cred = conexao.gerar_par_de_chaves("acxya", "dev", base_dir=tmp_path)

    assert (cred.key_path.stat().st_mode & 0o777) == 0o600


def test_ambiente_invalido_e_recusado(tmp_path):
    (tmp_path / "acxya").mkdir()

    with pytest.raises(ValueError):
        conexao.gerar_par_de_chaves("acxya", "prod", base_dir=tmp_path)


def test_recusa_sobrescrever_sem_forcar(tmp_path):
    (tmp_path / "acxya").mkdir()
    conexao.gerar_par_de_chaves("acxya", "qa", base_dir=tmp_path)

    with pytest.raises(conexao.CredencialJaExisteError):
        conexao.gerar_par_de_chaves("acxya", "qa", base_dir=tmp_path)


def test_forcar_permite_regenerar(tmp_path):
    (tmp_path / "acxya").mkdir()
    primeira = conexao.gerar_par_de_chaves("acxya", "qa", base_dir=tmp_path)
    chave_original = primeira.key_path.read_text()

    segunda = conexao.gerar_par_de_chaves("acxya", "qa", base_dir=tmp_path, forcar=True)

    assert segunda.key_path.read_text() != chave_original


def test_openssl_ausente_vira_erro_dedicado(tmp_path, monkeypatch):
    (tmp_path / "acxya").mkdir()
    monkeypatch.setenv("PATH", "")

    with pytest.raises(conexao.OpensslAusenteError):
        conexao.gerar_par_de_chaves("acxya", "dev", base_dir=tmp_path)
