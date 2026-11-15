# EPLAST-31 — Previsão de vendas por vendedor, região, carteira e período

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), **não contratada** no projeto atual (Ondas 1–2)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Status:** análise para validação humana. **Não pronta para design.** A pergunta da seção 0 (escopo contratual) bloqueia o desenho até ser respondida pelo gestor de conta, e as perguntas da seção 5 mudam a arquitetura.

Fontes usadas: `demandas/EPLAST-31/demanda.md` (história do consultor, três linhas), `assessment.md` (2026-09-30, org `sbx-eplast-dev`), `contrato.md` (materializado pelo Squad OS, Status Report semana 05), e o RAG de delivery (análises anteriores deste cliente, citadas onde usadas). O documento de origem (Solicitação de Proposta) não está no workspace, então o texto da demanda é o único enunciado disponível. Nenhuma consulta `sf` foi feita nesta etapa: tudo o que se diz sobre a org abaixo vem do assessment e está marcado como a confirmar.

---

## 0. Pendência bloqueante: escopo contratual

`demanda.md` declara "Onda 3 · Comercial — ainda não contratada no projeto atual (Ondas 1–2)". `contrato.md` confirma: o contrato cobre Ondas 1 e 2 (120 h, fim previsto 2026-11-30); Ondas 3, 4 e 5 não foram contratadas. A demanda não diz se existe aditivo, autorização comercial ou decisão de antecipar o escopo.

Não decidi isso por conta própria. **Antes do design, o gestor de conta precisa confirmar por escrito uma destas opções:**

- (a) a Onda 3 foi autorizada e entra na esteira com horas próprias;
- (b) a demanda fica em `backlog` como antecipação, sem trabalho de design ou build até o aceite;
- (c) a demanda sai do escopo deste projeto e vai para uma proposta futura.

Contexto de cronograma: hoje (2026-11-10) estamos na semana 7 do projeto; o fim do contrato é 2026-11-30. Com a medição do piloto (`eplast-ent-12`) na semana 9, a janela para qualquer trabalho novo dentro do contrato atual é curta. Mesmo padrão aparece em outras demandas da Onda 3 deste cliente [demandas/EPLAST-25/01-analise.md] [demandas/EPLAST-27/01-analise.md].

---

## 1. Contexto de negócio

A Eplast quer enxergar a previsão de vendas por vendedor, região, carteira e período. A demanda não diz quem consome essa previsão (diretoria, gerência comercial, vendedor), com que frequência, nem qual decisão ela sustenta (ajuste de meta, alocação de carteira, cobrança de pipeline, reforço de equipe).

**Sobreposição com outra demanda.** A EPLAST-32 descreve um painel mensal que compara meta, carteira, faturado, pedidos imputados, projeção e gap, por vendedor ou equipe [demandas/EPLAST-32/01-analise.md]. Previsão por vendedor, região e período e "projeção vs. meta" são, em grande parte, o mesmo problema visto de dois ângulos. Antes de qualquer desenho, é preciso dizer se a EPLAST-31 é (i) a mesma entrega da EPLAST-32, (ii) um subconjunto dela, ou (iii) uma entrega diferente, que usaria os mesmos dados. Se for o caso (i) ou (ii), o escopo contratual da seção 0 vale para as duas.

Como a demanda não define "previsão", esta análise não escolhe uma definição. Três leituras plausíveis, que levam a arquiteturas diferentes:

- **Previsão nativa do Salesforce (Forecasting).** Agregação de oportunidades por vendedor e período, usando valor, data de fechamento e categoria de previsão. Não precisa de IA.
- **Projeção estatística ou por IA.** Estimativa do que será fechado com base em histórico, com modelo próprio ou recurso de IA da plataforma. Depende de histórico suficiente, que o assessment não pôde medir (sandbox sem registros).
- **Painel analítico.** Consolidação de dados de Opportunity, Order e meta em tela ou relatório, sem previsão calculada pelo sistema.

## 2. Objetivo

Dar ao comercial uma visão de previsão de vendas por vendedor, região, carteira e período, de forma que o usuário não precise montar a conta manualmente.

**Lacuna:** a demanda não tem métrica de sucesso, nem valor de referência, nem prazo. Proposta a validar (não assumida): erro entre previsão e realizado por período, medido contra o baseline `eplast-ent-06` e a medição do piloto `eplast-ent-12`. Essa métrica só é válida se a previsão for calculada pelo sistema, o que depende da leitura escolhida na seção 1.

## 3. Regra de negócio

A demanda não permite inferir regra de negócio concreta. O que segue é a lista de regras que precisam existir, com o conteúdo pendente:

- RN-1. Previsão = [PENDENTE Q3: fórmula — soma de valor de oportunidades por categoria? valor ponderado por probabilidade? projeção histórica?].
- RN-2. Recorte por vendedor, região e carteira. Como uma oportunidade ou conta pertence a uma região e a uma carteira: [PENDENTE Q5 — owner da conta? território? campo específico? a org não tem território confirmado no assessment].
- RN-3. Período = [PENDENTE Q6 — mês, trimestre, ano; fechamento de previsão por data de fechamento ou data de faturamento?].
- RN-4. Meta de referência = [PENDENTE Q4 — de onde vem a meta, quem a cadastra, em qual objeto; a org não foi lida para isso].
- RN-5. Faturado/realizado, se entrar na conta = [PENDENTE Q4 — vem de Order, que é alimentado pela integração com o ERP Protheus, ou de outra fonte].
- RN-6. Visibilidade: cada perfil vê o recorte da sua posição na hierarquia [PENDENTE Q9 e Q10].

## 4. Critérios de aceite (rascunho em Gherkin)

**Rascunho.** Os cenários abaixo são testáveis na forma, mas os valores e as fontes dependem das respostas da seção 5. Onde falta informação, o texto está entre colchetes. Não considerar aprovados.

```gherkin
Funcionalidade: Previsão de vendas por vendedor, região, carteira e período

  Cenário: Vendedor vê somente a própria carteira
    Dado um usuário vendedor associado à carteira A [PENDENTE Q5]
    E previsões calculadas para as carteiras A e B no período [PENDENTE Q6]
    Quando o usuário consulta a previsão
    Então vê apenas os valores da carteira A
    E nenhum valor da carteira B aparece, nem em totais agregados

  Cenário: Total da previsão reconcilia com as oportunidades de origem
    Dado um período P e um recorte R com N oportunidades na fonte [PENDENTE Q3]
    Quando a previsão do recorte R é calculada para o período P
    Então o total exibido é igual ao total recalculado a partir das N oportunidades, pela regra RN-1
    E a diferença entre os dois é zero em um conjunto de dados sintético de referência

  Cenário: Sem meta cadastrada, não inventa número
    Dado um vendedor sem meta cadastrada no período P [PENDENTE Q4]
    Quando a visão de meta vs. previsão é aberta
    Então o campo de meta mostra "sem meta cadastrada"
    E não mostra zero nem média de outros vendedores

  Cenário: Consulta não altera registros
    Dado um usuário com acesso à previsão
    Quando a previsão é consultada, filtrada e exportada [PENDENTE Q8]
    Então nenhum registro de Opportunity, Account ou Order é criado ou alterado
    E a contagem de registros desses objetos é igual antes e depois da consulta

  Cenário: Acesso restrito por permissão
    Dado um usuário sem o permission set [PENDENTE Q9 — nome do permission set]
    Quando tenta abrir a previsão, por tela ou por chamada direta ao componente
    Então a visão não aparece
    E a chamada direta é negada
```

Observação sobre testabilidade: "a previsão é boa" (acurácia, aceitação pelo comercial) não é critério de aceite nesta versão. Vira critério só depois que a métrica da seção 2 for definida.

---

## 5. O que a demanda NÃO diz (perguntas a responder antes do design)

Ordem de prioridade. As Q1 a Q3 bloqueiam o design; as demais definem escopo e critérios.

1. **(Bloqueante)** A Onda 3 foi autorizada? Qual das três opções da seção 0? Se for (b) ou (c), esta etapa para aqui.
2. **(Bloqueante)** A EPLAST-31 é a mesma entrega da EPLAST-32, parte dela, ou separada? Se for a mesma, uma das duas precisa ser retirada ou reescrita.
3. **(Bloqueante)** O que é "previsão"? Escolher entre previsão nativa do Salesforce, projeção estatística ou por IA, ou painel analítico (seção 1). Essa escolha muda a plataforma e o esforço; não é decisão do BA nem do agente.
4. **Fonte de meta e de realizado.** De onde vêm a meta por vendedor/região e o valor realizado? Meta é cadastrada no Salesforce, numa planilha, ou vem de outro sistema? Faturado vem de Order, que hoje depende da integração com o Protheus? A qualidade dos pedidos vindos do Protheus já é um risco registrado no `contrato.md` (`eplast-ent-11`).
5. **Carteira e região.** Como uma conta ou oportunidade pertence a uma carteira e a uma região? Owner, território, campo custom ou hierarquia de papéis? O assessment não confirmou nenhum modelo de território, e a sandbox de dev não tem registros para inferir a estrutura.
6. **Período.** Granularidade (mês, trimestre, ano), horizonte de previsão e critério de data (fechamento, faturamento ou criação).
7. **Canal e frequência.** Onde a visão aparece (Lightning page, relatório, dashboard, assistente de IA) e com que frequência é usada.
8. **Escrita.** A primeira versão é somente leitura, ou precisa gravar algo (ajuste de previsão, submissão, campo de categoria)? Se gravar em Opportunity, entra no risco de automação concorrente do assessment (seção 6).
9. **Público e perfis.** Quem usa e quem vê o quê. O assessment encontrou quatro variações de perfil comercial (`Comercial`, `Comercial - Analista`, `Comercial - Analistas`, `Comercial Padrão`). Gestor vê a equipe? Vendedor vê só a própria conta?
10. **Visibilidade no modelo de compartilhamento.** O OWD de Opportunity e Account não foi medido pelo assessment. Sem isso, não dá para afirmar a regra de visibilidade da seção 4.
11. **Dados pessoais.** A previsão individual por vendedor expõe performance de pessoa identificável. Quem pode ver isso e por quanto tempo esses dados são guardados? Não há regra de dados sensíveis preenchida no `CLAUDE.md` da Eplast.
12. **Critério de sucesso e medição.** Entra na medição do piloto (`eplast-ent-12`) ou fica fora? Qual métrica de erro e qual limite aceitável?
13. **Prazo e orçamento.** Quando precisa estar pronto, e a estimativa de horas tem teto contratual? A demanda não diz.
14. **Documento de origem.** A Solicitação de Proposta não está no workspace. O texto da proposta para este item deveria ser anexado ou colado em `demanda.md`.

---

## 6. Premissas a validar (todas pendentes)

Nada abaixo foi confirmado. Cada uma vira decisão só depois de validada pelo humano.

- **P-1 (pendente):** a Onda 3 está autorizada para entrar na esteira (Q1).
- **P-2 (pendente):** a primeira versão é somente leitura. Não grava em Opportunity, Account, Order, Task nem em meta.
- **P-3 (pendente):** a previsão, se for calculada pelo sistema, usa dados de Opportunity (valor, data de fechamento, estágio, categoria de previsão). Confirmar nomes de campo via `sf` antes de usar (guardrail #3). Não confirmado nesta etapa.
- **P-4 (pendente):** o realizado, se entrar, vem de Order já existente na org e não cria nova integração com o Protheus.
- **P-5 (pendente):** carteira e região são derivadas de um campo ou relação já existente. Não foi criado um modelo de território novo.
- **P-6 (pendente):** a validação de comportamento é feita com dados sintéticos em `sbx-eplast-dev`, sem copiar dado real de cliente para a sessão (guardrail #2).
- **P-7 (pendente):** a plataforma de IA, se houver, é decidida pelo arquiteto depois de Q3. Esta análise não assume nenhuma.
- **P-8 (pendente):** a visão não entra em produção sem o aceite do cliente, e o cronograma é definido com ele.

### Riscos do assessment que tocam esta demanda

- **Automação concorrente em Opportunity (achado 1, severidade alta).** Opportunity tem trigger custom, triggers do CPQ (`OpportunityAfter`, `OpportunityBefore`) e dois Flows `RecordAfterSave`, no mesmo evento. Uma demanda de leitura não aumenta esse risco. Qualquer escrita em Opportunity (Q8) aumenta. Se a previsão exigir campo ou gatilho novo, o mapeamento da ordem de execução vira pré-requisito do design.
- **Cobertura de teste em 10% (achado 2, severidade alta).** Se a solução exigir Apex, o deploy fica abaixo do mínimo de 75% e do padrão do squad (85%). A cadeia Account/Order → Protheus não tem teste identificável. Se o faturado vier de Order (P-4), a dependência entra no escopo.
- **Descrição ausente em campos custom (achado 4).** 19 de 28 campos custom de Opportunity e 53 de 64 de Order não têm `Description`. Escolher o campo errado para "valor previsto" ou "realizado" é um risco real. Cada campo usado precisa de confirmação com o cliente, não só pelo nome.
- **Alias de dev apontando para sandbox com nome de qa (achado 6).** Antes de qualquer build, confirmar com o cliente que `sbx-eplast-dev` é de fato o ambiente de dev. Sem isso, não se pode confiar na separação dev/qa.
- **Perfis comerciais duplicados (achado 8).** Afeta Q9 e a montagem das permissões. A visão precisa ser atribuída por permission set, não por perfil.
- **Dados vazios em dev (seção "Não pôde ser medido").** Não há registros em Account, Contact ou Opportunity na sandbox. Volume, distribuição de valores e qualidade de dados de previsão não podem ser inferidos daqui.

---

## 7. Complexidade

**G.** Justificativa: escopo ainda indefinido (três leituras possíveis de "previsão"), toca Opportunity com automação concorrente, o realizado pode depender do Protheus sem teste de cobertura, e a execução depende de decisão contratual sobre a Onda 3.

---

## 8. Estimativa de esforço humano

**Estimativa de esforço:** 60–160 h

Premissas que mais pesam na faixa:

- Faixa larga porque a definição de "previsão" (Q3) muda o trabalho em uma ordem de grandeza. Na ponta baixa, a visão é de leitura e usa a previsão nativa ou um painel sobre dados já existentes. Na ponta alta, há cálculo próprio, integração com Order/Protheus, Apex com teste de cobertura e configuração de permissão por carteira.
- Inclui: configuração, revisão, teste em dev, homologação com o comercial e ajustes.
- Não inclui: mapeamento da automação concorrente em Opportunity (estimado à parte, 16–24 h, se a escrita for necessária), o próprio processo de aceite contratual, nem o trabalho de curadoria de descrição de campos (achado 4).
- Não inclui: o esforço do agente. A calibração pelo timesheet fica no Squad OS.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
