import importlib.util
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def _mod(nome, arquivo):
    spec = importlib.util.spec_from_file_location(nome, RAIZ / "scripts" / arquivo)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


dns = _mod("mcdns", "mc_dns_remetente.py")
val = _mod("mcval2", "mc_validar_pacote.py")


def test_registro_txt_partido_se_junta_sem_espaco():
    assert dns.juntar('"v=spf1 include:a.example.com " "include:b.example.com -all"') == "v=spf1 include:a.example.com include:b.example.com -all"


def test_spf():
    assert dns.avaliar_spf([])[1:] == ("ausente", "crítica")
    assert dns.avaliar_spf(["v=spf1 -all", "v=spf1 ~all"])[2] == "crítica"
    assert dns.avaliar_spf(["v=spf1 include:x.example.com +all"])[1].startswith("termina")
    muitos = "v=spf1 " + " ".join(f"include:s{i}.example.com" for i in range(11)) + " -all"
    assert "11 consultas" in dns.avaliar_spf([muitos])[1]
    assert dns.avaliar_spf(["v=spf1 include:x.example.com ~all"])[1] == "atende"


def test_dmarc_e_dkim():
    assert dns.avaliar_dmarc([])[2] == "alta"
    assert dns.avaliar_dmarc(["v=DMARC1; p=none"])[2] == "média"
    assert "atende" in dns.avaliar_dmarc(["v=DMARC1; p=reject; rua=mailto:dmarc@example.com"])[1]
    assert dns.avaliar_dkim([])[2] == "crítica"
    assert dns.avaliar_dkim(["v=DKIM1; k=rsa; p="])[1].startswith("chave revogada")
    assert dns.avaliar_dkim(["v=DKIM1; k=rsa; p=MIGfMA0"])[1] == "atende"


def test_dominio_invalido_e_recusado(capsys):
    assert dns.main(["nao é domínio"]) == 2
    assert dns.main(["cliente.com.br", "--seletor-dkim", "x;rm"]) == 2


ASSESSMENT_OK = """# Marketing Cloud – Acme

## Achados

| # | Área | Achado | Severidade | Evidência | Correção | Dono |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Entregabilidade | DMARC ausente | alta | workflow mc-dns-remetente | publicar _dmarc com p=none | TI do cliente |

## Não verificado

| Item | O que falta |
| --- | --- |
"""


def test_assessment_correto_passa(tmp_path):
    arq = tmp_path / "mc-assessment.md"
    arq.write_text(ASSESSMENT_OK, encoding="utf-8")
    assert val.validar_assessment(arq) == []


def test_assessment_com_severidade_invalida_sem_dono_e_sem_nao_verificado(tmp_path):
    arq = tmp_path / "mc-assessment.md"
    ruim = ASSESSMENT_OK.replace("| alta |", "| urgente |").replace("| TI do cliente |", "| — |").split("## Não verificado")[0]
    arq.write_text(ruim + "contato: fulano@cliente.com.br\n", encoding="utf-8")
    erros = val.validar_assessment(arq)
    assert any("urgente" in e for e in erros)
    assert any("sem dono" in e for e in erros)
    assert any("Não verificado" in e for e in erros)
    assert any("cliente.com.br" in e for e in erros)
