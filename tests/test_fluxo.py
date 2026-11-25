"""O laço de auto-avanço é o que faz a demanda andar sem humano entre etapas de
agente. Errar aqui não dá erro de sintaxe em lugar nenhum: dá etapa pulada com
status.yaml dizendo que ela aconteceu."""

from pathlib import Path

import pytest

from salesforce_agents import demands, fluxo, verificacao


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
            texto = QA_APROVADO if nome == "05-testes.md" else f"artefato de {etapa}"
            (base / nome).write_text(texto, encoding="utf-8")
        # Build concluído sai com a verificação do agente (verificacao.py).
        if etapa == "build" and (base / "04-plano-build.md").exists():
            (base / "04-verificacao.md").write_text(VERIFICACAO_APROVADA, encoding="utf-8")

    executor.rodou = rodou
    return executor


VERIFICACAO_APROVADA = "**Verificação:** aprovada\n**Org de teste:** `sbx-acme-dev`\n\n| Caso | Status |"
QA_APROVADO = "**Veredito:** aprovado\n**Org de teste:** `sbx-acme-qa`\n\n| Caso | Status |"

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
    # A demanda chega ao release com o QA já aprovado: sem essa evidência em
    # disco, `entregue` é recusado (test_entregue_sem_qa_aprovado_e_recusado).
    (demands.CLIENTS_ROOT / "acme" / "demandas" / d.id / "05-testes.md").write_text(QA_APROVADO, encoding="utf-8")
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


def test_demanda_congelada_ou_cancelada_nao_roda_nada(tmp_path, monkeypatch):
    """Disparada por engano (varredura, fila, botão), standby/cancelada não anda.

    Antes, standby caía na regra de triagem e a análise começava.
    """
    monkeypatch.chdir(tmp_path)
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    monkeypatch.setattr(demands, "CLIENTS_ROOT", tmp_path / "clients")
    chamadas = []
    for status in ("standby", "cancelada"):
        d = demands.create("acme", f"Demanda {status}", "texto")
        d.status = status
        d.save()
        parada = fluxo.rodar("acme", d.id, executor=lambda *a: chamadas.append(a))
        assert parada.motivo == "fim" and parada.etapa == status
        assert demands.Demand.load("acme", d.id).status == status
    assert chamadas == []


# --- build bloqueado ----------------------------------------------------


def _executor_de_build(texto):
    def executor(client, demand_id, etapa):
        base = demands.CLIENTS_ROOT / client / "demandas" / demand_id
        (base / "04-plano-build.md").write_text(texto, encoding="utf-8")
        # Build concluído sai verificado pelo agente; bloqueado não tem o que verificar.
        if "concluído" in texto:
            (base / "04-verificacao.md").write_text(VERIFICACAO_APROVADA, encoding="utf-8")

    return executor


def test_build_bloqueado_volta_ao_gate_de_design(repo):
    """Achado Somos Agility 2026-11-12: build que só registrou o bloqueio seguia
    para o gate de build e chegava à homologação sem nada construído."""
    d = _demanda("build")
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_build("**Resultado do build:** bloqueado\n\nFalta D1."))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_design"
    assert demands.Demand.load("acme", d.id).status == "aguardando_gate_design"


def test_build_concluido_segue_para_o_gate_de_build(repo):
    d = _demanda("build")
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_build("**Resultado do build:** concluído\n\n- Flow X"))
    assert parada.etapa == "aguardando_gate_build"


def test_plano_bloqueado_antigo_sai_antes_de_refazer_o_build(repo):
    """Sessão que não reescreve o plano não pode passar como build feito."""
    d = _demanda("build")
    plano = demands.CLIENTS_ROOT / "acme" / "demandas" / d.id / "04-plano-build.md"
    plano.write_text("# 04 — Build: BLOQUEADO (não é um plano de build concluído)", encoding="utf-8")

    with pytest.raises(demands.ArtifactAusenteError):
        fluxo.rodar("acme", d.id, executor=lambda *a: None)
    assert not plano.exists()


@pytest.mark.parametrize(
    "texto",
    [
        "**Resultado desta etapa: BUILD BLOQUEADO. Nenhum componente foi criado.**",
        "# 04 — Build: BLOQUEADO (não é um plano de build concluído)",
        "## Resultado desta tentativa: build não executado",
        "## Execução bloqueada até confirmação",
        "**Status: BUILD BLOQUEADO. Nenhum metadata foi criado ou alterado.**",
    ],
)
def test_planos_antigos_da_somos_sao_lidos_como_bloqueados(texto):
    from salesforce_agents import bloqueio

    assert bloqueio.build_bloqueado("# 04 — Plano de build\n\n" + texto)


def test_plano_normal_nao_e_lido_como_bloqueado():
    from salesforce_agents import bloqueio

    assert not bloqueio.build_bloqueado("# 04 — Plano de build\n\n## Componentes\n- Flow X\n\nRisco: deploy bloqueado se faltar o campo.")
    assert not bloqueio.build_bloqueado("**Resultado do build:** concluído\n\n## Execução bloqueada até confirmação")
    assert not bloqueio.build_bloqueado("## O build não está bloqueado")


# --- QA que não aprova volta para a construção ---------------------------


def _executor_de_qa(texto):
    def executor(client, demand_id, etapa):
        base = demands.CLIENTS_ROOT / client / "demandas" / demand_id
        (base / "05-testes.md").write_text(texto, encoding="utf-8")

    return executor


def _pasta(d):
    return demands.CLIENTS_ROOT / "acme" / "demandas" / d.id


def test_qa_aprovado_com_evidencia_segue_para_a_homologacao(repo):
    d = _demanda("qa")
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_qa(QA_APROVADO))
    assert parada.etapa == "aguardando_homologacao"
    assert (_pasta(d) / "05-testes.md").exists()


@pytest.mark.parametrize(
    "texto",
    [
        "**Veredito:** reprovado\n**Org de teste:** `sbx-acme-qa`\n\n### FALHA 1 (crítica) — painel sem dado",
        "# 05 — Testes\n\nTudo certo, sem linha de veredito.",
        "**Veredito:** aprovado\n**Org de teste:** `sbx-acme-dev`",
        "**Veredito:** aprovado",
    ],
)
def test_qa_sem_aprovacao_provada_volta_para_o_build(repo, texto):
    """Achado 2026-11-13: dez demandas em homologação com o QA reprovado."""
    d = _demanda("qa")
    (_pasta(d) / "05-roteiro-cliente.md").write_text("# Roteiro de uma rodada anterior", encoding="utf-8")
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_qa(texto))
    assert parada.motivo == "refazer"
    assert parada.etapa == "build"
    assert not parada.espera_humano
    assert demands.Demand.load("acme", d.id).status == "build"
    # o roteiro reprovado fica para o builder ler; o próximo QA escreve outro
    assert (_pasta(d) / "05-testes-rodada-1.md").exists()
    # o roteiro da rodada anterior sai antes de a sessão rodar
    assert not (_pasta(d) / "05-roteiro-cliente.md").exists()
    assert not (_pasta(d) / "05-testes.md").exists()


def test_build_refeito_passa_pelo_gate_de_pr_antes_de_voltar_ao_qa(repo):
    """Cada volta do QA tem um humano no meio: a regra de ouro não afrouxa."""
    d = _demanda("qa")
    fluxo.rodar("acme", d.id, executor=_executor_de_qa("**Veredito:** reprovado"))
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_build("**Resultado do build:** concluído"))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_build"


def test_depois_do_teto_de_reprovacoes_quem_decide_e_o_arquiteto(repo):
    d = _demanda("qa")
    for n in range(1, fluxo.MAX_VOLTAS_DO_QA + 1):
        (_pasta(d) / f"05-testes-rodada-{n}.md").write_text("**Veredito:** reprovado", encoding="utf-8")
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_qa("**Veredito:** reprovado"))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_design"
    assert (_pasta(d) / f"05-testes-rodada-{fluxo.MAX_VOLTAS_DO_QA + 1}.md").exists()


def test_refazer_sai_no_github_output():
    saida = fluxo.Parada("refazer", "build", "qa", ("qa",)).as_github_output()
    assert "motivo=refazer" in saida and "espera_humano=false" in saida


# --- entregue só com evidência -------------------------------------------


def test_entregue_sem_qa_aprovado_e_recusado(repo):
    """Achado 2026-11-14: demandas marcadas 'entregue' por correção manual só com o pedido."""
    d = _demanda("backlog")
    with pytest.raises(demands.EntregaSemEvidenciaError):
        demands.transition("acme", d.id, "entregue", "alguém")
    (_pasta(d) / "05-testes.md").write_text("**Veredito:** reprovado", encoding="utf-8")
    (_pasta(d) / "06-entrega.md").write_text("entrega", encoding="utf-8")
    with pytest.raises(demands.EntregaSemEvidenciaError):
        demands.transition("acme", d.id, "entregue", "alguém")
    assert demands.Demand.load("acme", d.id).status == "backlog"


def test_entregue_com_qa_aprovado_e_documento_passa(repo):
    d = _demanda("release")
    (_pasta(d) / "05-testes.md").write_text(QA_APROVADO, encoding="utf-8")
    with pytest.raises(demands.ArtifactAusenteError):  # falta o documento de entrega
        demands.transition("acme", d.id, "entregue", "pipeline")
    (_pasta(d) / "06-entrega.md").write_text("entrega", encoding="utf-8")
    assert demands.transition("acme", d.id, "entregue", "pipeline").status == "entregue"


ENTREGA_MANUAL = (
    "**Entrega manual:** registrada\n**Por:** Consultora\n**Em:** 2026-11-25T12:00:00Z\n"
    "**Evidência:** print.png\n\n# Entrega manual\n\n## O que foi feito\n\nRelatório desativado na org.\n"
)


def test_entrega_manual_registrada_vale_como_evidencia(repo):
    """2026-11-25: trabalho concluído pelo consultor fora da esteira, com registro e evidência."""
    d = _demanda("backlog")
    (_pasta(d) / demands.ARQUIVO_ENTREGA_MANUAL).write_text(ENTREGA_MANUAL, encoding="utf-8")
    assert demands.transition("acme", d.id, "entregue", "Cliente").status == "entregue"


def test_entrega_manual_incompleta_nao_vale(repo):
    """Arquivo vazio ou sem evidência nomeada não abre a porta."""
    d = _demanda("backlog")
    registro = _pasta(d) / demands.ARQUIVO_ENTREGA_MANUAL
    registro.write_text("", encoding="utf-8")
    with pytest.raises(demands.EntregaSemEvidenciaError):
        demands.transition("acme", d.id, "entregue", "alguém")
    registro.write_text(ENTREGA_MANUAL.replace("print.png", ""), encoding="utf-8")
    with pytest.raises(demands.EntregaSemEvidenciaError):
        demands.transition("acme", d.id, "entregue", "alguém")


def test_saida_longa_do_sf_e_cortada():
    tools = pytest.importorskip("salesforce_agents.tools")
    texto = "x" * 50_000
    cortado = tools._cortar(texto)
    assert len(cortado) < 13_000 and "saída cortada: 50000" in cortado
    assert tools._cortar("curto") == "curto"


def test_copia_do_roteiro_gravada_pelo_agente_nao_conta_como_outra_rodada(repo):
    """Achado EPLAST-47 (2026-11-15): o QA gravou `05-testes-rodada-1.md` igual ao
    `05-testes.md`, e a esteira arquivou o original como rodada 2."""
    texto = "**Veredito:** reprovado\n**Org de teste:** `sbx-acme-qa`\n\n### FALHA 1 (crítica) — x"
    d = _demanda("qa")

    def executor(client, demand_id, etapa):
        (_pasta(d) / "05-testes.md").write_text(texto, encoding="utf-8")
        (_pasta(d) / "05-testes-rodada-1.md").write_text(texto, encoding="utf-8")

    parada = fluxo.rodar("acme", d.id, executor=executor)

    assert parada.motivo == "refazer"
    assert sorted(p.name for p in _pasta(d).glob("05-testes*")) == ["05-testes-rodada-1.md"]


def test_roteiro_do_cliente_escrito_num_qa_reprovado_fica_para_o_time_testar(repo):
    """Decisão de 2026-11-15: o roteiro sai em toda rodada, não só na aprovada."""
    d = _demanda("qa")

    def executor(client, demand_id, etapa):
        (_pasta(d) / "05-testes.md").write_text("**Veredito:** reprovado", encoding="utf-8")
        (_pasta(d) / "05-roteiro-cliente.md").write_text("# Roteiro desta rodada", encoding="utf-8")

    assert fluxo.rodar("acme", d.id, executor=executor).motivo == "refazer"
    assert (_pasta(d) / "05-roteiro-cliente.md").read_text(encoding="utf-8") == "# Roteiro desta rodada"


# --- verificação do build: o agente testa antes de chamar o humano -----------


def _executor_com_verificacao(verificacao_texto):
    def executor(client, demand_id, etapa):
        base = demands.CLIENTS_ROOT / client / "demandas" / demand_id
        (base / "04-plano-build.md").write_text("**Resultado do build:** concluído", encoding="utf-8")
        if verificacao_texto is not None:
            (base / "04-verificacao.md").write_text(verificacao_texto, encoding="utf-8")

    return executor


def test_build_verificado_segue_para_o_gate_humano(repo):
    d = _demanda("build")
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(VERIFICACAO_APROVADA))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_build"


@pytest.mark.parametrize(
    "texto",
    [
        "**Verificação:** reprovada\n**Org de teste:** `sbx-acme-dev`\n\n### FALHA 1 — faixa errada",
        "# Verificação\n\nTudo certo, sem linha de resultado.",
        "**Verificação:** aprovada\n**Org de teste:** `sbx-acme-qa`",
        None,
    ],
)
def test_build_sem_verificacao_aprovada_refaz_a_construcao_sem_chamar_humano(repo, texto):
    d = _demanda("build")
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(texto))
    assert parada.motivo == "refazer"
    assert parada.etapa == "build"
    assert not parada.espera_humano
    assert demands.Demand.load("acme", d.id).status == "build"
    # a verificação reprovada fica para o builder ler; a próxima escreve outra
    assert not (_pasta(d) / "04-verificacao.md").exists()
    assert (_pasta(d) / "04-verificacao-rodada-1.md").exists() == (texto is not None)


def test_verificacao_inconclusiva_vai_ao_gate_porque_refazer_nao_resolve(repo):
    d = _demanda("build")
    texto = "**Verificação:** inconclusiva\n**Org de teste:** `sbx-acme-dev`\n\nNão há como disparar o agendamento na dev."
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(texto))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_build"
    assert (_pasta(d) / "04-verificacao.md").exists()


def test_depois_do_teto_de_verificacoes_reprovadas_quem_decide_e_o_arquiteto(repo):
    d = _demanda("build")
    for n in range(1, fluxo.MAX_VOLTAS_DA_VERIFICACAO + 1):
        (_pasta(d) / f"04-verificacao-rodada-{n}.md").write_text("**Verificação:** reprovada", encoding="utf-8")
    reprovada = "**Verificação:** reprovada\n**Org de teste:** `sbx-acme-dev`"
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(reprovada))
    assert parada.motivo == "gate"
    assert parada.etapa == "aguardando_gate_design"


def test_verificacao_de_um_build_anterior_nao_vale_para_o_refeito(repo):
    d = _demanda("build")
    (_pasta(d) / "04-verificacao.md").write_text(VERIFICACAO_APROVADA, encoding="utf-8")
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(None))
    assert parada.motivo == "refazer"


def test_build_bloqueado_continua_voltando_ao_design_sem_verificacao(repo):
    d = _demanda("build")

    def executor(client, demand_id, etapa):
        (_pasta(d) / "04-plano-build.md").write_text("**Resultado do build:** bloqueado", encoding="utf-8")

    parada = fluxo.rodar("acme", d.id, executor=executor)
    assert parada.etapa == "aguardando_gate_design"
    assert verificacao.faltando(_pasta(d)) == []


# --- QA em duas fases: automação agendada ------------------------------------


def test_qa_que_armou_o_teste_espera_em_qa_sem_chamar_ninguem(repo):
    d = _demanda("qa")
    texto = "**Veredito:** aguardando execução\n**Org de teste:** `sbx-acme-qa`\n**Conferir depois de:** 2026-11-15T16:00Z"
    parada = fluxo.rodar("acme", d.id, executor=_executor_de_qa(texto))
    assert parada.motivo == "aguardar"
    assert parada.etapa == "qa"
    assert not parada.espera_humano
    assert demands.Demand.load("acme", d.id).status == "qa"
    # nada é arquivado: a sessão seguinte reescreve este mesmo arquivo
    assert (_pasta(d) / "05-testes.md").exists()
    assert not list(_pasta(d).glob("05-testes-rodada-*.md"))


def test_teste_armado_fora_da_sandbox_de_qa_volta_para_o_build(repo):
    d = _demanda("qa")
    texto = "**Veredito:** aguardando execução\n**Org de teste:** `sbx-acme-dev`"
    assert fluxo.rodar("acme", d.id, executor=_executor_de_qa(texto)).motivo == "refazer"


def test_aguardar_sai_no_github_output():
    saida = fluxo.Parada("aguardar", "qa", "qa", ("qa",)).as_github_output()
    assert "motivo=aguardar" in saida and "espera_humano=false" in saida


# --- reverificação: só o verificador, sobre o build que já existe ----------------


def test_reverificar_roda_so_o_verificador_e_volta_ao_gate(repo):
    d = _demanda("aguardando_gate_build")
    (_pasta(d) / "04-plano-build.md").write_text("**Resultado do build:** concluído", encoding="utf-8")
    (_pasta(d) / "04-verificacao.md").write_text(
        "**Verificação:** inconclusiva\n**Org de teste:** `sbx-acme-dev`", encoding="utf-8"
    )
    executor = _executor_com_verificacao(VERIFICACAO_APROVADA)
    etapas = []

    def registra(client, demand_id, etapa):
        etapas.append(etapa)
        executor(client, demand_id, etapa)

    fluxo.reverificar("acme", d.id, "Fulano")
    parada = fluxo.rodar("acme", d.id, executor=registra, so_verificar=True)

    assert etapas == [fluxo.ETAPA_SO_VERIFICACAO]
    assert parada.motivo == "gate" and parada.etapa == "aguardando_gate_build"
    assert parada.etapas_rodadas == (fluxo.ETAPA_SO_VERIFICACAO,)
    assert "aprovada" in (_pasta(d) / "04-verificacao.md").read_text(encoding="utf-8")


def test_reverificacao_reprovada_refaz_o_build_de_verdade(repo):
    d = _demanda("aguardando_gate_build")
    (_pasta(d) / "04-plano-build.md").write_text("**Resultado do build:** concluído", encoding="utf-8")
    fluxo.reverificar("acme", d.id, "Fulano")
    reprovada = "**Verificação:** reprovada\n**Org de teste:** `sbx-acme-dev`"
    parada = fluxo.rodar("acme", d.id, executor=_executor_com_verificacao(reprovada), so_verificar=True)
    assert parada.motivo == "refazer" and parada.etapa == "build"


@pytest.mark.parametrize("status,plano", [
    ("aguardando_gate_design", "**Resultado do build:** concluído"),
    ("aguardando_gate_build", None),
    ("aguardando_gate_build", "**Resultado do build:** bloqueado"),
])
def test_reverificar_recusa_sem_build_concluido_no_gate(repo, status, plano):
    d = _demanda(status)
    if plano:
        (_pasta(d) / "04-plano-build.md").write_text(plano, encoding="utf-8")
    with pytest.raises(fluxo.FluxoError):
        fluxo.reverificar("acme", d.id, "Fulano")


# --- reaprovação do design depois de build bloqueado (SOMOSAGILITY-30) ----

PLANO_BLOQUEADO = (
    "**Resultado do build:** bloqueado\n\n**Pergunta sem resposta:** aceitar o limite de CPU?\n\n"
    "# 04 — Plano de build\n\ndetalhes que não vão para o topo do card\n"
)


def _bloqueada(repo):
    d = _demanda("build")
    base = demands.CLIENTS_ROOT / "acme" / "demandas" / d.id
    (base / "03-design.md").write_text("# Design\n\nseção 6: estourou, volta ao gate", encoding="utf-8")
    (base / "comentarios-do-card.md").write_text(
        "# Comentários do card\n\n## Equipe — 2026-11-23 10:29\n\nAprovou o gate \"aguardando_gate_design\". Entrou na fila da esteira.\n",
        encoding="utf-8",
    )
    fluxo.rodar("acme", d.id, executor=_executor_de_build(PLANO_BLOQUEADO))
    assert demands.Demand.load("acme", d.id).status == "aguardando_gate_design"
    return d, base


def test_reaprovar_sem_mudanca_e_recusado_e_nao_registra_gate(repo):
    d, base = _bloqueada(repo)
    gates_antes = (base / "gates.md").read_text(encoding="utf-8") if (base / "gates.md").exists() else ""
    # Mais uma aprovação automática no card não conta como resposta.
    with (base / "comentarios-do-card.md").open("a", encoding="utf-8") as fh:
        fh.write("\n## Equipe — 2026-11-23 13:35\n\nAprovou o gate \"aguardando_gate_design\". Entrou na fila da esteira.\n")
    with pytest.raises(fluxo.GateSemMudancaError):
        fluxo.aprovar_gate("acme", d.id, "Carlos")
    assert demands.Demand.load("acme", d.id).status == "aguardando_gate_design"
    gates_depois = (base / "gates.md").read_text(encoding="utf-8") if (base / "gates.md").exists() else ""
    assert gates_depois == gates_antes


def test_reaprovar_depois_de_registrar_no_design_passa(repo):
    d, base = _bloqueada(repo)
    with (base / "03-design.md").open("a", encoding="utf-8") as fh:
        fh.write("\n\n## Decisão: opção (a)\n")
    assert fluxo.aprovar_gate("acme", d.id, "Leonardo").status == "build"


def test_reaprovar_depois_de_resposta_no_card_passa(repo):
    d, base = _bloqueada(repo)
    with (base / "comentarios-do-card.md").open("a", encoding="utf-8") as fh:
        fh.write("\n## Cliente — 2026-11-23 17:07\n\nTodos os perfis\n")
    assert fluxo.aprovar_gate("acme", d.id, "Leonardo").status == "build"


def test_bloqueio_antigo_sem_impressao_nao_trava(repo):
    d, base = _bloqueada(repo)
    (base / "04-bloqueio-insumos.txt").unlink()
    assert fluxo.aprovar_gate("acme", d.id, "Leonardo").status == "build"


def test_impressao_sai_quando_o_build_roda_de_novo(repo):
    d, base = _bloqueada(repo)
    with (base / "03-design.md").open("a", encoding="utf-8") as fh:
        fh.write("\nresposta\n")
    fluxo.aprovar_gate("acme", d.id, "Leonardo")
    fluxo.rodar("acme", d.id, executor=_executor_de_build("**Resultado do build:** concluído\n\n- Flow X"))
    assert not (base / "04-bloqueio-insumos.txt").exists()


def test_card_do_design_mostra_o_bloqueio_no_topo(repo):
    from salesforce_agents import revisao

    d, _ = _bloqueada(repo)
    art = revisao.artefato_em_revisao(demands.Demand.load("acme", d.id))
    assert art["nome"] == "03-design.md"
    assert art["conteudo"].startswith("## O build parou: falta uma decisão")
    assert "aceitar o limite de CPU?" in art["conteudo"]
    assert "detalhes que não vão para o topo" not in art["conteudo"]
    assert "seção 6: estourou" in art["conteudo"]
