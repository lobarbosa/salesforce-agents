**Resultado do build:** concluído

# EPLAST-29 · Plano de build (rodada 4: Flow v2 e SFAgent2 v16, a partir da v15)

Org de build: `sbx-eplast-dev` (única em `sf org list`, sandbox, Org ID 00DHa000006vfMLMAY). Branch `feature/EPLAST-29`. Nada tocado em produção, QA ou Marketing Cloud. Sem Apex. Deploy só na dev, `--test-level NoTestRun` no agente.

## Base de versões usada
Conferido por query na dev no momento do build: `SFAgent2` tem v1 a v15, ativa só a v13. Base = **v15** (mais nova, reúne ações de EPLAST-27, 34 e 46), baixada da org por retrieve. A v16 é a seguinte; nenhuma outra demanda a criou antes. Flow `Task_Agente_CriarTarefa`: só existia a v1 (Active); a nova é a v2 (Draft). Aviso do preflight sobre EPLAST-27, 34 e 46 tratado: nada delas foi editado (grep: `insights_comerciais_v16` mantém as 6 ações da v15, e os 4 tópicos restantes são cópia sem mudança de conteúdo).

## Componentes
| Tipo | API name | Estado | Observação |
|---|---|---|---|
| CustomObject (custom metadata type) | `AssistenteTarefaSetting__mdt` | criado, deployed na dev | Item C do design (decisão do arquiteto humano, aprovada no gate). Visibilidade Public, com descrição |
| CustomField | `Ativo__c` (Checkbox, padrão true), `PrefixosPermitidos__c` (Text 50), `PrioridadePadrao__c` (Text 20), `DescricaoObrigatoria__c` (Checkbox, padrão false), `MarcaOrigem__c` (Text 80) | criados | Todos com descrição e help text |
| CustomMetadata | `AssistenteTarefaSetting.Padrao` | criado | `Ativo=true`, `001;006;00Q`, `Normal`, `DescricaoObrigatoria=false`, `Origem: assistente de IA` |
| Flow | `Task_Agente_CriarTarefa` **versão 2** | deployed como **Draft** (v1 segue Active, confirmado por query) | Ver abaixo |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | alterado | Ganha `customMetadataTypeAccesses` de `AssistenteTarefaSetting__mdt`. Continua concedendo agente e Flow. Descrição reduzida a 255 caracteres |
| GenAiPlannerBundle | `SFAgent2_v16` | criado, deployed | Cópia da v15 com nomes `_v16`; muda só o tópico `acoes_comerciais_EPLAST29_v16` e o schema da ação `CriarTarefa` |
| BotVersion | `SFAgent2.v16` | criado, **Inactive** | Ligada ao planner `SFAgent2_v16` |
| Fixture | `fixtures/lead.apex` e `fixtures/README.md` | criados e executados na dev | Ver "Dados de teste" |

### Flow v2 (mudanças sobre a v1)
Entradas e saídas iguais às da v1. Início: Get Records do `Padrao` (custom metadata); sem registro, falha do Get ou `Ativo__c = false` recusa com "A criação de tarefas pelo assistente está desligada." Depois, na ordem: assunto vazio, `Check In @`, prefixo (tem de ser 001, 006 ou 00Q **e** estar em `PrefixosPermitidos__c`), data vazia, descrição vazia com `DescricaoObrigatoria__c`. Ramo Lead (`00Q`): Get Records de `Id` e `IsConverted`; não achado devolve a mensagem genérica "Registro não encontrado ou sem acesso."; convertido recusa orientando a pedir na conta ou na oportunidade; senão grava Task com `WhoId` = lead e `WhatId` vazio. Ramo conta e oportunidade: igual à v1 (`WhatId`). Prioridade (`High`/`Normal` aceitos, qualquer outro valor ou vazio vira `PrioridadePadrao__c`) e marca de origem (`MarcaOrigem__c`) vêm dos parâmetros. Mantidos: `OwnerId = $User.Id`, `Status = Open`, `TaskSubtype = Task`, fault path, 1 DML por execução, `DefaultMode`. Todos os elementos e variáveis novos com descrição.

### SFAgent2 v16 (só o tópico `acoes_comerciais`)
Escopo passa a lead, cliente (conta) ou oportunidade; busca com `objectApiName` `Lead`, `Account` ou `Opportunity` conforme o usuário disser, nos três se não disser, listando nome, **tipo** e identificador quando houver mais de um candidato (inclusive mesmo nome em tipos diferentes); resumo de confirmação sempre com registro (nome e tipo), responsável (você), descrição ("sem descrição" quando vazia) e prazo; rascunho de e-mail ou mensagem com pedido de revisão antes de enviar; recusa por regra repassada sem insistir; lista de "não disponível" inclui compromisso. Descrição da ação e schema de `RegistroRelacionadoId` dizem "lead (00Q), conta (001) ou oportunidade (006)". `agentScript/SFAgent2_v16_definition.agent` é cópia byte a byte da v15 (arquivo gerado pela plataforma, não editado).

## Dados de teste
`fixtures/lead.apex` rodou na dev (bypass de trigger ligado): leads sintéticos `REG-TESTE-LEAD-01`, 2x `REG-TESTE-DUP` e `REG-TESTE-LEAD-CONV` (convertido por `Database.convertLead`, sem oportunidade), mais a conta `REG-TESTE-DUP`. Contagem na dev: 4 leads `REG-TESTE%`, 1 convertido. Nenhum dado real lido; só contagens. A conversão cria conta e contato sintéticos a partir do lead de teste.

## Versões e ativação (pendente, passo separado)
Nada foi ativado nesta etapa.
1. Ativar o Flow `Task_Agente_CriarTarefa` v2 na dev antes da verificação (rollback: reativar a v1).
2. Ativar o agente `SFAgent2` v16 na dev (`sf agent activate`) depois do Flow (rollback: reativar a v13).
3. Na QA: ordem do release 46, 27, 34, depois esta; `05-deploy-qa.md` confere os Flows e a classe das outras demandas antes (R2 do design).

## O que o build não provou (fica para a verificação)
- Flow v2 não foi executado: só existe em Draft e a plataforma só roda a versão ativa. Foi validado pelo deploy (sintaxe e referências), não por execução. Q-1, Q-4, Q-10 e Q-11 dependem de ativá-lo.
- R3 (a busca padrão `identifyRecordByName` aceitar `objectApiName = Lead`) não foi exercitada: a v16 está inativa. A verificação exercita com o lead `REG-TESTE-LEAD-01`; se a busca não aceitar Lead, volta ao gate de design (alternativa: Flow de busca de lead), sem improvisar.
- R4 (contexto de execução do Flow com usuário não administrador) e Q-12: não executados.
- `identifyRecordByName` e demais ações de EPLAST-27, 34 e 46 na v16 (Q-13): conferidas só por grep no bundle.

## Notas
- O deploy com `-m Bot:SFAgent2` falha ("não é possível editar uma versão do bot ativa", v13); usado `-d` só nos arquivos da v16. O pacote da branch traz só a v16 (a v15 baixada foi removida do working tree; a v13 e anteriores já estavam no repositório).
- A retrieve do `SFAgent2.bot-meta.xml` só reordenou `contextVariableMappings`; revertido, sem alteração no commit.
