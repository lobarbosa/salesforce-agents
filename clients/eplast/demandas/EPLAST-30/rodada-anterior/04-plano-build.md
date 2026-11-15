# EPLAST-30 · Plano de build — Apoio a propostas, follow-ups e argumentos comerciais

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** build · **Autor:** builder-declarativo
**Org:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, confirmado via `sf org display` antes de tocar em qualquer coisa)
**Entradas:** `01-analise.md` (gate 2026-11-11), `02-recon.md` (2026-11-11, válido até 2026-11-18), `03-design.md` (gate 2026-11-11, Carlos Sordi), `comentarios-do-card.md`, `gates.md`, `assessment.md`.

---

## 0. Pendência contratual — LEIA ANTES DE APROVAR ESTE GATE

A Onda 3 (Comercial) **ainda não está formalmente contratada** no projeto atual (Ondas 1–2).
O `contrato.md` confirma isso hoje. Isso foi sinalizado na análise (seção 0), repetido no
design (seção 0.1 — "bloqueante para o build") e **mesmo assim o humano que aprovou o gate de
design (Carlos Sordi, 2026-11-11T22:18:34Z) avançou o status para `build`** com esse texto na
mesa — o hash em `gates.md` prova que ele aprovou exatamente aquele documento. Esta sessão
trata isso como a aprovação explícita exigida pela regra de ouro para a etapa de build e
**não reabre essa decisão de negócio**. Quem revisa este PR precisa ver este ponto de novo:
antes de liberar o gate de build (`aguardando_gate_build`), confirme que existe aditivo ou
autorização por escrito para a Onda 3, ou que esta demanda deveria voltar para backlog como
antecipação de escopo.

---

## 1. Resultado desta sessão, em uma frase

**O build não fechou.** A arquitetura aprovada (seção 2 do design) tem uma peça que não
funciona como o design assumiu, confirmado por deploy real repetido contra `sbx-eplast-dev`
(não é suposição): um Flex `GenAiPromptTemplate` não consegue usar um `Flow` (`PromptFlow`)
customizado como fonte de grounding nesta org/release, porque o próprio tipo `PromptFlow`
**recusa** o único mecanismo de "variável de saída" que a vinculação Flex↔Flow parece exigir.
Isso é exatamente o que a seção 2.4 do design previu como gatilho de parada ("Se 1 ou 2
falhar, o build para e volta ao design"), e por isso este plano registra o achado, o que foi
e não foi deployado de verdade, e devolve a decisão ao arquiteto humano — não troquei a
arquitetura aprovada por conta própria.

Todo o resto do design (zero DML, zero Apex, zero LWC, zero Named Credential, FlexiPage em
aba própria, permissionamento por PSG) foi implementado e, onde não dependia da peça
quebrada, **foi deployado de verdade** em `sbx-eplast-dev` (seção 4).

---

## 2. O que foi verificado antes de construir (guardrail #3 — não inventar metadata)

Método: **nenhum XML foi escrito sem antes confirmar o pedaço de plataforma correspondente**,
via `sf` CLI contra `sbx-eplast-dev` (consultas e deploys `--dry-run`, nunca dado de negócio) ou
via os arquivos de schema/templates que acompanham o próprio `sf` CLI instalado no runner
(`@salesforce/types`, pacote oficial com a definição TypeScript dos tipos de metadata, e
`@salesforce/templates`, que inclui um `GenAiPromptTemplate` de exemplo real da Salesforce).
Nenhuma dessas fontes é "inventar" — são a definição oficial da metadata ou um teste real
contra a org.

| O que | Como confirmei | Resultado |
|---|---|---|
| Org correta, é sandbox | `sf org display --target-org sbx-eplast-dev` | Org Id `00DHa000006vfMLMAY`, bate com o recon |
| `Opportunity_Record_Page` é a página ativa da Opportunity (R12 do design) | Retrieve ao vivo de `CustomObject:Opportunity` (`actionOverrides`, `actionName=View`, `type=Flexipage`, sem `profile`/`recordType` — vale para todo mundo) | Confirmado: só `Opportunity_Record_Page`, para Small e Large. `Opportunity_Record_Page_Three_Column` não é usada. Não toquei nela |
| `GenAiPromptTemplate` existe como tipo de metadata nesta org/API | `sf org list metadata --metadata-type GenAiPromptTemplate` (retornou vazio, sem erro) | Tipo válido, 0 existentes — bate com o recon |
| `PromptFlow` é um `ProcessType` de Flow válido nesta org | `sf data query` em `FlowDefinitionView` (já tinha 5 gerenciados) | Confirmado, consistente com o recon |
| Sintaxe de um Flex `GenAiPromptTemplate` (`type`, `inputs`, `templateDataProviders`, `status`, `versionIdentifier`) | Arquivo de exemplo real `Get_Event_Info.genAiPromptTemplate-meta.xml`, empacotado dentro de `@salesforce/templates` (dependência do próprio `sf` CLI instalado) | Usei como base; validei contra a org via deploy (seção 3) |
| `generatePromptResponse` é um `actionType` de `actionCalls` de Flow válido (ação "Prompt Template" dentro de um Screen Flow) | `ResponseFormatInvocableActionType`/`InvocableActionType` em `@salesforce/types` (schema oficial do Metadata API) | Confirmado por schema; aceito pelo deploy real (Screen Flow deployou sem erro nessa parte) |
| Sintaxe de `flowruntime:interview` numa FlexiPage (como embutir um Screen Flow numa aba) | O próprio `Opportunity_Record_Page.flexipage-meta.xml` já tem um (`PaymentTermsOpportunity`) | Copiei o padrão exato já usado nesta org |
| Sintaxe de `visibilityRule` por custom permission numa FlexiPage | Regras existentes na mesma FlexiPage (`$User.Profile.Name`, operadores `NE`/`EQUAL`/`GT`) | **`EQ` não existe** nesta org — o operador certo é `EQUAL` (descoberto por erro de deploy real, corrigido) |
| `force__EinsteinGPTPromptTemplateUser` é o fullName certo do permission set padrão de Prompt Templates | `sf data query` em `PermissionSet` (`NamespacePrefix = force`) + já usado em `force__SalesUsers.permissionsetgroup-meta.xml` existente | Confirmado |
| Campos usados na allowlist (3.4 do design) em Opportunity/Account/SBQQ\_\_Quote\_\_c/SBQQ\_\_QuoteLine\_\_c | `02-recon.md` (coletado há poucas horas, dentro da validade) | Reconfirmado, sem re-rodar `sobject describe` porque o recon está fresco |
| Nomes de relacionamento (`SBQQ__Product__r`, `Account`) | `sf sobject describe --sobject SBQQ__QuoteLine__c` | `SBQQ__Product__c` → relationshipName `SBQQ__Product__r` |

Em vários pontos o comportamento real da plataforma **divergiu** do que a sintaxe "parece"
dizer (seção 3). Onde isso aconteceu, seguí o erro do deploy, não minha suposição.

---

## 3. A cadeia de achados técnicos, em ordem (todos com deploy real, não suposição)

### 3.1 `sobject://Opportunity` como input direto do Flex template — quebra o servidor

O design (seção 2.1) assumia: "grounding: merge fields padrão de Opportunity e Account
(lidos pela plataforma, no contexto do usuário)" — ou seja, o Flex template receberia a
`Opportunity` inteira como input (`definition: sobject://Opportunity`) e resolveria
`Account.Name` etc. automaticamente.

**Isso não funciona nesta org.** Deploy de um `GenAiPromptTemplate` com um input
`sobject://Opportunity` (ou `sobject://Account`, testado para isolar) falha com:

```
Cannot invoke "einstein.gpt.shared.provider.definition.GenAiPromptTypeEnum.getPath()"
because the return value of "einstein.gpt.shared.provider.definition.GenAiPromptDefType.getType()" is null
```

Isto é um erro de servidor (NullPointerException do lado da Salesforce), não um erro de
sintaxe — reproduzido de forma isolada e repetida, inclusive com o `activeVersionIdentifier`
no formato correto (hash) e sem nenhuma outra variável envolvida. Comparado lado a lado: o
mesmo template com **só** um input `primitive://String` (sem `sobject://`) deploya normalmente.

**Decisão tomada (dentro da mesma arquitetura aprovada, não é opção B/C):** em vez de passar
a Opportunity inteira, o Screen Flow passa só o **Id** (`primitive://String`, input
`OpportunityId`) e um **segundo** Flow de grounding (`Opportunity_PromptFlow_DadosOportunidade`,
novo, não estava no design) busca os campos de Opportunity/Account e devolve texto formatado —
exatamente o mesmo mecanismo que já valeria para a cotação CPQ. Continua Prompt Builder +
Flex + Screen Flow + Flow, zero Apex/LWC/Named Credential — só muda **como** o dado chega ao
template, não a decisão de arquitetura.

### 3.2 `PromptFlow` não aceita `triggerType` nulo nem `None`

Erro: `Fluxos do tipo PromptFlow não podem ter o tipo de acionamento None` (e o mesmo para
`null`, `OnDemandNoTrigger`, `BroadcastNoTrigger`, `RecordQuery`, `List`). Testados em
sequência contra a org; **`Capability`** foi o único aceito. Usado nos dois Flows de
grounding.

### 3.3 Variável de saída custom (`isOutput=true`) é **rejeitada** em `PromptFlow`

Erro, reproduzido isoladamente várias vezes (inclusive num Flow mínimo de 1 variável):

```
A variável global $Prompt é a única variável de saída usada em um fluxo de aviso.
Remova todas as outras variáveis de saída.
```

Tentei então **escrever** em `$Prompt` diretamente (já que a mensagem sugere que é "a"
variável de saída): também falha —
`Esse fluxo não pode referenciar $Prompt porque seu tipo de fluxo é PromptFlow`.
As duas mensagens parecem se contradizer; na prática, **nenhum `PromptFlow` com `isOutput=true`
deploya**, ponto final. A correção, nos dois Flows de grounding: a variável de texto
(`TextoCotacao`, `TextoOportunidade`) ficou como **variável comum** (`isOutput=false`), e o
Flex template referencia pelo nome dela mesmo assim (`{!$Flow:NomeDoFlow.NomeDaVariavel}`) —
isso é exatamente o que o único exemplo oficial disponível (`Get_Event_Info`, com data
provider Apex) também faz: nenhuma variável lá é `isOutput=true`.

### 3.4 Campo de relacionamento dentro de `queriedFields` não é aceito — precisa de `relatedRecords`

Tentativa inicial: listar `SBQQ__Product__r.Name` ou `Account.Name` direto em `queriedFields`
de um `recordLookups`. Erro: `O campo "SBQQ__Product__r.Name" do objeto "..." não existe`
(mesmo existindo, confirmado por `sobject describe`). O Get Records de Flow **não aceita
notação de ponto** em `queriedFields` — precisa do sub-elemento `relatedRecords`
(`relationshipField` + `relatedObject` + `queriedFields` próprios), e **`relatedRecords` exige
`storeOutputAutomatically=true`** no elemento pai (outro erro de deploy real apontou isso:
"Para obter registros relacionados, selecione Armazenar todos os campos automaticamente").
E `relationshipField` é o **nome do relacionamento** (`SBQQ__Product__r`, `Account`), não o
nome do campo de lookup (`SBQQ__Product__c`, `AccountId`) — testei as duas formas, só a
primeira deploya.

### 3.5 `storeOutputAutomatically` + `relatedRecords` + **"primeiro registro"** quebra o servidor; em modo coleção funciona

Com `getFirstRecordOnly=true` (buscar 1 oportunidade por Id) **e** `relatedRecords` **e**
qualquer conector de saída (uma Assignment, uma Decision — testei os dois), o deploy falha com
um erro genérico de servidor (`An unexpected error occurred... ErrorId ...-582814444`),
reproduzido de forma isolada e repetida. Trocando só o `getFirstRecordOnly` para `false`
(modo coleção, ainda filtrado por Id único, então no máximo 1 resultado) com exatamente a
mesma configuração, **o deploy funciona**. A correção, no
`Opportunity_PromptFlow_DadosOportunidade`: a oportunidade é buscada em modo coleção
(`limit=2`, porque **o limite mínimo aceito é 2**, não 1 — outro erro de deploy real apontou
isso) e um Loop de no máximo 1 iteração "desembrulha" o registro — o mesmo padrão declarativo
que o `Opportunity_PromptFlow_CotacaoPrimaria` já usa para as linhas da cotação. Não é SOQL
dentro de loop (a query já aconteceu antes do loop, uma vez só); é só a forma de acessar o
único resultado.

### 3.6 Bloqueio não resolvido: vínculo Flex ↔ Flow custom como `templateDataProvider`

Com os dois Flows de grounding **deployados de verdade e confirmados existentes na org**
(`sf org list metadata --metadata-type Flow` os lista), o deploy dos 3 `GenAiPromptTemplate`
ainda falha, para os dois Flows, com:

```
O parâmetro de saída da ação Opportunity_PromptFlow_CotacaoPrimaria não corresponde.
O parâmetro de saída da ação Opportunity_PromptFlow_DadosOportunidade não corresponde.
```

Tentei (todas testadas, todas falharam ou pioraram o erro):
- Variável de saída declarada (`isOutput=true`) → o próprio Flow não deploya (3.3).
- Variável comum (`isOutput=false`), referenciada pelo nome → Flow deploya, mas o **template**
  reclama que o "parâmetro de saída" da ação não bate.
- Um segundo `<parameters>` dentro do `templateDataProviders`, sem `valueExpression`,
  tentando declarar explicitamente a saída → novo erro (`A expressão do valor é inválida: null`)
  **mais** o erro original — piorou, não existe essa sintaxe.

Não encontrei, nos materiais a que tenho acesso nesta sessão (schema oficial do `sf` CLI, um
único exemplo oficial com data provider **Apex**, os 5 `PromptFlow` já existentes na org — mas
**todos de pacote gerenciado, não retrieváveis**, então não dá para inspecionar a estrutura
real deles), a forma correta de declarar o "parâmetro de saída" que a validação do
`GenAiPromptTemplate` espera de um `templateDataProvider` do tipo `flow://`. **Não inventei
mais tentativas de tag depois disso** — continuar adivinhando XML que não consigo validar é
exatamente o que o guardrail #3 pede para não fazer.

**Isto é, na prática, a falha do item 2 da verificação obrigatória da seção 2.4 do design**
("Um Flex template aceita um PromptFlow como fonte de grounding"). A seção 2.4 do design é
explícita: *"Se 1 ou 2 falhar, o build para e volta ao design... essa troca é decisão do
arquiteto humano."* É isso que estou fazendo aqui — não troquei para a opção B (Agentforce)
por conta própria.

**Hipóteses não verificadas, para quem decidir os próximos passos:**
1. O recurso pode exigir criação pela **UI do Prompt Builder** (Setup), não por deploy direto
   de metadata — e a UI pode gerar uma estrutura de metadata diferente da que eu montei
   (o retrieve depois de criar pela UI revelaria o campo que falta). Esta sessão não tem
   acesso a navegador/UI (isso é ferramenta do agente `qa`, não deste).
2. Pode ser uma limitação real desta API version/release para data providers baseados em
   Flow **customizado** (os 5 existentes são todos de pacote gerenciado — não há prova de que
   um `flow://` customizado funcione nesta org hoje).
3. Trocar o data provider de `flow://` para `apex://` (como o único exemplo oficial realmente
   demonstra funcionando) resolveria, mas **reabre a decisão "zero Apex"** da seção 2 do design
   — não fiz essa troca sozinho.

---

## 4. Inventário real: o que está em `sbx-eplast-dev` agora vs. o que só existe no repositório

Status conferido com `sf org list metadata` depois de cada deploy (não assumido pelo texto de
retorno do comando, porque descobri que um `deploy start` com **qualquer** componente
reprovado faz **rollback da transação inteira** — mesmo os componentes que o próprio relatório
lista como `"state": "Created"` não persistem se o resultado geral for `Failed`. Conferi isso
objetivamente comparando o relatório com `sf org list metadata` depois).

| Componente | Tipo | Em `force-app/` | Deployado de verdade em `sbx-eplast-dev` |
|---|---|---|---|
| `IA_Rascunho_Comercial` | CustomPermission | Sim | **Sim** |
| `Opportunity_PromptFlow_CotacaoPrimaria` | Flow (PromptFlow) | Sim | **Sim** |
| `Opportunity_PromptFlow_DadosOportunidade` | Flow (PromptFlow, novo — não estava no design) | Sim | **Sim** |
| `Opportunity_Screen_RascunhoComercial` | Flow (Screen) | Sim | Não — bloqueado (referencia as 3 ações de prompt, que não existem) |
| `Rascunho_Proposta_Comercial` | GenAiPromptTemplate (Flex) | Sim | Não — bloqueado (seção 3.6) |
| `Rascunho_Followup_Comercial` | GenAiPromptTemplate (Flex) | Sim | Não — bloqueado (seção 3.6) |
| `Argumentos_Comerciais_Oportunidade` | GenAiPromptTemplate (Flex) | Sim | Não — bloqueado (seção 3.6) |
| `PS_Comercial_RascunhoIA` | PermissionSet | Sim | Não — bloqueado (referencia o Screen Flow) |
| `PSG_Comercial_RascunhoIA` | PermissionSetGroup | Sim | Não — bloqueado (referencia o PermissionSet) |
| `Opportunity_Record_Page` (aba "Rascunho IA") | FlexiPage (alteração) | Sim | Não — bloqueado (referencia o Screen Flow) |

Tudo que está em `force-app/` e não deployou é, mesmo assim, a melhor implementação
declarativa possível do design, pronta para ativar assim que o item da seção 3.6 for resolvido —
não é um placeholder.

---

## 5. Ordem de criação (a que foi seguida, e a que valerá quando o bloqueio for resolvido)

1. `CustomPermission` `IA_Rascunho_Comercial` — sem dependências.
2. `Flow` `Opportunity_PromptFlow_CotacaoPrimaria` (PromptFlow) — sem dependências.
3. `Flow` `Opportunity_PromptFlow_DadosOportunidade` (PromptFlow) — sem dependências.
4. `GenAiPromptTemplate` × 3 (Flex) — dependem de 2 e 3 (via `templateDataProviders`). **Bloqueado.**
5. `Flow` `Opportunity_Screen_RascunhoComercial` (Screen) — depende de 4 (actionCalls por
   `actionName`). **Bloqueado.**
6. `PermissionSet` `PS_Comercial_RascunhoIA` — depende de 1, 2, 3, 5 (flowAccesses +
   customPermissions + object/field permissions). **Bloqueado.**
7. `PermissionSetGroup` `PSG_Comercial_RascunhoIA` — depende de 6. **Bloqueado.**
8. `FlexiPage` `Opportunity_Record_Page` (alteração: nova aba) — depende de 1 e 5.
   **Bloqueado.**

---

## 6. Decisões tomadas durante o build (todas dentro da arquitetura aprovada)

- **Novo componente não previsto no design:** `Opportunity_PromptFlow_DadosOportunidade`
  (seção 3.1). Justificativa: `sobject://Opportunity` como input direto do Flex template
  quebra o servidor; a correção é entregar os mesmos dados (Opportunity + Account) por um
  segundo Flow de grounding, em vez de merge field automático. Mesma arquitetura, mesmo nível
  da doutrina (declarativo), zero Apex/LWC. **Um Flow, um propósito** (CLAUDE.md raiz): por
  isso não empilhei esses campos dentro do `Opportunity_PromptFlow_CotacaoPrimaria`, que
  continua só sobre a cotação.
- **Input dos 3 `GenAiPromptTemplate` mudou de `Opportunity` (SObject) para `OpportunityId`
  (Text)**, pelo mesmo motivo. O Screen Flow passa `{!Opportunity.Id}` em vez do registro
  inteiro.
- **Allowlist de campos (3.4 do design) não mudou** — os mesmos campos de Opportunity,
  Account, `SBQQ__Quote__c` e `SBQQ__QuoteLine__c`, só que lidos por Flow em vez de merge
  field automático.
- **Nenhum componente novo além dos dois Flows de grounding** foi adicionado. Nada de Apex,
  LWC, Named Credential — confirmado por inspeção (`grep` em todos os Flows novos por
  `recordCreates`/`recordUpdates`/`recordDeletes`: zero ocorrências).
- **Descrições dos componentes** tiveram que ser reduzidas por causa do limite de 255
  caracteres do campo `Description` em `PermissionSet`/`PermissionSetGroup`/
  `GenAiPromptTemplate` (descoberto por erro de deploy real) — todas continuam preenchidas e
  com referência à demanda e ao design.

---

## 7. O que ficou pendente

1. **Bloqueante técnico (seção 3.6):** o vínculo Flex ↔ Flow custom como grounding não
   deploya. Precisa de decisão do arquiteto humano: investigar via UI do Prompt Builder,
   aceitar um achado de limitação de plataforma e reabrir o design (ex.: trocar para opção B,
   Agentforce — a alternativa que o próprio design 2.4 já cogitava), ou autorizar Apex como
   data provider (reabre a decisão "zero Apex").
2. **Pendência contratual (seção 0):** autorização por escrito para a Onda 3, antes de
   qualquer deploy em QA/produção.
3. **R4 do design (dev == qa?):** continua sem confirmação — `sbx-eplast-qa` segue não
   autenticada neste runner. Bloqueante para a etapa de QA, não para o build.
4. **Atribuição do PSG:** manual, pós-deploy, pela lista de usuários que o cliente der
   (design, seção 7) — só relevante depois que o item 1 for resolvido e o PSG existir de
   verdade na org.
5. **Reconfirmar a allowlist de campos com o Comercial** (achado 4 do assessment) — fora do
   escopo desta demanda v1, como o design já registrava.
6. Se a resolução do item 1 mudar qualquer parte do fluxo de dados (ex.: trocar `flow://` por
   `apex://`), os 3 `GenAiPromptTemplate` e possivelmente o Screen Flow precisam ser revisados
   de novo — não assumir que o resto do plano continua válido sem reconferir.

---

## 8. Riscos do design e como o build lidou com cada um

| Risco | Como o build lidou |
|---|---|
| **R3** (automação concorrente em Opportunity/Account) | Zero DML confirmado por inspeção em todos os 3 Flows novos (nenhum `recordCreates`/`recordUpdates`/`recordDeletes`). Os dois Flows deployados de verdade (grounding) só leem. Risco não se materializa |
| **R4** (dev == qa?) | Não resolvido nesta etapa (não é do build) — fica para antes do QA, como o design já previa |
| **R6** (campos sem descrição) | Allowlist não mudou; só campos padrão/CPQ já descritos no recon são lidos |
| **R7** (alucinação de preço/prazo) | As instruções fixas nos 3 templates (regras 1–5/6 de cada um) não mudaram de conteúdo; só a forma de entrega do dado ao modelo mudou (texto formatado por Flow em vez de merge field). O roteiro de QA adversarial continua necessário e não foi afetado por este achado |
| **R8** (capacidades de plataforma não verificadas em documentação) | **Este é o risco que se materializou.** A POC do passo 0 (2.4) revelou que a premissa de grounding por Flow custom não fecha nesta org, exatamente como o design previu que poderia acontecer. Reportado aqui, não contornado |
| **R13** (dado sintético difícil de criar) | Não cheguei a criar dado sintético nesta sessão — o bloqueio de 3.6 impede testar geração ponta a ponta. Fica para quando o item 1 da seção 7 for resolvido |

---

## 9. Conferências finais desta sessão

- `sf org list` confirmou `sbx-eplast-dev` como única org autenticada, alvo de todo comando.
- Nenhum comando `sf` rodou contra outro alias.
- Nenhum dado de negócio foi lido ou gravado (só metadata e definições).
- Nenhum arquivo de verificação temporário (`.verify-tmp-EPLAST-30/`) ficou no repositório —
  usado só fora de `force-app/`, fora do commit, removido ao final de cada rodada de teste.
- `git status` antes do commit mostra só os componentes listados na seção 4, mais este plano.

---

Build não fechou. Reporto para o humano decidir o próximo passo da seção 3.6 antes de liberar
o gate de build.
