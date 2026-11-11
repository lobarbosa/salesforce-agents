# EPLAST-28 — Plano de build: alertas de oportunidade parada ou sem acompanhamento

**Status desta etapa: build NÃO executado.** Nenhuma branch foi criada, nenhuma metadata foi
escrita, nenhum PR foi aberto. Este documento é o artefato da etapa 4 (`04-plano-build.md`),
mas o conteúdo dele é o registro de **por que a construção não pôde acontecer nesta sessão** e
o plano condicional de passos, para o builder retomar assim que as respostas chegarem — não um
"passo a passo" de algo já decidido.

## 0. Por que não construí

O gate `aguardando_gate_design` foi aprovado por Carlos Sordi em 2026-11-11T22:12:57
(`gates.md`, hash de `02-recon.md`/`03-design.md`), o que moveu `status.yaml` para `build`. Mas
o próprio `03-design.md` — o artefato aprovado naquele gate — condiciona explicitamente a
liberação do build a itens que **não são técnicos** e que nenhum agente decide (seção 0 e
seção 11 daquele documento):

> "Aceitar este design NÃO libera o build enquanto a decisão contratual não estiver
> registrada e os quatro parâmetros bloqueantes da seção 3 não estiverem respondidos."

Conferi o disco antes de escrever qualquer metadata e nenhuma das cinco pré-condições da
checklist (seção 11 do design) está satisfeita:

| # | Pré-condição (design §11) | Medido | Resultado |
|---|---|---|---|
| 1 | Decisão contratual da análise §6 registrada (a/b/c) | `comentarios-do-card.md` | **Não registrada.** Só há duas entradas: aprovação do gate de análise (2026-11-10) e aprovação do gate de design (2026-11-11). Nenhuma decide (a) aditivo, (b) voltar pro backlog ou (c) autorizar análise/design sem build |
| 1b | Onda 3 está contratada? | `contrato.md` | **Não.** "Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e treinamento) ainda não contratadas" — escopo contratado é só Ondas 1–2, 120h, fim previsto 2026-11-30. O próprio `demanda.md` já dizia isso ("ainda não contratada no projeto atual") |
| 2 | Respostas aos itens 1–4 da seção 3 do design (definição de "parada"/"acompanhamento", prazo único ou por estágio, canal/frequência, destinatário/escalonamento) | `comentarios-do-card.md` | **Nenhuma resposta.** Sem elas não dá para fechar se a forma é Flow (nível 2) ou desce para Apex (seção 1.3 do design) |
| 3 | Volume de oportunidades abertas em produção (item 8) | `comentarios-do-card.md` | **Não informado.** Ninguém consulta produção (guardrail #2); só o cliente pode dar esse número |
| 4 | Confirmação de qual sandbox é dev e qual é QA (R6), com `sbx-eplast-qa` conectada | `sf org list` (rodei agora) | **Não confirmado, e o sinal é o mesmo do assessment:** só o alias `sbx-eplast-dev` está conectado (`Sandbox`, Org Id `00DHa000006vfMLMAY`, Connected). `sbx-eplast-qa` **não aparece na lista** — não está conectada. O usuário de integração autenticado na sandbox de "dev" se identifica com um sufixo de ambiente que sugere "qa" (mesmo achado 6 do assessment, sem repetir aqui o identificador — é dado de autenticação, não metadata de org), reforçando que não há confirmação de que dev e QA são ambientes distintos |
| 5 | Aprovação da estimativa pelo cliente no Squad OS | — | **Não consegui medir.** A aprovação de estimativa vive no Postgres do Squad OS (`apps/squad-os`), não neste checkout do repositório — não há arquivo em `clients/eplast/` que reflita esse estado, e esta sessão não tem acesso à API do Squad OS. Registro a limitação em vez de supor um valor |

Construir agora exigiria inventar valor para pelo menos 4 destas 5 lacunas (definição de
"parada", prazo, canal/destinatário, volume) — o que o guardrail #3 (não invente metadata) e a
seção 0 do próprio design proíbem explicitamente. A quinta (sandbox QA) é um guardrail de
produção: construir e já abrir caminho para deploy numa sandbox que pode ser a mesma org de
dev contraria o guardrail #1 na prática, mesmo que o nome `sbx-eplast-dev` passe pela allowlist
de `ambientes.py`.

## 1. O que FOI possível medir/confirmar nesta sessão (sem inventar nada)

- `sf org list`: só o alias `sbx-eplast-dev` conectado (`Sandbox`, `Connected`) e `sbx-eplast-qa`
  ausente da lista — ver tabela acima. Nenhuma consulta de dados de negócio foi feita.
- `contrato.md`: confirma que Onda 3 não está no escopo contratado atual.
- `gates.md` e `comentarios-do-card.md`: confirma que os dois gates de artefato (análise,
  design) foram aprovados, e que nenhuma resposta às pendências da seção 3/11 do design foi
  registrada no card até o momento desta sessão.
- `03-design.md` e `01-analise.md`: já continham as perguntas pendentes; não há nada novo para
  extrair deles além do que já está documentado nesses artefatos.

## 2. Plano condicional (o que o build faria, assim que cada resposta chegar)

Isto não é uma decisão — é o mapeamento do design (seções 1.3, 2, 4.1–4.2) para passos
executáveis, para o builder não ter que reler tudo do zero na próxima sessão.

### 2.1 Caminho base (se item 1 = opção A/B/C, item 3 = Custom Notification, item 2 = valor único, sem escalonamento)

1. Criar branch `feature/EPLAST-28` a partir do `main` atual.
2. Criar `CustomNotificationType` `Oportunidade_Parada` (desktop + mobile), com a descrição já
   redigida no design (§4.1).
3. Criar Flow `Opportunity_Scheduled_AlertaParada` (Schedule-Triggered, API v68):
   - Start: `Opportunity`, `IsClosed = false` (+ filtros de elegibilidade do item 6, a
     confirmar com o humano antes de fechar a fórmula).
   - Fórmula `DiasParado` = `TODAY() - <campo de referência do item 1>`.
   - Fórmula `Limite` = `<N do item 2>`.
   - Decisão `DiasParado = Limite` → Send Custom Notification ao `OwnerId`, alvo = Id da
     oportunidade, texto = nome + dias parado (sem valor, conforme item 7 do design).
   - Nenhum elemento de Update/Create/Delete (mantém a garantia "somente-leitura" da seção 5.1
     do design).
4. Agendar o Flow em horário diferente de `ScheduledFlowOpportunity` (design §5.1), horário
   exato a definir com o humano (não há recomendação registrada ainda).
5. Fixture de teste sintética em sandbox que satisfaça as 16 validation rules de Opportunity
   (R8 do design) — sem dado real (guardrail #2).
6. Teste de carga conforme design §5.2: (a) 200+ oportunidades de donos diferentes, metade no
   dia-limite; (b) 1 dono com 150 oportunidades no dia-limite. Critério de corte: 70% do limite
   diário de interviews de Flow agendado (valor exato a confirmar na documentação oficial
   vigente no momento do build, não de memória — guardrail #3).
7. Abrir PR com os dois componentes + evidência do teste de carga, revisor humano obrigatório
   (guardrail #4).

### 2.2 Caminho Apex (se item 1 = opção D, item 3 = resumo por dono, ou item 8 acima do teto seguro)

Design §1.3/§4.2: `OpportunityStaleAlertScheduler` → `OpportunityStaleAlertBatch` →
`OpportunityStaleAlertService`, cada um com `<Classe>Test` dedicada, cobertura ≥ 85% por
classe (`sf apex run test --code-coverage`). Nenhuma classe nova herda a cobertura de 10% da
org (achado 2 do assessment) — o build não piora a cobertura, mas também não a recupera (R9).

### 2.3 Fora de qualquer caminho (reafirmado do design, não repetido na íntegra aqui)

Sem Task, sem gravação em Account/Opportunity, sem canal Marketing Cloud/Teams/Slack, sem
escalonamento ao gestor, sem tocar `OpportunityTrigger`/`OpportunityFlow`/`Oportunidade_Industria`
/`ScheduledFlowOpportunity`, sem Custom Metadata de parâmetro por estágio, sem ativar os
templates `agentic_feed` — ver `03-design.md` §9 para a lista completa e a justificativa de
cada exclusão.

## 3. O que falta para desbloquear

Registro, não repetição: as mesmas 5 lacunas da seção 0 — decisão contratual, itens 1–4 e 8 do
design, confirmação de `sbx-eplast-qa`, aprovação da estimativa. Nenhuma tem resposta nesta
sessão. Até que alguém registre essas respostas em `comentarios-do-card.md` (ou a aprovação de
estimativa no Squad OS), a próxima sessão de build deve reconferir este arquivo antes de criar
qualquer branch ou metadata — não presumir que o tempo passado resolveu algo sozinho.

**Esta etapa não avança para `aguardando_gate_build`.** Não há PR para revisar, porque não há
build. `status.yaml` permanece em `build` até a construção real acontecer.
