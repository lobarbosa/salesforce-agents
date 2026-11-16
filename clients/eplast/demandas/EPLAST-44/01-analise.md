# EPLAST-44 — Jornadas automáticas de comunicação

**Cliente:** Eplast · **Onda:** 4 · Marketing (autorizada a seguir, regra 1 da conta)
**Org conectada:** `sbx-eplast-dev` (sandbox `eplast--qa`), confirmada com `sf org list` em 2026-11-15
**Etapa:** analise · **Fonte:** `demandas/EPLAST-44/demanda.md` + `comentarios-do-card.md` (2026-11-13 e 2026-11-15)

---

## 1. Contexto de negócio

A demanda pede jornadas automáticas de comunicação. Na versão original ela dependia de uma
plataforma de marketing ainda não definida. Em 2026-11-15 o responsável pela conta definiu o
**Marketing Cloud** como plataforma (comentário do card, 2026-11-15 03:11).

Pela regra de marketing da conta (regra 2 do `CLAUDE.md` da Eplast), tudo que é disparo
(e-mail, mensagem, campanha, jornada, nutrição) acontece no Marketing Cloud. No Sales Cloud
fica o que alimenta o Marketing Cloud: dado, público (segmento), status e opt-out.

O histórico desta conta já tem demandas de público e segmentação para o Marketing Cloud, com
o mesmo desenho: relatório no CRM lido pelo Marketing Cloud, sem envio pelo CRM
([demandas/EPLAST-36/03-design.md], [demandas/EPLAST-42/01-analise.md]).

## 2. Objetivo

Preparar o lado do Sales Cloud para que as jornadas de comunicação rodem no Marketing Cloud:
públicos identificáveis, dados disponíveis e opt-out respeitado. **Esta demanda não cria
envio, jornada nem público no Marketing Cloud.**

Objetivo mensurável do build: cada jornada tem, no CRM, um público (relatório) que o Marketing
Cloud consegue ler, com exclusão de opt-out e de lead convertido, testado em dados sintéticos
na sandbox de dev.

## 3. Regra de negócio

O que a demanda já deixa claro:
- Jornada é executada no Marketing Cloud (comentário de 2026-11-15).
- O CRM entrega público, dado e status. Sem envio pelo CRM.
- Escopo não bloqueia (comentário de 2026-11-13).
- Pergunta de regra de negócio sem resposta vira premissa assumida, pela org ou pelo padrão
  (regra 4 da conta).

O que ainda não está definido e está listado na seção 9: as jornadas, o público de cada uma
e o gatilho de entrada.

## 4. Escopo

**Dentro (lado do CRM):**
- Relatórios de público para cada jornada, reaproveitando os existentes quando atendem.
- Filtros de exclusão: opt-out de e-mail, opt-out de mensagem, lead convertido.
- Campo ou status no CRM só se um gatilho não puder ser expresso com campos que já existem.

**Fora:**
- Qualquer configuração no Marketing Cloud: conexão, público, jornada, envio, conteúdo.
- E-mail alert, Flow com ação de e-mail ou Apex de envio no CRM.
- Campaign e CampaignMember novos (ver premissa PA-04).

## 5. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca marketing (jornada, nutrição, comunicação). Esta seção é obrigatória (regra 2).

**a) Dados que o Marketing Cloud precisa ler e onde ficam no CRM** (campos confirmados em
`sbx-eplast-dev` por FieldDefinition, 2026-11-15):

| Dado | Objeto e campo | Uso |
|---|---|---|
| E-mail | `Contact.Email`, `Lead.Email` (campo padrão) | Destinatário |
| Opt-out de e-mail | `Contact.HasOptedOutOfEmail`, `Lead.HasOptedOutOfEmail` | Exclusão |
| Opt-out de mensagem | `Contact.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__HasOptedOutOfMobile__c` | Exclusão |
| Status do lead | `Lead.Status`, `Lead.IsConverted` | Prospecção e exclusão de convertido |
| Origem | `Lead.LeadSource`, `Contact.LeadSource`, `Opportunity.LeadSource` | Recorte |
| Campanha de origem | `Lead.CampaignId`, `Opportunity.CampaignId` | Recorte (sem registros hoje) |
| Estágio da oportunidade | `Opportunity.StageName` | Recorte de pós-venda, se a jornada usar |
| Atividade recente | `LastActivityDate` (padrão, Lead, Contact, Opportunity) | Reativação |

Não confirmados nesta org: `MKT_Origem_Agrupada` e `PriorityBand`/`PriorityScore`. A consulta
de FieldDefinition em Lead, Contact e Opportunity não os retornou. A análise EPLAST-42 cita
esses campos. Divergência a checar antes de qualquer relatório que os use.

**b) Como o público fica identificável do lado do CRM:** relatório salvo, dinâmico, na pasta
de marketing. Não há campanha de envio no CRM (Campaign tem 0 registros nesta org).

**c) O que o Marketing Cloud devolve e onde é gravado:** não lido nesta etapa. O conector
`et4ae5` está instalado e grava atividade em `CampaignMember.et4ae5__Activity__c`
([demandas/EPLAST-42/01-analise.md] PA-02). O recon confirma o que o conector lê e grava no
CRM antes de qualquer campo novo (regra 2).

**d) Consentimento e opt-out:** exclusão obrigatória de `HasOptedOutOfEmail` e de
`et4ae5__HasOptedOutOfMobile__c` em todo público (premissa PA-02).

**e) Fica para quem opera o Marketing Cloud:** criar públicos e jornadas a partir dos
relatórios, definir cadência, conteúdo e canal, e configurar qualquer envio. Responsável
assumido: time de marketing da Eplast (premissa PA-08).

## 6. Riscos do assessment que tocam o pedido

Assessment em `clients/eplast/assessment.md`, uma foto antiga. Itens confirmados ou não
confirmados nesta sessão estão marcados.

- **Ordem de execução em Account, Opportunity e Order (achado 1).** Build só de relatório e
  campo não escreve nesses objetos e não entra na ordem de triggers. Se o gatilho exigir
  gravar em Opportunity, Account ou Order, esta análise precisa ser refeita: mapear a ordem
  entre `AccountTrigger`/`OpportunityTrigger`/`OrderTrigger`, os triggers do CPQ e os Flows
  antes do design.
- **Lead tem um Flow ativo que não estava no assessment.** `Lead_AfterInsert_AplicaRegraAtribuicao`
  (custom, ativo, confirmado em 2026-11-15). Qualquer alteração em Lead passa por versão nova
  antes da implementação (convenção do squad). Se a jornada depender de criação ou atribuição
  de lead, o desenho mapeia esse Flow.
- **Cobertura de teste em 10% (achado 2).** Se o build não tiver Apex, o risco fica no
  verificador e nos relatórios, não em classe. Se o desenho pedir Apex, a cobertura mínima
  de 85% por classe é obrigatória.
- **Campos sem descrição (achado 4).** Assessment: 19 de 28 em Opportunity e 78 de 90 em
  Account. Campo que a jornada usar deve ter o significado confirmado com quem construiu,
  antes de ser usado como critério de público.
- **Nome ambíguo de `OrderTrigger` (achado 3).** Só relevante se a demanda tocar Order.
- **Dev sem registros de negócio.** Lead, Contact e Campaign têm 0 registros (COUNT
  confirmado). O resultado dos relatórios só pode ser testado com dado sintético criado para
  o teste, com prefixo `EPLAST44 TESTE`. Volume real não pode ser inferido daqui.

## 7. O que já existe na org (regra 3)

| Item | Achado | Prova |
|---|---|---|
| Relatórios | 409 no total | `COUNT` em `Report`, 2026-11-15 |
| Pasta de marketing | 35 relatórios em `MARKETING CLOUD` na EPLAST-36 | Não recontado nesta sessão |
| Campos de opt-out | Existem em Lead e Contact | FieldDefinition |
| Campanha | 0 registros | `COUNT` em `Campaign` |
| Flow ativo em Lead | `Lead_AfterInsert_AplicaRegraAtribuicao` | FlowDefinition |
| Flows `MCC_*` | Citados como dezenas na EPLAST-26/33. Não confirmados nesta sessão | — |
| `SFAgent2` | Não se aplica: a demanda não pede assistente, resumo nem linguagem natural | — |

Se o gatilho ou o público pedir resumo ou recomendação em linguagem natural, o caminho é
estender `SFAgent2`, não criar agente novo.

## 8. Critérios de aceite (testáveis)

Todos os dados são sintéticos, com prefixo `EPLAST44 TESTE`, na sandbox de dev. Nenhum critério
exige ler registro real.

**CA-01 — Opt-out de e-mail excluído**
- Dado um `Contact` sintético com `HasOptedOutOfEmail = true` que atende aos demais critérios
  de um público de jornada,
- Quando o relatório desse público for executado,
- Então esse contato não aparece no resultado.

**CA-02 — Opt-out de mensagem excluído (Lead e Contact)**
- Dado um `Lead` e um `Contact` sintéticos com `et4ae5__HasOptedOutOfMobile__c = true`, ambos
  atendendo aos demais critérios de um público de jornada,
- Quando os relatórios desses públicos forem executados,
- Então nenhum dos dois aparece no resultado.

**CA-03 — Lead convertido fora da prospecção**
- Dado o relatório de público de prospecção,
- Quando seu metadata for inspecionado,
- Então o filtro contém `IsConverted = false`,
- E, quando houver lead sintético convertido no teste, ele não aparece na execução.
- Observação: a dev não tem leads, então a prova principal é o metadata.

**CA-04 — Nenhum envio no CRM**
- Dado o pacote de metadata gerado pelo build,
- Quando procurado por `EmailTemplate`, `EmailAlert`, ação de Flow de envio de e-mail e Apex
  que use `Messaging` ou `SingleEmailMessage`,
- Então nenhuma ocorrência existe.

**CA-05 — Reuso dos relatórios existentes**
- Dado a contagem de relatórios da pasta de marketing registrada em `04-plano-build.md` antes
  do build,
- Quando o build terminar,
- Então cada relatório novo ou alterado tem justificativa de por que o existente não atendia,
  e o número de relatórios sem justificativa é zero.

**CA-06 — Gatilho de entrada refletido no público** *(bloqueado pela PEND-02)*
- Dado um registro sintético que muda o campo definido como gatilho (conforme PEND-02),
- Quando o relatório de público for executado depois da mudança,
- Então o registro aparece no público; e, quando sai da condição, deixa de aparecer.

## 9. O que a demanda NÃO diz

1. **Quais jornadas** (quantas, nome e objetivo de cada uma). Sem isso não há público nem
   gatilho para construir.
2. **Quem entra e quem sai** de cada jornada, e o gatilho de entrada.
3. **Público-alvo:** lead, cliente (Contact/Account), oportunidade ou uma combinação.
4. **Canal:** só e-mail, ou também mensagem. A exclusão de mensagem já existe no conector.
5. **Cadência, conteúdo e frequência.** Ficam com quem opera o Marketing Cloud.
6. **Quem opera o Marketing Cloud e aprova o conteúdo** do lado da Eplast.
7. **Volume esperado.** Não dá para inferir: a dev não tem registros de negócio.
8. **Se a jornada precisa de dado de compra (Order)**, o que mudaria o risco de ordem de
   execução (seção 6).
9. **Se a Eplast quer medir retorno por campanha no CRM**, o que ligaria esta demanda à
   EPLAST-39.
10. **O que o conector `et4ae5` lê e grava** hoje nos objetos de CRM. Será confirmado pelo
    recon.

## 10. Premissas assumidas (validar na homologação)

Decididas pela org ou pelo padrão, conforme a regra 4 da conta. Cada uma pode ser trocada
sem refazer a análise.

- [x] **PA-01 — Lead ou Contact como público?**
  - Pergunta: a jornada atinge lead, cliente ou ambos?
  - Decisão: prospecção (Lead não convertido) e relacionamento (Contact) são públicos
    separados. Lead convertido sai do público de prospecção.
  - Evidência: Lead tem `IsConverted` e `Status`, e Contact tem o mesmo opt-out (FieldDefinition,
    2026-11-15). Padrão: a conversão move o contato para Contact.
  - Como mudar: trocar o filtro do relatório.

- [x] **PA-02 — Opt-out**
  - Pergunta: quais opt-outs excluem o contato?
  - Decisão: exclui `HasOptedOutOfEmail = true` para e-mail e
    `et4ae5__HasOptedOutOfMobile__c = true` para mensagem, em todo público.
  - Evidência: os dois campos existem em Lead e Contact na org. Padrão de consentimento.
  - Como mudar: não é configurável sem decisão do cliente e do responsável pela conta.

- [x] **PA-03 — Público vive em relatório no CRM**
  - Pergunta: o público é relatório, campanha ou lista?
  - Decisão: relatório salvo e dinâmico, lido pelo Marketing Cloud. Mesmo desenho das
    demandas anteriores.
  - Evidência: 409 relatórios na org, e o precedente EPLAST-36/42. Regra 3: reaproveitar.
  - Como mudar: campanha no CRM, se a Eplast quiser medir retorno. Vira demanda ligada à
    EPLAST-39.

- [x] **PA-04 — Sem Campaign nem CampaignMember novos**
  - Pergunta: a jornada precisa de registro de campanha no CRM?
  - Decisão: não. A campanha vive no Marketing Cloud.
  - Evidência: Campaign tem 0 registros nesta org. Precedente EPLAST-42 (PA-02).
  - Como mudar: demanda separada de origem e retorno (EPLAST-39).

- [x] **PA-05 — Gatilho usa campos que já existem**
  - Pergunta: o gatilho de entrada precisa de campo novo?
  - Decisão: não, a princípio. Usar `Lead.Status`, `Opportunity.StageName`, `LeadSource` ou
    `LastActivityDate`, conforme a PEND-02. Campo novo só com justificativa no design.
  - Evidência: todos existem na org (FieldDefinition, 2026-11-15). Regra 3.
  - Como mudar: o arquiteto propõe campo novo no design, com a verificação da org.

- [x] **PA-06 — CRM não dispara nada**
  - Pergunta: o CRM precisa enviar o e-mail ou a mensagem quando o gatilho acontece?
  - Decisão: não. O CRM só mantém o dado e o público atualizados. O disparo é do Marketing
    Cloud.
  - Evidência: regra 2 da conta (reforço de 2026-11-15).
  - Como mudar: não é configurável nesta conta.

- [x] **PA-07 — Lead_AfterInsert_AplicaRegraAtribuicao fica como está**
  - Pergunta: esta demanda altera o Flow de atribuição de lead?
  - Decisão: não. Se o build precisar tocar em Lead, cria versão nova antes da implementação.
  - Evidência: Flow ativo confirmado. Convenção do squad (commit 00794d37).
  - Como mudar: o arquiteto revisa no design.

- [x] **PA-08 — Quem opera o Marketing Cloud**
  - Pergunta: quem opera a jornada do lado da Eplast?
  - Decisão: time de marketing da Eplast, declarado no desenho como passo de quem opera.
  - Evidência: regra 2 da conta. Padrão do precedente EPLAST-36.
  - Como mudar: a Eplast indica o responsável na homologação.

## 11. Pendências (bloqueiam o gate)

- [ ] **PEND-01 — Quais jornadas e para quê.** Nome e objetivo de cada jornada (ex.: boas-vindas
  de lead, reativação de cliente, pós-venda). Não há como a org ou o padrão decidir o
  conteúdo da comunicação, e errar gera mensagem errada para contato real.
- [ ] **PEND-02 — Público e gatilho de entrada e saída de cada jornada.** Quem entra, quando
  entra, quando sai. Mesma razão: é regra de negócio, e um público errado dispara
  comunicação para quem não deveria receber.

## 12. Complexidade e esforço

**Complexidade: M.** Duas entidades (Lead e Contact), exclusão de opt-out, reaproveitamento de
relatórios, e jornadas ainda não definidas. O build é só CRM (relatórios e, no máximo, campos),
sem Apex e sem Flow de envio.

**Estimativa de esforço:** 10–20 h
- Premissas que mais pesam: número de jornadas (1 a 4); campo novo ou não no gatilho (PA-05);
  reaproveitamento de relatórios existentes (CA-05) em vez de criação; homologação com quem
  opera o Marketing Cloud (time da Eplast, fora desta estimativa).
- Não inclui trabalho dentro do Marketing Cloud, que é da Eplast.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
