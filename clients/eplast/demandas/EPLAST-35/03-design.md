# EPLAST-35 — Design: aprovação, distribuição de Leads e encaminhamento

**Cliente:** Eplast · **Tipo:** projeto · **Onda 3 (Comercial)**: segue pela regra 1 da conta, sem pendência de escopo.
**Org conferida:** `sbx-eplast-dev` (sandbox, `IsSandbox = true`, API 68.0 confirmada pelo `sf`; o briefing dizia v67). Só leitura nesta etapa: metadata, retrieve em diretório temporário e `COUNT()`. Nenhum DML, deploy ou dado de registro.
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 2026-11-15), `02-recon.md` (com o complemento do arquiteto ao final), `comentarios-do-card.md`, `assessment.md` (2026-09-30), RAG do cliente.
**Respostas D1 a D12:** não existem. `comentarios-do-card.md` traz só as orientações gerais do responsável pela conta e o registro de aprovação do gate (que pede para conferir as premissas aqui). `demanda.md` não tem respostas. Todas as perguntas foram tratadas pela regra 4 (seção 10).

---

## 1. Resumo da decisão

| Frente | Decisão | Nível |
|---|---|---|
| Aprovação | **Reaproveita os três Approval Processes ativos, sem alterá-los.** Não cria alçada de desconto. Entrega só visibilidade: relatório de aprovações pendentes no tipo de relatório que a org já tem | 1 — configuração |
| Distribuição de Leads | **Regra de atribuição nativa de Lead** por região (UF), copiando a régua que a Eplast já usa nos seus relatórios, com 8 filas (7 regiões + Triagem). Layout com a caixa de atribuição marcada por padrão | 1 — configuração |
| Distribuição de Leads criados por integração | Flow after-save de Lead (caminho assíncrono) que chama uma ação Apex invocável mínima para reaplicar **a mesma** regra nativa. Liga só para usuários com uma custom permission | 2 + 3 (ponte mínima) |
| Encaminhamento | **Transferência nativa de proprietário do Lead** para fila ou vendedor (OWD `ReadWriteTransfer` já permite), com histórico de campo ligado em `OwnerId` e `Status` | 1 — configuração |

Nenhum objeto entre Account, Opportunity, Order, Quote e `SBQQ__Quote__c` recebe componente novo ou alterado. Nenhum campo custom novo. Nenhuma mudança de modelo de dados (nada a escalar como decisão de arquitetura sênior).

### Por que não ficar só no nível 1 na distribuição
A regra de atribuição nativa só roda quando o salvamento pede: caixa marcada na tela, cabeçalho `AssignmentRuleHeader` na API ou Web-to-Lead. Leads criados por integração sem esse cabeçalho (é o caso de formulários do Marketing Cloud gravando direto no CRM, que não enviam o cabeçalho) ficariam com o usuário integrador como dono. Flow não tem elemento que dispare regra de atribuição; só Apex (`Database.DMLOptions.assignmentRuleHeader.useDefaultRule`). Por isso a ponte é código, mas mínima: **a régua continua na regra nativa** (editável em Setup, sem deploy), e o Apex só pede para a plataforma aplicá-la. Alternativa descartada: replicar a régua dentro do Flow (nível 2 puro), porque criaria dois motores de régua para manter em sincronia.

### Por que não criar nova aprovação
A org já aprova, por motor nativo, **toda** cotação submetida (`Quote.AssignPricing`, sem critério de entrada, aprovador do Pricing), **todo** pedido submetido (`Order.LiberationFinancial`, sem critério de entrada) e a oportunidade na etapa `Análise Financeira` (`Opportunity.FinancialAnalysis`). Uma alçada de desconto na Quote concorreria com `AssignPricing` (dois processos no mesmo objeto, um deles sem critério: a ordem dos processos decide qual captura a submissão) e exigiria um limite e um aprovador que nem a org nem o padrão indicam. Pela regra 3 da conta, não sobrepomos. A alternativa fica desenhada na seção 9 para o cliente escolher na homologação.

---

## 2. Mapa reaproveita / altera / cria

| # | Componente (API name) | Ação | Prova de existência ou de ausência |
|---|---|---|---|
| 1 | `ApprovalProcess` `Quote.AssignPricing`, `Opportunity.FinancialAnalysis`, `Order.LiberationFinancial` | **Reaproveita, sem alteração** | retrieve; ativos |
| 2 | Relatório `Histrico_de_Aprovao_XNR` (pasta Geral) | **Reaproveita, sem alteração** (é histórico da Análise financeira; alterá-lo mudaria o que o cliente já usa) | retrieve |
| 3 | Tipo de relatório `Inst_ncias_do_processo_de_aprova_o__c` | **Reaproveita** | usado pelo relatório #2 |
| 4 | Relatório `Aprovacoes_Pendentes_Por_Processo` (pasta Geral, **Summary**, agrupado por processo; filtro status pendente; colunas processo, data de criação, tempo decorrido, aprovador atual se o tipo oferecer) | **Cria** | ausente (busca por nome em Report) |
| 5 | `AssignmentRules` `Lead` — regra `Distribuicao_Regional_Leads` (ativa) | **Altera** (hoje é um conjunto vazio) | retrieve |
| 6 | Filas (Queue, objeto suportado `Lead`): `Leads_SP`, `Leads_RJ`, `Leads_MG`, `Leads_ES`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem` | **Cria** (sem membros; membros são passo do admin) | 0 Groups `Type='Queue'` |
| 7 | Layout `Lead-Lead Layout` | **Altera** só `runAssignmentRulesDefault` de `false` para `true` | retrieve |
| 8 | Histórico de campo de Lead: `enableHistory` no objeto e `trackHistory` em `OwnerId` e `Status` | **Altera** | `IsFieldHistoryTracked = false` hoje |
| 9 | Custom permission `Lead_DistribuicaoAutomaticaViaApi` | **Cria** | só existe `IA_Rascunho_Comercial` |
| 10 | Permission set `PS_Integracao_DistribuicaoLead` (custom permission #9 + acesso à classe #12) | **Cria** | ausente |
| 11 | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (record-triggered, after save, **create**, caminho assíncrono) | **Cria** | nenhum Flow ativo em Lead |
| 12 | Classe `LeadAssignmentService` (método `@InvocableMethod`) + `LeadAssignmentServiceTest` | **Cria** | ausente |
| 13 | List views de fila | **Reaproveita o automático**: cada fila nova gera sua list view de Lead | — |
| 14 | Relatórios `LEADS - SP/RJ/MG/SUL/GERAL`, `Hot_Leads_w_o_Activity_96_Hours`, `LeadsbySource`, `MKT_Leads_por_Origem` | **Reaproveita, sem alteração** (servem de acompanhamento) | SOQL Report |
| 15 | `Lead.Status`, `LeadSource`, `State`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | **Reaproveita** | describe / FieldDefinition |
| 16 | Agente `SFAgent2` | **Não se aplica**: a demanda não pede assistente, resumo, recomendação ou linguagem natural. Nada criado nem estendido | regra 3 |
| 17 | Salesforce Maps (`maps__AssignmentRule__c`, 0 registros) | **Não usado** na v1 (régua territorial por mapa exige licença e territórios que a org não tem); fica como evolução | `COUNT()` |

Descrição obrigatória (assessment, achado 4): fila, custom permission, permission set, Flow, classe e relatório saem com `description` (ou comentário de cabeçalho na classe) iniciando por "EPLAST-35." e dizendo o propósito. Nenhum campo custom é criado.

### 2.1 Regra `Distribuicao_Regional_Leads` (entradas em ordem)

A régua é a mesma dos relatórios da pasta `MARKETING CLOUD` (ver complemento do recon). Critério: `Lead.State` igual a (lista separada por vírgula, como nos relatórios).

| Ordem | Critério (`State` igual a) | Atribui a |
|---|---|---|
| 1 | SP | `Leads_SP` |
| 2 | RJ | `Leads_RJ` |
| 3 | MG | `Leads_MG` |
| 4 | ES | `Leads_ES` |
| 5 | PR,SC,RS | `Leads_Sul` |
| 6 | GO,DF,MT,MS,TO | `Leads_CO` |
| 7 | AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE | `Leads_NO_NE` |
| 8 | sem critério (pega tudo o que sobrou: UF vazia, por extenso, fora do Brasil) | `Leads_Triagem` |

Sem e-mail de notificação ao novo dono na regra (`template` vazio): a regra 2 da conta reserva comunicação ao Marketing Cloud; aviso interno ao vendedor fica pela list view da fila e pela notificação padrão da plataforma, se o admin quiser ligar.

### 2.2 Flow `Lead_AfterInsert_AplicaRegraAtribuicao` e classe `LeadAssignmentService`

- Gatilho: Lead criado. Condição de entrada (fórmula): `$Permission.Lead_DistribuicaoAutomaticaViaApi` **e** `LEFT({!$Record.OwnerId}, 3) = "005"` (dono ainda é usuário, ou seja, a regra não rodou no insert). Sem a permissão (todo usuário de tela), o Flow não faz nada.
- Caminho **assíncrono** (Run Asynchronously): a transação da integração não é afetada; a reatribuição ocorre logo após o commit.
- Ação: `LeadAssignmentService.aplicarRegraPadrao(List<Id>)` — uma consulta `SELECT Id FROM Lead WHERE Id IN :ids AND IsConverted = false`, define `DMLOptions.assignmentRuleHeader.useDefaultRule = true` em cada registro e faz **um** `Database.update(leads, false)`; erros por registro vão para o log de depuração do Flow (sem dado pessoal na mensagem). A classe é `without sharing`, explícito e documentado, porque precisa reatribuir o dono independentemente do acesso de quem criou o Lead.
- API version 68.0. `LeadAssignmentServiceTest`: cobertura >= 85%; casos: lote de 200 Leads com UF de várias regiões, UF vazia (Triagem), Lead já em fila (não reprocessa), lista vazia, Lead convertido ignorado. Fixture preenche os campos exigidos pelas VRs ativas de Lead (`Celular`, `Telefone`: deixar vazios ou em formato válido — confirmar a fórmula no build) com dados sintéticos.

---

## 3. Ordem de execução nos objetos tocados

### Lead (único objeto com automação nova)
Inventário atual confirmado: nenhum trigger (custom ou de pacote), nenhum Flow ativo, 2 VRs ativas (`Celular`, `Telefone`), regra de atribuição vazia. Ordem resultante:

1. **Insert pela tela, caixa marcada (padrão novo):** validação de sistema → VRs `Celular`/`Telefone` → gravação → **regra de atribuição** (dono vira a fila) → after-save Flow `Lead_AfterInsert_AplicaRegraAtribuicao` avalia a entrada: usuário de tela não tem a permissão → não roda → commit.
2. **Insert pela tela, caixa desmarcada pelo vendedor** (prospecção própria): igual, sem atribuição; o vendedor continua dono.
3. **Insert pela API por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho:** VRs → gravação → sem atribuição → Flow entra (dono é usuário) → commit → **transação assíncrona**: `LeadAssignmentService` faz update com a regra padrão → VRs → atribuição → o Flow não reentra (é só de criação) → commit. Sem recursão.
4. **Insert pela API com cabeçalho:** a regra roda no insert; dono vira fila; o Flow não entra (dono começa com `00G`).
5. **Transferência manual (encaminhamento):** update de `OwnerId` → VRs → gravação → histórico de campo → nenhum Flow (o novo é só de criação).

A regra de atribuição roda **depois** das after triggers e **antes** dos after-save Flows (doutrina). O design depende disso só no ponto 1 (o Flow vê o dono já trocado e não entra). Está documentado como dependência e coberto por teste de QA.

### Conversão de Lead
Não é alterada. Converter cria Account, Contact e Opportunity e dispara a cadeia já existente (`AccountTrigger`, `AccountBefore` do SBQQ, Flows `AccountTriggered` e `UpdateParentAccountUsedLimit`; `OpportunityTrigger`, `OpportunityBefore`/`OpportunityAfter` do SBQQ, Flow `OpportunityFlow`; 16 VRs ativas de Opportunity). Lead com dono fila exige que quem converte escolha um usuário como dono dos registros convertidos (comportamento padrão). O QA **não** exercita conversão nesta demanda (ver seção 6, R4).

### Account, Opportunity, Order, Quote, `SBQQ__Quote__c`
**Não tocados.** Nada é criado, alterado ou desativado neles, nem nos três Approval Processes. A ordem relativa entre `OpportunityTrigger`, os triggers SBQQ e os Flows after-save desses objetos **continua não mapeada** (o recon não conseguiu, e este design não depende dela). Esse mapeamento segue como pré-requisito de qualquer demanda que mude esses objetos, incluindo a alternativa B da seção 9. Inventário corrigido no complemento do `02-recon.md`.

---

## 4. Riscos do assessment, por objeto e automação mexidos

| Achado do assessment | Como este design lida |
|---|---|
| #1 Automação concorrente em Account/Opportunity/Order (trigger custom + CPQ + Flows) | **Não se aplica à mudança**: nenhum desses objetos é tocado. Lead não tem concorrência (zero trigger, zero Flow). A única via até eles é a conversão, que não muda |
| 23 VRs de Order (8 de campo obrigatório, 6 inativas de máquina de estados) | **Não se aplica**: Order não é tocado. Contagem reconferida: 17 ativas + 6 inativas |
| 153 campos custom sem descrição | Nenhum campo novo. Todo componente novo sai com descrição "EPLAST-35. ..." |
| `OrderTrigger` custom com o mesmo nome do SBQQ | **Não se aplica**: nenhum trigger criado ou tocado. Classe nova com nome inequívoco (`LeadAssignmentService`) |
| API version desatualizada nas classes custom | Nenhuma classe existente é tocada. Código novo nasce em 68.0 |
| Cobertura Apex de 10% | Classe nova com `LeadAssignmentServiceTest` >= 85%. Não reduz a cobertura geral, mas também não resolve o bloqueio para produção (org abaixo de 75%); ver R6 |
| Alias `sbx-eplast-dev` em sandbox que se chama `qa`; `sbx-eplast-qa` não listada | Build usa `sbx-eplast-dev`. A etapa de QA depende de a esteira ter a sandbox de QA distinta (R5) |
| Perfis comerciais duplicados (4 variações) | Nada atribuído por perfil: integração recebe permission set; filas recebem usuários/grupos pelo admin |

---

## 5. Impacto em permissões

- **Novo:** `PS_Integracao_DistribuicaoLead` (custom permission `Lead_DistribuicaoAutomaticaViaApi` + acesso à classe `LeadAssignmentService`). Atribuído **só** a usuários de integração que criam Lead (incluindo o usuário do conector Marketing Cloud, se ele criar Leads). A atribuição é passo do admin da Eplast na sandbox de QA e depois em produção; o build não atribui a usuários reais.
- **Filas:** membros não vêm no deploy. O admin inclui vendedores (ou o grupo/papel) em cada fila. Para o QA, a esteira usa usuários de teste da sandbox.
- **Perfis:** nenhuma alteração. O OWD de Lead `ReadWriteTransfer` já permite que qualquer usuário interno transfira Lead (encaminhamento) e assuma Lead da fila da qual é membro.
- **Relatório novo** na pasta Geral, que já existe; mesmo acesso do relatório de histórico de aprovação.
- **Aprovações:** sem mudança de aprovador.

---

## 6. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | `Lead.State` é texto livre (sem picklist de estado). "São Paulo" ou "sp " não casam com "SP" e caem em `Leads_Triagem` | Média | Triagem garante dono. Relatório/list view da Triagem mostra o volume; ativar picklists de estado/país é mudança da org inteira, fora desta demanda |
| R2 | Integração que cria Lead sem ter recebido o permission set não distribui | Média | Passo do admin listado na entrega; teste de QA com e sem o PS |
| R3 | Ponte assíncrona: o dono muda segundos depois do insert; quem integra e lê o dono na mesma chamada vê o usuário integrador | Baixa | Documentado; integrações que puderem devem mandar o cabeçalho (ponto 4 da seção 3) |
| R4 | Conversão de Lead dispara a cadeia Account/Opportunity, que inclui a integração Protheus sem teste | Média (pré-existente) | Não é alterada nem exercitada no QA; o roteiro diz isso. Teste de conversão fica para quando a cadeia Protheus tiver cobertura |
| R5 | Sandbox de QA não confirmada como distinta da dev (só `sbx-eplast-dev` aparece; instância se chama `qa`) | Média | Condição de infraestrutura para a etapa de QA, não pergunta de negócio; a esteira confere no passo de deploy em QA |
| R6 | Org com cobertura de 10%: nenhum deploy com Apex chega a produção sem resolver isso | Alta (pré-existente, fora da esteira) | A esteira para na QA. Registrado para o release; esta demanda não piora |
| R7 | Mudar `runAssignmentRulesDefault` muda o comportamento da tela para todo vendedor: Lead novo vai para a fila se ele não desmarcar | Média | Premissa PA-14; reverte com um clique no layout |
| R8 | Deploy da configuração de histórico do objeto Lead pode carregar outras propriedades do objeto | Baixa | Build implanta só `enableHistory` e os dois campos, a partir de retrieve fresco |
| R9 | Relatório por metadata custa caro (doutrina, achado EPLAST-39) | Baixa | Copiar `scope`, colunas e filtro do `Histrico_de_Aprovao_XNR`; formato Summary; se o filtro de status for recusado duas vezes, sai do escopo e vira pendência do plano de build |

**Governador e escala:** carga em massa de 200 Leads pela API = 1 interview em lote, 1 SOQL e 1 DML na transação assíncrona; CPU desprezível (Lead sem trigger e com 2 VRs). Cenário "um pai com muitos filhos" não se aplica: Lead não tem filho em cascata nem roll-up, e a demanda não toca objeto pai. Volume atual da dev: 0 Lead; dado de teste sintético.

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca leads e origem; a seção é obrigatória (regra 2). Nada é feito no Marketing Cloud, e nada é enviado pelo CRM.

| Ponto | Onde fica no CRM |
|---|---|
| Dados que o Marketing Cloud lê | Lead: `FirstName`, `LastName`, `Email`, `Company`, `State`, `LeadSource`, `Status`, `Rating`, `Sector__c`, `Subsector__c`, `OwnerId` (fila = região). Nenhum campo novo |
| Como o público fica identificável | Pelo dono (fila regional `Leads_*`) ou pela UF, com os relatórios já existentes `LEADS - SP/RJ/MG/SUL/GERAL` (pasta `MARKETING CLOUD`). `Status = Aberto - Não contatado` separa quem ainda não foi trabalhado. Campanha e membro de campanha seguem o padrão (0 registros hoje na dev) |
| O que o Marketing Cloud devolve e onde grava | Retorno de envio continua onde o conector já grava (objetos `et4ae5__IndividualEmailResult__c` e afins, existentes). Leads que o Marketing Cloud criar no CRM (formulários) entram pela ponte da seção 2.2, se o usuário do conector tiver `PS_Integracao_DistribuicaoLead` |
| Consentimento e opt-out | `Lead.HasOptedOutOfEmail` (já no layout) e `et4ae5__HasOptedOutOfMobile__c`. A distribuição não altera consentimento; transferir o Lead de dono não mexe nesses campos |
| O que fica para quem opera o Marketing Cloud | 1) Se criar Leads no CRM, gravar `State` com a sigla da UF e `LeadSource` com o valor da picklist (ex.: `E-mail MKT`), para cair na fila certa. 2) Montar público excluindo opt-out. 3) Se quiser segmentar por região, usar o dono (fila) ou a UF. Passos fora da esteira |

---

## 8. O que NÃO será feito nesta demanda

- Nova aprovação (alçada de desconto, margem ou valor) e qualquer mudança nos três Approval Processes (alternativa B na seção 9).
- Troca de aprovador, aprovador delegado ou gestor de usuário (é dado de usuário, ação do admin).
- Escalonamento ou prazo automático de aprovação e de primeiro contato com Lead (RN-4/D8).
- Round robin, distribuição por capacidade, score ou território do Salesforce Maps.
- Encaminhamento de demandas internas para áreas (Pricing, Fiscal, Financeiro) por Case ou Task.
- Integração com Protheus; teste de conversão de Lead.
- Mapeamento completo da ordem de execução de Opportunity/Order/Quote (não é tocado; segue pré-requisito de quem tocar).
- Ativação de picklists de estado/país.
- Qualquer configuração, jornada, público ou envio no Marketing Cloud; qualquer envio de e-mail pelo CRM.
- Agente `SFAgent2`: sem alteração.

---

## 9. Alternativas discutidas

**Aprovação**
- **A (escolhida):** reaproveitar os três processos + relatório de pendentes. Zero risco nos objetos CPQ/Order.
- **B:** alçada de desconto na Quote padrão (`Quote.Discount`, campo padrão), limite num Custom Metadata (`Eplast_Parametro_Comercial__mdt`) lido por fórmula, aprovador fila (`Aprovacao_Desconto`), processo ordenado antes de `AssignPricing` com critério de entrada. Custo: +16–28 h, cria campo fórmula (mudança de modelo de dados leve) e exige antes o mapeamento de ordem de execução da Quote (`Quote_AfterUpdate_SyncToCPQ` roda em todo update e o bloqueio de registro durante a aprovação pode impedir a sincronização com o CPQ). Só se o cliente pedir.
- **C:** Flow de aprovação (Approval Orchestration) — descartado: muda o motor que a Eplast já usa e exige licença/recurso não confirmado.

**Distribuição**
- **A (escolhida):** regra nativa regional + ponte para API.
- **B:** régua inteira em Flow com Custom Metadata (nível 2 puro) — descartada: dois motores de régua.
- **C:** Salesforce Maps — descartada na v1: 0 regras, sem territórios.

**Encaminhamento**
- **A (escolhida):** transferência nativa de Lead + histórico.
- **B:** Case com tipo "Solicitação interna", filas por área e regra de atribuição de Case — descartada na v1: introduz um processo novo que a org não usa (0 Case) sem evidência de que é isso que se quer.
- **C:** Task para a área por etapa da oportunidade — descartada: toca Opportunity, objeto de maior risco, e Task não aceita fila.

---

## 10. Premissas assumidas (validar na homologação)

A aprovação do gate de análise foi dada em lote e pede conferência das premissas aqui. As premissas da análise vinham todas como `[pendente]`; abaixo cada uma resolvida pela regra 4, com evidência.

### Da análise (resolvidas neste design)

- [x] **PA-01 (D1, D2, D3, P2) — Qual aprovação, qual motor, qual critério?** Decisão: nenhuma aprovação nova; os três processos nativos ficam como estão. Evidência (org): `AssignPricing` e `LiberationFinancial` sem critério de entrada (toda cotação e todo pedido submetidos são aprovados); `FinancialAnalysis` na etapa `Análise Financeira`; nenhum campo, regra ou Flow de alçada de desconto. Padrão: regra 3, não sobrepor. Como mudar: alternativa B da seção 9 (+16–28 h).
- [x] **PA-02 (D7, RN-2) — Quem aprova?** Decisão: os aprovadores atuais (usuários nomeados nos processos). Evidência: retrieve; aprovação por gestor impossível hoje (0 de 19 usuários ativos com gestor). Como mudar: admin preenche gestor ou aprovador delegado no usuário, sem deploy.
- [x] **PA-03 (D4, RN-3, P7) — Régua de distribuição?** Decisão: por região da UF do Lead, 7 regiões + Triagem. Evidência (org): é a régua dos relatórios da Eplast na pasta `MARKETING CLOUD` (Lead por SP/RJ/MG/SUL; conta por SP/RJ/MG/ES/SUL/CO/NO-NE); a regra de atribuição existente é vazia (substituída). Como mudar: editar entradas da regra em Setup, sem deploy.
- [x] **PA-04 (RN-3) — Para quem, dentro da região?** Decisão: para a fila; o vendedor assume o Lead da fila. Sem round robin. Evidência: padrão da plataforma (regra nativa não faz rodízio), opção mais simples. Como mudar: membros da fila pelo admin; rodízio vira demanda própria.
- [x] **PA-05 (D5) — Processo atual de Lead em produção?** Decisão: assumimos que não há distribuição automática. Evidência: dev sem regra, Flow ou trigger em Lead. Como mudar: se produção tiver algo, o recon da próxima rodada compara (sem tocar produção).
- [x] **PA-06 (D6) — O que é "encaminhamento de demandas"?** Decisão: encaminhar o Lead para outra fila ou vendedor, com registro de quem mudou e quando. Evidência (org): OWD de Lead `ReadWriteTransfer`; o encaminhamento para áreas internas já acontece pelas etapas da oportunidade e pelas aprovações financeira e de Pricing. Como mudar: alternativa B (Case por área) numa demanda própria.
- [x] **PA-07 (D8, RN-4) — Prazos e escalonamento?** Decisão: sem prazo automático na v1; acompanhamento pelo relatório de pendentes, pelas list views das filas e pelo relatório existente `Hot_Leads_w_o_Activity_96_Hours`. Evidência: padrão (aprovação nativa não escala sozinha); nenhum SLA na org. Como mudar: demanda de escalonamento.
- [x] **PA-08 (D9, P3) — Protheus?** Decisão: fora. Evidência: nenhum componente desta demanda toca Account/Order.
- [x] **PA-09 (P4) — Mapeamento da ordem de execução entra?** Decisão: não é necessário, porque Account/Opportunity/Order/Quote não são tocados; fica como pré-requisito de quem tocar.
- [x] **PA-10 (P5) — Cobertura?** Decisão: classe nova com teste dedicado >= 85%; nenhuma classe existente tocada.
- [x] **PA-11 (D10, P6) — Sandbox de QA?** Build em `sbx-eplast-dev`. A distinção dev/QA é condição de infraestrutura conferida pela esteira no passo de QA (R5), não pergunta de negócio.
- [x] **PA-12 (D11) — Quem homologa?** Decisão: o responsável pela conta indica o homologador pelo card. Padrão do squad.
- [x] **PA-13 (D12) — Dados de teste?** Decisão: sintéticos, criados pelo QA na sandbox de QA, sem CPF, e-mail ou telefone reais. Padrão do squad (guardrail #2).
- [x] **PA-14 (P8) — Regra de horário ou aprovador obrigatório?** Decisão: nenhuma além dos guardrails. Evidência: `CLAUDE.md` do cliente não traz.

### Novas deste design

- [x] **PA-15 — Lead criado na tela vai para a fila?** Decisão: sim por padrão (caixa "Atribuir usando regra ativa" passa a vir marcada); o vendedor desmarca quando o Lead é prospecção dele. Evidência: o layout já mostra a caixa (desmarcada); padrão da plataforma. Como mudar: um clique no layout.
- [x] **PA-16 — Leads de integração são distribuídos?** Decisão: sim, só para usuários com `PS_Integracao_DistribuicaoLead`. Como mudar: atribuir ou remover o PS, sem deploy.
- [x] **PA-17 — UF fora do padrão?** Decisão: cai em `Leads_Triagem`. Evidência: `State` é texto livre. Como mudar: incluir variações na entrada da regra, sem deploy.
- [x] **PA-18 — Notificação ao novo dono?** Decisão: sem e-mail da regra; aviso pela list view da fila. Evidência: regra 2 da conta. Como mudar: o admin pode ligar notificação interna padrão.
- [x] **PA-19 — Relatório de aprovações?** Decisão: cria um de pendentes; o histórico existente não é alterado. Como mudar: excluir ou ajustar o filtro na tela.

### Perguntas que bloqueiam (caso c)

Nenhuma. Todas as decisões acima são configuráveis e reversíveis sem perda de dado; nenhuma muda modelo de dados.

---

## 11. Critérios de aceite ajustados (sobre a análise)

- **Aprovação:** os cenários de "dentro/acima da alçada" e "aprovação vencida" ficam fora (PA-01, PA-07). Ficam: "nova aprovação não duplica as existentes" (prova: os três `ApprovalProcess` recuperados antes e depois do deploy são idênticos) e "decisão registrada" (prova: histórico de aprovação já ligado, `showApprovalHistory = true`), mais o relatório de pendentes renderizando pela Analytics API.
- **Distribuição:** Lead com UF de cada região cai na fila certa; UF vazia ou fora do padrão cai em `Leads_Triagem`; Lead criado na tela com a caixa desmarcada fica com o criador; Lead criado pela API por usuário com o PS vai para a fila; sem o PS, fica com o criador; lote de 200 pela API distribui todos.
- **Encaminhamento:** transferir o Lead para outra fila ou vendedor grava o histórico de `OwnerId`; Lead nunca fica sem dono (fila de Triagem).
- **Isolamento:** criar e atribuir Leads não altera a contagem de Account, Opportunity nem Order (`COUNT()` antes e depois).
- **Qualidade:** `LeadAssignmentServiceTest` >= 85%; descrições preenchidas; dados sintéticos.

---

## 12. Estimativa

**Estimativa de esforço:** 40–70 h

O que mudou em relação à análise (120–260 h) e por quê:
- A org já cobre a aprovação: nenhuma aprovação nova nem mexida em Opportunity/Quote/Order. Saem o mapeamento de ordem de execução desses objetos e a cobertura de classes existentes (nenhuma é tocada), que eram a maior parte da faixa.
- A régua de distribuição veio da própria org (relatórios regionais), sem desenho de algoritmo.
- Encaminhamento é configuração nativa.
- Composição: filas, regra, layout e histórico 8–12 h; Flow + classe + teste 10–16 h; relatório de pendentes 4–8 h (doutrina: relatório por metadata é caro); verificação e QA com dados sintéticos, roteiro e homologação 14–26 h; revisão de PR e documentação 4–8 h.
- Não inclui a alternativa B de aprovação (+16–28 h) nem Protheus.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Respostas do cliente (2026-11-17) — valem acima das premissas assumidas deste desenho

A Eplast respondeu por escrito ("Respostas Konecta/Eplast", recebido em 17/11) aos pontos que
este desenho tinha resolvido como premissa assumida. Registrado por Leonardo Barbosa, que
mandou redesenhar com as respostas. **Onde a resposta abaixo diverge de uma premissa deste
arquivo, vale a resposta.** O que o cliente marcou como "a validar" continua premissa, a
repetir no roteiro em "O que assumimos e você precisa confirmar". Os parâmetros ficam
configuráveis (pedido do cliente), sem deploy para ajustar. Reaproveite o que já foi
construído e passou no QA; mude só o que a resposta pede. Os artefatos de build e QA da
rodada anterior estão em `rodada-anterior/premissas-assumidas/` para consulta.

**Resposta do cliente (EPLAST-35 — aprovação, distribuição de leads e encaminhamento):**
- Aprovação: mapear os três processos existentes e complementá-los, sem duplicar. Gatilhos
  (desconto acima da alçada, margem abaixo do mínimo, prazo fora da política, exceção de
  frete ou pedido mínimo, limite de crédito) **dependem de matriz de valores e alçadas que a
  Eplast ainda vai aprovar**.
- Distribuição dos leads: **região/território** como regra principal, **respeitando contas
  com proprietário já definido**. Dentro da mesma região, **rodízio** entre responsáveis
  elegíveis. Demandas técnicas ou projetos especiais podem ter encaminhamento específico.
- Regionais: SP (SP); RJ/ES (RJ, ES); MG (MG); SUL (PR, SC, RS); CO (DF, GO, MT, MS, TO);
  NO/NE (AC, AP, AM, PA, RO, RR, AL, BA, CE, MA, PB, PE, PI, RN, SE).
- Encaminhamento de demandas: transferência comercial e encaminhamento a áreas internas, com
  fluxos distintos; demanda interna com registro rastreável (responsável, prazo, status).
- Aprovadores: filas por área e alçadas definidas; matriz de Comercial, Financeiro, PCP,
  Logística e Qualidade a validar pela Eplast.

**O que muda neste desenho (só a distribuição de leads; o resto espera a Eplast):**
1. Regiões conforme a tabela acima (6 regionais, **RJ e ES juntas**), mantendo a Triagem
   para UF fora do padrão.
2. **Rodízio** dentro da região entre os membros elegíveis, no lugar de "fica na fila e o
   vendedor assume" (revê a PA-04). Avalie a forma declarativa de rodízio; os elegíveis por
   região são configuração que o administrador mantém (a Eplast ainda vai informar os nomes).
3. **Respeitar proprietário já definido:** lead cuja empresa já corresponde a uma conta com
   proprietário vai para esse proprietário, se houver forma confiável de casar lead e conta
   (por exemplo CNPJ); se não houver, declarar a limitação.
4. **Não construir** gatilhos de aprovação, alçadas nem o encaminhamento a áreas internas:
   dependem da matriz da Eplast e são escopo a combinar. Manter os três processos como
   estão e registrar o mapeamento deles para a conversa com o cliente.
