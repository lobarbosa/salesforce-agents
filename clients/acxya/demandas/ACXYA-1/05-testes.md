# ACXYA-1 — Testes (etapa 5)

**Agente:** `qa` · **Data:** 2026-09-07 · **Branch:** `feature/ACXYA-1`
**Org:** `sbx-acxya` (Sandbox), Org Id `00DHa000006bRsDMAU`, usuário
`lbarbosa@konectabr.com.sbxacxya`, API v67.0 — confirmada via `sf org list` antes de
qualquer comando. **Produção não está configurada nesta máquina, não tocada.**
**Base:** `01-analise.md` (critérios de aceite), `03-design.md` (decisões B-1..B-4 e §6.2),
`04-plano-build.md` (o que foi construído e os desvios D-1..D-6), `gates.md` (decisões do
humano, incluindo a resolução de D-2).

---

## 1. Escopo e pré-condição — LEIA ANTES DE QUALQUER OUTRA COISA

**A execução funcional deste roteiro está BLOQUEADA.** O build da etapa 4 nunca foi
implantado na sandbox (`sf project deploy start`) — só rodou `sf project deploy validate`
(check-only). Reconfirmei agora, nesta etapa, via Tooling API / metadata list contra
`sbx-acxya`:

| Componente da demanda | Existe na org agora? | Como confirmei |
|---|---|---|
| `Lead.Data_Aniversario__c` | **Não** | `SELECT QualifiedApiName FROM EntityParticle WHERE EntityDefinitionId='Lead' AND QualifiedApiName='Data_Aniversario__c'` (Tooling) → 0 registros. `sf org list metadata --metadata-type CustomField` → nenhuma ocorrência de `Data_Aniversario` em nenhum objeto. |
| `Lead.Valida_Data_Aniversario_Nao_Futura` (VR) | **Não** | `SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Lead'` (Tooling) → só as 4 VRs pré-existentes, todas `Active=false`. A VR nova não aparece. |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` (Flow) | **Não** | `sf org list metadata --metadata-type Flow` → lista completa de flows da org não contém esse nome. |
| Deltas de `fieldPermissions` nos 4 perfis (B-4) | **Não** (não há campo para conceder FLS) | Consequência direta da ausência do campo. |
| `Lead-Lead Layout` (com o item novo) | Layout **existe** (é o layout base, sem o campo novo) | `sf org list metadata --metadata-type Layout` retorna `Lead-Lead Layout`, última modificação anterior a este build. |

**Consequência prática:** não é possível criar um Lead de teste, preencher a data, salvar,
converter, ou observar qualquer comportamento de VR/Flow — porque nenhum desses componentes
existe no ambiente. Qualquer afirmação de "passou" para um teste funcional seria invenção.

Este documento entrega, portanto, duas coisas de natureza diferente e não devem ser
confundidas:

1. **Um roteiro de teste** (§2), derivado 1-a-1 dos critérios de aceite de `01-analise.md`
   e das decisões de `03-design.md`/`gates.md`, pronto para ser executado **assim que o
   deploy real acontecer** (etapa 6, decisão do humano). Todo caso está marcado
   `NÃO EXECUTADO — bloqueado por deploy`.
2. **Verificações estáticas** (§3) que **foram** de fato executadas agora: reconfirmação de
   ausência/presença de metadata, `deploy validate` check-only, e revisão por leitura da
   fórmula da VR e da lógica do Flow contra os critérios de aceite.

Nenhum teste funcional deste documento deve ser lido como "executado com sucesso". Onde a
tabela diz "NÃO EXECUTADO", é literal.

---

## 2. Roteiro de teste (para execução após deploy real)

Convenção de status: `NÃO EXECUTADO — bloqueado por deploy` para todos os casos funcionais
desta seção. Nenhum caso foi rodado em sandbox.

### Falhas conhecidas hoje (nenhuma — mas listadas primeiro por disciplina do relatório)

Não há falha a reportar nesta etapa porque não há execução funcional possível. A única
"falha" real do ciclo é de processo, não de comportamento: **o artefato que este roteiro
deveria testar não existe na org.** Isso está registrado como risco em §5, não como caso de
teste reprovado — não seria correto marcar um caso como "Falhou" quando ele nunca rodou.

### 2.1 Caminho feliz e cobertura de layout/FLS (CA-01, CA-03, B-4)

| Caso | Critério de aceite | Pré-condição | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|---|
| T-01 | CA-01 — campo existe e é editável no layout | Deploy real feito; usuário logado com perfil `Usuário Padrão` (Standard) | 1. Abrir um Lead qualquer. 2. Localizar seção "Lead Information", coluna 2, logo após "Email". 3. Clicar em editar o campo. | Campo "Data de Aniversário" aparece, rotulado, tipo Date (date picker), editável. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-02 | CA-03 — tipo do campo é Date (não Date/Time) | Deploy real feito; acesso a Setup → Object Manager | 1. Abrir Setup → Object Manager → Lead → Fields & Relationships → `Data_Aniversario__c`. | `Type = Date`. Nenhum componente de hora exibido no picker do layout. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-03 | B-4/P-2 — campo visível/editável para os 4 perfis de minimização | Deploy real feito; 4 usuários de teste, um por perfil: `Administrador do sistema`, `System Administrator (non-API user)`, `Usuário Padrão`, `Usuário do Marketing` | Para cada perfil: logar (ou "Login As" via admin) e abrir um Lead de teste. | Campo aparece e é editável para os 4 perfis. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-04 | B-4/P-2 — campo **não** visível para perfis de integração (minimização/LGPD) | Deploy real feito; usuário ou permission set de um perfil de integração (ex.: `Salesforce API Only System Integrations`, `Sales Insights Integration User`, ou o perfil real do usuário de integração Marketing Cloud, se identificado) | 1. Consultar FLS efetiva do campo para o perfil de integração via Setup → Object Manager → Lead → Fields → `Data_Aniversario__c` → "View Field Accessibility", **ou** via API: `SELECT PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Field='Lead.Data_Aniversario__c' AND Parent.Profile.Name='<perfil de integração>'` (metadata/permissão, não dado pessoal — permitido). | Nenhuma linha retornada, ou `PermissionsRead=false`/`PermissionsEdit=false` para todo perfil de integração. Campo não aparece em nenhuma tela/API para esses perfis. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-05 | Confirmação de rollback de layout (não é CA, mas é pré-condição de release seguro) | Deploy real feito | Comparar `Lead-Lead Layout` pós-deploy com `demandas/ACXYA-1/layout-lead-original-backup.xml` | Diff mostra somente a inserção do item `Data_Aniversario__c` — nada mais mudou na seção nem em outras seções. | — | NÃO EXECUTADO — bloqueado por deploy |

### 2.2 Campo opcional (B-3, borda)

| Caso | Critério de aceite | Pré-condição | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|---|
| T-06 | B-3 — campo é opcional | Deploy real feito | 1. Criar um Lead novo com todos os campos obrigatórios padrão preenchidos, **deixando `Data_Aniversario__c` em branco**. 2. Salvar. | Save concluído sem erro. Nenhuma mensagem de campo obrigatório para `Data_Aniversario__c`. | — | NÃO EXECUTADO — bloqueado por deploy |

### 2.3 Validation Rule — negativo, borda e regressão (CA-04, B-2, R1/R2)

| Caso | Critério de aceite | Pré-condição | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|---|
| T-07 | CA-04 — VR barra data futura **na criação** | Deploy real feito, VR `active=true` | 1. Criar Lead novo. 2. Preencher `Data_Aniversario__c` com uma data futura fictícia (ex.: `31/12/2099`). 3. Salvar. | Save bloqueado. Mensagem "A data de aniversário não pode ser uma data futura." exibida **ancorada no campo** `Data_Aniversario__c` (não no topo da página — `errorDisplayField` setado). | — | NÃO EXECUTADO — bloqueado por deploy |
| T-08 | CA-04 — VR barra data futura **na edição** | Deploy real feito; Lead de teste existente com o campo vazio | 1. Editar o Lead de teste. 2. Preencher `Data_Aniversario__c` com data futura fictícia. 3. Salvar. | Save bloqueado, mesma mensagem de T-07. | — | NÃO EXECUTADO — bloqueado por deploy |
| **T-09** | **Regressão — guarda `ISNEW()/ISCHANGED()` (B-2, achado mais importante deste roteiro)** | Deploy real feito. **Requer massa "envenenada":** um Lead de teste com `Data_Aniversario__c` já preenchido com data futura fictícia (só possível de criar **antes** da VR estar ativa, ou via inserção que ignore a VR — ex.: Data Loader com um usuário bypass, ou inserir o registro **antes** deste deploy e só then ativar a VR). | 1. Com o registro "envenenado" já existente (data futura já salva, sem que o campo tenha sido tocado nesta transação). 2. Editar **qualquer outro campo** do mesmo Lead (ex.: `Company`), **sem tocar** em `Data_Aniversario__c`. 3. Salvar. | Save **passa**, sem erro. A VR não deve disparar porque `ISCHANGED(Data_Aniversario__c)` é `false` e `ISNEW()` é `false` — o guard existe exatamente para não travar update de integração em registro antigo com dado inválido. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-10 | Borda — VR aceita data = hoje | Deploy real feito | 1. Criar ou editar Lead. 2. Preencher `Data_Aniversario__c = TODAY()` (data de hoje). 3. Salvar. | Save passa. A fórmula usa `> TODAY()`, então `= TODAY()` não deve disparar o erro. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-11 | Borda — VR aceita data passada válida (CA-02) | Deploy real feito | 1. Criar ou editar Lead. 2. Preencher `Data_Aniversario__c` com data passada fictícia (ex.: `01/01/1990`). 3. Salvar. | Save passa sem erro. Valor persiste e é exibido no formato de data padrão da org ao reabrir. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-12 | Negativo/permissão — usuário sem edição de Lead não deve conseguir salvar alteração no campo | Deploy real feito; usuário com perfil que **não** tem Edit no objeto Lead (nenhum dos 7 perfis listados em §4.1 do design) | 1. Tentar editar um Lead com esse usuário. | Edição do objeto inteiro é bloqueada por permissão de objeto (comportamento padrão do Lead, não específico desta demanda) — o campo novo não deve abrir uma brecha de edição que o objeto já não permitisse. | — | NÃO EXECUTADO — bloqueado por deploy |

### 2.4 Conversão de Lead → Contact.Birthdate (B-1, Flow)

| Caso | Critério de aceite | Pré-condição | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|---|
| T-13 | B-1 — conversão com data preenchida mapeia para `Contact.Birthdate` | Deploy real feito, Flow `Lead_AfterSave_MapeiaAniversarioNaConversao` ativo | 1. Criar Lead de teste com `Data_Aniversario__c` preenchida (data passada fictícia, ex. `15/06/1985`). 2. Converter o Lead (criar novo Contact). 3. Abrir o Contact resultante. | `Contact.Birthdate` = mesmo valor de `Lead.Data_Aniversario__c`. | — | NÃO EXECUTADO — bloqueado por deploy |
| T-14 | B-1 — conversão **sem** data preenchida não quebra | Deploy real feito | 1. Criar Lead de teste com `Data_Aniversario__c` **vazio**. 2. Converter o Lead. | Conversão conclui normalmente (sem erro). `Contact.Birthdate` permanece vazio (Flow não dispara — filtro `Data_Aniversario__c` não nulo). | — | NÃO EXECUTADO — bloqueado por deploy |
| T-15 | Volume — conversão em lote | Deploy real feito | 1. Criar 20-30 Leads de teste, metade com `Data_Aniversario__c` preenchida, metade sem. 2. Converter todos via API/Data Loader em um único lote. | Todos convertem sem erro de limite de governador. Contacts dos Leads com data preenchida recebem `Birthdate`; os demais ficam vazios. Nenhum erro de "too many DML" (o design estimou folga larga, §7 de `03-design.md`). | — | NÃO EXECUTADO — bloqueado por deploy |

### 2.5 Regressão dos 3 Flows `RecordAfterSave` simultâneos no Lead (D-2, gate crítico)

> Este caso existe porque o humano, em `gates.md`, decidiu **aceitar ordem de execução não
> garantida** entre `Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes` e
> `Lead_AfterSave_MapeiaAniversarioNaConversao` (D-2 do `04-plano-build.md` — `<triggerOrder>`
> foi rejeitado pela API v67.0 e não pôde ser implementado como metadata) e empurrou a
> verificação explicitamente para o QA. **Se este caso falhar ou mostrar comportamento
> inconsistente, a decisão volta ao gate do arquiteto/humano antes de liberar homologação —
> não é uma falha "normal" de teste, é reabertura de decisão de design.**

| Caso | Critério de aceite | Pré-condição | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|---|
| **T-16** | **Regressão — 3 Flows after-save simultâneos no Lead, ordem não garantida (D-2)** | Deploy real feito. Todos os 3 flows ativos: `Leads_do_Marketing_Cloud` (RecordAfterSave/Create, faz Update de `OwnerId`), `Count_de_Tasks_Pendentes` (RecordAfterSave/CreateAndUpdate, escreve no Lead), `Lead_AfterSave_MapeiaAniversarioNaConversao` (RecordAfterSave/Update, dispara na conversão). | 1. Criar um Lead novo com `Data_Aniversario__c` preenchida, de forma que dispare `Leads_do_Marketing_Cloud` (evento Create). 2. Confirmar que `OwnerId` foi trocado corretamente (comportamento pré-existente, não desta demanda) e que o Lead salvou sem erro — isto prova que a VR nova (guard `ISNEW`/`ISCHANGED`) convive com o update reentrante do flow de Marketing Cloud sem causar rollback (mecanismo de risco R2 do design). 3. Separadamente, converter o mesmo Lead (ou outro com o campo preenchido) e confirmar que `Count_de_Tasks_Pendentes` e `Lead_AfterSave_MapeiaAniversarioNaConversao` disparam ambos sem erro, e que o resultado final é consistente independente da ordem relativa entre eles (o Flow novo só toca `Contact.Birthdate`, os outros dois só tocam `Lead`/`Task` — checar que não há campo em comum sendo escrito por mais de um flow, o que eliminaria a dependência de ordem na prática). 4. Repetir a criação/conversão 3-5 vezes para observar se a ordem de execução varia entre execuções (evidência empírica de não-determinismo, já que não há `triggerOrder` definido). | Nenhum erro de rollback por VR nas reentrâncias. Resultado funcional (owner trocado, tasks contadas, Birthdate mapeado) é o mesmo independente da ordem de disparo dos 3 flows, porque eles não escrevem em campos sobrepostos. Se qualquer execução mostrar resultado diferente dependendo da ordem (ex.: um flow sobrescrevendo o resultado de outro, ou uma VR barrando um update reentrante), **este caso é reprovado** e a decisão de D-2 deve voltar ao gate antes de homologar. | — | NÃO EXECUTADO — bloqueado por deploy |

---

## 3. Verificações estáticas executadas agora

Estas foram, de fato, rodadas nesta etapa contra `sbx-acxya`. Nenhuma delas prova
comportamento — só metadata, sintaxe e consistência de leitura.

### 3.1 Reconfirmação de ausência/presença de metadata (Tooling API / metadata list, sem dado pessoal)

```
SELECT QualifiedApiName FROM EntityParticle
WHERE EntityDefinitionId='Lead' AND QualifiedApiName='Data_Aniversario__c'
→ 0 registros (campo não existe na org)

SELECT ValidationName, Active FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName='Lead'
→ 4 registros, todas Active=false:
  Validacao_de_Telefone, Validacao_de_Campos,
  Valida_Lead_Atividades_Pendentes, Lead_status_MQL
  (Valida_Data_Aniversario_Nao_Futura NÃO aparece — confirma ausência)

sf org list metadata --metadata-type Flow --target-org sbx-acxya
→ lista completa de flows da org não contém
  "Lead_AfterSave_MapeiaAniversarioNaConversao"

sf org list metadata --metadata-type CustomField --target-org sbx-acxya | grep Data_Aniversario
→ nenhuma ocorrência (exit code 1 / sem match)

sf org list metadata --metadata-type Layout --target-org sbx-acxya | grep "Lead-Lead Layout"
→ 1 registro, "Lead-Lead Layout", última modificação anterior a este build
  (confirma que o layout base existe, mas sem o item novo)
```

Nenhuma dessas consultas retornou dado de cliente — só nomes de campo, de VR e metadados de
componente (guardrail #2 respeitado).

### 3.2 `sf project deploy validate` (check-only) do pacote da demanda

Reexecutei o exato comando descrito na §6.2 do `04-plano-build.md`, contra o estado atual
de `sbx-acxya`:

```
sf project deploy validate \
  --metadata "CustomField:Lead.Data_Aniversario__c" \
  --metadata "ValidationRule:Lead.Valida_Data_Aniversario_Nao_Futura" \
  --metadata "Layout:Lead-Lead Layout" \
  --metadata "Flow:Lead_AfterSave_MapeiaAniversarioNaConversao" \
  --metadata "Profile:Admin" \
  --metadata "Profile:MarketingProfile" \
  --metadata "Profile:Standard" \
  --metadata "Profile:System Administrator %28non-API user%29" \
  --target-org sbx-acxya --test-level RunLocalTests
```

**Resultado literal: `Succeeded`.**

```
status: Succeeded
success: true
numberComponentErrors: 0
numberComponentsDeployed: 8
numberComponentsTotal: 8
numberFiles: 12
numberTestsCompleted: 10
numberTestErrors: 0
numberTestsTotal: 10
rollbackOnError: true
deployId: 0AfHa00000DWkBWKA1
```

Os 8 componentes reportados (`Created`/`Changed`): `Lead.Data_Aniversario__c` (Created),
`Lead_AfterSave_MapeiaAniversarioNaConversao` (Created), `Lead-Lead Layout` (Changed),
`Admin`/`MarketingProfile`/`Standard`/`System Administrator %28non-API user%29` (Changed),
`Lead.Valida_Data_Aniversario_Nao_Futura` (Created). Mesmos 10 testes Apex da org, 0 falhas.

**O que isso prova, e o que não prova:** este resultado confirma que o pacote é
**sintaticamente válido, resolve suas dependências internas** (o campo referenciado pela VR
e pelo layout existe dentro do próprio pacote de validação) **e não quebra nenhum teste
Apex existente da org.** Isso **não é** um teste funcional — não simula um usuário salvando
um Lead, não avalia a VR contra um registro, não executa o Flow. `deploy validate` não roda
lógica declarativa de VR/Flow contra dado real; ele só compila e valida metadata.

### 3.3 Revisão por leitura — VR contra os critérios de aceite

Li o XML de `force-app/main/default/objects/Lead/validationRules/Valida_Data_Aniversario_Nao_Futura.validationRule-meta.xml`:

```
AND(
  OR(ISNEW(), ISCHANGED(Data_Aniversario__c)),
  NOT(ISBLANK(Data_Aniversario__c)),
  Data_Aniversario__c > TODAY()
)
```

- `active=true` — consistente com B-2 Opção B (decidida em `gates.md`).
- Guard `OR(ISNEW(), ISCHANGED(...))` presente — cobre exatamente o cenário de regressão de
  T-09 (não trava update de registro antigo não tocado no campo). **Nenhuma divergência
  encontrada** entre o XML e o que `gates.md`/`04-plano-build.md` descrevem.
- `NOT(ISBLANK(...))` presente — cobre T-06 (campo vazio não dispara a regra).
- `Data_Aniversario__c > TODAY()` — operador estrito, consistente com T-10 (data = hoje deve
  passar). Fórmula lida corretamente sem precisar de execução para confirmar a semântica do
  operador `>` do Salesforce sobre tipo Date.
- `errorDisplayField=Data_Aniversario__c` — ancora a mensagem no campo, consistente com a
  divergência de precedente já documentada e aprovada em §3.3 do design.

**Nenhuma divergência entre o metadata construído e o que os artefatos anteriores
descrevem.** A fórmula em si é logicamente consistente com CA-04 e com a exigência de
regressão de B-2 — mas isso é leitura, não execução. Não há forma de confirmar por leitura
que o motor de fórmula do Salesforce avalia `ISCHANGED()` exatamente como o texto sugere em
todo cenário de reentrância (T-09, T-16) sem rodar de fato.

### 3.4 Revisão por leitura — Flow contra os critérios de aceite

Li o XML de `force-app/main/default/flows/Lead_AfterSave_MapeiaAniversarioNaConversao.flow-meta.xml`:

- `object=Lead`, `recordTriggerType=Update`, `triggerType=RecordAfterSave`,
  `doesRequireRecordChangedToMeetCriteria=true` — evita reprocessar Lead já convertido em
  updates subsequentes. Consistente com a descrição de `04-plano-build.md` §2.5.
- Filtros de entrada: `IsConverted=true`, `ConvertedContactId` não nulo,
  `Data_Aniversario__c` não nulo — cobre T-13 (dispara só quando há dado e conversão) e T-14
  (não dispara sem data, então `Birthdate` fica vazio sem erro).
- `recordUpdates` filtra `Contact.Id = $Record.ConvertedContactId` e atribui
  `Birthdate = $Record.Data_Aniversario__c` — mapeamento direto, sem transformação, sem
  lógica condicional adicional. Nenhuma cláusula trata o caso de o Contact já ter um
  `Birthdate` preenchido por outra fonte (a conversão de Lead **sobrescreve** o valor
  existente sem perguntar) — isto **não está errado frente aos critérios de aceite**
  (nenhum deles fala de "preservar valor existente"), mas é um comportamento que vale
  confirmar no teste funcional (não coberto explicitamente por nenhum T- acima; sugiro
  acrescentar ao roteiro se o negócio achar relevante depois do deploy).
- `status=Active` — consistente com B-1.
- **Nenhum `<triggerOrder>`** — confirma o achado D-2: a ordenação relativa entre os 3 Flows
  `RecordAfterSave` do Lead não está definida em metadata. É exatamente o que T-16 precisa
  verificar empiricamente.

**Nenhuma divergência** entre o Flow construído e a especificação de B-1/`gates.md`, além do
ponto de sobrescrita de `Birthdate` acima, que é uma observação nova desta revisão, não uma
falha de critério.

---

## 4. Dados de teste necessários (para quando o deploy acontecer)

Nenhum dado real de cliente deve ser usado. Sugestão de massa fictícia, claramente
identificável como teste:

| Lead (nome fictício) | `Data_Aniversario__c` | Finalidade no roteiro |
|---|---|---|
| `QA Teste Aniversario 01` | (vazio) | T-06, T-14 |
| `QA Teste Aniversario 02` | `1990-01-01` (passada) | T-11, T-13 |
| `QA Teste Aniversario 03` | `TODAY()` (data de hoje no dia da execução) | T-10 |
| `QA Teste Aniversario 04` | `2099-12-31` (futura, tentativa de save — deve ser bloqueada) | T-07, T-08 |
| `QA Teste Aniversario 05 (envenenado)` | data futura fictícia, inserida **antes** de ativar a VR ou via caminho que ignore a VR | T-09 (regressão do guard `ISCHANGED`) |
| Lote `QA Teste Aniversario Lote 01..30` | metade preenchida (passada), metade vazia | T-15 |

Todos os nomes usam o prefixo `QA Teste Aniversario` para serem identificáveis e
removíveis em bloco após o teste. Nenhum CPF, e-mail, telefone ou nome real deve ser
usado — usar domínios fictícios do tipo `qa-teste-acxya@example.invalid` se e-mail for
exigido pelo layout.

---

## 5. Riscos e pendências para o humano

1. **Bloqueio de deploy (crítico, impede qualquer homologação real).** Nada deste roteiro
   pode ser executado até que o build seja implantado de verdade na sandbox — decisão da
   etapa 6 (`release`), fora do escopo deste agente. Recomendo fortemente que o humano trate
   isso antes de tratar qualquer outro item abaixo: sem deploy, não há homologação possível,
   só revisão de papel.
2. **Pendência de LGPD ainda aberta.** `gates.md` registra que a finalidade/base legal da
   coleta (uso interno de relacionamento comercial, legítimo interesse — art. 7º, IX) foi
   uma **assunção do agente/orquestrador**, não uma confirmação do consultor. Isso segue
   pendente de confirmação **antes do release**, conforme já sinalizado em `03-design.md`
   §11 e `04-plano-build.md` §7.
3. **Risco de ordenação de Flows (D-2).** Os 3 Flows `RecordAfterSave` do Lead
   (`Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes`,
   `Lead_AfterSave_MapeiaAniversarioNaConversao`) não têm ordem garantida entre si —
   `<triggerOrder>` foi rejeitado pela API v67.0 e a decisão registrada em `gates.md` foi
   aceitar o risco e empurrar a verificação para o caso **T-16** deste roteiro. **T-16 ainda
   não rodou** (bloqueado por deploy). Até que rode e passe, este risco continua em aberto —
   não deve ser tratado como mitigado só porque o gate já decidiu "aceitar por ora".
4. **Caso não coberto por nenhum critério de aceite existente:** o Flow sobrescreve
   `Contact.Birthdate` na conversão sem checar se o Contact já tinha um valor preenchido por
   outra via. Nenhum CA de `01-analise.md` fala sobre isso, então não é uma falha — mas é uma
   lacuna de critério que vale uma pergunta ao consultor antes do release, para não ser uma
   surpresa em produção depois.
5. **Critérios não testáveis na sandbox atual:** todos os 16 casos de teste funcional (T-01
   a T-16) — nenhum deles é testável hoje, pela razão única e já declarada em §1 (ausência
   total de deploy). Não há critério de aceite de `01-analise.md` que seja parcialmente
   testável nesta sandbox no estado atual — é um bloqueio total, não parcial.

---

**Testes funcionais NÃO executados** (bloqueio de deploy, §1). O que foi executado nesta
etapa são as verificações estáticas da §3. Não há o que homologar funcionalmente ainda:
o próximo passo é a decisão do humano sobre o deploy na sandbox, não uma homologação.
