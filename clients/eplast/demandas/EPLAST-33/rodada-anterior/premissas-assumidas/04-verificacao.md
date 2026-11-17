**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-33 — Verificação do build

Org conectada (`sf org list`): só `sbx-eplast-dev` (usuário de serviço da Konecta da conta, Id `005bJ00000piKAaQAM`, ativo). Nada fora da dev. Nenhuma escrita minha em Account, Opportunity, Order ou OrderItem; nenhum registro de teste criado fora dos testes Apex (que revertem sozinhos). Não há `fixtures/` do cliente no repositório; a fábrica do builder (`CommercialSignalTestFactory`) é o que monta dado, dentro dos testes. Não alterei permission set, perfil nem usuário.

## Por que inconclusiva
A dev tem 0 contas, 0 pedidos e 0 sinais (`SELECT COUNT()`). Exercitar o batch ponta a ponta com dado persistido e medir limites com volume exigiria criar Account/Order na dev, o que a instrução desta verificação proíbe (PA-9). Os critérios de regra foram exercitados por Apex (execução real na dev, com asserts); o que ficou sem prova está abaixo.

## Testes Apex (dev)
`sf apex run test -o sbx-eplast-dev` nas 4 classes de teste, com cobertura. Rodada 1 (Test Run `707Ha00001E423F`): 41 testes, 40 passam, 1 falha: `CommercialSignalBatchTest.doesNotWriteToCommercialObjects` com `UNABLE_TO_LOCK_ROW` no insert de Account da fábrica (o intermitente que o builder já registrou, plano 4.6; não é a lógica da entrega). Reexecutada a classe sozinha (`707Ha00001E432F`): 13 de 13 passam. Resultado: 41 de 41 passam, com 1 retentativa. Risco: rodar em paralelo pode dar vermelho esporádico na CI; o builder já recomenda série.

Cobertura por classe: `CommercialSignalService` 99%, `CommercialSignalGroupStatsBatch` 98%, `CommercialSignalBatch` 97% (linhas 120 e 129 descobertas), `CommercialSignalScheduler` 100%. Todas acima de 85% (CA-20).

## Critérios
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | CA-01, CA-02 | Testes Apex (61, 60, 59 dias) | 61 entra; 60 e 59 não | Testes passam | passou |
| 2 | CA-03, CA-04 | Testes Apex | Nunca comprou aparece; cancelado e "Revisao de Pedido" não contam | Passam | passou |
| 3 | CA-05, CA-06, CA-07 | Testes Apex | 30% exato fora, 31% dentro, queda e alta; sem base não classifica | Passam | passou |
| 4 | CA-08 a CA-11 | Testes Apex | Cruzada 4 de 10 sim, 2 de 10 não; compra recente exclui; sem Industry fora; grupo de 4 não | Passam | passou |
| 5 | CA-12, CA-21 | Teste de contagem/LastModifiedDate de Account, Order, OrderItem, Opportunity e EmailMessage antes e depois; build sem trigger/Flow novo (plano 2) | Nada escrito | Passa; não conferi a metadata de trigger/Flow além do plano | passou |
| 6 | CA-13 | Teste: sem o permission set não lê, com ele lê e não cria | Visibilidade por conta herdada do master-detail | Só a parte de permissão provada; visibilidade por conta (A não vê X) não se prova na dev (OWD Account ReadWrite) | não executado (parcial) |
| 7 | CA-14 | Relatório `CommercialSignals_ByAccount` existe (1 registro em `Report`); colunas conforme plano | Sem campo de contato | Existência confirmada; abertura com dados não feita (dev vazia) | não executado (parcial) |
| 8 | CA-15, CA-16 | Testes Apex | Reexecução sem duplicata; pedido novo remove recuperação | Passam | passou |
| 9 | CA-17 | Teste Apex alterando o parâmetro (90 dias) | Muda classificação sem mudar código | Passa | passou |
| 10 | Agendamento | Testes: job registrado, cron esperado, encadeamento fase 1 para fase 2 gravando sinais. `CronTrigger` `EPLAST33%` na dev: 0 | Job só em teste; sem job pendente (deploy livre) | 0 jobs pendentes | passou |
| 11 | Acesso | `PermissionSetAssignment` de `PS_Comercial_SinaisComerciais`: 1 (usuário da dev, atribuído pelo builder, não por mim). CMDT `Default`: 1 registro | Existem | Confirmado | passou |
| 12 | CA-18, CA-19 | Homologação com o Comercial; Marketing Cloud fora desta etapa | n/a | Não aplicável na dev | não executado |
| 13 | Limites com volume | Não medido (1 conta com 5 mil itens; 1.000 contas em 3 grupos) | Dentro dos governadores | Não medido: exige criar Account/Order na dev | não executado |

## O que ficou sem prova (e o que fazer)
- Batch real ponta a ponta com dado persistido e consumo de limites com volume sintético (design, seção 4): precisa de fixture de Account/Order na dev ou na QA; autorizar a criação de dado sintético `TESTE EPLAST-33` na dev, ou medir na sessão de QA.
- Abertura do relatório `CommercialSignals_ByAccount` com dados (formato escrito à mão): conferir na QA.
- CA-13, visibilidade por conta: só na QA com compartilhamento real.
- CA-18: amostra do Comercial na homologação.

## O que o gate humano deve olhar
- Atribuir o `PS_Comercial_SinaisComerciais` ao usuário que agenda o job antes de agendar; sem ele o batch falha em runtime (plano, rodada de retorno).
- Falhas de gravação do batch só aparecem em `System.debug`, não no status do job (plano 4.4, desvio do design).
- Retentativa de `UNABLE_TO_LOCK_ROW` na suíte em paralelo.

## O que pode ter saído da org
Nada. Nenhum registro persistido por mim, nenhuma chamada externa, nenhum job agendado.
