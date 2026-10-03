# Assessment da org — Centric

**Org auditada:** sbx-centric-dev (https://centric-system--sbxdev.sandbox.my.salesforce.com) · **API:** v67.0 · **Data:** 2026-10-03
**Saúde geral:** vermelho

## Veredito em três linhas
A sandbox de dev é Enterprise Edition de verdade (`IsSandbox=true`), sem dado de cliente dentro
(Account/Opportunity/Contact zerados) — o ambiente certo pra construir. Mas a conexão atual não
consegue usar a Metadata API (SOAP) por um descompasso entre o Connected App (emite token JWT) e a
versão da org, o que bloqueia retrieve/deploy e teria que ser resolvido antes da primeira demanda
de build. Dentro do que deu pra medir por API REST/Tooling: Opportunity concentra 17 Flows ativos e
13 validation rules, e a cobertura de teste Apex registrada nesta sandbox está em 0%.

## Inventário

| Item medido | Valor | Comando/fonte |
|---|---|---|
| Edition / tipo de org | Enterprise Edition, Sandbox (`IsSandbox=true`) | `SELECT OrganizationType, IsSandbox FROM Organization` |
| Instância | BRA8S | idem |
| API version da org | v67.0 | `sf org display` |
| Apex classes (total) | 479 | `SELECT COUNT() FROM ApexClass` |
| Apex classes — pacote DocuSign (`dfsle`) | 452 | `SELECT NamespacePrefix, COUNT(Id) ... GROUP BY NamespacePrefix` |
| Apex classes — próprias do cliente (sem namespace) | 27 (14 de produção + 10 de teste + `OmieTest`/`OmieTestData`) | idem |
| Apex triggers | 0 | `SELECT COUNT() FROM ApexTrigger` |
| Cobertura de teste org-wide | 0% | `SELECT PercentCovered FROM ApexOrgWideCoverage` |
| Classes próprias com dado de cobertura, todas em 0% | 16 de 16 | `ApexCodeCoverageAggregate` (Tooling) |
| Flow definitions (total, qualquer status) | 38 definições / 132 versões | `SELECT COUNT() FROM FlowDefinition`; `Flow` (Tooling) |
| Flows ativos | 29 (26 `AutoLaunchedFlow` + 3 `Flow`/screen) | `SELECT ProcessType, Status FROM Flow` |
| Flows ativos referenciando Opportunity (`[Oportunidade]`/`[Produto da Oportunidade]`) | 20 (17 + 3) | nomes dos 29 Flows ativos, Tooling API |
| Process Builder ativo | 0 | nenhum `Flow` com `ProcessType='Workflow'` |
| Workflow Rules | 0 | `SELECT COUNT() FROM WorkflowRule` (Tooling) |
| Validation Rules (total / ativas) | 32 / 26 | `ValidationRule` (Tooling) |
| Validation Rules em Opportunity | 13 (7 ativas, 6 inativas) | idem |
| Objetos custom próprios (sem namespace) | 6 (`Cidade__c`, `Comissao__c`, `In_App_Checklist_Settings__c`, `Inside_Sales__c`, `Pos_Venda__c`, `Prazo_de_Pagamento__c`) | `sf sobject list` |
| Objetos custom via pacote DocuSign (`dfsle__`) | 18 | idem |
| Entidades customizáveis (`__c`), via Tooling | 39 | `EntityDefinition` (Tooling) |
| Campos custom (total org) | 709 | `CustomField` (Tooling) |
| Campos custom sem descrição | 618 (87%) | `CustomField WHERE Description = null` (Tooling) |
| Campos custom em Opportunity / sem descrição | 88 / 88 (100%) | idem, filtrado por `EntityDefinition.QualifiedApiName='Opportunity'` |
| Campos em Account / Lead / Contact / Product2 (total, nenhum perto de 400) | 105 / 78 / 66 / 34 | `sf sobject describe` |
| Perfis (total / custom aparentes) | 25 (perfis com nome próprio do cliente: Admin Sem MFA, Administrador do sistema, Cadastro e Contratos, Comercial, Comercial-API, CPQ Integration User, Gerente de soluções, Gerente do contrato, Usuário do Marketing, Usuário Padrão) | `SELECT Name FROM Profile` |
| Permission Sets (não vinculados a perfil) | 76 | `PermissionSet WHERE IsOwnedByProfile=false` |
| Pacotes gerenciados instalados | DocuSign Apps Launcher (`dfsle`), Sales Insights (`OIQ`), Salesforce Connected Apps/Mobile Apps/CRM Dashboards (padrão SF) | `InstalledSubscriberPackage` (Tooling) |
| Remote Site Settings (endpoints externos ativos) | 10 — `app.omie.com.br`, `api.docusign.net`, `account.docusign.com`, `na2.docusign.net`, `collaboration.docusign.net`, `na.services.docusign.net`, `na21.springcm.com` (x2), `apina21.springcm.com` (x2), `integrationna21.springcm.com` | `RemoteProxy` (Tooling) |
| Named Credentials | 0 | `SELECT COUNT() FROM NamedCredential` (Tooling) |
| Jobs agendados (`CronTrigger`) | 5, todos jobs internos da plataforma (Metalytics, SRT Semantic Graph, ReportType Edge, MciDashboard) — nenhum Apex schedulable próprio | `CronTrigger` |
| Licença "Salesforce" (full) | 17 de 18 usadas (94%) | `UserLicense` |
| Data/File Storage | 0% usado (200MB/200MB livres) | `sf org list limits` — números de sandbox, não refletem produção |
| Registros em Account/Opportunity/Contact | 0 / 0 / 0 (sandbox sem dado de cliente) | `SELECT COUNT() FROM <objeto>` |

## Achados

### 1. Metadata API (SOAP) indisponível nesta conexão — bloqueia build/deploy/retrieve
- **Severidade:** alta
- **Área:** dívida técnica
- **Evidência:** `sf org list metadata --metadata-type Flow` (e os mesmos testes para `WorkflowRule`, `ApexTrigger`, `ApexClass`) e `sf project retrieve start --metadata Flow:...` retornaram, de forma consistente, `SOAP API does not support JWT-based access tokens for API versions below 68.0` — a org está em v67.0, abaixo do piso exigido pelo Connected App atual.
- **Risco:** toda a esteira de demanda depende de `sf project retrieve start`/`deploy` (etapas recon, build, release). Se a próxima sessão de agente tentar construir algo nesta mesma conexão, vai falhar no primeiro retrieve — não é um problema futuro, é um bloqueio hoje.
- **Recomendação:** desligar a opção "Issue JSON Web Token (JWT)-based access tokens" no Connected App/External Client App usado por esta conexão (ou reemitir a autenticação sem esse modo) antes da próxima etapa que precise tocar em metadata. Confirmar depois com um `sf project retrieve start --metadata Flow` de teste.
- **Esforço:** baixo (é uma configuração do Connected App, não da org em si).

### 2. Opportunity concentra 17 Flows ativos + 13 validation rules
- **Severidade:** alta
- **Área:** automação
- **Evidência:** `SELECT MasterLabel, ProcessType, Status FROM Flow WHERE Status='Active'` (Tooling) devolveu 29 Flows ativos, dos quais 17 trazem `[Oportunidade]` no label e mais 3 trazem `[Produto da Oportunidade]` (OpportunityLineItem, objeto filho direto); `ValidationRule` (Tooling) mostra 13 regras em Opportunity (7 ativas).
- **Risco:** 20 pontos de automação declarativa concorrendo no mesmo objeto é terreno fértil pra ordem de execução imprevisível, Flow interferindo com Flow, e qualquer consultor novo levar horas só pra mapear o que já existe antes de tocar em qualquer coisa. Já apareceu nos próprios nomes dos Flows evidência de automação corretiva em cima de outra ("Remover campos de Integração", "Limpar campo..."), sinal de patch sobre patch.
- **Recomendação:** antes da próxima demanda em Opportunity, mapear os 20 Flows num quadro único por evento (criação/edição/antes-depois de salvar) e consolidar o que puder ser consolidado — não dá pra confirmar o evento exato de disparo de cada um por aqui porque isso exige abrir o XML do Flow (ver seção "Não pôde ser medido").
- **Esforço:** alto.

### 3. Cobertura de teste Apex registrada em 0%
- **Severidade:** alta
- **Área:** código
- **Evidência:** `SELECT PercentCovered FROM ApexOrgWideCoverage` devolveu `0`; as 16 classes próprias do cliente com dado em `ApexCodeCoverageAggregate` (toda a família `Omie*`, a integração com o ERP) aparecem com `NumLinesCovered = 0` em 100% delas, apesar de existirem 10 classes de teste dedicadas (`OmieApiClientTest`, `OmieProdutoServiceTest`, etc.).
- **Risco:** produção exige mínimo 75% de cobertura pra aceitar deploy. Com 0% registrado, qualquer deploy de uma classe `Omie*` pra produção falha hoje — não é risco futuro.
- **Recomendação:** rodar a suíte de teste completa nesta sandbox (fora do escopo desta sessão, que é read-only) e confirmar se o número é real ou só reflexo de os testes não terem rodado desde o último refresh/deploy. Se depois de rodar a cobertura continuar baixa, writar teste pra `OmieProdutoRetryBatch` e `OmieServicoRetryBatch`, que não têm classe de teste dedicada aparente.
- **Esforço:** médio.

### 4. 87% dos campos custom sem descrição (100% em Opportunity)
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** `SELECT COUNT() FROM CustomField WHERE Description = null` (Tooling) = 618 de 709 campos custom da org; filtrando por `EntityDefinition.QualifiedApiName='Opportunity'`, os 88 campos custom do objeto têm `Description = null` — 100%.
- **Risco:** ninguém novo no projeto consegue saber pra que serve um campo sem abrir Flow/relatório/VR que o usa. Em um objeto com 20 automações em cima, isso custa caro em investigação toda vez que alguém mexe.
- **Recomendação:** política mínima: todo campo novo exige descrição preenchida (pode virar checklist do `builder-declarativo`); retroativamente, priorizar os 88 campos de Opportunity.
- **Esforço:** médio (é trabalho de preenchimento, não de redesenho).

### 5. Integrações externas via Remote Site Settings, sem Named Credential
- **Severidade:** média
- **Área:** segurança
- **Evidência:** `SELECT COUNT() FROM NamedCredential` = 0; `RemoteProxy` (Tooling) lista 10 endpoints ativos (Omie, DocuSign, SpringCM).
- **Risco:** Remote Site Settings só libera o domínio para callout — a credencial/autenticação fica por conta do código Apex (visto em `OmieApiClient`), sem a camada de cofre de credencial e rotação que Named Credential oferece. É o padrão mais antigo e mais frágil de manter.
- **Recomendação:** migrar ao menos a integração com Omie (código próprio, não pacote) para Named Credential na próxima vez que `OmieApiClient` for tocado.
- **Esforço:** médio.

### 6. Validation rule de endereço obrigatório duplicada entre Lead e Account
- **Severidade:** baixa
- **Área:** qualidade de config
- **Evidência:** `ValidationRule` (Tooling) mostra o mesmo conjunto de 4 nomes — `Campo_rua_obrigatorio`, `Campo_cidade_obrigatorio`, `Campo_Estado_obrigatorio`, `Campo_CEP_obrigatorio` — ativo tanto em `Lead` quanto em `Account`.
- **Risco:** baixo isoladamente, mas é o tipo de padrão que, se precisar mudar a regra de negócio (ex.: tornar CEP opcional pra um tipo de conta), exige lembrar de mexer em dois lugares.
- **Recomendação:** ao tocar em qualquer uma dessas regras, avaliar se dá pra consolidar a lógica (ex.: num Flow de validação compartilhado ou ao menos documentar a dependência cruzada).
- **Esforço:** baixo.

### 7. Perfil "CPQ Integration User" sem nenhum objeto do pacote CPQ instalado
- **Severidade:** baixa
- **Área:** dívida técnica
- **Evidência:** `SELECT Name FROM Profile` lista `CPQ Integration User`; `sf sobject list` não traz nenhum objeto com prefixo `SBQQ__` nem o pacote aparece em `InstalledSubscriberPackage`.
- **Risco:** mínimo, mas é um sinal de configuração órfã — perfil criado para uma integração/pacote que não está (ou nunca esteve) de fato instalado nesta org.
- **Recomendação:** confirmar com o cliente se há CPQ real em produção; se não houver, não vale a pena desenhar nada em cima desse perfil.
- **Esforço:** baixo.

## Não pôde ser medido

- **Sharing settings (OWD) por objeto** — não há como consultar Org-Wide Default via SOQL REST/Tooling; esse dado só sai pela Metadata API (`SecuritySettings`), que está bloqueada nesta conexão (achado #1).
- **Evento exato de disparo de cada Flow (before/after save, criação/edição)** — o objeto `Flow` via Tooling API não expõe `TriggerType`/`RecordTriggerType` por SOQL; isso exige abrir o XML do Flow via `sf project retrieve start`, bloqueado pelo mesmo erro de SOAP/JWT do achado #1. A concentração em Opportunity (achado #2) foi medida pelo nome/label dos Flows e pela contagem, não pelo evento de disparo.
- **Fórmula das Validation Rules e lógica interna dos Flows** — mesma limitação: leitura do corpo/fórmula completa depende de metadata retrieve.
- **Page layouts órfãos e uso real de record types** — a sandbox de dev está com Account/Opportunity/Contact zerados (0 registros), então não há como medir "uso" de nada: qualquer page layout ou record type aqui está, por definição, sem dado de uso nesta cópia.
- **Cobertura de teste real (pós-execução)** — o 0% registrado em `ApexOrgWideCoverage`/`ApexCodeCoverageAggregate` é o último valor computado nesta sandbox; não rodei a suíte de teste (`sf apex run test`) porque isso está fora do escopo read-only desta etapa — não dá pra garantir que o número não é apenas resultado de os testes não terem sido executados desde o último refresh.
- **Componentes legados de automação (Process Builder antigo, Workflow Rule desativada mas não deletada) além do que o Tooling API expõe** — o inventário oficial de metadata (`sf org list metadata`) está bloqueado pelo mesmo erro de SOAP/JWT; os números de Process Builder (0) e Workflow Rule (0) vêm de consulta direta ao Tooling API, que deveria ser equivalente, mas não há uma segunda fonte pra cruzar.
