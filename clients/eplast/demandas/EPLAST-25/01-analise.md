# EPLAST-25 — Medição do piloto de IA contra o baseline (até 10 usuários)

**Cliente:** Eplast · **Tipo:** projeto · **Entregável contratado:** `eplast-ent-12` (peso 1, Onda 2, semana 9)
**Origem:** roteiro de IA no Salesforce Sales e Marketing (Konecta).
**Status:** análise refeita na rodada 2 (2026-11-15), pela regra 4 da conta (pergunta de negócio sem resposta não trava; decide-se pela org, depois pelo padrão, e registra-se como premissa).
**Org confirmada:** `sbx-eplast-dev` (Org Id 00DHa000006vfMLMAY), conectada nesta sessão via `sf org list`. Produção não foi acessada.

Fontes usadas:
- `demandas/EPLAST-25/demanda.md` (história do consultor, 5 linhas) e `comentarios-do-card.md` (orientações do Leonardo de 2026-11-13 e a decisão de refazer pela regra 4 em 2026-11-15).
- `contrato.md` (linhas dos entregáveis `eplast-ent-06` a `eplast-ent-12`).
- `assessment.md` (em `clients/eplast/`, não na raiz): lido por trecho e pelo resumo do prompt.
- `rodada-anterior/01-analise.md` e `02-recon.md`: usados como referência de perguntas já levantadas (Q1 a Q13). Não são decisão.
- Checagem `sf` desta sessão (metadata e contagens agregadas, sem registro de cliente).
- Histórico RAG: `[demandas/EPLAST-25/01-analise.md]` (critérios Gherkin da rodada anterior). Nenhuma demanda irmã traz a lista do baseline.

---

## 1. Contexto de negócio

A Eplast contratou a implantação de IA no Salesforce Sales e Marketing em 6 ondas. As Ondas 1 (diagnóstico e desenho, semanas 1–3) e 2 (projeto-piloto, semanas 4–9) estão contratadas, com 120 h. As Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e treinamento) não estão contratadas. A Onda 6 é banco de horas após o go-live. Pela decisão da conta, o escopo não bloqueia esta demanda.

Pelo contrato, a Onda 1 já entregou o `eplast-ent-06` ("Baseline dos indicadores e roadmap de implantação", concluído). A EPLAST-25 é o `eplast-ent-12`: medir o piloto contra esse baseline, com até 10 usuários, na semana 9. O resultado é o insumo para a Eplast decidir se contrata as Ondas 3 a 5.

Calendário (início do projeto em 28/09/2026, segunda-feira):
- Hoje, 15/11/2026, é domingo da semana 7 (09/11 a 15/11).
- Semana 8: 16/11 a 22/11. Semana 9: 23/11 a 29/11. Fim do contrato: 30/11.
- Restam 14 dias para a medição. Isso é risco de prazo e está na seção 9.

## 2. Objetivo

Produzir, na semana 9, a medição dos indicadores do piloto comparados ao baseline da Onda 1, para a Eplast decidir sobre as Ondas 3 a 5. O objetivo é uma medição, não uma funcionalidade nova no CRM. A demanda não pede automação, campo nem integração.

## 3. Regras de negócio

- RN1 **[texto]**: a medição é contra o baseline definido na Onda 1 (`eplast-ent-06`). Não se mede contra referência nova.
- RN2 **[texto]**: o grupo medido tem até 10 usuários do piloto.
- RN3 **[texto]**: a coleta é preparada nas semanas 6–7 e a medição acontece na semana 9.
- RN4 **[texto]**: o resultado alimenta a decisão de contratar as Ondas 3 a 5.
- RN5 **[squad, guardrail 2]**: o agente não lê dado real de cliente nem de usuário. Indicadores de produção são coletados já agregados, por quem tem acesso à produção.
- RN6 **[squad, LGPD]**: indicador por usuário individual é dado pessoal. O relatório trabalha só com agregados do grupo e não identifica pessoa.
- RN7 **[squad, guardrail 1]**: a medição não executa nada em produção pelos agentes. Qualquer leitura de produção é feita fora dos agentes, por quem tem credencial e autorização da Eplast.

## 4. Escopo

**Entra:**
- Documento de medição (relatório) com uma linha por indicador do baseline, alimentado por relatórios padrão já existentes na org (PA-1).
- Roteiro de coleta com fonte, janela e data de corte de cada indicador.
- Validação, na sandbox de dev, de que as fontes existem e de que a execução é só leitura.

**Fica de fora:**
- Campo, objeto, Flow, Apex, painel novo ou qualquer gravação em Account, Opportunity ou Order (salvo se PA-2 for reaberta).
- Envio de qualquer comunicação ao piloto. Se a medição exigir pesquisa com usuários, o disparo é do Marketing Cloud (regra 2 da conta) e vira item de quem opera o Marketing Cloud, fora da esteira.
- Coleta em produção pelos agentes (RN5, RN7).
- Ondas 3, 4 e 5 (escopo aprovado pela conta; não são objeto desta medição).

## 5. Critérios de aceite (Gherkin)

Os cenários marcados **[aguarda PD-n]** dependem de pendência aberta na seção 8 e não podem ser dados como aceitos até ela ser resolvida.

```gherkin
Funcionalidade: Medição do piloto contra o baseline

  Cenário: C1 — Relatório traz cada indicador do baseline                          [aguarda PD-1]
    Dado que o baseline da Onda 1 (eplast-ent-06) lista N indicadores com valor de referência
    Quando o documento de medição é gerado
    Então o documento tem N linhas, uma por indicador do baseline
    E cada linha traz valor de referência, valor medido no piloto e variação em percentual
    E nenhum indicador fica fora do documento sem justificativa escrita

  Cenário: C2 — Cada indicador declara fonte, janela e data de corte
    Dado a coleta preparada nas semanas 6–7
    Quando o roteiro de coleta é revisado
    Então cada linha informa a fonte, a janela (semanas 6 a 9) e a data de corte (29/11/2026, ou a data efetiva da coleta)
    E toda fonte que é relatório padrão tem nome e DeveloperName conferidos na org por sf

  Cenário: C3 — Documento não identifica usuário individual
    Dado que o grupo do piloto tem até 10 usuários
    Quando o documento de medição é gerado
    Então não aparece nome, e-mail, User Id, username ou qualquer valor que leve a uma pessoa
    E o scanner de PII (ci-pii-scan) passa sem achados nos artefatos da demanda

  Cenário: C4 — Todos os indicadores são do grupo inteiro
    Dado a regra de agregação da PA-9
    Quando o documento é revisado
    Então nenhum indicador é recortado por usuário ou subgrupo

  Cenário: C5 — Execução dos relatórios é só leitura
    Dado a sandbox sbx-eplast-dev
    Quando os relatórios das fontes são executados
    Então a contagem de registros de Account, Opportunity e Order é igual antes e depois
    E nenhum metadado de relatório ou painel é alterado

  Cenário: C6 — Veredito por indicador segue o critério do cliente                 [aguarda PD-2]
    Dado o critério de decisão definido pelo cliente para cada indicador
    Quando o documento é concluído
    Então cada indicador é marcado "atingiu", "não atingiu" ou "inconclusivo"
    E se não existe limiar para o indicador, o documento marca "sem critério definido", sem "atingiu" nem "não atingiu"

  Cenário: C7 — Indicador sem dado suficiente fica inconclusivo com causa
    Dado um agente do piloto que não estava em uso pelo grupo na semana 6, ou um indicador sem dado suficiente
    Quando o documento é concluído
    Então esse indicador é marcado "inconclusivo"
    E a causa está escrita na linha

  Cenário: C8 — Indicador do Protheus traz limitação declarada
    Dado um indicador de pedido cuja fonte é o Protheus
    Quando o documento é concluído
    Então a linha traz a declaração de limitação de qualidade do dado (eplast-ent-11)
    E o indicador usa apenas a amostra validada com o Comercial

  Cenário: C9 — Consumo de IA vem do relatório de consumo, no mesmo período
    Dado que o baseline inclui consumo ou crédito de IA
    Quando o indicador é medido
    Então a fonte é o relatório "Consumption by Agent" e o período é o da janela da PA-4

  Cenário: C10 — Validação de QA não vira medição do piloto
    Dado qualquer validação feita em sandbox
    Quando o resultado é registrado
    Então os artefatos não contêm dado real de cliente nem de usuário
    E o resultado da validação não aparece como medição do piloto
```

## 6. Impacto na org e reaproveitamento (confirmado por `sf`)

Metadata e contagens agregadas da `sbx-eplast-dev`, consultadas nesta sessão:

| Item | O que a org mostra | Decisão (regra 3 da conta) |
|---|---|---|
| Agente Agentforce | `Bot` `SFAgent2`, único bot da dev, com 4 versões (1 a 4), **todas Inactive**. `GenAiPlugin` vazio | Não cria agente. A medição não altera o agente. O "ponto de partida" da conta para assistente continua sendo o `SFAgent2` |
| Consumo de IA | Relatório `Consumption by Agent` (pasta "Consumption Insights by Tags") existe | Reaproveita como fonte de consumo, se o baseline o incluir (PA-7) |
| Indicadores de venda | Painéis `Leads & Oportunidades` e `Pedidos` (pasta Eplast) | Reaproveita como fonte de leitura. Não altera |
| Supervisão de agente de atendimento | Painel `Agent Supervisor Overview` (Service Dashboards) | Candidato. Função não verificada (só o nome) |
| Relatório ou painel de medição | Nenhum com "piloto" ou "baseline" no nome. Contagens: 380 relatórios, 20 painéis na dev | Não cria painel novo. Só se a Eplast pedir (PA-1) |
| Campo de flag de piloto em User ou Account | Não criado | Não cria. Não é necessário na v1 |
| Registros de Account, Opportunity e Order | 0, 0 e 0 (contagem agregada) | Dev não tem dado para validar cálculo. Validação é de existência e de fonte (PA-11) |

## 7. Riscos do assessment que tocam esta demanda

O assessment classificou a org de dev como vermelha. A demanda é de leitura e relatório, e leitura não dispara trigger, Flow nem validation rule. Por isso a maior parte dos achados não se aplica por padrão.

| Achado | Severidade | Toca EPLAST-25? | Por quê |
|---|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | alta | **Não, por padrão** | Zero escrita (PA-2). Se algum indicador exigir gravação (ex.: flag de piloto), a ordem de execução entre triggers custom, triggers do CPQ e Flows precisa ser mapeada antes do design |
| #2 Cobertura Apex de 10% | alta | **Não** | Não há Apex na demanda. Se houver, vale o padrão do squad (`<Classe>Test`, 85%) |
| #3 Validation rules de Order | média | **Não** | Sem criação de Order |
| #4 Campos sem descrição | média | **Não, por padrão** | Sem campo novo. Se houver, sai com `Description` |
| #5 Nome de classe de teste | média | **Não** | Sem Apex |
| #6 Alias `sbx-eplast-dev` | média | **Sim, para o QA** | Ver seção 10: a sandbox de dev tem instância e usuário que se identificam como "qa" |
| #7, #9, #10 | baixa | **Não** | Sem relação com a medição |
| #8 33 perfis com nomes inconsistentes | baixa | **Marginal** | Só importa se a coleta depender de perfil (PD-3 e PA-5) |

Pontos não medidos pelo assessment que tocam a demanda:
- **OWD e compartilhamento.** Se o usuário que faz a coleta em produção não enxerga todos os registros, o número sai parcial. Não medido. Vira condição de coleta (PA-5).

## 8. Premissas assumidas (validar na homologação)

Cada decisão abaixo resolve uma pergunta que a rodada anterior deixou em aberto, pela ordem da regra 4: o que a org mostra, depois o padrão, na opção mais simples e mais fácil de mudar. Todas estão como resolvidas. Se a Eplast discordar, a seção "Como mudar" diz o que refazer.

- [x] **PA-1 — Forma de entrega** (pergunta da rodada anterior: Q1, documento ou painel?).
  - **Decisão:** a entrega é um documento de medição, preparado pelo consultor a partir de relatórios padrão já existentes. Não há painel novo nem código.
  - **Evidência:** a org tem 380 relatórios e 20 painéis, incluindo `Leads & Oportunidades` e `Pedidos` (pasta Eplast). Não há relatório de piloto ou baseline. Regra 3 da conta manda reaproveitar.
  - **Como mudar:** se a Eplast quiser painel dentro do Salesforce, vira build declarativo novo em dev, com passo de design. Soma cerca de 6 a 10 h e sobe a complexidade para M.

- [x] **PA-2 — Só leitura** (Q3, parte de escopo).
  - **Decisão:** nenhum campo, objeto, Flow ou Apex novo. Nada é gravado no CRM.
  - **Evidência:** a demanda é medição. Nenhum indicador identificado exige gravação. Zero registros de Account, Opportunity e Order na dev.
  - **Como mudar:** se algum indicador exigir gravação, a análise é reaberta e o achado #1 vira bloqueante, com mapeamento da ordem de execução antes do design.

- [x] **PA-3 — Grupo do piloto** (Q4: antes e depois ou grupo de comparação?).
  - **Decisão:** antes e depois, no mesmo grupo de até 10 usuários. A lista de usuários é fechada pela Eplast e fica fora dos artefatos (LGPD). Não há grupo de comparação.
  - **Evidência:** contrato, `eplast-ent-12`, "até 10 usuários". Nenhum grupo de controle previsto no contrato.
  - **Como mudar:** se a Eplast quiser grupo de controle, a lista e a janela mudam. Até lá, o documento declara "sem grupo de comparação" como limitação do resultado.

- [x] **PA-4 — Janela e data de corte** (Q7).
  - **Decisão:** janela de semana 6 a semana 9 (02/11 a 29/11/2026). Data de corte: 29/11/2026, ou a data efetiva da coleta se for antes.
  - **Evidência:** contrato. `eplast-ent-09` tem homologação nas semanas 6–7; `eplast-ent-12` é na semana 9; o contrato termina em 30/11.
  - **Como mudar:** o consultor ajusta a janela no roteiro. Se o fim do contrato não permitir coleta suficiente, o indicador sai inconclusivo com causa (C7).

- [x] **PA-5 — Coleta em produção e papel** (Q8 e Q13).
  - **Decisão:** o consultor, com as horas do `eplast-ent-12`, faz a coleta em produção com relatórios padrão e exporta só agregados, com usuário de coleta que enxergue o grupo inteiro. O agente não acessa produção.
  - **Evidência:** guardrails 1 e 2. Contrato lista o `eplast-ent-12` como entregável da Onda 2 com horas do projeto.
  - **Como mudar:** a Eplast designa outra pessoa para a coleta, mantendo a regra de agregado.

- [x] **PA-6 — Agentes medidos** (Q9 e Q10: quais agentes entram e onde estão?).
  - **Decisão:** o `SFAgent2` é o agente de referência. Os agentes de `eplast-ent-09` e `eplast-ent-10` entram se estiverem em uso em produção na semana 6. Agente sem uso pelo grupo fica inconclusivo.
  - **Evidência:** `sf` mostra um único Bot na dev (`SFAgent2`), com todas as versões Inactive, e `GenAiPlugin` vazio. Contrato marca `eplast-ent-07` como concluído, mas a dev não o reflete.
  - **Como mudar:** o consultor confirma a lista de agentes em produção antes da coleta.

- [x] **PA-7 — Consumo e custo de IA** (Q11).
  - **Decisão:** se o baseline incluir consumo ou crédito, a fonte é o relatório `Consumption by Agent`.
  - **Evidência:** relatório existe na dev (`sf`). Resultado do `eplast-ent-04` (licenças e créditos) não está no workspace.
  - **Como mudar:** se o baseline usar custo fora dos créditos, a fonte muda.

- [x] **PA-8 — Dado do Protheus** (Q12).
  - **Decisão:** indicador de pedido vindo do Protheus usa só a amostra validada com o Comercial, e leva declaração de limitação.
  - **Evidência:** contrato, `eplast-ent-11`, risco registrado na qualidade do dado de pedidos vindos do Protheus.
  - **Como mudar:** se a amostra não for validada, o indicador sai inconclusivo.

- [x] **PA-9 — Agregação** (Q6, parte operacional).
  - **Decisão:** o documento traz só agregado do grupo inteiro, sem recorte por usuário nem por subgrupo. Com isso o limiar de tamanho mínimo (K) não se aplica na v1.
  - **Evidência:** guardrail 2 e RN6. Não há recorte previsto no pedido.
  - **Como mudar:** se a Eplast pedir recorte, K e base legal viram pendência (PD-3).

- [x] **PA-10 — Validação de dev sem dado** (Q de validação).
  - **Decisão:** na dev, valida-se só que as fontes existem, que estão nomeadas como no roteiro e que a execução é só leitura (C2 e C5). Cálculo com dado real fica para a Eplast e o consultor, fora da sandbox.
  - **Evidência:** `sf`: 0 Account, 0 Opportunity, 0 Order na dev.
  - **Como mudar:** se a Eplast disponibilizar dado sintético para a dev, a validação de cálculo passa a ser possível.

- [x] **PA-11 — Escopo fora de onda** (decisão da conta).
  - **Decisão:** a demanda segue análise e build, mesmo sem a Onda 2 cobrir a medição. Ondas 3 a 5 não contratadas não bloqueiam.
  - **Evidência:** `comentarios-do-card.md`, orientação do Leonardo de 2026-11-13, item 1.
  - **Como mudar:** não se aplica a esta demanda.

## 9. Pendências (caso 3 da regra 4)

Estas três não têm resposta na org nem no padrão, e errar é caro ou difícil de desfazer. Por isso continuam abertas. Elas impedem a aprovação do gate no Squad OS.

- [ ] **PD-1 — Lista do baseline (`eplast-ent-06`).** Quais indicadores, com definição, unidade, valor de referência e janela?
  - **Motivo:** o documento não está no workspace nem no histórico RAG. A org não tem essa lista, e nenhum padrão de plataforma define os indicadores de negócio da Eplast. Um valor de referência errado muda a decisão de contratar as Ondas 3 a 5, e o erro não se corrige depois de 30/11.
  - **Ação:** o consultor entrega o documento do `eplast-ent-06` antes do início da semana 9 (23/11).
  - **Bloqueia:** C1 e a montagem do documento.

- [ ] **PD-2 — Critério de decisão por indicador e quem decide.** Qual limiar leva a contratar as Ondas 3 a 5?
  - **Motivo:** é decisão comercial do cliente. Não existe na org nem num padrão. Um limiar inventado mudaria o investimento que a Eplast vai fazer.
  - **Bloqueia:** só o veredito (C6). A montagem da medição segue sem ele, com "sem critério definido".

- [ ] **PD-3 — Base legal, aviso aos usuários e responsável LGPD da Eplast.** A medição de uso de IA pelas pessoas do piloto é tratamento de dado de empregado.
  - **Motivo:** base legal e aviso são decisão do cliente (DPO). Errar tem custo legal. A análise do agregado (PA-9) não depende disso, mas a coleta depende.
  - **Bloqueia:** a coleta em produção (PA-5). Não bloqueia o build, que é zero.

## 10. Incertezas declaradas

- **Produção não foi acessada.** Uso real dos agentes e volume de sessões em produção não estão confirmados. Dizer que `eplast-ent-07` está em uso exigiria consultar produção, o que está fora do alcance dos agentes.
- **`AiAgentSession` não pôde ser consultado** na dev (erro de consulta). Uso por sessão não foi medido.
- **Alias `sbx-eplast-dev` (achado #6).** A instância é `eplast--qa.sandbox` e o usuário tem sufixo `eplast2.qa`. A separação dev e QA não está comprovada. `sbx-eplast-qa` não está conectada nesta sessão. Antes de qualquer validação de QA, comparar o Org Id da QA com o da dev.
- **Função do painel `Agent Supervisor Overview`** não verificada. Só o nome foi confirmado.
- **OWD e compartilhamento** não medidos (seção 7).
- **Assessment em `clients/eplast/assessment.md`**, não na raiz. Usei o resumo do prompt e busca por trecho.
- **Metadata de agentes:** `GenAiPlanner` não é aceito nesta versão da API. A ausência de `GenAiPlugin` na dev é confirmada. Não afirmo ausência de agente em produção.

## 11. Complexidade

**P.** Nenhum código, campo ou metadata novo previsto. A medição lê relatórios existentes e o peso está em coleta e alinhamento, não em construção. Sobe para M se a Eplast pedir painel novo (PA-1).

## 12. Estimativa de esforço

**Estimativa de esforço:** 14–28 h

Premissas que mais pesam na faixa:
- Roteiro de coleta e revisão do baseline (PD-1 entregue): 3–5 h. Coleta em produção e consolidação agregada pelo consultor (PA-5): 4–8 h. Documento de medição e revisão: 4–6 h. Validação de fontes na dev (PA-10): 1–2 h. Homologação com a Eplast: 2–4 h.
- Se o baseline não chegar (PD-1), reconstruir a lista com a Eplast soma 4–8 h. Se a Eplast pedir painel novo (PA-1), soma 6–10 h. A faixa de cima já tem uma folga para a amostra do Protheus (PA-8).
- Tempo de resposta da Eplast a PD-2 e PD-3 não está na faixa. Se não fecharem até 23/11, a medição sai inconclusiva por falta de critério.

Esta é a faixa crua de delivery, do ponto de vista humano (consultor e Eplast). O arquiteto refina no design, se houver.

## 13. Próximos passos

1. Consultor entrega o documento do `eplast-ent-06` (PD-1).
2. Eplast responde o critério de decisão e quem decide (PD-2), e a base legal e o responsável LGPD (PD-3).
3. Consultor confirma a lista de agentes em uso em produção na semana 6 (PA-6) e o usuário de coleta (PA-5).
4. Confirmar que a sandbox de QA é distinta da dev (seção 10) antes de qualquer validação de QA.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
