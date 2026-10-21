# 04 — Plano de build (etapa 4): SOMOSAGILITY-12

**Agente:** `builder-declarativo` · **Data:** 2026-10-21 · **Branch:** `feature/SOMOSAGILITY-12`
**Org:** `sbx-somos-agility-dev` (sandbox), Org Id `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0 — confirmada via
`sf org list` (`isSandbox: true`) antes de qualquer alteração. **Nenhum alias fora de
`sbx-somos-agility-dev` foi usado. Produção não foi tocada.**
**Base:** `03-design.md` aprovado em `gates.md` (gate `aguardando_gate_design`, Leonardo
Barbosa, 2026-10-21T02:14:27Z). Opção **(b)** da seção 4 do design foi adotada, conforme
instrução explícita desta etapa: criar `PS_JST_ClassificacaoDenominacao`.
**D-08 (texto da mensagem) e demais dúvidas:** respondidas em `comentarios-do-card.md`
(ver seção 7). Nenhuma delas muda a arquitetura aprovada no design — só preenche os
parâmetros que o próprio design deixou em aberto.

Nada foi implantado de verdade (`sf project deploy start`). Todos os comandos `sf` usados
foram `sf sobject describe` (metadata), `sf project retrieve start` (só leitura),
`sf data query` (só nomes de classe Apex, sem dado de cliente) e `sf project deploy
validate` (check-only). Nenhum SOQL retornou CPF, e-mail, telefone ou valor — só metadata e
nomes (guardrail #2).

---

## 1. Infra de projeto criada

Este é o primeiro build de metadata de `somos-agility`. Criado:

- `clients/somos-agility/sfdx-project.json` — mesmo formato de `clients/acxya/sfdx-project.json`,
  `name: "somos-agility"`, `sourceApiVersion: "68.0"` (API confirmada via `sf org list` para
  `sbx-somos-agility-dev`, que também é a mesma versão já carimbada pela CLI na própria
  sessão: `instanceApiVersion: "68.0"`).
- `clients/somos-agility/force-app/main/default/` — esqueleto source-format, só com os
  componentes desta demanda (ver inventário abaixo). Não trouxe o objeto inteiro
  `JOB_de_Solicitacao_de_Treinamentos__c` para o repo: um primeiro `retrieve` de
  `CustomObject:...` baixou todos os ~30 campos e list views do objeto só para eu confirmar
  nomes de API; descartei esse retrieve (`rm -rf`) depois de confirmar e mantive em disco
  só o que esta demanda cria/altera (`validationRules/`, `permissionsets/`, `layouts/`).
  Trazer o objeto inteiro para o PR misturaria metadata não relacionada à demanda com o
  que foi de fato decidido no gate.

## 2. Inventário de componentes criados/alterados

| # | Ação | Tipo | Caminho | Decisão do design que amarra |
|---|---|---|---|---|
| C-1 | Criado | `ValidationRule` | `force-app/main/default/objects/JOB_de_Solicitacao_de_Treinamentos__c/validationRules/JST_Classif_Denominacao_Obrigatorias.validationRule-meta.xml` | §3 do design: bloqueia save sem os dois campos, recorte por `CreatedDate`, `errorDisplayField` em branco. |
| C-2 | Criado | `PermissionSet` | `force-app/main/default/permissionsets/PS_JST_ClassificacaoDenominacao.permissionset-meta.xml` | §4 do design, opção **(b)** — instrução explícita desta etapa. FLS read+edit nos dois campos. |
| C-3 | Alterado | `Layout` | `force-app/main/default/layouts/JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos.layout-meta.xml` | §3 do design: inclui os dois campos, `behavior=Edit` (não `Required`). |
| — | Backup (não é metadata) | arquivo | `demandas/SOMOSAGILITY-12/layout-job-original-backup.xml` | Cópia do layout **antes** da edição, retirada da org nesta sessão — precedente ACXYA-1 §2.3. |
| — | Criado (infra) | config | `sfdx-project.json` | Primeiro build de metadata deste cliente (ver seção 1). |

Não foi criado: campo novo, Flow, Apex, mudança em processo de aprovação, mudança no
layout `...Treinamentos CEO` — tudo conforme a seção 7 do design ("o que NÃO será feito").
Não foi feita atribuição de `PS_JST_ClassificacaoDenominacao` a nenhum usuário (fora do
escopo, seção 7 do design e desta instrução).

---

## 3. Detalhe por componente

### 3.1 Confirmação de metadata antes de usar (guardrail #3)

Antes de escrever qualquer XML, confirmei via `sf sobject describe --sobject
JOB_de_Solicitacao_de_Treinamentos__c --target-org sbx-somos-agility-dev`:

| API name | Tipo retornado | Observação |
|---|---|---|
| `Classificacao_Gerencial__c` | `picklist`, length 255, `nillable: true` | Bate com `02-recon.md` |
| `Denomina_o_do_Treinamento__c` | `textarea`, length 5000, `nillable: true` | É LongTextArea — confirma o alerta R-05 do design |
| `Status_da_Qualifica_o__c` | `picklist`, length 255 | Confirmado, não usado na fórmula final (ver 3.2) |

Fiz também `sf project retrieve start --metadata "Layout:JOB_de_Solicitacao_de_Treinamentos__c-Layout
de JOB de Solicitação de Treinamentos"` para editar a partir do estado real da org, não de
suposição (seção 3.3).

### 3.2 `ValidationRule` `JST_Classif_Denominacao_Obrigatorias`

Fórmula final entregue (idêntica à hipótese do design, sem fallback — ver resultado do
teste de R-05 na seção 6):

```
AND(
  OR( ISNEW(), CreatedDate >= DATETIMEVALUE("2026-10-21 00:00:00") ),
  OR( ISBLANK( TEXT( Classificacao_Gerencial__c ) ),
      ISBLANK( Denomina_o_do_Treinamento__c ) )
)
```

- **Data de corte escolhida: `2026-10-21 00:00:00`** (data desta sessão de build). Critério:
  na ausência de uma data de go-live comunicada pelo consultor, usar a data em que o
  pacote foi efetivamente construído é o valor mais honesto disponível — qualquer `JOB`
  criado a partir de agora já nasce sob a nova regra, e nenhum `JOB` existente até este
  momento é tocado retroativamente (atende CA-06/H-D05). **É um literal na fórmula, não um
  ID hardcoded** — não fere a convenção `padrao-entrega`. **O humano do gate de PR pode e
  deve ajustar essa data** para a data real de deploy em produção antes do release, se ela
  for diferente da data deste build (ver seção 8, incerteza aberta).
- `active=true` desde o deploy — o design não condicionou isso a decisão humana adicional
  (diferente do precedente ACXYA-1, que tinha uma decisão B-2 pendente sobre isso; aqui
  não há equivalente em aberto).
- `errorDisplayField` **omitido** (não emitido o elemento), para erro no topo da página —
  são dois campos, igual decidido no design. Tentei inicialmente emitir
  `<errorDisplayField></errorDisplayField>` vazio; não precisei testar se isso seria aceito
  porque percebi que a forma correta de "nenhum campo de erro" é simplesmente omitir o
  elemento, e assim ficou — confirmado que o `deploy validate` aceitou sem erro de parsing.
- **Mensagem de erro: usei a resposta real do consultor a D-08** (`comentarios-do-card.md`:
  *"Favor preencher os campos antes de enviar para aprovação"*), não mais a provisória do
  design. É uma troca sem impacto técnico, como o próprio design já previa.
- `description` preenchida citando SOMOSAGILITY-12, dentro do limite de 255 caracteres
  (ver seção 6 — a primeira tentativa, mais longa, foi rejeitada pelo `deploy validate` e
  corrigida nesta sessão).

### 3.3 `PermissionSet` `PS_JST_ClassificacaoDenominacao`

Opção **(b)** da seção 4 do design, adotada por instrução explícita desta etapa. Conteúdo:

```xml
<fieldPermissions>
    <field>JOB_de_Solicitacao_de_Treinamentos__c.Classificacao_Gerencial__c</field>
    <readable>true</readable>
    <editable>true</editable>
</fieldPermissions>
<fieldPermissions>
    <field>JOB_de_Solicitacao_de_Treinamentos__c.Denomina_o_do_Treinamento__c</field>
    <readable>true</readable>
    <editable>true</editable>
</fieldPermissions>
```

Sem `objectPermissions` — os 13 perfis afetados (02-recon, seção 6) já têm create/edit no
objeto; só falta FLS nos dois campos novos no layout, que é exatamente o que este
permission set resolve. `hasActivationRequired=false` (não é um pacote licenciado).
**Nenhum usuário foi atribuído** — tarefa do admin do cliente (seção 7 do design), listada
como passo manual pós-deploy (seção 5 abaixo).

### 3.4 `Layout` `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos`

Antes de editar, fiz o retrieve do layout real da org (comando em 3.1) e copiei o
resultado, **sem alteração**, para
`demandas/SOMOSAGILITY-12/layout-job-original-backup.xml` — rollback, igual ao precedente
`ACXYA-1/04-plano-build.md` seção 2.3.

Inseri os dois campos na seção **"Dados Gerais"**, segunda coluna, logo após
`Centro_de_Custo__c` (último item hoje daquela coluna), ambos com `behavior=Edit`:

```xml
<layoutItems>
    <behavior>Edit</behavior>
    <field>Classificacao_Gerencial__c</field>
</layoutItems>
<layoutItems>
    <behavior>Edit</behavior>
    <field>Denomina_o_do_Treinamento__c</field>
</layoutItems>
```

**Por que essa posição:** a seção "Dados Gerais" é a primeira do layout e já reúne os
campos de cabeçalho do JOB (`Objetivo__c`, `Tentativa__c`, `Tipo_de_Local__c`,
`Justificativa__c`, `Centro_de_Custo__c`), todos obrigatórios no layout ou tratados como
dados de abertura do registro. Colocar os dois campos novos ali, e não nas seções de
Alunos ou Financeiro, segue o mesmo agrupamento temático já existente e deixa a coluna 2
balanceada (5 itens em cada coluna, antes 3 e 5). **O design deixou a posição exata para o
build decidir com o consultor** (seção 3 do design); não houve consultor disponível nesta
sessão — é a melhor decisão de UI disponível com a informação em mãos, e pode ser ajustada
em revisão de PR sem nenhum impacto técnico (não há regra de negócio amarrada à posição na
tela).

`behavior=Edit`, não `Required` — exatamente como o design exige (seção 1: Required no
layout bloquearia também edição de registros legados pela UI, contrariando CA-06/H-D05).

Diff funcional: **só adição** das duas `layoutItems` citadas acima. Nenhuma outra
`layoutSection`, `relatedList` ou `platformActionList` foi tocada.

---

## 4. Ordem de deploy

1. `PermissionSet` `PS_JST_ClassificacaoDenominacao` (FLS primeiro — pré-requisito lógico
   de R-01 do design: ninguém deve ficar impedido de salvar por falta de FLS no mesmo
   instante em que a validation rule entra em vigor).
2. `Layout` `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de
   Treinamentos` (os campos precisam estar visíveis/editáveis na tela antes da regra
   bloquear o save).
3. `ValidationRule` `JST_Classif_Denominacao_Obrigatorias` (ativa por último).

O `deploy validate` dos três juntos (seção 6) não exige essa ordem explícita — a API de
Metadata resolve as dependências dentro da mesma transação —, mas esta é a ordem lógica
registrada para quem montar o deploy real na etapa de release, e **os três devem ir no
mesmo pacote**, nunca a `ValidationRule` sozinha antes da FLS/layout (R-01 do design).

---

## 5. Rollback por componente

| Componente | Rollback | Observação |
|---|---|---|
| `ValidationRule` | Redeploy com `<active>false</active>` | Primeira alavanca se bloquear alguém incorretamente. Não apagar o componente. |
| `Layout` | Redeploy de `demandas/SOMOSAGILITY-12/layout-job-original-backup.xml` | Remove os dois campos da tela — volta ao estado anterior a esta demanda. |
| `PermissionSet` | Deletar a atribuição a qualquer usuário que a tenha recebido (passo manual — ver seção 6) e/ou não reatribuir mais; o componente em si pode ficar na org sem efeito se não houver atribuição ativa | Revoga a FLS extra sem apagar dado. |

---

## 6. Passos manuais pós-deploy (fora do escopo deste agente)

1. **Atribuir `PS_JST_ClassificacaoDenominacao`** aos usuários dos 13 perfis listados em
   `02-recon.md` seção 6 que criam/editam o JOB sem FLS de edição nos dois campos — tarefa
   do admin do cliente, não deste agente (seção 7 do design).
2. **Confirmar a data de corte da `ValidationRule`** (`2026-10-21`, seção 3.2) antes do
   deploy real — se o go-live em produção acontecer em outra data, o humano do gate de PR
   deve ajustar o literal na fórmula.
3. **Validar o posicionamento dos campos no layout** (seção 3.4) com o consultor/cliente —
   decisão de UI que não foi confirmada com um humano nesta sessão.
4. Verificar FLS efetiva na org depois do deploy real (modo de falha comum: "deploy
   passou, mas o campo continua invisível para o perfil").

---

## 7. O que o recon/comentários do card já resolveram, e o que ainda está aberto

| Item | Situação |
|---|---|
| D-01 (objeto) | Confirmado pelo consultor em `comentarios-do-card.md`: `JOB_de_Solicitacao_de_Treinamentos__c`. Bate com a inferência do recon. |
| D-03 (só na submissão?) | Consultor respondeu "só na submissão" — **mas essa resposta chegou depois do design já ter fechado H-D03 (obrigatório desde o primeiro save) como a única opção declarativa viável sem mudança de modelo de dados** (seção 1 do design, "por que não alterar o critério de entrada do processo de aprovação"). Este agente **não reabriu essa decisão de negócio** — ela já estava decidida e aprovada no gate do design, e a instrução desta etapa foi explícita: não reabrir decisões já tomadas em `03-design.md`. Reporto a divergência aqui para o humano avaliar: a resposta do consultor ("só na submissão") e a solução entregue (bloqueia desde a criação) não são a mesma coisa. Se isso for inaceitável, a decisão sobe para o arquiteto, como o próprio design já previa na seção 6. |
| D-05 (legado) | Consultor respondeu "ficam como estão" — bate com H-D05 e CA-06, já implementado via recorte por `CreatedDate`. |
| D-07 (quem vê a mensagem) | Consultor respondeu "todos verão em tela" — bate com o comportamento padrão de validation rule (mensagem na UI para qualquer usuário que tentar salvar). |
| D-08 (texto da mensagem) | Respondida: *"Favor preencher os campos antes de enviar para aprovação"*. Usada literalmente em `errorMessage` (seção 3.2). |
| D-06 (usuário sem permissão) | Não respondida diretamente nos comentários; o design já tinha H-D06 (dar FLS via C-2) como a solução adotada, que é o que foi construído. |

**Atenção para o gate de PR:** a linha D-03 acima é a única divergência material entre o
que o consultor respondeu e o que o design (já aprovado) determinou. Não é um erro deste
build — é um artefato de sequência (a resposta do consultor registrada em
`comentarios-do-card.md` tem timestamp 2026-10-20 12:51, mas o design que fechou H-D03 foi
aprovado depois, em 2026-10-21, já considerando essa resposta como "sem resposta técnica
neutra" — ver seção 2 do design). Estou reportando, não decidindo.

---

## 8. Validação (check-only) — resultado literal

### 8.1 Teste do risco R-05 (ISBLANK em LongTextArea)

Primeira tentativa de `deploy validate` com `--test-level RunLocalTests` **falhou**, mas
por motivo não relacionado a R-05: a org tem 19% de cobertura média de testes Apex
(abaixo dos 75% exigidos para `RunLocalTests`/`RunAllTestsInOrg`), e vários testes e
triggers legados do cliente falham/têm 0% de cobertura — dívida técnica preexistente,
nada deste pacote. `deploy validate` exige um `--test-level` que rode pelo menos um
teste (não há `NoTestRun` nessa versão da CLI para validate); usei
`--test-level RunSpecifiedTests --tests ChangePasswordControllerTest` (classe já presente
na org, sem relação com esta demanda, só para satisfazer a exigência de teste) para isolar
a avaliação aos três componentes desta demanda.

Comando final:

```
sf project deploy validate \
  --metadata "ValidationRule:JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias" \
  --metadata "PermissionSet:PS_JST_ClassificacaoDenominacao" \
  --metadata "Layout:JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos" \
  --target-org sbx-somos-agility-dev --test-level RunSpecifiedTests --tests ChangePasswordControllerTest
```

**Resultado literal: `Succeeded`.**

```
status: Succeeded
success: true
numberComponentErrors: 0
numberComponentsDeployed: 3
numberComponentsTotal: 3
numberTestsCompleted: 1
numberTestErrors: 0
numberTestsTotal: 1
rollbackOnError: true
deployId: 0AfHa00000Dzj8nKAB
```

Componentes reportados (`componentSuccesses`):

| fullName | type | created/changed |
|---|---|---|
| `JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias` | ValidationRule | Created |
| `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos` | Layout | Changed |
| `PS_JST_ClassificacaoDenominacao` | PermissionSet | Created |

1 teste executado (`ChangePasswordControllerTest.testChangePasswordController`), 0
falhas.

**Conclusão sobre R-05:** `ISBLANK(TEXT(Classificacao_Gerencial__c))` e
`ISBLANK(Denomina_o_do_Treinamento__c)` (LongTextArea) **foram aceitos pelo `deploy
validate` sem erro** — não foi necessário o fallback `LEN(...) = 0` previsto no design.
Nenhum desvio em relação à fórmula proposta na seção 3 do design.

### 8.2 Erros de descrição corrigidos durante o build (não são desvio de design)

Duas tentativas anteriores falharam por **limite de 255 caracteres** em `<description>`,
tanto da `ValidationRule` quanto do `PermissionSet` — os textos iniciais, mais longos (para
documentar bem o racional), excediam o limite da plataforma. Corrigidos para versões mais
enxutas, mantendo a citação de SOMOSAGILITY-12 e o essencial do racional. Sem impacto
funcional — é limite de schema, não decisão de negócio.

---

## 9. Incertezas/desvios para o humano do gate de PR decidir

| # | Item | Natureza |
|---|---|---|
| 1 | Data de corte da `ValidationRule` (`2026-10-21`, data desta sessão de build) pode não ser a data real do go-live em produção — ajustar antes do deploy real. | Decisão operacional, não técnica. |
| 2 | Posicionamento dos dois campos no layout (seção "Dados Gerais", coluna 2, após `Centro_de_Custo__c`) foi escolhido sem consultor disponível nesta sessão. | Decisão de UI, reversível sem custo técnico. |
| 3 | **D-03 reportado na seção 7:** a resposta do consultor ("só na submissão") não é o que foi construído (obrigatório desde a criação, H-D03). A decisão de negócio já estava fechada no design aprovado; não reabri. | Potencial divergência entre o que o consultor pediu e o que o design (já aprovado) decidiu — precisa de decisão humana, possivelmente escalada ao arquiteto (seção 6 do design já previa esse caminho). |
| 4 | `errorDisplayField` foi **omitido** (elemento ausente) em vez de emitido vazio — forma que o `deploy validate` aceitou. | Confirmação técnica, não decisão. |

---

## 10. O que este agente NÃO fez

- Nenhum deploy real (`sf project deploy start`) foi executado — só `retrieve` (leitura) e
  `deploy validate` (check-only).
- Nenhuma atribuição de `PS_JST_ClassificacaoDenominacao` a usuário algum — tarefa do
  admin do cliente, fora do escopo (seção 7 do design).
- Nada em produção — produção não está configurada nesta máquina e não foi tocada.
- `status.yaml` não foi alterado por este agente.
- `gates.md` não foi escrito por este agente — é mecânico, de outra ferramenta.
- Nenhuma decisão de negócio do design aprovado foi reaberta ou alterada (ver divergência
  reportada, não decidida, na seção 7/9).
- Nenhum SOQL retornou dado de cliente — só `sf sobject describe`, metadata e nomes de
  classe Apex (guardrail #2).
- O conteúdo do anexo do card (e-mail da consultoria) não foi reproduzido em nenhum
  artefato — nem nomes, nem contato, conforme instrução desta etapa.

---

Build pronto para PR. Próximo passo: abrir PR contra `main`, anexar
`layout-job-original-backup.xml`, e aguardar `ci-salesforce-validate.yml` + revisor
humano. Este agente não faz commit, push nem merge.
