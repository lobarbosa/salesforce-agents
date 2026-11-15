**Resultado do build:** concluído

# EPLAST-29 · Plano de build — Ações por linguagem natural no assistente de IA

**Branch:** `feature/EPLAST-29` · **Org de build:** `sbx-eplast-dev` (única org listada por `sf org list`; sandbox) · **Builder:** builder-declarativo
**Base:** `03-design.md` (gate de design aprovado em `gates.md`), `comentarios-do-card.md` (aprovação em lote: conferir no gate de build). Sem Apex. Só metadata e contagens agregadas; nenhum registro foi lido ou criado.

## 1. Componentes criados (deploy em `sbx-eplast-dev`)

| Componente | API name | Deploy | Descrição preenchida |
|---|---|---|---|
| Flow (AutoLaunchedFlow, API 67.0, `DefaultMode`) | `Task_Agente_CriarTarefa` | `0AfHa00000EHtknKAD` — Succeeded | Sim (Flow, variáveis, decisões, formulas, Get e Create) |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | `0AfHa00000EHtknKAD` — Succeeded | Sim (limite de 255 caracteres respeitado) |
| BotVersion | `SFAgent2.v5` | Succeeded (deploy seguinte) | n/a |
| GenAiPlannerBundle | `SFAgent2_v5` | Succeeded | Sim (descrição do tópico e das ações) |
| Tópico local | `acoes_comerciais` (`acoes_comerciais_EPLAST29`) | dentro do bundle v5 | Sim |
| Ações locais do tópico | `IdentificarRegistro` (padrão `identifyRecordByName`, sem confirmação) e `CriarTarefa` (Flow, `isConfirmationRequired = true`) | dentro do bundle v5 | Sim |

Arquivos: `force-app/main/default/flows/Task_Agente_CriarTarefa.flow-meta.xml`, `permissionsets/PS_Comercial_AssistenteAcoes.permissionset-meta.xml`, `bots/SFAgent2/` (baseline v4 retrieve + `v5.botVersion-meta.xml`), `genAiPlannerBundles/SFAgent2_v4/` (baseline, não alterado) e `genAiPlannerBundles/SFAgent2_v5/`.

### Flow `Task_Agente_CriarTarefa`
- Entradas: `Assunto`, `DataVencimento` (Date), `RegistroRelacionadoId`, `Descricao`, `Prioridade`. Saídas: `Sucesso`, `TarefaId`, `Mensagem`. Toda variável com `description` em pt-BR.
- Guardas determinísticas, nesta ordem: (1) assunto vazio; (2) assunto `Check In @` (sem diferenciar maiúsculas, igual ao `StartsWith` do `TaskCreatedOrUpdated`); (3) prefixo do Id diferente de `001`/`006` ou tamanho diferente de 15/18; (4) data vazia; (5) Get Records do Account/Opportunity sem resultado.
- Um único DML (Create Task): `Subject`, `ActivityDate`, `WhatId`, `OwnerId = $User.Id`, `Priority` (`High` só se vier `High`, senão `Normal`), `Status = Open`, `TaskSubtype = Task`, `Description` = texto + `Origem: assistente de IA`. Fault path no Get e no Create devolve mensagem amigável, sem texto técnico.
- Sem trigger: autolaunched; não acrescenta automação record-triggered em Task (assessment #1).

### PS `PS_Comercial_AssistenteAcoes`
- `flowAccesses` = `Task_Agente_CriarTarefa`; `agentAccesses` = `SFAgent2`. Sem objeto nem campo. Confirmado no org por contagem agregada de `SetupEntityAccess` do PS: 1 `FlowDefinition` + 1 `BotDefinition`. **Resolve R7 (sintaxe de acesso a agente em PS): existe por metadata, não vira passo manual.**
- Nenhum perfil alterado. Nenhuma atribuição de PS feita (por usuário, passo da verificação/homologação).

### Agente `SFAgent2` v5
- v5 = cópia da v4 como estava na org + tópico `acoes_comerciais` + transição `go_to_acoes_comerciais` no `agent_router`. `insights_comerciais` copiado sem mudança. v4 intacta (rollback).
- Fonte de verdade do agente é o Agent Script (`agentScript/SFAgent2_v5_definition.agent`, base64 no bundle). Retrieve de volta do v5 devolveu o script idêntico ao enviado.
- Instruções do tópico seguem a seção 3.2 do design: só Task, uma por confirmação; registro pela página atual ou `IdentificarRegistro`, lista candidatos se houver mais de um; data absoluta; resumo antes de `CriarTarefa`; rascunho de e-mail/mensagem como Task `Rascunho de e-mail - <tema>` / `Rascunho de mensagem - <tema>`, informando que o envio é fora do CRM (Marketing Cloud ou canal do vendedor); recusa de outros objetos, tarefa para terceiros, check-in e envio.
- **Ativada** em `sbx-eplast-dev` (`sf agent activate`): v5 `Active`, v1 a v4 `Inactive`.

## 2. Desvios do design (a confirmar no gate de build)

1. **A v4 da org tem 4 ações em `insights_comerciais`, não 3.** Além de `ConsultarPedidos`, `AgregacaoPedidos` e `IdentificarConta`, há `ProximaAcaoCliente` (Flow `Account_Agente_ProximaAcao`, ativo na dev, vindo da EPLAST-27, que está em `backlog`) e, no script, várias ações-alias (`IdentificarUsuario`, `ConsultarOportunidadesConta` etc.). A v5 copia tudo como a v4 estava (AC-9 preservado, "mesma leitura que a v4"). **Isso corrige R7**: já existe uma ação de Flow na org; o Flow `Account_Agente_ProximaAcao` e a EPLAST-27 não foram tocados nem entram neste PR (o bundle v5 só referencia o Flow). Consequência: o deploy da v5 em outra org depende de `Account_Agente_ProximaAcao` já existir lá.
2. **Nomes de tópicos e ações copiados ganharam sufixo `_v5`** (`insights_comerciais_1790e90ae9fbdc8_v5` etc.). Os `GenAiPlugin`/`GenAiFunction` são globais na org e o deploy com os mesmos nomes da v4 falhou por duplicidade. O `localDeveloperName` e o script não mudam.
3. **Graph do agente (`agentGraph/*_graph.json`) não foi gerado para a v5.** É artefato derivado; o da v4 já estava defasado em relação ao script (sem `ProximaAcaoCliente`). A org aceitou a v5 só com o script e o XML. Quem abrir a v5 no Agent Builder deve conferir que o tópico `acoes_comerciais` aparece.
4. **Mensagens do Flow sem acentuação** (texto ASCII), por segurança de encoding; só o texto que o agente repassa. Pode ser ajustado sem mudar a lógica.
5. `deploy validate` com RunLocalTests falhou por testes Apex pré-existentes da org (70 de 79, ex.: `CompanyDocument__c` e duplicidade de conta); não tem relação com esta demanda (sem Apex alterado) e confirma o assessment #2. O deploy em sandbox foi feito sem testes (padrão da sandbox).

## 3. O que foi provado no build (somente guardas, sem DML)

Chamada REST do Flow em `sbx-eplast-dev` (`/actions/custom/flow/Task_Agente_CriarTarefa`), com usuário da sessão de deploy:

| Caso | Resultado |
|---|---|
| Assunto em branco | `Sucesso=false`, "Informe o assunto da tarefa." |
| Assunto `check in @ visita` (minúsculas) | `Sucesso=false`, recusa de check-in (guarda 2 fecha a cascata Task -> Account) |
| Id com prefixo `801` | `Sucesso=false`, recusa de objeto |
| Sem data | `Sucesso=false`, pede a data |
| Conta inexistente (`001...AAA`) | `Sucesso=false`, "Registro nao encontrado ou sem acesso." |

`SELECT COUNT() FROM Task` = 0 depois dos 5 casos (nenhuma Task criada). A verificação reconhece como **não exercitado no build**: caminho de sucesso (Account e Opportunity sintéticas), AC-4 com usuário sem acesso (R5: `DefaultMode` x contexto do agente), debug log sem DML em Account, e toda a parte conversacional (AC-1 a AC-9).

## 4. Pendências para a verificação (não são perguntas de negócio)

- **Dado sintético (PD-9) não criado.** R8 exige antes conferir se o callout `Protheus*` da sandbox aponta para ambiente não produtivo (0 `NamedCredential`; endpoint não verificado). Sem essa checagem não criei `REG-TESTE-01`/`REG-TESTE-DUP`.
- **Licença de Agentforce** a atribuir ao usuário de teste (0 atribuídas hoje; R9) e atribuição de `PS_Comercial_AssistenteAcoes` ao usuário de teste do perfil `Comercial - Analista`. Passo de administração, não metadata. Sem isso, a verificação conversacional fica `inconclusiva`.
- Se o contexto do Flow chamado pelo agente for de sistema (R5), trocar `runInMode` para `SystemModeWithSharing` e manter o PS restrito.
- Nenhuma ação no Marketing Cloud ou no conector `et4ae5`. Nenhum campo, objeto ou perfil alterado.

## 5. Premissas assumidas do design aplicadas (sem pendência)

P1–P13 e PD-1 a PD-10 construídas como no design: Account e Opportunity (PD-1); check-in recusado (PD-2); rascunho como Task `Open`, `TaskSubtype = Task` (PD-3); responsável = quem pede (PD-4); assunto, registro e vencimento obrigatórios, prioridade `Normal` e status `Open` por padrão (PD-5); PS novo com agente + Flow (PD-6); v5 ativa e v4 de rollback (PD-7); `DefaultMode` (PD-8, a provar na verificação); uma tarefa por confirmação (PD-10). PD-9 depende da checagem do R8 acima.
