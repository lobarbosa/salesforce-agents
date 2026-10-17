"""Comentários do card chegam ao agente sem dado pessoal e sem virar commit."""

from __future__ import annotations

import subprocess

from salesforce_agents import comentarios


def test_redige_email_cpf_e_telefone():
    texto, n = comentarios.redigir("fale com ana.souza@cliente.com.br, CPF 123.456.789-00, tel (11) 91234-5678")
    assert "@" not in texto and "123.456" not in texto and "91234" not in texto
    assert "[e-mail omitido]" in texto and "[CPF omitido]" in texto and "[telefone omitido]" in texto
    assert n == 3


def test_renderiza_lado_e_ordem_sem_autor():
    md, omitidos = comentarios.renderizar([
        {"papel": "cliente", "em": "2026-10-16T10:00:00Z", "texto": "o erro é 'FIELD_CUSTOM_VALIDATION'"},
        {"papel": "consultor", "em": "2026-10-16T11:00:00Z", "texto": "ok, conferindo"},
    ])
    assert md.index("## Cliente") < md.index("## Equipe")
    assert "FIELD_CUSTOM_VALIDATION" in md
    assert omitidos == 0


def test_gravar_e_nota_no_prompt(tmp_path):
    pasta = tmp_path / "acme" / "demandas" / "ACME-1"
    pasta.mkdir(parents=True)
    assert comentarios.nota_para_o_prompt("acme", "ACME-1", tmp_path) == ""
    destino, _ = comentarios.gravar(pasta, [{"papel": "cliente", "em": "x", "texto": "resposta"}])
    assert destino and destino.exists()
    assert "comentarios-do-card.md" in comentarios.nota_para_o_prompt("acme", "ACME-1", tmp_path)


def test_sem_comentario_nao_grava(tmp_path):
    assert comentarios.gravar(tmp_path, []) == (None, 0)


def test_arquivo_nunca_entra_no_git():
    r = subprocess.run(
        ["git", "check-ignore", "-q", "clients/acme/demandas/ACME-1/comentarios-do-card.md"], capture_output=True
    )
    assert r.returncode == 0
