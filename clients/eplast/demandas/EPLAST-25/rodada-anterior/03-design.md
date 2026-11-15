# EPLAST-25 — Design: medição do piloto de IA contra o baseline (até 10 usuários)

**Cliente:** Eplast · **Tipo:** projeto · **Entregável:** `eplast-ent-12` (Onda 2, semana 9: 23/11 a 29/11; contrato termina em 30/11)
**Org do recon:** `sbx-eplast-dev` (sandbox confirmada por `Organization.IsSandbox`, ver `02-recon.md`, coleta de 2026-11-11)
**Entradas:** `demanda.md`, `01-analise.md` (aprovada no gate `aguardando_gate_analise` em 2026-11-11, ver `gates.md`), `comentarios-do-card.md`, `contrato.md`, `assessment.md` (2026-09-30), `02-recon.md`, RAG do cliente.

## Status deste design: condicional. Não libera build.

A análise foi aprovada no gate, e isso não está em discussão. Ela mesma, porém, se classificou como **"Não pronta para design"** e marcou Q1 a Q6 como bloqueantes. Conferi o workspace:

- `comentarios-do-card.md` tem uma única entrada: a aprovação do gate de análise. Nenhuma resposta a Q1–Q13.
- `contrato.md` confirma que o `eplast-ent-06` (baseline) está concluído, mas não traz a lista de indicadores.
- As pastas das demandas irmãs (EPLAST-26 a -34 e -39) estão em `backlog`, só com `demanda.md`. Nenhuma define indicador do piloto.
- O RAG do cliente não tem o documento de baseline. A consulta devolveu só a própria análise da EPLAST-25 e materiais de outras demandas.

Q1 (forma de entrega), Q2 (indicadores), Q3 (fonte de cada indicador), Q4 (grupo do piloto), Q5 (critério de decisão) e Q6 (LGPD) são decisões de negócio, de contrato e de proteção de dados. **Não respondi nenhuma e não assumi resposta.** Este documento diz, tecnicamente, o que muda em cada resposta possível, para que o aprovador saiba o que está aprovando.

Precedente no mesmo cliente: o design da EPLAST-34 tratou bloqueantes abertos do mesmo jeito, com design condicional e sem liberar build (`[demandas/EPLAST-34/03-design.md]`, via RAG). Sigo o mesmo padrão aqui.

**O que este gate pode aprovar:** a moldura técnica (os três cenários, a recomendação e o que fica fora). **O que este gate não pode aprovar:** um build. Para isso, Q1–Q6 precisam de resposta escrita no card e este design precisa de uma segunda rodada, que fecha um cenário só.

---

## 1. Decisão: três cenários, definidos por Q1 e Q3

A ordem da doutrina (configuração → Flow → código) começa aqui um degrau antes: **nenhuma metadata**. A demanda pede uma medição, não uma funcionalidade (análise, seção 2). O nível mais alto que resolve é o que deve ser usado.

| Cenário | Gatilho (resposta a Q1/Q3) | Nível | Passa pela esteira de build? |
|---|---|---|---|
| **A — Documental** | Entrega é um relatório de medição (documento). Indicadores vêm de relatórios que já existem, de pesquisa com usuários ou de dado agregado que a Eplast ou o consultor extrai de produção. | Sem metadata | Não. Etapas 4 a 6 não se aplicam. |
| **B — Relatórios nativos** | Entrega inclui relatório ou painel dentro do Salesforce, **só leitura**, sobre campos que já existem. | Configuração (Report, Dashboard, Report Type, pasta) | Sim, build declarativo. |
| **C — Instrumentação / gravação** | Algum indicador exige campo novo, objeto novo, gravação em Account/Opportunity/Order/Task ou Apex. | Modelo de dados + Flow ou Apex | **Escalado. Fora deste design.** |

### Recomendação técnica (não é decisão de Q1)

**A, ou A complementado por B, se Q2 mostrar indicadores que relatórios nativos já cobrem.** Motivos:

1. **Prazo.** Hoje é semana 7 (11/11). A medição é na semana 9 e o contrato termina em 30/11. O cenário B exige build, PR, validação em QA e homologação. O cenário A não. A preparação da coleta, que a demanda põe nas semanas 6 e 7, já está atrasada em relação à janela que a análise calculou.
2. **A medição vale em produção, e o agente não toca produção** (guardrail #1). Qualquer painel construído na esteira só mostra dado sintético até alguém promovê-lo. Quem promove para produção é humano, fora da esteira. O valor que decide as Ondas 3 a 5 sai de produção de qualquer forma, pelas mãos de quem tem acesso (RN5, RN7).
3. **Dez usuários é pouco para um painel agregado.** Com até 10 pessoas, qualquer recorte por usuário identifica a pessoa (Q6). Um painel nativo agrupado por proprietário é o formato que mais facilita expor desempenho individual. O documento permite agregar e omitir recortes pequenos com controle editorial.
4. **A org já tem material reutilizável.** O recon achou 374 relatórios e 19 painéis, incluindo relatórios do comercial (carteira por região, clientes recorrentes, efetividade, média de dias para fechamento) e o painel padrão de adoção. A análise tinha registrado zero, por um artefato do comando (`02-recon.md`, seção 2). Se os indicadores do baseline forem dessa natureza, rodar o que existe resolve sem construir nada.

Desço para B só se Q1 pedir explicitamente um artefato no CRM, por exemplo para a Eplast continuar acompanhando depois do piloto. Desço para C só com decisão de arquitetura sênior (seção 4).

---

## 2. Cenário A — documental

### Componentes

Nenhuma metadata criada, alterada ou depreciada. Nada em `force-app/`.

### Entregáveis

| Artefato | Conteúdo | Quem produz |
|---|---|---|
| Roteiro de coleta | Uma linha por indicador do baseline: definição, unidade, valor de referência, fonte, filtro do grupo do piloto, janela, data de corte, responsável | Consultor, com apoio do agente na estrutura (sem dado) |
| Planilha de coleta agregada | Só totais e médias por indicador, já sem identificação de pessoa | Quem tem acesso a produção (Q8) |
| Relatório de medição | Indicador, referência, medido, variação %, status (atingiu / não atingiu / inconclusivo), limitações (Q12) | Consultor |

O relatório de medição e a planilha **não entram no repositório**. Contêm resultado de produção do cliente. No repositório entra só o roteiro, sem valores. Isso atende ao critério de aceite "Nenhum dado de produção entra no repositório" e ao `ci-pii-scan`.

### Como o cenário A trata a fonte de cada indicador (Q3)

| Tipo de fonte | Tratamento |
|---|---|
| Relatório existente (seção 4 do recon) | Rodado em produção por quem tem acesso, com filtro de período e de grupo **aplicado na hora da execução, sem salvar** a lista de usuários no relatório. Exportado já agregado. |
| Painel de adoção / atividade padrão (`AdoptionDashboard`, `NonA360EacDashboard`) | Idem, se o indicador for de uso do CRM. |
| Uso do agente de IA | Depende de onde o agente roda e de a telemetria de sessão estar ligada (Q10). Não verificado. Se não houver telemetria, o indicador vem de pesquisa com os usuários ou fica inconclusivo. |
| Consumo de créditos (Q11) | O painel padrão de consumo (`Digital_Wallet_Consumption_Insights_By_Tags`) existe na sandbox. Vale conferir se existe em produção e se separa o piloto. |
| Protheus (Q12) | Extração agregada fora do Salesforce, com declaração de limitação no relatório. |
| Pesquisa com usuários | Formulário fora do CRM, anônimo, com o mesmo K de Q6. |

### Esteira

Se Q1 confirmar A, a recomendação é que o consultor decida no Squad OS se a demanda segue a esteira de build ou é encerrada como entregável de consultoria após este gate. Sem build, as etapas 4 a 6 não têm o que produzir, e o fluxo exige artefato em cada uma (`ArtifactAusenteError`). Essa é uma decisão de processo, não técnica.

---

## 3. Cenário B — relatórios nativos, só leitura

Só se aplica se Q1 pedir artefato no Salesforce. Os nomes abaixo são **propostos, não existem na org** (confirmado no recon). Os relatórios concretos dependem de Q2 e não dá para nomeá-los antes disso.

### Componentes a criar

| Tipo | API name proposto | Observação |
|---|---|---|
| Pasta de relatório | `Piloto_IA_Medicao` | Compartilhada só com quem decide as Ondas 3 a 5 (Q5), não com o grupo do piloto. |
| Pasta de painel | `Piloto_IA_Medicao` | Idem. |
| Relatórios | um por indicador que tenha fonte no CRM, nomes definidos após Q2 | Reaproveitar tipo de relatório existente antes de criar um novo. Candidatos no recon: `AP_User_Activities_2024_07_02`, `AP_Opportunities_with_Activities_2024_07_02`, `AP_Accounts_with_Activities_2024_07_02`, `Oportunidades_com_tend_ncia_do_hist_rico`. A definição deles não foi aberta. |
| Report Type custom | só se nenhum existente servir | Com `Description` preenchida (achado #4). |
| Painel | `Piloto_IA_Medicao` | `SpecifiedUser`, com usuário executor definido pelo cliente. **Não usar painel dinâmico (`LoggedInUser`)**: a org já tem 3, e o limite da edição é baixo. |

Nada a alterar e nada a depreciar.

### Como identificar o grupo do piloto sem gravar dado (Q4)

Não há campo em `User` que marque o piloto (recon, seção 5). As opções no cenário B são:

| Opção | Mudança de modelo? | Problema |
|---|---|---|
| Filtro por usuário salvo no relatório | Não | **Reprovado.** Grava nome ou ID de usuário em metadata versionada. Viola o guardrail #2 e a regra "hardcode de ID de usuário" do code review (`padrao-entrega`). |
| Filtro por perfil ou papel | Não | Só funciona se os 10 usuários forem exatamente um perfil ou papel. Há quatro variações de perfil comercial na org (achado #8). Responder em Q4. |
| Filtro aplicado na execução, sem salvar | Não | O relatório fica genérico e o recorte é manual. Na prática, B se aproxima de A. |
| Campo novo em `User` (ex.: flag de piloto) | **Sim** | Vai para o cenário C. Escalado. |

### Automação, ordem de execução e governador

- Relatório e painel são só leitura. **Não disparam** trigger, Flow nem validation rule de Account, Opportunity, Order ou Task. Sem conflito de ordem de execução.
- Governador de Apex não se aplica. Valem os limites de relatório e painel (linhas exibidas, componentes por painel, refresh). Com 10 usuários e um período de semanas, o volume é pequeno. O volume real de produção não foi medido e não deve ser (o agente não lê produção).

### Permissões

- Nenhum perfil alterado. Nenhum permission set novo: o acesso ao relatório é pelo compartilhamento da pasta.
- Quem vê a pasta precisa já ter leitura nos objetos e campos usados. OWD e regras de compartilhamento não foram medidos (assessment e recon). O painel `SpecifiedUser` mostra o que o usuário executor enxerga. A escolha desse usuário é decisão do cliente e define o que aparece.

### Validação

- Em sandbox, só com dado sintético. A sandbox de dev tem 0 Account, 0 Contact e 0 Opportunity (assessment). Alguém precisa criar massa sintética.
- **Bloqueio: achado #6.** O alias de dev aponta para uma instância chamada "qa", e `sbx-eplast-qa` não está conectada nesta sessão. Até confirmar que são duas sandboxes, build e homologação concorrem no mesmo ambiente.

---

## 4. Cenário C — instrumentação ou gravação. **Escalado ao arquiteto humano.**

**Se a resposta a Q3 exigir campo novo (em `User`, `Account`, `Opportunity`, `Order` ou outro), objeto novo de log de uso, ou gravação automática em registro, isso é mudança de modelo de dados. Pela regra do papel, não decido sozinho. O cenário não é desenhado aqui.**

O que o arquiteto humano precisa saber para decidir:

- **Risco de ordem de execução (alto).** Account, Opportunity e Order têm, no mesmo evento, trigger custom (`AccountTrigger`, `OpportunityTrigger`, `OrderTrigger`), triggers do CPQ (`SBQQ`) e Flows after-save (`AccountTriggered`, `UpdateParentAccountUsedLimit`, `OpportunityFlow`, `Oportunidade_Industria`, `Order`) e, em Order, um Flow before-save. Task tem o Flow `TaskCreatedOrUpdated`, que atualiza Account (recon, seção 5). **Qualquer gravação nesses objetos para "marcar uso do piloto" entra numa cadeia sem ordem garantida, sem mapeamento feito (achado #1).**
- **CPU (alto).** Uma gravação em Task ou Opportunity que atualize a Account pai dispara de novo a cadeia de Account. Num pai com muitos filhos na mesma transação, o custo multiplica pelo número de Flows e triggers do pai. Foi o caso do achado SOMOSAGILITY-10, que estourou CPU com 150 filhos. O volume de filhos por pai em produção não é conhecido (a sandbox tem 0 registros).
- **Apex (alto).** Cobertura da org em 10% (achado #2). Apex novo exige `<Classe>Test` com 85% ou mais (achado #5). Editar classe existente exige subir a API version (achado #9).
- **Prazo.** C não cabe até a semana 9 com build, QA e homologação, e ainda depende da confirmação dev/qa (achado #6).
- **Uso após o piloto.** Instrumentação só para medir 10 usuários por algumas semanas deixa metadata permanente para manter. Só faz sentido se as Ondas 3 a 5 forem usar a mesma medição.

Se C for escolhido, o caminho é refazer a análise com a lista de campos (premissa P5 da análise) e um novo design. Não é ajuste deste.

---

## 5. Conflito de automação

| Cenário | Conflito? |
|---|---|
| A | Não. Nada é gravado no CRM. |
| B | Não. Relatório e painel são só leitura. |
| C | **Sim, alto. Account, Opportunity e Order têm trigger custom + trigger do CPQ + Flow no mesmo evento. Task tem Flow after-save que grava em Account. Ordem de execução não mapeada.** |

## 6. Riscos do assessment que tocam esta demanda

Ponto de partida: análise, seção 5. Reconfirmado na org onde indicado.

| Achado | Sev. | A | B | C | Como o design lida |
|---|---|---|---|---|---|
| #1 Automação concorrente em Account/Opportunity/Order | alta | Não se aplica | Não se aplica (só leitura) | **Bloqueante** | Reconfirmado no recon (triggers e Flows custom). C está escalado. |
| #2 Cobertura Apex 10% | alta | Não | Não | **Sim** | A e B não têm Apex. |
| #3 Validation rules de Order | média | Não | Não | Só se gravar Order | Validation rule roda no save. Leitura não aciona. |
| #4 Campos sem descrição | média | Não | Report Type novo sai com `Description` | Campo novo sai com `Description` | |
| #5 Convenção de teste | média | Não | Não | Sim | |
| #6 Alias dev aponta para instância "qa" | média | Não (sem sandbox) | **Bloqueante** | **Bloqueante** | Reconfirmado: única org conectada é `sbx-eplast-dev`, instância "qa". |
| #7 Perfil Financeiro com 1 usuário | baixa | Não | Não | Não | |
| #8 Perfis comerciais duplicados | baixa | Marginal | **Sim, se o filtro do piloto for por perfil** | Marginal | Q4 precisa dizer qual perfil, se for por perfil. |
| #9 API version antiga | baixa | Não | Não | Se editar classe | |
| #10 Nome de trigger duplicado | baixa | Não | Não | Dificulta leitura de log em C | |
| Não medido: OWD e compartilhamento | — | Não | **Sim** | Sim | Define o que o painel `SpecifiedUser` mostra. Medir antes do build de B. |

## 7. Riscos técnicos

| # | Risco | Severidade | Cenário | Mitigação |
|---|---|---|---|---|
| R1 | Bloqueantes Q1–Q6 sem resposta escrita. O design não fecha e a medição pode não acontecer na semana 9. | **alta** | todos | Resposta no card antes da segunda rodada do design. |
| R2 | Prazo: semana 9 termina em 29/11, contrato em 30/11. Preparação da coleta (semanas 6–7) termina em 15/11. | **alta** | todos, pior em B e C | Preferir A. Fechar Q7 (janela e data de corte). |
| R3 | Monitoramento individual de empregado em grupo de até 10 pessoas (LGPD). | **alta** | todos, pior em B | Q6 define K e base legal. Nenhum relatório agrupado por usuário. |
| R4 | Separação dev/qa não comprovada (achado #6). | média (bloqueante para B e C) | B, C | Confirmar antes do build. |
| R5 | Telemetria do agente pode não existir. O agente na sandbox (`SFAgent2`) tem todas as versões inativas, e não se sabe onde os agentes do piloto rodam. | média | todos | Q9 e Q10. Indicador sem fonte sai como "inconclusivo", com a causa escrita. |
| R6 | Sem grupo de comparação (Q4), a medição não separa o efeito da IA do efeito do período. | média | todos | Declarar a limitação no relatório. Decisão de método do cliente. |
| R7 | Dado de pedido vindo do Protheus com qualidade incerta (`eplast-ent-11`). | média | se Q3 incluir Protheus | Limitação declarada (Q12). |
| R8 | Relatório reaproveitado medir outra coisa: a definição dos relatórios existentes não foi aberta. | baixa | A, B | Abrir a definição em `/tmp/recon` ao mapear cada indicador. |

## 8. O que NÃO será feito nesta demanda

- Nenhuma leitura, execução ou deploy em produção pelo agente. A coleta de produção é humana (RN5, RN7).
- Nenhum campo, objeto, Flow ou Apex novo sem decisão do arquiteto humano (cenário C).
- Nenhuma alteração em `AccountTrigger`, `OpportunityTrigger`, `OrderTrigger`, nos Flows desses objetos ou em `TaskCreatedOrUpdated`.
- Nenhuma alteração no agente `SFAgent2` nem nos agentes do piloto (`eplast-ent-09`/`-10`/`-11`, construídos fora da esteira).
- Nenhum relatório com nome, ID ou filtro salvo de usuário individual.
- Nenhuma definição de indicador, limiar ou K pelo agente (Q2, Q5, Q6).
- Nenhuma correção de achado do assessment (consolidar automação, cobertura, perfis, alias). Fica para demanda própria.
- Nenhum painel dinâmico.

## 9. Bloqueantes em aberto para quem aprova este gate

| Pergunta | Bloqueia | O que muda tecnicamente com a resposta |
|---|---|---|
| **Q1** Forma de entrega | Escolha do cenário | Documento → A, sem build. Artefato no CRM → B. |
| **Q2** Lista do baseline | Critérios de aceite e relatórios de B | Sem a lista, nenhum relatório pode ser nomeado e a seção 4 da análise não tem alvo. |
| **Q3** Fonte de cada indicador | Se vira C | Qualquer gravação ou campo novo → C, escalado. |
| **Q4** Grupo do piloto | Filtro em B, método em todos | Perfil ou papel único → filtro viável em B. Lista avulsa → recorte manual, sem salvar. Comparação → mais um recorte. |
| **Q5** Critério de decisão | Status "atingiu / não atingiu" | Sem limiar, o relatório só mostra variação, sem veredito. |
| **Q6** LGPD | Formato de qualquer saída | Define K e se pode existir algum recorte por pessoa. |
| Achado #6 | Build e QA de B e C | Confirmar se há duas sandboxes distintas. |

Q7 a Q13 não bloqueiam o cenário, mas Q7 (data de corte) e Q8 (quem coleta em produção) precisam de resposta antes da semana 9 em qualquer cenário.

## 10. Estimativa de esforço

**Estimativa de esforço:** 12–36 h

O que mudou em relação à análise (16–40 h) e por quê:
- **Piso de 16 para 12 h.** O recon mostrou 374 relatórios, 19 painéis (incluindo adoção, atividades e consumo de créditos) e 33 tipos de relatório custom já na org. A análise registrou zero por um artefato do comando. No cenário A, parte da coleta é rodar o que existe, não construir.
- **Teto de 40 para 36 h.** O cenário C (gravação ou Apex), que puxava o topo da faixa da análise, saiu deste design e foi escalado. Se for escolhido, ganha estimativa própria em novo design e fica acima desta faixa.
- Faixa por cenário, para orientar a conversa: **A ≈ 12–20 h** (roteiro, mapeamento de fontes, consolidação, relatório, revisão com o consultor) · **B ≈ 24–36 h** (A mais pasta, relatórios, painel, massa sintética, PR, QA e homologação).
- **Não inclui:** reuniões para responder Q1–Q6, negociação de LGPD, a coleta em produção feita pela Eplast, a confirmação dev/qa do achado #6 e horas de agente.
- A faixa continua larga porque o cenário não está escolhido. Ela fecha na segunda rodada do design.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

Observação para o aprovador: este gate aprova a moldura, não um build. Com Q1–Q6 em aberto, a etapa de build não tem o que construir. Se aprovado, o próximo passo é responder Q1–Q6 no card e rodar a segunda rodada deste design, que escolhe um cenário. Se a resposta for A, a próxima decisão é encerrar a demanda como entrega de consultoria, sem as etapas 4 a 6.
