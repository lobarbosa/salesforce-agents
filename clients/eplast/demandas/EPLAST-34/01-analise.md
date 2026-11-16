# EPLAST-34 — Resumos automáticos para reuniões comerciais, GDD, S&OP e Board

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial). Não contratada no `contrato.md`, mas autorizada a seguir pelo responsável da conta (comentário de 2026-11-13; regra 1 da conta). Não é pendência.
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast).
**Status:** refeita em 2026-11-15 pela regra 4 da conta (pergunta de negócio sem resposta vira premissa assumida). Análise pronta para validação humana. Nenhuma pendência em aberto.

**Org confirmada (`sf org list`):** `sbx-eplast-dev` (usuário técnico da sandbox de dev, Sandbox, conectada). Todas as consultas desta etapa foram de leitura, só metadata e contagens agregadas. Nenhum registro de negócio foi lido.

**Fontes:** `demandas/EPLAST-34/demanda.md`; `demandas/EPLAST-34/comentarios-do-card.md` (orientações de 2026-11-13 e a nova regra de 2026-11-15); `rodada-anterior/01-analise.md` (perguntas já levantadas, usadas como checklist, não como decisão); `contrato.md`; `assessment.md` (foto de 2026-09-30, usada só para riscos, cada fato relevante foi reconfirmado por `sf`); RAG de delivery (`[demandas/EPLAST-33/01-analise.md]` PA-12, `[demandas/EPLAST-31/rodada-anterior/01-analise.md]`, `[demandas/EPLAST-47/01-analise.md]`).

---

## 1. Contexto de negócio

A Eplast quer resumos gerados a partir do CRM para quatro reuniões: comercial, GDD, S&OP e Board. Hoje a preparação dessas reuniões é manual.

Três entregáveis já tocam o mesmo território e definem o que **não** deve ser duplicado:

- `eplast-ent-10` — "Qual o resumo completo de determinado cliente?" (contatos, negociações, pedidos, ocorrências), Onda 2, em construção fora da esteira. É o resumo **por cliente**.
- `eplast-ent-08` — consulta rápida ao CRM via assistente, concluído.
- `eplast-ent-09` — agente de acompanhamento de clientes, em homologação.

A org já tem o assistente **SFAgent2** (confirmado por `sf` hoje: 1 Bot `SFAgent2` e 4 versões de planner `SFAgent2_v1` a `SFAgent2_v4`). Pela regra 3 da conta, qualquer pedido de resumo ou linguagem natural estende o SFAgent2; não cria agente novo.

## 2. Objetivo

Entregar, para cada uma das quatro reuniões, um resumo de números e listas do CRM, gerado sob demanda do usuário, com data de corte e origem de cada número, sem gravar nada no CRM e sem disparar nenhum envio.

## 3. Escopo

**Entra**
- Um motor de agregação com quatro recortes (comercial, GDD, S&OP, Board), conforme PA-07.
- Exposição do resumo ao usuário pelo SFAgent2 (ação nova ou estendida) e, se o build indicar, por relatório ou dashboard padrão da plataforma.
- Validação em `sbx-eplast-dev` com dados sintéticos identificados.

**Não entra**
- Resumo por cliente com contatos. Isso é `eplast-ent-10` (PA-02).
- Envio de e-mail, mensagem ou campanha. Isso é do Marketing Cloud, se algum dia for pedido (regra 2 da conta).
- Gravação de campo ou objeto em Account, Opportunity ou Order.
- Meta, carteira e pedido imputado vindos do Protheus, enquanto a Eplast não indicar a fonte (PA-08).
- Agendamento, PDF, Word e geração narrativa livre por modelo (PA-03, PA-04, PA-05).

## 4. Regra de negócio

Definida parcialmente pela demanda, completada pelas premissas abaixo:

- Fonte: dados do próprio Salesforce, somente leitura, nos objetos Opportunity, Account e Order.
- Números: calculados por consulta e agregação determinística. O texto, se houver, apenas descreve números já calculados. O modelo não produz número (PA-03).
- Visibilidade: o resumo mostra somente o que o perfil do usuário já lê. Não há bypass de permissão (PA-07).
- Cada número carrega data de corte e campo de origem (CA-03).

## 5. Critérios de aceite

Testáveis, para o build e o QA. Entre parênteses, a premissa que os define.

```gherkin
# CA-01 (PA-07): acesso
Funcionalidade: Resumo respeita a permissão do usuário

  Cenário: usuário sem leitura de Opportunity não recebe dado de oportunidade
    Dado um usuário sintético de perfil sem permissão de leitura em Opportunity
    Quando ele pede o resumo do tipo "comercial"
    Então recebe mensagem de acesso insuficiente
    E nenhum nome, valor, etapa ou data de Opportunity aparece na resposta

  Cenário: usuário com leitura recebe apenas os totais do seu recorte
    Dado um usuário sintético do perfil "Comercial - Analista"
    Quando ele pede o resumo do tipo "comercial" para o mês corrente
    Então os totais conferem com o relatório padrão de Opportunity com o mesmo filtro

# CA-02 (PA-08): números
Cenário: números batem com a base sintética
  Dado 5 Opportunities sintéticas abertas, com CloseDate no mês corrente e Amount somando S
  Quando o usuário pede o resumo do tipo "comercial"
  Então o resumo mostra a contagem 5 e o total S no formato pt-BR
  E o total confere com o relatório padrão de mesmo filtro

# CA-03 (PA-06): data de corte e origem
Cenário: cada número traz data de corte e origem
  Dado qualquer resumo gerado
  Então o resumo mostra a data e hora de corte
  E, para cada número, o objeto e o campo de origem (por exemplo, "Opportunity.Amount")

# CA-04 (PA-07): conteúdo por tipo
Esquema do Cenário: cada tipo tem exatamente as seções definidas
  Dado o tipo "<tipo>"
  Quando o resumo é gerado
  Então contém exatamente as seções de "<tipo>" da tabela PA-07
  E nenhuma seção dos outros tipos

  Exemplos:
    | tipo       |
    | comercial  |
    | GDD        |
    | S&OP       |
    | Board      |

# CA-05 (PA-04): sem gravação
Cenário: gerar o resumo não grava nada no CRM
  Dado a contagem de registros e o maior LastModifiedDate de Account, Opportunity e Order antes da geração
  Quando o usuário gera o resumo de qualquer um dos quatro tipos
  Então as contagens e o LastModifiedDate não mudam

# CA-06 (regra 2 da conta, PA-04): sem envio
Cenário: gerar o resumo não envia nada
  Dado a contagem de EmailMessage antes da geração
  Quando o usuário gera o resumo
  Então a contagem não muda, nenhum Flow de e-mail é disparado e a ação não faz callout externo

# CA-07 (PA-09): dado pessoal
Cenário: o resumo não contém dado pessoal de contato
  Dado registros sintéticos com e-mail, telefone e CPF fictícios no formato válido
  Quando o resumo de qualquer tipo é gerado
  Então o texto não contém nenhum desses padrões

# CA-08 (PA-04): falha
Cenário: falha não mostra resumo incompleto e não grava nada
  Dado uma falha simulada na consulta de agregação
  Quando o usuário pede o resumo
  Então vê mensagem de erro
  E nenhum resumo parcial aparece como completo
  E nenhum registro é gravado

# CA-09 (PA-02, regra 3 da conta): sem agente novo
Cenário: a entrega não cria agente
  Dado a org antes do build com 1 Bot "SFAgent2" e 4 planners "SFAgent2_v*"
  Quando o build é concluído
  Então a org tem 1 Bot, nenhum novo bot ou planner de outro nome, e o SFAgent2 ganhou a ação ou o tópico do resumo

# CA-10 (PA-07, achado 2): Apex novo, se houver
Cenário: classe nova tem teste próprio
  Dado uma classe Apex nova criada para a agregação
  Então existe a classe "<Classe>Test" com cobertura mínima de 85% para a classe
  E nenhuma classe nova envia dados para fora da org

# CA-11 (PA-06): período
Cenário: período padrão e explícito
  Dado um pedido sem período
  Então o resumo usa o mês corrente e exibe o período
  Quando o usuário informa um período
  Então o resumo usa o período informado

# CA-12 (PA-13): dados sintéticos
Cenário: validação usa só dados sintéticos identificados
  Dado os registros usados na validação em dev
  Então todos têm a marca "TESTE-EPLAST34" no nome
  E nenhum registro real da Eplast foi copiado para a dev
```

## 6. Riscos do assessment que tocam o pedido

Reconfirmados por `sf` nesta data. O assessment é foto de 2026-09-30.

- **Achado 1, automação concorrente em Account, Opportunity e Order (alta).** Confirmado: triggers `AccountTrigger`, `AccountBefore`, `OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter` e `OrderTrigger` (duas linhas com o mesmo nome, a colisão já apontada no assessment). Por PA-04 a demanda só lê. Leitura não dispara trigger nem Flow de gravação. O CRITÉRIO CA-05 proíbe gravação, então o mapeamento de ordem de execução só vira obrigatório se o build precisar gravar. Nesse caso, volta ao arquiteto antes do build.
- **Achado 2, cobertura Apex de 10% (alta).** Relevante só se houver Apex novo. Aplicam-se CA-10 e a exigência de classe `<Classe>Test`. A cadeia Protheus (`SendAccountToProtheus`, `SendOrderToProtheus`) não entra nesta demanda, e o build não a toca.
- **Achado 4, campos sem descrição (média, relevante).** Confirmado por `sf`: 90 campos custom em Account, 28 em Opportunity e 64 em Order. O assessment falava em 223 no total, então a foto antiga não bate com a contagem atual, a diferença precisa ser conferida no recon. A demanda usa, sempre que possível, campos padrão (`Amount`, `StageName`, `CloseDate`, `OwnerId`, `TotalAmount`, `EffectiveDate`, `Status`, confirmados por `sf`), o que reduz a dependência de campo sem descrição.
- **Achado 6, alias de dev com nome "qa" (média).** Confirmado por `sf` que a org conectada é Sandbox (`IsSandbox = true`). Não é produção. A relação entre `sbx-eplast-dev` e a sandbox de QA não foi confirmada. Não é regra de negócio, então não bloqueia a análise. O recon e a esteira confirmam antes do build.
- **Visibilidade (não medido no assessment, agora medido, relevante).** OWD por `sf`: Account `ReadWrite`, Order `ReadWrite`, Opportunity `Read` (Public Read Only). Ou seja, sem permissão de objeto no perfil, o usuário lê Opportunity de todos. O critério "não expõe dado que o usuário não vê" depende da **permissão de objeto do perfil**, não de compartilhamento por registro. O CA-01 foi reescrito nesse sentido.
- **Dados de negócio (sem risco de build, relevante para validação).** Confirmado por `sf`: 0 Account, 0 Opportunity e 0 Order na dev. Os números só podem ser validados com dados sintéticos (PA-13). Nenhum volume real foi inferido.
- **Qualidade do pedido vindo do Protheus (de `contrato.md`, eplast-ent-11).** Relevante para o recorte S&OP, que depende de Order. Por PA-08, o resumo usa Order como está no CRM e não corrige nem infere dado do ERP.

## 7. Objetos e automações que a demanda provavelmente toca (a confirmar no recon)

| Item | Situação confirmada por `sf` | Papel provável |
|---|---|---|
| Bot `SFAgent2` e planners `SFAgent2_v1`–`_v4` | Existem (1 Bot, 4 planners) | Veículo de exposição do resumo (ação ou tópico novo, sem agente novo) |
| Flow `Opportunity_PromptFlow_DadosOportunidade` | Existe, ativo | Possível reuso de dado de oportunidade. Não lido, papel a confirmar no recon |
| Opportunity, Account, Order (padrão) | Campos padrão listados na seção 6 confirmados | Fonte dos números |
| Perfis `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, `Gerente de soluções`, `Gerente do contrato` | Existem | Define quem vê cada recorte (PA-07). Perfis duplicados são risco já apontado no assessment |
| Relatórios e dashboards | Nenhum com nome de resumo, reunião, GDD, S&OP ou Board. Os nomes que casam com "Board" são "Leaderboard" de amostra ou padrão | Não há painel da Eplast a reaproveitar. A conferência de números usa o relatório padrão com o mesmo filtro (CA-02) |
| Triggers em Account, Opportunity e Order | Existem (ver achado 1) | Só entram se o build gravar. Por PA-04, não gravam |

## 8. Premissas assumidas (validar na homologação)

Cada item abaixo foi decidido pela ordem da regra 4 (org, depois padrão). Todos ficam como resolvidos e configuráveis.

- [x] **PA-01 · Escopo.** *Pergunta:* a Onda 3 não contratada entra? *Decisão:* entra, com análise, design e build. *Evidência:* diretriz do responsável da conta em 2026-11-13 (`comentarios-do-card.md`) e regra 1. *Como mudar:* não se aplica. Se a Eplast contratar a Onda 3 depois, nada muda aqui.

- [x] **PA-02 · Sobreposição com `eplast-ent-10`, `eplast-ent-08` e SFAgent2.** *Pergunta:* é extensão, entregável separado ou já coberto? *Decisão:* o resumo por cliente é do `eplast-ent-10` e não é duplicado. A demanda cobre os três recortes gerenciais (GDD, S&OP, Board) e o comercial agregado por equipe. Tudo é exposto pelo SFAgent2 existente, sem agente novo. *Evidência:* `sf` confirma 1 Bot e 4 planners SFAgent2; `contrato.md` lista `eplast-ent-10` em construção; regra 3 da conta. *Como mudar:* se o `eplast-ent-10` for descontinuado, o recorte por cliente pode ser absorvido aqui, sem mudar o restante.

- [x] **PA-03 · Geração determinística ou por modelo.** *Pergunta:* o resumo é texto por IA generativa, painel ou combinação? *Decisão:* números por agregação determinística. Texto opcional de apoio gerado pelo SFAgent2 a partir desses números, sem produzir número. *Evidência:* SFAgent2 já ativo em dev e QA (`sf`), o que dá caminho licenciado para texto; regra de integridade (número errado em Board é caro de corrigir). *Como mudar:* a Eplast pode pedir mais texto narrativo; isso é ajuste de prompt no SFAgent2, dentro do que já está licenciado (PA-10).

- [x] **PA-04 · Saída e canal.** *Pergunta:* documento, e-mail, slide, tela ou campo? *Decisão:* resposta do SFAgent2 na tela e, se o build indicar, relatório ou dashboard padrão. Sem gravação em Account, Opportunity ou Order e sem envio. *Evidência:* achado 1 do assessment (gravar em registro reabre a automação concorrente); regra 2 da conta (envio é do Marketing Cloud). *Como mudar:* PDF, exportação ou envio por Marketing Cloud são passos posteriores e exigem reavaliação do achado 1 se houver gravação.

- [x] **PA-05 · Gatilho.** *Pergunta:* sob demanda, agendado ou por evento? *Decisão:* sob demanda, pedido do usuário. *Evidência:* padrão do squad (mais simples e reversível). Sem `Schedulable` nesta demanda. *Como mudar:* agendamento vira demanda própria, com achado 1 reavaliado.

- [x] **PA-06 · Janela e data de corte.** *Pergunta:* qual período e até que hora? *Decisão:* padrão mês corrente, com possibilidade de informar outro período. Data de corte é o momento da geração. *Evidência:* convenção de filtro de data dos relatórios padrão da plataforma. *Como mudar:* parâmetro de configuração, sem mudar a arquitetura.

- [x] **PA-07 · Público e conteúdo de cada tipo.** *Pergunta:* quem recebe cada reunião e com que conteúdo? *Decisão:* um motor, quatro recortes (P5 da rodada anterior: uma demanda, não quatro). Tabela inicial, a validar com a Eplast:
  - **Comercial:** por equipe ou vendedor. Oportunidades abertas com `Amount`, `StageName` e `CloseDate` no período, totais por etapa.
  - **GDD:** por conta. Oportunidades abertas e pedidos (`Order.TotalAmount`, `Status`) no período, por conta.
  - **S&OP:** pedidos (`Order`) por status e data de efetivação (`EffectiveDate`) no período, totais.
  - **Board:** consolidado por equipe, sem detalhe de conta, com os mesmos totais dos outros recortes.
  Acesso: o usuário só vê o que o perfil lê. OWD: Opportunity é Public Read Only, então o controle real é a permissão de objeto do perfil. Board consolidado exige perfil com leitura de Opportunity e Order. *Evidência:* OWD e perfis confirmados por `sf` (seção 6 e 7). *Como mudar:* a Eplast redefine seções e quem vê cada uma. Isso é configuração de perfil e de recorte, não de arquitetura.

- [x] **PA-08 · Fontes e métricas.** *Pergunta:* quais objetos, campos e fórmulas? Meta, carteira e pedido imputado vêm de onde? *Decisão:* só dados do próprio Salesforce, com os campos padrão da seção 7. Meta, carteira e pedido imputado não entram, porque a org não tem campo com esses nomes (busca por nome em Account, Opportunity e Order, `sf`, 2026-11-15) e não se inventa fonte. Números usam a mesma definição de `Amount`, `StageName` e `CloseDate` que o padrão da plataforma, para não criar uma terceira régua. *Evidência:* busca por nome em `sf`; `[demandas/EPLAST-33/01-analise.md]` PA-12, que já prevê régua única com a sobreposição; achado 4. *Como mudar:* se a Eplast indicar onde vive a meta, ela entra como campo a mapear no recon. Isso amplia o escopo, não desbloqueia nada.

- [x] **PA-09 · Dado pessoal.** *Pergunta:* o resumo pode trazer contatos? *Decisão:* não. O resumo traz nomes de conta, valores, etapas, datas e status. Nenhum nome, e-mail, telefone ou CPF de contato. *Evidência:* guardrail 2 do squad (LGPD) e a finalidade da reunião, que não precisa de contato. *Como mudar:* se a Eplast quiser contato num recorte, a decisão segue o que for decidido no `eplast-ent-10`, com validação do DPO da Eplast sobre o texto gerado.

- [x] **PA-10 · Licenças e créditos de IA.** *Pergunta:* quem paga o consumo? *Decisão:* nenhuma geração além do que já está ativo no SFAgent2, e o consumo adicional não é assumido. A análise não resolve custo comercial. *Evidência:* SFAgent2 já presente em dev e QA (`sf`); assessment mediu licença só na sandbox. *Como mudar:* se o consumo exceder o previsto, vira decisão comercial separada, fora da análise. Com PA-03, o consumo previsto é baixo.

- [x] **PA-11 · Aprovação do conteúdo.** *Pergunta:* o resumo circula sem revisão? *Decisão:* sem revisão humana antes de circular. O resumo mostra data de corte e origem (CA-03), e o usuário que o consome responde pelo número. *Evidência:* padrão de relatório consumido direto na plataforma. *Como mudar:* se o Board exigir revisão, adiciona-se etapa de aprovação no design.

- [x] **PA-12 · Idioma, formato e template.** *Pergunta:* há template padrão da Eplast? *Decisão:* português (pt-BR), seções fixas por tipo como na PA-07, sem template próprio. *Evidência:* nenhum template da Eplast existe no workspace. *Como mudar:* o template da Eplast substitui as seções da PA-07.

- [x] **PA-13 · Dados de teste.** *Pergunta:* como validar sem dado real? *Decisão:* o builder cria dados sintéticos identificados com `TESTE-EPLAST34` em `sbx-eplast-dev`. Nenhum dado real entra na sessão. *Evidência:* `sf` confirma 0 Account, 0 Opportunity e 0 Order na dev; guardrail 2. *Como mudar:* se a Eplast liberar uma extração anonimizada, o QA pode usá-la na sandbox de QA, com nova análise de LGPD.

- [x] **PA-14 · Documento de origem.** *Pergunta:* a Solicitação de Proposta pode ser anexada? *Decisão:* a análise segue sem ela, porque a demanda e o `contrato.md` cobrem o escopo. Se o consultor quiser conferir o texto, anexa ao card com liberação de dado pessoal. *Evidência:* documento não está no workspace. *Como mudar:* a anexação é opcional; se trouxer requisito novo, a análise é refeita.

- [x] **PA-15 · Tipos de reunião e seus donos.** *Pergunta:* o que é GDD, S&OP e Board e quem consome? *Decisão:* a análise usa a definição da seção PA-07 como ponto de partida, sem mudar a estrutura se a Eplast ajustar o conteúdo. *Evidência:* a demanda não explica as siglas; a tabela de PA-07 é o padrão de partida. *Como mudar:* a Eplast valida a tabela na homologação.

## 9. O que a demanda não diz e como foi resolvido

| # (rodada anterior) | Tema | Resolvido por | Onde |
|---|---|---|---|
| 1 | Escopo comercial | Diretriz da conta, regra 1 | PA-01 |
| 2 | Sobreposição com ent-10 e ent-08 | Org (SFAgent2) e contrato | PA-02 |
| 3 | Números batendo com EPLAST-26, 32, 33 | Régua única da plataforma, sem métrica nova | PA-08 |
| 4 | Por modelo ou determinístico | Org (SFAgent2 ativo) e integridade | PA-03 |
| 5 | Formato e canal | Padrão, sem gravação (achado 1) | PA-04 |
| 6 | Público e conteúdo | OWD e perfis confirmados por `sf` | PA-07 |
| 7 | Fontes e métricas | Org (campos padrão, sem campo de meta) | PA-08 |
| 8 | Gatilho | Padrão, mais simples e reversível | PA-05 |
| 9 | Janela de dados | Padrão de filtro de data | PA-06 |
| 10 | LGPD | Guardrail 2 e finalidade da reunião | PA-09 |
| 11 | Aprovação | Padrão | PA-11 |
| 12 | Idioma, tamanho e template | Padrão, sem template na Eplast | PA-12 |
| 13 | Licenças e créditos | Org (SFAgent2 já ativo), consumo baixo | PA-10 |
| 14 | Dados de teste | Org (dev vazia) e guardrail 2 | PA-13 |
| 15 | Documento de origem | Opcional | PA-14 |
| 16 | Dev e QA | Infraestrutura, não negócio. Registrado no achado 6 | seção 6 |

Não há pergunta de negócio que caia no caso 3 (nem a org nem o padrão indicam caminho, e errar seria caro). Por isso não há pendência `- [ ]`.

## 10. Complexidade

**M.** Quatro recortes sobre um motor, com visibilidade por perfil e uma extensão do SFAgent2. Não há gravação nem envio. Sobe para G se o build precisar de Apex de envio, de gravação em registro ou de fonte nova (meta, Protheus).

## 11. Estimativa de esforço humano

**Estimativa de esforço:** 40–72 h

Premissas que mais pesam na faixa:
- **Quatro recortes sobre um motor (PA-07):** a faixa sobe se cada tipo tiver conteúdo próprio validado com o público.
- **Extensão do SFAgent2 em vez de agente novo (PA-02):** reduz horas de configuração, mas exige teste de regressão nos três tópicos e ações já existentes.
- **Validação de visibilidade por perfil (CA-01, OWD Public Read Only):** cada perfil de teste precisa ser criado e conferido, o que pesa mais se houver muitos perfis comerciais.
- **Dados sintéticos sem volume (PA-13):** os números são conferidos com poucas oportunidades, mas o teste de consistência com relatório padrão consome tempo de consultor.
- **Homologação com quatro públicos:** cada um precisa validar seu recorte, o que é tempo do cliente e não só execução técnica.
- **Apex novo (CA-10):** se for necessário, soma testes de 85% por classe e pode levar a faixa para o topo.

Faixa larga porque a demanda é uma linha e as seções por reunião ainda serão validadas na homologação. Não inclui horas de agente nem o tempo de espera do cliente. O arquiteto refina no design.

## 12. Próximo passo

Acionar o recon (`org-recon`) com foco em: (1) confirmar o papel do Flow `Opportunity_PromptFlow_DadosOportunidade` e das ações do SFAgent2; (2) confirmar os perfis que leem Opportunity e Order; (3) conferir os 182 campos custom dos três objetos contra o achado 4.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
