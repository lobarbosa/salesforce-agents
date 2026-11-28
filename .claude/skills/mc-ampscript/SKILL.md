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

## Teste nesta versão

O agente não executa AMPscript (versão 1 sem conexão). No README, cada bloco ganha uma tabela
"dado de entrada → saída esperada" com três linhas no mínimo: dado completo, campo ausente e
caso de pular. Quem implanta confere na pré-visualização com a massa de teste fictícia.
