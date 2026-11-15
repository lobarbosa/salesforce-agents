# EPLAST-46 — Design: sugestão de campanhas pelo comportamento dos clientes

**Org conectada nesta sessão:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected, Org Id `00DHa000006vfMLMAY`; é a `eplast--qa` da Eplast, dev da esteira pela regra 5). Só metadata e contagens agregadas; nenhum DML, nenhum registro de cliente lido. Nada consultado nem feito no Marketing Cloud.
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, `00-preflight.md` (sem bloqueios, sem outra demanda nos mesmos componentes).
**Tipo:** projeto · **Complexidade:** M

---

## 1. Decisão

**Uma ação nova de leitura no `SFAgent2` (versão nova do planner, v9), que chama um Flow autolançado novo, sem DML, que monta a lista de campanhas sugeridas para uma conta a partir do que a org já calcula:** `Account.Inactive__c` (reativação) e os sinais de cruzada `CommercialSignal__c` da EPLAST-33 (ampliação de mix), com contagem de contatos elegíveis por canal respeitando opt-out. O catálogo (ordem de prioridade, nome e público de cada campanha) fica em custom metadata. O público que o Marketing Cloud importa continua sendo relatório da pasta `MARKETING CLOUD`; cria-se um único relatório novo, para o público de ampliação de mix.

Nível: **declarativo (Flow)**, sem Apex.

### 1.1 Achado que muda a análise (confirmado nesta sessão)

O recon não listou, mas a org já tem o motor de cruzada da EPLAST-33 (rodada anterior; a demanda está em `backlog` no Squad OS, mas os componentes estão na dev):

| Item | Confirmado (comando) |
|---|---|
| Objeto `CommercialSignal__c` (master-detail de Account): `Type__c` (`Recuperacao`, `NuncaComprou`, `QuedaVolume`, `AltaVolume`, `Cruzada`), `Product__c`, `Reason__c`, `DaysWithoutPurchase__c`, `LastPurchaseDate__c`, `CalculationDate__c`, `SignalKey__c` e campos de moeda | `FieldDefinition` + `sf sobject describe`; `COUNT()` = 0 na dev |
| `CommercialSignalSetting__mdt` registro `Default`: grupo `Industry`, janela 12 meses, exclusão de produto comprado em **180 dias**, grupo mínimo 5, participação mínima 30%, até 10 por conta, recuperação 60 dias, status de compra `Faturamento;Concluido` | `SELECT ... FROM CommercialSignalSetting__mdt` (configuração, não dado de cliente) |
| Classes `CommercialSignalBatch`, `CommercialSignalGroupStatsBatch`, `CommercialSignalScheduler`, `CommercialSignalService` (+ testes) | `ApexClass` |
| Relatório `CommercialSignals_ByAccount` ("Sinais Comerciais por Conta", Summary, pasta `EPLAST33 Sinais Comerciais`) | `Report` |
| Permission set `PS_Comercial_SinaisComerciais` | `PermissionSet` |
| Job agendado `%Signal%` | `CronTrigger` = 0 na dev (sinais não são recalculados sozinhos hoje) |

A análise pedia "família que clientes do mesmo setor compram e a conta não comprou, excluindo o comprado em 180 dias" (seção 3, item 2). É exatamente a regra `Cruzada` da EPLAST-33 (RAG: `demandas/EPLAST-33/01-analise.md`, PA-7, CA-08/09), com grupo `Industry` em vez de `Sector__c` e granularidade de produto. Pela regra 3 da conta, **não se cria uma segunda regra de cruzada**: a sugestão lê os sinais existentes (premissa PA-46-01).

Outros fatos confirmados nesta sessão que pesam na decisão:
- `Account.LastPurchase__c` = resumo **MAX de `Opportunity.CloseDate`** com filtro `StageName = Fechado/Ganho` (`CustomField.Metadata`). `Account.Inactive__c` = `IF((today() - LastPurchase__c) > 90, true, false)`; conta sem oportunidade ganha fica `false`.
- `Product2.Family` preenchido em 118 de 1042 produtos; `Product2.Group__c` (Texto 255, rótulo "Grupo") preenchido em 910, com os mesmos 5 códigos (`PREF`, `TAMP`, `RESI`, `ALCA`, `GPET`); 132 produtos sem nenhum dos dois. "Família" na sugestão = `Product2.Group__c` (PA-46-03).
- Flow `Account_Agente_ProximaAcao`: versão ativa 2, última 2 (`FlowDefinition`).
- Relatórios de reativação existentes: `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS` (pasta `MARKETING CLOUD`, Tabular), desenhados sobre `LastPurchase__c` (RAG: `demandas/EPLAST-36/03-design.md`; `demandas/EPLAST-37/03-design.md`). Filtros não relidos nesta sessão.

### 1.2 Por que não o nível acima (configuração pura)

- Relatório resolve o **público** (quem recebe), mas não a **sugestão por conta** com motivo, prioridade e contagem de elegíveis por canal (CA-01 a CA-06). Fórmula em Account não enxerga `CommercialSignal__c` nem conta contatos por opt-out, e gravar o resultado num campo foi descartado (PA-03, sem gravação).
- Roll-up de `CommercialSignal__c` em Account (master-detail permite) daria só "tem cruzada sim/não", e seria campo novo gravado em Account, com a concorrência de triggers do CPQ (achado 1 do assessment). Não se justifica para a v1.

### 1.3 Por que Flow e não Apex

- A regra é por **uma conta por chamada**: 1 leitura de Account, até 10 sinais (`CrossSellMaxPerAccount__c`), 2 contagens de contato, 1 leitura do catálogo (≤ 5 registros). Nada disso pede agregação SQL, rollback, callout nem recursão (critérios da skill `salesforce-doutrina`).
- A agregação pesada (participação de cada produto no grupo `Industry`) já está feita pelo batch da EPLAST-33. Recalcular isso em Apex nesta demanda seria duplicar o motor.
- O padrão do `SFAgent2` nesta org é ação com alvo Flow (`ProximaAcaoCliente_EPLAST27` → `Account_Agente_ProximaAcao`). Seguir o mesmo padrão mantém a manutenção num lugar só.
- Gatilho para descer a Apex (só com novo gate): se o cliente pedir exclusão por **família** comprada (e não por produto), o que exige ler `OrderItem` por conta com agregação; ou se a medição passar de 70% de algum limite (seção 6).

### 1.4 Ação nova versus estender `ProximaAcaoCliente_EPLAST27` (alternativa que a análise deixou)

| Alternativa | Prós | Contras | Decisão |
|---|---|---|---|
| A. Versão 3 do Flow `Account_Agente_ProximaAcao` com saída nova de campanha, mesma ação | Uma ação só | Muda o contrato de uma ação já homologada na EPLAST-27 (um `actionCode` e uma `message` que o agente mostra "sem acrescentar"); reativa a discussão de `RestrictToOwner__c` e A1/A2, que não são campanha; ativar a v3 troca o comportamento da próxima ação de quem usa | Rejeitada |
| B. **Ação nova `SugestaoCampanha_EPLAST46` no mesmo tópico do `SFAgent2`, alvo Flow novo** | Não altera nada do que está ativo; reaproveita o mesmo critério de reativação (`Inactive__c`) que o caso A3 da EPLAST-27 usa, então as duas ações não divergem; permissão própria de Marketing; desfazer = desativar a v9 | Mais uma ação no planner | **Escolhida** |

A regra 3 da conta pede estender tópico ou ação, não criar agente. A opção B estende o tópico `insights_comerciais` do `SFAgent2` existente. A PA-07 da análise previa essa troca ("se o arquiteto mostrar que a ação não serve, cria-se ação nova com nome próprio"); fica registrada como PA-46-02.

---

## 2. Regra da sugestão (como o Flow decide)

Entrada: `recordId` (Id da conta). Saídas: `suggestionCode` (a de maior prioridade), `message` (texto da lista completa).

1. **Acesso:** se o usuário não tem a custom permission `SugestaoCampanha_EPLAST46` → `suggestionCode = NO_ACCESS`, mensagem de acesso negado, **sem ler a conta** (CA-09).
2. **Conta:** lê `Inactive__c`, `LastPurchase__c`, `Industry`, `Name`. Conta não encontrada ou sem acesso pelo compartilhamento → `NODATA`.
3. **Reativação** (`REATIVACAO`): `Inactive__c = true`. Motivo: "sem compra há N dias" (N = hoje − `LastPurchase__c`). Público indicado pela faixa: 91–180 → `SEM COMPRA - 91 A 180 DIAS`; 181–365 → `SEM COMPRA - 181 A 365 DIAS`; acima → `SEM COMPRA - MAIS DE 365 DIAS`.
4. **Ampliação de mix** (`AMPLIACAO_MIX`): existe ao menos um `CommercialSignal__c` da conta com `Type__c = Cruzada`. Motivo: lista dos grupos (`Product__r.Group__c`, sem repetir; produto sem grupo aparece como "sem grupo") e quantidade de produtos sugeridos. A exclusão de produto comprado nos últimos 180 dias já vem do sinal (`CrossSellRecentDays__c`). Data do cálculo = `CalculationDate__c` mais recente, mostrada na mensagem. Público: relatório novo `AMPLIACAO MIX - CONTATOS` (seção 3).
5. **Sem histórico** (`SEM_HISTORICO`): `LastPurchase__c` vazio **e** nenhum sinal `Cruzada`. Não sugere reativação (CA-06).
6. **Nenhuma** (`NONE`): conta com compra recente e sem sinal de cruzada.
7. **Elegíveis por canal**, para cada sugestão: contagem de contatos da conta com `HasOptedOutOfEmail = false` e `Email` preenchido (e-mail) e com `et4ae5__HasOptedOutOfMobile__c = false` e `MobilePhone` preenchido (mensagem). Zero num canal → "sem contato elegível para <canal>" (CA-03, CA-04). Só a contagem sai; nenhum e-mail, telefone ou nome de contato.
8. **Ordem:** pela `Priority__c` do catálogo (padrão: reativação 1, ampliação de mix 2). Item com `Active__c = false` no catálogo não é avaliado.
9. **Fora da mensagem:** valores de compra (`LastMonthPurchaseValue__c`, `CurrentPeriodAmount__c`, `BasePeriodAmount__c`), CPF/CNPJ, e-mail, telefone (CA-11).
10. **Nutrição de lead:** não entra na ação (a ação é por conta e lead não pertence a conta). O público de nutrição continua no relatório existente `LEADS - PROSPECÇÃO PRIORIZADA` (PA-46-05).

---

## 3. Componentes — item a item (regra 3)

### Reaproveita sem alterar

| Componente | Uso |
|---|---|
| Agente `SFAgent2` (`BotDefinition` único; v8 ativa) | Base da v9. Nenhum agente novo |
| Ações `IdentificarConta_*`, `ProximaAcaoCliente_EPLAST27_*`, `ConsultarPedidos_*`, `AgregacaoPedidos_*`, `CriarTarefa_EPLAST29`, `IdentificarRegistro_EPLAST29`, `ResumoReuniao_EPLAST34_*` | Copiadas para a v9 só com sufixo de versão, sem mudar conteúdo. `IdentificarConta` resolve o nome da conta antes da ação nova |
| Flow `Account_Agente_ProximaAcao` (v2 ativa) | Não alterado. O critério de reativação da ação nova é o mesmo do caso A3 dele (`Inactive__c`) |
| `Account.Inactive__c`, `Account.LastPurchase__c`, `Account.Industry` | Leitura. Nenhum campo novo em Account |
| `CommercialSignal__c`, `CommercialSignalSetting__mdt`, classes `CommercialSignal*` (EPLAST-33) | Leitura dos sinais `Cruzada`. Nenhuma alteração no motor nem nos limiares |
| `Product2.Group__c` | Nome do grupo do produto sugerido |
| `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__HasOptedOutOfMobile__c`, `Email`, `MobilePhone` | Filtro de elegibilidade por canal (só contagem) |
| Relatórios `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`, `LEADS - PROSPECÇÃO PRIORIZADA`, `CommercialSignals_ByAccount` | Públicos já existentes, citados pela sugestão. Não alterados |
| `NextBestActionSetting__mdt` | Não usado nem alterado (não tem campo de campanha; misturar o catálogo nele acoplaria à EPLAST-27) |

### Cria

| Componente | API name | Detalhe |
|---|---|---|
| Custom metadata type (**ver seção 9, decisão do arquiteto humano**) | `CampaignSuggestionSetting__mdt` | Campos: `Priority__c` (Número 2,0), `AudienceReport__c` (Texto 120: nome do relatório que o Marketing Cloud importa), `Active__c` (Checkbox). Registros: `REATIVACAO` (1, "SEM COMPRA - faixa"), `AMPLIACAO_MIX` (2, `AMPLIACAO MIX - CONTATOS`). Proteção: pública (não `protected`) |
| Flow autolançado novo | `Account_Agente_SugestaoCampanha` | Sem gatilho, sem DML, sem e-mail. `runInMode = SystemModeWithSharing` (respeita o compartilhamento de conta; o acesso à funcionalidade é pela custom permission). Entrada `recordId`; saídas `suggestionCode`, `message`. Nasce **Active** (é Flow novo, não substitui nada — skill `salesforce-doutrina`). Descrição preenchida |
| Custom permission | `SugestaoCampanha_EPLAST46` | Testada no início do Flow |
| Permission set novo | `PS_Marketing_SugestaoCampanha` | Custom permission acima; leitura de `CommercialSignal__c` e campos `Type__c`, `Product__c`, `CalculationDate__c`; leitura de `CampaignSuggestionSetting__mdt`; acesso ao Flow. Não dá escrita em nada |
| Ação do agente | `SugestaoCampanha_EPLAST46_v9` (`GenAiFunction`, alvo `flow` `Account_Agente_SugestaoCampanha`) | Descrição: "lista campanhas sugeridas para uma conta (reativação, ampliação de mix), com motivo, público e contatos elegíveis por canal; não envia nada" |
| Versão nova do planner | `SFAgent2_v9` (+ `BotVersion` v9), **inativa** | Cópia da v8 baixada da org, sufixos `_v8` → `_v9`; acrescenta a ação acima e a instrução `instruction1_EPLAST46_v9` no tópico `insights_comerciais_*_v9`: "Quando pedirem campanha, público ou ação de marketing para uma conta, identifique a conta com `IdentificarConta` e chame `SugestaoCampanha`. Mostre a `message` sem acrescentar, sem inventar campanha e sem oferecer envio. Envio é feito pelo Marketing Cloud" |
| Relatório novo | `AMPLIACAO_MIX_CONTATOS` ("AMPLIACAO MIX - CONTATOS"), pasta `MARKETING CLOUD`, Tabular | Tipo Contatos e Contas; filtro cruzado "Contas com `CommercialSignal__c`" `Type__c = Cruzada`; `HasOptedOutOfEmail = false`. Colunas: Id do contato, Id da conta, nome da conta, `Industry`. Ver incerteza I-04 (filtro cruzado) |
| Fixture | `fixtures/` (script novo, nome pela skill `padrao-entrega`) | Ver seção 7 |

### Altera

Nada que já existe é editado no lugar. O planner v8 e o Flow `Account_Agente_ProximaAcao` v2 seguem ativos e intocados.

### Deprecia

Nada.

### Versões e ativação (skill `salesforce-doutrina`, "Alterar o que já existe")

| Item | Versão nova | Continua ativo | Passo de ativação | Desfazer |
|---|---|---|---|---|
| `SFAgent2` | v9, implantada **inativa**, a partir da **v8 ativa baixada da org** (não do repositório; achado EPLAST-34: o `.agent` local pode estar defasado) | v8 | Dev: `verificador` ativa a v9 para verificar e registra em `04-verificacao.md`. QA: o `qa` ativa a v9 e registra qual entrou e qual saiu em `05-testes.md` | Ativar a v8 |
| `Account_Agente_SugestaoCampanha` | v1 nova, Active | — | Nenhum (não substitui nada) | Desativar o Flow; sem a v9 ativa ninguém o chama |

Se outra demanda tiver criado uma v9 do `SFAgent2` antes do build, o build parte da última versão existente e cria a seguinte (nunca duas demandas na mesma versão).

---

## 4. Permissões

- **Novo:** `PS_Marketing_SugestaoCampanha` (seção 3). Atribuição a Marketing e Comercial (PA-04) é passo do admin da Eplast depois da entrega; a esteira não atribui a usuário real.
- **Pré-requisito do usuário final:** já ter acesso ao `SFAgent2` (permission sets existentes do agente, não alterados) e leitura de Account e Contact pelo perfil.
- **Não alterados:** `PS_Marketing_AnaliseCampanhas`, `PS_Marketing_Publicos`, `PS_Comercial_ProximaAcao`, `PS_Comercial_SinaisComerciais`. O conteúdo deles não pôde ser lido pelo recon (`ObjectPermissions`/`SetupEntityAccess` indisponíveis); somar acesso a eles às cegas poderia dar mais do que se quer a quem já os tem. Um permission set novo e aditivo é mais fácil de desfazer.
- **Relatório novo:** visível a quem já acessa a pasta `MARKETING CLOUD` (compartilhamento da pasta não alterado). Quem lê o relatório precisa de leitura em `CommercialSignal__c` para o filtro cruzado valer: `PS_Comercial_SinaisComerciais` ou o novo PS.
- **Usuário de teste (regra 6):** `005bJ00000piKAaQAM` (ativo, Administrador do sistema) é proprietário dos registros de teste. Para CA-09: sem a custom permission atribuída → `NO_ACCESS`; com o PS novo atribuído → sugestão. Atribuir o PS novo ao usuário de execução da esteira na dev segue a regra da esteira de ajuste do próprio usuário de execução (#191); perfil e papel dele não são alterados. Se a atribuição não for permitida naquela org, o caminho positivo fica provado e o negativo é registrado como inconclusivo, não inventado.

---

## 5. Preparação do Sales Cloud para o Marketing Cloud

Regra 2 da conta. A esteira não conecta, não configura nem cria nada no Marketing Cloud.

**a) Dados que o Marketing Cloud lê e onde ficam no CRM**

| Dado | Objeto.campo | Estado |
|---|---|---|
| Recência de compra | `Account.LastPurchase__c` (MAX `Opportunity.CloseDate`, `StageName = Fechado/Ganho`), `Account.Inactive__c` | Existe, confirmado |
| Segmento | `Account.Industry` (grupo da cruzada), `Account.Sector__c`, `Account.Subsector__c` | Existe |
| Sinal de ampliação de mix | `CommercialSignal__c` (`Type__c = Cruzada`, `Product__c`, `Reason__c`, `CalculationDate__c`) com `Product2.Group__c` | Existe (EPLAST-33) |
| Contato e canal | `Contact.AccountId`, `Email`, `MobilePhone`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | Existe |
| Campo novo para o Marketing Cloud | Nenhum | — |

**b) Como o público fica identificável no CRM**

| Campanha sugerida | Público (relatório na pasta `MARKETING CLOUD`) | Estado |
|---|---|---|
| Reativação | `SEM COMPRA - 91 A 180 DIAS`, `SEM COMPRA - 181 A 365 DIAS`, `SEM COMPRA - MAIS DE 365 DIAS` | Reaproveita |
| Ampliação de mix | `AMPLIACAO MIX - CONTATOS` | **Cria** |
| Nutrição de lead | `LEADS - PROSPECÇÃO PRIORIZADA` | Reaproveita |

O nome do relatório sai na própria sugestão do `SFAgent2`, para o time saber qual público pedir a quem opera o Marketing Cloud. `Campaign`/`CampaignMember` não são usados (0 registros na dev; PA-06 da EPLAST-43, mantida).

**c) O que o Marketing Cloud devolve e onde grava**

Retorno de envio, abertura e clique fica no conector `et4ae5` (`et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c` confirmados pelo recon). A v1 **não lê** esse retorno e não cria campo de retorno (PA-01). `CampaignMember.et4ae5__Activity__c` não confirmado na org (incerteza I-05); irrelevante para a v1.

**d) Consentimento e opt-out**

- E-mail: `Contact.HasOptedOutOfEmail`. Mensagem: `Contact.et4ae5__HasOptedOutOfMobile__c`. Em Account não há campo de consentimento.
- A sugestão conta só elegíveis por canal; o relatório novo já exclui opt-out de e-mail. Para mensagem, o filtro de opt-out móvel é reaplicado pelo Marketing Cloud (o relatório é de e-mail; o público de mensagem continua nos relatórios `MSG - CONTATOS - CELULAR APTOS`, existentes).
- A regra de consentimento final é do Marketing Cloud; o CRM entrega o filtro.

**e) O que fica para quem opera o Marketing Cloud**

1. Importar `AMPLIACAO MIX - CONTATOS` como público (os de reativação e nutrição já são importáveis).
2. Reaplicar opt-out no envio, criar jornada, envio e conteúdo das campanhas.
3. Decidir se o retorno de envio deve alimentar a sugestão numa versão futura.

Nada disso é feito pela esteira.

---

## 6. Ordem de execução, governador e escala

- **Ordem de execução / concorrência com CPQ e triggers de Account e Order: não se aplica à solução.** O Flow novo não tem gatilho e não grava; a ação não grava; o relatório não grava. Nenhum `AccountTrigger`, `AccountBefore` (SBQQ), `OrderTrigger` (custom e SBQQ), `AccountTriggered`, `AccountUpdateEconomicGroup` ou `OrderScheduledFlow` é disparado por ela. **Atenção:** a fixture de teste grava Account, Contact e Opportunity na dev e dispara esses triggers (seção 7).
- **SOQL por chamada:** 5 (custom permission não consome; Account 1, catálogo 1, sinais 1, contatos por canal 2). Limite 100.
- **Linhas:** sinais ≤ 10 por conta (`CrossSellMaxPerAccount__c`); catálogo ≤ 5; contatos: só Id, para contar.
- **CPU, cenário "um pai com muitos filhos":** uma conta com muitos contatos é o caso pesado (a ação é por conta). O Flow só conta (Assignment "Equals Count"), sem loop sobre contatos. Até 2.000 contatos numa conta a estimativa fica bem abaixo de 1 s de CPU. Acima de 10.000 contatos numa conta, o heap da coleção de Ids passa a pesar: aí o design volta (Apex com `COUNT()`). Volume real de contatos por conta na QAS não foi medido (dev tem 0); o `qa` mede um `COUNT()` agregado máximo por conta se quiser comprovar, sem ler registro.
- **Cenário "muitos registros":** não existe; o agente chama a ação para uma conta por vez. CA-07 (20 contas) são 20 chamadas independentes.
- **DML:** 0. Nenhum e-mail, nenhuma mensagem.

---

## 7. Dados de teste

Dev vazia (Account, Contact, Opportunity, Order, Campaign = 0; Product2 = 1042). Fixture em `fixtures/` (regra 6), rótulo de teste no nome (`TESTE-EPLAST46`), criada e apagada por quem testa:

- 5 contas com `Industry` igual, `TriggerUtility.bypassTrigger` conforme `fixtures/README.md` (não validado nesta sessão): A sem compra há 100 dias, B compra há 30 dias, C sem nenhuma oportunidade ganha, D compra há 30 dias + sinal de cruzada, E compra há 200 dias + sinal de cruzada.
- Oportunidades `Fechado/Ganho` com `CloseDate` controlada (alimentam `LastPurchase__c`). Os triggers de Opportunity (custom e SBQQ) e as validation rules de Opportunity rodam; a fixture preenche todo campo exigido (skill `salesforce-doutrina`, achado SOMOSAGILITY-10).
- `CommercialSignal__c` `Type__c = Cruzada` inseridos **direto** pela fixture (não pelo batch), apontando para produtos existentes com `Group__c` `PREF` e `TAMP`. Evita criar `Order` (validation rules e trigger duplicado do CPQ, achados 3 e 10 do assessment).
- Contatos: um com opt-out de e-mail, um com opt-out móvel, um sem opt-out, todos com e-mail e celular fictícios de teste.
- Proprietário: `005bJ00000piKAaQAM`.

---

## 8. Critérios de aceite após o design

| CA | Situação |
|---|---|
| CA-01, CA-02, CA-03, CA-04, CA-06, CA-07, CA-08, CA-11 | Mantidos |
| CA-05 | **Reescrito** (PA-46-01/03): "Dado uma conta com sinal `Cruzada` para produto do grupo PREF e que comprou o produto P (grupo TAMP) há 60 dias, quando a sugestão é gerada, então aparece ampliação de mix citando o grupo PREF e o produto P não aparece". A exclusão de P vem do motor da EPLAST-33; no teste é garantida pela fixture (não há sinal para P) |
| CA-09 | Executado pela custom permission (seção 4) |
| CA-10 | **Não se aplica**: não há Apex. Volta a valer se o build precisar descer a Apex (com novo gate) |
| CA-12 (novo) | "Dado uma conta sem sinal `Cruzada` e com compra há 30 dias, então `suggestionCode = NONE` e a mensagem diz que não há campanha sugerida" |

---

## 9. Decisão para o arquiteto humano (modelo de dados)

**Novo custom metadata type `CampaignSuggestionSetting__mdt`.** É metadata de configuração, não dado de cliente, mas é um tipo novo no modelo: decida no gate.
- Recomendação: aprovar. Deixa ordem, ativação e nome do público configuráveis sem deploy (PA-02 e PA-06 da análise prometiam isso).
- Plano B, se recusado: os dois itens do catálogo viram constantes no Flow; mudar ordem ou público passa a exigir versão nova do Flow. Nenhum outro componente muda.
- Nenhum campo novo em Account, Contact, Lead, Opportunity, Order ou `CommercialSignal__c`.

---

## 10. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Dependência da EPLAST-33.** `CommercialSignal__c` e as classes existem na dev, mas a EPLAST-33 está em `backlog` no Squad OS (rodada anterior). Se não estiverem na QA, o deploy do Flow (que referencia o objeto) falha; se a EPLAST-33 for refeita e mudar o objeto, a sugestão quebra | **Alta** | `release`/esteira confere `CommercialSignal__c` na QA antes do deploy (não foi possível conferir: só a dev está conectada). Se faltar, a ampliação de mix sai da v1 por versão do Flow sem esse ramo, e a reativação segue. Qualquer mudança da EPLAST-33 no objeto precisa citar esta demanda |
| R2 | Sinais desatualizados ou vazios: nenhum job `CommercialSignal*` agendado na dev (`CronTrigger` = 0); na QA não medido | Média | A mensagem mostra a data do cálculo (`CalculationDate__c`). Agendar o batch é decisão da EPLAST-33/admin, não desta demanda |
| R3 | **Duas noções de "compra" na org.** Reativação usa oportunidade ganha (`LastPurchase__c`); cruzada usa pedido com status `Faturamento;Concluido` (EPLAST-33). Uma conta pode estar "inativa" e ter sinal de cruzada por pedido recente | Média | Assumido (PA-46-04): cada regra usa a fonte que o público correspondente já usa. Homologação valida com amostra |
| R4 | Ativar a v9 troca o assistente de quem usa a dev/QA | Média | Passo de ativação separado e registrado; desfazer = ativar v8 |
| R5 | Filtro cruzado de `Contact` para `CommercialSignal__c` (via Account) pode não ser aceito no tipo de relatório | Média | Builder confere pelo describe do tipo de relatório antes do XML (skill, EPLAST-39). Plano B: público por conta (`CommercialSignals_ByAccount` já existe) e o Marketing Cloud cruza com contato; sem criar tipo de relatório novo sem novo gate |
| R6 | 132 produtos sem `Group__c` | Baixa | Aparecem como "sem grupo" |
| R7 | Relatórios `SEM COMPRA` com filtro diferente das faixas da sugestão | Baixa | Filtros não relidos; builder confere e ajusta só o texto da faixa no Flow, não os relatórios |
| R8 | Usuário de teste é administrador; caso negado depende da custom permission não atribuída | Baixa | Seção 4 |

### Riscos do assessment que tocam o pedido

| Achado | Como se aplica |
|---|---|
| 1 — automação concorrente em Account/Opportunity/Order com CPQ | Não se aplica à solução (sem gravação). Aplica-se à fixture (Opportunity, Account): bypass e campos obrigatórios |
| 2 — cobertura Apex baixa | Não se aplica (sem Apex) |
| 3 — validation rules de Order | Não se aplica: a fixture não cria Order (sinais inseridos direto) |
| 6 — alias dev aponta para sandbox "qa" | Resolvido pela regra 5 da conta |
| 10 — `OrderTrigger` duplicado com CPQ | Não se aplica (nenhum trigger criado) |

---

## 11. Incertezas declaradas

- I-01: presença de `CommercialSignal__c` e do `SFAgent2` v8 na QA (só a dev está conectada).
- I-02: conteúdo dos permission sets existentes, perfis e OWD (recon não conseguiu ler).
- I-03: filtros dos relatórios `SEM COMPRA - *` e `LEADS - PROSPECÇÃO PRIORIZADA` (RAG diz que usam `LastPurchase__c`; não relido).
- I-04: suporte a filtro cruzado no relatório novo (R5).
- I-05: `CampaignMember.et4ae5__Activity__c`.
- I-06: gatilho e objeto de `AccountTriggered` e `AccountUpdateEconomicGroup` (irrelevante para a solução, relevante para a fixture).
- I-07: bypass `TriggerUtility.bypassTrigger` não validado na org.
- I-08: tópico exato do planner v8 que contém `ProximaAcaoCliente` (builder confere no bundle baixado; o desenho usa `insights_comerciais`).

---

## 12. Premissas assumidas (validar na homologação)

Da análise (mantidas, com ajuste quando indicado):

- [x] **PA-01 — Comportamento = histórico de compra.** Mantida. Interação de e-mail fora da v1.
- [x] **PA-02 — Necessidade e limites.** **Ajustada.** Necessidade = produto que contas do mesmo `Industry` compram e a conta não (sinal `Cruzada`). 90 dias vem de `Inactive__c` (fórmula); 180 dias vem de `CommercialSignalSetting__mdt.CrossSellRecentDays__c`. Nenhum limite novo. Como mudar: fórmula de `Inactive__c` (com os relatórios `SEM COMPRA`) e o registro `Default` do CMDT da EPLAST-33.
- [x] **PA-03 — Calculada na hora, sem campo novo.** Mantida.
- [x] **PA-04 — Marketing e Comercial, leitura.** Mantida, pelo PS novo.
- [x] **PA-05 — Não dispara.** Mantida (regra da conta).
- [x] **PA-06 — Catálogo e lead.** **Ajustada:** catálogo = reativação e ampliação de mix na ação; nutrição de lead pelo relatório existente (PA-46-05).
- [x] **PA-07 — Reaproveitar `ProximaAcaoCliente`.** **Substituída por PA-46-02.**
- [x] **PA-08 — Fixtures.** Mantida (seção 7).
- [x] **PA-09 — Qualidade do pedido do Protheus.** Mantida; afeta os sinais da EPLAST-33.

Acrescentadas no design:

- [x] **PA-46-01 — Ampliação de mix reaproveita a cruzada da EPLAST-33.**
  - Pergunta: a regra de mix é nova ou a existente?
  - Decisão: lê `CommercialSignal__c` `Type__c = Cruzada`; grupo de referência `Account.Industry`, não `Sector__c`.
  - Evidência: objeto, CMDT e classes na dev (seção 1.1); regra 3 da conta.
  - Como mudar: trocar o grupo é `CrossSellGroupField__c` no CMDT da EPLAST-33, sem tocar nesta demanda.
- [x] **PA-46-02 — Ação nova no mesmo tópico, não versão da ação da EPLAST-27.**
  - Pergunta: estender `ProximaAcaoCliente` ou criar ação?
  - Decisão: ação nova `SugestaoCampanha_EPLAST46` no tópico `insights_comerciais` da v9 (seção 1.4).
  - Evidência: contrato da ação da EPLAST-27 (um código, mensagem mostrada sem acréscimo); critério de reativação é o mesmo (`Inactive__c`), sem divergência.
  - Como mudar: fundir as duas numa versão futura do Flow `Account_Agente_ProximaAcao`, em demanda própria.
- [x] **PA-46-03 — "Família" = `Product2.Group__c`.**
  - Pergunta: qual campo é a família do produto?
  - Decisão: `Group__c` (910 de 1042 preenchidos) em vez de `Family` (118).
  - Evidência: contagens agregadas na dev; mesmos códigos nos dois campos.
  - Como mudar: trocar o campo lido no Flow (versão nova).
- [x] **PA-46-04 — Fonte de "compra" diferente por regra.**
  - Pergunta: reativação e mix usam a mesma fonte?
  - Decisão: reativação por oportunidade ganha (`LastPurchase__c`), mix por pedido (EPLAST-33), cada uma alinhada ao público que já existe.
  - Evidência: definição de `LastPurchase__c` e `PurchaseStatuses__c` confirmadas.
  - Como mudar: se a Eplast quiser pedido também na reativação, usar `CommercialSignal__c` `Recuperacao` (60 dias) — troca de ramo no Flow, versão nova.
- [x] **PA-46-05 — Lead fora da ação.**
  - Pergunta: a ação sugere nutrição de lead?
  - Decisão: não; a ação é por conta. Nutrição segue no relatório `LEADS - PROSPECÇÃO PRIORIZADA`.
  - Evidência: lead não tem conta; público de nutrição já existe (EPLAST-44, RAG).
  - Como mudar: ação por lead em demanda própria.
- [x] **PA-46-06 — Mensagem só com contagens e códigos.**
  - Pergunta: a sugestão mostra quem são os contatos elegíveis?
  - Decisão: não; só quantos por canal. A lista nominal fica no relatório que o Marketing Cloud importa.
  - Evidência: guardrail #2 e CA-11.
  - Como mudar: não muda no agente; a lista está no relatório.

Nenhuma pergunta caiu no caso 3 da regra 4: nada bloqueia o build. A única decisão reservada é a de modelo de dados (seção 9).

---

## 13. O que NÃO será feito

- Nada no Marketing Cloud nem na configuração do conector `et4ae5`.
- Envio de e-mail ou mensagem por Flow, e-mail alert ou Apex.
- Campo novo em Account, Contact, Lead, Opportunity, Order; gravação de sugestão em registro.
- Alteração do motor da EPLAST-33 (objeto, CMDT, classes, agendamento do batch).
- Alteração do Flow `Account_Agente_ProximaAcao`, da ação `ProximaAcaoCliente_EPLAST27` e dos permission sets existentes.
- Alteração dos relatórios existentes da pasta `MARKETING CLOUD`.
- `Campaign` e `CampaignMember`; leitura do retorno de envio.
- Sugestão para lead na ação; exclusão por família comprada (é por produto).
- Apex.

---

## 14. Esforço

**Estimativa de esforço:** 18–30 h

O que mudou em relação à análise (16–32 h): a regra de mix, que era a maior incerteza, já existe na org (EPLAST-33) e não será construída, o que tira o teto alto e o risco de Apex. Em compensação entram a versão v9 do `SFAgent2` (historicamente cara nesta conta: EPLAST-27, 29 e 34 tiveram retrabalho de versão), um relatório com filtro cruzado (formato a confirmar, EPLAST-39) e uma fixture que cria oportunidades e sinais com triggers do CPQ ativos. Distribuição: Flow e CMDT 6–8 h; PS e custom permission 1–2 h; agente v9 4–7 h; relatório 2–4 h; fixture 3–5 h; verificação 2–4 h. Não inclui nada do Marketing Cloud nem agendamento do batch da EPLAST-33.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
