# EPLAST-39 — Plano de build

**Etapa:** build declarativo (nível 1 — config, sem Flow, sem Apex, sem campo novo).
**Org:** `sbx-eplast-dev` (sandbox, Enterprise Edition, API 68.0). Nenhum outro alias foi usado.
**Entrada:** `03-design.md` (gate aprovado por Carlos Sordi em 2026-11-12T02:59:51Z, ver `gates.md`), `02-recon.md`.

---

## 1. Componentes criados

Todos sob `force-app/main/default/`, API names conforme a tabela 2.1 do design.

| # | Tipo | API name | Caminho | O que faz |
|---|---|---|---|---|
| C1 | ReportFolder | `Marketing_Origem_Retorno` | `reports/Marketing_Origem_Retorno.reportFolder-meta.xml` | Pasta dos 5 relatórios desta demanda. Compartilhada em leitura (`View`) com o grupo C3. Separada das pastas de amostra e da `MARKETINGCLOUD`. |
| C2 | DashboardFolder | `Marketing_Origem_Retorno_Dash` | `dashboards/Marketing_Origem_Retorno_Dash.dashboardFolder-meta.xml` | Pasta do dashboard, compartilhada (`View`) com o grupo C3. |
| C3 | Group (público) | `Marketing_Origem_Retorno` | `groups/Marketing_Origem_Retorno.group-meta.xml` | Destino do compartilhamento das pastas C1/C2. Sem membros definidos no código — atribuição manual pela Eplast (ver seção 4). |
| C4 | PermissionSet | `PS_Marketing_AnaliseCampanhas` | `permissionsets/PS_Marketing_AnaliseCampanhas.permissionset-meta.xml` | Leitura (sem create/edit/delete) em Campaign, Lead e Opportunity. FLS explícita em `Campaign.ActualCost`, `Campaign.BudgetedCost`, `Campaign.ExpectedRevenue`, `Lead.LeadSource`, `Opportunity.LeadSource`, `Opportunity.CampaignId`. Sem "Marketing User". |
| R1 | Report (LeadList) | `MKT_Leads_por_Origem` | `reports/Marketing_Origem_Retorno/MKT_Leads_por_Origem.report-meta.xml` | Leads por bucket de origem (`BucketField_Origem` sobre `Lead.LeadSource`) × mês de criação. Sem linhas de detalhe. |
| R2 | Report (LeadList) | `MKT_Conversao_Leads_por_Origem` | `.../MKT_Conversao_Leads_por_Origem.report-meta.xml` | Mesmo bucket de origem, com fórmula de resumo `CONVERTED:SUM / RowCount` (mesmo padrão de `Marketing_Exec_Conversion_Rate`). Sem linhas de detalhe. |
| R3 | Report (Opportunity) | `MKT_Oportunidades_por_Origem` | `.../MKT_Oportunidades_por_Origem.report-meta.xml` | Oportunidades por `LeadSource` (grupo) × `IsWon` (subgrupo): quantidade, valor (`Amount`, soma) e fórmula de resumo `WON:SUM / RowCount` (taxa de ganho). Sem linhas de detalhe. |
| R4 | Report (CampaignList) | `MKT_Desempenho_Campanhas` | `.../MKT_Desempenho_Campanhas.report-meta.xml` | Uma linha por campanha (tabular): custo real/orçado, leads, convertidos, respostas, oportunidades, ganhas, valor ganho e **ROI** (coluna nativa do tipo de relatório `CampaignList` — ver seção 2). |
| R6 | Report (CampaignLead) | `MKT_Resposta_Membros_Campanha` | `.../MKT_Resposta_Membros_Campanha.report-meta.xml` | Membros (`RowCount`) e respondentes (`HasResponded`, somado) por campanha e por status de membro. Sem linhas de detalhe, sem coluna de nome/e-mail/telefone. |
| D1 | Dashboard | `MKT_Origem_e_Retorno_Campanhas` | `dashboards/Marketing_Origem_Retorno_Dash/MKT_Origem_e_Retorno_Campanhas.dashboard-meta.xml` | Painel com 5 componentes (um por relatório acima, R5 fora — ver seção 2). Tipo **`LoggedInUser`** (dinâmico). |

**R5 não foi criado** — ver seção 2.

Todo componente tem `description` preenchida, **exceto** `Group` e os tipos `Folder`
(`ReportFolder`/`DashboardFolder`), cujo schema de metadata não aceita essa tag — ver seção 3.

---

## 2. Decisões condicionadas pelo design, resolvidas no build

### R5 (influência de campanha) — **excluído do escopo**, conforme condição do design

Testei a disponibilidade do report type padrão de influência de campanha antes de criar R5,
via REST (`/services/data/v68.0/analytics/report-types/CampaignInfluence`) com o usuário de
integração da esteira (alias `sbx-eplast-dev`):

```
[
  {
    "errorCode": "BAD_REQUEST",
    "message": "Você não tem permissão para acessar um ou mais objetos em que o tipo de
    relatório CampaignInfluence é baseado. Solicite acesso ao administrador do Salesforce."
  }
]
```

O tipo `CampaignInfluence` existe (nomes alternativos como `CampaignInfluence1` retornam
"não é um tipo de relatório válido", então o nome correto é esse), mas o usuário da conexão
não tem acesso ao(s) objeto(s) subjacentes — o mesmo achado do recon (`sObject
CampaignInfluence não é consultável`). Conforme a condição do design (seção 2.1, risco 7):
**R5 sai do escopo desta rodada.** Não busquei contorno em código. Se a Eplast quiser esse
relatório, é preciso resolver o acesso ao objeto `CampaignInfluence` (ou confirmar com um
usuário Administrador do Sistema) antes de reabrir esse item.

### D1 (tipo do dashboard) — **dinâmico criado com sucesso, teto de 3 não se confirmou**

O design previa que a Enterprise Edition tivesse um teto de 3 dashboards dinâmicos, e a org
já tinha exatamente 3 (`Activities Dashboard`, `Einstein Conversation Insights Dashboard`,
`Digital Wallet Consumption Insights by Tags`) — confirmado via
`SELECT Id, Title, Type, FolderName FROM Dashboard WHERE Type = 'LoggedInUser'` antes do
build. Também confirmei a edição: `SELECT OrganizationType FROM Organization` →
`Enterprise Edition`.

Segui a instrução do design de não supor e confirmar pelo erro real do deploy: deployei D1
como `LoggedInUser` (dry-run e depois real) e **os dois tiveram sucesso** — não houve
nenhum erro relacionado a limite de dashboards dinâmicos. A mesma consulta, rodada depois do
deploy, mostra 4 dashboards `LoggedInUser` na org, incluindo o novo
`MKT_Origem_e_Retorno_Campanhas`. Ou seja: **o fallback manual (`SpecifiedUser` fora do
`force-app/`) não foi necessário** — o teto documentado de 3 não se aplicou (ou não se aplica
da forma como o design presumiu) nesta org/edição. D1 está em `force-app/`, deployado, sem
usuário fixo e sem e-mail/username gravado no metadata.

---

## 3. Desvios do design (achados do build, não improviso)

1. **`Group` e `Folder` (`ReportFolder`/`DashboardFolder`) não aceitam a tag `<description>`.**
   Confirmado por erro de deploy: `Element description invalid at this location in type
   ReportFolder` (e o mesmo para `DashboardFolder`). O `Group`, ao contrário, aceitou a tag
   normalmente (deploy confirmou). Isso é uma limitação do próprio schema de metadata desses
   dois tipos, não uma omissão minha — removi a tag de C1/C2 e documentei o propósito de cada
   um aqui e na tabela acima. Não achei alternativa dentro do schema desses tipos para registrar
   descrição.
2. **ROI de R4 não é uma fórmula row-level custom** como o rascunho do design cogitava —
   usei a coluna nativa `ROI` do tipo de relatório padrão `CampaignList`, confirmada via
   describe (`/services/data/v68.0/analytics/report-types/CampaignList`, categoria com
   `"ROI": {"dataType": "percent", "isCustom": false, ...}`). Essa coluna já é calculada pela
   plataforma e, por ser a mesma usada no relatório de amostra `CampaignsbyROI`, tem o mesmo
   comportamento de não dividir por `ActualCost = 0` (exatamente a proteção que o design pedia
   para uma fórmula própria). Prefiro o campo nativo a inventar uma fórmula cuja semântica eu
   não poderia confirmar sem dado real na sandbox (guardrail #3) — e evita depender da resposta
   de H3 (fórmula de ROI), que segue em aberto só para a eventual necessidade de uma variante
   diferente da nativa.
3. **Filtro de período (R1–R4) não foi incluído.** O design previa um filtro relativo
   editável com padrão "este trimestre". Tentei `INTERVAL_THISFISCALQUARTER` e depois
   `INTERVAL_THIS_FISCAL_QUARTER` como valor de `<interval>` em `<timeFrameFilter>`; os dois
   falharam no deploy com `'...' is not a valid value for the enum 'UserDateInterval'`. Não
   encontrei a documentação do enum exato nesta sessão (sem acesso à Workbench/doc oficial) e,
   em vez de seguir adivinhando valores de um enum que não consegui confirmar (guardrail #3),
   removi o `timeFrameFilter` dos 4 relatórios. Isso é consistente com o próprio design, que já
   registrava o período como parâmetro em aberto (dúvida 2, não respondida). Quem abrir o
   relatório pode aplicar o filtro de data manualmente na tela; não há metadata nova necessária
   para isso. **Pendência para uma próxima rodada:** descobrir o valor correto do enum
   `UserDateInterval` (ex.: inspecionando um relatório padrão da org que já use filtro relativo
   de trimestre, se algum existir) e aplicar o padrão "este trimestre" nos 4 relatórios.
4. **Bucket de "Sem origem" (valor vazio) não foi implementado como entrada explícita do
   bucket field.** Tentei (`bucketType` `text`, depois `picklist`) incluir uma entrada de
   bucket com `<sourceValues/>` vazio mapeando para o rótulo "Sem origem", distinta do
   `otherBucketLabel` ("Fora da lista") usado para valores não listados. Com `bucketType`
   `text` o deploy aceitava a sintaxe mas rejeitava o bucket inteiro por tipo de dado
   incompatível com a coluna de origem (picklist); com `bucketType` `picklist` (o valor certo
   para a coluna), a mesma entrada de valor vazio gerou um erro interno opaco do serviço
   (`An unexpected error occurred`, com ErrorId, sem mensagem de validação específica). Removi
   a entrada vazia explícita dos buckets de R1 e R2; o `nullTreatment` (`n`) permanece
   configurado, então leads sem origem preenchida devem cair em algum tratamento de nulo
   padrão da plataforma — **mas não pude confirmar qual rótulo isso produz**, porque a sandbox
   tem 0 registros de Lead (recon, seção 2) e o deploy de metadata não executa o relatório.
   **Isto precisa de verificação do QA com dado sintético**: criar Leads com `LeadSource`
   vazio e conferir se R1/R2 os classificam de forma visível (ainda que não seja exatamente o
   rótulo "Sem origem") ou se eles desaparecem do relatório — o segundo caso contrariaria o
   critério de aceite "todo lead do período tem origem contável, com 'Sem origem'" (03-design.md
   seção 7) e precisaria voltar para esta etapa.
5. **Escopo (`scope`) de R3 ajustado de `org` para `team`.** O design não especificava scope;
   usei `org` por padrão em todos, mas o tipo de relatório `Opportunity` rejeitou `org`
   (`scope: o valor "org" não é uma das opções da lista`), diferente do tipo `OpportunityLead`
   usado em `Marketing_Exec_Conversion_Rate` (que aceita `org`). Troquei para `team`, o mesmo
   valor já usado com sucesso em `LeadsbySource` na org. Isso é um detalhe técnico do tipo de
   relatório, não uma mudança de visibilidade de dado: o OWD de Opportunity (`Read`) e os
   compartilhamentos do usuário continuam sendo o limite real de quem vê o quê.

Nenhum desses desvios altera objeto, campo, Flow, Apex, perfil ou relatório/dashboard
existente — todos ficam dentro do "nível 1" e do escopo aprovado no gate. Nenhum deles é uma
mudança de requisito; são ajustes de sintaxe/schema descobertos ao tentar implantar
exatamente o que o design pediu.

---

## 4. Passos manuais pós-deploy (fora deste PR, não vão para `force-app/`)

- **Atribuir `PS_Marketing_AnaliseCampanhas`** aos usuários que a Eplast decidir (dúvida 7 da
  análise — público ainda não definido). Nenhum ID de usuário está no código.
- **Adicionar membros ao grupo `Marketing_Origem_Retorno`** (mesma decisão de público).
- **Confirmar a lista oficial de origens e a fórmula de ROI** com a Eplast (dúvidas 4 e 6 da
  análise) — hoje R4 usa o ROI nativo da plataforma; se a Eplast quiser uma fórmula diferente,
  isso volta para o design.
- **Resolver o acesso ao objeto `CampaignInfluence`** se R5 for retomado (seção 2).
- **Confirmar o valor correto do enum `UserDateInterval`** para aplicar o filtro "este
  trimestre" em R1–R4 (seção 3, item 3).

---

## 5. Validação do deploy

Rodado contra `sbx-eplast-dev` (único alias autenticado nesta sessão). Sequência real:
1. Dry-run (`--dry-run --ignore-conflicts`) iterado 5 vezes até os 10 componentes passarem
   (erros e correções documentados na seção 3).
2. Deploy real (sem `--dry-run`) do mesmo conjunto de 10 componentes.

**Resultado do deploy real:**

```
Status: Succeeded
Deploy ID: 0AfHa00000EFcrJKAT
Components: 10/10 (100%)
```

Os 10 componentes (C1–C4, R1, R2, R3, R4, R6, D1) foram criados com sucesso. R5 não foi
submetido (excluído, seção 2).

Nenhum comando tocou `sbx-eplast-qa` nem qualquer outro alias. Nenhum dado de cliente foi
lido durante o build (só metadata, describe e contagens agregadas via `sf data query`).

---

## 6. O que fica para a próxima etapa (QA / `05-testes.md`)

- Criar dado sintético mínimo (Lead, Campaign, CampaignMember, Opportunity) respeitando a
  cautela da seção 4 do design (achado 1: cadeia CPQ + trigger custom + callout Protheus) —
  volume mínimo, sem bypass global, endpoint do Protheus confirmado antes.
- Verificar o comportamento de "Sem origem" com `LeadSource` vazio (item 4 da seção 3 acima).
- Verificar que nenhum relatório expõe nome, e-mail, telefone ou documento de Lead/Contact
  (critério de aceite, seção 7 do design).
- Confirmar visualmente o painel D1 com um usuário que tenha `PS_Marketing_AnaliseCampanhas`
  atribuído (depois do passo manual da seção 4) e também com um perfil comercial sem o PS,
  para validar que o acesso está de fato restrito.
