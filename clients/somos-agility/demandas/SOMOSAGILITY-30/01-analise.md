# 01 — Análise: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da Solicitação de Reembolso

**Cliente:** somos-agility · **Etapa:** analise (ba-discovery) · **Tipo:** sustentação (revisão de regra), design enxuto
**Origem:** card SOMOSAGILITY-10 (Erro no campo total de despesas realizadas, PRJ). Este card não altera o SOMOSAGILITY-10.
**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`), única org conectada, confirmada com `sf org list`. Só leitura: describe filtrado, consulta de Flow com campos específicos, retrieve de um Flow para diretório temporário (apagado depois). Nenhum registro lido, nenhuma alteração.
**Status:** pendente de validação humana. Não há aprovação registrada aqui.

---

## 1. Contexto de negócio

O campo **Total de despesas realizadas** do projeto (`PPM_Project__c.Total_de_despesas_realizadas__c`) hoje é calculado pelo Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`. Ele soma os Lançamentos de Despesa vinculados ao projeto cuja Solicitação de Reembolso (SR) está em uma destas situações: `Pendente - Gestor`, `Pendente - Diretor`, `Pendente - Operações` ou `Aprovado`.

Ou seja, o total já é alimentado antes da aprovação final. O consultor reporta isso como erro: o projeto passa a mostrar despesa que ainda não foi aprovada. A regra pedida é que o total só receba valor quando a SR chegar à aprovação final.

Histórico: o design do SOMOSAGILITY-10 (fluxo, BO da SR e do Lançamento, e a cascata para o projeto) está registrado na base de delivery, não no disco desta workspace. Fontes consultadas via RAG: `[demandas/SOMOSAGILITY-10/02-recon.md]` (flow e classes envolvidas: `SolicitacaoReembolsoBO`, `LancamentoDespesasBO`, `PPMProjectBO`), `[demandas/SOMOSAGILITY-10/03-design.md]` (cascata: a BO da SR grava os Lançamentos do projeto, que dispara o Flow de soma, que grava o projeto) e `[demandas/SOMOSAGILITY-10/04-plano-build.md]` (cenário de recursão na transição de etapa). Os três confirmam o mesmo ponto de disparo descrito acima.

## 2. Objetivo

Garantir que `Total_de_despesas_realizadas__c` do projeto reflita apenas Lançamentos de Despesa vinculados a projeto cuja SR está aprovada na etapa final. Rejeição e recolhimento retiram a despesa do total. O card também pede que os cenários de teste sejam refeitos, pois hoje partem da aprovação do gerente de projeto.

## 3. Regra de negócio (como entendida a partir da demanda)

1. Um Lançamento de Despesa entra no total do projeto somente se (a) estiver vinculado a um projeto e (b) sua SR estiver na situação final "Aprovado".
2. O valor de cada Lançamento que entra é somado ao total do projeto.
3. Enquanto a SR estiver em qualquer etapa pendente (incluindo gerente de projeto, gestor, diretor e operações), o Lançamento não entra no total.
4. Se a SR for rejeitada ou recolhida, os Lançamentos dela saem do total.
5. Um projeto sem nenhuma despesa em SR aprovada fica com total 0 (a confirmar com o cliente, ver seção 5).

Divergências entre a demanda e o Flow atual, que precisam de decisão:
- O Flow atual também soma em `Pendente - Operações`. A demanda não menciona essa etapa.
- O Flow atual, para os tipos de despesa de quilometragem (`Kilometragem (Analistas)`, `Kilometragem (Gestores)`, `Kilometragem (GC's)`), soma `Valor_da_Kilometragem__c` no lugar de `Valor_da_Despesa__c`. A demanda diz "o valor de todos os Lançamentos".

## 4. Critérios de aceite (Gherkin)

Os exemplos usam os valores das situações como estão no campo `Status de Aprovação e Etapas` da SR (é o campo que alimenta o Flow atual via `Status_da_SR__c`). A escolha do campo está em aberto (P1); os cenários valem para qualquer um dos dois, desde que a situação "Aprovado" seja a final.

**CA-01 — Soma só na aprovação final**
```gherkin
Dado um projeto P com total de despesas realizadas 0
E uma SR com etapa "Pendente - Gestor" e dois Lançamentos de Despesa vinculados a P, valores 100 e 50
Quando a SR passa para "Pendente - Diretor"
Então o total de P continua 0
```

**CA-02 — Soma ao chegar em Aprovado**
```gherkin
Dado o mesmo projeto P e a mesma SR com dois Lançamentos de valores 100 e 50
Quando a SR passa para "Aprovado"
Então o total de P é 150
```

**CA-03 — Não soma em etapas pendentes (inclusive Operações)**
```gherkin
Dado uma SR vinculada a P com dois Lançamentos de valores 100 e 50
Quando a SR passa para cada uma das etapas "Pendente - Gerente de Projetos", "Pendente - Gestor", "Pendente - Diretor" e "Pendente - Operações"
Então o total de P permanece 0 em todas elas
```
Observação: este critério muda o comportamento atual para "Pendente - Gestor", "Pendente - Diretor" e "Pendente - Operações". Depende de P2.

**CA-04 — Rejeição tira a despesa do total**
```gherkin
Dado uma SR vinculada a P com Lançamentos de valores 100 e 50, e o total de P com valor 0
Quando a SR é rejeitada
Então o total de P continua 0
```

**CA-05 — Recolhimento tira a despesa do total**
```gherkin
Dado uma SR aprovada, vinculada a P, com Lançamentos de valores 100 e 50, e o total de P igual a 150
Quando a SR é recolhida (situação "Recall")
Então o total de P é 0
```
Depende de P5 (o que acontece no total quando uma aprovada volta atrás).

**CA-06 — Aprovado volta atrás (comportamento a confirmar)**
```gherkin
Dado uma SR aprovada, vinculada a P, com total de P igual a 150
Quando a SR volta para uma situação não aprovada
Então o total de P passa a refletir apenas as SRs que continuam aprovadas
```
Depende de P5. Este critério só fica testável depois da resposta sobre quais transições são possíveis a partir de "Aprovado".

**CA-07 — Projeto sem despesa aprovada fica com 0**
```gherkin
Dado um projeto P que só tem Lançamentos em SRs pendentes, rejeitadas ou recolhidas
Quando o Flow é recalculado
Então o total de P é 0
```
Depende de confirmação com o cliente (P7).

**CA-08 — Lançamento sem projeto não altera nenhum projeto**
```gherkin
Dado uma SR aprovada com um Lançamento sem projeto vinculado, valor 80
Quando a SR passa para "Aprovado"
Então nenhum registro de projeto tem o total alterado por esse Lançamento
```

**CA-09 — Várias SRs no mesmo projeto**
```gherkin
Dado um projeto P com SR1 aprovada (Lançamento 100) e SR2 pendente de diretor (Lançamento 40)
Quando o Flow é recalculado
Então o total de P é 100
```

**CA-10 — Tipo de quilometragem (depende de P4)**
```gherkin
Dado uma SR aprovada, vinculada a P, com um Lançamento do tipo "Kilometragem (Analistas)" com Valor_da_Kilometragem__c 30 e Valor_da_Despesa__c 0
Quando o Flow é recalculado
Então o total de P é 30
```
Se a resposta a P4 for diferente, este critério muda.

Os critérios CA-01 a CA-05, CA-08 e CA-09 são testáveis hoje, com dados de teste na sandbox de QA, sem depender de respostas pendentes (exceto a inclusão de Operações em CA-03). CA-06, CA-07 e CA-10 ficam testáveis depois das respostas.

## 5. O que a demanda NÃO diz (precisa de resposta antes do design)

- **P1 — Campo da situação.** A SR tem dois campos de situação. `Status__c` tem `Rascunho | Pendente | Aprovado | Rejeitado | Recall`. `Status de Aprovação e Etapas` tem `Rascunho | Pendente - Gerente de Projetos | Pendente - Gestor | Pendente - Diretor | Pendente - Operações | Aprovado | Rejeitado | Recall`. O Flow atual usa o segundo (via `Status_da_SR__c`). Qual é o campo que define "aprovação final"?
- **P2 — Pendente - Operações.** É uma etapa antes da final, ou a aprovação final passa por ela? A demanda não cita essa etapa, mas o Flow atual soma nela.
- **P3 — Pendente - Gerente de Projetos.** Confirmar que nenhuma etapa pendente soma (o Flow atual já não soma nela; só confirmar).
- **P4 — Quilometragem.** Para os três tipos de quilometragem, mantém-se `Valor_da_Kilometragem__c` como valor do Lançamento, ou "valor" é `Valor_da_Despesa__c` em todos os tipos?
- **P5 — Aprovado volta atrás.** Quais transições são possíveis a partir de "Aprovado" (Recall, Rejeitado, outra)? O total deve sair imediatamente na transição, ou só quando a SR for recolhida? A demanda pede para "confirmar o comportamento", então é decisão, não suposição.
- **P6 — Escopo do SOMOSAGILITY-10.** O card diz que o 10 "deve ser revisado antes de seguir", mas também diz que este card não o altera. Quem revisa o design do 10 (este card ou o próprio 10)? O 10 segue parado no gate de design até lá?
- **P7 — Projeto sem despesa aprovada.** A demanda manda confirmar com o cliente que o total fica 0. Essa confirmação ainda não foi feita.
- **P8 — Dados existentes (backfill).** Projetos que já têm total somado com SRs em "Pendente - Gestor", "Pendente - Diretor" ou "Pendente - Operações" ficam com valor errado depois da correção. Precisa recalcular o histórico? Se sim, como (recálculo pela esteira, ou correção manual com aprovação)? Não sei se a regra atual já está em produção; isso muda o plano de implantação.
- **P9 — Quem é o usuário que vê o campo.** O campo aparece em tela para algum perfil específico? Afeta a massa de teste da QA (perfis reais da org são muitos; ver assessment, seção 5 abaixo).

## 6. Premissas a validar (pendentes, não aceitas)

- **PV-1.** O campo de situação da regra é `Status de Aprovação e Etapas` (hipótese, ver P1). Não aceita até o consultor responder.
- **PV-2.** "Aprovado" é a única situação que conta (hipótese a partir da demanda; ver P2).
- **PV-3.** Rejeição e recolhimento já tiram a despesa do total pelo critério atual do Flow (ele só soma as quatro situações; rejeitado e recall ficam de fora). Confirmado por leitura do Flow, mas ainda depende de P5 para o caso "volta atrás".
- **PV-4.** Os Lançamentos da SR são regravados quando a SR muda de etapa (a BO da SR grava os Lançamentos vinculados ao projeto). Hipótese vinda do RAG do SOMOSAGILITY-10; não confirmada no código nesta sessão.

## 7. Metadata confirmada na org de dev (`sbx-somos-agility-dev`)

- **Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`:** existe, `Active`, `AutoLaunchedFlow`, `RecordAfterSave` `CreateAndUpdate` em `Lancamento_de_Despesas__c`. Versão ativa = última versão (`301Ha000014xO5rIAE`). Entrada: só Lançamentos com `Relacionado_ao_Projeto__c` não nulo. Lógica: busca todos os Lançamentos do projeto com `Status_da_SR__c` em {`Pendente - Gestor`, `Pendente - Diretor`, `Pendente - Operações`, `Aprovado`}, soma (`Valor_da_Despesa__c`, ou `Valor_da_Kilometragem__c` para os três tipos de quilometragem) e grava `Total_de_despesas_realizadas__c` no projeto. O recálculo é completo a cada gatilho, não incremental.
- **`Solicitacao_de_Reembolso__c`** (label "Solicitação de Reembolso"): existe. `Status__c` e `Status_de_Aprovacao_e_Etapas__c` confirmados com os valores listados na seção 5.
- **`Lancamento_de_Despesas__c`** (label "Lançamento de Despesas"): existe. `Relacionado_ao_Projeto__c` (referência) confirmado. `Status_da_SR__c` confirmado como fórmula `TEXT(Solicitacao_de_Reembolso__r.Status_de_Aprovacao_e_Etapas__c)`.
- **`PPM_Project__c`**: existe. `Total_de_despesas_realizadas__c` confirmado (tipo moeda).
- **Outras automações nos três objetos** (FlowDefinitionView, ativas, nenhum Process Builder encontrado nos três):
  - `Projeto Agility` (PPM_Project__c): 17 `RecordAfterSave` e 2 `Scheduled`. Notificações de projeto, datas, status de auditoria, freezing e suspensão.
  - `Solicitação de Reembolso`: 1 `RecordAfterSave` (`Atualiza_o_status_de_aprovacao_e_etapas_da_SR`) e 2 `RecordBeforeSave` (`Status_Etapa_Aprova_o_Gestor`, `Email_Gestor_4`).
  - `Lançamento de Despesas`: 3 `RecordAfterSave` (o Flow desta demanda, `atualizaAprovadorReembolso`, `sincroniza_campos`).
- **Não confirmado nesta sessão:** a existência de `Valor_da_Despesa__c` e `Valor_da_Kilometragem__c` por describe (aparecem no XML do Flow; não rodei describe nesses campos). Também não conferi quais automações, além do Flow desta demanda, leem ou gravam `Total_de_despesas_realizadas__c`. O conteúdo das classes (`SolicitacaoReembolsoBO` e outras) não foi lido.

## 8. Riscos do assessment que tocam esta demanda

O `assessment.md` é uma foto antiga (confirmei só o que está listado acima com `sf`).

- **Cobertura Apex de 40% (org-wide), achado 3.** O Flow desta demanda não tem cobertura Apex. A regra de soma vive em Flow, e a regressão só aparece em teste manual ou em teste de classe que atravesse o fluxo. O assessment também aponta que handlers sem teste dedicado são onde regressão silenciosa acontece. Consequência para o design: o teste de regressão do CA-01 a CA-09 precisa ser feito na QA e, se houver Apex na BO (`SolicitacaoReembolsoBO`), o teste dedicado entra no escopo. Meta do squad: 85% por classe.
- **Process Builder ativo, achado 2.** A org tem 59 Process Builders ativos na visão geral. Nos três objetos desta demanda não encontrei nenhum. Nenhum risco direto, mas o inventário de automação no Projeto Agility deve ser refeito no design (ver seção 7).
- **Concentração de automações (achado 1).** O achado de 31 automações em Oportunidade e 24 no mesmo evento não se aplica aos objetos desta demanda. Os objetos desta demanda têm 17 after-save em Projeto Agility, 3 em SR e 3 em Lançamento. Se o design precisar mexer em outra automação que escreve `Total_de_despesas_realizadas__c`, a ordem de execução entre elas precisa ser verificada (seção 7).
- **Perfil por pessoa, achado 6.** Não muda a regra. Afeta o planejamento de QA: a massa de teste precisa de usuários que representem o perfil que vê o campo (P9).

## 9. Complexidade

**P.** Mudança de critério de um Flow existente (remover as três situações pendentes do filtro, e tratar as transições pós-aprovação) mais o refazer dos cenários de teste. A parte de incerteza (P1 a P5) pode subir para M se a decisão sobre "volta atrás" exigir mudança em BO.

## 10. Esforço humano

**Estimativa de esforço:** 5–10 h
Premissas que mais pesam na faixa:
- respostas a P1, P2 e P5 em até um ciclo de consultor. Sem elas, o limite superior sobe (é a principal fonte de faixa larga);
- o Flow atual sendo alterado por nova versão (não edição no lugar), com revisão do PR e teste de regressão em QA cobrindo os cenários CA-01 a CA-09 (2–4 h);
- decisão sobre backfill (P8): se houver recálculo de projetos existentes, o limite superior sobe;
- homologação com o cliente (P7 e aceite dos cenários) em 1–2 h;
- não inclui o redesenho do SOMOSAGILITY-10 (P6), que é outra demanda.

---

## 11. Perguntas para o consultor (resumo)

1. P1: o campo que define a aprovação final é `Status de Aprovação e Etapas` ou `Status__c`?
2. P2: `Pendente - Operações` é uma etapa antes da aprovação final?
3. P4: para quilometragem, o valor que entra é `Valor_da_Kilometragem__c` ou `Valor_da_Despesa__c`?
4. P5: o que acontece com o total quando uma SR aprovada volta atrás? Quais transições são possíveis a partir de "Aprovado"?
5. P6: quem revisa o design do SOMOSAGILITY-10 e quando?
6. P7: o cliente confirmou que projeto sem despesa aprovada fica com 0?
7. P8: há projetos já com total errado que precisam ser recalculados? Essa regra já está em produção?

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
