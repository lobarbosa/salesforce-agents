# Entrega — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Autor:** doc (agente) · **Data:** 2026-10-06

---

## Resumo em uma frase

Uma base técnica (scaffold Apex) foi validada e pronta para integração, mas a funcionalidade de resumo inteligente de cliente não foi implementada — ela aguarda 9 decisões de negócio, compliance e ambiente (D1–D9) sem resposta até esta data.

---

## O que foi entregue, em linguagem de negócio

**Isto não é a feature descrita em `demanda.md`.** O que foi entregue é infraestrutura:

- **Assinatura pública de um serviço Apex** (`CustomerSummaryService.resumirCliente`) que recebe o ID de uma conta e está pronto para consolidar informações de contatos, negociações, pedidos e ocorrências. A assinatura foi validada em testes unitários (100% de cobertura de código).
- **Permission Set padrão** (`PS_Comercial_ResumoClienteAgente`) que permite aos usuários comerciais acessar este serviço, sem alterar seu acesso a dados.

Nenhuma das 6 categorias do resumo (Visão geral, Contatos, Negociações, Pedidos, Ocorrências, Síntese) foi implementada. O serviço, hoje, lança uma exceção explícita para qualquer entrada válida, informando que depende de decisões ainda não respondidas. Não existe Agent, Topic nem Flow do Agentforce na org — não há ponto de entrada para um usuário solicitar o resumo em linguagem natural.

**Nenhum dos 8 critérios de aceite de `demanda.md` é satisfeito ou testável hoje.** O que pode ser verificado é apenas o comportamento técnico do scaffold (que a exceção é lançada, que não há leitura de dados, que o acesso segue as regras de permissão).

---

## Componentes técnicos criados/alterados, com API names

### Criados (novos)

| Tipo | API Name | Arquivo | Propósito |
|---|---|---|---|
| Classe Apex | `CustomerSummaryService` | `force-app/main/default/classes/CustomerSummaryService.cls` | Serviço invocável que consolida dados de cliente. Hoje, lança `CustomerSummaryPendingDecisionException` para qualquer entrada bem formada, bloqueando até que as decisões de negócio (D2–D6) sejam respondidas. |
| Classe Apex (teste) | `CustomerSummaryServiceTest` | `force-app/main/default/classes/CustomerSummaryServiceTest.cls` | 5 cenários de teste unitário, todos com sucesso (100% de cobertura de `CustomerSummaryService`). Provam que o scaffold não faz SOQL/DML, que a exceção é lançada corretamente, e que o comportamento é determinístico independente do perfil de usuário. |
| Permission Set | `PS_Comercial_ResumoClienteAgente` | `force-app/main/default/permissionsets/PS_Comercial_ResumoClienteAgente.permissionset-meta.xml` | Concede apenas acesso à classe Apex acima. Não concede acesso a objeto nem a campo — cada usuário continua vendo exatamente o que já via. |

### Alterados

Nenhum componente existente foi alterado.

### Removidos

Nenhum componente foi removido.

---

## Como funciona

Qualquer chamada bem formada ao método `CustomerSummaryService.resumirCliente(List<CustomerSummaryRequest>)` devolve a seguinte resposta:

```
Exception: CustomerSummaryPendingDecisionException
Message: "Resumo de cliente bloqueado. Aguardando decisões de negócio (D2–D6, vide design.md seção 7):
- D2: Qual objeto é 'Ocorrência' (Case, SalesReturn__c ou ambos)?
- D3: Lista final de campos por categoria?
- D4: Valores de N (top-N) por categoria e janelas de 'recente'?
- D5: Critérios e limiares da síntese de atenção?
- D6: Pode enviar e-mail/telefone/WhatsApp de contato ao LLM (LGPD)?"
```

**Comportamento hoje:**

1. Valida entrada:
   - Lista vazia → devolve lista vazia, sem exceção
   - `accountId` nulo → lança `IllegalArgumentException`
   - Lista com um ou mais requests válidos → lança `CustomerSummaryPendingDecisionException` (bloqueio citado acima)

2. Zero SOQL, zero DML — prova comprovada em teste unitário com `Limits.getDmlStatements() == 0` e `Limits.getQueries() == 0`.

3. Executa sem alterar estado da org nem dos registros de cliente.

**O que não funciona (porque não existe):**
- Identificação de conta por nome (Flow `Account_AgentAction_BuscaCliente`): não construído
- Agent de funcionário Agentforce, Topic e instruções: não construídos
- Consolidação de contatos, negociações, pedidos, ocorrências ou síntese de atenção: bloqueada por D2–D6

---

## Configuração pós-deploy (para quando o deploy em QA acontecer)

### Passos obrigatórios

1. **Atribuir Permission Set** `PS_Comercial_ResumoClienteAgente` aos usuários de teste em `sbx-eplast-qa` que vão validar o scaffold. A atribuição não muda o acesso deles a dados — apenas permite que executem a classe `CustomerSummaryService`.

2. **Comunicar ao time de QA** que o comportamento esperado deste componente é lançar a exceção de bloqueio citada acima para qualquer `accountId` válido. **Isso é correto, não uma falha a investigar.**

3. **NÃO publicar nem ativar nada de Agentforce** (Agent, Topic, Flow) com este deploy — nenhum desses componentes faz parte do pacote entregue, e nenhum existe na org. Não há ponto de entrada para o usuário final usar.

4. **NÃO homologar critérios de aceite** da demanda a partir deste deploy — eles continuam não testáveis (ver `05-testes.md`). O scaffold não implementa a funcionalidade, apenas a base técnica dela.

### Passos futuros (quando D2–D6 forem respondidos)

Quando as 9 decisões de negócio, compliance e ambiente forem respondidas e registradas:

1. Implementar as 6 categorias no corpo de `CustomerSummaryService.resumirCliente` — a assinatura pública não precisa mudar.
2. Construir o Flow `Account_AgentAction_BuscaCliente` (busca de conta por nome/CNPJ/ID Protheus).
3. Configurar Agent, Topic e instruções no Agentforce.
4. Atribuir `PS_Comercial_ResumoClienteAgente` a usuários reais (não apenas de QA).
5. Testar os 5 cenários Gherkin de `01-analise.md` de forma completa (interface, dados, permissões).
6. Repetir o ciclo completo de build → qa → release com conteúdo real.

---

## Plano de rollback (para quando o deploy em QA acontecer)

Se por algum motivo o deploy em `sbx-eplast-qa` for revertido:

1. **Remover Permission Set** `PS_Comercial_ResumoClienteAgente` (ou revogar atribuição a usuários se já atribuído).
2. **Remover classes Apex** `CustomerSummaryService` e `CustomerSummaryServiceTest` via `destructiveChangesPost.xml` ou Setup UI.
3. **Risco de rollback quebrar algo em cascata:** baixo — as classes não são referenciadas por nenhuma automação, Flow, trigger ou Agent na org (confirmado no recon). Confirmar de novo em `sbx-eplast-qa` antes de excluir via `sf apex execute` read-only de metadata.
4. **Dados:** zero — nenhum dado é criado ou alterado por estes componentes.

---

## Limitações conhecidas e dívida técnica identificada

### 9 Decisões pendentes que bloqueiam a funcionalidade (D1–D9)

| # | Decisão | Bloqueia | Status |
|---|---|---|---|
| **D1** | Arquiteto humano aprova agente de funcionário + Flow + Apex como arquitetura (A1)? | Gate arquitetura | ✅ Aprovado em `gates.md`, 2026-10-06T20:40:55, Carlos Sordi |
| **D2** | "Ocorrência" = `Case`, `SalesReturn__c` ou ambos? Qual é usado em produção? | Categoria Ocorrências em `CustomerSummaryService` | ❌ Aberta — negócio Eplast |
| **D3** | Lista final de campos por categoria. Qual campo de crédito vale (`AvailableCreditLimit__c` vs. `AvailableCreditLimitt__c`)? | Conteúdo de todas as categorias | ❌ Aberta — negócio Eplast |
| **D4** | Valores de N (top-N) por categoria e janelas de "recente" (últimos 30 dias? 90 dias?)? | `LIMIT`/filtro de data em todas as categorias | ❌ Aberta — negócio Eplast |
| **D5** | Critérios e limiares exatos da síntese de atenção (ex.: "CloseDate ≤ quantos dias" = atenção)? | Cálculo de `sinaisAtencao[]` | ❌ Aberta — negócio Eplast (comercial + atendimento) |
| **D6** | Pode enviar e-mail, telefone, WhatsApp de contato ao LLM? Há mascaramento obrigatório (LGPD)? | Categoria Contatos — compliance | ❌ Aberta — compliance/DPO Eplast |
| **D7** | Produção tem o mesmo OWD público da sandbox? Há segregação de acesso não documentada em metadata? | Validação do critério de aceite de permissão | ❌ Aberta — admin Eplast |
| **D8** | Agentforce para funcionários e Data Cloud estão ativos e o consumo está contratado? | Construção de Agent, Topic, Flow | ❌ Aberta — Eplast (admin + comercial) |
| **D9** | `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas de fato? | Separação real entre build e QA | ❌ Aberta — Eplast / BASIS. **Achado:** `sbx-eplast-dev` aponta para `eplast--qa.sandbox.my.salesforce.com` (recon, achado 6). Build e QA podem estar no mesmo ambiente. |

### Funcionalidades não construídas (porque D1 foi aprovado, mas D2–D6 não foram respondidas)

- **Agent** (`Eplast_Assistente_Comercial`): ponto de entrada não existe
- **Topic** (`ResumoCliente`): instruções do Topic não existem
- **Flow de busca** (`Account_AgentAction_BuscaCliente`): identificação de conta por nome/CNPJ não existe
- **6 categorias de dados:**
  - Visão geral (Account)
  - Contatos (Contact)
  - Negociações (Opportunity)
  - Pedidos (Order)
  - Ocorrências (Case ou `SalesReturn__c`?)
  - Síntese de atenção (sinais calculados)
- **Todos os 8 critérios de aceite** de `demanda.md`: não testáveis (ver `05-testes.md`, conclusão)

### Dívida técnica herdada (não criada por esta demanda)

- **Campos de crédito duplicados em Account:** `AvailableCreditLimit__c` e `AvailableCreditLimitt__c` com o mesmo rótulo (recon, achado 4). A demanda não resolve isso.
- **Cobertura Apex da org:** 10–11% (assessment + `05-testes.md`). O código novo desta demanda alcança 100% de cobertura própria, mas não piora nem melhora a dívida pré-existente.
- **Possível duplicação de automação:** Account, Opportunity, Order têm triggers custom + triggers do CPQ + Flows AfterSave/BeforeSave (recon §4). Fora desta demanda.

### Riscos residuais após esta entrega

| Risco | Severidade | Mitigation |
|---|---|---|
| **R2:** Implementação de D2–D6 será inventada sem resposta humana registrada | Alta | Registrar as respostas em novo documento/gate antes de retomar a Apex |
| **R4:** Pré-requisitos de plataforma (Agentforce/Data Cloud ativos) não confirmados | Média | Primeiro passo do build: checklist no Setup. Se faltar, parar e escalar com D8. |
| **R6:** Alucinação na síntese do resumo — LLM pode afirmar algo não suportado pelos dados | Média | Sinais calculados em código (não LLM); instrução do Topic para redigir só a partir dos sinais; testes Gherkin com casos negativos |
| **R7:** QA rodou em `sbx-eplast-dev`, não em `sbx-eplast-qa` — sandbox vazia, sem dados para homologar | Média | Próxima sessão precisa criar massa sintética em `sbx-eplast-qa` (nunca dado real, guardrail #2) antes de validação de negócio |
| **R8:** `sbx-eplast-dev` aponta para instância "qa" — build e QA podem estar no mesmo ambiente | Média | Confirmar com cliente e resolver D9 antes de considerar qualquer feature "pronta para produção" |
| **R9:** Busca por nome sem seletividade em base grande | Baixa | Priorizar CNPJ/Protheus ID nas instruções do agente; limitar candidatos retornados |

---

## Rastreabilidade

| Campo | Valor |
|---|---|
| **Demanda** | EPLAST-23 |
| **Branch** | `feature/EPLAST-23` |
| **Commits** | `74af075` (QA), `17e49bc` (build), `e48419b` (design gate), mais anteriores. Ver `git log feature/EPLAST-23` para histórico completo. |
| **PR** | Não aberta. Conforme `04-plano-build.md` §4: scaffold que apenas bloqueia não entrega critério de aceite nenhum, então PR aguarda resposta de D2–D6. |
| **Deploy para `sbx-eplast-qa`** | Não executado. `sbx-eplast-qa` não está conectada/autorizada nesta esteira (D9 aberto). O release tentou dry-run e recebeu `NamedOrgNotFoundError`. |
| **Deploy ID** | Não existe. Nenhum deploy novo ocorreu nesta sessão em nenhuma org. |
| **Validação em `sbx-eplast-dev`** | Testes passaram (5/5), 100% cobertura de `CustomerSummaryService`. Ver `05-testes.md`. Mas esta sandbox está mapeada para ambiente "qa" na URL (`eplast--qa.sandbox.my.salesforce.com`), então a separação build/qa pode estar comprometida (D9). |

---

## Próximos passos

1. **Responder D2–D6** (negócio, compliance): registrar no design ou em novo documento `03-design-v2.md`, com gate humano antes de retomar Apex.
2. **Resolver D7–D9** (ambiente, compliance): confirmar OWD de produção, Agentforce ativo, sandboxes distintas.
3. **Retomar build:** com as respostas, implementar as 6 categorias no corpo de `CustomerSummaryService`, construir Flow de busca, configurar Agent e Topic.
4. **Abrir PR:** quando a Apex tiver conteúdo real.
5. **Deploy em QA:** quando D9 for resolvido e `sbx-eplast-qa` estiver conectada.
6. **Validar critérios de aceite:** com dados sintéticos em QA, rodar os 5 cenários Gherkin de `01-analise.md` de forma completa.

---

## Histórico de gates

| Data/Hora | Agente | Ação | Decisão |
|---|---|---|---|
| 2026-10-06T20:40:55 | arquiteto (aprovação humana por Carlos Sordi) | Aprova design em `03-design.md` | ✅ D1 — Agente de funcionário + Flow + Apex, aceito. D2–D6 permanecem pendentes. |
| 2026-10-06T20:58:22 | qa (submissão para homologação) | Move `status.yaml` de `design` para `aguardando_homologacao` | ✅ Testes técnicos do scaffold passam. Funcionalidade de negócio ainda não testável. |
| 2026-10-06T20:58:22 (inferred) | release (input do gate anterior) | Tenta deploy em `sbx-eplast-qa`, falha em org não conectada | ⚠️ D9 — `sbx-eplast-qa` não autorizada. Deploy não executado. Scaffold registrado para quando D9 for resolvido. |

Ver `gates.md` para hash de cada artefato aprovado.

---

**Consolidação concluída. A demanda entregou infraestrutura técnica (scaffold pronto, com testes), mas a funcionalidade aguarda decisões de negócio, compliance e ambiente que ainda não foram respondidas.**
