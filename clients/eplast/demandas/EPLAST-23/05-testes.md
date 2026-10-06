# Testes — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Escopo deste arquivo:** só o que foi de fato construído e é seguro de testar
hoje — o scaffold bloqueado de `CustomerSummaryService` (ver `04-plano-build.md`).
Não há roteiro de QA funcional da demanda (resumo de cliente via Agentforce)
porque a lógica de consolidação não existe ainda — depende de D2–D6. Este não é
o `05-testes.md` final da demanda.

**Org:** `sbx-eplast-dev`, `https://eplast--qa.sandbox.my.salesforce.com`,
username `projetos@konectabr.com.eplast2.qa`, Org Id `00DHa000006vfMLMAY`.
**Data:** 2026-10-06.

## Deploy

```
sf project deploy start --target-org sbx-eplast-dev --source-dir force-app \
  --test-level RunSpecifiedTests --tests CustomerSummaryServiceTest --wait 15
```

Resultado: `status: Succeeded`, `success: true`, `numberComponentErrors: 0`,
`numberComponentsDeployed: 3` (`CustomerSummaryService`,
`CustomerSummaryServiceTest`, `PS_Comercial_ResumoClienteAgente`),
`numberTestsCompleted: 5`, `numberTestErrors: 0`.

## Execução de teste com cobertura

```
sf apex run test --target-org sbx-eplast-dev --class-names CustomerSummaryServiceTest \
  --code-coverage --result-format human --wait 10 --synchronous
```

```
=== Test Results
TEST NAME                                                                                OUTCOME  MESSAGE  RUNTIME (MS)
───────────────────────────────────────────────────────────────────────────────────────  ───────  ───────  ────────────
CustomerSummaryServiceTest.deveBloquearIgualmenteParaUsuarioComAcessoRestrito            Pass              609
CustomerSummaryServiceTest.deveBloquearLoteDe200RequestsSemSoqlNemDml                    Pass              60
CustomerSummaryServiceTest.deveBloquearRequestUnicoValidoComExcecaoDePendenciaDeNegocio  Pass              45
CustomerSummaryServiceTest.deveDevolverListaVaziaQuandoNaoHaRequests                     Pass              46
CustomerSummaryServiceTest.deveLancarIllegalArgumentQuandoAccountIdEhNulo                Pass              46


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
Test Setup Time      0 ms
Test Execution Time  946 ms
Test Total Time      946 ms
Org Id               00DHa000006vfMLMAY
Username             projetos@konectabr.com.eplast2.qa
Org Wide Coverage    11%
```

`AccountTrigger`/`OpportunityTrigger`/`OrderTrigger` aparecem no relatório porque
o `sf apex run test` lista a cobertura agregada de todo componente com registro
em `ApexCodeCoverageAggregate` no org, não só o que a execução tocou — nenhum dos
três foi executado por este teste (prova disso: `CustomerSummaryService` não faz
DML, então nenhum trigger dispara). `Org Wide Coverage` subiu de 10% (assessment,
2026-09-30) para 11% só com a classe nova — org ainda está bem abaixo de 85% (e
do mínimo de deploy de produção, 75%), mas isso é dívida pré-existente, registrada
no assessment, não desta demanda.

## Cobertura de `CustomerSummaryService`

**100% (10/10 linhas executáveis).** Cobertura alcançada porque a classe hoje só
tem um caminho de execução real por cenário de entrada (vazio / único bloqueado /
lote bloqueado / inválido / bloqueado sob outro usuário) — todos exercitados, com
asserts reais (tipo de exceção e mensagem, não só "não estourou").

## Cenários cobertos vs. os 4 cenários padrão (`dev-apex`: caminho feliz, bulk 200, negativo/exceção, permissão)

| Cenário padrão | Adaptação para este scaffold | Teste |
|---|---|---|
| Caminho feliz | Não existe caminho feliz de consolidação ainda (não implementada). Interpretado como "request único bem formado" → bloqueio previsível e correto | `deveBloquearRequestUnicoValidoComExcecaoDePendenciaDeNegocio` |
| Bulk (200) | 200 requests válidos → mesmo bloqueio, **e prova de 0 SOQL / 0 DML** mesmo em volume | `deveBloquearLoteDe200RequestsSemSoqlNemDml` |
| Negativo/exceção | `accountId` nulo → `IllegalArgumentException`, distinta da exceção de bloqueio de negócio | `deveLancarIllegalArgumentQuandoAccountIdEhNulo` |
| Permissão | Executado via `System.runAs` com usuário de perfil `Minimum Access - Salesforce` → mesmo bloqueio, provando que o scaffold não depende de FLS/OLS hoje (porque ainda não lê dado nenhum). **Não é** o teste de permissão real da demanda (ex. usuário sem acesso a Case) — esse só faz sentido quando a consolidação por categoria existir | `deveBloquearIgualmenteParaUsuarioComAcessoRestrito` |
| (extra) lista vazia | Nada a processar → lista vazia, sem exceção | `deveDevolverListaVaziaQuandoNaoHaRequests` |

Nenhum teste usa `SeeAllData=true`. Nenhum dado de registro real foi lido ou
criado além do usuário sintético do cenário de permissão (`insert usuarioRestrito`,
um `User` de teste, sem nenhum dado pessoal de cliente).

## O que falta testar (depende de D2–D6)

Todos os cenários Gherkin de `01-analise.md` (resumo com múltiplas categorias,
ambiguidade de conta, categoria sem dados, "cliente não encontrado") dependem de
lógica que não existe ainda. Serão escritos quando a implementação real de
`CustomerSummaryService` for retomada (ver `04-plano-build.md` seção 6).
