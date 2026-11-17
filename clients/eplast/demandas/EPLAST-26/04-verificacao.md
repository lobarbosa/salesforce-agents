**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-26 — Verificação do build (rodada 3: critérios e faixas AA/A/B/C/D)

- Org conferida com `sf org list`: `sbx-eplast-dev` (Sandbox, Connected; usuário de conexão omitido). Nada feito na QA nem em produção.
- Casos derivados da seção 8 do design (critérios de aceite), não do plano de build. Só registros sintéticos `TESTE EPLAST-26`, criados por Apex anônimo (uma transação por coisa: massa, atualização e consulta em execuções separadas).
- Nenhum SOQL de dado real. Os 4 leads que já existem na dev não foram lidos.

## Resultado por caso

| Caso | Critério (design, seção 8) | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Lead engajamento Alto | Insert de Lead sintético, consulta de `PriorityScore__c`, `PriorityBand__c` | 15, D | 15, D | passou |
| 2 | Lead "Sem engajamento" | idem | 0, D | 0, D | passou |
| 3 | Lead engajamento vazio | idem | 0, Não classificado | 0, Não classificado | passou |
| 4 | Critérios antigos saíram | Lead com Status "Contatado", `Sector__c`=Alimentos, `LeadSource`=Campanha, sem engajamento | 0 | 0, Não classificado | passou |
| 4b | Médio e Baixo (pesos do Default) | Leads Médio e Baixo | 10 e 5, D | 10 D, 5 D | passou |
| 5 | Opp: descoberta, orçamento, Negociação Comercial, atividade 5 dias, próximo passo | Opp sintética (RT Industria, fixture `opportunity.apex` adaptada) atualizada; Task concluída com `ActivityDate` há 5 dias | 45, C | `LastActivityDate`=2026-11-12, 45, C | passou |
| 6 | Opp Qualificação sem nada | Opp sintética sem evidência | 0, D | 0, D | passou |
| 7 | Atividade há 31 dias / há 30 dias | Duas Opps iguais ao caso 5, Task há 31 e há 30 dias | 35 D / 45 C | 35 D / 45 C | passou |
| 8 | Opp encerrada | Opp passada a `Fechado/Perdido` (Ganho não testado: exige filial e pagamento, ver fixture) | 0, Não classificado | 0, Não classificado | passou (Perdido); Ganho não executado, mesma ramificação `IsClosed` |
| 9 | Campos somente leitura | Apex anônimo atribuindo `Opportunity.PriorityScore__c = 99` | recusado | falha de compilação (campo não gravável) | passou (API); tela não exercitada |
| 10 | Faixas AA, A, B, C (cortes baixos, ver abaixo) | Cópia temporária do `Default` com cortes baixos, mesmos registros relidos | AA/A/B/C aparecem | Ver tabela de faixas | passou |
| 11 | List view `Oportunidades_Prioridade_Alta` filtra AA e A | `describe` da list view pela REST: `IsClosed=false AND (PriorityBand__c='AA' OR 'A')`. Mesmo filtro como SOQL só nas Opps de teste com cortes AA45/A40/B35 | AA e A entram, B e Não classificado ficam fora | O2 e O4 (AA) voltaram; O3 (B) e O1 (encerrada) não | passou |
| 12 | Colunas novas das list views | `describe` das duas outras list views | `NextStep`, `LastActivityDate` na de Opps; `MKT_MC_Engajamento__c` na de Leads | presentes | passou |
| 13 | `MKT_Nutricao_ProntoAbordagem__c` com filtro AA/A (A6) | Leitura do campo nos leads de teste em cada configuração de cortes | Falso com faixas D/C/B/NC; verdadeiro com AA e A | Valores iniciais: falso nos 5. Cortes 15/10/5/1: AA true, A true, B false, D false, NC false | passou |
| 14 | Valores iniciais do `Default` | Consulta a `PriorityScoreSetting__mdt` ao final | 15/10/5, 10/10/5/10/30/10, cortes 90/75/60/40 | idênticos; 1 único registro (`Default`) | passou |
| 15 | Diff sem Apex, Flow, e-mail, callout, Named Credential, layout, página ou permission set | `git show --stat 92d22928` | só metadata declarativa | 24 arquivos: mdt (objeto, 13 campos, registro), 4 fórmulas, `MKT_Nutricao_ProntoAbordagem__c`, 3 list views, plano de build | passou |
| 16 | I-2: usuário sem "Personalizar aplicativo" lê o valor | Ver seção própria | lê 15, D | lê 15, D | passou, com ressalva |
| 17 | Regressão em Opportunity (criar e alterar) | Insert e três updates (estágio, próximo passo, encerrar) de Opps sintéticas, sem exceção; Flows rodaram, Apex de `Account` desviado por `TriggerUtility.bypassTrigger` | sem erro | todas as execuções "Executed successfully" | passou |

### Faixas (cópia temporária do Default, só na dev)

| Cortes AA/A/B/C | Registros (score) | Faixas obtidas |
|---|---|---|
| 45/40/35/10 | Opps 45, 45, 35, encerrada | AA, AA, B, Não classificado |
| 45/40/35/10 | Leads 15, 10, 5, 0, vazio | C, C, D, D, Não classificado |
| 50/15/10/5 | Opps 45, 45, 35 | A, A, A |
| 50/15/10/5 | Leads 15, 10, 5, 0, vazio | A, B, C, D, Não classificado |
| 15/10/5/1 | Leads 15, 10, 5, 0, vazio | AA, A, B, D, Não classificado |

AA, A, B, C, D e "Não classificado" apareceram em pelo menos um objeto. O corte é lido do Custom Metadata (mudou a faixa sem tocar a fórmula).

## Pontos abertos do construtor

**(2) Cópia temporária e Default final.** Não foi criado outro registro: a troca dos cortes foi feita redeployando o próprio `Default` (via `--metadata-dir` em `/tmp`, fora do repositório) e, ao final, redeployando o arquivo original do repositório. Consulta posterior: um único registro `Default`, 90/75/60/40, pesos 15/10/5/10/10/5/10/30/10. Os leads de teste voltaram a D e Não classificado após a restauração. Nada de cópia ficou. Corresponde ao design (seção 4.1).

**(1) I-2, leitura sem "Personalizar aplicativo".** O `PermissionSet` `PS_Comercial_ScorePrioridade` tem `PermissionsCustomizeApplication=false` e dá leitura (sem edição) nos 4 campos (`Lead.PriorityScore__c`, `Lead.PriorityBand__c`, `Opportunity.PriorityScore__c`, `Opportunity.PriorityBand__c`), além dos campos MKT. Para exercitar a leitura foi implantada na dev uma classe de teste temporária (`TmpVerify26Test`), que fez `System.runAs` de um usuário ativo do perfil "Comercial - Analista" (Id `005bJ000004gGVxQAM`, perfil sem "Personalizar aplicativo", confirmado por consulta dentro do teste), inseriu um Lead sintético com engajamento Alto e leu score e faixa: 15, D (teste passou). A classe foi removida por destructive change (consulta: 0 classes com esse nome) e o Lead do teste foi apagado.
Ressalva honesta: esse usuário não tem o permission set da demanda (só o executor o tem e não alterei atribuição de outros usuários), então a leitura rodou em modo sistema; com `WITH USER_MODE` a consulta falhou por falta de acesso ao campo, como esperado sem o permission set. O que ficou provado: a fórmula que lê `$CustomMetadata.PriorityScoreSetting__mdt.Default.*` calcula para usuário sem "Personalizar aplicativo" e sem acesso ao tipo (Public), e o permission set concede a leitura dos campos. A combinação "usuário real com o PS, sem Personalizar aplicativo, na tela" não foi exercitada; é o que o QA da sandbox de QA pode conferir com o usuário de teste da regra 6.

## Não sobreposição com EPLAST-30, 35, 38, 40, 41 e 45

- O commit `92d22928` não toca layout, flexipage nem permission set (`git show --stat`); só os arquivos da tabela do caso 15.
- Na dev: o permission set `PS_Comercial_ScorePrioridade` existe e mantém leitura nos 4 campos de score e nos campos MKT (`MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c`, `MKT_Nutricao_Elegivel__c`, `MKT_Nutricao_ProntoAbordagem__c`); as flexipages `Lead_Record_Page` e `Opportunity_Record_Page` existem (2 encontradas por Tooling API).
- Única mexida em componente de outra demanda: `MKT_Nutricao_ProntoAbordagem__c` (EPLAST-45), na fórmula, conforme D2. Comportamento provado no caso 13.
- Não abri o conteúdo dos layouts nem das flexipages na org: a integridade é inferida pelo diff e pela existência dos componentes, não por comparação campo a campo.

## Dado alterado e devolvido (executor)

- `User` `005bJ00000piKAaQAM` (executor, só dev): `ProtheusSellerId__c` de vazio para `TESTE26` (exigido pela validation rule `CheckAccountOwnerHasProtheusSellerId` para criar Opportunity). Devolvido a vazio ao final (a consulta retornou nulo).
- O executor já tinha `PS_Comercial_ScorePrioridade` antes desta verificação; não atribuí nem retirei nada.

## Dados de teste e limpeza

- Criados: 5 Leads (`Company='TESTE EPLAST-26'`), 1 Account e 4 Opportunities `TESTE EPLAST-26 ...`, 3 Tasks concluídas, 1 Lead do teste de I-2 (dentro do teste, revertido pelo framework e removido).
- Apagados ao final; consulta de contagem de Account, Opportunity e Lead de teste devolve 0. Nada ficou.
- Fixture: `fixtures/lead.apex` e `fixtures/opportunity.apex` serviram de base; os scripts usados desta vez estavam em `/tmp` e não foram gravados em `fixtures/`.

## O que pode ter saído da org

Nenhuma chamada externa. Os Leads de teste foram criados sem telefone ou e-mail; Accounts foram criadas com `TriggerUtility.bypassTrigger = true`, logo sem consulta à BrasilAPI nem envio ao Protheus. Sem job Apex agendado, sem fila de integração gerada (a execução do Apex anônimo reportou 0 de 50 queueable jobs). Nada para desfazer fora da org.

## Pontos sem prova

- Ganho (`Fechado/Ganho`) não foi exercitado (exige filial e pagamento); a fórmula usa `IsClosed`, mesma ramificação do Perdido.
- Tela (campo somente leitura, list view renderizada) não foi exercitada; provado por API, `describe` e SOQL equivalente.
- Usuário real com o permission set e sem "Personalizar aplicativo" na tela: ver I-2 acima.
- As faixas AA, A e B só existem com cortes temporários; com os valores definitivos continuam inalcançáveis, como o design declara (máximo Lead 15, Opportunity 45).

## Observação para a esteira

- O relato do construtor sobre `Lead.Status` (`trackHistory` na org e não no repositório) não foi investigado nem alterado aqui.
