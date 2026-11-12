# EPLAST-30 · Design: Apoio a propostas, follow-ups e argumentos comerciais

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** design · **Autor:** arquiteto (proposta para o aceite do arquiteto humano)
**Entradas:** `demanda.md`, `01-analise.md` (aprovada em `gates.md`, 2026-11-11), `comentarios-do-card.md`, `assessment.md` (2026-09-30), `02-recon.md` (2026-11-11, `sbx-eplast-dev`)
**Histórico consultado (RAG):** `demandas/EPLAST-29/02-recon.md` e `03-design.md` (extensão do `SFAgent2`), `demandas/EPLAST-27/03-design.md` (cascata Task → Account), `demandas/EPLAST-34/03-design.md` (provedores de IA não desligados, permission set por público).

> **Revisão 1 — 2026-11-12 (retorno do build).** A versão aprovada em 2026-11-11 (hash `049045dc14019ee1` em `gates.md`) continua abaixo, sem reescrita. Esta revisão acrescenta a **seção 12** (achado do build, diagnóstico, decisão, componentes, riscos e estimativa) e marca com **[Rev. 1]** os pontos das seções 2.4, 3.1, 6, 8 e 11 que ela altera. Entrada nova: `04-plano-build.md` (build de 2026-11-12, que parou na verificação 2 da seção 2.4).

Toda metadata citada como **existente** foi confirmada em `sbx-eplast-dev` em 2026-11-11 (ver `02-recon.md`). Os nomes da seção 3.1 são componentes **novos**, propostos por este design.

---

## 0. Antes de tudo: o que este design assume sem resposta humana

Nenhuma das 15 perguntas da análise (seção 5) foi respondida. Também nenhuma das 11 premissas (P-1 a P-11). O `comentarios-do-card.md` só registra a aprovação do gate. Este design **não para** por isso. Ele segue o escopo mais conservador que a própria análise propôs e marca cada premissa como **assumida, não confirmada**. Tudo o que depende de resposta não dada fica **fora** (seção 7). Mudar qualquer premissa abaixo **exige novo design**, não ajuste no build.

| Premissa | Como este design a trata | Confirmada? |
|---|---|---|
| **P-1** Autorização contratual (Onda 3 não contratada) | **Pendência de negócio, bloqueante para o build** (seção 0.1). Não é decisão técnica e o arquiteto não a resolve | Não |
| **P-2** Somente leitura | **Assumida.** Nada é gravado em Opportunity, Account, Contact, Order, Task ou cotação. Nenhum e-mail é enviado | Não |
| **P-3** 3 saídas, 1 ponto de entrada na Opportunity | **Assumida.** Proposta (texto), follow-up (texto) e argumentos (lista), a partir da página de Opportunity | Não |
| **P-4** Fontes: Opportunity, Account, Contact aprovados e CPQ quando existir | **Assumida e estreitada:** campos **padrão** de Opportunity e Account, e a cotação **primária** do CPQ. Contact e campos custom ficam fora até a curadoria (seção 6, R6) | Não |
| **P-5** Revisão humana antes de enviar | **Garantida por construção:** a solução não tem como enviar nada | Não precisa de confirmação |
| **P-6** Preço só do CPQ, senão marcador | **Assumida.** Instrução do template e grounding restrito | Não |
| **P-7** Plataforma escolhida pelo arquiteto | **Decidida aqui** (seção 2) | Decisão desta etapa |
| **P-8** Validação com dados sintéticos em dev | **Assumida** | Não |
| **P-9** Tempo de resposta `<N>` | Medido no QA e reportado. Não vira critério de reprovação enquanto o cliente não definir N | Não |
| **P-10** Retenção mínima do texto e do prompt | **Assumida:** a solução não grava texto nem prompt em objeto nenhum. Ver R2 e R9 sobre o que a plataforma registra | Não |
| **P-11** Custo de IA é do cliente | Registrada como risco (R5). O design não cria consumo fora do uso manual | Não |

### 0.1 Pendência contratual (pergunta 1 da seção 0 da análise): bloqueante para o build

A `demanda.md` diz: "Onda 3 · Comercial — ainda não contratada no projeto atual (Ondas 1–2)". **Este design não cria escopo contratado.** Antes de liberar a etapa de build, alguém de negócio ou de conta precisa registrar no card uma das duas coisas:
1. há aditivo ou autorização por escrito para a Onda 3 (ou para este item), e a esteira segue; ou
2. a demanda volta para backlog como antecipação, e este design fica arquivado como referência.

É decisão comercial e contratual, não técnica. O mesmo ponto está aberto em EPLAST-27 e EPLAST-29 (RAG, `01-analise.md` de cada uma).

---

## 1. O que o recon mudou na leitura da análise

1. **O risco de automação concorrente é ainda maior que o descrito no assessment, e a solução leitura-only o evita por inteiro.** `OpportunityFlow` é after-save em create e update, **sem critério de entrada**. Ele tem até 22 DMLs, chama `CreateQuoteCPQController` e pode submeter aprovação (`Opportunity.FinancialAnalysis`). Ele divide o evento after com `OpportunityTrigger`, `SBQQ.OpportunityAfter` e `Oportunidade_Industria`, e nenhum desses tem ordem garantida (02-recon, 4.3). **Qualquer escrita em Opportunity, mesmo um campo "Rascunho IA", dispara essa cadeia inteira.** A escrita em Task também tem cascata (`TaskCreatedOrUpdated` → Account, segundo o design da EPLAST-27 no RAG).
2. **OWD medido:** Opportunity é Public Read Only, Account é Public Read/Write e Contact é controlado pelo pai (02-recon, 3). O risco "rascunho sobre registro que o usuário não vê" é baixo via compartilhamento. A proteção relevante passa a ser CRUD/FLS e a permissão de uso da ferramenta.
3. **A plataforma nativa já está pronta na sandbox:** Einstein generativo habilitado, licença de Prompt Templates ativa e o tipo `PromptFlow` presente. Não existe nenhuma Named Credential. Não há infraestrutura de LLM externo.
4. **Nenhum campo custom de Opportunity tem descrição (19 de 19), e em Account só 1 de 78 tem.** Isso é pior que o número do assessment, que somava os gerenciados.
5. **Dev e qa:** continua sem confirmação (a instância de dev se chama "qa"; `sbx-eplast-qa` não está autenticada no runner).

---

## 2. Decisão de arquitetura

### 2.1 Decisão

**Prompt Builder nativo (3 Flex prompt templates) acionado por um Flow de tela na página de Opportunity, com grounding da cotação CPQ por um prompt flow declarativo. Somente leitura. Sem Apex, sem LWC, sem Named Credential, sem alteração no agente `SFAgent2`.**

```
Opportunity record page (componente de Flow, visível só para quem tem a custom permission)
  └─ Screen Flow  Opportunity_Screen_RascunhoComercial
       tela 1: usuário escolhe o tipo (proposta | follow-up | argumentos) e pede a geração
       ação:   Prompt Template (Flex) correspondente, com entrada = a Opportunity atual
                 └─ grounding: merge fields padrão de Opportunity e Account (lidos pela plataforma, no contexto do usuário)
                 └─ grounding: Flow PromptFlow  Opportunity_PromptFlow_CotacaoPrimaria (lê SBQQ__Quote__c primária e até 50 SBQQ__QuoteLine__c)
       tela 2: texto gerado (copiável), lista de campos usados e campos vazios, aviso de "rascunho, revisar antes de usar"
       falha:  tela de erro com mensagem amigável; nada mais acontece
  Nenhum elemento Create/Update/Delete Records em nenhum dos dois Flows.
```

### 2.2 Opções avaliadas (pergunta 2 da análise)

| | A. **Prompt Builder + Screen Flow** (escolhida) | B. Agentforce: novo tópico/ação no `SFAgent2` | C. LLM externo por callout (Named Credential + Apex) |
|---|---|---|---|
| Nível da doutrina | Configuração (templates) + declarativo (Flow) | Configuração + declarativo | **Código** (Apex, possivelmente LWC) |
| Infra na org hoje | Pronta: Einstein generativo habilitado, PSL de Prompt Templates ativa, `PromptFlow` disponível | Pronta: `SFAgent2` existe | **Inexistente:** 0 Named Credential, 0 External Credential |
| Apex novo | Nenhum | Nenhum | Controller + callout + parsing + `<Classe>Test` a 85%, numa org com 10% de cobertura |
| LGPD | Passa pelo Einstein Trust Layer (processador já contratado com a plataforma); provedores ainda a restringir (R2) | Igual a A | **Processador de dados novo**, fora do Trust Layer, com contrato e DPA próprios |
| Determinismo do ponto de entrada | Alto: botão, tipo escolhido, template fixo | Baixo: o planner escolhe o tópico e a ação a partir da frase do usuário | Alto |
| Interação com o que existe | Nenhuma: componente novo e Flows novos, sem tocar nada existente além de 1 Lightning page | Altera o agente do piloto (`eplast-ent-07` a `10`, construído fora da esteira), que a **EPLAST-29 também está estendendo**. São duas demandas no mesmo artefato (guardrail #6) | Nenhuma em automação, mas o deploy de Apex numa org a 10% exige atenção ao `RunLocalTests` de produção |
| Reaproveitamento futuro | Os Flex templates podem virar ação do agente depois, sem refazer | — | Baixo |

**Por que A e não B.** B não ganha nada funcional para um uso iniciado na própria oportunidade. Ela traria não determinismo de roteamento e colocaria duas demandas abertas (29 e 30) no mesmo `GenAiPlannerBundle` de um agente que não nasceu na esteira. A escolha A não fecha a porta: os templates de A são reaproveitáveis como ação do `SFAgent2` numa demanda futura, quando a 29 tiver passado e o piloto estiver estável.

**Por que não C.** C desce até código sem nenhum dos gatilhos da doutrina (não há rollback complexo, nem volume, nem recursão, nem regra que precise de teste unitário). Pelo contrário, ela **adiciona** os dois riscos mais altos da org: Apex novo numa base com 10% de cobertura (achado 2) e um processador de dado pessoal novo (LGPD). Só se justifica se o cliente exigir um modelo específico fora da Salesforce. Isso seria nova demanda, com DPA.

### 2.3 Por que este nível e não o acima

- **Só configuração não basta.** Um Flex template sozinho não tem ponto de entrada na página de registro sem um Flow ou um agente. O tipo "Field Generation", que tem botão nativo no campo, **grava** num campo de Opportunity e cai direto na cadeia do `OpportunityFlow` (seção 1, item 1). O tipo "Sales Email" é acoplado ao compositor de e-mail, ou seja, a envio (contra P-2). Por isso Flex + Flow de tela.
- **Por que Flow e não Apex no grounding da cotação:** são 2 leituras (a cotação primária e as linhas), com limite de linhas, sem regra transacional nem callout. A doutrina não justifica Apex aqui.
- **Por que não LWC:** o Flow de tela entrega escolha, texto copiável, lista de campos e tratamento de erro. Um LWC só se justificaria por uma exigência de UX que a demanda não faz (streaming, edição rica).

### 2.4 Verificação obrigatória no passo 0 do build (antes de construir o resto)

Não confirmei na documentação oficial, nesta etapa, três capacidades das quais a decisão depende. O recon mostra que o tipo `PromptFlow` existe na org, mas isso não prova as três. O build começa com uma **POC de no máximo 4 h** em `sbx-eplast-dev`:
1. A ação "Prompt Template" (Flex) é invocável a partir de um Screen Flow nesta edição (Enterprise + add-on) e devolve o texto para uma variável.
2. Um Flex template aceita um `PromptFlow` como fonte de grounding, e o `PromptFlow` consegue ler `SBQQ__Quote__c`/`SBQQ__QuoteLine__c` (objetos gerenciados).
3. A execução **não grava nada** em Opportunity, Account ou Contact (debug log sem DML nesses objetos).

**Se 1 ou 2 falhar, o build para e volta ao design.** Não se desce para Apex em silêncio. O substituto natural seria a opção B, que tem os riscos descritos acima, e essa troca é decisão do arquiteto humano.

**[Rev. 1]** A verificação 2 falhou no build (`04-plano-build.md`, 3.6). As verificações 1 e 3 ficaram sem resposta, porque dependem do template deployado. O diagnóstico aponta para um contrato de PromptFlow incompleto, não para limitação de plataforma. A decisão desta revisão é corrigir o contrato antes de trocar de opção, e a opção B continua fora. Ver seção 12.

---

## 3. Componentes

Não há convenção própria da Eplast no `CLAUDE.md` do cliente (seção de nomenclatura em branco). Vale a skill `padrao-entrega`. Todo componente novo sai com `Description` preenchida (achado 4).

### 3.1 Criar (nomes propostos, não existem hoje)

**[Rev. 1]** Esta tabela é a lista aprovada em 2026-11-11. O build já criou na org `IA_Rascunho_Comercial` e `Opportunity_PromptFlow_CotacaoPrimaria`, e acrescentou `Opportunity_PromptFlow_DadosOportunidade`. A lista vigente e as alterações estão na seção 12.5.

| Tipo | API name | Função |
|---|---|---|
| GenAiPromptTemplate (Flex) | `Rascunho_Proposta_Comercial` | Rascunho de texto de proposta. Entrada: Opportunity |
| GenAiPromptTemplate (Flex) | `Rascunho_Followup_Comercial` | Rascunho de follow-up. Entrada: Opportunity |
| GenAiPromptTemplate (Flex) | `Argumentos_Comerciais_Oportunidade` | Lista de argumentos, cada um com a fonte (campo ou linha de cotação). Entrada: Opportunity |
| Flow (`PromptFlow`) | `Opportunity_PromptFlow_CotacaoPrimaria` | Lê a `SBQQ__Quote__c` primária da oportunidade (`SBQQ__PrimaryQuote__c`) e até **50** `SBQQ__QuoteLine__c` (ordenadas por `SBQQ__NetTotal__c` desc). Devolve texto estruturado com produto, quantidade, preço líquido, desconto, condição de pagamento e validade. Sem cotação primária, devolve "sem cotação", e os templates trocam valores por `[a preencher]` |
| Flow (Screen) | `Opportunity_Screen_RascunhoComercial` | Ponto de entrada: escolha do tipo, chamada do template, exibição, fault path. **Zero elementos de DML.** Acesso restrito a permission set ("Override default behavior and restrict access") |
| CustomPermission | `IA_Rascunho_Comercial` | Controla a visibilidade do componente na página |
| PermissionSet | `PS_Comercial_RascunhoIA` | Acesso ao Flow de tela e ao prompt flow, a custom permission `IA_Rascunho_Comercial` e leitura (objeto + FLS) dos campos da allowlist (3.4) em Opportunity, Account, `SBQQ__Quote__c` e `SBQQ__QuoteLine__c` |
| PermissionSetGroup | `PSG_Comercial_RascunhoIA` | Agrupa `PS_Comercial_RascunhoIA` + `EinsteinGPTPromptTemplateUser` (padrão, existe). Uma atribuição por usuário |

### 3.2 Alterar

| Componente (existe) | Alteração |
|---|---|
| `Opportunity_Record_Page` e/ou `Opportunity_Record_Page_Three_Column` (FlexiPage) | Adicionar 1 componente `flowruntime:interview` com `Opportunity_Screen_RascunhoComercial` numa **aba própria** ("Rascunho IA"), com filtro de visibilidade `$Permission.IA_Rascunho_Comercial`. **Qual das duas páginas está ativa, e para quem, não foi medido**: o build confirma isso antes de alterar e altera só as ativas para o público comercial. O Flow abre numa tela de escolha, então **nenhuma chamada ao modelo acontece ao carregar a página** |

Nenhum page layout é alterado. Nenhuma quick action é criada: action de layout não tem filtro por permissão, e o cenário "a ação de rascunho não aparece" exige esse filtro.

### 3.3 Depreciar
Nada.

### 3.4 Allowlist de campos de grounding (v1)

Escolhida pelo critério "significado inequívoco sem descrição". **Só campos padrão ou gerenciados do CPQ, todos confirmados no recon.**

- **Opportunity:** `Name`, `StageName`, `CloseDate`, `Amount`, `Probability`, `NextStep`, `Description`, `Type`, `LeadSource`, `IsClosed`, `IsWon`, `LastActivityDate`
- **Account (via `AccountId`):** `Name`, `Industry`, `Type`, `BillingCity`, `BillingState`
- **SBQQ__Quote__c (primária):** `SBQQ__Status__c`, `SBQQ__NetAmount__c`, `SBQQ__PaymentTerms__c`, `SBQQ__ExpirationDate__c`, `SBQQ__CustomerDiscount__c`, `SBQQ__LineItemCount__c`
- **SBQQ__QuoteLine__c:** nome do produto (via `SBQQ__Product__c`), `SBQQ__Quantity__c`, `SBQQ__NetPrice__c`, `SBQQ__NetTotal__c`, `SBQQ__Discount__c`, `SBQQ__Description__c`

**Fora da v1, de propósito:**
- **Contact inteiro, inclusive `Name`.** `Email`, `Phone` e `MobilePhone` são dado pessoal e P-10 está em aberto. O texto usa `[nome do contato]`.
- **Os 19 campos custom de Opportunity e os 78 de Account:** nenhum tem descrição, e há nomes duplicados ou ambíguos (`LastMonth__c`/`LastMoth__c`, `Loss_Reason__c`/`DescricaoPerda__c`, três campos de pagamento). Entram só depois da curadoria com o Comercial, com descrição preenchida, por mudança de design.
- `Task`/`Event` (histórico de atividades), `Order` (Protheus), `Product2` além do nome e catálogo ou material de marketing para argumentos.

### 3.5 Regras de conteúdo nos templates (atendem aos cenários Gherkin)

Instruções fixas, em pt-BR, nos três templates:
- usar **só** os dados fornecidos; campo vazio vira `[dado ausente: <rótulo do campo>]`;
- preço, desconto, prazo e condição de pagamento **só** a partir dos dados da cotação primária; sem cotação, `[a preencher]` (P-6);
- nenhum número que não esteja no grounding;
- terminar com a seção "Campos usados / campos vazios" (cenário "dado ausente não vira invenção");
- nos argumentos, cada item cita a fonte (`Oportunidade.<campo>`, `Cotação`, `Linha: <produto>`);
- tom profissional, sem prometer prazo ou condição.

A eficácia dessas instruções é probabilística. Por isso o cenário de "preço não inventado" fica no roteiro de QA com casos adversariais (R7).

---

## 4. Conflito de automação e ordem de execução

**Existe automação concorrente em Opportunity no mesmo evento: `OpportunityTrigger` (custom) e `SBQQ.OpportunityAfter` em after insert/update, sem ordem garantida entre eles. Em seguida vêm `OpportunityFlow` (sem critério de entrada, até 22 DMLs, cria cotação CPQ e submete aprovação) e `Oportunidade_Industria`, ambos after-save e sem `triggerOrder`. Em Account há o mesmo padrão: `AccountTrigger` + `SBQQ.AccountBefore` + `AccountTriggered` e `UpdateParentAccountUsedLimit`, ambos sem critério.** (02-recon, 4.)

**Como este design lida com isso:** ele não entra no evento. A solução não faz DML em nenhum objeto, e nenhum trigger ou Flow record-triggered roda sem DML. A garantia é verificável em três pontos:
1. **Code review (reprovação automática):** qualquer elemento `recordCreates`, `recordUpdates` ou `recordDeletes` nos dois Flows novos.
2. **Passo 0 do build:** debug log da POC sem DML em Opportunity, Account ou Contact.
3. **QA:** cenário "não dispara automação existente", com debug log de uma geração completa.

**Este design não depende da ordem de execução.** O mapeamento desta etapa também não resolve o achado 1 do assessment (consolidar automação por objeto). Isso é demanda própria. Qualquer evolução que grave algo, como salvar o rascunho, criar Task ou enviar e-mail, **reabre este design** e exige o tratamento dessa cadeia.

---

## 5. Limites de governador e escala

| Cenário | Estimativa | Contra o limite |
|---|---|---|
| Uma geração (síncrona, 1 registro, iniciada pelo usuário) | SOQL: ~1–3 de merge fields resolvidos pela plataforma + 2 no prompt flow (cotação e linhas), mais nome de produto via relacionamento na mesma query. DML: **0** | Abaixo de 5% de 100 SOQL e de 150 DML |
| **Um pai com muitos filhos** (oportunidade com muitas linhas de cotação; o achado SOMOSAGILITY-10) | O prompt flow lê no máximo **50** linhas (limite fixo do Flow, por ordenação + contador). Acima disso, o texto informa "e mais N itens (ver cotação)". Sem DML e sem cascata, o CPU é dominado por loop simples de até 50 iterações e montagem de texto | CPU bem abaixo de 10 s. O limite que de fato pesa é o **tamanho do prompt** (tokens do modelo), que o teto de 50 também controla |
| **Muitos registros (carga em massa)** | Não se aplica: não há trigger nem Flow record-triggered novo, e a solução nunca roda em lote | — |
| Latência | Dominada pela chamada ao modelo. Não estimável sem medir. O QA mede e reporta (P-9) | Fora do governador; R10 |
| Volume de produção | **Desconhecido**: a dev tem 0 oportunidades e 0 cotações, e a distribuição de linhas por cotação não é mensurável aqui | Se a curadoria ou o cliente indicar cotações típicas acima de 50 linhas, o teto é revisto no design |

O critério de escalonamento da doutrina (passou de ~70% de um limite no volume realista, volta ao design) se aplica ao teste do QA com uma cotação sintética de 50 linhas e outra de 200 linhas.

---

## 6. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Onda 3 não contratada** (P-1) | **Alta** (negócio) | **Bloqueante para o build.** Seção 0.1 |
| R2 | **Dado de cliente sai para o provedor de modelo.** O recon mostra que **nenhum provedor está desligado** (OpenAI, Azure OpenAI, Bedrock, Vertex Gemini) e que o fallback de região está ligado. Há nome de conta, valores e produtos no prompt | **Alta** (LGPD) | Contact fora da v1. A allowlist não tem dado pessoal de pessoa física. **Antes de produção:** o DPO da Eplast aceita o processamento via Einstein Trust Layer e decide quais provedores e regiões manter. Configurar `EinsteinGptSettings` é decisão do cliente, fora desta demanda. Recomendado antes do build. Na sandbox, só dado sintético (P-8) |
| R3 | **Automação concorrente em Opportunity e Account** (achado 1, confirmado e agravado no recon) | **Alta** se houver escrita; **baixa** neste design | Zero DML, verificado em 3 pontos (seção 4). Qualquer escrita reabre o design |
| R4 | **Dev e qa podem ser a mesma sandbox** (achado 6; continua sem confirmação) | **Média**, bloqueante para o QA | Antes da etapa de QA, autenticar `sbx-eplast-qa` e comparar o Org ID com `00DHa000006vfMLMAY`, ou ter confirmação escrita do cliente. Se for a mesma, o humano decide se aceita build e homologação no mesmo ambiente |
| R5 | **Habilitação e licença de IA em produção desconhecidas; custo de consumo indefinido** (P-11). A PSL de Prompt Templates em sandbox não prova contrato em produção | **Média** | Conta e cliente confirmam licença e créditos antes do release. A solução só consome quando o usuário pede, sem execução em lote |
| R6 | **Campos sem descrição** (achado 4: 19/19 em Opportunity, 77/78 em Account) | **Média** | Allowlist só com campos padrão e CPQ (3.4). Custom só após curadoria, com descrição, por novo design |
| R7 | **Alucinação de preço, prazo ou condição** | **Média** | Grounding restrito, instruções fixas, marcadores. QA com casos adversariais: sem cotação, cotação com campos vazios, campo `Description` com texto que tenta instruir o modelo (prompt injection por dado) |
| R8 | **Capacidades da plataforma não verificadas em documentação** (Flex template em Screen Flow, PromptFlow lendo objeto CPQ) | **Média** → **materializado [Rev. 1]** | POC no passo 0 do build. Se falhar, volta ao design (2.4). **[Rev. 1]** Falhou na verificação 2 (`04-plano-build.md`, 3.6). Tratamento novo na seção 12; riscos derivados R14 a R18 na seção 12.7 |
| R9 | **Cenário "Trilha de uso sem dado pessoal" não é atendível sem decisão nova.** Gravar usuário, registro, tipo e data exige **objeto custom (mudança de modelo de dados)**. A auditoria do Trust Layer, se ativa, guarda prompt e resposta completos, contra o critério e P-10 | **Média** | **Escalado ao arquiteto humano (mudança de modelo de dados, seção 8).** A v1 **não** entrega esse cenário |
| R10 | Latência sem meta (P-9) | **Baixa** | Medida e reportada no QA. Sem critério de reprovação até o cliente definir N |
| R11 | Sobreposição com EPLAST-29 e com o piloto (`SFAgent2`) | **Baixa** | A v1 não toca o `SFAgent2`. Exposição como ação do agente vira demanda futura |
| R12 | Página ativa de Opportunity não medida; a página já tem um Flow embutido (`PaymentTermsOpportunity`) | **Baixa** | O build confirma a ativação antes de alterar. Componente em aba própria, sem mexer no existente |
| R13 | **Dado sintético é difícil de criar:** 16 validation rules em Opportunity (conta completa, vendedor com ID Protheus), 6 em Account, 3 em cotação e 6 em linha. Criar oportunidade em dev **dispara** o `OpportunityFlow` (cria cotação CPQ e pode submeter aprovação). Licença `Salesforce` está em 14/14 | **Média** (esforço) | Fixture que preenche toda regra ativa, só com valores fictícios. Teste de "sem permissão" com usuário existente sem o PSG, sem criar usuário novo. Esse DML é do **build/QA** na sandbox, nunca da solução |

### Riscos do assessment que tocam esta demanda

| Achado | Aplica? | Como este design lida |
|---|---|---|
| 1 (alta) automação concorrente Account/Opportunity/Order | Sim, como vizinhança | Zero DML (seção 4). Recon mapeou a ordem real em Opportunity e Account. Order não é lido |
| 2 (alta) cobertura Apex 10% | **Não** | Nenhum Apex criado ou alterado. O deploy de templates, Flows, permission sets e FlexiPage não traz classe nova para cobrir e não piora o número. O release confirma o nível de teste exigido no destino |
| 3 (média) validation rules de Order | Não | Order não é lido nem gravado |
| 4 (média) campos sem descrição | Sim | Allowlist (3.4). Componentes novos com descrição |
| 5 (média) convenção `<Classe>Test` | Não | Sem Apex |
| 6 (média) dev = qa? | Sim | R4, bloqueante para QA |
| 7 (baixa) perfil Financeiro | Não | Sem relação com o público comercial |
| 8 (baixa) 4 perfis comerciais | Sim | Público por **PSG**, nenhum perfil alterado |
| 9 (baixa) Apex em API antiga | Não | Nenhuma classe editada |
| 10 (baixa) `OrderTrigger` duplicado | Não | Order não é tocado |
| Não medido: OWD | **Medido agora** | 02-recon, 3. A restrição efetiva fica em CRUD/FLS + PSG |

---

## 7. Impacto em permissões

- **Novo:** `PS_Comercial_RascunhoIA` + `PSG_Comercial_RascunhoIA` (que inclui o padrão `EinsteinGPTPromptTemplateUser`, que exige a PSL `EinsteinGPTPromptTemplatesPsl`).
- **Nenhum perfil alterado** (achado 8). Nenhum permission set existente alterado. `PS_Comercial_ResumoClienteAgente` não é tocado.
- **Quem recebe:** o público é a pergunta 8 da análise, sem resposta. A atribuição é **manual, pós-deploy**, pela lista que o cliente der. Sem lista, ninguém recebe, e a funcionalidade fica invisível.
- **Acesso negado de verdade:** sem a custom permission, o componente não aparece. Sem o PSG, o Flow de tela recusa a execução (acesso restrito). Sem `EinsteinGPTPromptTemplateUser`, o template não roda. A leitura dos dados respeita o contexto do usuário (OWD + FLS). O FLS por perfil comercial não foi medido; o build confirma os campos da allowlist.
- **Gestor ver o rascunho do vendedor:** não existe, porque nada é gravado.

---

## 8. Escalado ao arquiteto humano (não decidido aqui)

1. **Mudança de modelo de dados para a trilha de uso** (R9, cenário Gherkin "Trilha de uso sem dado pessoal"). Para cumprir o cenário seria preciso um objeto custom de log (usuário, registro, tipo, data, modelo, sem texto). Isso é mudança de modelo de dados, gravação nova e uma decisão de retenção (P-10). **Proposta deste design:** retirar o cenário da v1 e reabrir quando o cliente e o DPO definirem retenção. A alternativa é aprovar o objeto agora, o que reabre o design e a estimativa.
2. **Troca de A por B** se a POC do passo 0 falhar (2.4). **[Rev. 1]** A POC falhou. Esta revisão **não** recomenda B (seção 12.3). Recomenda corrigir o contrato do PromptFlow, com Apex como fallback **só se o aceite autorizar** (seção 12.8).

---

## 9. O que NÃO será feito nesta demanda

- Gravar o rascunho em qualquer campo, objeto, Task, Event, nota ou arquivo.
- Enviar e-mail, mensagem ou qualquer comunicação ao cliente final.
- Gerar documento de proposta (PDF) ou alterar a Quote/cotação CPQ.
- Usar dados de Contact, Task/Event, Order/Protheus, campos custom de Opportunity e Account, catálogo ou material de marketing.
- Alterar o agente `SFAgent2` ou expor os templates como ação do Agentforce.
- LLM externo, Named Credential, Apex, LWC.
- Consolidar a automação de Opportunity e Account (achado 1), curar a descrição dos campos (achado 4), consolidar perfis (achado 8) ou configurar provedores e regiões do Einstein (R2). São decisões e demandas próprias.
- Trilha de uso em objeto custom (seção 8).
- Medição de qualidade contra o baseline do piloto (`eplast-ent-12`). Fica sem critério até a pergunta 9 da análise ser respondida.
- Qualquer ação em produção (guardrail #1).

---

## 10. Pré-condições para liberar o build

1. **R1:** autorização contratual registrada no card (seção 0.1). **Bloqueante.**
2. Aceite deste design pelo arquiteto humano, inclusive da proposta da seção 8.1 (retirar a trilha de uso da v1).
3. **Recomendado:** ciência do DPO ou da conta sobre o processamento via Einstein Trust Layer (R2). Obrigatório antes de produção.
4. Recon válido até 2026-11-18. Se o build começar depois, refazer.

Antes do QA: **R4** (dev ≠ qa) resolvido.

---

## 11. Estimativa

Estimativa original, aprovada em 2026-11-11: 36–80 h. **[Rev. 1]** Substituída pela seção 12.9.

| Bloco | Horas |
|---|---|
| POC do passo 0 (2.4) | 2–4 |
| 3 Flex templates, com iteração de prompt sobre dados sintéticos | 12–24 |
| Prompt flow da cotação (com teto de 50 linhas) | 4–8 |
| Flow de tela, custom permission, PS, PSG e FlexiPage | 6–12 |
| Dados sintéticos em dev (validation rules, cadeia do `OpportunityFlow`, cotação CPQ) | 6–14 |
| Roteiro de QA, inclusive casos adversariais, debug log e cenário de 50/200 linhas | 4–10 |
| Sessão de validação da allowlist e das regras de conteúdo com o Comercial | 2–4 |
| Documentação de entrega e passos manuais (atribuição do PSG) | 0–4 |

**O que mudou em relação à análise (50–140 h) e por quê:**
- **O teto caiu de 140 h para 80 h.** A plataforma foi decidida como nativa e declarativa. Isso tira da faixa o Apex com `<Classe>Test` a 85%, a Named Credential e a revisão LGPD de um processador novo, que eram o que puxava para 140 h.
- **O piso caiu de 50 h para 36 h** porque o recon mostrou a infraestrutura pronta na sandbox (Einstein habilitado, PSL ativa, `PromptFlow` disponível). Também porque a v1 é somente leitura, com grounding só de campos padrão e CPQ.
- **O que impede o piso de cair mais:** a criação de dado sintético contra 16 validation rules e a cadeia do `OpportunityFlow` (R13), a iteração de prompt para 3 tipos de saída e o QA adversarial de alucinação.
- **Fora da faixa:** a curadoria dos campos custom (achado 4), a trilha de uso em objeto custom (seção 8.1), a exposição no Agentforce e a decisão de provedores e regiões do Einstein. Cada um, se aprovado, soma esforço próprio.

---

## 12. Revisão 1 (2026-11-12): retorno do build, grounding Flex ↔ PromptFlow

### 12.1 Por que este design voltou

O build parou de propósito na verificação 2 da seção 2.4, como este design mandava. Os 3 `GenAiPromptTemplate` (Flex) não deployam em `sbx-eplast-dev`. Os dois falham com o mesmo erro, um para cada Flow de grounding: "O parâmetro de saída da ação `<Flow>` não corresponde". O erro se repetiu em vários deploys isolados (`04-plano-build.md`, 3.6). Tudo o que depende dos templates também ficou bloqueado: o Screen Flow, o PermissionSet, o PSG e a FlexiPage.

O build tomou duas decisões que esta revisão **aceita**, porque ficam dentro da arquitetura A (declarativa, sem DML):
- **`Opportunity_PromptFlow_DadosOportunidade`** foi criado porque o input `sobject://Opportunity` no template derrubou o servidor com NullPointerException (`04-plano-build.md`, 3.1). O template agora recebe `OpportunityId` (texto), e o Flow lê Opportunity e Account. A allowlist da seção 3.4 não mudou.
- **Get Records em modo coleção com loop de 1 item, `limit` 2 e `triggerType` `Capability`** contornam erros reais de deploy (3.2, 3.4 e 3.5 do plano). Não são SOQL em loop.

### 12.2 Diagnóstico desta revisão: o que confirmei e o que não

Não rodei deploy, nem mesmo `--dry-run`. Esta etapa não escreve na org, e o pedido desta sessão proíbe deploy. Também não tenho acesso à documentação oficial pela web nesta sessão. Por isso, tudo abaixo é evidência local ou consulta read-only à org.

| Evidência | Fonte | O que mostra |
|---|---|---|
| Exemplo oficial `Get_Event_Info` + classe `CurrentDate` | `@salesforce/templates`, que vem com o `sf` CLI do runner (o mesmo exemplo que o build usou) | O data provider devolve **uma saída chamada `Prompt`**: o campo `Prompt` da classe `Response`, marcado como `@InvocableVariable`. O template a referencia como `{!$Apex:CurrentDate.Prompt}`. O `parameterName` do provider (`Event_Type`) tem o **mesmo nome** do input do template (`Event_Type`) |
| Os 3 templates em `force-app/` | Leitura do repositório | Referenciam `{!$Flow:<Flow>.TextoOportunidade}` e `.TextoCotacao`, que são nomes de variáveis comuns, e não `.Prompt`. O `parameterName` é `recordId`, mas o input do template se chama `OpportunityId` |
| Schema oficial do Metadata API | `@salesforce/types` (`metadata.d.ts`) do `sf` CLI | `FlowStart` tem `capabilityTypes: FlowCapability[]` (`capabilityName`, mais `inputs` com `capabilityInputName`, `dataType` e `isCollection`). `FlowElementSubtype` inclui **`AddPromptInstructions`**, aplicado a um nó de Flow como o Assignment |
| Os 2 PromptFlows deployados | Leitura do XML em `force-app/` | **Nenhuma** ocorrência de `capabilityTypes` nem de `AddPromptInstructions`. O `start` só declara `triggerType` `Capability`, sem dizer a que capacidade (template) o Flow atende, e a saída é uma variável comum |
| PromptFlows na org | `FlowDefinitionView` em `sbx-eplast-dev` | 7 no total, todos com `TriggerType = Capability`. 5 são gerenciados (`OfferMgmt`, `setup_service_plan`, `sfdc_fieldservice`) e 2 são nossos. A Tooling API (`Flow`) só devolve as 2 versões não gerenciadas, então os gerenciados não servem de modelo |
| Versão de API | `sf org display` | A org está na API **68.0**. Os Flows do build declaram `apiVersion` 61.0 |
| Templates na org | `sf org list metadata -m GenAiPromptTemplate` | 0, consistente com o rollback descrito no plano (seção 4) |

**Leitura.** A conclusão da seção 3.3 do plano de build foi: "o exemplo oficial não usa `isOutput`, então uso variável comum". Essa conclusão lê o exemplo pela metade. No exemplo Apex, a saída não é "qualquer variável": é o campo `Prompt` da resposta invocável. No PromptFlow, o equivalente provável é a saída de prompt que o elemento **Add Prompt Instructions** (`elementSubtype` `AddPromptInstructions`) escreve. Ela só existe quando o Flow declara, no `start`, a capacidade (`capabilityTypes`) do template a que serve. As duas mensagens que pareciam contraditórias no 3.3 ("`$Prompt` é a única saída" e "não pode referenciar `$Prompt`") são coerentes com isso: existe uma saída de prompt reservada, e ela não se escreve com um Assignment comum. O erro "parâmetro de saída não corresponde" também é coerente: o template pede `.TextoOportunidade`, e esse nome não existe no contrato.

**Isto é hipótese com evidência forte, não fato confirmado.** A POC da seção 12.4 precisa responder:
1. o formato exato de `capabilityName` para um template Flex. Lembro de algo como `FlexTemplate://<API name do template>`, mas **não confirmei**;
2. a referência exata da saída escrita pelo Add Prompt Instructions dentro do Flow (de memória, `$Output.Prompt`) e no template (`{!$Flow:<Flow>.Prompt}`). Também **não confirmei**;
3. se um Flow de capacidade pode atender aos 3 templates ou se fica preso a um só (1:1);
4. se a dependência circular (o Flow declara o template e o template declara o Flow) deploya num pacote só ou exige duas rodadas;
5. (opcional, não bloqueia) se `SOBJECT://Opportunity`, em maiúsculas, evita a NPE do 3.1. Se evitar, não muda esta revisão: o caminho por Id já funciona.

### 12.3 Opções reavaliadas

| | **D. Corrigir o contrato do PromptFlow** (nova, escolhida) | A-UI. Criar pela UI do Prompt Builder/Flow Builder e fazer retrieve (hipótese (a) do build) | C. Apex como `templateDataProvider` (`apex://`) | B. Agentforce (`SFAgent2`) |
|---|---|---|---|---|
| Nível da doutrina | Declarativo, o mesmo já aprovado | Declarativo. É **técnica** para chegar em D, não uma arquitetura diferente | **Código** | Configuração + declarativo |
| Evidência de que funciona | Indireta e forte: schema + contrato `Prompt` do exemplo oficial (12.2) | Alta: a UI gera a estrutura que a plataforma espera, e o retrieve revela o que falta | **A mais direta**: é o único padrão com exemplo oficial completo | Não testada. A ação do agente também precisaria de grounding |
| Quem pode executar | Agente de build, por metadata | **Só humano**, porque o build não tem navegador (só o `qa` tem) | Agente `dev-apex` | Agente, mas no artefato de outra frente |
| Apex novo | Nenhum | Nenhum | 2 classes + 2 `<Classe>Test` a 85% | Nenhum |
| Interação com o que existe | Altera só os 2 PromptFlows desta demanda | Igual a D | Os testes criam Opportunity, Account e cotação, e com isso **disparam** `OpportunityTrigger`, `SBQQ.OpportunityAfter`, `OpportunityFlow` (até 22 DMLs, cotação CPQ, aprovação) e 16 validation rules. A solução não entra na cadeia do achado 1, mas **o teste entra** | O `SFAgent2` tem 4 versões de `GenAiPlannerBundle` (`SFAgent2_v1` a `_v4`), todas modificadas em 2026-11-10, construídas fora da esteira. **Está em mudança ativa** |
| Release em produção | Sem Apex, sem nível de teste a decidir | Igual a D | Deploy com Apex exige nível de teste. Com `RunLocalTests` vale a cobertura geral da org (mínimo de 75%), e a org está em **10%** (achado 2). Na prática obriga `RunSpecifiedTests` com as classes novas. É decisão de release, mas nasce aqui | Sem Apex |

**Por que não B agora.** Os motivos da seção 2.2 continuam valendo, e o recon de hoje os reforça:
- o agente está mudando fora da esteira (4 versões do bundle no mesmo dia, 2026-11-10);
- o estado da EPLAST-29 é **divergente**. Nesta branch, o `status.yaml` dela está em `backlog` e não há `03-design.md` em disco. O RAG, porém, devolve trechos de um `demandas/EPLAST-29/03-design.md` que estende o `SFAgent2`, provavelmente de outra branch. Não consigo confirmar daqui qual dos dois é o atual. Nos dois casos, B põe duas demandas no mesmo artefato (guardrail #6);
- B troca o determinismo do botão pelo roteamento do planner, sem ganho funcional para um uso que começa na própria oportunidade;
- B não elimina a dúvida de plataforma, só a troca por outra (ação de agente com grounding), também não testada nesta org.

**Por que C não é a escolha principal.**
- Nenhum dos 5 gatilhos da doutrina para descer a Apex existe aqui: são 3 leituras simples, sem DML, sem volume, sem rollback e sem callout. O único motivo seria limitação de plataforma, e ela **ainda não foi demonstrada**: o build testou um contrato incompleto (12.2).
- Apex novo bem testado não piora a cobertura de 10%. Uma classe a 85% até sobe a média um pouco. O custo real está em dois pontos. Primeiro, o fixture de teste atravessa a cadeia de automação de Opportunity e CPQ (achado 1, R13, e o risco de CPU do achado SOMOSAGILITY-10, agora **no teste**). Segundo, o release de produção passa a depender de uma decisão de nível de teste numa org a 10%.
- C continua sendo o caminho com **maior chance de deployar na primeira tentativa**. Por isso fica como **fallback explícito**, que vale só se o aceite deste gate o autorizar (12.8). O build não desce para Apex em silêncio.

### 12.4 Decisão (recomendação para o aceite)

**Opção D: manter a arquitetura A e corrigir o contrato dos PromptFlows. A UI (A-UI) entra como desempate dentro da mesma POC. C fica como fallback pré-autorizável. B fica fora.**

**POC com teto de 4 h**, em `sbx-eplast-dev`. O agente de build trabalha numa pasta temporária fora de `force-app/`, como já fez no plano.
1. **Por metadata (até 2 h).** Usar 1 template (`Rascunho_Followup_Comercial`) + `Opportunity_PromptFlow_DadosOportunidade`:
   - o `start` ganha `capabilityTypes`, que aponta para o template, com um input cujo `capabilityInputName` tem o mesmo nome do input do template (`OpportunityId`);
   - o Assignment final passa a ser `AddPromptInstructions` e escreve na saída de prompt;
   - o template referencia `.Prompt`, e o `parameterName` passa a ter o mesmo nome do input da capacidade;
   - `apiVersion` 68.0 nos dois;
   - validar primeiro com `--dry-run`, depois com deploy real;
   - cada tentativa fica registrada com a mensagem de erro, sem tentativa às cegas além das combinações das perguntas 1 a 4 da seção 12.2.
2. **Pela UI (se o passo 1 não fechar).** Uma pessoa de delivery com acesso a Setup faz isto:
   - cria o template como rascunho no Prompt Builder;
   - cria um *Template-Triggered Prompt Flow* no Flow Builder, vinculado a esse template;
   - salva os dois.

   O agente então faz o retrieve dos dois e compara com `force-app/`. A diferença é o contrato que faltava, e ele passa a valer para os outros 2 templates. Esse passo é trabalho humano, não um gate novo. Só usar dado sintético (P-8).
3. **Critério de sucesso:**
   - o template deploya;
   - o Preview do Prompt Builder (ou a execução pelo Screen Flow) resolve os blocos de oportunidade e de cotação com dado sintético;
   - as verificações 1 e 3 da seção 2.4 ficam respondidas.
4. **Se 1 e 2 falharem:**
   - se o aceite marcou a autorização de C na seção 12.8, o build segue para C (seção 12.5, quadro C);
   - se não marcou, o build para e volta ao design de novo;
   - nos dois casos, o resultado da POC é registrado em `04-plano-build.md`.

### 12.5 Componentes: o que muda

**Caminho D (principal)**

| Componente | Situação hoje | Mudança |
|---|---|---|
| `IA_Rascunho_Comercial` (CustomPermission) | Deployado | **Nenhuma** |
| `Opportunity_PromptFlow_DadosOportunidade` (Flow PromptFlow) | Deployado | **Alterar:** `capabilityTypes` no `start`, saída por `AddPromptInstructions`, input com o mesmo nome do input da capacidade, `apiVersion` 68.0. Ficam iguais: consulta, allowlist, modo coleção + loop e zero DML |
| `Opportunity_PromptFlow_CotacaoPrimaria` (Flow PromptFlow) | Deployado | **Alterar**, igual ao anterior. Ficam iguais: teto de 50 linhas, ordenação, texto "sem cotação" e zero DML |
| `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade` (GenAiPromptTemplate Flex) | Só no repositório | **Alterar:** referências `.Prompt`, `parameterName` com o mesmo nome do input. Ficam iguais: instruções de conteúdo (3.5), modelo e input `OpportunityId` |
| `Opportunity_Screen_RascunhoComercial`, `PS_Comercial_RascunhoIA`, `PSG_Comercial_RascunhoIA`, aba da `Opportunity_Record_Page` | Só no repositório | Sem mudança de conteúdo. O `PS` só muda se os Flows forem renomeados (abaixo) |

**Condicional em D: capacidade 1:1 com o template** (pergunta 3 da seção 12.2). Se um Flow de capacidade não puder atender a 3 templates, **a decisão fica tomada aqui**, para não voltar ao gate por isso:
- 1 Flow de grounding por template: `Opportunity_PromptFlow_RascunhoProposta`, `Opportunity_PromptFlow_RascunhoFollowup` e `Opportunity_PromptFlow_ArgumentosComerciais`;
- cada um monta os blocos de oportunidade e de cotação com a mesma lógica dos 2 Flows atuais. "Um Flow, um propósito" continua valendo: o propósito passa a ser "o grounding do template X";
- os 2 Flows atuais são **depreciados** (desativados e removidos em dev por `destructiveChanges`, pelo build) e saem do `PS`;
- **6 Flows (2 por template) ficam descartados**: o dobro de componentes com a mesma lógica repetida.

**Caminho C (fallback, só com autorização na seção 12.8)**

| Componente | Mudança |
|---|---|
| `OpportunityRascunhoDadosProvider` + `OpportunityRascunhoDadosProviderTest` (Apex, novo) | `@InvocableMethod` com `Request.OpportunityId` e `Response.Prompt`. `with sharing`, `WITH USER_MODE`, mesma allowlist, zero DML. Teste a ≥85% |
| `OpportunityRascunhoCotacaoProvider` + `OpportunityRascunhoCotacaoProviderTest` (Apex, novo) | Igual ao anterior, para a cotação primária e até 50 linhas. Uma query para as linhas, sem SOQL em loop |
| 3 templates | `templateDataProviders` passa para `apex://`. Referências `{!$Apex:<Classe>.Prompt}` |
| 2 PromptFlows deployados | **Depreciar** (desativar e remover em dev) |
| `PS_Comercial_RascunhoIA` | **Alterar:** `classAccesses` para as 2 classes. Os `flowAccesses` dos PromptFlows saem |
| `IA_Rascunho_Comercial`, Screen Flow, PSG, FlexiPage | Sem mudança |

Fixture dos testes C:
- preenche toda validation rule ativa de Opportunity, Account, cotação e linha (doutrina, achado SOMOSAGILITY-10, R13);
- não usa `SeeAllData=true`;
- se precisar desligar os triggers do CPQ no teste, o build **confirma na org** que o mecanismo existe antes de usá-lo. Este design não o confirmou.

### 12.6 O que NÃO muda

- **A decisão de arquitetura A:** Prompt Builder Flex + Screen Flow na Opportunity, somente leitura, zero DML, sem LWC, sem Named Credential, sem tocar o `SFAgent2`.
- Seções 3.4 (allowlist), 3.5 (regras de conteúdo), 4 (conflito de automação, que segue fora do evento), 5 (governador: no máximo 50 linhas e 0 DML) e 7 (permissões por PSG, nenhum perfil alterado). A seção 9 (o que não será feito) também não muda, exceto o item "Apex", que pode cair **só** pelo caminho C autorizado.
- `IA_Rascunho_Comercial`, já na org, vale em todos os caminhos.
- **Os 2 PromptFlows já deployados: correção à premissa de que "continuam valendo em qualquer opção".** A lógica de leitura deles continua valendo em D e serve de especificação em C. Os componentes em si mudam:
  - em D, são **alterados** (contrato de capacidade);
  - no condicional 1:1 de D, são **substituídos** por 3 Flows com a mesma lógica;
  - em C, são **depreciados**.

  Nenhum dos caminhos joga fora o trabalho de consulta: allowlist, `relatedRecords`, modo coleção e teto de 50.
- Pendências que esta revisão não resolve: **R1** (Onda 3 não contratada, reforçado na seção 0 do plano de build), **R4** (dev = qa?) e **R9** (trilha de uso).

### 12.7 Riscos novos ou alterados

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R8 | Capacidade de plataforma não verificada | **Materializado** | Seções 12.2 e 12.4 |
| R14 | **O diagnóstico de 12.2 estar errado** e D também falhar (limitação real para Flow custom como provider nesta release) | **Média** | POC com teto de 4 h e 2 técnicas (metadata e UI). Depois disso, C, se autorizado, ou volta ao design. Não há uma terceira rodada de tentativa às cegas |
| R15 | **Fallback C:** o fixture de teste dispara a cadeia de Opportunity/CPQ (CPU e validation rules), e o release de produção depende de nível de teste numa org a 10% | **Média** (só se C for acionado) | Fixture completo, `RunSpecifiedTests` com as classes novas no release, medição de CPU do teste no build. Se passar de ~70% de um limite, volta ao design (doutrina) |
| R16 | **Capacidade 1:1:** 3 Flows em vez de 2 e depreciação em dev | **Baixa** | Decidido em 12.5. Sem impacto em produção, onde nada foi deployado |
| R17 | **Ordem de deploy:** dependência circular Flow ↔ template | **Baixa** | A POC responde (pergunta 4). Se exigir duas rodadas, o plano de build e o release registram a ordem |
| R18 | **`SFAgent2` em mudança fora da esteira** (4 versões do bundle em 2026-11-10) e estado da EPLAST-29 divergente entre branch e RAG | **Baixa** para este design (B fora); **alta** para quem for expor os templates no agente depois | Registrado para a demanda futura de exposição no Agentforce (R11). Este design não toca o agente |

R7 (alucinação) e R13 (dado sintético) não mudam. R13 só pesa mais em C (R15).

### 12.8 O que o aceite deste gate precisa decidir

1. **Aceitar D + POC de 4 h** (12.4), inclusive a decisão condicional 1:1 (12.5).
2. **[ ] Autorizar C como fallback** se a POC falhar nas duas técnicas. Sem essa marca registrada no card ou no comentário do gate, o build para e volta ao design em vez de descer a Apex. Esta revisão **recomenda autorizar**, porque C é contido (2 classes de leitura, sem DML) e evita uma terceira volta ao gate. Mesmo assim, a decisão de reabrir o "zero Apex" é humana.
3. **Quem faz o passo de UI** (12.4, passo 2): uma pessoa de delivery com acesso a Setup em `sbx-eplast-dev`.
4. **R1 continua aberto:** o plano de build pede de novo autorização escrita para a Onda 3 antes do gate de build.

### 12.9 Estimativa revisada

**Estimativa de esforço:** 40–92 h

Os blocos são os da seção 11, mais o que esta revisão acrescenta:

| Bloco novo | Horas |
|---|---|
| POC de correção do contrato (metadata + UI, teto fixo) | 2–4 |
| Retrabalho dos 2 PromptFlows e dos 3 templates (ou 3 Flows novos e depreciação, no condicional 1:1) | 2–6 |
| Revisão de design (esta) e reconferência do Screen Flow e do PS depois da mudança | 0–2 |

**O que mudou em relação à estimativa aprovada (36–80 h) e por quê:**
- **O piso subiu 4 h** (POC + retrabalho mínimo). Parte do build já foi gasta, mas não sai da faixa, porque os blocos de templates, Flow de tela e permissões **não fecharam**: só existem no repositório.
- **O teto subiu 12 h**: retrabalho no pior caso de D (3 Flows novos + depreciação) e reconferência de tudo o que depende dos templates.
- **Fora da faixa: o fallback C.** Se for acionado, soma **14–24 h** (2 classes, 2 testes a 85% com fixture que atravessa 16 validation rules e a cadeia CPQ, ajuste de PS e depreciação dos Flows), e o teto vai para ~116 h. Fica fora porque só acontece se D falhar **e** o aceite autorizar.
- Continuam fora da faixa os mesmos itens da seção 11: curadoria de campos, trilha de uso, Agentforce e provedores do Einstein.

---

Design revisado (Revisão 1) e pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build de novo.
