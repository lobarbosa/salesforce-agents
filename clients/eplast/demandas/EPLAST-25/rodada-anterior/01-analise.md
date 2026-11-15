# EPLAST-25 — Medição do piloto de IA contra o baseline (até 10 usuários)

**Cliente:** Eplast · **Tipo:** projeto · **Entregável contratado:** `eplast-ent-12` (peso 1, Onda 2, semana 9)
**Origem:** roteiro de IA no Salesforce Sales e Marketing (Konecta). **Status:** análise para validação humana.
**Não pronta para design.** Há bloqueantes de escopo (Q1 a Q5, seção 6) que mudam se a demanda vira build na esteira ou só entrega de consultoria.

Fontes usadas:
- `demandas/EPLAST-25/demanda.md` (história do consultor, 5 linhas).
- `assessment.md` (2026-09-30) e a checagem `sf` desta sessão (2026-11-10).
- `contrato.md` (materializado pelo Squad OS; Status Report semana 05, 29/10/2026).
- Histórico RAG: `[demandas/EPLAST-28/01-analise.md]`, `[demandas/EPLAST-26/01-analise.md]`, `[demandas/EPLAST-29/01-analise.md]`, `[demandas/EPLAST-33/01-analise.md]`, `[demandas/EPLAST-34/01-analise.md]`. São demandas irmãs, usadas só como referência de convenção e de perguntas já levantadas. Nenhuma delas define os indicadores da EPLAST-25.

---

## 1. Contexto de negócio

A Eplast contratou a implantação de IA no Salesforce Sales e Marketing em 6 ondas. As Ondas 1 (diagnóstico e desenho, semanas 1–3) e 2 (projeto-piloto, semanas 4–9) estão contratadas, com 120 h. As Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e treinamento) não estão contratadas. A Onda 6 é banco de horas após o go-live.

Pelo `contrato.md`, a Onda 1 já entregou o `eplast-ent-06` ("Baseline dos indicadores e roadmap de implantação", concluído). A EPLAST-25 é o `eplast-ent-12`: medir o piloto contra esse baseline, com até 10 usuários, na semana 9. O resultado é o insumo para decidir se a Eplast contrata as Ondas 3 a 5.

Datas, calculadas a partir do início do projeto (2026-09-28, segunda-feira):
- Semana 6: 02/11 a 08/11. Semana 7: 09/11 a 15/11. Hoje (10/11) é semana 7.
- Semana 9: 23/11 a 29/11. Fim do contrato: 30/11.

Ou seja, a preparação da coleta (semanas 6–7) já está em curso, e a medição precisa cair em uma janela de 7 dias antes do fim do contrato. Isso é risco de prazo e entra na seção 6.

## 2. Objetivo

Produzir, na semana 9, a medição dos indicadores do piloto comparados ao baseline da Onda 1, para que a Eplast decida sobre as Ondas 3 a 5. Nesta etapa, preparar a coleta dos indicadores nas semanas 6–7.

O objetivo é uma medição, não uma automação. A demanda não pede nova funcionalidade no CRM.

## 3. Regras de negócio

O texto da demanda define poucas regras. As abaixo são as que dá para extrair dele ou que decorrem de guardrails do squad. Cada uma é marcada como **[texto]** (está na demanda ou no contrato) ou **[squad]** (vem de guardrail ou convenção, não foi pedida pelo cliente).

- RN1 **[texto]**: a medição é contra o baseline definido na Onda 1 (`eplast-ent-06`). Não se mede contra uma referência nova.
- RN2 **[texto]**: o grupo medido tem até 10 usuários do piloto.
- RN3 **[texto]**: a coleta é preparada nas semanas 6–7 e a medição acontece na semana 9.
- RN4 **[texto]**: o resultado alimenta a decisão de contratar as Ondas 3 a 5.
- RN5 **[squad, guardrail #2]**: o agente não lê dado real de cliente nem de usuário. Indicadores de produção são coletados e enviados já agregados, por quem tem acesso à produção (consultor ou Eplast). O agente só trabalha com metadata, contagens agregadas e dado sintético.
- RN6 **[squad, LGPD]**: indicador por usuário individual é dado pessoal. O relatório entregue deve trabalhar com agregados e não identificar pessoa (ver Q6).
- RN7 **[squad, guardrail #1]**: a medição não executa nada em produção. Qualquer leitura de produção é feita fora dos agentes, por quem tem a credencial e a autorização do cliente.

## 4. Critérios de aceite (Gherkin)

Os cenários abaixo são testáveis. Os que dependem de decisão pendente trazem a marca **[aguarda Qn]** e não devem ser tratados como aceitos até a resposta.

```gherkin
Funcionalidade: Medição do piloto contra o baseline

  Cenário: Relatório traz cada indicador do baseline com referência e valor medido
    Dado que o baseline da Onda 1 (eplast-ent-06) lista N indicadores com valor de referência  [aguarda Q2]
    Quando a medição da semana 9 é concluída com o grupo do piloto
    Então o relatório tem uma linha por indicador do baseline
    E cada linha traz o valor de referência, o valor medido no piloto e a variação em percentual
    E nenhum indicador do baseline fica fora do relatório sem justificativa escrita

  Cenário: Cada indicador declara fonte, periodicidade e data de corte
    Dado a coleta preparada nas semanas 6–7
    Quando o roteiro de coleta é revisado pelo consultor
    Então cada indicador tem fonte identificada (relatório padrão, consulta agregada, pesquisa com usuários ou outro sistema)  [aguarda Q3]
    E cada indicador tem responsável pela coleta e data de corte do período medido  [aguarda Q7 e Q8]

  Cenário: Relatório não identifica usuário individual
    Dado que o grupo do piloto tem até 10 usuários
    Quando o relatório é gerado
    Então não aparece nome, e-mail, identificador de usuário ou qualquer valor que permita chegar a uma pessoa
    E indicadores com menos de K usuários no recorte são omitidos ou agrupados  [aguarda Q6 para definir K]

  Cenário: Nenhum dado de produção entra no repositório ou nos artefatos do agente
    Dado que a coleta foi feita em produção por quem tem acesso
    Quando os artefatos da demanda são commitados
    Então o scanner de PII (ci-pii-scan) passa sem achados
    E nenhum arquivo contém registro, valor individual ou identificador de cliente ou de usuário

  Cenário: Medição tem resultado frente ao critério de decisão
    Dado o critério de decisão para as Ondas 3 a 5 definido pelo cliente  [aguarda Q5]
    Quando o relatório é concluído
    Então cada indicador é marcado como "atingiu", "não atingiu" ou "inconclusivo"
    E "inconclusivo" é usado quando o piloto não tinha dado suficiente para aquele indicador, com a causa escrita

  Cenário: Dado de QA é sintético e fica fora da medição de produção
    Dado que qualquer validação do roteiro de medição roda na sandbox de QA
    Quando a validação é executada
    Então os dados usados são sintéticos ou anonimizados
    E o resultado da validação de QA não é apresentado como medição do piloto
```

Observação sobre os critérios. Um critério como "a medição é precisa" não é testável e não entrou na lista. O critério de precisão depende da definição de cada indicador (Q2), e só então vira um teste de conferência.

## 5. Riscos do assessment que tocam esta demanda

O assessment (2026-09-30) classificou a org de dev como **vermelha**. Abaixo, cada achado com a avaliação de se ele de fato toca o pedido. A regra usada: a demanda, como escrita, é de **leitura e relatório**. Leitura não dispara trigger, Flow nem validation rule (que rodam no save). Por isso, a maior parte dos achados de Account, Opportunity e Order **não se aplica por padrão**. Aplica-se se a medição passar a gravar dado no CRM.

| Achado | Severidade | Toca EPLAST-25? | Por quê |
|---|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | alta | **Não por padrão; condicional a Q3** | Relatórios e consultas são só leitura e não disparam a automação. Vira relevante se a medição criar ou alterar registro (ex.: marcar a conta ou a oportunidade como "usada no piloto", gravar log de uso num registro de Account/Opportunity/Order, criar Task automática). Nesse caso, a ordem de execução entre `AccountTrigger`/`OpportunityTrigger`/`OrderTrigger` e as triggers e Flows do CPQ precisa ser mapeada antes do design. |
| #2 Cobertura Apex de 10%; cadeia Protheus sem teste | alta | **Não por padrão; condicional a Apex** | Sem Apex novo, não há cobertura a exigir. Se houver instrumentação em Apex, aplica o padrão do squad: classe `<Classe>Test` e 85% por classe. A cadeia Protheus só entra se algum indicador vier do ERP (ver Q3 e Q12). |
| #3 Validation Rules de Order | média | **Não** | Validation rule roda no save. Leitura não aciona. Só entraria se houvesse criação de Order de teste em QA. |
| #4 68,6% dos campos custom sem descrição | média | **Condicional a campo novo** | Só se a medição exigir campo novo (ex.: flag de piloto em User ou Account). Campo novo sai com `Description` preenchida. |
| #5 Convenção de nome de classe de teste | média | **Condicional a Apex** | Mesmo gatilho do #2. |
| #6 Alias `sbx-eplast-dev` apontando para sandbox "qa" | média | **Sim, bloqueante para qualquer build ou teste** | Confirmado nesta sessão: `sf org display --target-org sbx-eplast-dev` retorna instância `https://eplast--qa.sandbox.my.salesforce.com` e um usuário de integração cujo sufixo de sandbox também se identifica como `.eplast2.qa` (mesmo padrão do achado do assessment). A separação dev/qa não está comprovada. Antes de validar o roteiro em QA, confirmar qual sandbox é de fato a de QA. |
| #7 Perfil "Financeiro" com 1 usuário | baixa | **Não** | Sem relação com medição. |
| #8 33 perfis, nomes inconsistentes | baixa | **Marginal** | Só relevante se o relatório for filtrado por perfil (ex.: "Comercial - Analista" vs "Comercial - Analistas"). Confirmar com Q4. |
| #9 Classes em API version antiga | baixa | **Condicional a Apex** | Só se houver edição de classe existente. |
| #10 Nome de trigger duplicado (SBQQ e custom) | baixa | **Não** | Sem Apex novo. |

Pontos do assessment que **não foram medidos** e que tocam esta demanda:
- **OWD e regras de compartilhamento por objeto.** Definem quem enxerga o que. Se o relatório mostrar dado por usuário ou por equipe, a visibilidade depende disso. Não medido (assessment, "Não pôde ser medido").
- **Uso real de campos e layouts.** Não tem impacto direto na medição. Vale só se algum indicador depender de campo que ninguém usa.

Dados que o assessment **não tem** e que limitam a validação:
- A sandbox de dev tem 0 Account, 0 Contact e 0 Opportunity. Não dá para validar a lógica de medição com dado real em dev. A validação precisa de dado sintético em QA ou de dado agregado fornecido pelo cliente.
- A sandbox de dev tem 14 usuários com licença Salesforce ativos (consulta `sf` de hoje). Esse número não é o de produção e não diz nada sobre o tamanho do piloto real.

## 6. O que a demanda NÃO diz

Estas perguntas precisam de resposta antes do design. As marcadas como **[bloqueante]** impedem o design.

- **Q1 [bloqueante] — Forma de entrega.** A entrega é um documento (relatório de medição), um relatório ou dashboard dentro do Salesforce, ou os dois? A resposta decide se a demanda passa pela esteira de build (etapas 3 a 7) ou é só entrega de consultoria. Sem build, as etapas 4 a 6 não se aplicam.
- **Q2 [bloqueante] — Lista do baseline.** Quais são os indicadores do `eplast-ent-06`, com definição, unidade, valor de referência e janela temporal? O documento de baseline não está no workspace e não foi encontrado no histórico RAG. Sem a lista, os critérios de aceite de medição não têm alvo.
- **Q3 [bloqueante] — Fonte de cada indicador.** Cada indicador vem de relatório padrão do Salesforce, consulta, Agentforce analytics, Protheus, pesquisa com usuários ou outra fonte? Se algum indicador exigir campo novo, gravação em Account, Opportunity ou Order, ou integração com o Protheus, os achados #1, #2 e #4 passam a ser bloqueantes.
- **Q4 [bloqueante] — Grupo do piloto.** Quem são os até 10 usuários, como foram escolhidos e a lista está fechada? A medição é antes e depois no mesmo grupo, ou há grupo de comparação? Sem grupo de comparação, o resultado não separa efeito da IA de efeito do período.
- **Q5 [bloqueante] — Critério de decisão.** Qual limiar por indicador leva a contratar as Ondas 3 a 5, e quem decide? Sem isso, "medir" não tem critério de aceite final, e o critério de decisão do critério de aceite (seção 4) fica aberto.
- **Q6 [bloqueante] — LGPD e monitoramento.** Indicador por usuário individual (ex.: quantas vezes cada pessoa usou o assistente) é monitoramento de desempenho de empregado. Precisa de: base legal, aviso aos usuários do piloto, tamanho mínimo de grupo (K) para agregar, retenção dos dados e quem é o responsável pela Eplast. A demanda não trata disso. O agente não decide sozinho o K nem a base legal.
- **Q7 — Janela de medição.** A medição cobre o período de quais semanas (4 a 9, só 6 a 9, outra)? Qual é a data de corte? Hoje é semana 7. A semana 9 cai entre 23/11 e 29/11, e o contrato termina em 30/11. Um atraso de uma semana tira o insumo da decisão antes do fim do contrato.
- **Q8 — Quem coleta em produção.** A coleta de produção é feita pelo consultor, pelo cliente ou por outra pessoa? Com qual credencial? A demanda não fala disso. Pela RN5 e RN7, o agente não faz essa coleta.
- **Q9 — Agentes que entram na medição.** A demanda mede quais agentes do piloto? O `eplast-ent-09` e o `eplast-ent-10` estão sendo construídos fora da esteira (semana 5, homologação nas semanas 6–7). O `eplast-ent-11` não começou. Se um agente não estiver em uso pelos 10 usuários na semana 9, o indicador dele fica inconclusivo.
- **Q10 — Onde estão os agentes do piloto.** O `eplast-ent-07` (Agentforce no perímetro do piloto) está marcado como concluído no contrato. Nesta sessão, `sf org list metadata --metadata-type GenAiPlugin` e `Dashboard` e `Report` retornaram vazio na sandbox de dev. Isso não prova que o Agentforce não existe. Pode estar em produção, ou usar outro tipo de metadata. Não afirmo nenhum dos dois. Confirmar com o consultor e, se for o caso, com `sf` na org correta.
- **Q11 — Custo de IA entra na medição?** Se o baseline inclui consumo de créditos ou custo por conversa, o resultado do `eplast-ent-04` (licenças e créditos) é insumo. Ele não está no workspace.
- **Q12 — Qualidade do dado de pedido.** O `eplast-ent-11` registra risco na qualidade dos dados de pedidos vindos do Protheus. Se algum indicador de recompra ou de pedido vier do Protheus, a qualidade desse dado afeta o resultado. Precisa de declaração de limitação no relatório.
- **Q13 — Papel no contrato.** Quem executa a medição: o consultor, com horas do contrato, ou a equipe da Eplast? Isso define o responsável pelo aceite do entregável `eplast-ent-12`.

## 7. Premissas a validar

Todas pendentes. Nenhuma foi confirmada.

- **P1 (PENDENTE)** — A medição é leitura e relatório. Não grava dado no CRM. Confirmar com Q1 e Q3.
- **P2 (PENDENTE)** — A coleta de produção é manual, feita fora dos agentes, por quem tem acesso autorizado pelo cliente. Confirmar com Q8.
- **P3 (PENDENTE)** — O baseline da Onda 1 existe como documento com lista de indicadores e valores de referência. Não foi verificado porque não está no workspace. Confirmar com Q2.
- **P4 (PENDENTE)** — O grupo do piloto são os 10 usuários de um conjunto fixo, sem troca no período. Confirmar com Q4.
- **P5 (PENDENTE)** — Não é necessário campo, objeto ou Apex novo. Se for necessário, a análise precisa ser refeita. Confirmar com Q3.
- **P6 (PENDENTE)** — O alias `sbx-eplast-dev` é a sandbox de dev, conforme o `CLAUDE.md` do cliente, mesmo com a identidade de "qa" (achado #6). Não confirmado. Bloqueia qualquer validação em sandbox.
- **P7 (PENDENTE)** — A org consultada hoje (API 68.0) é a mesma auditada no assessment (registrado como API v67, 2026-09-30). A diferença de versão não altera a análise, mas o assessment pode estar desatualizado.

## 8. Complexidade

**M (provisório).** Justificativa: não há código previsto, mas o alvo da medição (baseline) não foi confirmado, o grupo e o critério de decisão estão indefinidos, e há exigência de LGPD sobre indicador individual. Se Q1 definir entrega só como documento, com fontes padrão e agregados, cai para **P**.

## 9. Estimativa de esforço

**Estimativa de esforço:** 16–40 h

Premissas que mais pesam na faixa:
- Entrega só documental com relatórios padrão e dado agregado fornecido pelo cliente: próximo de 16 h. Inclui revisão do baseline, roteiro de coleta, consolidação e revisão com o consultor.
- Entrega com relatório ou dashboard dentro do Salesforce (sem gravar dado no CRM): acima de 24 h, pela configuração, revisão e homologação em QA com dado sintético.
- Qualquer gravação em Account, Opportunity ou Order, ou Apex novo: sobe para o topo da faixa ou acima, porque entram mapeamento de ordem de execução, classe de teste e a ressalva do alias (achado #6).
- Tempo de negociação de LGPD (Q6) e de definição do critério de decisão (Q5) não está na faixa, porque depende do cliente. Se esses itens não fecharem até a semana 9, a medição pode sair inconclusiva.

Esta é a faixa crua de delivery. O arquiteto refina no design, se houver.

## 10. Próximos passos

1. Consultor responde Q1 a Q6 e Q9 a Q10 antes de qualquer design. Q5 e Q6 são as que mais atrasam.
2. Consultor entrega o `eplast-ent-06` (baseline) para o workspace, ou confirma a lista de indicadores por escrito.
3. Confirmar o alias dev/qa (P6), antes de qualquer validação em sandbox.
4. Decidir a janela de coleta considerando o fim do contrato em 30/11 (Q7).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
