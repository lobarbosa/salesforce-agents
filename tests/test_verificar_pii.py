"""scripts/verificar_pii.py — a rede técnica que falta no guardrail #2.

demanda.md e os artefatos das 7 etapas são texto livre. Sem isto, só a
disciplina de quem escreveu impede CPF/e-mail/telefone de virarem corpus do
RAG (CLAUDE.md, achado do council de 2026-10-01).
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from verificar_pii import main, mascarar, verificar  # noqa: E402


def escreve(tmp_path: Path, nome: str, conteudo: str) -> str:
    caminho = tmp_path / nome
    caminho.write_text(conteudo, encoding="utf-8")
    return str(caminho)


def test_arquivo_limpo_nao_acha_nada(tmp_path: Path):
    caminho = escreve(tmp_path, "demanda.md", "Pedido do consultor: ajustar o layout da Opportunity.")
    assert verificar(caminho) == []


def test_cpf_formatado_e_detectado(tmp_path: Path):
    caminho = escreve(tmp_path, "01-analise.md", "Cliente informou CPF 123.456.789-00 no chamado.")
    achados = verificar(caminho)
    assert len(achados) == 1
    assert "CPF" in achados[0]


def test_email_e_detectado(tmp_path: Path):
    caminho = escreve(tmp_path, "demanda.md", "Contato: maria.silva@clienteacme.com.br")
    achados = verificar(caminho)
    assert any("e-mail" in a for a in achados)


def test_telefone_formatado_e_detectado(tmp_path: Path):
    caminho = escreve(tmp_path, "demanda.md", "Ligar pro usuário em (11) 91234-5678 antes de aprovar.")
    achados = verificar(caminho)
    assert any("telefone" in a for a in achados)


def test_cpf_sem_mascara_nao_e_pego_de_proposito(tmp_path: Path):
    # 11 dígitos corridos tem falso positivo demais (telefone sem formatação,
    # id interno) pra valer a pena travar o PR por isso — o scanner pega o
    # padrão formatado óbvio, não faz parsing semântico.
    caminho = escreve(tmp_path, "demanda.md", "ref interna 12345678900")
    assert verificar(caminho) == []


def test_mascarar_nunca_devolve_o_valor_original():
    assert mascarar("123.456.789-00") not in "123.456.789-00"
    assert "456.789" not in mascarar("123.456.789-00")


def test_main_devolve_1_quando_acha_pii(tmp_path: Path, capsys):
    caminho = escreve(tmp_path, "demanda.md", "e-mail: joao@example.com")
    assert main([caminho]) == 1
    saida = capsys.readouterr().out
    assert "joao@example.com" not in saida  # nunca imprime o valor real


def test_main_devolve_0_para_arquivo_limpo(tmp_path: Path):
    caminho = escreve(tmp_path, "demanda.md", "Nada de sensível aqui.")
    assert main([caminho]) == 0


def test_main_ignora_arquivo_que_nao_e_md(tmp_path: Path):
    caminho = escreve(tmp_path, "notas.txt", "CPF 123.456.789-00")
    assert main([caminho]) == 0
