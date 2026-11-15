"""O roteiro do cliente sai em toda rodada de QA e é reescrito a cada uma."""

import pytest

from salesforce_agents import roteiro

APROVADO = "**Veredito:** aprovado\n**Org de teste:** `sbx-acme-qa`\n\n| Caso | Status |"
REPROVADO = "**Veredito:** reprovado\n**Org de teste:** `sbx-acme-qa`\n\n### FALHA 1 (crítica) — x"


@pytest.mark.parametrize("testes", [APROVADO, REPROVADO])
def test_toda_rodada_de_qa_sem_roteiro_cobra_o_arquivo(tmp_path, testes):
    (tmp_path / "05-testes.md").write_text(testes, encoding="utf-8")

    assert roteiro.faltando(tmp_path) == [str(tmp_path / roteiro.NOME)]


def test_com_roteiro_ou_sem_testes_nao_cobra_nada(tmp_path):
    assert roteiro.faltando(tmp_path) == []
    (tmp_path / "05-testes.md").write_text(REPROVADO, encoding="utf-8")
    (tmp_path / roteiro.NOME).write_text("# Roteiro", encoding="utf-8")

    assert roteiro.faltando(tmp_path) == []


def test_conteudo_vem_vazio_sem_arquivo_e_cortado_no_limite(tmp_path):
    assert roteiro.conteudo(tmp_path) == ""
    (tmp_path / roteiro.NOME).write_text("a" * (roteiro.LIMITE_CONTEUDO + 10), encoding="utf-8")

    assert len(roteiro.conteudo(tmp_path)) == roteiro.LIMITE_CONTEUDO


def test_descartar_apaga_e_nao_reclama_se_nao_existe(tmp_path):
    roteiro.descartar(tmp_path)
    (tmp_path / roteiro.NOME).write_text("# Roteiro", encoding="utf-8")

    roteiro.descartar(tmp_path)

    assert not (tmp_path / roteiro.NOME).exists()
