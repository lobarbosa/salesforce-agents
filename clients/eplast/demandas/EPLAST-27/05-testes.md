**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 6, SFAgent2 v15 + Flow v6)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy da esteira: `0AfHa00000EIGcXKAX` (Succeeded, commit `519db944`). Componentes de `05-deploy-qa.md` conferidos na org: Flow `Account_Agente_ProximaAcao`, CMDT `NextBestActionSetting`, `PS_Comercial_ProximaAcao` (atribuível), BotVersion v15 Active (v14 e v13 Inactive). Só registros criados por mim (`TESTE EPLAST-27`), todos apagados. Nenhum registro existente lido ou alterado.

**Resumo:** a rodada 5 reprovou só pela improvisação em pergunta de continuação. O responsável decidiu (card, 2026-11-16 11:50, e 03-design.md) tratá-la como limitação conhecida, a observar na homologação. O restante passou: 14 de 14 respostas corretas por nome nesta rodada, sem gravação e sem chamada externa. Nenhuma falha bloqueante.

## Falhas
Nenhuma bloqueante.

### Limitação conhecida aceita (não reprovada) — pergunta de continuação
Rodada 5 (FALHA 1): em conversa seguinte ("E então, qual é a ação?") numa conta sem dados, o assistente improvisa ação fora de A1 a A3. Aceita pelo responsável como limitação conhecida; **não reexecutei** o caso nesta rodada, fica registrado como "não corrigida, aceita por decisão". Entra no roteiro do cliente para observação.

## Versões ativadas (QA)
- SFAgent2: já v15 Active desde a rodada anterior (`BotVersion`: v15 Active, v14 e v13 Inactive). Não alterei. A versão é compartilhada com EPLAST-29, 34 e 46.
- Flow `Account_Agente_ProximaAcao`: antes, v5 Active e v6 Draft (implantada pela esteira, mesmo conteúdo). Reimplantei só esse Flow com `<status>Active</status>` (conteúdo inalterado). Depois: v6 Active, v5 Obsolete (conferido por consulta a `Flow`). Fica ativa.

## Casos
Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (C1 a C7, apagados). Usuário de execução `005bJ00000piKAaQAM` (Administrador, ativo; a conta de serviço Konecta inativa `005bJ00000hBJmYQAW` não foi usada). Não há outro usuário ativo para "sem permissão por perfil"; o caso de não-dono foi coberto por C6. Cada consulta em sessão nova (`sf agent preview start/send/end`), 2 tentativas por cenário.

| Caso (critério) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| A1 por nome (C1, risco E, parada 45 dias), 2x | `preview send` "Qual a próxima ação para a conta TESTE EPLAST-27 C1 ...?" | "Tratar risco da conta", sem A2 | 2 de 2: "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| A2 (C2, 31 dias), 2x | idem | A2 com estágio | 2 de 2: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." | passou |
| A3 (C3, ganha há 91 dias), 2x | idem | A3 | 2 de 2: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| Nenhuma ação (C4), 2x | idem | "Nenhuma ação prioritária" | 2 de 2: "Nenhuma ação prioritária no momento." | passou |
| Dados insuficientes (C5), 2x | idem | mensagem sem erro técnico | 2 de 2: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| Risco fora da lista (C7, risco A, 45 dias), 2x | idem | A2, não A1 | 2 de 2: "Retomar oportunidade parada ... 45 dias." | passou |
| Conta de outro vendedor (C6), 2x | idem | sem dado da conta | 2 de 2 recusa ("você não é o responsável"/"não tem permissão"), sem dado da conta | passou |
| A consulta não grava | 14 consultas | `LastModifiedDate` de Account e Opportunity inalterado | máx. Account e Opportunity 2026-11-16T12:24:14Z (criação da massa), conferido às 12:27Z depois de todas as consultas; Tasks de teste criadas todas às 12:24:14Z, nenhuma depois | passou |
| Sem comunicação/chamada externa pelo CRM | `COUNT(IntegrationLog__c)` | sem aumento | 856 antes da massa, 856 depois das consultas; Flow sem e-mail/DML (verificação estática da rodada anterior, arquivo inalterado) | passou |
| Sem dado pessoal na resposta | leitura das 14 respostas | sem CPF, e-mail, telefone | nenhuma resposta trouxe esses dados (as contas de teste têm e-mail e telefone sintéticos preenchidos) | passou |
| Limiar configurável (CMDT) | não executado | A2 some com limiar 60 | mudar o registro exige implantar na QA, fora do que o QA pode fazer sem armar automação; CMDT Default existe (conferido na rodada 4) | não executado |
| Mesma regra para EPLAST-28 e ent-11 | design | — | não testável nesta entrega | não testável |
| Continuação não inventa ação | — | repetir mensagem | não reexecutado; limitação conhecida aceita (acima) | não executado (aceito) |
| Conflito com EPLAST-29/34/46 | consultas de próxima ação na v15 compartilhada | resposta correta mesmo com as outras ações presentes | respostas corretas em 14 de 14; nenhuma ação de outra demanda foi acionada nas consultas | passou |
| Teste Apex | — | — | demanda sem classe Apex nova | não aplicável |

## Premissas assumidas testadas
- P1/P9 (prioridade NODATA, A1, A2, A3, NONE; risco = `E`): confirmada pelos casos C1 a C5 e C7 (risco "A" não conta como risco).
- P2 (30 dias A2, 90 dias A3): confirmada com 31 e 45 dias (A2) e 91 dias (A3). Mudança de limiar não executada.
- P6 (sob demanda, sem gravar): confirmada.
- P8 (recorte de carteira = dono da conta): confirmada por C6.
- P5 (regra fixa, assistente só apresenta): confirmada nas consultas diretas; a limitação da continuação segue aberta.

## Mudanças feitas e desfeitas
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim) durante, 0 depois (consulta).
- Usuário `005bJ00000piKAaQAM`, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null` (consulta).
- Marketing User: não liguei.

## O que pode ter saído da org
- Automação existente criou 2 Cases de pós-vendas nas oportunidades ganhas da massa e Tasks; todos apagados. Nenhum e-mail, mensagem ou campanha; `IntegrationLog__c` 856 antes e depois. Marketing Cloud: nada feito.
- Limpeza conferida por consulta: 0 Account, 0 Task, 0 Branch__c `TESTE EPLAST-27%`.
