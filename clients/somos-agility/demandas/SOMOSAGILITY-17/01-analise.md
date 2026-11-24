# Análise — SOMOSAGILITY-17: Ajuste no fluxo de aprovação do JOB de investimento - Usuario Cyber

## Contexto de negócio
O usuário "Cyber" (provavelmente um usuário de integração/automação, não uma pessoa — a
ambiguidade está listada abaixo) cria registros de um tipo chamado aqui de "JOB de
investimento". Hoje, aparentemente, a sequência de aprovação desses registros quando
criados por esse usuário não segue a ordem que o negócio espera. O chamado interno
referenciado no card (Agility 20260831-014) sugere que este é um ajuste corretivo sobre um
comportamento de aprovação já existente, não a criação de um fluxo novo do zero — mas isso
não foi confirmado, é premissa (ver abaixo).

## Objetivo
Garantir que todo "JOB de investimento" criado pelo usuário Cyber siga obrigatoriamente a
sequência de aprovação:

1. Criação — Cyber
2. 1ª aprovação — Gustavo
3. 2ª aprovação — Wanderley
4. 3ª aprovação — Walmor

## Regra de negócio
- A sequência de aprovadores é fixa e ordenada: Gustavo aprova antes de Wanderley, que
  aprova antes de Walmor.
- A regra se aplica apenas a registros criados pelo usuário Cyber (não a todo "JOB de
  investimento" independente de quem criou — presumido a partir do texto da demanda, que
  fala explicitamente "Jobs criado por este usuário").
- Não foi informado o que ocorre em caso de rejeição em qualquer etapa (reinicia a
  sequência? volta para o aprovador anterior? encerra o processo?) — ver premissas.

## Critérios de aceite (Gherkin)

```gherkin
Funcionalidade: Sequência de aprovação de JOB de investimento criado pelo usuário Cyber

  Cenário: Job criado pelo usuário Cyber segue a ordem de aprovação definida
    Dado que o usuário Cyber cria um registro de JOB de investimento
    Quando o processo de aprovação é submetido
    Então o primeiro aprovador designado deve ser Gustavo
    E, após a aprovação de Gustavo, o próximo aprovador designado deve ser Wanderley
    E, após a aprovação de Wanderley, o próximo aprovador designado deve ser Walmor
    E o registro só deve ser considerado totalmente aprovado após a aprovação de Walmor

  Cenário: Aprovador fora de ordem não consegue aprovar antes da sua vez
    Dado que um JOB de investimento criado pelo usuário Cyber está aguardando aprovação de Gustavo
    Quando Wanderley ou Walmor tentar agir sobre a aprovação antes de Gustavo
    Então o sistema não deve permitir a ação (ou a etapa não deve estar visível/pendente para eles)

  Cenário: Job criado por outro usuário não é afetado
    Dado que um JOB de investimento é criado por um usuário diferente de Cyber
    Quando o processo de aprovação é submetido
    Então a sequência de aprovação vigente para esse outro usuário não deve ser alterada por esta demanda
```

> Os dois últimos cenários dependem de confirmar, no recon da org, se o mecanismo atual é
> Approval Process nativo, Flow com etapas de aprovação, ou outra automação — sem isso não
> é possível afirmar que "visibilidade" ou "bloqueio de ordem" sejam comportamento padrão
> do mecanismo existente ou algo a construir.

## O que a demanda NÃO diz (pendente de validação antes do design)

1. **Objeto/processo exato**: o que é, na org, um "JOB de investimento"? É um objeto custom,
   um registro de um objeto padrão, ou um registro de uma automação batch? Não confirmado
   via `sf` CLI — isso é trabalho da etapa de recon (próxima etapa), não desta análise, mas
   o design não pode avançar sem essa confirmação.
2. **Mecanismo de aprovação atual**: é um Approval Process padrão do Salesforce, um Flow de
   aprovação, ou outra automação? A demanda assume que já existe "o fluxo de aprovação" e
   pede para "ajustar" — não criar do zero —, mas isso não está explícito no texto.
3. **Identidade de Cyber, Gustavo, Wanderley e Walmor**: são usuários individuais, filas
   (queues), ou papéis/perfis na org? "Cyber" soa a usuário de integração (ex.: usuário de
   serviço de um sistema externo que cria os registros via API) — não confirmado.
4. **Escopo do usuário Cyber**: a regra deve valer só quando o *criador* do registro é
   Cyber, ou também quando Cyber apenas *atualiza* um registro criado por outra pessoa?
   A demanda fala só em "criado por este usuário".
5. **Comportamento em caso de rejeição**: nenhuma etapa descreve o que acontece se Gustavo,
   Wanderley ou Walmor rejeitar. Reinicia o processo, volta ao criador, ou encerra?
6. **Convivência com a regra atual**: existe hoje alguma sequência de aprovação diferente
   para Jobs criados por outros usuários, e esta demanda não deve alterá-la (presumido no
   terceiro cenário de Gherkin) — precisa confirmação de que não é intenção unificar tudo
   numa regra só.
7. **Urgência/criticidade**: o chamado interno (Agility 20260831-014) sugere que isto pode
   ser decorrência de um incidente (ex.: aprovação saiu de ordem em produção), o que mudaria
   a prioridade e possivelmente a classificação de "bug crítico" (gate do arquiteto reduzido,
   mas existente, por tipo "sustentacao" conforme CLAUDE.md) — não confirmado nos
   comentários do card, que só trazem o número do chamado sem detalhe adicional.
8. **Ambiente de origem do problema**: não foi dito se o comportamento incorreto foi
   observado em produção, QA ou é um requisito novo ainda não implementado em nenhum
   ambiente.

## Premissas a validar
- Cyber, Gustavo, Wanderley e Walmor existem como usuários ativos (ou filas) identificáveis
  na org — a confirmar via `sf` CLI na etapa de recon, não assumido aqui.
- "JOB de investimento" corresponde a um objeto/registro já existente na org, não a criar
  nesta demanda — a confirmar na etapa de recon.
- O mecanismo de aprovação já existe e esta demanda é um ajuste de sequência/condição nele,
  não a criação de um approval process novo — presumido pelo verbo "ajustar" no título, a
  confirmar no recon/design.

## Complexidade
**P (pequena)** — presumindo que o mecanismo de aprovação já existe na org e que a mudança
se resume a ajustar a ordem/condição dos aprovadores para um critério de criador específico
(configuração declarativa típica de Approval Process ou Flow). Pode subir para **M** se o
recon revelar que não há approval process hoje e será necessário criar um do zero, ou que
"JOB de investimento" envolve um objeto com automações adicionais que a mudança de ordem
pode impactar.

**Estimativa de esforço:** 2–6 h
Premissas que mais pesam na faixa: (1) o approval process/Flow já existe e só a sequência de
aprovadores muda; (2) Cyber, Gustavo, Wanderley e Walmor já são usuários/filas existentes na
org, sem necessidade de provisionamento; (3) não há regra de rejeição custom a replicar. Se
qualquer uma dessas premissas cair, a faixa sobe.

---
Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
