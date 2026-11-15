# Análise — EPLAST-37 · Classificação de clientes em ativos, inativos e potenciais

**Cliente:** eplast · **Etapa:** analise (ba-discovery) · **Data:** 2026-11-15
**Org confirmada:** `sbx-eplast-dev` (alias `sbx-eplast-dev`; Org Id `00DHa000006vfMLMAY`), conferida com `sf org list`. O usuário de conexão não é citado aqui (guardrail 2). Pela regra 5 da Eplast, é a sandbox "QA" da Eplast; o nome não é bloqueio.
**Divergência de etapa:** o preflight traz `Etapa que vai rodar: backlog`; a etapa pedida é `analise`. Tratada como `analise`. Preflight sem bloqueios, sem outra demanda mexendo nos mesmos componentes, e demanda sem componentes no repositório.
**Registro da demanda:** `demanda.md` tem uma linha. Comentários do card (2026-11-13) lidos.

---

## 1. Resumo do pedido

Registro original: "Classificar automaticamente os clientes em ativos, inativos e potenciais." Item de proposta: identificação de clientes ativos, inativos e potenciais. Onda 4 · Marketing, não contratada no projeto atual (Ondas 1–2). Pela regra 1 da Eplast e pelo comentário do card de 2026-11-13, a demanda segue para análise, design e build.

Orientações do card (2026-11-13), válidas aqui:
1. Escopo autorizado independentemente da onda.
2. Tudo que é marketing é disparado pelo Marketing Cloud (MC). No CRM fica o que alimenta o MC: dado, segmento, público e status.
3. Conferir o que já existe na org antes de construir; o `SFAgent2` é o ponto de partida para o que envolver assistente, resumo ou recomendação.

O registro não define "ativo", "inativo" nem "potencial", não diz a fonte, a frequência de atualização nem o destino da classe. Essas lacunas foram resolvidas por decisão com evidência (seção 5), não por suposição silenciosa.

## 2. Contexto e objetivo

**Contexto de negócio:** a Eplast quer enxergar a base de clientes por situação de relacionamento para ações de marketing (reativação, nutrição) e de acompanhamento comercial. Itens correlatos no contrato: "Quais clientes estão há mais tempo sem comprar?" (eplast-ent-11, Onda 2) e a segmentação de base da EPLAST-36 (backlog).

**Objetivo:** toda conta de cliente no Sales Cloud tem uma classe de relacionamento (ativo, inativo ou potencial) que se mantém sozinha, sem ação manual, e que o time e o MC conseguem usar.

## 3. Escopo

**Dentro:**
- definição operacional das três classes e a ordem de precedência;
- reaproveitamento de campos e relatórios que a org já tem;
- o lado do CRM da preparação para o Marketing Cloud (seção 11).

**Fora:**
- envio de qualquer comunicação, jornada, público ou configuração no Marketing Cloud (regra 2 da Eplast);
- Flow, trigger ou Apex que grave a classe em `Account`;
- agente novo ou alteração no `SFAgent2` (a pergunta "quais clientes estão sem comprar" é do entregável eplast-ent-11; ver seção 10);
- reativar o fluxo `Custom_Stale_Opp` (inativo na org).

## 4. O que a org já tem (confirmado por `sf`, 2026-11-15)

Só metadata e contagens; nenhum registro foi lido.

| Item | Tipo / situação | Evidência | Leitura para esta demanda |
|---|---|---|---|
| `Account.LastPurchase__c` | Resumo da totalização (MAX de Oportunidade) | describe Tooling | Data da última compra. O filtro de Oportunidade (Fechado/Ganho) vem do recon da EPLAST-33 (histórico; a regra do roll-up não foi relida hoje). |
| `Account.Inactive__c` | Fórmula (caixa de seleção) | describe Tooling | Campo existente de inatividade. Regra registrada na EPLAST-33 (>90 dias desde `LastPurchase__c`). Fórmula não relida hoje: conferir antes do build. |
| `Account.Ranking__c` | Lista: MP, PP, P, M, G, GG, 3G | describe + descrição do campo | Gravado pelo `ScheduledFlowOpportunity` a partir de `RankingRange__mdt`, pela média de compras do ano. Mede **porte**, não situação de relacionamento. |
| `Account.Type` | Lista: Inativo, Novo, Prospect, Prospect Indústria, Reativo, Recorrente, Sazonal, Stand-by, Encerrou atividades | describe | Já tem rótulos de relacionamento. Não verificamos se algum Flow ou Apex grava o campo; não é usado como fonte (premissa P6). |
| `Account.Risk__c` | Lista: A, B, C, D, E | describe | Sem descrição no metadata. Fora desta demanda. |
| `ScheduledFlowOpportunity` (Fluxo Agendado - Oportunidade) | Ativo, agendado | FlowDefinitionView | Grava `Ranking__c`. É o fluxo que a EPLAST-47 corrige. Não alterar nesta demanda. |
| `Custom_Stale_Opp` (Create Custom Recommendations) | Inativo, agendado | FlowDefinitionView | Não reativar. Não é base desta demanda. |
| `AccountUpdateEconomicGroup` | Ativo, agendado, em Account | FlowDefinitionView | Grava em Account; fora do escopo, mas entra na ordem de execução (riscos). |
| Relatórios na pasta `MARKETING CLOUD` | 58 relatórios | COUNT com `FolderName` | Candidatos a reaproveitar. Nomes não listados nesta sessão. A EPLAST-36 cita "SEM COMPRA - 181 A 365 DIAS" (histórico, não reconfirmado). |
| Agente `SFAgent2` | Existe (`BotDefinition`) | query de metadata | Regra 3 da Eplast vale. Tópicos e ações não reconferidos nesta etapa. |
| `CampaignMember` | 0 registros | COUNT | Nenhum público por campanha existente na dev. |
| `Account` | 0 registros na dev | COUNT | Validação com dado exige massa sintética (LGPD). |

**Reaproveitamento item a item (regra 3):**

- Sinal de inatividade: **reaproveita** `Account.Inactive__c`.
- Data da última compra: **reaproveita** `Account.LastPurchase__c`.
- Potencial: **reaproveita** a ausência de `LastPurchase__c`. Nenhum campo novo.
- Relatório ou lista por classe: **reaproveita e ajusta** relatórios da pasta `MARKETING CLOUD` que já filtram por inatividade; **cria** apenas o que faltar.
- Campo único de classe: **não previsto**. Só se o cliente pedir (ver P5).
- Assistente: **não cria agente**. Se a consulta for conversacional, é tópico ou ação do `SFAgent2` (fora deste escopo).

## 5. Regra de negócio proposta

Ordem de precedência, aplicada a cada conta (decisões registradas nas premissas P1 a P10):

1. **Potencial:** `LastPurchase__c` vazio (nenhuma compra ganha).
2. **Inativo:** `LastPurchase__c` preenchido e `Inactive__c` = verdadeiro (mais de 90 dias sem compra ganha).
3. **Ativo:** `LastPurchase__c` preenchido e `Inactive__c` = falso.

A regra 1 vem antes da fórmula para não depender do valor de `Inactive__c` quando não há compra.

A classe é **derivada**: muda sozinha quando a compra muda, porque `LastPurchase__c` é roll-up. Não há gravação em `Account` (P5).

## 6. Critérios de aceite

Testados na dev com contas sintéticas criadas pelo verificador (sem registro real). Cenários em Dado/Quando/Então.

**CA-01 · Potencial sem compra**
- Dado uma conta de teste sem nenhuma Oportunidade Fechado/Ganho
- Quando o relatório de classificação é executado
- Então a conta aparece como Potencial, e não como Ativo nem Inativo.

**CA-02 · Ativo por compra recente**
- Dado uma conta de teste com Oportunidade Fechado/Ganho com data de fechamento há 30 dias
- Quando o relatório é executado
- Então a conta aparece como Ativo e `Inactive__c` = falso.

**CA-03 · Inativo por compra antiga**
- Dado uma conta de teste com última compra ganha há 120 dias
- Quando o relatório é executado
- Então a conta aparece como Inativo e `Inactive__c` = verdadeiro.

**CA-04 · Limite de 90 dias**
- Dado uma conta com última compra ganha há 90 dias e outra com 91 dias
- Quando o relatório é executado
- Então a de 90 dias aparece como Ativo e a de 91 dias como Inativo.
- Se o comportamento divergir da fórmula existente, o verificador registra a divergência; não altera a fórmula.

**CA-05 · Atualização automática**
- Dado uma conta de teste Potencial
- Quando uma Oportunidade dessa conta é fechada como Fechado/Ganho
- Então, sem ação manual, a conta passa a Ativo no relatório e `LastPurchase__c` = data de fechamento da oportunidade.

**CA-06 · Type não decide a classe**
- Dado uma conta de teste com `Type` = Prospect e Oportunidade Fechado/Ganho recente
- Quando o relatório é executado
- Então a conta aparece como Ativo, não como Potencial.

**CA-07 · Nenhuma gravação nova em Account**
- Dado o pacote de build
- Quando comparado à baseline da dev
- Então não há Apex, trigger, Flow nem campo novo em `Account`. Só relatórios e filtros. Campo fórmula só se o design aprovar (P5).

**CA-08 · Ranking intacto**
- Dado o `ScheduledFlowOpportunity` ativo
- Quando o build é feito
- Então ele permanece na versão ativa atual, sem versão nova do build.

**CA-09 · Reaproveitamento registrado**
- Dado os 58 relatórios da pasta `MARKETING CLOUD`
- Quando o design é escrito
- Então cada relatório reaproveitado ou criado aparece item a item no `03-design.md`, com o motivo, e nenhum existente foi duplicado.

**CA-10 · LGPD**
- Dado o relatório de classificação
- Quando for publicado
- Então as colunas não incluem e-mail, telefone nem CPF, e a validação usou só massa sintética na dev e totais agregados na QA.

**CA-11 · Marketing Cloud intacto**
- Dado a demanda concluída
- Quando verificada
- Então nenhuma configuração foi feita no MC, e a lista de campos do CRM que o MC lê está registrada no design.

**CA-12 · Apex, se houver (condicional)**
- Dado que a demanda não prevê Apex
- Quando algum Apex for necessário, por decisão do arquiteto
- Então cada classe tem cobertura de 85% ou mais e classe de teste `<Classe>Test`.

## 7. Premissas assumidas (validar na homologação)

Cada item traz a pergunta, a decisão, a evidência e como mudar se o cliente discordar.

- [x] **P1 · Escopo.** Pergunta: a demanda da Onda 4 (não contratada) pode seguir? Decisão: sim. Evidência: regra 1 da Eplast e comentário do card de 2026-11-13. Como mudar: não se aplica; é decisão do responsável pela conta.

- [x] **P2 · Potencial.** Pergunta: o que é cliente potencial? Decisão: conta sem nenhuma compra ganha (`LastPurchase__c` vazio). Evidência: `LastPurchase__c` é roll-up de Oportunidade Fechado/Ganho (EPLAST-33, recon, histórico); o padrão de "prospect" é quem nunca comprou; o valor `Prospect` do `Type` é rótulo manual e não é fonte (P6). Como mudar: trocar a condição de vazio por uma janela de tempo no filtro do relatório.

- [x] **P3 · Inativo e janela de 90 dias.** Pergunta: qual a janela de inatividade? Decisão: 90 dias sem compra ganha, a mesma regra que `Inactive__c` já aplica. Evidência: `Inactive__c` existe como fórmula (confirmado por `sf`); a regra de 90 dias vem do recon da EPLAST-33 (histórico, não reconfirmado hoje). Como mudar: ajustar o filtro do relatório; mudar a fórmula é alteração de campo em uso e passa pelo gate.

- [x] **P4 · Ativo.** Pergunta: o que é cliente ativo? Decisão: conta com compra ganha e que não está inativa (P3). Evidência: consequência direta de P2 e P3. Como mudar: segue P3.

- [x] **P5 · Classe derivada, sem campo novo e sem gravação em Account.** Pergunta: a classe precisa ser gravada num campo? Decisão: não; a classe é derivada por filtro de relatório ou lista sobre campos existentes. Evidência: achados 1 e 2 do assessment (automação concorrente em Account; cobertura Apex de 10%); a EPLAST-36 já rejeitou gravar classe em Account pelo mesmo motivo; `Inactive__c` já é derivado. Como mudar: se o cliente pedir um campo único (picklist ou fórmula), vira decisão de design do arquiteto; fórmula somente leitura é a alternativa mais barata.

- [x] **P6 · `Type` não é fonte.** Pergunta: o campo `Type` (Inativo, Prospect etc.) serve como classe? Decisão: não; é rótulo manual e pode divergir da regra. Evidência: picklist confirmado por describe com 9 valores; não verificamos se algum Flow ou Apex o grava. Como mudar: o relatório mostra a divergência entre `Type` e a classe derivada; o cliente decide se `Type` passa a ser fonte.

- [x] **P7 · Compra = Oportunidade ganha.** Pergunta: pedido do Protheus conta como compra? Decisão: não diretamente; segue o que `LastPurchase__c` já define. Evidência: roll-up em Oportunidade (EPLAST-33, recon). Risco: o contrato aponta qualidade dos pedidos vindos do Protheus (eplast-ent-11). Como mudar: trocar a origem do campo é demanda própria, com gate. Na homologação, validar com o Comercial uma amostra de contas (total agregado, sem nomes).

- [x] **P8 · Ranking fora da classe.** Pergunta: porte (Ranking) entra na classificação? Decisão: não; Ranking é eixo separado. Evidência: descrição do campo (média de compras do ano, faixas em `RankingRange__mdt`). Como mudar: o cliente pode pedir cruzamento em relatório; não exige mudança de componente.

- [x] **P9 · Reaproveitar antes de criar.** Pergunta: quais relatórios usar? Decisão: reaproveitar entre os 58 da pasta `MARKETING CLOUD`; criar só o que faltar. Evidência: contagem via `sf`; regra 3 da Eplast. Como mudar: não se aplica; o arquiteto registra o que foi reaproveitado.

- [x] **P10 · Dado de teste sintético.** Pergunta: como validar sem dado real? Decisão: a dev tem 0 contas, então a validação usa massa sintética criada pelo verificador; na QA (Partial Copy), só totais agregados. Evidência: contagem via `sf` (0 contas na dev); regra 2 da Eplast (LGPD) e regra da QAS. Como mudar: não se aplica.

## 8. Pendências reais

Nenhuma pendência `- [ ]`. Nenhuma pergunta caiu no caso 3 da regra 4: a decisão é reversível (filtro de relatório, sem gravação em Account) e a org e o padrão indicam caminho. As verificações da seção 9 são do recon, não perguntas de negócio.

## 9. Verificações para o recon (não bloqueiam a análise)

- Reconfirmar a fórmula de `Account.Inactive__c` e a regra de `LastPurchase__c` (filtro de Oportunidade).
- Listar os relatórios da pasta `MARKETING CLOUD` com o critério de cada um; identificar quais já separam as três classes.
- Verificar se algum Flow ou Apex grava `Account.Type` (P6).
- Confirmar `et4ae5__HasOptedOutOfMobile__c` e `HasOptedOutOfEmail` em `Contact`, e a lista de campos de Account que o conector MC usa.
- Confirmar que nenhum relatório selecionado expõe campos de contato pessoal (CA-10).

## 10. Riscos do assessment e de demandas relacionadas

- **Achado 1 (automação concorrente em Account, alta).** Em Account coexistem `AccountTrigger`, `AccountBefore` (SBQQ), os Flows `AccountTriggered` e `UpdateParentAccountUsedLimit`, além de `AccountUpdateEconomicGroup` e do `ScheduledFlowOpportunity`, que já grava `Ranking__c`. Tratamento: o desenho não grava classe em Account (P5, CA-07) e não altera nenhum fluxo (CA-08).
- **Achado 2 (cobertura Apex de 10%).** Tratamento: o desenho não prevê Apex. Se aparecer, CA-12 se aplica.
- **Achado 4 (campos sem descrição).** `LastPurchase__c`, `Inactive__c` e `Risk__c` estão sem descrição; `Ranking__c` tem descrição parcial. Tratamento: não renomear nem alterar campos em uso; sugerir ao cliente documentar os que o MC vai ler.
- **Achado 6 (nome "qa" na dev).** Resolvido pela regra 5 da Eplast; não é risco.
- **Demanda relacionada EPLAST-36 (segmentação, backlog).** Usa as mesmas fontes e já tem design que rejeita gravar classe em Account. O arquiteto deve tratar as duas juntas, para não criar duas definições de "inativo".
- **Demanda relacionada eplast-ent-11 (quem está há mais tempo sem comprar).** Usa o mesmo sinal de inatividade. Tratamento: reaproveitar `Inactive__c` e `LastPurchase__c`, sem criar critério paralelo.
- **Demanda relacionada EPLAST-47 (corrige o fluxo de ranking).** Qualquer mudança em `ScheduledFlowOpportunity` pertence a ela; esta demanda não toca.

## 11. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca segmentação e reativação, então a preparação é obrigatória (regra 2 da Eplast). Esta análise não faz nada no MC.

- **Dados que o MC lê e onde ficam no CRM:**
  - `Account.LastPurchase__c` (data da última compra ganha);
  - `Account.Inactive__c` (inatividade de 90 dias);
  - `Account.Type` (rótulo manual, não usado para classificar);
  - `Account.Ranking__c` (porte, para cruzamento);
  - `Contact.AccountId` (para chegar ao contato da conta).
- **Como o público fica identificável no CRM:** pelos relatórios da pasta `MARKETING CLOUD` com o critério de cada classe (público dinâmico), e, se o MC pedir, por campanha com membros. Hoje não há campanha nem membro na dev (0 registros); nada novo é criado nesta demanda.
- **O que o MC devolve e onde é gravado:** nada nesta demanda. Se o conector devolver dado de engajamento, o destino é definido por quem opera o MC; nenhum campo de retorno é criado aqui.
- **Consentimento e opt-out:** `Contact.HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` (conforme a EPLAST-36, a confirmar no recon). Esta demanda não altera esses campos; o público exclui quem optou por sair, responsabilidade de quem opera o MC.
- **O que fica para quem opera o MC:** criar o público ou data extension a partir dos campos acima, definir a jornada e o envio, e tratar o opt-out. Nada disso é feito pela esteira.

## 12. Complexidade e esforço

**Complexidade: P.** Sem código; reaproveita campos e relatórios existentes. O esforço está na validação com dado sintético e na checagem de amostra de compras.

**Estimativa de esforço:** 6–12 h
Premissas que mais pesam:
- ajustar ou criar de 2 a 5 relatórios, a partir dos 58 existentes;
- massa sintética de teste na dev, sem dado real;
- validação, com o Comercial, de uma amostra de contas (P7);
- checagem LGPD das colunas e homologação com key user.

Sobe para 20–30 h se o cliente pedir um campo único gravado (P5), porque aí entram design, fórmula ou Flow novos e nova rodada de teste de automação.

## 13. O que a demanda não diz

- A definição de cada classe e a janela de tempo (90 dias é a regra da org, não confirmada pelo cliente).
- Se "potencial" é quem nunca comprou ou quem tem perfil de prospect sem compra.
- Se a classe precisa estar gravada em campo, ou basta ser filtro de relatório e lista.
- Quem consome a classe (Comercial, Marketing, MC) e com que frequência.
- Se a classe deve alimentar o assistente (`SFAgent2`).
- Se pedido do Protheus conta como compra, além da oportunidade ganha.
- Qual relatório ou lista o time usa hoje para essa visão.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
