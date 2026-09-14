# ACXYA-2 — Plano de build (executado)

**Etapa:** 4 (build declarativo) · **Agente:** `builder-declarativo` · **Data:** 2026-09-14
**Org:** `sbx-acxya-dev` — sandbox `https://acxya--sbxacxya.sandbox.my.salesforce.com`,
Org Id `00DHa000006bRsDMAU`, API v67.0. Confirmado via `sf org list` antes do primeiro comando
de escrita: única org conectada nesta máquina, `isSandbox: true`. Nenhuma outra org foi tocada.
**Branch:** `feature/ACXYA-2` (já existia, checked out — não foi criada nem renomeada).
**Base:** `03-design.md`, aprovado no gate por Leonardo em 2026-09-14T15:52:59Z (registrado em
`gates.md`, seção `aguardando_gate_design`). Nenhuma decisão divergiu do design; nenhuma
lacuna encontrada durante o build que exigisse escalar de volta ao arquiteto.

---

## 1. Componentes criados/alterados

| Ação | Tipo | API name | Caminho |
|---|---|---|---|
| **Criar** | `CustomField` | `Lead.Descobertas_da_Reuniao__c` | `force-app/main/default/objects/Lead/fields/Descobertas_da_Reuniao__c.field-meta.xml` |
| **Alterar** | `Layout` | `Lead-Lead Layout` | `force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`) | `Admin` | `force-app/main/default/profiles/Admin.profile-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`) | `System Administrator %28non-API user%29` | `force-app/main/default/profiles/System Administrator %28non-API user%29.profile-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`) | `Standard` | `force-app/main/default/profiles/Standard.profile-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`) | `MarketingProfile` | `force-app/main/default/profiles/MarketingProfile.profile-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`, bloco novo) | `SolutionManager` | `force-app/main/default/profiles/SolutionManager.profile-meta.xml` |
| **Alterar** | `Profile` (delta `fieldPermissions`, bloco novo) | `ContractManager` | `force-app/main/default/profiles/ContractManager.profile-meta.xml` |

Nenhum outro componente foi tocado. `FlexiPage` `Lead_P_gina_de_registro` **não foi alterada**,
conforme §4.2 do design. `Need_Contexto__c` e `Description` **não foram alterados**, conforme §2.

### 1.1 `CustomField` — metadata usada (literal de `03-design.md` §3.3)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Descobertas_da_Reuniao__c</fullName>
    <description>ACXYA-2 — Descobertas e insights coletados em reunião com o potencial cliente.</description>
    <externalId>false</externalId>
    <label>Descobertas da Reunião</label>
    <length>32768</length>
    <trackFeedHistory>false</trackFeedHistory>
    <trackHistory>false</trackHistory>
    <type>LongTextArea</type>
    <visibleLines>5</visibleLines>
</CustomField>
```

### 1.2 `Layout` — item adicionado

Um `layoutItems` (`behavior: Edit`, `field: Descobertas_da_Reuniao__c`) foi inserido como
**último item da segunda coluna** da seção "Informações de classificação" — imediatamente após
`Qualified_Lead__c`, que já era o último item existente da seção. Nenhuma outra seção,
`FlexiPage` ou componente de layout foi alterado.

### 1.3 `Profile` — deltas de `fieldPermissions`

Aplicado o mesmo padrão que ACXYA-1 deixou para `Data_Aniversario__c`: um bloco
`fieldPermissions` (`editable: true`, `readable: true`, `field: Lead.Descobertas_da_Reuniao__c`)
por perfil.

- `Admin`, `System Administrator %28non-API user%29`, `Standard`, `MarketingProfile` — já
  continham o bloco `fieldPermissions` de `Data_Aniversario__c`; o novo bloco foi adicionado
  imediatamente depois, no mesmo arquivo.
- `SolutionManager`, `ContractManager` — **não continham nenhum bloco `fieldPermissions`**
  antes desta demanda (só `userPermissions`). O bloco novo foi inserido antes do primeiro
  `userPermissions`, respeitando a ordem alfabética dos elementos do schema de `Profile`
  (`fieldPermissions` antes de `userPermissions`).

Nenhum arquivo de perfil teve `objectPermissions` alterado — confirmado no design (§5.3) que
nenhum arquivo de `Profile` carrega `objectPermissions` de `Lead` nesta org, e este build não
mudou essa característica.

---

## 2. Mapeamento label → API name dos 6 perfis (confirmado, não presumido)

Confirmado por `sf org list metadata --metadata-type Profile --target-org sbx-acxya-dev` — os
6 `fullName` abaixo batem exatamente com o retorno da org e com os arquivos já existentes em
`force-app/main/default/profiles/` (nenhum arquivo precisou ser criado; todos os 6 já existiam
no repositório antes desta demanda):

| API name (`fullName` confirmado na org) | Label pt-BR (§5.2 do design) | Arquivo |
|---|---|---|
| `Admin` | Administrador do sistema | `Admin.profile-meta.xml` |
| `System Administrator %28non-API user%29` | System Administrator (non-API user) | `System Administrator %28non-API user%29.profile-meta.xml` |
| `Standard` | Usuário Padrão | `Standard.profile-meta.xml` |
| `MarketingProfile` | Usuário do Marketing | `MarketingProfile.profile-meta.xml` |
| `SolutionManager` | Gerente de soluções | `SolutionManager.profile-meta.xml` |
| `ContractManager` | Gerente do contrato | `ContractManager.profile-meta.xml` |

A lacuna deixada em aberto pelo design (§5.3, "não confirmei par a par") está fechada: os 6
`fullName` foram conferidos contra `sf org list metadata --metadata-type Profile` nesta sessão,
não inferidos do conjunto padrão de perfis do Salesforce.

---

## 3. Resultado do deploy

Dois passos, ambos contra `sbx-acxya-dev`, restritos aos 8 componentes desta demanda (nenhum
outro arquivo de `force-app/` foi incluído no pacote):

1. **`sf project deploy validate`** (check-only) — `status: Succeeded`, `success: true`,
   `numberComponentErrors: 0`, `numberComponentsDeployed: 8/8`. Rodou com testes Apex (10
   testes existentes na org, 0 falhas — nenhuma classe de teste nova foi necessária, pois não
   há Apex nesta demanda).
2. **`sf project deploy start`** (deploy real) — **Deploy Id `0AfHa00000Dax6xKAB`**,
   `status: Succeeded`, `success: true`, `numberComponentErrors: 0`,
   `numberComponentsDeployed: 8/8`, `zipFileCount: 9`.

Componentes confirmados no resultado do deploy: `Lead.Descobertas_da_Reuniao__c` (Created),
`Lead-Lead Layout` (Changed), e os 6 arquivos de `Profile` listados acima (Changed).

Pós-deploy, `sf sobject describe --sobject Lead` confirma o campo na org:
`Descobertas_da_Reuniao__c`, `type: textarea`, `length: 32768`, `label: "Descobertas da
Reunião"`, `createable/updateable: true`. Nenhuma consulta retornou dado de registro — só
metadata do describe (guardrail #2).

---

## 4. Pull Request

**PR #<preencher>** `feature/ACXYA-2` → `main` — abrir manualmente se a criação automática via
`gh` não constar como concluída nesta sessão (ver nota no fechamento do relatório da sessão).
Nenhum merge foi realizado por este agente.

---

## 5. O que fica para a próxima etapa (QA)

- Verificação de FLS por perfil é item obrigatório do roteiro de QA (R1 do design): confirmar
  que o campo aparece em edição para usuários dos 6 perfis e **não** aparece para o perfil de
  integração (`Sales Insights Integration User`) nem para `Atendimento Konecta Perfil`.
- `sbx-acxya-qa` ainda não existe (confirmado no `CLAUDE.md` do cliente) — a demanda para na
  etapa 5 até a sandbox de QA existir. Isso é o comportamento esperado, não um bloqueio deste
  build.
