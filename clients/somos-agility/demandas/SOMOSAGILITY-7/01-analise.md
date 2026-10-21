# SOMOSAGILITY-7 — Análise (BA)

**Cliente:** somos-agility
**Tipo:** Sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (design enxuto), 4, 5, 7.
**Entrada:** `demandas/SOMOSAGILITY-7/demanda.md` (título: "LAT - Erro na atualização dos Status Geral").
**Status desta análise:** BLOQUEADA por lacunas de informação (ver seção 6). Não é possível fechar critérios de aceite executáveis sem as respostas.

---

## 1. Contexto de negócio

A demanda relata que o campo "Status Geral" não reflete os "status secundários" de um registro. O texto diz que o detalhamento está num "documento anexo". **Esse anexo não está disponível para a análise**: não existe em `demandas/SOMOSAGILITY-7/` nem em nenhum outro ponto do cliente. O conteúdo dele não foi inventado aqui.

Consequência: não sabemos qual objeto é afetado, quais são os status secundários, qual é a regra que deveria consolidar o "Status Geral", nem qual mecanismo o calcula hoje (fórmula, Flow, trigger Apex, processo de validação, integração).

## 2. Objetivo

Fazer com que o "Status Geral" reflita corretamente os "status secundários" conforme a regra de negócio definida pelo cliente, eliminando a divergência relatada.

Objetivo **não verificável ainda**: falta definir a regra (seção 3) e o registro-exemplo que reproduz o erro.

## 3. Regra de negócio

**Não definida.** A demanda não diz:
- Quais status secundários entram na composição do Status Geral.
- Qual é a precedência / lógica de consolidação (ex.: "o mais atrasado vence", "todos concluídos", tabela de combinações).
- Em que momento o Status Geral deve ser recalculado (ao alterar um secundário, ao salvar, em lote, agendado).
- O que fazer quando os secundários estão vazios ou em estados conflitantes.

Hipótese de trabalho (NÃO validada, marcada como pendente): "Status Geral" é um campo picklist ou fórmula em um objeto custom (nome possivelmente com prefixo LAT, a confirmar) e é atualizado por algum automatismo existente, que hoje falha ou não é disparado ao mudar os secundários.

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo são **esqueleto provisório**. Não devem ser usados para build ou QA até as lacunas da seção 6 serem respondidas, porque os valores entre `<>` dependem delas.

```gherkin
Funcionalidade: Status Geral reflete os status secundários

  Cenário: Alteração de um status secundário recalcula o Status Geral
    Dado um registro de <OBJETO_A_CONFIRMAR> com status secundários <VALORES_INICIAIS>
    E o Status Geral atual é <VALOR_INICIAL_STATUS_GERAL>
    Quando o status secundário <CAMPO_A_CONFIRMAR> é alterado para <NOVO_VALOR>
    Então o Status Geral deve ser <VALOR_ESPERADO_PELA_REGRA>
    E o valor deve ser persistido sem intervenção manual

  Cenário: Combinação de status secundários conforme a tabela de regra
    Dado a combinação de status secundários <COMBINACAO_DA_TABELA>
    Quando o registro é salvo
    Então o Status Geral deve ser <VALOR_DA_TABELA>

  Cenário: Caso de borda — secundários vazios ou conflitantes
    Dado um registro com status secundários <VAZIOS_OU_CONFLITANTES>
    Quando o registro é salvo
    Então o Status Geral deve ser <VALOR_DEFINIDO_PELO_CLIENTE>

  Cenário: Registro que já apresenta divergência antes da correção
    Dado um registro existente com Status Geral divergente da regra
    Quando o recálculo é executado (automático ou por lote, a definir)
    Então o Status Geral deve ser igual ao valor da regra
    E nenhum outro campo do registro deve ser alterado
```

Pontos de testabilidade ainda pendentes:
- "Persistido sem intervenção manual" exige saber o gatilho (seção 6, pergunta 4).
- O cenário de registros históricos depende de a correção ser retroativa ou apenas prospectiva (seção 6, pergunta 6).

## 5. O que a demanda NÃO diz (perguntas bloqueantes)

Perguntas ao consultor, por ordem de impacto na arquitetura:

1. **Documento anexo:** pode enviar o anexo referido em "Detalhamento esta no documento anexo"? Ele não está no repositório nem na pasta da demanda.
2. **Objeto e campos:** qual objeto (API name) contém o "Status Geral" e quais são os "status secundários" (API names e tipo: picklist, fórmula, checkbox, lookup)? Nomes exatos, não apelidos de tela.
3. **Mecanismo atual:** o Status Geral é fórmula, campo atualizado por Flow, por trigger/classe Apex, por integração externa ou manualmente? Isso decide se a correção é declarativa ou código, e é o insumo do arquiteto.
4. **Gatilho esperado:** o recálculo deve ocorrer ao salvar o secundário, só em certas transições, ou em lote/agendado?
5. **Regra de consolidação:** qual a tabela ou lógica exata de cada combinação de status secundários → Status Geral? Precisa de exemplos concretos, inclusive os casos de conflito.
6. **Dados existentes:** registros já divergentes devem ser corrigidos (retroativo, com plano de execução) ou só os novos?
7. **Reprodução:** qual registro (ID de exemplo em sandbox, nunca dado real de cliente) e qual sequência de passos reproduz o erro? Qual é o comportamento observado e o esperado?
8. **Origem do bug:** o erro é desde sempre ou começou após alguma mudança/release identificável?
9. **Impacto e urgência:** quantos registros e usuários são afetados, e há prazo ou consequência de negócio (ex.: relatório, integração, cobrança) que dependa do campo?
10. **Escopo de ambiente:** a correção deve ir primeiro para `sbx-somos-agility-dev` e depois `sbx-somos-agility-qa`? Há alguma restrição de janela de deploy para esta conta (o `CLAUDE.md` do cliente ainda não a registra)?

## 6. Premissas a validar (pendentes, não assumidas)

| # | Premissa | Status |
|---|----------|--------|
| P1 | O "documento anexo" existe e contém a regra de consolidação | **Pendente — anexo ausente** |
| P2 | "Status Geral" e "status secundários" são campos de um objeto custom (nome com prefixo LAT ou similar) | **Pendente — não confirmado** |
| P3 | O Status Geral é calculado por automatismo em org (e não só manualmente ou por integração) | **Pendente** |
| P4 | A correção é de sustentação (mudança localizada), não redesenho do modelo de status | **Pendente** |
| P5 | Nenhum dado de cliente será necessário para reproduzir (reprodução em sandbox com registro de teste) | **Pendente** |

Nenhuma dessas premissas foi usada para fechar critérios acima. Qualquer uma delas que for confirmada deve ser registrada aqui com a fonte.

Não foi feito acesso à org (`sf` CLI) para esta análise, conforme escopo. A confirmação de objetos e campos (guardrail #3) será feita na etapa 2 (recon), depois que os nomes forem informados.

## 7. Estimativa de complexidade

**Estimativa provisória: M** (somente após as respostas às perguntas 2 e 3).

Justificativa: a demanda é pontual (um campo, uma regra), mas a regra de consolidação não está definida, o número de combinações de status pode ser grande, e o mecanismo atual é desconhecido. Se for fórmula simples, tende a P; se envolver trigger Apex com lógica de combinação e correção retroativa, tende a G.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.

## Estimativa de esforço

**Estimativa de esforço:** 6–12 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). M provisória: depende da regra do Status Geral e do registro-exemplo que reproduz o erro.

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
