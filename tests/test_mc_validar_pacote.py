import importlib.util
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("mcval", RAIZ / "scripts" / "mc_validar_pacote.py")
mcval = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mcval)

DE_OK = {
    "nome": "Acme_MKT_Reativacao",
    "enviavel": True,
    "campo_de_envio": "ContactId",
    "retencao_dias": 30,
    "campos": [
        {"nome": "ContactId", "tipo": "Text", "tamanho": 18, "chave": True},
        {"nome": "Email", "tipo": "EmailAddress"},
    ],
}
SQL_OK = "-- destino: Acme_MKT_Reativacao\n-- acao: Overwrite\nSELECT c.ContactId, c.Email FROM [Acme_Contatos] c WHERE c.OptInEmail = 1\n"
EMAIL_OK = (
    "<!-- assunto: Sentimos sua falta -->\n<!-- preheader: 10% até domingo -->\n"
    '<table><tr><td><img src="x.png" alt="Logo" width="120"></td></tr>'
    '<tr><td><a href="%%unsub_center_url%%">Descadastrar</a> %%Member_Busname%% %%Member_Addr%%</td></tr></table>'
)
README_OK = "# Implantação\n\n## Ordem de implantação\n1. DE\n\n## Como testar\nPré-visualização\n\n## Como desfazer\nApagar a DE\n"


def _pacote(tmp_path, de=DE_OK, sql=SQL_OK, email=EMAIL_OK, readme=True):
    mc = tmp_path / "mc"
    for d in ("data-extensions", "sql", "conteudo"):
        (mc / d).mkdir(parents=True)
    (mc / "data-extensions" / "Reativacao.json").write_text(json.dumps(de), encoding="utf-8")
    (mc / "sql" / "Reativacao.sql").write_text(sql, encoding="utf-8")
    (mc / "conteudo" / "Reativacao.html").write_text(email, encoding="utf-8")
    if readme:
        (mc / "README.md").write_text(README_OK, encoding="utf-8")
    return mc


def test_pacote_correto_passa(tmp_path):
    assert mcval.validar(_pacote(tmp_path)) == []


def test_sql_que_altera_dado_ou_usa_cte_e_recusado(tmp_path):
    erros = mcval.validar(_pacote(tmp_path, sql="-- destino: X\n-- acao: Overwrite\nDELETE FROM [X]\n"))
    assert any("DELETE" in e for e in erros)
    erros = mcval.validar(_pacote(tmp_path / "b", sql="-- destino: X\n-- acao: Append\nWITH t AS (SELECT 1 AS a) SELECT a FROM t\n"))
    assert any("CTE" in e for e in erros)


def test_palavra_proibida_dentro_de_texto_ou_comentario_nao_conta(tmp_path):
    sql = "-- destino: Acme_MKT_Reativacao\n-- acao: Overwrite\n-- não usar DELETE aqui\nSELECT 'UPDATE' AS Origem FROM [Acme_Contatos]\n"
    assert mcval.validar(_pacote(tmp_path, sql=sql)) == []


def test_update_exige_chave_no_destino(tmp_path):
    de = {**DE_OK, "campos": [{"nome": "ContactId", "tipo": "Text", "tamanho": 18}, {"nome": "Email", "tipo": "EmailAddress"}]}
    sql = SQL_OK.replace("Overwrite", "Update")
    assert any("chave primária" in e for e in mcval.validar(_pacote(tmp_path, de=de, sql=sql)))


def test_email_sem_descadastro_sem_alt_e_com_email_real(tmp_path):
    email = "<!-- assunto: x -->\n<!-- preheader: y -->\n<img src='a.png'> fale com joao@empresa.com.br"
    erros = mcval.validar(_pacote(tmp_path, email=email))
    assert any("descadastro" in e for e in erros)
    assert any("sem alt" in e for e in erros)
    assert any("empresa.com.br" in e for e in erros)


def test_de_enviavel_sem_campo_de_envio_e_text_sem_tamanho(tmp_path):
    de = {"nome": "Acme_X", "enviavel": True, "campo_de_envio": "Nada", "campos": [{"nome": "Email", "tipo": "Text"}]}
    erros = mcval.validar(_pacote(tmp_path, de=de))
    assert any("campo_de_envio" in e for e in erros)
    assert any("sem tamanho" in e for e in erros)
    assert any("EmailAddress" in e for e in erros)


def test_falta_readme(tmp_path):
    assert any("README" in e for e in mcval.validar(_pacote(tmp_path, readme=False)))


AUTOMACAO_OK = (
    "# Acme_MKT_Reativacao\n\n**Estado:** inativa\n**Gatilho:** agenda diária 06:00\n"
    "**Notificação de erro:** time de marketing do cliente\n\n"
    "| Passo | Atividade | Peça | Esperado |\n| --- | --- | --- | --- |\n"
    "| 1 | Consulta SQL | `sql/Reativacao.sql` | 2 a 5 mil |\n"
    "| 2 | Verificação | Acme_MKT_Reativacao | parar se 0 |\n"
    "| 3 | Envio de e-mail | `conteudo/Reativacao.html` | — |\n"
)
SEGMENTO_OK = (
    "# Reativação\n\n**Critério:** sem compra há 180 dias\n**Consentimento:** OptInEmail = 1\n"
    "**Exclusões:** atendimento aberto, rejeição permanente\n**Tamanho esperado:** não medido\n"
)


def _com_extras(mc, automacao=AUTOMACAO_OK, segmento=SEGMENTO_OK):
    (mc / "automacoes").mkdir(exist_ok=True)
    (mc / "segmentos").mkdir(exist_ok=True)
    (mc / "automacoes" / "Reativacao.md").write_text(automacao, encoding="utf-8")
    (mc / "segmentos" / "Reativacao.md").write_text(segmento, encoding="utf-8")
    return mc


def test_automacao_e_segmento_corretos_passam(tmp_path):
    assert mcval.validar(_com_extras(_pacote(tmp_path))) == []


def test_automacao_ativa_sem_verificacao_e_com_sql_ausente(tmp_path):
    ruim = (
        "**Estado:** ativa\n**Gatilho:** agenda\n\n| Passo | Atividade | Peça |\n| --- | --- | --- |\n"
        "| 1 | Consulta SQL | `sql/NaoExiste.sql` |\n| 2 | Envio de e-mail | x |\n"
    )
    erros = mcval.validar(_com_extras(_pacote(tmp_path), automacao=ruim))
    assert any("inativa" in e for e in erros)
    assert any("Notificação de erro" in e for e in erros)
    assert any("NaoExiste.sql" in e for e in erros)
    assert any("Verificação antes do envio" in e for e in erros)


def test_segmento_sem_consentimento_nem_exclusoes(tmp_path):
    erros = mcval.validar(_com_extras(_pacote(tmp_path), segmento="**Critério:** todos\n**Tamanho esperado:** 10 mil\n"))
    assert any("Consentimento" in e for e in erros)
    assert any("Exclusões" in e for e in erros)


JORNADA_OK = (
    "# Reativação\n\n**Estado:** inativa\n**Fonte de entrada:** DE Acme_MKT_Reativacao, diária\n"
    "**Reentrada:** só depois de sair\n**Classificação de envio:** comercial\n**Meta:** comprou em 30 dias\n"
    "**Critério de saída:** descadastrou ou comprou\n\n```mermaid\nflowchart LR\n  A[Entrada] --> B[E-mail 1]\n```\n"
    "| Envio | E-mail |\n| --- | --- |\n| 1 | `conteudo/Reativacao.html` |\n"
)


def test_jornada_correta_passa_e_incompleta_e_recusada(tmp_path):
    mc = _pacote(tmp_path)
    (mc / "jornadas").mkdir()
    (mc / "jornadas" / "Reativacao.md").write_text(JORNADA_OK, encoding="utf-8")
    assert mcval.validar(mc) == []
    (mc / "jornadas" / "Reativacao.md").write_text("**Estado:** ativa\n`conteudo/Outro.html`\n", encoding="utf-8")
    erros = mcval.validar(mc)
    assert any("inativa" in e for e in erros)
    assert any("Reentrada" in e for e in erros)
    assert any("mermaid" in e for e in erros)
    assert any("Outro.html" in e for e in erros)


def test_ampscript_exige_casos_de_teste_e_blocos_fechados(tmp_path):
    email = EMAIL_OK + "%%[ SET @n = AttributeValue(\"PrimeiroNome\") "
    erros = mcval.validar(_pacote(tmp_path, email=email))
    assert any("sem fechar" in e for e in erros)
    assert any("casos.md" in e for e in erros)
    mc = _pacote(tmp_path / "b", email=EMAIL_OK + "%%[ SET @n = AttributeValue(\"PrimeiroNome\") ]%%")
    (mc / "conteudo" / "Reativacao.casos.md").write_text(
        "| Entrada | Saída |\n| --- | --- |\n| nome Ana | Olá, Ana |\n| sem nome | Olá, cliente |\n| sem oferta | pula |\n", encoding="utf-8"
    )
    assert mcval.validar(mc) == []


def test_de_enviavel_por_email_sem_retencao_e_select_estrela(tmp_path):
    de = {**DE_OK, "campo_de_envio": "Email"}
    de.pop("retencao_dias")
    sql = "-- destino: Acme_MKT_Reativacao\n-- acao: Overwrite\nSELECT * FROM [Acme_Contatos]\n"
    erros = mcval.validar(_pacote(tmp_path, de=de, sql=sql))
    assert any("Subscriber Key" in e for e in erros)
    assert any("retenção" in e for e in erros)
    assert any("SELECT *" in e for e in erros)


def test_readme_sem_secoes_e_email_sem_endereco(tmp_path):
    mc = _pacote(tmp_path, email=EMAIL_OK.replace("%%Member_Addr%%", ""))
    (mc / "README.md").write_text("# Implantação\n", encoding="utf-8")
    erros = mcval.validar(mc)
    assert any("Como desfazer" in e for e in erros)
    assert any("Member_Addr" in e for e in erros)


def test_raise_error_sem_true_para_o_envio_inteiro(tmp_path):
    casos = "| Entrada | Saída |\n| --- | --- |\n| completo | ok |\n| vazio | reserva |\n| sem oferta | pulado |\n"
    for n, chamada in enumerate(('RaiseError("sem oferta")', 'RaiseError("sem oferta", false)', "raiseerror('a, b', 0)")):
        email = EMAIL_OK + f"%%[ IF Empty(@oferta) THEN {chamada} ENDIF ]%%"
        mc = _pacote(tmp_path / str(n), email=email)
        (mc / "conteudo" / "Reativacao.casos.md").write_text(casos, encoding="utf-8")
        assert any("RaiseError" in e for e in mcval.validar(mc)), chamada


def test_raise_error_que_pula_so_o_destinatario_passa(tmp_path):
    casos = "| Entrada | Saída |\n| --- | --- |\n| completo | ok |\n| vazio | reserva |\n| sem oferta | pulado |\n"
    email = EMAIL_OK + '%%[ IF Empty(@oferta) THEN RaiseError("sem oferta, pulado", true, "1", 1, true) ENDIF ]%%'
    mc = _pacote(tmp_path, email=email)
    (mc / "conteudo" / "Reativacao.casos.md").write_text(casos, encoding="utf-8")
    assert mcval.validar(mc) == []
