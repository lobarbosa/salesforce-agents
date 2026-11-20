**Verificação:** aprovada
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-26 — Verificação do build (reverificação após o enxugamento de perfis e permission sets)

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected, pelo alias). QA e produção não foram tocadas. Nada foi implantado, nenhum arquivo do build foi alterado e nenhum dado foi criado nesta sessão (os 3 objetos seguem com 0 registros).

Escopo desta rodada: o último commit (1f363461) só mudou perfis e permission sets (68 arquivos, só `fieldPermissions` dos 9 campos). Por isso esta sessão reconferiu metadata e FLS na dev. O comportamento (casos C5 a C12 abaixo) **não foi reexecutado**: o resultado vem da verificação anterior desta mesma demanda (versão em git, commit 1f363461 e anteriores), feita com massa sintética e já apagada. O commit novo não toca campo, layout nem Flow.

Nota sobre os critérios: o `01-analise.md` descreve o problema original (Gherkin com `<N>` pendentes). O design aceito no gate (G1-b, G3 = 32.768) redefiniu a solução para 9 campos novos. Os casos derivam dos critérios (tamanho alvo, recusa de N+1, dado antigo íntegro, automações sem erro, FLS mantida) aplicados a esses campos.

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Campos existem com tamanho alvo | `FieldDefinition` (BluePrint__c, Propostas_de_Solucao__c, FluxoVendaProdutos__c, `PFP_%_Texto__c`) e Tooling `CustomField.Description` | 9 campos LongTextArea 32768 com descrição | 9 registros, todos "Área de texto longo(32768)", Length 32768, descrição preenchida nos 9 | passou (esta sessão) |
| C2 | FLS mantida depois do enxugamento | `SELECT COUNT() FROM FieldPermissions WHERE Field IN (9 campos)` | 573 linhas | 573 linhas (441 com edição; leitura sem edição no FVP, coerente com o plano). Amostra PSL.PFP_1_Texto: 2 permission sets (DiretorComercial, Acesso_completo_Esteira...) e perfis com Read e Edit | passou (esta sessão) |
| C3 | Disco bate com a org (FLS) | Contagem de `<fieldPermissions>` nos 68 arquivos (66 perfis + 2 PS) | 573 | 573 em 66 perfis + 2 PS | passou (esta sessão) |
| C4 | Flow: versão nova existe, anterior não editada | Tooling `Flow` por `Definition.DeveloperName` | v1 e v2 preservadas, v3 com a mudança | v1 Obsolete, v2 Obsolete, v3 Active (Id 301Ha000016vCwQIAU), descrição da versão preenchida. Ver divergência abaixo | passou, com divergência declarada |
| C5 | Baseline com v2 ativa | Verificação anterior: PSL inserida com v2 ativa | Copia só os campos antigos | `PFP_N__c` preenchidos, `PFP_N_Texto__c` nulos | passou (verificação anterior, não reexecutado) |
| C6 | Texto > 255 copiado BluePrint para PSL | Verificação anterior: v3 ativada, PSL atualizada, BluePrint com 618 caracteres | PSL recebe 618 | 618 caracteres na PSL | passou (verificação anterior, não reexecutado) |
| C7 | Dado antigo continua copiado | Verificação anterior | `PFP_N__c` recebe o UNC antigo | Copiado | passou (verificação anterior, não reexecutado) |
| C8 | Não sobrescreve valor antigo digitado | Verificação anterior: PSL nova com `PFP_1__c='MANUAL'` | Permanece `MANUAL` | Permaneceu | passou (verificação anterior, não reexecutado) |
| C9 | Aceita o tamanho alvo | Verificação anterior: FVP com 32.768 caracteres | Salva e lê 32768 | 32768 | passou (verificação anterior, não reexecutado) |
| C10 | Recusa N+1 | Verificação anterior: 32.769 caracteres | `STRING_TOO_LONG` | `STRING_TOO_LONG` | passou (verificação anterior, não reexecutado) |
| C11 | Fórmulas do FVP seguem funcionando | Verificação anterior | Valor antigo continua visível | OK | passou (verificação anterior, não reexecutado) |
| C12 | VRs e automações sem erro | Verificação anterior: DML em Opportunity, BluePrint, PSL, FVP | Sem exceção | Sem exceção | passou (verificação anterior, não reexecutado) |
| C13 | Dados existentes íntegros | Contagem dos 3 objetos na dev | Valor antigo igual depois | 0 registros nos 3 objetos, sem dado para comparar | não executado |

## Divergências entre disco e org
1. O Flow no repositório está com `<status>Draft</status>` (v3). Na dev a v3 está **Active** (a verificação anterior ativou, autorizado no plano) e a v2 está Obsolete. Para a dev voltar ao estado de antes, reative a v2. Na QA a esteira leva a v3 em Draft.
2. Os 68 arquivos de perfil e permission set no repositório são parciais (só os 9 campos), conforme declarado no plano. Não servem de backup do perfil.

## Observações para o revisor (não são falha)
- A descrição dos campos de BluePrint e PSL cita "Flow ... (v2)", mas a versão nova é a v3. Detalhe de texto.
- No Layout de BluePrint o antigo `PFP_1_UNC_Path__c` é Required e o novo entrou como Edit (desvio declarado no plano).
- Limitação herdada do Flow (declarada no plano): PSL com texto novo preenchido e antigo vazio não recebe a cópia do antigo.

## O que pode ter saído da org
Nada criado nesta sessão. Na verificação anterior não foi identificada chamada externa. Os registros de teste foram apagados e não restou massa na dev.

## Sem prova
- C13: sem registro anterior na dev; a integridade de dado existente só se prova na QA e na homologação.
- Os comportamentos C5 a C12 não foram reexecutados nesta sessão (ver escopo acima).
- Deploy contra a QA (o check-only do erro `standard__AdvancedTherapyManagement`) fica para a esteira e o CI do PR. O plano registra 0 ocorrências de `applicationVisibilities` no pacote.
- FLS efetiva para usuário não-admin (só foram conferidas as linhas de `FieldPermissions`).
- Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP) seguem para a homologação.
