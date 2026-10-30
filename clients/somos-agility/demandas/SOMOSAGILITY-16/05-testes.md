# SOMOSAGILITY-16 — Testes (qa)

**Cliente:** Somos Agility
**Demanda:** "Desabilitar relatório - Leads Semanais" (sustentação)
**Insumos:** `01-analise.md` (critérios de aceite Gherkin), `02-recon.md`, `03-design.md`,
`04-plano-build.md`, `comentarios-do-card.md`, `gates.md`, `status.yaml`
**Org desta sessão:** `sbx-somos-agility-dev` (não há `sbx-somos-agility-qa` nem produção
conectadas). Nenhuma ferramenta de browser (`qa_browser_*`) foi usada nesta etapa — não há
tela, Flow, campo ou layout construído para testar (ver `03-design.md` §1 e §3: zero
componentes em `force-app/`). Nenhum `sf apex run test` nem deploy foi executado — não há
Apex nem pacote nesta demanda.

---

## Achado principal — bloqueio, não aprovação

**Esta etapa não pode homologar nada porque a mudança pedida ainda não foi executada.**
Toda a entrega técnica desta demanda é um runbook de execução manual em produção
(`04-plano-build.md`), e o próprio runbook é explícito: *"Ninguém deve executar este
runbook em produção antes de D1, D2 e D3 aparecerem respondidas no card."*

Conferi `comentarios-do-card.md` nesta data (2026-10-30) linha a linha. Ele registra:

1. Aprovação da estimativa (2026-10-27)
2. Aprovação do gate de análise (2026-10-27)
3. Aprovação do gate de design (2026-10-28)
4. Aprovação do gate de build (2026-10-30)

**Nenhuma resposta a D1, D2 ou D3 está registrada.** Não há evidência no card de que:

- D1 — o escopo foi confirmado (remover só Fabio Soto × desativar o relatório inteiro);
- D2 — o link é de fato produção, e quem (papel) executou lá;
- D3 — o destino do mapeamento nominal foi decidido.

Isso significa que a demanda **avançou de etapa (build → qa) sem a pré-condição que o
próprio design e o próprio plano de build declararam como bloqueante.** Não é um erro desta
etapa de QA corrigir isso retroativamente fabricando uma resposta ou uma evidência — o
caminho correto agora é sinalizar o bloqueio e não avançar para homologação. Nenhum teste
desta demanda pode ser dado como "passou" porque **a ação que os critérios de aceite
descrevem não aconteceu** (ou, se aconteceu fora do card, não há registro — para a esteira,
é o mesmo que não ter acontecido).

Não tentei suprir essa lacuna: não acessei produção (sem credencial e vedado pelo
guardrail #1), não usei a sandbox dev como substituto (o próprio design, §3, já descartou
essa prática: assinaturas de relatório normalmente não são copiadas em refresh de sandbox e
a cópia não prova nada sobre o estado em produção) e não inventei um resultado de teste.

---

## Casos de teste — derivados dos 5 cenários Gherkin de `01-analise.md` §4

| # | Caso | Passos (conforme o cenário) | Esperado | Obtido | Status |
|---|------|------------------------------|----------|--------|--------|
| 1 | Fabio Soto deixa de estar entre os destinatários do agendamento | Comparar lista de destinatários do relatório "Leads Semanais" (Id `00O4z0000057ssKEAQ`) antes e depois da alteração em produção | Lista "depois" não contém mais "Fabio Soto" | Nenhuma alteração registrada como executada em produção; D1/D2 sem resposta no card | **Bloqueado / não verificável nesta etapa** |
| 2 | Os demais destinatários permanecem inalterados | Comparar lista "antes" e lista "depois", registradas no mapeamento | Lista "depois" = lista "antes" menos "Fabio Soto" | Não há mapeamento "antes"/"depois" registrado em nenhum artefato (depende de D3 e da execução em produção) | **Bloqueado / não verificável nesta etapa** |
| 3 | O relatório continua existindo e agendado para os demais | Após a alteração, conferir Id do relatório e status do agendamento em produção | Relatório mantém o mesmo Id; agendamento ativo para os destinatários restantes | Nenhuma alteração foi aplicada até o momento desta verificação | **Bloqueado / não verificável nesta etapa** |
| 4 | Mapeamento dos destinatários atuais é registrado sem dado pessoal | Inspecionar o artefato de mapeamento (contagem total + perfil/papel, sem e-mail/telefone/nome completo) | Artefato presente e conforme RN4 | Nenhum artefato de mapeamento foi produzido ainda — a seção "Roteiro de verificação" abaixo é o molde a preencher, não um resultado | **Não verificável nesta etapa** (o molde existe; o conteúdo, não) |
| 5 | Nenhum dado de produção é alterado pelo agente | Conferir `gates.md` e os logs de sessão do pipeline | Nenhuma escrita em produção feita por agente; alteração em produção (se houver) registrada como ação humana no card | Confirmado **parcialmente**: nenhuma sessão de agente desta demanda tocou produção (nenhuma credencial de produção esteve disponível em nenhuma etapa, e `02-recon.md`/`03-design.md` documentam essa limitação explicitamente). Mas a segunda metade do critério — "a alteração em produção, se houver, é registrada como ação humana no card" — **ainda não tem o que registrar**, porque não há evidência de que a alteração ocorreu | **Parcialmente verificável: a parte do agente passa; a parte do registro humano está pendente** |

**Nenhum dos 5 cenários pode ser marcado como "passou".** Os cenários 1-4 descrevem o
estado depois de uma execução que não há evidência de ter ocorrido; o cenário 5 é o único
em que a parte sob controle do agente é verificável agora, e essa parte está conforme.

---

## Cobertura adicional pedida pelo método padrão (borda, negativo, permissão, volume)

Não aplicável da forma usual: não há tela, Apex, Flow nem permissão nova criada por esta
demanda para testar (`03-design.md` §4 e §7: nenhum componente, nenhum perfil/permission
set alterado). Os riscos de borda e negativo que existem são os que o próprio design já
levantou em sua seção 9 ("Riscos técnicos") e seção 6 do plano de build ("Parar e escalar"):

- Fabio Soto recebe o relatório via grupo público ou papel (não individualmente) — o
  runbook manda parar e escalar, não prosseguir. Isso só é verificável durante a execução
  real em produção (passo 3 do runbook), não nesta etapa.
- Mais de uma assinatura do mesmo relatório (uma por usuário) — mesma observação.
- Homônimo/duplicidade de "Fabio Soto" em produção — não verificável sem acesso a produção;
  confirmado apenas que não existe homônimo **na sandbox dev** (`02-recon.md` §3), o que não
  garante o mesmo estado em produção.

Nenhum desses pontos pode ser testado nesta sandbox porque nenhum deles depende de metadata
replicável — todos dependem do estado real do agendamento em produção.

---

## Roteiro de verificação — a preencher pelo humano DEPOIS de executar o runbook em produção

Este checklist é o que falta para, no futuro, comparar o resultado real contra os 5
cenários de aceite acima. Deve ser preenchido por quem executar `04-plano-build.md`, e só
depois disso esta demanda pode voltar à etapa de QA para fechamento. **Sem nome, e-mail,
telefone ou qualquer identificador pessoal de destinatário — apenas contagem e
perfil/papel (RN4 / guardrail #2).**

```markdown
### Evidência de execução — SOMOSAGILITY-16

- [ ] D1 respondida no card antes da execução (escopo): ___________________________
- [ ] D2 respondida no card antes da execução (ambiente + executor, por papel):
      ___________________________
- [ ] D3 respondida no card antes da execução (destino do mapeamento nominal):
      ___________________________

- Data/hora da execução: ___________________________
- Papel de quem executou (ex.: "administrador do sistema do cliente"; NUNCA o nome): ___
- Id do relatório confirmado em produção: 00O4z0000057ssKEAQ (sim/não) _______________
- Nome do relatório confirmado em produção: "Leads Semanais" (sim/não) _______________
- Quantas assinaturas/agendamentos do relatório foram encontradas: _____
- Alguma delas tinha Fabio Soto como destinatário via grupo/papel (não individual)?
  (sim/não — se sim, runbook deveria ter sido escalado, não executado) _______________

#### Contagem "antes" (antes da alteração)
- Total de destinatários: _____
- Distribuição por perfil/papel (ex.: "Vendas — 3", "Gerência — 1"): ___________________

#### Ação aplicada
- [ ] 5a — removido só Fabio Soto (padrão)
- [ ] 5b — desativado o agendamento inteiro (só se D1 confirmou esta opção)

#### Contagem "depois" (depois da alteração)
- Total de destinatários: _____
- Distribuição por perfil/papel: ___________________
- Confirmação de que "Fabio Soto" não consta mais entre os destinatários: (sim/não) ____

#### Checagens de não-regressão (cenário 3)
- Relatório ainda existe, mesmo Id: (sim/não) _____
- Agendamento ainda ativo para os demais destinatários: (sim/não) _____

#### Guardrail #2 / RN4
- [ ] Nenhum nome, e-mail ou telefone de destinatário foi registrado neste arquivo ou em
      qualquer screenshot anexado ao card.
- [ ] A lista nominal completa (se produzida) ficou fora do repositório, conforme D3.
```

Quando este checklist vier preenchido, os 5 cenários da tabela acima devem ser
reavaliados um a um contra ele — é só nesse momento que a etapa de QA pode, de fato,
marcar "passou"/"falhou" em vez de "bloqueado".

---

## Por que o card não deveria ter chegado até aqui sem D1-D3 — e o que fazer agora

O design (`03-design.md` §8) e o plano de build (`04-plano-build.md`, seção "Execução
bloqueada até confirmação") foram explícitos de que o build não deveria nem começar sem
D1, D2 e D3 respondidas. O gate de build foi aprovado mesmo assim (`gates.md`,
`aguardando_gate_build`, 2026-10-30T02:57:47Z), e a demanda chegou à etapa de QA sem essas
respostas aparecerem em nenhum momento no card. Isso não é uma falha desta etapa de teste
— é um achado que preciso reportar: **o gate de build foi aprovado sobre um artefato que
já previa, explicitamente, não poder ser executado como estava.**

Dado que o avanço de etapa já aconteceu, o caminho correto agora não é fabricar uma
execução ou uma evidência que não ocorreu, nem regredir o status sozinho — é documentar o
bloqueio aqui, de forma explícita, e esperar que:

1. D1, D2 e D3 sejam respondidas no card;
2. o runbook (`04-plano-build.md`) seja executado por um humano em produção, nos termos
   da resposta a D1-D3;
3. o checklist acima seja preenchido com a evidência real;
4. esta etapa de QA seja revisitada para, só então, avaliar os 5 cenários contra dado
   real.

---

## Resumo de status

| Cenário (01-analise.md §4) | Status |
|---|---|
| 1 — Fabio Soto removido do agendamento | Bloqueado / não verificável nesta etapa |
| 2 — Demais destinatários inalterados | Bloqueado / não verificável nesta etapa |
| 3 — Relatório e agendamento continuam ativos | Bloqueado / não verificável nesta etapa |
| 4 — Mapeamento registrado sem dado pessoal | Não verificável nesta etapa (molde pronto, conteúdo pendente) |
| 5 — Nenhum dado de produção alterado pelo agente | Parcial: parte do agente OK; registro humano pendente |

**Nenhuma falha de implementação foi encontrada — porque não há implementação a testar.**
O que existe é uma lacuna de processo (D1-D3 sem resposta) que impede qualquer verificação
de resultado.

---

Testes executados. Preciso da sua homologação para liberar o release — mas essa
homologação **depende, antes, de D1, D2 e D3 serem respondidas no card e do runbook em
`04-plano-build.md` ser de fato executado em produção, com o roteiro de verificação acima
preenchido**. A esteira não pode homologar uma mudança que não há evidência de ter
acontecido.
