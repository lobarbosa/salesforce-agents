**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27 (próxima melhor ação, v6 só com a 27)

Org conferida com `sf org list`: única org, `sbx-eplast-dev`, Sandbox, Connected (a "QA" da Eplast, regra 5). QA da esteira e produção não tocadas. Nada ativado, nada implantado além do que está descrito em "Alterações temporárias". Usuário de execução: Id `005bJ00000piKAaQAM` (ativo, Administrador do sistema; conta de serviço da Konecta, identificada por Id).

**Por que inconclusiva:** a regra de decisão (Flow v2 ativo) foi exercitada de verdade e passou em todos os casos. O que ficou sem prova é o comportamento do **assistente** (o agente interpretar a pergunta, chamar `IdentificarConta` e `ProximaAcaoCliente` e repetir a `message`), porque a v6 está inativa, não existe BotVersion v6 (v1 a v4 Inactive, v5 Active) e eu não ativo versão. Os critérios que falam "a resposta do assistente indica ..." estão provados na camada do Flow, não na conversa.

## Casos (Flow `Account_Agente_ProximaAcao`, v2 Ativa, chamado por Apex anônimo com `Flow.Interview`, como o proprietário `005bJ00000piKAaQAM`)
Massa sintética `TESTE EPLAST-27 ...` (7 contas, 4 oportunidades abertas, 2 ganhas, tasks concluídas). Estado conferido por consulta antes de rodar (Risk__c, LastPurchase__c, Inactive__c, LastActivityInDays).

| Caso | Critério (cenário) | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | A1 com prioridade sobre A2 | Conta com Risk__c=E e oportunidade aberta com LastActivityInDays=45 | A1, sem A2 | `A1` "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| C2 | A2 | Sem risco, oportunidade aberta (Qualificação) com 31 dias | A2 com estágio | `A2` "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." | passou |
| C3 | A3 | Sem risco, oportunidade ganha com CloseDate há 91 dias (LastPurchase__c=2026-08-16, Inactive__c=true), sem aberta parada | A3 | `A3` "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| C4 | Nenhuma ação | Sem risco, oportunidade com 5 dias, compra há 10 dias | NONE, sem ação inventada | `NONE` "Nenhuma ação prioritária no momento." | passou |
| C5 | Dados insuficientes | Conta sem oportunidade e sem compra | NODATA sem erro técnico | `NODATA` "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| C6 | Conta de outra carteira | Conta com proprietário outro usuário ativo, flow chamado por `005bJ00000piKAaQAM` | Não revela dados | `NOT_OWNER` "Esta conta não está na sua carteira." (sem dado da conta) | passou |
| C7 | Risco fora da lista (borda) | Risk__c=A (lista do mdt: só E) e oportunidade com 45 dias | A2, não A1 | `A2` ... "sem atividade há 45 dias." | passou |
| C8 | A consulta não grava nada | 70 chamadas do Flow (10 rodadas sobre as 7 contas, em 10 transações) | LastModifiedDate de Account e Opportunity inalterado; sem Task nova | Antes e depois idênticos: Account máx. 2026-11-15 18:43:28, Opportunity máx. 18:43:08, Tasks 11 e 11 | passou (Flow roda sem DML; a ausência de execução de outros Flow/trigger não foi medida) |
| C9 | Sem comunicação pelo CRM | Metadata do Flow (retrieve do repositório) e do bundle | Sem e-mail alert, Apex de e-mail ou envio | O Flow tem só Get/Assignment/Decision, sem DML e sem ação de envio; o plano não cria Apex nem e-mail; nada no Marketing Cloud | passou (por inspeção de metadata) |
| C10 | Resposta sem dado pessoal | Mensagens devolvidas nos casos C1 a C7 | Sem CPF, e-mail ou telefone | Só texto fixo, risco, estágio e dias; campos lidos: Name, OwnerId, Risk__c, LastPurchase__c, Inactive__c e da oportunidade StageName e LastActivityInDays | passou |
| C11 | Limiar configurável sem código | Valor de `StaleOpportunityDays__c` do registro `Default` do `NextBestActionSetting__mdt` mudado de 30 para 60 (deploy só do registro), chamadas em C2 (31 dias) e C7 (45 dias), depois voltou a 30 | A2 deixa de ser sugerida com 60 | Com 60: C2 `NONE`, C7 `NONE`, C1 segue `A1`. De volta a 30: C2 e C7 `A2`. Registro confere em 30 / `E` | passou |
| C12 | Mesma regra para EPLAST-28 e eplast-ent-11 | Consumidores ainda não existem | Mesmo resultado | Não há outro consumidor construído; o Flow é único e reutilizável | não executado |

## Agente SFAgent2 (sem ativar)
| Caso | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|
| G1 | Versões do agente (`BotVersion`) | v5 ativa, v1 a v4 inativas | v1 a v4 `Inactive`, v5 `Active` (não tocada) | passou |
| G2 | Planner `SFAgent2_v6` na dev (`GenAiPlannerDefinition`, retrieve) | Existe, inativo, 4 tópicos | Existe; bundle lista 4 plugins: `agent_router_..._v6`, `ambiguous_question_..._v6`, `insights_comerciais_..._v6`, `off_topic_..._v6`. Sem BotVersion v6, logo não está ativo | passou |
| G3 | Funções do tópico `insights_comerciais_..._v6` (`GenAiPluginFunctionDef` + `GenAiFunctionDefinition`) | 3 ações da v4 + `ProximaAcaoCliente_EPLAST27_v6` | `AgregacaoPedidos_..._v6`, `ConsultarPedidos_..._v6`, `IdentificarConta_..._v6`, `ProximaAcaoCliente_EPLAST27_v6` (alvo tipo `flow`, Id `300Ha00000Oxjo5IAB`) | passou |
| G4 | Instrução `instruction2_EPLAST27_v6` no mesmo tópico | Existe com a regra da seção 3.3 | Existe: identificar com `IdentificarConta`, chamar `ProximaAcaoCliente`, mostrar a mensagem sem acrescentar nem combinar, `NOT_OWNER` sem consultar a conta por outra ação | passou |
| G5 | Nada da 29/34 na v6 | Sem `acoes_comerciais`, `ResumoReuniao`, `CriarTarefa`, `IdentificarRegistro` | Bundle e funções da v6 sem esses nomes. Resta na dev o plugin órfão `acoes_comerciais_EPLAST29` (da v5), fora da v6 | passou |
| G6 | Resposta real do assistente (a conta certa, repetir a `message`, NOT_OWNER sem vazar) | Conversa com o agente | Exige v6 ativa e BotVersion v6, que não existem; ativação é passo humano separado | não executado |
| G7 | Flow ativo chamado pela v6 | Alvo é o Flow ativo | A v2 está ativa (v1 Obsolete); o Flow da v6 aponta para ele | passou |

## O que ficou sem prova (e o que fazer)
- G6 e a camada de conversa dos cenários A1, A2, A3, NONE, NODATA e NOT_OWNER: depois que alguém criar/associar a BotVersion v6 e ativá-la na dev (passo humano, exige licença Agentforce e concessão do agente ao permission set `PS_Comercial_ProximaAcao`, não confirmados), perguntar ao assistente a próxima ação de contas da fixture e conferir a mensagem. Latência é métrica, não reprova.
- C12: só prova quando EPLAST-28 / eplast-ent-11 consumirem o Flow.

## Alterações temporárias e limpeza
- `ProtheusSellerId__c` do usuário `005bJ00000piKAaQAM` (exigido pela validation rule de Oportunidade): antes `null`, durante `TESTE27`, depois `null` (conferido).
- `NextBestActionSetting.Default.StaleOpportunityDays__c`: 30, durante 60 por alguns minutos, depois 30 (conferido; deploy do registro só na dev, a partir de pasta temporária fora do repositório).
- `TriggerUtility.bypassTrigger = true` só dentro da execução do Apex anônimo (variável estática, não altera a metadata).
- Dados apagados: todas as Task, Opportunity, Account, `Branch__c` e `PaymentTerms__c` `TESTE EPLAST-27`. Contagens finais na dev: Account 0, Opportunity 0, Branch__c 0 (a dev estava vazia antes). Nada ficou.
- Nenhum job agendado. Nenhuma versão ativada.
- Observação: as 11 Tasks contadas para 4 criadas por mim indicam que a criação de oportunidade gerou tasks por alguma automação da org (bypass de trigger não cobre Flow); todas foram apagadas.
- Fixture gravada: `fixtures/conta-oportunidade-proxima-acao.apex` (e `fixtures/README.md`). Achados: `Risk__c` nasce `E` por padrão; Oportunidade ganha exige Branch com `CodeERP__c`, forma de pagamento e `PaymentTermId__c` (tipo de registro Industria evita as regras de catálogo, análise fiscal e financeira); `LastPurchase__c` é rollup MAX de oportunidade ganha.

## O que pode ter saído da org
Nada. Nenhuma chamada externa, e-mail, pedido, cotação ou log de integração foi gerado: as oportunidades foram criadas com `TriggerUtility.bypassTrigger = true` e nenhuma passou por integração Protheus. Marketing Cloud não tocado.
