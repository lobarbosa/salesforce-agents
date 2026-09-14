"""O gate precisa chegar cheio ao Squad OS, não vazio.

Contexto (ACXYA-2, 2026-09-14, primeiro ciclo real de demanda): o
`ba-discovery` fez o que devia — não inventou o tipo do campo, listou onze
premissas pendentes — e o card mostrou "0 perguntas" com um botão de aprovar
pronto pra uso. O modal já se recusava a aprovar com pergunta em aberto; a
trava estava inerte porque ninguém populava o campo que ela confere.

O que estes testes protegem: que o artefato daquele gate e as pendências dele
viajem junto do status, e que o mapa de qual arquivo está em julgamento
continue derivado de `REQUIRED_ARTIFACTS` em vez de virar uma segunda lista
escrita à mão.
"""

from __future__ import annotations

import pytest

from salesforce_agents import demands, revisao


@pytest.fixture
def repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "clients" / "acme").mkdir(parents=True)
    monkeypatch.setattr(demands, "CLIENTS_ROOT", tmp_path / "clients")
    return tmp_path


ANALISE = """# Análise ACME-1

## Critérios de aceite
Coisas testáveis aqui.

## Premissas a validar (PENDENTES)

- [ ] **Tipo de campo**: texto curto, texto longo ou rico?
- [ ] **Obrigatoriedade**: é Required ou opcional?
- [x] Nomenclatura: já respondida pelo CLAUDE.md do cliente
"""


def _demanda_no_gate(status: str, artefato: str | None, conteudo: str = ANALISE):
    d = demands.create("acme", "Campo novo", "texto da demanda")
    if artefato:
        (d.path / artefato).write_text(conteudo, encoding="utf-8")
    d.status = status
    d.save()
    return d


# --- qual arquivo está na mesa -----------------------------------------------


def test_cada_gate_julga_o_que_a_etapa_anterior_produziu():
    assert revisao.artefato_do_gate("aguardando_gate_analise") == "01-analise.md"
    assert revisao.artefato_do_gate("aguardando_gate_build") == "04-plano-build.md"
    assert revisao.artefato_do_gate("aguardando_homologacao") == "05-testes.md"


def test_gate_de_design_poe_o_design_na_mesa_e_nao_o_recon():
    """A etapa `design` produz dois arquivos. O recon é insumo; o que o
    arquiteto humano aprova é a decisão declarativo-vs-código."""
    assert revisao.artefato_do_gate("aguardando_gate_design") == "03-design.md"


def test_fora_de_gate_nao_ha_nada_para_revisar():
    assert revisao.artefato_do_gate("analise") is None
    assert revisao.artefato_do_gate("backlog") is None
    assert revisao.artefato_do_gate("entregue") is None


def test_o_mapa_cobre_todo_gate_que_existe():
    """Se alguém acrescentar um gate em STAGES_EXECUCAO e ele não cair neste
    mapa, o card daquele gate volta a ser um botão sem contexto — falha aqui,
    não em produção."""
    gates = [s for s in demands.STAGES_EXECUCAO if s.startswith("aguardando_")]
    assert gates, "nenhum gate encontrado — STAGES_EXECUCAO mudou de forma"
    for gate in gates:
        assert revisao.artefato_do_gate(gate), f"{gate} não tem artefato em julgamento"


# --- as pendências ------------------------------------------------------------


def test_pendencia_marcada_vira_pergunta_e_resolvida_nao():
    perguntas = revisao.pendencias(ANALISE)

    textos = [p["texto"] for p in perguntas]
    assert "Tipo de campo: texto curto, texto longo ou rico?" in textos
    assert "Obrigatoriedade: é Required ou opcional?" in textos
    assert not any("Nomenclatura" in t for t in textos), "`- [x]` é pendência já fechada"


def test_id_da_pergunta_sobrevive_a_uma_nova_sincronizacao():
    """A mesma etapa pode sincronizar de novo (re-run do job). Se o id mudasse,
    a resposta que o humano digitou seria descartada junto."""
    a = revisao.pendencias(ANALISE)
    b = revisao.pendencias(ANALISE)
    assert [p["id"] for p in a] == [p["id"] for p in b]


def test_artefato_sem_checkbox_nao_inventa_pergunta():
    assert revisao.pendencias("# Design\n\nTudo decidido, nada pendente.\n") == []


# --- o payload ----------------------------------------------------------------


def test_em_gate_o_payload_leva_artefato_e_perguntas(repo):
    d = _demanda_no_gate("aguardando_gate_analise", "01-analise.md")

    payload = revisao.payload_de_sync(d)

    assert payload["status"] == "aguardando_gate_analise"
    assert payload["artefato"]["nome"] == "01-analise.md"
    assert "Premissas a validar" in payload["artefato"]["conteudo"]
    assert len(payload["artefato"]["perguntas"]) == 2


def test_fora_de_gate_o_payload_continua_sendo_so_o_status(repo):
    d = _demanda_no_gate("analise", "01-analise.md")

    assert "artefato" not in revisao.payload_de_sync(d)


def test_artefato_faltando_nao_quebra_o_sync(repo):
    """Quem recusa avançar sem artefato é `demands.transition`. Aqui, informar
    que não há o que mostrar é suficiente — duas vozes recusando a mesma coisa
    só confundem o log."""
    d = _demanda_no_gate("aguardando_gate_analise", artefato=None)

    assert revisao.artefato_em_revisao(d) is None
    assert "artefato" not in revisao.payload_de_sync(d)


def test_artefato_gigante_e_cortado_e_avisa(repo):
    gigante = "# Design\n\n" + ("linha de conteúdo\n" * 20_000)
    d = _demanda_no_gate("aguardando_gate_design", "03-design.md", gigante)

    artefato = revisao.artefato_em_revisao(d)

    assert artefato["truncado"] is True
    assert len(artefato["conteudo"]) == revisao.LIMITE_CONTEUDO


def test_payload_nao_contamina_o_status_yaml(repo):
    """`to_dict` é o que vai pro disco. Artefato e perguntas são derivados —
    gravá-los criaria uma segunda cópia do arquivo ao lado, que envelhece."""
    d = _demanda_no_gate("aguardando_gate_analise", "01-analise.md")

    assert "artefato" not in d.to_dict()
    assert "artefato" in revisao.payload_de_sync(d)
