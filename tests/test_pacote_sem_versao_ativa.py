"""Versão de agente ativa na QA: sai do pacote só ela, a versão nova da demanda fica."""

import importlib.util
import json
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pacote_sem_versao_ativa.py"
_spec = importlib.util.spec_from_file_location("pacote_sem_versao_ativa", _SCRIPT)
pacote = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pacote)

BASE = "force-app/main/default"
ARGS = [
    "--source-dir", f"{BASE}/bots/SFAgent2/SFAgent2.bot-meta.xml",
    "--source-dir", f"{BASE}/bots/SFAgent2/v16.botVersion-meta.xml",
    "--source-dir", f"{BASE}/bots/SFAgent2/v17.botVersion-meta.xml",
    "--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v16/SFAgent2_v16.genAiPlannerBundle",
    "--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v16/agentScript/SFAgent2_v16_definition.agent",
    "--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v17/SFAgent2_v17.genAiPlannerBundle",
    "--source-dir", f"{BASE}/flows/Task_Agente_CriarTarefa.flow-meta.xml",
    "--test-level", "NoTestRun",
]  # fmt: skip


def _deploy(*falhas):
    lista = [{"componentType": t, "fullName": n, "problem": "o agente está ativo"} for t, n in falhas]
    return {"result": {"status": "Failed", "details": {"componentFailures": lista}}}


def _caminhos(argumentos):
    return [argumentos[i + 1] for i, a in enumerate(argumentos) if a == "--source-dir"]


def test_sai_so_a_versao_ativa_e_a_nova_fica():
    falhas = pacote.falhas(_deploy(("BotVersion", "SFAgent2.v16"), ("GenAiPlannerBundle", "SFAgent2_v16")))
    saida, tirados = pacote.sem_as_recusadas(ARGS, pacote.trechos_recusados(falhas))
    assert tirados == 3
    assert _caminhos(saida) == [
        f"{BASE}/bots/SFAgent2/SFAgent2.bot-meta.xml",
        f"{BASE}/bots/SFAgent2/v17.botVersion-meta.xml",
        f"{BASE}/genAiPlannerBundles/SFAgent2_v17/SFAgent2_v17.genAiPlannerBundle",
        f"{BASE}/flows/Task_Agente_CriarTarefa.flow-meta.xml",
    ]
    assert saida[-2:] == ["--test-level", "NoTestRun"]


def test_versao_de_nome_parecido_nao_sai_junto():
    args = ["--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v1/x.genAiPlannerBundle",
            "--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v16/x.genAiPlannerBundle"]  # fmt: skip
    saida, tirados = pacote.sem_as_recusadas(args, ["/genAiPlannerBundles/SFAgent2_v1/"])
    assert tirados == 1
    assert _caminhos(saida) == [f"{BASE}/genAiPlannerBundles/SFAgent2_v16/x.genAiPlannerBundle"]


def test_pasta_inteira_do_bundle_como_source_dir_tambem_sai():
    args = ["--source-dir", f"{BASE}/genAiPlannerBundles/SFAgent2_v16", "--source-dir", f"{BASE}/flows/F.flow-meta.xml"]
    saida, tirados = pacote.sem_as_recusadas(args, ["/genAiPlannerBundles/SFAgent2_v16/"])
    assert tirados == 1
    assert _caminhos(saida) == [f"{BASE}/flows/F.flow-meta.xml"]


def test_bot_recusado_tira_a_pasta_do_bot():
    trechos = pacote.trechos_recusados([("Bot", "SFAgent2")])
    saida, tirados = pacote.sem_as_recusadas(ARGS, trechos)
    assert tirados == 3
    assert all("/bots/" not in c for c in _caminhos(saida))


def test_tipo_desconhecido_nao_arrisca():
    assert pacote.trechos_recusados([("BotVersion", "SFAgent2.v16"), ("Flow", "F")]) is None
    assert pacote.trechos_recusados([("BotVersion", "semponto")]) is None


def test_linha_de_comando(tmp_path, capsys):
    deploy = tmp_path / "deploy.json"
    args = tmp_path / "args.txt"
    args.write_text("\n".join(ARGS) + "\n", encoding="utf-8")
    deploy.write_text(json.dumps(_deploy(("BotVersion", "SFAgent2.v16"))), encoding="utf-8")
    assert pacote.main(["x", str(deploy), str(args)]) == 0
    saida = capsys.readouterr().out.splitlines()
    assert f"{BASE}/bots/SFAgent2/v16.botVersion-meta.xml" not in saida
    assert f"{BASE}/bots/SFAgent2/v17.botVersion-meta.xml" in saida
    # nada do pacote corresponde à versão recusada: volta ao comportamento antigo
    deploy.write_text(json.dumps(_deploy(("BotVersion", "Outro.v2"))), encoding="utf-8")
    assert pacote.main(["x", str(deploy), str(args)]) == 3
    # pacote que só tinha a versão recusada: não sobra o que implantar
    args.write_text(f"--source-dir\n{BASE}/bots/SFAgent2/v16.botVersion-meta.xml\n--test-level\nNoTestRun\n", encoding="utf-8")
    deploy.write_text(json.dumps(_deploy(("BotVersion", "SFAgent2.v16"))), encoding="utf-8")
    assert pacote.main(["x", str(deploy), str(args)]) == 3
    assert pacote.main(["x", str(tmp_path / "nada.json"), str(args)]) == 3
