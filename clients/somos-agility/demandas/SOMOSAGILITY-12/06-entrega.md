# 06 — Entrega: SOMOSAGILITY-12

**Agente:** `release`/`doc` · **Data:** 2026-10-28
**Status desta entrega: BLOQUEADA — deploy ainda não realizado em nenhuma sandbox de QA ou UAT.**
Este documento registra o que está pronto e o que falta, não uma entrega concluída. Não há
deploy ID porque nenhum deploy real aconteceu.

## O que foi pedido

Tornar os campos **Classificação Gerencial** e **Denominação do Treinamento**, no objeto
`JOB_de_Solicitacao_de_Treinamentos__c`, obrigatórios no envio para aprovação (fluxo "Job de
ST Geral - v2"), bloqueando o envio com a mensagem "Favor preencher os campos antes de enviar
para aprovação" quando algum dos dois estiver vazio.

## O que foi construído (metadata em `force-app`, no branch `feature/SOMOSAGILITY-12`)

| Componente | API Name | O que faz |
|---|---|---|
| Validation Rule | `JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias` | Bloqueia o save/submit quando `Classificacao_Gerencial__c` ou `Denomina_o_do_Treinamento__c` estão vazios, com exceção para registros criados antes de 2026-10-21 (`OR(ISNEW(), CreatedDate >= 2026-10-21T00:00:00Z)`) |
| Permission Set | `PS_JST_ClassificacaoDenominacao` | Concede FLS de edição nos dois campos para os perfis que criam/editam o JOB — necessário porque, sem ele, usuários sem FLS ficam impedidos de preencher os campos e portanto de salvar um JOB novo (risco R-01, severidade Alta, ver `03-design.md`) |
| Layout | `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos` | Adiciona os dois campos à seção "Dados Gerais", após `Centro_de_Custo__c`, como `Edit` (não `Required` pelo layout — a obrigatoriedade é inteiramente pela validation rule) |

Pacote mínimo com exatamente esses 3 componentes em `clients/somos-agility/manifest/package.xml`.
Ordem de deploy: PermissionSet → Layout → ValidationRule (`04-plano-build.md`).

## Como funciona (fluxo do processo)

1. Usuário cria ou edita um `JOB_de_Solicitacao_de_Treinamentos__c`.
2. Se o registro foi criado a partir de 2026-10-21 e qualquer um dos dois campos está vazio,
   **qualquer save** é bloqueado com a mensagem "Favor preencher os campos antes de enviar para
   aprovação" — não só no clique de "Submit for Approval".
3. Registros criados antes de 2026-10-21 (`CreatedDate < 2026-10-21`) nunca são bloqueados por
   esta regra, mesmo com os campos vazios — ficam como estavam (decisão registrada em
   `comentarios-do-card.md`, resposta D-05: "ficam como estão").
4. Usuário sem o Permission Set `PS_JST_ClassificacaoDenominacao` atribuído não enxerga os
   campos como editáveis — precisa do Permission Set para conseguir preencher e salvar.

## Divergência conhecida entre o que foi pedido e o que foi construído (D-03)

`01-analise.md` definia os critérios de aceite (CA-01, CA-02, CA-03, CA-05) assumindo que a
obrigatoriedade valeria **só no envio para aprovação**, não em qualquer salvamento. Tecnicamente
isso não é possível de forma puramente declarativa sem Apex/Flow sensível ao novo valor de
status (`03-design.md`, seção 1) — a alternativa de código foi descartada por custo (seção 6 do
design). A regra entregue bloqueia **qualquer save** de registro novo, não só a submissão.

`05-testes.md` (verificação estática, sem depender de sandbox) confirma que, como estão
escritos hoje, **CA-01, CA-02, CA-03 e CA-05 não passam** — é consequência direta e já
documentada dessa escolha de design, não um defeito de implementação. A homologação
(`gates.md`, Carlos Sordi, 2026-10-28) foi registrada sobre `05-testes.md` já com essa
divergência relatada; entendo como aceita, mas fica registrado aqui para quem for dar
manutenção não achar que é uma regressão.

## Por que esta entrega está bloqueada (não consegui medir/entregar isto)

- **Deploy real: não executado em nenhuma sandbox.** `sbx-somos-agility-qa` nunca foi
  conectada a esta esteira — confirmado com `sf org list` nesta sessão: só a sandbox de dev
  aparece conectada. Tentei `sf project deploy start --dry-run --manifest manifest/package.xml
  --target-org sbx-somos-agility-qa`; falhou com `NamedOrgNotFoundError` (org/alias não
  autenticado). Não usei a sandbox de dev como substituta — guardrail #1 exige que `release`
  rode contra QA, nunca contra dev.
- **Nenhum teste de UI foi executado** (nem por este agente nem pelo `qa` anteriormente) pelo
  mesmo motivo: sandbox de QA inacessível, e os componentes nunca foram deployados de fato em
  lugar nenhum para serem testados na tela. O que existe é só verificação estática da fórmula
  contra os critérios de aceite (`05-testes.md`).
- **Cobertura de teste Apex: não se aplica.** Não há classe Apex nesta demanda — só
  ValidationRule, PermissionSet e Layout (`04-plano-build.md`, seção 2).
- **Deploy ID: não existe.** O único resultado de deploy desta demanda é um `deploy validate`
  (check-only) contra **dev**, deployId `0AfHa00000Dzj8nKAB`, `Succeeded` (`04-plano-build.md`
  seção 8.1) — não é um deploy real, e não é em QA.

## Plano de rollback (preparado, não executado — nenhum deploy aconteceu)

| Componente | Rollback | Como |
|---|---|---|
| `ValidationRule JST_Classif_Denominacao_Obrigatorias` | Desativar sem apagar | Redeploy do mesmo componente com `<active>false</active>` |
| `Layout ...Treinamentos` | Reverter para o estado anterior | Redeploy do backup em `layout-job-original-backup.xml` (retirado da org real antes da edição) |
| `PermissionSet PS_JST_ClassificacaoDenominacao` | Revogar o efeito | Remover qualquer atribuição a usuário (nenhuma foi feita ainda); o componente pode ficar na org sem efeito se não houver atribuição ativa |

Ordem de rollback inversa à de deploy: ValidationRule (desativar) → Layout (reverter) →
PermissionSet (remover atribuições, se houver).

## Configuração pós-deploy (quando o deploy real acontecer)

1. Atribuir `PS_JST_ClassificacaoDenominacao` aos usuários dos perfis que criam/editam o JOB
   sem FLS hoje nos dois campos (13 perfis listados em `02-recon.md`, seção 6) — tarefa do
   admin do cliente.
2. Confirmar/ajustar a data de corte hardcoded na Validation Rule (`2026-10-21T00:00:00Z`,
   data do build) para a data real de go-live, se for diferente.
3. Validar com o consultor o posicionamento dos campos no layout — decisão de UI tomada sem
   consultor disponível durante o build (`04-plano-build.md`, seção 9, item 2).
4. Verificar FLS efetiva na org pós-deploy (modo de falha comum: deploy passa, campo continua
   invisível para o perfil).
5. Executar o roteiro de QA pendente em `05-testes.md` ("Roteiro para execução humana em
   sbx-somos-agility-qa") — nenhum caso foi executado ainda.

## Limitações conhecidas e dívida técnica

- Regra bloqueia qualquer save de registro novo com campo vazio, não só a submissão (D-03,
  acima) — `01-analise.md` precisa ser atualizado para refletir isso caso a divergência seja
  aceita como está.
- Não há massa de dados de JOB legado (`CreatedDate` anterior ao corte) em nenhuma sandbox
  conhecida para testar CA-06/R-02 — pendente de confirmação com o cliente.
- Pedido de escopo novo do cliente (`comentarios-do-card.md`, 2026-10-23): estender a mesma
  obrigatoriedade ao objeto `JOB_de_Solicita_o_de_Investimento__c`. Fora do escopo desta
  demanda (`03-design.md`, seção 7) — precisa virar outra demanda, não foi tratado aqui.
- Data de corte da regra é fixa (hardcoded), não configurável por Custom Metadata/Label — uma
  mudança futura de data exige novo deploy.

## Rastreabilidade

- **Demanda:** SOMOSAGILITY-12
- **Branch:** `feature/SOMOSAGILITY-12`
- **PR:** não verificado nesta sessão (sem acesso a `gh` autenticado neste ambiente) — conferir
  manualmente no GitHub antes de considerar esta demanda pronta para merge.
- **Deploy ID (QA ou UAT):** nenhum — deploy real ainda não ocorreu.
- **Deploy validate (dev, check-only):** `0AfHa00000Dzj8nKAB`, `Succeeded` (`04-plano-build.md`).
- **Gate de homologação:** aprovado por Carlos Sordi em 2026-10-28T16:54:20Z (`gates.md`),
  sobre `05-testes.md`.
- **Bloqueio atual:** `sbx-somos-agility-qa` não conectada à esteira — ver
  `release-pendente.md` para o relatório completo desta sessão e o que falta para destravar.

## Conclusão

Build e pacote estão prontos e revisados. **Esta demanda não pode ser considerada entregue**
até que `sbx-somos-agility-qa` seja conectada (skill `conectar-ambiente`) e o deploy real
ocorra nessa sandbox, seguido da execução do roteiro de QA pendente em `05-testes.md`. Até lá,
o trabalho restante é de infraestrutura/conexão, não de construção.
