# EPLAST-31 — Previsão de vendas por vendedor, região, carteira e período

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), não contratada em `contrato.md`. Pela regra 1 da conta, o escopo não bloqueia esta análise.
**Origem:** Solicitação de Proposta Konecta, Implantação de IA no Salesforce Sales e Marketing (Eplast).
**Rodada:** 2 (2026-11-15). Refeita pela regra 4 da conta (premissas assumidas). A rodada 1 está em `rodada-anterior/` e serviu de referência, não de decisão.
**Org confirmada (`sf org list`):** alias `sbx-eplast-dev`, sandbox "Eplast" (`IsSandbox = true`). O username e a URL da instância também trazem a marca `qa` (identificadores omitidos aqui por conterem dado de conta). Isso é o achado 6 do assessment (alias de dev com nome de qa). Não consigo confirmar daqui qual sandbox é a dev. Antes de qualquer escrita, a equipe Eplast precisa confirmar a identidade (seção 8). Nesta etapa só houve leitura de metadata e contagens agregadas.

**Fontes:** `demanda.md`, `comentarios-do-card.md` (orientação de 2026-11-13 e decisão de 2026-11-15), `rodada-anterior/01-analise.md`, `02-recon.md`, `03-design.md`, `contrato.md`, `assessment.md` (busca por trecho), RAG de delivery e `sf` com metadata e contagens.

---

## 1. Contexto de negócio

A Eplast quer enxergar a previsão de vendas por vendedor, região, carteira e período, sem que o comercial monte a conta à mão. O `demanda.md` não diz qual "previsão" é essa. Com base na org, o comercial já chama de "previsão" os **pedidos com data prevista de venda**. Há relatórios `Previsão de Imputados Período`, `Previsão de Pedidos HOJE` e variações em dev. Ver PA-02.

A EPLAST-32 pede um painel de meta, faturado, pedidos imputados e projeção por vendedor e equipe. Os dois temas se sobrepõem (PA-15).

## 2. Objetivo

Oferecer ao gestor comercial uma visão de pedidos previstos (valor e quantidade) agrupada por vendedor, carteira, região e mês, com leitura por Salesforce (relatório e dashboard), sem cálculo de projeção, sem meta e sem escrita em registro.

Critério de sucesso da v1: os totais batem com os registros de origem e a visão só aparece para quem tem a pasta liberada. Acurácia da previsão não é critério desta versão (PA-13).

## 3. Regras de negócio (v1)

- **RN-1 Previsão:** soma de `Order.TotalAmount` dos pedidos com `Order.ExpectedSaleDate__c` dentro do intervalo do filtro. Sem probabilidade e sem projeção (PA-02, PA-03).
- **RN-2 Vendedor e carteira:** proprietário da conta (`Account.OwnerId`), a mesma chave que o relatório existente usa. `Order.Salesperson1__c` (texto livre) não é usado (PA-04).
- **RN-3 Região:** estado do endereço de cobrança da conta (`Account.BillingAddress`, campo padrão composto). Conta sem estado vai para "Sem região" (PA-05).
- **RN-4 Período:** mês calendário de `Order.ExpectedSaleDate__c`. Pedido sem data prevista vai para a linha "Sem data prevista" e não é distribuído entre meses (PA-06).
- **RN-5 Fora da v1:** meta, faturado e realizado, integração com Protheus, cotas e territórios (PA-07, PA-08).
- **RN-6 Visibilidade:** a visão fica em pasta de relatório restrita. Na v1, o vendedor não enxerga a visão dos colegas (PA-11).
- **RN-7 Somente leitura:** nenhum registro de Order, Opportunity, Account ou Task é criado ou alterado pela visão (PA-10).

## 4. Critérios de aceite (Gherkin, testáveis em dev com dados sintéticos)

```gherkin
Funcionalidade: Previsão de pedidos por vendedor, região e mês (EPLAST-31, v1)

  Cenário: Total por vendedor reconcilia com os pedidos de origem
    Dado um conjunto sintético de 3 contas de 2 proprietários, com pedidos cuja data prevista cai em março
    Quando o relatório de previsão é executado com o filtro de março
    Então o total de cada proprietário é igual à soma de TotalAmount dos seus pedidos com data prevista em março
    E a soma dos proprietários é igual ao total geral do relatório

  Cenário: Limites do mês são respeitados
    Dado um pedido com data prevista no último dia de março e outro no primeiro dia de abril
    Quando o relatório é executado com o filtro de março
    Então o pedido de 31 de março entra no total
    E o pedido de 1 de abril não entra

  Cenário: Pedido sem data prevista não é distribuído entre meses
    Dado um pedido sem ExpectedSaleDate__c
    Quando o relatório é executado para qualquer intervalo
    Então o valor aparece apenas na linha "Sem data prevista"
    E não aparece em nenhum mês

  Cenário: Conta sem estado de cobrança cai em "Sem região"
    Dado uma conta sem estado no BillingAddress com pedido previsto no mês
    Quando o relatório é agrupado por região
    Então o valor aparece na linha "Sem região"
    E a soma de todas as regiões continua igual ao total geral

  Cenário: Dashboard e relatório mostram o mesmo total
    Dado um dashboard com o componente de total de previsão do mês
    Quando o relatório base é executado com o mesmo filtro
    Então o valor do componente é igual ao total do relatório

  Cenário: Usuário sem a pasta liberada não vê a visão
    Dado um usuário comercial sem acesso à pasta de previsão
    Quando procura relatórios e dashboards de previsão e tenta abrir a URL direta
    Então a visão não aparece na lista
    E o acesso direto é negado

  Cenário: Consulta não altera registros
    Dado a contagem de Order, Opportunity, Account e Task no ambiente de teste
    Quando um usuário com acesso consulta, filtra e exporta a previsão
    Então a contagem de cada objeto é igual antes e depois da consulta

  Cenário: Meta não aparece nesta visão
    Dado a visão de previsão publicada
    Quando a lista de colunas e componentes é inspecionada
    Então não há coluna, componente ou filtro de meta ou de faturado
```

Observação: a v1 não tem critério de acurácia (erro entre previsão e realizado). Isso só entra quando houver fonte de realizado e medição de piloto (PA-13).

## 5. Premissas assumidas (validar na homologação)

Cada decisão abaixo foi tomada pela ordem da regra 4: o que a org mostra, depois o padrão. Todas são configuráveis.

- [x] **PA-01 · Escopo.** *Pergunta:* a Onda 3 está autorizada? *Decisão:* sim, a frente segue análise, design e build. *Evidência:* orientação do responsável pela conta em `comentarios-do-card.md` (2026-11-13, item 1); regra 1 da conta. *Como mudar:* não muda o desenho. O prazo e o aditivo são tratados pelo gestor de conta.

- [x] **PA-02 · O que é "previsão".** *Pergunta:* o forecast é previsão de pedidos, de oportunidades ou projeção? *Decisão:* previsão de pedidos por data prevista de venda, a leitura que o comercial já usa. *Evidência:* quatro relatórios `Previsão de ...` existem em dev, entre eles `Previsão de Imputados Período` (DeveloperName `Previso_de_Pedidos_Perodo_Yko`), confirmados por `sf`; o recon (rodada 1, seção 5) registra que esse relatório usa `ExpectedSaleDate__c`, sem reler o filtro interno. O Forecasting nativo está ligado, mas tem um único tipo ativo (`Opportunity_Amount`), zero cotas e hierarquia de papéis quase vazia (17 usuários sem papel). Usá-lo exigiria mudar a hierarquia e o compartilhamento, o que não é neutro (recon, seção 2). *Como mudar:* se o cliente quiser previsão de oportunidade (`Amount` × `CloseDate` ou categoria de forecast), a fonte do relatório troca sem código. Isso muda RN-1, e o arquiteto avalia o custo. Também é preciso que o cliente confirme o significado de `ExpectedSaleDate__c`, que está sem descrição no metadata (achado 4).

- [x] **PA-03 · Fórmula.** *Pergunta:* a previsão é soma simples, ponderada por probabilidade ou projeção histórica? *Decisão:* soma simples de `TotalAmount`. *Evidência:* padrão dos relatórios existentes; projeção por histórico precisa de dados que a dev não tem (0 Opportunity e 0 Order, contagem agregada de hoje). *Como mudar:* uma coluna ou filtro de probabilidade, ou um modelo de projeção, quando houver histórico real. Isso é demanda nova.

- [x] **PA-04 · Vendedor e carteira.** *Pergunta:* o vendedor é o dono da conta ou do pedido? *Decisão:* proprietário da conta (`Account.OwnerId`), como o relatório existente agrupa. *Evidência:* `Order.OwnerId` existe, mas `Order.Salesperson1__c` é texto livre de 255 caracteres (`sf`, metadata), então não é chave confiável. *Como mudar:* trocar a chave de agrupamento para `Order.OwnerId` se o cliente disser que o vendedor é o dono do pedido. É troca de agrupamento no relatório.

- [x] **PA-05 · Região.** *Pergunta:* como a conta pertence a uma região? *Decisão:* estado do `BillingAddress`. *Evidência:* `Account.BillingAddress` é campo padrão do tipo Endereço. A busca por campos com `UF`, `Regi`, `Setor` e `Carteira` em Account não achou nenhum campo custom de região (só `StateRegistration__c`, que é inscrição estadual, não região). `Territory2` tem 0 registros em dev (contagem agregada). *Como mudar:* usar `ShippingAddress` ou um campo de região quando o cliente definir a regra. Território só com decisão de arquiteto, porque muda compartilhamento.

- [x] **PA-06 · Período.** *Pergunta:* qual granularidade e qual data? *Decisão:* mês calendário de `ExpectedSaleDate__c`, com intervalo escolhido no filtro. Pedido sem data vai para linha própria. *Evidência:* os relatórios existentes filtram por período usando essa mesma data. *Como mudar:* trimestre ou ano são filtros e agrupamentos do relatório, sem código.

- [x] **PA-07 · Meta fora da v1.** *Pergunta:* de onde vem a meta? *Decisão:* a v1 não tem meta. *Evidência:* o recon (rodada 1, seção 4) não achou objeto nem campo de meta em Account, Opportunity, Order ou User, e `ForecastingQuota` está vazio. O recon não foi reconfirmado nesta etapa. *Como mudar:* quando a fonte da meta for definida, entra como incremento, e a análise de meta fica com a EPLAST-32.

- [x] **PA-08 · Realizado e faturado fora da v1.** *Pergunta:* a previsão precisa de faturado? *Decisão:* não. *Evidência:* o pedido é de previsão; `Order` vem da integração com o Protheus, cuja qualidade já é risco registrado (`contrato.md`, `eplast-ent-11`). *Como mudar:* entra como coluna se o cliente pedir. A dependência da integração vira escopo próprio.

- [x] **PA-09 · Canal.** *Pergunta:* onde a visão aparece? *Decisão:* relatório e dashboard do Salesforce (Lightning). Sem Apex, sem Flow e sem assistente na v1. *Evidência:* a org tem 374 relatórios e 19 dashboards (rodada 1, design, seção 2.4), e a doutrina prefere configuração antes de código. *Como mudar:* se o cliente pedir resposta em linguagem natural, a regra 3 manda estender uma ação do `SFAgent2`, sem criar agente novo. O briefing diz que o agente existe e foi conferido em 2026-11-10. Não confirmei isso nesta etapa.

- [x] **PA-10 · Somente leitura.** *Pergunta:* a visão grava algo? *Decisão:* não. *Evidência:* o pedido é de visualização. Não gravar evita a concorrência de automação em Opportunity e Order (achado 1 do assessment). *Como mudar:* escrita (ajuste de previsão, submissão) é análise nova, com mapeamento da ordem de execução antes.

- [x] **PA-11 · Visibilidade.** *Pergunta:* quem vê o quê? *Decisão:* a pasta do relatório fica restrita a gestão comercial (permission set novo, nome a definir no design). Vendedor não vê a visão dos colegas na v1. *Evidência:* o OWD de Account e de Order é `ReadWrite` e o de Opportunity é `Read` (`sf`, `EntityDefinition`). Nesses objetos, o compartilhamento de registro não separa vendedores, então a barreira real é a pasta do relatório. Não existe permission set de previsão (recon). *Como mudar:* liberar a pasta para vendedores ou criar a visão "minha carteira" com filtro pelo usuário logado. Ambas são reversíveis e não mexem em compartilhamento.

- [x] **PA-12 · Dados pessoais e retenção.** *Pergunta:* a performance individual é guardada? *Decisão:* a visão lê dado vivo. Não há snapshot, campo novo nem histórico. Retenção não se aplica à v1. *Evidência:* consequência do PA-10. *Como mudar:* snapshot mensal de previsão é demanda nova e exige regra de retenção aprovada pelo cliente.

- [x] **PA-13 · Critério de sucesso.** *Pergunta:* qual métrica de erro? *Decisão:* a v1 é aceita por critério funcional (reconciliação, período, permissão, somente leitura). Acurácia fica fora. *Evidência:* a dev não tem histórico, e a medição depende de dado real que a sandbox não tem. *Como mudar:* a medição entra com o piloto (`eplast-ent-12`), se o cliente quiser.

- [x] **PA-14 · Prazo e documento de origem.** *Pergunta:* qual prazo e qual teto? *Decisão:* a demanda não tem prazo e não bloqueia análise nem build. A v1 é o que o `demanda.md` pede. *Evidência:* o contrato atual termina em 2026-11-30 e a Onda 3 não está nele. A Solicitação de Proposta não está no workspace. *Como mudar:* prazo e teto ficam com o gestor de conta. Se a proposta trouxer mais escopo, anexar o texto em `demanda.md` e abrir análise de delta.

- [x] **PA-15 · Sobreposição com a EPLAST-32.** *Pergunta:* a 31 é a mesma entrega que a 32? *Decisão:* a 31 entrega a visão de pedidos previstos por vendedor, região e período. A 32 (meta, faturado, projeção, gap) reutiliza os mesmos relatórios e campos e não cria segundo painel. *Evidência:* a rodada 1 (`03-design.md`, comparação de sobreposição) marcou a sobreposição como alta; a RAG cita `demandas/EPLAST-32/01-analise.md`, que não reli nesta etapa. *Como mudar:* se o cliente quiser unir ou separar, muda o escopo da 32. O desenho da 31 não muda.

---

## 6. Pendências que bloqueiam

Nenhuma. Pelo critério da regra 4, a pendência só bloqueia quando nem a org nem o padrão indicam caminho e errar é caro ou difícil de desfazer. Nas perguntas levantadas:

- Forecasting nativo com hierarquia de papéis seria caro de desfazer, porque muda compartilhamento. Não entra na v1, então não bloqueia.
- O significado de `ExpectedSaleDate__c` é o ponto mais sensível. Se estiver errado, o relatório mostra outra coisa, mas corrigir é trocar o campo ou o filtro, sem dado persistido. Fica como validação na homologação (PA-02), não como bloqueio.
- Visibilidade só afeta a pasta do relatório, que é reversível (PA-11).

## 7. O que a demanda não diz, e onde está resolvido

| Pergunta da rodada 1 | Situação | Onde |
|---|---|---|
| Q1 Onda 3 autorizada? | Resolvida pela regra 1 e pela orientação do card | PA-01 |
| Q2 Sobreposição com EPLAST-32 | Decidida: reuso, sem segundo painel | PA-15 |
| Q3 O que é "previsão"? | Decidida pela org (pedido previsto) | PA-02, PA-03 |
| Q4 Fonte de meta e de realizado | Fora da v1 | PA-07, PA-08 |
| Q5 Carteira e região | Decidida pela org | PA-04, PA-05 |
| Q6 Período | Decidida pela org | PA-06 |
| Q7 Canal e frequência | Decidida pelo padrão (relatório e dashboard). Frequência fica para o piloto | PA-09 |
| Q8 Escrita | Decidida: somente leitura | PA-10 |
| Q9 Público e perfis | Decidida: pasta restrita; vendedor fora na v1 | PA-11 |
| Q10 Modelo de compartilhamento | Medido: OWD de Account e Order é ReadWrite, de Opportunity é Read | PA-11 |
| Q11 Dados pessoais | Decidida: sem armazenamento | PA-12 |
| Q12 Métrica de sucesso | Decidida: critério funcional na v1 | PA-13 |
| Q13 Prazo e orçamento | Não bloqueia. Fica com o gestor de conta | PA-14 |
| Q14 Documento de origem | Não bloqueia. Anexar se houver mais escopo | PA-14 |

## 8. Riscos do assessment que tocam o pedido

- **Achado 6, alias de dev com nome de qa (severidade alta para o build).** A org de `sbx-eplast-dev` tem URL com `--qa`. Não pude confirmar a identidade. Antes de qualquer escrita, a equipe Eplast precisa confirmar qual sandbox é a dev. A análise é só leitura, então não depende disso. O build depende.
- **Achado 1, automação concorrente em Opportunity e Order.** Não se aplica à v1, que é somente leitura (PA-10). Se a visão passar a gravar, o mapeamento da ordem de execução (trigger custom, trigger do CPQ e Flows) vira pré-requisito.
- **Achado 2, cobertura de teste em 10%.** Não se aplica à v1, que não tem Apex. Se algum Apex aparecer no build, ele precisa de classe de teste com 85% pelo padrão do squad.
- **Achado 4, campos sem descrição.** `ExpectedSaleDate__c` está sem descrição. Ele é o campo central do PA-02, então a homologação precisa validar o significado com o cliente.
- **Achado 8, perfis comerciais duplicados.** A visibilidade é por pasta e permission set (PA-11), não por perfil.
- **Dev sem dados.** Contagem agregada: 0 Opportunity, 0 Order e 0 Territory2. A validação dos critérios exige dados sintéticos criados em dev. Isso não pode ser feito com dado real, pela regra LGPD.

## 9. Complexidade e esforço

**Complexidade: M.** Justificativa: são só configurações de relatório, dashboard, pasta e permission set, sem código. Mas exige fixture sintética em uma dev vazia e a validação de quatro campos cujo significado depende do cliente.

**Estimativa de esforço:** 16–32 h
Premissas que mais pesam na faixa:
- Inclui: configuração de relatório e dashboard, pasta e permission set, criação de dados sintéticos em dev, testes dos critérios da seção 4, revisão e uma rodada de homologação com o comercial.
- A faixa sobe para 60 h ou mais se o PA-02 virar previsão de oportunidade ou Forecasting nativo com hierarquia, ou se a meta entrar (PA-07).
- Não inclui: o mapeamento de automação, caso a visão passe a gravar (PA-10), e a curadoria de descrição dos campos (achado 4).
- Não inclui o esforço do agente.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
