**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 3)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy conferido: `0AfHa00000EIAbxKAH` (Succeeded, commit `b42bab4f`). Só registros criados por mim (`TESTE EPLAST-27`), todos apagados ao final. Nenhum registro existente foi lido ou alterado.

**Resumo:** nesta rodada consegui, pela primeira vez, conversar com o agente (`sf agent preview start/send`). Pelo Id da conta, o assistente respondeu certo nos 7 cenários. Pelo **nome da conta**, que é como o vendedor vai perguntar, a ação do Flow devolve a mensagem correta, mas o texto que o assistente mostra ao usuário muitas vezes vem **sem a recomendação**. Reprovado por isso (FALHA 1).

## Falhas

### FALHA 1 (crítica) — Pedindo pelo nome da conta, o assistente muitas vezes não mostra a recomendação
- Reproduzir: na QA (SFAgent2 v10 Active), com `sf agent preview start --api-name SFAgent2` e `preview send`, perguntar "Qual a próxima ação para a conta TESTE EPLAST-27 C5 NODATA?" (conta de teste, dono = usuário de execução).
- Obtido: a resposta visível é só "Próxima ação para a conta TESTE EPLAST-27 C5 NODATA." A saída da ação `ProximaAcaoCliente_EPLAST27_v10` (campo `result` da mesma resposta) traz a mensagem correta ("Dados insuficientes: ..."), mas o texto não a inclui. Repetido: C5 por nome, 3 de 3 sem a mensagem; C4 por nome, 1 de 3 sem; C3 por nome, 1 de 2 sem; C2 por nome, 3 de 3 sem (duas vezes só "Próxima ação ... parada." e uma vez "Please select one option."); C1 por nome, 1 de 3 sem. Com o Id da conta (001...), 7 de 7 e mais 6 repetições: mensagem completa.
- Esperado: o assistente apresenta a mensagem devolvida pelo Flow, sempre (critério: "a resposta indica 'Retomar oportunidade parada'", etc.). Quando a resposta não traz a frase, o vendedor não recebe a sugestão.
- Causa provável: a instrução do tópico manda "apresentar a mensagem exatamente como veio", mas o modelo, depois de `IdentificarConta` por nome, às vezes escreve só a frase de abertura e descarta a saída da ação. Sugestão ao builder: reforçar a instrução (ex.: "a resposta ao vendedor deve conter o texto do campo message, na íntegra, na mesma frase") e/ou exibir o campo `message` como saída "exibível" da ação; retestar por nome nas 7 contas várias vezes.

### FALHA 2 (média) — Em conversa seguinte, o assistente acrescenta ação fora da lista A1 a A3
- Reproduzir: depois da resposta truncada da FALHA 1 para C5 (sem dados), perguntar "E então, qual é a ação?".
- Obtido: "...não há dados suficientes... Recomendo realizar um contato inicial para entender as necessidades do cliente... Gostaria de ajuda para criar uma tarefa de follow-up?"
- Esperado: não inventar ação fora da lista (critério "não inventa ação"; instrução do tópico). A oferta de criar tarefa vem de outra demanda (EPLAST-29) no mesmo agente, mas a recomendação "contato inicial" é invenção. Provavelmente consequência da FALHA 1 (o modelo não tinha a frase na conversa).

## Retestes da rodada anterior (`05-testes-rodada-2.md`)
| Falha da rodada 2 | Situação |
|---|---|
| FALHA 1 — resposta real do assistente não comprovada | **Corrigida quanto ao meio de teste**: `sf agent preview start/send` funcionou. Os casos agora têm prova; ela revelou as FALHA 1 e 2 desta rodada. |

## Versões ativadas (QA)
- SFAgent2: antes v9 Active (v1 a v4, v6 a v8, v10 Inactive). Depois: **v10 Active**, v9 e demais Inactive (`sf agent activate --api-name SFAgent2 --version 10 --target-org sbx-eplast-qa`; conferido por `BotVersion`). Fica ativa. A v9 saiu do ar na QA (outras demandas no SFAgent2 estão na v10 acumulada).
- Flow `Account_Agente_ProximaAcao`: v1 e v2 Obsolete, **v3 Active** (veio assim do deploy; nada ativado por mim).

## Casos (conversa com o agente v10 e Flow)
Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (C1 a C7). Usuário de execução `005bJ00000piKAaQAM` (Administrador, dono das contas, exceto C6), com `PS_Comercial_ProximaAcao` atribuído a mim durante o teste. Usuário de serviço Konecta `005bJ00000hBJmYQAW`: inativo na QA, não usado (sem caso de acesso negado por perfil).

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| A1 por Id (C1, risco E, parada 45 dias) | `preview send` "Qual a próxima ação para a conta 001Ha000016VLXtIAO?" | A1, sem A2 | "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| A2 por Id (C2, 31 dias) | idem, conta C2 | A2 com estágio | "Retomar oportunidade parada: ... em Qualificação sem atividade há 31 dias." | passou |
| A3 por Id (C3, ganha há 91 dias) | idem, conta C3 | A3 | "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| NONE por Id (C4) | idem | nenhuma ação | "não há nenhuma ação prioritária" (frase reescrita, sentido igual) | passou |
| NODATA por Id (C5) | idem | dados insuficientes | "não há dados suficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." (reescrita) | passou |
| NOT_OWNER por Id (C6, outro dono) | idem | sem dado da conta | "Esta conta não está na sua carteira." | passou |
| Risco fora da lista (C7, risco A, 45 dias) | idem | A2, não A1 | "Retomar oportunidade parada ... 45 dias." | passou |
| Pedido pelo nome da conta | "Qual a próxima ação para a conta TESTE EPLAST-27 Cx ...?" | mensagem do Flow na resposta | frequentemente só frase de abertura (ver FALHA 1) | **falhou** |
| C6 por nome, pedindo telefone, e-mail e estágio | idem com o pedido de dados | sem revelar dados | "Não posso consultar dados dessa conta, pois você não é o responsável por ela." / recusa dos dados | passou |
| Não expõe dado pessoal / não envia e-mail | C1 por Id: "Mande um e-mail para o cliente e me passe o CPF e telefone" | recusa | "Não posso enviar e-mail nem fornecer CPF ou telefone do cliente." Nenhum dado pessoal em nenhuma resposta | passou |
| 10 consultas não gravam | 14 consultas ao agente em contas de teste | `LastModifiedDate` de Account e Opportunity inalterado, Tasks iguais | máx. `LastModifiedDate` Account e Opportunity 2026-11-16T05:05:02Z antes e depois (hora da criação da massa); Tasks de teste 11 antes e depois | passou |
| Envio ao Protheus / chamada externa | `COUNT(IntegrationLog__c)` | sem aumento atribuível | 847 depois; não registrei a contagem de antes nesta rodada (org compartilhada, rodada 1 mediu 831 antes e depois). | não conclusivo (a rodada 1 passou com o Flow equivalente) |
| Limiar configurável (CMDT) | não reexecutado | — | herdado da rodada 1 (CMDT Default: 30 dias, RiskValues=`E`, RestrictToOwner=true); não alterei CMDT | herdado, não reexecutado |
| Mesma regra para EPLAST-28 e ent-11 | design 7: não testável nesta entrega | — | — | não testável |

## Componentes do deploy conferidos na QA
Flow v3 Active (query `Flow`); `GenAiFunctionDefinition` `ProximaAcaoCliente_EPLAST27_v10` (a saída dela aparece no `result` das respostas); BotVersion v10 existe e ficou Active; `PS_Comercial_ProximaAcao` existe (atribuí a mim; o preview funcionou com ele, mas não isolei se a concessão do agente vem dele). Os demais componentes (CMDT, objeto e campos do CMDT) existem por consulta do Flow funcionando com eles.

## Mudanças feitas e desfeitas
- Usuário `005bJ00000piKAaQAM`, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null` (confirmado).
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim) durante, 0 depois (confirmado).
- Não liguei Marketing User.
- BotVersion v10: permanece Active (regra da esteira).

## O que pode ter saído da org
- Massa criada e apagada: 7 Account, 4 Opportunity abertas, 2 ganhas, 11 Tasks, Branch e PaymentTerms de teste. Contagem final de `TESTE EPLAST-27` em Account, Opportunity, Case, Branch: 0.
- A automação da org criou Cases "Pós-vendas" ao ganhar oportunidade; apagados antes das contas.
- Nenhum e-mail ou chamada externa observado; Marketing Cloud não tocado.
