---
name: mc-automacao
description: Como especificar uma automação do Automation Studio no pacote mc/ — gatilho (agenda ou arquivo), passos e atividades, ordem, verificação antes de enviar, notificação de erro e o formato que o validador confere. Use quando a demanda de Marketing Cloud precisa preparar dado, montar público ou enviar de forma recorrente.
---

# Automação (Automation Studio)

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`. Consultas: `mc-sql`. Público:
`mc-segmentacao`. Na versão 1 a automação é uma **especificação**: quem monta e agenda é uma
pessoa, e ela entra no pacote **inativa**, sempre.

## Gatilho

| Gatilho | Quando usar | O que escrever |
| --- | --- | --- |
| Agenda | rotina diária, semanal, mensal | frequência, horário **no fuso da conta**, data de início e de fim |
| Arquivo (File Drop, no FTP do Marketing Cloud) | dado que chega de outro sistema | pasta, padrão do nome do arquivo, quem envia |
| Sob demanda | carga pontual | quem roda e quando |

## Passos e atividades

A automação é uma sequência de **passos**; atividades do mesmo passo rodam em paralelo, e o
passo seguinte só começa quando todas terminam. Ponha no mesmo passo só o que não depende um
do outro.

| Atividade | Para que |
| --- | --- |
| Consulta SQL | preparar dado e montar público (arquivo em `mc/sql/`) |
| Importação de arquivo | carregar arquivo do FTP numa DE (ação: adicionar, atualizar ou substituir) |
| Extração de dado e transferência de arquivo | gerar arquivo para outro sistema |
| Filtro | segmentar uma DE por critério simples, sem SQL (skill `mc-segmentacao`) |
| Verificação | **parar a automação** se a contagem de uma DE fugir do esperado (ex.: público zerado ou 10 vezes maior que o normal) |
| Envio de e-mail | disparo recorrente para uma DE de público |
| Script (SSJS) | só quando nenhuma outra atividade resolve; justificar no design |

## Regras

- **Toda automação que envia tem uma Verificação antes do envio.** Público vazio ou fora do
  tamanho esperado para a automação e notifica, em vez de enviar errado.
- Notificação de erro e de pulo para um e-mail do time do cliente (descrito pelo papel, sem
  endereço no pacote).
- Uma automação por objetivo. Não junte a carga de dados de uma área com o envio de outra.
- Nome: `<Cliente>_<Área>_<Propósito>`, como as DEs.
- Diga o tempo esperado de cada passo e o total: consulta de mais de 30 minutos falha.

## Formato no pacote (`mc/automacoes/<Nome>.md`)

```markdown
# Acme_MKT_ReativacaoDiaria

**Estado:** inativa
**Gatilho:** agenda, todo dia às 06:00 (fuso da conta), a partir da aprovação
**Notificação de erro:** e-mail do time de marketing do cliente

| Passo | Atividade | Peça | Esperado |
| --- | --- | --- | --- |
| 1 | Consulta SQL | `sql/Acme_ReativacaoClientes.sql` → `Acme_MKT_ReativacaoClientes` (Overwrite) | 2 a 5 mil linhas |
| 2 | Verificação | `Acme_MKT_ReativacaoClientes` | parar se 0 ou mais de 20 mil linhas |
| 3 | Envio de e-mail | `conteudo/Reativacao.html` para `Acme_MKT_ReativacaoClientes` | — |
```

O validador confere: `**Estado:** inativa`, a linha de gatilho, a de notificação de erro,
que todo `sql/<arquivo>.sql` citado existe no pacote, e que automação com envio tem uma
Verificação antes dele.

## Antes de fechar

- [ ] Cada passo depende só dos anteriores; nada no mesmo passo depende de outra atividade dele.
- [ ] A faixa da Verificação vem do tamanho esperado do segmento.
- [ ] Horário no fuso da conta e longe de outras automações que gravam nas mesmas DEs.
- [ ] Tempo total estimado, cada consulta abaixo de 30 minutos.
- [ ] Como pausar e como desfazer (DE a restaurar, envio a cancelar) no README.
