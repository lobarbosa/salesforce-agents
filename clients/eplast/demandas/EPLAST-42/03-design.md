# EPLAST-42 — Design: públicos de relacionamento, prospecção e reativação prontos para o Marketing Cloud

**Org consultada nesta sessão:** `sbx-eplast-dev` (sandbox de dev da esteira, confirmada com `sf org list`). Só leitura: metadata e contagens. Nenhum deploy, DML ou anonymous Apex.
**Base:** `01-analise.md` (aprovado em `gates.md`, 2026-11-15), `02-recon.md`, `00-preflight.md` (sem bloqueios e sem outra demanda nos mesmos componentes), comentários do card e regras 1 a 6 do `CLAUDE.md` da conta.
**Etapa:** DESIGN. **Gate bloqueante:** precisa do aceite do arquiteto humano.

**Estimativa de esforço:** 12–18 h

Em relação à análise (12–20 h): o teto caiu porque o recon fechou o escopo. A mudança é mecânica sobre 58 relatórios que já existem, mais 1 relatório novo e 1 permission set ajustado. Não há Apex, Flow nem campo novo. O piso fica igual por três custos que a análise não previa: (1) o dado de teste de reativação exige Conta mais Oportunidade ganha, porque `LastPurchase__c` é roll-up (seção 2), e passa pela `AccountTrigger` e pelas regras de Oportunidade; (2) o XML de relatório não tem validação local (doutrina, achado EPLAST-39); (3) a comparação dos 58 relatórios entre dev e QA antes do deploy na QA (risco R4).

---

## 1. Decisão

**Configuração nativa (relatórios e permission set), sem Flow e sem Apex.**

| Nível | Usado? | Por quê |
|---|---|---|
| Configuração (relatório, filtro, FLS em permission set) | **Sim, só isso** | O modelo de público da Eplast já são os relatórios da pasta `MARKETINGCLOUD` (60, recon). O que falta são três filtros (opt-out de celular, lead convertido, prioridade) e acesso a dois campos. Nada disso exige automação. |
| Declarativo (Flow) | Não | Gravar segmento em registro (PA-03) traria automação nova em Lead, Contact ou Account. Account já tem `AccountTrigger`, o `AccountBefore` do CPQ e 2 Flows after-save (conferido nesta sessão; assessment, achado 1). Público lido do relatório é sempre atual e não precisa de carga retroativa. |
| Código (Apex/LWC) | Não | Nenhum critério da doutrina se aplica: sem callout, sem rollback, sem volume transacional. Cobertura org-wide de 10% (assessment, achado 2) é mais um motivo para não acrescentar código. |

Alternativas que a análise deixou abertas, e a escolha:

| Ponto | Alternativas | Escolha e porquê |
|---|---|---|
| Opt-out de celular (CA-03) | (a) filtro em todos os relatórios de lista da pasta; (b) só em públicos novos de "mensagem"; (c) só uma coluna, e o Marketing Cloud filtra | **(a)**. A org não separa público por canal (nenhum relatório é "de SMS"). PA-04, aprovada, diz que todo público exclui quem tem opt-out. É o mesmo critério da EPLAST-36 para e-mail (`[demandas/EPLAST-36/03-design.md]`, PA-07, hoje em 58 de 60). Errar para o lado de excluir não gera envio indevido e é fácil de desfazer (tirar o filtro). Efeito colateral em R1 e PD-02. |
| Lead convertido no público | (a) filtro "não convertido" nos 16 `LeadList`; (b) filtro por `Status` | **(a)**. Lead convertido já existe como Contato e entraria duas vezes. "Fechado - Não convertido" continua no público (PD-03). |
| Recorte de prioridade (CA-06) | (a) acrescentar filtro de prioridade nos `LEADS_*` existentes; (b) 1 relatório novo | **(b)**. Filtrar os existentes mudaria o público que o Marketing Cloud já importa deles. Nenhum dos 60 usa `PriorityBand__c` (recon), então não há o que reaproveitar. |
| Recorte de origem (CA-05) | (a) relatório novo por origem; (b) reaproveitar `MKT_Leads_por_Origem` (EPLAST-39) mais a coluna de origem no relatório novo | **(b)**. `MKT_Leads_por_Origem` existe (Summary, pasta "Origem e Retorno de Campanhas", conferido nesta sessão). Criar outro seria sobreposição (regra 3). |
| Mecanismo pelo qual o Marketing Cloud lê o público | relatório, objeto sincronizado, campanha | Fica com quem opera o Marketing Cloud (regra 2). O CRM entrega relatório e campo legíveis; a seção 7 diz o que cada caminho precisa. |

**Mudança de modelo de dados:** nenhuma. Nenhum objeto, campo ou relacionamento novo. Não há o que escalar como decisão de arquitetura sênior.

**Versões e ativação:** a demanda não altera Flow, classe Apex nem agente Agentforce. `Lead_AfterInsert_AplicaRegraAtribuicao`, `LeadAssignmentService` e `SFAgent2` ficam como estão. Não há passo de ativação.

---

## 2. O que a org mostra (confirmado nesta sessão, complementa o recon)

| Item | Achado | Comando |
|---|---|---|
| `Account.LastPurchase__c` | **Roll-up** (`Summary`), rótulo "Última Compra": `MAX(Opportunity.CloseDate)` com filtro `Opportunity.StageName = Fechado/Ganho`. Calculado, não atualizável. Sem `Description`. | Tooling `CustomField.Metadata`; describe de `Account` |
| `Lead.MKT_Origem_Agrupada__c` | Fórmula texto, com `Description` (EPLAST-39). Vazio vira "Sem origem"; valor fora dos 13 vira "Fora da lista". | Tooling `CustomField.Metadata` |
| FLS de `MKT_Origem_Agrupada__c` | Leitura só em `PS_Marketing_AnaliseCampanhas` e `sfdc_a360_sfcrm_data_extract`. Nenhum perfil tem. O usuário de execução da esteira não tem (por isso o campo some do describe dele). | `FieldPermissions` |
| FLS de `PriorityBand__c` / `PriorityScore__c` | Leitura em `PS_Comercial_ScorePrioridade` (atribuído ao usuário de execução) e `sfdc_a360_sfcrm_data_extract`. **Não** em `PS_Marketing_Publicos`. | `FieldPermissions`; `PermissionSetAssignment` do usuário de execução |
| FLS de opt-out de celular | `PS_Marketing_Publicos` já lê o campo em Lead e Contact. | `FieldPermissions` |
| Sintaxe de coluna custom em relatório | `Lead.Sector__c`, `Account.LastPurchase__c` e `Account.Sector__c` aparecem em relatórios da pasta. Boa base para `Lead.PriorityBand__c` e `Lead.et4ae5__HasOptedOutOfMobile__c`. **Coluna custom de Contato em `ContactList` não tem exemplo na pasta.** | leitura dos XML do retrieve do recon (`/tmp`) |
| Validation rules | Lead `Celular` e `Telefone`, Contact `Telefone` e `WhatsApp`, Account `Celular`, `Telefone`, `WhatsApp` e `Contato_Fiscal`: todas só barram formato **quando o campo está preenchido**. Account tem também `CheckUserCanSetLimitDueDate` e `CheckUserCanSetRisk`. | Tooling `ValidationRule.Metadata` |
| Workflow rules `et4ae5` | Todas em objetos do pacote (`SendDefinition`, `SMSDefinition`, `Automated_Send`, `SupportRequest`, `IndividualEmailResult`). Nenhuma em Lead, Contact ou Account. | `sf org list metadata --metadata-type WorkflowRule` |
| Automação em Account | `AccountTrigger` (custom), `AccountBefore` (SBQQ), Flows `AccountTriggered` e `UpdateParentAccountUsedLimit` (after-save, create e update) e `AccountUpdateEconomicGroup` (agendado). Contact: nenhum Flow ativo. | `FlowDefinitionView`; Tooling `ApexTrigger` |
| Pasta `Volume_Inativos` | 1 relatório (`Novo_relat_rio_Contas`), não 3. Fora do escopo. | `sf org list metadata --metadata-type Report --folder Volume_Inativos` |
| Relatórios de lista da pasta | 58 com filtro de opt-out de e-mail: 42 `ContactList` e 16 `LeadList`. Entre eles, 6 cópias `Cpia_de_*` (4 de Contato e 2 de Lead). | recon e leitura dos XML |

---

## 3. Reaproveita × cria (item a item, regra 3)

| # | Componente (API name) | Ação | Prova de que existe | O que muda |
|---|---|---|---|---|
| 1 | 42 relatórios `ContactList` da pasta `MARKETINGCLOUD` (inclui 4 `Cpia_de_*`) | **Altera** | recon (retrieve dos 60) | + filtro opt-out de celular do Contato = falso. Nada mais. |
| 2 | 16 relatórios `LeadList` da pasta `MARKETINGCLOUD` (inclui `Cpia_de_LEADS_GERAL_D2D` e `Cpia_de_LEADS_SP_fWa`) | **Altera** | recon | + filtro `Lead.et4ae5__HasOptedOutOfMobile__c` = falso; + filtro lead não convertido. |
| 3 | `CLASSIFICACAO_CONTAS_POR_CLASSE`, `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` | Reaproveita, sem alteração | recon | São agregações de Conta e Item de Pedido, não lista de envio (sem filtro de e-mail hoje). |
| 4 | `MARKETINGCLOUD/LEADS_PROSPECCAO_PRIORIDADE` (relatório `LeadList`, Summary) | **Cria** | Confirmado que não existe: nenhum dos 60 usa `PriorityBand__c` | Público de prospecção priorizada. Ver seção 4. |
| 5 | `PS_Marketing_Publicos` | **Altera** (FLS) | recon e `FieldPermissions` | + leitura em `Lead.PriorityBand__c`, `Lead.PriorityScore__c` e `Lead.MKT_Origem_Agrupada__c`. Nenhuma permissão de objeto nova, nenhuma escrita. |
| 6 | `MKT_Leads_por_Origem` (EPLAST-39) | Reaproveita, sem alteração | SOQL `Report` nesta sessão | Público e leitura por origem (CA-05). |
| 7 | `Lead.MKT_Origem_Agrupada__c`, `Lead.PriorityBand__c`, `Lead.PriorityScore__c`, `Account.LastPurchase__c`, `Account.Type` | Reaproveita, sem alteração | seção 2 e recon | Critérios de público. |
| 8 | `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` (Lead e Contact) | Reaproveita | describe e Tooling | Opt-out. Campo do conector não é alterado. |
| 9 | `CampaignMember.et4ae5__Activity__c` e objetos de resultado do conector | Reaproveita, sem alteração | recon; `[demandas/EPLAST-36/03-design.md]` | Retorno do Marketing Cloud. |
| 10 | `PS_Marketing_AnaliseCampanhas` | Reaproveita, sem alteração | recon | Continua sendo o acesso de quem analisa campanha. |
| 11 | `Lead_AfterInsert_AplicaRegraAtribuicao`, `LeadAssignmentService` | Não toca | recon | Só o dado de teste de Lead passa por eles. |
| 12 | `SFAgent2` | Não se aplica | análise 2.4 | A demanda não envolve assistente. |
| 13 | Pacote `et4ae5` (campos, workflow, conexão) | Não toca | recon; regra 2 | Nada no Marketing Cloud nem na conexão. |
| 14 | Pasta `Volume_Inativos` | Não toca | seção 2 | Fora da pasta de público. |
| 15 | `Campaign` / `CampaignMember` (registros) | Não usa | PA-02 | Nenhuma campanha criada no CRM. |

Total do pacote: **58 relatórios alterados, 1 relatório criado, 1 permission set alterado.** Zero Flow, zero Apex, zero campo, zero objeto.

---

## 4. Especificação do que muda

### 4.1 Filtros acrescentados aos 58 relatórios de lista

- O filtro existente `EMAIL_OPT_OUT` fica intocado, assim como região, `TYPE`, setor e `LastPurchase__c`. O filtro novo entra como mais um `criteriaItems`, com lógica AND (nenhum dos 60 usa `booleanFilter`; conferido).
- **`ContactList` (42):** opt-out de celular do Contato = falso. O nome da coluna (`Contact.et4ae5__HasOptedOutOfMobile__c` ou outra forma) **sai do describe do tipo de relatório** (`/analytics/report-types/ContactList`), porque não há exemplo na pasta. O valor booleano (`0`/`False`) segue o formato do filtro `EMAIL_OPT_OUT` existente.
- **`LeadList` (16):** `Lead.et4ae5__HasOptedOutOfMobile__c` = falso, mais lead não convertido. A coluna de "convertido" também sai do describe de `LeadList`.
- **Base do XML:** retrieve dos 58 da org de dev **no momento do build**, não do `/tmp` do recon. A edição é por script, aplicada igual nos 58, e o diff de cada arquivo deve mostrar só as linhas do filtro novo.
- Doutrina, achado EPLAST-39: se duas tentativas de deploy forem recusadas no mesmo filtro, pare, tire o item e registre a pendência no plano de build.

### 4.2 `LEADS_PROSPECCAO_PRIORIDADE` (novo)

- Pasta `MARKETINGCLOUD`; tipo `LeadList`; formato Summary agrupado por `Lead.PriorityBand__c`. `scope` copiado de `LEADS_OlB`, que é do mesmo tipo (`org`).
- Filtros: `PriorityBand__c` diferente de "Sem dados suficientes"; `EMAIL_OPT_OUT` = falso; opt-out de celular = falso; não convertido.
- Colunas: nome, empresa, `STATE`, `Lead.Sector__c`, `LeadSource`, `Lead.MKT_Origem_Agrupada__c`, `Lead.PriorityBand__c`, `Lead.PriorityScore__c`, status, e-mail (o Marketing Cloud precisa do destinatário). **Sem telefone, CPF ou documento.**
- `description`: "EPLAST-42. Público de prospecção priorizada para o Marketing Cloud: leads não convertidos, sem opt-out de e-mail e de celular, com faixa de prioridade calculada (exclui 'Sem dados suficientes'). Agrupado por faixa; origem em coluna."
- XML montado a partir do retrieve de `LEADS_OlB` (mesmo tipo e formato), conforme a doutrina.
- Fallback (R3): se o deploy recusar a coluna `MKT_Origem_Agrupada__c` por falta de FLS do usuário que implanta, o relatório sai sem ela. O recorte por origem continua coberto por `MKT_Leads_por_Origem` e pelo campo, e o fato fica registrado no plano.

### 4.3 `PS_Marketing_Publicos`

- Retrieve do permission set na dev e acréscimo só de 3 `fieldPermissions` (leitura, sem edição). Deploy de permission set é aditivo para o que não está no XML. Mesmo assim, o diff deve mostrar só as 3 entradas.
- `description` do PS: manter a existente e acrescentar "EPLAST-42: leitura de prioridade e origem agrupada do Lead."

---

## 5. Ordem de execução e governador

- **Nenhuma automação entra em Lead, Contact, Account, Opportunity ou Order.** Relatório e permission set não participam da ordem de execução.
- Afetado só pelo **dado de teste** (DML do verificador e do QA, não do build):
  - Lead → validation rules `Celular` e `Telefone` (passam com telefone vazio) → after-save `Lead_AfterInsert_AplicaRegraAtribuicao` (muda o proprietário pela região). Filtros de relatório `scope=org` não dependem do proprietário.
  - Account → `AccountBefore` (SBQQ) e `AccountTrigger` (valida CNPJ e consulta a BrasilAPI; usar o desvio `TriggerUtility.bypassTrigger` do `fixtures/README.md`) → validation rules (passam com telefone vazio) → after-save `AccountTriggered` e `UpdateParentAccountUsedLimit`.
  - Opportunity `Fechado/Ganho` → automação de Opportunity do assessment (achado 1) e roll-up para `Account.LastPurchase__c`. Exige "ID Usuário Protheus" no proprietário (fixtures).
- **Governador e CPU:** sem transação nova. O dado de teste é de dezenas de registros (seção 9), longe de qualquer limite. O cenário "um pai com muitos filhos" não se aplica: o roll-up é nativo e o teste usa 1 a 2 oportunidades por conta. Relatório de lista tem teto de exibição, mas o Marketing Cloud importa por mecanismo próprio. O volume real de públicos não é medível na dev (0 registros).

---

## 6. Impacto em permissões

| Item | Impacto |
|---|---|
| `PS_Marketing_Publicos` | + leitura em 3 campos de Lead. 0 atribuições na dev (recon). |
| Perfis | Nenhum alterado. |
| Pasta `MARKETINGCLOUD` | Compartilhamento não alterado. |
| Usuário do conector Marketing Cloud | Não alterado pela esteira. Para que o Marketing Cloud leia prioridade e origem, quem opera o conector atribui `PS_Marketing_Publicos` ao usuário de integração que roda a importação (seção 7e). |
| Usuário de execução da esteira | Não alterado pelo build. Ver o pedido P1 da seção 11. |

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

**Nada é feito no Marketing Cloud. Nada é enviado pelo CRM.** O build entrega só dado, público e filtro do lado do CRM.

**a) Dados que o Marketing Cloud lê e onde ficam**

| Dado | Objeto.campo | Público que usa |
|---|---|---|
| Destinatário de e-mail | `Contact.Email`, `Lead.Email` | todos |
| Celular (mensagem) | `Contact.MobilePhone`, `Lead.MobilePhone`, mais `et4ae5__Mobile_Country_Code__c` (existe em Lead e Contact, recon) | canal de mensagem |
| Opt-out de e-mail | `HasOptedOutOfEmail` (Lead e Contact) | todos (filtro) |
| Opt-out de celular | `et4ae5__HasOptedOutOfMobile__c` (Lead e Contact) | todos (filtro novo) |
| Origem do lead | `Lead.LeadSource`, `Lead.MKT_Origem_Agrupada__c` | prospecção |
| Prioridade do lead | `Lead.PriorityBand__c`, `Lead.PriorityScore__c` | prospecção priorizada |
| Tipo de cliente | `Account.Type` (Prospect, Recorrente, Sazonal, Reativo, Inativo…) | relacionamento, prospecção, reativação |
| Última compra | `Account.LastPurchase__c` (data da última oportunidade ganha) | reativação (`SEM_COMPRA_*`) |
| Região e setor | `STATE`, `Lead.Sector__c`, `Account.Sector__c` | recortes |

**b) Como o público fica identificável no CRM**

- Cada público é um relatório da pasta `MARKETINGCLOUD`, com nome por finalidade:
  - Prospecção: `LEADS_*`, `PROSPECTS_*`, `POTENCIAIS_SEM_COMPRA` e, novo, `LEADS_PROSPECCAO_PRIORIDADE`.
  - Relacionamento: `RECORRENTES_ATIVOS_*`, `SAZONAIS_*`, `CONTAS_E_CONTATOS_RECORRENTES_6PU`, `COMPRA_ULTIMOS_90_DIAS`, `SEGMENTO_*`.
  - Reativação: `REATIVOS_GERAL_rbp`, `INATIVOS_GERAL`, `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`.
- Após o build, todo relatório de lista já sai sem opt-out (e-mail e celular) e, no caso de Lead, sem convertido. O Marketing Cloud não precisa refazer esse filtro.
- Sem campo de segmento persistido e sem campanha nova no CRM (PA-02 e PA-03).

**c) O que o Marketing Cloud devolve e onde é gravado**

- Envio, abertura e clique: onde o conector já grava, ou seja, `CampaignMember.et4ae5__Activity__c` e os objetos de resultado do pacote (`[demandas/EPLAST-36/03-design.md]`). Nenhum campo de retorno novo.
- Opt-out feito no Marketing Cloud: o sentido da sincronização para `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` **não é visível pela org** (recon, item 4) e depende da configuração do conector. Fica como PD-05 e como passo de quem opera o Marketing Cloud.

**d) Consentimento e opt-out**

- Exclusão por canal nos públicos: e-mail por `HasOptedOutOfEmail` e celular por `et4ae5__HasOptedOutOfMobile__c`, os dois aplicados a todo relatório de lista (PD-02).
- WhatsApp não tem campo de opt-out na org (`[demandas/EPLAST-36/03-design.md]`): fica como lacuna para a demanda de LGPD, e nada é criado aqui.
- Nenhum registro de consentimento novo.

**e) O que fica para quem opera o Marketing Cloud**

1. Escolher como importa cada público (relatório do Salesforce, objeto sincronizado ou outro mecanismo do conector) e mapear cada público ao relatório pelo nome.
2. Confirmar qual usuário de integração do Salesforce o conector usa e atribuir a ele `PS_Marketing_Publicos`, para ler prioridade e origem. É atribuição de permissão no CRM, feita por quem administra o conector, não pela esteira.
3. Saber que os 58 públicos passam a excluir quem tem opt-out de celular e, em Lead, quem foi convertido. Na próxima atualização, a contagem importada pode cair.
4. Confirmar o sentido da sincronização de opt-out entre Marketing Cloud e CRM (PD-05).
5. Definir conteúdo, cadência, frequência e jornada de relacionamento, prospecção e reativação.
6. Aplicar a regra de consentimento própria do Marketing Cloud, se houver.

---

## 8. Riscos

### 8.1 Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Opt-out de celular em todos os públicos tira também do e-mail quem só recusou mensagem.** | Média | Escolha consciente (seção 1, PD-02): exclui a mais, nunca envia indevido. Para desfazer, basta tirar o filtro dos relatórios de e-mail. Vai explícito no roteiro do cliente. |
| R2 | Nome de coluna e valor booleano do filtro novo, em `ContactList` e para "convertido" em `LeadList`, não têm exemplo na pasta. | Média | Describe do tipo de relatório antes do XML. Regra das duas tentativas (doutrina). Testar primeiro em 1 relatório de cada tipo e só depois aplicar aos 58. |
| R3 | O usuário de execução da esteira não tem FLS em `MKT_Origem_Agrupada__c`. O deploy do relatório novo pode recusar a coluna, e a verificação não enxerga o campo. | Média | Fallback em 4.2. Para a verificação, pedido P1 (seção 11). Sem P1, CA-05 fica inconclusivo na dev e é provado na QA ou na homologação. |
| R4 | **O deploy substitui o XML inteiro de cada relatório. Na QA (Partial Copy), os 58 podem ter filtros diferentes dos da dev, e o deploy apagaria essa diferença.** | **Alta** | O build parte do retrieve da dev e o plano lista os 58 nomes. Antes do passo fixo de deploy na QA, a esteira, ou um humano, compara a lista e os filtros dos 58 entre QA e branch. Se divergirem, o deploy na QA espera e volta ao builder para remontar sobre a base da QA. Fica no plano de build como pré-condição. |
| R5 | Alterar os 58 muda o público que o Marketing Cloud já importa deles. | Média | É o objetivo (PA-04). Aviso a quem opera o Marketing Cloud (7e, item 3) e registro em `06-entrega.md`. |
| R6 | O dado de teste de reativação passa por `AccountTrigger` (BrasilAPI), CPQ, Flows de Account e validações de Oportunidade. | Baixa | Scripts já provados em `fixtures/` (seção 9); desvio oficial da trigger; telefones vazios. |
| R7 | Cópias `Cpia_de_*` são alteradas junto. Podem ser rascunhos de alguém. | Baixa | Mesmo critério da EPLAST-36 (as cópias já têm o filtro de e-mail). Limpeza das cópias não é feita (seção 10). |

### 8.2 Riscos do assessment que a demanda toca

| Achado | Aplica? | Como o design lida |
|---|---|---|
| 1 — Automação concorrente em Account, Opportunity e Order | Só no dado de teste | O build não cria automação. Os fixtures passam pela cadeia existente (seção 5) sem alterá-la. |
| 2 — Cobertura de 10% | Não | Zero Apex. |
| 3 — 23 validation rules de Order | Não | Nenhum Order gravado. O relatório `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` (OrderItem) não é tocado. |
| 4 — Campos sem descrição | Em parte | Nenhum campo novo. Relatório novo e PS saem com descrição. `Account.LastPurchase__c` não tem `Description` (conferido), mas a curadoria fica fora do escopo. |
| 6 — Dev parecida com QA | Não | Resolvido pela regra 5 da conta. |
| 9 e 10 — API antiga e `OrderTrigger` duplicado | Não | Nenhuma classe ou trigger tocada. |
| Workflow rules `et4ae5` (inventário) | Não | Todas em objetos do pacote (seção 2). |

---

## 9. Plano de build (alto nível) e dados de teste

**Build** (`builder-declarativo`, branch `feature/EPLAST-42`, só `sbx-eplast-dev`):
1. Describe de `ContactList` e `LeadList` (colunas de opt-out de celular e de convertido).
2. Retrieve dos 58 relatórios, de `LEADS_OlB` (molde) e de `PS_Marketing_Publicos`.
3. Piloto: aplicar o filtro em 1 `ContactList` e 1 `LeadList`, depois deploy com `--dry-run` e deploy real.
4. Script aplica o mesmo filtro aos outros 56. Diff de cada arquivo só com o filtro novo.
5. Criar `LEADS_PROSPECCAO_PRIORIDADE` e ajustar o PS.
6. Conferir pela Analytics API (`/analytics/reports/<id>`) que os 59 relatórios executam, lendo só rótulos e contagens.
7. `04-plano-build.md` com a lista dos 58, a pré-condição R4 para a QA, o fallback R3 (se usado) e a seção "Versões e ativação" dizendo "não se aplica".

**Dados de teste** (verificador na dev; QA na QAS só com o mesmo prefixo, sem tocar registro real). Partir dos scripts já provados em `clients/eplast/fixtures/` (estão na `main`; trazer para a branch): `lead-segmento.apex` (Lead com estado, setor e opt-out) e `conta-oportunidade-ganha.apex` (conta, contato e oportunidade `Fechado/Ganho`, que alimentam `LastPurchase__c`). Gravar a variação desta demanda como `fixtures/publicos-mc-eplast42.apex`, com prefixo `EPLAST42 TESTE` e modo `LIMPAR`.

| Cenário | Dado | Critério |
|---|---|---|
| Opt-out de e-mail | Contato de conta `Recorrente` com `HasOptedOutOfEmail = true` | CA-02 |
| Opt-out de celular | Lead SP com `et4ae5__HasOptedOutOfMobile__c = true`; Contato de conta `Recorrente` idem | CA-03 |
| Convertido | Lead SP convertido (o Contato gerado é de teste) | PD-03 |
| Reativação | Conta com oportunidade ganha de `CloseDate` hoje −100; outra com hoje −400; outra com hoje −365 (fronteira) | CA-04 e PD-04 |
| Origem | Lead com `LeadSource = Evento`; Lead sem origem | CA-05 |
| Prioridade | Lead com faixa Alta (setor, origem e `Status = Contatado`, conforme `fixtures/README.md`); Lead sem dados suficientes | CA-06 |
| Retorno do conector | `CampaignMember` com `et4ae5__Activity__c`, só se o verificador conseguir criar `Campaign` de teste. Senão, conferência por metadata de que o campo existe e não foi alterado | CA-07 |
| Inspeção do pacote | metadata da branch | CA-01, CA-08, CA-09, CA-10, CA-11 |

- Telefone, celular e WhatsApp ficam vazios (validation rules). E-mail, quando exigido pelo cenário, é sintético em domínio reservado de exemplo.
- Proprietário de teste: usuário `005bJ00000piKAaQAM` (ativo na dev, regra 6). Não alterar perfil, permissão nem papel dele, salvo o que a exceção do verificador já permite na dev ("ID Usuário Protheus", com valor devolvido ao final).
- Quem apaga: o verificador (dev) e o QA (QAS), pelo modo `LIMPAR`, ao final da rodada.

---

## 10. O que NÃO será feito

- Nada no Marketing Cloud nem na conexão do conector `et4ae5`. Nenhum envio pelo CRM.
- Nenhum Flow, Apex, campo, objeto, `Campaign` ou agente.
- Não altera os filtros de negócio dos públicos (região, tipo, faixas de dias, setor).
- Não limpa nem renomeia as cópias `Cpia_de_*` e não mexe na pasta `Volume_Inativos`.
- Não cria opt-out de WhatsApp nem registro formal de consentimento (demanda de LGPD).
- Não atribui `PS_Marketing_Publicos` a usuários (passo pós-deploy de quem administra).
- Não documenta `Account.LastPurchase__c` e os demais campos sem descrição.

---

## 11. Premissas assumidas (validar na homologação)

As premissas PA-01 a PA-10 da análise seguem valendo, com os ajustes abaixo. Nenhuma é caso 3.

| # | Pergunta | Decisão | Evidência | Como mudar |
|---|---|---|---|---|
| PD-01 | Quais relatórios recebem os filtros novos? | Os 58 relatórios de lista da pasta (amplia PA-01, que listava só parte deles), cópias incluídas | Org: 58 com opt-out de e-mail; padrão EPLAST-36 de aplicar o filtro de consentimento a toda a pasta | Reverter o filtro nos relatórios que a Eplast indicar |
| PD-02 | Opt-out de celular vale para todo público ou só para mensagem? | Para todo público de lista (exclui a mais) | PA-04 aprovada; a org não separa público por canal | Tirar o filtro dos públicos de e-mail ou criar cópias por canal |
| PD-03 | Lead "Fechado - Não convertido" sai do público? | Não: só o convertido sai | Padrão: lead não convertido segue nutrível; o convertido já está como Contato | Acrescentar filtro de `Status` no relatório |
| PD-04 | "Compra", para reativação, é o quê? | Oportunidade `Fechado/Ganho`, pela data de fechamento (roll-up `LastPurchase__c`), não Pedido. CA-04 lê "último pedido" como "última oportunidade ganha" | Org: definição do roll-up (seção 2) | Trocar a base dos relatórios `SEM_COMPRA_*` exige demanda própria (campo ou roll-up novo) |
| PD-05 | Opt-out feito no Marketing Cloud volta ao CRM? | O CRM não depende disso: filtra pelo que está nos campos. A sincronização é configuração do conector | Org não mostra; regra 2 | Quem opera o Marketing Cloud confirma e registra |
| PD-06 | O dia 365 sem compra é "181 a 365" ou "mais de 365"? | "181 a 365", como está hoje (faixas contíguas) | Org: filtros atuais (recon) | Ajuste de filtro |
| PD-07 | Público de prospecção priorizada inclui faixa Baixa? | Sim; exclui só "Sem dados suficientes", e o relatório agrupa por faixa | PA-05 aprovada | Filtro de faixa no relatório |
| PD-08 | Janela de reativação por conta ou por contato? | Por conta (`Account.LastPurchase__c`); todos os contatos da conta entram | Org: os públicos são `ContactList` com o campo da conta | Demanda própria se for por contato |

**Pergunta bloqueante (caso 3):** nenhuma.

**Pedidos ao arquiteto humano neste gate** (decisão de operação da esteira, não de negócio):
- **P1.** Autorizar, ou não, que o verificador atribua `PS_Marketing_Publicos` (alterado por esta demanda) ao próprio usuário de execução **só na dev**, removendo ao final, para enxergar `MKT_Origem_Agrupada__c`. A exceção vigente cobre só permission set criado pela demanda. Sem P1, CA-05 fica inconclusivo na dev (R3).
- **P2.** Confirmar a pré-condição R4: comparar os 58 relatórios entre QA e branch antes do deploy na QA.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
