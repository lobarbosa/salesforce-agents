"""A sessão de agente não pode terminar em promessa.

Estes testes existem por causa de um incidente com data: no primeiro assessment
de uma org Salesforce de verdade (Konecta, 2026-09-13), o agente encerrou a
sessão dizendo que o trabalho seguia "em background" e que avisaria quando os
artefatos estivessem prontos. Não havia background nenhum — a sessão era a única
execução, o processo morreu naquela frase, e `assessment.json` nunca existiu.
Do lado de quem esperava, a tela não mudou.

O que é protegido aqui não é o texto do prompt, é o mecanismo: enquanto a sessão
está aberta, o disco é conferido e o agente é cobrado; e quando nem a cobrança
resolve, o processo falha alto em vez de deixar passar.

O SDK não está instalado no ambiente de teste (de propósito — ver o import
tardio em `sessao.rodar`), então o cliente é dublado aqui. O dublê é fiel ao
que importa: um `query` por turno, uma resposta drenada por turno, e efeitos no
disco acontecendo (ou não) entre um turno e o outro.
"""

from __future__ import annotations

import asyncio
import sys
import types
from pathlib import Path

import pytest

from salesforce_agents import sessao


# --- dublê do Claude Agent SDK ------------------------------------------------


class _TextBlock:
    def __init__(self, text: str) -> None:
        self.text = text


class _AssistantMessage:
    def __init__(self, content: list) -> None:
        self.content = content


class _ResultMessage:
    def __init__(self, custo: float = 0.01) -> None:
        self.total_cost_usd = custo


class _ClienteDublado:
    """Roda um roteiro: para cada turno, o que o agente diz e o que ele grava.

    `roteiro` é uma lista de callables — um por turno, recebendo o número do
    turno. O retorno é o texto que o agente "responde"; o efeito colateral (ou a
    ausência dele) é o que aparece no disco.
    """

    roteiro: list = []
    pedidos: list[str] = []
    turnos: int = 0

    def __init__(self, options=None) -> None:
        self.options = options

    async def __aenter__(self):
        return self

    async def __aexit__(self, *_) -> bool:
        return False

    async def query(self, prompt: str) -> None:
        type(self).pedidos.append(prompt)

    async def receive_response(self):
        turno = type(self).turnos
        type(self).turnos += 1
        acao = type(self).roteiro[min(turno, len(type(self).roteiro) - 1)]
        texto = acao(turno)
        yield _AssistantMessage([_TextBlock(texto)])
        yield _ResultMessage()


@pytest.fixture
def sdk_dublado(monkeypatch):
    """Instala o dublê como `claude_agent_sdk` para o import tardio encontrar."""
    modulo = types.ModuleType("claude_agent_sdk")
    modulo.AssistantMessage = _AssistantMessage
    modulo.TextBlock = _TextBlock
    modulo.ResultMessage = _ResultMessage
    modulo.ClaudeSDKClient = _ClienteDublado
    monkeypatch.setitem(sys.modules, "claude_agent_sdk", modulo)

    _ClienteDublado.roteiro = []
    _ClienteDublado.pedidos = []
    _ClienteDublado.turnos = 0
    return _ClienteDublado


def _rodar(alvo: Path, **kwargs):
    """Roda a sessão com `conferir` olhando um arquivo só."""
    return asyncio.run(
        sessao.rodar(
            object(),
            "faça o trabalho",
            conferir=lambda: sessao.faltantes([alvo]),
            **kwargs,
        )
    )


# --- comportamento ------------------------------------------------------------


def test_entrega_de_primeira_nao_cobra_nada(sdk_dublado, tmp_path):
    """Quem entregou não é importunado: um turno, uma cobrança nenhuma."""
    alvo = tmp_path / "assessment.json"

    def grava(_turno: int) -> str:
        alvo.write_text("{}", encoding="utf-8")
        return "pronto, gravei"

    sdk_dublado.roteiro = [grava]

    _rodar(alvo)

    assert sdk_dublado.turnos == 1
    assert len(sdk_dublado.pedidos) == 1


def test_agente_que_promete_em_vez_de_entregar_e_cobrado_na_mesma_sessao(
    sdk_dublado, tmp_path
):
    """A regressão do incidente de 2026-09-13, ao pé da letra.

    Turno 1 responde exatamente o que o agente respondeu naquele run — que está
    rodando em background e avisa depois — sem gravar nada. Antes desta
    correção, a sessão terminava aqui e o job morria sem artefato. Agora o turno
    2 acontece, e é nele que o arquivo aparece.
    """
    alvo = tmp_path / "assessment.json"

    def promete(_turno: int) -> str:
        return (
            "O assessment está rodando em background via subagente `org-assessment`. "
            "Vou avisar assim que os artefatos estiverem prontos."
        )

    def cumpre(_turno: int) -> str:
        alvo.write_text("{}", encoding="utf-8")
        return "gravado"

    sdk_dublado.roteiro = [promete, cumpre]

    _rodar(alvo)

    assert sdk_dublado.turnos == 2, "a sessão aceitou a promessa e encerrou"
    cobranca = sdk_dublado.pedidos[1]
    assert str(alvo) in cobranca, "a cobrança não diz qual arquivo falta"
    assert "não existe turno seguinte" in cobranca.lower()


def test_sem_artefato_ate_o_fim_o_processo_falha_alto(sdk_dublado, tmp_path):
    """Cobrar não é insistir para sempre: esgotou, fica vermelho.

    O contrário — encerrar em silêncio depois de tentar — é o comportamento que
    deixaria `status.yaml` (ou o perfil do cliente) declarando etapa que não
    aconteceu. Guardrail #5 do CLAUDE.md, um passo antes.
    """
    alvo = tmp_path / "assessment.json"
    sdk_dublado.roteiro = [lambda _t: "já já eu mando"]

    with pytest.raises(sessao.ArtefatoNaoProduzidoError) as exc:
        _rodar(alvo)

    assert sdk_dublado.turnos == sessao.MAX_TENTATIVAS
    assert str(alvo) in str(exc.value)


def test_todo_turno_entra_na_telemetria_de_custo(sdk_dublado, tmp_path):
    """Contar só o primeiro turno faria o custo mentir por baixo justamente nos
    ciclos caros — e "esta etapa precisou de três turnos" é sinal, não ruído."""
    alvo = tmp_path / "assessment.json"
    sdk_dublado.roteiro = [lambda _t: "nada ainda"]
    registrados: list[float] = []

    with pytest.raises(sessao.ArtefatoNaoProduzidoError):
        _rodar(alvo, ao_terminar=lambda m: registrados.append(m.total_cost_usd))

    assert len(registrados) == sessao.MAX_TENTATIVAS


def test_conferir_cobra_artefato_invalido_e_nao_so_ausente(sdk_dublado, tmp_path):
    """`conferir` é callable, e não lista de caminhos, exatamente por isto: um
    `assessment.json` presente e malformado é tão inútil quanto ausente, e dá
    para cobrar enquanto o agente ainda está na linha."""
    alvo = tmp_path / "assessment.json"

    def escreve_lixo(_turno: int) -> str:
        alvo.write_text("isto não é json", encoding="utf-8")
        return "pronto"

    def escreve_valido(_turno: int) -> str:
        alvo.write_text('{"saude": "verde"}', encoding="utf-8")
        return "agora vai"

    sdk_dublado.roteiro = [escreve_lixo, escreve_valido]

    def conferir() -> list[str]:
        import json

        if not alvo.exists():
            return [f"{alvo} não existe"]
        try:
            json.loads(alvo.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            return [f"{alvo} não é JSON válido: {exc}"]
        return []

    asyncio.run(sessao.rodar(object(), "faça", conferir=conferir))

    assert sdk_dublado.turnos == 2
    assert "não é JSON válido" in sdk_dublado.pedidos[1]


# --- o texto da cobrança ------------------------------------------------------


def test_cobranca_fecha_as_saidas_de_emergencia():
    """As três frases com que um modelo encerra sem entregar precisam estar
    explicitamente fechadas — é isso que a cobrança faz de diferente de só
    repetir o pedido."""
    texto = sessao.cobranca(["clients/acxya/assessment.json"], 2, 3)

    assert "background" in texto, "não fecha a saída de delegar pro nada"
    assert "não peça confirmação" in texto.lower(), "não fecha a saída de pedir aval"
    assert "avisa quando terminar" in texto, "não fecha a saída de adiar"


def test_cobranca_nao_convida_a_inventar():
    """Pressionar por arquivo é pressionar por invenção, e inventar é a única
    coisa pior que não entregar: o assessment vira número falso no perfil do
    cliente, e ninguém tem como saber. A cobrança tem que dizer, no mesmo
    fôlego, que 'não consegui medir' é resposta aceita."""
    texto = sessao.cobranca(["clients/acxya/assessment.json"], 2, 3)

    assert "não consegui medir" in texto
    assert "inventad" in texto or "inventar" in texto


def test_faltantes_lista_so_o_que_nao_existe(tmp_path):
    existe = tmp_path / "tem.md"
    existe.write_text("oi", encoding="utf-8")
    sumido = tmp_path / "nao-tem.json"

    assert sessao.faltantes([existe, sumido]) == [str(sumido)]
