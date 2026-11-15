# EPLAST-38 — Qualificação e roteamento do lead ao vendedor responsável

**Etapa:** análise (`ba-discovery`) · **Data:** 2026-11-15 · **Org consultada:** `sbx-eplast-dev` (sandbox "eplast--qa", conferido com `sf org list`)
**Fonte da demanda:** `demanda.md` (texto curto, sem detalhe de regra) + `comentarios-do-card.md` (orientação de 2026-11-13 do responsável pela conta).

Escopo: Onda 4 (Marketing), ainda não contratada. Pelo escopo não bloqueia (regra 1 da Eplast), a análise segue.

---

## 1. Contexto de negócio

A Eplast quer que os leads entrem no CRM já qualificados e cheguem ao vendedor certo, no momento certo. A demanda não diz como qualificar, quem é o vendedor de cada lead nem quando o encaminhamento acontece.

O que a org já mostra (conferido por `sf`, só metadata e contagens; dev com 0 Lead):

| Peça | Estado na dev | Prova |
|---|---|---|
| Campo `PriorityScore__c` (Lead) | Existe, fórmula numérica, somente leitura. Faixas Alta/Média/Baixa conforme setor, origem e status (desenho anterior: [demandas/EPLAST-26/03-design.md] e verificação [demandas/EPLAST-26/04-verificacao.md]) | FieldDefinition (Tooling) |
| Regra de atribuição `Distribuicao_Regional_Leads` | Existe e **ativa** | `AssignmentRule` (Lead) |
| 8 filas de Lead: Centro-Oeste, ES, MG, Norte e Nordeste, RJ, SP, Sul (PR, SC, RS), Triagem | Existem | `Group` tipo Queue |
| Membros das filas | **Nenhum.** Total de `GroupMember` das filas = 0 | `GroupMember` |
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Existe, **ativo**, AutoLaunched, versão de API 68 | Flow (Tooling) |
| Classe `LeadAssignmentService` + `LeadAssignmentServiceTest` | Existem, API v68 | ApexClass (Tooling) |
| Custom permission `Lead_DistribuicaoAutomaticaViaApi` | Existe | CustomPermission |
| Trigger de Lead | Nenhum | ApexTrigger (TableEnumOrId = Lead) |
| Campos de Marketing Cloud em Lead | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`; `HasOptedOutOfEmail` (padrão) | FieldDefinition |
| Fórmula de origem agrupada `MKT_Origem_Agrupada__c` | Existe, fórmula texto | FieldDefinition |

Leitura: a roteirização já foi montada na org (regra ativa, filas, Flow, classe), mas **sem membros nas filas**, então hoje um lead que casar com a regra cai numa fila vazia. Os componentes não estão versionados no repositório (`force-app` e `manifest` não citam `Distribuicao_Regional_Leads`, `LeadAssignmentService` nem `PriorityScore__c`). Os desenhos de [demandas/EPLAST-26] e [demandas/EPLAST-35] estão em backlog e não têm artefatos no disco desta demanda; o histórico vem do RAG. A origem desses componentes na org (qual demanda ou ação manual os criou) não está confirmada. Isso vai para o recon, que deve cruzar com o histórico e fazer retrieve pontual, não o pacote inteiro.

## 2. Objetivo

1. Todo lead novo recebe uma faixa de prioridade e um responsável (fila regional ou fila de triagem) sem intervenção manual.
2. O que já existe na org é reaproveitado. Nada de regra paralela, Flow paralelo ou agente novo.
3. O lado do CRM fica pronto para o Marketing Cloud ler (ver seção 6).

## 3. Regra de negócio (decidida pelo que a org mostra; premissas na seção 5)

- RN-01: O lead é roteado **na criação** pelo Flow `Lead_AfterInsert_AplicaRegraAtribuicao` e pela regra `Distribuicao_Regional_Leads`.
- RN-02: O critério de região é a UF do lead (campo `State`), conforme as filas regionais. Lead sem UF reconhecida vai para `Leads Triagem`.
- RN-03: O "vendedor responsável" é a fila regional. Quem atende é membro da fila, mantido pelo administrador. Não se cria atribuição por vendedor individual nesta demanda.
- RN-04: A prioridade é o `PriorityScore__c` já existente. Não se grava score em campo novo.
- RN-05: Nenhum e-mail, mensagem ou notificação de disparo sai do CRM. Qualquer comunicação com o lead é do Marketing Cloud (regra 2 da Eplast).

## 4. Critérios de aceite (testáveis)

Testes em dev com leads criados pelo agente (dado de teste, permitido). Em QA (QAS, Partial Copy), só leads criados pelo agente; nenhum registro real é lido ou alterado.

```gherkin
CA-01 Roteamento por UF
  Dado que a regra Distribuicao_Regional_Leads está ativa e as filas regionais existem
  Quando um Lead é criado com State = "SP" e sem OwnerId informado
  Então o OwnerId do Lead é a fila "Leads SP"
  E a verificação é feita por SOQL pelo Id do Lead criado no teste

CA-02 Triagem para UF sem região
  Dado um Lead criado sem State ou com UF que não cai em nenhuma fila regional
  Quando o Flow e a regra são executados
  Então o OwnerId do Lead é a fila "Leads Triagem"

CA-03 Cobertura das 7 regiões
  Dado os 7 valores de UF representativos (um por fila regional, incluindo ES e Centro-Oeste)
  Quando um Lead de teste é criado para cada um
  Então cada Lead cai na fila definida na tabela de regiões do design (a tabela será fechada no design, com base na regra existente)

CA-04 Responsável informado não é sobrescrito
  Dado um Lead criado com OwnerId de um usuário ativo
  Quando é salvo
  Então o OwnerId continua o informado (comportamento a confirmar no recon: ver premissa PA-05)

CA-05 Faixa de prioridade já calculada na criação
  Dado um Lead criado com Sector preenchido, LeadSource preenchido e Status "Contatado"
  Quando é lido o PriorityScore__c e a faixa correspondente
  Então o score é 100 e a faixa é "Alta"; com Status "Aberto - Não contatado" e mesmo setor e origem, o score é 60 e a faixa é "Média"
  (valores do desenho anterior de EPLAST-26; a fórmula é reconferida no build)

CA-06 Carga em massa sem erro
  Dado 200 Leads de teste criados numa única operação via API, distribuídos entre UFs de regiões diferentes
  Quando a operação termina
  Então nenhum Lead fica sem OwnerId, nenhum erro de governador é registrado e a distribuição bate com a tabela de CA-03

CA-07 Nenhum disparo pelo CRM
  Dado o Flow e as classes que a demanda criar ou alterar
  Quando o metadata é conferido
  Então não há ação de e-mail (emailSimple, e-mail alert), chamada de envio ou integração de disparo no CRM
```

Total: **7 critérios**.

## 5. Premissas

Todas abaixo são decisões tomadas com evidência, pela ordem da regra 4 da Eplast. Nenhuma pergunta de negócio ficou sem resposta que bloqueie a demanda.

- [x] **PA-01 — Como qualificar.** Pergunta: qual critério de qualificação o lead precisa ter? Decisão: usar `PriorityScore__c` e a faixa (Alta/Média/Baixa) já existentes. Evidência: campo existe na dev como fórmula, desenhado para isso no EPLAST-26 (fonte: RAG, sem artefato em disco). Como mudar: ajustar a fórmula, que é uma alteração de campo com versão nova.

- [x] **PA-02 — Quando encaminhar.** Pergunta: encaminhar na criação, ao qualificar ou quando o status mudar? Decisão: na criação. Evidência: o Flow ativo é do tipo "after insert" e a regra existente roda no mesmo ponto. Como mudar: criar um segundo ponto de roteamento ao mudar score ou status, o que exige desenho próprio (e cuidado com concorrência, ver seção 7).

- [x] **PA-03 — Critério de região.** Pergunta: a região vem da UF, do setor ou de outro campo? Decisão: UF (`State`). Evidência: as 8 filas são regionais por estados (SP, RJ, MG, ES, Centro-Oeste, Norte e Nordeste, Sul com PR/SC/RS), e a regra existente trabalha sobre UF segundo o desenho de EPLAST-35 (RAG). A correspondência exata UF → fila é confirmada no recon, lendo as entradas da regra. Como mudar: trocar o critério na regra.

- [x] **PA-04 — Quem é o vendedor.** Pergunta: é fila ou pessoa? Decisão: fila regional, com membros mantidos pelo administrador. Evidência: as filas existem e a regra aponta para elas; não há atribuição individual na org. Como mudar: criar atribuição por vendedor (round-robin ou por carteira), o que é outra demanda. Membros das filas ainda não existem: a carga inicial de membros é passo do administrador, registrado no build.

- [x] **PA-05 — Responsável informado manualmente.** Pergunta: se o usuário já escolheu o responsável, a regra sobrescreve? Decisão: não sobrescreve. Evidência: o layout de Lead tem a opção de regra padrão de atribuição (`runAssignmentRulesDefault`), que o EPLAST-35 (RAG) previa alterar para `true`; o comportamento exato de sobrescrita, por dono informado, ainda não foi testado nesta org. Por isso a premissa é reconferida no recon e no teste CA-04, que é o que a prova. Como mudar: alterar a opção do layout ou o Flow.

- [x] **PA-06 — Notificação do vendedor.** Pergunta: o vendedor é avisado quando recebe o lead? Decisão: não nesta entrega. Evidência: a regra 2 da Eplast proíbe disparo de e-mail no CRM, e o padrão de notificação nativa não foi pedido. Como mudar: se o cliente quiser aviso, o caminho é o Marketing Cloud (ou notificação nativa, em demanda própria).

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca leads, origem e prioridade, então a seção é obrigatória (regra 2). Nada é feito no Marketing Cloud, e a esteira não conecta, configura nem cria público lá.

- **Dados que o Marketing Cloud precisa ler:** `Lead.OwnerId` (fila regional), `Lead.State`, `Lead.LeadSource`, `Lead.PriorityScore__c`, `Lead.MKT_Origem_Agrupada__c`, `Lead.Status`, `Lead.Email` (padrão), `Lead.HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c` (já existente).
- **Como o público fica identificável no CRM:** pela fila de dono (`OwnerId` = fila regional ou Triagem), pela faixa de prioridade e pela list view de leads abertos por prioridade, já existente (`Leads_Abertos_Prioridade`, citada em [demandas/EPLAST-26/04-verificacao.md]). Não há campo novo de segmento nesta demanda.
- **O que o Marketing Cloud devolve e onde fica gravado:** nada previsto no escopo. O conector `et4ae5` tem objetos de envio e tracking, mas não foram levantados nesta análise (ver seção 8). Se houver retorno (abertura, clique), a gravação é do conector e fica fora deste build.
- **Consentimento e opt-out:** `HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c` existem. O CRM só lê. A exclusão de opt-out do público é feita por quem opera o Marketing Cloud.
- **Fica para quem opera o Marketing Cloud:** montar o público a partir das filas e da faixa de prioridade, excluir opt-out, e configurar qualquer envio ou jornada de nutrição.

## 7. Riscos do assessment e da org que tocam o pedido

O assessment (API v67, data 2026-09-30) não tem achado específico de Lead. Os riscos abaixo são os que tocam esta demanda:

- **Automação concorrente no objeto (alta, a verificar no design):** a regra de atribuição ativa e o Flow after insert atuam no mesmo evento de criação de Lead. Se a regra e o Flow forem disparados juntos, o dono pode ser definido duas vezes ou o Flow pode sobrescrever a regra. O design deve fixar a ordem e a fonte de verdade (uma só). O assessment trata concorrência em Account, Opportunity e Order; para Lead, esta análise não tem achado de org e a checagem fica para o design.
- **Componentes fora do repositório (média):** regra, filas, Flow, classe e permission existem na dev sem estarem em `force-app`. Se a esteira fizer deploy sem versionar, o estado de QA pode divergir. O recon deve versionar pontualmente o que a demanda usar.
- **Filas sem membros (alta para o resultado):** a regra está ativa, mas nenhuma fila tem membro. Sem carga de membros, o roteamento funciona tecnicamente e entrega ninguém. O build deve tratar isso como entrega, não como detalhe.
- **Versão de API (média):** o assessment registra org v67 e classes antigas (v58/v59). Os componentes de Lead estão em v68, acima da versão da org no diagnóstico. Confirmar a versão atual da org no recon antes do build.
- **Cobertura Apex (alta, global):** `LeadAssignmentService` tem classe de teste, mas a cobertura real não foi medida nesta análise. O build deve medir (meta 85% da classe, mínimo de deploy 75%).

## 8. O que a demanda NÃO diz e que o design precisa fechar

Nenhuma destas perguntas bloqueia a análise. Ficam para o design, que decide com base nas premissas acima.

1. Lista exata de UF por fila (entradas da regra `Distribuicao_Regional_Leads`). Hoje não foi lida; a tabela de CA-03 depende dela.
2. Quem é o membro de cada fila (nomes e papéis). Dado de pessoa não entra no contexto; a lista será fornecida pelo cliente ou pelo administrador.
3. Se o Flow e a regra devem coexistir ou se um deles deve ser desativado (desenho, com ordem de execução).
4. Se o cliente quer score gravado (histórico) ou apenas calculado na leitura (premissa atual).
5. Se há um SLA de primeiro contato por fila (fora do escopo desta análise; hoje não há regra na org).
6. Se os objetos `et4ae5__*` que o conector usa para envio e tracking devem ser lidos pelo CRM (não levantado nesta análise).
7. Se "conversar" com o assistente (SFAgent2) sobre leads é pedido. A demanda não fala de assistente. Se for, a regra 3 manda estender o tópico ou a ação do SFAgent2, não criar agente novo.

## 9. Complexidade e esforço

**Complexidade: M.** Justificativa: a maior parte da roteirização já existe na org, mas há componentes fora do repositório, ordem de execução a fechar entre regra e Flow, e carga de membros das 8 filas com teste de carga.

**Estimativa de esforço:** 8–16 h

Premissas que mais pesam na faixa: (a) a regra e o Flow existentes forem aproveitados sem reescrita (faixa baixa); (b) a ordem de execução entre regra e Flow exigir ajuste de Flow e versão nova (faixa alta); (c) a carga de membros das filas e a tabela UF → fila chegarem prontas do cliente; (d) o teste de carga de 200 leads e a medição de cobertura Apex estarem incluídos. Faixa larga porque a origem dos componentes na org não está confirmada; o arquiteto refina no design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
