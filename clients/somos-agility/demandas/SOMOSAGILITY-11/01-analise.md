# 01 — Análise (BA Discovery) — SOMOSAGILITY-11

**Título:** MANUTENÇÃO - CAMPO LOGÍSTICA - DSA
**Tipo:** sustentação
**Fonte:** `demanda.md` (registrada pelo consultor)

## Contexto de negócio

A demanda pede a inclusão de informações referentes ao **status de logística** em
registros, em **massa** (ou seja, não é um ajuste pontual em um único registro, e sim uma
carga/atualização que afeta um volume de registros de uma vez). O texto original cita um
"Detalhamento e planilha com os dados em anexo", mas **nenhum anexo chegou a este
repositório** — a pasta `demandas/SOMOSAGILITY-11/` contém apenas `demanda.md` e
`status.yaml`. Não há, portanto, confirmação de:

- qual objeto do Salesforce recebe esse campo (ex.: `Account`, algum objeto de pedido/
  remessa, um objeto customizado de logística);
- quais são os valores possíveis do "status de logística" (é um picklist? texto livre?
  está atrelado a algum processo de transporte/expedição já existente na org?);
- de onde vêm os dados da carga em massa (a planilha anexada seria a própria fonte dos
  valores a importar, ou é só documentação do pedido?).

O `CLAUDE.md` deste cliente (`clients/somos-agility/CLAUDE.md`) ainda não tem o briefing de
conta preenchido (clouds em uso, integrações existentes, convenções específicas de
nomenclatura) — não há fonte adicional para inferir isso com segurança. Nada aqui foi
inventado a partir desse arquivo porque ele está vazio.

## Objetivo

Permitir que o(s) registro(s) relevante(s) passem a carregar uma informação de **status de
logística**, atualizada em massa a partir de um conjunto de dados fornecido pelo consultor
(a planilha citada na demanda, ainda não recebida neste repositório).

## Regra de negócio

Não é possível declarar a regra de negócio com segurança ainda, porque a demanda não diz:

- se o campo é apenas informativo (display) ou se dispara alguma automação/processo
  (ex.: notificação, atualização de outro campo, gatilho de Flow);
- se existem transições de status válidas/inválidas (ex.: um registro só pode ir de
  "Em separação" para "Em trânsito", nunca o contrário) ou se é um campo livre sem
  máquina de estados;
- se a atualização em massa é um evento único (carga pontual desta demanda) ou um processo
  recorrente (nesse caso a solução precisa prever automação/recorrência, não só uma carga
  manual via Data Loader/Loader de tela).

Qualquer regra escrita aqui antes dessas respostas seria suposição silenciosa, o que a
doutrina deste squad proíbe explicitamente.

## Critérios de aceite (Gherkin)

Os critérios abaixo cobrem apenas o que é **testável com o que a demanda já afirma**
(existência do campo e carga em massa). Critérios sobre regra de transição, automação ou
visibilidade em layout ficam pendentes até as perguntas da seção seguinte serem
respondidas — não foram escritos para não inventar comportamento.

```gherkin
Funcionalidade: Status de logística em massa

  Cenário: Campo de status de logística existe no objeto alvo
    Dado que o objeto alvo da demanda foi confirmado via "sf" CLI contra a org
    Quando um usuário com acesso ao objeto abre um registro
    Então o campo "Status de Logística" está disponível e visível no layout apropriado

  Cenário: Carga em massa aplica o status corretamente
    Dado um conjunto de registros identificados na planilha fornecida pelo consultor
    Quando a carga em massa é executada em ambiente de sandbox (dev)
    Então cada registro listado na planilha reflete o status de logística correspondente
    E nenhum registro fora da lista da planilha tem seu status alterado

  Cenário: Carga em massa não quebra registros existentes
    Dado que outros campos do registro já estavam preenchidos antes da carga
    Quando a carga em massa é executada
    Então nenhum outro campo do registro é alterado além do status de logística
```

## O que a demanda NÃO diz

1. **Objeto alvo** — em qual objeto (padrão ou customizado) o campo de status de logística
   deve existir.
2. **Anexo/planilha** — a planilha mencionada no texto original não está neste repositório;
   sem ela não há como confirmar volume de registros, formato dos dados-fonte (IDs,
   chave de cruzamento) nem os valores possíveis do status.
3. **Tipo de campo** — picklist (valores fixos, e quais), texto livre, ou referência a um
   objeto/processo de logística já existente na org.
4. **Automação associada** — se a mudança de status deve dispará-la (ex.: notificar alguém,
   atualizar outro registro) ou se é puramente informativo.
5. **Recorrência** — se esta é uma carga única (projeto pontual de sustentação) ou se o
   cliente espera que cargas futuras do mesmo tipo sigam o mesmo mecanismo.
6. **Quem recebe o campo na UI** — perfis/papéis que devem enxergar e/ou editar esse campo,
   e em qual layout.
7. **Convenção de nomenclatura do cliente** — `clients/somos-agility/CLAUDE.md` não define
   prefixo de campo customizado nem padrão de branch/commit próprios; na ausência disso a
   skill `padrao-entrega` (convenção padrão do squad) deve ser usada, mas vale confirmar
   com o cliente antes do design se há um prefixo institucional não documentado ainda.

## Premissas a validar

- [ ] **Pendente** — Objeto Salesforce alvo do campo de status de logística (não foi
  possível confirmar via `sf` CLI nesta etapa porque a demanda não indica sequer um
  candidato a objeto; confirmação de metadata fica para a etapa de recon, depois que o
  objeto alvo for esclarecido com o consultor/cliente).
- [ ] **Pendente** — Conteúdo da planilha/anexo citado na demanda (não recebido neste
  repositório).
- [ ] **Pendente** — Lista de valores possíveis do status de logística.
- [ ] **Pendente** — Se há automação (Flow/Apex) associada à mudança de status ou é só
  dado informativo.
- [ ] **Pendente** — Se a carga em massa é evento único ou processo recorrente.

Nenhuma destas premissas foi assumida como verdadeira para fins de estimativa ou de
critérios de aceite acima — todas seguem marcadas como pendentes de validação com o
consultor/cliente antes do design técnico (etapa do `arquiteto`).

## Estimativa de complexidade

**M (média)** — justificativa: mesmo que a solução em si possa ser simples (um campo novo
+ uma carga em massa, típica de sustentação P/G pequena), a ausência total do anexo com os
dados e a falta de definição do objeto alvo e da regra de negócio tornam o escopo real
desconhecido até essas lacunas fecharem. A estimativa deve ser revisada assim que o anexo
e as respostas às perguntas acima chegarem — pode cair para P (se for só um campo +
import simples) ou subir para G (se envolver automação ou objeto novo).

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
