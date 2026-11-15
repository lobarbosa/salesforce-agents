**Solução:** declarativa
**Org de teste:** sbx-eplast-dev

# EPLAST-31 — Design: previsão de pedidos por vendedor, região e mês (v1)

**Rodada:** 2 (2026-11-15), pela regra 4 da conta. A rodada 1 (`rodada-anterior/03-design.md`) serviu só de referência.
**Org conferida:** `sf org list` mostra só `sbx-eplast-dev` (Sandbox, Connected). Achado 6 do assessment segue valendo: o usuário e a instância dessa conexão trazem a marca `qa` (ver risco R1).
**Fontes:** `01-analise.md` (aprovada em 2026-11-15), `02-recon.md` (inclui a seção 8, que acrescentei nesta etapa com o que confirmei por `sf`), `comentarios-do-card.md`, `assessment.md` (achados 1 a 10, por trecho), skills `salesforce-doutrina` e `padrao-entrega`, RAG do cliente (`rodada-anterior/03-design.md`, comparação de opções A–D).

**Nota do gate de análise:** a análise foi aprovada em lote e o card registra que as premissas não foram revisadas uma a uma. Elas estão repetidas na seção 7 para revisão neste gate, com os ajustes que o design fez.

---

## 1. Contexto e requisitos

A Eplast quer ver a previsão de vendas por vendedor, região, carteira e período sem montar a conta à mão. A análise decidiu (PA-02) que "previsão" é o que o comercial já usa: **pedidos (`Order`) com data prevista de venda** (`Order.ExpectedSaleDate__c`, rótulo na org "Data previsão de vendas").

Requisitos da v1, vindos da análise:
- RN-1 soma de `Order.TotalAmount` por data prevista no intervalo filtrado, sem probabilidade nem projeção.
- RN-2 vendedor e carteira = proprietário da conta.
- RN-3 região = estado de cobrança da conta; sem estado → "Sem região".
- RN-4 mês calendário de `ExpectedSaleDate__c`; sem data → "Sem data prevista", fora dos meses.
- RN-5 sem meta, faturado, cotas, territórios ou Protheus.
- RN-6 pasta restrita.
- RN-7 somente leitura.
- Os 8 cenários Gherkin da seção 4 da análise são os critérios de aceite. O design ajusta a redação de dois deles (seção 7, PA-19 e PA-20) por limite da plataforma.

## 2. Decisão: configuração (relatórios e painel), sem Flow e sem Apex

**Nível da doutrina: 1, configuração.** A entrega é tipo de relatório, relatórios, painel, pastas e grupo público. Nenhum campo, Flow, trigger ou classe.

Por que não descer:
- **Flow:** não há nada a automatizar. A visão só lê (RN-7). Um Flow gravando campo de região ou de mês no pedido acrescentaria automação em `Order`, objeto que já tem 2 triggers, 2 Flows de gravação e 17 validation rules ativas (achado 1). Isso só traria risco.
- **Apex/LWC:** nenhum critério de aceite exige lógica que relatório não faça. Agrupamento por mês é granularidade de data. Região é bucket de texto. Dono da conta é coluna via lookup.
- **Campo novo (fórmula de região ou de UF em `Order`):** dispensado. Um tipo de relatório custom alcança `Account.BillingState` pelo lookup, sem mudar o modelo de dados. Por isso o design não escala decisão de modelo de dados ao arquiteto sênior.
- **Forecasting nativo:** descartado na análise (PA-02). Exige hierarquia de papéis (2 papéis, maioria dos usuários sem papel) e muda compartilhamento.
- **`SFAgent2`:** fora da v1 (PA-09). Se o cliente pedir pergunta em linguagem natural, o caminho é estender a ação `AgregacaoPedidos` do tópico `insights_comerciais`, sem criar agente novo (regra 3).

## 3. Reaproveita × cria, item a item

| # | Item | Decisão | Por quê (evidência) |
|---|---|---|---|
| 1 | Relatório `Previsão de Imputados Período` (`Previso_de_Pedidos_Perodo_Yko`, pasta `RELATÓRIOS DIÁRIOS - ADV`) | **Reaproveita como molde, não altera.** Os novos relatórios copiam seus filtros de negócio (status, setor, tipo de operação). | Ele é a definição viva de "previsão" na org. Ele não agrupa por dono, região nem mês, e é de uso diário do ADV com datas fixas. Mudar o agrupamento dele quebraria esse uso, e a pasta dele não é restrita. |
| 2 | Relatório `Previsão de Pedidos HOJE` (`Previso_de_Pedidos_Q4W`) | **Não toca.** | Visão do dia, outro uso. |
| 3 | Cópias `Previsão de Imputados Período - ANA` e `Previsão de Amostras - HOJE` | **Não toca.** | Pasta pessoal e outro assunto (amostras). |
| 4 | Relatórios `Número Total da Carteira <região>` (pasta `ANALISTAS`) | **Reaproveita a regra de região** (UF → região). Não altera os relatórios. | São a definição de região que a Eplast já usa (recon, seção 8). |
| 5 | Tipo de relatório padrão `OrderList` | **Não usa.** | Não tem o estado de cobrança da conta, só o do pedido (recon, seção 8). |
| 6 | Tipo de relatório custom `Pedidos_customizados` (base `Order`, 119 colunas, já no `force-app/` do baseline) | **Reaproveita e estende**, acrescentando 3 campos via lookup de conta: `Account.Owner`, `Account.BillingState`, `Account.Sector__c`. Não remove nem renomeia nada. | Já é o tipo custom sobre `Order` e já tem `ExpectedSaleDate__c`, `TotalAmount`, `Total_com_Desconto__c`, `Status`, `TypeOperation__c` e o lookup `Account`. A mudança é só aditiva e não afeta relatórios que já o usem. Criar um segundo tipo sobre `Order` seria sobrepor (regra 3). |
| 7 | Pasta de relatório de previsão | **Cria** `Previsao_de_Vendas` (rótulo "Previsão de Vendas"). | Não existe pasta de previsão, gestão ou comercial (recon, seção 8). |
| 8 | Pasta de painel de previsão | **Cria** `Previsao_de_Vendas_Paineis` (rótulo "Previsão de Vendas - Painéis"). | Idem. |
| 9 | Grupo de acesso | **Cria** o grupo público `Comercial_Previsao_Vendas` (rótulo "Comercial - Previsão de Vendas"), com descrição. As duas pastas são compartilhadas com ele em modo leitura. | Pasta se compartilha com grupo, papel ou usuário, não com permission set. O único grupo no baseline é `DEV`. |
| 10 | Permission set de previsão (citado na PA-11 da análise) | **Não cria.** | Permission set não abre pasta. A leitura de `Order` e `Account` e "Executar relatórios" já vêm dos perfis comerciais, e o OWD de `Account` e `Order` é `ReadWrite`. Ver PA-20. |
| 11 | Relatórios novos | **Cria 4** (seção 4.2). | Nenhum relatório existente agrupa pedido previsto por dono, região e mês. |
| 12 | Painel de previsão | **Cria 1** `Previsao_de_Vendas`. | A busca por Previs, Forecast e Vend em `Dashboard` retornou 0 (recon). |
| 13 | Agente `SFAgent2` | **Não toca na v1.** | PA-09. |
| 14 | Forecasting nativo, `Territory2`, `ForecastingQuota` | **Não toca.** | PA-02, PA-05, PA-07. |

## 4. Componentes

Todos são metadata confirmada na org ou componentes novos com nome definido aqui. O builder retrieve o que for alterar da `sbx-eplast-dev` antes de editar.

### 4.1 Alterar
| Tipo | API name | Mudança |
|---|---|---|
| `ReportType` | `Pedidos_customizados` | Acrescentar colunas via lookup, na seção de colunas de `Order`: `Account.Owner`, `Account.BillingState`, `Account.Sector__c`. Sintaxe copiada do exemplo da org `<field>Opportunity.Account.Owner</field>` (tipo `Gestao`), aqui como `Account.<Campo>` com `<table>Order</table>`. Preencher a `<description>` só se estiver vazia (hoje é "Pedidos customizados", então fica). |

### 4.2 Criar
| Tipo | API name | Definição |
|---|---|---|
| `Group` (público) | `Comercial_Previsao_Vendas` | Descrição: "EPLAST-31: quem vê a previsão de vendas (pastas Previsão de Vendas)". Sem membros na metadata. A inclusão de pessoas é passo manual pós-deploy (PA-20). |
| `ReportFolder` | `Previsao_de_Vendas` | `accessType` Shared, `folderShares` com o grupo acima em `View`. Sem `<description>`, que a pasta não aceita (doutrina). |
| `DashboardFolder` | `Previsao_de_Vendas_Paineis` | Idem. |
| `Report` | `Previsao_de_Vendas/Previsao_Vendas_Vendedor_Regiao_Mes` | Tipo `Pedidos_customizados`, formato **Summary**. Agrupamentos: proprietário da conta → bucket Região → `ExpectedSaleDate__c` por **mês**. Soma de `TotalAmount` (principal) e de `Total_com_Desconto__c` (secundária, PA-18). Filtros na seção 4.3. Colunas de detalhe: nome da conta, nº do pedido, `ExternalNumber__c`, status, `Account.BillingState`, `ExpectedSaleDate__c`, `TotalAmount`, `Total_com_Desconto__c`. É a visão de leitura e exportação, e alimenta o componente "por vendedor". |
| `Report` | `Previsao_de_Vendas/Previsao_Vendas_por_Mes` | Mesmo tipo e filtros. Summary agrupado só por `ExpectedSaleDate__c` (mês). Alimenta a métrica de total e o gráfico por mês. |
| `Report` | `Previsao_de_Vendas/Previsao_Vendas_por_Regiao` | Mesmo tipo e filtros. Summary agrupado só pelo bucket Região. Alimenta o gráfico por região. |
| `Report` | `Previsao_de_Vendas/Previsao_Vendas_Sem_Data_Prevista` | Mesmo tipo e filtros de negócio, com `ExpectedSaleDate__c` **igual a vazio** no lugar do filtro de período. Summary por proprietário da conta. Alimenta o componente "Sem data prevista" (PA-19). |
| `Dashboard` | `Previsao_de_Vendas_Paineis/Previsao_de_Vendas` | `dashboardType` **LoggedInUser** (PA-21), sem `runningUser` na metadata. Componentes: (1) métrica "Total previsto no período" ← `Previsao_Vendas_por_Mes`; (2) barras "Previsão por vendedor" ← `Previsao_Vendas_Vendedor_Regiao_Mes`; (3) barras "Previsão por região" ← `Previsao_Vendas_por_Regiao`; (4) colunas "Previsão por mês" ← `Previsao_Vendas_por_Mes`; (5) métrica "Pedidos sem data prevista" ← `Previsao_Vendas_Sem_Data_Prevista`. Nenhum componente de meta ou faturado. |

Um relatório por dimensão de gráfico é deliberado. A doutrina (achado EPLAST-39) mostra que gráfico exige relatório Summary com o agrupamento certo, e evita depender de escolher o agrupamento dentro do componente, que não confirmei.

### 4.3 Filtros comuns dos relatórios (herdados do relatório existente, PA-16)
- `Status` em Liberacao Financeiro, Liberacao Estoque, Faturamento (os três existem entre os valores ativos de `Order.Status`).
- `Account.Sector__c` na mesma lista de 9 setores mais vazio do relatório `Previso_de_Pedidos_Perodo_Yko`. O builder copia os valores do XML retrieved, sem redigitar.
- `TypeOperation__c` diferente dos mesmos 8 códigos (04, 05, 07, 11, 13, 27, 31, 45).
- Período (exceto no relatório "sem data"): filtro de data padrão em `ExpectedSaleDate__c`, **ano corrente** como padrão (PA-22), editável pelo usuário. O valor do enum de intervalo é copiado de um relatório da org que já use filtro relativo. Se não houver exemplo, ou se duas tentativas forem recusadas, o builder usa o ano corrente com datas fixas e registra a pendência no plano de build (doutrina).

### 4.4 Bucket Região
- `bucketType` **text** sobre `Account.BillingState` (o campo é `string`, porque o picklist de estado e país está desligado). A doutrina só proíbe `text` sobre picklist.
- Entradas, iguais às da pasta `ANALISTAS`: CO = GO, DF, MT, MS, TO · MG = MG · NO/NE = AC, AP, AM, PA, RO, RR, AL, BA, CE, MA, PB, PE, PI, RN, SE · RJ/ES = RJ, ES · SP = SP · SUL = PR, SC, RS.
- `otherBucketLabel` = "Sem região". Esse grupo cobre estado vazio e qualquer valor fora das 27 siglas (por exemplo, nome por extenso).
- **Incerteza:** a doutrina registra que `otherBucketLabel` não consolidou valores soltos em picklist. Em bucket de texto não está provado, nem se o vazio entra no "outros". O builder testa na dev com conta sem estado. Se o vazio aparecer como `-`, o grupo é renomeado na tela e o fato é registrado no plano de build. É ajuste manual, não metadata (doutrina, "Bucket sobre picklist").

### 4.5 Depreciar
Nada.

## 5. Objetos, campos, automações e validation rules afetados

**Nenhum é alterado pela solução.** Só são lidos:

| Objeto.campo | Uso | Confirmação |
|---|---|---|
| `Order.ExpectedSaleDate__c` (Data) | Período | recon §2, §8 |
| `Order.TotalAmount` (Moeda) | Valor principal | recon §2 |
| `Order.Total_com_Desconto__c` (fórmula `TotalAmount - Discount__c`) | Valor secundário | recon §8 |
| `Order.Status`, `Order.TypeOperation__c`, `Order.ExternalNumber__c` | Filtros e detalhe | recon §1, §2 |
| `Order.AccountId` → `Account.OwnerId`, `Account.BillingState`, `Account.Sector__c` | Vendedor, região e filtro de setor | recon §2, §8 |

Flows, triggers, classes e validation rules: nenhum é criado ou alterado. **Não há Apex nesta entrega**, então não há classe nova a cobrir. Se no build aparecer necessidade de Apex, o design volta ao gate, porque a decisão aqui é configuração.

## 6. Ordem de execução e automação concorrente

**Em tempo de uso, não se aplica.** Relatório e painel não executam DML. Nenhum trigger, Flow ou validation rule de `Account`, `Opportunity`, `Order` ou `OrderItem` dispara por consultar, filtrar ou exportar. O critério "Consulta não altera registros" prova isso.

**Em tempo de teste, se aplica.** O dado sintético (dev vazia: 0 `Account`, 0 `Order`) passa por toda a automação desses objetos. O mapa vem do recon (§3 e §8). Os nomes e eventos foram confirmados. O corpo de cada um e a ordem relativa entre os dois `OrderTrigger` não foram lidos.

| Objeto (DML do fixture) | Before-save Flow | Triggers before | Validation rules ativas | Triggers after | After-save Flow |
|---|---|---|---|---|---|
| `Account` (insert) | nenhum achado | `AccountBefore` (SBQQ), `AccountTrigger` (custom) | 6 | `AccountTrigger` (custom) | `AccountTriggered`; `UpdateParentAccountUsedLimit` (objeto não conferido) |
| `Order` (insert) | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` (CreateAndUpdate) | `OrderTrigger` (SBQQ) | 17 | `OrderTrigger` (SBQQ) | `Order` (CreateAndUpdate) |
| `Order` (update, inclusive a atualização de total causada pelos itens) | idem | `OrderTrigger` (SBQQ) e **`OrderTrigger` custom (before update)** | 17 | os dois `OrderTrigger` | `Order` |
| `OrderItem` (insert) | nenhum achado | `OrderProductTrigger` (SBQQ) | 4 | `OrderProductTrigger` (SBQQ) | nenhum achado |

**Risco de ordem de execução (achados 1 e 10): em `Order` há dois triggers com o mesmo nome (`SBQQ` e custom) no mesmo evento de update, e a ordem entre eles não é garantida pela plataforma.** A solução não depende dessa ordem, porque não grava nada. O efeito é só sobre o fixture: um erro pode vir de qualquer um dos dois, e a mensagem "OrderTrigger" é ambígua. Regra para o build e o QA: ao registrar falha do fixture, anotar o namespace do trigger que aparece no stack trace.

Como o fixture lida com isso:
- **Volume pequeno e um pai com poucos filhos:** cerca de 10 pedidos com 1 item cada, em lotes de no máximo 10. Isso fica longe de 100 SOQL e de 10 s de CPU, mesmo com 2 triggers e 2 Flows em `Order`. O cenário "um pai com muitos filhos" (achado SOMOSAGILITY-10) não acontece, porque cada pedido tem um item.
- **Validation rules** (achado 3: obrigatoriedade duplicada e máquina de estados abandonada): o fixture preenche todo campo que as 17 regras de `Order`, as 6 de `Account` e as 4 de `OrderItem` exigirem, não só os da demanda (doutrina, SOMOSAGILITY-10). Não há status de rascunho em `Order.Status`. Se a regra de status impedir criar o pedido direto em "Liberacao Financeiro", o fixture cria em "Revisao de Pedido" e avança o status, e o plano de build registra o caminho.
- **Escala da solução em produção:** relatório Summary não tem limite de governador. O detalhe na tela mostra até 2.000 linhas, mas os totais e o painel agregam tudo. O volume real de `Order` não foi medido, porque a dev está vazia. Não há risco de CPU nem de SOQL na solução.

## 7. Premissas assumidas (validar na homologação)

As PA-01 a PA-15 vêm da análise e seguem valendo com o texto de lá, exceto onde está indicado. As PA-16 a PA-23 são decisões deste design. Todas são configuráveis.

- [x] **PA-01 a PA-04, PA-06 a PA-10, PA-12 a PA-15**: mantidas como na `01-analise.md` §5 (escopo, o que é previsão, soma simples, vendedor = dono da conta, mês de `ExpectedSaleDate__c`, sem meta, sem faturado, canal relatório e painel, somente leitura, sem armazenamento, critério funcional, prazo, sobreposição com a EPLAST-32). Reforço da PA-02: o rótulo do campo na org é "Data previsão de vendas" (recon §8).
- [x] **PA-05 (refinada) · Região.** *Pergunta:* região é UF ou agrupamento de UFs? *Decisão:* agrupamento das UFs do estado de cobrança da conta nas 6 regiões que a Eplast já usa (CO, MG, NO/NE, RJ/ES, SP, SUL), e a UF fica visível no detalhe. "DIRETA" não entra como região, porque na org é carteira de um proprietário, não geografia. *Evidência:* filtros `ADDRESS1_STATE` dos relatórios `Número Total da Carteira <região>` (recon §8). *Como mudar:* editar as entradas do bucket no relatório, sem deploy de código. Para usar a UF pura, troca-se o agrupamento pela coluna `Account.BillingState`.
- [x] **PA-11 → ver PA-20.**
- [x] **PA-16 · Quais pedidos contam como previsão.** *Pergunta:* entram todos os pedidos com data prevista ou só alguns status e tipos? *Decisão:* os mesmos filtros do relatório `Previsão de Imputados Período`: status Liberacao Financeiro, Liberacao Estoque ou Faturamento; a lista de 9 setores mais vazio; exclusão dos 8 tipos de operação. *Evidência:* é como o relatório de previsão em uso define o universo (recon §1). Assim o total novo bate com o que o ADV já vê. *Como mudar:* editar os filtros nos 4 relatórios. São só 4 relatórios, sem dependência.
- [x] **PA-17 · Vendedor = dono da conta, não do pedido.** Confirma a PA-04 com nova evidência: o relatório `Número Total das Carteiras` também agrupa por dono da conta (recon §8). *Como mudar:* trocar o agrupamento por `Order.OwnerId`, que já está no tipo de relatório.
- [x] **PA-18 · Valor.** *Pergunta:* qual valor somar? *Decisão:* `TotalAmount` como valor da previsão (RN-1). `Total com Indenização` (`TotalAmount - Discount__c`) aparece como segunda soma, só informativa. *Evidência:* o relatório de período mostra os dois, o de "HOJE" usa o segundo (recon §1), e a fórmula foi confirmada (recon §8). *Como mudar:* inverter qual soma é a principal no relatório e no painel.
- [x] **PA-19 · "Sem data prevista" como componente próprio, não como linha.** *Pergunta:* como mostrar pedido sem data sem distribuí-lo entre meses? *Decisão:* relatório e componente de painel próprios ("Pedidos sem data prevista"). Os relatórios por período não os incluem. *Evidência (padrão da plataforma):* agrupamento por data põe o vazio num grupo rotulado `-`, sem como renomear por metadata, e bucket não se aplica a campo de data. Juntar o vazio ao filtro de período exigiria filtro customizado com lógica OR, e o usuário perderia o seletor padrão de período. *Ajuste do critério de aceite:* no cenário 3, "a linha 'Sem data prevista'" passa a ser "o relatório e o componente 'Pedidos sem data prevista'". O resto do cenário se mantém. *Como mudar:* se o cliente preferir a linha no mesmo relatório, troca-se o filtro de data por filtro customizado com OR. É configuração.
- [x] **PA-20 · Visibilidade por grupo público, não por permission set (ajusta a PA-11).** *Pergunta:* quem entra no grupo? *Decisão:* o grupo `Comercial_Previsao_Vendas` sai vazio na metadata, e o administrador da Eplast inclui os gestores comerciais como passo pós-deploy. Para o QA, entra um usuário de teste. *Evidência:* permission set não compartilha pasta (padrão da plataforma). A org não tem hierarquia que identifique "gestão" (2 papéis, recon §6). **Limite:** 14 dos 19 usuários ativos têm "Ver todos os dados" ou "Gerenciar relatórios em pastas públicas" e veem a pasta de qualquer forma (recon §8). A restrição só vale para os demais. Mudar essas permissões fica fora desta demanda. *Ajuste do critério de aceite:* no cenário 6, o usuário de teste é um **sem** essas duas permissões. *Como mudar:* incluir ou retirar membros do grupo, ou compartilhar a pasta com um papel. Nada disso exige deploy.
- [x] **PA-21 · Painel dinâmico (usuário logado).** *Pergunta:* o painel roda como quem? *Decisão:* `LoggedInUser`. *Evidência:* com OWD `ReadWrite` em `Account` e `Order`, o resultado é o mesmo de um usuário fixo. Um usuário fixo poria um username na metadata, o que viola o guardrail 2 e quebra o deploy entre sandboxes. A org tem 4 painéis dinâmicos, e o Enterprise Edition costuma limitar a 5 (limite não confirmado por deploy; doutrina). **Este painel ocupa a última vaga provável.** A EPLAST-32 deve acrescentar componentes a ele, não criar outro painel dinâmico, o que é coerente com a PA-15. *Como mudar:* trocar para `SpecifiedUser` na tela, escolhendo o usuário em cada org.
- [x] **PA-22 · Período padrão.** *Pergunta:* que intervalo o relatório abre? *Decisão:* ano corrente, editável no filtro. *Evidência:* padrão mais simples. O relatório de molde usa datas fixas, que envelhecem. *Como mudar:* trocar o intervalo padrão do filtro.
- [x] **PA-23 · Os relatórios existentes não são alterados.** *Pergunta:* ajustar o relatório de previsão existente ou criar um novo? *Decisão:* criar novo na pasta restrita, copiando os filtros. *Evidência:* o existente é de uso diário do ADV, com datas fixas e pasta aberta. Ganhar 3 níveis de agrupamento mudaria o uso dele (recon §1). Regra 3 cumprida pela reutilização do tipo de relatório e dos filtros. *Como mudar:* se o ADV quiser a nova visão, basta incluí-lo no grupo.

## 8. Pendências bloqueantes (caso c)

**Nenhuma.** Não há pergunta de negócio que a org ou o padrão não resolvam e que seja cara de desfazer. Tudo aqui é relatório e pasta, sem dado persistido e sem mudança de modelo ou de compartilhamento.

Fica para o arquiteto humano neste gate um ponto de **ambiente**, não de negócio (risco R1): confirmar que `sbx-eplast-dev` é a sandbox de dev. Se for a mesma da QA, o build e o roteiro de QA rodam no mesmo ambiente. Não é destrutivo para esta entrega, que é aditiva e usa dado sintético marcado e apagado ao final.

## 9. Riscos

### 9.1 Técnicos
| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Achado 6: `sbx-eplast-dev` traz a marca `qa`, e dev e QA podem ser a mesma sandbox | **Alta** (ambiente) | Confirmação humana neste gate. Fixture com prefixo e limpeza ao final. Nenhuma alteração destrutiva. |
| R2 | Dado sintético barrado por validation rules ou triggers de `Order`, `OrderItem` e `Account` (achados 1, 3, 10) | **Alta** (pode travar o build) | Seção 6: preencher todos os campos exigidos, avançar status se preciso, registrar o namespace do trigger que falhar. Se o fixture não for criado depois de corrigir os campos exigidos, a verificação sai `inconclusiva`, dizendo qual regra barrou, e o design não muda. |
| R3 | Sintaxe de bucket de texto, filtro relativo e componentes do painel descoberta por erro de deploy (achado EPLAST-39) | Média | Copiar exemplos da org. Duas recusas no mesmo campo levam à pendência no plano. Conferir cada componente pela Analytics API ainda no build. |
| R4 | "Sem região" pode aparecer como `-` (§4.4) | Baixa | Renomear na tela e registrar. |
| R5 | Restrição de pasta não alcança 14 dos 19 usuários (PA-20) | Média (expectativa do cliente) | Declarado na premissa e no roteiro do cliente. |
| R6 | Última vaga provável de painel dinâmico (PA-21) | Baixa | EPLAST-32 reutiliza este painel. Se o deploy recusar pelo limite, cair para `SpecifiedUser` configurado na tela de cada org e registrar. |
| R7 | Significado de `ExpectedSaleDate__c` sem descrição no metadata (achado 4) | Média | O rótulo "Data previsão de vendas" reforça a leitura. O cliente valida na homologação. |
| R8 | QA em sandbox com dado real expor valores de cliente | **Alta** (LGPD) | O QA só lê totais com filtro sobre as contas sintéticas (§10). Total sem filtro nunca vai para artefato. |

### 9.2 Riscos do assessment e como este design lida com cada um
| Achado | Toca? | Como |
|---|---|---|
| 1. Automação concorrente em Account, Opportunity e Order | Só no fixture | §6. A solução não grava. Opportunity não é tocada nem pelo fixture. |
| 2. Cobertura Apex ~10% | Não | A entrega não tem Apex. O fixture é script anônimo, rodado só nas sandboxes, e não vai para o deploy. Se surgir Apex, o design volta ao gate, com meta de 85% e `<Classe>Test`. |
| 3. Validation rules de Order | Só no fixture | §6 e R2 |
| 4. Campos sem descrição | Sim | R7. Os componentes novos levam descrição onde a metadata aceita (relatório, painel, grupo). Pasta não aceita. |
| 5. Convenção de classe de teste | Não | Sem Apex. |
| 6. Alias dev × qa | Sim | R1 |
| 7. Perfil Financeiro com 1 usuário | Não | Visibilidade por grupo, não por perfil. |
| 8. Perfis duplicados | Não | Idem |
| 9. API version das classes | Não | Sem Apex. Metadata nova na `sourceApiVersion` do projeto (67.0). |
| 10. Nome `OrderTrigger` duplicado | Só no fixture | Registrar o namespace em falhas (§6). |

## 10. Preparação do Sales Cloud para o Marketing Cloud

**Não se aplica.** A demanda é visão interna de pedidos previstos para gestão comercial. Não toca lead, origem, campanha, segmentação, público, nutrição, comunicação, relacionamento nem reativação. Não cria dado que o Marketing Cloud leia nem recebe retorno dele. O conector `et4ae5` não usa `Order` nem os campos de previsão (recon §4). Nada é feito no Marketing Cloud.

## 11. O que o QA deve testar (uma sessão; não é automação agendada)

Dado sintético em toda conta e pedido com o prefixo **`EPLAST31 TESTE`** no nome da conta. Valores redondos e fictícios. Dois proprietários: usuários existentes da sandbox, citados no artefato só como "Proprietário A" e "Proprietário B". Leitura pela Analytics API (`/analytics/reports/<id>` com filtro adicional "nome da conta começa com `EPLAST31 TESTE`" e período explícito), registrando só rótulos e totais desses registros sintéticos. Na sandbox de QA, **nenhum total sem o filtro do prefixo vai para artefato** (R8).

| # | Caso (critério da análise) | Como provar |
|---|---|---|
| 1 | Total por vendedor reconcilia | 3 contas, 2 proprietários, pedidos em março. A soma por proprietário é igual à soma calculada do fixture, e a soma dos proprietários é igual ao total geral. |
| 2 | Limites do mês | Pedidos em 31/03 e 01/04. O filtro de março pega só o primeiro. |
| 3 | Sem data prevista (PA-19) | Pedido sem data aparece em `Previsao_Vendas_Sem_Data_Prevista` e em nenhum mês dos outros relatórios. |
| 4 | Sem região | Conta sem `BillingState` (e outra com estado fora das siglas, por exemplo nome por extenso) cai em "Sem região". A soma das regiões é igual ao total. Conferir também uma UF de cada uma de duas regiões (por exemplo SP e PR → SUL). |
| 5 | Painel = relatório | Valor da métrica (1) igual ao total de `Previsao_Vendas_por_Mes` com o mesmo período. Em QA, comparar por script e gravar só "iguais: sim/não", porque o painel não aceita o filtro do prefixo. Conferir que nenhum componente tem `errorCode` (doutrina). |
| 6 | Acesso negado (PA-20) | Pela metadata: as duas pastas são compartilhadas só com `Comercial_Previsao_Vendas`. Teste negativo com um usuário fora do grupo e **sem** "Ver todos os dados" ou "Gerenciar relatórios em pastas públicas". Se o QA não puder logar como outro usuário, o caso fica `inconclusivo`, dizendo por quê, e o teste negativo vai para o roteiro do cliente. |
| 7 | Somente leitura | `COUNT()` de `Order`, `Opportunity`, `Account` e `Task` antes e depois de executar e exportar os relatórios. |
| 8 | Sem meta e sem faturado | Inspecionar colunas, filtros e componentes. |
| 9 | Filtros herdados (PA-16, fragilidade do achado 3) | Um pedido sintético em status `Cancelado` e um com setor fora da lista **não** entram nos totais. |
| 10 | Fixture e automação (achados 1 e 10) | Registrar se o fixture passou por todas as validation rules e triggers sem erro. Em erro, registrar a regra ou o trigger com namespace. |

Limpeza: o script de limpeza apaga, pelo prefixo, os pedidos, itens, entradas de lista de preço e contas criadas, na dev depois da verificação e na QA depois do veredito. Quem executa é o agente da etapa (builder ou verificador na dev, QA na QA).

O roteiro do cliente repete as PA-05, 16, 18, 19, 20, 21 e 22 na seção "O que assumimos e você precisa confirmar", com destaque para o significado da "Data previsão de vendas" e para quem entra no grupo.

## 12. O que NÃO será feito nesta demanda

- Meta, cota, faturado, realizado, gap ou projeção (EPLAST-32 e demandas futuras).
- Forecasting nativo, hierarquia de papéis, territórios, mudança de OWD ou de compartilhamento.
- Campo, Flow, trigger ou classe Apex. Alteração nos relatórios existentes.
- Alteração das permissões amplas ("Ver todos os dados" e semelhantes) dos 14 usuários.
- Extensão do `SFAgent2`.
- Agendamento de envio do painel por e-mail. Assinatura de relatório é recurso do usuário, não entrega.
- Qualquer coisa no Marketing Cloud.
- Curadoria de descrição dos campos existentes (achado 4).

## 13. Plano de build (passos curtos)

1. Branch `feature/EPLAST-31`. Confirmar `sf org list` e `IsSandbox` em `sbx-eplast-dev`.
2. Retrieve de `ReportType:Pedidos_customizados` e do relatório `Previso_de_Pedidos_Perodo_Yko` (este para `/tmp`, como molde de filtros; não entra no PR).
3. Estender `Pedidos_customizados` com `Account.Owner`, `Account.BillingState` e `Account.Sector__c`. Deploy com `--dry-run`, depois o deploy real. Confirmar as colunas novas pelo describe do tipo.
4. Criar o grupo `Comercial_Previsao_Vendas` e as pastas `Previsao_de_Vendas` e `Previsao_de_Vendas_Paineis`, compartilhadas com o grupo.
5. Procurar na org um relatório com filtro de data relativo e copiar o enum. Criar os 4 relatórios (§4.2–4.4), com os filtros copiados do molde.
6. Criar o painel `Previsao_de_Vendas` (`LoggedInUser`, 5 componentes). Deploy com `--dry-run`, depois o real.
7. Criar e rodar na dev o script de dado sintético (`EPLAST31 TESTE`) e guardar o script de limpeza junto, fora de `force-app/`, por exemplo `scripts/EPLAST-31/`.
8. Conferir cada relatório e cada componente pela Analytics API (sem `errorCode` e sem `NO_DATA`) e os casos 1 a 9 da §11 na dev.
9. Gravar `04-plano-build.md` com o resultado, os desvios (bucket, enum, painel dinâmico) e os passos manuais pós-deploy: incluir membros no grupo e renomear o grupo `-` se necessário. Rollback: remover o painel, os relatórios, as pastas e o grupo, e reverter o `ReportType` ao XML do baseline.

## 14. Estimativa

**Estimativa de esforço:** 20–36 h

O que mudou em relação à análise (16–32 h):
- **Sobe:** o fixture em `Order` vai passar por 2 triggers no mesmo evento, 2 Flows, 17 validation rules ativas, 4 regras de `OrderItem` e um status sem rascunho. Esse é o maior risco de tempo (R2).
- **Sobe:** são 4 relatórios e 5 componentes, com sintaxe de bucket e de filtro relativo a confirmar por deploy (achado EPLAST-39).
- **Desce:** região, vendedor e o universo de pedidos vêm prontos da org (recon §8), sem rodada de definição. Não há permission set nem campo novo.
- Inclui a revisão e uma rodada de homologação. Não inclui o esforço do agente.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
