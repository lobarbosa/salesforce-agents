# EPLAST-32 — Análise funcional: painel meta × carteira × faturamento × pedidos × gap

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 · Comercial
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Status:** rascunho para validação humana. Não acionar o arquiteto antes de resolver a pendência contratual (seção 0) e as perguntas da seção 7.

---

## 0. Pendência contratual (validar antes de qualquer design)

A demanda está marcada como **Onda 3 · Comercial, ainda não contratada no projeto atual (Ondas 1–2)**. Isso muda o status da demanda: ela não é executável agora. Antes do design, confirmar com o consultor/comercial:

- Se a Onda 3 entra no escopo contratado do projeto, em que data, e com que peso no progresso (o contrato de projeto pondera entregáveis).
- Se o painel é entregável próprio ou sub-item de outro entregável (ex.: "gap da meta mensal" já tratado em demanda anterior, ver seção 6).
- Se o build pode começar em paralelo a outras demandas que tocam Opportunity (EPLAST-26, EPLAST-28), dado o achado de automação concorrente.

Enquanto isso não for respondido, esta análise fica como **entrada para planejamento**, não como trabalho aprovado para construção.

---

## 1. Contexto de negócio

A Eplast quer um painel único que compare, por recorte comercial, o que foi **planejado** (meta), o que está **em carteira**, o que foi **faturado**, quantos **pedidos foram imputados**, qual é a **projeção** e qual é o **gap** entre meta e realizado/projetado. Hoje, segundo a própria demanda, a pergunta sobre o gap da meta mensal já foi respondida em outra entrega, mas a visão consolidada ainda não existe.

Os cinco conceitos (meta, carteira, faturamento, pedidos imputados, projeção) são termos de negócio do cliente. Nenhum deles está definido na demanda em termos de **fonte de dado**, **fórmula** ou **recorte**. Essa é a principal lacuna da análise.

## 2. Objetivo

Dar à área comercial uma visão mensal consolidada, por vendedor/equipe (recorte a confirmar), que mostre meta, carteira, faturamento, pedidos imputados, projeção e gap, sem que o usuário precise cruzar relatórios manualmente.

Objetivo **não** coberto por esta demanda (a confirmar): alertas automáticos, ação sobre o gap (ex.: tarefa, notificação) e previsão estatística. Isso seria outra demanda.

## 3. Regras de negócio

Tudo o que está abaixo é o que a demanda **diz** ou o que é **inferido** do nome dos conceitos. O que é inferido está marcado como pendente.

| Conceito | O que a demanda diz | Lacuna (pendente) |
|---|---|---|
| Meta | "meta" e "meta mensal" | Onde a meta é cadastrada (objeto custom, planilha, ERP)? Granularidade (vendedor, equipe, região, produto)? Quem a altera e com que histórico? |
| Carteira | "carteira" | Carteira = contas por proprietário (Account.Owner)? Valor de quê (oportunidades abertas, pedidos em aberto, receita histórica)? |
| Faturamento | "faturamento" | Vem do Salesforce (Order/Invoice) ou do ERP Protheus? Qual data conta (emissão, competência, entrega)? Inclui devolução/cancelamento? |
| Pedidos imputados | "pedidos imputados" | "Imputado" a quem? Regra de atribuição (proprietário do pedido, da conta, do vendedor que fechou)? Quais status contam? |
| Projeção | "projeção" | Fórmula? Base (pipeline ponderado, histórico, carteira)? Quem preenche (sistema ou vendedor)? |
| Gap | "gap da meta" | Fórmula inferida: gap = meta − (faturamento + projeção?) ou meta − faturamento? Sinal e arredondamento? Já existe fórmula na entrega anterior (seção 6) — precisa ser reaproveitada, não redefinida. |
| Período | "mensal" | Mês por data de faturamento, de fechamento ou de competência? Fuso e corte de fechamento? |

## 4. Critérios de aceite (Gherkin)

Escritos para serem testáveis com dado sintético no QA. Os critérios marcados com **[PENDENTE P-n]** só podem ser fechados depois da resposta à pergunta correspondente na seção 7. Nenhum critério usa dado real de cliente (guardrail #2).

```gherkin
# language: pt
Funcionalidade: Painel meta × carteira × faturamento × pedidos × gap

  Contexto:
    Dado um vendedor "V1" com meta mensal de 100.000 cadastrada para o mês "M"   # [PENDENTE P-1: onde a meta é cadastrada]
    E uma carteira de contas de "V1" com saldo conhecido (dataset sintético)        # [PENDENTE P-2: definição de carteira]

  Cenário: Painel exibe os seis indicadores para o recorte e mês escolhidos
    Dado um usuário com acesso ao vendedor "V1"
    Quando ele abre o painel filtrando o mês "M" e o recorte "V1"
    Então o painel exibe meta, carteira, faturamento, pedidos imputados, projeção e gap
    E cada indicador bate com o valor esperado do dataset sintético

  Cenário: Gap é calculado pela fórmula acordada
    Dado meta = 100.000 e faturamento = 60.000 e projeção = 25.000 no mês "M"           # [PENDENTE P-5: fórmula do gap]
    Quando o painel é carregado
    Então o gap exibido é 15.000                                                         # ajustar conforme P-5
    E o sinal e o arredondamento seguem a regra aprovada

  Cenário: Pedidos fora do status que conta não entram em "pedidos imputados"
    Dado um pedido em status "Rascunho" e outro em status "Faturado" para "V1" no mês "M"  # [PENDENTE P-4: status que contam]
    Quando o painel é carregado
    Então "pedidos imputados" conta apenas o pedido em status "Faturado"

  Cenário: Mês sem meta cadastrada não mostra gap zerado
    Dado que não existe meta cadastrada para "V1" no mês "M+1"
    Quando o painel é carregado para "M+1"
    Então o gap aparece como "sem meta" e não como 0

  Cenário: Painel é somente leitura
    Dado um usuário com acesso ao painel
    Quando ele interage com todos os filtros e indicadores
    Então nenhum registro de Account, Opportunity, Order, OrderItem ou meta é criado, alterado ou excluído

  Cenário: Usuário sem permissão não vê meta de outro vendedor
    Dado um usuário com acesso somente ao vendedor "V2"
    Quando ele tenta abrir o painel no recorte "V1"
    Então o painel não exibe valores de "V1"                                              # [PENDENTE P-7: regra de visibilidade por perfil/hierarquia]

  Cenário: Total da equipe bate com a soma dos vendedores
    Dado a equipe "E" com vendedores "V1" e "V2" no mês "M"
    Quando o painel é carregado no recorte "E"
    Então meta, carteira, faturamento e pedidos imputados da equipe são iguais à soma dos vendedores
    E o gap da equipe é calculado sobre os totais, não como soma de gaps                  # [PENDENTE P-6: recorte e hierarquia]
```

Critérios transversais (testáveis já):

```gherkin
  Cenário: Dado de produção não entra no ambiente de teste
    Dado o ambiente sbx-eplast-qa
    Quando a validação do painel é executada
    Então apenas dataset sintético é usado e nenhum CPF, e-mail ou telefone real aparece em screenshot ou log
```

## 5. Riscos do assessment que tocam esta demanda

Fonte: `clients/eplast/assessment.md` (saúde **vermelho**, 2026-09-30). A demanda é majoritariamente **leitura**, mas o painel precisa ler Opportunity, Order e Account, e a projeção ou o gap podem exigir gravação. Cada risco abaixo foi avaliado contra a demanda.

| Achado do assessment | Toca esta demanda? | Por quê | Tratamento no design |
|---|---|---|---|
| **1 (alta)** — automação concorrente em Account, Opportunity e Order (trigger custom + SBQQ + Flows `RecordAfterSave`/`RecordBeforeSave`) | **Sim, condicionalmente** | Um dashboard/relatório nativo só lê e não dispara automação, então o risco não se aplica à leitura em si. Aplica-se se o painel **gravar** algo: projeção persistida, meta espelhada em campo de Opportunity/Account, gap salvo em Account para filtro. Nesse caso, qualquer escrita entra na cadeia de triggers e Flows descrita no assessment | Se houver escrita, mapear a ordem de execução antes do design e encaminhar via ponto de entrada único. Preferir cálculo na leitura (fórmula de relatório ou Apex read-only) |
| **2 (alta)** — cobertura Apex org-wide de 10%; cadeia Protheus (`SendOrderToProtheus`, `OrderTriggerHandler`, `OrderUtility`) sem teste identificável | **Sim, se houver Apex** | Um controller Apex do painel precisa de classe `<Classe>Test` própria e cobertura ≥ 85% (padrão do squad). Se o faturamento vier do Protheus, a cadeia de integração entra no caminho de leitura e não tem rede de teste | Classe de teste desde o primeiro commit. Se a fonte do faturamento for o ERP, tratar como risco de integração e não só de tela |
| **3 (média)** — 23 validation rules em Order; 8 de obrigatoriedade duplicada e 6 de máquina de estados inativas | **Baixo** | Validation rule só dispara em DML. O painel não grava em Order. Relevante apenas se a demanda decidir gravar pedido imputado ou status | Nenhum, salvo escrita |
| **4 (média)** — 153 de 223 campos custom em Account/Order/Opportunity/OrderItem sem descrição | **Sim** | O painel vai depender de campos que ninguém documentou (ex.: campo de "imputação", campo de data de faturamento). Sem descrição, o risco de usar o campo errado é alto | Mapear, antes do design, cada campo usado com a respectiva definição confirmada com o cliente. Campo novo sai com `Description` |
| **5 (média)** — convenção `<Classe>Test` não seguida | **Sim, se houver Apex** | Mesmo motivo do achado 2 | Seguir `<Classe>Test` |
| **6 (média)** — alias `sbx-eplast-dev` aponta para sandbox cujo usuário e URL indicam "qa" | **Sim, bloqueante para build** | Não impede a análise. Impede saber se build e QA ficam separados. Ainda não resolvido: a conexão atual (`sf org list`, nesta sessão) mantém `instanceUrl` `eplast--qa` e username `...qa` no alias `sbx-eplast-dev` | Resolver com o cliente/BASIS antes de qualquer build (ver seção 9) |
| **Não medido** — OWD, sharing, layouts órfãos, uso real de campos | **Sim** | A regra de visibilidade (carteira e meta por vendedor) depende de OWD e de hierarquia de papéis, que não foram medidos | Medir na etapa de recon (org-recon), não aqui |
| **Sandbox vazia** — 0 Account, Contact e Opportunity | **Sim** | Não é possível validar o painel com dado real da org de dev. QA precisa de dataset sintético criado pelo time, sem dado do cliente | Premissa PA-3 (seção 8) |
| **8 (baixa)** — quatro variações do perfil comercial (`Comercial`, `Comercial - Analista`, `Comercial - Analistas`, `Comercial Padrão`) | **Sim** | Visibilidade do painel por perfil pode variar entre variações que talvez sejam o mesmo time | Confirmar com o cliente antes de definir a regra da seção 4 (cenário de visibilidade) |
| **9 (baixa)** — classes Apex em API version antiga (v58–v64) | **Só se editar classe existente** | Não se aplica a código novo | Código novo em API atual |

Conclusão sobre automação: se o painel for só leitura (relatório, dashboard ou componente que chama Apex read-only), os achados 1 e 3 não se aplicam à execução do painel. Eles voltam a valer no momento em que qualquer campo for gravado.

## 6. Histórico do cliente (RAG)

Consulta a `mcp__rag__rag_consultar` com os termos da demanda (painel, meta, carteira, faturamento, pedidos, gap):

- **Não encontrei** no histórico uma demanda que entregue especificamente o "gap da meta mensal". A consulta retornou apenas trechos do assessment e de análises de demandas vizinhas. Por isso **não atribuo** esse gap a nenhum ID. Pergunta ao consultor (P-8, seção 7): qual demanda entregou o gap, e onde está a fórmula.
- `[demandas/EPLAST-26/01-analise.md]` — scoring de leads e oportunidades, Onda 3. Também grava ou lê Opportunity e menciona o mesmo achado 1 do assessment. Se a projeção do painel depender de score, as duas demandas precisam ser desenhadas juntas, senão a ordem de automação em Opportunity fica indefinida duas vezes.
- `[demandas/EPLAST-28/01-analise.md]` — alerta comercial, Onda 3. Também pode ler Opportunity e aponta a mesma pendência de ambiente de build (achado 6). Se o alerta usar o gap como critério, as duas demandas dependem da mesma fórmula.

Os trechos acima vieram da busca, não da leitura integral dos arquivos. Antes do design, reler as duas análises na íntegra.

## 7. O que a demanda NÃO diz

Perguntas que precisam de resposta antes do design. Cada uma tem um identificador para o card e para o consultor.

- **P-0 (contratual):** a Onda 3 entra no escopo contratado? Data, peso e sequência em relação às Ondas 1–2 (seção 0).
- **P-1 (meta):** onde a meta mensal está hoje? Objeto custom, planilha, ERP ou outro sistema? Quem cadastra e com que frequência? Granularidade: vendedor, equipe, região, produto?
- **P-2 (carteira):** definição exata de carteira e de valor (contas por proprietário? oportunidades abertas? pedidos em aberto? receita histórica?).
- **P-3 (faturamento):** a fonte é o Salesforce (Order/Invoice) ou o ERP Protheus? Qual data define o mês? Como tratar devolução, cancelamento e nota complementar?
- **P-4 (pedidos imputados):** regra de imputação (proprietário do pedido, da conta ou do vendedor que fechou). Quais status contam?
- **P-5 (projeção e gap):** fórmula da projeção e do gap. Base da projeção. Quem preenche. Sinal e arredondamento. A fórmula da entrega anterior (P-8) vale?
- **P-6 (recorte):** o painel é por vendedor, equipe, região ou todos? Há hierarquia de gerência para somar equipes? Equipe soma os vendedores ou recalcula sobre os totais?
- **P-7 (visibilidade):** quem vê o quê? Regra por perfil (há quatro variações comerciais no org), por hierarquia de papéis ou por OWD? O gestor vê o time inteiro?
- **P-8 (histórico):** qual demanda entregou o gap da meta mensal, e onde estão a fórmula e o componente já existente?
- **P-9 (formato):** dashboard/relatório nativo, componente Lightning (LWC) com Apex, ou outro (planilha exportada, Tableau/CRM Analytics)? Isso muda a estimativa e a necessidade de teste Apex.
- **P-10 (atualização):** o painel é em tempo real ou em snapshot diário/mensal? Snapshot exige job e, portanto, mais automação.
- **P-11 (dado de teste):** o cliente fornece dataset sintético para o QA? Quem cria?
- **P-12 (ambiente):** o alias `sbx-eplast-dev` foi confirmado como sandbox de dev distinta da de QA (achado 6)?
- **P-13 (usuários):** quantos usuários vão usar o painel e em que frequência? Afeta performance e limite de dashboard.

## 8. Premissas a validar

Nenhuma premissa abaixo está confirmada. Todas estão **pendentes**.

- **PA-1 (pendente):** o painel é leitura. Nenhuma tela grava meta, projeção ou gap. Se não for, a análise de risco da seção 5 precisa ser refeita.
- **PA-2 (pendente):** faturamento vem do Salesforce e não do ERP. Se vier do ERP, a demanda passa a depender de integração com Protheus, cuja cadeia não tem teste (achado 2).
- **PA-3 (pendente):** QA usa dataset sintético criado pelo time. Sem isso, não há como validar os critérios da seção 4.
- **PA-4 (pendente):** o painel usa objetos padrão (Account, Opportunity, Order, OrderItem). Se usar campos custom de imputação, cada um precisa de definição confirmada (achado 4).
- **PA-5 (pendente):** a visibilidade é por perfil e hierarquia padrão, sem regra de compartilhamento especial.

## 9. Complexidade

**G.** Quatro conceitos de negócio sem fonte nem fórmula definidas, possível dependência de ERP (Protheus) e de Opportunity/Order com automação concorrente, mais um possível componente com Apex e teste obrigatório.

## 10. Estimativa de esforço

**Estimativa de esforço:** 30–120 h

Premissas que mais pesam na faixa (consultor/dev configurando, revisando, testando e homologando — sem o tempo do agente):

- **Forma de entrega (P-9):** dashboard/relatório nativo fica no início da faixa (30–50 h). Componente LWC com Apex e teste fica no meio ou no alto (60–120 h).
- **Definição das fórmulas e da fonte (P-1 a P-5):** se estiverem fechadas antes do design, a faixa cai. Se não, a faixa sobe porque a negociação com o cliente entra no esforço.
- **Faturamento no ERP (P-3, PA-2):** se a fonte for Protheus, a faixa sai desta estimativa e vira outra, de integração e reconciliação.
- **Visibilidade (P-7):** regra simples por perfil custa pouco. Hierarquia com OWD e compartilhamento custa mais.

A faixa é larga de propósito: a demanda ainda não tem definição de fonte nem de fórmula. O arquiteto refina no design.

## Verificação de org

- Org conectada nesta sessão (`sf org list`): alias `sbx-eplast-dev`, `isSandbox = true`, Enterprise Edition, API 68.0 (o assessment registrou v67; a versão mudou, sem impacto nesta análise).
- A sessão **não** consultou metadata nem dados da org. Os campos, triggers e Flows citados vêm do assessment de 2026-09-30 e precisam ser confirmados pelo `sf` na etapa de recon (guardrail #3).
- Alerta persistente: o alias `sbx-eplast-dev` ainda aponta para uma sandbox cujo username e URL indicam "qa" (achado 6). Não bloqueia esta análise, mas bloqueia build (P-12).
- Nenhuma escrita foi feita na org nem em `gates.md`.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
