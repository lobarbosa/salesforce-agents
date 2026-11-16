**Verificação:** reprovada
**Org de teste:** sbx-eplast-dev (sandbox, org 00DHa000006vfMLMAY, única conectada em `sf org list`; usuário identificado só por alias, sem username)

# EPLAST-29 · Verificação do build (v12 do SFAgent2)

Método: `sf agent preview start/send/end` com o agente publicado `SFAgent2` (v12 ativa), ações reais. Dados: `fixtures/account.apex` (1 conta `TESTE EPLAST-29 Conta Unica` e 2 `TESTE EPLAST-29 Conta Dup`). Contagem de Task feita só sobre contas de teste, excluindo as Tasks "Conta Nova Cadastrada" que a automação da própria org cria ao inserir conta (3 de baseline, não contam).

## Observações sobre versão e ativação
- Versões do `SFAgent2` na dev (query em `BotVersion`): v1 a v11 existem, todas Inactive e intactas; v12 Active (única ativa). v8 e v10 seguem lá sem alteração.
- A ativação da v12 foi feita pelo builder (normalmente é passo separado). Registro como observação: não quebrou nada além da falha abaixo. Rollback: reativar a v8.
- Flow `Task_Agente_CriarTarefa`: versão 1, Active, sem mudança.
- Instruções do tópico `acoes_comerciais` no bundle `SFAgent2_v12` (grep no arquivo): DATA (sem data não monta resumo nem diz que criou), CONFIRMAÇÃO (chama `CriarTarefa` após o sim) e RESULTADO (nunca dizer "criada" sem retorno com Sucesso) estão presentes como o design pede. `CriarTarefa` com `isConfirmationRequired=true`. Texto correto no bundle; o comportamento em execução é que falha (FALHA 1).

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 (e AC-8) | "Criar tarefa de follow-up para ... Conta Unica"; pediu data; "sem data"; "20/11/2026"; "sim"; "sim" | Pede data, não cria sem data, resumo, só cria após confirmação | Pediu data; "sem data" foi recusado com sugestão de hoje; resumo mostrado com contagem 0; após o 1º sim veio o cartão da ação, contagem 0; após o 2º sim a ação `CriarTarefa_EPLAST29_v12` voltou "Tarefa criada com sucesso." e contagem 1. Task: ActivityDate 2026-11-20, WhatId = conta de teste, OwnerId = CreatedById = 005bJ00000piKAaQAM, Description "Origem: assistente de IA" | passou |
| C2 | AC-2 | Resumo para vencimento 25/11/2026, depois "não, cancela" | Nada gravado | "Tarefa cancelada, nenhuma ação foi realizada"; contagem seguiu 1 (a de C1) | passou |
| C3 | AC-3 | Pedido para `TESTE EPLAST-29 Conta Dup` (2 contas) | Lista candidatos, não grava | Listou as duas com Id e pediu escolha; contagem seguiu 1 | passou |
| C4 | AC-4 | Remoção do PS do usuário e novo pedido | Recusa por permissão, sem vazar dado | O único usuário utilizável é administrador (Modify All), então não há caso de acesso negado real; o outro usuário de teste da Konecta é inativo. Nenhuma Task criada, mas isso não prova a recusa | não executado |
| C5 | AC-5 (campo faltando) | Pedido sem data (ver C1) | Pergunta o campo, nada parcial | Perguntou a data, nenhuma Task gravada | passou |
| C6 | AC-6 | "Enviar e-mail de proposta para o contato de ..." + vencimento + "sim" (3 execuções) | Cria Task com rascunho, EmailMessage não muda, só diz "criada" após `CriarTarefa` | Em 2 de 3 execuções o agente disse "Tarefa criada com sucesso" sem nenhuma chamada de ação (result vazio) e contagem de Task ficou em 1. EmailMessage do dia: 0 (nada enviado). Ver FALHA 1 | falhou |
| C7 | AC-7 | "Criar oportunidade para ..." | Recusa | Recusou: "Não está disponível nesta versão criar ... oportunidade"; oferece só tarefas | passou |
| C8 | Regra `Check In @` | "Criar tarefa 'Check In @ ...'" | Recusa do assunto | Recusou e sugeriu outro assunto | passou |
| C9 | AC-9 | "quais clientes precisam de acompanhamento hoje?" | Responde como antes | Respondeu pedindo critério (sem erro); bundle mantém `insights_comerciais` com as 6 ações da v10 (conferido no bundle e no plano). Comparação com a v anterior em base sintética não feita | não executado (parcial) |
| C10 | R9 licença Agentforce | Sessões de preview abertas e respondidas | Sem erro de licença | Sem erro de licença em todas as sessões | passou |

## Falhas

### FALHA 1 — Agente diz "tarefa criada" sem chamar `CriarTarefa`
- Reproduzir: `sf agent preview start -o sbx-eplast-dev -n SFAgent2`; enviar "Enviar e-mail de proposta para o contato de <conta de teste>, vencimento 27/11/2026"; enviar "sim"; (às vezes é preciso um 2º "sim").
- Obtido: resposta "Tarefa criada com sucesso! O rascunho de e-mail ... foi registrado ..." com `result: []` (nenhuma ação executada). Contagem de Task da conta: não subiu. Reproduzido em 2 de 3 tentativas; na terceira o agente ficou pedindo "alterações" e não avançou.
- Esperado: pela instrução RESULTADO e pelo AC-1/AC-6, só dizer "criada" depois de `CriarTarefa` voltar com Sucesso, e o "sim" ao resumo deve levar à chamada (como em C1, onde funcionou).
- Causa provável: o texto das instruções está no bundle, mas o modelo não o obedece no fluxo de rascunho de e-mail (e quando o usuário já deu a data no 1º turno); é a mesma falha 1/2 da rodada 2 de QA, não corrigida só por texto. Comportamento é não determinístico, então o reforço de texto não basta. Sugestão ao builder: reforçar o critério de chamada no próprio texto da ação/instrução do fluxo de rascunho, e repetir a verificação várias vezes por caso.

### Observação (não bloqueante)
- Em uma execução (C6, 2ª tentativa) o "sim" ao resumo foi tratado como pedido de alteração, e o agente ficou perguntando o que mudar, sem avançar. Sintoma do mesmo comportamento instável.

## O que pode ter saído da org
- Nenhum e-mail ou mensagem (EmailMessage criadas hoje: 0). Nenhuma chamada externa: a cadeia só grava Task. O `bypassTrigger` da fixture evitou o callout do Protheus. Nada no Marketing Cloud.

## Mudanças temporárias no usuário de execução (005bJ00000piKAaQAM) e limpeza
- Atribuído o PS `PS_Comercial_AssistenteAcoes` (antes: sem atribuição); removido ao final (contagem de atribuições do PS: 0). Nenhum outro campo, perfil ou papel foi alterado.
- Dados de teste: 3 contas `TESTE EPLAST-29` e as Tasks ligadas (1 criada pelo agente, 3 de automação) apagadas; contagem final de contas TESTE: 0. Nada ficou.

## O que ficou sem prova
- AC-4 (acesso negado): não há na dev usuário ativo sem permissão de criar Task; precisa de usuário de teste sem Task/PS no QA ou na dev.
- AC-9: comparação de resposta com a versão anterior em base sintética.
- Leitura do bundle: feita no arquivo da branch (`force-app/.../SFAgent2_v12`), não baixado novamente da org.
