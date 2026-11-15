# EPLAST-36 — Análise: segmentação da base e criação de públicos

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 4 · Marketing (ainda não contratada; Ondas 1–2 em andamento)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Org de referência:** alias `sbx-eplast-dev` (lido do `assessment.md`, 2026-09-30; não reconfirmado com `sf` nesta sessão — ver premissa P0)
**Status:** análise **não fecha escopo**. Há bloqueio contratual e uma decisão de arquitetura pendente (seções 2 e 5). Não seguir para o arquiteto sem resposta.

---

## 0. Alerta de escopo contratual (ler primeiro)

- O `contrato.md` contrata só as **Ondas 1 (Diagnóstico e desenho) e 2 (Projeto-piloto)**, 120 h, fim previsto **2026-11-30**. A Onda 4 (Marketing) **não está contratada**.
- A demanda inteira é Onda 4. Não há entregável de Marketing no contrato (`eplast-ent-01` a `eplast-ent-12` são todos Sales/SDR/Pós-vendas/Agentforce e medição do piloto).
- Hoje o contrato já tem 12 entregáveis e o fim previsto está a 18 dias. Qualquer design desta demanda consome horas fora do contrato ou exige aditivo.
- **Decisão necessária do humano que aprova o gate:** (a) aditivo de escopo/horas para a Onda 4 antes de design; ou (b) demanda fica parada em `analise` até a contratação; ou (c) entrar como item de backlog do próximo contrato. Este agente não decide isso.
- Atenção: o `contrato.md` cita a "Onda 4 · Marketing" como item de roteiro de 6 ondas, mas o briefing do cliente (`CLAUDE.md` da conta) não tem nenhuma regra de Marketing. A plataforma de Marketing (`eplast-ent-05`, "decisão da plataforma de Marketing") foi entregue na Onda 1, mas o resultado **não está no workspace**. Não sabemos qual plataforma foi decidida.

---

## 1. Contexto de negócio

A demanda pede segmentar a base de clientes e criar públicos por:
- região
- segmento
- produto
- comportamento
- histórico de compra

No Sales Cloud. O texto original é uma linha de proposta comercial, sem processo descrito, sem usuário, sem canal de uso e sem resultado esperado.

Dois pontos de contexto que mudam a análise:

1. **Dado de histórico de compra vem do Protheus.** O `assessment.md` (achados 1 e 2) mostra que a integração Account/Order → ERP Protheus existe e não tem cobertura de teste. O `contrato.md` (`eplast-ent-11`) já registra risco de "qualidade dos dados de pedidos vindos do Protheus". Segmentar por histórico de compra depende de dado que a própria Eplast ainda não validou.
2. **Já existe trabalho de campanha e medição.** O RAG aponta `EPLAST-39` (análise de campanhas/ROI) usando campos padrão de Campaign e relatórios, sem automação. Parte do que "públicos" pede pode já ser coberta por relatório ou membro de campanha. Precisa ser confrontado antes de desenhar algo novo.

---

## 2. Objetivo

Hipótese de objetivo, **não confirmada pelo consultor**: permitir que a equipe de Marketing selecione subconjuntos da base de Contas/Contatos/Leads por critérios de região, segmento, produto, comportamento e histórico, para usar em campanha ou ação comercial.

Métrica de sucesso: não definida. Ver "o que a demanda não diz".

---

## 3. Regra de negócio

Não há regra de negócio explícita na demanda. As regras abaixo são **premissas a validar**, não fatos:

- **RN-1 (premissa P3):** um "público" é um conjunto de registros selecionados por critérios, reconstruído sob demanda ou congelado em um instante. Não é um campo gravado no registro.
- **RN-2 (premissa P4):** "região", "segmento" e "produto" são campos já existentes na org ou derivados de campos existentes. Nenhum campo novo é criado sem aprovação explícita.
- **RN-3 (premissa P5):** "comportamento" e "histórico de compra" são métricas agregadas (ex.: última compra, valor acumulado, tempo sem comprar). A regra de cálculo de cada métrica **não existe ainda** e precisa ser definida pelo negócio.
- **RN-4:** a demanda **não autoriza** escrita em Account, Opportunity ou Order. Se a solução exigir gravar uma classificação em registro, isso vira design à parte, obrigatoriamente passando pelo achado 1 do assessment (automação concorrente em Account/Opportunity/Order).

---

## 4. Riscos do assessment que tocam este pedido

- **Achado 1 (alta) — automação concorrente em Account e Order.** Se a segmentação gravar qualquer campo em Account ou Order, dispara trigger custom + trigger do CPQ + Flows no mesmo evento. Não gravar é a rota de menor risco; se gravar for necessário, o design precisa mapear a ordem de execução antes.
- **Achado 2 (alta) — cobertura Apex de 10%.** Se a solução tiver Apex (ex.: lógica de cálculo de métrica), exige teste dedicado `<Classe>Test` e cobertura ≥ 85% por classe pela convenção do squad. Cadeia Protheus sem teste: não tocar nela nesta demanda.
- **Achado 4 (média) — 68,6% dos campos custom de Account/Order/Opportunity sem descrição.** Campos de região, segmento e produto podem ser ambíguos. Mapeamento de campo precisa de confirmação com o negócio, não de palpite pelo nome.
- **Achado 6 (média) — alias `sbx-eplast-dev` aponta para instância que se identifica como `qa`.** Antes de qualquer build, confirmar que o alias de dev é de fato dev. Bloqueante para confiança na separação de ambientes.
- **Achado de volume:** a sandbox de dev está **vazia** (0 Account/Contact/Opportunity). Segmentação não pode ser validada contra dados nela. Validação de "o público tem os registros certos" exige massa de teste anonimizada ou ambiente com dado (ver guardrail #2: nunca SOQL que devolva dado real de cliente).
- **Trabalho de LGPD (RAG `EPLAST-34`, pendente):** contatos em públicos exportados ou usados em e-mail/WhatsApp envolvem dado pessoal. Já há pergunta bloqueante aberta sobre DPO/jurídico da Eplast.

---

## 5. Perguntas que bloqueiam o design (ambiguidade que muda arquitetura)

Estas precisam de resposta antes de o arquiteto desenhar. Não escolhi nenhuma por conta própria.

**Q1 — "Segmentação inteligente": o que significa?**
- (a) filtros e relatórios padrão do Sales Cloud (list views, relatórios, membros de campanha);
- (b) regras de negócio configuradas com Flow/Apex que classificam registros;
- (c) segmentação por IA (Einstein ou similar, com recomendação automática);
- (d) segmentação em Data Cloud ou Marketing Cloud, com audiência sincronizada para fora do Salesforce.

Cada opção muda o design de forma relevante: (a) é declarativo e baixo risco; (b) mexe em registro e cai no achado 1; (c) depende de licença e pode enviar dado a terceiro (LGPD); (d) é outra plataforma, fora do que a demanda descreve como "no Sales Cloud".

**Q2 — Onde o público vive e para onde vai?** Fica como lista/relatório dentro da Salesforce, vira membro de campanha, é exportado, ou é enviado para Marketing Cloud (`et4ae5` está instalado no org)? Se for enviado, quem é o destinatário e qual é a plataforma definida em `eplast-ent-05`?

**Q3 — Os públicos são congelados (snapshot) ou calculados na hora?** Impacta custo, consistência e o que o usuário vê.

**Q4 — Quem usa e quantas pessoas?** Usuários de Marketing da Eplast; o perfil da licença determina o que podem ver (ex.: `Comercial - Analista`).

**Q5 — Qual é a fonte de "comportamento" e "histórico de compra"?** Pedidos do Protheus replicados em Order? Atividades? Campanhas? Com qual janela de tempo (últimos 12 meses, por exemplo)?

**Q6 — Escopo contratual (seção 0).** Aditivo, espera ou backlog?

---

## 6. O que a demanda NÃO diz

1. Quem é o usuário final (Marketing? Comercial? SDR?) e com que frequência o público é usado.
2. Definição operacional de cada critério (região: por UF, por CEP, por campo de cadastro? segmento: qual lista de valores?).
3. Definição de "comportamento" e de "histórico de compra" (métrica, janela, fonte).
4. Plataforma de destino do público (Q2) e se a Eplast já decidiu isso em `eplast-ent-05`.
5. Se "segmentação inteligente" é IA, regra ou relatório (Q1).
6. Volume esperado de registros e de públicos.
7. Métrica de sucesso e linha de base.
8. Quem aprova o público antes de uso em campanha.
9. Escopo contratual e aprovação de horas da Onda 4 (seção 0).
10. Se o dado de Protheus está validado para este uso (`eplast-ent-11`).
11. Restrições de LGPD: quais campos de contato podem aparecer no público e para quem.
12. Se o trabalho sobrepõe o que `EPLAST-39` já cobre (campanhas e influência).
13. Se há um público já existente que o time usa hoje e que esta demanda pretende substituir.
14. Prazo desejado. Com fim do contrato em 2026-11-30, não há janela de Onda 4 sem aditivo.

---

## 7. Critérios de aceite (Gherkin)

Os critérios abaixo são **provisórios**. Só valem depois de Q1 e Q2 respondidas. Estão escritos para o caso (a) — filtros e relatórios padrão — que é o único de risco baixo. Para (b), (c) e (d), a análise será refeita.

```gherkin
Funcionalidade: Públicos de segmentação na base (Sales Cloud, caso a - provisório)

  Cenário: Criar público por região
    Dado que o usuário de Marketing tem acesso de leitura às Contas com o campo de região preenchido
    Quando ele cria um público com o critério "região = <valor>"
    Então o público retorna somente Contas cuja região é <valor>
    E a contagem exibida é igual à contagem de um relatório de controle com o mesmo filtro

  Cenário: Criar público combinando critérios
    Dado que existem Contas nas regiões "<A>" e "<B>" e segmentos "<X>" e "<Y>"
    Quando o usuário cria um público com "região = <A>" E "segmento = <X>"
    Então o público contém somente Contas com região <A> e segmento <X>
    E nenhuma Conta de outro par fica no público

  Cenário: Público por histórico de compra (depende de P5 e Q5)
    Dado que a métrica "última compra" está definida como <regra aprovada>
    Quando o usuário cria um público com "última compra há mais de N dias"
    Então o público contém somente Contas cuja última compra está além de N dias, pela regra aprovada

  Cenário: Público não grava em registro
    Dado que o público foi criado
    Quando o usuário consulta Account, Opportunity e Order
    Então nenhum campo novo ou alterado foi gravado nesses registros pela criação do público

  Cenário: Acesso respeita perfil
    Dado que um usuário sem permissão de Marketing
    Quando tenta criar ou ver um público de Marketing
    Então o acesso é negado ou o público não aparece

  Cenário: Validação sem dado real
    Dado que o ambiente de dev não tem registros de produção
    Quando o teste usa massa anonimizada aprovada pelo cliente
    Então os resultados dos cenários acima são comparados contra o resultado esperado da massa
    E nenhum dado real de cliente aparece em log, print ou no 05-testes.md
```

Observações sobre os critérios:
- "Contagem igual a relatório de controle" é testável. Não usa valor fixo porque não há massa de dados no dev.
- Os cenários de histórico de compra não são testáveis até P5/Q5 serem respondidos. Estão aqui para não serem esquecidos.
- Nenhum critério trata de LGPD ou de exportação. Entram depois da resposta da pergunta LGPD (RAG `EPLAST-34`).

---

## 8. Premissas a validar (todas PENDENTES)

- **P0 — Org.** O alias `sbx-eplast-dev` foi lido pelo assessment de 2026-09-30. Não reconfirmado com `sf org list` nesta sessão. O assessment (achado 6) põe em dúvida se o alias é dev de fato. Confirmar antes de qualquer build.
- **P1 — Objetos padrão.** Account, Contact, Lead e Campaign existem e são usados. Não confirmei campos de região, segmento e produto com `sf` nesta sessão. Qualquer nome de campo citado depois precisa de `sf sobject describe` antes de entrar em design (guardrail #3).
- **P2 — Licença.** O usuário de Marketing tem licença que permite criar list view, relatório e público. Não verificado. A org tem 14 de 14 licenças Salesforce usadas na sandbox (assessment).
- **P3 — Modelo de público.** Premissa de público como conjunto reconstruído por critério (RN-1). Pendente de Q3.
- **P4 — Campos existentes.** Premissa de que região, segmento e produto já existem. Pendente de confirmação com `sf` e com o cliente.
- **P5 — Métricas de comportamento e compra.** Ninguém definiu. Pendente de Q5.
- **P6 — Dado do Protheus.** Premissa de que Order chega à org com histórico suficiente para as métricas. Contrariada parcialmente pelo risco em `eplast-ent-11`. Pendente de validação com o Comercial.
- **P7 — Escopo.** Premissa de que a Onda 4 será contratada ou aditada antes de design. Não há evidência disso no workspace.

---

## 9. Complexidade

**M (médio), com risco de virar G.**

Justificativa: com a interpretação (a), é configuração declarativa com baixo risco técnico, mas a definição das métricas e a validação de dados são trabalho de negócio sem sandbox com dados. Com (b), (c) ou (d), vira G: mexe em registro (achado 1), exige Apex com teste (achado 2) ou cria integração de plataforma nova.

---

## 10. Estimativa

**Estimativa de esforço:** 12–40 h

Premissas que mais pesam na faixa:
- **12 h (limite inferior):** interpretação (a) — filtros e relatórios padrão, sem gravação em registro, critérios já definidos pelo cliente, validação por relatório de controle.
- **40 h (limite superior):** interpretação (b) ou (c) com lógica de classificação em registro, mapeamento de campos sem descrição (achado 4), definição de métricas de compra com dado do Protheus, e validação de LGPD.
- Fora da faixa: interpretação (d) (Data Cloud ou Marketing Cloud). Não estimada aqui; exige nova análise e nova proposta.
- Não inclui: aditivo de escopo, reunião com o negócio para definir métricas, nem a curadoria de campos (achado 4), que o cliente pode fazer por conta própria.

---

## 11. Próximo passo

Responder Q1–Q6 e a seção 6 com o consultor e o cliente. Confirmar P0 e P1 com `sf` antes de qualquer design. Decidir o escopo contratual (seção 0) antes do gate.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
