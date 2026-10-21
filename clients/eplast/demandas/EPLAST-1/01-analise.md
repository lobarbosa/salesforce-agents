# EPLAST-1 — Análise: Diagnóstico da qualidade dos dados comerciais

Status: análise (etapa 1). Fonte: `demanda.md` (enviada pelo consultor, não editada).
Premissas e perguntas abaixo estão marcadas como pendentes. Nada aqui foi confirmado contra a org.

## 1. Contexto de negócio

A fase 1 do projeto Eplast prevê um diagnóstico de qualidade de dados antes de qualquer construção
nas ondas seguintes. O objetivo é avaliar completude, duplicidade e consistência dos dados de Conta,
Contato, Lead e Oportunidade, para que automações e scoring das ondas seguintes não herdem dados ruins.

Estado atual do cliente (de `clients/eplast/CLAUDE.md`):
- Segmento, contatos principais, clouds em uso, integrações: **não documentados**.
- Org de produção: **não configurada no workspace**; o agente não toca em produção (guardrail #1).
- Sandboxes da esteira (`sbx-eplast-dev`, `sbx-eplast-qa`): URLs e versões de API ainda são placeholders.
- Saúde da org: **sem `assessment.md`**. Volume, configuração e qualidade atual dos dados são desconhecidos.

## 2. Objetivo

Produzir, sobre a org atual, dois indicadores e um conjunto de recomendações priorizadas:

1. Percentual de duplicidade em Conta, Lead e Contato.
2. Percentual de preenchimento dos campos de segmentação e scoring (a lista de campos ainda não existe).
3. Recomendações de correção priorizadas, validadas pelo cliente.

O objetivo é **diagnóstico**. Esta demanda não corrige dados, não altera regras de duplicidade e não
cria automação. Se o cliente quiser correção, vira demanda própria.

## 3. Regras de negócio

- RN1. O diagnóstico é somente leitura sobre a org. Nenhuma escrita (DML, deploy, metadata) como parte da análise.
- RN2. Apenas metadata e contagens agregadas entram no contexto dos agentes. Nenhum registro individual
  (nome, CPF, e-mail, telefone, valores) pode aparecer em artefatos, logs, PRs ou no RAG (guardrail #2, LGPD).
  Os relatórios de duplicidade devem mostrar contagem e percentual, não a lista dos pares duplicados.
- RN3. "Duplicado" precisa de uma definição explícita e aprovada pelo cliente: quais campos compõem a chave
  de comparação (ex.: CNPJ/CPF, e-mail, nome+cidade) e qual regra de match (exato ou normalizado).
  Sem isso, o percentual de duplicidade não tem significado. Ver pergunta P3.
- RN4. Os percentuais de completude devem ser calculados sobre uma base declarada (ex.: todos os registros
  ativos do objeto, ou só registros criados nos últimos N meses). A base também precisa ser aprovada. Ver P4.
- RN5. Nenhum agente recomenda correção que mude dado de cliente sem aprovação humana.

## 4. Critérios de aceite

Os critérios propostos no `demanda.md` não são testáveis como estão (ver seção 6). Reescritos abaixo.

```gherkin
Funcionalidade: Diagnóstico de qualidade de dados comerciais — Eplast

  Cenário: Percentual de duplicidade calculado por objeto
    Dado que a regra de duplicidade de Conta, Lead e Contato foi aprovada pelo cliente (campos-chave e regra de match)
    Quando o diagnóstico é executado sobre a org de referência declarada
    Então existe um relatório com, para cada objeto em Conta, Lead e Contato:
      | total de registros da base | quantidade de registros em grupo duplicado | percentual de duplicidade |
    E o relatório não contém nome, e-mail, telefone, documento ou qualquer outro dado pessoal de registro
    E a base e a regra de match usadas aparecem no próprio relatório

  Cenário: Percentual de preenchimento dos campos de segmentação e scoring
    Dado que a lista de campos de segmentação e scoring foi aprovada pelo cliente
    Quando o diagnóstico é executado sobre a base aprovada
    Então existe um relatório com, para cada campo da lista, o percentual de registros preenchidos
    E o relatório indica a base (objeto, filtro de data e status) usada no cálculo
    E o relatório contém apenas contagens e percentuais agregados

  Cenário: Recomendações priorizadas validadas pelo cliente
    Dado que o relatório de duplicidade e o de preenchimento foram gerados
    Quando o agente produz a lista de recomendações de correção
    Então cada recomendação tem objeto, problema, impacto estimado nas ondas seguintes e prioridade (alta, média ou baixa)
    E a lista foi enviada à pessoa de contato do cliente aprovada pela Eplast
    E existe registro, no card, da validação da lista pelo cliente com data e nome de quem validou

  Cenário: Diagnóstico somente leitura
    Dado que o diagnóstico roda contra uma org sandbox declarada
    Quando a análise é executada
    Então nenhuma operação de escrita é realizada na org
    E a org usada é confirmada como sandbox antes da primeira consulta
```

Observação sobre o critério "percentual de preenchimento": ele só passa a ser testável quando a lista de
campos e a base forem aprovadas (P4 e P5). Até lá, o critério está **pendente**, não aceito.

## 5. O que a demanda NÃO diz

Estas perguntas precisam de resposta antes do design. Algumas mudam a arquitetura da solução.

- **P1 (bloqueante — muda arquitetura): qual org é a fonte dos dados?**
  Os dados comerciais reais da Eplast estão, presumivelmente, em produção. Produção é proibida para agentes.
  Se o diagnóstico tiver que rodar sobre dados reais, é preciso uma sandbox copiada de produção (com quais
  dados mascarados, em qual data, por quem) ou exportação controlada. Essas opções têm arquiteturas e riscos
  LGPD muito diferentes. Não escolho sozinho.
- **P2 (bloqueante — muda arquitetura): onde o relatório será hospedado?**
  Relatórios e dashboards nativos do Salesforce (Reports/Dashboards) ou ferramenta externa (BI, planilha, PDF)?
  Relatório nativo exige report types, permissões e possivelmente campos de apoio na org; externo exige
  exportação de dados, que esbarra em RN2.
- **P3: qual é a definição de duplicidade?** Campos-chave, regra de match (exato, normalizado, fuzzy) e
  o que conta como "grupo" (2 ou mais registros?). Quem aprova: quem, do lado da Eplast?
- **P4: qual é a base do percentual de completude?** Todos os registros ativos, só criados em um período,
  só registros em status específico?
- **P5: quais campos compõem "segmentação e scoring"?** A lista não existe. Ela é da Eplast, não do squad.
  As ondas seguintes ainda não estão desenhadas, então esta lista pode ser um palpite a validar com o cliente.
- **P6: quais objetos e registros entram?** Só Conta, Lead, Contato e Oportunidade? Oportunidade aparece no
  objetivo mas não nos critérios de aceite do `demanda.md`. Ponto a confirmar.
- **P7: quem valida as recomendações do lado do cliente, e em qual prazo?** Não há contato nomeado no CLAUDE.md.
- **P8: a Eplast é um cliente de projeto ou AMS?** O `tipo` no `status.yaml` é `projeto`, mas o contrato não
  está confirmado no workspace. Afeta como o esforço é acompanhado.
- **P9: as recomendações devem ser aplicadas em alguma etapa, ou só entregues como relatório?**
  O `demanda.md` fala em "recomendações de correção", mas não diz quem executa a correção nem se faz parte desta demanda.
- **P10: volume.** Não há assessment. Quantos registros existem em cada objeto? Isso define se as consultas
  agregadas cabem em limites de API e de tempo de relatório.
- **P11: integrações.** Há sistemas externos (ERP, marketing, portal) que criam ou atualizam Contas, Leads e
  Contatos? Duplicidade pode vir de integração, não de digitação. Isso muda a recomendação.
- **P12: prazo.** A demanda não tem data.

## 6. Problemas de redação do `demanda.md`

- O critério "existe um relatório com percentual de duplicidade" não diz qual base, qual regra e qual
  formato. Reescrito na seção 4.
- "Campos usados para segmentação e scoring" é indefinido (P5).
- "Recomendações validadas pelo cliente" não diz quem valida nem o que conta como validado. Reescrito na seção 4.
- O objetivo cita "Conta, Contato, Lead e Oportunidade", mas os critérios só cobrem Conta, Lead e Contato (P6).

## 7. Premissas a validar

Todas pendentes. Nenhuma foi confirmada contra a org.

- PR1. A org de referência é uma sandbox de dev ou qa, ou uma cópia de produção a ser criada. Pendente de P1.
- PR2. Os objetos são Conta, Lead, Contato e Oportunidade, todos padrão, sem objetos customizados de dados
  comerciais. Não confirmado: depende de `sf sobject list` na org de referência.
- PR3. O diagnóstico é executado pelo squad com somente leitura e saídas agregadas. Não há DML.
- PR4. O relatório será nativo do Salesforce, a não ser que P2 diga o contrário.
- PR5. O volume de registros é compatível com consultas agregadas sem processamento em lote. Não confirmado (P10).
- PR6. A validação das recomendações é feita por uma pessoa da Eplast a ser indicada (P7).

## 8. Complexidade

**M** — diagnóstico read-only em dois indicadores e uma lista de recomendações, sem construção de automação.
O peso vem da dependência de definições do cliente (P3 a P5) e do acesso à base de dados correta (P1),
não da técnica.

## 9. Estimativa de esforço humano

**Estimativa de esforço:** 14–28 h

Premissas que mais pesam na faixa:
- Definições de duplicidade e de campos de scoring (P3, P5) chegando em uma ou duas rodadas. Se o cliente
  demorar a responder, a faixa sobe para o topo ou acima.
- Acesso à base correta (P1). Se for preciso criar e mascarar uma sandbox a partir de produção, a faixa
  sobe bastante e não está coberta aqui.
- Escolha de hospedagem (P2). Relatório nativo cabe na faixa; ferramenta externa com exportação controlada não cabe.
- Validação das recomendações pelo cliente (P7), que depende de terceiros e de prazo.
- Consultor e dev configurando relatórios, revisando e homologando. Não inclui o tempo do agente.

O arquiteto refina no design.

## 10. Pedidos ao consultor

1. Confirmar a org de referência (P1) e, se for produção, qual caminho de cópia ou exportação o cliente aprova.
2. Confirmar a hospedagem do relatório (P2).
3. Trazer a definição de duplicidade (P3) e a lista de campos de segmentação e scoring (P5), validadas pelo cliente.
4. Indicar quem valida as recomendações e o prazo (P7, P12).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
