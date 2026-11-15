"""Verificação do build: o que a esteira lê do arquivo que o agente grava."""

from salesforce_agents import revisao, verificacao

DEV = "sbx-acme-dev"


def _texto(estado, org=DEV):
    return f"**Verificação:** {estado}\n**Org de teste:** `{org}`\n\n| Caso | Status |"


def test_aprovada_na_sandbox_de_dev_passa():
    assert verificacao.ler(_texto("aprovada"), DEV) == verificacao.Resultado("aprovada", "")


def test_reprovada_e_inconclusiva_sao_lidas_como_estao():
    assert verificacao.ler(_texto("reprovada"), DEV).estado == "reprovada"
    assert verificacao.ler(_texto("inconclusiva"), DEV).estado == "inconclusiva"


def test_sem_linha_de_resultado_ou_em_outra_org_conta_como_reprovada():
    assert verificacao.ler("# Verificação\n\nTudo certo.", DEV).estado == "reprovada"
    assert verificacao.ler(_texto("aprovada", "sbx-acme-qa"), DEV).estado == "reprovada"
    assert verificacao.ler("**Verificação:** aprovada", DEV).estado == "reprovada"


def test_so_cobra_verificacao_de_build_concluido(tmp_path):
    assert verificacao.faltando(tmp_path) == []
    plano = tmp_path / "04-plano-build.md"
    plano.write_text("**Resultado do build:** bloqueado", encoding="utf-8")
    assert verificacao.faltando(tmp_path) == []

    plano.write_text("**Resultado do build:** concluído", encoding="utf-8")
    assert verificacao.faltando(tmp_path) == [str(tmp_path / verificacao.NOME)]

    (tmp_path / verificacao.NOME).write_text(_texto("aprovada"), encoding="utf-8")
    assert verificacao.faltando(tmp_path) == []


def test_reprovada_e_arquivada_com_o_numero_da_rodada(tmp_path):
    (tmp_path / verificacao.NOME).write_text(_texto("reprovada"), encoding="utf-8")
    verificacao.arquivar_reprovada(tmp_path)
    (tmp_path / verificacao.NOME).write_text(_texto("reprovada"), encoding="utf-8")
    verificacao.arquivar_reprovada(tmp_path)

    assert sorted(p.name for p in tmp_path.iterdir()) == [
        "04-verificacao-rodada-1.md",
        "04-verificacao-rodada-2.md",
    ]
    assert verificacao.rodadas_reprovadas(tmp_path) == 2


def test_quem_revisa_o_build_ve_a_evidencia_junto_do_plano(tmp_path):
    assert verificacao.anexo_para_o_gate(tmp_path) == ""
    (tmp_path / verificacao.NOME).write_text(_texto("aprovada"), encoding="utf-8")

    assert "**Verificação:** aprovada" in verificacao.anexo_para_o_gate(tmp_path)
    assert revisao.verificacao is verificacao


def test_org_sem_crase_ou_com_comentario_e_a_mesma_declaracao():
    """Achado EPLAST-28: `**Org de teste:** sbx-eplast-dev` sem crase virava reprovada."""
    assert verificacao.ler("**Verificação:** inconclusiva\n**Org de teste:** sbx-acme-dev", DEV).estado == "inconclusiva"
    assert verificacao.ler("**Verificação:** aprovada\n**Org de teste:** `sbx-acme-dev` (Org ID 00D...)", DEV).estado == "aprovada"
    assert verificacao.ler("**Verificação:** aprovada\n**Org de teste:** sbx-acme-qa", DEV).estado == "reprovada"


def test_veredito_do_qa_aceita_org_sem_crase():
    from salesforce_agents import veredito

    assert veredito.ler("**Veredito:** aprovado\n**Org de teste:** sbx-acme-qa", "sbx-acme-qa").aprovado


def test_conferir_depois_de_sai_em_iso_utc():
    from salesforce_agents import veredito

    t = "**Veredito:** aguardando execução\n**Org de teste:** `sbx-acme-qa`\n**Conferir depois de:** 2026-11-15T18:47Z\n"
    assert veredito.conferir_depois_de(t) == "2026-11-15T18:47Z"
    assert veredito.conferir_depois_de("**Conferir depois de:** `2026-11-16 10:05:00`") == "2026-11-16T10:05:00Z"
    assert veredito.conferir_depois_de("**Veredito:** aprovado") == ""
