# EPLAST-45 · Design: nutrição de leads até a abordagem comercial

**Decisão:** configuração nativa. Dois campos fórmula e dois campos de retorno no Lead, dois relatórios de público na pasta do Marketing Cloud, uma list view para o vendedor e ajuste de permissões. Sem Flow, sem Apex, sem nada no Marketing Cloud.
**Cliente:** eplast · **Etapa:** design · **Data:** 2026-11-15 · **Autor:** arquiteto
**Org consultada:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`), única conectada em `sf org list`. Só leitura; só metadata e contagens agregadas.
**Insumos:** `01-analise.md` (aprovado em `gates.md`, 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, `00-preflight.md` (sem bloqueio, nenhuma outra demanda nos mesmos componentes), `assessment.md` (achados 1, 2, 4, 6, 10), skills `salesforce-doutrina` e `padrao-entrega`, RAG do cliente (designs EPLAST-26, 42, 43, 44).
**Bloqueio:** nenhum. Nenhuma pergunta caiu no caso 3 da regra 4.

**Estimativa de esforço:** 8–14 h
O que mudou em relação à análise (12–20 h): o recon e esta sessão confirmaram que não há Workflow Rule, trigger nem Flow de update em Lead, então a solução fica toda em fórmula, sem Flow e sem coordenar ordem de execução. Os relatórios de público partem de XML de relatórios `LeadList` que já existem na pasta `MARKETING CLOUD` (`MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_PRIORIDADE`), e isso tira o custo de descobrir o formato que pesou na EPLAST-39. O que continua pesando: fixture de Lead que passe nas validation rules `Celular` e `Telefone`, e o roteiro de QA. Não inclui o trabalho de quem opera o Marketing Cloud.

---

## 1. Solução escolhida e por que este nível

### 1.1 Em uma frase
O Lead ganha dois sinalizadores calculados ("em nutrição" e "pronto para abordagem") e dois campos para o Marketing Cloud devolver o engajamento. Os públicos de e-mail e de mensagem saem de relatórios que excluem quem deu opt-out, e o vendedor vê os prontos numa list view.

### 1.2 Alternativas avaliadas

| Alternativa | Avaliação | Decisão |
|---|---|---|
| (a) **Campo fórmula** no Lead para elegibilidade e prontidão; públicos em relatório | Nível 1 da doutrina (configuração nativa). Não entra na ordem de execução, não gasta CPU nem DML, não depende de volume (PA-09) e muda editando uma linha. Atende CA-01 a CA-06 | **Escolhida** |
| (b) Flow before-save em Lead que grava os sinalizadores e a data em que o lead ficou pronto | Daria um campo armazenado (bom se o Marketing Cloud precisar de "mudou para pronto" como gatilho) e a data da prontidão. Custa uma automação nova em Lead, que hoje só tem o Flow de atribuição em Create. Nada na análise pede histórico da data | Não agora. Fica como caminho se quem opera o Marketing Cloud precisar de campo armazenado (risco R4) |
| (c) Apex (trigger ou batch) | Nenhum critério da doutrina para descer a código: sem callout, sem volume alto confirmado, sem rollback complexo | Descartada |
| (d) Campo de elegibilidade por canal (e-mail e mensagem) | Mais três campos. A org já segmenta opt-out por filtro de relatório (`LEADS_PROSPECCAO_PRIORIDADE`, `MSG_LEADS_CELULAR_APTOS`, EPLAST-42 e 44), e o padrão da conta é esse | Descartada; canal fica no relatório (PD-02) |

Por que não um nível acima: (a) já é o nível mais alto da ordem de preferência. Nenhum componente desce para Flow ou código.

### 1.3 Regras de cálculo

- `MKT_Nutricao_Elegivel__c` (fórmula, Checkbox):
  `AND(NOT(IsConverted), OR(ISPICKVAL(Status, "Aberto - Não contatado"), ISPICKVAL(Status, "Contatado")))`
  RN1 e RN4. Valores de `Status` conferidos na org (4 ativos). O opt-out **não** entra aqui: entra no público de cada canal (CA-02).
- `MKT_Nutricao_ProntoAbordagem__c` (fórmula, Checkbox):
  `AND(MKT_Nutricao_Elegivel__c, PriorityBand__c = "Alta")`
  RN2 e RN4. Reaproveita a faixa existente; não altera `PriorityScore__c` nem `PriorityBand__c`.

**Efeito da fórmula atual de faixa (lido pelo recon, não é suposição):** "Alta" (score >= 70) só acontece com `Status = Contatado` mais setor ou origem preenchidos. Um lead `Aberto - Não contatado` chega no máximo a "Média". Na prática, "pronto para abordagem" é lead contatado, com setor ou origem, ainda não convertido. O engajamento do Marketing Cloud aparece como coluna para o vendedor, mas não muda a prontidão (PD-04, ponto de decisão D1).

---

## 2. Mapa item a item: o que reaproveita e o que cria (regra 3)

| # | Componente (API name) | Ação | Prova de que existe / não existe | O que muda |
|---|---|---|---|---|
| 1 | `Lead.PriorityScore__c`, `Lead.PriorityBand__c` | Reaproveita, sem alteração | recon (Tooling `CustomField`) | Base de "pronto para abordagem" |
| 2 | `Lead.Status`, `Lead.IsConverted`, `Lead.HasOptedOutOfEmail` | Reaproveita | `FieldDefinition` nesta sessão; picklist no recon | Critérios de elegibilidade e opt-out de e-mail |
| 3 | `Lead.et4ae5__HasOptedOutOfMobile__c` (pacote `et4ae5`) | Reaproveita, sem alteração | recon | Opt-out de mensagem |
| 4 | `Lead.MKT_Origem_Agrupada__c`, `Sector__c`, `Subsector__c` | Reaproveita, sem alteração | recon | Colunas de segmentação nos públicos |
| 5 | `Lead.MKT_Nutricao_Elegivel__c` (fórmula Checkbox) | **Cria** | Não existe (recon: nenhum campo de nutrição em Lead) | Seção 1.3 |
| 6 | `Lead.MKT_Nutricao_ProntoAbordagem__c` (fórmula Checkbox) | **Cria** | Não existe | Seção 1.3 |
| 7 | `Lead.MKT_MC_Engajamento__c` (Picklist **restrita**: `Sem engajamento`, `Baixo`, `Médio`, `Alto`) | **Cria** | Não existe campo de engajamento em Lead (recon, seção 1 e 4) | Gravado pelo Marketing Cloud (PA-10, PD-03) |
| 8 | `Lead.MKT_MC_EngajamentoData__c` (DateTime) | **Cria** | Não existe | Data e hora da última devolução do Marketing Cloud |
| 9 | Relatório `MARKETINGCLOUD/NUTRICAO_LEADS_EMAIL` ("NUTRIÇÃO - LEADS - E-MAIL"), `LeadList`, Tabular, escopo `org` | **Cria** | Nenhum relatório de nutrição na pasta (19 relatórios de Lead listados nesta sessão) | Filtros: `Lead.MKT_Nutricao_Elegivel__c = Verdadeiro`, `EMAIL_OPT_OUT = Falso`, `EMAIL` diferente de vazio. Colunas no padrão de `MSG_LEADS_CELULAR_APTOS`: `LEAD_ID`, `FIRST_NAME`, `LAST_NAME`, `COMPANY`, `EMAIL`, `STATE`, `Lead.Sector__c`, `LEAD_SOURCE`, `Lead.PriorityBand__c`, `STATUS`, `Lead.MKT_Nutricao_ProntoAbordagem__c`, `Lead.MKT_MC_Engajamento__c` |
| 10 | Relatório `MARKETINGCLOUD/NUTRICAO_LEADS_MENSAGEM` ("NUTRIÇÃO - LEADS - MENSAGEM"), `LeadList`, Tabular, escopo `org` | **Cria** | idem | Filtros: `Lead.MKT_Nutricao_Elegivel__c = Verdadeiro`, `Lead.et4ae5__HasOptedOutOfMobile__c = Falso`, `MOBILE_PHONE` diferente de vazio. Colunas como o 9, trocando `EMAIL` por `MOBILE_PHONE` e `Lead.et4ae5__Mobile_Country_Code__c` |
| 11 | `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_PRIORIDADE` e demais relatórios da pasta | Reaproveita **como modelo de XML**, sem alterar | describe de relatório nesta sessão (filtros e colunas lidos) | Não se altera público que outra demanda entregou |
| 12 | List view `Lead.Leads_Abertos_Prioridade` ("Leads abertos por prioridade") | Reaproveita, sem alteração | describe da list view nesta sessão: filtro `IsConverted = false` e Status fora dos dois "Fechado", o mesmo critério de `MKT_Nutricao_Elegivel__c` | É a visão "em nutrição" do vendedor (PD-06) |
| 13 | List view `Lead.Leads_Prontos_Abordagem` ("Leads prontos para abordagem") | **Cria** | Não existe (recon, seção 5) | Filtro `MKT_Nutricao_ProntoAbordagem__c = true`. Colunas de `Leads_Abertos_Prioridade` mais `MKT_MC_Engajamento__c` e `MKT_MC_EngajamentoData__c`. Visibilidade e escopo copiados de `Leads_Abertos_Prioridade` (CA-04, PA-08) |
| 14 | Permission set `PS_Comercial_ScorePrioridade` | **Altera** (só FLS de leitura) | existe (`PermissionSet` nesta sessão) | + leitura em 5, 6, 7 e 8 |
| 15 | Permission set `PS_Marketing_Publicos` | **Altera** (só FLS de leitura) | existe | + leitura em 5, 6, 7 e 8 |
| 16 | Permission set `PS_Marketing_RetornoMC` | **Cria** | Não há PS não gerenciado para escrita de retorno do Marketing Cloud; os do `et4ae5` são gerenciados e não se alteram | Só leitura em 5 e 6, e leitura e edição em 7 e 8. Sem permissão de objeto nova. A atribuição ao usuário de integração do Marketing Cloud é passo manual (seção 6e) |
| 17 | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Não toca | recon (ativo, Create, after-save) | Nenhuma nova versão; a solução não muda dono (PA-07, CA-06) |
| 18 | Validation rules `Celular` e `Telefone` de Lead | Não toca | lidas nesta sessão (formato `(DD)NNNNNNNNN` sem espaço) | Ver risco R2 e plano de fixtures |
| 19 | `SFAgent2` | Não se aplica | regra 3 da conta; recon (`BotDefinition`) | A demanda não pede assistente, resumo ou recomendação |
| 20 | Campaign / CampaignMember (`et4ae5__Activity__c`) | Não toca | recon (0 registros; campo existe) | O retorno de engajamento vai para o Lead, não para membro de campanha (PD-03) |

Nenhum objeto novo, nenhum Flow, nenhuma classe Apex, nenhum perfil alterado, nenhum componente em Account, Opportunity ou Order.

### 2.1 Descrições (CA-10)
Todo componente criado ou alterado leva `description` começando por "EPLAST-45." e dizendo quem lê ou grava o campo. Nos campos 7 e 8: "Gravado pelo Marketing Cloud. Não editar à mão."

---

## 3. Ordem de execução nos eventos tocados

Objeto tocado: só **Lead**. Na org hoje (recon e esta sessão):

| Evento em Lead | O que roda hoje | O que a solução acrescenta |
|---|---|---|
| Insert | Validation rules `Celular`, `Telefone`; Flow after-save `Lead_AfterInsert_AplicaRegraAtribuicao` (ação Apex invocável) | Nada. Fórmula é calculada na leitura, não é passo da transação |
| Update (vendedor muda Status, setor, origem) | Validation rules `Celular`, `Telefone`. Nenhum Flow de update, trigger ou Workflow Rule em Lead | Nada. As fórmulas recalculam na leitura |
| Update (Marketing Cloud grava `MKT_MC_Engajamento__c`) | Validation rules `Celular`, `Telefone` | Nada. Não há automação que reaja ao campo, e por isso Status, faixa e dono não mudam (CA-07) |
| Conversão | Processo padrão de conversão | Nada. `IsConverted = true` zera os dois sinalizadores (CA-05) |

- CPQ e triggers custom: nenhum trigger em Lead (0, Tooling `ApexTrigger`), nenhum dos 14 triggers `et4ae5` em Lead. A colisão de nome `OrderTrigger` (achado 10) e a automação concorrente em Account, Opportunity e Order (achado 1) ficam fora do caminho desta solução.
- **Atenção futura, fora desta demanda:** se quem opera o Marketing Cloud criar um evento de entrada "Salesforce Data" em Lead no Journey Builder, o conector pode passar a ter automação própria em Lead. Isso entra na ordem de execução do objeto e deve ser registrado por quem configurar (seção 6e).
- CPU e volume: fórmula de duas condições sobre uma fórmula já existente. Não há laço, SOQL, DML nem processamento de pai com muitos filhos. Volume alto de leads (PA-09) pesa só no tempo de execução do relatório, não em limite de governador.
- Tamanho compilado da fórmula: `MKT_Nutricao_ProntoAbordagem__c` referencia `PriorityBand__c`, que referencia `PriorityScore__c`. O builder confere no deploy de validação (`--dry-run`) que o limite de caracteres compilados não estoura. Risco baixo pelo tamanho das três fórmulas.

---

## 4. Riscos do assessment que tocam o escopo

| Achado do assessment | Toca? | Como é tratado |
|---|---|---|
| 1 · Automação concorrente em Account, Opportunity e Order | Não | A solução não grava nesses objetos nem cria automação. CA-08 confere por metadata |
| 2 · Cobertura Apex ~10% | Não | Sem Apex. CA-11 fica sem objeto, e a verificação registra "não se aplica" |
| 3 · Validation Rules do Order | Não | Order fora do escopo |
| 4 · Campos custom sem descrição | Sim, nos campos novos | Todos os componentes novos com `description` (seção 2.1). Sem curadoria dos campos existentes de Lead, que estão fora do escopo |
| 5 · Classe de teste fora da convenção | Não | Sem Apex |
| 6 · Alias dev com nome "qa" | Não é risco | Resolvido pela regra 5 da conta. Conferido por `sf org list` |
| 10 · `OrderTrigger` com nome duplicado do CPQ | Não | Order fora do escopo |
| Validation rules de Lead (não está no assessment; lidas nesta sessão) | **Sim** | Ver R2 |

---

## 5. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | "Pronto para abordagem" nunca vale para lead `Aberto - Não contatado`, porque a faixa "Alta" exige `Contatado`. Leads nutridos e engajados que nunca foram contatados não aparecem como prontos | Média (de negócio) | Declarado na seção 1.3. Decisão D1 no gate. A mudança é uma linha na fórmula do campo 6 |
| R2 | **As validation rules `Celular` e `Telefone` rodam em todo update de Lead.** Lead com telefone fora do formato `(DD)NNNNNNNNN` faz a gravação do Marketing Cloud em `MKT_MC_Engajamento__c` falhar | Média | Não se alteram as regras nesta demanda. Fica declarado para quem opera o Marketing Cloud (seção 6e). Fixture com telefone no formato aceito. Desvio para o usuário de integração, se a Eplast quiser, entra em demanda própria (D3) |
| R3 | Picklist restrita recusa valor fora da lista: se o Marketing Cloud mandar outro rótulo, a gravação falha | Baixa | É proposital, porque a doutrina mostra que picklist aberta grava valor solto (achado SOMOSAGILITY-21). Os valores ficam declarados na seção 6c para quem opera o Marketing Cloud |
| R4 | Fórmula não é campo armazenado: se o Marketing Cloud precisar de "mudou para pronto" como gatilho de jornada, a fórmula pode não servir | Baixa | Fallback: alternativa (b), um Flow before-save que grava o sinalizador. É demanda nova, com design próprio |
| R5 | O usuário de teste é Administrador do sistema e não serve para o caso de acesso negado | Baixa | Acesso conferido pelo metadata dos permission sets (seção 8) |
| R6 | `MKT_Origem_Agrupada__c` não é lido pelo usuário conectado (FLS só em 3 permission sets) | Baixa | Não entra nos relatórios novos, só `LEAD_SOURCE`. Não se mexe na FLS desse campo |

---

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda é de marketing (nutrição). O build entrega só o lado do CRM. A esteira não conecta, não configura e não cria nada no Marketing Cloud.

**a) Dados que o Marketing Cloud lê e onde ficam**

| Dado | Objeto · campo | Fonte para o Marketing Cloud |
|---|---|---|
| Chave | Lead · `Id` | Relatórios 9 e 10 (coluna `LEAD_ID`) ou dados sincronizados do conector |
| Endereço de envio | Lead · `Email` (e-mail), `MobilePhone` e `et4ae5__Mobile_Country_Code__c` (mensagem) | Relatório do canal correspondente |
| Personalização | Lead · `FirstName`, `LastName`, `Company`, `State` | Relatórios 9 e 10 |
| Segmentação | Lead · `Sector__c`, `LeadSource`, `PriorityBand__c`, `Status` | Relatórios 9 e 10 |
| Estágio da nutrição | Lead · `MKT_Nutricao_Elegivel__c`, `MKT_Nutricao_ProntoAbordagem__c` | Filtro e coluna |

Só os campos acima vão para o público, para não mandar ao Marketing Cloud dado pessoal além do necessário (LGPD).

**b) Como o público fica identificável no CRM**
- Público de nutrição por e-mail: relatório `NUTRICAO_LEADS_EMAIL`.
- Público de nutrição por mensagem: relatório `NUTRICAO_LEADS_MENSAGEM`.
- Os dois na pasta `MARKETING CLOUD`, que o time de marketing já usa (EPLAST-36, 42 e 44).
- Lead que ficou pronto continua elegível e continua no público até ser convertido ou fechado. Quem opera o Marketing Cloud pode usar `MKT_Nutricao_ProntoAbordagem__c` para tirá-lo da jornada de nutrição.

**c) O que o Marketing Cloud devolve e onde é gravado**
- `Lead.MKT_MC_Engajamento__c`: um dos valores `Sem engajamento`, `Baixo`, `Médio`, `Alto` (API name igual ao rótulo). Picklist restrita (R3).
- `Lead.MKT_MC_EngajamentoData__c`: data e hora da gravação.
- Quem grava: o usuário de integração do conector, com o permission set `PS_Marketing_RetornoMC`.
- A régua (o que é "Alto") é definida por quem opera o Marketing Cloud.

**d) Consentimento e opt-out**
- E-mail: `HasOptedOutOfEmail = true` sai do relatório de e-mail. Mensagem: `et4ae5__HasOptedOutOfMobile__c = true` sai do relatório de mensagem.
- Um opt-out de um canal não tira o lead do outro (CA-02).
- O descadastro feito no Marketing Cloud volta ao CRM pelos mesmos campos, via conector. Garantir essa sincronização e respeitar o opt-out na entrega é de quem opera o Marketing Cloud.

**e) O que fica com quem opera o Marketing Cloud (passos fora da esteira)**
1. Importar os relatórios 9 e 10 (ou montar o público equivalente pelos dados sincronizados) e criar a jornada de nutrição, com conteúdo, cadência e frequência.
2. Configurar a atividade de atualização do Lead para gravar `MKT_MC_Engajamento__c` e `MKT_MC_EngajamentoData__c` com os valores da seção 6c.
3. Pedir ao admin da Eplast que atribua `PS_Marketing_RetornoMC` ao usuário de integração do conector.
4. Saber que leads com telefone fora do formato aceito pelas validation rules recusam a gravação (R2) e acompanhar os erros de sincronização.
5. Se criar evento de entrada "Salesforce Data" em Lead, avisar o time do CRM, porque isso entra na ordem de execução do objeto.

---

## 7. Premissas assumidas (validar na homologação)

Valem as premissas PA-01 a PA-10 da análise, todas mantidas. PA-10 fica fechada: o recon confirmou que não existe campo de engajamento em Lead, e por isso os campos 7 e 8 são criados. Premissas acrescentadas no design:

- [x] **PD-01 · Prefixo dos campos novos.** Pergunta: qual prefixo usar? O `CLAUDE.md` da conta não define. Decisão: `MKT_`. Evidência: `Lead.MKT_Origem_Agrupada__c`, campo de marketing que já existe na org. Como mudar: renomear antes do deploy em QA, porque depois disso fica caro.
- [x] **PD-02 · Opt-out por canal fica no relatório, não em campo.** Pergunta: o público de cada canal vira campo próprio? Decisão: não, vira filtro de relatório. Evidência: os públicos existentes (`LEADS_PROSPECCAO_PRIORIDADE`, `MSG_LEADS_CELULAR_APTOS`) filtram opt-out no relatório. Como mudar: criar fórmula por canal (alternativa d).
- [x] **PD-03 · Formato do retorno de engajamento.** Pergunta: o que o Marketing Cloud devolve? Decisão: faixa em picklist restrita, com quatro valores, mais data e hora, no Lead. Evidência: padrão de faixa já usado na org (`PriorityBand__c`: Alta, Média, Baixa). Faixa é o formato mais simples de ler em list view. Como mudar: incluir valor na picklist, ou trocar por número (score) antes de quem opera o Marketing Cloud configurar.
- [x] **PD-04 · Engajamento não muda a prontidão.** Pergunta: lead com engajamento "Alto" fica pronto mesmo sem faixa Alta? Decisão: não. Prontidão = elegível e faixa "Alta", como diz CA-04 da análise aprovada. O engajamento aparece como coluna. Evidência: CA-04 ("a lista de prontos não contém leads de faixa Média ou Baixa"). Como mudar: na fórmula do campo 6, trocar a condição por `OR(PriorityBand__c = "Alta", ISPICKVAL(MKT_MC_Engajamento__c, "Alto"))`. Decisão D1.
- [x] **PD-05 · Quem grava o retorno.** Pergunta: qual usuário do conector escreve no Lead? Decisão: um permission set novo e mínimo (`PS_Marketing_RetornoMC`), atribuído por admin. Evidência: os permission sets do `et4ae5` são gerenciados. O uso de `Marketing_Cloud_Connected_App` (não gerenciado) não foi levantado, e alterá-lo mexeria em algo cujo papel não conhecemos (regra 3). Como mudar: incluir a FLS no permission set que a Eplast indicar e apagar o novo.
- [x] **PD-06 · Visão "em nutrição" do vendedor.** Pergunta: precisa de list view nova de elegíveis? Decisão: não. Reaproveita `Leads_Abertos_Prioridade`, que tem o mesmo critério. Evidência: query da list view lida nesta sessão. Como mudar: criar list view filtrada por `MKT_Nutricao_Elegivel__c`.
- [x] **PD-07 · `Fechado - Não convertido` não é nutrido.** Pergunta: lead fechado sem conversão entra na nutrição? Decisão: não. Reativação já tem público próprio (`Cpia_de_LEADS_GERAL_D2D`, "LEADS - NÃO CONVERTIDOS", EPLAST-43). Evidência: PA-04 e `[demandas/EPLAST-43/03-design.md]`. Como mudar: incluir o status na fórmula do campo 5.

---

## 8. Plano de testes: dados e usuário

**Dado de teste (regra 6):** a dev não tem Lead (contagem 0). O verificador cria `clients/eplast/fixtures/lead-nutricao.apex` (Apex anônimo, só em `sbx-eplast-dev` e, no QA, em `sbx-eplast-qa`) e o registra no `fixtures/README.md`. Todo nome leva `TESTE`, e o e-mail é fictício em domínio reservado (`example.com`). Telefone e celular ficam em branco, ou no formato `(DD)NNNNNNNNN` exigido pelas validation rules `Celular` e `Telefone`, com números fictícios. Leads mínimos:

| Lead | Status | Setor / Origem | Opt-out | Esperado |
|---|---|---|---|---|
| L1 | Aberto - Não contatado | preenchidos | nenhum | Elegível, não pronto; nos dois públicos se tiver e-mail e celular (CA-01, R1) |
| L2 | Contatado | preenchidos | nenhum | Elegível e pronto; na list view de prontos (CA-04) |
| L3 | Contatado | preenchidos | e-mail | Fora do público de e-mail, no de mensagem (CA-02) |
| L4 | Contatado | preenchidos | mobile | Fora do público de mensagem, no de e-mail (CA-03) |
| L5 | Contatado → convertido | preenchidos | nenhum | Sai dos dois públicos e da list view (CA-05) |
| L6 | Contatado | vazios | nenhum | Elegível, faixa "Sem dados suficientes", não pronto |
| L7 | Fechado - Não convertido | preenchidos | nenhum | Não elegível (PD-07) |

- CA-06 e CA-07: em L2, gravar `MKT_MC_Engajamento__c = Alto` e a data, simulando o Marketing Cloud. Conferir que `Status`, `PriorityBand__c` e `OwnerId` não mudam e que o lead continua pronto (PD-04).
- CA-01: contagem do relatório 9 igual a `SELECT COUNT() FROM Lead WHERE MKT_Nutricao_Elegivel__c = true AND HasOptedOutOfEmail = false AND Email != null`, restrita aos leads `TESTE`.
- CA-08 e CA-10: inspeção de metadata (nenhum Flow nem Apex novo; todas as `description` preenchidas).
- CA-11: não se aplica (sem Apex).
- Limpeza: o script diz no topo como apagar os leads `TESTE`. Na QA (Partial Copy), só registros criados pelo agente (regra 5).

**Usuário de teste:** o usuário de serviço da conta (regra 6), Id ativo na dev `005bJ00000piKAaQAM`, perfil Administrador do sistema. É o proprietário dos leads de teste, e CA-06 confere que o dono continua esse Id. Ele não serve para acesso negado (R5). O acesso é provado pelo metadata dos permission sets 14, 15 e 16: leitura nos campos novos e edição só em 7 e 8, só no 16. Na QA, o agente de QA resolve o Id pela consulta da regra 6. Não se altera perfil nem permissão desse usuário.

---

## 9. O que NÃO será feito nesta demanda

- Nada no Marketing Cloud: jornada, público, conteúdo, envio, conector ou sincronização.
- Envio de e-mail ou mensagem pelo CRM (e-mail alert, Apex de e-mail, notificação por e-mail).
- Alteração de `PriorityScore__c`, `PriorityBand__c`, das validation rules `Celular` e `Telefone`, do Flow de atribuição ou da regra `Distribuicao_Regional_Leads`.
- Alteração dos relatórios de público existentes na pasta `MARKETING CLOUD`.
- Reatribuição de dono, criação de tarefa ou notificação ao vendedor (PA-07, PA-08).
- Contact, Campaign e CampaignMember como público de nutrição (PA-02).
- Extensão do `SFAgent2`.
- Curadoria de descrição dos campos existentes de Lead.

---

## 10. Impacto em permissões

- Perfis: nenhum alterado.
- `PS_Comercial_ScorePrioridade` e `PS_Marketing_Publicos`: + leitura nos 4 campos novos.
- `PS_Marketing_RetornoMC` (novo): leitura em 5 e 6; leitura e edição em 7 e 8. Sem atribuição pelo build.
- Pasta de relatório `MARKETING CLOUD`: compartilhamento existente, não alterado.
- List view `Leads_Prontos_Abordagem`: mesma visibilidade de `Leads_Abertos_Prioridade`.

---

## 11. Pontos que pedem decisão humana no gate

- **D1 · Prontidão com engajamento (R1, PD-04).** Hoje só lead contatado fica pronto. Quer que engajamento "Alto" no Marketing Cloud também torne o lead pronto? Isso muda CA-04. O padrão do design é "não".
- **D2 · Mudança de modelo de dados (decisão de arquitetura sênior).** São 4 campos novos em Lead (2 fórmulas e 2 de retorno), sem objeto novo. Pede aceite explícito do arquiteto humano, principalmente sobre o prefixo `MKT_` (PD-01) e o formato picklist do retorno (PD-03).
- **D3 · Validation rules de telefone (R2).** Aceitar que gravações do Marketing Cloud falhem em lead com telefone fora do formato, e tratar desvio para integração em demanda separada?
- **D4 · Permission set de retorno (PD-05).** Criar `PS_Marketing_RetornoMC`, ou a Eplast indica permission set existente do usuário de integração?

Nenhum desses pontos bloqueia o build: todos têm decisão padrão registrada.

---

## 12. Rollback

Excluir a list view 13, os relatórios 9 e 10 e o permission set 16. Reverter a FLS dos permission sets 14 e 15 para a versão anterior (da `main`). Excluir os campos 5 a 8, nesta ordem: 6, depois 5, depois 7 e 8. Antes, é preciso tirá-los dos relatórios e da list view. Nenhum dado de negócio é perdido, exceto o retorno de engajamento que o Marketing Cloud já tiver gravado.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
