# SOMOSAGILITY-19 — Análise (BA)

**Título:** Salesforce - carga em massa de dados para Históricos de Vendas e Renovações
**Tipo:** sustentação (etapas 1, 2, 3 enxuto, 4, 5, 7)
**Cliente:** somos-agility
**Org conectada na sessão (confirmada via `sf org list`):** alias `sbx-somos-agility-dev` (sandbox). Nenhuma escrita foi feita nela nesta etapa; só leitura de metadata.

**Status da análise:** BLOQUEADA para desenho. Faltam a planilha e o alinhamento com a demandante (ver seções 6 e 7).

---

## 1. Contexto de negócio

O cliente quer carregar em massa dados de **Históricos de Vendas e Renovações** no Salesforce. A demanda foi aberta pelo departamento de **Renovações** (chamado interno Agility 20260922-039, demandante Vanessa Ranieri, conforme comentário do card de 2026-10-19). O texto diz "carga de dados em massa para atualização de dados", então o objetivo pode ser criar registros, atualizar registros existentes, ou ambos. Não há como saber pela demanda.

A demanda cita uma planilha em anexo. Nenhum anexo foi liberado para esta sessão: não existe `demandas/SOMOSAGILITY-19/anexos/` neste workspace. O conteúdo da planilha não foi visto e nada abaixo assume o que ela contém.

O briefing do cliente (`clients/somos-agility/CLAUDE.md`) está em branco nos campos de contato, clouds, convenção de nomenclatura e saúde da org. Não há assessment em `clients/somos-agility/` ainda. Por isso nenhuma convenção de campo custom foi aplicada aqui.

## 2. Objetivo

Colocar na org os dados históricos de vendas e renovações que hoje estão na planilha, de forma que o departamento de Renovações passe a enxergá-los no Salesforce, sem duplicar registros e com rastro do que foi carregado.

Objetivo mensurável ainda **não definido** (depende da planilha e da Vanessa, ver seção 6).

## 3. Regra de negócio

**Nenhuma regra de negócio explícita na demanda.** Em particular, não está definido:

- o que conta como "Histórico de Venda" e como "Histórico de Renovação" (são o mesmo objeto com dois tipos de registro, ou dois objetos?);
- qual é a chave de correspondência entre a linha da planilha e o registro da org (Id externo, número de contrato, número de pedido, outra?);
- o que fazer com linha que não casa com nenhum registro existente (criar, rejeitar, reportar);
- o que fazer com linha que casa com mais de um registro;
- se há campos que nunca podem ser sobrescritos na atualização.

Candidatos encontrados na sandbox dev, **sem confirmação de que sejam o alvo**. A busca foi por nome em `sf sobject list --sobject custom` (somente metadata):

- `Hist_rico_de_Venda_e_Renova_o__c` (nome sugere o alvo de "Históricos de Vendas e Renovações")
- `Realizacao_Financeira_de_Renovacoes__c` e `Realizacao_Financeira_de_Venda__c`
- `Aviso_de_Renovacao__c`
- `Potencial_e_Objetivo_de_Vendas__c`, `Parcelas_de_Venda__c`

Nenhum campo desses objetos foi descrito nesta etapa. Quem confirma qual é o objeto e quais campos recebem a carga é a etapa 2 (recon) com `sf sobject describe`, depois do alinhamento com a demandante. Não assumo nenhum deles como correto.

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo ficam em forma testável, mas com parâmetros marcados como **[a definir]**. Não devem ser tratados como fechados até as premissas da seção 5 serem respondidas.

```gherkin
Funcionalidade: Carga em massa de Históricos de Vendas e Renovações (SOMOSAGILITY-19)

  Contexto:
    Dado que a planilha foi liberada para a sessão e validada pela demandante
    E que a chave de correspondência está definida como [a definir]
    E que o objeto alvo está confirmado via sf sobject describe como [a definir]

  Cenário: Carga em sandbox de dev conclui com reconciliação
    Dado a planilha com [N] linhas válidas e [M] linhas inválidas identificadas antes da carga
    Quando a carga é executada em "sbx-somos-agility-dev"
    Então o total de registros criados mais atualizados é igual a [N]
    E cada linha inválida aparece no relatório de erros com o motivo
    E nenhuma linha inválida gera registro na org

  Cenário: Atualização não duplica registros
    Dado que existem registros na org com a chave [a definir] presente na planilha
    Quando a carga é executada
    Então a contagem total de registros do objeto aumenta somente pelo número de linhas sem correspondência
    E para cada chave existente, existe exatamente um registro após a carga

  Cenário: Amostra confere campo a campo
    Dado uma amostra de [X] registros escolhida pela demandante
    Quando comparo cada campo mapeado com a planilha de origem
    Então os valores são iguais, exceto os campos listados como transformados no mapeamento aprovado

  Cenário: Rollback possível
    Dado que existe exportação do estado anterior dos registros que serão atualizados
    Quando a restauração é executada na sandbox de dev
    Então os valores voltam ao estado anterior à carga para todos os registros afetados

  Cenário: Dados pessoais não vão para o contexto de agente
    Dado que a planilha pode conter dado pessoal de cliente
    Quando a sessão de agente trata a planilha
    Então apenas metadata, contagens e nomes de colunas são registrados nos artefatos
    E nenhum valor de linha aparece em artefato versionado, PR ou comentário do card

  Cenário: Produção fica fora da esteira do agente
    Dado que a demanda termina na etapa qa
    Quando o pipeline de agentes encerra
    Então nenhuma carga é executada em produção pelo agente
    E a execução em produção, se existir, tem decisão humana registrada fora da esteira (ver premissa P9)
```

Observação sobre o último cenário: é um limite do squad (guardrail 1), não uma escolha do cliente. Se o cliente quiser que a carga vá a produção, isso precisa de decisão e rito próprios, fora do que o agente faz.

## 5. Premissas a validar

Todas pendentes. Nenhuma foi tomada como verdade.

| # | Premissa / pergunta | Por que pesa | Status |
|---|---|---|---|
| P1 | **Planilha**: qual é, quantas linhas, quais colunas, de onde veio (sistema de origem ou exportação manual)? | Sem ela não há mapeamento, volume nem como validar. Pendência crítica. | PENDENTE |
| P2 | **Objeto(s) alvo**: é `Hist_rico_de_Venda_e_Renova_o__c` ou outro? Vendas e renovações são um objeto com tipo, ou dois objetos? | Muda o número de cargas, o mapeamento e a regra de duplicidade. | PENDENTE — candidatos da seção 3 não confirmados |
| P3 | **Operação**: criação, atualização ou upsert? | O texto diz "atualização", o título diz "carga". Operação errada corrompe dado existente. | PENDENTE |
| P4 | **Chave de correspondência** (chave externa existente, número de contrato, outro) e se ela é única na org | Sem chave única, o upsert pode sobrescrever o registro errado. | PENDENTE |
| P5 | **Volume** em número de registros e a frequência (carga única ou recorrente) | Define a ferramenta (Data Loader, Bulk API, script) e o tempo de execução. | PENDENTE |
| P6 | **Ferramenta de carga** preferida pelo cliente/consultoria (Data Loader, Workbench, Bulk API via `sf data import bulk`) | Muda o esforço e o que o agente consegue operar. | PENDENTE |
| P7 | **Dados pessoais** na planilha (nome, CPF, e-mail, telefone, valores de contrato de pessoas físicas)? | Guardrail 2 e LGPD. Se houver, a planilha não entra no contexto e a liberação de anexo exige declaração expressa. | PENDENTE |
| P8 | **Quem valida o resultado** (nome, papel) e critério de aceite de negócio (ex.: contagem por carteira bate com o relatório de origem?) | Sem dono do aceite, a etapa 5 não tem como fechar. | PENDENTE — provavelmente Vanessa, a confirmar |
| P9 | **Produção**: a carga vai a produção? Se sim, quem executa, em que janela, com que aprovação? Fora da esteira do agente | Guardrail 1. Não é decisão do agente. | PENDENTE |
| P10 | **Backup/rollback**: o cliente aceita export pré-carga e restauração como mecanismo de desfazer? Há janela para isso? | Carga de atualização em massa sem rollback é risco alto. | PENDENTE |
| P11 | **Regras de validação e triggers/flows** existentes nesses objetos que podem bloquear ou disparar efeito colateral na carga (e-mails, cálculos, integrações) | Carga em massa pode disparar automações e integrações de Renovações. | PENDENTE — não verificado na org |
| P12 | **Integrações**: o campo "Integrações existentes" do briefing do cliente está vazio. Algum sistema lê ou escreve esses objetos? | Mesma razão de P11, do lado externo. | PENDENTE |
| P13 | **Convenção de nomenclatura** do cliente (prefixo de campo custom) | O briefing está vazio. Se a carga criar campo novo, não há convenção para seguir. | PENDENTE — assumindo que não há campo novo a criar |

## 6. Pendência bloqueante: alinhamento com a demandante

No comentário do card de 2026-10-19 17:25, o cliente pede que a consultoria chame a **Vanessa Ranieri (Renovações)** para pegar os detalhes e o entendimento antes de executar a demanda.

Isto **bloqueia o avanço para o design** (etapa 3). Motivo: sem a Vanessa, não há como responder P1 a P6, P8 e P9. O que o agente entregaria seria desenho de uma carga sobre objeto e chave que ninguém confirmou.

Ação necessária: a consultoria registra no card (ou na análise, em rodada seguinte) o resultado da conversa, com: planilha (ou o que ela contém, sem dado pessoal), objeto alvo, operação, chave, volume, quem valida e se haverá produção.

## 7. Itens que a demanda NÃO diz e que precisam de resposta antes do design

1. O conteúdo e a origem da planilha (P1). Não foi visto nada.
2. O objeto alvo e os campos (P2). Só há candidatos por nome.
3. Se é criação, atualização ou upsert (P3).
4. A chave de correspondência e a regra para linha sem match ou com match duplo (P4).
5. Volume e frequência (P5).
6. Quem valida e com qual critério (P8).
7. Se há produção no escopo e como ela é autorizada (P9).
8. Se há dado pessoal na planilha (P7).
9. Se há rollback exigido (P10).
10. Efeitos colaterais: regras, flows, triggers e integrações nesses objetos (P11, P12).
11. Motivação de negócio concreta: o que o departamento consegue fazer depois da carga que não consegue hoje.

## 8. Complexidade

**M**: a carga em si é simples, mas o risco está na chave de match, no volume ainda desconhecido e nos possíveis efeitos colaterais de automações ao atualizar registros em massa, sem nada disso verificado ainda na org.

## 9. Estimativa de esforço

**Estimativa de esforço:** 10–28 h

Premissas que mais pesam na faixa:
- Planilha limpa e com chave única (faixa inferior) versus planilha com problemas de qualidade, chave ambígua ou necessidade de tratamento antes da carga (faixa superior).
- Volume baixo, carga única, sem produção no escopo (inferior) versus volume alto, carga recorrente ou com produção (superior).
- Número de rodadas de homologação com a Vanessa. Uma rodada assume inferior; duas ou mais tendem ao superior.
- Ausência de automações ou integrações nos objetos alvo. Se houver, a faixa sobe.
- Esta faixa é de consultor e dev: mapeamento, validação, execução em dev, reconciliação, rollback de teste e homologação. Não inclui tempo do agente. Faixa larga porque a demanda está vaga; o arquiteto refina no design.

---

## Premissas de execução do agente nesta etapa

- Só leitura de metadata foi feita (`sf org list`, `sf sobject list --sobject custom`). Nenhum SOQL de dado foi rodado. Nenhum registro de cliente foi lido.
- Nenhum artefato em `gates.md` foi escrito.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
