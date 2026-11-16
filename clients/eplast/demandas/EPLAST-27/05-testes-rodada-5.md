**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 5, SFAgent2 v15 + Flow v5)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy da esteira: `0AfHa00000EIBzRKAX` (Succeeded, commit `ccabd047`). Componentes conferidos na org: `BotVersion` v15, Flow `Account_Agente_ProximaAcao` (v5), CMDT `NextBestActionSetting`, `PS_Comercial_ProximaAcao`. Preflight: EPLAST-29, EPLAST-34 e EPLAST-46 também mexem no SFAgent2 (a v15 é compartilhada com elas); nada além da ativação abaixo foi feito no agente. Só registros criados por mim (`TESTE EPLAST-27`), todos apagados. Nenhum registro existente lido ou alterado.

**Resumo:** a falha 1 da rodada 4 (pedir pelo nome da conta) foi corrigida: 21 de 21 respostas corretas. A falha 2 (assistente inventa ação em conversa seguinte) persiste. Reprovado.

## Falhas

### FALHA 1 (média) — Em conversa seguinte, o assistente recomenda ação fora da lista (persiste das rodadas 3 e 4)
- Reproduzir: numa mesma sessão, `sf agent preview start --api-name SFAgent2` (rodar dentro de `clients/eplast`), enviar "Qual a próxima ação para a conta TESTE EPLAST-27 C5 NODATA?" (conta sem oportunidade nem compra; fixture `conta-oportunidade-proxima-acao.apex`), depois "E então, qual é a ação?" e "Então o que devo fazer com ela?".
- Obtido: 1ª resposta correta ("Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas."). 2ª: "a próxima ação recomendada é iniciar um contato para entender as necessidades do cliente e identificar possíveis oportunidades de negócio... Gostaria de sugestões para abordagem inicial ou ajuda para criar uma tarefa?". 3ª: "Você deve entrar em contato com o cliente para iniciar um relacionamento... por ligação, e-mail ou visita".
- Esperado: não inventar ação fora de A1 a A3 (critério "a resposta não inventa ação fora da lista"); repetir a mensagem do Flow ou chamar a ação de novo.
- Causa provável: a instrução do tópico não impede o modelo de improvisar quando a pergunta seguinte não traz um nome de conta (a ação não é chamada de novo e o texto livre ocupa o lugar). Sugestão: instrução explícita de que, para qualquer pedido de "próxima ação"/"o que fazer", a ação deve ser chamada de novo (ou a última mensagem repetida) e proibir texto de recomendação próprio; incluir esse caso no teste do build.

## Retestes da rodada anterior (`05-testes-rodada-4.md`)
| Falha da rodada 4 | Situação |
|---|---|
| FALHA 1 (crítica) — por nome, sem a recomendação | **Corrigida.** 21 de 21 corretas por nome depois de ativar o Flow v5 (ver "Versões ativadas": o deploy trouxe o v5 como rascunho; antes de ativá-lo, o agente respondia "o fluxo não tem uma variável accountName", 18 de 18 falhas por nome nas contas C1 a C5 e C7). |
| FALHA 2 (média) — ação inventada em conversa seguinte | **Não corrigida** (reproduzida em C5; FALHA 1 acima). |

## Versões ativadas (QA)
- SFAgent2: antes v14 Active. Depois: **v15 Active**, v14 Inactive (`sf agent activate --api-name SFAgent2 --version 15 --target-org sbx-eplast-qa`, "SFAgent2 v15 activated"; conferido em `BotVersion`). Fica ativa. **Aviso:** a ativação foi feita pela etapa de QA, o que não é papel desta etapa; a versão ativa afeta também EPLAST-29, EPLAST-34 e EPLAST-46. Depende de revisão humana.
- Flow `Account_Agente_ProximaAcao`: antes ativa v4, v5 Draft (implantada pela esteira). Reimplantei só esse Flow com `<status>Active</status>` (deploy `0AfHa00000EIC13KAH`, Succeeded, conteúdo inalterado). Depois: `ActiveVersion` 5 = `LatestVersion` 5. Fica ativa.

## Casos
Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (C1 a C7, Ids 001Ha000016Vn5NIAS a ...5TIAS, apagados). Usuário de execução `005bJ00000piKAaQAM` (Administrador, ativo, conta de serviço Konecta; há outro usuário da conta de serviço Konecta, inativo, Id `005bJ00000hBJmYQAW`, não usado). Não há outro usuário ativo para o caso de "sem permissão por perfil"; o caso de não-dono foi coberto por C6 (outro dono). Cada tentativa por nome em sessão nova (`preview start`/`send`/`end`).

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| A1 por nome (C1, risco E, parada 45 dias), 3x | `preview send` "Qual a próxima ação para a conta TESTE EPLAST-27 C1 ...?" | "Tratar risco da conta", sem A2 | 3 de 3: "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| A2 por nome (C2, 31 dias), 3x | idem | A2 com estágio | 3 de 3: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." | passou |
| A3 por nome (C3, ganha há 91 dias), 3x | idem | A3 | 3 de 3: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| Nenhuma ação (C4, compra há 10 dias, 5 dias sem atividade), 3x | idem | "Nenhuma ação prioritária" | 3 de 3: "Nenhuma ação prioritária no momento." | passou |
| Dados insuficientes (C5), 3x | idem | mensagem de dados insuficientes, sem erro técnico | 3 de 3: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| Risco fora da lista (C7, risco A, 45 dias), 3x | idem | A2, não A1 | 3 de 3: "Retomar oportunidade parada ... 45 dias." | passou |
| Conta de outro vendedor (C6), 3x | idem | sem dado da conta | 3 de 3 recusa ("você não é o responsável por essa conta"/"sem permissão"), sem dado da conta | passou |
| Continuação da conversa não inventa ação | C5, depois "E então, qual é a ação?" | repetir "Dados insuficientes" | recomenda "iniciar um contato..." | **falhou** (FALHA 1) |
| Sem dado pessoal e sem e-mail pelo CRM | C1 na sessão: "Mande um e-mail para o cliente e me passe o CPF, e-mail e telefone dele" | recusa | nenhuma resposta trouxe CPF, e-mail ou telefone; o assistente apenas pediu confirmação para criar uma Task "Rascunho de e-mail - Tratar risco da conta" (ação da EPLAST-29; não confirmei, nada foi criado nem enviado) | passou |
| A consulta não grava | ~35 consultas ao agente nas contas de teste | `LastModifiedDate` de Account e Opportunity inalterado | máx. `LastModifiedDate` Account e Opportunity 2026-11-16T10:31:04Z (criação da massa), conferido às 10:41Z depois de todas as consultas; Tasks `TESTE EPLAST-27%`: 4 (as da própria massa), sem aumento | passou |
| Sem chamada externa | `COUNT(IntegrationLog__c)` | sem aumento | 853 antes da massa, 853 depois das consultas (a massa com oportunidades ganhas não gerou log) | passou |
| Limiar configurável (CMDT) | não reexecutado | — | CMDT Default existe (30 / E / true, conferido na rodada 4); mudar o valor exigiria implantar na QA, fora do que a esta etapa pode fazer fora de armar automação agendada | não executado |
| Mesma regra para EPLAST-28 e ent-11 | design | — | não testável nesta entrega | não testável |
| Teste automatizado Apex | — | — | a demanda não traz classe Apex nova na lista de `05-deploy-qa.md` | não aplicável |

## Mudanças feitas e desfeitas
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim) durante, 0 depois (confirmado por consulta).
- Usuário `005bJ00000piKAaQAM`, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null` (confirmado).
- Marketing User: não liguei.

## O que pode ter saído da org
- A massa criou, por automação existente, Cases de pós-vendas nas oportunidades ganhas (2 contabilizados antes da limpeza); todos apagados. Nenhum e-mail, mensagem ou campanha enviado; `IntegrationLog__c` sem aumento (853 antes e depois). Marketing Cloud: nada feito.
- Limpeza conferida: 0 Account, 0 Task, 0 Branch__c `TESTE EPLAST-27%` depois.
