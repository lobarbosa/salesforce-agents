"""Pré-checagem: chaves de componente e o que se confere na org."""

from salesforce_agents import preflight

BASE = "clients/acme/force-app/main/default/"


def test_versoes_do_mesmo_agente_sao_o_mesmo_componente():
    assert preflight.componente(BASE + "bots/Agente/v5.botVersion-meta.xml") == "agente Agente"
    assert preflight.componente(BASE + "genAiPlannerBundles/Agente_v4/Agente_v4.genAiPlannerBundle") == "agente Agente"
    assert preflight.componente(BASE + "genAiPlannerBundles/Agente_v5/x/y.json") == "agente Agente"


def test_campo_e_por_item_nao_pelo_objeto():
    assert preflight.componente(BASE + "objects/Account/fields/A__c.field-meta.xml") == "objects/Account/fields/A__c"
    assert preflight.componente(BASE + "objects/Account/fields/B__c.field-meta.xml") != "objects/Account/fields/A__c"
    assert preflight.componente(BASE + "classes/Svc.cls") == preflight.componente(BASE + "classes/Svc.cls-meta.xml")
    assert preflight.componente("clients/acme/demandas/X/01-analise.md") is None


def test_org_mostra_versao_ativa_flow_ativo_e_job_pendente():
    def consulta(org, soql):
        assert org == "sbx-acme-qa"
        if "BotVersion" in soql:
            return [{"VersionNumber": 4, "Status": "Active"}, {"VersionNumber": 3, "Status": "Inactive"}]
        if "FlowDefinitionView" in soql:
            return [{"ApiName": "Meu_Flow", "ActiveVersionId": "301x"}]
        return [{"ApexClass": {"Name": "Agendada"}, "JobType": "ScheduledApex", "Status": "Queued"}]

    achados = preflight.conferir_org(
        "sbx-acme-qa", {"agente Agente", "flows/Meu_Flow", "flows/Outro", "classes/Agendada"}, consulta
    )
    texto = "\n".join(achados)
    assert "ativa: v4" in texto
    assert "`Meu_Flow`: tem versão ativa" in texto and "`Outro`: não existe" in texto
    assert "job pendente nesta org: Agendada" in texto


def test_consulta_que_falha_vira_nao_conferido():
    def consulta(org, soql):
        raise RuntimeError("sem acesso")

    assert "não conferido (sem acesso)" in preflight.conferir_org("o", {"agente A"}, consulta)[0]


def test_qa_ocupada_por_outra_demanda_bloqueia(monkeypatch):
    monkeypatch.setattr(preflight, "demandas_em_andamento", lambda c, e: {"ACME-2": "qa", "ACME-3": "build"})
    monkeypatch.setattr(preflight, "componentes_da_branch", lambda c, ref: set())
    assert preflight.rodar("acme", "ACME-1", "qa", "sbx-acme-qa").bloqueios
    assert not preflight.rodar("acme", "ACME-1", "build", "sbx-acme-dev").bloqueios


def test_outra_demanda_no_mesmo_agente_vira_aviso(monkeypatch):
    monkeypatch.setattr(preflight, "demandas_em_andamento", lambda c, e: {"ACME-2": "aguardando_gate_build"})
    monkeypatch.setattr(preflight, "componentes_da_branch", lambda c, ref: {"agente Agente"})
    res = preflight.rodar("acme", "ACME-1", "design", "sbx-acme-dev")
    assert res.avisos == ["ACME-2 (aguardando_gate_build) também mexe em: agente Agente."]
    assert res.org == []  # design ainda não implanta: não confere a org
