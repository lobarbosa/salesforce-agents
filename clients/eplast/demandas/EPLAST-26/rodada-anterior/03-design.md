# EPLAST-26 — Design da solução: Scoring de leads e oportunidades

**Cliente:** Eplast · **Tipo:** projeto · **Org do recon:** `sbx-eplast-dev` (ver `02-recon.md`, coleta de 2026-11-10)
**Estado do design:** **parcial, com decisão condicionada.** O que dá para decidir sem resposta do cliente
está decidido abaixo. O mecanismo (P1), a saída de dados (P2), o escopo de objetos (P7) e a contratação da
Onda 3 (P12) continuam em aberto. Eles **não** foram respondidos por mim.

Fontes: `01-analise.md` (aprovada em 2026-11-10), `02-recon.md`, `assessment.md` (2026-09-30), `contrato.md`,
histórico RAG (`[demandas/EPLAST-39/03-design.md]`, mesmo diagnóstico de Lead e Opportunity).

---

## 1. Resumo executivo

1. **Decidido e válido para qualquer mecanismo:** o cálculo do score **não pode gerar DML em Opportunity**. O
   recon mostrou que qualquer update em Opportunity aciona o CPQ, 16 validation rules (7 delas testam a
   Account em todo save), um Flow sem critério de entrada que reescreve o próprio registro e atualiza a
   Account, e um Queueable que faz **callout ao Protheus por Account**. Um job que "só grava o score" em lote
   chamaria o ERP uma vez por Account e falharia nas oportunidades com Account incompleta.
2. **Recomendado (Fase 1), condicionado a P1 = regras (a) ou combinação (c):** score por **campo fórmula** em
   Lead e em Opportunity. É o primeiro nível da doutrina, configuração. Calcula na leitura, não gera DML,
   não aciona automação, não precisa de Apex e não depende da cobertura de 11% da org. Priorização por list
   view e relatório ordenados pelo score.
3. **Não decidido, depende do cliente:** modelo preditivo nativo (Einstein) ou serviço externo. O desenho de
   cada opção, o que muda e o que bloqueia estão na seção 4. Se o score precisar ser **gravado** (e não
   calculado na leitura), a opção que respeita o item 1 é um **objeto novo**. Isso é mudança de modelo de
   dados e **está escalado ao arquiteto humano** (seção 7).
4. **O build não pode começar** mesmo com este gate aprovado, enquanto três condições externas ao design
   estiverem abertas: Onda 3 não contratada (P12), alias dev/qa (P14) e aprovação da estimativa pelo cliente
   (regra do Squad OS).

## 2. Decisão de abordagem

### 2.1 O que o recon mudou em relação à análise

| Hipótese da análise | O que a org mostrou |
|---|---|
| Gravar score em Opportunity "dispara esses automatismos" | Pior que isso. `OpportunityTrigger` enfileira `OpportunityTriggerHelper` em **todo** insert/update, e esse Queueable faz callout ao Protheus por Account. `OpportunityFlow` não tem critério de entrada, reescreve o `$Record` (novo ciclo de save, segundo enfileiramento possível) e atualiza Account, o que dispara mais 4 automações |
| Validation rules de Opportunity não foram levantadas | 16 ativas. 7 testam campos da Account em todo save, sem `ISCHANGED`. Update em segundo plano falha em oportunidade com Account incompleta |
| Lead não coberto pelo assessment | Lead não tem trigger, Flow nem Apex que o referencie. Só 2 validation rules de formato de telefone. É um objeto de baixo risco para escrever |
| Mecanismo nativo depende de licença | Sem permission set license de "Sales Cloud Einstein" na sandbox. Há indícios de tentativa anterior: perfil `Sales Insights Integration User` com usuário ativo e campo `Opportunity.Previs_o_Eintein__c` sem descrição nem dependência. Licença de sandbox não é a de produção |
| Sandbox vazia | Confirmado: 0 Lead, 0 Opportunity. Nenhum modelo pode ser treinado ou validado aqui |

### 2.2 Ordem de preferência aplicada à Fase 1 (opção de regras)

| Nível | Serve? | Por quê |
|---|---|---|
| **1. Configuração: campo fórmula** | **Sim, escolhido** | Calcula na leitura: zero DML, zero trigger, zero Flow, zero callout ao Protheus, zero validation rule. Pode usar campos do próprio registro, campos do pai (`Account.Ranking__c`, `Account.Risk__c`, `Account.Overdue__c`, por exemplo) e campos padrão de atividade como `LastActivityDate`. É somente leitura por natureza, o que atende o cenário de permissão da análise sem regra adicional. List view e relatório ordenam por fórmula |
| 2. Declarativo: Flow (record-triggered ou agendado) gravando o score | Não | Em Opportunity, gravar é exatamente o que o item 1 do resumo proíbe. Um Flow agendado em lote aciona o callout ao Protheus por Account e falha nas oportunidades com Account incompleta. Mais um Flow after-save no objeto também piora o achado 1 do assessment. Em Lead funcionaria (não há automação), mas levaria a dois mecanismos diferentes para a mesma regra sem ganho sobre a fórmula |
| 3. Código: Apex (batch, trigger, LWC) | Não | Herda o mesmo problema de DML em Opportunity e soma classe nova numa org com 11% de cobertura e `OpportunityTrigger` com 0/8 linhas cobertas. Nada na regra de pontuação por pesos exige rollback, callout ou controle de recursão |

**Quando a fórmula deixa de servir. Cada item abaixo leva o design de volta ao gate:**
- Entrada que é contagem ou agregação de filhos (número de Tasks, engajamento do Marketing Cloud,
  histórico de estágio). Fórmula não agrega filhos, e roll-up summary não existe para Task nem para lookup.
  Isso exigiria campo gravado, ou seja, DML (P3).
- Regra que precisa de peso editável pelo negócio sem deploy (P9). Mitigação possível sem descer de nível:
  ler pesos de Custom Metadata (`$CustomMetadata`) dentro da fórmula. Confirmar o suporte no build antes de
  prometer. Isso cria um tipo de metadata novo e entra na escalada da seção 7.
- Limite de tamanho compilado da fórmula estourado pela regra final. Medir no build. Se estourar, dividir em
  fórmulas parciais (por exemplo, fit e engajamento) e somar.
- Histórico do score ("data do último cálculo", evolução no tempo). Fórmula não guarda passado (ver ajuste de
  critério de aceite na seção 9).

## 3. Componentes (Fase 1, opção de regras)

Prefixo de campo da Eplast não está definido no `CLAUDE.md` do cliente. Segui o padrão dos campos mais
recentes da org (`NomeTipoRegistro__c`, `DescricaoPerda__c`: português, CamelCase, sem prefixo) e o padrão do
permission set já existente do piloto (`PS_Comercial_ResumoClienteAgente`). **Nenhum dos API names a criar
existe hoje** (confirmado por `sf sobject describe` e pela consulta de `PermissionSet`).

### Criar
| API name | Tipo | Observação |
|---|---|---|
| `Lead.ScoreConversao__c` | Fórmula (Number, 0 casas) | Escala e pesos definidos com o cliente (P1, P3, P13). `Description` obrigatória, listando os campos de entrada e o significado de cada um |
| `Lead.PrioridadeConversao__c` | Fórmula (Text) | Faixa derivada do score (ex.: Alta/Média/Baixa/"Sem dados suficientes"). Valores e cortes vêm do cliente (P1) |
| `Opportunity.ScoreConversao__c` | Fórmula (Number, 0 casas) | Mesma lógica, com entradas de Opportunity e da Account pai |
| `Opportunity.PrioridadeConversao__c` | Fórmula (Text) | Faixa |
| `PS_Comercial_ScoreConversao` | Permission Set | Leitura (FLS read) nos 4 campos. Sem permissão de objeto nova. `Description` preenchida |
| List view `Lead.Leads_PorPrioridade` | ListView | Ordenada por `ScoreConversao__c` desc. **Condicionada a P4/P5** |
| List view `Opportunity.Oportunidades_PorPrioridade` | ListView | Idem, filtrando `IsClosed = false` |

### Alterar
| Componente (existente, confirmado) | Alteração |
|---|---|
| `Lead-Lead Layout` | Incluir os 2 campos, somente leitura |
| `Opportunity-Opportunity Layout` e `Opportunity-CPQ Opportunity Layout` | Incluir os 2 campos, somente leitura |
| `Lead_Record_Page` / `Lead_Record_Page_Three_Column`, `Opportunity_Record_Page` / `Opportunity_Record_Page_Three_Column` | Só se a página ativa usar seção de campos própria e não o layout. Confirmar a atribuição no build (P4) |

### Depreciar
Nada. O campo `Opportunity.Previs_o_Eintein__c` **não** será reaproveitado nem removido sem resposta do
cliente (P15, seção 8).

### Notas de construção
- **Desempate (P5):** list view ordena por uma coluna só. Se o cliente quiser critério de desempate, ele tem
  que estar dentro da fórmula, como componente fracionário do score (por exemplo, recência de
  `LastActivityDate` ou `CreatedDate`).
- **"Sem dados suficientes":** a fórmula testa os campos mínimos com `ISBLANK` antes de pontuar e devolve
  vazio ou a faixa própria. Nunca devolve zero, que confundiria com um score baixo de verdade (cenário 2 da
  análise).
- **Fórmula com `TODAY()`** (para recência) é recalculada a cada leitura. Funciona em list view e relatório,
  mas não serve para disparar automação. Nada nesta demanda dispara a partir do score.

## 4. Alternativas de mecanismo (P1/P2). Não decididas

| | (a) Regras por fórmula (**Fase 1 deste design**) | (b) Modelo preditivo nativo (Einstein Lead/Opportunity Scoring) | (c) Serviço externo (modelo próprio ou de terceiro) |
|---|---|---|---|
| Nível da doutrina | Configuração | Configuração (ativação de recurso) | Código (callout, Named Credential, Apex) |
| Licença | Nenhuma | **Não confirmada.** Sem permission set license "Sales Cloud Einstein" na sandbox. Depende do resultado de `eplast-ent-04` e de produção | Do provedor |
| Dado sai da Salesforce? | Não | Fica na plataforma (confirmar com `eplast-ent-04` e com o Trust da Salesforce) | **Sim**: novo processador de dado pessoal. P2 bloqueante (LGPD) |
| Precisa de histórico | Não | Sim, volume mínimo de histórico em **produção**. Sandbox vazia, não dá para validar aqui. Histórico de campo de Opportunity está desligado | Sim, e extração de histórico, que precisa de base legal |
| Onde o score fica | Fórmula no registro | Na estrutura do recurso nativo. **Confirmar se ele grava no registro de Opportunity.** Se gravar, o item 1 do resumo volta a valer e precisa de teste de regressão com CPQ e Protheus | Precisa ser gravado de volta. Em Opportunity cai no item 1. A alternativa é **objeto novo** (`ScoreConversao__c` filho de Lead/Opportunity), que é **mudança de modelo de dados, escalada** |
| Explicabilidade (P9) | Total: a regra está na `Description` e na fórmula | Fatores do próprio recurso | Depende do provedor |
| Esforço (consultor + dev) | 24–56 h (seção 10) | 30–70 h, se a licença existir, mais a espera pelo treino em produção | 90–180 h, mais a decisão de modelo de dados e de LGPD |
| O que bloqueia hoje | P3, P13 (regra), P12, P14 | `eplast-ent-04`, P10, P12, P14 | P2, decisão de modelo de dados, P12, P14 |

**Por que a Fase 1 é recomendada mesmo se o cliente quiser IA:** ela não descarta (b) nem (c). Um score por
regras serve de **baseline mensurável** para provar se o modelo preditivo traz ganho (P10). É a única opção
que dá para entregar e validar sem histórico, numa sandbox vazia e sem depender de licença que ninguém
confirmou. Se P1 for (b) ou (c) puro, este design volta ao gate com a seção 3 trocada, e a análise de
automação concorrente (seção 5) continua valendo.

## 5. Conflito de automação e limites

### Opportunity: risco de ordem de execução

**Existe automação concorrente no mesmo objeto e evento: `SBQQ.OpportunityBefore`, `SBQQ.OpportunityAfter`,
`OpportunityTrigger` (after insert/update) e os Flows after-save `OpportunityFlow` (sem critério de entrada,
sem `triggerOrder`) e `Oportunidade_Industria` (sem `triggerOrder`). A ordem entre os dois after triggers e
entre os dois Flows não é garantida. `OpportunityFlow` reescreve o próprio registro, o que gera novo ciclo de
save e pode enfileirar um segundo Queueable com callout ao Protheus.** A ordem estática está detalhada em
`02-recon.md`, seção 3.

**Como a Fase 1 lida com isso:** ela não adiciona nenhum ponto de automação e não gera nenhum DML em
Opportunity. Criar campo fórmula, layout, list view e permission set não aciona trigger nem Flow. O valor da
fórmula muda na leitura, sem evento de save. Por isso **a ordem de execução não é dependência da solução**. O
cenário de regressão da análise continua obrigatório para provar isso (seção 9).

**O que este design não resolve:** a consolidação da automação de Opportunity em um ponto de entrada único,
recomendada pelo assessment, é remediação (PA-7) e fica fora. Foi registrada como risco para as demandas
irmãs que **vão** escrever em Opportunity (EPLAST-28, -30).

### Lead
Sem trigger, sem Flow, sem Apex. A fórmula também não gera DML. Nenhum conflito.

### Governador e CPU
| Cenário | Fase 1 (fórmula) | Se o score for gravado em Opportunity (rejeitado) |
|---|---|---|
| Carga em massa (200 oportunidades num save) | Custo zero no save. Fórmula não consome SOQL, DML nem CPU de transação de escrita | Por chunk de 200: CPQ, 16 validation rules, `OpportunityFlow` com 2 lookups (oportunidades do ano por Account) e update de Account (mais 4 automações de Account), mais o enfileiramento de Queueable com callout por Account |
| Um pai com muitos filhos (uma Account com muitas oportunidades) | Não se aplica: a fórmula de Opportunity lê a Account, e a Account não é recalculada | `OpportunityFlow` já atualiza a Account a cada save de oportunidade. Recalcular N oportunidades da mesma Account geraria N updates em Account em cascata. É o padrão do achado SOMOSAGILITY-10 |
| Leitura (list view, relatório) | Fórmula cross-object é calculada na consulta. Medir em QA o tempo de list view com volume realista, que depende de dado cedido pelo cliente (P10) | n/a |

Critério de volta ao design: se a fórmula final precisar de mais relações cross-object do que o limite da
plataforma, ou se o tamanho compilado passar de ~70% do limite, a regra volta para revisão antes do build.

## 6. Impacto em permissões e compartilhamento
- **Perfis:** nenhum perfil é alterado. Isso segue o achado 8 do assessment (4 variações de perfil comercial);
  a permissão vai por permission set.
- **`PS_Comercial_ScoreConversao`:** FLS de leitura nos 4 campos. Atribuição a quem o cliente definir em P9.
  Na sandbox, os candidatos seriam os 4 usuários ativos de `Comercial - Analista` e os administradores. A
  atribuição é passo manual pós-deploy, documentado na entrega.
- **Edição:** fórmula é somente leitura para qualquer perfil. O cenário "não consegue editar" fica atendido
  por construção.
- **Visibilidade de registro (OWD medido na sandbox):** Lead `ReadEditTransfer` e Opportunity `Read` (público).
  Quem tiver o permission set vê o score de **todas** as oportunidades e leads, não só os seus. Se o cliente
  quiser restringir (P9), isso é decisão de compartilhamento, fora desta demanda. Confirmar se produção tem os
  mesmos OWDs.

## 7. Escalada ao arquiteto humano: modelo de dados

- **Fase 1 (fórmulas):** campos novos, aditivos, somente leitura, sem armazenamento de dado e sem relação
  nova. Entendo que **não** é mudança de modelo de dados no sentido que exige decisão sênior, mas **peço
  confirmação explícita no gate**.
- **Escalado e não decidido por mim:** se o cliente escolher (b) com gravação no registro, (c), ou exigir
  entrada agregada ou histórico do score, a única forma de gravar sem acionar a automação de Opportunity é um
  **objeto custom novo** (score por registro, filho de Lead/Opportunity), ou então consolidar a automação de
  Opportunity antes. As duas coisas são decisão de arquitetura sênior. Um Custom Metadata Type para pesos
  editáveis também entra aqui.

## 8. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Automação concorrente em Opportunity** (CPQ, trigger custom, 2 Flows sem `triggerOrder`, Flow sem critério de entrada reescrevendo o registro) | **Alta** | Fase 1 não escreve em Opportunity. Regressão obrigatória em QA com debug log. Qualquer variante que grave em Opportunity volta ao gate |
| R2 | **Callout ao Protheus a cada update de Opportunity** (`OpportunityTriggerHelper`) | **Alta** | Mesmo tratamento do R1. Registrado para as demandas irmãs |
| R3 | 7 validation rules de Opportunity testam a Account em todo save | Alta (para qualquer escrita) / nula (Fase 1) | Fase 1 não escreve. Se alguma variante escrever, ela precisa tratar falha parcial |
| R4 | Mecanismo indefinido (P1). O cliente pode querer IA e a Fase 1 ser vista como insuficiente | Alta (escopo) | Seção 4. Fase 1 apresentada como baseline, não como resposta final de "IA" |
| R5 | Onda 3 não contratada, contrato termina em 2026-11-30 (P12) | Alta (comercial) | Build bloqueado até contratação, independente deste gate |
| R6 | Alias `sbx-eplast-dev` aponta para instância com nome de qa, e não há `sbx-eplast-qa` autenticada (P14) | Média, **bloqueante para o build** | Confirmar antes do build. Sem isso, build e homologação podem cair na mesma sandbox |
| R7 | Campos de entrada sem `Description` (Lead 12/12, Opportunity 19/28) e significado desconhecido | Média | Workshop com o comercial para validar cada campo de entrada antes de escrever a fórmula. A `Description` dos campos novos documenta a regra |
| R8 | Sandbox vazia: sem dado para validar qualidade do score nem desempenho de list view | Média | Validação de qualidade com amostra agregada ou anonimizada cedida pelo cliente (PA-5/P10). Sem ela, o aceite de qualidade vira risco aceito pelo cliente |
| R9 | Picklists não restritas (`StageName`, `LeadSource`, `Status`, `Rating`): a fórmula que compara valor pode errar com valor solto vindo de integração | Média | Fórmula compara contra a lista confirmada no recon, com ramo "outro". Pedir ao cliente os valores realmente em uso em produção (contagem agregada feita por eles) |
| R10 | Sobreposição com campos existentes: `Lead.Rating` (AA–D), `Opportunity.Previs_o_Eintein__c`, `Account.Ranking__c` | Baixa | P15/P16 abaixo. Não reaproveitar sem confirmação |
| R11 | Limite de tamanho compilado da fórmula | Baixa | Medir no build. Dividir em fórmulas parciais se necessário |
| R12 | Cobertura Apex de 11% e `OpportunityTrigger` com 0% | Alta na org / não se aplica à Fase 1 | Fase 1 não tem Apex. Pela regra da plataforma, deploy sem Apex não exige execução de testes (confirmar com `release`). Não corrige a dívida |

### Riscos do assessment que tocam esta demanda: como o design lida
| Achado | Tratamento |
|---|---|
| 1. Automação concorrente (Opportunity) | Evitado por construção na Fase 1 (sem DML, sem novo ponto de automação). Ordem estática documentada no recon. Ordem empírica fica para o QA. Consolidação fora (PA-7) |
| 1. Automação concorrente (Account) | Não se aplica: a fórmula **lê** campos da Account e não grava nela |
| 1. Automação concorrente (Order) | Não se aplica: Order fora do escopo (PA-1) |
| 2. Cobertura de 10% (hoje 11%) | Não se aplica à Fase 1 (sem Apex). Se (c) for escolhido, toda classe nova nasce com `<Classe>Test` e 85%. O deploy em produção de pacote com Apex esbarraria nos 75% org-wide. Isso é risco de release, não do design |
| 2. Cadeia Protheus sem teste | Não tocada. Atenção: a cadeia é acionada indiretamente por qualquer escrita em Opportunity (R2) |
| 4. Campos sem descrição | Campos novos com `Description`. Campos de entrada validados com o cliente (R7). Descrever campos existentes fica fora, salvo pedido |
| 6. Dev/qa | Reconfirmado (`02-recon.md` §0). Bloqueante para o build |
| 8. Perfis comerciais duplicados | Permissão por permission set, nenhum perfil tocado |
| 9. API version antiga | Não se aplica: nenhuma classe existente é editada |
| Não medido: OWD | Medido na sandbox (seção 6) |
| Sandbox vazia | Confirmado. Ver R8 |

## 9. Ajustes propostos aos critérios de aceite (para o consultor levar ao cliente)
- **Cenário 1** ("a data do último cálculo é preenchida"): na Fase 1 a fórmula é sempre atual e não existe
  "último cálculo". Proposta: retirar esse passo, ou aceitar que histórico do score exige gravação (seção 7).
- **Cenário 3** ("recalculado até o prazo P6"): na Fase 1 o recálculo é imediato, na leitura. P6 deixa de
  bloquear.
- **Cenário de regressão (obrigatório):** passa a incluir verificar no debug log, em QA, que salvar Lead e
  Opportunity depois do deploy aciona exatamente as mesmas automações de antes. Para Opportunity: CPQ,
  `OpportunityTrigger`, `OpportunityFlow` e `Oportunidade_Industria`. Também incluir verificar que a leitura
  do score não aciona nada.
- **Cenário de dado fora da Salesforce:** não se aplica à Fase 1. Volta se P1 = (c).

### Perguntas novas que o recon gerou
- **P15.** `Opportunity.Previs_o_Eintein__c` (criado em 2024-10, sem descrição, sem uso no metadata) e o perfil
  `Sales Insights Integration User` ativo: o Einstein de vendas já foi ativado em produção? O campo é
  preenchido? Pode ser depreciado?
- **P16.** `Lead.Rating` (AA–D) é usado hoje? A faixa de prioridade deve substituí-lo, conviver com ele ou
  seguir a mesma escala?
- **P17.** `Account.Ranking__c`, `Account.Risk__c`, `Account.Overdue__c` são confiáveis para entrar no score de
  Opportunity?
- **P13 (refinada com valores reais):** conversão de Lead = `Status = 'Fechado - Convertido'` (ou
  `IsConverted`)? Conversão de Opportunity = `StageName = 'Fechado/Ganho'`?

## 10. O que NÃO será feito nesta demanda
- Nenhum Apex, trigger, Flow ou LWC novo. Nenhuma alteração em `OpportunityTrigger`, `OpportunityFlow`,
  `Oportunidade_Industria` ou nos triggers do CPQ.
- Consolidação da automação de Opportunity, testes da cadeia Protheus e aumento da cobertura org-wide
  (remediação do assessment, PA-7).
- Ativação de Einstein Lead/Opportunity Scoring, Data Cloud ou Agentforce para score. Integração com serviço
  externo de IA (PA-2).
- Gravação de score, histórico de score ou objeto novo (escalado, seção 7).
- Account e Order (PA-1). Envio de score ao Protheus (PA-3).
- Alteração de perfis ou de OWD. Atribuição de permission set a usuários reais de produção.
- Curadoria de `Description` de campos existentes.
- Escopo de EPLAST-28, -30 e -39 (P11), além do registro de risco para as irmãs que escrevem em Opportunity.
- Deploy em produção (guardrail #1).

## 11. Estimativa de esforço

**Estimativa de esforço:** 24–56 h

Vale para a **Fase 1 (regras por fórmula em Lead e Opportunity)**, o único caminho que está desenhado neste
documento. Composição (consultor + dev):
- Workshop de regra com o comercial: campos de entrada, pesos, faixas, definição de conversão (P3, P13, P16,
  P17). 6–12 h.
- Build: 4 fórmulas, permission set, 3 layouts, até 2 list views, páginas Lightning se necessário. 6–12 h.
- QA: funcional, permissão, regressão de Opportunity e Lead com debug log. 6–12 h.
- Validação de qualidade com amostra do cliente (P10). 0–12 h. Fica no 0 se o cliente aceitar o risco
  (PA-5).
- Homologação e documentação de entrega. 6–8 h.

**O que mudou em relação à análise (40–120 h):** o teto caiu porque o recon mostrou que a Fase 1 dispensa
Apex e não toca na automação de Opportunity. Saem a cobertura construída do zero e a remediação de triggers,
que puxavam a faixa para cima. O piso caiu porque não há integração nem preparação de modelo. **Se P1 for (b)
ou (c), esta estimativa não vale:** o design volta ao gate com a faixa da seção 4 (30–70 h ou 90–180 h), e no
caso (c) somam-se a decisão de modelo de dados e a avaliação de LGPD.

---

## Bloqueios em aberto (resumo para o gate)
| Bloqueio | Impede | Dono |
|---|---|---|
| P1: mecanismo (regras vs. preditivo vs. externo) | Confirmar que a Fase 1 é o que o cliente quer | Cliente, via consultor |
| P2: dado saindo da Salesforce | Opção (c) | Cliente e responsável LGPD da Eplast |
| P7: escopo de objetos | Incluir Account ou Order (hoje fora) | Cliente |
| P12: Onda 3 não contratada | **Qualquer build** | Comercial Konecta e Eplast |
| P14: alias dev/qa | **Qualquer build** | Delivery e BASIS do cliente |
| Aprovação da estimativa pelo cliente | Liberação do build (regra do Squad OS) | Cliente |
| Confirmação de que fórmula não é mudança de modelo de dados (seção 7) | Este gate | Arquiteto humano |
