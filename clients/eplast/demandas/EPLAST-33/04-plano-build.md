**Resultado do build:** concluído

# EPLAST-33 — Plano de build (cross-sell, volume e recuperação)

**Org:** `sbx-eplast-dev` (sandbox `eplast--qa`, usuário `projetos@konectabr.com.eplast2.qa`, única org em `sf org list`; regra 5 da conta). **Branch:** `feature/EPLAST-33`. **Design:** `03-design.md`, aprovado em 2026-11-15 (`gates.md`), incluindo o objeto novo `CommercialSignal__c`. Nenhuma pergunta aberta (design, seção 8); build seguiu as premissas PA-1 a PA-22.

## 1. O que foi construído (tudo implantado na dev)

| Tipo | Componente |
|---|---|
| Objeto | `CommercialSignal__c` (Sinal Comercial): sharing "controlado pelo pai", nome automático `SC-{000000}`, sem trigger, Flow, validation rule nem roll-up. `Description` em objeto e campos |
| Campos | `Account__c` (master-detail), `Type__c` (picklist restrita, 5 valores), `Product__c`, `LastPurchaseDate__c`, `DaysWithoutPurchase__c`, `BasePeriodAmount__c`, `CurrentPeriodAmount__c`, `VariationPercent__c`, `Reason__c`, `CalculationDate__c`, `SignalKey__c` (External ID, único, chave de upsert) |
| CMDT | `CommercialSignalSetting__mdt` com os 13 parâmetros do design e o registro `Default` com os valores do design (60 dias, `Faturamento;Concluido`, 3 meses, 30%, `Queda;Alta`, `Industry`, 12 meses, 180 dias, 30%, grupo mínimo 5, teto 10, lote 100, "Nunca comprou" ligado) |
| Apex | `CommercialSignalService` (regras puras, sem SOQL/DML), `CommercialSignalGroupStatsBatch` (fase 1, `Database.Stateful`, encadeia a fase 2 no `finish`), `CommercialSignalBatch` (fase 2, upsert por `SignalKey__c` e remoção dos sinais que não se repetiram), `CommercialSignalScheduler` (`Schedulable`) |
| Testes | `CommercialSignalServiceTest`, `CommercialSignalGroupStatsBatchTest`, `CommercialSignalBatchTest`, `CommercialSignalSchedulerTest` e a fábrica `CommercialSignalTestFactory` (`@IsTest`) |
| Saída | Tipo de relatório `Accounts_with_CommercialSignals`, pasta `EPLAST33_SinaisComerciais` (compartilhada com o grupo público `EPLAST33_SinaisComerciais`), relatório `CommercialSignals_ByAccount` (resumo por tipo; Account ID, nome, `Ranking__c`, produto, dias, somas, variação, datas, motivo; **nenhum campo de contato**) |
| Acesso | Permission set `PS_Comercial_SinaisComerciais` (leitura do objeto e dos campos; sem criar, editar ou excluir), aba `CommercialSignal__c` |

Regras como implementadas: recuperação com "mais de" 60 dias (61 entra; 60 e 59 não); volume por soma de `Order.TotalAmount`, atual = (hoje − 3 meses, hoje], base = os 3 meses anteriores, comparação exata sem arredondar (`|atual − base| × 100 > limite × base`), base zero nunca classifica, `VariationPercent__c` guarda o valor absoluto e o sentido está no tipo; cruzada com grupo ≥ 5 contas, participação ≥ 30% (inclusive) em 12 meses, exclusão de produto comprado nos últimos 180 dias, teto de 10 por conta (maior percentual primeiro, empate por Id); conta sem `Industry` fica fora da cruzada e segue nos demais tipos. Só `Order` com status do CMDT conta como compra.

Governador: nada de SOQL ou DML em laço. Fase 2: 5 SOQL por lote (última compra, soma atual, soma base, produtos recentes, sinais existentes) e até 2 DML (`allOrNone=false`). Fase 1: 1 SOQL de agregação por lote. `without sharing` nos dois batches, com justificativa em comentário no código (PA-17).

## 2. O que NÃO foi tocado

Nenhuma escrita, trigger, Flow ou validation rule em Account, Opportunity, Order, OrderItem. `ScheduledFlowOpportunity`, `RankingRange__mdt`, campos de compra de Account, `SFAgent2`, perfis: intocados. Nada no Marketing Cloud (`et4ae5`, `Campaign`, `CampaignMember` não usados). Produção não foi tocada.

## 3. Testes (sandbox dev)

`sf apex run test -o sbx-eplast-dev --class-names CommercialSignalServiceTest CommercialSignalGroupStatsBatchTest CommercialSignalBatchTest CommercialSignalSchedulerTest --code-coverage` — Test Run Id `707Ha00001Dzssr`, última rodada:

- **38 testes, 38 passam (100%)**, tempo 32,7 s.
- Cobertura por classe: `CommercialSignalService` 99%, `CommercialSignalGroupStatsBatch` 98%, `CommercialSignalBatch` 97%, `CommercialSignalScheduler` 100% (todas ≥ 85%, CA-20).

Cenários cobertos, com `System.assert*` sobre o resultado: CA-01/02 (61, 60 e 59 dias), CA-03/04 (nunca comprou; cancelado e "Revisao de Pedido" não contam), CA-05/06 (30% exato fora, 31% dentro, queda e alta), CA-07 (sem base), CA-08/09/10/11 (cruzada 4 de 10 sim, 2 de 10 não, compra recente, sem Industry, grupo de 4), CA-12 (contagem e maior `LastModifiedDate` de Account e Order, contagens de OrderItem e Opportunity, nenhum `EmailMessage`), CA-15 (reexecução sem duplicata, mesmos Ids), CA-16 (pedido novo remove a recuperação), CA-17 (90 dias), bulk de 200 contas num lote (um sinal por conta), 200 fatos no serviço, negativo (campo de grupo inexistente cai em `Industry`, tipo desligado remove sinais, parâmetros por direção), permissão (sem o permission set não lê; com ele lê e não cria), agendamento (job registrado, cron esperado, e encadeamento fase 1 → fase 2 gravando sinais).

Fixture: os pedidos nascem em rascunho, recebem o item com o valor e mudam de status, com todos os campos que as validation rules de Order apontam (fórmulas lidas por Tooling API, só metadata). Dois contornos, ambos só no teste e comentados na fábrica: (a) `TriggerUtility.bypassTrigger` (mecanismo oficial da org) durante o insert de Account, porque `AccountTrigger` valida CNPJ e enfileira uma consulta à BrasilAPI por conta (limite de 50 jobs; impediria o bulk de 200); (b) a mudança de status roda como usuário de teste com username `integracao*` e perfil administrador, porque `OrderTrigger` não envia ao Protheus nesse caso, e o envio enfileirado falha no teste (sem Opportunity nem mock).

Pendente de medição (design, seção 4): consumo de limites com volume sintético (1 conta com 5 mil itens; 1.000 contas em 3 grupos). A dev tem 0 contas e 0 pedidos; é trabalho do verificador/QA.

## 4. Desvios e pontos de atenção

1. **Agendamento e fuso.** O cron do Salesforce roda no fuso do usuário que agenda (aqui, America/Sao_Paulo). `0 0 4 * * ?` resultou em 07:00 UTC; o cron ficou `0 0 1 * * ?` (01:00 local = 04:00 UTC, o horário do design). `NextFireTime` conferido: 2026-11-16 04:00 UTC. Quem reagendar de outro fuso ajusta a hora. O nome da constante (`CRON_DAILY_0400_UTC`) é o do design.
2. **Job agendado na dev.** `System.schedule` com `CommercialSignalScheduler.scheduleDaily(CommercialSignalScheduler.JOB_NAME)` (passo 2.5 do design), job "EPLAST33 Sinais Comerciais". Na QA quem agenda é a esteira, em duas sessões. Há também uma sobrecarga com nome de job, usada só pelo teste, para não colidir com o job real.
3. **Permission set.** O campo obrigatório `Type__c` e o master-detail `Account__c` não aceitam permissão de campo (a plataforma recusa), então não constam; o acesso a eles vem do objeto. O permission set traz leitura de Account (a plataforma exige: "Ler CommercialSignal__c depende de Ler Account"), sem editar nada. Foi atribuído ao usuário da dev (`sf org assign permset`), porque sem FLS os campos novos nem aparecem no describe; isso é dado de sandbox, não metadata.
4. **Falhas de gravação não aparecem no status do job.** O design pedia "falhas contadas e expostas no status do job". As falhas são contadas (`failures`, `Database.Stateful`) e escritas em `System.debug` no `finish`; o status do `AsyncApexJob` não mostra isso sem lançar exceção, o que derrubaria o lote. Se a esteira precisar do número na tela, a saída é um campo de log ou e-mail ao admin, fora do que o design aprovou.
5. **CA-13 só em parte.** A org tem OWD de Account interno ReadWrite (recon §5), então não há conta "invisível" para um usuário padrão: o teste prova que o sinal só é lido com o permission set e nunca é criado por ele, mas a visibilidade por conta (A não vê X) só se prova na QA com compartilhamento real. A herança vem do master-detail.
6. **Rodadas com `UNABLE_TO_LOCK_ROW` intermitente.** Em 2 das 10 rodadas da suíte inteira (execução paralela) um insert de Account na fábrica falhou com bloqueio de linha; a mesma classe, reexecutada, passou. Não envolve a lógica da entrega (o batch não escreve em Account). Se aparecer na QA, rodar as classes em série.
7. **Relatório sem dados exercitado.** O relatório e o tipo de relatório foram implantados e existem na org (conferido por contagem); não foram abertos com dados, porque a dev está vazia. O formato foi escrito à mão (não havia relatório da org no repositório para copiar, como o design pedia): conferir a abertura na verificação.
8. **Não-escopo registrado, sem correção.** R-7 (filtro `Liberação Financeira` do `OrderScheduledFlow`), `CNPJ`/BrasilAPI no `AccountTrigger` e envio ao Protheus no `OrderTrigger` apareceram só como obstáculo de fixture; nada foi alterado.

## 5. Premissas assumidas

Sem premissa nova. Valem PA-1 a PA-22 do `03-design.md`. Onde mudar cada uma está no CMDT `CommercialSignalSetting__mdt` (registro `Default`), exceto PA-4 (campo `EffectiveDate`, no código) e PA-20 em mês fechado (ajuste pontual no serviço).

## 6. Passo para a esteira e para o humano

- Deploy na QA (feito pela esteira, `05-deploy-qa.md`): objeto, CMDT e registro, 4 classes + testes + fábrica, tipo de relatório, pasta, relatório, grupo público, permission set, aba. Depois: agendar o job e atribuir o permission set a quem testa.
- Cobertura global da org continua baixa (assessment, achado 2); esta entrega não a eleva (risco R-5 do release humano).
