"""Perfis e permission sets vão à QA só com o que a demanda acrescentou."""

import importlib.util
import subprocess
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "permissoes_so_o_diff.py"
_spec = importlib.util.spec_from_file_location("permissoes_so_o_diff", _SCRIPT)
perm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(perm)

NS = "http://soap.sforce.com/2006/04/metadata"
BASE_PS = f"""<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="{NS}">
    <applicationVisibilities>
        <application>standard__AdvancedTherapyManagement</application>
        <visible>true</visible>
    </applicationVisibilities>
    <description>Diretor</description>
    <fieldPermissions>
        <editable>true</editable>
        <field>Conta__c.Antigo__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>Diretor Comercial</label>
</PermissionSet>
"""
NOVO = """    <fieldPermissions>
        <editable>true</editable>
        <field>BluePrint__c.PFP_1_Texto__c</field>
        <readable>true</readable>
    </fieldPermissions>
"""


def _com_novo(xml: str) -> str:
    return xml.replace("    <hasActivationRequired>", NOVO + "    <hasActivationRequired>")


def test_permission_set_fica_so_com_o_novo_e_os_obrigatorios():
    reduzido, novos, total = perm.reduzir(BASE_PS, _com_novo(BASE_PS))
    assert (novos, total) == (1, 6)
    assert "PFP_1_Texto__c" in reduzido
    assert "AdvancedTherapyManagement" not in reduzido
    assert "Antigo__c" not in reduzido
    for obrigatorio in ("<label>Diretor Comercial</label>", "<description>Diretor</description>", "<hasActivationRequired>"):
        assert obrigatorio in reduzido
    assert f'<PermissionSet xmlns="{NS}">' in reduzido


def test_formatacao_diferente_nao_conta_como_novo():
    reformatado = BASE_PS.replace("    <label>", "<label>").replace("<visible>true</visible>", "<visible> true </visible>")
    assert perm.reduzir(BASE_PS, reformatado)[0] is None


def test_perfil_alterado_em_item_existente_leva_so_o_item():
    base = f"""<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="{NS}">
    <custom>true</custom>
    <fieldPermissions><editable>false</editable><field>A__c.X__c</field><readable>true</readable></fieldPermissions>
    <userLicense>Salesforce</userLicense>
</Profile>
"""
    atual = base.replace("<editable>false</editable>", "<editable>true</editable>")
    reduzido, novos, _ = perm.reduzir(base, atual)
    assert novos == 1
    assert "<editable>true</editable>" in reduzido
    assert "<custom>true</custom>" in reduzido
    assert "userLicense" not in reduzido


def test_linha_de_comando_reduz_tira_e_preserva(tmp_path, monkeypatch, capsys):
    raiz = tmp_path
    subprocess.run(["git", "init", "-q"], cwd=raiz, check=True)
    pasta = raiz / "clients/cli/force-app/main/default"
    (pasta / "permissionsets").mkdir(parents=True)
    (pasta / "profiles").mkdir(parents=True)
    ps = pasta / "permissionsets/Diretor.permissionset-meta.xml"
    igual = pasta / "profiles/Igual.profile-meta.xml"
    ps.write_text(BASE_PS, encoding="utf-8")
    igual.write_text(BASE_PS.replace("PermissionSet", "Profile"), encoding="utf-8")
    subprocess.run(["git", "add", "-A"], cwd=raiz, check=True)
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "base"], cwd=raiz, check=True)
    ps.write_text(_com_novo(BASE_PS), encoding="utf-8")
    novo = pasta / "permissionsets/Novo.permissionset-meta.xml"
    novo.write_text(BASE_PS, encoding="utf-8")
    args = tmp_path / "args.txt"
    D = "force-app/main/default"
    args.write_text(
        "\n".join([
            "--source-dir", f"{D}/permissionsets/Diretor.permissionset-meta.xml",
            "--source-dir", f"{D}/profiles/Igual.profile-meta.xml",
            "--source-dir", f"{D}/permissionsets/Novo.permissionset-meta.xml",
            "--source-dir", f"{D}/flows/F.flow-meta.xml",
            "--test-level", "NoTestRun",
        ]) + "\n",
        encoding="utf-8",
    )  # fmt: skip
    monkeypatch.chdir(raiz)
    assert perm.main(["x", "HEAD", "cli", str(args)]) == 0
    linhas = args.read_text(encoding="utf-8").split()
    assert f"{D}/profiles/Igual.profile-meta.xml" not in linhas
    assert f"{D}/permissionsets/Diretor.permissionset-meta.xml" in linhas
    assert f"{D}/permissionsets/Novo.permissionset-meta.xml" in linhas
    assert linhas[-2:] == ["--test-level", "NoTestRun"]
    assert "AdvancedTherapyManagement" not in ps.read_text(encoding="utf-8")
    assert "AdvancedTherapyManagement" in novo.read_text(encoding="utf-8")
    saida = capsys.readouterr().out
    assert "1 de 6 elementos" in saida and "fora do pacote" in saida and "vai inteiro" in saida
