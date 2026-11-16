"""Evidências de teste: capturas guardadas por rodada e payload do sync."""

from __future__ import annotations

import base64

from salesforce_agents import evidencias


def test_salvar_captura_numera_e_registra_legenda(tmp_path):
    a = evidencias.salvar_captura(tmp_path, b"\xff\xd8um", "CA-03: rascunho gerado (conta de teste)")
    b = evidencias.salvar_captura(tmp_path, b"\xff\xd8dois", "Tela de erro")
    assert a.name == "01-ca-03-rascunho-gerado-conta-de-teste.jpg"
    assert b.name == "02-tela-de-erro.jpg"
    assert [i["legenda"] for i in evidencias.imagens(tmp_path)] == ["CA-03: rascunho gerado (conta de teste)", "Tela de erro"]


def test_payload_traz_roteiro_capturas_e_hash_que_muda(tmp_path):
    (tmp_path / "05-testes.md").write_text("**Veredito:** aprovado\n", encoding="utf-8")
    evidencias.salvar_captura(tmp_path, b"\xff\xd8um", "Tela A")
    p1 = evidencias.payload(tmp_path)
    assert p1["evidencias_teste"].startswith("**Veredito:** aprovado")
    assert base64.b64decode(p1["evidencias_imagens"][0]["jpeg_base64"]) == b"\xff\xd8um"
    assert len(p1["evidencias_hash"]) == 64
    assert evidencias.payload(tmp_path)["evidencias_hash"] == p1["evidencias_hash"]
    evidencias.salvar_captura(tmp_path, b"\xff\xd8dois", "Tela B")
    assert evidencias.payload(tmp_path)["evidencias_hash"] != p1["evidencias_hash"]


def test_sem_roteiro_vigente_usa_a_ultima_rodada_arquivada(tmp_path):
    (tmp_path / "05-testes-rodada-2.md").write_text("rodada 2", encoding="utf-8")
    (tmp_path / "05-testes-rodada-10.md").write_text("rodada 10", encoding="utf-8")
    assert evidencias.conteudo(tmp_path) == "rodada 10"


def test_sem_teste_nenhum_o_payload_vai_vazio(tmp_path):
    evidencias.salvar_captura(tmp_path, b"\xff\xd8um", "Tela órfã")
    assert evidencias.payload(tmp_path) == {"evidencias_teste": "", "evidencias_imagens": [], "evidencias_hash": ""}


def test_descartar_esvazia_a_pasta(tmp_path):
    evidencias.salvar_captura(tmp_path, b"\xff\xd8um", "Tela A")
    evidencias.descartar(tmp_path)
    assert not evidencias.pasta(tmp_path).exists()
    evidencias.descartar(tmp_path)  # sem pasta, não falha


def test_teto_de_bytes_corta_as_capturas(tmp_path, monkeypatch):
    monkeypatch.setattr(evidencias, "MAX_BYTES_IMAGENS", 10)
    evidencias.salvar_captura(tmp_path, b"123456", "A")
    evidencias.salvar_captura(tmp_path, b"123456", "B")
    assert [i["nome"] for i in evidencias.imagens(tmp_path)] == ["01-a.jpg"]
