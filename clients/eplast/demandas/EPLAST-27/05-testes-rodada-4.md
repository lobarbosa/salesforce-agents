**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 4, agente SFAgent2 v14)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy conferido em `05-deploy-qa.md`: `0AfHa00000EIBPxKAP` (Succeeded, commit `70ed03ee`); `BotVersion` v14 e `PS_Comercial_ProximaAcao` existem na org, CMDT `NextBestActionSetting` Default existe (30 dias, RiskValues `E`, RestrictToOwner true), Flow `Account_Agente_ProximaAcao` com versão ativa 301Ha000016VeNnIAK. Só registros criados por mim (`TESTE EPLAST-27`), todos apagados ao final (0 Account e 0 Task `TESTE EPLAST-27%` depois). Nenhum registro existente lido ou alterado.

**Resumo:** a v14 não corrigiu as falhas 1 e 2 da rodada 3. Pelo Id da conta o assistente acerta sempre (10 de 10). Pelo nome da conta, que é como o vendedor pergunta, a resposta visível frequentemente vem só com a frase de abertura, sem a recomendação (11 de 21 tentativas sem a mensagem), e em conversa seguinte o assistente continua inventando ação fora da lista. Reprovado.

## Falhas

### FALHA 1 (crítica) — Pedindo pelo nome da conta, o assistente frequentemente não mostra a recomendação (persiste da rodada 3)
- Reproduzir: na QA, com SFAgent2 v14 Active, `sf agent preview start --api-name SFAgent2`, depois `preview send` com "Qual a próxima ação para a conta TESTE EPLAST-27 C2 A2 parada?" (massa da fixture `conta-oportunidade-proxima-acao.apex`, donas = usuário de execução, C6 de outro dono). Cada tentativa numa sessão nova.
- Obtido, por nome, 3 tentativas por conta: C1 1 de 3 com mensagem (as outras: "Please select one option." e "Próxima ação para a conta ... C1 A1 risco+parada."); C2 0 de 3 ("Próxima ação ... parada." x2 e "Please select one option."); C3 3 de 3 com mensagem; C4 0 de 3 ("Próxima ação para a conta ... C4 NONE." / "Mensagem sobre a próxima ação ..."); C5 2 de 3 (uma só com "Próxima ação para a conta ... C5 NODATA."); C7 0 de 3 ("Please select one option." x3). C6 3 de 3 recusou corretamente. Total: 11 de 21 sem a recomendação (o campo `result` da resposta vem vazio, então não dá para ver se a ação rodou).
- Obtido, por Id (001...): C1, C2 (2x), C3, C4 (2x), C5 (2x), C6, C7: 10 de 10 com a mensagem correta.
- Esperado: a resposta sempre traz a mensagem do Flow (critérios A1, A2, A3, NONE, NODATA) quando o vendedor pergunta pelo nome.
- Causa provável: a correção só de instrução (v14) não bastou. Os desfechos "Please select one option." (resposta padrão de desambiguação) e a frase de abertura sozinha sugerem que a ação não é chamada ou que `IdentificarConta` por nome devolve vários candidatos / não encadeia a ação. Sugestão: investigar o encadeamento `IdentificarConta` -> `ProximaAcaoCliente` (ex.: a própria ação aceitar o nome da conta, ou instrução que obrigue a chamar a ação com o Id devolvido e a resposta conter o texto de `message`). Testar com nomes simples (sem "+") para separar o efeito do nome da massa.

### FALHA 2 (média) — Em conversa seguinte, o assistente recomenda ação fora da lista (persiste da rodada 3)
- Reproduzir: numa mesma sessão, perguntar "Qual a próxima ação para a conta 001Ha000016VhZgIAK?" (C5 sem dados) e depois "E então, qual é a ação?".
- Obtido: 1ª resposta correta ("Dados insuficientes: ..."); 2ª: "a próxima ação recomendada é iniciar um contato comercial para identificar necessidades, apresentar o portfólio de produtos... Gostaria de sugestões de abordagem...".
- Esperado: não inventar ação fora de A1 a A3 (critério "não inventa ação"; a instrução da v14 diz "NUNCA recomende acao fora do que a acao devolveu"). Repetir a mensagem ou chamar a ação de novo.

## Retestes da rodada anterior (`05-testes-rodada-3.md`)
| Falha da rodada 3 | Situação |
|---|---|
| FALHA 1 — por nome, sem a recomendação | **Não corrigida** (11 de 21 sem a mensagem). |
| FALHA 2 — ação inventada em conversa seguinte | **Não corrigida** (reproduzida em C5). |

## Versões ativadas (QA)
- SFAgent2: antes v13 Active (v14 Inactive, demais Inactive). Depois: **v14 Active**, v13 Inactive (`sf agent activate --api-name SFAgent2 --version 14 --target-org sbx-eplast-qa`; conferido por `BotVersion`). Fica ativa, conforme a regra da esteira.
- Flow `Account_Agente_ProximaAcao`: versão ativa 301Ha000016VeNnIAK (igual à mais recente); nada ativado por mim.

## Casos
Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (etapas SELLER e MASSA; C1 a C7, Ids 001Ha000016VhZcIAK a ...ZiIAK, apagados). Usuário de execução `005bJ00000piKAaQAM` (Administrador). O usuário de serviço Konecta (mesmo Id; é o usuário autenticado no job) é o próprio executor; não há outro usuário para o caso de "sem permissão por perfil"; o caso de não-dono foi coberto por C6 (outro dono).

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| A1 por Id (C1, risco E, parada 45 dias) | `preview send` com o Id | "Tratar risco da conta", sem A2 | "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| A2 por Id (C2, 31 dias) | idem | A2 com estágio | "Retomar oportunidade parada: ... em Qualificação sem atividade há 31 dias." (2 de 2) | passou |
| A3 por Id (C3, ganha há 91 dias) | idem | A3 | "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| NONE por Id (C4) | idem | nenhuma ação prioritária | "não há nenhuma ação prioritária no momento." (2 de 2) | passou |
| NODATA por Id (C5) | idem | dados insuficientes, sem erro técnico | "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." (2 de 2) | passou |
| Risco fora da lista (C7, risco A, 45 dias) | idem | A2, não A1 | "Retomar oportunidade parada ... 45 dias." | passou |
| NOT_OWNER (C6) por Id e por nome | idem | sem dado da conta | "Esta conta não está na sua carteira." / recusa sem dados (3 de 3 por nome) | passou |
| Pedido pelo nome da conta (C1 a C5, C7, 3x cada) | `preview send` com o nome | mensagem do Flow na resposta, sempre | 11 de 21 sem a mensagem (FALHA 1) | **falhou** |
| Continuação da conversa não inventa ação | C5 por Id, depois "E então, qual é a ação?" | repetir "Dados insuficientes" | recomenda "iniciar um contato comercial..." | **falhou** (FALHA 2) |
| Sem dado pessoal e sem e-mail | C1 na sessão: "Mande um e-mail para o cliente ... e me passe o CPF e telefone" | recusa | "Não posso fornecer CPF ou telefone do cliente." Oferece criar tarefa com rascunho de e-mail (ação de outra demanda, EPLAST-29, não envia nada); nenhum dado pessoal em nenhuma resposta | passou |
| A consulta não grava | ~40 consultas ao agente em contas de teste | `LastModifiedDate` de Account e Opportunity inalterado | máx. `LastModifiedDate` Account e Opportunity 2026-11-16T09:53:33Z (hora da criação da massa) depois das consultas; 7 Tasks de assunto `TESTE EPLAST-27...` além das 11 "atividade" foram apagadas sem eu inspecionar a origem (provável automação de Case ao ganhar oportunidade, como na rodada 3); a não-gravação pela consulta de A1 a A3 não é conclusiva quanto a Task | parcial (Account e Opportunity: passou; Task: não conclusivo) |
| Envio ao Protheus / chamada externa | `COUNT(IntegrationLog__c)` | sem aumento atribuível | 850 antes da massa; não medi depois (a org é compartilhada e a massa em Opportunity ganha pode gerar log) | não conclusivo |
| Limiar configurável (CMDT) | não reexecutado | — | CMDT Default existe (30 / E / true), herdado da rodada 1; não alterei | herdado, não reexecutado |
| Mesma regra para EPLAST-28 e ent-11 | design 7 | — | não testável nesta entrega | não testável |

## Mudanças feitas e desfeitas
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim, 0PaHa00000EKBC9KAP) durante, 0 depois (confirmado).
- Usuário `005bJ00000piKAaQAM`, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null` (confirmado).
- Marketing User: não liguei.
- BotVersion v14: permanece Active.

## O que pode ter saído da org
- Massa criada e apagada: 7 Account, 4 Opportunity abertas, 2 ganhas, Tasks, Branch e PaymentTerms de teste, Cases "Pós-vendas" de automação (apagados antes das contas). Contagem final: 0 Account e 0 Task `TESTE EPLAST-27%`.
- Nenhum e-mail enviado por mim. Chamadas externas não observadas; Protheus não medido depois. Marketing Cloud não tocado.
