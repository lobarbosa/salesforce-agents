> **RESOLVIDO em 2026-10-30.** `sbx-somos-agility-qa` foi conectada à esteira depois desta
> sessão (achado de 2026-10-28 abaixo). O deploy real foi executado com sucesso nessa sandbox
> nesta data — deploy ID `0AfHa00000E78SFKAZ`, detalhes completos em `06-entrega.md`. Este
> arquivo é mantido como histórico do bloqueio, não como situação atual.

# Release pendente — SOMOSAGILITY-12

**Agente:** `release` · **Data:** 2026-10-28
**Não é `06-entrega.md` de propósito.** Esse artefato marca o fim da etapa `release` e libera a
transição automática para `entregue` (terminal) — criá-lo aqui seria declarar entregue uma
demanda que não foi deployada em lugar nenhum. Este arquivo existe só para não perder o
achado abaixo entre sessões (guardrail #5 — estado em disco).

## Situação

Esta demanda está **bloqueada para release**. `sbx-somos-agility-qa` nunca foi conectada a
esta esteira. Confirmado nesta sessão com `sf org list`:

```
   Type     Alias                  Org Id              Status
---------------------------------------------------------------
   Sandbox  sbx-somos-agility-dev  00DHa0000070wxfMAA  Connected
```

Só `sbx-somos-agility-dev` aparece. Isso repete, na etapa `release`, o mesmo achado que
`05-testes.md` (seção "Ambiente desta sessão") já tinha reportado na etapa `qa`: a sandbox de
QA nunca esteve conectada nesta esteira, e nenhum componente desta demanda foi deployado de
fato em nenhuma sandbox até hoje — só `sf project deploy validate` (check-only) contra **dev**
(`04-plano-build.md` seção 8.1, deployId `0AfHa00000Dzj8nKAB`, `Succeeded`).

Conforme guardrail #1 (a etapa `release` roda contra QA, nunca contra dev como substituta) e
a instrução explícita desta sessão, **não caí para `sbx-somos-agility-dev` como substituto**
mesmo a própria CLI `sf` tendo sugerido isso ao falhar:

```
$ sf project deploy start --dry-run --manifest manifest/package.xml --target-org sbx-somos-agility-qa
Error (NamedOrgNotFoundError): Parsing --target-org
	No authorization information found for sbx-somos-agility-qa.
It looks like you mistyped the username or alias. Did you mean "sbx-somos-agility-dev"?
```

Nenhum deploy, real ou dry-run, foi executado em nenhuma org nesta sessão.

## O que já está pronto para quando a conexão existir

- `manifest/package.xml` — gerado nesta sessão, com exatamente os 3 componentes aprovados na
  homologação (`gates.md`, Carlos Sordi, 2026-10-28T16:54:20Z), nenhum a mais:
  - `PermissionSet`: `PS_JST_ClassificacaoDenominacao`
  - `Layout`: `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos`
  - `ValidationRule`: `JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias`
- Ordem de deploy (de `04-plano-build.md`): PermissionSet → Layout → ValidationRule.

## Plano de rollback (preparado, não executado)

| Componente | Rollback | Como |
|---|---|---|
| `ValidationRule JST_Classif_Denominacao_Obrigatorias` | Desativar sem apagar | Redeploy do mesmo componente com `<active>false</active>` |
| `Layout ...Treinamentos` | Reverter para o estado anterior | Redeploy do backup já existente em `layout-job-original-backup.xml` (retirado da org real antes da edição) |
| `PermissionSet PS_JST_ClassificacaoDenominacao` | Revogar o efeito | Remover qualquer atribuição a usuário (nenhuma foi feita ainda); o componente pode permanecer na org sem efeito se não houver atribuição ativa |

Ordem de rollback inversa à de deploy: ValidationRule (desativar) → Layout (reverter) →
PermissionSet (remover atribuições, se houver).

## Passos manuais pós-deploy (quando o deploy real acontecer)

1. Atribuir `PS_JST_ClassificacaoDenominacao` aos usuários dos 13 perfis listados em
   `02-recon.md` seção 6 que criam/editam o JOB sem FLS nos dois campos — tarefa do admin do
   cliente, não do agente.
2. Confirmar/ajustar a data de corte hardcoded na `ValidationRule`
   (`2026-10-21 00:00:00`, data do build) para a data real de go-live, se for diferente.
3. Validar com o consultor o posicionamento dos dois campos no layout (seção "Dados Gerais",
   coluna 2, após `Centro_de_Custo__c`) — decisão de UI tomada sem consultor disponível no build.
4. Verificar FLS efetiva na org pós-deploy.
5. Executar o roteiro de QA pendente em `05-testes.md` (seção "Roteiro para execução humana em
   sbx-somos-agility-qa") — nenhum caso foi executado ainda, porque a sandbox nunca esteve
   conectada nem os componentes foram deployados de fato em lugar nenhum.
6. Reconfirmar a divergência D-03 (CA-01, CA-02, CA-03, CA-05 como escritos hoje não passam,
   por decisão consciente do design) — `gates.md` já registra a homologação de Carlos Sordi
   sobre `05-testes.md`, então trato como aceita, mas sinalizo para dupla checagem já que não é
   papel deste agente reinterpretar o gate.

## O que precisa acontecer para destravar

Um humano conectar `sbx-somos-agility-qa` a esta esteira (skill `conectar-ambiente` —
Connected App JWT, GitHub Environment `somos-agility-qa`, secrets, teste de conexão). Depois
disso, a etapa `release` precisa rodar de novo: dry-run contra QA, e só então deploy real.
`06-entrega.md` só deve ser escrito depois que o deploy real tiver de fato ocorrido em
`sbx-somos-agility-qa`.

**Status desta demanda não foi alterado por esta sessão** — permanece `release` em
`status.yaml`, porque não houve o que avançar.
