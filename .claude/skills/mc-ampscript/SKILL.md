---
name: mc-ampscript
description: Como escrever a personalização em AMPscript dos e-mails do pacote mc/ — sintaxe, valor ausente, consultas a Data Extension, quando pular o envio e como testar sem enviar. Use ao personalizar e-mail, assunto ou pré-cabeçalho numa demanda de Marketing Cloud.
---

# AMPscript

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md` e `mc-email`.

## Sintaxe

- Bloco: `%%[ ... ]%%`. Saída na linha: `%%=v(@nome)=%%`.
- Variável: `SET @nome = AttributeValue("PrimeiroNome")`. Use `AttributeValue` em vez de
  `%%PrimeiroNome%%` quando o campo pode não existir no dado de envio: a documentação diz que
  ele é melhor que a referência direta porque **devolve nulo** quando não acha o dado (procura
  no perfil do assinante, na DE de envio e nos atributos da entrada da jornada). O que a
  referência direta faz nesse caso não está na página: não prometa. Fonte: "AttributeValue()"
  (https://developer.salesforce.com/docs/marketing/marketing-cloud-ampscript/references/mc-ampscript-utilities/mc-ampscript-reference-utilities-attribute-value.html,
  lida em 2026-11-28).
- Condição: `IF Empty(@nome) THEN SET @nome = "cliente" ENDIF`.

## Valor ausente é regra, não exceção

Todo campo personalizado tem um valor de reserva. Saudação sem nome vira "Olá," e não
"Olá ,". Data e número passam por `FormatDate` e `FormatNumber` com a cultura do cliente
(`"pt-BR"`).

## Consultar outra Data Extension

- `Lookup("DE", "CampoRetorno", "CampoFiltro", valor)`: um valor. Com mais de uma linha que
  casa, devolve **a primeira que achar**: só consulte por campo único na DE (a chave
  primária). Fonte: "Lookup()"
  (https://developer.salesforce.com/docs/marketing/marketing-cloud-ampscript/references/mc-ampscript-data-extension/mc-ampscript-reference-data-extension-lookup.html).
- `LookupRows`: várias linhas, **no máximo 2.000 e sem ordem**, sem distinguir maiúscula de
  minúscula (`LookupRowsCS` distingue). Precisa de ordem ("a última compra")? Use
  `LookupOrderedRows`, que recebe coluna e direção. A DE pode passar de 2.000 linhas para o
  mesmo filtro? Então o filtro está errado para AMPscript: monte a lista antes, numa
  consulta (skill `mc-sql`). Fonte: "LookupRows()"
  (https://developer.salesforce.com/docs/marketing/marketing-cloud-ampscript/references/mc-ampscript-data-extension/mc-ampscript-reference-data-extension-lookup-rows.html),
  lidas em 2026-11-28. Consulte pela chave primária da DE (skill `mc-modelo-de-dados`).
- Uma consulta por informação, fora de laço quando possível: AMPscript roda por destinatário.

## Quando não enviar

`RaiseError("motivo", true)` pula aquele destinatário sem derrubar o envio (por exemplo,
oferta obrigatória ausente). Use só quando enviar sem o dado seria pior que não enviar, e
diga no README o critério.

O que a documentação diz ("RaiseError",
https://developer.salesforce.com/docs/marketing/marketing-cloud-ampscript/references/mc-ampscript-utilities/mc-ampscript-reference-utilities-raise-error.html,
lida em 2026-11-28):

- O segundo parâmetro **vale `false` por padrão, e `false` para o envio inteiro**. Sem o
  `true`, um destinatário sem oferta cancela a campanha de todos. O validador recusa
  `RaiseError` sem `true` no segundo parâmetro.
- **Não é ferramenta de segmentação**: a recomendação é usar só para tratar erro; quem não
  deve receber sai antes, na consulta ou na lista de exclusão (skill `mc-segmentacao`).
- Na jornada, pula a pessoa só daquele envio; ela segue para os próximos passos.
- O e-mail pulado não conta como uso para cobrança, mas **entra nas métricas** de envio: o
  relatório de entregues não bate com o tamanho do público, e o README diz isso.
- Gravação em DE feita pelo AMPscript antes do erro se perde, salvo com o quinto parâmetro
  (`boolPreserveDataExt`) verdadeiro. Registro de erro numa DE de log, antes do
  `RaiseError`, precisa dele.

## Segurança

- Nunca monte URL ou HTML com valor vindo do dado sem tratar.
- Link rastreado: `%%=RedirectTo(@url)=%%` quando a URL é montada.
- Nada de dado pessoal em parâmetro de URL de rastreamento.

## Casos de teste (`mc/conteudo/<Nome>.casos.md`)

O agente não executa AMPscript (versão 1 sem conexão). Todo e-mail com AMPscript tem, ao
lado, um arquivo de casos com a mesma base de nome, e quem implanta confere cada linha na
pré-visualização com a massa de teste fictícia:

```markdown
| Entrada (massa de teste) | Saída esperada |
| --- | --- |
| PrimeiroNome = Ana, oferta = 10% | "Olá, Ana" e "10% de desconto" |
| PrimeiroNome vazio | "Olá, cliente" |
| sem oferta na DE de apoio | destinatário pulado (RaiseError) |
```

O validador confere: blocos `%%[ ]%%` e `%%= =%%` fechados, o arquivo de casos com ao menos
três linhas (dado completo, campo ausente, pular ou o pior caso da regra), e todo
`RaiseError` com `true` no segundo parâmetro.

## Antes de fechar

- [ ] Todo campo personalizado tem valor de reserva.
- [ ] `AttributeValue` em todo campo que pode faltar na DE de envio.
- [ ] Consultas a DE pela chave primária e fora de laço.
- [ ] `RaiseError` só com o critério escrito no README, sempre com `true` no segundo
      parâmetro, e nunca no lugar de um filtro do segmento.
- [ ] `Lookup` só por campo único; `LookupRows` com filtro que nunca passa de 2.000 linhas, e
      `LookupOrderedRows` quando a ordem importa.
- [ ] Nenhum dado pessoal em URL.
