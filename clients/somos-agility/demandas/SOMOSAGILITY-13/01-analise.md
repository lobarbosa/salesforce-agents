# SOMOSAGILITY-13 — Análise: Esteira de venda para Renovação

> Status: **BLOQUEADA POR INFORMAÇÃO**. A demanda depende de um anexo de detalhamento que não foi liberado. Não avançar para o design (`arquiteto`) até as perguntas da seção "Lacunas críticas" serem respondidas.

## 1. Contexto de negócio

- Cliente: Somos Agility (`clients/somos-agility`).
- Hoje existe uma esteira de venda em operação na org. A demanda pede uma esteira **semelhante**, mas **específica para renovações** (contratos/assinaturas que já existem e precisam ser renovados, em vez de vendas novas).
- O texto original da demanda diz: "detalhamento esta no documento anexo". Conferido em disco: `demandas/SOMOSAGILITY-13/` contém apenas `demanda.md` e `status.yaml`. Não há pasta `anexos/` nem arquivo liberado. O conteúdo do anexo **não está disponível** e **não foi inferido** nesta análise.
- O `CLAUDE.md` de conta do cliente ainda está com a maior parte do briefing em branco (segmento, contatos, clouds em uso, nome da esteira atual, convenções). Isso também limita o entendimento do contexto.

## 2. Objetivo

Permitir que o time de renovação conduza o processo de renovação numa esteira própria, reaproveitando a lógica da esteira de venda atual, sem que a renovação dispare ou se misture com a esteira de venda nova.

Objetivo mensurável ainda **não definido** (ver lacuna L6).

## 3. Regra de negócio

Regras confirmadas pela demanda:

- R1. Deve existir uma esteira para renovação, distinta da esteira de venda.
- R2. A esteira de renovação deve ser semelhante à de venda atual em estrutura geral (a demanda não diz o que "semelhante" quer dizer em detalhe).

Regras **não** confirmadas (dependem do anexo): estágios, critérios de transição, objetos, campos, responsáveis, SLAs, integrações, regras de aprovação, o que muda em relação à venda. Nada disso foi assumido aqui; ver seção 6.

## 4. Critérios de aceite (Gherkin)

Os cenários abaixo são **provisórios**. Só cobrem o que a demanda já deixa claro. Os valores entre colchetes são placeholders que dependem das respostas da seção 5 e **não podem ser validados ainda**.

```gherkin
Funcionalidade: Esteira de renovação

  Cenário: Renovação segue uma esteira própria
    Dado uma oportunidade (ou registro equivalente) classificada como renovação
    Quando ela entra no processo
    Então ela é conduzida pela esteira de renovação
    E não é conduzida pela esteira de venda

  Cenário: Venda nova não entra na esteira de renovação
    Dado uma oportunidade classificada como venda nova
    Quando ela entra no processo
    Então ela não é conduzida pela esteira de renovação

  Cenário: Estágios da esteira de renovação
    Dado a esteira de renovação configurada
    Quando um registro de renovação percorre o processo
    Então ele passa pelos estágios [LISTA PENDENTE — L1]
    E a transição entre estágios respeita [REGRA PENDENTE — L2]

  Cenário: Diferenças em relação à esteira de venda
    Dado o mapeamento de diferenças [PENDENTE — L3]
    Quando um registro de renovação percorre a esteira
    Então [COMPORTAMENTO PENDENTE — L3]
```

Observação de testabilidade: os cenários 1 e 2 dependem de existir um campo ou critério que classifique "renovação" versus "venda nova". Esse critério não foi definido (L4). Sem ele, nenhum dos cenários é executável.

## 5. Lacunas críticas (precisam de resposta humana antes do design)

Ordem de prioridade. L1 a L4 bloqueiam o design.

- **L0 — Anexo de detalhamento ausente (bloqueante).** A demanda aponta para um anexo que não foi liberado nem está na pasta. Pedir ao consultor que libere o arquivo no card (com a declaração de ausência de dado pessoal, conforme guardrail #2) ou que informe o conteúdo por comentário.
- **L1 — Estágios da esteira de renovação.** Quais são, em ordem? Serão os mesmos da venda atual ou diferentes?
- **L2 — Regras de transição.** O que dispara a mudança de estágio? Há aprovação, validação ou ação manual?
- **L3 — Diferenças em relação à esteira de venda atual.** Quais estágios, campos, valores de picklist, automações e responsáveis mudam? Qual é a lista do que é "semelhante"?
- **L4 — Como um registro é classificado como renovação.** Existe um objeto, um tipo de registro (record type), um campo ou um vínculo com contrato existente que identifique a renovação? A renovação é um objeto próprio ou uma oportunidade com outro tipo?
- **L5 — Qual é a esteira de venda atual.** Nome, objeto e onde ela está na org. O cliente ainda não tem essa informação no `CLAUDE.md`.
- **L6 — Objetivo mensurável.** Qual resultado a esteira precisa entregar (prazo de renovação, taxa de renovação, redução de churn etc.)?
- **L7 — Integrações e dados.** A esteira de renovação lê ou escreve em sistemas externos (faturamento, ERP, contratos)? Há dado pessoal envolvido na renovação? (Guardrail #2: o agente não consulta dado real para responder isso.)
- **L8 — Responsáveis e aprovadores.** Quem opera a esteira, quem aprova a renovação, quem recebe notificação?
- **L9 — Prazo e prioridade.** Existe data-alvo ou dependência de outra entrega?
- **L10 — Ambiente.** Confirmar que a construção será feita primeiro em `sbx-somos-agility-dev` e que o alvo de homologação é `sbx-somos-agility-qa`.

## 6. Premissas a validar

Nenhuma destas premissas foi confirmada. Todas estão **pendentes** e precisam de validação humana antes do design.

- P1 (pendente, L4). A renovação é identificada dentro da org por um mecanismo que já existe ou que precisa ser criado. Não se sabe qual.
- P2 (pendente, L3). "Semelhante à de venda" significa copiar a estrutura da esteira atual e ajustar só os pontos de renovação. Não significa criar uma esteira do zero.
- P3 (pendente, L1). A esteira de renovação terá estágios próprios, não apenas um filtro sobre a esteira de venda.
- P4 (pendente, L7). Não haverá integração nova com sistema externo nesta demanda.
- P5 (pendente, L0). O conteúdo do anexo não será considerado nesta análise até ser liberado e lido.

## 7. Estimativa de esforço humano

**Estimativa de esforço:** 12–40 h

Premissas que mais pesam na faixa:
- Se a esteira de renovação for uma cópia da venda com poucos ajustes (novo record type, estágios e campos específicos), fica perto do piso (~12 h). Inclui configuração, revisão, teste e homologação.
- Se exigir objeto novo, classificação de renovação não existente na org ou integração externa, sobe para o teto (~40 h) ou mais.
- A faixa é larga porque o anexo com o detalhamento não foi lido. O arquiteto refina no design, quando as lacunas L1 a L4 estiverem respondidas.

Classificação de complexidade: **M** (justificativa: cópia de esteira existente com ajustes de estágio e classificação; o G só se confirmar objeto ou integração novos).

## 8. Próximos passos

1. Consultor libera o anexo no card ou responde L0 a L10 nos comentários do card.
2. Com as respostas, a análise é revisada e os critérios de aceite são reescritos sem placeholders.
3. Aprovação humana do refinamento no card (gate da etapa 1).
4. Só então o `arquiteto` é acionado.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
