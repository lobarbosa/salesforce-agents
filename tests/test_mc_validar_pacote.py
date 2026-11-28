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
    "campos": [
        {"nome": "ContactId", "tipo": "Text", "tamanho": 18, "chave": True},
        {"nome": "Email", "tipo": "EmailAddress"},
    ],
}
SQL_OK = "-- destino: Acme_MKT_Reativacao\n-- acao: Overwrite\nSELECT c.ContactId, c.Email FROM [Acme_Contatos] c WHERE c.OptInEmail = 1\n"
EMAIL_OK = (
    "<!-- assunto: Sentimos sua falta -->\n<!-- preheader: 10% até domingo -->\n"
    '<table><tr><td><img src="x.png" alt="Logo" width="120"></td></tr>'
    '<tr><td><a href="%%unsub_center_url%%">Descadastrar</a></td></tr></table>'
)


def _pacote(tmp_path, de=DE_OK, sql=SQL_OK, email=EMAIL_OK, readme=True):
    mc = tmp_path / "mc"
    for d in ("data-extensions", "sql", "conteudo"):
        (mc / d).mkdir(parents=True)
    (mc / "data-extensions" / "Reativacao.json").write_text(json.dumps(de), encoding="utf-8")
    (mc / "sql" / "Reativacao.sql").write_text(sql, encoding="utf-8")
    (mc / "conteudo" / "Reativacao.html").write_text(email, encoding="utf-8")
    if readme:
        (mc / "README.md").write_text("# Implantação\n", encoding="utf-8")
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
