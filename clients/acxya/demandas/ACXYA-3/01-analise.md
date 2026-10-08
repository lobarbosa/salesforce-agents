# Análise de demanda — ACXYA-3

## Contexto de negócio

O ciclo de venda em Salesforce é documentado através de Oportunidades. Clientes se comunicam com vendedores via email durante a negociação. Atualmente, não há mecanismo que force ou registre o reconhecimento formal do vendedor quando um email do cliente chega relacionado a uma Oportunidade, criando lacuna de rastreabilidade e potencial risco de comprometimento de prazos ou SLAs.

## Objetivo

Implementar uma interface visual dentro de um registro de Oportunidade que permita ao vendedor confirmar formalmente o recebimento de emails de clientes, deixando um rastro auditável de quando cada email foi reconhecido.

## Regra de negócio

**PENDENTE — não respondida na demanda.** A lógica de negócio que governa este fluxo depende de esclarecimentos críticos (listados abaixo em "Premissas a validar"). Sem respostas, não há como estabelecer a regra de forma operacional.

## O que a demanda NÃO diz (perguntas bloqueantes)

1. **Qual é a fonte dos emails?**
   - Sistema integrado (ex.: integração com Gmail/Outlook) que empurra notificações pra Salesforce?
   - Emails recebidos em mailbox de vendedor fora do Salesforce (manual, consultor reconhece visualmente)?
   - Email-to-Case ou email-to-Opp existente que gera records automáticos?
   - Integração com algum sistema de suporte/ticketing?

2. **O que significa "dar ok" operacionalmente?**
   - Um campo de checkbox (Lido/Não lido)?
   - Um botão que muda um status do email/da Oportunidade?
   - Uma assinatura digital ou confirmação com data/hora?
   - Um voto numa aprovação formal (sim/não, com motivo)?
   - Um campo de texto (notas do vendedor)?

3. **Em qual objeto exactamente a tela aparece?**
   - Uma nova aba na Oportunidade?
   - Um componente LWC embedado numa aba existente (por ex., Detalhes)?
   - Um related list de emails/comunicações?
   - Um modal/popup disparado quando o email chega?
   - Um componente inline no campo de histórico?

4. **Como o sistema sabe que um novo email chegou?**
   - Notificação push/Chatter quando entra?
   - Polling (agente de background verificando periodicamente)?
   - Fluxo automatizado (Flow ou automação Salesforce)?
   - Manual — o vendedor acessa a tela e vê a lista?

5. **Qual é a granularidade?**
   - Uma confirmação por email individual?
   - Uma confirmação por "lote de emails" (ex.: "confirmei todos de hoje")?
   - Uma confirmação por Oportunidade (não por email)?

6. **Quem pode confirmar?**
   - Apenas o proprietário da Oportunidade?
   - Qualquer membro do time de vendas?
   - Um gestor aprovando em nome do vendedor?
   - Múltiplos usuários com voto?

7. **O que acontece após "dar ok"?**
   - Apenas registro auditável (sem ação posterior)?
   - Dispara um fluxo (ex.: notificação ao cliente)?
   - Altera o status da Oportunidade?
   - Inicia uma tarefa ou cria um registro?

8. **Qual é a historicidade esperada?**
   - Manter histórico de todas as confirmações e não-confirmações?
   - Apenas o estado atual (último "ok")?
   - Tempo-limite para confirmar (ex.: "deve confirmar em 24h")?

## Critérios de aceite

**NÃO SÃO TESTÁVEIS até que as 8 perguntas acima sejam respondidas.** Abaixo está o template que será preenchido após validação:

### Assumindo: confirmação é um campo de checkbox por email individual

```gherkin
Funcionalidade: Vendedor confirma recebimento de email na Oportunidade
  Cenário: Visualizar lista de emails pendentes de confirmação
    Dado que um email de cliente chegou relacionado a uma Oportunidade
    Quando o vendedor abre a Oportunidade e navega até a tela de confirmação de emails
    Então vê uma lista com os emails não confirmados, ordenados por data recente
    E cada linha mostra: remetente, assunto, data e um checkbox "Lido"
  
  Cenário: Marcar email como confirmado
    Dado que o vendedor vê um email não confirmado na lista
    Quando clica no checkbox "Lido" do email
    Então o sistema registra a data/hora da confirmação
    E o email deixa de aparecer na lista de pendentes
    E uma entrada de auditoria é criada (Usuário X confirmou email Y em Z)

  Cenário: Visualizar histórico de confirmações
    Dado que emails foram confirmados anteriormente
    Quando o vendedor acessa a aba de histórico
    Então vê a data, hora e usuário de cada confirmação
    E consegue "reabrir" um email se necessário
```

### Validação em design (gate do arquiteto)

Antes de prosseguir, o arquiteto precisará confirmar:
- **Declarativo ou código?** (LWC vs. related list + Flow vs. Apex?)
- **Performance:** quantos emails por Oportunidade são esperados? Há limite?
- **Integração existente:** já há dados de email em Salesforce ou será preciso criar?

## Premissas a validar (bloqueantes)

- [ ] **Confirmar origem dos emails** — qual sistema/integração envia os dados de email pra Salesforce?
- [ ] **Definir semântica de "dar ok"** — é um campo, um status, uma assinatura, ou algo mais?
- [ ] **Especificar posição da tela** — aba nova? Related list? Componente inline?
- [ ] **Mecanismo de disparo** — notificação quando chega ou vendedor acessa manualmente?
- [ ] **Granularidade de confirmação** — por email, por Opp ou por lote?
- [ ] **Permissões** — quem pode confirmar? Apenas proprietário ou time todo?
- [ ] **Ação pós-confirmação** — é apenas auditoria ou dispara fluxo/automação?
- [ ] **Retenção de histórico** — manter todos os registros ou apenas estado atual?
- [ ] **Estrutura de dados** — qual objeto armazena os emails? (EmailMessage? Custom object? Related list automática?)

## Estimativa de complexidade

**Médio (M)**

Justificativa: interface visual é simples (um formulário, uma tabela), mas o comportamento exato depende de 9 decisões arquiteturais diferentes. Uma vez respondidas, a implementação é direta (LWC + Flow ou Apex com testes); porém, a ambiguidade atual impede estimar o esforço fino.

---

**Análise pronta. Preciso da sua validação antes de acionar o arquiteto.**
