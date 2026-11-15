# EPLAST-33 — Design da solução

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** 3 (design, arquiteto)
**Org do recon:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, sandbox, API v68.0). Recon em `02-recon.md`, coletado em 2026-11-11.
**Entradas:** `01-analise.md` (aprovada no gate de análise), `comentarios-do-card.md`, `assessment.md` (2026-09-30, saúde vermelha), `contrato.md`, RAG do cliente (citado onde pesa).

**Status deste documento:** proposta para o gate bloqueante do arquiteto humano. **As perguntas bloqueantes da análise (Q1, Q2, Q3) não foram respondidas.** O card só registra a aprovação do gate de análise. Nenhuma resposta foi inventada aqui. O design separa:
- o que vale **para qualquer resposta** (seção 1, decisões firmes);
- a abordagem recomendada **para cada regra**, com o nível da doutrina e o caminho alternativo conforme a resposta (seções 2 e 3);
- o que **só o humano pode decidir** antes do build (seção 10).

---

## 0. O que o recon mudou em relação à análise

1. **A org já tem três definições diferentes de "cliente sem compra"** (`02-recon.md` §3.1 e §5):
   - `Account.Inactive__c`: fórmula, 90 dias desde `LastPurchase__c`. `LastPurchase__c` é roll-up de `MAX(Opportunity.CloseDate)` das oportunidades `Fechado/Ganho`. **Usa Opportunity, não pedido.**
   - CENÁRIO 9 do `SFAgent2_v4`: 60 dias desde o último `Order.EffectiveDate`.
   - CENÁRIO 4 do `SFAgent2_v4`: ranking por último `Order.EffectiveDate`, sem limiar.

   `eplast-ent-11` ainda vai definir a dela. A análise temia "duas listas com regras diferentes". Hoje já existem três. **Esta demanda não pode criar uma quarta** (D2).
2. **O agente `SFAgent2` (subagente `insights_comerciais`) já cobre recuperação, queda de volume e recompra da própria conta**, sob demanda e só com leitura. Ele não cobre **aumento de volume para cima** nem **venda cruzada por grupo de referência** (RN-3). Isso é exatamente a sobreposição da pergunta Q1, agora confirmada na org.
3. **Defeito latente no agente:** os filtros usam `Order.Status` `'Cancelled'`, `'Draft'`, `'Activated'` e `'Completed'`, que não existem no picklist desta org (`Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`, `Faturamento`, `Cancelado`, `Concluido`). Pedido cancelado conta como compra. O defeito é do território de `eplast-ent-09/10/11` e está registrado aqui (R6). Não é corrigido nesta demanda.
4. **Carteira não é segurança.** Account e Order são Public Read/Write internamente. RN-4 só pode ser um **filtro** de "minhas contas", não uma restrição de acesso.
5. **Criar fixture de teste na dev aciona o Protheus.** Todo insert ou update de Account enfileira `SendAccountToProtheus`. As Remote Sites `ProtheusProd` e `ProtheusQA` estão **as duas ativas** nesta sandbox. O endpoint está em `Protheus__mdt` e não foi lido. Isso vira uma pré-condição do build (D5).
6. **Venda cruzada não tem eixo de produto pronto.** `Product2.Family` tem um valor ativo só. O agrupamento teria que vir de `Product2.Group__c` (texto, sem descrição) ou do próprio produto (1042 produtos na dev).

---

## 1. Decisões firmes (valem para qualquer resposta de Q1–Q3)

**D1. Somente leitura sobre Account, Opportunity, Order, OrderItem, Product2 e Task.** Nenhum campo novo nesses objetos guarda resultado. Nenhum DML neles, nenhuma automação nova neles.
- Todo update de Account reenvia a conta ao ERP (`AccountTriggerHelper.updateAccountInfoFromCNPJ`, um `enqueueJob` por conta, sem filtro de campo; `02-recon.md` §4.3). Acima de 50 contas por transação síncrona, estoura o limite de `enqueueJob`.
- Account, Opportunity e Order têm trigger custom, trigger `SBQQ` e Flows after-save no mesmo evento (`02-recon.md` §4.1–4.2). O mesmo motivo levou à D1 de EPLAST-27 e à D1 de EPLAST-34 [RAG: `demandas/EPLAST-27/03-design.md`; `demandas/EPLAST-34/03-design.md`].
- **Se a resposta a Q3 for "gerar tarefa, oportunidade ou campo no registro", este design perde a validade e volta ao gate.** O pré-requisito passa a ser o mapeamento da ordem de execução que o assessment recomenda (achado 1).

**D2. Uma regra só por conceito, antes de qualquer build.** Antes de construir, o Comercial define, por escrito:
- o que é "compra": Order ou Opportunity ganha; quais `Order.Status` contam; qual data vale (`EffectiveDate` ou `IssuanceDate__c`, que coexistem);
- a janela N de recuperação.

A regra é **a mesma** de `eplast-ent-11` (Q5). Se o cliente aceitar `Inactive__c` como está, ela é reaproveitada. Se não aceitar, a decisão sobre aposentar ou alterar `Inactive__c` é do humano, não desta demanda (seção 9).

**D3. `SFAgent2` não é alterado por esta demanda sem decisão explícita do gate.** O agente é território de `eplast-ent-09/10/11`, construídos fora da esteira, e todas as versões estão `Inactive` na dev. A EPLAST-29 já propõe uma `SFAgent2_v5` [RAG: `demandas/EPLAST-29/03-design.md`], que **não existe na org**. Duas demandas abrindo a mesma próxima versão do mesmo agente se atropelam (guardrail #6).

**D4. Nenhum objeto ou campo novo sem escalação à arquitetura sênior.** Só a opção C (seção 3.3) exige objeto novo. Ela fica **escalada**, não decidida.

**D5. Nenhuma fixture criada na dev antes de confirmar o destino do Protheus.** O consultor confirma que `Protheus__mdt.Credentials.BaseURL__c` desta sandbox aponta para um ERP de teste. Se não aponta, a fixture usa o bypass existente (`TriggerUtility__mdt.TriggerExecution.BypassTrigger__c`), só durante a carga e com aceite do humano. A alternativa é a sandbox de QA, depois que o achado 6 for resolvido. A fixture preenche todo campo exigido pelas validation rules ativas de Account e Order, e de Opportunity se a regra usar Opportunity (doutrina, achado SOMOSAGILITY-10).

**D6. Permissão por pasta de relatório e permission set, nunca por perfil.** Os quatro perfis comerciais duplicados (achado 8) não são alterados.

---

## 2. Decisão de abordagem por regra

A ordem da doutrina é configuração, depois Flow, depois código. Cada regra foi avaliada separadamente, porque têm naturezas diferentes.

| Regra | Nível recomendado | Por que este nível | Por que não o nível acima |
|---|---|---|---|
| **RN-1 Recuperação** | **Configuração**: relatório de contas com filtro cruzado "sem pedidos no período" (ou filtro `Inactive__c = true`, se D2 escolher Opportunity) | O filtro cruzado responde "conta sem Order que atenda X nos últimos N meses" sem campo novo, sem automação e sem código | É o topo da escada |
| **RN-2 Volume** | **Configuração**: relatório resumido de Order por conta e por período (mês ou trimestre), com fórmula de resumo `PREVGROUPVAL` para a variação e destaque condicional | Comparação período contra período é recurso nativo do relatório resumido | É o topo. **Limite:** relatório não filtra pela fórmula de resumo. A lista ordena e destaca, mas não esconde as contas abaixo do limiar. Se o cliente exigir lista já filtrada pelo limiar, desce para a opção B ou C |
| **RN-3 Venda cruzada** | **Não resolvível em configuração.** Depende de Q2 (canal) e do volume: opção B (declarativa, agente) ou opção C (código + objeto novo, **escalada**) | Precisa comparar, para cada conta, o que ela compra com o que o grupo de referência compra. Isso é cálculo entre contas | Relatório consegue "contas que não compraram o produto P", mas um produto por vez, escolhido à mão. Não gera a lista por conta que a RN-3 pede. Flow não tem agregação (`GROUP BY`), e montar a matriz grupo × produto em Flow é loop sobre milhares de itens, o caso que a doutrina manda para Apex |

**Recomendação ao gate:**
- **Fase 1, liberável se o gate aceitar o escopo:** RN-1 e RN-2 em configuração. Isso não toca `SFAgent2`, não cria objeto e não depende da plataforma de IA.
- **Fase 2, condicionada:** RN-3 por B ou C, decidida no gate depois de Q2 e Q13.
- **Se a resposta a Q2 for "o canal é o assistente de IA"**, a Fase 1 encolhe para **um relatório de conferência** que o QA e o Comercial usam para validar os números do agente. As três regras passam a ser cenários do agente (opção B), com o defeito de status (R6) resolvido antes por quem é dono do `SFAgent2`. Assim nada é construído duas vezes.

Risco de expectativa: o item vem de uma proposta de "Implantação de IA". Relatório pode ser lido como resposta insuficiente (R8). A Fase 1 é o **piso**, com as mesmas regras que qualquer canal de IA vai usar. Não é apresentada como "a IA".

---

## 3. Opções para a Fase 2 (RN-3) e para o caso "canal = agente"

### 3.1 Opção B: novo cenário no `insights_comerciais` (declarativo, Agentforce)

- **Componentes propostos (nenhum existe):** cenário "OPORTUNIDADES DE VENDA CRUZADA" no subagente `insights_comerciais`, numa nova versão de `SFAgent2`. Usa só as ações padrão já presentes (`queryRecordsWithAggregate`, `queryRecords`). São duas agregações:
  - (a) produtos comprados pela conta na janela M, `OrderItem` por `Product2Id`;
  - (b) produtos comprados pelo grupo de referência, `OrderItem` por `Product2Id` com contagem distinta de `Order.AccountId`, filtrado pelo campo de grupo de Q8.

  O modelo apresenta a diferença com o motivo, e as instruções proíbem inventar preço ou condição, como o agente já faz.
- **Quando é a certa:** Q2 = agente; volume do grupo de referência dentro do limite de linhas (abaixo); decisão LGPD tomada sobre o que vai ao LLM.
- **Pré-requisitos:**
  1. POC de no máximo 4 h numa sandbox **com volume**. A dev está vazia, então o número só sai da QA ou de uma sandbox com cópia de dados.
  2. Correção dos filtros de status (R6) por quem é dono do agente.
  3. Coordenação com a EPLAST-29 sobre a versão (D3).
- **Por que não C:** não cria objeto, não cria Apex. Fica no nível declarativo.

### 3.2 Limite que decide entre B e C

Em consulta agregada com `SUM`, `MAX` ou `COUNT_DISTINCT`, cada linha agregada conta para o limite de 50.000 linhas por transação. A agregação (b) varre todos os `OrderItem` do grupo de referência na janela M. Exemplo: um setor com 2.000 contas, 12 pedidos por ano cada e 5 itens por pedido dá cerca de 120.000 linhas e **estoura**.

O volume de produção não é conhecido (`02-recon.md` §9). A regra de corte da doutrina vale aqui: se a POC medir mais de cerca de 70% do limite no grupo maior, B sai e entra C. A semântica exata de contagem de linhas em consulta agregada com `GROUP BY` deve ser conferida na documentação oficial na POC, não presumida.

### 3.3 Opção C: cálculo agendado em Apex + objeto de resultado (código) — **ESCALADA À ARQUITETURA SÊNIOR**

- **Mudança de modelo de dados:** um objeto custom novo para guardar o resultado (conta, tipo de oportunidade, produto, motivo, data do cálculo). Pela regra do papel, **não decido isso sozinho.** O cliente também não tem prefixo de campo definido no `CLAUDE.md` da conta, e isso precisa ser definido junto.
- **Componentes propostos (nenhum existe):**
  - classe `CrossSellOpportunityBatch` (`Database.Batchable` + `Schedulable`, `with sharing`, consultas `WITH USER_MODE` onde couber) e `CrossSellOpportunityBatchTest`, com 85%;
  - permission set `PS_Comercial_OportunidadesCarteira` (leitura do objeto novo);
  - list view, relatório ou componente na `Account_Record_Page` para mostrar o resultado.
- **Desenho de escala:**
  1. A matriz grupo × produto é calculada **uma vez** por execução: no máximo 9 setores × 1042 produtos, menos de 10 mil linhas de resultado.
  2. A comparação por conta roda em lotes de 200 contas, com uma consulta agregada por lote (nunca por conta).
  3. O objeto novo é apagado e regravado por execução. Ele **não tem** trigger nem Flow. Se ganhar algum, o design volta ao gate.
  4. Cenário "um pai com muitos filhos": uma conta com dezenas de milhares de itens na janela pode, sozinha, aproximar o limite de linhas do lote. A mitigação é a janela M e um lote menor, a medir na sandbox com volume.
- **Por que não B:** só se a POC de B estourar o limite, ou se Q2 for lista ou relatório (sem agente).
- **Risco de deploy:** a cobertura org-wide é 11%. Um pacote com Apex novo para produção esbarra nos 75% da plataforma (achado 2). É risco de release, registrado em R9.

---

## 4. Componentes

### 4.1 Criar — Fase 1 (nomes propostos, **nenhum existe**; todos com `Description` preenchida, achado 4)

| Componente | Tipo | Base confirmada na org |
|---|---|---|
| Pasta `EPLAST_Oportunidades_Comerciais` | ReportFolder | — |
| `Recuperacao_Contas_Sem_Compra` | Report (tabular, Account, filtro cruzado "sem Order" com subfiltro de status e data da D2; ou filtro `Inactive__c`) | `Order.Status`, `Order.EffectiveDate`, `Account.Inactive__c` confirmados (`02-recon.md` §3.1) |
| `Volume_Variacao_Por_Conta` | Report (resumido, base Order, agrupado por conta e por período, `PREVGROUPVAL`) | report type custom `Pedidos_customizados` (base Order) ou o report type padrão de pedidos, a escolher no build; `Order.TotalAmount` confirmado |
| Painel `EPLAST_Oportunidades_Comerciais` (opcional, Q16) | Dashboard | — |

O filtro de carteira (RN-4) é o filtro padrão "Minhas contas" ou "Meus pedidos" do relatório. Se Q10 disser que a carteira não é o `OwnerId` (por exemplo, `Order.Salesperson1__c`, que é **texto livre**), o filtro muda, e texto livre não serve como chave confiável (R7).

### 4.2 Criar — Fase 2

Só depois do gate da Fase 2: os componentes da seção 3.1 (B) **ou** da seção 3.3 (C).

### 4.3 Alterar

**Nenhum** na Fase 1. Na Fase 2/B, uma versão nova de `SFAgent2`, sujeita à D3.

### 4.4 Depreciar

**Nenhum.** Aposentar uma das três definições de "sem compra" é uma recomendação ao humano (seção 9), não algo que esta demanda faz.

---

## 5. Impacto em permissões

- **Fase 1:** nenhum perfil e nenhum permission set alterado. `Comercial - Analista` (único perfil comercial com usuário ativo, 4) já lê Account, Order e Product2, e já roda e cria relatório (`02-recon.md` §8). O acesso aos relatórios é dado **pelo compartilhamento da pasta** com o grupo ou papel que Q10 indicar.
- `Comercial Padrão` não lê Order e `Comercial - Analistas` não lê Product2. Hoje nenhum dos dois tem usuário ativo. Se Q10 incluir alguém nesses perfis, a leitura entra por **permission set novo**, nunca por mudança de perfil (D6).
- **Fase 2/B:** acesso ao agente por um PSG existente (`SetupWithAgentforceUserPsg` ou o que `eplast-ent-07` definiu). Isso precisa ser confirmado com o dono do agente.
- **Fase 2/C:** `PS_Comercial_OportunidadesCarteira` (proposto).
- OWD: Account e Order são Public Read/Write, então **não há como restringir a lista à carteira por segurança** sem mudar o OWD, o que está fora de escopo. A RN-4 é atendida como filtro. O cliente precisa saber disso (Q10).

---

## 6. Conflito de automação e ordem de execução

**Account, Opportunity e Order já têm trigger custom, trigger do CPQ (`SBQQ`) e Flows after-save no mesmo evento, sem ordem garantida (achado 1, reconfirmado em `02-recon.md` §4.1–4.2). Order tem dois triggers chamados `OrderTrigger` (achado 10). Este design não adiciona automação nenhuma nesses objetos e não grava neles (D1), então não entra nessa ordem. Se alguma resposta (Q3) exigir gravação, o design volta ao gate com o mapeamento da ordem de execução como pré-requisito.**

A única execução que aciona essa cadeia é a **criação de fixture** de teste (D5).

---

## 7. Governador e escala

| Cenário | Fase 1 (relatórios) | B (agente) | C (Apex agendado) |
|---|---|---|---|
| Muitos registros | Sem governador Apex. Relatório Lightning mostra até 2.000 linhas na tela, e mais por exportação. Filtro cruzado sobre muitos pedidos pode ficar lento: medir na QA | Limite de 50.000 linhas por agregação (seção 3.2). **Desconhecido sem volume** | Lotes de 200, uma agregação por lote, matriz calculada uma vez. Assíncrono: 60 s de CPU, 12 MB de heap |
| Um pai com muitos filhos (conta com muitos pedidos ou itens) | Sem efeito | A consulta de itens por conta (STEP 3B atual) não tem `LIMIT`. Uma conta grande pode trazer resposta parcial: o agente já é instruído a declarar cobertura parcial | Limite de linhas do lote: janela M e lote menor |
| CPU por cascata de automação | **Nulo**: sem DML | **Nulo**: sem DML | **Nulo** nos objetos existentes. O objeto novo não pode ganhar automação (seção 3.3) |
| SOQL e DML em loop | n/a | n/a | Proibido. Revisão de código reprova |

Critério de retorno ao design: se a medição em sandbox com volume passar de cerca de 70% de qualquer limite, o design volta para revisão.

---

## 8. Riscos

### 8.1 Riscos do assessment que tocam esta demanda

| Achado | Sev. | Como este design lida |
|---|---|---|
| 1. Automação concorrente em Account, Opportunity e Order | Alta | **Evitado por construção** (D1). Reconfirmado e agravado pelo recon: update de Account reenvia ao ERP. Volta ao gate se Q3 exigir escrita |
| 2. Cobertura Apex de 10% (hoje 11%) | Alta | Fase 1 e B: **não se aplica** (sem Apex). C: classe nova com `CrossSellOpportunityBatchTest` e 85%. O deploy em produção esbarra nos 75% org-wide (R9) |
| 3. Validation rules de Order | Média | Produção: não se aplica (sem escrita). **Teste:** a fixture precisa satisfazer as 23 regras de Order (D5) |
| 4. Campos sem descrição | Média | Componentes novos com `Description`. Os campos de entrada (`VolumeByMonth__c`, `Group__c`, `Volume1__c`, `IssuanceDate__c`, `Deleted2__c`) **não são usados** sem o Comercial confirmar o significado (Q6, Q7, Q17). O assessment proíbe inferir pelo nome |
| 5. Convenção `<Classe>Test` | Média | Só em C. A classe nova segue o padrão |
| 6. Alias dev aponta para instância "qa" | Média | **Ainda aberto** (`02-recon.md`, topo). `sbx-eplast-qa` não está autenticada. **Bloqueante para o QA**, e para a POC de B, que precisa de volume |
| 7, 8. Perfis | Baixa | Nenhum perfil alterado (D6) |
| 9. API antiga | Baixa | Nenhuma classe existente editada |
| 10. `OrderTrigger` duplicado | Baixa | Não tocado. Afeta só a leitura de log na fixture |
| Não medido: OWD | — | **Medido agora:** Account e Order Public Read/Write. RN-4 vira filtro (seção 5) |

### 8.2 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Escopo não contratado (Onda 3) e contrato termina em 2026-11-30 | **Alta (comercial)** | Build bloqueado até decisão de contrato (G1), independentemente deste gate |
| R2 | Quarta definição de "sem compra" divergindo de `Inactive__c`, do agente e de `eplast-ent-11` | **Alta** | D2. Uma regra escrita e aprovada pelo Comercial antes do build |
| R3 | Fixture na dev dispara callout ao ERP, possivelmente o de produção (`ProtheusProd` ativo) | **Alta** | D5. Confirmar `Protheus__mdt` antes de qualquer insert |
| R4 | Q3 = "gerar tarefa ou campo": entra na cadeia de automação não mapeada | **Alta** (se ocorrer) | Design volta ao gate (D1) |
| R5 | Volume de produção desconhecido: B pode estourar o limite de linhas | **Alta** para B / média para C | POC com volume antes de escolher (seção 3.2) |
| R6 | Filtros de status do `SFAgent2_v4` usam valores que não existem: cancelado conta como compra | **Média** (alta se B for escolhida) | Registrado para o dono do agente (`eplast-ent-09/10/11`). Pré-requisito de B. Não corrigido aqui |
| R7 | Carteira por `Order.Salesperson1__c` (texto livre) ou por `Order.OwnerId` pode não refletir o vendedor real se o pedido vier da integração | **Média** | Q10. Preferir `Account.OwnerId` até o cliente dizer o contrário |
| R8 | Cliente espera "IA" e recebe relatório | **Média (expectativa)** | Fase 1 apresentada como piso e verdade de referência. Caminho para B explícito |
| R9 | Apex novo (C) não sobe para produção com cobertura org-wide de 11% | **Média** (só C) | Risco de release. Registrar no 06 |
| R10 | EPLAST-29 e EPLAST-33 criando a mesma próxima versão do `SFAgent2` | **Média** (só B) | D3. Uma demanda por vez no agente |
| R11 | Pedidos que nascem só no Protheus podem não existir no Salesforce (existe `SendOrderToProtheus`, sentido SF → ERP) | **Média** | Q12. Validar uma amostra com o Comercial, como `eplast-ent-11` já exige |
| R12 | Devoluções (`SalesReturn__c`) fora da conta de volume distorcem RN-2 | **Baixa** | Pergunta Q18 |

---

## 9. O que NÃO será feito nesta demanda

- Nenhuma escrita em Account, Opportunity, Order, OrderItem, Product2 ou Task. Nenhum Flow, trigger, validation rule ou campo novo nesses objetos (D1).
- Nenhum objeto ou campo novo sem escalação (D4). A opção C fica escalada, não aprovada.
- Não alterar, ativar nem corrigir `SFAgent2` (D3). O defeito de status (R6) vai para o dono do agente.
- Não alterar nem aposentar `Account.Inactive__c` ou `LastPurchase__c`. Recomendação ao humano: depois de D2, decidir qual das três definições de "sem compra" sobrevive. É uma decisão que atravessa `eplast-ent-11`, o agente e esta demanda.
- Não consolidar a automação de Account, Opportunity e Order (achado 1, esforço alto, demanda própria).
- Não subir a cobertura Apex da org (achado 2).
- Não mudar OWD nem perfis.
- Não conciliar números com EPLAST-26, 31 e 32.
- Não validar com dado real nem consultar produção.
- Não enviar notificação. Q16 não foi respondida, e assinatura de relatório ou painel é opcional na Fase 1.

---

## 10. Decisões que o gate do arquiteto humano precisa tomar

O build **não começa** sem G1 a G4. G5 a G7 decidem a Fase 2.

| # | Decisão | Pergunta da análise | Bloqueia |
|---|---|---|---|
| **G1** | A Onda 3 está autorizada a entrar em esteira? | Ponto 0.1 | Todo o build |
| **G2** | EPLAST-33 é demanda própria, extensão de `eplast-ent-11` ou parte do `SFAgent2` (`eplast-ent-09/10`)? Se for extensão de ent-11, a recuperação sai desta demanda e as horas mudam | Q1, Q5 | Todo o build |
| **G3** | Canal e natureza: relatório/lista (Fase 1 como descrita) ou assistente de IA (Fase 1 vira conferência, regras vão para B)? Confirmar **somente leitura** | Q2, Q3 | Todo o build |
| **G4** | Definição única de "compra" e de "sem compra": Order ou Opportunity ganha; quais `Order.Status`; qual data; N; o que fazer com `Inactive__c` | Q4, Q5 + D2 | RN-1 e RN-2 |
| G5 | Métrica e limiar de volume. "Aumento de volume" é queda contra o histórico (o agente já faz) ou potencial não realizado? `Account.VolumeByMonth__c` é potencial declarado? | Q6, Q17 (nova) | RN-2 |
| G6 | Fonte de produto e grupo de referência para cruzada (`Product2.Group__c`? setor? região?) e janela M | Q7, Q8 | RN-3 |
| G7 | **Modelo de dados:** aceita objeto novo para resultado (opção C)? Se sim, o prefixo de campo da conta precisa ser definido no `CLAUDE.md` do cliente | Escalação D4 | RN-3 via C |
| G8 | Destino do Protheus nesta sandbox (`Protheus__mdt`) e autorização para criar fixture (D5) | nova | Teste |
| G9 | Achado 6: `sbx-eplast-dev` é dev mesmo? Onde está a `sbx-eplast-qa`? | — | QA e POC de B |

Perguntas novas desta etapa:
- **Q17.** O que significam `Account.VolumeByMonth__c`, `Order.Volume1__c`, `Product2.Group__c`, `Product2.QuantityConverter__c` e `Order.IssuanceDate__c` em relação a `EffectiveDate`?
- **Q18.** Volume é bruto ou líquido de devolução (`SalesReturn__c`)?
- **Q19.** Os pedidos nascem no Salesforce e vão ao Protheus, vêm do Protheus, ou os dois?

---

## 11. Estimativa de esforço humano

**Estimativa de esforço:** 18–100 h

Faixa por caminho, a ser fechada no gate conforme G2, G3 e G7:

| Caminho | Horas | Composição principal |
|---|---|---|
| **A. Fase 1 só (RN-1 + RN-2 em relatório)** | **18–32 h** | Sessão de regras com o Comercial (D2, G4/G5): 3–5. Confirmação do Protheus e plano de fixture (D5): 1–2. Relatório de recuperação: 2–4. Relatório de volume com `PREVGROUPVAL`: 4–6. Pasta, compartilhamento e painel opcional: 1–3. Fixture sintética satisfazendo as validation rules de Account e Order sem disparar callout: 4–8. Revisão e homologação: 3–4 |
| **B. Canal = agente (três regras no `SFAgent2`, relatório só de conferência)** | **38–60 h** | A reduzido (cerca de 14–24). POC com volume: 4. Cenários novos e correção de status coordenada com o dono do agente: 10–16. Decisão LGPD sobre o que vai ao LLM: 2–4. Regressão dos 9 cenários existentes: 6–10. Coordenação com a EPLAST-29: 2 |
| **C. A + venda cruzada em Apex com objeto novo (escalado)** | **70–100 h** | A completo. Modelagem e aprovação do objeto: 4–6. Batch, Schedulable e teste com 85%: 24–36. Exibição (list view, relatório ou componente): 6–10. Permission set: 1–2. Revisão de código e validação de volume: 6–10 |

**O que mudou em relação à análise (24–120 h) e por quê:**
- **Piso caiu de 24 para 18 h.** O recon mostrou que recuperação e variação de volume saem em configuração pura, sem campo novo (filtro cruzado e `PREVGROUPVAL`), e que a org já tem `Inactive__c` e as consultas do agente como referência. Por outro lado, a fixture custa mais do que a análise previa, por causa do callout ao Protheus (D5) e das validation rules de Order.
- **Teto caiu de 120 para 100 h.** A análise incluía "mapeamento e consolidação da automação concorrente". A D1 tira isso desta demanda: a solução não entra na cadeia, e a consolidação é uma demanda própria.
- **A faixa continua larga porque G2, G3 e G7 não foram respondidas.** Se G2 decidir que a recuperação é de `eplast-ent-11`, cerca de 6 a 10 h saem de qualquer caminho.

Esforço humano (consultor e dev configurando, revisando, testando e homologando). Não inclui tempo de agente.

---

## 12. Fontes de histórico (RAG)

- `[demandas/EPLAST-27/03-design.md]`: D1 somente leitura por causa do reenvio de Account ao Protheus, **reconfirmado na org nesta data** (`02-recon.md` §4.3); matriz de opções A a D, usada como referência para B e C.
- `[demandas/EPLAST-34/03-design.md]`, `[demandas/EPLAST-26/03-design.md]`, `[demandas/EPLAST-30/03-design.md]`: mesma linha de somente leitura e tratamento dos achados do assessment. Citados, não relidos em disco: as pastas dessas demandas neste workspace só têm `demanda.md` e `status.yaml`.
- `[demandas/EPLAST-29/03-design.md]`: propõe `SFAgent2_v5`. **A v5 não existe na org** (`02-recon.md` §5). Base da D3 e do R10.
- `[demandas/EPLAST-34/02-recon.md]`, `[demandas/EPLAST-28/02-recon.md]`: descrição do `SFAgent2` e do `insights_comerciais`. **Reconfirmado** por retrieve de `SFAgent2_v4` nesta coleta.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
