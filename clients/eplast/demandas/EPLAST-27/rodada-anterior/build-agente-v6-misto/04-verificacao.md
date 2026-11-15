**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (conferida pelo alias, Org Id 00DHa000006vfMLMAY, `sf org list`: única org, Sandbox, Connected)

# Verificação — EPLAST-27 (Próxima melhor ação por cliente)

Só dev. QA e produção não tocadas. Nenhum dado de teste criado (nenhum DML); nada para apagar. Consultas apenas de metadata e contagens (`SELECT COUNT() FROM Account` = 0 na dev). Nada ativado, nada alterado.

## Pontos conferidos

### 1. Estado real do SFAgent2
- `BotVersion` (SFAgent2): v1–v4 Inactive, **v5 Active**. **Não existe BotVersion v6** (confirma o builder).
- `GenAiPlannerDefinition`: SFAgent2_v1 a v5 e **SFAgent2_v6** existem. O planner v6 existe e está sem BotVersion, portanto inativo.
- Conteúdo da v6 (bundle no repositório, deployado): tópicos `agent_router`, `ambiguous_question`, `off_topic`, `insights_comerciais`, `acoes_comerciais_EPLAST29` (todos com sufixo `_v6`); ações `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`, `ProximaAcaoCliente_EPLAST27_v6`, `ResumoReuniao_EPLAST34_v6`, `IdentificarRegistro_EPLAST29_v6`, `CriarTarefa_EPLAST29_v6`. Instrução `instruction2_EPLAST27_v6` presente no tópico `insights_comerciais_v6`.
- Não consegui ler o planner v6 direto da org (só a consulta de existência por Tooling); o conteúdo acima vem do bundle do repositório, que o builder diz ter deployado.

### 2. Colisão com EPLAST-29 e EPLAST-34: PROCEDE
- A v6 contém ações de EPLAST-34 (`ResumoReuniao_EPLAST34_v6`, `instruction1_EPLAST34_v6`) e de EPLAST-29 (tópico `acoes_comerciais_EPLAST29_v6` com `IdentificarRegistro` e `CriarTarefa`). São herança da v5 ativa, que já as carregava; a v6 as copia.
- O tópico/ações da EPLAST-29 ganharam sufixo `_v6` (confirmado). Observação: as instruções do tópico EPLAST-29 (`instruction0..8_EPLAST29`) **não** ganharam sufixo `_v6` no bundle; não consegui provar se isso gera conflito de nome no deploy ou na ativação. Ponto de atenção.
- Risco: EPLAST-29 e EPLAST-34 estão aguardando gate de design mas já têm componentes na v5/v6. Ativar a v6 da EPLAST-27 promove também o que estiver ali dessas duas demandas. Quem ativar deve partir de uma única v6 com as três mudanças e confirmar com os donos das outras demandas.

### 3. Flow `Account_Agente_ProximaAcao`
- Dev: v1 Obsolete, **v2 Active** (Tooling query em `Flow`). Retrieve da v2 ativa comparado ao repositório por contagem de marcadores (A1, A2, A3, NONE, NODATA, NOT_OWNER, CASESAFEID, `StaleOpportunityDays__c`, `RiskValues__c`): idênticos. Códigos de resultado A1, A2, A3, NONE, NODATA e NOT_OWNER presentes; A1 usa `Risk__c` contra `RiskValues__c` do CMDT; A3 usa `LastPurchase__c`. A afirmação do builder (nenhuma versão nova necessária) procede.
- Isso prova que a regra está presente, não que se comporta bem; ver "Sem prova".

### 4. Ação, CMDT e permission set
- GenAiFunction `ProximaAcaoCliente_EPLAST27`, `_v5` e `_v6`: existem, `InvocationTargetType=flow`, alvo `300Ha00000Oxjo5IAB`, o mesmo para as três.
- `NextBestActionSetting__mdt`: registro `Default` existe (`RiskValues__c`=E, `StaleOpportunityDays__c`=30).
- `PS_Comercial_ProximaAcao`: existe; `SetupEntityAccess` com 1 FlowDefinition. Não há concessão da ação ao agente (é passo manual, como o builder disse).

### 5. Git
- `git log origin/feature/EPLAST-27 -1`: `3e02df83 EPLAST-27: criar planner v6 do SFAgent2 com instrução da próxima ação`, igual ao HEAD local. **O push chegou.**
- PR: não aberto por mim (sem GH_TOKEN). O plano de build diz "PR aberto", mas não confirmei. **Pendência: confirmar/abrir o PR.**

## Critérios de aceite (01-analise.md seção 6)
Todos os cenários descritos têm o assistente como ponto de entrada e foram escritos para a QA; a dev não tem licença Agentforce confirmada nem a v6 ativa.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | A1 risco -> "Tratar risco da conta" | só verificada a presença da regra no Flow ativo | resposta correta | regra presente; não executado (dev com 0 Account; massa atravessa a cadeia Protheus) | não executado |
| 2 | A2 oportunidade parada | idem | idem | regra e limiar presentes (30 no CMDT); não executado | não executado |
| 3 | A3 sem compra há 91 dias | idem | idem | regra presente; não executado | não executado |
| 4 | NONE | idem | idem | código presente; não executado | não executado |
| 5 | NODATA | idem | idem | código presente; não executado | não executado |
| 6 | NOT_OWNER, sem vazamento | idem | idem | código e comparação com `CASESAFEID` presentes; não executado | não executado |
| 7 | Somente leitura (LastModifiedDate) | não executado | sem alteração | Flow com `queriedFields` apenas; sem DML no repositório do Flow; não exercitado | não executado |
| 8 | Sem e-mail/mensagem pelo CRM | verificação estática do plano e do bundle | nenhum envio | nenhum e-mail/Apex de envio no plano; não exercitado | não executado |
| 9 | Resposta sem CPF/e-mail/telefone | não executado | sem dado pessoal | não exercitado | não executado |
| 10 | Limiar configurável (30 -> 60) | só leitura do CMDT | A2 deixa de valer | CMDT tem o campo; não alterado | não executado |
| 11 | Consumidores com o mesmo resultado (EPLAST-28) | não executado | mesmo resultado | fora do que a dev exercita | não executado |
| 12 | Existência/vínculo dos componentes (pontos 1, 3, 4) | consultas sf | existem e ligados | confirmados acima | passou |
| 13 | Push da branch | `git log origin/...` | commit remoto | `3e02df83` presente | passou |

## O que ficou sem prova
- Comportamento do Flow (A1–A3, NONE, NODATA, NOT_OWNER): a dev está sem registros e criar Account/Opportunity atravessa a cadeia de integração Protheus. Não criei massa nesta rodada. O builder cita rodadas anteriores que passaram; não há `04-verificacao-rodada-<n>.md` para eu confirmar. Para provar: criar contas `TESTE EPLAST-27 ...` na dev com o desvio documentado e chamar o Flow por Apex anônimo; ou rodar na QA.
- Resposta real do agente: exige criar/associar BotVersion v6 e ativá-la, licença Agentforce e concessão do agente ao `PS_Comercial_ProximaAcao`. Passos manuais.
- Nenhuma falha encontrada no que foi exercitado; por isso inconclusiva, não reprovada.

## O que pode ter saído da org
Nada: nenhum registro criado, nenhuma chamada externa.

## Observações para o gate
- Conferir que o PR existe (pendência de GH_TOKEN).
- Decidir a ordem de ativação da v6 com EPLAST-29 e EPLAST-34 (risco de colisão).
