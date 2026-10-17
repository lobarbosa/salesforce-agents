# Análise da Demanda SOMOSAGILITY-3
Alteração de Status de Oportunidade para Aberta

## Contexto de Negócio

Uma oportunidade no Salesforce foi encerrada com sucesso ("Encerrado Win") mas, por razão a esclarecer, precisa voltar ao estado "Aberta". A demanda referencia um registro específico (Argo - Fornecimento Firewalls ET 13100124, ID: 006U400000YnxGHIAZ) e é marcada como urgente.

## Objetivo

Alterar o Status de uma Oportunidade de "Encerrado Win" para "Aberta", permitindo que o fluxo de vendas continue seu processamento.

## Regra de Negócio

- Uma Oportunidade que tenha sido encerrada com sucesso ("Encerrado Win") pode ser reaberta para o estado "Aberta".
- A transição de estado depende de validações no formulário ou automações da org.

## Critérios de Aceite

```gherkin
Cenário: Reabrir oportunidade encerrada com sucesso
  Dado uma oportunidade com Status "Encerrado Win"
  Quando o Status é alterado para "Aberta"
  Então o registro é atualizado com o novo Status "Aberta"
  E a data de modificação é registrada

Cenário: Validar transição de estado permitida
  Dado uma oportunidade com Status "Encerrado Win"
  Quando a alteração é aplicada
  Então nenhuma validação de campo deve bloquear a mudança
  E nenhum Flow automático deve reverter a mudança
```

## O Que a Demanda NÃO Diz (Premissas a Validar)

### Crítico para o design

1. **Qual é o ambiente de execução?**
   - A demanda referencia um link da org `agilitynetworks.lightning.force.com`, que não corresponde a nenhuma sandbox da esteira (dev: sbx-somos-agility-dev, qa: sbx-somos-agility-qa).
   - Precisa-se confirmar: é a org de **produção** do cliente?
   - **Implicação:** Não é possível desenhar, testar ou homologar a solução em produção (guardrail #1 — produção é read-only para agente). A solução será desenhada em sandbox; a aprovação no gate do arquiteto definirá o caminho de entrega para o registro real em produção (esse é escopo do `release`, não da análise).

2. **Como a mudança será entregue?**
   - É uma atualização única de um registro específico (data fix)?
   - É uma automação (Flow, Process Builder) que reabilita a mudança de status no formulário?
   - É uma ação de menu personalizado (custom action) visível ao usuário?
   - É um job em lote que pode reutilizar essa lógica para outros registros no futuro?
   - **Implicação:** A arquitetura muda radicalmente entre essas opções (ex.: automação vs. script único).

3. **Qual é o disparador real?**
   - Por que essa oportunidade específica precisa ser reaberta?
   - É um erro de entrada de dados (status mudou por engano)?
   - É um cenário de negócio previsto (ex.: cliente desistiu da compra e quer renegociar)?
   - É recorrente ou um incidente isolado?
   - **Implicação:** Afeta se a solução é one-off ou automação reutilizável.

4. **Existem validações ou automações que bloqueiam essa transição?**
   - Confirmado via `sf` que o Status "Encerrado Win" pode voltar para "Aberta" sem violar nenhuma validação de campo ou Process Builder?
   - Existe Lock de registro que impede edição?
   - Existe dependência de outro campo ou relacionamento?

5. **Qual é o passo seguinte após a reabertura?**
   - Assim que reabrir para "Aberta", qual campo de data ou quem deve atualizar?
   - Há fila de revisão ou aprovação?
   - Algum fluxo de e-mail ou notificação deveria disparar?

### Contexto do cliente

6. **O CLAUDE.md da conta está incompleto.** Não temos:
   - Identificação clara da pessoa solicitante (papel, permissões)
   - Convenção de nomenclatura própria do cliente
   - Informações sobre integrações existentes que possam ser impactadas
   - Horário ou janela de deploy permitida (se houver)

7. **Assessment da org ainda não foi rodado.** Não foi confirmado:
   - Que tipos de automação existem no objeto Opportunity (Flows, Process Builders, Validations)
   - Qual é a versão API e limite de mudanças simultâneas
   - Se há trigger ou apex que intercept mudanças de Status

## Estimativa de Complexidade

**Pequena (P)** — assume-se que é uma atualização de um registro ou um Flow simples sem dependências de integração; complexidade escala para **Média (M)** se a solução for um batch job com validações complexas ou se houver múltiplas condições de entrada.

## Próximos Passos Bloqueantes

Antes que o `arquiteto` possa desenhar a solução, o consultor/humano responsável precisa responder:

1. Confirmar se o link referencia a org de produção do cliente
2. Esclarecer se é uma atualização única ou uma automação reutilizável
3. Confirmar se existem validações/automações que bloqueiam a transição de status (via recon)
4. Descrever o cenário de negócio e o fluxo esperado após a reabertura

---

**Análise pronta. Preciso da sua validação antes de acionar o arquiteto.**
