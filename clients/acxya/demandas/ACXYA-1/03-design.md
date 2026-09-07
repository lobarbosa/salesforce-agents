# ACXYA-1 — Desenho da solução

**Etapa:** 3 (arquitetura) · **Autor:** agente `arquiteto` · **Data:** 2026-09-07
**Org usada para confirmação:** `sbx-acxya` — sandbox
`https://acxya--sbxacxya.sandbox.my.salesforce.com` · Org Id `00DHa000006bRsDMAU` · API v67.0
**Produção:** não conectada nesta máquina. Nenhum comando desta etapa tocou prod.
**Base:** `01-analise.md` (aprovado no gate de 2026-09-06) e `02-recon.md` (coletado
2026-09-07, **vence em 2026-09-14**).

**Comandos desta etapa foram somente leitura + `sf project deploy validate` (check-only).**
Os validates rodaram a partir de um projeto DX temporário em `/tmp`, já removido — **nada
foi criado em `force-app/` e nada foi commitado na org**. Confirmado: `git status` limpo.

---

## 0. Resumo executivo

1. **Declarativo, nível 1 da doutrina (configuração nativa).** Campo custom + Validation
   Rule + layout. Nenhuma linha de Apex se justifica.
2. **Achado que quebra uma decisão já aprovada:** o mapeamento `Lead.Data_Aniversario__c` →
   `Contact.Birthdate` na conversão **não é possível na plataforma** — a configuração de
   Lead Conversion Field Mapping só aceita campo **custom → custom**. `Birthdate` é campo
   padrão. Confirmado empiricamente contra a org (§2). Isso **reabre a premissa P4** e é a
   principal decisão que o humano precisa tomar neste gate.
3. **R1/R2 (primeira VR ativa do Lead):** três opções com trade-off em §5. Recomendação do
   arquiteto é a Opção B, mas a decisão é do humano.
4. **4 perguntas bloqueiam o build** (§8). Nenhuma delas é resolvível pelo agente.

---

## 1. Decisão: declarativo vs. código

### 1.1 Decisão

**Solução 100% declarativa, no nível 1 da ordem de preferência da skill `salesforce-doutrina`
(configuração nativa).** Nenhum Apex, nenhum LWC, nenhum Flow — *exceto* se o humano escolher
a Opção 2 de §2, que sobe para o nível 2 (Flow) com justificativa escrita.

### 1.2 Por que não subir/descer de nível

| Nível | Cabe aqui? | Justificativa |
|---|---|---|
| 1 — Configuração nativa | **Sim** | Campo custom, Validation Rule e layout resolvem CA-01, CA-02, CA-03 e CA-04 integralmente. É onde a solução deve morar. |
| 2 — Flow | Só condicionalmente | Nenhum requisito atual exige Flow. Passa a exigir **apenas** se o humano escolher a Opção 2 de §2 (mapear aniversário no momento da conversão), porque aí a plataforma não oferece configuração para isso. |
| 3 — Apex/LWC | **Não** | Nenhum dos gatilhos da doutrina está presente: não há callout, não há rollback transacional complexo, não há recursão com estado, não há volume que ameace limite de elementos, e a regra não precisa de teste unitário determinístico (uma VR é determinística por construção). Descer para Apex aqui seria custo de manutenção puro. |

### 1.3 Mecanismo de validação: Validation Rule vs. Flow before-save vs. nada

A demanda pede "bloquear data futura". Existem três mecanismos possíveis. Comparação:

| Mecanismo | Cobre quais entradas | Comportamento | Veredito |
|---|---|---|---|
| **Validation Rule** | UI, API, Data Loader, integração, Web-to-Lead, import — **todas** | Bloqueia o save inteiro e devolve mensagem ao chamador | **Escolhido** |
| Flow record-triggered **before-save** que corrige/limpa o valor | Todas as entradas também | Não bloqueia: silenciosamente descarta ou altera o dado do usuário | **Rejeitado** |
| Nada (validar só no front) | Só a UI | Integração e import passam com dado sujo | **Rejeitado** |

Justificativa da escolha:

- **VR é nível 1 da doutrina; Flow é nível 2.** Descer de nível sem motivo é a principal
  fonte de custo de manutenção em projeto Salesforce (skill `salesforce-doutrina`). Não há
  motivo aqui.
- **Um Flow before-save que "corrige" o valor destrói informação sem avisar ninguém.** Se o
  usuário digitou 2027 querendo 1997, apagar o valor esconde o erro em vez de expor. Para
  dado pessoal (§11), alteração silenciosa é ainda pior — não fica claro quem alterou o quê.
- **"Nada" não atende CA-04**, que a análise aprovou como requisito.
- Bônus de ordem de execução: a VR roda **antes** dos dois Flows after-save existentes no
  Lead, então não disputa ordem com nada (§6). Um Flow before-save seria a **primeira**
  automação before-save do Lead nesta org — introduziria uma camada de automação nova em um
  objeto que hoje não tem nenhuma, sem ganho.

**Custo aceito conscientemente:** VR bloqueia *qualquer* save que viole a regra, inclusive de
integração. Esse é exatamente o risco R2 e está tratado em §5 com opções de escopo da fórmula.

---

## 2. Achado que altera o escopo aprovado — mapeamento na conversão (P4)

> **Escalação para o arquiteto humano.** A decisão registrada no gate de 2026-09-06 foi
> "mapear para `Contact.Birthdate`". Essa decisão **não é executável como está.** Não é
> preciosismo de nomenclatura: é limite da plataforma.

### 2.1 O que foi confirmado, e como

O recon (§5 do `02-recon.md`) confirmou que `Contact.Birthdate` existe, é do tipo `date` e é
atualizável — e concluiu "compatível para Lead Conversion Field Mapping". **A compatibilidade
de tipo é necessária mas não suficiente.** Testei o caminho de entrega de verdade:

1. `sf org list metadata-types` → o tipo `LeadConvertSettings` **existe** nesta org
   (directoryName `LeadConvertSettings`, suffix `LeadConvertSetting`).
2. `sf project retrieve start` desse tipo → **"Nothing retrieved"**; com member explícito,
   `Entity of type 'LeadConvertSettings' named 'LeadConvertSettings' cannot be found`.
   `SELECT ... FROM LeadConvertSettings` (Tooling) → **0 registros**. Ou seja: hoje a org
   **não tem** nenhum mapeamento de conversão custom versionável.
3. `sf project deploy validate` (check-only) mapeando um campo custom do Lead →
   `Contact.Birthdate` (padrão) → **FALHOU**, com a mensagem literal da API:

   ```
   errorCode: INVALID
   message: "The mapping fields cannot be null. The valid from entity is only LEAD and the
             target entity can only be ACCOUNT, CONTACT, OPPORTUNITY. The field needs to be
             a custom"
   outputField: null
   ```

   Repare em `"outputField": null` — a API nem resolveu `Birthdate` como alvo válido.
4. Contraprova: `sf project deploy validate` mapeando um campo custom do Lead → um campo
   **custom** do Contact → **SUCESSO** (`Status: Succeeded`, componente `LeadConvertSettings`
   validado, 10 testes Apex da org passando).

**Conclusão:** `LeadConvertSettings` **é metadata deployável** nesta org (contraprova 4), mas
**só aceita mapeamento custom → custom**. Mapear para `Contact.Birthdate` está fora do
alcance dessa configuração.

**Incerteza declarada:** confirmei a restrição pela **API de Metadata**. Não consigo, via CLI,
verificar a tela Setup → Object Manager → Lead → *Map Lead Fields*. A mensagem de erro é do
motor da plataforma, não do parser do arquivo, o que indica fortemente que a tela tem a mesma
restrição (é o comportamento conhecido: a lista de campos-alvo só oferece campos custom). Mas
**não confirmei a tela**. Ver §8, item NB-1: é uma checagem de 2 minutos para o humano e ela
elimina uma opção inteira.

### 2.2 Opções para o humano decidir

| # | Opção | Nível doutrina | Prós | Contras |
|---|---|---|---|---|
| **1** | **Não mapear.** O aniversário fica só no Lead. `Contact.Birthdate` continua vazio após conversão. | 1 | Zero automação nova. Zero risco. Entrega hoje. | Não atende à intenção do gate de 2026-09-06. O dado se perde de vista após a conversão. Exige o negócio dizer "tudo bem". |
| **2** | **Flow record-triggered no Lead, after-save**, com critério de entrada `IsConverted = true` e `ConvertedContactId` preenchido e `Data_Aniversario__c` preenchido → atualiza `Contact.Birthdate`. | 2 | Atende o requisito. Usa o campo padrão, sem duplicar dado. Declarativo. | **Vira o 3º Flow after-save no objeto Lead** — armadilha explícita da doutrina ("múltiplas automações no mesmo objeto/evento → ordem imprevisível"). Ver §6. |
| **3** | **Criar campo custom em Contact** (ex.: `Contact.Data_Aniversario__c`) e usar `LeadConvertSettings` custom→custom. | 1 | Fica tudo em configuração versionável. | **Duplica dado pessoal**: Contact passa a ter `Birthdate` e um clone. Duas fontes de verdade, dois lugares para vazar (§11). **É mudança de modelo de dados** → pela regra do `CLAUDE.md` do squad, decisão de arquitetura sênior, escalada, não decidida aqui. |
| 4 | Apex (trigger/hook de conversão) | 3 | — | **Rejeitada de saída.** Nada aqui justifica descer para código quando a Opção 2 resolve declarativamente. |

**Recomendação do arquiteto:** **Opção 2**, com a ressalva de ordem de execução de §6
registrada e testada no QA. Se o negócio aceitar viver sem o mapeamento, **Opção 1** é
estritamente melhor (menos automação = menos risco). **Recomendo formalmente contra a
Opção 3**: duplicar data de nascimento em um objeto que já tem campo padrão para isso é
dívida de modelo de dados e superfície extra de LGPD, sem ganho funcional.

---

## 3. Especificação do metadata

### 3.1 Inventário de componentes

| Ação | Tipo | API name | Condicional? |
|---|---|---|---|
| **Criar** | `CustomField` | `Lead.Data_Aniversario__c` | Não |
| **Criar** | `ValidationRule` | `Lead.Valida_Data_Aniversario_Nao_Futura` | Não (mas `active` depende de §5/R1) |
| **Alterar** | `Layout` | `Lead-Lead Layout` | Não |
| **Alterar** | `Profile` (deltas de `fieldPermissions`) | ver §4 | Não |
| **Criar** | `Flow` | `Lead_AfterSave_MapeiaAniversarioNaConversao` | **Sim** — só se §2 Opção 2 |
| **Criar** | `LeadConvertSettings` | `LeadConvertSettings` | **Sim** — só se §2 Opção 3 (não recomendada) |
| **Depreciar** | — | nenhum | — |

Nenhum componente existente é removido ou desativado por esta demanda.

### 3.2 `CustomField` — `Lead.Data_Aniversario__c`

Espelha exatamente o padrão do precedente `Lead.Last_Touch_Date__c` (único outro campo Date
custom do Lead), confirmado no `force-app` local.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Data_Aniversario__c</fullName>
    <description>ACXYA-1 — Data de nascimento (aniversário) do prospect.</description>
    <externalId>false</externalId>
    <label>Data de Aniversário</label>
    <required>false</required>
    <trackFeedHistory>false</trackFeedHistory>
    <trackHistory>false</trackHistory>
    <type>Date</type>
</CustomField>
```

| Atributo | Valor | Justificativa |
|---|---|---|
| `type` | `Date` | Decisão do gate (P1). Atende CA-03. |
| `label` | `Data de Aniversário` | Consistente com o rótulo em português dos 29 campos custom do Lead. |
| `description` | preenchida | `padrao-entrega` reprova componente sem descrição em code review. |
| `required` | `false` | Pendência #4 aberta; instrução do gate é assumir opcional. **Ver B-3 em §8** — este atributo é bloqueante. |
| `trackHistory` | **`false`** | O objeto Lead tem `enableHistory=true` e 5 campos rastreados (`Budget__c`, `CNPJ__c`, `Company`, `Email`, `Status`). Rastrear aniversário replicaria dado pessoal em `LeadHistory` sem necessidade declarada — contraria minimização (§11). Também é o valor do precedente `Last_Touch_Date__c`. |
| `trackFeedHistory` | `false` | Precedente da org. |
| `externalId` | `false` | Não é chave de integração. |
| `defaultValue` | ausente | Data de nascimento não tem default sensato. |

**Validado:** este XML passou em `sf project deploy validate` (check-only) contra
`sbx-acxya` com `Status: Succeeded`.

### 3.3 `ValidationRule` — `Lead.Valida_Data_Aniversario_Nao_Futura`

Nome segue o padrão dos 4 existentes no objeto (`Valida_Lead_Atividades_Pendentes`,
`Validacao_de_Telefone`, `Validacao_de_Campos`, `Lead_status_MQL`).

**Fórmula recomendada (Opção B de §5 — escopo "só quando o campo é tocado"):**

```
AND(
  OR(ISNEW(), ISCHANGED(Data_Aniversario__c)),
  NOT(ISBLANK(Data_Aniversario__c)),
  Data_Aniversario__c > TODAY()
)
```

**Fórmula da Opção A (escopo total), caso o humano prefira:**

```
AND(
  NOT(ISBLANK(Data_Aniversario__c)),
  Data_Aniversario__c > TODAY()
)
```

XML (com a fórmula da Opção A, que é a versão que já validei contra a org; a da Opção B só
acrescenta o `OR(ISNEW(), ISCHANGED(...))`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Valida_Data_Aniversario_Nao_Futura</fullName>
    <active>false</active>
    <description>ACXYA-1 — Impede que a data de aniversário do prospect seja futura.</description>
    <errorConditionFormula>AND(
  NOT(ISBLANK(Data_Aniversario__c)),
  Data_Aniversario__c &gt; TODAY()
)</errorConditionFormula>
    <errorDisplayField>Data_Aniversario__c</errorDisplayField>
    <errorMessage>A data de aniversário não pode ser uma data futura.</errorMessage>
</ValidationRule>
```

| Atributo | Valor | Justificativa |
|---|---|---|
| `errorMessage` | `A data de aniversário não pode ser uma data futura.` | Português, como as 4 VRs existentes. Diz o que está errado, sem jargão. |
| `errorDisplayField` | **`Data_Aniversario__c`** | **Divergência consciente do precedente:** nenhuma das 4 VRs existentes usa `errorDisplayField` — todas dão erro no topo da página. Ancorar no campo aponta o problema direto para o usuário e reduz a chance de o erro ser lido como "o Lead inteiro está errado". Vale o desvio. |
| `active` | **`false` no XML entregue** | Ver §5/R1. O valor final é decisão do humano; o build deve entregar o que ele decidir. `false` é o default seguro se ele não se pronunciar. |
| `description` | preenchida | `padrao-entrega`. |

**Nota sobre `ISBLANK` em campo Date:** `ISBLANK` é válido para Date e é a função recomendada
para fórmulas novas. O guard `NOT(ISBLANK(...))` não é decorativo — sem ele, a fórmula
avaliaria um campo nulo na comparação e a VR passaria a ter comportamento dependente do
contexto. Com ele, a regra é **inerte para todo Lead que não preencha o campo**, que é
exatamente o que neutraliza R2 para o tráfego atual das integrações.

**Validado:** campo + VR (versão Opção A) passaram juntos em `sf project deploy validate`
(check-only) contra `sbx-acxya`, `Status: Succeeded`, 10 testes Apex da org executados e
aprovados. **A fórmula compila.**

### 3.4 `Layout` — `Lead-Lead Layout`

O recon confirmou: **1 Record Type ativo (`Mestre`) e 1 layout (`Lead Layout`)**. Não há
segregação a resolver.

Seções atuais confirmadas no arquivo local
`force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml`: `Lead Information`,
`Informações de classificação`, `Informações fiscais`, `Address Information`,
`Additional Information`, `Description Information`, `System Information`,
`Marketing Cloud`, `Custom Links`.

**Posição proposta:** seção **`Lead Information`** (style `TwoColumnsTopToBottom`),
**coluna 2**, imediatamente **após `Email`**, com `<behavior>Edit</behavior>`.

Justificativa: a coluna 2 dessa seção já concentra os atributos de contato da pessoa
(`Status`, `Phone`, `Email`, `Rating`). Aniversário é atributo da pessoa, não de qualificação
comercial — não pertence a `Informações de classificação` (BANT) nem a `Informações fiscais`.

Se e somente se `required = true` for decidido (B-3), o `behavior` no layout passa a
`Required`.

> ⚠️ **Risco operacional de layout, severidade Média.** Deploy de `Layout` **substitui o
> layout inteiro**, não faz merge. O arquivo local veio de um baseline retrieve; qualquer
> alteração feita na org depois disso seria silenciosamente revertida. **Obrigatório no
> build:** fazer `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` imediatamente
> antes de editar, e o PR deve mostrar como diff **apenas** a linha do campo novo. Se o diff
> mostrar mais coisa, parar e escalar.

### 3.5 Lead Conversion Field Mapping — **como é entregável**

Resposta direta à pergunta, confirmada e não presumida (evidência em §2.1):

- **É metadata deployável?** O tipo `LeadConvertSettings` **existe e é deployável** nesta org
  (validate check-only com `Status: Succeeded` para um mapeamento custom→custom).
- **Serve para esta demanda?** **Não.** Só aceita **campo custom → campo custom**.
  `Contact.Birthdate` é padrão. A API rejeita explicitamente: *"The field needs to be a
  custom"*.
- **Existe hoje na org?** Não. `SELECT ... FROM LeadConvertSettings` retorna **0 registros** e
  o retrieve não traz nada. Ou seja, não há nenhum mapeamento de conversão custom versionado
  hoje — este seria o primeiro.

**Portanto, o que é entregável depende da opção escolhida em §2.2:**

| Opção §2.2 | Entregável como |
|---|---|
| 1 — não mapear | Nada a entregar. |
| 2 — Flow (recomendada) | `Flow` versionado no repo, deploy normal. **Não** usa `LeadConvertSettings`. |
| 3 — campo custom no Contact | `LeadConvertSettings` versionado no repo + o campo custom novo. Deployável, mas exige mudança de modelo de dados (escalada). |

**Não existe caminho de "passo manual na org" que funcione aqui.** A tela *Map Lead Fields*
está sujeita ao mesmo motor que rejeitou a chamada de API — a menos que a verificação NB-1
de §8 prove o contrário.

---

## 4. Impacto em permissões

### 4.1 Como esta org concede FLS hoje — confirmado, não presumido

Consultei `FieldPermissions` na org para três campos custom existentes do Lead
(`Last_Touch_Date__c`, `Cargo__c`, `CNPJ__c`). Os três têm **o mesmo padrão: 14 concessões,
13 delas por PERFIL com Read+Edit**, incluindo perfis de integração e o `Read Only`:

`Administrador do sistema`, `System Administrator (non-API user)`, `Usuário Padrão`,
`Usuário do Marketing`, `Gerente de soluções`, `Gerente do contrato`, `Read Only`,
`Analytics Cloud Integration User`, `Analytics Cloud Security User`,
`Sales Insights Integration User`, `Salesforce API Only System Integrations`,
`Minimum Access - Salesforce`, `Minimum Access - API Only Integrations` / `Anypoint Integration`
— mais 1 permission set (`Slack Integration User`, só Read).

Ou seja: **o precedente da org é FLS ampla por perfil**, o padrão "marcou todos os perfis na
tela de criação do campo".

Para referência, os perfis com **Edit no objeto Lead** são 7:
`Administrador do sistema`, `System Administrator (non-API user)`, `Usuário Padrão`,
`Usuário do Marketing`, `Gerente de soluções`, `Gerente do contrato`,
`Sales Insights Integration User`.

### 4.2 Armadilha confirmada no repositório

Os arquivos de `Profile` no `force-app` local têm **zero `fieldPermissions`**
(`Admin`, `MarketingProfile`, `Atendimento Konecta Perfil`: contagem = 0). O baseline de
perfis **não é fonte de verdade de FLS**.

**Consequência para o builder:** não adianta editar os arquivos de perfil existentes esperando
que "o resto continue igual" — eles não carregam FLS nenhum. O caminho correto é entregar
**arquivos de perfil delta**, contendo apenas o bloco `fieldPermissions` do campo novo (deploy
de Profile pela Metadata API é aditivo para os membros incluídos no pacote). Isso precisa
estar explícito no `04-plano-build.md`.

### 4.3 Opções de FLS — decisão do humano (B-4 em §8)

| # | Opção | Prós | Contras |
|---|---|---|---|
| **P-1** | **Replicar o precedente**: os mesmos 13 perfis, Read+Edit. | Consistente com todo o resto do Lead. Nada quebra por falta de acesso. Zero surpresa para o usuário. | Concede **dado pessoal** a perfis de integração e ao `Read Only` sem necessidade declarada. Contraria minimização (§11). |
| **P-2** | **Minimização (recomendada)**: Read+Edit só para `Admin`, `System Administrator %28non-API user%29`, `Standard`, `MarketingProfile`. Nenhum perfil de integração. | Aderente à LGPD: só quem opera Lead com humano vê o dado. Reversível a qualquer momento. | Diverge do padrão da org. Se a pendência #6 revelar que uma integração precisa escrever no campo, exige um ajuste extra depois. |
| P-3 | Permission set dedicado (`PS_Comercial_Data_Aniversario`, conforme `padrao-entrega`). | Prática moderna; acesso audita bem. | Nenhum campo do Lead nesta org usa esse modelo hoje. Introduzir o padrão numa demanda P/M é escopo além da demanda. |

**Recomendação:** **P-2**. Se o humano preferir alinhamento com o legado, P-1 é aceitável,
mas então o registro de finalidade de §11 vira obrigatório.

> **Sem FLS explícita, o campo não aparece para ninguém.** Um `CustomField` criado por deploy
> de Metadata API não herda visibilidade automaticamente. Este é o modo de falha mais comum
> dessa entrega: "deploy passou, mas o campo sumiu". A verificação de FLS pós-deploy é item
> obrigatório do roteiro de QA (etapa 5).

**Nomes de perfil — incerteza declarada:** a org responde em **pt-BR** (labels), e o
`force-app` guarda **API names** em inglês (`Admin`, `Standard`, `MarketingProfile`,
`SolutionManager`, `ContractManager`, `Read Only`,
`System Administrator %28non-API user%29`). O mapeamento label→API name acima é **inferência
consistente com os nomes de arquivo locais**, não uma confirmação campo a campo. O builder
deve confirmar cada par antes de escrever os deltas.

---

## 5. Tratamento dos riscos do recon

### R1 — Ligar a primeira Validation Rule ativa do Lead · Severidade **Alta**

**O que o recon achou:** existem 4 VRs no Lead, **todas inativas**. O objeto não tem nenhuma
validação ativa hoje.

**O que eu acrescento:** li as 4 fórmulas no `force-app`. Elas explicam o desligamento e o
achado é relevante para a decisão:

- `Validacao_de_Telefone` → `LEFT(Phone, 1) <> "+"`. **Sem guard de campo vazio.** Essa regra
  derruba *todo* Lead cujo telefone não comece com `+`, inclusive Lead sem telefone. É
  exatamente o tipo de VR que quebra integração no dia seguinte.
- `Validacao_de_Campos` → exige **32 campos preenchidos** quando `Status = 'Prospect'`.
  Idem: inviabiliza criação programática de Lead.
- `Valida_Lead_Atividades_Pendentes` → bloqueia conversão com atividade pendente.
- `Lead_status_MQL` → bloqueia mudança para MQL sem passar pelo wizard.

**Leitura do arquiteto:** o padrão das duas primeiras é consistente com "VR ampla demais foi
ligada, quebrou a operação, foi desligada". Isso **não é prova** — ninguém documentou o motivo
e eu não tenho como recuperá-lo. Mas muda o peso da recomendação: o histórico do objeto sugere
que VR mal escopada aqui já custou caro antes.

**A diferença desta VR para aquelas:** ela é escopada a um único campo novo que **ninguém
preenche hoje** (o campo não existe). Com o guard `NOT(ISBLANK(...))`, ela é matematicamente
inerte para 100% do tráfego atual. O risco não é o mesmo.

**Opções — decisão do humano:**

| # | Opção | Trade-off |
|---|---|---|
| **A** | VR nasce **ativa**, fórmula sem `ISCHANGED` (§3.3, Opção A). | CA-04 atendido no deploy, sem passo manual. Regra vale para todo save, sempre. Mas cria a possibilidade de "registro envenenado" (ver R2). |
| **B** | VR nasce **ativa**, fórmula com `OR(ISNEW(), ISCHANGED(Data_Aniversario__c))` (§3.3, Opção B). **← recomendada** | CA-04 atendido; a regra só dispara quando alguém **mexe** no campo. Um valor ruim pré-existente não trava updates futuros de integração. Custo: se um valor futuro entrar por um caminho que ignore VR, ele persiste sem ninguém ser avisado. |
| **C** | VR nasce **inativa** (`active=false`); o humano liga na org depois do smoke test. | Deploy totalmente neutro. Mas CA-04 **não** é atendido pelo deploy, vira passo manual pós-deploy, e passo manual pós-deploy é o que mais se esquece. Também deixa o repo divergente da org. |

**Recomendação:** **B**. Atende o critério de aceite, e o `ISCHANGED` remove o único cenário
em que a VR causaria dano recorrente. Se o humano quiser risco zero na primeira janela,
**C** com data marcada para ativar é defensável — mas a data precisa ser marcada, não
"depois a gente vê".

**Recomendação adicional, fora do escopo desta demanda:** as 4 VRs inativas são dívida
técnica não documentada. Vale abrir uma demanda separada para decidir se são para consertar
ou para apagar. Não faz parte de ACXYA-1 (§9).

### R2 — VR versus integração · Severidade **Média**

**Mecanismo concreto que confirmei**, e que é mais específico do que o recon descreveu:

O flow `Leads_do_Marketing_Cloud` é `RecordAfterSave` / `Create` no Lead e executa um
**Update Records** no próprio Lead (troca o `OwnerId`). O flow `Count_de_Tasks_Pendentes` é
`RecordAfterSave` / `CreateAndUpdate` e também escreve no Lead. **Update disparado por flow
after-save reentra no ciclo de save e reavalia as Validation Rules.** Portanto uma VR que
falhe não "só" bloqueia a gravação da integração: ela faz o **flow** falhar, e o rollback
derruba a transação inteira — a criação do Lead pelo Marketing Cloud vira erro.

Além disso, o modo de falha crônico: com a fórmula da Opção A (sem `ISCHANGED`), se um valor
de data futura chegar ao banco por qualquer caminho que ignore VR, aquele registro fica
**permanentemente não-salvável** — toda tentativa futura de update, por qualquer integração,
falha até alguém corrigir o campo à mão.

**Grau real de exposição hoje:** **baixo**, porque (a) o campo é novo, (b) nenhuma integração
o conhece, (c) o guard `NOT(ISBLANK(...))` torna a regra inerte para registro sem o campo
preenchido, e (d) sob a Opção P-2 de FLS (§4.3) os perfis de integração **nem enxergam** o
campo. A exposição só sobe se, no futuro, alguém mapear Marketing Cloud ou WhatsApp para
este campo — e aí é uma mudança consciente, não um acidente.

**Opções de mitigação — decisão do humano:**

| # | Opção | Trade-off |
|---|---|---|
| **M-1** | Guard `NOT(ISBLANK(...))` **(obrigatório em qualquer cenário)** + fórmula Opção B (`ISCHANGED`). | Cobre o modo de falha crônico. Custo próximo de zero. **Recomendada.** |
| **M-2** | M-1 + **não conceder FLS a perfil de integração** (Opção P-2 de §4.3). | Defesa em profundidade: integração que não vê o campo não consegue sujá-lo. Custo: se depois alguém precisar, tem que voltar e conceder. **Recomendada em conjunto com M-1.** |
| M-3 | Bypass de VR por **Custom Permission** (`AND(NOT($Permission.Bypass_Validacao_Lead), ...)`). | Padrão robusto e reutilizável. Mas é infraestrutura nova (custom permission + permission sets + convenção) para um campo — **escopo além da demanda**, reprovável em code review por `padrao-entrega`. Só se o humano quiser adotar o padrão como iniciativa própria. |
| M-4 | Excluir perfis por `$Profile.Id` na fórmula. | **Rejeitada.** `padrao-entrega` reprova automaticamente hardcode de ID de perfil em code review. Não proponha. |

**Recomendação:** **M-1 + M-2**.

### R3 — Recon não cobre Web-to-Lead · Severidade **Média** (probabilidade desconhecida)

**Não consegui reduzir esta incerteza.** Web-to-Lead não é metadata retrievável pela CLI —
não há objeto de Tooling/Metadata que liste os formulários gerados, e a sandbox tem 0 Leads,
então nem inferência por `LeadSource` é possível. **Continua não confirmado.**

**Recomendação:** manter o campo **fora de qualquer formulário Web-to-Lead** nesta demanda,
e tratar a exposição pública como demanda separada. Motivo: coletar data de nascimento em
formulário público exige base legal e aviso de privacidade explícitos (§11), e validação no
lado do formulário — Web-to-Lead **não respeita Validation Rule da mesma forma que a UI** em
todos os cenários, então a proteção do CA-04 não é garantida ali. Não é uma decisão que se
toma de passagem dentro de uma demanda de criação de campo.

**Pergunta para o humano (não bloqueante para o build — ver NB-2 em §8):** existe formulário
Web-to-Lead ativo em produção? Se sim, quem o mantém?

### R4 — Sandbox sem massa de Lead · Severidade **Baixa** para o build, **Média** para a confiança do teste

`SELECT COUNT() FROM Lead` = 0. Consequências, uma a uma:

1. **Impacto retroativo de ligar a VR: zero em sandbox** — não há registro para reprovar.
   Isso é bom para o deploy e **enganoso para a decisão**: não diz nada sobre produção.
2. **Não é possível medir o impacto em produção a partir daqui.** Prod não está conectada
   (e é proibida ao agente). Qualquer afirmação sobre volume ou sujeira de dado em prod
   seria invenção. Registrado como limite conhecido.
3. **QA (etapa 5) precisa criar a própria massa.** O roteiro deve cobrir, no mínimo:
   data passada válida (CA-02); data futura → bloqueio com a mensagem correta no campo
   correto (CA-04); campo vazio → save passa (regra inerte); update de um Lead que **não**
   tem o campo preenchido → passa, provando não-regressão para o caminho das integrações;
   e conversão de Lead (CA-05, se a Opção 2 de §2 for escolhida).
4. **Dados de teste devem ser fictícios**, e nenhuma consulta do QA pode retornar o valor do
   campo em conjunto com dado identificável (guardrail #2 + §11).

**Recomendação:** aceitar o risco, com o roteiro de QA acima escrito explicitamente no
`05-testes.md`. Não há mitigação melhor sem tocar em produção — o que é proibido.

---

## 6. Impacto na org existente e ordem de execução

### 6.1 Automação já existente no objeto Lead (confirmada no recon)

| Componente | Tipo | Momento | Alterado por esta demanda? |
|---|---|---|---|
| `Leads_do_Marketing_Cloud` | Flow autolaunched | `RecordAfterSave` / `Create` | **Não** |
| `Count_de_Tasks_Pendentes` | Flow autolaunched | `RecordAfterSave` / `CreateAndUpdate` | **Não** |
| `sfLma.updatePackages` | Apex Trigger (pacote gerenciado, `installed`) | fase de trigger | **Não** — nem poderia |
| 4 Validation Rules | — | — | **Não** — permanecem inativas |

### 6.2 Ordem de execução

Ordem relevante (skill `salesforce-doutrina`):
`Validation Rules → before triggers/before-save Flows → after triggers → ... → Flows record-triggered (after)`.

- A VR nova roda **antes** dos dois flows after-save e **antes** do trigger `sfLma`. Não há
  Flow `RecordBeforeSave` no Lead. **Não há disputa de ordem.** Item resolvido, sem risco.
- **Efeito colateral que precisa estar escrito:** os dois flows after-save fazem update no
  Lead, o que **reentra no ciclo de save e reavalia a VR** (detalhado em R2). Não é conflito
  de ordem — é reentrância. Documentado aqui porque é o caminho por onde uma VR derruba uma
  integração sem que ninguém perceba a relação.
- `sfLma.updatePackages` é de pacote gerenciado, não é alterável, e não toca campos custom do
  cliente. Acrescentar um campo Date é **inerte** para ele. O único acoplamento é o rollback:
  se a VR reprovar o save, a transação inteira volta atrás, incluindo o que o trigger fez.
  Risco **Baixo**.

> ⚠️ **Se a Opção 2 de §2 for escolhida, isto vira o ponto de atenção da demanda:**
> **passariam a existir 3 Flows `RecordAfterSave` ativos no objeto Lead, sem ordem garantida
> entre si.** É a armadilha nomeada na skill `salesforce-doutrina` ("múltiplas automações no
> mesmo objeto/evento → ordem de execução imprevisível"). Mitigação: definir `<triggerOrder>`
> explícito no Flow novo (colocando-o por último) e registrar o número escolhido no
> `04-plano-build.md` — para que a próxima pessoa que criar um flow de Lead saiba onde
> encaixar. Ainda assim, o QA precisa validar que a conversão continua funcionando com os
> três ativos ao mesmo tempo.

### 6.3 Integrações

| Integração | Escreve em Lead? | Impacto do campo novo | Impacto da VR |
|---|---|---|---|
| Marketing Cloud (`et4ae5__`) | Sim (flow ativo + campos próprios) | **Nenhum** — não conhece o campo novo | Nulo enquanto não preencher o campo (guard `ISBLANK`); ver R2 |
| WhatsApp (`WA_Chat__c`) | Sim | **Nenhum** | Idem |
| sfLma (License Management App) | Sim (trigger) | **Nenhum** | Só via rollback de transação |

**Incerteza declarada:** não confirmei sob qual perfil ou permission set o usuário de
integração do Marketing Cloud roda. Na consulta de `ObjectPermissions` do Lead, 6 registros
vieram com `Parent` não legível pela API — pode haver um permission set de integração ali
que eu não enxerguei. Se a Opção P-2 de FLS for escolhida, isso não importa (ninguém de
integração ganha o campo). Se for P-1, **o builder precisa fechar essa lacuna antes**.

---

## 7. Limites de governador e escala

Verificação contra os números da skill `salesforce-doutrina`, com o volume real do recon
(**0 Leads em sandbox**; volume de produção **desconhecido e não verificável daqui**):

| Item | Consumo | Avaliação |
|---|---|---|
| `CustomField` Date | Nenhum | Sem impacto. Campos não consomem limite de transação. |
| Validation Rule | Nenhum SOQL, nenhum DML. Fórmula com 3 operandos, sem cross-object, sem `VLOOKUP`. | Muito abaixo do limite de fórmula compilada. Sem risco de CPU. |
| Flow da Opção 2 (§2) | 1 update no Contact por Lead convertido; o motor bulkifica por transação. | Uma conversão em massa por API traz até 100 leads por chamada; Data Loader processa 200 por lote. O flow adiciona ~1 DML por lote, contra o limite de 150. **Folga larga.** |
| Três flows after-save no mesmo objeto (Opção 2) | Somatório de tempo de CPU por transação | Único ponto a observar em carga em massa. `Count_de_Tasks_Pendentes` já faz Get Records em Task. Risco **Baixo**, mas é o item a monitorar num import grande. |

**Nenhum SOQL ou DML em loop está sendo proposto.** Nada aqui se aproxima de 100 SOQL,
150 DML, 50.000 registros ou 10s de CPU.

---

## 8. Perguntas abertas — o que bloqueia o build e o que não bloqueia

### 8.1 BLOQUEIA o build (precisa de resposta antes da etapa 4)

| # | Pergunta | Por que bloqueia | Default se não houver resposta |
|---|---|---|---|
| **B-1** | **§2 — mapeamento na conversão: Opção 1, 2 ou 3?** A decisão aprovada no gate (`Contact.Birthdate` via Lead Conversion Field Mapping) **não é executável**. | Muda o inventário de componentes: pode adicionar um Flow inteiro, ou uma mudança de modelo de dados. Não dá para "buildar e decidir depois". | Nenhum. **Precisa de decisão explícita** — é uma decisão de negócio + arquitetura sênior. |
| **B-2** | **R1/R2 — a VR nasce ativa? Com qual escopo de fórmula?** (Opções A / B / C de §5) | Define o literal de `<active>` e o `errorConditionFormula` no XML entregue. | Recomendação: **B** (ativa, com `ISCHANGED`). Se ninguém decidir, entregar **C** (`active=false`) por ser o default seguro — mas aí CA-04 não é atendido no deploy. |
| **B-3** | **Pendência #4 — o campo é obrigatório?** | Muda `<required>` no `CustomField` e o `behavior` no layout. **E interage diretamente com R2:** campo obrigatório derruba **toda** criação de Lead por integração que não o preencha — e o Marketing Cloud cria Lead hoje. Um `required=true` aqui é um incidente de produção esperando acontecer. | Assumir **`false`** (instrução do gate de 2026-09-06). Peço confirmação explícita porque a consequência de errar é grande. |
| **B-4** | **§4.3 — FLS: P-1 (replicar o precedente amplo) ou P-2 (minimização)?** | Sem FLS, o campo não aparece para ninguém e CA-01 falha. A lista de perfis é conteúdo do deploy. | Recomendação: **P-2**. |

### 8.2 NÃO bloqueia o build (pode ser decidido depois, ou é fora de escopo)

| # | Assunto | Encaminhamento |
|---|---|---|
| **NB-1** | **Verificação de 2 minutos:** abrir Setup → Object Manager → Lead → *Map Lead Fields* e ver se `Data_Aniversario__c` aceita `Birthdate` como destino. | Não bloqueia porque a API já deu a resposta. Mas se a tela aceitar, a Opção 1 de §2 vira desnecessária e a Opção 2 (Flow) fica dispensada — vale a checagem antes de aprovar B-1. |
| **NB-2** | **Pendência #6 / R3 — origem do preenchimento e existência de Web-to-Lead.** | Não bloqueia a criação do campo. Bloqueia apenas a decisão de expor em formulário público, que está **fora de escopo** (§9). Precisa de resposta antes de qualquer demanda futura de Web-to-Lead. |
| **NB-3** | **Pendência #7 — relatório de "aniversariantes do mês".** | **Fora de escopo** (§9). Se o negócio quiser, é demanda nova (campo fórmula de mês/dia — filtrar por mês num campo Date puro não funciona bem em relatório). |
| **NB-4** | Label exato: "Data de Aniversário" vs. "Data de Nascimento". | Cosmético e ajustável no PR. O API name já está decidido (`Data_Aniversario__c`) e não muda. |
| **NB-5** | Posição exata do campo no layout (§3.4 propõe `Lead Information`, coluna 2, após `Email`). | Ajustável no PR sem retrabalho. |
| **NB-6** | As 4 Validation Rules inativas do Lead (dívida técnica achada no recon). | **Fora de escopo.** Recomendo abrir demanda separada. |

---

## 9. O que NÃO será feito nesta demanda

Explicitamente fora de escopo. Nenhum destes itens deve aparecer no PR — `padrao-entrega`
reprova "escopo além da demanda" em code review:

1. **Campo fórmula de mês/dia de aniversário** para viabilizar relatório de aniversariantes
   (pendência #7). Não solicitado.
2. **Relatórios, dashboards ou list views** baseados no campo novo.
3. **Exposição do campo em formulário Web-to-Lead** (R3). Exige decisão de LGPD própria.
4. **Campo equivalente em Account ou Opportunity.**
5. **Reativar, corrigir ou apagar as 4 Validation Rules inativas do Lead.** Dívida técnica
   preexistente, registrada em §5/R1 e em NB-6 — demanda separada.
6. **Corrigir o hardcode de `OwnerId` (`0054x000007Tn9rAAC`) no flow
   `Leads_do_Marketing_Cloud`.** Achado colateral da leitura do flow; viola
   `padrao-entrega` (hardcode de ID de usuário). **Não é desta demanda** — registrado aqui
   só para não se perder.
7. **Qualquer alteração nos 2 flows ativos do Lead** ou no trigger `sfLma.updatePackages`.
8. **Migração ou backfill de dados históricos.** Não há Leads na sandbox; produção não está
   conectada.
9. **Qualquer coisa em produção.** Guardrail #1 do squad: proibido ao agente.
10. **Adoção do padrão de permission set por campo** (Opção P-3 de §4.3), se não for escolhida
    explicitamente em B-4.

---

## 10. Plano de deploy e rollback

### 10.1 Pré-condições

- Branch `feature/ACXYA-1` (já existe). Nada direto na `main`.
- **Recon vence em 2026-09-14.** Se o build passar dessa data, refazer o recon antes.
- `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` **imediatamente antes** de
  editar o layout (§3.4).
- Confirmar o mapeamento label→API name dos perfis escolhidos em B-4 (§4.3).

### 10.2 Ordem de deploy

Tudo num único deploy é possível (as dependências se resolvem na mesma transação de
metadata), mas a ordem lógica de montagem do pacote é:

1. `CustomField` `Lead.Data_Aniversario__c`
2. `Profile` deltas com `fieldPermissions` (§4.2 — **deltas**, não os arquivos completos do repo)
3. `Layout` `Lead-Lead Layout`
4. `ValidationRule` `Lead.Valida_Data_Aniversario_Nao_Futura`
5. *(condicional B-1 = Opção 2)* `Flow` `Lead_AfterSave_MapeiaAniversarioNaConversao`

**Já comprovado nesta etapa:** os passos 1 e 4 juntos passam em
`sf project deploy validate` contra `sbx-acxya` (`Status: Succeeded`). A org tem **10 testes
Apex**, todos passando — o validate os executa, então o CI (`ci-salesforce-validate.yml`) não
deve trazer surpresa por esse lado.

### 10.3 Rollback, por componente

| Componente | Rollback | Tempo | Observação |
|---|---|---|---|
| `ValidationRule` | Redeploy com `<active>false</active>` | segundos | **Primeira alavanca a puxar** se alguma integração começar a falhar. Não apague a VR — desligue. |
| `Flow` (se existir) | Desativar a versão / redeploy da anterior | minutos | — |
| `Layout` | Redeploy da cópia do layout retirada em 10.1 | minutos | **Guardar essa cópia anexada ao PR** — sem ela não há rollback de layout. |
| `fieldPermissions` | Redeploy dos deltas com `readable/editable = false` | minutos | Revogar FLS esconde o campo sem destruir dado. |
| `CustomField` | **Não deletar como rollback.** Remover do layout + revogar FLS. | minutos | `destructiveChanges` apaga o campo **e os dados nele**. Em sandbox é tolerável; em produção, nunca como rollback automático (lixeira de 15 dias, e recuperação não é garantida). |

**Regra de rollback:** o rollback padrão desta entrega é **desligar a VR e revogar a FLS**, não
apagar metadata. Só se remove o campo se o humano decidir explicitamente abandonar a demanda.

### 10.4 Passos manuais pós-deploy

- Verificar FLS efetiva na org depois do deploy (modo de falha mais comum — §4.3).
- Se B-2 = Opção C: **ativar a VR manualmente**, com data marcada. Registrar em `gates.md`.
- Nada mais. Não há passo manual de configuração de conversão (§3.5).

---

## 11. Nota de LGPD

**Data de nascimento é dado pessoal** (LGPD, art. 5º, I — informação relacionada a pessoa
natural identificada ou identificável). **Não é dado pessoal sensível** (art. 5º, II) — não se
enquadra em origem racial, convicção religiosa, opinião política, saúde, vida sexual, genética
ou biometria. Isso reduz a exigência, mas não a elimina: continua exigindo **finalidade
determinada** e **base legal**.

**Como isso já está refletido neste design:**

1. **Minimização de acesso** — Opção P-2 de FLS (§4.3): só quem opera Lead com humano recebe
   o campo; perfis de integração não.
2. **Minimização de cópias** — `trackHistory = false` (§3.2). Rastrear histórico replicaria a
   data de nascimento em `LeadHistory` indefinidamente, sem necessidade declarada.
3. **Sem exposição pública** — o campo fica fora de Web-to-Lead nesta demanda (§5/R3, §9).
4. **Sem duplicação de dado** — motivo adicional para recomendar **contra** a Opção 3 de §2
   (criar um clone de `Contact.Birthdate`): dois lugares guardando o mesmo dado pessoal são
   dois lugares para vazar e dois lugares para apagar num pedido de eliminação (art. 18, VI).

**Pendência formal para o humano registrar no gate:** a demanda original diz apenas
"inserção", e a análise (`01-analise.md`, §Contexto) registrou que o uso é **suposição**.
**Coletar dado pessoal sem finalidade declarada é uma lacuna de conformidade, não de
documentação.** Peço que a aprovação deste gate registre em `gates.md` a **finalidade** e a
**base legal** da coleta (ex.: legítimo interesse para relacionamento comercial, ou
consentimento). Isso não bloqueia o build tecnicamente — mas bloqueia a responsabilidade.

**Para as etapas seguintes (QA e entrega):** guardrail #2 do squad continua valendo —
nenhum agente deve rodar SOQL que retorne o valor deste campo. O QA da etapa 5 usa **massa
fictícia criada por ele mesmo** (R4) e valida por comportamento (o save passou / o save foi
bloqueado), nunca lendo valores em conjunto com dado identificável.

---

## 12. Incertezas declaradas

Registradas aqui para não virarem premissa silenciosa. Nenhum metadata citado neste documento
foi inventado — tudo veio de `sf` CLI contra `sbx-acxya` ou do `force-app` do repo.

| # | Incerteza | Impacto |
|---|---|---|
| I-1 | Não verifiquei a tela Setup → *Map Lead Fields*. A restrição custom→custom foi confirmada **pela API**. | Ver NB-1. Se a tela permitir, a Opção 2 de §2 é dispensável. |
| I-2 | Mapeamento label pt-BR → API name de perfil é **inferência** consistente com os nomes de arquivo do `force-app`, não confirmação campo a campo. | Builder confirma antes de escrever os deltas de FLS. |
| I-3 | 6 registros de `ObjectPermissions` do Lead vieram com `Parent` não legível pela API. Pode haver permission set de integração não identificado. | Só importa se B-4 = P-1. |
| I-4 | Perfil/permission set do usuário de integração do Marketing Cloud não confirmado. | Idem I-3. |
| I-5 | Existência de Web-to-Lead: **não verificável pela CLI**. Continua desconhecida (R3). | Mantido fora de escopo. |
| I-6 | **Produção não está conectada.** Nada neste documento pode ser lido como afirmação sobre o volume, a sujeira de dado ou o impacto real em produção. | Limite conhecido e intransponível pelo agente (guardrail #1). |
| I-7 | O motivo pelo qual as 4 VRs do Lead foram desativadas **não está documentado em lugar nenhum**. A leitura de §5/R1 é interpretação das fórmulas, não fato histórico. | Pesa na decisão B-2, mas não a determina. |

---

## Encerramento

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

Para aprovar, preciso de resposta em **B-1, B-2, B-3 e B-4** (§8.1). Sem elas o build não sai
do lugar — em especial **B-1**, que é uma decisão de negócio provocada por um limite de
plataforma que só apareceu agora, e que **contraria uma decisão já registrada no gate de
2026-09-06**.

Nada foi construído. Nenhum arquivo foi criado em `force-app/`. Nenhum commit foi feito.
`status.yaml` não foi alterado.
