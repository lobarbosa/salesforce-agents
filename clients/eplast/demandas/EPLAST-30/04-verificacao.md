**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-30 · Verificação (dev)

`sf org list` mostrou só `sbx-eplast-dev` (Sandbox, Org Id 00DHa000006vfMLMAY, Connected). Nada foi feito na QA nem em produção. Nenhum registro foi criado, alterado ou apagado, então não há dado de teste a limpar.

## Por que inconclusiva

O critério principal é o comportamento do Screen Flow `Opportunity_Screen_RascunhoComercial`: gerar o rascunho (CA-01 a 03), tratar campo ausente, valor, contato e erro (CA-04 a 10), e o limite de 50 linhas (CA-13). Não consegui exercitá-lo.

- A CLI não executa Screen Flow. Não tenho ferramenta de navegador nesta sessão para abrir a aba "Rascunho IA".
- A dev tem 0 Opportunity (consulta agregada: 0). Exercitar o Flow exigiria massa sintética (conta, oportunidade, cotação primária, linhas, usuários). Sem como abrir a página, esses registros disparariam a cadeia de automação da dev sem provar nada.

Isto não é defeito do build. Nenhum caso executado falhou.

## Evidência do que foi checado (metadata e contagem)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | CA-14 | `SELECT ProcessType, COUNT(Id) FROM Flow WHERE ProcessType='PromptFlow' GROUP BY ProcessType` (dev) | 0 PromptFlow | 0 registros | passou |
| V2 | Flow ativo | Tooling API: `Flow` com `Definition.DeveloperName='Opportunity_Screen_RascunhoComercial'` | versão ativa, tipo Screen Flow | versão 1, `Status=Active`, `ProcessType=Flow` | passou |
| V3 | CA-11/12 (só leitura) | Contagem de `recordCreates`, `recordUpdates` e `recordDeletes` no XML do Flow em `force-app` (branch, não a versão da org) | 0 | 0, 0, 0 | passou (estático, só o arquivo do repositório) |
| V4 | CA-10 | Contagem de `faultConnector` no mesmo XML | caminho de falha nos Get Records e na ação | 7 ocorrências | passou (estático) |
| V5 | CA-13 | Presença de `Decision_Limite` no XML | decisão do limite existe | 3 ocorrências | passou (estático; o comportamento com mais de 50 linhas não foi executado) |
| V6 | Item 11 do plano | `PriorityScore__c`, `PriorityBand__c`, `flowruntime:interview` e `CustomPermission.IA_Rascunho_Comercial` no `Opportunity_Record_Page` em `force-app` | todos presentes | 1, 1, 2 e 1 ocorrências | passou (estático; não conferi a versão implantada na dev, o retrieve passou do tempo) |
| V7 | CA-09 (parcial) | `PermissionSetGroup` `PSG_Comercial_RascunhoIA` na dev | existe e está atualizado | existe, `Status=Updated` | passou (existência; o efeito de visibilidade não foi testado) |
| V8 | Templates | `GenAiPromptTemplate` não é consultável por SOQL | não aplicável | erro "sObject type not supported" | não executado |
| C1 | CA-01 a 03 | Abrir a aba, gerar os 3 tipos, medir tempo, conferir fontes | rascunho em até 15 s com fontes | sem UI | não executado |
| C2 | CA-04/05 | Oportunidade sem `CloseDate` e sem cotação primária | `[dado ausente]`, `sem cotação`, nenhum preço inventado | sem UI | não executado |
| C3 | CA-06 | Valor do texto igual a `SBQQ__NetAmount__c` | igual, com vírgula decimal e moeda | sem UI | não executado |
| C4 | CA-07 | Contato sintético com e-mail e telefone | nada disso no texto | sem UI | não executado |
| C5 | CA-08 | Usuário sem acesso à oportunidade | tela de negativa, modelo não chamado | sem UI | não executado |
| C6 | CA-09 | Usuário sem o PSG | não vê a aba nem roda o Flow | sem UI | não executado |
| C7 | CA-10 | Template desativado | tela de erro, registro não trava | sem UI | não executado |
| C8 | CA-11/12 | Debug log e contagem de Task/Event antes e depois | sem trigger nem Flow gravando; contagens iguais | sem UI | não executado |
| C9 | CA-13 | Cotação com mais de 50 linhas | 50 linhas e "e mais N itens" | sem UI | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer

Tudo o que é comportamento do Flow em execução (C1 a C9). Uma pessoa deve, na `sbx-eplast-dev`, e só com dado sintético com nome começando por `TESTE EPLAST-30`:

1. Criar conta, oportunidade, cotação primária e linhas sintéticas (uma cotação com mais de 50 linhas), e um contato sintético com e-mail e telefone fictícios. Verificar antes se a cadeia de automação da criação chama sistema externo.
2. Atribuir o `PSG_Comercial_RascunhoIA` a um usuário de teste e rodar os casos C1 a C9 pela aba "Rascunho IA", conforme os itens 1 a 9 da seção 7 de `04-plano-build.md`.
3. Conferir que a versão implantada da `Opportunity_Record_Page` na dev mantém `PriorityScore__c` e `PriorityBand__c`.
4. Apagar a massa ao final.

Observação já declarada pelo builder (PB-01): o modelo às vezes escreve "a preencher" sem colchetes. É premissa assumida, não motivo de reprovação.
