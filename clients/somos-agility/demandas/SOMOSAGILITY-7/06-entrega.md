# SOMOSAGILITY-7 — Entrega

**Cliente:** somos-agility · **Tipo:** sustentação (bug) · **Documentação de negócio:** 2026-10-30
(revisada pelo agente `doc`, rodada 3) · **Parte técnica do release:** 2026-10-30 (agente `release`)
**Branch:** `feature/SOMOSAGILITY-7` · **Status em `status.yaml` no momento desta escrita:** `release`
**Ambientes onde a correção está implantada:** `sbx-somos-agility-dev` e `sbx-somos-agility-qa`.
**Produção:** não tocada. Fora do escopo de qualquer agente.

> **AVISO — LEIA ANTES DE TUDO (30/10)**
>
> A demanda está **pronta para QA/ambiente, não pronta para produção.**
>
> - **Implantada e ativa:** a versão 5 do Flow `Atualiza_o_status_final_de_aprovacao_do_LAT` está
>   `Active` em dev e em QA. Em QA, o deploy desta esteira foi feito em 30/10 (Deploy ID
>   `0AfHa00000E79zNKAR`, `Succeeded`) — ver "Parte técnica do release" abaixo.
> - **Gap de rastreabilidade (AMB-03):** a v5 já estava ativa em QA desde 26/10/2026 (23:35–23:36 UTC),
>   por um Change Set de entrada chamado "FluxoLAT", que não passa por esta esteira. O deploy de 30/10
>   formaliza e documenta a entrega, mas não mudou o estado da org (retornou `Unchanged`). Quem
>   operou esse Change Set não está identificado nos artefatos. Ver `Limitações`, item AMB-03.
> - **Validação funcional NÃO feita:** a matriz CT-03 a CT-13 (`05-testes.md` §3) continua sendo roteiro.
>   Nenhum registro de LAT foi criado ou alterado em nenhum ambiente. O motivo é FLS: o usuário de
>   teste disponível não tem os permission sets do modelo de 3 executores. Por isso, **os critérios de
>   aceite centrais da demanda (Status Geral em aprovação parcial e em rejeição) não foram validados
>   de ponta a ponta em nenhuma das três rodadas.**
> - **Regra R4 (rejeição) não confirmada pelo negócio** (L1). É proposta do agente.
> - **Homologação de 30/10:** a aprovação de Juliana Mendes (`gates.md`, 2026-10-30T14:27:25Z) aprova
>   o **roteiro e o ambiente**, conforme a própria `05-testes.md` §5. Não aprova o comportamento
>   funcional da regra.
> - **Comentário do cliente em 30/10 14:26** ("Demanda validada em AW, podemos seguir para produção")
>   está registrado em `comentarios-do-card.md`. **Não é tratado como autorização de deploy em
>   produção.** Promoção para produção é decisão e execução humanas, com janela e aprovação próprias,
>   fora da esteira de agentes (guardrail #1).

---

## Histórico desta demanda (três rodadas)

A demanda passou por duas devoluções. Esta é a terceira rodada de documentação.

1. **Rodada 1 (28/10):** a documentação foi escrita como "entregue", mas nenhum deploy em QA havia
   acontecido. Leonardo Barbosa devolveu em 29/10 ("entrega falsa: nada foi implantado em QA").
   A homologação de 28/10 foi invalidada.
2. **Rodada 2 (30/10, 01:23 UTC):** as etapas de QA rodaram na sandbox de dev, não na de QA. Leonardo
   Barbosa devolveu ao gate de build. O motivo registrado foi um defeito do `run-demand`, que deveria
   ter direcionado a etapa para QA.
3. **Rodada 3 (30/10):** build reaprovado por Leonardo Barbosa (02:43 UTC). QA rodou em
   `sbx-somos-agility-qa`, com a v5 já ativa (ver AMB-03). Homologação de Juliana Mendes (14:27 UTC)
   e deploy formal em QA pelo agente `release` (Deploy ID `0AfHa00000E79zNKAR`).

---

## O que foi entregue (linguagem de negócio)

Quando o gerente de projetos aprovava um executor e ainda havia outro executor pendente, ou rejeitava
um executor, o **Status Geral** do Lançamento de Atividades (LAT) ficava travado em "Pendente - Gerente
de projeto". Ninguém recalculava o status geral nesses casos. O único cálculo existente só promovia o
LAT para "Aprovado" quando todos os executores estavam aprovados.

A correção faz o Status Geral ser recalculado a cada gravação do LAT, com esta regra (a primeira que
bater define o valor; só são considerados os executores em uso, de 1 até a quantidade de executores
do LAT):

1. Algum executor ainda aguardando o gerente de projetos → **Pendente - Gerente de projeto**.
2. Todos os executores aprovados → **Aprovado**.
3. Algum executor ainda sem preenchimento → **Pendente - Preenchimento do(s) executor(es)**, para o
   próximo executor lançar.
4. Algum executor rejeitado (e nenhum dos casos acima) → **Pendente - Preenchimento do(s) executor(es)**.
   *Regra proposta pelo agente, não confirmada pelo negócio (ver limitações, L1).*
5. Nenhum dos casos acima → o Status Geral não é alterado.

**Estado em 2026-10-30:**

- Implementado e **ativo** em `sbx-somos-agility-dev` e em `sbx-somos-agility-qa`.
- Validação funcional de ponta a ponta (dado de teste passando pela matriz CT-03 a CT-13): **ainda não
  aconteceu em nenhum ambiente.**
- Não validado em produção. Produção não foi tocada.

---

## Componente técnico alterado

| API name | Tipo | Alteração |
|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow record-triggered (Update, after save) em `Lancamento_de_Atividades__c` | Nova versão **v5**, `Active` em QA (Id `301Ha000014rLOdIAM`) e em dev (a versão 5 foi deployada em dev em 22–23/10; o Id de dev não consta nos artefatos de build). A v4 ficou `Obsolete` nos dois. Passou a calcular `Status__c` pela regra acima. Elementos novos: formula `fxStatusGeralCalculado`, decision `Status_calculado_e_diferente`, record update `Atualiza_Status_Geral_do_LAT`. |

Arquivo: `force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml`.

Nenhum outro componente foi criado ou alterado: nenhum campo, objeto, approval process, field update,
Process Builder, permission set, perfil, layout ou `FlowDefinition`.

Desvio em relação ao design: o `triggerOrder` planejado (valor 900, para ordenar o flow depois da auto
aprovação do GP) **não foi aplicado**. O deploy em dev rejeitou o elemento em `FlowStart`, mesmo com API
68.0. Ver `04-plano-build.md` §3 e limitação T1.

---

## Como funciona

1. O executor preenche as horas da sua posição e envia para aprovação. O approval process coloca o
   Status Geral em "Pendente - Gerente de projeto". Isto já existia.
2. O gerente de projetos aprova ou rejeita um executor pelo approval process, ou a auto aprovação do
   gerente grava o status do executor. Aprovação e rejeição finais gravam o secundário como `Aprovado` ou
   `Rejeitado`. Isto já existia e não foi alterado.
3. Ao salvar o LAT, o flow só segue se o Status Geral atual for Rascunho, Pendente - Preenchimento do(s)
   executor(es) ou Pendente - Gerente de projeto.
4. O flow calcula o valor esperado pela regra acima, olhando só o registro salvo (não consulta outros
   registros).
5. Se o valor calculado for vazio (caso 5), o flow não faz nada.
6. Se o valor calculado for igual ao atual, o flow não grava. Só grava quando o valor muda, para não
   gerar salvamentos desnecessários.
7. Se o valor mudou, grava `Status__c` numa única operação. Como o flow roda em contexto de sistema, não
   depende das permissões do usuário que salvou.

Observação: o flow não tem ordem definida em relação aos outros flows que rodam no mesmo salvamento
(ver limitação T1). A correção depende de o recálculo ser refeito quando outro flow regrava o status
do executor no mesmo save. Isso ainda não foi testado.

Onde olhar para manutenção: a fórmula `fxStatusGeralCalculado` concentra a regra inteira. Os rótulos
dos valores são comparados como texto exato (ver limitações).

---

## Configuração pós-deploy

**No Flow, nenhuma.** O `<status>Active</status>` do XML ativa a v5 e torna a v4 `Obsolete` no mesmo
deploy. Isso foi confirmado em dev e, nesta sessão, também em QA. Não há passo manual de ativação,
permission set, perfil ou layout associado ao deploy do Flow.

**Para a correção ser validada e usável de ponta a ponta, ainda falta** (todos decisão ou execução
humana, nenhum é passo que um agente da esteira deva executar):

1. ~~Conectar `sbx-somos-agility-qa` ao ambiente de CI e agentes.~~ **Feito** (`Connected` confirmado
   nesta sessão).
2. ~~Fazer o deploy em QA (dry-run e depois real).~~ **Feito em 30/10**, Deploy ID `0AfHa00000E79zNKAR`.
   A v5 já estava ativa em QA desde 26/10 por outro caminho (AMB-03).
3. Atribuir o permission set `Lancamento_de_atividades_admin` (ou equivalente com FLS em
   `Qtd_de_executores__c`, `Status_de_aprovacao_N__c` e `Executor_da_atividade_N__c`) a um usuário de
   teste em QA que seja submissor ou aprovador dos approval processes `Fluxo_de_aprovacao_1/2/3_executor`.
   Sem isso, ninguém consegue criar massa de teste nem ver os campos. Bloqueio confirmado em QA em
   30/10 (`05-testes.md` §0.4), igual ao de dev. **Pendente.**
4. Criar massa sintética (Projeto → Marco → LAT com Qtd 1, 2 e 3), sem dado real de cliente. QA tem
   6639 registros de `Marcos__c` pré-existentes (`05-testes.md` §0.5). Crie um registro novo e isolado,
   não reaproveite os existentes. **Pendente.**
5. Executar a matriz `05-testes.md` §3 (CT-03 a CT-13) e registrar resultados. Em nenhuma das três
   rodadas ela foi executada. **Pendente.**
6. Confirmar com o negócio a regra R4 (rejeição parcial, L1). Os casos CT-07 a CT-09 dependem disso.
   **Pendente.**
7. Decidir a governança do Change Set "FluxoLAT" (AMB-03): se esse caminho de deploy direto em QA
   continua disponível em paralelo à esteira, e quem o opera. **Pendente, decisão humana.**
8. Antes de promover a produção: comparar a versão ativa do flow em produção com a de QA e dev, e
   conferir os flows "Somatória" citados no card (D1, D2). Definir janela e plano de comunicação.
   **Fora do escopo de qualquer agente.** Produção é ato humano.

**Rollback (se necessário):** reativar a v4 (`301U400000lNFgEIAW`) pela UI ou pela Tooling API. O
procedimento completo está na "Parte técnica do release", §6.

---

## Limitações e dívida técnica

- **Validação funcional pendente (bloqueante para produção).** Nenhum critério de aceite central foi
  exercitado com dado de teste. CT-03 a CT-13 são roteiro. Bloqueio: FLS do usuário de teste em QA e em dev.
- **L1 — regra de rejeição (R4) não confirmada.** O comportamento "rejeitado → Pendente - Preenchimento"
  é proposta do agente. Se o negócio definir outra regra, trocar o valor na fórmula é a mudança. Os
  casos CT-07 a CT-09 dependem disso.
- **T1 — ordem de execução (risco alto, não confirmado).** Há quatro flows after save de Update no
  objeto, mais um Process Builder ativo, sem `triggerOrder`. O `triggerOrder` planejado foi removido
  porque o deploy o rejeitou. A mitigação é o cálculo sobre o estado final do registro, seguido de nova
  gravação quando o valor muda. Essa mitigação não foi validada. Teste: CT-12.
- **T3 — disparo pelo approval process (risco médio, não confirmado).** Não foi reproduzido que a
  gravação do executor pelo approval process dispara o flow. Se não disparar, nem a v4 nem a v5 resolvem
  aprovação e rejeição. Nesse caso, o plano B do design (ações de configuração nos approval processes)
  vira obrigatório e volta ao arquiteto. Teste: CT-13.
- **T5 — validation rule `Checa_preenchimento_unitario_do_executor`.** Avalia o registro inteiro. Não foi
  testada na prática. Teste: CT-10.
- **T2, D1, D2 — paridade com produção não verificada.** O agente não acessou produção. A versão ativa
  de produção do flow de status e da auto aprovação não foi conferida. Os flows "Somatória" citados no
  card (P3) estão inativos em dev desde 2019 e, quando existiam, escreviam em `Marcos__c`, não em
  `Status__c`. Não se sabe se isso reflete produção.
- **T6 — registros já presos não se corrigem sozinhos.** A v5 só recalcula quando o registro é salvo de
  novo. Não há correção retroativa. Está fora de escopo e a decisão é humana.
- **T7 — auto aprovação sem critério de entrada.** `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos`
  grava o status do executor em todo update. Não foi alterado. Desperdício e recursão ficam para demanda
  futura.
- **Fórmula com rótulos literais.** A regra compara textos exatos das picklists. Os rótulos do Status
  Geral e dos status de executor são diferentes (ex.: "Gerente de projeto" e "Gerente de projetos").
  Renomear um valor de picklist sem atualizar a fórmula faz a regra deixar de bater, sem erro visível.
- **Valores legados não limpos.** Permanecem em `Status__c` (Pendente, Aguardando Aprovação, Recall,
  Rejeitado) e o approval process inativo `Solicitacao_de_aprovacao_para_atividade`.
- **Snapshot de metadata do recon vencido.** A coleta do recon (`02-recon.md`) é de 2026-10-21 e foi
  feita em dev. A comparação de parity de 30/10 (`05-testes.md` §0.5) usou esse recon como referência
  para dev, não uma releitura de dev. Não achou divergência relevante para a correção, além do volume
  de `Marcos__c` em QA. Não foi conferido se os approval processes estão ativos em QA.
- **Origem do bug desconhecida (L4).** Pista: a v4 do flow é de 2026-06-08. Não confirmado.
- **Impacto, urgência e janela de deploy em produção não informados (L5).** Decisão humana, fora desta
  esteira.
- **Anexo original da demanda não recebido (L6).** A regra veio dos comentários do card (P1).
- **AMB-03 — gap de rastreabilidade entre 26/10 e 30/10.** A v5 já estava ativa em QA desde 26/10/2026,
  por um Change Set de entrada ("FluxoLAT", implantado em 2026-10-26T23:35:57Z), não pela esteira Git/CI
  nem pelos gates de `gates.md`. Nenhum artefato desta demanda registrava isso até 30/10. O autor do
  deploy não é determinável pelos dados consultados. Esse achado é de governança e fica com o humano.
- **Rastreabilidade de PR não confirmada.** Ver seção Rastreabilidade.

---

## Rastreabilidade

- **Demanda:** SOMOSAGILITY-7 (somos-agility, sustentação). Título: "LAT - Erro na atualização dos Status Geral".
- **Branch:** `feature/SOMOSAGILITY-7`.
- **PR:** **número não confirmado nesta sessão.** Não há acesso ao `gh` com token válido neste ambiente.
  Não há número de PR nos artefatos desta demanda que possa ser atribuído a ela com segurança. O
  `status.yaml` cita "PR #121", mas no contexto de um defeito do `run-demand`, não desta demanda. Confirmar
  o número e o estado da PR antes de publicar este documento.
- **Commits citados nos gates:** `d82cf3cb` (análise), `15fdbfd8` (design), `eb2aae78` (build), `4cb73318`
  (1ª homologação, invalidada), `222d8d7c` (reaprovação do build), `8a472705` (2ª homologação, a que
  autoriza este release).
- **Pacote de deploy:** `manifest/package.xml` (só o Flow acima, versão de API 67.0).
- **Ambiente de deploy desta esteira:** `sbx-somos-agility-qa` (Sandbox, orgId `00DHa000006WcTcMAK`).
  Produção não tocada.

### Gates (`gates.md`)

Conferir os hashes com `sfagents demanda conferir-gates --client somos-agility SOMOSAGILITY-7` antes de
publicar. Não foi possível rodar essa conferência nesta sessão.

| Gate | Aprovado por | Quando (UTC) | Commit | Artefato revisado (sha256) | Situação |
|---|---|---|---|---|---|
| `aguardando_gate_analise` | Carlos Sordi | 2026-10-21 21:36:21 | `d82cf3cb` | `01-analise.md` (`cff3e404259feb87`) | Válido |
| `aguardando_gate_design` | Carlos Sordi | 2026-10-22 21:16:01 | `15fdbfd8` | `02-recon.md` (`a95bb9f2ee5cdaa0`), `03-design.md` (`42b16e12ec8e8202`) | Válido |
| `aguardando_gate_build` | Carlos Sordi | 2026-10-23 20:28:27 | `eb2aae78` | `04-plano-build.md` (`1c7ae6ad50a76631`) | Devolvido em 30/10 01:23 (ver rodada 2) |
| `aguardando_homologacao` | Juliana Mendes | 2026-10-28 22:50:16 | `4cb73318` | `05-testes.md` (`82556ecd83112b0f`) | **Invalidado** (devolução de Leonardo Barbosa, 29/10, "entrega falsa") |
| `aguardando_gate_build` (reaprovação) | Leonardo Barbosa | 2026-10-30 02:43:56 | `222d8d7c` | `04-plano-build.md` (`1c7ae6ad50a76631`, mesmo artefato) | Válido |
| `aguardando_homologacao` | Juliana Mendes | 2026-10-30 14:27:25 | `8a472705` | `05-testes.md` (`93612e009369e17d`, 17364 bytes) | **Válido para este release.** Aprova roteiro e ambiente, não comportamento (ver aviso) |

Os comentários do card registram as mesmas aprovações como "Equipe" e "Cliente" (ex.: "Cliente —
2026-10-28 22:48, Aprovou o gate aguardando_homologacao"). Os nomes e os hashes acima vêm de `gates.md`,
que é o registro de referência.

- **Estimativa:** 10 h, aprovada pelo cliente em 2026-10-22 (comentário do card). Faixa do design: 8–14 h.
- **Comentário do cliente em 2026-10-30 14:26** ("podemos seguir para produção"): registrado para
  contexto. **Não tratado como instrução de deploy.** Este release cobre exclusivamente
  `sbx-somos-agility-qa`.
- **Status em `status.yaml`:** `release`. A transição seguinte (`entregue`) não foi registrada no
  momento desta escrita.

---

# Parte técnica do release (agente `release`, 2026-10-30)

**Cliente:** somos-agility · **Agente:** `release` · **Data desta sessão:** 2026-10-30
**Org alvo:** `sbx-somos-agility-qa` (Sandbox, `Connected`, orgId `00DHa000006WcTcMAK`,
instância `BRA8S`, Enterprise Edition — confirmado via `sf org list --json` antes de qualquer
comando de escrita; nenhum alias com `prod`/`prd`/`production` presente ou tocado).
**Entradas:** `04-plano-build.md`, `05-testes.md` (rodada de 2026-10-30), `gates.md`
(homologação aprovada por Juliana Mendes em 2026-10-30T14:27:25.405152+00:00, sobre
`05-testes.md`, sha256 `93612e009369e17d`, 17364 bytes — conferido antes de iniciar).

Esta sessão **substitui** a seção técnica de 2026-10-28, que registrava um release bloqueado
porque `sbx-somos-agility-qa` não estava conectada naquele momento. Desta vez ela está
conectada e o release aconteceu de fato.

---

## 1. Pacote de deploy

Único componente desta demanda, confirmado em `04-plano-build.md` §1/§4 e em `05-testes.md`
§0.2:

| Componente | Tipo | API name | Arquivo |
|---|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow (record-triggered, Update, after-save) | `Atualiza_o_status_final_de_aprovacao_do_LAT` | `force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml` |

`manifest/package.xml` já existia na working tree com exatamente este componente (criado numa
sessão anterior de release, nunca alterado desde então); conferido e usado sem modificação:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Atualiza_o_status_final_de_aprovacao_do_LAT</members>
        <name>Flow</name>
    </types>
    <version>67.0</version>
</Package>
```

Nenhum outro componente (objeto, campo, permission set, layout, flowDefinition) faz parte deste
pacote — consistente com `04-plano-build.md` §5 e §8.

## 2. Dry-run

Comando:

```
sf project deploy start --dry-run --target-org sbx-somos-agility-qa --manifest manifest/package.xml
```

Resultado real (`--json`), resumido:

- `status`: `"Succeeded"`, `success: true`, `numberComponentErrors: 0`,
  `numberComponentsDeployed: 1`, `numberComponentsTotal: 1`.
- Componente `Atualiza_o_status_final_de_aprovacao_do_LAT` (Flow): `success: true`,
  `changed: false`, Id retornado `301Ha000014rLOdIAM`.
- Deploy (check-only) Id: `0AfHa00000E79xlKAB`.
- `files`: o Flow aparece com `state: "Unchanged"` — o conteúdo do XML em
  `force-app/main/default/flows/` já é idêntico ao que está ativo na org.

Dry-run limpo: sem erros, sem falhas de componente. Prossegui para o deploy real.

## 3. Deploy real

Comando:

```
sf project deploy start --target-org sbx-somos-agility-qa --manifest manifest/package.xml
```

Resultado real (`--json`):

- `status`: `"Succeeded"`, `success: true`, `numberComponentErrors: 0`,
  `numberComponentsDeployed: 1`, `numberComponentsTotal: 1`.
- Componente `Atualiza_o_status_final_de_aprovacao_do_LAT`: `success: true`, `changed: false`,
  Id `301Ha000014rLOdIAM` (mesmo Id de versão do Flow já ativo).
- **Deploy ID: `0AfHa00000E79zNKAR`.**
- `files`: Flow com `state: "Unchanged"`.

O `changed: false` / `state: "Unchanged"` em ambos os passos **não é um erro nem um sinal de
que nada foi feito** — é a plataforma relatando corretamente que o conteúdo do pacote já batia
byte a byte com o que estava ativo na org antes deste deploy. O valor deste deploy é
**documentar formalmente, com Deploy ID rastreável nesta esteira**, algo que já existia na org
mas não estava registrado em nenhum artefato da demanda (ver §5, AMB-03).

## 4. Confirmação pós-deploy (Tooling API)

```
sf data query --use-tooling-api --target-org sbx-somos-agility-qa --query "SELECT Id, VersionNumber, Status, Definition.DeveloperName FROM Flow WHERE Definition.DeveloperName = 'Atualiza_o_status_final_de_aprovacao_do_LAT' ORDER BY VersionNumber"
```

| Versão | Status | Id |
|---|---|---|
| 1 | Obsolete | `301U400000j5zaZIAQ` |
| 2 | Obsolete | `301U400000jvkx6IAA` |
| 3 | Obsolete | `301U400000lNyq8IAC` |
| 4 | Obsolete | `301U400000lNFgEIAW` |
| **5** | **Active** | `301Ha000014rLOdIAM` |

Estado confirmado como esperado: v5 `Active`, v1–v4 `Obsolete`. Nenhuma versão nova foi criada
por este deploy (continuam 5 versões no total, mesma Id de v5 de antes) — consistente com
`changed: false` acima.

## 5. Investigação do gap AMB-03 (como a v5 chegou a QA antes desta sessão)

`05-testes.md` §0.3 registrou que não havia, em nenhum artefato desta demanda, um release
documentado explicando como a v5 passou a existir — e estar ativa — em `sbx-somos-agility-qa`
antes de qualquer sessão de `release` rodar contra essa org. Investiguei nesta sessão, sem
inventar autor nem data (guardrail #3), só com o que os dados confirmam:

**Datas da versão, via Tooling API:**

```
SELECT Id, VersionNumber, Status, CreatedDate, LastModifiedDate FROM Flow
WHERE Definition.DeveloperName = 'Atualiza_o_status_final_de_aprovacao_do_LAT'
```

A v5 (`301Ha000014rLOdIAM`) tem `CreatedDate = 2026-10-26T23:35:52Z` e
`LastModifiedDate = 2026-10-26T23:36:14Z` — ou seja, **ela já existia em QA desde 26/10**,
quatro dias antes desta sessão de release e antes de qualquer gate de build/homologação sobre a
rodada atual de `05-testes.md`.

**`SetupAuditTrail` no mesmo intervalo** (consulta agregada, só `Action`/`Section`/`Display`/
`CreatedDate` — nenhum campo de usuário, e-mail ou dado de cliente foi incluído na consulta nem
neste registro, por disciplina do guardrail #2):

| Horário (UTC) | Action | Section | Display |
|---|---|---|---|
| 23:35:52 | `createdinteractiondefversion` | Fluxos | Nº da versão do fluxo criada **5** "Atualiza o status final de aprovação do LAT" |
| 23:35:57 | `deployedchangeset` | **Conjuntos de alterações de entrada** | Conjunto de alterações implantadas: **"FluxoLAT"** |
| 23:36:14 | `activatedinteractiondefversion` | Fluxos | Nº da versão do fluxo ativada **5** |
| 23:36:14 | `deactivatedinteractiondefversion` | Fluxos | Nº da versão do fluxo desativada **4** |

**Conclusão, sem inventar o que a auditoria não registra:**

- A v5 chegou a `sbx-somos-agility-qa` via um **Change Set de entrada chamado "FluxoLAT"**,
  implantado em **2026-10-26T23:35:57Z** — um mecanismo de deploy diferente desta esteira
  (`sf project deploy` / `manifest/package.xml`), tipicamente operado manualmente pelo Setup da
  org, não pelo pipeline Git/CI deste squad.
- A sequência bate exatamente: criação da versão (23:35:52) → deploy do change set (23:35:57)
  → ativação da v5 e desativação simultânea da v4 (23:36:14, ambas no mesmo segundo, efeito
  colateral automático de ativar uma versão nova de Flow).
- **Não consigo determinar quem fez esse deploy** — a consulta não trouxe (e eu deliberadamente
  não incluí) o campo de usuário responsável, seguindo a mesma disciplina já aplicada nesta
  demanda em `05-testes.md`/commit `7ef55804` (não expor identidade de quem operou a org em
  artefato de texto). Quem precisar dessa informação para auditoria tem acesso direto ao Setup
  Audit Trail da org (`sbx-somos-agility-qa`, registro de Id `0YmHa00000aLNo6KAG`).
- **Não há, nos artefatos desta demanda, nenhuma etapa `build`/`release` do pipeline associada a
  esse horário** (`status.yaml` não registra nada entre 23/10 e a devolução de 30/10 às
  01:23) — confirma que o Change Set "FluxoLAT" foi um caminho **paralelo** à esteira, não um
  deploy desta automação que simplesmente deixou de ser documentado.
- Isto é reportado como **achado de processo para o humano**, não como erro desta sessão: existe
  pelo menos um caminho de deploy direto em QA (Change Set) que não passa pela esteira Git/CI
  nem pelos gates registrados em `gates.md`. Vale uma decisão de governança — fora do escopo
  deste agente — sobre se esse caminho deve continuar disponível em paralelo à esteira.

## 6. Plano de rollback

1. **O que reverter:** a ativação da v5 do Flow `Atualiza_o_status_final_de_aprovacao_do_LAT`
   em `sbx-somos-agility-qa`. (Produção está fora de escopo deste agente e não foi tocada.)
2. **Como reverter** (Flow não tem "undeploy" — a versão anterior não é apagada, só vira
   `Obsolete` quando outra é ativada):
   - **Via UI:** Setup → Flows → abrir `Atualiza_o_status_final_de_aprovacao_do_LAT` → aba de
     versões → selecionar a **v4** (`301U400000lNFgEIAW`, a que estava ativa antes da v5) →
     **Activate**. Isso reativa a v4 e torna a v5 `Obsolete` automaticamente, sem deploy de
     metadata.
   - **Via Tooling API:** `PATCH /services/data/v68.0/tooling/sobjects/Flow/301U400000lNFgEIAW`
     com corpo `{"Metadata": {"status": "Active"}}`.
   - **Via deploy de metadata:** re-deployar o XML da v4 (disponível no histórico do git, no
     commit anterior a `e3721ce1` na branch `feature/SOMOSAGILITY-7`, ou em
     `baseline/somos-agility`) com `<status>Active</status>` — cria uma versão 6 com o conteúdo
     da v4. Mais lento e deixa um histórico extra; preferir a reativação direta acima.
   - **Confirmar após reverter:** repetir a query do §4 — a v4 deve aparecer `Active`, a v5
     `Obsolete`.
3. **Não há dado a reverter.** Este deploy não grava, altera nem migra dados — é só uma versão
   de lógica de automação. Registros de `Lancamento_de_Atividades__c` que a v5 já tiver
   recalculado **não são desfeitos** automaticamente por um rollback de versão de Flow; se algum
   `Status__c` precisar ser corrigido depois de um rollback, é uma ação manual separada, fora
   deste release.
4. **Antes de decidir reverter por causa de R4** (`03-design.md`/L1, regra de rejeição ainda não
   confirmada pelo negócio): avalie se o problema é a lógica inteira (reverter para v4, que tem
   o bug original que esta demanda corrige) ou só o valor de R4 (nesse caso, uma v6 ajustando só
   essa regra é melhor que reverter).

## 7. Passos manuais pós-deploy pendentes

Nenhum passo manual é necessário para o deploy do Flow em si (`<status>Active</status>` já
ativa/obsoleta sozinho). Os pendentes abaixo são pré-requisitos para a **validação funcional**,
não para o deploy, e são decisão/execução humana — não deste agente:

1. **Atribuir FLS** — permission set `Lancamento_de_atividades_admin` (ou outro que conceda FLS
   em `Qtd_de_executores__c`, `Status_de_aprovacao_1/2/3__c`,
   `Executor_da_atividade_1/2/3__c`) a um usuário de teste em `sbx-somos-agility-qa` que também
   seja submissor/aprovador de `Fluxo_de_aprovacao_1/2/3_executor`. Confirmado nesta demanda que
   isto bloqueia toda a validação funcional, em dev e em QA (`04-plano-build.md` §6,
   `05-testes.md` §0.4).
2. **Criar massa sintética** — Projeto → Marco → LAT com Qtd 1, 2 e 3, isolada dos 6639
   `Marcos__c` já existentes em QA (`05-testes.md` §0.5). Sem dado real de cliente.
3. **Executar a matriz `05-testes.md` §3** (CT-03 a CT-13) de ponta a ponta, incluindo os casos
   que confirmam T1 (CT-12) e T3 (CT-13), ainda sem confirmação prática em nenhuma rodada desta
   demanda.
4. **Confirmar com o negócio a regra R4/L1** (rejeição parcial) antes de considerar esse
   comportamento definitivo.
5. **Esclarecer governança do Change Set "FluxoLAT"** (§5, AMB-03) — se esse caminho de deploy
   direto em QA deve continuar coexistindo com a esteira Git/CI, e quem o opera.
6. **Produção:** fora do escopo de qualquer agente desta esteira. Antes de qualquer promoção —
   decisão e execução exclusivamente humanas —: comparar a versão ativa do Flow em produção com
   a de QA/dev, confirmar os pontos T1/T2/T3/D1/D2/L1 acima, definir janela e plano de
   comunicação. O comentário do cliente em 2026-10-30 ("podemos seguir para produção") registra
   a vontade do cliente, não substitui esses passos nem autoriza um agente a executá-los.

## 8. Resumo desta sessão

- **Org alvo:** `sbx-somos-agility-qa` (Sandbox, Connected) — confirmada antes de qualquer
  comando de escrita; nenhum alias de produção presente ou tocado.
- **Dry-run:** `Succeeded`, Id `0AfHa00000E79xlKAB`, 0 erros.
- **Deploy real:** `Succeeded`, **Deploy ID `0AfHa00000E79zNKAR`**, 0 erros, 1 componente.
- **Pós-deploy:** v5 `Active` (`301Ha000014rLOdIAM`), v1–v4 `Obsolete` — confirmado via Tooling
  API.
- **AMB-03:** esclarecido na medida do possível — origem identificada (Change Set de entrada
  "FluxoLAT", 2026-10-26T23:35:57Z), autor não determinável pelos dados consultados nesta
  sessão (e deliberadamente não investigado além disso, por guardrail #2).
- **Plano de rollback e passos manuais pós-deploy:** registrados acima (§6 e §7).
- **Produção:** não tocada, não avaliada para deploy, fora de escopo. O pedido do cliente no
  card para "seguir para produção" foi registrado e explicitamente não executado nem
  encaminhado como se fosse aprovação de deploy.
- **Esta etapa de release está concluída para o que está dentro do seu escopo** (empacotar,
  validar e deployar em QA, com rastreabilidade). **A demanda como um todo não está pronta para
  produção**: a validação funcional de ponta a ponta (CT-03–CT-13) continua pendente por
  bloqueio de FLS, e essa é uma decisão de próxima etapa humana (atribuir permissão, testar),
  não deste agente.
- Sessão encerrada nesta mensagem — sem continuação em background, sem passo pendente que este
  agente ainda vá executar depois.
