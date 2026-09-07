# ACXYA-1 — Plano de build (etapa 4)

**Agente:** `builder-declarativo` · **Data:** 2026-09-07 · **Branch:** `feature/ACXYA-1`
**Org:** `sbx-acxya` (sandbox), Org Id `00DHa000006bRsDMAU`, API v67.0 — confirmada via
`sf org list` antes de qualquer alteração. **Produção não configurada nesta máquina,
não tocada.**
**Base:** `03-design.md` aprovado em `gates.md` (2026-09-07), decisões B-1 a B-4 travadas.
**Recon usado:** `02-recon.md`, coletado 2026-09-07, válido até 2026-09-14 — dentro da
validade na data deste build.

Nada foi implantado de verdade (`deploy`). Todos os comandos `sf` usados foram
`retrieve` (só leitura) e `deploy validate` (check-only). Nenhum SOQL retornou dado de
cliente — só metadata, contagens e nomes de perfil/campo (guardrail #2).

---

## 1. Inventário de componentes criados/alterados

| # | Ação | Tipo | Caminho | Decisão do gate que amarra |
|---|---|---|---|---|
| 1 | Criado | `CustomField` | `force-app/main/default/objects/Lead/fields/Data_Aniversario__c.field-meta.xml` | XML exato de §3.2 do design. `required=false` (B-3). |
| 2 | Criado | `ValidationRule` | `force-app/main/default/objects/Lead/validationRules/Valida_Data_Aniversario_Nao_Futura.validationRule-meta.xml` | B-2 = Opção B: `active=true`, fórmula com `OR(ISNEW(), ISCHANGED(Data_Aniversario__c))`. |
| 3 | Alterado | `Layout` | `force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml` | §3.4: campo inserido na seção `Lead Information`, coluna 2, imediatamente após `Email`, `behavior=Edit`. |
| 4 | Alterado | `Profile` | `force-app/main/default/profiles/Admin.profile-meta.xml` | B-4 = P-2: FLS Read+Edit para `Data_Aniversario__c`. |
| 5 | Alterado | `Profile` | `force-app/main/default/profiles/System Administrator %28non-API user%29.profile-meta.xml` | Idem. |
| 6 | Alterado | `Profile` | `force-app/main/default/profiles/Standard.profile-meta.xml` | Idem. |
| 7 | Alterado | `Profile` | `force-app/main/default/profiles/MarketingProfile.profile-meta.xml` | Idem. |
| 8 | Criado | `Flow` | `force-app/main/default/flows/Lead_AfterSave_MapeiaAniversarioNaConversao.flow-meta.xml` | B-1 = Opção 2: Flow after-save no Lead mapeando para `Contact.Birthdate` na conversão. |
| 9 | Criado (artefato de demanda, não metadata) | backup | `demandas/ACXYA-1/layout-lead-original-backup.xml` | Pré-condição §10.1/§3.4 — cópia do layout original retirada da org **antes** de editar. |

Nenhum perfil de integração recebeu FLS. Nenhum `LeadConvertSettings` foi criado (Opção 2
não usa esse tipo — confirmado em §3.5 do design). Nenhum `FlowDefinition` foi criado para
o Flow novo — o próprio `Flow` já traz `<status>Active</status>`, que é suficiente para
deploy de uma versão ativa (mesmo padrão observado nos flows `Leads_do_Marketing_Cloud` e
`Count_de_Tasks_Pendentes`, que também não têm `FlowDefinition` companion apesar de
ativos — só alguns flows do baseline têm esse arquivo, não é obrigatório).

---

## 2. Detalhe por componente

### 2.1 `CustomField` `Lead.Data_Aniversario__c`

Espelha exatamente o XML aprovado em §3.2 (`type=Date`, `required=false`,
`trackHistory=false`, `trackFeedHistory=false`, `externalId=false`, descrição
preenchida). Sem desvio.

### 2.2 `ValidationRule` `Lead.Valida_Data_Aniversario_Nao_Futura`

Usei a fórmula da **Opção B** (a recomendada e aprovada em B-2), não a Opção A que o
design tinha validado tecnicamente por conveniência de teste:

```
AND(
  OR(ISNEW(), ISCHANGED(Data_Aniversario__c)),
  NOT(ISBLANK(Data_Aniversario__c)),
  Data_Aniversario__c > TODAY()
)
```

`active=true` desde o deploy (conforme B-2). `errorDisplayField=Data_Aniversario__c`
(divergência consciente do precedente, já justificada no design §3.3). Adicionei
`<description>` preenchida — o design já continha uma no XML de exemplo; **confirmei
empiricamente que `ValidationRule` aceita esse elemento** (validate passou sem erro de
parsing nele).

### 2.3 `Layout` `Lead-Lead Layout`

Segui a pré-condição obrigatória do design **antes de editar**:

```
sf project retrieve start --metadata "Layout:Lead-Lead Layout" --target-org sbx-acxya
```

Resultado: o arquivo retornado pela org é **byte-idêntico** ao já versionado em
`force-app` (`git diff` vazio após o retrieve, `git status --short` sem mudanças). Ou
seja, **não havia drift** entre o baseline local e o estado atual da org para este
layout — o layout retirado pela org nesta etapa é o mesmo que já estava no repo. Copiei
esse arquivo (idêntico ao commitado) para
`demandas/ACXYA-1/layout-lead-original-backup.xml`, como pede §10.1/§10.3, para servir de
ponto de rollback caso o PR precise reverter.

Editei apenas a seção `Lead Information`, coluna 2, inserindo um `layoutItems` novo
(`Data_Aniversario__c`, `behavior=Edit`) imediatamente após `Email`, exatamente como
especificado em §3.4. **Confirmado por `git diff`:** o diff mostra somente essas 4 linhas
adicionadas — nada mais no arquivo mudou.

### 2.4 Deltas de `Profile` (FLS) — **desvio consciente do texto literal do design, documentado aqui**

**O que o design pede (§4.2, literal):** "entregar arquivos de perfil delta, contendo
apenas o bloco `fieldPermissions` do campo novo". A leitura literal disso seria substituir
o conteúdo inteiro dos 4 arquivos de perfil por um XML mínimo contendo só o bloco
`fieldPermissions`.

**O que eu fiz, e por quê:** antes de editar, li os 4 arquivos por completo. Eles **não
estão vazios** — carregam, de fato, dezenas a centenas de `userPermissions` já
versionadas (873 linhas no `Admin`, 593 no `System Administrator %28non-API user%29`,
209 no `MarketingProfile`, 201 no `Standard`). Substituir esses arquivos por um XML de
poucas linhas **destruiria, no repositório, todo esse histórico de configuração já
versionado** — mesmo que o efeito no deploy (concessão de FLS) fosse idêntico, porque a
API de Metadata já trata `Profile` como merge por elemento incluído no pacote,
independente de o arquivo estar "cheio" ou "vazio" no resto.

Optei por **inserir o bloco `<fieldPermissions>` dentro dos arquivos já existentes**
(logo após `<userLicense>`, antes do primeiro `<userPermissions>`, seguindo a ordem de
schema observada nos arquivos do baseline), preservando 100% do conteúdo anterior. O
resultado funcional é idêntico ao pedido pelo design — os mesmos 4 perfis, o mesmo campo,
`readable=true`/`editable=true`, nenhum perfil de integração tocado — e o `git diff`
confirma que a mudança em cada arquivo é estritamente aditiva (+5 linhas por arquivo, 0
remoções):

```
 Admin.profile-meta.xml                                       | 5 +++++
 MarketingProfile.profile-meta.xml                             | 5 +++++
 Standard.profile-meta.xml                                     | 5 +++++
 System Administrator %28non-API user%29.profile-meta.xml     | 5 +++++
 4 files changed, 20 insertions(+)
```

**Por que estou documentando isso como desvio, e não apenas fazendo:** o texto do design
foi aprovado no gate humano, e a instrução era literal. Decidi não seguir a letra porque
segui-la teria um efeito colateral que acho que o arquiteto não tinha em mente ao propor
(ele fundamentou a recomendação em "esses arquivos têm zero `fieldPermissions`", o que é
verdade, mas não observou que eles têm **outro conteúdo substancial** que seria perdido).
O efeito no **deploy/na org** é idêntico nas duas abordagens — a diferença é só sobre o
que fica versionado no **repositório**. Se o humano revisor do PR preferir a abordagem
literal (arquivo delta mínimo, descartando o resto), é uma troca de poucos minutos — mas
prefiro expor a decisão agora a apagar silenciosamente conteúdo já versionado.

**Mapeamento label → API name, confirmado (não presumido) nesta etapa** — resolvendo a
incerteza I-2 do design:

```sql
SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions
WHERE SobjectType='Lead' AND Field='Lead.Last_Touch_Date__c' AND Parent.IsOwnedByProfile = true
```
e
```sql
SELECT Name, Id FROM Profile WHERE Name IN
('Administrador do sistema','System Administrator (non-API user)','Usuário Padrão','Usuário do Marketing')
```

Confirmado: `Administrador do sistema` = arquivo `Admin`; `System Administrator (non-API
user)` = arquivo `System Administrator %28non-API user%29`; `Usuário Padrão` = arquivo
`Standard`; `Usuário do Marketing` = arquivo `MarketingProfile`. Nenhum dado pessoal foi
retornado — só nome de perfil e booleans de permissão (guardrail #2 respeitado).

### 2.5 `Flow` `Lead_AfterSave_MapeiaAniversarioNaConversao` (B-1)

Estrutura:
- **Start:** objeto `Lead`, `recordTriggerType=Update`, `triggerType=RecordAfterSave`,
  `doesRequireRecordChangedToMeetCriteria=true` (só dispara quando o registro **muda** para
  atender ao critério — evita reprocessar em todo update subsequente de um Lead já
  convertido). Filtros (`and`): `IsConverted = true`, `ConvertedContactId` não nulo,
  `Data_Aniversario__c` não nulo.
- **Record Update:** `Contact` filtrado por `Id = $Record.ConvertedContactId`, atribuindo
  `Birthdate = $Record.Data_Aniversario__c`.
- `status=Active`.

O padrão de "Update Records filtrado por Id, sem `inputReference` para `$Record`" (para
atualizar um objeto **diferente** do que disparou o flow) foi copiado do precedente real
já existente no repo (`Update_Atividades_Pendentes.flow-meta.xml`), e o padrão
`doesRequireRecordChangedToMeetCriteria` do precedente
`Oportunidade_Validar_Contato_na_Conta.flow-meta.xml` — **não inventei sintaxe**, ambos
foram confirmados por leitura direta de flows já deployados nesta org.

**Desvio em relação à recomendação de mitigação do design (§6.2) — reportado, não
mascarado:** o design recomendava "definir `<triggerOrder>` explícito no Flow novo
(colocando-o por último)" para mitigar a armadilha de 3 Flows `RecordAfterSave` ativos no
mesmo objeto sem ordem garantida. **Tentei implementar isso literalmente e o
`sf project deploy validate` rejeitou o arquivo:**

```
Error in Lead_AfterSave_MapeiaAniversarioNaConversao - Error parsing file: Element
{http://soap.sforce.com/2006/04/metadata}triggerOrder invalid at this location in type
FlowStart (80:23)
```

Ou seja: **`<triggerOrder>` não é um elemento válido do tipo `FlowStart` na versão de
metadata desta org (API v67.0)**, pelo menos na posição em que tentei (após
`recordTriggerType`, antes de `triggerType`). Não encontrei nenhum precedente de
`triggerOrder` em nenhum flow já existente no `force-app` deste ou de outros clientes do
repo (busquei) para confirmar uma posição alternativa válida, e não tenho como testar
outras posições sem gastar mais ciclos de validate — dado que é uma recomendação de
mitigação, não uma das decisões bloqueantes B-1–B-4, removi o elemento e **decido não
insistir**, reportando aqui em vez de mascarar.

**Consequência real:** a ordem de execução relativa entre os 3 Flows `RecordAfterSave`
agora ativos no objeto Lead (`Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes`, e este
novo) **não está definida via metadata versionado**. Se o humano quiser garantir uma ordem
específica, o caminho é a tela Setup → Process Automation → **Flow Trigger Explorer**,
que permite definir a ordem manualmente na org (mudança declarativa, não versionável por
este mecanismo). **Isso não bloqueia o deploy** — os 3 flows continuam funcionando, só sem
ordem garantida entre si, exatamente como já era o caso entre os 2 flows pré-existentes
antes desta demanda (nenhum deles tinha ordem definida). O próprio design já previa que
"o QA precisa validar que a conversão continua funcionando com os três ativos ao mesmo
tempo" — isso continua valendo e fica ainda mais importante dado que a mitigação de
`triggerOrder` não pôde ser aplicada.

**Recomendação para o humano no gate de QA/homologação:** decidir se vale a pena definir
a ordem manualmente via Flow Trigger Explorer na sandbox antes do smoke test, e registrar
essa decisão em `gates.md` — não é algo que este agente deva decidir sozinho.

---

## 3. Ordem de deploy (§10.2 do design)

Ordem lógica confirmada e reproduzida no pacote de validação:

1. `CustomField` `Lead.Data_Aniversario__c`
2. `Profile` (deltas de `fieldPermissions`) — Admin, System Administrator %28non-API
   user%29, Standard, MarketingProfile
3. `Layout` `Lead-Lead Layout`
4. `ValidationRule` `Lead.Valida_Data_Aniversario_Nao_Futura`
5. `Flow` `Lead_AfterSave_MapeiaAniversarioNaConversao` (condicional B-1 = Opção 2 — já
   decidida)

O `sf project deploy validate` não obriga ordem explícita dentro de um mesmo pacote (as
dependências — campo existir antes da VR/layout que o referenciam — são resolvidas na
mesma transação de metadata), mas a ordem acima é a que documento para quem for montar o
deploy real na etapa de release.

---

## 4. Rollback por componente (§10.3 do design)

| Componente | Rollback | Observação |
|---|---|---|
| `ValidationRule` | Redeploy com `<active>false</active>` | Primeira alavanca se alguma integração começar a falhar. Não apagar. |
| `Flow` | Desativar a versão / redeploy sem o Flow | — |
| `Layout` | Redeploy de `demandas/ACXYA-1/layout-lead-original-backup.xml` (confirmado byte-idêntico ao commit anterior a este build) | Cópia anexada a este PR. |
| `fieldPermissions` (Profile) | Redeploy dos mesmos 4 arquivos com `readable=false`/`editable=false` no bloco do campo | Revoga FLS sem apagar dado. Como optei por manter o resto do arquivo intacto (§2.4), o rollback é só reverter esse bloco específico via novo commit — não há risco de o rollback também mexer em `userPermissions`. |
| `CustomField` | **Não apagar como rollback.** Remover do layout + revogar FLS. | `destructiveChanges` apaga o campo e os dados nele — só se o humano decidir abandonar a demanda de vez. |

---

## 5. Passos manuais pós-deploy (§10.4 do design)

1. **Verificar FLS efetiva na org** depois do deploy real (modo de falha mais comum:
   "deploy passou, mas o campo sumiu" — nenhum agente deve pular esta checagem).
2. **Decisão pendente sobre `triggerOrder`** (novo, encontrado nesta etapa, não estava no
   design): decidir se vale configurar manualmente a ordem dos 3 Flows `RecordAfterSave`
   do Lead via Flow Trigger Explorer antes do smoke test da etapa 5. Ver §2.5 acima.
3. Nenhum passo manual de configuração de conversão via `LeadConvertSettings` — não se
   aplica à Opção 2 (§3.5 do design).
4. B-2 já veio decidido como Opção B (ativa desde o deploy) — não há passo de "ativar VR
   depois" a executar.

---

## 6. Validação (check-only) — resultado literal

### 6.1 Primeira tentativa: `--source-dir force-app` (pacote completo do repo)

```
sf project deploy validate --source-dir force-app --target-org sbx-acxya --test-level RunLocalTests
```

**Resultado: FALHOU**, com 5 erros de componente:

```
Error in standard__EnvironmentHub - defaultLandingTab must be included in tab list
Error in Lead_AfterSave_MapeiaAniversarioNaConversao - Error parsing file: Element
  {http://soap.sforce.com/2006/04/metadata}triggerOrder invalid at this location in type
  FlowStart (80:23)
Error in Case-Case Layout - Invalid field:SOLUTION.ISSUE in related list:RelatedSolutionList
Error in GuestCommunityCase - Error parsing file: 'Guest Community Case' is not a valid
  value for the enum 'QuickActionLabel' (26:56)
Error in NewCommunityCase - Error parsing file: 'New Community Case' is not a valid value
  for the enum 'QuickActionLabel' (26:54)

5 component error(s)
```

**Análise, sem mascarar:**
- **1 erro era meu** (`triggerOrder` inválido) — corrigido, ver §2.5.
- **4 erros são pré-existentes no baseline do repo, não relacionados a esta demanda.**
  Confirmado via `git status`/`git diff`: nenhum arquivo de `EnvironmentHub`, `Case-Case
  Layout`, `GuestCommunityCase` ou `NewCommunityCase` foi tocado por este build — são
  problemas que já existiam no `force-app` antes desta sessão. **Não são desta demanda e
  não devem ser corrigidos aqui** (escopo além da demanda, reprovável em code review por
  `padrao-entrega`). Registro isto para o humano decidir se abre uma demanda de dívida
  técnica separada — o `force-app` completo desta org **não passa hoje** num
  `deploy validate` de tudo, o que é relevante para o funcionamento de
  `ci-salesforce-validate.yml` caso ele algum dia rode contra o pacote inteiro em vez de só
  o que mudou.

### 6.2 Validação com o pacote da demanda (escopo desta entrega, após corrigir o
`triggerOrder`)

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

**Resultado literal: `SUCESSO`.**

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
deployId: 0AfHa00000DWpUXKA1
```

Os 8 componentes reportados como `Created`/`Changed`:

| fullName | type | state |
|---|---|---|
| `Lead.Data_Aniversario__c` | CustomField | Created |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` | Flow | Created |
| `Lead-Lead Layout` | Layout | Changed |
| `Admin` | Profile | Changed |
| `MarketingProfile` | Profile | Changed |
| `Standard` | Profile | Changed |
| `System Administrator %28non-API user%29` | Profile | Changed |
| `Lead.Valida_Data_Aniversario_Nao_Futura` | ValidationRule | Created |

10 testes Apex da org executados (os mesmos 10 já citados no design §10.2 —
`ChangePasswordControllerTest`, `CommunitiesLandingControllerTest`,
`CommunitiesLoginControllerTest`, `CommunitiesSelfRegConfirmControllerTest`,
`CommunitiesSelfRegControllerTest`, `ForgotPasswordControllerTest`,
`MicrobatchSelfRegControllerTest`, `MyProfilePageControllerTest`,
`SiteLoginControllerTest`, `SiteRegisterControllerTest`), **0 falhas**.

**Conclusão:** o pacote completo desta demanda (os 8 componentes do inventário §1, exceto
o arquivo de backup que não é metadata) **passa em `deploy validate` check-only contra
`sbx-acxya`**. Nenhum deploy real foi executado.

---

## 7. Incertezas e desvios — resumo consolidado para o humano

| # | Item | Natureza | Precisa de decisão humana? |
|---|---|---|---|
| D-1 | Deltas de `fieldPermissions` foram **inseridos nos arquivos de perfil completos existentes**, preservando `userPermissions` já versionadas, em vez de **substituir** os arquivos por um XML mínimo (leitura literal de §4.2). Efeito no deploy é idêntico; efeito no repositório é diferente. | Desvio consciente, documentado em §2.4 | Opcional — reverter para arquivo delta puro é possível se o revisor preferir a leitura literal. |
| D-2 | `<triggerOrder>` no `Flow` novo **não é aceito** por esta org/API v67.0 na posição testada (erro de validate). Mitigação de ordenação recomendada pelo design (§6.2) **não pôde ser implementada como metadata**. | Achado técnico, não decisão de negócio | **Sim** — decidir se define a ordem manualmente via Flow Trigger Explorer antes do QA (etapa 5), ou aceitar ordem não garantida entre os 3 Flows `RecordAfterSave` do Lead. |
| D-3 | `deploy validate` do `force-app` completo (todo o repo) falha por **4 erros pré-existentes, não relacionados a esta demanda** (`EnvironmentHub`, `Case-Case Layout`, `GuestCommunityCase`, `NewCommunityCase`). | Dívida técnica preexistente, achado colateral | Não bloqueia esta demanda. Recomendo demanda separada de "sustentação" para investigar/corrigir — sem isso, qualquer CI que valide o `force-app` inteiro (não só o diff do PR) vai falhar por motivos alheios a esta entrega. |
| D-4 | Mapeamento label → API name dos 4 perfis de B-4 foi **confirmado empiricamente** nesta etapa (query `FieldPermissions`/`Profile`, sem dado pessoal) — resolve a incerteza I-2 do design. | Incerteza do design, resolvida | Não. |
| D-5 | Retrieve do layout original confirmou que **não há drift** entre a org e o baseline local — o arquivo de backup é idêntico ao que já estava commitado antes deste build. | Confirmação, não desvio | Não. |
| D-6 | Recon usado (2026-09-07) segue válido — build ocorreu no mesmo dia da coleta, dentro da janela de 7 dias. | Confirmação | Não. |

Nenhuma decisão de negócio (B-1 a B-4) foi reaberta ou alterada por este agente. A
pendência de LGPD (finalidade/base legal, registrada em `gates.md` como pergunta aberta ao
consultor) **não foi resolvida nesta etapa** — continua como estava, não bloqueia o build,
mas segue precisando de confirmação do consultor antes da etapa de release.

---

## 8. O que este agente NÃO fez

- Nenhum deploy real (`sf project deploy start`) foi executado.
- `status.yaml` não foi alterado.
- Nenhuma homologação foi realizada — isso é etapa 5 (`qa`), gate humano.
- Nenhum SOQL retornou dado de cliente (CPF, e-mail, telefone, valor, data de nascimento
  de registro real) — só metadata (nomes de campo/perfil) e resultado de validate.
- Nada em produção — produção não está configurada nesta máquina e não foi tocada.

---

Build pronto para PR. Próximo passo: abrir PR contra `main`, anexar
`layout-lead-original-backup.xml`, e aguardar `ci-salesforce-validate.yml` + revisor
humano. Este agente não faz merge.
