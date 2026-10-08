# Testes — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Autor:** qa (agente) · **Data:** 2026-10-06

## Conclusão em uma frase

**Nenhum critério de aceite funcional da demanda (`demanda.md`) é testável hoje.** O que
existe em `sbx-eplast-dev` é um scaffold Apex que recusa, explicitamente, consolidar
qualquer dado — não a feature. Os casos abaixo derivam dos 5 cenários Gherkin de
`01-analise.md`, não do que foi construído, e por isso a tabela está dominada por
`BLOQUEADO`, não por `PASSOU`.

## Org usada nesta sessão

`sf org list` nesta sessão mostra **apenas uma org conectada**: `sbx-eplast-dev`
(`projetos@konectabr.com.eplast2.qa`, Org Id `00DHa000006vfMLMAY`, status `Connected`).
**`sbx-eplast-qa` não está disponível/conectada nesta sessão.** Pela doutrina, o estágio
`qa` deveria rodar contra `sbx-eplast-qa` — não foi possível aqui, e registro isso em vez
de presumir. Todos os testes executados abaixo (automatizáveis, Apex) rodaram em
`sbx-eplast-dev` por ser a única org acessível. Isso é, em si, um achado: D9
(`03-design.md` §7 — "`sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas?") segue
sem resposta, e o build já havia registrado (`04-plano-build.md`) que
`sbx-eplast-dev` aponta para uma instância chamada "qa" (`eplast--qa.sandbox.my.salesforce.com`).
Não há evidência nesta sessão de que QA funcional rode em ambiente separado do build.

Confirmei que o código em `force-app/` não mudou desde o commit `e48419b` (o mesmo que
gerou a versão anterior de `05-testes.md`) via `git diff --stat force-app/` (limpo) e
`git log -1 -- force-app/`. Mesmo assim, re-executei os 5 testes Apex agora (não apenas
reaproveitei o resultado antigo) — resultado idêntico, ver seção "Testes automatizados
executados hoje".

---

## Falhas e bloqueios (primeiro, como manda o método)

| # | Achado | Severidade |
|---|--------|------------|
| F1 | **Nenhuma das 6 categorias do resumo (Visão geral, Contatos, Negociações, Pedidos, Ocorrências, Síntese) existe.** `CustomerSummaryService.resumirCliente` lança `CustomerSummaryPendingDecisionException` para qualquer request bem formado, citando D2–D6 (`03-design.md` §7) como pendência de negócio/compliance não respondida. | **Bloqueante** |
| F2 | **Não existe Agent, Topic nem Action do Agentforce na org.** Não há como um usuário digitar "Resuma o cliente [nome]" em lugar nenhum — o ponto de entrada da demanda inteira não foi construído (`04-plano-build.md` §3). | **Bloqueante** |
| F3 | **Não existe o Flow de busca de conta** (`Account_AgentAction_BuscaCliente`). Não há identificação de conta por nome, nem tratamento de ambiguidade, nem "cliente não encontrado" — nada disso tem implementação para testar. | **Bloqueante** |
| F4 | **QA rodou em `sbx-eplast-dev`, não em `sbx-eplast-qa`.** Só uma org está conectada nesta sessão. D9 segue sem resposta. Se as duas sandboxes forem, na prática, o mesmo ambiente (achado do build), o próprio modelo "build em dev, QA em qa" da esteira está comprometido para este cliente até D9 ser esclarecido. | Alta (achado de processo, não deste código) |
| F5 | **D2–D6 seguem sem resposta registrada em qualquer artefato** (`gates.md`, `status.yaml`, `03-design.md`, `04-plano-build.md`) nesta data. Isso não é um problema de QA, mas é a causa raiz de F1: sem resposta de negócio, a lógica não pode ser escrita, logo não pode ser testada. | Bloqueante (upstream) |

**Recomendação de QA:** esta demanda não deveria avançar para homologação funcional no
sentido de "a feature funciona" — porque a feature, tal como descrita em `demanda.md`,
não existe ainda. O que pode ser homologado hoje, no máximo, é o comportamento do
scaffold (seção seguinte). Essa é uma constatação de QA, não uma decisão de gate — quem
decide o que acontece com `status.yaml` é o humano.

---

## Casos de teste derivados do Gherkin (`01-analise.md`) — critérios de aceite, não o que foi construído

| Caso | Cenário Gherkin de origem | Passos | Esperado (critério de aceite) | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Caminho feliz — resumo com 6 seções | Usuário digita "Resuma o cliente [nome]" no Agentforce, com exatamente 1 conta correspondente | Agente apresenta Visão geral, Contatos, Negociações, Pedidos, Ocorrências, Síntese; cada seção com dado ou "Sem registros nesta categoria"; referências clicáveis; nenhum registro alterado | Não existe Agent/Topic no Agentforce para receber a solicitação (F2). Mesmo que existisse, `CustomerSummaryService` lança exceção de pendência de negócio para qualquer `accountId` válido (F1) — nenhuma das 6 categorias é calculada | **BLOQUEADO — não testável.** Depende de D2 (objeto de Ocorrência), D3 (campos por categoria), D4 (valores de N/janelas), D5 (limiares de síntese) |
| C2 | Ambiguidade na identificação do cliente | Nome fornecido corresponde a múltiplas contas | Agente lista os clientes potenciais e pede confirmação | Não existe o Flow `Account_AgentAction_BuscaCliente` nem ação padrão configurada (F3). Não há onde testar isso | **BLOQUEADO — não testável.** Depende de D8 (Agentforce ligado) e da construção do Flow, nenhum dos dois feito |
| C3 | Respeito a permissões de acesso | Usuário sem permissão de leitura em um registro que entraria no resumo | Agente não expõe o registro; categoria reflete só os registros acessíveis | `CustomerSummaryService` ainda não faz nenhuma consulta a Contact/Opportunity/Order/Case — não há FLS/OLS para violar ou respeitar porque não há leitura de dado nenhuma ainda. O design (`03-design.md` §1.2 item 1) propõe `WITH USER_MODE` + `stripInaccessible`, mas isso é proposta, não código | **BLOQUEADO — não testável.** Depende de D2–D6 (a lógica de consolidação por categoria, onde o controle de acesso seria aplicado, não existe) |
| C4 | Categoria sem dados | Cliente sem registros em uma categoria (ex.: nenhuma negociação aberta) | Seção sinaliza "Sem negociações em andamento", não omite a categoria | Não há cálculo de categoria nenhuma — o método sempre lança exceção antes de chegar a qualquer status `OK`/`VAZIO`/`SEM_ACESSO` (que é só uma proposta de design, `03-design.md` §2.1, nunca implementada) | **BLOQUEADO — não testável.** Depende de D2–D5 |
| C5 | Recuperação de falha na identificação | Cliente mencionado não existe | Agente retorna "Cliente não encontrado" e oferece busca alternativa (CNPJ, código interno) | Não existe Flow de busca nem Agent/Topic (F2, F3) — não há onde essa busca aconteceria | **BLOQUEADO — não testável.** Depende de D8 e da construção do Flow/Agent |

Nenhum dos 8 critérios de aceite listados em `demanda.md` pode ser considerado satisfeito:
"usuário consegue solicitar em linguagem natural" (sem Agent/Topic), "identifica conta ou
pede esclarecimento" (sem Flow de busca), "consolida contatos/negociações/pedidos/
ocorrências" (scaffold bloqueado), "apresentado por categoria com síntese" (idem),
"permite acessar registros fonte" (idem), "categorias sem dados sinalizadas" (idem),
"informações sem permissão não expostas" (nenhuma leitura de dado existe para violar ou
respeitar), "nenhum registro criado ou alterado" — este último é o único em que o código
atual *coincide* com o critério, mas só porque não faz nada, não porque implementa a regra
de "leitura pura" com intenção.

---

## O que É testável hoje: comportamento real do scaffold `CustomerSummaryService`

Estes não são testes da demanda — são testes do bloqueio em si, úteis para confirmar que
o scaffold falha do jeito certo (explícito, nomeando a pendência) em vez de inventar dado.

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| S1 | Chamar `resumirCliente` com lista vazia | Devolve lista vazia, sem exceção | Lista vazia devolvida, sem exceção (`deveDevolverListaVaziaQuandoNaoHaRequests`) | **PASSOU** |
| S2 | Chamar `resumirCliente` com 1 request válido (`accountId` preenchido) | Lança `CustomerSummaryPendingDecisionException` citando D2–D6 | Exceção lançada com a mensagem esperada (`deveBloquearRequestUnicoValidoComExcecaoDePendenciaDeNegocio`) | **PASSOU** |
| S3 | Chamar `resumirCliente` com lote de 200 requests válidos | Mesmo bloqueio, zero SOQL e zero DML mesmo em volume | Bloqueio confirmado, `Limits.getQueries() == 0` e `Limits.getDmlStatements() == 0` provados no teste (`deveBloquearLoteDe200RequestsSemSoqlNemDml`) | **PASSOU** |
| S4 | Chamar `resumirCliente` com `accountId` nulo | Lança `IllegalArgumentException`, distinta da exceção de bloqueio de negócio | `IllegalArgumentException` lançada (`deveLancarIllegalArgumentQuandoAccountIdEhNulo`) | **PASSOU** |
| S5 | Chamar `resumirCliente` sob `System.runAs` com usuário de perfil `Minimum Access - Salesforce` (acesso restrito) | Mesmo bloqueio — prova que o scaffold não depende de FLS/OLS hoje, porque ainda não lê dado nenhum | Bloqueio idêntico ao de S2, sob usuário restrito (`deveBloquearIgualmenteParaUsuarioComAcessoRestrito`) | **PASSOU** — mas não é o teste de permissão real da demanda (C3); é só prova de que o bloqueio independe de perfil |

### Execução (re-rodada hoje, 2026-10-06, em `sbx-eplast-dev`)

```
sf apex run test --target-org sbx-eplast-dev --class-names CustomerSummaryServiceTest \
  --code-coverage --result-format human --wait 10 --synchronous
```

```
=== Test Results
TEST NAME                                                                                OUTCOME  MESSAGE  RUNTIME (MS)
───────────────────────────────────────────────────────────────────────────────────────  ───────  ───────  ────────────
CustomerSummaryServiceTest.deveBloquearIgualmenteParaUsuarioComAcessoRestrito            Pass              812
CustomerSummaryServiceTest.deveBloquearLoteDe200RequestsSemSoqlNemDml                    Pass              78
CustomerSummaryServiceTest.deveBloquearRequestUnicoValidoComExcecaoDePendenciaDeNegocio  Pass              69
CustomerSummaryServiceTest.deveDevolverListaVaziaQuandoNaoHaRequests                     Pass              67
CustomerSummaryServiceTest.deveLancarIllegalArgumentQuandoAccountIdEhNulo                Pass              69

=== Apex Code Coverage by Class
CLASSES                 PERCENT  UNCOVERED LINES
──────────────────────  ───────  ───────────────
CustomerSummaryService  100%
AccountTrigger          0%       2,3,5,7,8,...
OpportunityTrigger      0%       2,4,5,6,7,...
OrderTrigger            0%       2,4,5,6,7

=== Test Summary
NAME                 VALUE
───────────────────  ─────────────────────────────────
Outcome              Passed
Tests Ran            5
Pass Rate            100%
Fail Rate            0%
Skip Rate            0%
Test Execution Time  1270 ms
Org Id               00DHa000006vfMLMAY
Username             projetos@konectabr.com.eplast2.qa
Org Wide Coverage    11%
```

Resultado idêntico ao registrado na versão anterior deste arquivo (rodada em
2026-10-06 durante o build, commit `e48419b`). `AccountTrigger`/`OpportunityTrigger`/
`OrderTrigger` aparecem com 0% porque o `sf apex run test` reporta cobertura agregada de
todo componente com registro em `ApexCodeCoverageAggregate`, não porque esta execução os
tocou — `CustomerSummaryService` não faz DML, então nenhum trigger dispara. `Org Wide
Coverage` de 11% é dívida pré-existente da org (assessment registrou 10% em 2026-09-30),
não desta demanda, e segue abaixo dos 85% mínimos da convenção do squad e dos 75% mínimos
de deploy de produção — mas produção está fora do escopo desta esteira de qualquer forma.

**Cobertura de `CustomerSummaryService`: 100% (10/10 linhas executáveis)** — alcançável
porque a classe hoje tem só os caminhos de entrada/bloqueio, todos exercitados com
asserts reais (tipo de exceção e conteúdo de mensagem).

Nenhum teste usou `SeeAllData=true`. Nenhum dado pessoal de cliente foi lido ou criado —
o único registro de teste é um `User` sintético (`usuarioRestrito`) criado dentro do
teste, sem CPF/e-mail/telefone real.

---

## Itens do roteiro que exigiriam tela (Agentforce / Agent Builder)

Não executados com `qa_browser_*` nem escritos como roteiro manual, porque **não há
nada para abrir**: não existe Agent, Topic, Action nem Flow publicados na org para um
usuário interagir. Abrir o Agent Builder nesta org hoje mostraria um catálogo vazio para
esta demanda — não um roteiro de teste, apenas confirmação de ausência. Quando D2–D6
forem respondidos e a Apex, o Flow e o Agent/Topic existirem, os 5 cenários Gherkin
devem virar roteiro de UI real (incluindo captura de tela com dado sintético, nunca
dado real de cliente, guardrail #2).

---

## Rastreamento das pendências que bloqueiam o teste funcional

Reaproveitado de `03-design.md` §7 e `04-plano-build.md` §5 — nenhuma resposta nova
apareceu em nenhum artefato da demanda até esta data:

| # | Pergunta | Bloqueia qual caso acima |
|---|---|---|
| D2 | "Ocorrência" é `Case`, `SalesReturn__c` ou os dois? | C1, C3, C4 |
| D3 | Lista final de campos por categoria (e qual campo de crédito: `AvailableCreditLimit__c` × `AvailableCreditLimitt__c`) | C1, C3, C4 |
| D4 | Valores de N por categoria e janelas de "recente" | C1, C4 |
| D5 | Critérios e limiares da síntese de atenção | C1, C4 |
| D6 | Mascaramento de e-mail/telefone/WhatsApp de contato ao LLM (LGPD) | C1, C3 (categoria Contatos) |
| D8 | Agentforce para funcionários e Data Cloud ativos e contratados? | C1, C2, C5 (sem isso não há onde o Agent existir) |
| D9 | `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas? | Esta própria sessão de QA (F4) |

---

## Conclusão

- **0 de 5** cenários Gherkin de `01-analise.md` são testáveis hoje — todos bloqueados por
  D2–D6 (lógica de negócio inexistente) e/ou D8 (plataforma Agentforce não confirmada como
  ativa).
- **5 de 5** testes do scaffold (comportamento de bloqueio, bulk, negativo, permissão
  superficial) passam e foram re-executados nesta sessão em `sbx-eplast-dev` — único
  comportamento real que existe no código hoje.
- **QA funcional rodou em `sbx-eplast-dev`, não em `sbx-eplast-qa`**, porque só a primeira
  está conectada nesta sessão. Isso é um achado de processo, registrado, não ignorado.
- Nenhum critério de aceite de `demanda.md` pode ser dado como satisfeito nesta data.
- Não alterei `status.yaml` nem `gates.md` — a decisão sobre avançar, devolver para design/
  build ou aguardar resposta de negócio antes de homologar é exclusivamente humana.

Testes executados. Preciso da sua homologação para liberar o release.
