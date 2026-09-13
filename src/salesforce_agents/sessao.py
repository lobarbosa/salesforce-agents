"""Uma sessão de agente é um tiro só — e tem que terminar com artefato no disco.

O processo que roda aqui vive dentro de um job de CI: manda um prompt, drena a
resposta, encerra. Não existe turno seguinte, ninguém está lendo o chat do outro
lado, e o agente não tem como "avisar depois". O modelo não sabe disso por
padrão — ele conversa como se conversa, e conversa admite "já volto".

Achado real (Konecta, 2026-09-13, run 34769410038): o assessment da primeira org
realmente conectada terminou com o agente dizendo

    "O assessment está rodando em background via subagente `org-assessment` [...]
     Vou avisar assim que os artefatos estiverem prontos."

Ninguém foi avisado. A sessão fechou nessa frase, `assessment.json` nunca
existiu, e o job morreu trinta segundos depois no `AssessmentError` — com o
contexto carregado (e pago, e cacheado) já descartado. Do lado de quem esperava,
a tela não mudou: "ainda não avaliada", idêntico a nunca ter tentado.

O conserto é cobrar enquanto a sessão ainda está aberta. Conferir disco custa
zero, o contexto ainda está lá, e é a única janela em que dizer "não existe
depois" ainda serve para alguma coisa. Falhar continua sendo o fim da linha
(guardrail #5) — o que muda é falhar **depois** de cobrar, não antes.
"""

from __future__ import annotations

from collections.abc import Callable, Iterable, Sequence
from pathlib import Path

# Três no total: a primeira tentativa e mais duas cobranças. O teto existe
# porque um agente que ignorou duas cobranças explícitas não está a uma
# terceira de entregar — está com um problema que uma pessoa precisa ver. O job
# vermelho com a lista do que falta informa mais do que a quarta tentativa.
MAX_TENTATIVAS = 3

# Vai no fim do prompt inicial de quem usa este módulo. O texto mora aqui, e não
# copiado em cada chamador, porque é a regra da casa sobre o que é uma sessão —
# não um detalhe de uma etapa específica.
CONTRATO_DA_SESSAO = (
    "Esta sessão é a única execução que vai acontecer: ela roda dentro de um job de CI "
    "e termina no instante em que você parar de responder. Não existe turno seguinte, "
    "não existe trabalho continuando em background depois que você encerrar, e não há "
    "ninguém do outro lado para receber um aviso posterior. Se você encerrar antes de os "
    "arquivos existirem no disco, eles não vão passar a existir sozinhos: o job falha e "
    "ninguém recebe nada. Só encerre depois de confirmar, lendo o disco, que gravou o que "
    "foi pedido."
)


class ArtefatoNaoProduzidoError(RuntimeError):
    """A sessão encerrou sem gravar o que a etapa deveria ter gravado.

    Sobe para o chamador virar job vermelho. É o mesmo princípio do
    `ArtifactAusenteError` de `demands.py`, um passo antes: lá o estado é
    impedido de mentir, aqui a sessão é impedida de terminar em promessa.
    """


def faltantes(caminhos: Iterable[Path]) -> list[str]:
    """Quais dos artefatos esperados não estão no disco, pelo nome que o agente usaria."""
    return [str(caminho) for caminho in caminhos if not caminho.exists()]


def cobranca(pendencias: Sequence[str], tentativa: int, total: int) -> str:
    """O texto que recobra o agente dentro da sessão que ainda está aberta.

    Fecha as três saídas que um modelo usa para encerrar sem entregar: adiar
    ("depois eu mando"), delegar para um background que não existe, e pedir
    confirmação que ninguém vai dar. E fecha a quarta, que este próprio texto
    abriria se ficasse calado: pressionar por arquivo é pressionar por invenção,
    então diz explicitamente que "não consegui medir" é resposta aceita e número
    inventado não é.
    """
    lista = "\n".join(f"  - {p}" for p in pendencias)
    return (
        f"Parei antes de encerrar porque o que você deveria ter produzido não está no "
        f"disco (tentativa {tentativa} de {total}):\n\n{lista}\n\n"
        f"{CONTRATO_DA_SESSAO}\n\n"
        "Então: produza os arquivos agora, nesta resposta, usando Write. Não responda que "
        "vai fazer, que está fazendo, ou que avisa quando terminar — nenhuma dessas frases "
        "chega a ninguém. Não peça confirmação para seguir: já está confirmado.\n\n"
        "Se algum comando falhou e por isso você não tem um dado, isso **não** impede a "
        "entrega: registre no relatório o que você não conseguiu medir e por quê, e siga "
        "com o que deu para medir. Um 'não consegui medir a cobertura de teste porque o "
        "comando X falhou com Y' é conteúdo válido e esperado. Número inventado para "
        "preencher campo, não — continua valendo a regra de não inventar nada que você não "
        "mediu."
    )


async def rodar(
    options,
    prompt: str,
    *,
    conferir: Callable[[], list[str]],
    ao_terminar: Callable[[object], None] | None = None,
    escrever: Callable[[str], None] = print,
    tentativas: int = MAX_TENTATIVAS,
) -> None:
    """Roda a sessão e só volta quando `conferir()` não achar mais pendência.

    `conferir` devolve a lista de pendências em linguagem de quem vai ler o log
    (arquivo que falta, JSON malformado, campo obrigatório vazio) — lista vazia
    significa entregue. É um callable, e não uma lista de caminhos, porque
    "existe no disco" nem sempre é o critério: um `assessment.json` presente mas
    inválido é tão inútil quanto ausente, e também dá para cobrar em sessão.

    `ao_terminar` recebe o ResultMessage de **cada** turno, incluindo os de
    cobrança. Contar só o primeiro faria a telemetria de custo mentir por baixo
    justamente nos ciclos que custaram mais caro — e "esta etapa precisou de três
    turnos" é, ela mesma, o sinal de que algo naquele agente merece atenção.
    """
    # Import tardio, mesma disciplina de `orchestrator` e `assessment`: o SDK só
    # é necessário para rodar de verdade, e as funções puras acima precisam ser
    # testáveis sem ele instalado.
    from claude_agent_sdk import (
        AssistantMessage,
        ClaudeSDKClient,
        ResultMessage,
        TextBlock,
    )

    async with ClaudeSDKClient(options=options) as sdk:
        pedido = prompt
        for tentativa in range(1, tentativas + 1):
            await sdk.query(pedido)
            async for message in sdk.receive_response():
                if isinstance(message, AssistantMessage):
                    for block in message.content:
                        if isinstance(block, TextBlock):
                            escrever(block.text)
                elif isinstance(message, ResultMessage):
                    if ao_terminar is not None:
                        ao_terminar(message)

            pendencias = conferir()
            if not pendencias:
                return

            if tentativa < tentativas:
                escrever(
                    f"\n--- o agente encerrou sem produzir {', '.join(pendencias)}; "
                    f"cobrando na mesma sessão (turno {tentativa + 1} de {tentativas}) ---"
                )
                pedido = cobranca(pendencias, tentativa + 1, tentativas)

    raise ArtefatoNaoProduzidoError(
        f"a sessão encerrou {tentativas} vezes sem produzir: {', '.join(conferir())}. "
        f"O agente foi cobrado a cada turno e ainda assim não gravou — não é falta de "
        f"instrução, é algo que precisa de olho humano no log acima."
    )
