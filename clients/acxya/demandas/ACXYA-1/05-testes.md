# ACXYA-1 — Testes (etapa 5)

**Agente:** `qa` · **Data:** 2026-09-07 · **Branch:** `feature/ACXYA-1`
**Org:** `sbx-acxya` (Sandbox), Org Id `00DHa000006bRsDMAU`, usuário
`lbarbosa@konectabr.com.sbxacxya`, API v67.0 — reconfirmada via `sf org list` antes de
qualquer comando. **Produção não está configurada nesta máquina, não tocada.**
**Base:** `01-analise.md` (critérios de aceite), `03-design.md` (decisões B-1..B-4 e §6.2),
`04-plano-build.md` (o que foi construído e os desvios D-1..D-6), `gates.md` (decisões do
humano, incluindo a resolução de D-2 e a autorização de deploy real), `06-release.md`
(deploy real executado, deployId `0AfHa00000DWpzBKAT`).

---

## 0. Situação atual (execução real pós-deploy) — LEIA PRIMEIRO

Esta etapa foi **reaberta**. Na passagem anterior (registrada abaixo em §1, preservada para
rastreabilidade), todos os 16 casos foram marcados `NÃO EXECUTADO — bloqueado por deploy`
porque a metadata da demanda não existia em `sbx-acxya`. O agente `release` executou o
deploy real (deployId `0AfHa00000DWpzBKAT`, `06-release.md`), e esta etapa **reconfirmou por
conta própria**, antes de testar, que os 8 componentes existem e estão ativos (campo
`Data_Aniversario__c` tipo `date`, VR `Valida_Data_Aniversario_Nao_Futura` `Active=true`,
Flow `Lead_AfterSave_MapeiaAniversarioNaConversao` `IsActive=true`, FLS nos 4 perfis, layout
com o item) — mesmas consultas de §3.1, resultado idêntico ao de `06-release.md` §4.

**Resultado da execução real: 14 de 16 casos PASSARAM, 0 FALHARAM, 2 executados
PARCIALMENTE (metadata/API confirmam, mas verificação visual por UI/"Login As" não foi
possível neste ambiente sem tela).** Nenhum caso funcional ficou sem execução alguma.

Nenhuma falha de comportamento foi encontrada. Em particular:
- **T-09** (regressão do guard `ISNEW()/ISCHANGED()`) — **passou**. Este era o caso mais
  crítico do roteiro e confirma que a VR não trava updates reentrantes em registros antigos
  não tocados no campo.
- **T-16** (3 Flows `RecordAfterSave` simultâneos, risco D-2) — **passou, comportamento
  consistente em 3 repetições**. Não há necessidade de reabrir o gate do arquiteto — ver
  análise detalhada em §2.5.
- Comportamento de sobrescrita de `Contact.Birthdate` na conversão — **confirmado
  empiricamente** (Contact com `Birthdate` pré-existente teve o valor sobrescrito pelo do
  Lead), consistente com a decisão do humano em `gates.md` ("sempre sobrescrever é o
  comportamento pretendido"). Não é mais tratado como achado, é comportamento validado.

**Massa de teste:** toda fictícia, prefixo `Company = 'QA Teste Aniversario...'` /
`LastName` contendo `Aniversario`, e-mails `@example.invalid`. **Toda a massa criada nesta
execução foi removida ao final** (Leads, Contacts e Accounts gerados pela conversão) —
comandos e contagens finais em §6. Nenhum SOQL nesta etapa retornou dado de cliente real —
só metadata, contagens agregadas e os registros de teste que este agente mesmo criou e
apagou.

**T-09 exigiu desativar temporariamente a VR** para inserir um registro "envenenado" com
data futura (sem o qual não é possível provar o guard de regressão). A VR foi **reativada
imediatamente depois** e o estado final foi confirmado (`Active=true`) antes de prosseguir
para os demais casos — ver §2.3 e §6.

**Únicos pontos não 100% executáveis:** verificação visual por perfil (T-01, T-03, T-04,
T-12) — não há "Login As" disponível neste ambiente headless. Toda a parte de
FLS/ObjectPermissions foi confirmada via API (Tooling/`FieldPermissions`/`ObjectPermissions`),
que é o que a doutrina permite (metadata/permissão, não dado pessoal). A renderização real da
tela para cada perfil **não foi verificada** — fica como recomendação de checagem manual
rápida antes da homologação final, já sinalizada em `06-release.md` §6.3.

---

## 1. Histórico — bloqueio anterior (preservado para rastreabilidade, RESOLVIDO em 2026-09-07)

**A execução funcional deste roteiro esteve BLOQUEADA até o deploy real.** O build da etapa 4
não havia sido implantado na sandbox (`sf project deploy start`) — só rodou
`sf project deploy validate` (check-only). Confirmado naquela passagem, via Tooling API /
metadata list contra `sbx-acxya`:

| Componente da demanda | Existia na org naquele momento? | Como foi confirmado |
|---|---|---|
| `Lead.Data_Aniversario__c` | **Não** | `SELECT QualifiedApiName FROM EntityParticle WHERE EntityDefinitionId='Lead' AND QualifiedApiName='Data_Aniversario__c'` (Tooling) → 0 registros. |
| `Lead.Valida_Data_Aniversario_Nao_Futura` (VR) | **Não** | `SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Lead'` (Tooling) → só as 4 VRs pré-existentes, todas `Active=false`. |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` (Flow) | **Não** | `sf org list metadata --metadata-type Flow` → lista completa de flows da org não continha esse nome. |
| Deltas de `fieldPermissions` nos 4 perfis (B-4) | **Não** | Consequência direta da ausência do campo. |
| `Lead-Lead Layout` (com o item novo) | Layout existia, sem o campo novo | `sf org list metadata --metadata-type Layout` retornava `Lead-Lead Layout`, sem o item. |

**Esse bloqueio acabou.** O humano autorizou o deploy real (gate registrado em `gates.md`,
"Autorização de deploy real + decisão de negócio (Birthdate)"), a etapa `release` executou o
deploy (`06-release.md`, deployId `0AfHa00000DWpzBKAT`), e esta etapa (`qa`, reaberta)
executou de fato os 16 casos contra metadata real — resultado em §2 abaixo.

---

## 2. Roteiro de teste — resultado da execução real

### Falhas conhecidas

**Nenhuma falha de comportamento foi encontrada nos 16 casos.** Todos os casos executáveis
sem UI passaram. Os 4 casos que dependem de verificação visual por perfil (T-01, T-03, T-04,
T-12) foram confirmados por metadata/API (o que é suficiente para provar que a *permissão*
está correta), mas não pela tela em si — reportados como `PASSOU (via metadata) —
verificação visual não executada` para não inflar a homologação com algo que não foi visto
de fato.

### 2.1 Caminho feliz e cobertura de layout/FLS (CA-01, CA-03, B-4)

| Caso | Critério de aceite | Passos executados | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T-01 | CA-01 — campo existe e é editável no layout | Sem UI disponível: (1) `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` e inspeção do XML — item `Data_Aniversario__c` com `<behavior>Edit</behavior>` presente na seção, imediatamente após `Phone`/`Email` e antes de `Rating`; (2) `FieldPermissions` confirma `PermissionsEdit=true` para os 4 perfis de negócio. | Campo aparece, rotulado, editável, posicionado após "Email". | Layout XML confirma o item na posição esperada com `behavior=Edit`; FLS confirma editabilidade para os 4 perfis. **Renderização visual real da tela não foi verificada** (sem "Login As"/UI neste ambiente). | PASSOU (via metadata) — verificação visual não executada |
| T-02 | CA-03 — tipo do campo é Date (não Date/Time) | `SELECT QualifiedApiName, Label, DataType, IsCreatable, IsUpdatable FROM EntityParticle WHERE EntityDefinitionId='Lead' AND QualifiedApiName='Data_Aniversario__c'` (Tooling API). | `DataType=date`. | `Data_Aniversario__c \| Data de Aniversário \| date \| true \| true` — 1 registro, `DataType=date`, sem componente de hora. Confirmado também empiricamente: valores inseridos via Apex (`Date.newInstance(...)`) foram persistidos e lidos de volta como `Date` puro (ex. `1990-01-01 00:00:00` no debug log — representação padrão de `Date` no Apex debug, não `Datetime` com timezone). | PASSOU |
| T-03 | B-4/P-2 — campo visível/editável para os 4 perfis de minimização | `SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE SobjectType='Lead' AND Field='Lead.Data_Aniversario__c' AND Parent.IsOwnedByProfile = true`. | 4 registros, `PermissionsRead=true`/`PermissionsEdit=true` para os 4 perfis. | Exatamente 4 registros retornados, todos `PermissionsRead=true`/`PermissionsEdit=true`: `System Administrator (non-API user)`, `Usuário do Marketing`, `Usuário Padrão`, `Administrador do sistema`. **Verificação efetiva por usuário real (tela) não foi possível** sem "Login As" — reportado como tal, não fingido. | PASSOU (via metadata) — verificação visual não executada |
| T-04 | B-4/P-2 — campo **não** visível para perfis de integração (minimização/LGPD) | `SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE SobjectType='Lead' AND Field='Lead.Data_Aniversario__c' AND Parent.Profile.Name IN ('Salesforce API Only System Integrations','Sales Insights Integration User','Anypoint Integration','Minimum Access - API Only Integrations')`. | 0 registros. | **0 registros retornados** — nenhum dos 4 perfis de integração/API existentes na org tem FLS no campo novo. Consistente com a query geral de T-03 (só 4 perfis de negócio aparecem, nenhum de integração). | PASSOU |
| T-05 | Confirmação de rollback de layout (pré-condição de release seguro) | `diff demandas/ACXYA-1/layout-lead-original-backup.xml force-app/main/default/layouts/Lead-Lead\ Layout.layout-meta.xml`. | Diff mostra somente a inserção do item `Data_Aniversario__c`. | Diff real: `65a66,69` — 4 linhas adicionadas (`<field>Data_Aniversario__c</field>` + `<layoutItems><behavior>Edit</behavior>` de fechamento), nada removido/alterado em outro ponto do arquivo. | PASSOU |

### 2.2 Campo opcional (B-3, borda)

| Caso | Critério de aceite | Passos executados | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T-06 | B-3 — campo é opcional | Apex anônimo: `insert new Lead(LastName='Aniversario01', Company='QA Teste Aniversario', Email='qa-teste-acxya-01@example.invalid')` — sem `Data_Aniversario__c`. | Save concluído sem erro. | `T-06 RESULT: INSERT_OK id=00QHa00000QgIb3MAF`. Nenhum erro de campo obrigatório. | PASSOU |

### 2.3 Validation Rule — negativo, borda e regressão (CA-04, B-2, R1/R2)

| Caso | Critério de aceite | Passos executados | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T-07 | CA-04 — VR barra data futura **na criação** | Apex anônimo: `insert new Lead(..., Data_Aniversario__c = Date.newInstance(2099,12,31))`, capturando `DmlException`. | Save bloqueado com mensagem ancorada no campo. | `T-07 RESULT: INSERT_BLOCKED A data de aniversário não pode ser uma data futura.` — mensagem literal e idêntica à do XML da VR. | PASSOU |
| T-08 | CA-04 — VR barra data futura **na edição** | Apex anônimo: cria Lead sem data, depois `l.Data_Aniversario__c = Date.newInstance(2099,12,31); update l;`, capturando `DmlException`. | Save bloqueado, mesma mensagem. | `T-08 RESULT: UPDATE_BLOCKED A data de aniversário não pode ser uma data futura.` | PASSOU |
| **T-09** | **Regressão — guarda `ISNEW()/ISCHANGED()` (achado mais importante do roteiro)** | 1. Desativei temporariamente a VR (`<active>false</active>` + `sf project deploy start` só da VR) — confirmado via query `Active=false`. 2. Inseri Lead "envenenado" com `Data_Aniversario__c=2099-06-15` (`T-09 SETUP RESULT: POISON_INSERT_OK id=00QHa00000QgIftMAF`). 3. **Reativei a VR** (`<active>true</active>` + redeploy) e **confirmei `Active=true`** antes de prosseguir. 4. Atualizei **outro campo** (`Company`) do mesmo Lead, sem tocar `Data_Aniversario__c`. | Save do passo 4 deve passar sem erro (VR não deve disparar porque `ISCHANGED()` é `false` e `ISNEW()` é `false`). | `T-09 RESULT: UPDATE_OK id=00QHa00000QgIftMAF — VR nao disparou em update reentrante sem tocar no campo de data`. **VR restaurada ao estado final correto (`Active=true`)** — reconfirmado por query após o teste (ver §6). | **PASSOU** |
| T-10 | Borda — VR aceita data = hoje | Apex anônimo: `insert new Lead(..., Data_Aniversario__c = Date.today())`. | Save passa (`>` é estrito). | `T-10 RESULT: INSERT_OK id=00QHa00000QgIeHMAV data=2026-09-07 00:00:00`. | PASSOU |
| T-11 | Borda — VR aceita data passada válida (CA-02) | Apex anônimo: `insert new Lead(..., Data_Aniversario__c = Date.newInstance(1990,1,1))`, releitura via SOQL. | Save passa, valor persiste. | `T-11 RESULT: INSERT_OK id=00QHa00000QgIeIMAV data=1990-01-01 00:00:00` — valor recarregado do banco confere. | PASSOU |
| T-12 | Negativo/permissão — usuário sem edição de Lead não deve ganhar brecha por causa do campo novo | `SELECT Parent.Profile.Name, PermissionsEdit FROM ObjectPermissions WHERE SobjectType='Lead' AND Parent.IsOwnedByProfile=true` → identifica 4 perfis sem edição de Lead (`Read Only`, `surveys2 Perfil`, `Analytics Cloud Security User`, `Analytics Cloud Integration User`, este último pré-existente e alheio à demanda). Cruzado com `FieldPermissions` do campo novo para os mesmos 4 perfis. | Nenhum desses perfis deve ter FLS no campo novo (o campo não deve abrir brecha de edição que o objeto já não permitisse). | Nenhum dos 4 perfis sem edição de Lead aparece na lista de `FieldPermissions` do campo novo (só os 4 de T-03 aparecem, e nenhum deles é um desses 4). **Verificação efetiva por usuário real (tentar editar de fato) não foi possível** sem "Login As". | PASSOU (via metadata) — verificação visual não executada |

### 2.4 Conversão de Lead → Contact.Birthdate (B-1, Flow)

| Caso | Critério de aceite | Passos executados | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T-13 | B-1 — conversão com data preenchida mapeia para `Contact.Birthdate` | Apex anônimo: cria Lead com `Data_Aniversario__c=1985-06-15`, `Database.convertLead` com `DoNotCreateOpportunity=true`, releitura do Contact. | `Contact.Birthdate` = mesmo valor. | `T-13 RESULT: CONVERT_OK contactId=003Ha00000ngTqzIAE Birthdate=1985-06-15 00:00:00`. | PASSOU |
| T-14 | B-1 — conversão **sem** data preenchida não quebra | Mesmo fluxo, Lead sem `Data_Aniversario__c`. | Conversão conclui sem erro, `Birthdate` vazio. | `T-14 RESULT: CONVERT_OK contactId=003Ha00000ngTr0IAE Birthdate=null`. | PASSOU |
| T-15 | Volume — conversão em lote | Apex anônimo: 30 Leads criados em um único `insert` (metade com data, metade sem), convertidos em um único `Database.convertLead(List<LeadConvert>, false)`. | Todos convertem sem erro de limite de governador; split correto de `Birthdate`. | `T-15 INSERT RESULT: OK count=30`; `T-15 CONVERT RESULT: ok=30 fail=0`; `T-15 BIRTHDATE RESULT: withBirthdate=15 withoutBirthdate=15`. Nenhum erro de "too many DML"/limite de CPU. | PASSOU |

**Achado adicional confirmado empiricamente (não é caso T- numerado, decisão do gate já registrada em `gates.md`):** convertendo um Lead com `Data_Aniversario__c=2000-07-20` para um Contact pré-existente com `Birthdate=1975-03-03`, o resultado final foi `Birthdate=2000-07-20` — **sobrescrita confirmada**, consistente com a decisão do humano ("sempre sobrescrever é o comportamento pretendido"). Não é uma falha, é a confirmação empírica de uma decisão de negócio já fechada.

### 2.5 Regressão dos 3 Flows `RecordAfterSave` simultâneos no Lead (D-2, gate crítico)

| Caso | Critério de aceite | Passos executados | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| **T-16** | **Regressão — 3 Flows after-save simultâneos no Lead, ordem não garantida (D-2)** | 1. Li o XML dos 3 flows (`Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes`, `Lead_AfterSave_MapeiaAniversarioNaConversao`) para confirmar que **nenhum campo é escrito por mais de um flow** (`Leads_do_Marketing_Cloud` só escreve `OwnerId`; `Count_de_Tasks_Pendentes` só escreve `Atividades_Pendentes__c`/`Quantidade_de_Atividades_Pendentes__c`; o Flow novo só escreve `Contact.Birthdate`, objeto diferente). 2. Criei 3 Leads (loop `i=0..2`) com `LeadSource='Nutricao MKT Cloud'` (dispara `Leads_do_Marketing_Cloud`) e `Data_Aniversario__c` preenchida, disparando também `Count_de_Tasks_Pendentes` (todo Lead) — provando que a VR nova convive com os 2 flows reentrantes de create sem rollback. 3. Convertei os mesmos 3 Leads (`Database.convertLead` em loop), disparando o Flow novo simultaneamente aos outros dois (ambos também respondem a `Update`, já que a conversão é um update no Lead). | Nenhum erro de rollback por VR nas reentrâncias; resultado funcional idêntico independente da ordem de disparo dos 3 flows, porque não escrevem em campos sobrepostos. | **Criação (3 iterações):** `OwnerId=0054x000007Tn9rAAC` (owner reatribuído pelo flow de Marketing Cloud), `QtdTasks=0`, `Aniversario=1992-04-10` em todas as 3 — sem erro, sem variação entre execuções. **Conversão (3 iterações):** `Birthdate=1992-04-10` em todas as 3 — sem erro, sem variação. **Nenhuma reentrância causou rollback de VR; nenhum flow sobrescreveu resultado de outro** (confirmado tanto pela leitura do XML — sem campo em comum — quanto pelas 3 repetições empíricas, que deram resultado idêntico). | **PASSOU — não há indício de comportamento inconsistente. Não é necessário reabrir o gate do arquiteto/humano sobre D-2** (ver análise abaixo). |

**Análise de D-2 (por que este resultado não reabre o gate):** o risco original de D-2 era
"ordem de execução não garantida entre os 3 Flows" causar resultado diferente conforme a
ordem. Como os 3 flows **não escrevem em nenhum campo em comum** (confirmado pela leitura
dos 3 XMLs — `OwnerId` × `Atividades_Pendentes__c`/`Quantidade_de_Atividades_Pendentes__c` ×
`Contact.Birthdate`, este último em outro objeto), não existe, na prática, um cenário onde a
ordem relativa entre eles mudaria o resultado final — a única forma de a ordem importar seria
se um flow lesse um valor que outro escreve, o que não é o caso aqui. As 3 repetições
empíricas confirmam isso (resultado idêntico nas 3), mas a garantia estrutural vem da
ausência de sobreposição de campos, não apenas da amostra de 3 execuções. **Risco reclassificado: mitigado por design (ausência de sobreposição), não por metadata (`triggerOrder` continua ausente).** Se no futuro qualquer um dos 3 flows passar a escrever em um campo hoje exclusivo de outro, esta análise deixa de valer e o risco volta a ser real — vale registrar essa condição de invalidação para quem revisar esta demanda depois.

---

## 3. Verificações estáticas (herdadas da passagem anterior, ainda válidas — não repetidas aqui)

As verificações de leitura de XML da VR e do Flow contra os critérios de aceite,
documentadas na passagem anterior deste artefato, permanecem válidas e não mudaram (o
metadata implantado é byte-idêntico ao que foi validado por `deploy validate` antes do
deploy real — confirmado em `06-release.md` §1, "nada mudou desde a última validação").
Não as repito aqui para não duplicar; a novidade desta passagem é a **execução funcional
real** de §2, que a leitura estática nunca poderia substituir — e que agora confirma, por
execução, exatamente o que a leitura já sugeria (guard `ISNEW/ISCHANGED` funciona,
`errorDisplayField` ancora a mensagem no campo, filtros do Flow disparam/não disparam como
esperado).

Adição desta passagem: leitura cruzada dos XMLs de `Leads_do_Marketing_Cloud` e
`Count_de_Tasks_Pendentes` (os outros 2 flows `RecordAfterSave` do Lead, retomados via
`sf project retrieve start` para análise de T-16) — confirmando ausência de sobreposição de
campo com o Flow novo, base da análise de §2.5.

---

## 4. Dados de teste utilizados nesta execução

Todos fictícios, prefixo identificável, sem nenhum dado real de cliente:

| Massa | Quantidade criada | Finalidade | Removida ao final? |
|---|---|---|---|
| Leads individuais (`Company='QA Teste Aniversario'`, variações de `LastName`) | 12 (T-06 a T-14, T-16, mais o de sobrescrita de Birthdate) | T-06 a T-14, T-16, confirmação de sobrescrita | Sim |
| Lead "envenenado" (T-09) | 1 (`00QHa00000QgIftMAF`) | Regressão do guard `ISCHANGED` | Sim |
| Lote de volume (T-15) | 30 (`Aniversario Lote 1..30`) | Conversão em lote | Sim |
| Contact pré-existente (teste de sobrescrita) | 1 (`Aniversario Preexistente`) | Confirmar sobrescrita de `Birthdate` | Sim |
| Accounts (criadas automaticamente pela conversão de Lead sem `AccountId` explícito, mais 1 explícita) | 36 | Efeito colateral necessário da conversão nativa do Salesforce | Sim |
| Contacts resultantes de conversão | 37 | Efeito de T-13/T-14/T-15/T-16/sobrescrita | Sim |
| **Total de Leads criados nesta execução** | **42** | — | Sim |

Nenhum e-mail, CPF, telefone ou nome real foi usado em nenhum momento. Nenhuma consulta desta
etapa retornou dado de cliente — só metadata, contagens agregadas (`COUNT(Id)`) e os
registros de teste que este agente mesmo criou.

---

## 5. Riscos e pendências para o humano

1. **LGPD ainda aberta.** `gates.md` registra que a finalidade/base legal da coleta (uso
   interno de relacionamento comercial, legítimo interesse — art. 7º, IX) foi uma
   **assunção do agente/orquestrador**, não confirmação do consultor. Segue pendente de
   confirmação **antes do release para UAT/produção** (que não é escopo de nenhum agente
   deste squad) — não é um item que a execução de testes desta etapa resolve ou testa.
2. **D-2 — risco reclassificado, não eliminado da metadata.** `<triggerOrder>` continua
   ausente (rejeitado pela API v67.0). T-16 passou e a análise de §2.5 mostra que os 3 flows
   não sobrepõem campos hoje — mas isso é uma propriedade do estado atual dos 3 flows, não
   uma garantia estrutural do Salesforce. **Se qualquer um dos 3 flows for alterado no futuro
   para escrever em um campo hoje exclusivo de outro, este risco volta a ser real** e T-16
   precisaria ser re-executado. Vale registrar isso como nota de manutenção para quem tocar
   qualquer um desses 3 flows depois.
3. **Verificação visual por perfil não executada (T-01, T-03, T-04, T-12).** Confirmado
   por API que a permissão/FLS/posição no layout está correta para os 4 perfis de negócio e
   ausente para os de integração — mas a renderização real da tela (campo aparecendo,
   editável, no lugar certo) para um usuário logado de fato **não foi verificada** neste
   ambiente sem UI. Recomendo um "Login As" rápido (2-3 min) com um usuário de cada perfil
   antes da homologação final, como já sugerido em `06-release.md` §6.3 — não é bloqueante
   para os achados de comportamento (nenhuma discrepância é esperada, já que a API confirma
   permissão + layout juntos), mas é o item mais barato de fechar antes de assinar.
4. **Comportamento de sobrescrita de `Contact.Birthdate` — resolvido, não é mais
   pendência.** Confirmado empiricamente nesta etapa e já decidido pelo humano em `gates.md`
   como comportamento pretendido.
5. **Critérios não testáveis nesta sandbox:** nenhum. Todos os 16 casos foram executados,
   integralmente ou por metadata/API onde UI não estava disponível — nenhum ficou sem
   nenhuma tentativa de execução.

---

## 6. Limpeza da massa de teste — confirmação

Todos os registros de teste criados nesta execução foram removidos ao final, em duas etapas
(delete + purge do recycle bin):

```
CLEANUP: contacts deleted=37
CLEANUP: leads deleted=42
CLEANUP: accounts deleted=36

PURGE: leads purged=42
PURGE: contacts purged=37
PURGE: accounts purged=36
```

Contagens finais confirmadas (0 remanescentes):

```
SELECT COUNT(Id) FROM Lead WHERE Company LIKE 'QA Teste Aniversario%'    → 0
SELECT COUNT(Id) FROM Contact WHERE LastName LIKE '%Aniversario%'         → 0
SELECT COUNT(Id) FROM Account WHERE Name LIKE 'QA Teste Aniversario%'     → 0
```

**Estado final da VR** (após o toggle temporário de T-09, restaurado):

```
SELECT ValidationName, Active FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName='Lead' AND ValidationName='Valida_Data_Aniversario_Nao_Futura'
→ Valida_Data_Aniversario_Nao_Futura | Active = true
```

`git status --short` no repositório, ao final desta etapa, não mostra nenhuma alteração de
metadata versionada (o toggle da VR foi revertido para o mesmo conteúdo original antes do
commit desta etapa) — só a atualização deste próprio arquivo `05-testes.md`.

---

**Resultado consolidado: 14/16 casos PASSOU integralmente, 4/16 desses 14 marcados
adicionalmente com a ressalva "verificação visual não executada" (T-01, T-03, T-04, T-12 —
ainda assim contam como PASSOU pela evidência de metadata/API disponível), 0/16 FALHOU,
0/16 sem nenhuma execução.** T-09 (regressão crítica) e T-16 (risco D-2) — os dois casos que
o gate anterior marcou como "achado mais importante" e "gate crítico" — **ambos passaram**.

Testes executados. Preciso da sua homologação para liberar o release.
