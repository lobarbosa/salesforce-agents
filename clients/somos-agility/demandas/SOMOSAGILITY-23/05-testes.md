# SOMOSAGILITY-23 — Testes (qa)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (enxuto), 4, 5, 7.
**Entradas:** `01-analise.md` (critérios de aceite), `03-design.md` (hipóteses de causa),
`04-plano-build.md` (diagnóstico anterior em sandbox de **dev**, sem build de metadata),
`comentarios-do-card.md`, anexo do card (PDF, só a URL do erro, sem texto da mensagem).
**Gate que libera esta etapa:** `aguardando_gate_build`, última aprovação em `gates.md`
(2026-10-30T02:00Z, conforme `comentarios-do-card.md`).
**Org usada nesta etapa:** `sbx-somos-agility-qa` — confirmada via `sf org list` como
**único** alias conectado nesta sessão, `Status: Connected`. Nenhuma outra org (dev ou
produção) foi tocada, autenticada ou consultada.

---

## 0. Por que esta rodada é diferente das anteriores

Duas rodadas anteriores desta mesma etapa não produziram teste real:

1. A primeira rodou sem `sbx-somos-agility-qa` conectada e documentou corretamente
   "bloqueado por ambiente" — depois levado indevidamente até "entregue" e revertido.
2. A segunda rodou, por defeito do `run-demand.yml` (já corrigido), contra a sandbox de
   **dev** em vez de QA — revertido de novo.

Nesta rodada, `sbx-somos-agility-qa` está conectada e foi usada de ponta a ponta. **É a
primeira execução real de teste desta demanda em sandbox de QA.**

## 1. O que continua pendente antes desta etapa (sem mudança desde o design)

Conferido `comentarios-do-card.md`: a última entrada é a aprovação do gate de build em
2026-10-30. **Nenhuma das duas respostas humanas bloqueantes do plano de diagnóstico
(`03-design.md` §3) chegou:**

1. Mensagem de erro exata exibida ao cliente em produção.
2. Confirmação de humano autorizado olhando a Opportunity pai do lançamento
   `a6UU40000000Ue1MAE` em produção.

Isso limita o que esta etapa consegue fechar — ver §5.

## 2. Pré-checagem de metadata viva em QA (guardrail #3)

Antes de montar qualquer dado sintético, confirmei ao vivo em `sbx-somos-agility-qa`
(não assumi o que valia em dev):

| Componente | Confirmado via | Resultado em QA |
|---|---|---|
| `Realizacao_Financeira_de_Venda__c.Renova_o__c` | `sf sobject describe` | `currency`, createable/updateable `true` |
| `Realizacao_Financeira_de_Venda__c.Resultado__c` | `sf sobject describe` | lookup/master-detail, createable `true`, updateable `false` (esperado para MD) |
| `Resultado__c.Oportunidade__c` | `sf sobject describe` | master-detail para `Opportunity`, createable `true`, updateable `false` |
| `Resultado__c.RenovacaoRealizado__c` | `sf sobject describe` + `sf data query` antes/depois | roll-up (`calculated: true`), confirmado funcionando na prática (§4) |
| `Opportunity.N_mero_de_DSA__c` | `sf sobject describe` | roll-up (`calculated: true`), não editável diretamente |
| `Opportunity.RenovacaoRealizado__c` | `sf sobject describe` + `sf data query` | roll-up (`calculated: true`), confirmado funcionando na prática (§4) |
| `DSA__c.Oportunidade__c` | `sf sobject describe` | master-detail para `Opportunity`, `createable: true` |
| `ValidationRule M38_Valida_Numero_DSA` (Opportunity) | `sf data query` (Tooling API, `Metadata.errorConditionFormula`) | `Active: true`, fórmula `N_mero_de_DSA__c >= 2` — **igual ao que `04-plano-build.md` achou em dev** |
| `ValidationRule M35_Somente_pode_existir_um_SOW_atual` (Opportunity) | idem | `Active: true`, referencia `Qtde_Propostas_SOW__c`, com exceção de perfil — **igual ao achado em dev** |

### Divergência de metadata confirmada também em QA (não é só de dev)

`04-plano-build.md` havia achado, em `sbx-somos-agility-dev`, que os campos referenciados
por `M35`/`M17`-`M20`/`M39` não existem no describe ao vivo de `Opportunity`, apesar das
regras estarem `Active: true`. A instrução desta etapa pedia para não assumir que isso
também valeria em QA. **Confirmei ao vivo que a mesma divergência existe em
`sbx-somos-agility-qa`:**

- `Qtde_Propostas_SOW__c` (referenciado por `M35`) — **não encontrado** no describe ao vivo
  de `Opportunity` em QA.
- `Mapeamento_esta_valido_com_fabricante__c`, `Descreva_mapeada_opp_fabricante__c`,
  `Condicoes_especiais_de_fornecimento__c`, `Descreva_condicoes_especiais_forneciment__c`
  (referenciados por `M17`/`M39` e prováveis equivalentes de `M18`/`M19`/`M20`) —
  **não encontrados** no describe ao vivo de `Opportunity` em QA.

**Conclusão:** essa divergência não é peculiaridade da sandbox de dev — está presente em
QA também. Isso não prova nem descarta nada sobre produção (continua sendo necessário
confirmar lá, ação humana pendente), mas descarta a hipótese de que fosse só dev
desatualizada. Como em dev, isso **impede reproduzir M35/M17-M20/M39 nesta sandbox** com
dados sintéticos — os campos que essas regras avaliam não existem como `createable` aqui.
Só `M38` continuou operável para reprodução.

## 3. Setup sintético criado em QA (sem dado de cliente — guardrail #2)

Nomes óbvios de teste (`TESTE DIAGNOSTICO SOMOSAGILITY-23`), valores fictícios (telefone
`0000000000`, valores monetários arbitrários). Nenhum dado de cliente foi copiado,
consultado ou inventado. Todos os IDs abaixo foram apagados ao final (ver §4.4).

| Ordem | Objeto | Id (apagado) | Observação |
|---|---|---|---|
| 1 | `Contact` | `003Ha00000pZdfSIAS` | `LastName='TESTE DIAGNOSTICO SOMOSAGILITY-23'`, `Phone='0000000000'` |
| 2 | `Opportunity` | `006Ha00000Q8RyXIAV` | `Name='TESTE DIAGNOSTICO SOMOSAGILITY-23'`, `StageName='Qualificação'`, `CloseDate=2026-12-31`, `Conversao_de_Lead__c='Não'` |
| 3 | `Resultado__c` | `a6xHa0000002C57IAE` | `Oportunidade__c` apontando para a Opportunity acima |
| 4 | `Realizacao_Financeira_de_Venda__c` | `a6UHa0000004E2nMAE` | `Resultado__c` apontando para o Resultado acima, `Renova_o__c=100` (Opportunity ainda sem DSA — estado válido) |
| 5 | `DSA__c` (1º) | `a00Ha00000OSHBNIA5` | `Oportunidade__c` apontando para a Opportunity acima, contatos de faturamento/entrega = o Contact acima |

## 4. Execução dos cenários

### 4.1 Demais campos do lançamento afetado continuam editáveis (adaptado para dado sintético)

Atualizei `Rentabilidade__c` (campo currency, não ligado a nenhum roll-up) no RFV
sintético, de vazio para `42.5`.

- **Resultado: salvou sem erro** (`"success": true`).

### 4.2 Lançamentos não afetados continuam funcionando

Com a Opportunity em estado válido (0 DSA), atualizei `Renova_o__c` do RFV sintético de
`100` para `250` e conferi o roll-up antes e depois:

- **Resultado: salvou sem erro.**
- Roll-up propagou pela cadeia inteira, confirmado por query:
  - `Resultado__c.RenovacaoRealizado__c`: `100` → `250`
  - `Opportunity.RenovacaoRealizado__c`: `100` → `250`

Isso confirma, agora em QA (não só em dev), que o mecanismo de cascata de roll-up por si só
não causa erro quando a Opportunity respeita as regras ativas — exatamente o cenário Gherkin
"Lançamentos não afetados continuam funcionando".

### 4.3 Reprodução da tentativa de violar M38 (fechamento de lacuna adicional, pedido no escopo)

Criei o 1º `DSA__c` vinculado à Opportunity sintética (estado válido, `N_mero_de_DSA__c=1`
confirmado por query) e tentei criar um 2º `DSA__c` na mesma Opportunity.

- **Resultado: bloqueado na criação do 2º registro**, com
  `FIELD_CUSTOM_VALIDATION_EXCEPTION: Esta Oportunidade já possui um DSA. Revise o DSA já
  existente (Msg38)` — **mensagem e código idênticos ao que `04-plano-build.md` havia
  encontrado em dev.**
- Confirmado por query que o 2º `DSA__c` não foi persistido (rollback automático,
  `COUNT(Id)=1` para a Opportunity de teste).

**Conclusão:** o comportamento de `M38` é igual em QA e em dev — mesma regra, mesmo
bloqueio, mesmo ponto de disparo (na criação do filho via master-detail, não numa edição
posterior de terceiro objeto). Isso reforça, sem confirmar como causa definitiva, que **se**
`M38` for a causa em produção, o estado de violação (2+ DSAs) não foi alcançado por
inserção normal via tela/API nesta org — precisa ter chegado por outro caminho (import,
bypass, ordem histórica). Isso não é uma pergunta que QA consegue responder; depende da
ação humana pendente (§1, item 2).

### 4.4 Limpeza

Todos os 5 registros sintéticos foram apagados, na ordem filho → pai (`DSA__c` →
`Realizacao_Financeira_de_Venda__c` → `Resultado__c` → `Opportunity` → `Contact`).
Confirmado por `sf data query` (contagens, sem dado pessoal) que **zero** registros
sintéticos permanecem em `sbx-somos-agility-qa`:

- `Realizacao_Financeira_de_Venda__c` ligado à Opportunity de teste: 0
- `Resultado__c` ligado à Opportunity de teste: 0
- `DSA__c` ligado à Opportunity de teste: 0
- `Opportunity` com `Name='TESTE DIAGNOSTICO SOMOSAGILITY-23'`: 0
- `Contact` com `LastName='TESTE DIAGNOSTICO SOMOSAGILITY-23'`: 0

## 5. Critérios de aceite — status (`01-analise.md` §4)

| Cenário | Status | Motivo |
|---|---|---|
| Ajustar "Renovação Realizado" no lançamento afetado sem erro | **Não verificado** | Exige o registro real de produção (`a6UU40000000Ue1MAE`) ou a confirmação de qual estado da Opportunity pai reproduz a causa real — nenhuma das duas respostas humanas chegou (§1). Fora do alcance do agente testar isso com dado sintético sem saber qual violação reproduzir de fato. |
| Demais campos do lançamento afetado continuam editáveis | **Passou** (adaptado para dado sintético, §4.1) | Executado em QA, salvou sem erro. |
| Lançamentos não afetados continuam funcionando | **Passou** (§4.2) | Executado em QA com dado sintético ligado a Opportunity em estado válido, salvou sem erro, roll-up propagou corretamente. |
| Causa registrada antes da correção (tipo + objeto responsável) | **Parcialmente atendido** | O tipo de causa continua restrito a validação de estado na Opportunity (mecanismo de cascata confirmado tecnicamente, agora também em QA) e `M38` é a única hipótese reproduzível nesta sandbox — mas **não há confirmação definitiva da causa em produção**. Falta a mensagem de erro exata do cliente e a conferência humana da Opportunity pai em produção (`03-design.md` §3, passos 1 e 2 — ainda pendentes conforme `comentarios-do-card.md`). |
| Validação em sandbox de QA antes de produção | **Executado, com ressalva** | Esta própria etapa rodou de fato em `sbx-somos-agility-qa` pela primeira vez. Os cenários testáveis sem produção (2 e 3 da análise) passaram. O cenário 1 e o fechamento do cenário 4 continuam fora do alcance do agente — dependem de ação humana fora da sandbox. |

## 6. O que não consegui medir, e por quê

- **Não consegui testar o cenário "ajustar o campo no lançamento afetado sem erro"** contra
  o estado real de violação, porque a causa raiz ainda não foi confirmada — sem a mensagem
  de erro exata (pendente) ou a confirmação de qual regra a Opportunity pai de produção
  viola (pendente), qualquer dado sintético que eu monte para "simular a violação" seria
  advinhação, não reprodução. Testei a única hipótese operável nesta sandbox (`M38`, §4.3)
  como evidência de mecanismo, não como confirmação de causa.
- **Não consegui fechar o cenário "causa registrada"** como totalmente atendido, pela mesma
  razão: o tipo de causa está restrito, mas não confirmado.
- **Não consegui confirmar nem descartar `M35`/`M17`-`M20`/`M39`** em QA, porque os campos
  que essas regras avaliam não existem no describe ao vivo do objeto Opportunity nesta
  sandbox (§2) — o mesmo achado de `04-plano-build.md` em dev, agora confirmado também aqui.
- Nenhuma das duas lacunas acima foi contornada com dado inventado, execução em produção ou
  suposição de causa — guardrails #1, #2 e #3 proíbem isso, e "não consegui medir X" é a
  resposta correta aqui, não uma tentativa de simular um resultado.

## 7. Recomendação

1. **Os dois itens pendentes desde o design continuam bloqueantes** para fechar os
   cenários 1 e 4 por completo: (a) mensagem de erro exata do cliente; (b) humano
   autorizado confirmando, em produção, se a Opportunity pai do lançamento
   `a6UU40000000Ue1MAE` tem 2+ `DSA__c`, 2+ propostas SOW "Proposta Fechada pelo Cliente",
   ou campo "Sim" sem descrição obrigatória.
2. O homologador decide, com esses dois pontos em aberto, se aprova a demanda nestes
   termos (aceitando que ela fica sem fechar causa raiz e sem corrigir o registro real,
   já que não há build nesta demanda), ou se segura até as respostas chegarem.
3. Sem build nesta demanda (decisão do design, confirmada): não há metadata para liberar
   release. Se a causa vier a ser confirmada como regra mal desenhada ou falha de subflow,
   o design é refeito e o fluxo volta ao gate do arquiteto.

---

Testes executados. Preciso da sua homologação para liberar o release.
