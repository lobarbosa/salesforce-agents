# Assessment da org — Somos Agility

**Org auditada:** sbx-somos-agility-dev (`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`) · **API:** v67 · **Data:** 2026-09-30

Confirmado via `sf org display --target-org sbx-somos-agility-dev`: sandbox (`IsSandbox=true`), Enterprise Edition, instância BRA8S. Este é o primeiro assessment desta conta — não existia `assessment.md`/`assessment.json` antes deste diagnóstico.

**Saúde geral:** vermelho

## Veredito em três linhas

A automação está concentrada de um jeito que qualquer mudança em Oportunidade vira uma aposta: 31 automações ativas competem no mesmo objeto, 24 delas disparando no mesmo evento (`RecordAfterSave`/create-update), sem ninguém conseguir prever a ordem de execução. A cobertura de teste Apex da org inteira está em 40% — metade do mínimo de produção da Salesforce (75%) e menos da metade do padrão deste squad (85%). Security segue o padrão "perfil por pessoa" (20 de 26 perfis em uso têm exatamente 1 usuário ativo), o que é o oposto de permission set. Nenhuma dessas três coisas trava a operação hoje, mas qualquer demanda nova nesta org herda esse risco antes mesmo de o consultor escrever a primeira linha.

## Inventário

| Área | Métrica | Valor |
|---|---|---|
| Automação | Flow definitions totais / ativas | 407 / 316 |
| Automação | Automações ativas por ProcessType | AutoLaunchedFlow 197, Workflow (Process Builder) 59, Flow (tela) 32, Appointments 16, RoutingFlow 5, IndividualObjectLinkingFlow 2, ApprovalWorkflow 2, ManagedContentAuthoringWorkflow 1, EvaluationFlow 1, FieldServiceMobile 1 |
| Automação | Flow definitions inativas (obsoletas, não apagadas) | 91 |
| Automação | Registros `WorkflowRule` (Workflow Rule clássica, metadata type) | 184 (status ativo/inativo não confirmável por SOQL — ver "Não pôde ser medido") |
| Automação | Apex Triggers ativos / inativos | 85 / 8 (93 total) |
| Código | Classes Apex custom (sem namespace) | 95 (36 nomeadas como teste, 59 de produção) |
| Código | Classes de produção sem `<Classe>Test`/`Test<Classe>` correspondente | 30 de 59 |
| Código | Cobertura de teste Apex — org-wide (`ApexOrgWideCoverage`) | 40% |
| Código | Classes Apex custom por API version | v13: 2, v23: 1, v27: 3, v28: 1, v29: 6, v30: 2, v31: 4, v32: 8, v33: 10, v37: 13, v44: 4, v48: 34, v51: 3, v54: 2, v65: 1, v66: 1 (org hoje em v67) |
| Código | Classes Apex totais (incl. pacotes gerenciados) | 965 |
| Modelo de dados | Objetos custom totais (`sf sobject list --sobject custom`) | 461 (264 de pacotes gerenciados, 197 próprios) |
| Modelo de dados | Campos em Opportunity (total / custom) | 332 / 290 |
| Modelo de dados | Campos em Account (total / custom) | 243 / 194 |
| Modelo de dados | Campos em Contract (total / custom) | 231 / 208 |
| Modelo de dados | Campos em Case (total / custom) | 111 / 68 |
| Modelo de dados | Campos em Contact (total / custom) | 133 / 86 |
| Modelo de dados | Campos em Lead (total / custom) | 86 / 36 |
| Modelo de dados | Registros em Opportunity/Account/Contact/Case/Lead/Contract nesta sandbox | 0 em todos (sandbox de dev sem dados semeados) |
| Segurança | Profiles totais | 77 |
| Segurança | Profiles em uso por usuário ativo (distintos) | 26, dos quais 20 têm exatamente 1 usuário ativo |
| Segurança | Usuários ativos | 38 |
| Segurança | Permission Sets (excl. profile-linked) / Permission Set Groups | 134 / 5 |
| Segurança | Atribuições de Permission Set (excl. profile-linked) | 314 |
| Qualidade de config | Validation Rules ativas / totais | 387 / 648 (261 desativadas, não removidas) |
| Qualidade de config | Record types ativos não-master (Opportunity/Case/Account/Lead/Contract) | 10 / 5 / 3 / 4 / 2 |
| Qualidade de config | Pacotes gerenciados instalados | 18 (inclui SnapERP, PPM, SDocs, Conga Composer, Rollup Helper e DLRS ao mesmo tempo, Survey Force, LoginFlows) |
| Limites | Data/File Storage (sandbox de dev) | 0% usado (200 MB / 200 MB livres — sandbox sem dados) |
| Limites | Licença `Salesforce` (full) — total / usadas | 30 / 29 (97%) |
| Limites | `DailyApiRequests` (24h, sandbox) | 5.000.000 / 4.999.934 livres |

## Achados

### 1. Oportunidade concentra 31 automações ativas, 24 no mesmo evento

- **Severidade:** alta
- **Área:** automação
- **Evidência:** `SELECT ApiName, TriggerObjectOrEventLabel, TriggerType, ProcessType, RecordTriggerType FROM FlowDefinitionView WHERE IsActive=true` (Tooling/data API) devolveu 316 automações ativas na org; agrupando por `TriggerObjectOrEventLabel`, "Oportunidade" aparece em 31 registros — o maior de qualquer objeto. Detalhando: 24 são `RecordAfterSave` com `RecordTriggerType` `Create`, `Update` ou `CreateAndUpdate` (18 delas especificamente `CreateAndUpdate`), mais 3 `RecordBeforeSave`, 3 `Scheduled` e 1 `RecordBeforeDelete`. Nomes incluem `Preenche_Certezas`, `Preenche_OT_anterior`, `Preenche_Previsto_RR_ajustado_Valor_anterior`, `Preenche_compromisso_de_fechamento_anterior`, `Preenchimento_data_de_fechamento_anterior` — cinco flows separados só para preencher campos "anteriores" no mesmo objeto/evento.
- **Risco:** ordem de execução entre Flows do mesmo evento não é garantida de forma legível por quem não abriu os 24 de uma vez; qualquer alteração em Oportunidade (nova automação, mudança de campo) tem chance real de colidir com uma dessas 24 sem que o autor saiba que ela existe. Debugar um comportamento errado em Oportunidade hoje exige ler ~30 componentes antes de achar a causa.
- **Recomendação:** antes de qualquer nova demanda tocar em Oportunidade, mapear as 24 automações `RecordAfterSave`/`RecordBeforeSave` numa planilha de ordem de execução e avaliar consolidação em um ou dois Flows orquestradores por evento (before-save para cálculo de campo, after-save para side-effects), aposentando os de escopo sobreposto (os cinco "preenche X anterior" são candidatos óbvios a virar um único Flow parametrizado).
- **Esforço:** alto

### 2. Process Builder ainda ativo em produção de automação (fim de vida)

- **Severidade:** alta
- **Área:** automação
- **Evidência:** dos 316 registros ativos em `FlowDefinitionView`, 59 têm `ProcessType = 'Workflow'` — que é como a Salesforce expõe Process Builder nessa view (tecnologia sem suporte a novos recursos desde 2021 e em ciclo de retirement anunciado pela Salesforce).
- **Risco:** Process Builder não recebe features novas, tem performance pior que Flow em volume e será desativado em uma data futura pela Salesforce sem aviso individual por org — qualquer automação de negócio ainda nele quebra nesse dia sem plano de migração.
- **Recomendação:** inventariar os 59 Process Builders ativos, priorizar por objeto de maior automação (Oportunidade, Projeto Agility, Caso aparecem no achado #1 e #4) e migrar para Flow via `sf project retrieve start --metadata Flow`, revisão funcional e novo deploy — não é reescrita 1:1 mecânica, cada um precisa de leitura de regra de negócio.
- **Esforço:** alto

### 3. Cobertura de teste Apex da org em 40%

- **Severidade:** alta
- **Área:** código
- **Evidência:** `SELECT PercentCovered FROM ApexOrgWideCoverage` (Tooling API) devolveu `40`. Este número é agregado da org inteira (inclui pacotes gerenciados, que normalmente não contam contra o mínimo de deploy, mas o valor bruto retornado foi este).
- **Risco:** abaixo dos 75% mínimos que a Salesforce exige para deploy em produção — qualquer deploy real dependeria de escrever teste novo às pressas ou mirar só as classes tocadas, empurrando dívida para frente. Também está bem abaixo do padrão de 85% por classe deste squad (`CLAUDE.md` raiz).
- **Recomendação:** rodar `sf apex run test --code-coverage --result-format json` no /* próximo ciclo com escrita */ para ter cobertura por classe (não pôde ser rodado aqui por não alterar/gerar artefatos de execução de teste sem avaliação prévia do humano) e atacar primeiro as 30 classes do achado #4, que não têm teste dedicado algum.
- **Esforço:** alto

### 4. 30 das 59 classes Apex de produção não têm classe de teste dedicada

- **Severidade:** média
- **Área:** código
- **Evidência:** listagem de `ApexClass WHERE NamespacePrefix = null` (95 classes) cruzada por nome: 59 não seguem convenção de nome de teste (`*Test`/`Test*`); dessas, 30 não têm nenhuma classe `<Nome>Test`/`Test<Nome>` correspondente na mesma lista — entre elas `PPMProjectTriggerHandler`, `SolicitacaoCoffeeBreakTriggerHandler`, `SolicitacaoPassagemAereaTriggerHandler`, `LancamentoDespesasTriggerHandler`, `SolicitacaoReembolsoTriggerHandler`, `PropostasSolucaoTriggerHandler`, `LancamentoCreditoProjetoTriggerHandler` (handlers de trigger de objetos de negócio) e classes utilitárias como `wsSalesForce`, `MyXmlParser`, `ReportFinderUtil`.
- **Risco:** trigger handlers sem teste dedicado são exatamente onde regressão silenciosa acontece — mudar um deles hoje não tem rede de segurança própria, só cobertura incidental de outros testes que passam por ali.
- **Recomendação:** priorizar os 7 `*TriggerHandler` sem teste (ligados a objetos com volume de automação alto) e criar `<Classe>Test` cobrindo os cenários de create/update que o handler resolve.
- **Esforço:** médio

### 5. Classes Apex em API version muito atrás da org (v67 hoje)

- **Severidade:** média
- **Área:** código
- **Evidência:** `SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null` mostra 2 classes em API v13, 1 em v23, 3 em v27, 1 em v28, 6 em v29, 2 em v30, 4 em v31, 8 em v32 e 10 em v33 — 27 das 95 classes custom estão em API version anterior a 2015 (v33 foi lançada em 2015; a org está em v67/2026).
- **Risco:** classes em API version muito antiga rodam com comportamento de segurança/runtime congelado daquela época (ex.: regras de sharing e de validação de referência mudaram entre versões) — silenciosamente diferente do resto do código, e um recompile forçado (ex.: por um pacote novo) pode expor comportamento nunca visto em produção.
- **Recomendação:** revisar as 27 classes pré-v33 uma a uma; para as que ainda estão em uso ativo, subir API version em lote pequeno com bateria de teste manual antes/depois (subir API version não é no-op — pode mudar comportamento).
- **Esforço:** médio

### 6. Perfil por pessoa em vez de permission set

- **Severidade:** média
- **Área:** segurança
- **Evidência:** `SELECT ProfileId, COUNT(Id) cnt FROM User WHERE IsActive=true GROUP BY ProfileId` devolveu 26 perfis distintos em uso pelos 38 usuários ativos; 20 desses 26 perfis têm exatamente 1 usuário ativo associado. A org tem 77 perfis cadastrados no total. Em paralelo, há 134 Permission Sets e 314 atribuições ativas (excluindo as ligadas a perfil) — ou seja, o modelo de permission set já é usado, mas convive com perfil individualizado.
- **Risco:** perfil por pessoa multiplica o custo de qualquer mudança de acesso (2× a superfície de manutenção: perfil + permission set) e dificulta auditoria — "quem pode ver X" vira uma pergunta sem resposta única.
- **Recomendação:** para os 20 perfis com 1 usuário, migrar a diferença de acesso individual para permission set e consolidar os usuários num perfil-base por função; não requer decisão de arquitetura pesada, é reorganização.
- **Esforço:** médio

### 7. Dois motores de rollup instalados ao mesmo tempo (Rollup Helper + DLRS)

- **Severidade:** baixa
- **Área:** qualidade de config
- **Evidência:** `sf package installed list` lista, entre os 18 pacotes gerenciados instalados, tanto "Rollup Helper" (22.7.0.14) quanto "Declarative Lookup Rollup Summaries Tool" (2.9.0.1) — duas ferramentas que resolvem o mesmo problema (rollup declarativo sem código). Também aparece um Apex trigger próprio em `dlrs__LookupChild__c` e `dlrs__LookupRollupSummary__c` (do pacote DLRS), confirmando uso ativo de pelo menos um dos dois.
- **Risco:** manter dois pacotes com sobreposição de função aumenta a superfície de manutenção e de erro (rollup que deveria estar num lugar acaba configurado no outro, sem padrão único).
- **Recomendação:** inventariar quais rollups vivem em cada pacote e planejar consolidação num só, aposentando o outro numa janela de manutenção controlada.
- **Esforço:** baixo

### 8. 261 Validation Rules e 91 Flow definitions desativadas, não removidas

- **Severidade:** baixa
- **Área:** qualidade de config
- **Evidência:** `SELECT COUNT() FROM ValidationRule` (Tooling API) devolveu 648 no total contra 387 com `Active=true` — 261 desativadas. `SELECT COUNT() FROM FlowDefinitionView WHERE IsActive=false` devolveu 91, contra 407 definitions totais.
- **Risco:** regra/automação desativada continua ocupando espaço mental de quem lê a lista de metadata da org, sem sinalizar se foi desligada por engano, por substituição ou por decisão definitiva — aumenta o tempo de qualquer recon futuro.
- **Recomendação:** revisão de limpeza: confirmar com o time de negócio quais dessas 261+91 já não têm motivo de existir e removê-las num lote dedicado (não é alteração de comportamento, é remoção de morto).
- **Esforço:** baixo

### 9. Licença `Salesforce` (full) em 97% de uso

- **Severidade:** média
- **Área:** limites
- **Evidência:** `SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE TotalLicenses > 0` devolveu `Salesforce: TotalLicenses=30, UsedLicenses=29`.
- **Risco:** este número reflete o snapshot da sandbox de dev (herdado do último refresh de produção) — pode não ser o consumo atual de produção, mas se for próximo, qualquer usuário novo trava até liberar ou comprar licença.
- **Recomendação:** confirmar o número real em produção (fora do escopo deste agente — guardrail #1) antes de qualquer projeto que preveja novos usuários.
- **Esforço:** baixo

## Não pôde ser medido

- **Cobertura de teste por classe** — só o agregado org-wide (40%) foi obtido via `ApexOrgWideCoverage`. Cobertura por classe individual exigiria `sf apex run test --code-coverage`, que executa testes (roda Apex) — decidi não rodar nesta etapa read-only sem alinhamento prévio sobre o impacto de rodar toda a suíte de testes numa sandbox compartilhada; fica como recomendação para a próxima etapa, não como número inventado aqui.
- **Sharing settings / Organization-Wide Defaults por objeto** — `sf sobject describe` (REST) não expõe `sharingModel` no JSON retornado por este CLI (confirmado inspecionando as chaves do retorno para Account, Opportunity, Case, Contact, Lead e Contract); obter OWD de forma confiável exigiria retrieve de metadata de Security Settings via Metadata API, não coberto pelos comandos padrão da skill `org-recon` usados aqui.
- **Status ativo/inativo de `WorkflowRule` (Workflow Rule clássica)** — o objeto Tooling `WorkflowRule` devolveu 184 registros totais, mas não expõe um campo queryable por SOQL (`IsActive`/`Active` não existem nesse objeto) para diferenciar ativo de inativo sem um retrieve completo de metadata por objeto.
- **Campos sem descrição** — `sf sobject describe` (API REST padrão) não retorna o atributo `description` de campo (confirmado inspecionando as chaves de um campo custom em Opportunity); isso só está disponível via Metadata API `readMetadata`/retrieve completo de `CustomField` por objeto, que não foi feito para os 197 objetos custom próprios por escopo de tempo desta etapa.
- **Referências a metadata inexistente / dependências quebradas** — checar isso de forma confiável exigiria ou um `sf project deploy validate` completo (que baixa e valida todo o `force-app`, operação pesada e fora do escopo desta etapa read-only rápida) ou consulta a `MetadataComponentDependency`, que não é garantidamente habilitada/performática nesta org via CLI simples. Não foi tentado.
- **Volume real de dados em produção** — a sandbox de dev auditada está com 0 registros em Opportunity/Account/Contact/Case/Lead/Contract (`SELECT COUNT()` confirmado em todos), ou seja, é uma sandbox sem massa de dados seedada. Achados sobre volume/armazenamento não podem ser extrapolados desta sandbox para produção — produção está fora do alcance deste agente por guardrail (#1).
- **Contagem de perfis "custom" vs "padrão Salesforce"** — o objeto `Profile` não expõe um flag confiável de "é custom" via SOQL simples (`UserType` descreve a licença associada, não se o perfil foi clonado/criado); o número usado no achado #6 (perfis com exatamente 1 usuário ativo) é medição direta e não depende dessa distinção.

## Recomendações completas (ordem de prioridade)

1. Consolidar/reorganizar as 31 automações de Oportunidade, especialmente as 24 no mesmo evento (alta, automação)
2. Migrar os 59 Process Builders ativos para Flow antes do retirement da Salesforce (alta, automação)
3. Elevar a cobertura de teste Apex de 40% para o mínimo de produção (alta, código)
4. Criar classes de teste dedicadas para as 30 classes/handlers sem `<Classe>Test` (média, código)
5. Atualizar API version das 27 classes pré-v33 (média, código)
6. Migrar os 20 perfis de 1 usuário para modelo perfil-base + permission set (média, segurança)
7. Confirmar consumo real de licença `Salesforce` em produção antes de novo projeto (média, limites)
8. Consolidar Rollup Helper e DLRS num único motor de rollup (baixa, config)
9. Limpar as 261 validation rules e 91 flows desativados e não removidos (baixa, config)
