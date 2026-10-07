# Recon ACXYA-2: objeto Lead

**Data da coleta:** 2026-09-14
**Org:** `sbx-acxya-dev` (sandbox, `acxya--sbxacxya.sandbox.my.salesforce.com`, API v67.0) —
confirmado via `sf org list` / `sf org display` antes de qualquer comando. É a única org
conectada nesta sessão; `sbx-acxya-qa` ainda não existe (registrado no `CLAUDE.md` do
cliente).

## Campos já existentes no objeto Lead

`sf sobject describe --sobject Lead` retorna 80 campos, 30 custom. Nenhum campo hoje
armazena "descobertas de reunião" — não há conflito de nome nem de propósito direto.
Custom fields existentes (lista completa, para referência de nomenclatura e de eventual
sobreposição funcional):

```
Capital_Social__c (currency)         AE_do_Parceiro__c (string)
Tecnologia_proposta__c (picklist)    sfLma__Subscriber_Org_Type__c (string)
et4ae5__HasOptedOutOfMobile__c (boolean)
et4ae5__Mobile_Country_Code__c (picklist)
CNAE__c (string)                     CNPJ__c (double)
Qualified_Lead__c (boolean)          Numero_de_Funcionarios__c (picklist)
Numero_de_Agentes__c (double)        Status_Atividades__c (picklist)
Canais_de_Atendimento__c (picklist)  Need_Contexto__c (string)
Ferramenta_que_utilizam_hoje__c (string)
Volume_de_Dados__c (string)          Possui_Fluxo_de_Atendimento__c (string)
Timeline__c (picklist)               Budget__c (picklist)
Authority__c (picklist)              Competitors__c (string)
Cargo__c (string)                    Atividades_Pendentes__c (boolean)
Quantidade_de_Atividades_Pendentes__c (double)
GCLID__c (string)                    Score_de_Engajamento__c (string)
WA_Chat__c (reference)               Touch_Count__c (double)
Last_Touch_Date__c (date)            Data_Aniversario__c (date)
```

**Atenção para o arquiteto (não é conflito, é sobreposição de propósito a avaliar):**
já existem `Need_Contexto__c`, `Timeline__c`, `Budget__c`, `Authority__c` — um conjunto de
qualificação estilo BANT provavelmente preenchido em reunião com o lead. A demanda pede
um campo novo e específico para "descobertas", que é mais livre/qualitativo que esses
campos estruturados. Vale o arquiteto decidir explicitamente se é campo novo (como a
demanda pede) ou se cabe em `Need_Contexto__c` — registrando a decisão, não assumindo.

Nenhum campo custom nem padrão usa nome parecido com "Descoberta", "Discovery",
"Insight", "Meeting" ou "Reunião" — busca por palavra-chave no describe não retornou nada.

## Nomenclatura

Confirmado com o `CLAUDE.md` do cliente: **sem prefixo** de origem (ex.:
`Data_Aniversario__c`, não `KTA_Data_Aniversario__c`). Os campos custom existentes seguem
`Palavra_Palavra__c` em português, capitalizado por palavra — convenção a repetir no
campo novo.

## Layout do Lead

Um único layout ativo: **`Lead Layout`** (`Layout:Lead-Lead Layout`, retrieve confirmado),
com as seções: Lead Information, Additional Information, Address Information, Description
Information, Informações fiscais, Informações de classificação, Marketing Cloud, System
Information, Custom Links. "Description Information" e "Additional Information" são as
candidatas mais óbvias para o campo novo — decisão final é do arquiteto/builder.

Há também uma Lightning Record Page dedicada ao Lead: `Lead_P_gina_de_registro`
(retrieve confirmado via `FlexiPage`), então o campo pode precisar ser adicionado tanto
no layout clássico quanto no componente de detalhes da record page, dependendo de qual
está realmente em uso pelos usuários de vendas.

## Automação existente no objeto Lead

`sf project retrieve start --metadata Flow` + busca por `<object>Lead</object>` no
`force-app` retrieve encontrou 8 Flows que tocam Lead. Dos que estão **Active** e
disparam em `RecordAfterSave` (os que importam para avaliar efeito colateral de um campo
novo):

| Flow | Trigger | Objeto(s) |
|---|---|---|
| `Count_de_Tasks_Pendentes` | RecordAfterSave | Lead, Task |
| `Lead_AfterSave_MapeiaAniversarioNaConversao` | RecordAfterSave | Lead, Contact |
| `Leads_do_Marketing_Cloud` | RecordAfterSave | Lead |
| `Update_Atividades_Pendentes` | RecordAfterSave | Lead, Task |

Os demais Flows que tocam Lead (`Atualiza_Lead_Atividade_Status`,
`Lead_Criacao_de_Tarefas`, `Lead_Qualification_Custom_Flow`, `JBSystemFlow_Lead`) estão
com `<status>Obsolete</status>` — não rodam hoje.

Nenhum dos Flows ativos referencia campos de qualificação/texto livre em suas condições
de entrada (todos operam sobre atividades/tarefas ou mapeamento de aniversário/Marketing
Cloud) — um campo novo de texto isolado não deve entrar no caminho de nenhum deles, mas
não abri o detalhe de cada elemento node a node; se o arquiteto quiser blindar 100%, vale
reler as condições de entrada antes do build.

## Validation Rules no Lead

Via Tooling API (`SELECT ... FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Lead'`):

| Nome | Ativa |
|---|---|
| `Validacao_de_Telefone` | não |
| `Validacao_de_Campos` | não |
| `Valida_Lead_Atividades_Pendentes` | não |
| `Lead_status_MQL` | não |
| `Valida_Data_Aniversario_Nao_Futura` | **sim** |

Só uma ativa, e não referencia o campo novo nem nada relacionado a texto livre —
nenhum risco de conflito identificado para uma inclusão de campo simples.

## Volume e acesso

- `SELECT COUNT() FROM Lead` → **0 registros** nesta sandbox (org de dev vazia; sem dado
  real, sem risco de LGPD nessa consulta — só contagem, conforme guardrail #2).
- 25 Profiles e 94 Permission Sets cadastrados na org — volume normal para uma org deste
  porte; FLS específico do campo novo (quem vê/edita) fica para a etapa de build, a
  decidir pelo arquiteto/builder conforme a lacuna "Visibilidade" ainda aberta em
  `01-analise.md`.

## Conclusão do recon

Nenhum bloqueio técnico encontrado para criar um campo novo em Lead: sem conflito de
nome, sem Flow ativo que dependa da ausência do campo, sem Validation Rule ativa que
possa colidir. As decisões em aberto (tipo de campo, se reaproveita `Need_Contexto__c`
ou não, layout(s) alvo, FLS) ficam para `03-design.md`.
