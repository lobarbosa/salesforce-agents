**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-28 — Testes na QA, fase 2 (conferência)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS Partial Copy). Usuário de execução = usuário de teste da regra 6, Id `005bJ00000piKAaQAM`; nenhum permission set, valor ou perfil dele foi alterado. A fase 1 (armar) está registrada na versão anterior deste arquivo e resumida abaixo. Conferência feita em 2026-11-17 ~11:35Z, depois de `Conferir depois de` (11:28Z). Sem DML da minha parte nesta fase.

## Falhas
### FALHA 1 (branda) — Título do aviso sem acento
O Flow (`TituloAviso`, linha 53 do XML) monta `"Oportunidade sem atividade ha N dias"` (sem o "á"); o design e o roteiro dizem "há". Reproduzir: ler a fórmula no XML. Esperado: "há". Causa provável: acento evitado de propósito na fórmula. Não bloqueia o aceite (conteúdo e número de dias corretos); sugerir ajuste na próxima versão. O sino não foi lido por tela (ver CA-03), então o texto exato exibido não foi confirmado.

Nenhuma falha crítica ou média.

## Execução do agendamento
- `CronTrigger` `08eHa00000Xtg0SIAR`: `PreviousFireTime` 2026-11-17T11:18:00Z, `TimesTriggered` 1, próximo 2026-11-18T11:18Z, estado WAITING. A automação rodou no horário armado.
- Flow ativo: v9 (antes: v7 Active, v8 Draft da demanda; v7 e v8 viraram Obsolete). Fica ativa. Conteúdo do Flow inalterado.
- Armado com `DiasSemAcompanhamento__c` 7 -> 2 e início 08:18 (fuso da org); confirmado agora `Default` = 2. A esteira reimplanta o build original (7, 07:00). Não desfiz.

## Resultado por caso
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| CA-01 fechada não alerta | Opp D (perdida, tarefa 13/11) no disparo | sem log | `IntegrationLog__c` de hoje (ação do Flow): 9 `ALERTA_ENVIADO`; nenhum com o Id de D (`006Ha00000QWpOfIAL`) | Passou |
| CA-02 alerta ao dono uma vez, no dia exato | Opp C (sem atividade, criada há 2 dias), prazo armado 2 | 1 log `<Id> \| DiasParado=2` | log de C (`006Ha00000QWpOeIAL`) `DiasParado=2`, 1 só. A, B (4 e 3 dias) e H (1) e I (0) sem log (dia exato). Prazo 7 em si não exercitado; só o valor do CMDT muda (CA-12 parcial) | Passou |
| CA-03 texto | Fórmula XML; sino | título com dias, corpo só nome | XML: título "...sem atividade ha N dias", corpo `CorpoAviso` conferido por revisão estática (sem conta/estágio/valor nesta revisão do título). Sino não lido por tela: a sessão de browser não achou o controle e abrir o sino da conta de teste pode mostrar aviso de oportunidade real copiada (LGPD). Sem captura | Parcial (ver FALHA 1; tela fica ao roteiro do cliente) |
| CA-04 estágio não reinicia | Opp F (tarefa 15/11, estágio e valor alterados hoje 11:06Z) | alerta | log de F (`006Ha00000QYi4VIAT`) `DiasParado=2` | Passou |
| CA-05 sem repetição | 1 disparo só | sem 2º aviso | Um log por oportunidade no disparo; segundo disparo não exercitável na sessão. Previsto pelo dia exato | Não executado (inferido) |
| CA-06 tarefa aberta não reinicia, concluída reinicia, sem vencimento | Opps G, H, I | G alerta; H não; I não (criada hoje) | G (`006Ha00000QYnk5IAD`) com log `DiasParado=2`; H e I sem log. Medido na fase 1: `LastActivityDate` de G = 2026-11-15 mesmo com tarefa aberta de 16/11; I vazio | Passou |
| CA-07 alteração administrativa | F com valor alterado | alerta | F alertou (troca de dono não testada) | Passou (parcial: valor) |
| CA-08 gestor desligado | `NotificarGestor__c` false | sem `ALERTA_GESTOR_ENVIADO`/`SEM_GESTOR` | só `ALERTA_ENVIADO` hoje (9), nenhum outro status. Ramo ligado e gestor real não exercitados (0 `ManagerId`; usuário não pode ser alterado) | Passou (só desligado) |
| CA-09 dono inativo | — | `DONO_INATIVO` | não criei dono inativo (não alterar usuário); nenhum apareceu | Não executado |
| CA-10 sem agente novo / sem e-mail | contagens | iguais | `GenAiPluginDefinition` 57, `GenAiFunctionDefinition` 74 (sem baseline anterior registrado; o build não contém metadata de agente e `05-deploy-qa.md` não lista nenhuma). Não houve e-mail nem Marketing Cloud (Flow só cria notificação e log) | Passou (baseline parcial) |
| CA-11 não grava em objetos de negócio | contagens antes/depois | iguais | Opportunity 9341/9341, Account 1221/1221, Order 10321/10321, Event 5455/5455, Task 8549/8549; F `LastModifiedDate` 11:06:24Z inalterado; XML: 0 `recordUpdates`/`recordDeletes`, `recordCreates` só de log; `IntegrationLog__c` 911 -> 920 (+9) | Passou |
| CA-12 configurável | `DiasSemAcompanhamento__c`=2 mudou o dia do aviso | aviso no dia 2 | alertou aos 2 dias, não aos 7. Demais parâmetros não variados | Passou (parcial) |
| Volume / limites | 9 avisos em 1 execução, 7 deles de registros copiados | sem erro | 9 `ALERTA_ENVIADO`, 0 `FALHA_NOTIFICACAO`; 0 `AsyncApexJob` falhado relevante não verificado em detalhe (FlowInterview não consultável) | Passou (volume baixo; escala não provada) |

Total esperado na fase 1 (9: 7 sem atividade criados em 15/11 + F + G) = obtido (9). Não há log para A, B, D, H, I.

## Não exercitável
- Gestor real e `SEM_GESTOR` (ramo ligado); dono inativo; segundo disparo (CA-05); prazo 7 literal; leitura do sino por tela. Premissas P20/P21 aceitas pelo design.

## O que pode ter saído da org
- Dados de teste `TESTE EPLAST-28` (oportunidades A a I, tarefas, conta de teste).
- 9 notificações internas (sino) aos donos das oportunidades que bateram o prazo, 7 de registros copiados; 9 linhas em `IntegrationLog__c` (`ALERTA_ENVIADO`). Nenhum e-mail, nada no Marketing Cloud, nada ao Protheus.

## Rodada anterior
Falhas das rodadas 1 e 2 (arquivadas em `rodada-anterior/`) não retestadas uma a uma; o design desta versão as substitui por novas respostas do cliente.
