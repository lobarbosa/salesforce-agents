"""O laço de auto-avanço é o que faz a demanda andar sem humano entre etapas de
agente. Errar aqui não dá erro de sintaxe em lugar nenhum: dá etapa pulada com
status.yaml dizendo que ela aconteceu."""

from pathlib import Path

import pytest

from salesforce_agents import demands, fluxo


@pytest.fixture
def repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(demands, "CLIENTS_ROOT", Path("clients"))
    (Path("clients") / "acme").mkdir(parents=True)
    return tmp_path


def _demanda(status="backlog"):
    d = demands.create("acme", "Campo novo no Lead", "corpo da demanda", "sustentacao")
    if status != "backlog":
        d.status = status
        d.save()
    return d


def _executor_que_produz(artefatos_por_etapa):
    """Executor de teste que escreve o artefato que cada etapa deveria produzir
    — é assim que o agente de verdade se comporta quando faz o trabalho."""
    rodou = []

    def executor(client, demand_id, etapa):
        rodou.append(etapa)
        base = demands.CLIENTS_ROOT / client / "demandas" / demand_id
        for nome in artefatos_por_etapa.get(etapa, ()):
            (base / nome).write_text(f"artefato de {etapa}", encoding="utf-8")

    executor.rodou = rodou
    return executor


TODOS_ARTEFATOS = {
    "analise": ("01-analise.md",),
    "design": ("02-recon.md", "03-design.md"),
    "build": ("04-plano-build.md",),
    "qa": ("05-testes.md",),
    "release": ("06-entrega.md",),
}


# --- a ordem do fluxo ---------------------------------------------------


def test_triagem_entra_na_execucao_pela_primeira_etapa():
    for s in demands.STAGES_TRIAGEM:
        assert fluxo.proxima_etapa(s) == "analise"


def test_cada_etapa_aponta_pra_seguinte():
    assert fluxo.proxima_etapa("analise") == "aguardando_gate_analise"
    assert fluxo.proxima_etapa("aguardando_gate_analise") == "design"
    assert fluxo.proxima_etapa("qa") == "aguardando_homologacao"
    assert fluxo.proxima_etapa("aguardando_homologacao") == "release"


def test_entregue_e_terminal():
    assert fluxo.proxima_etapa("entregue") is None


def test_gate_e_so_o_que_comeca_com_aguardando():
    for s in demands.STAGES_EXECUCAO:
        assert fluxo.eh_gate(s) == s.startswith("aguardando_")


# --- o laço -------------------------------------------------------------


def test_para_no_primeiro_gate_humano(repo):
    d = _demanda()
    ex = _executor_que_produz(TODOS_ARTEFATOS)

    parada = fluxo.rodar("acme", d.id, executor=ex)

    # Rodou só a análise e parou esperando gente — não seguiu pro design.
    assert ex.rodou == ["analise"]
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_analise"
    assert demands.Demand.load("acme", d.id).status == "aguardando_gate_analise"


def test_toda_etapa_de_agente_e_seguida_de_gate_ou_do_fim(repo):
    """A invariante que define quanto o laço encadeia. Hoje ela vale pra todas
    as cinco etapas de agente, e por isso `rodar` executa uma etapa por
    invocação: o que ele automatiza é a borda agente→humano, não agente→agente.

    Se alguém puser duas etapas de agente em sequência (o fluxo de sustentação
    reduz gates, por exemplo), este teste quebra — e aí `fluxo.rodar` passa a
    encadear de verdade, o que é o comportamento desejado, mas merece ser uma
    decisão consciente e não uma surpresa."""
    for i, etapa in enumerate(demands.STAGES_EXECUCAO):
        if etapa not in fluxo.DISPARA_SESSAO:
            continue
        seguinte = fluxo.proxima_etapa(etapa)
        assert seguinte is None or fluxo.eh_gate(seguinte) or seguinte == "entregue", (
            f"'{etapa}' é seguida por '{seguinte}', que também é etapa de agente — "
            f"reveja o encadeamento em fluxo.rodar()"
        )


def test_a_fronteira_dev_qa_cai_exatamente_num_gate(repo):
    """Corolário do teste acima aplicado a ambientes: como o job autentica numa
    org só, a troca dev→qa precisa acontecer num ponto em que o controle já
    volta pro humano. Hoje acontece em aguardando_gate_build."""
    from salesforce_agents import ambientes

    anterior = None
    for etapa in demands.STAGES_EXECUCAO:
        atual = ambientes.ambiente_do_estagio(etapa)
        if anterior is not None and atual != anterior:
            predecessora = demands.STAGES_EXECUCAO[demands.STAGES_EXECUCAO.index(etapa) - 1]
            assert fluxo.eh_gate(predecessora), (
                f"a troca de ambiente antes de '{etapa}' não é precedida por gate"
            )
        anterior = atual


def test_etapa_em_org_diferente_da_do_job_derruba_em_vez_de_seguir(repo, monkeypatch):
    """Se a fronteira sair de cima de um gate, o laço tem que falhar alto em vez
    de rodar a etapa com a credencial errada."""
    from salesforce_agents import ambientes

    d = _demanda("analise")
    ex = _executor_que_produz(TODOS_ARTEFATOS)

    # O job resolve o próprio ambiente uma vez, no começo; a checagem de cada
    # etapa vem depois. Aqui a primeira resposta é "dev" (o que o job
    # autenticou) e as seguintes "qa" — é a fronteira se movendo sob os pés do
    # job, que é exatamente o que a guarda existe pra pegar.
    respostas = iter(["dev"])
    monkeypatch.setattr(
        ambientes, "ambiente_do_estagio", lambda s: next(respostas, "qa")
    )

    with pytest.raises(fluxo.FluxoError, match="autenticou em"):
        fluxo.rodar("acme", d.id, executor=ex)
    assert ex.rodou == []


def test_release_fecha_a_demanda_sem_pedir_mais_nada(repo):
    """`release` é a única etapa de agente sem gate depois: o que vem é
    `entregue`, terminal. Então é a única invocação que sai por 'fim'."""
    d = _demanda("release")
    ex = _executor_que_produz(TODOS_ARTEFATOS)

    parada = fluxo.rodar("acme", d.id, executor=ex)

    assert ex.rodou == ["release"]
    assert parada.motivo == "fim"
    assert demands.Demand.load("acme", d.id).status == "entregue"


def test_agente_que_nao_produz_o_artefato_derruba_o_job(repo):
    """O cenário que o laço não pode engolir: o agente rodou, não entregou o
    artefato, e o status seguiria em frente mentindo que a etapa aconteceu."""
    d = _demanda()
    ex = _executor_que_produz({})  # roda e não escreve nada

    with pytest.raises(demands.ArtifactAusenteError):
        fluxo.rodar("acme", d.id, executor=ex)

    # E o status não avançou.
    assert demands.Demand.load("acme", d.id).status == "analise"


def test_demanda_entregue_nao_roda_nada(repo):
    d = _demanda("entregue")
    ex = _executor_que_produz(TODOS_ARTEFATOS)
    parada = fluxo.rodar("acme", d.id, executor=ex)
    assert ex.rodou == []
    assert parada.motivo == "fim"


# --- aprovação de gate --------------------------------------------------


def test_aprovar_gate_avanca_e_registra_quem_aprovou(repo):
    d = _demanda("aguardando_gate_design")
    (Path("clients/acme/demandas") / d.id / "02-recon.md").write_text("x")
    (Path("clients/acme/demandas") / d.id / "03-design.md").write_text("x")

    atualizada = fluxo.aprovar_gate("acme", d.id, "leonardo")

    assert atualizada.status == "build"
    assert atualizada.historico[-1]["autor"] == "leonardo"
    assert atualizada.historico[-1]["de"] == "aguardando_gate_design"


def test_aprovar_o_que_nao_e_gate_e_recusado(repo):
    """Sem isso, um clique errado no app pularia a etapa de build inteira."""
    d = _demanda("build")
    with pytest.raises(fluxo.FluxoError):
        fluxo.aprovar_gate("acme", d.id, "leonardo")


# --- contrato com o YAML ------------------------------------------------


def test_saida_pro_github_output_tem_as_chaves_que_o_workflow_le():
    parada = fluxo.Parada("gate", "aguardando_gate_build", "dev", ("build",))
    linhas = dict(l.split("=", 1) for l in parada.as_github_output().splitlines())
    assert linhas == {
        "motivo": "gate",
        "etapa": "aguardando_gate_build",
        "ambiente": "dev",
        "espera_humano": "true",
        "etapas_rodadas": "build",
    }
