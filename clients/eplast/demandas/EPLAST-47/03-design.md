**Etapa:** 3 (design, arquiteto)
**Data:** 2026-11-17

# EPLAST-47 — Design (rodada 3): classificar a conta quando a oportunidade é salva, sem fluxo agendado

**Cliente:** Eplast · **Demanda:** EPLAST-47 · **Substitui:** o design da rodada 2 (objeto `AccountRanking__c`), que não será construído, por decisão do responsável de 17/11 (`comentarios-do-card.md`, 2026-11-17 00:56).

**Estimativa de esforço:** 22–34 h
O que mudou em relação à análise (30–50 h) e à rodada 2 (36–52 h): sai o objeto novo, o relatório novo e o permission set novo. Sai também o teste de volume da execução mensal (critério 18). Ficam reaproveitados os dois tipos de metadado personalizado, as 7 faixas, os 7 valores do picklist, o histórico de campo, o relatório de mudanças e a lógica de soma, faixa e falha da v2 do `ScheduledFlowOpportunity`. O que pesa agora é a verificação: salvar oportunidade ganha de teste dispara CPQ, criação de Pedido, Caso e a cadeia do Protheus, e exige fixture que passe pelas 16 validation rules de Opportunity. Divisão: Flow novo 6–8 h, ajuste do relatório e do metadado 1–2 h, desativação do agendado 1 h, verificação na dev 6–10 h, QA 6–10 h, documentação 2–3 h.

## Entradas e org de referência

- **Org conectada (`sf org list`, 2026-11-17):** só `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`, Connected), que é a sandbox `eplast--qa` da Eplast (regra 5 da conta). API 68.0. Nenhum deploy, DML, Apex anônimo ou alteração de metadata nesta etapa. Só consulta, describe pontual e retrieve em pasta temporária descartada.
- **Lidos:** `01-analise.md` (aprovada em 14/11, `gates.md`), `02-recon.md` (17/11), `comentarios-do-card.md` (decisão de 17/11), `00-preflight.md` (sem bloqueios, nenhuma outra demanda nos mesmos componentes), `05-testes-rodada-3.md` (falha "Too many queueable jobs: 51"), seção "Decisão do responsável (2026-11-17)" do rascunho anterior deste arquivo, regras 1 a 6 do `CLAUDE.md` da Eplast, skills `salesforce-doutrina` e `padrao-entrega`, trechos do `assessment.md`.
- **Conferido por mim nesta sessão** (linhas acrescentadas ao `02-recon.md`, seção "Complemento do arquiteto"): os Flows ativos em Opportunity e Account e o `TriggerOrder` deles; em que caminhos o `OpportunityFlow` grava a média; a fase ganha; o corpo de `UpdateAccountWithProtheusInfo`; os 68 relatórios da pasta MARKETING CLOUD; os campos `et4ae5__` em Account.

## 1. Solução escolhida

**Declarativo: um Flow novo disparado por registro, after save, em Opportunity, `Opportunity_AfterSave_ClassificaConta`.** Ele recalcula a soma e a classificação **só da conta da oportunidade salva** e grava em `Account` só quando algo mudou. Sem Apex, sem campo novo, sem objeto novo. O `ScheduledFlowOpportunity` é desativado num passo separado.

### 1.1 Por que este nível (doutrina: configuração, depois Flow, depois código)

- **Configuração não resolve.** `Ranking__c` como fórmula quebraria o histórico de campo (fórmula não tem histórico, e o critério 14 depende dele), o picklist que o relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` e o permission set `Protheus` leem, e as faixas configuráveis em `RankingRange__mdt` (fórmula não lê metadado em loop). Roll-up não existe: Opportunity–Account é lookup.
- **Flow resolve.** É uma conta por execução, uma consulta de oportunidades e uma gravação. Nada aqui pede Apex: não há callout, rollback elaborado nem recursão com estado, e o volume por execução é pequeno (seção 4). A restrição de 16/11 ("sem Apex novo") também vale.
- **Por que resolve a falha da rodada 3.** A rodada 3 gravou centenas de contas numa transação, e a `AccountTrigger` enfileirou um job por conta até passar de 50. Agora cada oportunidade salva grava no máximo **uma** conta, e só se mudou. Na tela, uma transação tem 1 oportunidade, então ficam no máximo 3 a 5 jobs enfileirados (seção 4.1).

### 1.2 Lógica do Flow novo

Reaproveita os elementos da v2 do `ScheduledFlowOpportunity`, que estão na dev (retrieve de hoje): `GetOpportunities`, `AssignSumValue`, `GetRanges`, `LoopRanges`, `RangeMatches`, `AssignRanking`, `KeepCurrentRanking`, `HasChanges`, `UpdateAccount`, `GetSetting`, `HasRecipient`, `SendFaultEmail`, `LogFault` e a fórmula `FaultBody`. O builder copia esses elementos para o Flow novo. Não entram `CheckDayMonth`, `Day`, `IsRepresentative`, `GetRepresentativeOpportunity` e `CheckAccount`, porque eram só do agendado.

| # | Elemento | O que faz |
|---|---|---|
| 0 | Start | Opportunity, `RecordAfterSave`, `CreateAndUpdate`, **`triggerOrder` 1500**. A condição de entrada é uma fórmula (1.3). A opção é "toda vez que o registro atende à condição" (`doesRequireRecordChangedToMeetCriteria` = false), porque a fórmula já usa `ISCHANGED`. |
| 1 | `GetAccount` (novo) | Get Records em Account por `Id = $Record.AccountId`. Campos: `Ranking__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c`. **Consulta explícita, e não `$Record.Account.*`**, para ler a média já gravada pelo `OpportunityFlow` na mesma transação (1.4). |
| 2 | `GetOpportunities` | Oportunidades com `AccountId = $Record.AccountId`, `StageName = Fechado/Ganho` e `ThisYear__c = true`. Só o campo `Amount`. É o mesmo filtro da v1 e da v2 (P1 e P2). |
| 3 | `LoopOpportunities` + `AssignSumValue` | Soma `Amount` em `SumAmount`. Sem oportunidade, a soma fica 0 (PA3). |
| 4 | `ClassifyRanking` | Se `GetAccount.AveragePurchasesThisYear__c` estiver vazia, `KeepCurrentRanking` mantém `GetAccount.Ranking__c`. Se estiver preenchida (inclusive 0), `GetRanges` busca `RankingRange__mdt` por `SortOrder__c`, e `LoopRanges`/`RangeMatches` pega a primeira faixa com `média <= UpperLimit__c` ou com `UpperLimit__c` vazio (3G). A comparação é a mesma de hoje: acima da faixa anterior, até o limite inclusive (P7). |
| 5 | `HasChanges` | Grava só se `NewRanking` for diferente de `GetAccount.Ranking__c` ou `SumAmount` for diferente de `GetAccount.LastMonthPurchaseValue__c`. Senão termina sem tocar na conta. |
| 6 | `UpdateAccount` | Update em Account `Id = $Record.AccountId`: `Ranking__c` e `LastMonthPurchaseValue__c`. Mais nada. |
| 7 | Fault de `UpdateAccount` | `LogFault` cria `IntegrationLog__c` (mesmos campos e ação da v2, com a ação renomeada para o API name do Flow novo). `GetSetting` lê `ScheduledFlowOpportunitySetting__mdt.Default`. `HasRecipient` verifica se há destinatário: com `FaultRecipient__c` preenchido, `SendFaultEmail` envia `FaultBody` (Id da conta e mensagem de erro, sem dado de cliente); vazio, só log. **A falha não desfaz a gravação da oportunidade** (PA13). |

Descrição do Flow e dos elementos em português, citando EPLAST-47 (achado 4 do assessment).

### 1.3 Condição de entrada (decisão 1 do responsável)

É o menor conjunto de eventos que muda a soma ou a média das ganhas do ano da conta:

```
AND(
  NOT(ISBLANK({!$Record.AccountId})),
  {!$Record.ThisYear__c},
  OR(
    AND(ISNEW(), ISPICKVAL({!$Record.StageName}, "Fechado/Ganho")),
    AND(NOT(ISNEW()), ISCHANGED({!$Record.StageName}),
        OR(ISPICKVAL({!$Record.StageName}, "Fechado/Ganho"),
           ISPICKVAL(PRIORVALUE({!$Record.StageName}), "Fechado/Ganho"))),
    AND(NOT(ISNEW()), ISPICKVAL({!$Record.StageName}, "Fechado/Ganho"),
        OR(ISCHANGED({!$Record.Amount}), ISCHANGED({!$Record.AccountId})))
  )
)
```

O Flow entra quando a oportunidade nasce ganha, passa a ganha, deixa de ser ganha, ou muda de valor ou de conta estando ganha. Não entra nos demais saves de oportunidade, nem em oportunidade criada em ano anterior. `Fechado/Ganho` é a única fase ativa com `IsWon` = true (`OpportunityStage`, conferido hoje). Se o deploy recusar `ISNEW()` na fórmula de entrada, o builder troca o primeiro ramo por `ISBLANK(PRIORVALUE({!$Record.StageName}))` e registra isso no plano.

### 1.4 Ordem em relação ao `OpportunityFlow` (decisão 2 do responsável)

**Escolha: rodar no mesmo save, depois do `OpportunityFlow`, com `triggerOrder` 1500 no Flow novo.** A plataforma roda os Flows after save assim: primeiro os que têm ordem de 1 a 1000, depois os sem ordem, depois os de 1001 a 2000. Os quatro Flows ativos em Opportunity não têm `TriggerOrder` (`FlowDefinitionView`, conferido hoje). Com 1500, o Flow novo roda depois de todos eles, **sem criar versão nova do `OpportunityFlow`**. A média é lida por `GetAccount`, uma consulta feita depois de o `OpportunityFlow` gravar na mesma transação.

Por que não o caminho assíncrono do Flow:
- O `OpportunityTriggerHelper` (Queueable, enfileirado pela `OpportunityTrigger`) também grava a mesma conta depois do commit, pelo `update this.acc` de `UpdateAccountWithProtheusInfo`. Dois assíncronos na mesma conta abrem espaço para `UNABLE_TO_LOCK_ROW` (critério 6).
- Não confirmei em que contexto o caminho assíncrono roda. Se for contexto de job assíncrono, a `AccountTrigger` só poderia enfileirar 1 job ali. É incerteza, e eu não aposto nela.
- No síncrono, a classificação nasce no mesmo save e é fácil de provar no debug log.

**Prova exigida na verificação (não testei: não implanto nesta etapa).** No debug log de um save de oportunidade ganha com cotação aprovada na dev, `Opportunity_AfterSave_ClassificaConta` tem de aparecer depois de `OpportunityFlow`, e `GetAccount` tem de devolver a média já recalculada. Se não aparecer, a verificação sai reprovada e o design volta.

**Risco de ordem de execução (sinalizado):** o resultado depende de o `OpportunityFlow` seguir sem `triggerOrder`. Se alguém der a ele ordem acima de 1500, o Flow novo volta a ler a média anterior. Isso fica escrito na descrição do Flow novo.

**O que o `OpportunityFlow` faz com a média** (lido hoje; não muda nesta demanda):
- Oportunidade em `Fechado/Ganho`: só grava média e total (`UpdateAccount`) se encontrar cotação aprovada (`QuoteFound`). Sem cotação, a média não muda, e o Flow novo classifica pela média que a conta já tem.
- Oportunidade de `Fechado/Ganho` para `Fechado/Perdido`: grava o total e depois a média como `{!$Record.Account.TotalPurchasesThisYear__c}/{!Count}`. Pela leitura, esse total pode ser o anterior à baixa, e com `Count` 0 a divisão é por zero. É comportamento existente, fora do escopo. Fica no relato à Eplast e no roteiro (caso Q7). O Flow novo classifica pelo que estiver gravado no campo, como manda P3 (PA12).

### 1.5 Mapa da ordem de execução num save de oportunidade

| Ordem | Etapa da plataforma | O que roda |
|---|---|---|
| 1 | Before save Flows | `Opportunity_BeforeSave_QualificaOportunidade` (só `StageName` = Qualificação; grava o próprio registro) |
| 2 | Before triggers | `OpportunityBefore` (SBQQ, não legível) |
| 3 | Validation rules | 16 ativas em Opportunity. O Flow novo não grava Opportunity. |
| 4 | After triggers | `OpportunityTrigger` (enfileira `OpportunityTriggerHelper`), `OpportunityAfter` (SBQQ) |
| 5 | After save Flows sem ordem | `OpportunityFlow` (cria Quote/Order/itens; grava média e total em Account, o que dispara a cadeia de Account abaixo; também atualiza o próprio registro, o que pode reentrar no save), `Opportunity_AfterSave_CriaCasoPosVendas` (cria Case), `Oportunidade_Industria` (cria Task) |
| 6 | After save Flow com ordem 1500 | **`Opportunity_AfterSave_ClassificaConta`** (novo): no máximo 1 update de Account |
| 7 | Commit e pós-commit | Queueables: `OpportunityTriggerHelper` (grava a conta e enfileira 1 `SendAccountToProtheus`) e os `SendAccountToProtheus`/`UpdateAccountCompanyInfo` enfileirados pela `AccountTrigger` |

Cada update de Account (do `OpportunityFlow` ou do Flow novo) roda: `AccountBefore` (SBQQ), 6 validation rules de Account (nenhuma olha os campos da demanda; as 4 de telefone barram conta com telefone fora do formato), `AccountTrigger` (1 enqueue por conta, sem filtro de campo), `AccountTriggered` e `UpdateParentAccountUsedLimit` (sem critério de entrada; o segundo grava a conta pai se houver `ParentId`, o que repete a cadeia no pai).

**Reentrada.** O `OpportunityFlow` atualiza `$Record` (Type, FinancialAnalysis__c, TaxAnalysis__c), e isso pode rodar o save de novo na mesma transação. Não confirmei se o Flow novo é reavaliado nessa reentrada. O `HasChanges` deixa a segunda execução sem efeito (mesma soma e mesma classificação, nenhuma gravação). A verificação conta os updates de Account no debug log.

### 1.6 Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Versão nova do agendado, gravando em lotes menores | Continua sendo gravação em massa em Account e o envio em massa ao Protheus que a decisão de 16/11 proíbe. A solução de outubro (agendado em Conta) foi reavaliada pelo responsável e não resolve o limite. |
| Objeto `AccountRanking__c` (rodada 2) | Retirado pelo responsável em 17/11. |
| `Ranking__c` como fórmula | Ver 1.1. |
| Versão nova do `OpportunityFlow` com a classificação dentro | Proibido pela diretriz (CPQ, mais de 2.000 linhas). Também misturaria a demanda com a criação de Pedido. |
| Calcular a média no próprio Flow novo (soma/quantidade) | Tiraria a dependência de ordem. Mas a classificação poderia divergir do campo `AveragePurchasesThisYear__c` que o usuário vê e o Protheus lê, e P3 manda classificar pelo campo. Fica como saída se a Eplast preferir (PA12): troca de uma atribuição em versão nova do Flow novo. |
| Caminho assíncrono | Ver 1.4. |

## 2. Reaproveita, cria, altera, desativa (regra 3 da conta)

| Componente (API name) | Na org (conferido) | Ação |
|---|---|---|
| `Opportunity_AfterSave_ClassificaConta` (Flow) | Não existe (`FlowDefinition`, consulta de hoje) | **Cria.** Flow novo nasce Active, porque não substitui nada (doutrina). Padrão `<Objeto>_<Gatilho>_<Proposito>`, o mesmo de `Opportunity_AfterSave_CriaCasoPosVendas`. API 68.0. |
| `ScheduledFlowOpportunity` (Flow) | v1 Obsolete, v2 Active na dev (v5 Active na QA, pela rodada 3) | **Desativa, não apaga.** Passo separado (seção 7), sem versão nova. A v2 fica no histórico como referência. |
| `RankingRange__mdt` (7 registros) | Existe, faixas certas | **Reaproveita** sem mudança. |
| `ScheduledFlowOpportunitySetting__mdt.Default` | Existe; `RunDayOfMonth__c` 14, `FaultRecipient__c` vazio | **Reaproveita** `FaultRecipient__c`. `RunDayOfMonth__c` perde uso e fica. **Altera só a descrição** do campo `RunDayOfMonth__c` para "Sem uso desde a EPLAST-47 (classificação passou a ser por oportunidade salva)". Não renomeia nem apaga: seria mudança de modelo de dados. |
| `Account.Ranking__c` | Picklist com 7 valores, histórico ligado | **Reaproveita.** Continua o campo vigente. |
| `Account.LastMonthPurchaseValue__c` | Currency | **Reaproveita.** Recebe a soma das ganhas do ano (P4: sem renomear). |
| `Account.AveragePurchasesThisYear__c`, `TotalPurchasesThisYear__c` | Gravados pelo `OpportunityFlow` | **Só leitura** da média. |
| `Opportunity.ThisYear__c` | Fórmula por `CreatedDate` | **Reaproveita** (P2). |
| `IntegrationLog__c` | Existe (16 registros na dev) | **Reaproveita** no caminho de falha. |
| Relatório `AccountRankingChanges` (pasta provisória "EPLAST-47 Relatorios (provisorio, P12)") | Existe, sem filtro: lista toda mudança de campo rastreado | **Altera** (relatório não é versionado): filtro do campo alterado = `Ranking__c`. O builder copia a sintaxe do filtro de um relatório `AccountAuditHistory` da org, ou do describe do tipo, e não adivinha o enum (skill, "Relatórios e painéis"). |
| Relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` (pasta MARKETING CLOUD) | Lê `Ranking__c` como coluna, sem filtro de valor | **Não toca.** Os 7 valores aparecem sozinhos. |
| Permission set `Protheus`, `PS_Comercial_*`, perfis | Existem | **Não toca** (seção 5). |
| `OpportunityFlow`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, `AccountTrigger`, `AccountTriggerHelper`, `TriggerUtility__mdt`, `OpportunityTrigger`, classes Protheus | Existem | **Não toca** (restrição de 16/11). |
| Agente `SFAgent2` | Existe | Não se aplica. Não é demanda de assistente. |

## 3. Limites de governador e escala

### 3.1 Jobs enfileirados por oportunidade salva (decisão 3 do responsável)

Contagem feita pela metadata. O número real será confirmado no debug log da verificação.

| Evento | Antes (hoje, síncrono) | Depois |
|---|---|---|
| Passa a ganha com cotação aprovada | `OpportunityFlow` `UpdateAccount`: 1 update → 1 enqueue; `OpportunityTrigger`: 1 enqueue do helper. **≈ 2** (+1 se a conta tem pai, por `UpdateParentAccountUsedLimit`) | +1 update e +1 enqueue só se a classificação ou a soma mudou. **≈ 3** (+2 com pai) |
| Ganha → perdida | 2 updates do `OpportunityFlow` + helper. **≈ 3** (+2 com pai) | **≈ 4** (+3 com pai) |
| Ganha sem cotação, ou valor/conta muda | helper. **≈ 1** | **≈ 2** |
| Save que não atende à entrada | sem mudança | sem mudança (o Flow novo não roda) |

Teto síncrono de 50: o pior caso fica em torno de 7, bem abaixo. Depois do commit, o `OpportunityTriggerHelper` grava a conta numa transação própria e enfileira 1 `SendAccountToProtheus`, como já faz hoje.

SOQL e DML do Flow novo por transação, com as interviews agrupadas: 2 SOQL (`GetAccount`, `GetOpportunities`), mais as consultas de metadado personalizado (`GetRanges`, `GetSetting`), que não contam no limite de SOQL. 1 DML em Account, mais 1 de `IntegrationLog__c` na falha. É pouco, mas o save de oportunidade ganha já é pesado (CPQ, Pedido, itens). A verificação registra o total de SOQL, DML e CPU do save, de modo que dê para comparar antes e depois do Flow novo.

### 3.2 Carga em massa (decisão 4 do responsável)

200 oportunidades ganhas de contas diferentes numa transação (importação ou integração): o `OpportunityFlow` já grava as contas, e o limite de 50 já existe hoje, sem esta demanda. **O Flow novo piora o teto**: acrescenta até 1 enqueue por conta. Com cotação aprovada, o máximo antes de falhar cai de cerca de 25 para cerca de 16 contas distintas por transação. O efeito vale só para contas cuja classificação ou soma mudou. Não corrijo aqui (diretriz). Fica no relato à Eplast junto com a correção sugerida do `UpdateAccountCompanyInfo`: a raiz é a `AccountTrigger` enfileirar um job por conta. Com o caminho de falha (1.2), a gravação da conta falha, mas a carga de oportunidades não cai pelo Flow novo. A falha de limite do `OpportunityFlow` continua como é hoje.

### 3.3 Um pai com muitos filhos (achado SOMOSAGILITY-10)

- Conta com muitas ganhas no ano, salva uma por vez: cada execução percorre todas as ganhas do ano da conta. Algumas centenas de iterações de laço não pesam em CPU.
- Muitas oportunidades da **mesma** conta numa transação: cada interview percorre a lista inteira (N × M iterações). Pior que isso, várias interviews podem tentar gravar a mesma conta no mesmo DML agrupado. **Não confirmei** como o runtime do Flow trata Id repetido no update agrupado. Caso V5 da verificação: 20 oportunidades ganhas da mesma conta numa inserção só. Critério da doutrina: se CPU passar de 70% (7 s), ou se aparecer "Duplicate id in list", o design volta para revisão. A saída provável é deduplicar por conta antes do update.
- Volume na QAS: o card cita 1.217 contas. Quantas oportunidades por conta: não medido.

## 4. Permissões

- Nenhum campo, objeto ou permission set novo. O Flow disparado por registro roda em contexto de sistema (padrão da plataforma para after save). Quem salva a oportunidade não precisa enxergar `Ranking__c`.
- O permission set `Protheus` continua lendo os mesmos 3 campos.
- **Não confirmado:** OWD de Account e Opportunity e o que os `PS_Comercial_*` concedem. Não muda o desenho, porque o Flow não depende do acesso do usuário. O caso de acesso negado (usuário de teste da regra 6, `005bJ00000piKAaQAM`, ativo, Administrador do sistema) não se aplica a uma automação de sistema. O roteiro não precisa dele.

## 5. Preparação do Sales Cloud para o Marketing Cloud (regra 2 da conta)

A demanda toca segmentação de contas (classificação), então a seção entra. **A esteira não faz nada no Marketing Cloud.**

- **Dado que o Marketing Cloud pode ler:** `Account.Ranking__c` (MP, PP, P, M, G, GG, 3G) e `Account.LastMonthPurchaseValue__c` (soma das ganhas do ano). Nenhum campo novo.
- **Como o segmento fica identificável no CRM:** pelo valor de `Ranking__c`, já usado como coluna no relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` da pasta MARKETING CLOUD. Dos 68 relatórios da pasta, esse é o único que cita `Ranking__c`, e nenhum cita os campos de compra (retrieve e grep de hoje). O recon de 16/11 contava 7. As mudanças ficam no histórico de campo e no `AccountRankingChanges`.
- **O que o Marketing Cloud devolve:** nada nesta demanda.
- **Consentimento e opt-out:** não se aplica. A demanda não cria comunicação nem público.
- **Conector `et4ae5`:** instalado. 0 campos `et4ae5__` em Account (consulta de hoje). Não sei se alguma extração ou sincronização do lado do Marketing Cloud lê `Ranking__c`: isso não é visível pelo CRM.
- **Para quem opera o Marketing Cloud:** (1) se algum público ou filtro usa `Ranking__c`, incluir MP e 3G e rever as faixas antigas; (2) a classificação passa a mudar a cada oportunidade ganha ou perdida, e não mais uma vez por mês. Público montado por data pode ver mudanças no meio do mês.

## 6. Riscos

### 6.1 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Ordem de execução**: o Flow novo ler a média antes de o `OpportunityFlow` gravá-la | **Alta** | `triggerOrder` 1500 e `GetAccount` explícito (1.4). Prova no debug log da verificação (V2). |
| R2 | A média não ser atualizada pelo `OpportunityFlow` (ganha sem cotação aprovada; baixa para perdida com total anterior ou divisão por zero) | Média | Comportamento existente. A classificação segue o campo (PA12). Vai para o relato à Eplast e para o roteiro (Q7). |
| R3 | Carga em massa de oportunidades reduz o teto de contas distintas por transação | Média | Declarado (3.2). Sem correção nesta demanda. |
| R4 | Muitas oportunidades da mesma conta na mesma transação (CPU, Id repetido no update) | Média | Caso V5. Volta ao design se falhar. |
| R5 | Update da conta barrado por validation rule de telefone ou pela `AccountTrigger` | Média | Caminho de falha: log, e-mail se houver destinatário, e a oportunidade salva. Caso V6. |
| R6 | Reentrada do save pelo `OpportunityFlow` executar o Flow novo duas vezes | Baixa | `HasChanges` deixa a segunda execução sem efeito. A verificação conta os updates. |
| R7 | Agendado e Flow novo ativos ao mesmo tempo até a desativação | Baixa | O agendado só age no dia 14. A desativação vem logo depois da verificação, e o próximo dia 14 é 14/12. |
| R8 | Cada classificação gravada gera um envio ao Protheus (ERP de produção, porta 8400, na linha de base) | Média | É aceito pelo responsável (15/11) para teste com dado sintético. O Protheus não recebe `Ranking__c` (`AccountAdapter`, `ProtheusAPI` e `UpdateAccountWithProtheusInfo` sem referência, grep de hoje). O teste lista o que saiu. |

### 6.2 Riscos do assessment que tocam o escopo

| Achado | Como o design trata |
|---|---|
| 1. Automação concorrente em Account, Opportunity e Order | Mapa em 1.5. Ordem resolvida por `triggerOrder`. Nada em Order é gravado pelo Flow novo. |
| 2. Cobertura Apex de 10% | Sem Apex novo: o build não depende de cobertura. Apex existente roda no teste (triggers, CPQ, Protheus). Erro de Apex existente no save de teste é achado, não falha do Flow novo, desde que o Flow novo não seja a causa. |
| 3. Validation rules de Order (23) | O Flow novo não grava Order. O `OpportunityFlow` cria Pedido quando a ganha tem cotação aprovada, então a fixture tem de passar por elas. Se uma VR de Order barrar o save, o roteiro registra o erro como comportamento existente. |
| 4. Campos sem descrição | O Flow novo nasce com descrição em tudo. Descrição atualizada em `RunDayOfMonth__c`. Os campos de compra seguem sem descrição (fora do escopo). |
| 6. Dúvida dev × qa | Resolvido pela regra 5. |
| 10. `OrderTrigger` duplicado (SBQQ e custom) | Não toca. Roda no Pedido criado pelo `OpportunityFlow` no teste. |
| 5, 7, 8 (classes de teste, perfil Financeiro, 33 perfis) | Não se aplicam: sem Apex, sem permissão nova, sem perfil. |

## 7. Versões e ativação

| Componente | Ação | Quando | Como desfazer |
|---|---|---|---|
| `Opportunity_AfterSave_ClassificaConta` | Deploy como Active na dev (Flow novo) | Build | Desativar o Flow |
| Relatório `AccountRankingChanges` | Filtro novo | Build | Tirar o filtro |
| `ScheduledFlowOpportunitySetting__mdt.RunDayOfMonth__c` | Descrição | Build | Voltar à descrição anterior |
| `ScheduledFlowOpportunity` | **Desativar** (dev: v2 sai, nenhuma entra). Passo separado, depois de o verificador provar V1 a V6. No pacote para a QA vai como `FlowDefinition` com versão ativa 0 (ou equivalente que o builder confirmar) | Fim da verificação na dev; na QA, pelo deploy da esteira | Reativar a versão anterior |

O builder registra isso na seção "Versões e ativação" do `04-plano-build.md`.

## 8. Plano de teste

Dado sintético com "TESTE EPLAST-47" no nome, montado pelos scripts de `fixtures/` (regra 6). Conta criada com `TriggerUtility.bypassTrigger`. Oportunidade salva **sem** o desvio, porque ele também desliga a `OpportunityTrigger` e esconderia a contagem de jobs. A oportunidade precisa passar pelas 16 validation rules de Opportunity: a conta precisa de endereço, CNAE, e-mail, telefone e loja sintéticos no formato válido. Para o caminho com média, é preciso cotação aprovada, ou a média gravada direto na conta de teste na fixture. Contagem de registros só agregada. Ao final, listar Pedidos, Cotações, Casos, Tasks e `IntegrationLog__c` criados pela cadeia, e os envios ao Protheus (autorização de 15/11).

**Verificação na dev (verificador):**

| Caso | Prova |
|---|---|
| V1 | Oportunidade ganha nova: a conta recebe `Ranking__c` da faixa da média e `LastMonthPurchaseValue__c` = soma. 1 linha nova de `AccountHistory` para `Ranking__c`. |
| V2 | Debug log: `Opportunity_AfterSave_ClassificaConta` depois de `OpportunityFlow`, e `GetAccount` com a média nova. Quantidade de updates de Account e de `System.enqueueJob` no save (esperado ≤ 7). SOQL, DML e CPU do save. |
| V3 | Save que não muda fase, valor nem conta: o Flow novo não aparece no log. |
| V4 | Mesmo save repetido com valores iguais: nenhuma gravação nova em Account (`HasChanges`). |
| V5 | 20 ganhas da mesma conta numa inserção: sem "Duplicate id in list". CPU registrada (< 70%). |
| V6 | Falha forçada (conta de teste com telefone fora do formato de uma das 4 VRs): `IntegrationLog__c` criado, oportunidade salva, sem e-mail (destinatário vazio). |
| V7 | XML final: nenhum limite das faixas antigas fora de `RankingRange__mdt`; nenhum endereço de e-mail fixo (critérios 12 e 15). |

**QA na sandbox de QA (roteiro):**

| Caso | Critério da análise | O que provar |
|---|---|---|
| Q1 | 4 (redefinido em 17/11) | Uma oportunidade que atende à entrada grava no máximo uma vez a conta dela, e nenhuma outra conta. |
| Q2 | 6 (redefinido) | Oportunidades de 3 contas salvas em transações separadas: 0 `UNABLE_TO_LOCK_ROW` e 0 "Too many queueable jobs" nos `IntegrationLog__c` da ação nova. |
| Q3 | 8 | Ganhas de 3.000 e 2.000 e uma perdida de 9.000: soma 5.000. |
| Q4 | 9 | Conta com uma única ganha que passa a perdida: `LastMonthPurchaseValue__c` = 0. A classificação segue a média gravada (PA3, PA12). É assim que o critério 9 vira exercitável a partir de um evento de oportunidade. |
| Q5 | 10, 11 | As 12 bordas das faixas e média 0 (MP) e vazia (mantém). Pode ser feito com média sintética na conta de teste (gravada na fixture com o desvio) e um save de oportunidade que entre no Flow. Na QAS a regra é não ler nem alterar registro que o agente não criou. |
| Q6 | 13, 14 | Picklist com os 7 valores. `AccountRankingChanges` mostra só mudanças de `Ranking__c`, com valor anterior e novo, pela Analytics API, só contagens e rótulos. |
| Q7 | 16 e R2 | Falha forçada com destinatário vazio: só log. Registrar o que o `OpportunityFlow` faz com a média na baixa para perdida. |
| Q8 | estado | `ScheduledFlowOpportunity` sem versão ativa na QA depois do deploy. `ScheduledFlowOpportunitySetting.Default` com `RunDayOfMonth__c` = 14 (a rodada 3 deixou 15 e o início às 17:10). Se a esteira não devolveu, o QA registra, e a correção é pelo pacote, não por DML do agente. |

Critérios 5, 7 e 18 não se aplicam (consulta por conta já garantida pelo filtro; D3; volume mensal extinto). Critérios 1 a 3 estão cobertos pelo `02-recon.md`, pela análise e por este design.

## 9. O que NÃO será feito nesta demanda

- Recálculo de todas as contas (entrada das faixas novas, virada do ano): é o card EPLAST-48, executado por uma pessoa em lotes pequenos.
- Qualquer mudança em `OpportunityFlow`, `AccountTrigger`, `AccountTriggerHelper`, `TriggerUtility__mdt`, `OpportunityTrigger`, classes do Protheus, CPQ ou Order.
- Correção do `UpdateAccountCompanyInfo` e do cálculo da média na baixa para perdida: só relato à Eplast.
- Excluir o `ScheduledFlowOpportunity`, renomear ou apagar `ScheduledFlowOpportunitySetting__mdt` ou `RunDayOfMonth__c`.
- Período configurável (D3), objeto `AccountRanking__c`, permission set novo.
- Qualquer coisa no Marketing Cloud.
- Promoção para QAS e produção além da QA da esteira (EPLAST-48).

## 10. Premissas assumidas (validar na homologação)

Regra 4 da conta. **Nenhuma se enquadra no caso 3: não há pergunta bloqueante.** P2, P3, P4 e P7 foram respondidas pelo Leonardo em 14/11. P9 foi respondida pela decisão de 17/11 (a cadência passa a ser por oportunidade salva).

- [x] **PA1 (P1). Base anual e só ganhas?** Decisão: soma das oportunidades `Fechado/Ganho` com `ThisYear__c`, como na v1. Evidência: Flow da org e a diretriz de 14/11 ("a regra de negócio atual não muda"). Como mudar: filtro de `GetOpportunities` em versão nova do Flow novo.
- [x] **PA2 (P5). O aviso de falha é operacional?** Decisão: operacional, por e-mail simples do Flow só para `FaultRecipient__c`, sem dado de cliente. Evidência: é erro técnico, não comunicação com cliente; a regra 2 trata de comunicação de marketing. Como mudar: deixar o destinatário vazio (só log).
- [x] **PA3 (P6). Conta sem compra?** Decisão: soma 0 em `LastMonthPurchaseValue__c`. Média vazia mantém a classificação, nunca GG. Média 0 vira MP. Evidência: soma de nada é 0; o critério 11 proíbe cair em GG. Como mudar: uma atribuição em versão nova.
- [x] **PA4 (P8). O Protheus aceita MP e 3G?** Decisão: a solução não muda o que vai ao ERP. Evidência: `AccountAdapter`, `ProtheusAPI` e `UpdateAccountWithProtheusInfo` sem `Ranking__c` (grep de hoje). Não li `ProtheusAPI` linha a linha, e a configuração do lado do ERP não é visível. Como mudar: se o ERP passar a ler a classificação, é demanda de integração.
- [x] **PA5 (P10). Volume de teste?** Decisão: o critério 18 deixa de se aplicar (decisão de 17/11). No lugar, os casos V2, V5 e Q2. Como mudar: a Eplast informa um cenário de carga, e ele vira caso de teste.
- [x] **PA6 (P11). Destinatário da falha?** Decisão: `FaultRecipient__c` vazio até a Eplast informar; sem destinatário, só log. Evidência: vazio na dev (contagem de hoje). Não sei o valor na QA e na QAS. Como mudar: preencher o registro `Default`, sem versão nova.
- [x] **PA7 (P12). Onde fica o relatório?** Decisão: segue na pasta provisória atual. Evidência: é onde o `AccountRankingChanges` está. Como mudar: mover de pasta.
- [x] **PA8 (nova). Oportunidade ganha que troca de conta.** Decisão: só a conta nova é recalculada; a antiga mantém a classificação até o próximo evento ou o recálculo da EPLAST-48. Evidência: a diretriz de 17/11 limita a uma conta por execução. Como mudar: um segundo update para `$Record__Prior.AccountId`, em versão nova (2 contas por save, ainda bem abaixo de 50).
- [x] **PA9 (nova). Exclusão e restauração de oportunidade ganha.** Decisão: não recalculam. Evidência: after save não cobre exclusão; o `OpportunityFlow` também não trata exclusão. Como mudar: Flow before delete próprio.
- [x] **PA10 (nova). Fase ganha.** Decisão: entrada e soma por `StageName = Fechado/Ganho`. Evidência: única fase ativa com `IsWon` (consulta de hoje), e é o filtro da v1. Como mudar: trocar por `IsWon` em versão nova se surgir outra fase ganha.
- [x] **PA11 (nova). Oportunidade de ano anterior.** Decisão: não dispara o Flow (`ThisYear__c` na entrada), porque não entra na soma. Evidência: P2 (data de criação). Como mudar: tirar a condição.
- [x] **PA12 (nova). Classificar pelo campo de média mesmo quando o `OpportunityFlow` não o atualiza.** Decisão: classifica por `AveragePurchasesThisYear__c` como gravado (ganha sem cotação aprovada não atualiza a média; a baixa para perdida usa o total anterior). Evidência: P3 ("classifica pela média, como hoje") e a leitura do `OpportunityFlow` de hoje. Como mudar: calcular a média no Flow novo (soma/quantidade), em versão nova.
- [x] **PA13 (nova). Falha da classificação não barra a venda.** Decisão: o caminho de falha registra e deixa a oportunidade salvar. Evidência: padrão do squad (falha de automação secundária não bloqueia o processo principal) e o comportamento da v2. Como mudar: tirar o caminho de falha (o erro passa a barrar o save).
- [x] **PA14 (nova). O que fazer com o agendado.** Decisão: desativar e não apagar; `RunDayOfMonth__c` fica sem uso e documentado. Evidência: proposta da diretriz de 17/11, e é a opção mais fácil de desfazer. Como mudar: reativar a versão anterior.

## 11. Incertezas abertas (não afirmadas como fato)

1. Se o `triggerOrder` 1500 garante, na prática, a leitura da média nova: prova na V2.
2. Contexto de execução do caminho assíncrono do Flow (motivo secundário para não usá-lo).
3. Como o update agrupado do Flow trata Id repetido de conta (V5).
4. O que `AccountTriggered` (`CheckRecord`) e `UpdateParentAccountUsedLimit` fazem quando só `Ranking__c` e a soma mudam. Sei que entram em toda atualização.
5. Se a `OpportunityTrigger` enfileira um helper por transação ou por registro (afeta a contagem da 3.1).
6. `FaultRecipient__c` na QA e na QAS; estado da QA (v5, dia 15, início 17:10) vem da rodada 3 e do card, não de consulta minha.
7. OWD, perfis e `PS_Comercial_*` (não mudam o desenho).
8. Se alguma extração do Marketing Cloud lê `Ranking__c` (não visível pelo CRM).
9. Se `SFAgent2` referencia `Ranking__c` ou os campos de compra (não verificado; a demanda não o altera).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Decisão do responsável (2026-11-17, depois da rodada 4 de QA): desativar o agendado agora; critério 16 fica para a homologação

Registrada por autorização de Leonardo Barbosa para conduzir a demanda (17/11). Fica dentro
da diretriz de 17/11 e da seção 7 deste desenho; não muda regra de negócio.

**O que a rodada 4 de QA mostrou.** Classificação, soma, histórico, relatório e ausência de
erro de limite passaram na sandbox de QA (casos Q1 a Q6, 12 bordas). Reprovou por um motivo:
o `ScheduledFlowOpportunity` continua **ativo e agendado** na QA (v7 Active, `CronTrigger` em
espera), porque o build deixou a desativação como "passo separado, pendente" à espera do
caso V6.

**Decisão 1 — desativar o `ScheduledFlowOpportunity` neste build.** A condição "depois de o
verificador provar V1 a V6" (seção 7) passa a ser "depois de V1 a V5", que já passaram na dev
e na QA. O builder inclui a desativação **no pacote** (FlowDefinition com versão ativa 0, ou
o equivalente que ele confirmar por dry-run), implanta na dev, confere que o Flow ficou sem
versão ativa e sem agendamento pendente, e registra em "Versões e ativação" do plano de
build. Não apagar o Flow nem as versões. Nada mais muda no pacote: o Flow novo, as faixas, o
relatório e o metadado ficam como estão (não reconstruir o que passou).

**Decisão 2 — critério 16 (falha forçada, V6/Q7) fica para a homologação, não bloqueia.**
Não é exercitável pela esteira: na dev as validation rules não deixam criar conta inválida,
e na QA a regra `CheckAccountOwnerHasProtheusSellerId` barra a própria oportunidade antes do
Flow novo; provocar a falha exigiria alterar usuário de terceiros ou dado real, o que a
esteira não faz. O caminho de falha fica provado por leitura do Flow (fault de
`UpdateAccount` → `LogFault` → e-mail só com destinatário). O QA marca o caso como "não
exercitável, validar na homologação", **sem reprovar por ele**, e o repete no roteiro do
cliente em "O que assumimos e você precisa confirmar".

**Decisão 3 — "média vazia mantém a classificação" (C11b).** Provado na QA pelo caso Q4
(ganha que passa a perdida deixa a média vazia e a classificação se mantém). Fechado.

**Para o QA da próxima rodada.** Reteste só o que mudou e o estado: Q8 (agendado sem versão
ativa e sem `CronTrigger` em espera na QA depois do deploy) e uma amostra de regressão da
classificação (3 bordas bastam). Os demais casos da rodada 4 valem como evidência; cite-os.
Se o deploy da esteira não desativar o agendado na QA, isso é defeito do pacote (reprova).

## Decisão do responsável (2026-11-17, depois da rodada 5 de QA): o pacote tem de desativar o agendado na QA de verdade

Registrada por autorização de Leonardo Barbosa para conduzir a demanda (17/11). É correção
de defeito do pacote; não muda o desenho nem regra de negócio.

**O que a rodada 5 mostrou.** O deploy da esteira na QA (`0AfHa00000EJ3yDKAT`) levou juntos
`flowDefinitions/ScheduledFlowOpportunity.flowDefinition-meta.xml` (`activeVersionNumber` 0)
e `flows/ScheduledFlowOpportunity.flow-meta.xml`, que ainda traz `<status>Active</status>`.
Resultado: a QA criou a v8 **ativa**, com `CronTrigger` em espera. Na dev a desativação
funcionou porque o builder implantou só a definição. O pacote que vai à QA é montado pela
esteira com **todo arquivo de `force-app` que o branch mudou em relação à `main`**, e o
arquivo do Flow agendado está nesse conjunto desde a rodada 1.

**O que o builder faz (só isto):**
1. Corrigir o pacote para que o conjunto que a esteira implanta na QA deixe o
   `ScheduledFlowOpportunity` **sem versão ativa**. Dois caminhos aceitos; escolha o que
   provar na dev:
   - (a) no `flows/ScheduledFlowOpportunity.flow-meta.xml`, trocar `<status>Active</status>`
     por `<status>Obsolete</status>` (ou `Draft`, se `Obsolete` for recusado), mantendo a
     definição com `activeVersionNumber` 0; ou
   - (b) devolver `flows/ScheduledFlowOpportunity.flow-meta.xml` ao conteúdo que está na
     `main` (o arquivo deixa de fazer parte do que o branch mudou e sai do pacote), deixando
     só a definição com `activeVersionNumber` 0.
2. **Provar na dev com o mesmo conjunto que irá à QA**, não só com a definição: reativar a
   v2 do agendado na dev (para partir do estado em que a QA está: uma versão ativa),
   implantar **juntos** todos os arquivos que `05-deploy-qa.md` lista para o agendado e o
   Flow novo, e conferir: `FlowDefinitionView.ActiveVersionId` nulo para
   `ScheduledFlowOpportunity`, nenhuma versão `Active` em `Flow` (Tooling), e 0 linhas em
   `CronTrigger` com nome `ScheduledFlowOpportunity%`. Registrar comandos e resultados em
   "Versões e ativação" do `04-plano-build.md`.
3. Não tocar no Flow novo, nas faixas, no relatório nem no metadado. Não apagar o Flow
   agendado nem suas versões.

**Para o verificador.** Repetir a prova do item 2 por consulta (estado do agendado na dev) e
conferir que `Opportunity_AfterSave_ClassificaConta` segue ativo. Não é preciso refazer as
bordas: valem as evidências das rodadas anteriores.

**Para o QA.** Reconferir Q8 (agendado sem versão ativa e sem `CronTrigger` em espera na QA
depois do deploy) e 3 bordas da classificação. O critério 16 segue para a homologação, sem
reprovar (decisão anterior).
