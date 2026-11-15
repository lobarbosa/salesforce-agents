# Design — EPLAST-37 · Classificação de clientes em ativos, inativos e potenciais

**Cliente:** eplast · **Etapa:** design (arquiteto) · **Data:** 2026-11-15
**Org confirmada:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, sandbox `eplast--qa`, Connected), conferida com `sf org list` nesta sessão. Pela regra 5 da Eplast, é a sandbox "QA" da Eplast; não é risco. Produção não foi tocada.
**Pré-requisitos:** `01-analise.md` aprovado em `gates.md` (2026-11-15); `02-recon.md` presente (coleta de 2026-11-15). Preflight sem bloqueios.

**Decisão: configuração nativa (nível 1). Sem Flow, sem Apex, sem trigger.** Um campo fórmula de texto somente leitura em Account que deriva a classe dos dois campos que a org já tem (`LastPurchase__c` e `Inactive__c`), mais 2 relatórios novos. Os 4 relatórios de público por data de compra que já existem na pasta `MARKETING CLOUD` são reaproveitados sem alteração.

> **Mudança de modelo de dados para o arquiteto humano decidir:** o desenho acrescenta **1 campo em Account** (`RelationshipClass__c`, fórmula, sem gravação). É a única adição ao modelo. A análise deixou isso para o design (P5, CA-07: "campo fórmula só se o design aprovar"). Se o gate recusar o campo, o plano B está na seção 9 e não muda nada mais no desenho.

---

## 1. Por que esta abordagem

**Por que um campo fórmula, e não só filtros de relatório (opção da análise):**
- A org já tem **duas definições de ativo/inativo convivendo**: 5 relatórios pelo `Type` manual e 2 por `LastPurchase__c` (recon, seção 1). Uma terceira definição espalhada em filtros de relatório repete o problema. Um campo é **uma definição só**, num lugar só, que relatórios, lista, Marketing Cloud e, no futuro, o `SFAgent2` leem igual.
- "Potencial" (sem compra) não tem relatório hoje. Sem campo, o relatório de classificação precisaria de fórmula por linha ou de bucket, e a doutrina registra que o XML dessas duas coisas custou caro na EPLAST-39 (skill `salesforce-doutrina`, "Relatórios e painéis por metadata"). Com o campo, basta agrupar por ele.
- O campo é fórmula: **não grava nada em Account, não dispara trigger, Flow nem validation rule** e não entra na ordem de execução (seção 4). É o argumento de P5 (achados 1 e 2 do assessment) preservado.
- Fórmula referenciando roll-up é suportado; o texto da fórmula é curto, longe do limite de caracteres compilados.

**Por que não Flow ou Apex (nível 2 ou 3):** a classe depende só de uma data já mantida pelo roll-up e da data de hoje. Gravar a classe exigiria Flow agendado ou Apex diário sobre Account, que entraria na cadeia de `AccountBefore` (SBQQ), `AccountTrigger`, 2 Flows after-save e 6 validation rules (achado 1, alta) e, se Apex, pesaria na cobertura de 10% (achado 2, alta). Não há ganho que justifique.

**Fórmula do campo** (texto):

```
IF(ISBLANK(LastPurchase__c), "Potencial", IF(Inactive__c, "Inativo", "Ativo"))
```

Precedência da análise (seção 5): Potencial antes de `Inactive__c`, para não depender do `BlankAsZero` de `Inactive__c` com data vazia (recon, "Não confirmei" 1). Reaproveitar `Inactive__c` em vez de repetir "90 dias" mantém a janela num lugar só: se a fórmula de `Inactive__c` mudar, a classe acompanha.

## 2. Mapa item a item: reaproveita ou cria

Tudo marcado "existe" foi confirmado por `sf` (recon de 2026-11-15 ou esta sessão).

| # | Item | Situação na org | Decisão | Motivo |
|---|---|---|---|---|
| 1 | `Account.LastPurchase__c` (roll-up MAX `CloseDate`, `StageName = 'Fechado/Ganho'`) | Existe | **Reaproveita, sem alteração** | Fonte da compra (P7) |
| 2 | `Account.Inactive__c` (fórmula, `> 90` dias) | Existe | **Reaproveita, sem alteração** | Fonte da inatividade (P3) |
| 3 | Campo de classe em Account | Não existe (lista de 90 campos custom de Account conferida nesta sessão; nenhum de classe/situação) | **Cria** `Account.RelationshipClass__c` | Seção 1 |
| 4 | `Account.Type` (9 valores, manual) | Existe | **Não altera; não é fonte** (P6) | Entra como coluna e segundo agrupamento no relatório de classificação, para mostrar a divergência |
| 5 | `Account.Ranking__c` | Existe | **Não altera** (P8); entra como coluna | Eixo de porte, não de relacionamento |
| 6 | `COMPRA - ÚLTIMOS 90 DIAS` (`COMPRA_ULTIMOS_90_DIAS`) | Existe; `LastPurchase__c` de 90 dias atrás até hoje | **Reaproveita, sem alteração** | É o público **Ativo** do MC; janela bate com `Inactive__c` |
| 7 | `SEM COMPRA - 91 A 180 DIAS` (`SEM_COMPRA_91_A_180_DIAS`) | Existe; 91 a 180 dias | **Reaproveita, sem alteração** | Público **Inativo** (faixa 1) |
| 8 | `SEM COMPRA - 181 A 365 DIAS` (`SEM_COMPRA_181_A_365_DIAS`) | Existe; `<= N_DAYS_AGO:181` e `>= N_DAYS_AGO:365` (lido nesta sessão) | **Reaproveita, sem alteração** | Público **Inativo** (faixa 2) |
| 9 | `SEM COMPRA - MAIS DE 365 DIAS` (`SEM_COMPRA_MAIS_DE_365_DIAS`) | Existe; `< N_DAYS_AGO:365` (lido nesta sessão) | **Reaproveita, sem alteração** | Público **Inativo** (faixa 3). As faixas 7, 8 e 9 cobrem juntas de 91 dias em diante, sem buraco e sem sobreposição |
| 10 | `INATIVOS - GERAL`, `REATIVOS - GERAL`, `NOVOS`, `PROSPECTS - GERAL`, `RECORRENTES (ATIVOS) - GERAL` e as variantes regionais por `Type` | Existem; filtro por `Type` manual | **Não mexe** | São os públicos que o time usa hoje pelo rótulo manual. Trocar o filtro mudaria público em uso sem decisão do cliente (P6). A divergência fica visível no relatório novo |
| 11 | Relatório de classificação para o negócio (por conta, sem dado pessoal) | Não existe. O único relatório de Account com `Inactive__c` (`Volume_Inativos/Novo_relat_rio_Contas`, tabular, filtro de data de criação desde 2025-06-16, sem Potencial) não atende | **Cria** `CLASSIFICACAO_CONTAS_POR_CLASSE` | Ajustar o existente mudaria o propósito dele (filtro de criação), e ele não é da demanda |
| 12 | Público **Potencial** para o MC | Não existe relatório por compra vazia; os de `PROSPECTS` usam `Type` | **Cria** `POTENCIAIS_SEM_COMPRA` | Único público que falta para as 3 classes |
| 13 | `SAZONAIS - MG (DUPLICADO - REVISAR)`, `Cpia_de_*` | Existem | **Não mexe** | Fora do escopo; duplicidade é do cliente |
| 14 | Agente `SFAgent2` | Existe (`BotDefinition`, `InternalCopilot`) | **Não mexe** | A análise tirou do escopo; o campo novo fica disponível para uma demanda futura do agente (eplast-ent-11) |
| 15 | Flows `ScheduledFlowOpportunity`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, `AccountUpdateEconomicGroup`, `Custom_Stale_Opp` | Existem | **Não mexe** (CA-08) | Nada de automação nesta demanda |
| 16 | Campanha / membro de campanha | Existe o objeto; 0 registros na dev | **Não cria** | Público via relatório (seção 6) |
| 17 | Conector `et4ae5` e Marketing Cloud | Instalado (17 objetos) | **Não mexe** (regra 2) | Seção 6 |

**Componentes que o build cria (lista fechada):**

| Tipo | API name | Detalhe |
|---|---|---|
| CustomField | `Account.RelationshipClass__c` | Rótulo "Classe de Relacionamento"; fórmula Texto (fórmula da seção 1); `formulaTreatBlanksAs` = `BlankAsBlank`; descrição: "EPLAST-37. Classe derivada: Potencial (sem compra ganha), Inativo (Inactive__c), Ativo. Não grava; não usar o campo Type como fonte." Ajuda: mesma regra em linguagem de usuário |
| Report | `MARKETINGCLOUD/CLASSIFICACAO_CONTAS_POR_CLASSE` | Rótulo "CLASSIFICAÇÃO - CONTAS POR CLASSE"; tipo `AccountList` (o tipo existe na org: `Novo_relat_rio_Contas` usa); formato **Resumo**, agrupado por `RelationshipClass__c` e depois por `TYPE`; colunas: nome da conta, proprietário, UF de cobrança, `LastPurchase__c`, `Inactive__c`, `TYPE`, `Ranking__c`. **Sem e-mail, telefone, endereço completo nem CPF/CNPJ** (CA-10). Sem filtro de data. `scope`: copiar de um `AccountList` existente; `organization` primeiro, `team` se recusado (doutrina) |
| Report | `MARKETINGCLOUD/POTENCIAIS_SEM_COMPRA` | Rótulo "POTENCIAIS - SEM COMPRA"; tipo `ContactList`, `scope` `organization`, tabular, como os vizinhos da pasta; filtros `Account.RelationshipClass__c` igual a `Potencial` e `EMAIL_OPT_OUT = 0` (mesmo padrão de opt-out dos 58); colunas: Id do contato, nome, sobrenome, nome da conta, `RelationshipClass__c`, proprietário. **Sem e-mail, telefone e endereço** (premissa PA-13) |

Os dois relatórios ficam na pasta existente `MARKETING CLOUD` (premissa PA-14). Nenhuma pasta nova.

## 3. Permissões

- **Leitura do campo novo:** espelhar exatamente quem lê `Account.Inactive__c` hoje (17 entradas de `FieldPermissions`, perfis e permission sets, recon seção 5). O build lista as entradas com `SELECT Parent.Name, Parent.IsOwnedByProfile FROM FieldPermissions WHERE Field = 'Account.Inactive__c' AND PermissionsRead = true` e implanta só o `fieldPermissions` do campo novo (somente leitura; fórmula não tem edição) nesses perfis e permission sets. Quem já vê a inatividade passa a ver a classe; ninguém ganha acesso a outro dado.
- Nenhum perfil, permission set ou atribuição novos. Nenhuma alteração de layout de página (seção 8).
- Os perfis comerciais duplicados do assessment (achado 8) não estão entre os que leem `LastPurchase__c` hoje (recon); o espelhamento mantém essa situação, não a corrige.
- Acesso à pasta `MARKETING CLOUD` não foi verificado (recon, "Não confirmei" 9): quem já abre os públicos de lá abre os dois novos. Não se altera compartilhamento de pasta.

## 4. Ordem de execução e impacto em Account, Opportunity e Order

**Onde a solução entra: em lugar nenhum da cadeia de gravação.** Campo fórmula é calculado na leitura (tela, relatório, API); não é gravado, não muda `SystemModstamp` e não dispara nada.

| Objeto | Automação existente (recon) | O que esta demanda faz | O que não pode quebrar |
|---|---|---|---|
| Account | `AccountBefore` (SBQQ), `AccountTrigger` (CNPJ), Flows `AccountTriggered` e `UpdateParentAccountUsedLimit`, `AccountUpdateEconomicGroup` (agendado), 6 validation rules | Só acrescenta o campo fórmula. Nenhuma gravação | Nada muda na ordem. A ordem interna `AccountBefore` × `AccountTrigger` (não confirmada no recon) **não importa para esta solução** e por isso não foi testada |
| Opportunity | `OpportunityBefore`/`OpportunityAfter` (SBQQ), `OpportunityTrigger`, `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity` | Nada | O roll-up de `LastPurchase__c` continua como está. Pela ordem de execução da plataforma (skill `salesforce-doutrina`), a atualização do roll-up passa o Account pai pelo procedimento de gravação, então a cadeia de Account já roda hoje a cada Oportunidade ganha. **É comportamento existente; a demanda não o altera nem depende dele** além de o roll-up continuar calculando |
| Order | Automação própria e CPQ (achado 1) | Nada | P7: pedido não entra na classe |

**CPU e escala:** nenhuma transação nova. O custo novo é de leitura: a fórmula é calculada por linha no relatório e não é indexável. Para o volume de contas de uma indústria B2B isso é desprezível; na QA o QA confere o tempo do relatório com o volume real (só totais). O risco de CPU com conta pai e muitos filhos (achado SOMOSAGILITY-10) não se aplica: não há automação por registro.

**Risco para o teste, não para a solução:** a massa sintética da dev passa pela cadeia completa. Criar Account dispara `validateCNPJ` (before) e `fillAccountWithCNPJInfo` (after insert); criar Oportunidade `Fechado/Ganho` dispara CPQ, `OpportunityTrigger`, os Flows de Opportunity e o roll-up, que reprocessa Account. O verificador lê as fórmulas das 6 validation rules de Account e o `validateCNPJ` do `AccountTriggerHandler` antes de montar o script, e preenche todo campo exigido (doutrina, "Armadilhas").

## 5. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Campo novo em Account é mudança de modelo de dados** | Média | Escalado ao arquiteto humano neste gate. Reversível: excluir o campo e os 2 relatórios que o usam. Plano B na seção 9 |
| R2 | Classe diverge do `Type` manual (ex.: `Type = Prospect` com compra recente). O time pode estranhar ver duas respostas | Média | Intencional (P6, CA-06). O relatório de classificação agrupa por classe e depois por `Type`, deixando a divergência à vista para o cliente decidir |
| R3 | **Fórmula que depende de hoje não "muda" o registro.** Uma conta que passa de Ativo para Inativo pelo tempo não tem o registro modificado. Integração que lê só registros alterados (como a sincronização de dados do conector MC, que se baseia em data de modificação) pode ficar com a classe velha | Média | Público do MC vem dos relatórios, avaliados na hora da importação (seção 6). Quem opera o MC não deve depender do valor sincronizado de `RelationshipClass__c` nem de `Inactive__c`; se usar dado sincronizado, calcula a partir de `LastPurchase__c`. Comportamento da sincronização é afirmação de plataforma, a confirmar por quem opera o MC |
| R4 | `LastPurchase__c` depende só de Oportunidade ganha; pedido do Protheus não conta (P7). Cliente que compra sem Oportunidade aparece Potencial ou Inativo | Média | Premissa P7 validada na homologação com amostra agregada. Mudar a origem é demanda própria |
| R5 | `Oportunidade Fechado/Ganho` com data de fechamento futura dá Ativo na classe e fica fora de `COMPRA - ÚLTIMOS 90 DIAS` (que vai até hoje) | Baixa | Mesmo comportamento de `Inactive__c` hoje (premissa PA-15) |
| R6 | Relatórios por metadata erram de formato (achado EPLAST-39) | Baixa | Partir do XML de `COMPRA_ULTIMOS_90_DIAS` (ContactList) e de `Novo_relat_rio_Contas` (AccountList); duas recusas no mesmo campo, tira o item e registra no plano |
| R7 | Dev vazia (0 contas, 0 oportunidades) e sem `fixtures/` na pasta do cliente | Média (esforço) | Massa sintética criada pelo verificador e gravada em `fixtures/` (regra 6). Usuário de teste ativo `005bJ00000piKAaQAM` (recon). Dado criado é apagado pelo próprio script ao fim |
| R8 | QA (`eplast--qas`) pode ter metadata diferente da dev (recon, "Não confirmei" 8) | Baixa | O deploy na QA pela esteira acusa campo ou relatório ausente. Na QA, só totais agregados por classe |

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca segmentação e reativação. Nada é feito no Marketing Cloud (regra 2); o build entrega só o lado do CRM.

- **Dados que o MC vai ler e onde ficam no CRM:**
  - `Account.RelationshipClass__c` — classe (Potencial, Inativo, Ativo). Novo.
  - `Account.LastPurchase__c` — data da última compra ganha. Existe. É o dado estável para o MC calcular janela própria (R3).
  - `Account.Inactive__c` — inatividade acima de 90 dias. Existe.
  - `Account.Ranking__c` (porte) e `Account.Type` (rótulo manual) — para cruzamento. Existem.
  - `Contact.AccountId` — liga o contato à classe da conta. Padrão.
- **Como o público fica identificável no CRM (relatórios na pasta `MARKETING CLOUD`, todos com opt-out de e-mail excluído):**

  | Classe | Relatório | Situação |
  |---|---|---|
  | Potencial | `POTENCIAIS - SEM COMPRA` | Novo |
  | Ativo | `COMPRA - ÚLTIMOS 90 DIAS` | Existe, reaproveitado |
  | Inativo | `SEM COMPRA - 91 A 180 DIAS` + `SEM COMPRA - 181 A 365 DIAS` + `SEM COMPRA - MAIS DE 365 DIAS` | Existem, reaproveitados; as faixas servem para reativação escalonada |

  Visão de negócio, por conta e sem dado pessoal: `CLASSIFICAÇÃO - CONTAS POR CLASSE` (novo). Campanha e membro de campanha não são usados nesta demanda (0 registros na dev); se o MC pedir público por campanha, é demanda própria.
- **O que o MC devolve e onde é gravado:** nada nesta demanda. Retorno de envio fica nos objetos do próprio conector `et4ae5` (ex.: `et4ae5__IndividualEmailResult__c`, existe), como decidido na EPLAST-43 (PA-05, histórico via RAG). Nenhum campo de retorno é criado.
- **Consentimento e opt-out:** `Contact.HasOptedOutOfEmail` (padrão; o relatório novo filtra como os 58 existentes) e `Contact.et4ae5__HasOptedOutOfMobile__c` (existe, do conector) para SMS. Esta demanda não altera nenhum dos dois. Respeitar opt-out no envio é de quem opera o MC.
- **O que fica para quem opera o MC:** importar os relatórios acima como público (ou montar o público pelos campos listados); confirmar se a importação precisa do e-mail como coluna do relatório (PA-13) ou lê do contato sincronizado; não depender do valor sincronizado de campo fórmula por data (R3); criar jornada, envio e cadência de reativação e nutrição. Nada disso é feito pela esteira.

## 7. Riscos do assessment que tocam a demanda

| Achado | Tratamento |
|---|---|
| 1 · Automação concorrente em Account/Opportunity/Order (alta) | Não se aplica à solução: nenhuma automação nova, nenhuma gravação (seção 4). Pesa só na massa de teste (R7) |
| 2 · Cobertura Apex ~10% (alta) | Não se aplica: sem Apex. CA-12 fica sem objeto |
| 3 · Validation rules do Order | Não se aplica: Order não é tocado |
| 4 · Campos custom sem descrição (média) | O campo novo nasce com descrição e ajuda. `LastPurchase__c` e `Inactive__c` continuam sem descrição: preencher seria alterar campo em uso fora do escopo; fica como recomendação ao cliente |
| 5, 9, 10 · Convenção de teste, versão de API, nome de trigger duplicado | Não se aplicam: sem Apex nem trigger |
| 6 · Alias "qa" na dev | Resolvido pela regra 5 da Eplast |
| 7, 8 · Perfis | Não se cria perfil; o espelhamento de FLS não amplia acesso (seção 3) |

**Demandas relacionadas:** a EPLAST-36 desenhou os 4 públicos por `LastPurchase__c` (RAG: `demandas/EPLAST-36/03-design.md`, item 8); eles existem na org hoje e são reaproveitados aqui, sem duplicar. A EPLAST-36 também rejeitou gravar classe em Account: este desenho mantém isso (fórmula, sem gravação). A eplast-ent-11 passa a ter um campo pronto para "quem está sem comprar". A EPLAST-47 (ranking) não é tocada.

## 8. O que NÃO será feito

- Flow, trigger, Apex ou qualquer gravação em Account, Opportunity ou Order.
- Alteração de `LastPurchase__c`, `Inactive__c`, `Type`, `Ranking__c` ou dos relatórios existentes da pasta `MARKETING CLOUD` (inclusive os por `Type`).
- Layout de página e list view de Account (premissa PA-16).
- Agente `SFAgent2`: nenhum tópico ou ação.
- Qualquer coisa no Marketing Cloud ou na configuração do conector.
- Campanha, membro de campanha, painel.
- Contar pedido do Protheus como compra.

## 9. Plano B, se o gate recusar o campo novo

Sem `RelationshipClass__c`: o relatório de classificação vira três visões filtradas sobre `LastPurchase__c` (vazio = Potencial; `Inactive__c` verdadeiro = Inativo; falso = Ativo) e `POTENCIAIS - SEM COMPRA` filtra `LastPurchase__c` vazio. Mesmo resto do desenho; esforço cai cerca de 1 h; perde-se a definição única (R2 fica mais difícil de ver).

## 10. Versões a criar (alterar o que já existe)

Nenhuma. A demanda não altera Flow, agente Agentforce nem classe Apex existentes, então não há versão nova nem passo de ativação. O campo e os 2 relatórios são novos (não substituem nada). Nos perfis e permission sets do espelhamento, o build só acrescenta a permissão de leitura do campo novo.

## 11. Critérios de aceite: ajustes ao que a análise trouxe

- **CA-07** passa a ler: não há Apex, trigger nem Flow novos; o único campo novo em Account é a fórmula `RelationshipClass__c`, sem gravação.
- **CA-01 a CA-06** são verificados pelo valor de `RelationshipClass__c` e pelo relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` (Analytics API, só rótulos e contagens). CA-04 exercita 90 e 91 dias; CA-01 registra também o valor de `Inactive__c` com data vazia (fecha o "Não confirmei" 1 do recon, sem mudar a fórmula).
- **CA-10** vale para os 2 relatórios novos. Os existentes reaproveitados continuam com e-mail, telefone e endereço como já estão: são listas de público do MC que esta demanda não altera; a decisão de enxugá-los é do cliente.
- **CA-12** sem objeto (sem Apex).

## 12. Premissas assumidas (validar na homologação)

Herdadas da análise, sem mudança: **P1** (escopo), **P2** (Potencial = sem compra ganha), **P3** (Inativo = mais de 90 dias, via `Inactive__c`; confirmado no recon: `> 90`), **P4** (Ativo), **P6** (`Type` não é fonte), **P7** (compra = Oportunidade ganha; confirmado no recon), **P8** (Ranking fora), **P9** (reaproveitar antes de criar), **P10** (dado sintético).

Alterada pelo design:
- [x] **P5 · Classe derivada, sem gravação em Account.** Pergunta: a classe precisa ficar num campo? Decisão: sim, como **fórmula** somente leitura (`RelationshipClass__c`), que não grava nada. Evidência: duas definições concorrentes na org (recon, seção 1); fórmula é configuração nativa, fora da ordem de execução (doutrina). Como mudar: excluir o campo e aplicar o plano B (seção 9).

Novas:
- [x] **PA-11 · Nomes e rótulos da classe.** Pergunta: como chamar o campo e os valores? Decisão: API `RelationshipClass__c` (padrão da org: nomes em inglês, sem prefixo, como `LastPurchase__c` e `Inactive__c`; o `CLAUDE.md` do cliente não define prefixo), rótulo "Classe de Relacionamento", valores "Potencial", "Inativo", "Ativo". Evidência: lista de campos de Account nesta sessão. Como mudar: trocar rótulo ou texto na fórmula (o filtro do relatório de Potencial acompanha).
- [x] **PA-12 · Público do MC por relatório, não por campanha.** Pergunta: como o MC recebe cada classe? Decisão: pelos relatórios da pasta `MARKETING CLOUD`, avaliados na hora da importação. Evidência: é o padrão que a org já usa (58 relatórios de público, todos `ContactList` com opt-out); 0 campanhas na dev. Como mudar: criar campanhas-público é demanda própria.
- [x] **PA-13 · Relatório de Potencial sem e-mail.** Pergunta: o público novo traz e-mail e telefone como os vizinhos? Decisão: não; traz Id do contato, nome e conta. Evidência: CA-10 da análise; minimização de dado (LGPD). Como mudar: se quem opera o MC precisar do e-mail como coluna para importar, acrescentar a coluna `EMAIL` (mudança de uma linha, que volta a passar pelo gate).
- [x] **PA-14 · Pasta dos relatórios novos.** Pergunta: onde publicar? Decisão: pasta existente `MARKETING CLOUD`. Evidência: é onde estão os públicos e quem os usa; doutrina "não sobrepor" (nenhuma pasta nova). Como mudar: mover o relatório de pasta pela tela.
- [x] **PA-15 · Compra com data futura.** Pergunta: Oportunidade ganha com fechamento no futuro conta como Ativo? Decisão: sim, como `Inactive__c` já trata hoje. Evidência: fórmula de `Inactive__c` (recon). Como mudar: acrescentar condição de data na fórmula.
- [x] **PA-16 · Sem campo na página da conta.** Pergunta: a classe aparece na ficha da conta? Decisão: não nesta demanda; fica no relatório e disponível para lista e MC. Evidência: padrão de menor impacto (a org tem vários layouts; alterar layout em uso foge do pedido). Como mudar: o administrador arrasta o campo para o layout, sem build.
- [x] **PA-17 · Quem enxerga a classe.** Pergunta: quais perfis leem o campo? Decisão: os mesmos que leem `Inactive__c` hoje. Evidência: `FieldPermissions` (recon, seção 5). Como mudar: ajustar FLS do campo pela tela.

## 13. Pendências reais

Nenhuma pendência `- [ ]`. Nenhuma pergunta caiu no caso 3 da regra 4: tudo é reversível (um campo fórmula e dois relatórios, sem gravação) e a org indica o caminho. O único ponto que depende de decisão humana é o campo novo em Account (R1), e ele é decidido neste gate.

## 14. Para o build e a verificação

- Build: `builder-declarativo`, branch `feature/EPLAST-37`. Retrieve de referência (os XML de relatório citados) fica em `/tmp`, não em `force-app/`. Deploy com `--dry-run` antes do real.
- Verificação na dev: massa sintética por script em `fixtures/` (contas com: nenhuma Oportunidade; ganha há 30, 90, 91 e 120 dias; `Type = Prospect` com ganha recente; uma Potencial que recebe Oportunidade ganha durante o teste, para CA-05), contatos sem dado pessoal real, usuário `005bJ00000piKAaQAM` como proprietário. Leitura pelo valor do campo e pela Analytics API, só rótulos e contagens. O script apaga o que criou.
- QA: só totais agregados por classe no relatório de classificação; nenhum registro lido.

**Estimativa de esforço:** 8–14 h
Mudança em relação à análise (6–12 h): +1 h pelo campo fórmula e espelhamento de FLS em perfis e permission sets; +1 a 2 h pela massa de teste, porque a dev está vazia, não há `fixtures/` e criar Oportunidade ganha passa por CPQ, triggers e validation rules de Account. Em contrapartida, caem os "2 a 5 relatórios" para 2 novos, porque os 4 públicos por data de compra já existem e são reaproveitados sem mudança.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
