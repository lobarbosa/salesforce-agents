**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-30 · Verificação (dev), rodada 2

Org conectada (`sf org list`): `sbx-eplast-dev`, Sandbox, Org Id `00DHa000006vfMLMAY`, Connected. Nada feito na QA nem em produção.
Usuário de execução: `005bJ00000piKAaQAM` (ativo). Não alterei nada nele (sem permission set, sem opção). A conta de serviço de teste (`005bJ00000hBJmYQAW`) está inativa na dev e não foi usada.
Não criei registro algum na org (0 DML), então não há dado a apagar. A pasta `clients/eplast/fixtures/` não existe, e a dev tem 0 Opportunity.

## Rodada anterior: a falha foi corrigida?

**FALHA 1 (regra 5 do follow-up não efetiva na dev): corrigida.**
- Retrieve só de `GenAiPromptTemplate:Rascunho_Followup_Comercial` (e do FlexiPage), em diretório temporário já removido: duas versões, `..._1` e `..._2`, ambas `Published`, e `activeVersionIdentifier` aponta para `_2`.
- Geração via `POST /services/data/v65.0/einstein/prompt-templates/Rascunho_Followup_Comercial/generations`, texto sintético `TESTE EPLAST-30`. Com data `31/12/2026`: 4 de 4 chamadas citaram conta, etapa e `31/12/2026`. Com `[dado ausente: Data de fechamento]`: 4 de 4 repetiram o marcador, sem inventar data. Total 8 de 8.
- Observações menores (não reprovam): o modelo às vezes lista "Valor" em "Campos vazios" mesmo recebendo o valor, e às vezes omite a saudação com `[nome do contato]` ou escreve `[Seu nome]` com variações (já coberto por PB-01).

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | Follow-up cita conta e data de fechamento (FALHA 2 da QA) | 4 chamadas ao template na dev com data `31/12/2026` | Conta, etapa e data no texto | 4 de 4 citam conta, etapa e `31/12/2026` | passou |
| V-02 | Follow-up com data vazia | 4 chamadas com `[dado ausente: Data de fechamento]` | Marcador no texto, sem data inventada | 4 de 4 com marcador, sem data inventada | passou |
| V-03 | Versão ativa do template é a `_2`, `_1` preservada | Retrieve do componente | `_1` e `_2` Published, ativa `_2` | Confirmado | passou |
| V-04 | CA-14: PromptFlows depreciados | `SELECT COUNT(Id) FROM Flow WHERE ProcessType='PromptFlow'` (Tooling) | 0 | 0 | passou |
| V-05 | Screen Flow ativo | Tooling `FlowDefinition` `Opportunity_Screen_RascunhoComercial` | Versão ativa | Versão 1, Active | passou |
| V-06 | PSG criado | `PermissionSetGroup` `PSG_Comercial_RascunhoIA` | Updated | Updated | passou |
| V-07 | Página da EPLAST-26 preservada e aba inserida | Retrieve de `FlexiPage:Opportunity_Record_Page` da dev | `PriorityScore__c`/`PriorityBand__c` presentes; `flowruntime:interview` e `IA_Rascunho_Comercial` presentes | Campos Priority: 2 ocorrências; `IA_Rascunho_Comercial`: 1; `flowruntime:interview`: 2 | passou |
| V-08 | CA-11/12: Flow sem DML | Grep estático (rodada 1): 0 `recordCreates/Updates/Deletes` no arquivo do Flow | 0 | 0 | passou (estático; sem debug log de execução) |
| V-09 | CA-01 a 03: abrir aba, gerar os 3 tipos, tempo, fonte nos argumentos | Não executado | Conforme `01-analise.md` | Screen Flow só roda pela interface; sem login com o PSG, sem Opportunity na dev | não executado |
| V-10 | CA-04/05/06/07/13: sem data, sem cotação, valor igual a `SBQQ__NetAmount__c`, Contact não lido, 50 linhas | Não executado | Conforme análise | Depende da execução do Flow com massa | não executado |
| V-11 | CA-08/09: acesso negado e usuário sem PSG | Não executado | Tela de negativa; aba oculta | Sem usuário de teste ativo com login | não executado |
| V-12 | CA-10: erro com template desativado | Não executado | Tela de erro | Depende da execução do Flow | não executado |
| V-13 | Debug log de uma geração sem DML nem trigger/Flow record-triggered | Não executado | Log sem DML em Opportunity, Account, Contact, Task, Order | A geração só ocorre dentro do Flow, que não rodou. A geração direta pela API de template (V-01/02) não passa pelo Flow e não prova esse ponto | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer
- **Execução do Screen Flow de ponta a ponta** (V-09 a V-13, os critérios principais da demanda). Motivos que o builder não resolve: Screen Flow não roda pela CLI; o único login disponível é a conta de execução do job, sem o PSG, e a regra da conta não permite mexer em perfil de outro usuário (o PSG da própria demanda poderia ser atribuído ao usuário de execução, mas Screen Flow continua sem execução por CLI); o usuário de teste da Konecta está inativo na dev.
- **Quem prova:** pessoa com login na dev ou na QA e `PSG_Comercial_RascunhoIA` atribuído, seguindo `05-roteiro-cliente.md` (C-09 a C-12 cobrem acesso negado, usuário sem PSG, erro e 50 linhas), com oportunidade sintética (conta, cotação primária, e uma com mais de 50 linhas). Para V-13, ligar debug log desse usuário durante uma geração e conferir a ausência de DML e de execução de trigger ou Flow record-triggered.
- Não há falha de construção conhecida: a única falha anterior está corrigida. O veredito é inconclusiva porque o critério principal (Flow rodando) não foi exercitado, não por defeito.

## O que pode ter saído da org
- 8 chamadas ao serviço de geração de texto do template de follow-up, todas com texto sintético `TESTE EPLAST-30` (nome de oportunidade e conta fictícios, data e valor fictícios). Nenhum registro foi criado na org; nenhum log de integração ou pedido gerado. Nada a desfazer do outro lado.

## Limpeza
- Nenhum dado de teste criado. Diretório temporário do retrieve removido; `git status` só mostra `00-preflight.md` (da esteira).
