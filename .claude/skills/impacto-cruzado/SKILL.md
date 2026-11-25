---
name: impacto-cruzado
description: Como o recon levanta tudo o que dispara junto com a mudança — automações no mesmo objeto, referências ao campo que será alterado, diferenças entre a sandbox de dev e a de QA, e outras demandas abertas nos mesmos componentes. Use na etapa de recon, depois dos comandos base da skill org-recon.
---

# Impacto cruzado

A skill `org-recon` diz como consultar a org. Esta diz o que procurar além do objeto que a
demanda cita, porque o que reprova o QA quase nunca está no componente novo: está no
vizinho.

## 1. Tudo o que roda no mesmo evento

Para cada objeto que a demanda grava, liste o que dispara em criação e em alteração:

- Flows acionados por registro (antes e depois de salvar), com a versão ativa e o critério
  de entrada;
- triggers Apex e a classe que eles chamam;
- validation rules ativas, com a fórmula das que tocam os campos da demanda;
- processos de aprovação, com a ordem entre eles;
- regras de duplicidade e de atribuição;
- campos de resumo no objeto pai, que fazem o pai ser gravado junto.

Para cada item, diga em uma linha se ele lê ou grava algum campo que a demanda toca. É essa
coluna que o arquiteto usa.

Se o objeto é filho de outro, repita para o pai: gravar o filho pode disparar a cadeia do
pai inteira (SOMOSAGILITY-10: 150 filhos numa transação estouraram CPU).

## 2. Quem usa o que vai mudar

Quando a demanda altera ou substitui um campo, um Flow ou uma classe que já existe, procure
onde ele é referenciado antes de alguém mexer:

- no repositório do cliente, com Grep pelo nome de API em `force-app/` (Flows, classes,
  layouts, relatórios, permission sets, fórmulas);
- na org, pela dependência de metadata da Tooling API (`MetadataComponentDependency`),
  filtrando pelo componente. A consulta tem limite de linhas e não cobre todo tipo de
  metadata: se vier vazia, diga "sem referência encontrada pela consulta", não "não é
  usado".

Valor de picklist renomeado ou removido: procure o valor antigo em fórmulas, critérios de
Flow, filtros de relatório e validation rules. Renomear o rótulo não quebra; trocar o
valor de API quebra tudo o que compara por ele.

## 3. Dev e QA são iguais?

O build é provado na dev e aceito na QA. Diferença entre as duas muda o resultado do teste
(SOMOSAGILITY-10: validation rule ativa só na QA derrubou a suíte inteira).

Para os objetos da demanda, compare nas duas sandboxes, sempre com a org explícita:

- validation rules ativas (nome e se está ativa);
- Flows ativos e a versão ativa de cada um;
- triggers ativos;
- existência dos campos que a demanda usa.

Registre só as diferenças, numa tabela "Dev × QA". Sem acesso à QA nesta etapa, diga isso
em "O que não consegui confirmar".

## 4. Outras demandas no mesmo lugar

Leia `00-preflight.md`: ele lista as demandas abertas do cliente que mexem nos mesmos
componentes. Para cada uma, diga o componente em comum e em que etapa ela está. Duas
demandas no mesmo Flow, no mesmo agente ou no mesmo processo de aprovação precisam de
ordem definida no design (SOMOSAGILITY-17 e 22: ordem de processos invertida).

## 5. O que precisa existir para testar

O design vai pedir pré-requisitos de ambiente. Adiante o levantamento:

- há licença livre do tipo que o perfil de teste usa, na dev e na QA? (contagem em
  `UserLicense`, só os números);
- as filas e os grupos que a demanda usa têm membro ativo? (contagem, sem listar pessoas);
- há fixture do cliente em `clients/<cliente>/fixtures/` para os objetos envolvidos?

## Como registrar

Uma seção "Impacto cruzado" no `02-recon.md`, com as tabelas acima e o comando que provou
cada linha. Termine com o que não foi possível confirmar. Só leitura, só metadata e
contagens; nenhum nome de pessoa, nome de usuário ou endereço de e-mail no artefato.
