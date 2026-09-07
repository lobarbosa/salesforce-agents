# ACXYA-1 — Release (etapa 6)

**Agente:** `release` · **Data:** 2026-09-07 · **Branch:** `feature/ACXYA-1`
**Org alvo confirmada:** `sbx-acxya` (Sandbox), Org Id `00DHa000006bRsDMAU`, usuário
`lbarbosa@konectabr.com.sbxacxya`, API v67.0 — reconfirmada via `sf org list` antes do
primeiro comando de deploy. **Produção não está configurada nesta máquina e não foi tocada
em nenhum momento.**

**Autorização:** exceção de sequenciamento registrada em `gates.md` (linha "Autorização de
deploy real + decisão de negócio (Birthdate)", 2026-09-07) — Leo autorizou explicitamente
o deploy real na sandbox do mesmo pacote de 8 componentes já validado em `05-testes.md`
§3.2, **antes** da homologação formal, para destravar a execução dos 16 casos de QA
(T-01..T-16), hoje impossível por ausência de metadata na org. Esta etapa executa
exatamente essa autorização — nada além dela.

---

## 1. Revalidação pré-deploy (passo 1)

Reexecutado o mesmo `sf project deploy validate` (check-only) documentado em
`05-testes.md` §3.2 / `04-plano-build.md` §6.2, com os mesmos 8 componentes e
`--test-level RunLocalTests`, contra `sbx-acxya`:

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
  --target-org sbx-acxya --test-level RunLocalTests --json
```

**Resultado literal:**

```
status: Succeeded
success: true
numberComponentErrors: 0
numberComponentsDeployed: 8
numberComponentsTotal: 8
numberTestErrors: 0
numberTestsCompleted: 10
numberTestsTotal: 10
rollbackOnError: true
id (deployId da validação): 0AfHa00000DWpvxKAD
```

Mesmo resultado em substância que o já documentado em `05-testes.md` (`0AfHa00000DWkBWKA1`)
e em `04-plano-build.md` (`0AfHa00000DWpUXKA1`) — `Succeeded`, 0 erros, 8/8 componentes,
10/10 testes Apex da org sem falha. Nada mudou desde a última validação. **Prossegui para o
deploy real conforme o critério de "PARE se o resultado mudou" — não mudou.**

---

## 2. Confirmação do backup de layout (passo 2)

`Lead-Lead Layout` é `Changed` (não `Created`) — o rollback depende do backup em
`demandas/ACXYA-1/layout-lead-original-backup.xml` (§10.3 do design).

Procedimento: `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` para uma
pasta temporária local ao projeto DX (`clients/acxya/.tmp-layout-check`, removida logo
depois — nunca commitada), e diff/md5 contra o backup:

```
diff demandas/ACXYA-1/layout-lead-original-backup.xml \
     .tmp-layout-check/layouts/Lead-Lead\ Layout.layout-meta.xml
→ (vazio, sem diferenças)

md5sum:
fadba4c5543a0b278b059345a884b199  demandas/ACXYA-1/layout-lead-original-backup.xml
fadba4c5543a0b278b059345a884b199  .tmp-layout-check/layouts/Lead-Lead Layout.layout-meta.xml
```

**Backup confirmado byte-idêntico ao layout que estava na org imediatamente antes deste
deploy.** O rollback de layout (§10.3 do design, tabela de rollback abaixo) é confiável.
Pasta temporária removida (`rm -rf .tmp-layout-check`); `git status --short` limpo antes de
prosseguir.

---

## 3. Deploy real (passo 3)

```
sf project deploy start \
  --metadata "CustomField:Lead.Data_Aniversario__c" \
  --metadata "ValidationRule:Lead.Valida_Data_Aniversario_Nao_Futura" \
  --metadata "Layout:Lead-Lead Layout" \
  --metadata "Flow:Lead_AfterSave_MapeiaAniversarioNaConversao" \
  --metadata "Profile:Admin" \
  --metadata "Profile:MarketingProfile" \
  --metadata "Profile:Standard" \
  --metadata "Profile:System Administrator %28non-API user%29" \
  --target-org sbx-acxya --test-level RunLocalTests --json
```

**Resultado literal:**

```
status: Succeeded
success: true
checkOnly: false
numberComponentErrors: 0
numberComponentsDeployed: 8
numberComponentsTotal: 8
numberTestErrors: 0
numberTestsCompleted: 10
numberTestsTotal: 10
rollbackOnError: true
deployId: 0AfHa00000DWpzBKAT
completedDate: 2026-09-07T22:19:03.000Z
```

Componentes reportados (`componentFailures: []`):

| fullName | type | created | changed |
|---|---|---|---|
| `Lead.Data_Aniversario__c` | CustomField | true | true |
| `Lead.Valida_Data_Aniversario_Nao_Futura` | ValidationRule | true | true |
| `Lead-Lead Layout` | Layout | false | true |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` | Flow | true | true |
| `Admin` | Profile | false | true |
| `MarketingProfile` | Profile | false | true |
| `Standard` | Profile | false | true |
| `System Administrator %28non-API user%29` | Profile | false | true |

10 testes Apex da org executados (`ChangePasswordControllerTest`,
`CommunitiesLandingControllerTest`, `CommunitiesLoginControllerTest`,
`CommunitiesSelfRegConfirmControllerTest`, `CommunitiesSelfRegControllerTest`,
`ForgotPasswordControllerTest`, `MicrobatchSelfRegControllerTest`,
`MyProfilePageControllerTest`, `SiteLoginControllerTest`, `SiteRegisterControllerTest`),
**0 falhas**.

**DEPLOY REAL EXECUTADO COM SUCESSO EM SANDBOX (`sbx-acxya`). Nenhum deploy em produção —
produção não está configurada nesta máquina e não foi alcançada em nenhum momento desta
sessão.**

---

## 4. Verificação pós-deploy (passo 4) — o que destrava o QA

Refeitas as mesmas consultas de `05-testes.md` §3.1, agora contra a org **pós-deploy**:

| Componente | Existe/ativo agora? | Como confirmei |
|---|---|---|
| `Lead.Data_Aniversario__c` | **Sim** | Tooling API: `SELECT QualifiedApiName, DataType, IsCreatable, IsUpdatable FROM EntityParticle WHERE EntityDefinitionId='Lead' AND QualifiedApiName='Data_Aniversario__c'` → 1 registro, `DataType=date`, `IsCreatable=true`, `IsUpdatable=true`. |
| `Lead.Valida_Data_Aniversario_Nao_Futura` (VR) | **Sim, `Active=true`** | Tooling API: `SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Lead'` → 5 registros; as 4 pré-existentes seguem `Active=false`, e `Valida_Data_Aniversario_Nao_Futura` aparece com `Active=true`. Consistente com B-2 Opção B. |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` (Flow) | **Sim, `IsActive=true`** | `sf org list metadata --metadata-type Flow` confirma a existência do componente (`fullName=Lead_AfterSave_MapeiaAniversarioNaConversao`, criado em `2026-09-07T22:18:53Z`). `SELECT ApiName, Label, ActiveVersionId, IsActive, ProcessType FROM FlowDefinitionView WHERE ApiName='Lead_AfterSave_MapeiaAniversarioNaConversao'` → `IsActive=true`, `ActiveVersionId` preenchido, `ProcessType=AutoLaunchedFlow`. |
| FLS nos 4 perfis de B-4 | **Sim, exatamente os 4, nenhum a mais** | `SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE SobjectType='Lead' AND Field='Lead.Data_Aniversario__c' AND Parent.IsOwnedByProfile = true` → 4 registros, todos `PermissionsRead=true`/`PermissionsEdit=true`: `Administrador do sistema`, `System Administrator (non-API user)`, `Usuário do Marketing`, `Usuário Padrão`. Nenhum perfil de integração na lista — consistente com B-4 = P-2 (minimização). |
| `Lead-Lead Layout` (com o item novo) | **Sim** | `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` para pasta temporária local ao projeto → arquivo contém `Data_Aniversario__c` (1 ocorrência) e é **byte-idêntico** (`diff` vazio) ao arquivo já versionado em `force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml` desta branch. Pasta temporária removida após a checagem; `git status --short` limpo. |

Nenhuma consulta retornou dado de cliente — só metadata, nomes de perfil/campo, booleans de
permissão e contagens (guardrail #2 respeitado).

**Conclusão:** os 8 componentes da demanda existem e estão ativos em `sbx-acxya`. O bloqueio
de execução funcional registrado em `05-testes.md` §1 está resolvido — o próximo agente
(`qa`, após correção manual de `status.yaml` de volta para `qa`, conforme já planejado em
`gates.md`) pode rodar os 16 casos T-01..T-16 contra metadata real.

---

## 5. Procedimento de rollback (se precisar reverter)

Mesma tabela de `03-design.md` §10.3 / `04-plano-build.md` §4, reafirmada aqui como plano de
ação imediato, com os IDs reais do deploy que acabou de acontecer:

| Componente | Como reverter | Como |
|---|---|---|
| `ValidationRule` `Valida_Data_Aniversario_Nao_Futura` | **Primeira alavanca** se alguma integração começar a falhar. Redeploy do mesmo XML com `<active>false</active>`. Não apagar a VR. | `sf project deploy start --metadata "ValidationRule:Lead.Valida_Data_Aniversario_Nao_Futura"` após editar o XML localmente para `active=false`. |
| `Flow` `Lead_AfterSave_MapeiaAniversarioNaConversao` | Desativar a versão ativa (via Setup → Flows → Deactivate) ou redeploy do Flow com `<status>Draft</status>`/inativo. | Setup manual ou redeploy do metadata. |
| `Layout` `Lead-Lead Layout` | Redeploy do backup `demandas/ACXYA-1/layout-lead-original-backup.xml` (confirmado byte-idêntico ao estado pré-deploy, §2 acima). | `sf project deploy start --metadata "Layout:Lead-Lead Layout"` apontando o source para o arquivo de backup (copiar de volta para o caminho do `force-app` antes do deploy, ou usar `--metadata-dir` apontando para uma cópia temporária do projeto com o backup no lugar do arquivo atual). |
| `fieldPermissions` (4 Profiles) | Redeploy dos mesmos 4 arquivos de perfil com `readable=false`/`editable=false` no bloco de `Data_Aniversario__c`, preservando o resto do arquivo (mesma abordagem do build, D-1 em `04-plano-build.md`). Revoga FLS sem apagar dado. | Editar o bloco `fieldPermissions` nos 4 arquivos e `sf project deploy start --metadata "Profile:..."` para os 4. |
| `CustomField` `Lead.Data_Aniversario__c` | **Não apagar como rollback.** Só remover do layout + revogar FLS (os dois itens acima). `destructiveChanges` apagaria o campo e qualquer dado nele — só se o humano decidir abandonar a demanda de vez. | — |

Esta é uma sandbox de trabalho — reverter aqui é seguro e rápido, mas o procedimento acima é
o mesmo que valeria (com mais cautela) para um eventual deploy futuro em UAT/produção, que
continua fora do escopo deste agente.

---

## 6. Passos manuais pós-deploy

1. **Nenhum passo manual bloqueante identificado.** FLS, VR ativa e Flow ativo já vieram
   corretos no próprio deploy (nenhum passo de "ativar depois" — B-2 já decidido como Opção
   B, ativa desde o deploy; ver §3 de `03-design.md`).
2. **Pendência técnica não resolvida por este deploy, carregada de `04-plano-build.md` D-2 /
   `gates.md`:** a ordem de execução entre os 3 Flows `RecordAfterSave` do Lead
   (`Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes`,
   `Lead_AfterSave_MapeiaAniversarioNaConversao`) continua **não garantida via metadata**
   (`<triggerOrder>` rejeitado pela API v67.0). O humano pode, opcionalmente, configurar a
   ordem manualmente via Setup → Process Automation → Flow Trigger Explorer antes do QA
   rodar T-16 — mas a decisão registrada em `gates.md` foi aceitar o risco e deixar o
   próprio T-16 confirmar empiricamente se há problema. **Não fiz essa configuração** — é
   decisão declarativa manual do humano, não deste agente, e alterá-la seria mexer no que já
   foi revisado/aprovado (fora do escopo desta etapa).
3. **Verificação de FLS efetiva por usuário real** (não só pela API `FieldPermissions`):
   recomendo, antes do smoke test do QA, um "Login As" rápido com um usuário de cada um dos
   4 perfis para confirmar visualmente que o campo aparece no layout — a API já confirma a
   permissão, mas a checagem visual é o item que `03-design.md` §4.3 chama de "modo de falha
   mais comum" (nenhuma surpresa esperada, já que a API confirma FLS + layout juntos, mas é
   o passo manual mais barato de fazer antes de liberar o QA funcional).
4. **Nenhuma permission set nova, nenhum dado de configuração adicional e nenhuma ativação de
   Flow separada é necessária** — o deploy já entregou tudo ativo.

---

## 7. Pendências abertas (carregadas, não resolvidas por este agente)

1. **LGPD — finalidade/base legal da coleta de data de aniversário.** Segue como **pergunta
   aberta ao consultor**, registrada em `gates.md` (gate de Design, 2026-09-07) e reafirmada
   em `04-plano-build.md` §7 e `05-testes.md` §5. **Este deploy é de sandbox de trabalho, não
   de produção — não fecha essa pendência.** A assunção de trabalho adotada (legítimo
   interesse, uso interno de relacionamento comercial) permanece apenas uma assunção do
   agente/orquestrador até confirmação explícita do consultor responsável pela demanda,
   exigida antes de qualquer avanço para produção (que, reforço, está fora do escopo de
   qualquer agente deste squad).
2. **D-2 — ordem não garantida entre os 3 Flows `RecordAfterSave` do Lead.** Continua **não
   mitigada**, apenas adiada para o caso de teste **T-16** de `05-testes.md`, que agora pode
   finalmente rodar (metadata existe). Se T-16 encontrar comportamento inconsistente, a
   decisão volta ao gate do arquiteto/humano antes de liberar homologação — não é uma falha
   "normal" de teste.
3. **Achado do QA ainda não fechado por nenhum gate desde `gates.md`:** o Flow sobrescreve
   `Contact.Birthdate` na conversão sem checar valor pré-existente — **já resolvido** no
   penúltimo gate ("Autorização de deploy real + decisão de negócio (Birthdate)"): o humano
   confirmou que sempre sobrescrever é o comportamento pretendido. Registrado aqui só para
   rastreabilidade; não é mais uma pendência aberta.
4. **`status.yaml` não foi alterado por este agente** — quem avança/corrige o estágio é o
   orquestrador. Meu entendimento do plano já registrado em `gates.md` é que o próximo passo
   é uma correção manual de volta para `qa`, para o agente `qa` rodar de fato os 16 casos
   contra metadata real; depois, `aguardando_homologacao` para homologação do resultado real.

---

## 8. O que este agente NÃO fez

- Nenhum deploy, DML ou Apex anônimo em produção — produção não está configurada nesta
  máquina e não foi tocada.
- Nenhuma alteração no Flow, na VR, no campo ou no layout além de implantar exatamente o que
  já estava revisado/aprovado — nenhum "conserto" foi feito.
- Nenhum caso funcional de QA (T-01..T-16) foi executado — isso é papel do agente `qa` na
  próxima etapa.
- Nenhum SOQL retornou dado de cliente — só metadata, contagens e booleans de permissão.
- `status.yaml` não foi alterado.
- Nenhum merge, nenhum PR aberto/fechado, nenhum `git push --force`.

---

Deploy real concluído com sucesso em `sbx-acxya`. Pronto para o agente `qa` retomar a
execução funcional dos 16 casos, após a correção manual de `status.yaml` já planejada em
`gates.md`.
