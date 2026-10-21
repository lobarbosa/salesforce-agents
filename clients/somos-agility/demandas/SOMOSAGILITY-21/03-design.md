# 03 — Design da solução — SOMOSAGILITY-21: Campo origem do Lead

Tipo: **sustentação** (design enxuto). Org consultada: `sbx-somos-agility-dev`
(`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API 68.0,
`Organization.IsSandbox = true`, conferido nesta sessão em 2026-10-21).
Pré-requisito: o gate `aguardando_gate_analise` de `01-analise.md` foi aprovado por Leonardo Barbosa
(ver `gates.md`).

## 0. Checagens extras feitas pelo arquiteto (além do `02-recon.md`)

Todas via `sf` CLI contra `sbx-somos-agility-dev`, só metadata e contagens (guardrail #2).

| Checagem | Resultado | Por que importa |
|---|---|---|
| Flows record-triggered em `Lead` (`FlowDefinitionView`) | Ativos: `Alerta_Diretor_Comercial` (after-save, create), `Alerta_Gerente_de_Contas` (after-save, create+update), `Notifica_se_Novo_Lead_Criado` (after-save, create). Inativo: `ApprovalDispatcher`. **Nenhum before-save ativo em Lead.** | Um before-save novo em Lead não concorre com nenhum outro before-save no mesmo objeto/evento. Os três after-save rodam depois, não leem nem gravam `LeadSource` (conferido na versão ativa de cada um). |
| `Atualizar_Descri_o_com_Informa_es_do_Lead` | O `02-recon.md` o listou como "relacionado a Lead". **Correção: é before-save em `Opportunity`** (create), e o filtro de entrada é `LeadSource = 'Web Site Agility Networks'`. Grava `Opportunity.Description` a partir de `$Record.Descricao_do_Lead__c`. | (a) Evidência adicional para a D-1: alguém já construiu automação esperando que leads do site cheguem com esse valor exato. (b) **Efeito colateral da correção:** hoje esse Flow provavelmente nunca dispara em oportunidades vindas do site, porque o valor nunca chega. Com a correção, ele **passa a disparar** nas oportunidades convertidas desses Leads (o `LeadSource` é copiado na conversão pelo mapeamento padrão). É o comportamento pretendido por quem o construiu, mas é mudança visível e precisa ser comunicada (R-4). |
| Apex triggers em `Lead` (Tooling `ApexTrigger`) | 0 | Não há risco de ordem de execução com Apex. |
| Workflow rules em `Lead` | `Alerta Diretor Comercial` e `Alerta Gerente de Contas`, as duas **inativas** | Não interferem. |
| Validation rules ativas em `Lead` | `Lead_Novo`, `Motivo`, `PreencheDescricaoMotivo`, `PreencherDescricaoMotivo`, `Origem_da_campanha_obrigatorio` | `Origem_da_campanha_obrigatorio` só atua quando `LeadSource = "Campanha Marketing"`, então não é afetada. `Lead_Novo` exige `Status = "Novo"` no insert, o que vale para o roteiro de QA. |
| `LeadSource` no describe | `restrictedPicklist = false`, `nillable = true`, default de org = `Prospecção - Gerente de Contas`. Valor `Web Site Agility Networks` com label `Web Site Agility`. | **O picklist não é restrito.** Por isso, se o middleware mandar o **label** ("Web Site Agility") em vez do API name, a API aceita e grava um valor solto, fora da lista. Isso também "não aparece como a opção Web Site Agility" no relatório. Existe então uma segunda causa-raiz plausível além do default (ver hipóteses abaixo). |
| Default de `LeadSource` por record type (`objects/Lead/recordTypes/*`) | Os 4 record types (`Lead_Interno`, `Lead_Marketing`, `Lead_Partner`, `Requisi_o_de_Conta`) têm default `Prospecção - Gerente de Contas` e todos incluem `Web Site Agility Networks` como valor disponível. Record type default do usuário de dev: `Lead Interno`. | Record type não separa o canal do site dos outros canais. |
| Connected App `Lead Site Agility` (`ConnectedApplication` + `SetupEntityAccess`) | `isAdminApproved = false`: **"All users may self-authorize"**, qualquer usuário pode autenticar. Os profiles associados (Administração, Marketing, Administração para Alta Gestão) **são idênticos** aos do Connected App `Lead Site Eagle`. | O Connected App **não identifica** quem está gravando, e profile também não serve de critério: os mesmos profiles têm usuários humanos que criam Lead à mão (CA-02), e talvez o mesmo usuário atenda os dois sites (Agility e Eagle). |

### Hipóteses de causa-raiz (não confirmáveis nesta sandbox)

- **H1, payload omite `LeadSource`:** o Lead herda o default de org `Prospecção - Gerente de Contas`.
  É o que o `02-recon.md` aponta como mais provável.
- **H2, payload manda o label `Web Site Agility`, não o API name:** como o picklist não é restrito,
  o valor fica gravado como texto solto, fora da lista. Visualmente parece certo, mas não agrupa com
  `Web Site Agility Networks` em relatório nem dispara o Flow de Opportunity.
- **H3, payload manda outro valor qualquer** (inclusive `Web Site Agility – E-mail`).

A evidência que separa as três é **olhar o valor de `LeadSource` de um Lead real afetado em produção**
(print do campo ou um `COUNT() GROUP BY LeadSource` rodado por um humano em produção). Este pipeline
não acessa produção (guardrail #1), e a sandbox de dev tem 0 Leads.

## 1. Decisão

**Decisão: a correção principal é configuração no middleware externo que alimenta o Connected App
`Lead Site Agility`.** O payload do `POST /sobjects/Lead` passa a mandar `"LeadSource": "Web Site
Agility Networks"`, o **API name**, não o label. Do lado Salesforce **não se cria nem se altera metadata**
nesta opção. A esteira entra com a validação: um teste em QA que reproduz o payload pela REST API e
prova o resultado (CA-04).

**Rede de segurança no Salesforce (opcional, condicionada):** um Flow before-save em `Lead` que corrige
`LeadSource` **só** para Leads gravados por um usuário de integração marcado com uma Custom Permission
dedicada. Ele só é construído se o humano confirmar no gate que existe um usuário de integração
**exclusivo** do site Agility (pergunta P-2). Sem essa confirmação, a rede de segurança **não é
construída**: um critério inventado viola CA-02 e o guardrail #3.

### Por que esta ordem (configuração → declarativo → código)

| Opção | Nível | Veredito | Motivo |
|---|---|---|---|
| **A. Middleware manda o API name correto** | Configuração (fora do SF) | **Recomendada, correção principal** | Corrige na origem e resolve H1, H2 e H3 de uma vez. Zero metadata, zero risco para outros canais (CA-02 garantido por construção). É o único lugar que sabe com certeza que o Lead veio do site. Contra: está fora do alcance desta esteira, depende de quem administra a integração (contato do Connected App: e-mail de TI da Agility no metadata). |
| B. Mudar o default do `StandardValueSet:LeadSource` | Configuração (SF) | **Rejeitada** | O default é global e vale para `Lead`, `Contact` e `Opportunity` (mesmo value set) e para todos os record types. Trocar o default para `Web Site Agility Networks` faria **todo** Lead manual, importação e prospecção de Gerente de Contas virar "site". Viola CA-02 de frente. Remover o default só troca "valor errado" por "vazio" e quebra quem depende dele hoje. |
| C. Mudar o default de `LeadSource` por record type | Configuração (SF) | **Rejeitada** | Nenhum record type é exclusivo do site (os 4 têm o mesmo default e usuários humanos usam todos). Não confirmei qual record type a integração grava. |
| D. Flow before-save com critério por **profile** ou **record type** | Declarativo | **Rejeitada** | Os profiles do Connected App (Marketing, Administração, Administração para Alta Gestão) têm usuários humanos que criam Lead manualmente, e são os mesmos do `Lead Site Eagle`. Haveria falso positivo e violaria CA-02. |
| E. Flow before-save com critério por **username fixo** | Declarativo | **Rejeitada** | O username muda entre sandbox e produção (sufixo `.sbxdev`) e o usuário não está confirmado. Hardcode de usuário é reprovação automática na `padrao-entrega`. |
| **F. Flow before-save com critério por Custom Permission atribuída via Permission Set ao usuário de integração** | Declarativo | **Recomendada como rede de segurança, condicionada à P-2** | Critério portátil entre ambientes (o Flow lê `$Permission`, não ID nem nome) e sem SOQL. Quem leva o crachá é decisão humana: o admin atribui o permission set ao usuário certo em cada org. Só faz sentido se esse usuário for **exclusivo** do site Agility (se ele também grava Leads do site Eagle ou de outro canal, o Flow classificaria esses Leads errado). |
| G. Apex trigger | Código | **Rejeitada** | Não há nada que o Flow before-save não faça aqui (uma atribuição de campo no mesmo registro). Descer para código só traria trigger novo, classe de teste e manutenção, sem ganho. |

### O que fica sem solução enquanto D-2 não for confirmada

- Sem a confirmação da P-2, **o Salesforce sozinho não tem como distinguir** um Lead do site de um Lead
  criado por outro canal com o mesmo usuário/profile. Nesse cenário, a única correção possível é a A
  (middleware), e esta esteira não constrói nada em `force-app`.
- Se o middleware não puder ser alterado **e** não houver usuário exclusivo, a demanda não tem correção
  segura no escopo atual. O caminho seria uma integração dedicada (usuário próprio para o site Agility).
  Isso é mudança de integração, não de modelo de dados, mas é decisão do humano e do cliente, não deste
  agente.

## 2. Risco para os outros canais (CA-02) e como o desenho evita

- **Opção A:** não há risco. Só o payload do site muda, e nenhuma regra do Salesforce é alterada. O
  default de org `Prospecção - Gerente de Contas` continua valendo para todos os outros canais.
- **Opção F (se construída):** o Flow só entra quando **as três** condições valem:
  1. evento = **create** (nunca update, para não reescrever Lead já qualificado nem corrigir dado de outro canal depois);
  2. o usuário corrente tem a Custom Permission (`$Permission`), que só o usuário de integração exclusivo do site recebe;
  3. `LeadSource` chegou como default de org (`Prospecção - Gerente de Contas`), vazio, ou com o texto
     solto `Web Site Agility` (H2). Se o middleware mandar outro valor válido de propósito (por exemplo
     `Web Site Agility – E-mail`), o Flow **respeita** e não sobrescreve.
  Usuários humanos, importações e outras integrações nunca recebem a Custom Permission, então não entram
  no critério. O `StandardValueSet` não é alterado, e `Contact` e `Opportunity` não são afetados.
- **Ordem de execução:** **não há outro Flow before-save nem trigger Apex em `Lead`.** O novo Flow seria
  o único no evento before-save/create, sem conflito de ordem. Os after-save existentes não dependem de
  `LeadSource`. Downstream, a correção ativa de fato o Flow before-save de Opportunity
  `Atualizar_Descri_o_com_Informa_es_do_Lead` na conversão (R-4).

## 3. Cobertura dos critérios de aceite

| CA | Como é coberto |
|---|---|
| **CA-01** — Lead do site recebe o valor confirmado | Opção A: o middleware manda `Web Site Agility Networks` (label "Web Site Agility", D-1 resolvida no recon). Opção F, se aprovada, cobre o caso de o middleware falhar ou regredir. |
| **CA-02** — outros canais não mudam | Opção A não toca regra nenhuma no SF. Opção F tem critério restrito a create + Custom Permission exclusiva + valor default/vazio/label-solto. As opções B, C, D e E foram rejeitadas justamente por violarem o CA-02. |
| **CA-03** — o valor do site sobrepõe o default | Opção A: um valor explícito no payload sempre vence o default de picklist. Opção F: a condição 3 trata exatamente o default `Prospecção - Gerente de Contas` (e o texto solto da H2). |
| **CA-04** — teste em QA com payload simulado | Roteiro na etapa QA (`sbx-somos-agility-qa`): `POST /services/data/vNN.0/sobjects/Lead` com dados fictícios (guardrail #2), `Status = "Novo"` (por causa da `Lead_Novo`) e os casos (i) `LeadSource = "Web Site Agility Networks"` → valor mantido; (ii) **sem** `LeadSource` → mostra o default `Prospecção - Gerente de Contas`, o que comprova H1 na plataforma; (iii) `LeadSource = "Web Site Agility"` (label) → mostra o valor solto, o que comprova H2. Com a F: (iv) os casos ii e iii com usuário que tem o PS → corrigido para `Web Site Agility Networks`; (v) os mesmos casos com usuário **sem** o PS → inalterado (CA-02). Opcional: converter o Lead do caso (i) e conferir que `Atualizar_Descri_o_com_Informa_es_do_Lead` preencheu `Opportunity.Description`. A validação do middleware real contra a sandbox de QA depende de quem o administra conseguir apontá-lo para a sandbox. Se não der, o QA cobre o lado Salesforce e a evidência do middleware fica com o cliente (registrar em `05-testes.md`). |

## 4. Componentes

### Opção A (sempre)
- **Criar/alterar no Salesforce:** nenhum.
- **Fora do Salesforce (responsabilidade do cliente/TI Agility):** mapeamento do payload do middleware
  que autentica pelo Connected App `Lead_Site_Agility`, para `LeadSource = "Web Site Agility Networks"`.
- **Insumo para QA:** script/coleção de chamadas REST de teste (não é metadata, fica em `05-testes.md`).

### Opção F (só se a P-2 for confirmada no gate). Nomes **propostos, a criar** (não existem hoje na org)
| Tipo | API name proposto | Conteúdo |
|---|---|---|
| Custom Permission | `Lead_Origem_Site_Agility` | Marca o usuário de integração exclusivo do site Agility. Com descrição preenchida. |
| Permission Set | `PS_Integracao_LeadSiteAgility` | Concede apenas a Custom Permission acima. Sem permissão de objeto/campo (o usuário já tem as que usa hoje). |
| Flow (record-triggered, before-save, create, objeto `Lead`) | `Lead_BeforeSave_OrigemSiteAgility` | Condição de entrada por fórmula: `$Permission.Lead_Origem_Site_Agility && (ISBLANK(TEXT({!$Record.LeadSource})) \|\| TEXT({!$Record.LeadSource}) = "Prospecção - Gerente de Contas" \|\| TEXT({!$Record.LeadSource}) = "Web Site Agility")`. Um único elemento: atualizar o registro que disparou com `LeadSource = Web Site Agility Networks`. Sem Get Records, sem loop. |

- **Alterar:** nenhum componente existente.
- **Depreciar:** nenhum.
- **Mudança de modelo de dados:** nenhuma (nenhum campo, objeto ou valor de picklist novo). Não exige
  escalonamento de arquitetura sênior.

### Limites de governador e escala
- Opção A: nada no SF.
- Opção F: um Flow before-save sem SOQL e sem DML (atribuição no próprio `$Record`), bulkificado pela
  plataforma. Custo desprezível mesmo em carga em lote pela API (até 200 registros por transação). Não
  existe SOQL em loop.

## 5. Impacto em permissões
- Opção A: nenhum.
- Opção F: um permission set novo (`PS_Integracao_LeadSiteAgility`), atribuído **manualmente por um admin**
  ao usuário de integração em cada org: QA na esteira, produção por quem faz o deploy humano. Nenhum
  profile é alterado. É passo manual pós-deploy e tem que constar em `06-entrega.md`. Sem a atribuição,
  o Flow fica inerte (falha segura: não muda nada, em vez de mudar errado).

## 6. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R-1 | Causa-raiz não confirmada (H1/H2/H3), sem dado em dev | **Alta** | A opção A resolve as três. Pedir no gate um print do campo de um Lead afetado em produção ou um agregado `GROUP BY LeadSource` (P-3). |
| R-2 | Correção depende de terceiro (middleware) fora da esteira | **Alta** | Registrar dono e prazo no gate. A opção F reduz a dependência, mas só com a P-2 confirmada. |
| R-3 | Usuário de integração compartilhado entre site Agility, site Eagle ou outros canais | **Alta** (se for construída a F) | A F só é construída com a P-2 confirmada como "exclusivo". Caso contrário, fica de fora. |
| R-4 | Correção ativa o Flow de Opportunity `Atualizar_Descri_o_com_Informa_es_do_Lead` (sobrescreve `Description` na conversão) | Média | É o comportamento que quem construiu esperava. Comunicar a Marketing/Comercial e incluir no roteiro de QA. |
| R-5 | Relatórios de Marketing passam a ver Leads do site em outro bucket (D-4). Histórico fica com o valor antigo | Média | Fora do escopo (ver seção 7). Avisar Marketing que a série histórica tem uma quebra na data do deploy. |
| R-6 | Sandbox de QA sem o middleware apontado para ela | Média | O CA-04 cobre o lado SF com payload simulado. A evidência do middleware real fica com o cliente, registrada em `05-testes.md`. |
| R-7 | Futuro Flow/trigger before-save em Lead mexendo em `LeadSource` | Baixa | A descrição do Flow F documenta a regra. Hoje não há concorrente. |

## 7. O que NÃO será feito nesta demanda
- Corrigir retroativamente os Leads históricos já gravados com o default ou com o label solto (D-4).
  Seria atualização em massa em produção, que é proibida ao agente e exige demanda própria com
  aprovação de Marketing.
- Alterar o `StandardValueSet:LeadSource` (default, labels, valores) ou os defaults por record type.
- Alterar o Connected App `Lead_Site_Agility` ou o `Lead_Site_Eagle`. Revisar a política "All users may
  self-authorize" seria uma melhoria de segurança legítima, mas fora do escopo (fica como recomendação
  para o cliente).
- Alterar o middleware: é ação do cliente/TI Agility, não da esteira.
- Mexer nos Flows/workflow rules existentes de Lead ou Opportunity.

## 8. Perguntas para o humano decidir no gate de design

- **P-1 (Marketing/Guilherme):** confirmar que a origem desejada é o valor exibido **"Web Site Agility"**
  (API name `Web Site Agility Networks`) e não `Web Site Agility – E-mail`. O recon já resolve a
  ambiguidade textual, e o Flow de Opportunity existente usa esse valor. É confirmação de negócio, não
  dúvida técnica.
- **P-2 (quem administra a integração/TI Agility), decide se a opção F entra:** o middleware do site
  Agility autentica com um usuário Salesforce **exclusivo** dele (que não grava Leads de nenhum outro
  canal, inclusive o site Eagle)? Se sim: qual usuário, e ele existe (ou pode existir) também na sandbox
  de QA para o teste? Se não: a F fica de fora e a demanda segue só com a A.
- **P-3 (evidência da causa-raiz):** alguém com acesso a produção pode trazer o valor de `LeadSource` de
  um Lead do site afetado (print só do campo, sem dado pessoal) ou um agregado
  `SELECT LeadSource, COUNT(Id) FROM Lead WHERE CreatedDate = LAST_N_DAYS:90 GROUP BY LeadSource`?
  Isso separa H1 de H2/H3.
- **P-4 (dono da correção externa):** quem altera o payload do middleware, e em que prazo? A demanda só
  fecha (CA-01 em produção) quando essa alteração for feita.
- **P-5 (D-4):** Marketing aceita a quebra na série histórica sem corrigir os Leads antigos nesta
  demanda?

## 9. Estimativa

**Estimativa de esforço:** 3–7 h

Composição: opção A só no lado da esteira (alinhamento com TI/Marketing, roteiro REST de QA com 3 casos,
evidência, `06-entrega.md`) dá cerca de 3–4 h. Somando a opção F (Custom Permission, Permission Set,
Flow before-save, casos iv e v de QA, passo manual de atribuição documentado) são mais 2–3 h. O limite
inferior vale se a P-2 for "não" (só A). O superior vale se a F entrar.

Em relação à análise (2–4 h): **o teto subiu** porque o recon mostrou que (1) não há ponto de entrada
declarativo no Salesforce para ajustar (não há Web-to-Lead, Flow nem Apex gravando o Lead do site), e a
correção principal está num middleware externo, o que soma alinhamento e evidência de terceiro;
(2) uma rede de segurança no SF só é segura com critério portátil (Custom Permission + Permission Set),
que tem mais peças que um ajuste de mapeamento; (3) a descoberta do Flow de Opportunity que reage ao
valor amplia o roteiro de QA. O esforço do middleware em si (lado do cliente) **não** está incluído.
