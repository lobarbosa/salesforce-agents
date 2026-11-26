import importlib.util
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("diag", RAIZ / "scripts" / "diagnostico_chave_externa.py")
diag = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(diag)


def _par(codigo, loja, n):
    return {"ProtheusId__c": codigo, "Store__c": loja, "n": n}


def test_lojas_diferentes_do_mesmo_codigo_nao_sao_duplicata():
    """Cliente do Protheus = código + loja: duas lojas do mesmo código são legítimas."""
    pares = [_par("000922", "01", 1), _par("000922", "02", 1)]
    c = diag.classificar(pares, "ProtheusId__c", "Store__c")
    assert c["lojas_diferentes"] == ["000922"]
    assert c["mesma_loja"] == [] and c["sem_loja"] == []


def test_mesmo_codigo_e_mesma_loja_e_duplicata():
    pares = [_par("000922", "01", 2), _par("001000", "01", 1), _par("001000", "02", 1)]
    c = diag.classificar(pares, "ProtheusId__c", "Store__c")
    assert c["mesma_loja"] == ["000922"]
    assert c["lojas_diferentes"] == ["001000"]


def test_conta_sem_loja_fica_separada():
    pares = [_par("000922", None, 1), _par("000922", "01", 1)]
    c = diag.classificar(pares, "ProtheusId__c", "Store__c")
    assert c["sem_loja"] == ["000922"]


def test_contas_afetadas_soma_os_grupos():
    assert diag.contas_afetadas([{"n": 2}, {"n": 3}]) == 5


def test_recusa_org_fora_da_esteira_e_nome_de_campo_estranho(capsys):
    assert diag.main(["--target-org", "eplast-prod"]) == 2
    assert diag.main(["--target-org", "sbx-eplast-qa", "--campo", "Name; DELETE"]) == 2
    assert diag.main(["--target-org", "sbx-eplast-qa", "--codigo", "x' OR Id != null"]) == 2
    assert diag.main(["--target-org", "sbx-eplast-qa", "--ids", "001' OR 1=1"]) == 2


def test_definicao_dos_campos_le_o_describe():
    describe = {"result": {"fields": [
        {"name": "ProtheusId__c", "type": "string", "length": 255, "externalId": True, "unique": False, "caseSensitive": False},
    ]}}
    linhas = "\n".join(diag.linhas_de_definicao(describe, ["ProtheusId__c", "Store__c"]))
    assert "| `ProtheusId__c` | string | 255 | sim | não | não |" in linhas
    assert "`Store__c` | não existe nesta org" in linhas
