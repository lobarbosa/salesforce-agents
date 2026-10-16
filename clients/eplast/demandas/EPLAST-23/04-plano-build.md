# Plano de build — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Status: BUILD PARCIAL E BLOQUEADO.** Isto não é um plano de build completo — é o
registro honesto do que foi possível construir sem decidir negócio no lugar de
alguém, e a lista do que falta para destravar o resto.

**Org confirmada:** `sbx-eplast-dev` (alias), Org Id `00DHa000006vfMLMAY`,
`https://eplast--qa.sandbox.my.salesforce.com`, `sf org list` em 2026-10-06 mostra
status `Connected` — bate com o ambiente registrado em `status.yaml` (`build` / `dev`).

---

## 1. Por que o build não avançou integralmente

O gate que moveu `status.yaml` para `build` (2026-10-06T20:40:55, Carlos Sordi,
ver `gates.md`) aprovou **a arquitetura** proposta em `03-design.md` — agente de
funcionário Agentforce + Flow de busca + Apex `CustomerSummaryService` (D1, seção
7 do design). Essa aprovação **não cobre** as pendências de negócio/compliance
D2–D6, que seguem sem resposta em qualquer artefato desta demanda (`gates.md`,
`status.yaml` e o histórico de commits não têm nada além da aprovação de D1).

O próprio `03-design.md` é explícito: *"o build não deve começar sem resposta
para A2 (objeto de ocorrência), A3 (valores de N), A5 (limiares) e P6 (dados
pessoais no LLM). Do contrário, o builder vai inventar regra de negócio."*
Praticamente toda a lógica de negócio de `CustomerSummaryService` — os campos por
categoria, o objeto de "ocorrência", os valores de N, as janelas de tempo e os
limiares de atenção — depende diretamente dessas pendências. Implementá-la agora
seria inventar regra de negócio, o que o guardrail #3 do `CLAUDE.md` raiz e as
instruções do agente `dev-apex` proíbem explicitamente.

## 2. O que foi construído e commitado

Apenas os componentes **estruturalmente independentes** de D2–D6: a assinatura
pública da Action Apex e um Permission Set que não concede acesso a dado nenhum.
Nenhum deles decide objeto de ocorrência, campo, N, janela, limiar ou
mascaramento de contato.

| Componente | Arquivo | O que faz | O que falta nele |
|---|---|---|---|
| Classe Apex (scaffold) | `force-app/main/default/classes/CustomerSummaryService.cls` | Define a assinatura pública `@InvocableMethod resumirCliente(List<CustomerSummaryRequest>)` aprovada em `03-design.md` §2.1. Valida entrada (lista vazia → lista vazia; `accountId` nulo → `IllegalArgumentException`). Para qualquer request bem formado, lança `CustomerSummaryPendingDecisionException` citando D2–D6 em vez de adivinhar. Zero SOQL, zero DML. `with sharing`. | Toda a consolidação real: Contatos/Negociações/Pedidos/Ocorrências, cálculo de sinais de atenção, mascaramento de contato — tudo aguardando D2–D6. |
| Classe de teste | `force-app/main/default/classes/CustomerSummaryServiceTest.cls` | 5 cenários, todos sobre o comportamento real de hoje (bloqueio): lista vazia, request único bloqueado, lote de 200 bloqueado com prova de 0 SOQL/0 DML, `accountId` nulo, e bloqueio idêntico sob usuário de perfil mínimo (`runAs`). 100% de cobertura de linha da classe-alvo (ver `05-testes.md`). | Cenários de "caminho feliz" de consolidação de dado e de permissão real (ex. usuário sem acesso a Case) só fazem sentido quando a lógica real existir — documentado no cabeçalho do teste. |
| Permission Set | `force-app/main/default/permissionsets/PS_Comercial_ResumoClienteAgente.permissionset-meta.xml` | Concede **somente** `classAccesses` para `CustomerSummaryService`. Nenhum `objectPermissions` nem `fieldPermissions`. | Não inclui o Flow de busca de conta (não construído) nem a licença/permission set de uso do agente de funcionário (não identificada com certeza no recon, `02-recon.md` §6.3). |
| `sfdx-project.json` | `clients/eplast/sfdx-project.json` | Primeiro `sfdx-project.json` deste cliente (greenfield; não havia `force-app` em `clients/eplast` antes desta demanda). `sourceApiVersion` 67.0, igual à org (recon). | — |

**Validação em `sbx-eplast-dev`:** os 3 componentes acima foram deployados com
sucesso (`sf project deploy start --test-level RunSpecifiedTests --tests
CustomerSummaryServiceTest`) e os 5 testes passaram, 100% de cobertura da classe
`CustomerSummaryService`. Resultado completo em `05-testes.md`. **Nenhuma PR foi
aberta** — ver seção 4.

## 3. O que NÃO foi construído, e por quê (não inventado)

| Componente do design (`03-design.md` §2.1) | Por que não foi construído agora |
|---|---|
| Agent (`Bot`/`BotVersion`/`GenAiPlannerBundle`) `Eplast_Assistente_Comercial` | Configuração de Agent Builder, fora do escopo Apex desta sessão (seria `builder-declarativo`), e de qualquer forma depende de D8 (Agentforce para funcionários ligado no Setup — não confirmado, `02-recon.md` §6.1). |
| Topic (`GenAiPlugin`) `ResumoCliente` | Idem — e as instruções do Topic sobre "nunca deduzir"/"sinalizar categoria vazia" dependem de como as categorias ficam definidas (D2–D5). |
| Flow `Account_AgentAction_BuscaCliente` | Fora do escopo Apex desta sessão (declarativo). Tecnicamente menos bloqueado que a Apex (usa só `Name`, `CompanyDocument__c`, `ProtheusId__c`, já confirmados no recon), mas não é parte do meu escopo de trabalho nesta etapa. |
| Lógica real de `CustomerSummaryService` (categorias, campos, N, janelas, sinais de atenção) | **Bloqueada por D2–D6.** Implementar qualquer um desses pontos exigiria decidir: <br>— **D2:** se "Ocorrência" é `Case`, `SalesReturn__c` ou os dois (muda o objeto da query inteira da categoria Ocorrências); <br>— **D3:** lista final de campos por categoria e qual campo de crédito vale (`AvailableCreditLimit__c` × `AvailableCreditLimitt__c`, ambos existem com o mesmo rótulo); <br>— **D4:** valores de N (top-N) por categoria e janelas de "recente" (não há como escrever `LIMIT` nem filtro de data sem isso); <br>— **D5:** critérios e limiares exatos da síntese de atenção (ex. "CloseDate ≤ quantos dias" é hoje um placeholder `⟨X⟩` no design, não um número); <br>— **D6:** se e-mail/telefone/WhatsApp de contato podem ir ao LLM ou precisam de mascaramento LGPD (decide se a categoria Contatos sequer pode devolver esses campos). |

Nenhum placeholder de valor de negócio (N, limiar, objeto de ocorrência, decisão
de mascaramento) foi escrito em código. Onde a estrutura toca esses pontos, o
método apenas lança uma exceção nomeando a pendência — nunca escolhe um valor.

## 4. Por que não há PR ainda

O grosso do trabalho desta demanda (a consolidação de dados em
`CustomerSummaryService`) não foi feito, porque não pode ser feito sem D2–D6. Um
PR com apenas um scaffold que sempre lança exceção, sem nenhuma categoria
implementada, não entrega nenhum critério de aceite da demanda (`demanda.md`,
`01-analise.md`) — entregaria menos valor do que o risco de alguém revisar achando
que é a implementação completa. Por isso o código fica commitado na branch
`feature/EPLAST-23`, mas a abertura de PR aguarda pelo menos as respostas de D2,
D3, D4 e D5 (o mínimo para a Apex ter conteúdo real) e idealmente D6 (que também
limita o que pode legalmente ir na resposta do agente).

## 5. Pendências que bloqueiam o restante (reaproveitado de `03-design.md` §7)

| # | Pergunta | Para quem | Bloqueia |
|---|---|---|---|
| D2 | "Ocorrência" é `Case`, `SalesReturn__c` ou os dois? Algum desses é usado de fato em produção? | Negócio Eplast | Categoria Ocorrências em `CustomerSummaryService` (qual objeto consultar) |
| D3 | Lista final de campos por categoria. Qual campo de crédito vale (`AvailableCreditLimit__c` × `AvailableCreditLimitt__c`)? | Negócio Eplast | Conteúdo de todas as categorias |
| D4 | Valores de N por categoria e janelas de "recente" | Negócio Eplast | `LIMIT`/filtro de data de todas as categorias |
| D5 | Critérios e limiares exatos da síntese de atenção | Negócio Eplast (comercial + atendimento) | Cálculo de `sinaisAtencao[]` |
| D6 | Pode enviar e-mail, telefone e WhatsApp de contato ao LLM? Há mascaramento obrigatório? | Compliance/DPO Eplast | Categoria Contatos — e, por extensão, se a resposta do agente é segura do ponto de vista de LGPD |
| D7 | Produção tem o mesmo OWD público da sandbox? Há regra de segregação que não está em metadata? | Admin Eplast | Validação do critério de aceite de permissão (fora do meu controle direto) |
| D8 | Agentforce para funcionários e Data Cloud estão ativos e o consumo está contratado? | Eplast (admin + comercial) | Construção do Agent/Topic (componente declarativo, fora desta sessão) |
| D9 | `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas? | Eplast / BASIS | Separação real de build e QA (fora do meu controle direto) |

## 6. Próximo passo

Quando D2, D3, D4 e D5 tiverem resposta registrada em artefato desta demanda
(idealmente um novo `03-design.md` revisado ou um adendo, com gate humano), a
implementação de `CustomerSummaryService` pode ser retomada a partir deste
scaffold: a assinatura pública (`CustomerSummaryRequest`) não precisa mudar, só o
corpo de `resumirCliente` e a adição das categorias/sinais de atenção descritos
em `03-design.md` §2.4. D6 precisa de resposta antes de a categoria Contatos
devolver qualquer campo de contato ao LLM.
