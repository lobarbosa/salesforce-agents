---
name: mc-modelo-de-dados
description: Como desenhar Data Extensions do Marketing Cloud no pacote mc/ — nome, campos, chave primária, se é enviável e por qual campo se liga ao contato, retenção e o formato JSON que o validador confere. Use ao criar ou alterar Data Extension numa demanda de Marketing Cloud.
---

# Data Extensions

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`.

## Decisões que toda Data Extension precisa ter

1. **Para que serve:** público de envio (enviável), tabela de apoio (lookup do AMPscript) ou
   passo intermediário de uma consulta. Uma DE, um papel.
2. **Chave primária.** Obrigatória quando uma consulta vai gravar nela com a ação *Update*
   (sem chave, o Update não tem como casar a linha) e quando o AMPscript a consulta por um
   campo. Escolha o menor conjunto de campos que identifica a linha.
3. **Enviável e relação de envio.** DE de público é *sendable*, com um campo ligado ao
   *Subscriber Key*. Com o Marketing Cloud Connect, o Subscriber Key é o Id de 18 caracteres
   do Contato ou do Lead no Sales Cloud: o campo da DE é texto de 18 e guarda esse Id, nunca o
   e-mail.
4. **E-mail só em campo do tipo EmailAddress**, e só em DE de público.
5. **Retenção.** DE intermediária e de público de campanha pontual têm retenção (por exemplo,
   apagar linhas depois de N dias). DE de apoio permanente, sem retenção, dita no README.
6. **Nome:** `<Cliente>_<Área>_<Propósito>`, sem espaço nem acento (ex.: `Acme_MKT_ReativacaoClientes`).
   A convenção do `CLAUDE.md` do cliente vence.

## Tipos de campo

`Text` (com tamanho), `Number`, `Decimal` (precisão e escala), `Date`, `Boolean`,
`EmailAddress`, `Phone`, `Locale`. Prefira o tamanho que o dado de origem tem no Sales Cloud;
texto sem tamanho vira 4000 e pesa em consulta.

## Formato no pacote (`mc/data-extensions/<Nome>.json`)

```json
{
  "nome": "Acme_MKT_ReativacaoClientes",
  "descricao": "Contatos sem compra há 180 dias, recalculado todo dia pela consulta Acme_ReativacaoClientes",
  "enviavel": true,
  "campo_de_envio": "ContactId",
  "retencao_dias": 30,
  "campos": [
    {"nome": "ContactId", "tipo": "Text", "tamanho": 18, "chave": true, "obrigatorio": true},
    {"nome": "Email", "tipo": "EmailAddress", "obrigatorio": true},
    {"nome": "PrimeiroNome", "tipo": "Text", "tamanho": 40},
    {"nome": "UltimaCompra", "tipo": "Date"}
  ]
}
```

O validador confere: nome válido, campos com tipo conhecido, `Text` com tamanho, chave
presente, e DE enviável com `campo_de_envio` existente.

## Contact Builder

Quando a DE de público se relaciona com outras (pedido, produto), diga no README a relação
(campo de uma, campo da outra, cardinalidade) que quem implanta vai criar no Contact Builder.
DEs sincronizadas do Sales Cloud (Synchronized Data Extensions) não são criadas pelo pacote:
são configuradas no Marketing Cloud Connect; o pacote só as cita pelo nome.
