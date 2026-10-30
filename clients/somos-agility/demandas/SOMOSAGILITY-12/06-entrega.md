# 06 — Entrega: SOMOSAGILITY-12

**Agente:** `release` · **Data:** 2026-10-30
**Status desta entrega: CONCLUÍDA — deploy real realizado em `sbx-somos-agility-qa`.**

Esta demanda já teve uma tentativa de entrega anterior (2026-10-28) registrada como
**bloqueada** em `release-pendente.md`, porque `sbx-somos-agility-qa` nunca tinha sido
conectada à esteira. Nesta sessão a org já aparece conectada (`sf org list`), confirmada como
sandbox de verdade (`SELECT IsSandbox FROM Organization` → `true`, org `Agility`,
`agilitynetworks--aw.sandbox.my.salesforce.com`), e o deploy real foi executado e confirmado
nesta sessão — não é uma repetição mecânica da sessão anterior.

## O que foi pedido

Tornar os campos **Classificação Gerencial** (`Classificacao_Gerencial__c`) e **Denominação do
Treinamento** (`Denomina_o_do_Treinamento__c`), no objeto `JOB_de_Solicitacao_de_Treinamentos__c`,
obrigatórios no fluxo de aprovação ("Job de ST Geral - v2"), bloqueando a gravação com a
mensagem "Favor preencher os campos antes de enviar para aprovação" quando algum dos dois
estiver vazio, conforme `01-analise.md` e `comentarios-do-card.md` (respostas D-01 a D-08).

## O que foi construído (branch `feature/SOMOSAGILITY-12`)

| Componente | API Name | O que faz |
|---|---|---|
| Validation Rule | `JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias` | Bloqueia o save quando `Classificacao_Gerencial__c` ou `Denomina_o_do_Treinamento__c` estão vazios, com exceção para registros criados antes de 2026-10-21T00:00:00 (`AND(OR(ISNEW(), CreatedDate >= 2026-10-21 00:00:00), OR(ISBLANK(TEXT(Classificacao_Gerencial__c)), ISBLANK(Denomina_o_do_Treinamento__c)))`), `active = true` |
| Permission Set | `PS_JST_ClassificacaoDenominacao` | Concede FLS de edição nos dois campos para os perfis que criam/editam o JOB sem isso hoje — mitiga o risco R-01 (severidade Alta, `03-design.md`): sem ele, usuário sem FLS fica impedido de preencher os campos e, portanto, de salvar um JOB novo |
| Layout | `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos` | Adiciona os dois campos à seção "Dados Gerais", após `Centro_de_Custo__c`, como `Edit` (não `Required` pelo layout — a obrigatoriedade é inteiramente pela validation rule) |

Pacote com exatamente esses 3 componentes, nenhum a mais, em
`clients/somos-agility/manifest/package.xml` — os mesmos aprovados na homologação
(`gates.md`, Juliana Mendes, 2026-10-30T14:40:21Z, sobre `05-testes.md`).

## Como funciona (fluxo do processo)

1. Usuário cria ou edita um `JOB_de_Solicitacao_de_Treinamentos__c`.
2. Se o registro foi criado a partir de 2026-10-21T00:00:00 e qualquer um dos dois campos está
   vazio, **qualquer save** é bloqueado com a mensagem "Favor preencher os campos antes de
   enviar para aprovação" — não só no clique de "Submit for Approval" (ver divergência D-03
   abaixo).
3. Registros criados antes de 2026-10-21T00:00:00 nunca são bloqueados por esta regra, mesmo
   com os campos vazios — "ficam como estão" (`comentarios-do-card.md`, resposta D-05).
4. Usuário sem o Permission Set `PS_JST_ClassificacaoDenominacao` atribuído não enxerga os
   campos como editáveis — precisa do Permission Set para conseguir preencher e salvar um JOB
   novo.

## Divergência conhecida entre o pedido e o construído (D-03)

`01-analise.md` definiu os critérios de aceite (CA-01, CA-02, CA-03, CA-05) assumindo que a
obrigatoriedade valeria **só no envio para aprovação**, não em qualquer salvamento. Isso não é
possível de forma puramente declarativa sem Apex/Flow sensível ao novo valor de status
(`03-design.md`, seção 1); a alternativa de código foi descartada por custo (seção 6 do
design). A regra entregue bloqueia **qualquer save** de registro novo, não só a submissão.

`05-testes.md` (verificação estática da fórmula contra os critérios de aceite literais)
confirma que, como estão escritos hoje, **CA-01, CA-02, CA-03 e CA-05 não passam** — é
consequência direta e já documentada da escolha de design, não um defeito de implementação.
A homologação de 2026-10-30 (Juliana Mendes, `gates.md`) foi registrada sobre esse mesmo
`05-testes.md`, com o comentário do cliente "Testado em AW, Podemos seguir para produção"
(`comentarios-do-card.md`, 2026-10-30 14:35) — "AW" bate com o sufixo da instância desta
sandbox de QA (alias `sbx-somos-agility-qa`). Entendo a divergência como aceita pelo cliente,
mas registro aqui para quem for dar manutenção não interpretar como regressão.

Também fora do escopo (pedido pelo cliente após o gate de design, `comentarios-do-card.md`,
2026-10-23): estender a mesma obrigatoriedade ao objeto `JOB_de_Solicita_o_de_Investimento__c`.
`03-design.md` seção 7 exclui esse objeto explicitamente. Nenhum componente desta demanda o
toca — precisa virar outra demanda.

## Deploy — resultado

### Dry-run (pré-requisito)

```
sf project deploy start --dry-run --manifest manifest/package.xml --target-org sbx-somos-agility-qa
```
- Deploy ID: `0AfHa00000E7A10KAF`
- Status: `Succeeded`, `numberComponentErrors: 0`, `numberComponentsDeployed: 3/3`
- Data: 2026-10-30T14:44:56Z–14:45:00Z

### Deploy real

```
sf project deploy start --manifest manifest/package.xml --target-org sbx-somos-agility-qa
```
- **Deploy ID: `0AfHa00000E78SFKAZ`**
- **Status: `Succeeded`**, `checkOnly: false`, `numberComponentErrors: 0`,
  `numberComponentsDeployed: 3/3`
- **Org de destino:** `sbx-somos-agility-qa` (org `Agility`, Enterprise Edition, sandbox
  confirmada via `Organization.IsSandbox = true`; instância
  `agilitynetworks--aw.sandbox.my.salesforce.com`)
- **Timestamp:** iniciado 2026-10-30T14:45:06Z, concluído 2026-10-30T14:45:18Z
- Componentes confirmados implantados (IDs retornados pela API de Metadata):
  - `PermissionSet` `PS_JST_ClassificacaoDenominacao` — `created: true`, id `0PSHa0000028VGnOAM`
  - `Layout` `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de
    Treinamentos` — `changed: true`, id `00h5000000BZ8TPAA1`
  - `ValidationRule` `JST_Classif_Denominacao_Obrigatorias` — `created: true`, id
    `03dHa000009laajIAA`
- Sem testes Apex rodados (`runTestsEnabled: false`) — não se aplica: não há classe Apex nesta
  demanda (`04-plano-build.md`, seção 2).

## Plano de rollback

| Componente | Rollback | Como |
|---|---|---|
| `ValidationRule JST_Classif_Denominacao_Obrigatorias` | Desativar sem apagar | Redeploy do mesmo componente com `<active>false</active>` contra `sbx-somos-agility-qa` |
| `Layout ...Treinamentos` | Reverter para o estado anterior | Redeploy do backup já existente em `demandas/SOMOSAGILITY-12/layout-job-original-backup.xml` (retirado da org real antes da edição) |
| `PermissionSet PS_JST_ClassificacaoDenominacao` | Revogar o efeito | Remover qualquer atribuição a usuário (ver passo pós-deploy abaixo — nenhuma atribuição foi feita por este agente); o componente pode permanecer na org sem efeito se não houver atribuição ativa |

**Ordem de rollback** (inversa à de deploy): ValidationRule (desativar) → Layout (reverter) →
PermissionSet (remover atribuições, se houver, antes de considerar remover o componente).

**Quem executa:** humano com acesso a `sbx-somos-agility-qa` (ou agente `release` numa sessão
futura, nunca em produção — guardrail #1). Nenhum rollback foi necessário nesta sessão; o
deploy foi bem-sucedido.

## Passos manuais pós-deploy (pendentes, não executados por este agente)

1. **Atribuir `PS_JST_ClassificacaoDenominacao`** aos usuários dos perfis listados em
   `02-recon.md` seção 6 que criam/editam o JOB sem FLS de edição nos dois campos hoje: `PO DT`,
   `Marketing`, `Diretor DT`, `PMO`, `Diretor de Marketing`, `Diretor Financeiro`, `Gerente de
   Suporte DC`, `Gerente de Suporte SEG`, `Diretor de Projetos`, `Service Delivery`, `Service
   Manager`, `Gerente de Suporte EA` (sem acesso) e `PO EA` (só leitura). `02-recon.md` contava
   até 5 usuários ativos nesses perfis na sandbox de dev (até 3 sem mitigação via
   `jobsAprovacao`) — o número real em QA/produção não foi confirmado por este agente
   (guardrail #1: não há consulta de dado de usuário real de produção). Tarefa do admin do
   cliente, não do agente.
2. **Confirmar/ajustar a data de corte** hardcoded na Validation Rule
   (`2026-10-21 00:00:00`, data do build) para a data real de go-live em produção, se for
   diferente — hoje é fixa, não configurável por Custom Metadata/Label; mudança futura exige
   novo deploy.
3. **Validar com o consultor o posicionamento dos campos no layout** (seção "Dados Gerais",
   após `Centro_de_Custo__c`) — decisão de UI tomada sem consultor disponível durante o build
   (`04-plano-build.md`, seção 9, item 2).
4. **Verificar FLS efetiva na org** pós-deploy (modo de falha comum: deploy passa, campo
   continua invisível para o perfil mesmo com o Permission Set atribuído, se houver
   Field-Level Security conflitante no perfil base).
5. **Executar o roteiro de QA ainda pendente** em `05-testes.md` ("Roteiro para execução humana
   em sbx-somos-agility-qa") — o cliente já homologou e autorizou seguir ("Testado em AW"), mas
   os casos ali (CA-04, CA-05/D-03, CA-06, R-01, R-02, mensagem de erro, layout) continuam
   listados como roteiro formal para quem assumir a manutenção, inclusive a observação sobre
   falta de massa de dados legados (`CreatedDate` anterior ao corte) para testar CA-06/R-02.
6. **Reconfirmar a divergência D-03** com o cliente antes de ir para produção, já que a
   homologação aconteceu sobre `05-testes.md` com a falha de CA-01/02/03/05 documentada, não
   escondida.

## Limitações conhecidas e dívida técnica

- Regra bloqueia qualquer save de registro novo com campo vazio, não só a submissão (D-03) —
  `01-analise.md` deveria ser atualizado para refletir isso, já que a divergência foi aceita.
- Não há massa de dados de JOB legado (`CreatedDate` anterior ao corte) em nenhuma sandbox
  conhecida para testar CA-06/R-02 de fato — pendente de confirmação com o cliente.
- Pedido de escopo novo do cliente (`comentarios-do-card.md`, 2026-10-23): estender a mesma
  obrigatoriedade a `JOB_de_Solicita_o_de_Investimento__c`. Fora do escopo desta demanda — vira
  outra demanda.
- Data de corte fixa (hardcoded) na fórmula, não configurável sem novo deploy.
- Volume real de JOBs legados com campos vazios em produção é desconhecido
  (`02-recon.md` seção 7); a sandbox de dev tinha 0 registros no objeto.

## Rastreabilidade

- **Demanda:** SOMOSAGILITY-12
- **Branch:** `feature/SOMOSAGILITY-12`
- **Cliente:** somos-agility
- **Org de destino:** `sbx-somos-agility-qa` (sandbox, confirmada via `Organization.IsSandbox`)
- **Deploy validate (dry-run, QA):** `0AfHa00000E7A10KAF`, `Succeeded`, 2026-10-30T14:44:56Z
- **Deploy real (QA):** `0AfHa00000E78SFKAZ`, `Succeeded`, 2026-10-30T14:45:06Z–14:45:18Z
- **Deploy validate anterior (dev, check-only, histórico):** `0AfHa00000Dzj8nKAB`,
  `Succeeded` (`04-plano-build.md`) — não é o deploy desta entrega, mantido só como registro.
- **Gate de homologação:** aprovado por Juliana Mendes em 2026-10-30T14:40:21Z (`gates.md`),
  sobre `05-testes.md`.
- **Histórico de bloqueio anterior:** ver `release-pendente.md` (sessão de 2026-10-28, bloqueada
  por `sbx-somos-agility-qa` ainda não estar conectada) e o histórico em `status.yaml`
  (reversão por Leonardo Barbosa em 2026-10-29 e 2026-10-30, PR #121).

## Conclusão

Deploy real concluído com sucesso em `sbx-somos-agility-qa` — os 3 componentes aprovados na
homologação (`PS_JST_ClassificacaoDenominacao`, o layout alterado e a validation rule
`JST_Classif_Denominacao_Obrigatorias`) estão implantados e ativos nessa sandbox. Os passos
manuais pós-deploy acima (atribuição do Permission Set, confirmação de data de corte, roteiro
de QA formal) continuam pendentes de execução humana. Esta entrega cobre o escopo aprovado;
deploy em produção permanece fora do alcance deste agente (guardrail #1) — exige janela,
plano de rollback (acima) e aprovação humana registrada, a cargo de quem decidir avançar para
produção.
