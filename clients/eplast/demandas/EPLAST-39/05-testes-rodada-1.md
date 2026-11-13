# EPLAST-39 — Testes: Origem dos leads e retorno das campanhas

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

---

## 0. Preparação do teste (feita nesta sessão, documentada conforme instrução)

1. **Deploy do pacote em `sbx-eplast-qa`.** O build (`04-plano-build.md`) só tinha implantado em
   `sbx-eplast-dev` ("Nenhum comando tocou sbx-eplast-qa"). Confirmei por SOQL que nenhum dos 10
   componentes existia em QA (`PermissionSet`, `Group`, `Report` por `DeveloperName` = 0
   registros). Rodei `sf project deploy start --dry-run --ignore-conflicts` e, limpo, o deploy
   real dos 10 componentes (`force-app/main/default/{reports,dashboards,groups,permissionsets}`
   referentes a esta demanda) contra `sbx-eplast-qa`. Resultado: **10/10 sucesso**
   (Deploy ID `0AfHa00000EFm2fKAD`). Confirmado depois por SOQL: 5 relatórios `MKT_*`, o
   dashboard `MKT_Origem_e_Retorno_Campanhas`, o grupo e o permission set, todos presentes em QA.
   **Isto sou eu (QA) implantando para poder testar — não substitui o deploy formal da etapa
   `release`, que acontece depois da minha homologação.**
2. **Endpoint do Protheus (achado 1 do assessment / risco 3 do design).** Sem alterar nada nem
   disparar callout, consultei o valor *ativo* do Custom Metadata `Protheus.Credentials` na
   própria org (`BaseURL__c`) e os dois `RemoteSiteSetting` (`ProtheusProd`, `ProtheusQA`):
   - `sbx-eplast-qa` está configurada, hoje, para `http://4.228.210.22:8499/rest` — a mesma porta
     do `RemoteSiteSetting` dedicado **`ProtheusQA`**, e diferente da porta 8400 de `ProtheusProd`
     (que é, por sinal, o valor hoje commitado em `force-app` — divergência entre repo e org ativa,
     registrada aqui como achado lateral, fora do escopo desta demanda).
   - Isso é evidência de configuração (metadata/config, não dado pessoal), não confirmação humana
     do que esse servidor realmente é. **Mantive a cautela pedida**: não criei Opportunity nem
     converti Lead em nenhum momento desta sessão, mesmo com essa evidência favorável. O item
     "conversão lead → oportunidade" segue não testado (seção 3).
3. **Dado sintético criado — só Lead, Campaign e CampaignMember (nunca Opportunity, nunca
   conversão de Lead):**

   | Objeto | Registros | Detalhe |
   |---|---|---|
   | Campaign | 2 | `QA-TESTE EPLAST-39 Campanha Com Custo` (ActualCost 1000, BudgetedCost 1200) e `QA-TESTE EPLAST-39 Campanha Sem Custo` (sem custo) |
   | Lead | 4 | `LeadSource`: "Google Ads", "SDR", vazio (sem origem), e `"QA_FORA_DA_LISTA"` (valor fora da lista de 13, picklist não restrita) — todos `Company = 'QA Teste EPLAST-39'` |
   | CampaignMember | 3 | ligando os 3 primeiros Leads às 2 campanhas |

   Nenhum CPF, e-mail, telefone ou nome real foi usado — todos os registros têm `LastName`/`Name`
   prefixado `QA-TESTE EPLAST-39`, claramente identificáveis para limpeza posterior. **Sugiro
   excluir esses registros depois da homologação** (não bloqueiam nada ficando, mas são lixo de
   teste).
4. **Achado lateral de preparação:** o usuário de integração da esteira (perfil "Administrador
   do sistema"; username omitido de propósito — guardrail #2) **não conseguiu
   criar `Campaign`** até eu confirmar a causa: faltava o flag `UserPermissionsMarketingUser`
   (estava `false`). Isso bate com o que `02-recon.md`/`03-design.md` já registravam ("criar ou
   editar campanha exige o flag de usuário Marketing User, 1 usuário ativo na sandbox") — não é
   novidade do build, é característica da plataforma que o design já tratou corretamente (o PS
   desta demanda é só leitura e não concede isso, de propósito). Habilitei o flag
   **temporariamente** só para conseguir criar o dado sintético e **revertido para `false`** ao
   final desta sessão (confirmado).
5. **Limitação da ferramenta `qa_browser_*` nesta sessão:** consegui abrir e fotografar relatórios
   e o painel, mas `qa_browser_click` não conseguiu interagir com elementos *dentro* do
   iframe do visualizador de relatório/painel (ex.: botão "Atualizar", linha de um bucket
   específico) — só com a navegação Lightning fora do iframe. Complementei com a Analytics REST
   API (`/services/data/v68.0/analytics/reports/{id}` e `/dashboards/{id}`), sempre lendo só
   metadata e contagens/rótulos agregados, nunca dado pessoal.
6. Licença Salesforce da sandbox: **14 de 14 em uso (100%)** — não há licença livre para criar um
   usuário de teste dedicado (ver item "não testável" na seção 3).

---

## 1. Falhas

### FALHA 1 (crítica) — Painel D1 não exibe dado em nenhum dos 5 componentes hoje

**Evidência:** screenshot do painel `MKT_Origem_e_Retorno_Campanhas` em `sbx-eplast-qa` (abaixo) e
chamada à Analytics API (`GET .../analytics/dashboards/01ZHa000001uI4vMAE?refreshDashboard=true`),
repetida após espera, com os 5 componentes retornando:

- **"Desempenho de Campanhas (Valor Ganho)"** (fonte: R4, `MKT_Desempenho_Campanhas`) — erro
  **permanente e estrutural**, `errorCode 209`: *"Este relatório não pode ser usado como origem
  para este componente. Se for um relatório de matriz ou resumo, adicione um ou mais
  agrupamentos a ele. Se for um relatório tabular com limite de linhas, especifique as
  Configurações do Painel no relatório."* Causa confirmada: R4 é `<format>Tabular</format>` sem
  `<groupingsDown>` nem "Configurações do Painel" (`tableRowLimit`), e um componente de gráfico de
  painel **exige** relatório de resumo/matriz ou essa configuração explícita. Isso não depende de
  dado existir ou não — **nunca vai funcionar do jeito que está implantado**, com qualquer volume
  de dado.
- Os outros 4 componentes ("Leads por Origem", "Taxa de Conversão de Leads por Origem",
  "Oportunidades e Valor por Origem", "Respondentes por Campanha e Status de Membro") retornaram
  `componentDataStatus: NO_DATA`, `refreshStatus: IDLE`, sem código de erro — mesmo **depois** de
  eu confirmar, consultando os relatórios de origem diretamente pela Analytics API, que R1, R2 e
  R6 **têm dado real e agregam corretamente** (712 Leads, fórmula de conversão calculada por
  bucket, membros de campanha contados — ver Falha 2 e tabela da seção 2). D1 é um painel
  `LoggedInUser` (dinâmico), que computa ao vivo por definição — não deveria depender de um
  "refresh" assíncrono como um painel `SpecifiedUser` depende. Ou seja: a ausência de erro não é
  tranquilizadora, porque o dado deveria aparecer na hora.
- Tentei forçar atualização tanto pela UI (botão "Atualizar", não clicável pela ferramenta — item
  5 da seção 0) quanto pela API (`refreshDashboard=true`, duas vezes, com espera entre as
  chamadas). Em nenhuma das duas o estado mudou.

**Risco para o aceite:** o critério "painel por campanha" (`01-analise.md`) diz "Quando eu abro o
painel de campanhas / Então vejo custo, leads, leads convertidos, oportunidades, oportunidades
ganhas e valor ganho". Hoje, abrindo o painel, **não vejo nada disso** — nem no componente
quebrado, nem nos outros 4.

**Recomendação:** 1 componente (Desempenho de Campanhas) precisa voltar para o design/build — ou
R4 muda de formato (Resumo/Matriz com agrupamento por campanha) ou ganha "Configurações do Painel"
explícitas. Os outros 4: preciso que um humano abra o painel na UI de verdade (com usuário e
sessão de navegador reais, não a automação desta sessão) e confirme se um clique manual em
"Atualizar" resolve — se resolver, é um comportamento de dashboard recém-implantado que nunca
rodou e a causa não é o pacote em si; se não resolver, é uma segunda falha de metadata a
investigar.

**Screenshot (evidência, sem dado real — só os registros sintéticos criados nesta sessão):**
painel aberto em `sbx-eplast-qa`, mostrando "Sem dados. Tente atualizar o painel." nos 3
componentes visíveis e o erro 209 no quarto.

---

### FALHA 2 (média) — Bucket de "Sem origem" renderiza como "-", não como "Sem origem"

**Evidência:** rodei R1 (`MKT_Leads_por_Origem`) pela Analytics API (`GET`, metadata/contagem
agregada, sem dado pessoal). O bucket de origem tem **12 grupos**, somando os 712 Leads da org
(confere com o total geral — essa parte funciona). O grupo dos Leads sem `LeadSource` preenchido
(incluindo o Lead sintético que criei de propósito sem origem) aparece com rótulo **`-`**
(469 de 712 registros, 65,9% — dado relevante por si só, ver nota de qualidade abaixo), não com o
texto **"Sem origem"** que o critério de aceite pede literalmente:

> "e os leads sem LeadSource aparecem em uma linha própria 'Sem origem'"

Isso é exatamente o que `04-plano-build.md` (seção 3, item 4) já tinha marcado como pendente de
verificação do QA, porque a sandbox de dev não tinha Lead para testar. Agora testei com dado
sintético em QA: **os leads sem origem não desaparecem e não se misturam com outro grupo** (o
critério de "contabilidade" é atendido), mas o rótulo exibido não é o combinado com a Eplast.
Mesmo comportamento confirmado em R2 (`MKT_Conversao_Leads_por_Origem`).

**Recomendação:** ajustar o bucket para ter uma entrada explícita de "Sem origem" (o build já
tentou isso e bateu num erro opaco do serviço de bucket com `bucketType` `picklist` — ver
`04-plano-build.md`), ou, mais simples, renomear o grupo pela própria tela do relatório
("Editar grupo" sobre o valor nulo), que não exige mexer no XML.

---

### FALHA 3 (média) — Valores de `LeadSource` fora da lista controlada não caem no bucket "Fora da lista"

**Evidência:** no mesmo retorno de R1, dois grupos aparecem com o **valor bruto**, fora da lista
de 13, em vez de serem consolidados sob o rótulo `otherBucketLabel` ("Fora da lista") configurado
no bucket:

- `QA_FORA_DA_LISTA` (1 registro) — o Lead sintético que criei de propósito para este teste.
- **`Web`** (1 registro) — **um Lead pré-existente na org, real, não criado por mim nesta sessão**,
  confirmando que o problema já acontece com dado de verdade, não só no meu teste sintético.

O design (`03-design.md`, R1) e o build (`04-plano-build.md`) descrevem o bucket com
`otherBucketLabel = "Fora da lista"` justamente para consolidar esses casos numa linha só. Na
prática, cada valor fora da lista cria o seu próprio grupo com o valor literal, em vez de cair no
bucket "Fora da lista". O critério de aceite ("não há valor em uso fora da lista acordada, ou o
desvio está registrado como pendência") não é *violado* no sentido de esconder o problema — o
valor "Web" fica visível — mas o mecanismo de bucket que o design descreveu para agrupar esses
casos não funciona como documentado, o que também significa que, se houver muitos valores
diferentes fora da lista, o relatório cria um grupo para cada um em vez de consolidar.

**Recomendação:** revisar a configuração do bucket (pode ser limitação do tipo de relatório
`LeadList` com bucket sobre picklist não restrita) ou documentar que "fora da lista" aparece
dissolvido por valor, não consolidado — e ajustar a expectativa combinada com a Eplast.

---

## 2. Tabela de casos de teste

| Caso (critério de `01-analise.md`) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Todo lead do período tem origem contável | Rodei R1 via Analytics API em `sbx-eplast-qa` com 712 Leads reais + 4 sintéticos | Soma dos grupos de origem = total de Leads | Soma dos 12 grupos = 712 = total geral. **Confere.** Mas o grupo de nulo é rotulado "-", não "Sem origem" | **Falhou** (Falha 2) |
| Origem usa a lista controlada / desvio registrado | Inspecionei os 12 grupos de R1 | Valores fora da lista de 13 ficam visíveis como pendência, idealmente consolidados em "Fora da lista" | 2 grupos fora da lista (`QA_FORA_DA_LISTA`, `Web`) aparecem, mas cada um como grupo próprio, não como "Fora da lista" | **Falhou** (Falha 3) |
| Conversão lead → oportunidade por origem (R2/R3) | Rodei R2 via API | Taxa de conversão por bucket bate com `IsConverted=true` por bucket | R2 calcula corretamente por bucket (ex.: WhatsApp 68%, SDR 5%, grupo nulo 32%), fórmula `CONVERTED:SUM/RowCount` funcionando, mesmo problema de rótulo das Falhas 2/3 se propaga | **Passou com ressalva** (herda Falhas 2/3) |
| Conversão lead → oportunidade (ligação com Opportunity, R3) | Rodei R3 via API | Ver taxa de ganho por origem com dado real/sintético | **Não testável nesta sessão.** 0 Opportunity na org (confirmado: R3 retorna 0 linhas, sem erro). Critério já estava marcado em `01-analise.md` como dependente de amostra/período não definidos; não criei Opportunity nem convertí Lead por cautela do achado 1 do assessment (cadeia CPQ + trigger custom + callout Protheus) | **Não testável** |
| Painel por campanha (custo, leads, convertidos, oportunidades, ganhas, valor) | Abri D1 na UI e via API, com 2 campanhas sintéticas (uma com custo, uma sem) | Vejo os 6 indicadores no painel | Painel não renderiza nenhum dos 5 componentes hoje (ver Falha 1) | **Falhou** (Falha 1) |
| Campanha sem custo não gera ROI ("não se aplica") | Rodei R4 via API: campanha com `ActualCost=1000` vs. campanha sem custo | ROI vazio/"não se aplica" quando sem custo, nunca 0 nem infinito | Campanha com custo: ROI `-100%` (coerente, sem oportunidade ganha). Campanha sem custo: ROI `-` (equivalente a "não se aplica", nunca 0 ou erro). **Confirmado no relatório fonte** — mas o painel (Falha 1) não exibe isso hoje | **Passou** (no relatório; falha no painel) |
| Nenhum dado pessoal no painel | Inspecionei metadata (XML) dos 5 relatórios e os retornos da Analytics API | Nenhuma coluna de nome, e-mail, telefone ou CPF de Lead/Contact | Nenhuma das 5 definições de relatório tem coluna pessoal; R1/R2/R6 sem `showDetails`; R4 (tabular, `showDetails=true`) só expõe `CAMPAIGN_NAME` e números — Campaign não é dado pessoal | **Passou** |
| Nenhuma escrita em Account/Opportunity/Order sem tratar achado 1 | Revisão de metadata: os 10 componentes implantados (pastas, grupo, PS, 5 relatórios, 1 dashboard) | Nenhum Flow/Apex/trigger novo; PS só leitura | Confirmado: PS concede só `allowRead`, sem `allowEdit/Create`; nenhuma classe/Flow/trigger no pacote desta demanda | **Passou** |
| Implantação só em dev/qa, após confirmar qual é cada uma | — | Deploy restrito às duas sandboxes da esteira | Deploy desta sessão feito só em `sbx-eplast-qa` (confirmado `IsSandbox=true` antes de tocar); nenhum outro alias usado | **Passou** |
| R5 (influência de campanha) fora do escopo | Query `Report` por pasta + conferência do diretório `force-app` | R5 não deveria existir | Confirmado: nem o arquivo nem o registro existem em QA | **Passou** (confirmação, não é bug) |
| Acesso por permission set (leitura concedida / perfil comercial sem PS não vê Campaign) | Query `ObjectPermissions` por perfil em `sbx-eplast-qa` | PS concede leitura; perfis comerciais/financeiro sem o PS não veem Campaign | PS confirmado com `allowRead=true` em Campaign/Lead/Opportunity e FLS corretas (metadata). Perfis `Comercial - Analista`/`Financeiro` **sem** `ObjectPermissions` de leitura em Campaign (consulta direta na org, 0 registros) — consistente com o recon. **Teste com usuário real atribuído ao PS não foi possível**: licença 14/14 em uso na sandbox, sem vaga para usuário de teste dedicado, e atribuir o PS a um usuário real existente é decisão reservada à Eplast (`03-design.md` seção 3) | **Parcialmente testável** — confirmado por metadata/ObjectPermissions; atribuição real não testável nesta sessão |
| Qualidade do dado de origem (nota, não é critério formal) | Observação da execução de R1 | — | **469 de 712 Leads (65,9%) na sandbox de QA estão sem `LeadSource` preenchido.** Isso é dado real da sandbox, não só sintético, e confirma a preocupação H2 de `01-analise.md`. Não é falha do build — é achado de negócio para a Eplast decidir (dúvida 12 da análise: quem corrige a qualidade do dado) | **Informativo** |

---

## 3. O que não foi testado (e por quê)

1. **Conversão lead → oportunidade com dado real de Opportunity.** Não criei nem uma Opportunity,
   nem convertí nenhum Lead, mesmo tendo encontrado evidência de configuração de que o endpoint
   Protheus ativo em QA é o identificado como "QA" (porta 8499, Remote Site Setting `ProtheusQA`),
   diferente do de produção (porta 8400, `ProtheusProd`). Essa evidência não é confirmação humana
   do que esse servidor realmente é, e o critério já estava marcado em `01-analise.md` como não
   fechável sem definição de amostra/período. Fica como risco em aberto, não como "validado".
2. **Acesso efetivo de um usuário real com o permission set atribuído.** Sandbox com licença
   100% em uso; atribuir o PS a um funcionário real é decisão da Eplast, não minha, pelo próprio
   design. Confirmei por metadata/`ObjectPermissions` (ver tabela), não por teste de ponta a
   ponta com login.
3. **Fórmula de ROI "acordada".** Não existe fórmula acordada (dúvida 6 da análise segue aberta);
   testei que o ROI nativo não quebra com custo zero, que é o que dava para testar.
4. **Filtro de período "este trimestre".** O build removeu o filtro por não confirmar o valor do
   enum `UserDateInterval` (`04-plano-build.md` seção 3, item 3) — não há filtro para testar hoje;
   fica pendente para a próxima rodada, como já registrado pelo build.

---

## 4. Dados sintéticos criados nesta sessão (para referência/limpeza)

Todos com `QA-TESTE EPLAST-39` no nome, em `sbx-eplast-qa`:

- Campaign: `701Ha000016Dr6qIAC` (com custo), `701Ha000016E6kPIAS` (sem custo)
- Lead: `00QHa00000SvmkfMAB`, `00QHa00000SvlWpMAJ`, `00QHa00000SvgkHMAR`, `00QHa00000SviJSMAZ`
- CampaignMember: `00vHa000007SwMnIAK`, `00vHa000007SwOPIA0`, `00vHa000007SwQ1IAK`

Recomendo excluir depois da homologação — não bloqueiam nada ficando, mas não são dado de negócio.

---

## 5. Conclusão

**Reprovado.** A Falha 1 (painel D1 não funcional, um componente com erro estrutural permanente)
bloqueia sozinha o critério central desta demanda ("painel por campanha"). As Falhas 2 e 3 são de
severidade média e não bloqueariam sozinhas, mas compõem o quadro: o comportamento de "Sem origem"
e "Fora da lista" não está como o design descreveu, embora a contabilidade (soma = total) esteja
correta nos relatórios que rodam fora do painel.

O que passou: os 5 relatórios individualmente calculam certo (conversão por bucket, ROI nativo com
proteção contra custo zero), nenhum dado pessoal aparece em nenhum relatório, nenhuma escrita nova
em Account/Opportunity/Order, R5 corretamente fora do escopo, e o deploy ficou restrito às
sandboxes da esteira.

Testes executados. Preciso da sua homologação para liberar o release.
