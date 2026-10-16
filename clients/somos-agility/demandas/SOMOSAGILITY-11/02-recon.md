# SOMOSAGILITY-11 — Recon da org

**Coletado em:** 2026-10-16
**Org:** `sbx-somos-agility-dev` — sandbox (confirmado `Organization.IsSandbox = true`)
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com` · Org Id `00DHa0000070wxfMAA` ·
Enterprise Edition · instância BRA8S · API v68
**Produção:** não configurada nesta máquina — nenhum comando tocou prod. Confirmado via
`sf org list` antes de qualquer outro comando: a única org conectada é a sandbox acima.

> Validade: recon vence em 7 dias (2026-10-23). Depois disso, refazer antes de buildar.

---

## 0. Achado principal — o campo provavelmente já existe

A pendência #1 do `01-analise.md` era "qual objeto recebe o campo" e a #3 era "o campo já
existe?". Busca por objeto/campo com "logíst*"/"DSA" na org (`sf sobject list --sobject
custom`) encontrou três candidatos: **`DSA__c`**, **`Novo_DSA__c`** e
`Workflow_de_Valida_o_de_DSA__c`. O título da demanda ("CAMPO LOGÍSTICA - DSA") aponta para
os dois primeiros.

**Os dois já têm um campo com rótulo de logística/backoffice:**

| Objeto | Campo (API name) | Rótulo | Tipo | Está no layout principal? |
|---|---|---|---|---|
| `DSA__c` | `Status_Backoffice__c` | **"Status Logística"** | picklist | Sim — `DSA__c-Layout de DSA`, editável |
| `Novo_DSA__c` | `Status_backoffice__c` | "Status backoffice" | picklist | Sim — `Novo_DSA__c-Layout de Novo DSA`, editável |

Isso muda o formato provável da demanda: não é "criar campo novo", é **popular/atualizar em
massa um campo que já existe** — compatível com o texto original ("inclusão das informações
... em massa", não "criação de campo"). Fica para o arquiteto decidir isso com confiança,
mas o recon não encontrou nenhum outro candidato melhor para "status de logística" na org.

**Incerteza que o recon não resolve:** qual dos dois objetos é o alvo real (ou os dois).
`DSA__c` parece ser o objeto legado e `Novo_DSA__c` o atual (nome literal "Novo DSA"), mas
isso é inferência de nome, não confirmado por nenhuma fonte (ver §5). A planilha anexada —
que não chegou a este repositório — provavelmente resolveria isso sozinha.

## 1. `DSA__c` — picklist values do campo

```
sf sobject describe --sobject DSA__c --target-org sbx-somos-agility-dev
```

`Status_Backoffice__c` ("Status Logística") tem 5 valores, todos ativos:

- Aguardando comercial
- Aguardando definição do GP
- Aguardando liberação de faturamento
- Em andamento
- Finalizado

Existe também `Observacao_BackOffice__c` (textarea, "Observação Logística"), logo ao lado
no layout — par campo+observação, padrão repetido em outras seções do mesmo objeto
(ex.: `Data_Efetiva_de_Chegada_na_Agility__c` + `Observacao_chegada__c`).

**Atenção:** `DSA__c` tem *outro* campo picklist chamado `Status_DSA__c` ("Status DSA"),
diferente de `Status_Backoffice__c`. São dois campos de status distintos no mesmo objeto —
não confundir ao escrever o design.

## 2. `Novo_DSA__c` — picklist values do campo

`Status_backoffice__c` ("Status backoffice") tem 8 valores, todos ativos — e são valores de
**fluxo de aprovação**, não de logística:

```
Aguardando comercial, Aguardando definição do GP, Aprovado, Compartilhado, Pendente,
Pendente aprovação do CTP+GP, Recall, Rejeitado
```

**Isto é um sinal relevante:** apesar do rótulo parecido ("backoffice"), o conjunto de
valores de `Novo_DSA__c.Status_backoffice__c` não é sobre "status de logística" no sentido
de rastrear entrega/despacho — é sobre aprovação/qualificação do DSA. O campo de
`DSA__c` (5 valores: aguardando comercial → aguardando GP → aguardando faturamento → em
andamento → finalizado) se parece muito mais com um fluxo de **logística/operação** de
verdade. **Isso pesa a favor de `DSA__c` ser o objeto certo**, mas não é confirmação —
é leitura do nome e dos valores, registrada aqui para o arquiteto decidir com o humano.

## 3. Automação ativa em `DSA__c` — nenhuma toca o campo de logística

```
SELECT ApiName, ProcessType, TriggerType, TriggerObjectOrEventLabel, RecordTriggerType, IsActive
FROM FlowDefinitionView WHERE TriggerObjectOrEventLabel = 'DSA' AND IsActive = true
```

5 Flows `AutoLaunchedFlow`/`RecordAfterSave` ativos no objeto:

| Flow | RecordTriggerType |
|---|---|
| `Atualiza_DSA_com_informacoes_da_PFV` | CreateAndUpdate |
| `Atualiza_DSAs_com_Status_de_Aprovacao_e_Etapas` | CreateAndUpdate |
| `DSA_Cancelado` | CreateAndUpdate |
| `DSA_Recall` | CreateAndUpdate |
| `Notifica_se_DSA_Aprovada_por_Operacoes` | Update |

Os 5 foram retrieved (via projeto DX temporário em `/tmp`, removido ao final — nada gravado
em `force-app/` deste repositório) e lidos por completo:

- **Nenhum dos 5 referencia `Status_Backoffice__c`** (zero ocorrências em busca textual no
  XML de cada um).
- **4 dos 5 referenciam `Status_DSA__c`** (o outro campo de status, não o de logística) —
  confirma que a automação pesada do objeto gira em torno do fluxo de aprovação
  (`Status_DSA__c`), não do campo alvo desta demanda.

**Conclusão para o design:** uma carga em massa em `Status_Backoffice__c` hoje **não dispara
nem é lida por nenhuma automação ativa conhecida**. Risco de side-effect inesperado por
automação existente: **baixo**, na medida do que este recon alcançou (ver §7 — Validation
Rules não foram lidas campo a campo, só a lista de nomes/estado).

`Novo_DSA__c` não tem nenhum Flow nem Validation Rule ativos hoje (`SELECT ... WHERE
TriggerObjectOrEventLabel = 'Novo DSA' AND IsActive=true` → 0 registros; idem para
`ValidationRule` do objeto) — objeto com automação muito mais enxuta que `DSA__c`.

## 4. Validation Rules em `DSA__c` — 38 no total, a maioria inativa

```
SELECT ValidationName, Active, EntityDefinition.QualifiedApiName FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName = 'DSA__c'
```

38 Validation Rules cadastradas, **7 ativas**: `Motivo_Processamento_Urgente`,
`Proces_Urgente_em_DSA_nao_desmarcar`, `Valida_Opp_Ganha_Parceiro`, `Checa_Multiano_e_Prazo`,
`Checa_FCP_F5_e_Prazo`, `Oportunidade_e_psl_obrigatorios` (6 nomeadas aqui, mais uma — ver
nota). Nenhum nome sugere relação com `Status_Backoffice__c`/logística pelos nomes; **não
li a fórmula das 7** nesta etapa (ficou para o arquiteto, se a opção de design envolver
mudar o valor do campo por fluxo que dispara validação, e não só update direto).

**Achado colateral, fora do escopo desta demanda mas relevante para contexto:** `DSA__c` é
um objeto com perfil de automação parecido com o que o `assessment.md` já sinalizou para
"Oportunidade" (achado #1: muita automação concentrada) — 38 Validation Rules (31 inativas)
e 5 Flows ativos. Reforça o achado 8 do assessment ("regra desativada, não removida") em
mais um objeto.

## 5. Record Types e Layout de `DSA__c`

- **16 Record Types**, só **1 ativo**: `DSA Unico`. Os outros 15 estão inativos (nomes
  indicam modelos antigos de contrato/suporte — `Comissionamento`, `MS/MSS com Produto`,
  `Parcela Avulsa de Suporte`, etc.).
- **1 layout de página principal**: `DSA__c-Layout de DSA` (fora os ~15 layouts de página
  de aprovação, que são telas do processo de aprovação, não o layout de edição do registro).
  `Status_Backoffice__c` está nele, seção com os outros campos de acompanhamento de entrega
  (`Data_Efetiva_de_Chegada_na_Agility__c`, `Observacao_chegada__c`, ...).

Com Record Type único ativo, não há segregação de layout a resolver — mesma situação que o
recon do ACXYA-1 encontrou em Lead.

## 6. FLS (Field-Level Security) atual de `Status_Backoffice__c`

```
SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions
WHERE Field = 'DSA__c.Status_Backoffice__c'
```

34 perfis têm pelo menos leitura. Dos que têm **edição** hoje: `Admin`, `Administração`,
`Compras Financeiro`, `Financeiro Agility`, `PMO`, `Sales Operations`, `Renovações`,
`Contratos Agility`, `Sales Operations ADM`, `adminPMO`, `Administrador do sistema`,
`Administração para Alta Gestão`, `Grupo Operações`, `Alta Gestão`, `Estagiário Comercial`
(mais 1 perfil sem nome resolvido pela API — provável perfil removido/órfão) — 15 ao todo.
O restante (`Diretor Comercial`, `Gerente de Projetos`, `Service Delivery`, etc.) só lê.

Esse padrão de FLS é consistente com um campo operacional de backoffice/financeiro —
nenhum perfil comercial "de ponta" (ex.: vendedor) edita, o que é esperado para um campo de
controle logístico interno. Não encontrei nada que sugira que o padrão de FLS precise mudar
para esta demanda — mas isso depende de quem vai rodar a carga em massa ter um desses
perfis (ou Admin via carga direta).

`Novo_DSA__c.Status_backoffice__c` tem FLS bem mais restrita (7 perfis, todos com edição):
`Gerente Comercial Sul`, `Customer Success Squad`, `Renovações`, `PO DT`, `Marketing`,
`Gerente de RH`, `Gerente Comercial SP`. Nenhum perfil administrativo/financeiro aparece
explicitamente — pode ser porque o Admin tem acesso implícito não listado, não investiguei
mais fundo por não ser necessário para decidir entre os dois objetos.

## 7. Volume de dados

```
SELECT COUNT() FROM DSA__c       → 0
SELECT COUNT() FROM Novo_DSA__c  → 0
```

Sandbox de dev sem massa semeada em nenhum dos dois objetos — mesmo padrão documentado no
`assessment.md` para todos os objetos principais da org. Nenhum dado pessoal ou de negócio
trafegado nesta etapa (guardrail #2): só `COUNT()` e metadata.

**Impacto no design/QA:** igual ao recon do ACXYA-1 — não há como medir impacto retroativo
de uma carga em massa nesta sandbox porque não há registros. O roteiro de QA (etapa 5)
precisará criar massa fictícia própria.

## 8. O que este recon NÃO resolve

1. **Qual objeto é o alvo real** — `DSA__c`, `Novo_DSA__c`, ou os dois. §2 dá um indício
   (valores do campo de `DSA__c` combinam melhor com "status de logística" que os de
   `Novo_DSA__c`), mas não é confirmação.
2. **Fonte e formato dos dados da carga em massa** — a planilha citada na demanda continua
   sem chegar a este repositório. Sem ela, não há como saber a chave de cruzamento (Id? Nº
   da Oportunidade? Nº do pedido/OV?) nem o volume real de registros a atualizar.
3. **Se os 5 valores atuais do picklist de `DSA__c` cobrem o que o consultor precisa**, ou
   se a demanda pede valor novo (o que mudaria de "carga de dados" para "metadata change
   pequena": adicionar valor a picklist existente).
4. **Fórmulas das 7 Validation Rules ativas de `DSA__c`** — não lidas nesta etapa; relevante
   só se o mecanismo de carga em massa (API em lote vs. Data Loader vs. edição manual)
   disparar alguma delas.
5. **Convenção de nomenclatura own do cliente** — `clients/somos-agility/CLAUDE.md` segue
   sem o briefing preenchido; nenhuma fonte adicional encontrada na org que supra isso além
   do padrão empírico (campos em português sem prefixo, igual ao que ACXYA já mostrou ser
   comum neste tipo de org).

## Comandos executados

```bash
sf org list
sf data query --query "SELECT Name, IsSandbox, OrganizationType, InstanceName FROM Organization" --target-org sbx-somos-agility-dev
sf sobject list --sobject custom --target-org sbx-somos-agility-dev
sf sobject describe --sobject DSA__c --target-org sbx-somos-agility-dev
sf sobject describe --sobject Novo_DSA__c --target-org sbx-somos-agility-dev
sf sobject describe --sobject Workflow_de_Valida_o_de_DSA__c --target-org sbx-somos-agility-dev
sf data query --query "SELECT COUNT() FROM DSA__c" --target-org sbx-somos-agility-dev
sf data query --query "SELECT COUNT() FROM Novo_DSA__c" --target-org sbx-somos-agility-dev
sf data query --query "SELECT Name, SobjectType, IsActive FROM RecordType WHERE SobjectType IN ('DSA__c','Novo_DSA__c')" --target-org sbx-somos-agility-dev
sf data query --use-tooling-api --query "SELECT Name, EntityDefinitionId FROM Layout" --target-org sbx-somos-agility-dev
sf data query --query "SELECT ApiName, ProcessType, TriggerType, TriggerObjectOrEventLabel, RecordTriggerType, IsActive FROM FlowDefinitionView WHERE TriggerObjectOrEventLabel IN ('DSA','Novo DSA') AND IsActive=true" --target-org sbx-somos-agility-dev
sf data query --use-tooling-api --query "SELECT ValidationName, Active, EntityDefinition.QualifiedApiName FROM ValidationRule WHERE EntityDefinition.QualifiedApiName IN ('DSA__c','Novo_DSA__c')" --target-org sbx-somos-agility-dev
sf data query --query "SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Field = 'DSA__c.Status_Backoffice__c'" --target-org sbx-somos-agility-dev
sf data query --query "SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Field = 'Novo_DSA__c.Status_backoffice__c'" --target-org sbx-somos-agility-dev

# Retrieve read-only via projeto DX temporário em /tmp/sa-dx (removido ao final desta
# etapa — este repositório não tem force-app/ para somos-agility ainda, e não é desta
# demanda criar um; nada foi commitado, nada ficou em disco fora do /tmp):
sf project retrieve start --metadata "Flow:Atualiza_DSAs_com_Status_de_Aprovacao_e_Etapas" "Flow:DSA_Cancelado" "Flow:DSA_Recall" "Flow:Atualiza_DSA_com_informacoes_da_PFV" "Flow:Notifica_se_DSA_Aprovada_por_Operacoes" --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "Layout:DSA__c-Layout de DSA" --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "Layout:Novo_DSA__c-Layout de Novo DSA" --target-org sbx-somos-agility-dev
```

**Nota de método:** nenhum comando escreveu em `DSA__c`/`Novo_DSA__c` nem em qualquer outro
objeto — recon é 100% leitura (describe, SOQL de metadata/contagem, retrieve). O projeto DX
usado para os `retrieve` ficou em `/tmp/sa-dx`, fora deste repositório, e não foi commitado.
