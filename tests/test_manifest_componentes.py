"""Promoção QA → DEV de componentes nomeados (EPLAST-49)."""

import importlib.util
from pathlib import Path

import pytest

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "manifest_componentes.py"
_spec = importlib.util.spec_from_file_location("manifest_componentes", _SCRIPT)
mc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mc)


def test_agrupa_por_tipo_e_ordena(tmp_path, capsys):
    saida = tmp_path / "p.xml"
    lista = "LightningComponentBundle:Central_Comercial, ApexClass:B,ApexClass:A,"
    assert mc.main(["x", lista, str(saida)]) == 0
    xml = saida.read_text(encoding="utf-8")
    assert xml.index("<members>A</members>") < xml.index("<members>B</members>")
    assert xml.index("<name>ApexClass</name>") < xml.index(
        "<name>LightningComponentBundle</name>"
    )
    assert (
        "<members>Central_Comercial</members>" in xml
        and "<version>66.0</version>" in xml
    )
    assert "`LightningComponentBundle`: `Central_Comercial`" in capsys.readouterr().out


@pytest.mark.parametrize(
    "lista", ["", " , ", "Central_Comercial", "Tipo:nome com espaço", "A:B;rm -rf /"]
)
def test_recusa_lista_invalida(tmp_path, lista):
    assert mc.main(["x", lista, str(tmp_path / "p.xml")]) == 65
    assert not (tmp_path / "p.xml").exists()
