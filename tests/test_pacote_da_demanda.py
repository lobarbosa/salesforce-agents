"""O pacote que a esteira implanta na QA: só o que a demanda mudou, com os testes dela."""

import importlib.util
from pathlib import Path

import pytest

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pacote_da_demanda.py"
_spec = importlib.util.spec_from_file_location("pacote_da_demanda", _SCRIPT)
pacote = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pacote)

BASE = "force-app/main/default"


def _criar(pasta: Path, caminho: str, texto: str = "x") -> str:
    arquivo = pasta / caminho
    arquivo.parent.mkdir(parents=True, exist_ok=True)
    arquivo.write_text(texto, encoding="utf-8")
    return caminho


def test_so_entra_o_force_app_do_proprio_cliente():
    caminhos = [
        "clients/eplast/force-app/main/default/flows/F.flow-meta.xml",
        "clients/eplast/demandas/EPLAST-47/04-plano-build.md",
        "clients/outro/force-app/main/default/flows/G.flow-meta.xml",
        "src/salesforce_agents/fluxo.py",
    ]
    assert pacote.alterados_do_cliente(caminhos, "eplast") == [f"{BASE}/flows/F.flow-meta.xml"]


def test_sem_apex_implanta_sem_rodar_teste(tmp_path):
    flow = _criar(tmp_path, f"{BASE}/flows/F.flow-meta.xml")
    campo = _criar(tmp_path, f"{BASE}/objects/Account/fields/R__c.field-meta.xml")

    args, removidos = pacote.argumentos([flow, campo], tmp_path)

    assert args == ["--source-dir", flow, "--source-dir", campo, "--test-level", "NoTestRun"]
    assert removidos == []


def test_com_apex_roda_so_os_testes_da_demanda(tmp_path):
    classe = _criar(tmp_path, f"{BASE}/classes/Foo.cls", "public class Foo {}")
    teste = _criar(tmp_path, f"{BASE}/classes/FooTest.cls", "@IsTest class FooTest {}")
    meta = _criar(tmp_path, f"{BASE}/classes/Foo.cls-meta.xml")

    args, _ = pacote.argumentos([classe, teste, meta], tmp_path)

    assert args[-4:] == ["--test-level", "RunSpecifiedTests", "--tests", "FooTest"]


def test_classe_sem_teste_dedicado_reprova(tmp_path):
    classe = _criar(tmp_path, f"{BASE}/classes/Bar.cls", "public class Bar {}")

    with pytest.raises(pacote.ApexSemTeste):
        pacote.argumentos([classe], tmp_path)


def test_arquivo_removido_fica_de_fora_e_e_avisado(tmp_path):
    flow = _criar(tmp_path, f"{BASE}/flows/F.flow-meta.xml")
    sumiu = f"{BASE}/flows/Antigo.flow-meta.xml"

    args, removidos = pacote.argumentos([flow, sumiu], tmp_path)

    assert sumiu not in args
    assert removidos == [sumiu]


def test_demanda_sem_metadata_nao_gera_pacote(tmp_path):
    assert pacote.argumentos([], tmp_path) == ([], [])
