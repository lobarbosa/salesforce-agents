**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (00DHa000006vfMLMAY)

# EPLAST-29 · Verificação do build (Flow v2, SFAgent2 v17)

Org confirmada com `sf org list`: único alias `sbx-eplast-dev`, sandbox, conectada (usuário de conexão omitido de propósito). Nada foi implantado, ativado nem alterado por esta verificação. Não toquei na QA.

## Estado da dev encontrado (consultas por `sf data query`)
| Item | Consulta | Obtido |
|---|---|---|
| SFAgent2 ativa | `BotVersion` com `Status='Active'` | só a **v13** (v14 a v17 Inactive) |
| Flow `Task_Agente_CriarTarefa` | `Flow` (Tooling) | **v1 Active**, v2 **Obsolete** |
| Dados de teste | `Lead` com `LastName LIKE 'REG-TESTE%'` (contagem) | 4 |
| Tarefas de teste | `Task` com `Subject LIKE 'REG-TESTE%'` (contagem) | 0 |

## Por que não foi possível exercitar
- O Flow v2 (que traz a lógica de lead, configuração e prioridade) não é a versão ativa na dev: a plataforma só roda a v1, que é a versão antiga. Executá-la não prova a construção. A v2 está Obsolete, então ativá-la exigiria reativar a versão, o que é ativação de metadata (passo separado do plano, item 1 de "Versões e ativação") e foge de "só exercito, não implanto".
- O agente v17 está Inactive; a ativa é a v13, sem as instruções da demanda. O comportamento do tópico `acoes_comerciais_EPLAST29_v17` só aparece com a v17 ativa, e depende do modelo, não só de metadata.
- Sem ativação, nada foi criado pelo agente: 0 tarefas de teste.

## Tabela por critério
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-1 | AC-1 criar tarefa com confirmação | Conferido estado de versões | Flow v2 e v17 ativos para exercitar | v1 ativo, v17 inativo | não executado |
| V-2 | AC-2 recusa do resumo não grava | idem | 0 tarefas após recusa | sem execução | não executado |
| V-3 | AC-3 registro ambíguo (`REG-TESTE-DUP`) | Dados existem (leads e conta), busca não rodada | lista candidatos, não grava | sem execução | não executado |
| V-4 | AC-4 usuário sem permissão | Não executado: depende de usuário comum e de ativação | recusa sem vazar dado | sem execução | não executado |
| V-5 | AC-5 campo obrigatório faltando | Não executado | pergunta e não grava | sem execução | não executado |
| V-6 | AC-6 e-mail/mensagem não envia pelo CRM | Não executado | rascunho, nada enviado | sem execução | não executado |
| V-7 | AC-7 fora do escopo | Não executado | não grava | sem execução | não executado |
| V-8 | AC-8 rastreabilidade (`Origem: assistente de IA`) | Não executado | marca na descrição, dono = usuário | sem execução | não executado |
| V-9 | AC-9 não quebra o existente | Só estado: a v13 segue ativa e a v1 do Flow ativa, intocadas | ações de EPLAST-27/34/46 intactas | sem regressão observada por metadata; sem execução | não executado |
| V-10 | Falhas 1 a 3 da rodada 1 (QA) | Não executado | v17 corrige | v17 só deployed | não executado |

Nenhum caso falhou; nenhum foi executado.

## Sem prova (o que uma pessoa precisa fazer)
1. Ativar na dev o Flow `Task_Agente_CriarTarefa` v2 (rollback: v1) e depois `SFAgent2` v17 (`sf agent activate`; rollback: v13). Depois reexecutar esta verificação com os dados `REG-TESTE-*` que já existem (fixtures/lead.apex, account.apex).
2. R3 (busca `identifyRecordByName` aceitar `Lead`), R4 (Flow com usuário comum) e Q-12 continuam sem prova.
3. AC-4 exige usuário comum, com e sem `PS_Comercial_AssistenteAcoes`: fica para a homologação.
4. O texto do resumo antes do cartão da ação (FALHA 3) só se confere na tela.

## Dados de teste
Nada criado nesta verificação. Permanecem os 4 leads `REG-TESTE%` (1 convertido) e a conta `REG-TESTE-DUP` do build. Nenhuma alteração em usuário (Marketing User, permission set, campo).

## O que pode ter saído da org
Nada: nenhuma automação foi disparada por esta verificação.
