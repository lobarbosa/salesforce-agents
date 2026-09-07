# ACXYA-1 — Recon da org

**Coletado em:** 2026-09-07
**Org:** `sbx-acxya` — sandbox
`https://acxya--sbxacxya.sandbox.my.salesforce.com` · Org Id `00DHa000006bRsDMAU`
Username `lbarbosa@konectabr.com.sbxacxya` · API v67.0
**Produção:** não configurada nesta máquina — nenhum comando tocou prod.

> Validade: recon vence em 7 dias (2026-09-14). Depois disso, refazer antes de buildar.

---

## 1. O campo já existe? — **NÃO**

`sf sobject describe --sobject Lead` retornou **79 campos**. Busca por
`birth` / `aniver` / `nasc` em API name e label: **zero ocorrências**.

Campos de data hoje existentes no Lead:

| API name | Tipo | Origem |
|---|---|---|
| `ConvertedDate`, `CreatedDate`, `LastModifiedDate`, `SystemModstamp`, `LastActivityDate`, `LastViewedDate`, `LastReferencedDate`, `EmailBouncedDate` | date/datetime | padrão |
| `Last_Touch_Date__c` | date | custom do cliente |

**Conclusão:** não há duplicidade. `Data_Aniversario__c` está livre para criação.
Pendência #9 da análise → **resolvida**.

## 2. Convenção de nomenclatura — confirma a decisão da análise

Os 29 campos custom do Lead confirmam empiricamente o padrão registrado no
`CLAUDE.md` do cliente: **sem prefixo de origem, rótulo em português, palavras
separadas por underscore**.

Precedentes diretos: `Capital_Social__c`, `Numero_de_Agentes__c`,
`Status_Atividades__c`, `Last_Touch_Date__c`, `Canais_de_Atendimento__c`.

Nenhum campo do cliente usa prefixo. Os únicos prefixados são de pacote gerenciado
(`sfLma__`, `et4ae5__`). → `Data_Aniversario__c` é aderente. Pendência #1 → **resolvida**.

## 3. Record Types e Layouts — um só de cada

- **Record Types de Lead:** 1 ativo — `Mestre`.
- **Layouts de Lead:** 1 — `Lead Layout`.

**Premissa P5 da análise → confirmada.** Não há segregação por Record Type; o campo
entra num único layout. Pendência #5 → **resolvida**.

## 4. Automação existente no Lead

### Flows
A org tem **114 Flows ativos** no total. Com trigger no objeto Lead, **2**:

| Flow | Tipo | Momento |
|---|---|---|
| `Count_de_Tasks_Pendentes` | AutoLaunchedFlow | **RecordAfterSave** |
| `Leads_do_Marketing_Cloud` | AutoLaunchedFlow | **RecordAfterSave** |

**Nenhum Flow `RecordBeforeSave` no Lead.** Uma Validation Rule roda antes dos
after-save flows na ordem de execução → sem conflito de ordenação.

Existem no `force-app` local outros flows de Lead retrieved (`Lead_Qualification_Custom_Flow`,
`Lead_Criacao_de_Tarefas`, `JBSystemFlow_Lead`, `Atualiza_Lead_Atividade_Status`,
`Leads_do_Marketing_Cloud`) — **apenas `Leads_do_Marketing_Cloud` e `Count_de_Tasks_Pendentes`
estão ativos na org.** Os demais são versões inativas. Não confie no `force-app` como
retrato do que está ligado.

### Apex Triggers
1 trigger no Lead: `updatePackages` — namespace `sfLma`, `ManageableState: installed`.
É do pacote gerenciado License Management App, **não é código do cliente**, não é
alterável e não interage com campos custom do cliente.

### Validation Rules
4 Validation Rules existem no Lead — **todas as 4 inativas**:

| Nome | Ativa? |
|---|---|
| `Validacao_de_Telefone` | Não |
| `Validacao_de_Campos` | Não |
| `Valida_Lead_Atividades_Pendentes` | Não |
| `Lead_status_MQL` | Não |

⚠️ **Sinal para o arquiteto:** hoje o Lead desta org **não tem nenhuma validação ativa**.
Quatro foram criadas e depois desligadas. Não sabemos por quê — pode ser decisão
operacional deliberada (não travar entrada de lead) ou resíduo. A análise aprovou
"bloquear data futura" como Validation Rule; antes de ligar a primeira VR ativa do
objeto, isso precisa de decisão consciente. Ver risco R1 abaixo.

## 5. Destino da conversão — `Contact.Birthdate` existe e serve

| Campo | Tipo | Custom? | Atualizável? |
|---|---|---|---|
| `Contact.Birthdate` | `date` | não (padrão) | sim |

Tipo `date` de ambos os lados → **compatível para Lead Conversion Field Mapping**
(o mapeamento exige compatibilidade de tipo). Premissa P4 → **viável tecnicamente**.

## 6. Volume de dados

`SELECT COUNT() FROM Lead` na sandbox → **0 registros**.

Só contagem agregada, nenhum dado pessoal trafegado (guardrail #2).

**Impacto no QA:** a sandbox está vazia de Leads. O roteiro de teste da etapa 5 terá
que **criar seus próprios registros de teste** — não há massa existente para validar
comportamento, nem para avaliar impacto retroativo de uma VR.

## 7. Contexto de integrações (relevante para o risco)

Pacotes gerenciados e permission sets indicam integrações ativas que **escrevem em Lead**:

- **Marketing Cloud** — namespace `et4ae5__` (campos no Lead), flow ativo
  `Leads_do_Marketing_Cloud`, permission sets `ExactTarget_Integration`,
  `Marketing_Cloud_System_User`, `Marketing_cloud_connect_App`.
- **WhatsApp** — campo `WA_Chat__c` no Lead, permission sets `WhatsApp_Integration_*`.
- **sfLma** (License Management App) — trigger `updatePackages`.

Pendência #6 da análise (origem do preenchimento) **permanece aberta**, mas o recon
mostra que Lead nesta org **não é preenchido só por humano** — há pelo menos uma
integração de Marketing Cloud criando/atualizando Lead.

---

## Riscos identificados para o design

**R1 — Ligar a primeira Validation Rule ativa do Lead.** As 4 VRs existentes estão
desligadas. Ativar uma VR de data futura torna-se a única validação ativa do objeto.
Se alguma foi desligada por quebrar integração no passado, o mesmo pode acontecer aqui.
→ O arquiteto precisa decidir se a VR nasce ativa, e o humano precisa confirmar.

**R2 — VR versus integração.** `Leads_do_Marketing_Cloud` e a integração WhatsApp
escrevem em Lead. Uma VR bloqueia **qualquer** save que viole a regra, inclusive o de
integração — que tipicamente falha silenciosamente ou acumula erro. Se o campo for
preenchido por integração com dado sujo, a VR derruba o save do Lead inteiro, não só
do campo. → Avaliar escopo da VR (ex.: `AND(NOT(ISBLANK(...)), ... )` só quando
preenchido) e se deve excluir usuários de integração.

**R3 — Recon não cobre Web-to-Lead.** Pendência #6 continua aberta. Se houver
formulário Web-to-Lead público capturando esse campo, há implicação de LGPD (data de
nascimento é dado pessoal) e de validação no lado externo. Não confirmado.

**R4 — Sandbox sem massa de Lead.** Nenhum registro para testar. QA vai depender
inteiramente de dados criados. Não é possível medir impacto retroativo de uma VR
sobre registros existentes — porque não existem.

## Pendências da análise: estado após recon

| # | Pendência | Estado |
|---|---|---|
| 1 | Prefixo / API name | ✅ Resolvida — `Data_Aniversario__c`, aderente ao padrão da org |
| 2 | Tipo Date vs Date/Time | ✅ Resolvida na análise — Date |
| 3 | Validação de data futura | ✅ Decidida — mas ver R1/R2 |
| 4 | Obrigatoriedade | ⬜ **Aberta** — assumindo opcional |
| 5 | Layout / Record Type | ✅ Resolvida — 1 RT (`Mestre`), 1 layout (`Lead Layout`) |
| 6 | Origem do preenchimento | ⬜ **Aberta** — recon mostra integrações escrevendo em Lead |
| 7 | Reporting / "aniversariantes do mês" | ⬜ **Aberta** — não solicitado |
| 8 | Mapeamento na conversão | ✅ Viável — `Contact.Birthdate`, tipo compatível |
| 9 | Campo já existe? | ✅ Resolvida — não existe |

---

## Comandos executados

```bash
sf org list
sf org display --target-org sbx-acxya
sf sobject describe --sobject Lead --target-org sbx-acxya
sf sobject describe --sobject Contact --target-org sbx-acxya
sf data query --use-tooling-api --query "SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'Lead'"
sf data query --use-tooling-api --query "SELECT Name, TableEnumOrId, Status FROM ApexTrigger WHERE TableEnumOrId = 'Lead'"
sf data query --use-tooling-api --query "SELECT Name, NamespacePrefix, ManageableState FROM ApexTrigger WHERE Name = 'updatePackages'"
sf data query --use-tooling-api --query "SELECT Name FROM Layout WHERE TableEnumOrId = 'Lead'"
sf data query --use-tooling-api --query "SELECT Name, IsCustom, IsOwnedByProfile FROM PermissionSet WHERE IsOwnedByProfile = false"
sf data query --query "SELECT ApiName, ProcessType, TriggerType, TriggerObjectOrEventLabel, IsActive FROM FlowDefinitionView WHERE IsActive = true"
sf data query --query "SELECT COUNT() FROM Lead"
```

**Nota de método:** a primeira tentativa de listar Flows usou `FlowDefinitionView` com
`--use-tooling-api` e retornou `INVALID_TYPE` — o erro foi mascarado e apareceu como
"0 Flows ativos". Foi detectado ao confrontar com os flows presentes no `force-app`
local e refeito sem a flag, revelando 114 flows ativos. Registrado aqui porque o
resultado errado era plausível e quase virou premissa de design.
