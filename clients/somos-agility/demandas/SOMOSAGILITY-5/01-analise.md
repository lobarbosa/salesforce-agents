# SOMOSAGILITY-5 — Análise (BA)

Status: **rascunho para validação humana. Não acionar o arquiteto antes de responder as perguntas da seção "O que a demanda não diz".**

Fonte: `demandas/SOMOSAGILITY-5/demanda.md` (enviada pelo consultor, não editada).

## Contexto de negócio

O consultor pede liberação de permissão de gravação na tabela "Previsão de Gastos dos Investimentos Realizados" para o usuário/grupo `grupooperacao`, no processo "Job de investimento → Relacionado → PGR". A demanda informa que o caso já foi "atendido pontualmente", ou seja, alguém já concedeu o acesso fora de um fluxo registrado.

Leitura provisória: a equipe de operação precisa registrar previsões de gasto de investimentos realizados a partir do job de investimento, e hoje só consegue ler (ou não consegue gravar). Isso é inferência do texto, não fato confirmado.

## Objetivo

Garantir que `grupooperacao` consiga gravar nos registros de "Previsão de Gastos dos Investimentos Realizados" acessados pelo processo "Job de investimento → Relacionado → PGR", com a menor permissão que atenda o processo, e que a concessão fique rastreável no repositório (não só na org).

## Regra de negócio

Não há regra de negócio descrita na demanda. A única regra explícita é de acesso: o grupo deve poder gravar. Quem pode gravar, em quais registros e em quais campos precisa ser definido (ver perguntas).

## Critérios de aceite

Rascunho em Gherkin. Os placeholders entre `<>` **não são testáveis ainda**: dependem das respostas da seção abaixo. Não considerar aprovados até serem substituídos.

```gherkin
Funcionalidade: Gravação de Previsão de Gastos dos Investimentos Realizados por grupooperacao

  Cenário: Membro de grupooperacao grava previsão a partir do processo Job de investimento
    Dado que um usuário membro de "grupooperacao" está logado na org de <AMBIENTE>
    Quando ele acessa o registro de <OBJETO_PAI> e navega por "Relacionado → PGR"
    E cria ou edita um registro de "Previsão de Gastos dos Investimentos Realizados"
    Então o registro é salvo com sucesso
    E os campos <LISTA_DE_CAMPOS_GRAVAVEIS> aceitam valor

  Cenário: Permissão fica restrita ao necessário
    Dado que um usuário membro de "grupooperacao" está logado na org de <AMBIENTE>
    Quando ele tenta excluir um registro de "Previsão de Gastos dos Investimentos Realizados"
    Então a operação é negada, salvo se <EXCLUSAO_PERMITIDA> for confirmada

  Cenário: Usuário fora do grupo não ganha acesso
    Dado que um usuário que não é membro de "grupooperacao" está logado na org de <AMBIENTE>
    Quando ele tenta gravar em "Previsão de Gastos dos Investimentos Realizados"
    Então o comportamento permanece igual ao anterior à mudança (registrar o estado antes na recon)

  Cenário: Concessão rastreável
    Dado que a permissão foi implementada em <AMBIENTE> via pacote/metadata versionado
    Quando o conferir-gates é executado após a aprovação
    Então o artefato de design e o plano de build referenciam o mesmo objeto, permissão e grupo
```

Critérios que ainda precisam ser escritos depois das respostas: qual objeto exato, qual mecanismo (Profile, Permission Set, FLS, sharing), quais campos, se há exclusão e se "Já atendido pontualmente" precisa ser revertido ou preservado.

## O que a demanda NÃO diz

1. **Qual objeto Salesforce corresponde à "tabela"?** Pode ser objeto custom com API name próprio, objeto padrão renomeado, ou um rótulo de lista relacionada. O nome exato e a API name não estão no texto.
2. **O que é `grupooperacao`?** Pode ser username, Public Group, Permission Set Group, Profile ou Role. O texto não diz. Isso muda completamente o mecanismo de correção.
3. **Qual mecanismo hoje bloqueia a gravação?** Não se sabe se é Profile sem CRUD, FLS de campo, Sharing (OWD/regra/manual), Validation Rule, Flow ou falta de Record Type. Não há mensagem de erro, print ou log.
4. **Em qual org?** A demanda não diz se o pedido vale para `sbx-somos-agility-dev`, `sbx-somos-agility-qa` ou produção. Produção é proibida ao agente (guardrail #1); a análise assume que só dev e qa estão no escopo, mas isso precisa ser confirmado pelo humano.
5. **Qual é o "Job de investimento" e o "PGR" no modelo?** Os nomes são de processo de negócio. Não há confirmação de quais objetos e relacionamentos formam essa cadeia.
6. **Qual é o escopo de gravação?** Criar, editar, excluir, todos os campos ou só alguns? Só a própria previsão ou previsões de outros registros do job?
7. **Quem solicitou e quem aprova?** Não há identificação do solicitante, aprovador do cliente nem ticket de origem. Regra da conta somos-agility sobre aprovador obrigatório não está preenchida no `CLAUDE.md` do cliente.
8. **O que foi feito "pontualmente"?** Quem concedeu, quando, em qual org, com qual mecanismo, e se a concessão ainda está ativa. Se foi feita direto em produção, é divergência a registrar, não a replicar.
9. **Há dado pessoal ou financeiro sensível?** Previsão de gasto de investimento pode ser dado de negócio sensível. A demanda não informa se há campos de valor, cliente ou pessoa envolvidos, o que importa para o guardrail #2 (sem SOQL com dado real).
10. **Qual o prazo e a urgência?** Não há data nem impacto descrito.

## Premissas a validar

Todas pendentes. Nenhuma foi confirmada na org.

- **P1 (pendente):** `grupooperacao` é um Public Group ou Permission Set Group, e o acesso será concedido por ele, não por Profile. Se for Profile, a mudança afeta todos os usuários daquele perfil, o que exige análise própria.
- **P2 (pendente):** a mudança é só de permissão de objeto/campo (CRUD/FLS) e não de sharing. Sharing muda o escopo de registros e costuma pedir mais cuidado.
- **P3 (pendente):** a exclusão não está incluída no pedido. Sem confirmação, o acesso fica em criar/editar.
- **P4 (pendente):** o pedido vale para dev e qa primeiro, com promoção posterior pelo fluxo de release. Nada vai para produção pelo agente.
- **P5 (pendente):** a concessão "pontual" feita antes deve ser substituída pela versão versionada em repositório, não mantida em paralelo.

## Complexidade

**P** — mudança de permissão em um objeto e um grupo, sem código, se as respostas confirmarem CRUD/FLS ou Permission Set. Sobe para M se for sharing, Profile compartilhado com outros usuários, ou se a causa estiver em Flow/Validation Rule.

## Estimativa de esforço

**Estimativa de esforço:** 2–5 h

Premissas que mais pesam na faixa:
- Mecanismo é Permission Set ou CRUD/FLS simples (faixa baixa). Se for sharing, Profile compartilhado ou Flow/Validation Rule, a faixa sobe para algo perto de 8–12 h.
- Objeto e campos já identificados pelo consultor. Sem isso, a recon precisa de tempo a mais.
- Inclui configurar, revisar, testar em dev, testar em qa e homologar com o consultor. Não inclui tempo de agente.
- Não inclui a investigação do que foi feito "pontualmente", que pode ser mais longa se houver divergência em produção.

## Próximos passos (depois das respostas)

1. Responder as perguntas 1 a 8 com o consultor e registrar as respostas em `demanda.md` pelo canal de comentários do card, para que o agente de recon as leia.
2. Recon (`org-recon`): confirmar via `sf` CLI o objeto, o grupo, a permissão atual e a causa do bloqueio, em dev e qa.
3. Atualizar esta análise com os critérios de aceite finais e a estimativa refinada.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
