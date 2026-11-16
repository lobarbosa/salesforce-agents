# EPLAST-44 — Design: Jornadas automáticas de comunicação (lado do Sales Cloud)

**Resultado do design:** pronto para o gate do arquiteto humano. Sem pendência bloqueante: PEND-01 e PEND-02 da análise viraram premissas assumidas (regra 4, seção 7). Sem mudança de modelo de dados.
**Cliente:** Eplast · **Etapa:** design (arquiteto) · **Data:** 2026-11-15
**Org confirmada:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, Connected), conferida com `sf org list` nesta sessão. Pela regra 5 da conta é a `eplast--qa` da Eplast; não é risco. Só leitura nesta sessão (SOQL de metadata, Tooling, describe de relatório via Analytics API, sem linhas de dado).
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 2026-11-15T23:13), `02-recon.md`, `00-preflight.md` (sem bloqueios, sem outras demandas nos mesmos componentes), `comentarios-do-card.md`, `CLAUDE.md` da Eplast (regras 1 a 6), `assessment.md` (Grep nos achados), RAG (EPLAST-26, -36, -37, -42, -43).

---

## 1. Decisão e justificativa

**Configuração nativa (nível 1): relatórios. Sem Flow, sem Apex, sem campo novo, sem envio.**

- **O CRM já tem os públicos das jornadas.** A pasta `MARKETING CLOUD` (DeveloperName `MARKETINGCLOUD`, 63 relatórios) tem, com filtros conferidos nesta sessão por describe, os públicos de prospecção, primeira compra, pós-compra, reativação em três faixas e mensagem, todos com exclusão de opt-out. Foram construídos pelas EPLAST-36, -37 e -42 ([demandas/EPLAST-36/05-roteiro-cliente.md], [demandas/EPLAST-37/03-design.md]). Regra 3: reaproveitar sem alterar.
- **Falta um público só:** o de entrada recente de lead (boas-vindas). Nenhum relatório da pasta recorta lead por data de criação recente (`LEADS_PROSPECCAO_PRIORIDADE` tem filtro de data `CREATED_DATE` sem intervalo, ou seja, todo o período). É o único componente criado.
- **Gatilho de entrada e saída = filtro do relatório dinâmico.** O registro entra na jornada quando passa a atender o filtro e sai quando deixa de atender (opt-out, conversão, compra, mudança de faixa). O Marketing Cloud lê o relatório na cadência que quem o opera definir. Não há gatilho gravado no CRM, então não há Flow nem campo de controle.
- **Por que não descer de nível.** Flow ou Apex só se justificariam para gravar um marcador de entrada ou disparar algo. Disparo é proibido no CRM (regra 2). Marcador gravado duplicaria o que o filtro do relatório já expressa e exigiria automação nova em Lead, onde já há o Flow `Lead_AfterInsert_AplicaRegraAtribuicao`, ou em Contact/Account, onde há triggers e Flows concorrentes (achado 1). Relatório não entra na ordem de execução.
- **`SFAgent2` não é tocado.** A demanda não pede assistente, resumo nem linguagem natural (recon, seção 1).

## 2. Mapa de jornadas e públicos

Cada jornada abaixo é premissa assumida (PD-01, PD-02). O Marketing Cloud decide quais ativa.

| Jornada | Público (relatório) | Objeto | Entra quando | Sai quando | Componente |
|---|---|---|---|---|---|
| J1 Boas-vindas de lead | `LEADS_BOAS_VINDAS` | Lead | Lead criado nos últimos 7 dias, aberto, não convertido, sem opt-out de e-mail | Passa de 7 dias, é convertido, vai para "Fechado - Não convertido" ou pede opt-out | **cria** |
| J2 Nutrição de prospecção | `LEADS_PROSPECCAO_PRIORIDADE` | Lead | Faixa de prioridade calculada (≠ "Sem dados suficientes"), não convertido, sem opt-out de e-mail e de celular | Converte, perde dados de faixa ou pede opt-out | reaproveita |
| J3 Primeira compra (potenciais) | `POTENCIAIS_SEM_COMPRA` | Contact | `Account.RelationshipClass__c = Potencial`, sem opt-out de e-mail | Conta deixa de ser Potencial (primeira compra ganha) ou opt-out | reaproveita |
| J4 Relacionamento pós-compra | `COMPRA_ULTIMOS_90_DIAS` | Contact | `Account.LastPurchase__c` entre hoje e 90 dias atrás, sem opt-out de e-mail e de celular | Passa de 90 dias sem compra (entra em J5) ou opt-out | reaproveita |
| J5 Reativação, faixa 1 | `SEM_COMPRA_91_A_180_DIAS` | Contact | Última compra entre 91 e 180 dias atrás, sem opt-out de e-mail | Compra de novo (volta a J4), passa a faixa 2 ou opt-out | reaproveita |
| J5 Reativação, faixa 2 | `SEM_COMPRA_181_A_365_DIAS` | Contact | Última compra entre 181 e 365 dias atrás | Idem | reaproveita |
| J5 Reativação, faixa 3 | `SEM_COMPRA_MAIS_DE_365_DIAS` | Contact | Última compra há mais de 365 dias | Compra de novo ou opt-out | reaproveita |
| Canal mensagem (qualquer jornada) | `MSG_LEADS_CELULAR_APTOS`, `MSG_CONTATOS_CELULAR_APTOS` | Lead, Contact | Celular preenchido, sem opt-out de celular (lead não convertido) | Opt-out de celular, conversão | reaproveita |

As faixas de J4 e J5 são mutuamente exclusivas pelas datas (90 / 91–180 / 181–365 / >365), conferido nos filtros. Um contato não fica em duas faixas ao mesmo tempo; pode estar em J3 e em mensagem, e a regra de prioridade e frequência entre jornadas é do Marketing Cloud.

**Não indicados para jornada:** `INATIVOS_GERAL` e `REATIVOS_GERAL_rbp` filtram pelo `Type` da conta (`TYPE equals Inativo` / `Reativo`), e a descrição de `Account.RelationshipClass__c` (EPLAST-37) diz para não usar `Type` como fonte. Não são alterados aqui (PD-07).

## 3. Componentes

| # | Tipo | API name | Ação | Observação |
|---|---|---|---|---|
| C1 | Report (LeadList, Tabular) | `MARKETINGCLOUD/LEADS_BOAS_VINDAS` | **cria** | Especificação na seção 3.1 |
| R1 | Report | `MARKETINGCLOUD/LEADS_PROSPECCAO_PRIORIDADE` | reaproveita, sem alteração | Filtros conferidos: faixa ≠ "Sem dados suficientes", `EMAIL_OPT_OUT = false`, `et4ae5__HasOptedOutOfMobile__c = false`, `CONVERTED = false` |
| R2 | Report | `MARKETINGCLOUD/POTENCIAIS_SEM_COMPRA` | reaproveita | `RelationshipClass__c = Potencial`, `EMAIL_OPT_OUT = false` |
| R3 | Report | `MARKETINGCLOUD/COMPRA_ULTIMOS_90_DIAS` | reaproveita | `LastPurchase__c` ≥ 90 dias atrás e ≤ hoje, opt-out de e-mail e celular excluídos |
| R4–R6 | Report | `MARKETINGCLOUD/SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS` | reaproveita | Faixas por `LastPurchase__c`, `EMAIL_OPT_OUT = false` |
| R7–R8 | Report | `MARKETINGCLOUD/MSG_LEADS_CELULAR_APTOS`, `MSG_CONTATOS_CELULAR_APTOS` | reaproveita | Opt-out de celular excluído (recon, seção 1) |
| P1 | Permission set | `PS_Marketing_Publicos` | reaproveita, sem alteração | Existe (SOQL nesta sessão). C1 só usa objeto e campos padrão de Lead e `PriorityBand__c` já cobertos por permissões existentes; não há permissão nova |
| F1 | Report folder | `MARKETINGCLOUD` (AccessType `Hidden`) | reaproveita, sem alteração | C1 herda o compartilhamento da pasta. Nenhum compartilhamento é mudado |
| — | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | — | **não tocado** | Nenhuma versão nova necessária |
| — | `SFAgent2` | — | **não tocado** | Fora do pedido |

Nenhum Flow, agente ou classe existente é alterado; por isso não há versão nova nem passo de ativação.

### 3.1 Especificação de C1 — `LEADS_BOAS_VINDAS`

- Pasta `MARKETINGCLOUD`; `reportType` `LeadList`; formato **Tabular** (sem agrupamento).
- Colunas, no padrão de R1: `FIRST_NAME`, `LAST_NAME`, `COMPANY`, `STATE`, `Lead.Sector__c`, `LEAD_SOURCE`, `STATUS`, `CREATED_DATE`, `Lead.PriorityBand__c`, `EMAIL`.
- Filtro de data padrão: `CREATED_DATE`, intervalo relativo **últimos 7 dias** (`LAST_N_DAYS:7`, ou o equivalente "Últimos 7 dias" do construtor). É o ponto configurável da janela (PD-03).
- Filtros: `CONVERTED equals false`; `EMAIL_OPT_OUT equals false`; `STATUS notEqual "Fechado - Não convertido"` (valores de status conferidos em `LeadStatus` nesta sessão: "Aberto - Não contatado", "Contatado", "Fechado - Não convertido", "Fechado - Convertido").
- Escopo: todos os leads (`org`), como R1.
- `description`: "EPLAST-44. Público de boas-vindas para o Marketing Cloud: leads criados nos últimos 7 dias, não convertidos, não fechados e sem opt-out de e-mail. Janela no filtro de data padrão. Canal mensagem: usar MSG_LEADS_CELULAR_APTOS."
- Sem filtro de opt-out de celular: é público de e-mail, coerente com os públicos de e-mail de Contact (PD-06).

## 4. Preparação do Sales Cloud para o Marketing Cloud

**a) Dados que o Marketing Cloud lê e onde ficam**

| Dado | Objeto e campo | Público |
|---|---|---|
| Nome, empresa, UF, setor, origem | `Lead.FirstName`, `LastName`, `Company`, `State`, `Sector__c`, `LeadSource` | J1, J2 |
| Faixa e score de prioridade | `Lead.PriorityBand__c`, `Lead.PriorityScore__c` (fórmulas da EPLAST-26) | J1 (coluna), J2 (filtro) |
| Status e conversão | `Lead.Status`, `Lead.IsConverted` | J1, J2 |
| Data de entrada | `Lead.CreatedDate` | J1 |
| Contato e endereço | `Contact.FirstName`, `LastName`, `Title`, endereço de correspondência, telefones, `Email`, `Account.Name` | J3–J5 |
| Última compra | `Account.LastPurchase__c` | J4, J5 |
| Classe de relacionamento | `Account.RelationshipClass__c` (EPLAST-37) | J3 |
| E-mail e celular | `Lead.Email`, `Contact.Email`; `MobilePhone` / `Contact.MobilePhone` e `et4ae5__Mobile_Country_Code__c` | todos / mensagem |

**b) Como o público fica identificável no CRM:** relatório salvo e dinâmico na pasta `MARKETINGCLOUD`, um por jornada ou faixa (seção 2). Sem Campaign nem CampaignMember (Campaign tem 0 registros na dev; PA-04 da análise). A tabela da seção 2 é o catálogo que quem opera o Marketing Cloud usa.

**c) O que o Marketing Cloud devolve e onde é gravado** (componentes do conector `et4ae5` confirmados pelo recon): resultado de envio em `et4ae5__IndividualEmailResult__c`; atividade em `CampaignMember.et4ae5__Activity__c`, só se houver campanha no CRM (não é o caso); opt-out de celular em `et4ae5__HasOptedOutOfMobile__c`. Opt-out de e-mail feito no Marketing Cloud volta para `HasOptedOutOfEmail` se a sincronização de descadastro do conector estiver ligada; isso é configuração do lado do Marketing Cloud e não foi verificado (a esteira não conecta). Esta demanda não cria campo de retorno.

**d) Consentimento e opt-out:** todo público de e-mail exclui `HasOptedOutOfEmail = true`; todo público de mensagem exclui `et4ae5__HasOptedOutOfMobile__c = true`; J2 e J4 excluem os dois (filtro já existente, mantido: exclusão a mais é o lado seguro). Lead convertido sai dos públicos de Lead (`CONVERTED = false`). Saída por opt-out é imediata na próxima leitura do relatório.

**e) Fica para quem opera o Marketing Cloud** (time de marketing da Eplast, PA-08 da análise): escolher quais jornadas ativar; importar cada relatório como público com a cadência de atualização; conferir se o conector aceita os relatórios no formato atual (R1 é Summary, os demais Tabular); garantir que o usuário de integração do conector enxergue a pasta `MARKETINGCLOUD`, que é `Hidden` e compartilhada (o usuário de integração não foi identificado na dev); ligar a sincronização de descadastro; definir conteúdo, cadência, prioridade entre jornadas e limite de frequência; montar e disparar as jornadas. Nada disso é feito pela esteira.

## 5. Automação concorrente, escala e limites

- **Nenhuma automação nova.** Relatório não dispara trigger, Flow nem validation rule; não entra na ordem de execução de Lead, Contact, Account, Opportunity ou Order.
- **Escala:** sem transação, sem SOQL, sem CPU. Limite que importa é o de linhas do relatório consumido por integração; o volume real não pode ser medido (dev com 0 Lead e 0 Contact). Risco R-03.
- **Na criação de dado de teste** (não na solução): inserir Lead dispara `Lead_AfterInsert_AplicaRegraAtribuicao` (pode trocar o proprietário) e as validation rules `Telefone`/`Celular`; inserir Account dispara `AccountBefore`, `AccountTrigger` e os Flows de Account; Contact passa pelas validation rules `Telefone`/`WhatsApp`. O fixture precisa respeitar o formato de telefone dessas regras ou deixar os telefones vazios onde o caso não precisa deles.

## 6. Riscos

### 6.1 Riscos do assessment

| Achado | Toca? | Como o design lida |
|---|---|---|
| 1. Automação concorrente em Account, Opportunity e Order (inclui triggers SBQQ) | Não, na solução | Nenhum componente grava nesses objetos. Só o fixture cria Account de teste (seção 5); não é Order nem Opportunity |
| 2. Cobertura Apex em 10% | Não | Sem Apex. Nada muda na cobertura |
| 3. Validation rules de Order | Não | Order não é tocado nem usado em filtro (a compra entra por `Account.LastPurchase__c`) |
| 4. Campos sem descrição | **Sim** | `Account.LastPurchase__c` e `Account.Inactive__c` estão sem descrição (Tooling nesta sessão). J4 e J5 dependem de `LastPurchase__c`. Não é alterado aqui (campo de outra origem, quem o alimenta não está documentado); vira R-02 e premissa PD-08. C1 sai com `description` |
| 5, 9. Convenções e versão de API de classes | Não | Sem classe |
| 6. Alias de dev "qa" | Resolvido pela regra 5 | — |
| 7, 8. Perfis | Não | Nenhum perfil ou permission set alterado |
| 10. Nome de trigger duplicado | Não | Order não é tocado |

### 6.2 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R-01 | Público escolhido não corresponde à jornada que a Eplast quer | Média | Premissas PD-01/PD-02; o CRM não envia nada, e quem opera o Marketing Cloud escolhe o público; corrigir é editar filtro |
| R-02 | `Account.LastPurchase__c` sem descrição e sem origem documentada; se não for alimentado na produção, J4 e J5 ficam vazios | Média | Herdado da EPLAST-37. QA prova o filtro com dado sintético; a homologação confirma quem alimenta o campo (PD-08) |
| R-03 | Volume real dos públicos desconhecido (dev sem dado) | Baixa | Validar contagem na QAS (Partial Copy) só por `COUNT()` agregado, sem ler linhas |
| R-04 | Formato Summary de R1 ou pasta `Hidden` impedirem a leitura pelo conector | Baixa | Não verificável sem conectar ao Marketing Cloud; declarado na seção 4e como passo de quem opera. Não alterado aqui |
| R-05 | Lead "Fechado - Não convertido" continua em J2 (R1 não filtra status) | Baixa | Mantido (PD-05); a EPLAST-43 previu retirá-lo, está em backlog e não mexe nesta demanda (preflight sem conflito) |

## 7. Premissas assumidas (validar na homologação)

Herdadas da análise e mantidas: PA-01 (Lead e Contact como públicos separados), PA-02 (opt-out por canal), PA-03 (público em relatório), PA-04 (sem Campaign), PA-05 (gatilho com campos existentes; confirmado, nenhum campo novo), PA-06 (CRM não dispara), PA-07 (Flow de atribuição de Lead intocado), PA-08 (time de marketing da Eplast opera o Marketing Cloud).

Novas, decididas neste design:

- [x] **PD-01 — Quais jornadas (era PEND-01).**
  - Pergunta: quais jornadas e para quê?
  - Decisão: cinco jornadas (seção 2): boas-vindas de lead, nutrição de prospecção, primeira compra de potenciais, relacionamento pós-compra e reativação em três faixas, com mensagem como canal alternativo.
  - Evidência: a org já mostra como a Eplast segmenta: relatórios `LEADS_PROSPECCAO_PRIORIDADE`, `POTENCIAIS_SEM_COMPRA`, `COMPRA_ULTIMOS_90_DIAS`, `SEM_COMPRA_*`, `MSG_*` na pasta `MARKETINGCLOUD` (describe nesta sessão), construídos nas EPLAST-36/37/42. Boas-vindas é a jornada automática padrão de entrada. Não é caso 3: o CRM não envia nada, quem opera o Marketing Cloud escolhe e aprova cada jornada antes de qualquer disparo, e desfazer é apagar ou ignorar um relatório.
  - Como mudar: ativar só as jornadas desejadas no Marketing Cloud; jornada nova vira relatório novo na mesma pasta.

- [x] **PD-02 — Gatilho de entrada e saída (era PEND-02).**
  - Pergunta: quem entra, quando entra, quando sai?
  - Decisão: entra quem passa a atender o filtro do relatório; sai quem deixa de atender (seção 2). Não há gatilho gravado no CRM.
  - Evidência: padrão de público dinâmico já usado na conta (PA-03; EPLAST-36/42); opção mais simples e mudável (editar filtro).
  - Como mudar: editar o filtro do relatório; se a Eplast exigir evento gravado (ex.: data de entrada na jornada), vira demanda com campo novo, que é decisão de modelo de dados.

- [x] **PD-03 — Janela de boas-vindas.**
  - Decisão: lead criado nos últimos 7 dias.
  - Evidência: padrão de mercado para série de boas-vindas; nenhum campo ou relatório na org indica outra janela.
  - Como mudar: trocar o intervalo do filtro de data de C1, sem deploy de código.

- [x] **PD-04 — Boas-vindas só para Lead.**
  - Decisão: Contact novo não recebe boas-vindas; contato de cliente com compra recente cai em J4.
  - Evidência: na org, Contact nasce de conversão ou de conta existente (Lead tem `IsConverted`; os públicos de Contact são por histórico de compra).
  - Como mudar: criar relatório de Contact por `CreatedDate`.

- [x] **PD-05 — Status de lead.**
  - Decisão: C1 exclui "Fechado - Não convertido" e convertido; R1 fica como está (inclui "Fechado - Não convertido", exclui convertido).
  - Evidência: valores de `LeadStatus` na org; R1 é de outra demanda e não é alterado (regra 3).
  - Como mudar: acrescentar filtro de status em R1, se a Eplast não quiser nutrir lead fechado.

- [x] **PD-06 — Opt-out por canal.**
  - Decisão: público de e-mail exclui opt-out de e-mail; de mensagem, opt-out de celular; R1 e R3 continuam excluindo os dois.
  - Evidência: filtros existentes (describe nesta sessão); PA-02 da análise.
  - Como mudar: não é configurável sem decisão da Eplast (consentimento).

- [x] **PD-07 — Reativação usa data de compra, não `Type`.**
  - Decisão: J5 usa `SEM_COMPRA_*`; `INATIVOS_GERAL` e `REATIVOS_GERAL_rbp` não são indicados e não são alterados.
  - Evidência: descrição de `Account.RelationshipClass__c` (EPLAST-37): "não usar o campo Type como fonte".
  - Como mudar: a Eplast pode usar esses relatórios no Marketing Cloud por conta própria.

- [x] **PD-08 — `Account.LastPurchase__c` é a data da última compra.**
  - Decisão: tratado como data da última compra, como nos relatórios da EPLAST-36/37.
  - Evidência: nome do campo e uso nos 4 relatórios de compra; descrição ausente (achado 4).
  - Como mudar: se o campo não for alimentado na produção, J4/J5 passam a depender de outra fonte, numa demanda própria.

- [x] **PD-09 — Caso de acesso negado.**
  - Decisão: não há usuário de teste sem acesso. `005bJ00000piKAaQAM` é o único ativo e é "Administrador do sistema"; `005bJ00000hBJmYQAW` está inativo (recon). Nenhum perfil ou permissão é alterado. O controle de acesso de C1 é o da pasta `MARKETINGCLOUD`, que não muda; a verificação prova por metadata que C1 está nessa pasta e que nenhum compartilhamento foi alterado, e o teste funcional de acesso negado vai para o roteiro do cliente, como na EPLAST-36 (testes 8 e 9).
  - Evidência: regra 6 da conta; recon seção 5.
  - Como mudar: se a Eplast indicar um usuário não admin de teste, o QA executa o caso.

## 8. O que NÃO será feito

- Nada no Marketing Cloud: conexão, público, jornada, envio, conteúdo, sincronização de descadastro.
- Nenhum envio no CRM: sem e-mail alert, template, ação de e-mail em Flow, Apex com `Messaging`.
- Nenhuma alteração nos relatórios existentes (R1–R8, `INATIVOS_GERAL`, `REATIVOS_GERAL_rbp`), no compartilhamento da pasta, em `PS_Marketing_Publicos`, em perfis, no Flow de atribuição de Lead ou no `SFAgent2`.
- Sem campo novo, Campaign, CampaignMember ou automação agendada.
- Descrição de `Account.LastPurchase__c` e `Inactive__c` (achado 4) fica fora: são campos de outra origem.

## 9. Plano de build (`builder-declarativo`)

1. Em `feature/EPLAST-44`, registrar em `04-plano-build.md` a contagem de relatórios da pasta antes do build (`SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'`, hoje 63), para o CA-05.
2. Criar `force-app/main/default/reports/MARKETINGCLOUD/LEADS_BOAS_VINDAS.report-meta.xml` conforme a seção 3.1. Se a pasta ainda não estiver no repositório, recuperar só o `ReportFolder` `MARKETINGCLOUD` (sem os relatórios) para o deploy.
3. Deploy em `sbx-eplast-dev` com `--dry-run` e depois real, só desse relatório.
4. Conferir por describe (Analytics API) que C1 tem os filtros e a data padrão da seção 3.1, e que a pasta continua com 63 + 1 relatórios.
5. Confirmar no pacote a ausência de `EmailTemplate`, `WorkflowAlert`, Flow ou Apex (CA-04).
6. Gravar em `04-plano-build.md` a justificativa de reuso de R1–R8 (tabela da seção 3) e de criação de C1.

## 10. O que o verificador e o QA devem testar

**Dados de teste:** sintéticos, prefixo `EPLAST44 TESTE`, proprietário `005bJ00000piKAaQAM`. A pasta `clients/eplast/fixtures/` **ainda não existe** nesta branch; quem montar o primeiro script cria a pasta e o `README.md` (regra 6). Telefones vazios ou no formato das validation rules de Lead e Contact (seção 5). Na QAS, não ler nem alterar registro que o agente não criou; filtrar os resultados por prefixo do nome.

| Caso | Dado | Resultado esperado | Cobre |
|---|---|---|---|
| T1 | Lead novo, aberto, sem opt-out | Aparece em C1 | CA-06 (entrada) |
| T2 | Lead de T1 com `HasOptedOutOfEmail = true` | Sai de C1 | CA-01, CA-06 (saída) |
| T3 | Lead novo com status "Fechado - Não convertido" | Não aparece em C1 | PD-05 |
| T4 | Lead convertido | Não aparece em C1 nem em R1 | CA-03 |
| T5 | Lead com `et4ae5__HasOptedOutOfMobile__c = true` | Fora de R1 e de `MSG_LEADS_CELULAR_APTOS` | CA-02 |
| T6 | Contact com `HasOptedOutOfEmail = true`, conta com `LastPurchase__c` há 120 dias | Fora de `SEM_COMPRA_91_A_180_DIAS` | CA-01 |
| T7 | Contact da conta com `LastPurchase__c` mudando de 30 para 120 dias atrás | Sai de `COMPRA_ULTIMOS_90_DIAS` e entra em `SEM_COMPRA_91_A_180_DIAS` | CA-06, PD-02 |
| T8 | Contact com `et4ae5__HasOptedOutOfMobile__c = true` | Fora de `MSG_CONTATOS_CELULAR_APTOS` | CA-02 |
| T9 | Metadata de C1 | Filtros e janela de 7 dias da seção 3.1; CA-04 sem ocorrências | CA-03, CA-04, CA-05 |
| T10 | Acesso negado | Não executável pela esteira (PD-09): provar por metadata que C1 está na pasta `MARKETINGCLOUD` e que o compartilhamento não mudou; levar o caso funcional ao roteiro do cliente | — |

A janela de 7 dias não exige teste em duas sessões: o lead de teste nasce dentro dela, e a saída por tempo é provada pelo filtro no metadata (T9). Não há automação agendada.

Limpeza: apagar os registros `EPLAST44 TESTE` criados ao final de cada rodada.

## 11. Esforço

**Estimativa de esforço:** 4–8 h
- Mudou em relação à análise (10–20 h): o recon e este design mostraram que sete dos oito públicos já existem com opt-out e conversão tratados; o build caiu para um relatório, sem campo novo (PA-05 confirmada). Sobra o teste com dado sintético em Lead, Contact e Account e a passagem pelas validation rules no fixture. Trabalho no Marketing Cloud continua fora.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
