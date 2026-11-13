# EPLAST-31 — Design: previsão de vendas por vendedor, região, carteira e período

**Cliente:** Eplast · **Tipo:** projeto · **Onda 3 (Comercial), não contratada** · **Org do recon:** `sbx-eplast-dev` (ver `02-recon.md`, coleta de 2026-11-10)
**Status deste design:** **incompleto por decisão.** Não escolhi arquitetura. As três perguntas bloqueantes da análise (Q1 escopo contratual, Q2 sobreposição com EPLAST-32, Q3 o que é "previsão") seguem sem resposta. `comentarios-do-card.md` só registra a aprovação do gate da análise, sem resposta a nenhuma pergunta.

**Este design não libera build.** Ele entrega: (1) o recon, (2) as restrições que valem para qualquer opção, (3) as opções comparadas com o que a org de fato tem, e (4) o que o humano precisa decidir para o design ser concluído.

---

## 0. O que falta decidir, e o que o recon acrescentou a cada pergunta

| # | Pergunta | Quem decide | O que o recon mostrou |
|---|---|---|---|
| Q1 | A Onda 3 foi autorizada? (a) entra com horas próprias, (b) fica em backlog, (c) sai do escopo | Gestor de conta | Nada técnico muda a pergunta. `contrato.md` cobre Ondas 1–2 (120 h, fim 2026-11-30). Se a resposta for (b) ou (c), esta demanda volta para `backlog` e nada mais deste documento se aplica agora |
| Q2 | EPLAST-31 e EPLAST-32 são a mesma entrega, uma contém a outra, ou são separadas? | Gestor de conta + cliente | EPLAST-32 está em `backlog`, só com `demanda.md`. **A análise cita `demandas/EPLAST-32/01-analise.md`, que não existe** no disco nem no RAG. A sobreposição foi inferida dos dois textos de demanda, não de uma análise. A EPLAST-32 afirma que "a pergunta do agente sobre o gap da meta mensal já foi entregue", mas **não há meta em lugar nenhum da org de dev** (seção 2.4). As duas demandas dependem da mesma fonte de meta, que ninguém localizou |
| Q3 | O que é "previsão"? | Cliente (comercial) + arquiteto humano | O recon achou uma **quarta leitura** que a análise não listou: hoje o comercial chama de "previsão" os **pedidos (Order) com `ExpectedSaleDate__c` no período** (relatório `Previso_de_Pedidos_Perodo_Yko`). São quatro opções, comparadas na seção 3 |

Duas perguntas não bloqueantes da análise ficaram mais concretas, e precisam de resposta junto com Q3:

- **Q5 (carteira e região):** os relatórios em uso tratam **carteira = contas do proprietário** (`Account.OwnerId`) e **região = UF de cobrança** (`Account.BillingState`), com agrupamentos como "SUL" e "CO". Isso é prática, não regra confirmada. O cliente precisa dizer se é essa a definição.
- **Q4 (meta):** sem fonte de meta, nenhuma opção entrega "previsão vs. meta". Se a meta for parte do pedido, alguém precisa dizer onde ela está hoje.

Mesmo padrão já aplicado neste cliente: EPLAST-27 e EPLAST-39 também tiveram o design entregue com as lacunas de escopo declaradas, sem preencher por suposição (RAG: `demandas/EPLAST-27/03-design.md`, `demandas/EPLAST-39/03-design.md`).

---

## 1. Decisão

### 1.1 O que fica decidido agora (vale para qualquer opção)

1. **Primeira versão é somente leitura.** Nenhuma opção grava em Opportunity, Account ou Order. Motivo: a seção 5 (automação concorrente). Se a resposta a Q3 ou Q8 exigir escrita, o design volta para revisão.
2. **Nível preferido é configuração** (relatório, tipo de relatório, campo de agrupamento em relatório, dashboard, configuração do Forecasting). Flow só se houver cálculo que o relatório não faça. **Apex não está justificado** por nenhuma das leituras com o que se sabe hoje. Com cobertura de 10% na org (achado 2), código novo também traz risco de deploy.
3. **Acesso por permission set, nunca por perfil.** Nenhum perfil novo, nenhuma alteração nos quatro perfis comerciais (achado 8).
4. **Nenhuma mudança de hierarquia de papéis, território ou compartilhamento nesta esteira sem decisão de arquiteto sênior** (seção 6).
5. **Teste com dados sintéticos mínimos em dev**, sem bypass global de automação (mesma regra da EPLAST-39, RAG `demandas/EPLAST-39/03-design.md`).

### 1.2 O que NÃO está decidido

A arquitetura. As quatro opções da seção 3 usam objetos, recursos e licenças diferentes. Escolher uma agora seria decidir por suposição o escopo que o cliente pediu. Isso não é papel do agente.

---

## 2. O que a org já tem (resumo do recon)

### 2.1 Forecasting nativo: ligado, sem estrutura

- `enableForecasts = true`. Um tipo ativo: `Opportunity_Amount` (receita de oportunidade, hierarquia **por papel**).
- 1 usuário com previsão habilitada, de 22 ativos. 0 cotas (`ForecastingQuota`).
- **Hierarquia de papéis quase inexistente:** 2 papéis raiz (`Coordination`, `Financeiro`) e 17 usuários padrão ativos sem papel. O Forecasting por papel soma de baixo para cima pela hierarquia. Sem hierarquia, não há visão de gestor.
- Pipeline Inspection ligado. PSLs `Salesforce Forecasting` e `Pipeline Inspection`: 14 cada, nenhuma em uso.

### 2.2 Território: modelo ativo e vazio

`Territory2Model` `ManagementAccount` ativo, **0 territórios**. Os tipos de previsão por território existem, todos inativos.

### 2.3 Campos

- Opportunity tem os campos padrão de previsão (`Amount`, `CloseDate`, `Probability`, `StageName`, `ForecastCategoryName`, `OwnerId`, `Territory2Id`).
- `Opportunity.Previs_o_Eintein__c` ("Previsão Einstein", número): sem descrição, não editável pelo usuário da sessão, **nenhum Flow ou trigger lido o escreve**. Origem desconhecida. **Não usar até o cliente explicar o que é.**
- Order: `ExpectedSaleDate__c` (data de previsão de venda), `Salesperson1__c`/`Salesperson2__c` (vendedor em **texto livre**, não lookup), `TotalAmount`.
- Nenhum campo de região, carteira ou meta em Account, Opportunity, Order ou User.

### 2.4 Meta

Não existe na org de dev. Nem objeto custom, nem campo, nem `ForecastingQuota`.

### 2.5 Relatórios em uso

374 relatórios, 19 dashboards. Já existem visões de carteira por proprietário, por UF, análise mensal de carteira com oportunidades, e "previsão de pedidos" por período em Order (`02-recon.md`, seção 5).

---

## 3. Opções, uma para cada leitura de "previsão"

Nenhuma está recomendada. A tabela é para o humano escolher com base no que a org tem, não para eu escolher.

| | **A. Painel analítico** | **B. Forecasting nativo** | **C. Projeção estatística ou por IA** | **D. Previsão de pedido (Order)** |
|---|---|---|---|---|
| O que é | Relatórios e dashboard sobre Opportunity (valor, fechamento, fase, categoria) por proprietário, UF e período | Tela de Forecasts do Salesforce, com rollup por gestor, ajustes e cotas | O sistema estima o que vai fechar, a partir de histórico | Relatórios e dashboard sobre Order com `ExpectedSaleDate__c` no período, por vendedor, UF e status |
| Nível da doutrina | Configuração | Configuração (recurso nativo) | Configuração se for recurso licenciado. Código se for modelo próprio | Configuração |
| Já existe na org | Report types padrão. Relatórios de carteira e pipeline parecidos | Recurso ligado, 1 tipo ativo, PSLs livres | `Previs_o_Eintein__c` de origem desconhecida. **Nenhuma PSL de Einstein Forecasting / Sales Cloud Einstein** entre as ativas | Relatórios parecidos (`Previso_de_Pedidos_Perodo_Yko`) |
| Região | Campo de agrupamento (bucket) no relatório sobre `BillingState`. Sem campo novo | Só por território (exige territórios) ou por papel (exige hierarquia) | Depende do recurso | Bucket sobre UF da conta |
| Carteira | `Account.OwnerId` (se o cliente confirmar Q5) | Proprietário da oportunidade na hierarquia de papéis | — | Vendedor do pedido. **`Salesperson1__c` é texto livre**: agrupar por ele depende da qualidade do dado do Protheus. Proprietário da conta é a alternativa |
| Meta | Só se a fonte existir (Q4) | `ForecastingQuota`, que precisa ser carregada (Q4) | — | Só se a fonte existir (Q4) |
| Muda modelo de dados ou compartilhamento? | **Não** | **Sim**: hierarquia de papéis para 17+ usuários ou territórios no modelo ativo. **Escala** (seção 6) | Provavelmente (licença, campo de saída, possível dado saindo da plataforma) | **Não** |
| Toca automação concorrente? | Não (leitura) | Não na leitura. Ajuste de previsão grava em objetos do Forecasting, não em Opportunity | Se o resultado for gravado em Opportunity, **sim** | Não (leitura) |
| Depende do Protheus | Não | Não | Depende | **Sim**: Order vem da integração. Mesmo risco de qualidade de `eplast-ent-11` |
| Histórico necessário | Não | Não | Sim, em produção. Dev está vazia e o histórico de campo de Opportunity está desligado | Não |
| Esforço estimado (humano) | 16–40 h | 40–90 h, sem contar a decisão de hierarquia | Não estimável hoje (licença e histórico desconhecidos). Pede estimativa própria | 16–40 h |
| Sobreposição com EPLAST-32 | Alta: é quase o mesmo painel | Média | Baixa | Alta: "pedidos imputados" e "faturado" da EPLAST-32 vêm de Order |

Avaliação técnica da opção C (sem decidir): a análise de licença da EPLAST-26 já tinha registrado que o recurso preditivo nativo não estava confirmado nesta org e que o histórico de campo de Opportunity estava desligado (RAG: `demandas/EPLAST-26/03-design.md`). O recon de hoje confirma as duas coisas. A opção C não é desenhável nesta demanda sem antes resolver licença (`eplast-ent-04`) e histórico em produção.

A, B e D não se excluem. Se o cliente quiser mais de uma, isso também precisa ser dito, porque muda o escopo e a relação com a EPLAST-32.

---

## 4. Componentes a criar / alterar / depreciar

**Nenhum nesta etapa.** Sem a escolha de Q3, qualquer lista de API names seria invenção.

O que já se sabe que **não** será criado em nenhuma opção: Apex, trigger, Flow record-triggered em Opportunity/Account/Order, campo novo em Opportunity, perfil novo.

Quando Q1–Q3 forem respondidas, este design será refeito com a lista de componentes. Todo componente novo sai com `description` preenchida (achado 4).

---

## 5. Conflito de automação

**Opportunity tem hoje 3 triggers (`OpportunityTrigger` custom, `OpportunityBefore` e `OpportunityAfter` do CPQ) e 2 Flows after-save (`OpportunityFlow`, `Oportunidade_Industria`) no mesmo evento. `OpportunityFlow` não tem critério de entrada e grava em Order, Quote, Account e Task. A ordem entre o trigger do CPQ e o trigger custom não é garantida pela plataforma.** Account e Order têm o mesmo padrão (`02-recon.md`, seção 6).

Como isso entra no design:

- **Nas opções A, B e D, a solução não escreve nesses objetos.** O risco não aumenta.
- **No teste, sim.** Criar Opportunity e Order sintéticas em dev passa pela cadeia inteira, inclusive pelo `OpportunityFlow` que cria Order. A Order dispara os triggers de Order e pode chamar a integração Protheus. Antes do build, o plano precisa confirmar para onde a integração aponta em dev, criar o mínimo de registros, e não ligar bypass global (RAG: `demandas/EPLAST-39/03-design.md`, risco 3, mesmo tratamento).
- **Na opção C, ou em qualquer leitura que grave em Opportunity**, o mapeamento da ordem de execução recomendado pelo achado 1 vira pré-requisito, com estimativa à parte (16–24 h, conforme a análise).

## 6. Limites de governador e escala

- **Opções A, B e D:** relatórios, dashboards e Forecasting nativo não rodam Apex nem Flow da solução. Não há SOQL em loop, DML ou CPU sob controle desta demanda. O limite que importa é o de relatório: até 2.000 linhas na tela e linhas de detalhe pesadas em dashboard. Isso precisa de volume de produção, que dev não tem (0 registros).
- **Pai com muitos filhos (achado SOMOSAGILITY-10):** não se aplica às opções de leitura. Aplica-se ao **teste**: uma Opportunity sintética com muitas linhas passa por `OpportunityLineItemTrigger` (CPQ) e pelos Flows do pai. Na massa de teste, manter poucas linhas por oportunidade. Se o cenário de negócio exigir oportunidade com muitas linhas, medir CPU em dev antes. Se passar de 70% do limite, o design volta para revisão.
- **Opção B:** o recálculo do Forecasting é assíncrono e da plataforma. O risco não é o limite de governador, é o volume de mudança de compartilhamento quando a hierarquia ou os territórios forem criados. Isso faz parte da escalação da seção 7.

---

## 7. Escalação: mudança de modelo de dados e de compartilhamento

**Decisão de arquiteto sênior, não minha.** A opção B só funciona com uma destas mudanças:

- criar a hierarquia de papéis do comercial e atribuir papel a 17+ usuários (muda quem vê o quê em toda a org, porque a hierarquia de papéis concede acesso para cima), ou
- popular territórios no modelo `ManagementAccount`, que já está ativo e concede Account Edit e Opportunity Read a quem for atribuído.

As duas mexem no modelo de compartilhamento, que o assessment não mediu (OWD de Account e Opportunity desconhecido). Também é escalada qualquer leitura que exija campo novo de região ou carteira em Account, ou objeto novo de meta.

## 8. Impacto em permissões

- Nenhum agora.
- Para qualquer opção: um permission set novo e dedicado (nome definido no próximo design, seguindo `padrao-entrega`), atribuído por usuário. Pasta de relatórios compartilhada com grupo, não com perfil.
- Opção B também exige a PSL `Salesforce Forecasting` (14 disponíveis) e a permissão de usar previsões. O número de usuários pagantes precisa caber em 14 **em produção**. Esse número é da sandbox e não vale para produção.
- **Dados pessoais (Q11):** previsão por vendedor expõe desempenho de pessoa identificável. A visibilidade por vendedor e por gestor precisa ser decidida pelo cliente antes do build, em qualquer opção.

## 9. Riscos

### 9.1 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| 1 | Escopo contratual sem resposta (Q1) | **Alta** (bloqueia design e build) | Seção 0 |
| 2 | Sobreposição com EPLAST-32 sem decisão (Q2). Risco de construir duas vezes o mesmo painel | **Alta** | Decidir antes do próximo design. Se forem a mesma entrega, uma das duas sai |
| 3 | "Previsão" sem definição (Q3), agora com quatro leituras | **Alta** | Seção 3 |
| 4 | Fonte de meta inexistente na org de dev (Q4), embora a EPLAST-32 diga que um agente já responde gap da meta | **Alta** se meta estiver no escopo | Localizar a fonte antes do próximo design |
| 5 | Achado 6: `sbx-eplast-dev` pode ser a mesma sandbox que `sbx-eplast-qa`. `sbx-eplast-qa` nem está autenticada neste runner | **Alta** (bloqueia build e QA) | Confirmação humana antes do build |
| 6 | Dados sintéticos de teste disparam CPQ, trigger custom, `OpportunityFlow` (que cria Order) e possivelmente a integração Protheus | **Média** | Seção 5 |
| 7 | `Previs_o_Eintein__c` de origem desconhecida. Alguém pode tratá-lo como "a previsão" sem saber de onde vem o número | **Média** | Não usar até o cliente explicar. Pergunta registrada na seção 11 |
| 8 | Na opção D, vendedor em texto livre (`Salesperson1__c`) e dado de Order dependente do Protheus | **Média** | Agrupar pelo proprietário da conta, ou validar amostra com o comercial (mesma recomendação de `eplast-ent-11`) |
| 9 | Fórmulas duplicadas em Opportunity (`LastMonth__c`/`LastMoth__c`, `CurrentYear__c`/`ThisYear__c`). Usar a errada não muda o resultado hoje, mas confunde | **Baixa** | Não usar nos relatórios novos. Filtros de data relativa do próprio relatório resolvem o período |

### 9.2 Riscos do assessment: como este design lida com cada um

| Achado | Aplica? | Como |
|---|---|---|
| 1. Automação concorrente em Account/Opportunity/Order | **Sim, no teste. Na solução, só na opção C** | Seção 5. Recon de 2026-11-10 confirmou os mesmos triggers e Flows |
| 2. Cobertura Apex de 10% | **Não**, desde que nenhuma opção traga Apex (restrição 1.1.2) | Se o próximo design precisar de código, cobertura vira pré-requisito |
| 3. Validation rules de Order | **Só no teste da opção D** | A massa sintética de Order precisa preencher os campos que as 8 regras de obrigatoriedade exigem |
| 4. Campos sem descrição | **Sim** | Todos os campos candidatos conferidos (`ExpectedSaleDate__c`, `Salesperson1__c`, `Branch__c`, `Previs_o_Eintein__c`, entre outros) estão sem descrição. Cada um precisa de confirmação do cliente antes de entrar em relatório. Componentes novos saem com descrição |
| 5. Convenção `<Classe>Test` | **Não** | Sem Apex |
| 6. Dev × QA | **Sim, bloqueante para build** | Risco 5 |
| 7 e 8. Perfis | **Sim** | Acesso por permission set (1.1.3) |
| 9 e 10. API version e nome de trigger duplicado | **Não** | Nenhuma classe ou trigger tocado |

---

## 10. O que NÃO será feito nesta demanda

- Escolher a arquitetura antes de Q1–Q3.
- Criar ou alterar hierarquia de papéis, territórios, OWD ou regras de compartilhamento.
- Criar objeto ou campo de meta, região ou carteira.
- Gravar em Opportunity, Account ou Order (nem campo, nem Flow, nem trigger).
- Projeção por IA ou modelo estatístico próprio (opção C) enquanto licença e histórico não estiverem resolvidos.
- Usar `Previs_o_Eintein__c`.
- Nova integração com o Protheus.
- Curadoria geral de descrição de campos (achado 4) e consolidação de perfis (achado 8).
- Qualquer coisa em produção.

---

## 11. Perguntas para o próximo ciclo (além de Q1–Q3)

1. O que é `Opportunity.Previs_o_Eintein__c`, quem preenche e se ainda é usado?
2. Carteira = contas do proprietário e região = UF de cobrança agrupada (SUL, CO, ...) são as definições certas? Qual é a lista de UFs por região?
3. Onde está a meta hoje, e como o agente citado na EPLAST-32 a lê?
4. Previsão de oportunidade (A/B) ou de pedido (D)? Ou as duas, com o pedido sendo o "realizado"?
5. Quantos usuários vão usar, para saber se as 14 licenças de Forecasting bastam em produção (só se B)?

---

## 12. Estimativa de esforço humano

**Estimativa de esforço:** 16–160 h

O que mudou em relação à análise (60–160 h) e por quê:

- **A ponta baixa caiu de 60 para 16 h.** O recon mostrou que, nas opções A e D, quase tudo é configuração de relatório e dashboard sobre campos que já existem, e o comercial já tem relatórios parecidos para partir. Não há Apex, Flow nem campo novo.
- **A ponta alta ficou em 160 h**, agora com motivo concreto: a opção B exige hierarquia de papéis ou territórios (hoje praticamente inexistentes), carga de cotas e a decisão de compartilhamento da seção 7, além do teste com a cadeia CPQ.
- **A opção C fica fora da faixa.** Sem licença de previsão por IA confirmada e sem histórico em dev, ela não é estimável hoje e precisaria de estimativa própria.
- Não inclui: mapeamento da ordem de execução em Opportunity (16–24 h, só se houver escrita), o processo de aceite contratual, a curadoria de campos. Também não inclui esforço de agente.
- A faixa continua larga porque Q3 não foi respondida. Ela fecha quando a opção for escolhida.

---

## 13. O que este gate pede ao arquiteto humano

Este design **não** deve ser aprovado como liberação de build. Não há componente para construir. A recomendação é uma destas:

- **Se Q1 = (b) ou (c):** devolver a demanda para `backlog` e encerrar esta etapa aqui.
- **Se Q1 = (a):** responder Q2 e Q3 (e, de preferência, as perguntas da seção 11) no card, e rodar o design de novo. O recon de hoje vale até 2026-11-17. Depois disso, precisa ser refeito.

Em qualquer caso, o build também depende da aprovação da estimativa pelo cliente e da confirmação dev × qa (risco 5).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
