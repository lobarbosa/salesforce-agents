**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27: Próxima melhor ação por cliente (v6)

Org conferida com `sf org list` antes de tocar em algo: única org, `sbx-eplast-dev` (usuário de execução: conta de serviço da Konecta, Id `005bJ00000piKAaQAM`, Administrador do sistema, ativo), Connected. É a "QA" da Eplast (regra 5 da conta). Nada em QA da esteira, produção ou Marketing Cloud. Nada do que o builder construiu foi alterado.

## Resumo
- A regra do Flow `Account_Agente_ProximaAcao` v2 foi exercitada de verdade na dev e passou nos casos executados (A1, A2, A3, NONE, NODATA, NOT_OWNER, risco fora da lista, sem gravação, sem e-mail).
- A metadata da v6 (BotVersion, planner, ação, instrução) foi conferida.
- **Sem prova:** a resposta do assistente em linguagem natural (critério principal dos cenários 1 a 6). A v6 está Inactive e não deve ser ativada por mim. Na dev a v8 (de outras demandas) é a ativa; ativar a v6 a desligaria. Por isso o veredito é inconclusivo, não reprovado: nenhum caso executado falhou.

## Estado da metadata na dev (consulta)
| Item | Obtido |
|---|---|
| BotVersion de `SFAgent2` | v1 a v7 e v9 Inactive, **v8 Active**, **v6 Inactive** (`SELECT VersionNumber,Status FROM BotVersion ...`) |
| Ligação BotVersion v6 a planner | `v6.botVersion-meta.xml` do repositório traz `genAiPlannerName` = `SFAgent2_v6`; planner `SFAgent2_v6` existe na org (`GenAiPlannerDefinition`, Id `16jHa0000005RHJIA2`). Não consegui consultar o vínculo direto na org (BotVersion não é exposto pela Tooling API); a confirmação é pelo arquivo implantado (Deploy `0AfHa00000EI0EPKA1`, Succeeded, segundo o plano) |
| Ação | `GenAiFunctionDefinition` `ProximaAcaoCliente_EPLAST27_v6` existe na org; no bundle aponta para o Flow `Account_Agente_ProximaAcao` (`invocationTargetType` flow) |
| Instrução | `instruction2_EPLAST27_v6` no bundle, tópico `insights_comerciais`: pede identificar a conta, chamar a ação, repetir a mensagem sem acrescentar ações e, em `NOT_OWNER`, não revelar dados |
| Flow | v1 Obsolete, **v2 Active** (`Flow` pela Tooling API) |
| Flow sem DML nem e-mail | 0 ocorrências de `actionCalls`, `recordCreates`, `recordUpdates`, `recordDeletes`, `emailSimple`, `emailAlert` no arquivo do Flow. Objetos lidos: Account, Opportunity, `NextBestActionSetting__mdt` |
| Campos de Account usados | `Risk__c`, `LastPurchase__c`, `Inactive__c`, `OwnerId` (nenhum CPF, e-mail ou telefone) |

## Dados de teste e mudanças no usuário de execução
- Fixture: `fixtures/conta-oportunidade-proxima-acao.apex` (2 etapas, org explícita). Criou 7 contas `TESTE EPLAST-27 C1..C7`, oportunidades, tasks, filial e condição de pagamento sintéticas.
- Usuário `005bJ00000piKAaQAM`, campo `ProtheusSellerId__c`: antes `null`; durante o teste `TESTE27`; **devolvido a `null` ao final** (contagem de usuários com `TESTE27` = 0). Nenhuma mudança em perfil, papel ou permission set.
- Não atribuí `PS_Comercial_ProximaAcao` nem liguei Marketing User: não foram necessários para chamar o Flow por Apex.

## Casos
Execução: Apex anônimo `Flow.Interview.createInterview('Account_Agente_ProximaAcao', {recordId})` por conta, lendo `actionCode` e `message`, com `LastModifiedDate` das contas lido antes e depois.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Cenário 1: risco alto, A1 sobre A2 | Flow na C1 (Risk E, oportunidade com 45 dias) | A1, sem A2 | `A1`: "Tratar risco da conta: o cadastro está com risco E..." | passou |
| V2 | Cenário 2: oportunidade parada, A2 com estágio | Flow na C2 (31 dias, sem risco) | A2 citando estágio | `A2`: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." | passou |
| V3 | Cenário 3: sem compra há 91 dias, A3 | Flow na C3 (ganha há 91 dias) | A3 | `A3`: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| V4 | Cenário 4: nenhuma condição casada | Flow na C4 (5 dias, compra há 10 dias) | "Nenhuma ação prioritária", sem ação fora de A1 a A3 | `NONE`: "Nenhuma ação prioritária no momento." | passou |
| V5 | Cenário 5: dado insuficiente, sem erro técnico | Flow na C5 (sem oportunidade nem compra) | "Dados insuficientes", sem erro | `NODATA`: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| V6 | Cenário 6: conta de outro vendedor, sem revelar dados | Flow na C6 (dona outro usuário) | Mensagem sem dados da conta | `NOT_OWNER`: "Esta conta não está na sua carteira." | passou (Flow); resposta do assistente não executada |
| V7 | Cenário 7: consulta não grava | 10 chamadas na C1 e 1 em cada outra; `LastModifiedDate` das 7 contas antes e depois; contagem de DML na transação | Nenhuma alteração | `accountsChanged=0`, `dml=0` | passou (contas); oportunidades e tasks não comparadas individualmente, mas o Flow não tem DML |
| V8 | Cenário 8: sem comunicação pelo CRM | Contagem de e-mails na transação; busca por ação de e-mail no Flow | 0 e-mails, sem e-mail alert | `emails=0`; 0 ações de e-mail no Flow | passou |
| V9 | Cenário 9: sem dado pessoal | Leitura das mensagens retornadas e dos campos do Flow | Sem CPF, e-mail ou telefone | Mensagens só com texto fixo, estágio e dias; campos listados acima | passou |
| V10 | Risco fora da lista (regra de P2/design) | Flow na C7 (Risk A, oportunidade com 45 dias) | Risco A não aciona A1; cai em A2 | `A2` ("... sem atividade há 45 dias") | passou |
| V11 | Cenário 10: mudar limiar para 60 dias sem deploy de código | Não executado | A2 deixa de ser sugerida com 45 dias | Alterar o registro `Default` do `NextBestActionSetting__mdt` na dev exige deploy de metadata, que é alterar o que o builder construiu; não fiz | não executado |
| V12 | Cenário 11: mesma regra para EPLAST-28 e eplast-ent-11 | Não executado | Mesmo resultado nos três consumidores | Os outros consumidores não existem na dev | não executado |
| V13 | Cenários 1 a 6, parte do assistente: resposta em linguagem natural, incluindo "não inventa ação" e vendedor sem permission set | Não executado | Assistente chama a ação e repete a mensagem | v6 Inactive; v8 é a ativa na dev; ativar a v6 é passo humano e a ativaria desligaria v7 a v9 de outras demandas. Depende também de licença Agentforce (I3) e da concessão do agente ao `PS_Comercial_ProximaAcao` (não confirmada como metadata) | não executado |
| V14 | Metadata da v6 (BotVersion, planner, ação, instrução, sem conteúdo de EPLAST-29 e 34) | Consultas e leitura dos arquivos acima | v6 Inactive, 4 tópicos, ação e instrução presentes | Conforme a tabela de metadata. Contagem de 4 tópicos pelo arquivo (`localTopics`): insights_comerciais, agent_router, ambiguous_question, off_topic. Ausência de 29 e 34 por leitura do bundle, não por diff completo | passou |

Observação (não reprova): o texto de A1 cita o código de risco ("risco E"). Se o cliente preferir o rótulo, é ajuste na mensagem do Flow, a validar na homologação.

Conflito com EPLAST-29, 34 e 46: nenhum observado nos casos executados. O Flow não é alterado por elas; o conflito possível é na ativação (v8 ativa na dev traz o que 29 e 34 acrescentam).

## O que pode ter saído da org
- A criação das oportunidades ganhas da fixture (C3 e C4) disparou automação própria da dev que criou 2 Cases: `00001221` ("Pós-vendas: TESTE EPLAST-27 ganha C4") e `00001222` ("Pós-vendas: TESTE EPLAST-27 ganha C3"), status New. Foram criados pela cadeia a partir de registros de teste e **apagados por mim**; contagem de Cases com TESTE EPLAST-27 no assunto = 0.
- Primeira tentativa de limpeza falhou por causa desses Cases (transação revertida, nada apagado); refeita apagando Cases, Tasks, Oportunidades, Contas, Filial e Condição de pagamento.
- Chamadas externas registradas: não verifiquei log de integração; a fixture usa `TriggerUtility.bypassTrigger = true` e o Flow não tem callout. Nenhum e-mail na transação de teste.

## Limpeza
Contagens finais (consulta `COUNT`): Account, Opportunity, Task, Case, Branch__c e PaymentTerms__c com `TESTE EPLAST-27`: 0. `ProtheusSellerId__c` do usuário: de volta a `null`. Nada ficou. Nenhum job Apex agendado por mim.

## O que ficou sem prova e o que uma pessoa precisa fazer
1. **Resposta do assistente (V13).** Uma pessoa autorizada ativa a BotVersion v6 na sandbox escolhida (decidindo sobre as capacidades da versão ativa que a v6 não tem), confirma a licença Agentforce (I3), concede o agente ao `PS_Comercial_ProximaAcao` e executa as perguntas dos cenários 1 a 6, incluindo o vendedor sem permission set.
2. **Limiar por Custom Metadata (V11).** Alterar `NextBestActionSetting.Default` para 60 dias na sandbox (deploy de metadata, passo da esteira) e repetir a consulta da C2/C1 com 45 dias.
3. **Mesma regra para outros consumidores (V12).** Só quando EPLAST-28 e eplast-ent-11 existirem.
