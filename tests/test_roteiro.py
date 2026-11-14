"""O roteiro do cliente só é cobrado quando o QA aprovou, e some quando reprova."""

from salesforce_agents import roteiro

APROVADO = "**Veredito:** aprovado\n**Org de teste:** `sbx-acme-qa`\n\n| Caso | Status |"
REPROVADO = "**Veredito:** reprovado\n**Org de teste:** `sbx-acme-qa`\n\n### FALHA 1 (crítica) — x"


def test_qa_aprovado_sem_roteiro_cobra_o_arquivo(tmp_path):
    (tmp_path / "05-testes.md").write_text(APROVADO, encoding="utf-8")

    assert roteiro.faltando(tmp_path, "sbx-acme-qa") == [str(tmp_path / roteiro.NOME)]


def test_qa_aprovado_com_roteiro_nao_cobra_nada(tmp_path):
    (tmp_path / "05-testes.md").write_text(APROVADO, encoding="utf-8")
    (tmp_path / roteiro.NOME).write_text("# Roteiro", encoding="utf-8")

    assert roteiro.faltando(tmp_path, "sbx-acme-qa") == []


def test_qa_reprovado_ou_sem_testes_nao_pede_roteiro(tmp_path):
    assert roteiro.faltando(tmp_path, "sbx-acme-qa") == []
    (tmp_path / "05-testes.md").write_text(REPROVADO, encoding="utf-8")

    assert roteiro.faltando(tmp_path, "sbx-acme-qa") == []


def test_aprovado_em_org_que_nao_e_a_de_qa_nao_pede_roteiro(tmp_path):
    (tmp_path / "05-testes.md").write_text(APROVADO, encoding="utf-8")

    assert roteiro.faltando(tmp_path, "sbx-outro-qa") == []


def test_conteudo_vem_vazio_sem_arquivo_e_cortado_no_limite(tmp_path):
    assert roteiro.conteudo(tmp_path) == ""
    (tmp_path / roteiro.NOME).write_text("a" * (roteiro.LIMITE_CONTEUDO + 10), encoding="utf-8")

    assert len(roteiro.conteudo(tmp_path)) == roteiro.LIMITE_CONTEUDO


def test_descartar_apaga_e_nao_reclama_se_nao_existe(tmp_path):
    roteiro.descartar(tmp_path)
    (tmp_path / roteiro.NOME).write_text("# Roteiro", encoding="utf-8")

    roteiro.descartar(tmp_path)

    assert not (tmp_path / roteiro.NOME).exists()
