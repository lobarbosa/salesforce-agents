"""O que faz a demanda andar sozinha do backlog até a sandbox de QA.

Antes deste módulo, cada etapa exigia um humano abrir o GitHub e disparar o
workflow de novo — inclusive entre duas etapas de agente, onde não havia
decisão nenhuma pra tomar. A doutrina pede gate humano nos `aguardando_*`, não
em toda transição; parar nos outros pontos era só falta de mecanismo.

**O que "correr sozinha" significa aqui, exatamente.** No fluxo canônico de
hoje, toda etapa de agente é seguida por um gate humano (analise →
aguardando_gate_analise, build → aguardando_gate_build, e assim por diante;
`release` é a única exceção e o que vem depois dela é `entregue`, terminal).
Ou seja: não existe par de etapas de agente consecutivas pra encadear, e o
laço abaixo roda de fato **uma** etapa por invocação. O que ele automatiza não
é agente→agente, é a borda:

  - agente termina → o status avança sozinho até o gate, e o Squad OS mostra
    que tem gente esperando (sync de volta);
  - humano aprova no card → a próxima sessão dispara sozinha, sem ninguém
    abrir o GitHub.

O laço continua sendo um laço porque essa invariante é da configuração atual,
não da estrutura: o fluxo de sustentação pode reduzir gates, e `demands.py`
pode ganhar etapas. `test_fluxo.py` trava a invariante — se alguém puser duas
etapas de agente em sequência, o teste avisa que este módulo passa a
encadear de verdade.

A regra vive aqui e não no YAML por testabilidade: "o que vem depois do quê" é
a coisa mais fácil de errar no pipeline inteiro e a mais cara quando erra —
etapa pulada é artefato que ninguém produziu com status.yaml jurando que sim.
"""

from __future__ import annotations

from dataclasses import dataclass

from . import ambientes, bloqueio, demands, gates, veredito

# Etapas de execução que acionam uma sessão de agente. As `aguardando_*` são
# gates humanos puros — não rodam nada, esperam gente. `entregue` é terminal.
DISPARA_SESSAO = frozenset({"analise", "design", "build", "qa", "release"})

# Demanda congelada (standby) ou cancelada não roda nada, mesmo disparada —
# por botão, varredura ou disparo duplicado na fila. Sem isto, standby caía
# na regra de triagem abaixo e a análise começava (achado de 2026-10-21).
PARADOS = frozenset({"standby", "cancelada"})

# Onde o build bloqueado volta: o gate em que alguém decide o design e responde
# as pendências. Aprovar de novo ali refaz o build.
GATE_DE_RETORNO_DO_BUILD = "aguardando_gate_design"
PLANO_DE_BUILD = "04-plano-build.md"


def _plano_de_build(d: demands.Demand):
    return d.path / PLANO_DE_BUILD


def _plano_bloqueado(d: demands.Demand) -> bool:
    plano = _plano_de_build(d)
    return plano.exists() and bloqueio.build_bloqueado(plano.read_text(encoding="utf-8"))


# QA que não aprova devolve a demanda para a construção (decisão de
# 2026-11-14, ver veredito.py). O build refeito passa de novo pelo gate de PR
# antes de voltar ao QA, então cada volta tem um humano no meio. O teto existe
# para a conta: depois de MAX_VOLTAS_DO_QA reprovações seguidas, quem decide o
# que fazer é o arquiteto, no gate de design.
ROTEIRO_DE_TESTE = "05-testes.md"
MAX_VOLTAS_DO_QA = 2
GATE_QUANDO_O_QA_NAO_FECHA = "aguardando_gate_design"


def _rodadas_reprovadas(d: demands.Demand) -> int:
    return len(list(d.path.glob("05-testes-rodada-*.md")))


def _arquivar_roteiro_reprovado(d: demands.Demand) -> None:
    """Guarda o roteiro reprovado para o builder ler as falhas e tira o
    `05-testes.md` do caminho: o próximo QA tem de escrever um novo."""
    destino = d.path / f"05-testes-rodada-{_rodadas_reprovadas(d) + 1}.md"
    (d.path / ROTEIRO_DE_TESTE).rename(destino)


# Autor registrado no histórico quando quem avança é o próprio pipeline. Fica
# distinguível de uma transição humana ao ler `status.yaml` depois.
AUTOR_PIPELINE = "pipeline"


class FluxoError(Exception):
    pass


def eh_gate(status: str) -> bool:
    return status.startswith("aguardando_")


def proxima_etapa(status: str) -> str | None:
    """Etapa seguinte no fluxo canônico, ou None se não houver.

    Uma demanda em triagem (backlog/planejada/...) entra na execução pela
    primeira etapa; `entregue` é o fim; qualquer outra avança uma posição.
    """
    if status in demands.STAGES_TRIAGEM:
        return demands.STAGES_EXECUCAO[0]
    if status not in demands.STAGES_EXECUCAO:
        raise FluxoError(f"estágio desconhecido: {status!r}")
    i = demands.STAGES_EXECUCAO.index(status)
    if i + 1 >= len(demands.STAGES_EXECUCAO):
        return None
    return demands.STAGES_EXECUCAO[i + 1]


@dataclass
class Parada:
    """Por que o laço parou — é o que o workflow lê pra decidir o que fazer.

    `motivo` é o contrato com run-demand.yml; mudar um destes valores quebra o
    YAML em silêncio, então eles têm teste.
    """

    motivo: str  # gate | fim | refazer
    etapa: str
    ambiente: str
    etapas_rodadas: tuple[str, ...] = ()

    @property
    def espera_humano(self) -> bool:
        return self.motivo == "gate"

    def as_github_output(self) -> str:
        return "\n".join(
            [
                f"motivo={self.motivo}",
                f"etapa={self.etapa}",
                f"ambiente={self.ambiente}",
                f"espera_humano={'true' if self.espera_humano else 'false'}",
                f"etapas_rodadas={','.join(self.etapas_rodadas)}",
            ]
        )


def aprovar_gate(client: str, demand_id: str, autor: str) -> demands.Demand:
    """Move a demanda do gate humano para a etapa seguinte.

    Recusa se a demanda não estiver num gate: aprovar o que não está esperando
    aprovação seria pular etapa, que é o que a doutrina proíbe.
    """
    d = demands.Demand.load(client, demand_id)
    if not eh_gate(d.status):
        raise FluxoError(
            f"{client}/{demand_id} está em '{d.status}', que não é um gate humano — "
            f"não há o que aprovar."
        )
    prox = proxima_etapa(d.status)
    if prox is None:
        raise FluxoError(f"{client}/{demand_id}: '{d.status}' não tem etapa seguinte.")

    # Registra ANTES de transicionar: o bloco precisa dizer o que estava na mesa
    # no gate, e depois da transição o estágio já é outro. Fica aqui, e não no
    # prompt do agente, porque instrução é ignorável e este é o único rastro do
    # gate bloqueante da doutrina.
    gates.registrar(d, d.status, autor)

    return demands.transition(client, demand_id, prox, autor)


def rodar(
    client: str,
    demand_id: str,
    *,
    executor=None,
    max_etapas: int = 12,
) -> Parada:
    """Roda etapas de agente em sequência até precisar parar.

    Para em duas situações, ambas normais:
      - **gate**: a próxima etapa é aprovação humana. É o ponto da doutrina, e
        na configuração de hoje é sempre por aqui que se sai.
      - **fim**: chegou em `entregue`.

    `executor` existe pra teste — em produção é o orquestrador de verdade. Sem
    ele o módulo não seria testável sem chamar a API da Anthropic.

    `max_etapas` é um cinto de segurança contra laço infinito caso alguém
    quebre a ordem de STAGES_EXECUCAO: o fluxo tem 10 etapas, então 12 nunca é
    atingido por um caminho legítimo.
    """
    if executor is None:  # pragma: no cover - caminho de produção
        from .orchestrator import run_sync as executor

    rodadas: list[str] = []
    d = demands.Demand.load(client, demand_id)

    if d.status in PARADOS:
        return Parada("fim", d.status, ambientes.ambiente_do_estagio(d.status), ())

    # Demanda em triagem entra na execução aqui. Ter sido disparada já é a
    # decisão de executá-la — no Squad OS é o botão "Materializar", que só
    # admin/consultor vê. Esta transição não exige artefato porque a triagem
    # não produz nenhum.
    if d.status in demands.STAGES_TRIAGEM:
        d = demands.transition(client, demand_id, demands.STAGES_EXECUCAO[0], AUTOR_PIPELINE)

    ambiente_do_job = ambientes.ambiente_do_estagio(d.status)

    for _ in range(max_etapas):
        d = demands.Demand.load(client, demand_id)

        if eh_gate(d.status):
            return Parada("gate", d.status, ambiente_do_job, tuple(rodadas))

        if d.status == "entregue":
            return Parada("fim", d.status, ambiente_do_job, tuple(rodadas))

        if d.status not in DISPARA_SESSAO:
            raise FluxoError(
                f"{client}/{demand_id}: estágio '{d.status}' não é gate, não é terminal "
                f"e não dispara sessão — o fluxo não sabe o que fazer com ele."
            )

        # A etapa só roda na org que este job autenticou. Hoje isso nunca
        # diverge — o gate na fronteira dev→qa devolve o controle antes, e o
        # job seguinte abre a credencial certa. Levanta em vez de contornar
        # justamente porque é um estado que o desenho diz não existir: rodar
        # `release` com a credencial de dev entregaria na org errada em
        # silêncio, e ninguém perceberia até o cliente abrir a sandbox.
        if ambientes.ambiente_do_estagio(d.status) != ambiente_do_job:
            raise FluxoError(
                f"{client}/{demand_id}: a etapa '{d.status}' roda em "
                f"'{ambientes.ambiente_do_estagio(d.status)}' mas este job autenticou em "
                f"'{ambiente_do_job}'. Alguém mudou a fronteira de ambiente pra um ponto "
                f"sem gate — o laço precisa devolver o controle ali."
            )

        # Plano de uma rodada anterior que só registrou o bloqueio sai antes de
        # o build rodar de novo: com o arquivo em disco, uma sessão que não
        # reescreve nada passaria como "produziu o artefato" (achado
        # SOMOSAGILITY-22: QA refeito em 4 min sem tocar no roteiro antigo).
        if d.status == "build" and _plano_bloqueado(d):
            _plano_de_build(d).unlink()

        executor(client, demand_id, d.status)
        rodadas.append(d.status)

        # Build que declarou bloqueio não construiu nada: volta ao gate de
        # design em vez de seguir para o gate de build, onde seria aprovado
        # como se houvesse PR para revisar (ver bloqueio.py).
        if d.status == "build" and _plano_bloqueado(d):
            demands.transition(client, demand_id, GATE_DE_RETORNO_DO_BUILD, AUTOR_PIPELINE)
            continue

        # QA só entrega ao cliente o que provou. Sem aprovação com evidência,
        # a demanda volta para a construção — em outro job, porque o build
        # roda na sandbox de dev e este autenticou na de QA.
        if d.status == "qa" and (d.path / ROTEIRO_DE_TESTE).exists():
            v = veredito.ler(
                (d.path / ROTEIRO_DE_TESTE).read_text(encoding="utf-8"),
                ambientes.org_alias(client, "qa"),
            )
            if not v.aprovado:
                voltas = _rodadas_reprovadas(d)
                _arquivar_roteiro_reprovado(d)
                if voltas >= MAX_VOLTAS_DO_QA:
                    demands.transition(client, demand_id, GATE_QUANDO_O_QA_NAO_FECHA, AUTOR_PIPELINE)
                    return Parada("gate", GATE_QUANDO_O_QA_NAO_FECHA, ambiente_do_job, tuple(rodadas))
                demands.transition(client, demand_id, "build", AUTOR_PIPELINE)
                return Parada("refazer", "build", ambiente_do_job, tuple(rodadas))

        prox = proxima_etapa(d.status)
        if prox is None:
            return Parada("fim", d.status, ambiente_do_job, tuple(rodadas))

        # `transition` levanta ArtifactAusenteError se o agente não produziu o
        # artefato da etapa. Não é tratado aqui de propósito: o job tem que
        # falhar vermelho. Um laço que engole isso e segue em frente é
        # exatamente como status.yaml passa a mentir.
        demands.transition(client, demand_id, prox, AUTOR_PIPELINE)

    raise FluxoError(
        f"{client}/{demand_id}: o laço passou de {max_etapas} etapas sem terminar — "
        f"a ordem de STAGES_EXECUCAO provavelmente tem um ciclo."
    )
