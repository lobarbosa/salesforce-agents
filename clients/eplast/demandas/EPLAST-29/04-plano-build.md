**Resultado do build:** bloqueado

> Atualizado na correção da verificação 2 (2026-11-21). O metadata da v18 abaixo continua na branch e na dev, inalterado. O bloqueio é do design: a sequência do tópico (4.3, item 1d) não funciona na plataforma e todas as saídas pedem decisão do arquiteto humano. Ver "Correções da verificação 2" no fim.

# EPLAST-29 · Plano de build (rodada 5: SFAgent2 v18, Flow PrepararTarefa e CriarTarefa v3)

Org de build: `sbx-eplast-dev` (única em `sf org list`, sandbox, Org ID 00DHa000006vfMLMAY). Branch `feature/EPLAST-29`. Nada tocado em produção, QA ou Marketing Cloud. Sem Apex (decisão do design, seção 2). Deploy só na dev, `--test-level NoTestRun`. Nenhum dado lido ou gravado; só deploy de metadata e consultas de status.

Escopo: diretrizes 1 a 4 do responsável (design, seção 13), alternativa C (seção 2). A gravação da Task não mudou de comportamento; mudam a validação (movida para um Flow sem DML), o texto de resumo e de sucesso (vêm do Flow) e a sequência do tópico.

## Base de versões usada
Conferido por query na dev: `SFAgent2` tem v1 a v17; ativa só a v13 (v14 a v17 inativas). Base = **v17** (a mais nova; reúne EPLAST-27, 34, 46 e as correções do 29). Nenhuma outra demanda criou a v18 antes. Flow `Task_Agente_CriarTarefa` na dev: v1 Active, v2 Obsolete; a nova é a **v3**.

## Componentes
| Tipo | API name | Estado na dev | Observação |
|---|---|---|---|
| Flow (novo, sem DML) | `Task_Agente_PrepararTarefa` v1 | **Draft** | Valida na ordem do design 4.1 (parâmetros, registro identificado, existência e tipo, assunto, check-in, prazo, descrição obrigatória e marcador "sem descrição"). Saídas `Pronto`, `Resumo`, `Mensagem`, `RegistroNome`, `RegistroTipo`. Toda recusa termina em "Nada foi criado." Lê só Lead (`Name`, `IsConverted`), Account ou Opportunity (`Name`) e o custom metadata. Descrição em todos os elementos e variáveis |
| Flow (versão nova) | `Task_Agente_CriarTarefa` v3 | **Draft** (v1 segue Active, v2 Obsolete) | Primeiro passo é o subflow `Task_Agente_PrepararTarefa`; `Pronto` falso recusa sem gravar. Com `Pronto`, grava como na v2 (lead em `WhoId`, conta/oportunidade em `WhatId`, `OwnerId = $User.Id`, `Status = Open`, `TaskSubtype = Task`, prioridade e marca de origem do custom metadata, 1 DML, fault path). Mensagem de sucesso montada pelo Flow: `Tarefa criada: "<Assunto>" para <Nome> (<tipo>), prazo <dd/mm/aaaa>, responsável: você.` + `Código da tarefa: <Id>` (+ aviso de rascunho). Mesmas entradas e saídas da v2 |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | alterado | Ganha `flowAccesses` de `Task_Agente_PrepararTarefa`. Sem objeto, campo, perfil nem PS novo. Descrição 237 caracteres |
| GenAiPlannerBundle | `SFAgent2_v18` | criado | Cópia da v17 com sufixo `_v18`; muda só o tópico `acoes_comerciais_EPLAST29_v18` |
| BotVersion | `SFAgent2.v18` | criado, **Inactive** (conferido por query) | Ligada ao planner `SFAgent2_v18` |
| Ação local | `PrepararTarefa_EPLAST29_v18` | criada no tópico | Alvo `Task_Agente_PrepararTarefa`, `isConfirmationRequired = false`; entradas todas opcionais; saídas `Resumo` e `Mensagem` com `isDisplayable = true` |
| Ação local | `CriarTarefa_EPLAST29_v18` | copiada da v17 | `isConfirmationRequired = true` mantido; saída `Mensagem` `isDisplayable = true` com descrição "Repita este texto ao usuário sem alterar" |

### Tópico `acoes_comerciais_EPLAST29_v18` (único com mudança de conteúdo)
- Instrução 1: sequência numerada (a) `IdentificarRegistro` sempre, única exceção o `currentRecordId` de lead/conta/oportunidade; (b) `PrepararTarefa` com o Id; (c) `Pronto` falso repete a `Mensagem` e para; (d) `Pronto` verdadeiro repete o `Resumo` e chama `CriarTarefa` na mesma resposta (o cartão é a confirmação); (e) repete a `Mensagem` do retorno.
- Instrução 4: toda resposta do usuário, inclusive "sim", recomeça em (b); "sim" não é confirmação.
- Instrução 5: o assistente nunca escreve que criou; mensagem de criação sem `Código da tarefa` é proibida.
- Instrução 3: palavras do assunto (contrato, pedido, proposta, reunião) não indicam o tipo do registro (FALHA 7).
- Instruções 2, 6, 7 e 8 mantidas no que importa (data relativa, descrição vazia vai vazia, rascunho só como tarefa, recusas do "não disponível", ambiguidade lista candidatos).

## Conferência de EPLAST-27, 34 e 46 (design 4.3 e seção 5)
Comparação programática dos tópicos v17 × v18 (só com sufixo normalizado): `insights_comerciais`, `agent_router`, `ambiguous_question` e `off_topic` **idênticos**; `insights_comerciais_v18` mantém as 6 ações (`ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`, `ProximaAcaoCliente_EPLAST27`, `ResumoReuniao_EPLAST34`, `SugestaoCampanha_EPLAST46`) e as instruções `instruction2_EPLAST27`, `instruction1_EPLAST34`, `instruction1_EPLAST46`. Só o tópico desta demanda difere.

## Deploy
1. Dry-run dos dois Flows e do PS: Succeeded. Deploy real: Succeeded (Flow novo `Created`, `CriarTarefa` `Changed` como versão nova, PS `Changed`).
2. Agente: `-d` nos arquivos da v18 (`-m Bot:SFAgent2` falha com versão ativa, como nas rodadas anteriores). A primeira tentativa falhou ("Plugin not found") por erro meu na geração do XML (substituição que apagou tópicos do bundle); corrigi regenerando a partir da v17 e o deploy seguinte passou. Nada ficou na org da tentativa falha.
3. Estado conferido por query: BotVersion v13 Active, v14 a v18 Inactive; Flow `CriarTarefa` v1 Active, v2 Obsolete, v3 Draft; `PrepararTarefa` v1 Draft.

## Versões e ativação (passo separado, nada ativado por este build)
| Org | Ordem | Rollback |
|---|---|---|
| dev (verificação) | 1. ativar `Task_Agente_PrepararTarefa` v1; 2. ativar `Task_Agente_CriarTarefa` v3 (o subflow precisa estar ativo); 3. `sf agent activate` da v18 | reativar `CriarTarefa` v1 e a v13 do agente |
| QA (esteira, `05-deploy-qa.md`) | mesma ordem; a v18 substitui a v17 ativa | reativar `CriarTarefa` v5 e a v17 |

Ativar os Flows antes da v18 é seguro: a v17 chama `CriarTarefa` com o mesmo contrato e passa a ganhar a validação e a mensagem novas.

## Pacote da branch
`SFAgent2_v18` e `bots/SFAgent2/v18.botVersion-meta.xml` (v17 e anteriores já estão nas orgs), `Task_Agente_PrepararTarefa`, `Task_Agente_CriarTarefa` (versão nova) e `PS_Comercial_AssistenteAcoes`. Branch `feature/EPLAST-29`; commit e PR registrados na sessão (ver histórico da branch).

## O que não foi provado neste build (para a verificação)
- Nenhum Flow foi executado: estão em Draft e só a versão ativa roda; foram validados pelo deploy (sintaxe, referências, subflow). Verificação precisa ativar na dev (acima) e exercitar os casos críticos 5 de 5, em sessões novas (design, seção 10).
- R3 do design: `isDisplayable = true` pode não garantir exibição literal do texto; o verificador confere o `Código da tarefa` na resposta.
- Fórmulas com acento e aspas escapadas (`\"`) passaram no deploy; o resultado do texto (data dd/mm/aaaa, quebra de linha) só se vê na execução.
- Se o 5 de 5 falhar, o próximo degrau é a alternativa D (variáveis e filtro de ação), levada ao arquiteto humano, não novo reforço de instrução.
- `DescricaoVazia` usa lista fixa de marcadores ("sem descrição", "nenhuma", "nenhum", "n/a", "-", "não"); duplicada nos dois Flows (Preparar e Criar) para a gravação seguir a mesma regra do resumo.

## Premissas assumidas
Nenhuma nova neste build; vale o que o design registra (seção 9).

## Correções da verificação 2
Fonte: `04-verificacao-rodada-2.md` (reprovada; v18 ativada só na dev para a verificação e revertida). Nenhum componente foi alterado nesta sessão: as duas falhas dependem de decisão do design.

| Falha | Situação | Por quê |
|---|---|---|
| FALHA 1 (resumo não aparece antes do cartão, 0 de 5; em 2 de 5 o `Resumo` aparece depois do aceite, junto de "Tarefa criada") | **Não corrigível no build; bloqueia** | Causa provada no trace: `CriarTarefa` tem `isConfirmationRequired = true`, e a plataforma descarta o texto do modelo e gera a legenda do cartão com prompt próprio. O passo 1d do design ("repetir o `Resumo` e, na mesma resposta, chamar `CriarTarefa`") não é executável. Reescrever a instrução não resolve (diretriz 2 do responsável, design 2.1-A) |
| FALHA 2 (Q-1: após "sim", cartão com data de hoje inventada em 3 de 5; nenhuma Task gravada) | **Não alterada; depende da mesma decisão** | Sem dano (0 Task, nenhum "criada" falso). A causa provável é o agente oferecer "hoje" no 1º turno. Corrigir exigiria texto de instrução ou exigir data explícita no Flow, o que a verificação deixa para o arquiteto; vai junto com a nova sequência |

### O que falta e quem responde
Pergunta de design, para o arquiteto humano / responsável da conta (Leonardo Barbosa). Não é pergunta de negócio ao cliente e não se resolve pela org nem pelo padrão (regra 4, caso 3: o aceite de 17/11 diz que, se o 5 de 5 falhar, a alternativa D vai ao responsável, "não reforçar texto"):

1. Como o usuário passa a ver o resumo completo (registro e tipo, responsável, descrição, prazo) antes de confirmar? Opções levantadas pela verificação e pelo design:
   - **(a)** Campo de resumo como entrada de `CriarTarefa` (ou usar os campos que o cartão já mostra), para o texto aparecer dentro do cartão nativo. Muda o contrato da ação, que o design 4.2 manteve igual. Não testado se o cartão mostra o campo de forma legível.
   - **(b)** Tirar `isConfirmationRequired` de `CriarTarefa`: o assistente exibe o `Resumo` e espera a resposta. A confirmação deixa de ser o cartão nativo, contra a decisão de design e o aceite.
   - **(c)** Alternativa D do design (variável do agente e filtro de disponibilidade da ação), formato de metadata ainda não confirmado na org.
2. Q-1: "sim" a uma pergunta sobre data conta como aceitar "hoje"? Se não, o Flow deve exigir a data explícita, ou o tópico deve proibir oferecer "hoje"?

Quando houver resposta, o build corrige sobre a v18 (versão nova, v19, se a v18 já tiver sido ativada em outra org) sem tocar nas versões ativas.

### Estado da dev (conferido por query em 2026-11-21)
`SFAgent2`: v13 Active (conforme o design), v14 a v18 Inactive. `Task_Agente_CriarTarefa`: v1 Active, v2 e v3 Obsolete. `Task_Agente_PrepararTarefa` v1 Obsolete. Ou seja, a verificação reverteu a ativação; para nova verificação é preciso reativar, e as versões Obsolete exigirão nova versão de Flow (Obsolete não volta a Draft).

### Sem prova
Q-8, Q-11, Q-13 e AC-4 seguem sem execução (verificação 2, "Sem prova"); a regressão de EPLAST-27, 34 e 46 só foi conferida por comparação do bundle.
