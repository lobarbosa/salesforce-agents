# CENTRIC-3 — Integração com Omie — Análise (ba-discovery)

**Cliente:** centric · **Tipo:** sustentação · **Etapa:** 1 (refinamento de critérios)
**Fonte:** `demandas/CENTRIC-3/demanda.md` (contém somente o título "# Integração com Omie")
**Org de referência:** `sbx-centric-dev` (conforme `assessment.md` de 2026-10-03; não reconfirmei com `sf org list` nesta etapa, que é só leitura de documentação — a confirmação da org fica para o recon)

> **ALERTA — DEMANDA INSUFICIENTE PARA ANÁLISE FUNCIONAL.**
> O consultor enviou apenas o título. Não há descrição do problema, regra de negócio, direção do fluxo,
> gatilho, objeto afetado nem critério de aceite. Esta análise **não inventa a demanda**: abaixo está a
> estrutura completa, com o que é possível afirmar a partir do assessment, as perguntas que bloqueiam o
> design e as faixas largas de esforço. Nenhum critério funcional foi escrito como se fosse aprovado.
>
> **Histórico relevante:** `demandas/CENTRIC-2/demanda.md` tem exatamente o mesmo conteúdo ("# Integração com Omie"),
> foi criada em 2026-11-11 20:55 e **cancelada pelo consultor** às 20:56 (`status.yaml`, motivo "cancelar").
> Pode ser reenvio por engano ou nova tentativa do mesmo pedido sem descrição. Confirmar antes de seguir.

## 1. Contexto de negócio

A Centric usa o Omie (ERP) integrado ao Salesforce por código próprio (família de classes `Omie*`, incluindo
`OmieApiClient`, `OmieProdutoServiceTest`, `OmieProdutoRetryBatch`, `OmieServicoRetryBatch`). Pelo histórico
de RAG, o pedido "Integração com Omie" já apareceu antes sem descrição, sem resultado registrado. Não há
no repositório nenhuma descrição do que a integração faz hoje além do nome das classes e do endpoint
`app.omie.com.br` liberado em Remote Site Settings.

## 2. Objetivo

**Não definido.** A demanda não diz se o objetivo é corrigir um defeito, mudar um comportamento, trocar um
endpoint, adicionar um objeto ao sincronismo ou outra coisa. Objetivo será escrito após as respostas da seção 6.

## 3. Regra de negócio

**Não há regra de negócio enviada.** Não vou descrever regra de sincronismo (quem é a fonte de verdade de
produto, cliente, pedido ou nota, em qual direção, com que frequência) porque nada disso está na demanda nem
foi confirmado na org.

Fatos confirmados pelo assessment (org `sbx-centric-dev`, 2026-10-03), que tocam qualquer mudança nessa integração:

- **Named Credential: 0.** A integração com Omie usa Remote Site Settings (`app.omie.com.br`) e autenticação feita
  no código Apex (`OmieApiClient`). Achado #5, severidade média. Recomendação do assessment: migrar a integração
  própria para Named Credential "na próxima vez que `OmieApiClient` for tocado". **Se a demanda tocar
  `OmieApiClient`, a migração para Named Credential vira decisão de design, não detalhe — e precisa de
  confirmação humana, porque muda a forma como a credencial é guardada.**
- **Cobertura Apex 0% nas classes `Omie*`.** Achado #3, severidade alta. As 16 classes próprias com dado de
  cobertura estão em 0%, apesar de existirem 10 classes de teste dedicadas. O assessment ressalva que pode ser
  só "os testes não rodaram desde o último refresh" e não confirmou com `sf apex run test` (fora do escopo
  read-only daquela sessão). Para esta demanda, a leitura prática é: **antes de alterar qualquer `Omie*`, a
  suíte precisa rodar na sbx-dev para termos linha de base real.** `OmieProdutoRetryBatch` e
  `OmieServicoRetryBatch` não têm classe de teste dedicada aparente.
- **Metadata API bloqueada (achado #1, alta).** Em 2026-10-03, `sf project retrieve start` e `deploy` falhavam
  com `SOAP API does not support JWT-based access tokens for API versions below 68.0` (org em v67.0).
  **Bloqueio de build/retrieve, não risco futuro**, se ainda estiver assim. Não sei se foi corrigido desde
  então — precisa de teste de conexão antes de qualquer etapa de build.
- **Dependência de Opportunity (achado #2).** Se a integração escreve em Opportunity ou OpportunityLineItem,
  há 20 Flows ativos e 13 validation rules (7 ativas) no objeto. Qualquer escrita via integração pode disparar
  ou ser bloqueada por essas automações. Mapa de ordem de execução não foi feito.
- **Campos sem descrição (achado #4).** 100% dos 88 campos custom de Opportunity sem descrição. Se a demanda
  criar campo novo para a integração, a convenção do squad pede descrição preenchida.
- **Remote Site Settings vs. objeto sincronizado:** se o pedido exigir novo endpoint Omie, o domínio
  `app.omie.com.br` já está liberado; outro domínio exigiria novo Remote Site Setting e nova decisão.

## 4. Critérios de aceite (Gherkin)

**Nenhum critério funcional está escrito**, porque a demanda não diz o que deve acontecer. Escrever um Gherkin
agora seria inventar regra. Os critérios abaixo valem **independentemente do escopo** (guardrails e convenção
do squad) e são testáveis:

```gherkin
Funcionalidade: Guardrails de qualquer alteração na integração Omie (CENTRIC-3)

  Cenário: Nenhuma escrita em produção
    Dado que a alteração foi construída na branch feature/CENTRIC-3
    Quando a esteira executa qualquer etapa de build ou teste
    Então todos os comandos sf usam o alias sbx-centric-dev ou sbx-centric-qa
    E nenhum deploy ou DML é executado contra a org de produção

  Cenário: Cobertura mínima nas classes alteradas
    Dado que uma classe Apex "Omie*" foi criada ou alterada nesta demanda
    Quando a suíte de testes roda na sbx-centric-dev
    Então a classe alterada tem cobertura igual ou superior a 85%
    E existe classe de teste dedicada <Classe>Test para ela

  Cenário: Linha de base medida antes da mudança
    Dado que a demanda altera qualquer classe Omie*
    Quando o recon (etapa 2) é concluído
    Então o relatório registra a cobertura medida pela suíte rodada na sbx-centric-dev antes da alteração
    E a cobertura de 0% do assessment é confirmada ou refutada com dado de execução
```

Os critérios funcionais (ex.: "dado um pedido no Salesforce, quando X, então o Omie recebe Y") serão escritos
depois das respostas da seção 6.

## 5. O que a demanda NÃO diz

1. Qual é o problema ou a mudança desejada (texto da demanda é só o título).
2. Tipo: **bug**, **nova funcionalidade**, **mudança de endpoint/versão da API Omie**, **ajuste de retry**,
   **novo objeto sincronizado** ou outra coisa.
3. Direção do fluxo de dados: Salesforce → Omie, Omie → Salesforce, ou bidirecional.
4. Quais objetos Salesforce e Omie estão envolvidos (Account, Opportunity, OpportunityLineItem, Product2,
   pedido/nota, cliente, produto, serviço — o código sugere produto e serviço).
5. Gatilho: evento de registro (criação, edição, mudança de estágio), agendamento, ação manual, ou o batch de retry.
6. Impacto esperado: qual processo de negócio quebra hoje, quem percebe, qual o volume e a frequência.
7. Se o problema já tem erro registrado (log, mensagem, registro de falha em `OmieRetry`/equivalente) e um exemplo
   sem dado pessoal (guardrail #2).
8. Se a demanda é a mesma que a CENTRIC-2 (cancelada hoje, mesmo texto) ou um novo pedido.
9. Prazo ou janela de deploy, e aprovador do cliente (CLAUDE.md de centric ainda não preenchido com essas regras).
10. Se o pedido depende de a Metadata API estar desbloqueada na conexão (achado #1) — isso é do squad, não do cliente,
    mas precisa ser verificado.

## 6. Perguntas que precisam de resposta antes do design

Bloqueiam o `arquiteto`. Sem elas, não há como decidir declarativo vs. código, nem se a Named Credential entra:

1. **O que exatamente muda na integração com Omie?** (descrição do problema ou da funcionalidade, com exemplo sem dado pessoal)
2. **É bug, nova funcionalidade, mudança de endpoint, ajuste de retry ou novo objeto sincronizado?**
3. **Direção do fluxo:** Salesforce → Omie, Omie → Salesforce ou ambos?
4. **Gatilho:** evento no registro, agendamento, ação manual ou o batch de retry?
5. **Objetos envolvidos** em cada lado, e se a integração escreve em Opportunity/OpportunityLineItem.
6. **Esta demanda substitui ou reenvia a CENTRIC-2 (cancelada)?** Por que foi cancelada, se for o caso?
7. **Pode ser liberada a migração de autenticação para Named Credential** se `OmieApiClient` for tocado? (achado #5 — decisão de segurança que o cliente precisa conhecer)
8. **Qual o prazo e a janela de deploy aceitos?** (ainda não há regra no CLAUDE.md de centric)

## 7. Premissas a validar (todas PENDENTES)

- **P1 — Sustentação, não projeto.** Assumido pelo tipo informado no pedido. Pendente confirmação.
- **P2 — A conexão de dev precisa ser funcional antes da etapa de build.** O bloqueio de Metadata API do assessment
  (2026-10-03) pode ter sido resolvido ou não; não verifiquei nesta etapa. **Pendente: `sf project retrieve start --metadata ApexClass:OmieApiClient` na sbx-dev antes do design.**
- **P3 — A integração está em uso produtivo.** Não há dado de uso (sandbox de dev tem 0 registros em Account/Opportunity/Contact).
  Pendente saber se há produção rodando com a integração e se há fila de retry real.
- **P4 — A cobertura 0% é real ou defasada.** Pendente rodar `sf apex run test` na sbx-dev.
- **P5 — Autenticação atual do Omie fica no Apex.** Confirmado pelo assessment (sem Named Credential), mas não li o código de `OmieApiClient` nesta etapa.

## 8. Complexidade

**Indefinida — a confirmar.** Sem descrição não dá para classificar em P/M/G com justificativa honesta. Faixa provisória:

- Se for ajuste pontual em uma classe `Omie*` sem mudança de contrato (ex.: correção de retry): tende a **P**.
- Se tocar autenticação (Named Credential), retry/batch e cobertura de teste de uma vez: **M**.
- Se for novo objeto sincronizado ou mudança de direção do fluxo, somando Opportunity com 20 Flows: **G**.

## 9. Estimativa de esforço

**Estimativa de esforço:** 4–24 h
Premissas que mais pesam na faixa:
- Escopo totalmente indefinido (seção 5) — a faixa cobre desde ajuste pontual até mudança de objeto sincronizado.
- Se a suíte de teste `Omie*` estiver de fato em 0% e não rodar limpa, o custo sobe: achado #3 exige linha de base e
  testes para `OmieProdutoRetryBatch` e `OmieServicoRetryBatch`, sem classe de teste dedicada aparente.
- Se a Metadata API continuar bloqueada na conexão (achado #1), soma o tempo de correção da conexão do Connected App.
- Se o pedido exigir migração para Named Credential (achado #5), soma configuração, teste de callout e revisão de segurança.
- Revisão e homologação humanas não incluídas nesta faixa além do que o `arquiteto` refinar no design.

## 10. Riscos do assessment que tocam esta demanda (resumo)

| Achado | Severidade | Toca a demanda como |
|---|---|---|
| #1 Metadata API bloqueada (v67 + JWT) | alta | Bloqueia retrieve/deploy na esteira; confirmar antes do build |
| #2 Opportunity com 20 Flows ativos + 13 VRs | alta | Risco de interação se a integração escreve em Opportunity |
| #3 Cobertura Apex 0% nas `Omie*` | alta | Linha de base obrigatória antes de alterar; 85% por classe alterada |
| #4 Campos sem descrição | média | Convenção para campo novo criado na demanda |
| #5 Remote Site Settings sem Named Credential | média | Decisão de segurança se `OmieApiClient` for tocado |
| #6 Validation rule de endereço duplicada | baixa | Só se a integração depender de endereço |

## 11. Próximo passo

Aguardar a descrição do consultor (seção 6). Sem resposta, a demanda fica em análise. Não acionar o `arquiteto` com este conteúdo.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
