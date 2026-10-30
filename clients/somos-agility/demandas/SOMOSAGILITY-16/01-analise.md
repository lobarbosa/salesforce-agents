# SOMOSAGILITY-16 — Análise (ba-discovery)

**Cliente:** Somos Agility
**Tipo:** sustentação (bug/melhoria) — etapas 1, 2, 3 (design enxuto), 4, 5, 7
**Fonte:** `demanda.md` (enviada por Juliana Mendes, consultora)
**Referência:** relatório "Leads Semanais" — `00O4z0000057ssKEAQ` (link na demanda)

## 1. Contexto de negócio

Existe um relatório agendado chamado "Leads Semanais" que envia a informação de leads
para uma lista de usuários do Salesforce. Um desses usuários, Fabio Soto, não deve mais
receber esse envio. A consultora pede (a) a remoção dele da lista de destinatários e
(b) um mapeamento de quem recebe hoje o relatório, para que a equipe saiba o estado atual
antes e depois da mudança.

Não há no material nenhum motivo de negócio explícito (por exemplo, desligamento do
usuário, troca de responsável pelo comercial, ruído de e-mail). Isso não impede a análise,
mas o motivo registrado ajuda a validar o escopo (ver "O que a demanda NÃO diz").

## 2. Objetivo

1. Fabio Soto deixa de receber o relatório "Leads Semanais" agendado.
2. Fica registrado, em artefato do projeto, a lista atual de destinatários do relatório
   (somente papel/perfil e contagem, sem dado pessoal — ver regra 4).

## 3. Regras de negócio

- **RN1.** A remoção se aplica somente à assinatura/destinatário de Fabio Soto neste
  relatório. Os demais destinatários e a própria existência do relatório permanecem
  inalterados. (Hipótese de leitura — ver título vs. corpo abaixo.)
- **RN2.** A alteração é uma configuração de agendamento/compartilhamento do relatório na
  org. Não envolve código, nem alteração de metadado de campo, objeto ou Flow.
- **RN3.** O mapeamento de destinatários é uma leitura: não altera nenhum destinatário,
  nenhum agendamento e nenhum usuário.
- **RN4 (LGPD, guardrail #2).** O artefato de mapeamento não pode conter e-mail, nome
  completo de terceiros ou qualquer identificador pessoal. Registrar contagem total e, por
  destinatário, apenas o perfil/papel (ex.: "Vendas — 3 destinatários"). Os nomes ficam
  na org, não no repositório.
- **RN5 (guardrail #1).** Esta demanda não pode ser executada pelo agente em produção.
  Ver premissa P1: o relatório que o link aponta pode estar em produção.

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo assumem a leitura de RN1 (remoção de um destinatário, sem desabilitar o
relatório). Se a leitura for outra, este bloco é reescrito antes do design.

```gherkin
Funcionalidade: Remover Fabio Soto dos destinatários do relatório "Leads Semanais"

  Cenário: Fabio Soto deixa de estar entre os destinatários do agendamento
    Dado que o relatório "Leads Semanais" (Id 00O4z0000057ssKEAQ) tem agendamento ativo
    E que o usuário "Fabio Soto" está na lista de destinatários antes da mudança
    Quando a alteração for aplicada no ambiente indicado pelo humano
    Então a lista de destinatários do agendamento não contém mais o usuário "Fabio Soto"

  Cenário: Os demais destinatários permanecem inalterados
    Dado que a lista de destinatários foi registrada antes da alteração
    Quando a alteração for aplicada
    Então a lista de destinatários depois da alteração é igual à anterior, menos "Fabio Soto"

  Cenário: O relatório continua existindo e agendado para os demais
    Dado que a alteração foi aplicada
    Então o relatório "Leads Semanais" continua existindo, com o mesmo Id
    E o agendamento continua ativo para os destinatários restantes

  Cenário: Mapeamento dos destinatários atuais é registrado sem dado pessoal
    Dado que o relatório "Leads Semanais" é consultado somente para leitura
    Quando o mapeamento for gerado
    Então o artefato registra a quantidade total de destinatários
    E registra, por destinatário, apenas o perfil ou papel
    E não contém e-mail, telefone ou nome completo de pessoas

  Cenário: Nenhum dado de produção é alterado pelo agente
    Dado que a demanda está no pipeline de agentes
    Quando qualquer etapa for executada
    Então nenhuma escrita é feita em org de produção
    E a alteração em produção, se houver, é registrada como ação humana no card
```

**Testabilidade:** os cenários 1 a 3 são verificáveis comparando a lista antes e depois
(registrada no mapeamento). O cenário 4 é verificável por inspeção do artefato (sem regex de
e-mail/telefone). O cenário 5 é verificável pelo gate e pelo log de sessões.

## 5. O que a demanda NÃO diz (precisa ser respondido antes do design)

1. **Título e corpo divergem.** O título diz "Desabilitar relatório - Leads Semanais"; o
   corpo pede só para retirar **um usuário** dos destinatários. Desabilitar o relatório
   inteiro afetaria todos os destinatários. Qual é o pedido?
2. **Ambiente.** O link é `agilitynetworks.lightning.force.com`. Não está dito se é
   produção ou sandbox. Se for produção, a alteração não pode ser feita pela esteira de
   agentes (guardrail #1): vira ação humana com registro no card.
3. **Quem é "Fabio Soto".** Não há Id de usuário nem indicação de qual dos possíveis
   usuários com esse nome (homônimos, usuário inativo, duplicado). Precisamos do Id ou
   do username.
4. **Motivo e prazo.** Por que ele deve sair (desligamento, troca de função, ruído)? Há
   prazo — a próxima rodada semanal já deve sair sem ele?
5. **Quem decide a lista final.** O mapeamento é só para ciência, ou alguém vai revisar e
   pedir outras remoções/adições depois dele?
6. **Mapeamento: formato e destino.** Quem consome o mapeamento? É para o card no Squad OS,
   para um arquivo no repositório (sem dado pessoal, conforme RN4) ou só para a própria
   consultora? Isso muda o que pode ser escrito.
7. **Mudança de quem administra.** Quem tem permissão para editar a assinatura do
   relatório (dono do relatório, admin, ou o próprio usuário)? Se só o dono pode, a
   alteração precisa dele.
8. **Outras pessoas afetadas.** Algum destinatário depende de Fabio Soto (ex.: encaminhamento
   manual) e perderia a informação indiretamente?
9. **Rollback.** Se a remoção for um erro, como o usuário volta à lista? Basta reinscrever
   manualmente, ou há histórico a preservar?

## 6. Premissas a validar

Todas pendentes. Nenhuma foi confirmada na org (não há conexão `sf` neste ambiente).

- **P1 — Ambiente (pendente).** Assumido que o relatório está em produção do cliente. Isso
  define que a execução é humana, não do agente. Confirmar com a consultora.
- **P2 — Leitura do pedido (pendente).** Assumido que o pedido é remover um destinatário,
  não desabilitar o relatório. Confirmar (ver seção 5, item 1).
- **P3 — Identidade do usuário (pendente).** Assumido que existe exatamente um usuário ativo
  "Fabio Soto" na org e que é o que está na lista de destinatários. Confirmar via `sf` no
  recon (Id do usuário e status ativo/inativo).
- **P4 — Mecanismo (pendente).** Assumido que a lista de destinatários é uma assinatura de
  relatório agendado, gerenciável pelo dono do relatório ou por admin. Não confirmado como
  o Salesforce expõe isso para este caso; o recon precisa verificar a forma exata na org
  (ex.: assinaturas do próprio relatório ou agendamento de relatório).
- **P5 — Estado atual (pendente).** Não sabemos quantos e quais usuários recebem o
  relatório hoje. O mapeamento é a primeira entrega do recon; nenhum nome foi inventado aqui.
- **P6 — Relatório existe e está ativo (pendente).** Assumido que o Id `00O4z0000057ssKEAQ`
  corresponde ao relatório "Leads Semanais" e que o agendamento está ativo. Confirmar.

## 7. Complexidade

**P (pequena).** Uma alteração de configuração em um relatório, sem código, sem objeto novo
e sem integração a ajustar; o mapeamento é leitura. O risco que pesa não é técnico, é de
ambiente e de escopo (P1 e P2): se for produção ou se o pedido for desabilitar o relatório
inteiro, o tratamento muda, mas a complexidade técnica não.

## 8. Estimativa de esforço

**Estimativa de esforço:** 1–2 h

Premissas que mais pesam na faixa:
- Confirmação do ambiente e do escopo (P1, P2) com a consultora — se o pedido for outro,
  a faixa muda.
- Identificação do usuário e do mecanismo de agendamento na org (P3, P4) — pode exigir
  acesso de admin para ver a lista atual.
- Mapeamento de destinatários feito uma vez, sem integração nem limpeza de dado.
- Sem alteração de código, sem deploy e sem homologação em QA além de conferência do
  antes/depois. Se o pedido crescer para mudança de regra do relatório, esta faixa não vale.

## 9. Próximos passos

1. Consultora responde a seção 5 (principalmente itens 1, 2 e 3).
2. Aprovação humana desta análise no card.
3. Etapa `org-recon` (skill) confirma P3 a P6 via `sf` contra a org correta e registra o
   mapeamento em `02-recon.md` no formato da RN4.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
