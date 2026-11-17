"""Deploy em QA travado por trabalho Apex pendente: quando a esteira pode cancelar, e o quê."""

import importlib.util
import json
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "jobs_pendentes.py"
_spec = importlib.util.spec_from_file_location("jobs_pendentes", _SCRIPT)
jobs = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(jobs)

AGENDAVEL = (
    "Essa classe programável tem trabalhos pendentes ou em andamento - "
    "IDs do CronTrigger (08eHa00000Xr4SZ)"
)
SEM_ID = "Essa classe programável tem trabalhos pendentes ou em andamento - IDs do CronTrigger ()"
DICA = (
    "É possível ignorar esse erro ao permitir implantações com trabalhos do Apex "
    "na página Configurações de implantação em Configuração."
)
ASSINCRONO = (
    "Essa classe do Apex possui trabalhos do Apex assíncronos (por exemplo, trabalhos em lote, "
    "agendáveis, ou enfileiráveis) pendentes ou em andamento; ID(s) de AsyncApexJob: 707Ha00001E4RF1"
)


def _deploy(*problemas):
    falhas = [{"componentType": "ApexClass", "fullName": f"C{i}", "problem": p} for i, p in enumerate(problemas)]
    return {"result": {"status": "Failed", "details": {"componentFailures": falhas}}}


def test_falha_so_por_trabalho_pendente_devolve_os_ids_agendados_primeiro():
    deploy = _deploy(ASSINCRONO, DICA, AGENDAVEL, DICA, SEM_ID, AGENDAVEL)
    assert jobs.trabalhos_que_travam(deploy) == ["08eHa00000Xr4SZ", "707Ha00001E4RF1"]


def test_mensagem_em_ingles_tambem_conta():
    deploy = _deploy(
        "This schedulable class has jobs pending or in progress - CronTrigger IDs (08eHa00000Xr4SZAAX)",
        "You can bypass this error by allowing deployments with Apex jobs in the Deployment Settings page in Setup.",
    )
    assert jobs.trabalhos_que_travam(deploy) == ["08eHa00000Xr4SZAAX"]


def test_outra_falha_junto_nao_cancela_nada():
    deploy = _deploy(AGENDAVEL, DICA, "Variable does not exist: Foo (12:9)")
    assert jobs.trabalhos_que_travam(deploy) == []


def test_sem_id_citado_nao_ha_o_que_cancelar():
    assert jobs.trabalhos_que_travam(_deploy(SEM_ID, DICA)) == []


def test_deploy_sem_falha_de_componente_nao_cancela_nada():
    assert jobs.trabalhos_que_travam({"result": {"status": "Failed", "details": {}}}) == []
    assert jobs.trabalhos_que_travam({"name": "ErroQualquer", "message": "x"}) == []


def test_falha_unica_vem_como_objeto():
    deploy = {"result": {"details": {"componentFailures": {"problem": AGENDAVEL}}}}
    assert jobs.trabalhos_que_travam(deploy) == ["08eHa00000Xr4SZ"]


def test_linha_de_comando_imprime_ids_ou_sai_com_3(tmp_path, capsys):
    arquivo = tmp_path / "deploy.json"
    arquivo.write_text(json.dumps(_deploy(AGENDAVEL, DICA)), encoding="utf-8")
    assert jobs.main(["jobs_pendentes.py", str(arquivo)]) == 0
    assert capsys.readouterr().out.strip() == "08eHa00000Xr4SZ"
    arquivo.write_text(json.dumps(_deploy("outro erro")), encoding="utf-8")
    assert jobs.main(["jobs_pendentes.py", str(arquivo)]) == 3
    assert jobs.main(["jobs_pendentes.py", str(tmp_path / "nao-existe.json")]) == 3
