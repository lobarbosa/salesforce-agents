**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-30 · Verificação (reverificação do build da rodada 2, opção E)

**Org:** `sf org list` mostrou só `sbx-eplast-dev` (sandbox, conectada; usuário e Org Id omitidos do artefato). Nada foi feito em QA nem em produção.
**Dados:** a dev tem 0 Opportunity, 0 Account e 0 SBQQ__Quote__c (contagem). Nenhum registro foi criado nem alterado; nenhum dado real foi lido. Não houve DML, nem alteração em usuário.

## Por que inconclusiva

O critério principal (Screen Flow `Opportunity_Screen_RascunhoComercial`, aba "Rascunho IA", rodando de ponta a ponta com compartilhamento, permission set e debug log) **não pôde ser exercitado**. Screen Flow só roda pela interface (a CLI e a API REST não o executam) e esta sessão não tem navegador nem usuário de teste com o PSG atribuído. Isso não é defeito do build. O que consegui provar foi a metadata na org e o comportamento do template com texto sintético, sem passar pelo Flow.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | Base | `sf data query` (Tooling) em `FlowDefinition` | Flow de tela ativo; nenhum PromptFlow | `Opportunity_Screen_RascunhoComercial` com `ActiveVersionId` 301Ha000016TlxgIAC; nenhuma linha para `%PromptFlow%` | passou |
| V-02 | Somente leitura / Nada enviado / Nenhuma automação | Retrieve do Flow para pasta temporária (apagada depois) e contagem de elementos | Zero DML, e-mail ou aprovação | 0 `recordCreates`, 0 `recordUpdates`, 0 `recordDeletes`; 3 `actionCalls`, todos `generatePromptResponse`; `processType` Flow; `isAdditionalPermissionRequiredToRun` true; 29 `faultConnector`. Prova estática, não execução | passou (estático) |
| V-03 | Acesso restrito por permission set | Consulta de `PermissionSet` e `PermissionSetGroup`; leitura do XML do PS | PS e PSG existem; só leitura; sem Contact | `PS_Comercial_RascunhoIA` e `PSG_Comercial_RascunhoIA` (status `Updated`); objetos Account, Opportunity, SBQQ__Quote__c e SBQQ__QuoteLine__c só com `allowRead`; Contact só aparece na descrição ("Sem Contact"); custom permission `IA_Rascunho_Comercial` presente | passou (estático) |
| V-04 | Acesso restrito (aba) | Leitura do XML da `Opportunity_Record_Page` na org | Aba "Rascunho IA" com `flowruntime:interview`, visível por custom permission | Aba "Rascunho IA" com `flowruntime:interview` (`flowruntime_interview_rascunhoIA`), visibilidade `{!$Permission.CustomPermission.IA_Rascunho_Comercial}` | passou (estático) |
| V-05 | Ponto 11 do plano | Contagem de `PriorityScore__c` e `PriorityBand__c` no XML da flexipage da org | Campos da outra demanda (EPLAST-26) mantidos | 2 ocorrências; a flexipage não foi alterada por mim | passou |
| V-06 | Depreciação CA-14 | Ver V-01 | 0 PromptFlow | 0 | passou |
| V-07 | Preço sem cotação não é inventado; Dado ausente não vira invenção | POST na API de geração do template `Rascunho_Proposta_Comercial` com texto sintético (`TESTE EPLAST-30`), data de fechamento `[dado ausente: ...]` e cotação `sem cotação` | Preço, desconto, prazo e condição como `[a preencher]`; data não inventada; campos usados e vazios listados | Preço, desconto, prazo e condição `[a preencher]`; data mantida como `[dado ausente: data de fechamento]`; seção "Campos usados / campos vazios" presente; contato como `[nome do contato]`; resposta em 6 s. Observação: o valor 1000,00 BRL passado na entrada não foi citado no texto | passou (template isolado, fora do Flow) |
| V-08 | Proposta (CA-01), Follow-up, Argumentos com fonte, Preço com cotação, Sem dado pessoal (fluxo completo) | Não executado pelo Flow | Texto na aba, em até 15 s, com fonte e valor igual à cotação | Sem execução do Flow | não executado |
| V-09 | Respeito ao compartilhamento | Não executado (exige usuário sintético sem acesso e abrir o Flow) | Tela de negativa; modelo não chamado | Sem execução | não executado |
| V-10 | Falha do serviço não trava o registro | Não executado | Tela de erro, registro editável | Sem execução (há 29 `faultConnector` na metadata) | não executado |
| V-11 | Nenhuma automação disparada (debug log) e contagem de Task/Event | Não executado | Sem trigger nem Flow de gravação no log | Sem execução do Flow; estaticamente não há DML (V-02) | não executado |
| V-12 | Limite de 50 linhas da cotação (CA-13) | Não executado (exige cotação sintética com mais de 50 linhas) | 50 linhas e "e mais N itens" | Sem execução (decisão com limite 50 presente na metadata) | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer

Sem prova de execução (V-08 a V-12): geração dos três tipos pela aba, tempo de 15 s no Flow, valor igual à cotação, compartilhamento, aba oculta sem PSG, tela de erro, debug log sem automação, contagem de Task/Event e limite de 50 linhas.

Quem prova, na `sbx-eplast-dev`:
1. Criar uma Opportunity sintética `TESTE EPLAST-30` com conta e cotação primária (a cadeia de automação de Account e Opportunity dispara na criação; o proprietário pode exigir o campo "ID Usuário Protheus", achado EPLAST-36). Criar uma segunda, sem `CloseDate` e sem cotação, e uma terceira com cotação de mais de 50 linhas.
2. Atribuir o `PSG_Comercial_RascunhoIA` só a um usuário de teste e abrir a aba "Rascunho IA" com o debug log ligado. Gerar os três tipos, medir o tempo e comparar o valor com `SBQQ__NetAmount__c`.
3. Repetir com usuário sem o PSG (aba ausente) e sem acesso à oportunidade (negativa). Forçar erro desativando um template e ver a tela de erro.
4. Conferir que o log não tem trigger nem Flow de gravação, e que Task e Event não mudaram em contagem.

## Observações para o revisor do PR (não são falhas)

- Premissas PB-01 a PB-03 e PD-01 a PD-07 não foram tratadas como motivo de reprovação. A PB-01 (modelo às vezes escreve "a preencher" sem colchetes) não apareceu no teste V-07, mas é variável por natureza.
- PB-03: a aba só existe na `Opportunity_Record_Page`; quem usar a `Opportunity_Record_Page_Three_Column` não a verá.
- A `Opportunity_Record_Page` pode ser alterada também pela EPLAST-26. Antes do release, confirmar que o arquivo implantado parte da versão da org.

## O que pode ter saído da org

Nenhum registro foi criado. A única chamada externa foi ao serviço de geração do Einstein (modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini` do Salesforce) com texto sintético `TESTE EPLAST-30`, sem dado de cliente; nada para desfazer. Nenhum job agendado, nenhum dado de teste ficou na org. A pasta temporária do retrieve foi apagada.
