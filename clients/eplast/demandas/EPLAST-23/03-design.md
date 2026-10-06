# Design — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Autor:** arquiteto (agente) · **Data:** 2026-10-06 · **Base:** `01-analise.md` (aprovada em 2026-10-06 por Carlos Sordi) + `02-recon.md` (coleta de 2026-10-06 em `sbx-eplast-dev`)
**Tipo:** projeto · **Complexidade:** M (mantida da análise)

---

## 0. Antes de ler: o que foi decidido, o que é proposta e o que segue em aberto

O gate da análise aprovou escopo e critérios de aceite. **As perguntas bloqueantes A1–A5 e as premissas P1–P8 não têm resposta registrada** em `gates.md` nem em outro arquivo da demanda. Este design trata cada uma assim:

| Item | Situação neste design |
|---|---|
| **A1** — tipo de implementação | **Resolvido em parte pelo recon.** Não existem três produtos distintos: na v67 tudo é Agent → Topic → Action. O design **propõe** agente de funcionário + Flow + Apex (seção 1). Essa é a decisão arquitetural central e **precisa do aceite explícito do arquiteto humano**. Não a trato como fechada. |
| **A2** — categorias e campos | **Em aberto (negócio).** Proponho um conjunto mínimo usando só campos confirmados (seção 2.4) e marco como proposta. Ficam abertas duas perguntas: o que é "ocorrência" na Eplast (Case ou `SalesReturn__c`?) e qual campo de crédito vale. |
| **A3** — volume e renderização | **Em aberto (negócio).** A arquitetura usa "Top N + total" (estrutural). Os valores de N são parâmetros **a definir**. Os números na seção 2.4 são placeholders. |
| **A4** — segregação | **Resolvido em parte pelo recon.** O OWD interno é público e não há territórios, então o controle real é OLS/FLS, que o design respeita em tempo de execução. **Em aberto:** confirmar que produção tem o mesmo OWD, e decidir se o perfil comercial deve ou não ler Case (ver risco R3). |
| **A5** — síntese de atenção | **Em aberto (negócio).** O design fixa a *forma*: regras determinísticas calculadas em código, e o LLM só redige a partir delas. Os *critérios e limiares* ficam como parâmetros a definir. |
| **P6** — LGPD / mascaramento | **Em aberto (compliance). Severidade alta.** Ver R1. |

A arquitetura proposta foi pensada para que A2, A3 e A5 virem **parâmetros**, não redesenho. Mesmo assim, **o build não deve começar** sem resposta para A2 (objeto de ocorrência), A3 (valores de N), A5 (limiares) e P6 (dados pessoais no LLM). Do contrário, o builder vai inventar regra de negócio.

---

## 1. Decisão e justificativa

### 1.1 Tipo de agente: **agente de funcionário (Agentforce Employee Agent)**, não Service Agent

O critério de aceite "informações sem permissão não são expostas" exige que as consultas rodem **como o usuário logado**. O Service Agent roda sob um usuário de agente dedicado. Com ele, o resumo mostraria o que o *agente* vê, não o que o *usuário* vê, e o critério seria violado por construção. A org tem licenças de Service Agent (`AgentforceServiceAgentUserPsl`), mas elas **não devem ser usadas** aqui.

### 1.2 Implementação, nível a nível (configuração → declarativo → código)

| Peça | Nível escolhido | Por que não o nível acima |
|---|---|---|
| Agente, Topic, instruções, guardrails de linguagem ("não inventar", "não escrever", "sinalizar categoria vazia") | **Configuração** (Agent Builder) | — (é o nível mais alto) |
| **Identificar a conta** (nome, CNPJ `CompanyDocument__c` ou `ProtheusId__c`; lista candidatos se houver mais de um) | **Configuração, se houver ação padrão de identificação por nome no catálogo do Agent Builder; senão, Flow** autolaunched em contexto de usuário | O recon **não conseguiu confirmar** quais ações padrão existem (elas não são metadata listável). O builder verifica no Agent Builder primeiro. Se a ação padrão não buscar por CNPJ/Protheus ID nem devolver lista de candidatos, desce para Flow: `Get Records` com filtro em `Name`, `CompanyDocument__c` e `ProtheusId__c`, ordenação e limite. Isso não exige código. |
| **Consolidar as categorias** (Visão geral, Contatos, Negociações, Pedidos, Ocorrências) e **calcular os sinais de atenção** | **Código: uma Apex invocável** | Ver justificativa abaixo. |
| **Redação final do resumo** | **Configuração**: instruções do Topic sobre a saída estruturada da action | Prompt Template à parte não é necessário no v1. O LLM do planner redige a partir da saída estruturada. Se a redação ficar inconsistente nos testes, o próximo passo é um Prompt Template (ainda declarativo) e não mais código. |

**Por que a consolidação desce para Apex e não fica em Flow.** Cada motivo abaixo vem de um critério de aceite ou de um achado do recon:

1. **Distinguir "sem registros" de "sem acesso".** O recon mostrou que o perfil comercial ativo (`Comercial - Analista`) **não lê Case**. Um Flow em contexto de usuário falha (fault) ao consultar um objeto sem acesso, e o caminho de falha não diferencia bem a causa. Já a FLS por campo, em Flow, é tudo ou nada. Em Apex, `Schema.sObjectType.Case.isAccessible()` + `WITH USER_MODE` + `Security.stripInaccessible(AccessType.READABLE, …)` resolvem isso de forma determinística: a categoria vem como `SEM_ACESSO` e os campos sem FLS são removidos, não mostrados vazios. Dizer "sem ocorrências" a quem não tem acesso seria uma conclusão inventada, o que viola a regra "sem inventar informações".
2. **"N de M registros" (estratégia de A3).** Mostrar o top N e o total exige `COUNT()` por categoria. Flow não tem agregação sem carregar todos os registros (custo e limite de linhas). Em Apex são 2 queries baratas por categoria.
3. **Síntese de atenção determinística (A5).** Para cumprir "basear conclusões nos registros", os pontos de atenção são *calculados* (ex.: oportunidade aberta com `CloseDate` dentro de X dias, caso aberto com `Priority = 'High'`) e devolvidos como sinais já prontos, com o ID do registro de origem. O LLM só redige. Fazer isso em Flow com 5 coleções, datas relativas e sinalização por registro é possível, mas fica frágil e não testável por unidade.
4. **Evidência testável do critério de permissão.** Teste Apex com `System.runAs` em usuários com e sem acesso prova o CA "sem permissão não expõe" de forma automatizada. Flow não tem equivalente.

### 1.3 Leitura pura: sem conflito de automação
**As automações existentes em Account, Opportunity e Order (triggers custom + triggers do CPQ `SBQQ` + Flows AfterSave/BeforeSave, ver recon §4) NÃO são acionadas por esta solução, porque ela não faz DML nenhuma.** Não há risco de ordem de execução. Isso vale **só** enquanto a solução continuar sendo leitura pura. Qualquer pedido futuro de "registrar que o resumo foi gerado" (auditoria em registro, Task etc.) reabre esse risco e precisa de novo design.

---

## 2. Componentes

### 2.1 A criar

Todos são **novos**. O recon confirmou que nenhum deles existe e que não há nenhum Agent, Topic ou Action na org. Os nomes seguem a skill `padrao-entrega`, porque o `CLAUDE.md` da Eplast não define convenção própria.

| Tipo (metadata) | API name proposto | Papel |
|---|---|---|
| Agent (`Bot` + `BotVersion` + `GenAiPlannerBundle`) | `Eplast_Assistente_Comercial` | Agente de funcionário. Ponto de entrada no painel do Agentforce no Lightning. |
| Topic (`GenAiPlugin`) | `ResumoCliente` | Escopo: "resumir cliente". Instruções: só leitura; sempre exibir as 6 seções; nunca deduzir; pedir esclarecimento se houver mais de 1 conta; citar a referência de cada item. |
| Agent Action (`GenAiFunction`) | `BuscarCliente` | Envolve a ação padrão de identificação (se servir) ou o Flow abaixo. |
| Flow autolaunched (contexto de usuário) | `Account_AgentAction_BuscaCliente` | **Só se a ação padrão não servir.** Entrada: termo. Saída: lista de até N candidatos (`Id`, `Name`, `CompanyDocument__c`, `ProtheusId__c`, cidade de cobrança, `Inactive__c`), com CNPJ normalizado (sem pontuação). |
| Agent Action (`GenAiFunction`) | `ResumirCliente` | Envolve a Apex abaixo. |
| Classe Apex (`@InvocableMethod`, `with sharing`, API v67) | `CustomerSummaryService` | Recebe o `AccountId` e devolve uma estrutura por categoria: `status` (`OK` / `VAZIO` / `SEM_ACESSO`), `totalRegistros`, lista top N (campos + `Id` para o link) e `sinaisAtencao[]` (regra, registro de origem). Todas as queries usam `WITH USER_MODE` + `stripInaccessible`, sem SOQL em loop. |
| Classe de teste | `CustomerSummaryServiceTest` | Cobertura ≥ 85%. Cenários: os 5 Gherkin da análise, `runAs` com usuário sem Case, campo sem FLS, conta inexistente, categoria vazia e prova de zero DML (`Limits.getDmlStatements() == 0`). Sem `SeeAllData`. |
| Permission Set | `PS_Comercial_ResumoClienteAgente` | Concede `CustomerSummaryService` (Apex class access) e o Flow, se existir. **Não concede acesso a objeto nem a campo**: cada usuário vê só o que já via. |

**Parametrização (A3/A5).** Os valores N por categoria, as janelas de "recente" e os limiares de atenção ficam como **constantes nomeadas** no topo de `CustomerSummaryService`, documentadas. Se o negócio quiser mudar esses valores sem deploy, a alternativa é um Custom Metadata Type. Isso **cria um tipo novo de metadata** e, por isso, deixo para o arquiteto humano decidir; não decido sozinho.

### 2.2 A alterar
**Nenhum componente existente.** Não se altera objeto, campo, Flow, trigger, classe, validation rule, layout nem perfil.

### 2.3 A depreciar
Nenhum.

### 2.4 Conteúdo por categoria. **PROPOSTA, depende de A2/A3/A5.**
Só campos confirmados no recon. Os números entre `⟨ ⟩` são **placeholders a definir pelo negócio**, não premissas.

| Categoria | Objeto | Campos propostos | Seleção proposta |
|---|---|---|---|
| Visão geral | `Account` | `Name`, `CompanyDocument__c`, `ProtheusId__c`, `Type`, `Rating`, `Industry`, `Inactive__c`, `OwnerId` (nome), `ParentId` (nome), `LastActivityDate`. **Campo de crédito: em aberto**, porque existem `AvailableCreditLimit__c` e `AvailableCreditLimitt__c` com o mesmo rótulo | 1 registro |
| Contatos | `Contact` | `Name`, `Title`, `Email`, `Phone`, `MobilePhone`, `WhatsApp__c` **(depende de P6)** | top ⟨N⟩ por `LastActivityDate`/`LastModifiedDate` + total |
| Negociações | `Opportunity` | `Name`, `StageName`, `Amount` (com `CurrencyIsoCode`, org multimoeda), `CloseDate`, `Probability`, `Type`; fechadas recentes com `IsWon`/`Loss_Reason__c` | abertas: top ⟨N⟩ por `CloseDate` asc + total; fechadas nos últimos ⟨D⟩ dias: top ⟨N⟩ |
| Pedidos | `Order` | `OrderNumber`, `Status`, `EffectiveDate`, `TotalAmount`, `DeliveryDate__c` | top ⟨N⟩ por `EffectiveDate` desc + total |
| Ocorrências | `Case` **ou** `SalesReturn__c`: **em aberto (A2)** | Case: `CaseNumber`, `Subject`, `Priority`, `Status`, `CreatedDate`. Aberto = `IsClosed = false` (New, On Hold, Escalated, conforme `CaseStatus`) | abertos: todos até ⟨N⟩ + total; fechados nos últimos ⟨D⟩ dias: top ⟨N⟩ |
| Síntese de atenção | calculada | Exemplos de regra **a confirmar**: oportunidade aberta com `CloseDate` ≤ hoje + ⟨X⟩ dias; oportunidade aberta com `CloseDate` vencida; caso aberto `Priority = 'High'`; caso `Escalated`; pedido em `Liberacao Financeiro` há mais de ⟨Y⟩ dias | cada sinal com o `Id` da origem |

**Referências (P8):** cada item sai com o `Id` do registro, e as instruções do Topic pedem link para o registro. Se o painel do Agentforce renderiza link clicável ou só texto, isso será validado no build. O fallback é nome + número (`OrderNumber`, `CaseNumber`).

## 3. Limites de governador e escala
- **SOQL por execução:** cerca de 1 (Account) + 2 por categoria (top N + `COUNT()`) × 4 ≈ **9–11 queries**, frente a um limite de 100. Nada em loop.
- **Linhas:** limitadas por `LIMIT ⟨N⟩`. `COUNT()` conta 1 linha por query para fins de limite.
- **DML:** zero, provado em teste.
- **Tamanho da resposta para o LLM:** controlado pelo top N. É o principal motivo para não aceitar "mostrar todos" (P7). Volumes de produção são **desconhecidos** (sandbox vazia), então os valores de N devem ser calibrados com o negócio.
- **Seletividade:** a busca por `CompanyDocument__c` e `ProtheusId__c` usa External IDs (indexados). A busca por `Name` com `LIKE '%termo%'` não é seletiva em base grande. É aceitável para consulta interativa de 1 usuário, mas com risco de lentidão se Account tiver centenas de milhares de registros (volume desconhecido).

## 4. Impacto em permissões
- **Novo:** `PS_Comercial_ResumoClienteAgente`, que só dá acesso à classe e ao Flow. Nenhum acesso a dado.
- **Uso do agente:** o usuário final precisa da permissão/PSL de uso de agente de funcionário. **O recon não identificou com certeza qual PS padrão concede isso nesta org** (recon §6.3). O build confirma no Setup e documenta antes de atribuir. Não cito um nome não confirmado.
- **Quem constrói:** `AgentforceDeveloperAndAdminTools` / `AgentPlatformBuilder` (confirmados) para o usuário de build na sandbox.
- **Público-alvo:** `Comercial - Analista` (4 ativos) e, a confirmar, `Financeiro` (1). **Nenhum dos dois lê Case** (ver R3). Esta demanda **não altera** acesso a Case.

## 5. Riscos técnicos

| # | Risco | Severidade | Mitigação / quem decide |
|---|---|---|---|
| R1 | **LGPD: dado pessoal enviado ao LLM.** E-mail, telefone e WhatsApp de contato saem da org para o provedor de modelo via Einstein Trust Layer. O recon não confirmou a configuração de mascaramento (recon §6.4). A demanda pede "informações de contato disponíveis". | **Alta** | **Pendência P6 com compliance da Eplast antes do build.** Alternativa segura até a resposta: devolver só nome e cargo, mais o link para o contato. |
| R2 | **A1–A5 sem resposta humana registrada.** O builder precisaria inventar regra de negócio (N, janelas, limiares, objeto de ocorrência). | **Alta** | Não iniciar o build sem as respostas da seção 7. O design já isola esses pontos como parâmetros. |
| R3 | **Perfil comercial ativo não lê Case.** Para o público principal, "Ocorrências" sempre virá como "sem acesso". Isso é correto do ponto de vista técnico, mas pode frustrar a expectativa de negócio. | **Média** | O design exibe "sem acesso" (≠ "sem registros"). Conceder Read em Case é **decisão de negócio/segurança fora desta demanda**. |
| R4 | **Pré-requisitos de plataforma não confirmados:** Agentforce para funcionários ligado no Setup, Data Cloud configurado, catálogo de ações padrão. | **Média** | Primeiro passo do build: checar no Setup. Se faltar algo, parar e escalar. Ativar recurso de plataforma é decisão do cliente. |
| R5 | **Custo de consumo** (créditos/requests por conversa) desconhecido. | **Média** | Confirmar o modelo comercial com a Eplast antes do go-live. Fora da esteira técnica. |
| R6 | **Alucinação na síntese**: o LLM pode afirmar algo não suportado pelos dados. | **Média** | Sinais calculados em Apex; instrução no Topic de redigir apenas a partir de `sinaisAtencao`; roteiro de QA com casos negativos. Risco residual inerente a LLM. |
| R7 | **Sandbox vazia**: QA não tem dados para homologar, e volume real é desconhecido. | **Média** | O build/QA precisa de massa sintética criada **na sandbox** (nunca dado real, guardrail #2), o que exige alinhar com o humano antes de qualquer DML de massa de teste. |
| R8 | **`sbx-eplast-dev` aponta para instância "qa"** (assessment, achado 6). Build e QA podem estar no mesmo ambiente. | **Média** | Confirmar com o cliente antes do build (guardrail #6). |
| R9 | Busca por nome não seletiva em base grande. | Baixa | Prioridade para CNPJ/Protheus ID nas instruções; `LIMIT` nos candidatos. |
| R10 | Org com cobertura Apex de 10% (assessment). | Baixa | Código novo com cobertura ≥ 85% própria. Não piora o agregado. Não resolve o problema da org (fora de escopo). |

## 6. O que NÃO será feito nesta demanda
- Nenhuma escrita: sem log de resumo em registro, sem Task, sem campo de "último resumo". Uma eventual auditoria de LGPD (gap 14 da análise) seria outra demanda.
- Nenhuma mudança de modelo de dados: sem campo nem objeto novo de negócio. Se o negócio pedir parametrização via Custom Metadata Type, isso volta ao arquiteto humano.
- Nenhuma alteração de perfil, OWD ou acesso a Case.
- Alertas proativos (oportunidade parada, cliente em risco): são a **Onda 2** do contrato, não esta demanda.
- Atividades (Task/Event), cotações (`Quote`/`SBQQ__Quote__c`), arquivos e `EconomicGroup__c` ficam fora do resumo, salvo se A2 incluir.
- Service Agent / canal externo (WhatsApp, site) e grounding via Data Cloud/RAG.
- Limpeza dos campos de crédito duplicados e das automações concorrentes do assessment.
- Qualquer ação em produção.

## 7. Pendências que precisam de resposta humana antes do build

| # | Pergunta | Para quem | Bloqueia |
|---|---|---|---|
| D1 | Aceita **agente de funcionário + Flow (busca) + Apex (consolidação)** como arquitetura? (A1) | Arquiteto humano (este gate) | Tudo |
| D2 | "Ocorrência" é `Case`, `SalesReturn__c` ou os dois? Algum desses é usado de fato em produção? (A2) | Negócio Eplast | `CustomerSummaryService` |
| D3 | Lista final de campos por categoria. Qual campo de crédito vale (`AvailableCreditLimit__c` × `AvailableCreditLimitt__c`)? (A2) | Negócio Eplast | idem |
| D4 | Valores de N por categoria e janelas de "recente" (A3/P3/P7) | Negócio Eplast | idem |
| D5 | Critérios e limiares exatos da síntese de atenção (A5/P4) | Negócio Eplast (comercial + atendimento) | idem |
| D6 | Pode enviar e-mail, telefone e WhatsApp de contato ao LLM? Há mascaramento obrigatório? (P6) | Compliance/DPO Eplast | Categoria Contatos |
| D7 | Produção tem o mesmo OWD público da sandbox? Há regra de segregação que não está em metadata? (A4/P5) | Admin Eplast | Validação do CA de permissão |
| D8 | Agentforce para funcionários e Data Cloud estão ativos e o consumo está contratado? | Eplast (admin + comercial) | Início do build |
| D9 | `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas? | Eplast / BASIS | Build e QA |

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
