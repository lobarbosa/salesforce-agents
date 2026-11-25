---
name: agentforce
description: Como desenhar, construir e testar ação e tópico de agente Agentforce sem que o agente afirme o que não fez — regra no Flow e não na instrução, versões acumuladas, e teste pelo efeito. Use em design, build e QA de toda demanda que toca um agente Agentforce (Bot, BotVersion, GenAiPlannerBundle, tópico ou ação).
---

# Agentforce: o que já deu errado e como evitar

Agente Agentforce foi a maior fonte de retrabalho da esteira: duas demandas somaram 12
rodadas de QA (EPLAST-27 e EPLAST-29). Os defeitos se repetem, e nenhum deles se resolve
"reforçando a instrução".

## A regra que organiza o resto

**O modelo apresenta; quem decide e quem grava é o Flow ou a classe.** Tudo o que precisa
ser verdade sempre (validar entrada, escolher o registro, montar o texto da resposta,
gravar) fica na ação. A instrução do tópico só diz quando chamar a ação e que o texto dela
deve ser repetido sem alteração.

Achado EPLAST-29: o agente dizia "criado" sem chamar a ação. Duas rodadas de reforço de
instrução não resolveram; a falha era intermitente. Resolveu quando a validação e o texto
passaram a sair do Flow.

## Design

- **Sequência obrigatória em passos numerados** na instrução do tópico: identificar o
  registro, preparar, confirmar, gravar. Diga que toda resposta do usuário, inclusive "sim"
  e "pode criar", recomeça pelo passo de preparar com os dados da conversa. "Sim" não é
  autorização para pular a ação.
- **Identificar antes de agir.** A ação de identificar o registro é chamada sempre, mesmo
  quando o usuário dá o nome completo. Sem isso, o agente coloca o nome no campo de Id e a
  gravação falha (EPLAST-29, FALHA 7).
- **A saída da ação é o texto da resposta.** Um campo de mensagem exibível, com a descrição
  "repita este texto ao usuário sem alterar". O resumo antes da confirmação também sai da
  ação, não do modelo (EPLAST-29, FALHA 8).
- **A ação diz o que fez.** Devolve um código de resultado e, quando grava, o Id. "Nada foi
  criado" é uma saída possível e explícita.
- **Entrada desconfiada.** O modelo manda o que quiser em qualquer entrada: código no lugar
  de Id, nome no lugar de código (EPLAST-27). A ação valida a forma e trata o resto.
- **Lista fechada.** Se a resposta deve ficar dentro de uma lista de ações, a instrução
  proíbe acrescentar, e o QA testa com perguntas de continuação ("e então, o que faço?"),
  que é onde o agente improvisa (EPLAST-27, rodadas 3 a 5). Se o responsável aceitar o
  resto como limitação conhecida, isso fica escrito no design.
- Não prometa trava que o planner da org não tem. Confirme no recon o tipo de planner e o
  que ele permite (filtro de ação, variável) antes de desenhar em cima disso.

## Build: versões acumuladas

- Nunca altere `BotVersion` nem `GenAiPlannerBundle` existentes. Crie a `vN+1` a partir da
  **última**, e implante inativa.
- **Outras demandas vivem no mesmo agente.** Parta da versão mais nova, não da ativa, e
  confira que as ações e instruções das outras demandas continuam iguais na versão que você
  criou. Nunca duas demandas na mesma versão.
- Nomeie tópico e ação com a demanda e a versão, para o QA saber o que é de quem.
- A assinatura da ação (entradas e saídas) mudou? Então é versão nova do agente. Não
  mudou? Só o Flow ganha versão, e o agente segue.
- No plano, seção "Versões e ativação": versão ativa antes, versão criada, e qual o QA
  deve ativar.

## Teste

- **Ative a versão antes de testar**, na sandbox de QA, com a org alvo explícita no comando,
  e confira `BotVersion.Status`. Versão inativa, ou que nem chegou à QA, respondeu por seis
  falhas críticas. A versão ativa pode ser de outra demanda mais nova que já contém a sua
  ação: nesse caso teste nela e não a desative.
- **Converse pela pré-visualização em passos**, não pelo modo interativo, que exige
  terminal: iniciar a sessão, enviar cada frase, encerrar (`sf agent preview start`, `send`
  e `end`, sempre com `--target-org sbx-<cliente>-qa`).
- **Confira o efeito, não a resposta.** Depois de cada ação, consulte o registro que
  deveria existir. "Criado" na resposta sem registro gravado é falha crítica.
- **Teste a ação direto também**, chamando o Flow com as mesmas entradas. Separa defeito da
  ação de comportamento do modelo, e diz a quem cabe a correção.
- **Varie a redação.** O mesmo pedido com e sem data, com nome parcial, com a confirmação
  em outras palavras, e uma pergunta de continuação. Comportamento de modelo é
  intermitente: repita o caso crítico e registre quantas vezes passou ("1 de 2").
- Só dados de teste. O agente não é testado com conta, pessoa ou valor real.

## Quando o QA reprova

Leia a causa antes de mexer na instrução. Se a falha é o modelo não chamando a ação ou
inventando conteúdo, a correção é levar a regra para a ação. Mais uma frase na instrução é
a correção que já falhou.
