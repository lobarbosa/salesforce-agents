---
name: mc-email
description: Como construir o HTML de e-mail do pacote mc/ para o Content Builder — estrutura que funciona nos clientes de e-mail, pré-cabeçalho, rodapé obrigatório com descadastro e central de preferências, acessibilidade e o que o validador confere. Use ao criar ou alterar e-mail numa demanda de Marketing Cloud.
---

# E-mail

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`. Personalização: `mc-ampscript`.

## Estrutura

- HTML com tabelas para o layout (clientes de e-mail ignoram boa parte do CSS moderno),
  largura de 600 px, CSS inline nos elementos e um `<style>` só para responsivo.
- Pré-cabeçalho logo no início do `<body>`, escondido, com o texto que aparece ao lado do
  assunto.
- Imagem sempre com `alt` descritivo e largura definida; o e-mail tem de fazer sentido com
  imagens bloqueadas.
- Botão como link estilizado (`<a>` dentro de célula), não imagem.
- Assunto e pré-cabeçalho vão no topo do arquivo, num comentário:

```html
<!-- assunto: %%=v(@nome)=%%, sentimos sua falta -->
<!-- preheader: 10% de desconto até domingo -->
```

## Rodapé obrigatório

- Link de descadastro: `%%unsub_center_url%%`, ou `%%profile_center_url%%` para a central de
  preferências. Sem um dos dois, o e-mail não sai do pacote.
- Endereço do remetente: `%%Member_Busname%%`, `%%Member_Addr%%`, `%%Member_City%%`.
- Por que a pessoa recebe (ex.: "Você recebe porque é cliente da Acme").

## LGPD

- Só envia para quem consentiu (filtro na consulta, skill `mc-sql`).
- Nenhum dado pessoal fixo no HTML: tudo vem do dado de envio, por AMPscript.
- Exemplo em comentário ou na massa de teste usa `@example.com`.

## O que o validador confere (`scripts/mc_validar_pacote.py`)

Comentários de assunto e preheader, link de descadastro ou de central de preferências,
endereço do remetente (`%%Member_Addr%%`), `alt` em toda imagem, ausência de endereço de
e-mail fixo fora de `@example.com`, e, havendo AMPscript, os casos de teste (skill
`mc-ampscript`).

## Antes de fechar

- [ ] Assunto com até cerca de 50 caracteres e pré-cabeçalho que completa o assunto.
- [ ] Legível com imagens bloqueadas e no celular (coluna única abaixo de 600 px).
- [ ] Um objetivo e uma chamada principal por e-mail.
- [ ] Rodapé com descadastro, remetente e motivo do recebimento.
- [ ] Links com o rastreamento que o cliente usa (parâmetros de campanha), sem dado pessoal.

## Teste nesta versão

Quem implanta: pré-visualização com a massa de teste, envio de teste só para a lista semente
do time, conferência em desktop e celular. O README lista esses passos com o dono.
