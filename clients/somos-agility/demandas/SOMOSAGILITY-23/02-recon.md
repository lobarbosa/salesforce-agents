# SOMOSAGILITY-23 — Recon da org (org-recon)

**Cliente:** somos-agility
**Org consultada:** `sbx-somos-agility-dev` (sandbox, `isSandbox: true` confirmado via `sf org list`;
instância `agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0)
**Data da coleta:** 2026-10-21
**Fontes:** `sf sobject describe`, `sf project retrieve start` (ValidationRule, Flow, ApexTrigger,
Layout), `sf data query` (Tooling API para ValidationRule e ProcessDefinition; REST API só com
`COUNT()` e campos não sensíveis, nunca dado de registro).

---

## 1. Objeto e campo

`Realizacao_Financeira_de_Venda__c` ("Realização Financeira de Venda") existe na org, com um
único Record Type (`Mestre`, master).

O campo citado na demanda, "Renovação Realizado", é `Renova_o__c`:

| Propriedade | Valor |
|---|---|
| Tipo | `currency` |
| Precisão / escala | 18 / 2 (cabe o valor informado em `demanda.md`, que não chega perto do limite) |
| `calculated` | `false` — **não é campo fórmula** |
| `createable` / `updateable` | `true` / `true` |
| `nillable` | `true` (não é obrigatório) |
| Comportamento no layout `Realizacao_Financeira_de_Venda__c-Layout de Realização Financeira de Venda` | `Edit` (campo editável na tela, não é read-only nem oculto) |

Nada na definição do próprio campo explica um erro de validação ao salvar.

## 2. Automação no objeto

- **Validation Rules:** nenhuma no objeto (confirmado por dois caminhos — retrieve de metadata
  `ValidationRule` trouxe zero arquivos, e a query Tooling
  `SELECT ValidationName FROM ValidationRule WHERE EntityDefinition.QualifiedApiName =
  'Realizacao_Financeira_de_Venda__c'` retornou zero linhas).
- **Flow:** um único Flow referencia o objeto diretamente —
  `Preenche_recorrente_ajustado_realizado` (migrado de workflow rule antigo,
  `RecordAfterSave`, `CreateAndUpdate`). O filtro de entrada é
  `OR(ISNEW(), ISCHANGED(RecorrenteNominalNetRealizado__c), ISCHANGED(prazoContrato__c),
  ISCHANGED(tipoPagamento__c))` — **não** inclui `Renova_o__c` nem é disparado só por ele mudar.
  Editar isoladamente "Renovação Realizado" não deveria acionar este Flow.
- **Apex (trigger/classe):** nenhum trigger Apex do objeto encontrado entre os triggers da org
  (busca por nome e por referência ao objeto/campo nas classes já retrievadas). Não há evidência
  de automação em código no objeto.
- **Approval Process:** nenhum processo de aprovação ativo no objeto
  (`ProcessDefinition WHERE TableEnumOrId = 'Realizacao_Financeira_de_Venda__c'` → zero linhas).

## 3. Permissão de campo

Dois Permission Sets concedem `editable: true` + `readable: true` para
`Realizacao_Financeira_de_Venda__c.Renova_o__c`: `Acesso_completo_Esteira_de_vendas_e_renovacoes`
e `DiretorComercial`. Não foi possível (nem é objetivo do recon) confirmar qual permission set o
usuário que reportou o erro tem atribuído — isso exigiria olhar atribuição de um usuário
específico, fora do escopo de metadata/contagem agregada deste recon.

## 4. Volume de dados nesta sandbox

`SELECT COUNT() FROM Realizacao_Financeira_de_Venda__c` → **0 registros** em
`sbx-somos-agility-dev`. Tentativa de localizar o registro citado na demanda
(`a6UU40000000Ue1MAE`) não encontrou nada — compatível com o COUNT() zerado, e esperado: a URL em
`demanda.md` aponta para o domínio `agilitynetworks.lightning.force.com`, que é **produção**, não
esta sandbox. O Id de um registro de produção não existe (nem faria sentido existir) numa org de
sandbox diferente.

## 5. O que isso significa para o design

- **Não há nada na metadata hoje, nesta sandbox, que explique o erro** ao editar
  "Renovação Realizado": sem validation rule, sem Flow que dispare só por esse campo, sem Apex,
  sem approval process, campo não é fórmula, é editável no layout e tem permission sets que dão
  acesso de escrita.
- **O bug não é reprodutível nesta sandbox como está**, porque o registro do incidente é de
  produção e esta sandbox não tem nenhum registro do objeto. Confirma a lacuna P2 da análise
  (`01-analise.md`): o registro está em produção.
- A mensagem de erro exata (P1 da análise) continua **sem confirmação** — nem `demanda.md`, nem
  `comentarios-do-card.md`, nem o anexo em PDF (que é a captura de tela da URL, sem texto do erro
  extraído) trazem o texto. Sem ela, e sem conseguir reproduzir em sandbox, a causa raiz segue uma
  hipótese, não um fato confirmado.
- Se a causa fosse uma das verificadas acima (regra, Flow, Apex, aprovação), o recon teria achado
  o componente. Como não achou, as explicações que sobram apontam mais para **dado/estado do
  registro específico em produção** (ex.: um valor fora de faixa esperada por regra de negócio não
  codificada em metadata, um processo externo, ou algo que só existe no dado daquele lançamento) do
  que para algo que o agente possa corrigir via metadata declarativa ou Apex em sandbox.

## 6. Comandos executados (para auditoria)

```
sf org list
sf sobject describe --sobject Realizacao_Financeira_de_Venda__c --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "ValidationRule" --target-org sbx-somos-agility-dev
sf data query --query "SELECT ValidationName, Active, ErrorDisplayField, ErrorMessage FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'Realizacao_Financeira_de_Venda__c'" --use-tooling-api --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "Flow" --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "ApexTrigger" --target-org sbx-somos-agility-dev
sf data query --query "SELECT Name, TableEnumOrId, State FROM ProcessDefinition WHERE TableEnumOrId = 'Realizacao_Financeira_de_Venda__c'"
sf org list metadata --metadata-type Layout --target-org sbx-somos-agility-dev
sf project retrieve start --metadata "Layout:Realizacao_Financeira_de_Venda__c-Layout de Realização Financeira de Venda" --target-org sbx-somos-agility-dev
sf data query --query "SELECT COUNT() FROM Realizacao_Financeira_de_Venda__c" --target-org sbx-somos-agility-dev
```

Nenhuma query retornou CPF, e-mail, telefone ou valor de registro de cliente — só contagens,
metadata e nomes de componentes (guardrail #2).
