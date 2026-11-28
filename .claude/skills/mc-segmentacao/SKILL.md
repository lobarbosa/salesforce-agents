---
name: mc-segmentacao
description: Como definir um segmento de público no pacote mc/ — critério, fonte do dado, consentimento, exclusões, grupo de controle, tamanho esperado e qual ferramenta do Marketing Cloud usar (consulta SQL, filtro, divisão na jornada). Use sempre que a demanda de Marketing Cloud precisa decidir para quem enviar.
---

# Segmentação

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`. Segmento é a decisão de
negócio de **quem recebe**; a consulta (`mc-sql`), o filtro e a jornada (`mc-jornada`) são
só a forma de executar. Escreva o segmento antes de escrever qualquer uma delas.

## O que todo segmento define (`mc/segmentos/<Nome>.md`)

1. **Objetivo**: a ação de marketing que ele alimenta.
2. **Critério**, em linguagem de negócio e depois em campo e valor (ex.: "sem compra há 180
   dias" = `UltimaCompra < hoje − 180`).
3. **Fonte**: de onde vem cada campo (DE sincronizada do Sales Cloud, DE de importação, data
   view de engajamento), confirmada com o cliente ou com a skill `mc-preparar-sales-cloud`.
4. **Consentimento**: o campo e o valor que provam o opt-in, e a exclusão de quem descadastrou.
5. **Exclusões**: clientes em atendimento aberto, quem recebeu outra campanha na mesma semana
   (limite de frequência), endereço com rejeição permanente, lista de supressão do cliente,
   funcionários. Cada uma com a fonte.
6. **Grupo de controle**, quando a demanda quer medir resultado: percentual retido sem envio e
   como é sorteado (ex.: últimos dígitos do Id), sempre o mesmo critério para poder comparar.
7. **Tamanho esperado**: faixa de contatos. Na versão 1 o agente não consulta a conta: use
   contagem agregada no Sales Cloud (só número, guardrail #2) ou escreva "não medido" e deixe
   a medição como primeiro passo de quem implanta. É esse número que alimenta a Verificação
   da automação (`mc-automacao`).
8. **Atualização**: com que frequência o segmento é recalculado e o que acontece com quem sai
   dele no meio de uma jornada.

## Qual ferramenta usar

| Situação | Use |
| --- | --- |
| Critério com mais de uma DE, data view ou cálculo | consulta SQL (`mc-sql`) |
| Critério simples numa única DE, mantido por quem opera | filtro (atividade Filtro ou DE filtrada) |
| A pessoa já está numa jornada e o caminho depende de dado ou engajamento | divisão por dado ou engajamento na jornada (`mc-jornada`) |
| Regra que só se sabe na hora do envio | exclusão no envio, documentada no README; evite quando der para resolver antes |

## Engajamento

Segmento por engajamento (abriu, clicou, não abre há N dias) lê as data views `_Open`,
`_Click`, `_Sent`, que guardam cerca de seis meses (`mc-sql`). Janela maior pede uma DE de
histórico alimentada antes. Abertura é sinal fraco (proteção de privacidade dos clientes de
e-mail abre mensagens sozinha): prefira clique e compra quando o objetivo for medir interesse.

## Formato no pacote

O validador confere em cada `mc/segmentos/<Nome>.md` as linhas `**Critério:**`,
`**Consentimento:**`, `**Exclusões:**` e `**Tamanho esperado:**`.

## Antes de fechar

- [ ] O critério em linguagem de negócio e em campo e valor dizem a mesma coisa.
- [ ] Todo campo do critério tem fonte confirmada; o que não tem é premissa assumida.
- [ ] Consentimento e descadastro aplicados antes de qualquer outro filtro.
- [ ] Limite de frequência considerado junto com as outras campanhas do cliente.
- [ ] Tamanho esperado com faixa, que alimenta a Verificação da automação.
