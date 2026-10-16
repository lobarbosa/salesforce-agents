"""Anexos liberados chegam ao prompt — e só eles, só quando existem."""

from __future__ import annotations

import subprocess

from salesforce_agents import anexos


def test_sem_pasta_nao_acrescenta_nada(tmp_path):
    assert anexos.nota_para_o_prompt("acme", "ACME-1", tmp_path) == ""


def test_lista_cada_anexo_com_o_jeito_de_ler(tmp_path):
    pasta = tmp_path / "acme" / "demandas" / "ACME-1" / "anexos"
    pasta.mkdir(parents=True)
    (pasta / "erro.png").write_bytes(b"\x89PNG")
    (pasta / "spec.pdf").write_bytes(b"%PDF")
    (pasta / "dados.csv").write_text("a,b")

    nota = anexos.nota_para_o_prompt("acme", "ACME-1", tmp_path)

    assert "demandas/ACME-1/anexos/erro.png (imagem — abra com Read)" in nota
    assert "demandas/ACME-1/anexos/spec.pdf (documento — leia com spec_read)" in nota
    assert "dados.csv" in nota
    assert "guardrail #2" in nota


def test_pasta_de_anexos_nunca_entra_no_git():
    """O anexo vive o tempo do job: se virasse commit, ia pro PR, pra main e pro RAG."""
    r = subprocess.run(
        ["git", "check-ignore", "-q", "clients/acme/demandas/ACME-1/anexos/erro.png"],
        capture_output=True,
    )
    assert r.returncode == 0
