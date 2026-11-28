---
name: mc-sql
description: Como escrever as consultas SQL do Automation Studio (Query Activity) no pacote mc/ — o dialeto que o Marketing Cloud aceita, a ação de gravação na DE de destino, as data views e o que evitar para não estourar o tempo. Use ao criar consulta de segmentação ou de preparo de dado numa demanda de Marketing Cloud.
---

# SQL do Automation Studio

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`.

## O que o Marketing Cloud aceita

- Só `SELECT`. A consulta não altera dado: quem grava é a Query Activity, na DE de destino,
  com uma de três ações: **Overwrite** (apaga e regrava), **Update** (casa pela chave primária
  da DE de destino) ou **Append** (acrescenta).
- Dialeto parecido com T-SQL, com restrições: **sem** variáveis, cursores, tabelas
  temporárias, procedures nem CTE (`WITH`). Use subconsulta.
- Tempo máximo de execução: 30 minutos. Consulta lenta falha e a automação para.
- A consulta lê DEs (pelo nome, entre colchetes quando tem caractere especial) e data views.

## Cabeçalho obrigatório em cada arquivo `mc/sql/<Nome>.sql`

```sql
-- destino: Acme_MKT_ReativacaoClientes
-- acao: Overwrite
-- objetivo: contatos sem compra há 180 dias e com consentimento de e-mail
SELECT c.ContactId, c.Email, c.PrimeiroNome, p.UltimaCompra
FROM [Acme_Contatos] c
INNER JOIN (
    SELECT ContactId, MAX(DataPedido) AS UltimaCompra
    FROM [Acme_Pedidos]
    GROUP BY ContactId
) p ON p.ContactId = c.ContactId
WHERE c.OptInEmail = 1
  AND p.UltimaCompra < DATEADD(DAY, -180, GETDATE())
```

O validador recusa arquivo sem `destino` e `acao`, com comando que não é `SELECT`
(`INSERT`, `UPDATE`, `DELETE`, `DROP`, `TRUNCATE`, `EXEC`, `DECLARE`), com `WITH` de CTE, e
com `acao: Update` cujo destino no pacote não tem chave primária, e com `SELECT *`.

## Antes de fechar

- [ ] Os campos do `SELECT` são exatamente os da DE de destino, com os mesmos nomes.
- [ ] A ação (Overwrite, Update, Append) é a que o segmento pede, dita no cabeçalho.
- [ ] Público de envio filtra consentimento e exclui descadastro (skill `mc-segmentacao`).
- [ ] Nenhuma janela de engajamento maior que a retenção das data views.
- [ ] Junções por campo de chave, sem produto cartesiano que multiplique linhas.

## Data views

`_Subscribers`, `_Sent`, `_Open`, `_Click`, `_Bounce`, `_Unsubscribe`, `_Complaint`, `_Job`,
`_Journey`, `_JourneyActivity`. Guardam cerca de **seis meses**: consulta de engajamento mais
antigo que isso precisa de uma DE de histórico alimentada antes.

## Desempenho

- Filtre cedo, junte por campo de chave, evite `SELECT *`.
- Uma consulta por passo; encadeie passos na automação em vez de uma consulta gigante.
- `GETDATE()` está no fuso da conta (em geral, horário central dos EUA). Diga no README quando
  a regra depende do dia.

## Consentimento

Toda consulta que monta público de envio filtra o consentimento (opt-in) e exclui quem
descadastrou. Se o campo de consentimento não existe, é premissa a validar, não omissão.
