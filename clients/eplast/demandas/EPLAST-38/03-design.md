# EPLAST-38 · Design: qualificação e roteamento do lead ao vendedor responsável

**Etapa:** design (`arquiteto`) · **Data:** 2026-11-15 · **Org consultada:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY, sandbox, única org conectada, conferida com `sf org list` nesta sessão). Só leitura. Retrieve de apoio em `/tmp`, fora do repositório.
**Entradas:** `01-analise.md` (gate aprovado em 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, `00-preflight.md` (sem bloqueios, nenhuma demanda concorrente), `assessment.md` (2026-09-30), RAG do cliente (plano de build de EPLAST-35, designs de EPLAST-26 e EPLAST-39).
**Precisa do aceite do arquiteto humano.**

Tudo o que este design cita como existente foi confirmado via `sf`, pelo recon ou nesta sessão. Onde não foi possível, o texto diz isso.

---

## 0. Resumo da decisão

**A roteirização já existe e funciona por configuração. Esta demanda não cria Flow, Apex, campo nem regra.** O build faz quatro coisas:

1. Versiona no repositório, **sem alterar**, os componentes que EPLAST-35 deixou na dev (regra, filas, Flow, classe, permissão, layout), para que a QA receba a mesma coisa que foi testada.
2. Cria o dado de teste em `fixtures/` (pasta ainda não existe no workspace) e prova os 7 critérios na dev.
3. Documenta o passo de quem opera: membros das 8 filas (hoje 0) e atribuição do permission set às integrações.
4. Ajusta o critério CA-04 ao comportamento da plataforma (premissa PA-07).

Nível escolhido: **configuração**. Ver a seção 1 para o motivo de não descer de nível.

---

## 1. Decisão e justificativa

| Alternativa | Nível | Decisão |
|---|---|---|
| **(a) Reaproveitar a regra `Distribuicao_Regional_Leads` como única fonte de dono, com o Flow e a classe existentes só como gatilho para a integração** | Configuração (o que já existe) | **Escolhida.** Cobre RN-01 a RN-05. Regra de atribuição é o recurso nativo para dono de Lead. Já roda na criação por tela (layout) e pela integração (Flow → classe com `useDefaultRule=true`). Nada novo entra na ordem de execução |
| (b) Novo Flow record-triggered que calcula a fila por UF | Declarativo | Rejeitada. Seria a segunda fonte de dono, concorrendo com a regra no mesmo evento: o risco que a análise apontou (seção 7) e que a regra 3 da conta proíbe |
| (c) Apex (trigger ou serviço novo) com tabela UF → fila | Código | Rejeitada. Nenhum critério da doutrina (rollback, callout, volume, recursão) exige isso. Lead não tem trigger, e criar um somaria classe numa org com 10% de cobertura (assessment, achado 2) |
| (d) Normalizar `State` com Flow before-save (ex.: "São Paulo" para "SP") | Declarativo | Fora desta entrega (PA-09). Acrescentaria automação nova no evento de criação. Fica como evolução se a Triagem receber volume alto de UF por extenso |
| (e) Atribuição individual (round-robin ou carteira por vendedor) | Código ou recurso pago | Fora (PA-04 da análise). O "vendedor responsável" é a fila regional |

Sobre a dúvida da análise (seção 8, item 3), **o Flow e a regra coexistem e não competem.** O Flow não define dono. Ele só pede que a regra rode (`Database.DMLOptions.assignmentRuleHeader.useDefaultRule = true` em `LeadAssignmentService`). A fonte de verdade do dono é **uma só: a regra**. Fonte: `02-recon.md`, seção 3, confirmado na leitura do XML.

---

## 2. Componentes, item a item (regra 3: reaproveita × cria)

| Componente (API name) | Tipo | Estado na dev (confirmado) | Nesta demanda |
|---|---|---|---|
| `Distribuicao_Regional_Leads` (`AssignmentRules:Lead`) | Regra de atribuição | Ativa. 8 entradas por `Lead.State`, a última sem critério vai para Triagem. **Nenhuma entrada com `template`** (sem e-mail ao novo dono, conferido no retrieve desta sessão) | **Reaproveita, sem alteração.** Versiona no repositório |
| `Leads_SP`, `Leads_RJ`, `Leads_MG`, `Leads_ES`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem` | Filas (`Queue`), objeto `Lead` (8 `QueueSobject`) | Existem. 0 membros. `DoesSendEmailToMembers=false` nas 8 e nenhuma com e-mail preenchido (conferido nesta sessão) | **Reaproveita.** Versiona **sem** `queueMembers` (ver R1). Membros entram por passo do operador (seção 7) |
| `Lead_AfterInsert_AplicaRegraAtribuicao` | Flow record-triggered, after save, Create, caminho assíncrono | Ativo, v1 (única). Único Flow ativo com gatilho em Lead (`FlowDefinitionView`, conferido nesta sessão) | **Reaproveita, sem versão nova** (nada muda no Flow). Versiona a v1 no repositório |
| `LeadAssignmentService` + `LeadAssignmentServiceTest` | Apex (API 68) | Existem. Cobertura agregada 13/13 linhas (100%), conferida nesta sessão em `ApexCodeCoverageAggregate`. Nenhum job agendado com "Lead" (`CronTrigger`: 0) | **Reaproveita, sem alteração.** Versiona. O verificador reexecuta o teste para atualizar a cobertura |
| `Lead_DistribuicaoAutomaticaViaApi` | Custom permission | Existe | **Reaproveita.** Versiona |
| `PS_Integracao_DistribuicaoLead` | Permission set | Existe, 1 atribuição na dev | **Reaproveita.** Versiona. Atribuição às integrações é passo do operador |
| `Lead-Lead Layout` | Layout (único layout de Lead na org, conferido nesta sessão) | `runAssignmentRulesDefault=true`, `showRunAssignmentRulesCheckbox=true` | **Reaproveita, sem alteração.** Versiona. Ver R1 sobre a QA |
| `PriorityScore__c` (fórmula número), `PriorityBand__c` (fórmula texto) | Campos de Lead | Existem (EPLAST-26) | **Reaproveita**, só leitura. Nenhuma alteração |
| `Sector__c` (picklist), `MKT_Origem_Agrupada__c` | Campos de Lead | Existem | **Reaproveita**, só leitura |
| List views `Leads abertos por prioridade`, `Leads Triagem`, `Leads SP`… (uma por região) | List views | Existem | **Reaproveita.** Nenhuma nova |
| Relatórios `LEADS - SP/RJ/MG/ES/CO/SUL/GERAL` (pasta MARKETING CLOUD) | Relatórios `LeadList` | Existem. Filtram `STATE` e `EMAIL_OPT_OUT = Falso` (filtros lidos nesta sessão pela Analytics API, só metadata). **Não há relatório para Norte e Nordeste** | **Reaproveita.** Lacuna NO_NE registrada na seção 8, não criada aqui |
| `SFAgent2` | Agente Agentforce | Existe (v1 a v6) | **Não tocado.** A demanda não pede assistente (seção 9) |
| `fixtures/` (workspace do cliente) | Scripts de dado de teste | **Não existe** no workspace | **Cria:** `fixtures/README.md` e `fixtures/lead_roteamento_regional.apex` (seção 6) |
| `manifest/EPLAST-38-package.xml` | Manifesto do build | — | **Cria** (seção 10) |

**Componentes novos de metadata na org: nenhum.** Não há mudança de modelo de dados, por isso não há escalonamento ao arquiteto sênior.

---

## 3. Como o lead chega à fila (comportamento fechado)

### 3.1 Tabela UF → fila (fecha o CA-03)

Lida das entradas da regra ativa (`02-recon.md`, seção 1):

| Fila | UF (`Lead.State` igual a) | UF representativa para CA-03 |
|---|---|---|
| `Leads_SP` | SP | SP |
| `Leads_RJ` | RJ | RJ |
| `Leads_MG` | MG | MG |
| `Leads_ES` | ES | ES |
| `Leads_Sul` | PR, SC, RS | SC |
| `Leads_CO` | GO, DF, MT, MS, TO | DF |
| `Leads_NO_NE` | AC, AP, AM, PA, RO, RR, AL, BA, CE, MA, PB, PE, PI, RN, SE | BA |
| `Leads_Triagem` | qualquer outro valor, inclusive vazio | (vazio) e "São Paulo" |

`Lead.State` é **texto livre** (`string`, sem `StateCode`; os picklists de estado e país não estão habilitados, conferido nesta sessão por describe filtrado). UF por extenso, com espaço ou com erro de digitação cai em Triagem (PA-09).

### 3.2 Caminhos de criação e ordem de execução

Ordem da plataforma (skill `salesforce-doutrina`): before-save Flows → before triggers → validation rules → gravação → after triggers → **regras de atribuição** → after-save Flows → commit → pós-commit (assíncrono).

| Caminho | O que acontece | Fonte do dono |
|---|---|---|
| **A. Tela**, caixa "Atribuir usando regra de atribuição ativa" marcada (padrão do layout) | A regra roda na transação, depois da gravação. O Flow não entra: o usuário de tela não tem a permissão, e o dono já é fila (`00G`) | Regra |
| **B. Tela**, caixa desmarcada pelo usuário | Regra não roda. Dono = o informado ou o criador | Usuário (CA-04) |
| **C. Integração com `PS_Integracao_DistribuicaoLead`**, dono usuário (`005`) | Lead grava com dono usuário. Depois do commit, o Flow (caminho assíncrono) chama `LeadAssignmentService`, que faz `update` com a regra. Dono passa para a fila. **Dono informado pela integração é sempre substituído** (decisão de EPLAST-35, PA-16, RAG `[demandas/EPLAST-35/04-plano-build.md]`) | Regra |
| **D. API com cabeçalho de regra de atribuição** (inclui Web-to-Lead, que aplica a regra ativa por padrão da plataforma) | Igual ao A | Regra |
| **E. API sem cabeçalho e sem o permission set** | Nada roteia. Dono = criador | Criador (fora do roteamento; ver R3) |

**Conflito de automação no evento de criação de Lead: há dois elementos (regra de atribuição e Flow after-save assíncrono), mas o metadata mostra que eles não concorrem.** O Flow só dispara quando o dono ainda é usuário (`005`) e o criador tem a permissão. Quando a regra já atribuiu a fila na transação, o filtro de entrada do Flow não passa. O update feito pela classe não reaciona o Flow, porque ele é só de Create. **Não há trigger de Lead.** Nenhum dos 13 Flows `MCC_*` tem Lead como objeto: os objetos são "Envio de email", "Envio acionado", "Resultado de email individual" e "Solicitação de suporte", conferidos nesta sessão em `FlowDefinitionView`. O verificador prova isso em execução (CA-01, CA-04, CA-06).

---

## 4. Governador e escala

- **Volume:** dev com 0 Lead. Volume de produção não conhecido; o teste usa 200 (CA-06), o tamanho de um lote de trigger.
- **Caminho A/D, carga em massa:** a regra de atribuição é processamento nativo, não consome SOQL nem DML do usuário.
- **Caminho C, 200 Leads:** uma execução do Flow em lote, que chama o invocable uma vez com 200 Ids. `LeadAssignmentService` faz 1 SOQL e 1 DML em lote, com `optAllOrNone=false` (`02-recon.md`). Fica muito abaixo de 100 SOQL e 150 DML. A execução é assíncrona (limite de CPU de 60 s). Carga via Bulk API de 10.000 registros vira lotes de 200, cada um com o mesmo custo.
- **CPU, cenário "um pai com muitos filhos" (achado SOMOSAGILITY-10):** não se aplica. A demanda não cria cascata pai-filho: Lead não tem filhos com automação, e a conversão de Lead não é tocada. O único re-update é o da classe, que não reaciona automação (Flow só de Create, sem trigger).
- **Critério de escalonamento:** se a verificação medir mais de 70% de qualquer limite com 200 Leads no caminho C, o design volta para revisão.

---

## 5. Permissões

| Item | Situação | Nesta demanda |
|---|---|---|
| OWD de Lead | Interno `ReadWriteTransfer` | Sem mudança |
| Perfis que criam Lead | Têm Create e Edit, entre outros: `Comercial - Analista` (4 usuários ativos na dev), `Comercial`, `Comercial - Analistas`, `Usuário do Marketing`, `Administrador do sistema`, `Pricing` (`ObjectPermissions`, nesta sessão). Leitura e edição sem criação: `Comercial Padrão`, `Marketing`, `Financeiro`, `Engenharia de Produtos` | **Nenhum perfil alterado** (assessment, achados 7 e 8) |
| `PS_Integracao_DistribuicaoLead` | Concede a custom permission | Sem mudança de conteúdo. **Atribuir aos usuários de integração que criam Lead é passo do operador**, com 1 atribuição já existente na dev. Quais integrações criam Lead em produção não foi levantado (R3) |
| Membros de fila e visibilidade | Membro de fila vê e assume os Leads da fila | Passo do operador (seção 7) |

---

## 6. Dados de teste e usuário de teste

- **Usuário de teste da regra 6:** na dev, o Id é `005bJ00000hBJmYQAW`, perfil `Administrador do sistema`, **inativo** (`IsActive=false`, nesta sessão). Pela regra 6, não se altera esse usuário: o teste segue sem ele na dev. CA-04 usa como dono informado o próprio usuário de execução do verificador. Na QA, o `qa` resolve o Id de novo e usa a conta se ela estiver ativa.
- **Validation rules `Celular` e `Telefone`:** podem barrar o Lead de teste. A fixture **deixa `Phone` e `MobilePhone` vazios**. Se a regra exigir o campo (a fórmula não foi lida), usa número fictício no formato da mensagem da regra, `(11)99999999`, sem número real. O verificador registra qual dos dois funcionou e grava em `fixtures/README.md`.
- **Fixture `fixtures/lead_roteamento_regional.apex`:** cria Leads com `LastName` e `Company` sintéticos e prefixo identificável (`EPLAST38-TESTE-`), um por UF da tabela 3.1, mais vazio e "São Paulo". Preenche `Sector__c`, `LeadSource` e `Status` para CA-05 com valores lidos da picklist da org no build. Tem dois modos: (i) com `assignmentRuleHeader.useDefaultRule=true` (caminhos A e D) e (ii) inserção simples pelo usuário com o permission set (caminho C, assíncrono). Inclui o bloco de 200 Leads (CA-06) e um script de limpeza que apaga só registros com o prefixo.
- **Caminho C na dev:** o verificador atribui `PS_Integracao_DistribuicaoLead` ao próprio usuário de execução, o que é permitido para dado de teste na dev, e remove a atribuição ao fim. Depois do insert, espera o processamento assíncrono antes de consultar `OwnerId`.
- **QAS (Partial Copy):** só Leads criados pelo agente, consultados pelo Id. Nenhum registro real é lido ou alterado.

---

## 7. Membros das filas (quem recebe o lead)

- **O que a org mostra:** 0 membros nas 8 filas. Não há papel nem grupo público regional: os papéis são só `Coordination` e `Financeiro`, e os grupos públicos não têm nome de região (conferido nesta sessão). Nada na org indica quem atende cada região.
- **Decisão (PA-08):** membros são incluídos **pelo administrador da Eplast, em Setup > Filas**, em cada sandbox e em produção. **Não vão no metadata:** listar usuário em `queueMembers` põe username no repositório (guardrail 2) e difere de org para org. Não se cria grupo nem papel regional, porque seria uma estrutura paralela que não acrescenta nada à fila (regra 3). Isso repete o passo 1 do plano de EPLAST-35 (RAG).
- **Mínimo recomendado:** a `Leads_Triagem` precisa de pelo menos um responsável, porque recebe tudo que não casa com UF. As filas já têm `DoesIncludeBosses=true`. Mesmo assim, sem membro ninguém recebe o lead: a list view da fila vira o único acesso.
- **Teste:** CA-01 a CA-06 provam o roteamento pelo `OwnerId` da fila, o que não depende de membro. O roteiro do cliente traz um passo "confira que sua fila tem membros" e a lista das 8 filas como checklist do operador.

---

## 8. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca leads, origem e prioridade (regra 2). **Nada é feito no Marketing Cloud.** O CRM não dispara e-mail nem mensagem: a regra não tem `template`, as filas não mandam e-mail aos membros, e o Flow e a classe não têm ação de e-mail (CA-07).

| Item | Onde fica no CRM |
|---|---|
| **Dados que o MC lê** | `Lead.State`, `Lead.OwnerId` (fila regional), `Lead.LeadSource`, `Lead.MKT_Origem_Agrupada__c`, `Lead.Sector__c`, `Lead.Status`, `Lead.PriorityScore__c`, `Lead.PriorityBand__c`, `Lead.Email`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__HasOptedOutOfMobile__c`. Todos existem e nenhum é criado |
| **Como o público fica identificável** | Pelos relatórios já existentes na pasta MARKETING CLOUD, que já excluem opt-out de e-mail: `LEADS - SP`, `- RJ`, `- MG`, `- ES`, `- CO`, `- SUL` (filtro por `State`, igual às entradas da regra) e `LEADS - GERAL`. Também pela faixa `PriorityBand__c` e pela list view `Leads abertos por prioridade`. **Lacuna:** não há relatório `LEADS - NO_NE` (Norte e Nordeste). Não é criado aqui (fora do pedido de roteamento); quem opera o MC pode filtrar `LEADS - GERAL` por UF ou pedir o relatório em demanda própria |
| **O que o MC devolve e onde grava** | Nada previsto nesta demanda. Retorno de envio e tracking é gravado pelo conector `et4ae5` nos próprios objetos, sem alteração aqui |
| **Consentimento e opt-out** | `HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c`. O CRM só lê. Os relatórios regionais já filtram opt-out de e-mail. Opt-out de celular é tratado por quem opera o MC |
| **Fica para quem opera o MC** | Montar público a partir dos relatórios regionais ou da faixa de prioridade. Excluir opt-out de celular. Configurar qualquer aviso, jornada ou nutrição, inclusive aviso ao vendedor, se o cliente quiser (PA-06 da análise) |

---

## 9. Riscos

### 9.1 Riscos do assessment

| Achado do assessment | Aplica? | Como este design lida |
|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order (CPQ) | **Não se aplica** | Nenhum DML nesses objetos. A conversão de Lead, que tocaria Account, Contact e Opportunity, não é alterada nem testada aqui |
| #2 Cobertura Apex ~10% | Aplica-se de leve | Nenhuma classe nova. `LeadAssignmentService` está com 13/13 linhas cobertas, e o verificador reexecuta `LeadAssignmentServiceTest` para confirmar ≥ 85% |
| #3 Validation rules de Order | Não se aplica | Order fora |
| #4 Campos sem descrição | Não se aplica a componente novo (não há) | `Sector__c` segue sem descrição, sem ser alterado aqui (seção 11) |
| #5 Nome de classe de teste | Não se aplica | `LeadAssignmentServiceTest` já segue a convenção |
| #6 dev × qa | Resolvido pela regra 5 da conta | Duas orgs distintas, confirmado pelo responsável |
| #7, #8 Perfis | Não se aplica | Nenhum perfil alterado |
| #9 API antiga de classes | Não se aplica | Classe em API 68 |
| #10 Trigger homônimo CPQ | Não se aplica | Lead sem trigger |

### 9.2 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| **R1** | **O deploy na QAS sobrescreve configuração que veio de produção.** A QAS é Partial Copy, e o estado dela não foi comparado com a dev (`02-recon.md`, seção 6). Implantar `AssignmentRules:Lead` substitui as regras de Lead da QAS, e a regra ativa desativa outra que estiver ativa lá. Implantar o `Lead-Lead Layout` substitui o layout da QAS. Se o Queue sem `queueMembers` remove membros existentes na QAS não está confirmado | **Alta** | O manifesto separa dois grupos (seção 10). **Antes do deploy em QA**, o passo da esteira (ou o revisor do PR, se o passo não comparar) faz retrieve só-leitura desses tipos na `sbx-eplast-qa` e confere. Componente que já existe lá com outro conteúdo, ou fila com membros, **sai do deploy** e fica registrado em `05-deploy-qa.md`. Rollback: reativar a regra anterior e restaurar o layout pelo retrieve guardado |
| R2 | Implantar o Flow já ativo cria uma versão nova idêntica na QAS | Média | O Flow entra no deploy só se não existir na QAS (Flow novo pode nascer ativo, pela doutrina). Se existir, fica fora do deploy |
| R3 | Integração que cria Lead sem o permission set e sem cabeçalho (caminho E) não roteia | Média | Passo do operador: atribuir o PS a cada usuário de integração que cria Lead. Quais integrações fazem isso em produção não foi levantado |
| R4 | Filas sem membro: o roteamento funciona e não entrega a ninguém | **Alta para o resultado** | Seção 7. Passo do operador obrigatório, no roteiro do cliente e em `06-entrega.md` |
| R5 | UF fora do padrão (por extenso, minúscula, com espaço) cai em Triagem | Baixa | PA-09. A comparação de critério de regra de atribuição é, pela plataforma, sem distinção de maiúscula e minúscula. O CA-02 inclui "sp" minúsculo para provar isso |
| R6 | Validation rules de telefone barram a fixture | Baixa | Seção 6 |
| R7 | O caminho C é assíncrono: consultar logo após o insert pode mostrar o dono ainda como usuário | Baixa | Verificação espera o fim do processamento antes de consultar |

---

## 10. Build: manifesto e versões

**Versões e ativação:** nenhum Flow, classe ou agente é alterado, então **nenhuma versão nova é criada e não há passo de ativação**. A v1 do Flow segue ativa, e a classe segue como está.

`manifest/EPLAST-38-package.xml`, montado por retrieve da dev, sem editar o conteúdo:

- **Grupo 1 (seguro, não sobrescreve config de negócio):** `ApexClass` `LeadAssignmentService`, `LeadAssignmentServiceTest`; `CustomPermission` `Lead_DistribuicaoAutomaticaViaApi`; `PermissionSet` `PS_Integracao_DistribuicaoLead`.
- **Grupo 2 (só se ausente ou idêntico na QAS, R1 e R2):** `Queue` (as 8, sem `queueMembers`); `AssignmentRules` `Lead`; `Layout` `Lead-Lead Layout`; `Flow` `Lead_AfterInsert_AplicaRegraAtribuicao`.

O builder não toca a QA. O plano de build (`04-plano-build.md`) lista o grupo 2 como condição para o deploy em QA.

---

## 11. Critérios de aceite: ajustes do design

- **CA-02:** inclui também `State = "sp"` (minúsculo, esperado `Leads_SP`) e `State = "São Paulo"` (esperado `Leads_Triagem`).
- **CA-03:** fechado pela tabela 3.1.
- **CA-04 (reformulado, PA-07):** *"Dado um Lead criado com dono informado (usuário ativo) e sem regra de atribuição (caixa desmarcada na tela, ou API sem cabeçalho por usuário sem o permission set), quando é salvo, então o dono continua o informado. Com a caixa marcada (padrão), a regra define a fila."* Os dois ramos são testados.
- **CA-05:** os valores 100 e 60 e as faixas vêm de EPLAST-26. O build relê a fórmula de `PriorityScore__c` e `PriorityBand__c` e os valores de `Status` e `LeadSource` da org antes de montar o caso. Se divergirem, vale a fórmula da org, e a diferença é registrada.
- **CA-06:** 200 Leads pelo caminho C (assíncrono), mais 200 pelo caminho A/D (cabeçalho), em UFs de regiões diferentes.
- **CA-07:** conferir que não há `template` na regra, que `DoesSendEmailToMembers=false` nas filas e que não há ação de e-mail no Flow nem na classe. Os três já foram confirmados no metadata nesta sessão. O verificador repete.

---

## 12. Premissas assumidas (validar na homologação)

Levadas da análise: PA-01 a PA-06, sem mudança, exceto a PA-05, que é substituída pela PA-07.

- [x] **PA-07 — Dono informado na criação.** *Pergunta:* se o usuário já escolheu o responsável, a regra sobrescreve? *Decisão:* a regra sobrescreve quando a caixa "Atribuir usando regra de atribuição ativa" está marcada, que é o padrão. Quem quer manter o dono que escolheu desmarca a caixa. Integração com o permission set é sempre roteada. *Evidência:* comportamento padrão da plataforma; o layout de Lead tem a caixa visível e marcada por padrão (`showRunAssignmentRulesCheckbox=true`, `runAssignmentRulesDefault=true`, nesta sessão); EPLAST-35 decidiu a caixa marcada (PA-15) e a integração sempre roteada (PA-16), segundo o RAG. Não há como a regra "manter o dono atual" sem automação nova contra a plataforma. *Como mudar:* desmarcar `runAssignmentRulesDefault` no layout, para que a tela não roteie por padrão, ou acrescentar uma automação em demanda própria.
- [x] **PA-08 — Quem é membro de cada fila.** *Pergunta:* quem atende cada região? *Decisão:* o administrador da Eplast inclui os membros em Setup, sem metadata. A Triagem precisa de pelo menos um responsável. *Evidência:* a org não tem papel nem grupo regional, as filas estão sem membro, e o plano de EPLAST-35 já tratava isso como passo manual (RAG). *Como mudar:* incluir ou remover membros em Setup > Filas, sem deploy.
- [x] **PA-09 — UF fora do padrão.** *Pergunta:* o lead com UF por extenso ou errada vai para onde? *Decisão:* para `Leads_Triagem`, sem normalização. *Evidência:* a regra existente tem a última entrada sem critério para Triagem, `State` é texto livre, e EPLAST-35 decidiu o mesmo (PA-17, RAG). *Como mudar:* acrescentar valores às entradas da regra (configuração) ou normalizar `State` com Flow before-save, em demanda própria.
- [x] **PA-10 — Momento do encaminhamento.** *Pergunta:* reencaminhar quando a UF mudar ou o lead for qualificado depois? *Decisão:* não. O roteamento acontece só na criação (PA-02 da análise). Edição posterior pode reaplicar a regra pela caixa na tela, que é o padrão da plataforma. *Evidência:* o Flow é só de Create, e a caixa existe no layout. *Como mudar:* acrescentar Update ao Flow, como versão nova, em demanda própria, com cuidado com recursão.

**Bloqueios (caso 3 da regra 4): nenhum.**

---

## 13. O que NÃO será feito

- Nenhum Flow, Apex, campo, regra, fila, grupo, papel, list view, relatório ou agente novo. Nenhuma alteração em `SFAgent2`.
- Membros das filas (passo do operador) e atribuição do permission set em produção.
- Normalização de `State` e habilitação de picklists de estado e país.
- Relatório `LEADS - NO_NE` para o Marketing Cloud.
- Aviso ao vendedor (e-mail, notificação ou Slack) e SLA de primeiro contato.
- Round-robin ou atribuição por vendedor individual.
- Descrição de `Sector__c` (campo de EPLAST-26, não é tocado).
- Qualquer configuração no Marketing Cloud.
- Conversão de Lead e qualquer efeito em Account, Opportunity ou Order.

---

## 14. Estimativa

**Estimativa de esforço:** 6–11 h

O que mudou em relação à análise (8–16 h): o recon e esta sessão confirmaram que regra, filas, Flow, classe (100% de cobertura) e permissão já existem e que **nada precisa de versão nova**. Isso cai no cenário (a) da análise, a faixa baixa. O esforço restante é: versionar por retrieve (1–2 h); criar as fixtures e acertar as validation rules de telefone (1–2 h); verificar os 7 critérios, incluindo 2 × 200 Leads e o caminho assíncrono (2–4 h); montar o manifesto em dois grupos e a condição de deploy em QA (R1) (1 h); passo do operador e roteiro (1–2 h). A faixa alta cobre o R1, se a QAS divergir da dev e o grupo 2 exigir decisão no PR.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
