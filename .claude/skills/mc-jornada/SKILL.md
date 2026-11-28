---
name: mc-jornada
description: Como especificar uma jornada do Journey Builder no pacote mc/ — fonte de entrada, reentrada, esperas, divisões, meta e critério de saída, num formato que uma pessoa monta na ferramenta e revisa antes de ativar. Use quando a demanda de Marketing Cloud pede comunicação em mais de um passo ou disparada por evento.
---

# Jornada

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md`. Na versão 1 a jornada é uma
**especificação**: quem monta e ativa no Journey Builder é uma pessoa. Ela entra no pacote
inativa, sempre.

## Decisões obrigatórias (`mc/jornadas/<Nome>.md`)

| Decisão | Opções | O que escrever |
| --- | --- | --- |
| Fonte de entrada | DE (agendada), Dado do Salesforce (via Marketing Cloud Connect, por evento de registro), Evento de API | qual, de que objeto ou DE, com que filtro |
| Reentrada | sem reentrada; a qualquer momento; só depois de sair | qual e por quê |
| Classificação de envio | comercial ou transacional | comercial respeita descadastro sempre |
| Esperas | duração ou até data/atributo | cada uma com o motivo |
| Divisões | por dado (decision split), por engajamento (abriu, clicou), aleatória | critério exato de cada ramo |
| Meta | o que conta como sucesso | campo e valor |
| Critério de saída | quando a pessoa sai antes do fim | campo e valor (ex.: comprou, descadastrou) |
| Avaliação de contato | quem entra de novo se o dado mudar | regra |

## Diagrama

Um diagrama mermaid (`flowchart LR`) com cada atividade e cada ramo, mais uma tabela com o
e-mail de cada envio (arquivo em `mc/conteudo/`). O nome das atividades no diagrama é o nome
que vai na ferramenta.

## Revisão antes de ativar (README)

1. Entrada testada com a massa fictícia numa DE de teste.
2. Cada ramo percorrido por um contato de teste.
3. Envio de teste de cada e-mail para a lista semente.
4. Quem ativa e quando, com aprovação registrada no card.
