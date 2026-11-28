---
name: mc-ampscript
description: Como escrever a personalização em AMPscript dos e-mails do pacote mc/ — sintaxe, valor ausente, consultas a Data Extension, quando pular o envio e como testar sem enviar. Use ao personalizar e-mail, assunto ou pré-cabeçalho numa demanda de Marketing Cloud.
---

# AMPscript

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md` e `mc-email`.

## Sintaxe

- Bloco: `%%[ ... ]%%`. Saída na linha: `%%=v(@nome)=%%`.
- Variável: `SET @nome = AttributeValue("PrimeiroNome")`. Use `AttributeValue` em vez de
  `%%PrimeiroNome%%` quando o campo pode não existir na DE de envio: ele devolve vazio, a
  outra forma derruba o envio.
- Condição: `IF Empty(@nome) THEN SET @nome = "cliente" ENDIF`.

## Valor ausente é regra, não exceção

Todo campo personalizado tem um valor de reserva. Saudação sem nome vira "Olá," e não
"Olá ,". Data e número passam por `FormatDate` e `FormatNumber` com a cultura do cliente
(`"pt-BR"`).

## Consultar outra Data Extension

- `Lookup("DE", "CampoRetorno", "CampoFiltro", valor)`: um valor.
- `LookupRows` / `LookupOrderedRows`: várias linhas; `LookupRows` devolve no máximo 2000.
  Consulte pela chave primária da DE (skill `mc-modelo-de-dados`).
- Uma consulta por informação, fora de laço quando possível: AMPscript roda por destinatário.

## Quando não enviar

`RaiseError("motivo", true)` pula aquele destinatário sem derrubar o envio (por exemplo,
oferta obrigatória ausente). Use só quando enviar sem o dado seria pior que não enviar, e
diga no README o critério.

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

O validador confere: blocos `%%[ ]%%` e `%%= =%%` fechados, e o arquivo de casos com ao menos
três linhas (dado completo, campo ausente, pular ou o pior caso da regra).

## Antes de fechar

- [ ] Todo campo personalizado tem valor de reserva.
- [ ] `AttributeValue` em todo campo que pode faltar na DE de envio.
- [ ] Consultas a DE pela chave primária e fora de laço.
- [ ] `RaiseError` só com o critério escrito no README.
- [ ] Nenhum dado pessoal em URL.
