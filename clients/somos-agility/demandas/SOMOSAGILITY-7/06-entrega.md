# SOMOSAGILITY-7 — Entrega

**Cliente:** somos-agility · **Tipo:** sustentação (bug) · **Documentação final:** 2026-10-28
**Branch:** `feature/SOMOSAGILITY-7` · **Ambiente onde a correção existe:** `sbx-somos-agility-dev` (apenas)

> **AVISO — LEIA ANTES DE TUDO**
>
> **Status do sistema mostrará 'entregue', mas isso não reflete a realidade.** A correção existe só em `sbx-somos-agility-dev`; não foi implantada em `sbx-somos-agility-qa` nem validada de ponta a ponta. Tratar esta demanda como **pendente de deploy e de homologação funcional real** até alguém conectar `sbx-somos-agility-qa` e rodar o roteiro de `05-testes.md` §3.
>
> Situação, item a item:
> - **Deploy em QA:** não houve. Nenhum dry-run e nenhum deploy real contra QA. Não existe Deploy ID de QA.
> - **Matriz de testes CT-03 a CT-13:** não executada. Existe só como roteiro escrito.
> - **Testes executados:** só conferências de metadata em dev (CT-00 e CT-01: v5 ativa, v4 obsoleta). A fórmula foi simulada fora da org, em Python. Nenhum registro de LAT foi criado nem alterado, porque o usuário da sessão não tem FLS nos campos do modelo de 3 executores.
> - **Riscos não confirmados na prática:** T1 (ordem entre flows no mesmo save; severidade alta) e T3 (disparo do flow pelo approval process; severidade média).
> - **Regra de rejeição (R4):** proposta do agente, não confirmada pelo negócio (L1). Nenhum artefato registra confirmação dela.
> - **Aceite de homologação em `gates.md`:** registrado em 2026-10-28 por Juliana Mendes, sobre `05-testes.md`. Esse documento contém matriz não executada. O aceite vale como aprovação do roteiro, não como validação do comportamento da correção.

---

## O que foi entregue (linguagem de negócio)

Quando o gerente de projetos aprovava um executor e ainda havia outro executor pendente, ou rejeitava um executor, o **Status Geral** do Lançamento de Atividades (LAT) ficava travado em "Pendente - Gerente de projeto". Ninguém recalculava o status geral nesses casos.

A correção faz o Status Geral ser recalculado a cada gravação do LAT, com esta regra (a primeira que bater define o valor; só são considerados os executores em uso, de 1 até a quantidade de executores do LAT):

1. Algum executor ainda aguardando o gerente de projetos → **Pendente - Gerente de projeto**.
2. Todos os executores aprovados → **Aprovado**.
3. Algum executor ainda sem preenchimento → **Pendente - Preenchimento do(s) executor(es)**, para o próximo executor lançar.
4. Algum executor rejeitado (e nenhum dos casos acima) → **Pendente - Preenchimento do(s) executor(es)**. *Regra proposta, não confirmada pelo negócio (ver limitações, L1).*
5. Nenhum dos casos acima → o Status Geral não é alterado.

Estado: implementado e ativo em dev. Não validado em QA nem em produção.

---

## Componente técnico alterado

| API name | Tipo | Alteração |
|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow record-triggered (Update, after save) em `Lancamento_de_Atividades__c` | Nova versão **v5**, ativa em dev (Id `301Ha000014cOgXIAU`). A v4 ficou `Obsolete`. Passou a calcular `Status__c` pela regra acima. Elementos novos: formula `fxStatusGeralCalculado`, decision `Status_calculado_e_diferente`, record update `Atualiza_Status_Geral_do_LAT`. |

Arquivo: `force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml`.

Nenhum outro componente foi criado ou alterado: nenhum campo, objeto, approval process, field update, Process Builder, permission set, perfil, layout ou `FlowDefinition`.

---

## Como funciona

1. O executor preenche as horas da sua posição e envia para aprovação. O approval process coloca o Status Geral em "Pendente - Gerente de projeto". Isto já existia.
2. O gerente de projetos aprova ou rejeita um executor pelo approval process, ou a auto aprovação do gerente grava o status do executor. Isto já existia.
3. Ao salvar o LAT, o flow só segue se o Status Geral atual for Rascunho, Pendente - Preenchimento do(s) executor(es) ou Pendente - Gerente de projeto.
4. O flow calcula o valor esperado pela regra acima, olhando só o registro salvo (não consulta outros registros).
5. Se o valor calculado for vazio (caso 5), o flow não faz nada.
6. Se o valor calculado for igual ao atual, o flow não grava. Só grava quando o valor muda, para não gerar salvamentos desnecessários.
7. Se o valor mudou, grava `Status__c` numa única operação. Como o flow roda em contexto de sistema, não depende das permissões do usuário que salvou.

Observação: o flow não tem ordem definida em relação aos outros flows que rodam no mesmo salvamento (ver limitações, T1).

---

## Configuração pós-deploy

**No Flow, nenhuma.** O `<status>Active</status>` do XML ativou a v5 e tornou a v4 `Obsolete` no mesmo deploy, confirmado em dev. Não há passo manual de ativação, permission set, perfil ou layout.

**Para a correção ser validada e usável, ainda falta** (todos decisão ou execução humana):

1. Conectar `sbx-somos-agility-qa` ao ambiente de CI e agentes. Hoje ela não está conectada.
2. Fazer o deploy em QA (dry-run e depois real). Comandos na parte técnica abaixo.
3. Atribuir o permission set `Lancamento_de_atividades_admin` (ou equivalente com FLS em `Qtd_de_executores__c`, `Status_de_aprovacao_N__c` e `Executor_da_atividade_N__c`) a um usuário de teste que seja submissor ou aprovador dos approval processes `Fluxo_de_aprovacao_1/2/3_executor`. Sem isso, o usuário não consegue criar massa de teste nem ver os campos.
4. Criar massa sintética (Projeto → Marco → LAT com Qtd 1, 2 e 3), sem dado real de cliente.
5. Executar a matriz `05-testes.md` §3 (CT-03 a CT-13) e registrar resultados. Hoje ela é roteiro.
6. Antes de promover a produção: comparar a versão ativa do flow em produção com a de dev, e conferir os flows "Somatória" citados no card (D1, D2). O agente não acessa produção.

---

## Limitações e dívida técnica

- **L1 — regra de rejeição (R4) não confirmada.** O comportamento "rejeitado → Pendente - Preenchimento" é proposta do agente. Se o negócio definir outra regra, trocar o valor na fórmula é a mudança. Os casos CT-07 a CT-09 dependem disso.
- **T1 — ordem de execução (risco alto, não confirmado).** Há quatro flows after save de Update no objeto, mais um Process Builder ativo, sem `triggerOrder`. O `triggerOrder` planejado no design foi removido: o deploy (dry-run e real) em dev rejeitou o elemento em `FlowStart`, mesmo com API 68.0. A mitigação é o cálculo sobre o estado final do registro, seguido de nova gravação quando o valor muda. Essa mitigação não foi validada. Teste: CT-12.
- **T3 — disparo pelo approval process (risco médio, não confirmado).** Não foi reproduzido que a gravação do executor pelo approval process dispara o flow. Se não disparar, nem a v4 nem a v5 resolvem aprovação e rejeição. Nesse caso, o plano B do design (ações de configuração nos approval processes) vira obrigatório e volta ao arquiteto. Teste: CT-13.
- **T5 — validation rule `Checa_preenchimento_unitario_do_executor`.** Avalia o registro inteiro. Não foi testada na prática. Teste: CT-10.
- **T2, D1, D2 — paridade com produção não verificada.** O agente não acessou produção. A versão ativa de produção do flow de status e da auto aprovação não foi conferida. Os flows "Somatória" citados no card (P3) estão inativos em dev desde 2019 e, quando existiam, escreviam em `Marcos__c`, não em `Status__c`. Não se sabe se isso reflete produção.
- **T6 — registros já presos não se corrigem sozinhos.** A v5 só recalcula quando o registro é salvo de novo. Não há correção retroativa. Está fora de escopo e a decisão é humana.
- **T7 — auto aprovação sem critério de entrada.** `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` grava o status do executor em todo update. Não foi alterado. Desperdício e recursão ficam para demanda futura.
- **Fórmula com rótulos literais.** A regra compara textos exatos das picklists. Os rótulos do Status Geral e dos status de executor são diferentes (ex.: "Gerente de projeto" e "Gerente de projetos"). Renomear um valor de picklist sem atualizar a fórmula faz a regra deixar de bater, sem erro visível.
- **Valores legados não limpos.** Permanecem em `Status__c` (Pendente, Aguardando Aprovação, Recall, Rejeitado) e o approval process inativo `Solicitacao_de_aprovacao_para_atividade`.
- **Snapshot de metadata vencido.** A coleta do recon (`02-recon.md`) foi feita em 2026-10-21 e o próprio documento indica validade até 2026-10-28. Reconferir a org antes de QA e de qualquer promoção.
- **Origem do bug desconhecida (L4).** Pista: a v4 do flow é de 2026-06-08. Não confirmado.
- **Impacto, urgência e janela de deploy não informados (L5).** Afetam o release, não o build.
- **Anexo original da demanda não recebido (L6).** A regra veio dos comentários do card (P1).

---

## Rastreabilidade

- **Demanda:** SOMOSAGILITY-7 (somos-agility, sustentação).
- **Branch:** `feature/SOMOSAGILITY-7`.
- **Commits citados nos gates:** `15fdbfd8` (design), `eb2aae78` (build), `4cb73318` (homologação). O commit `e3721ce1` ("versiona Flow de status do LAT...") aparece no histórico da branch e é a referência de rollback da parte técnica abaixo.
- **Pacote de deploy:** `manifest/package.xml` (só o Flow acima, versão de API 67.0).
- **PR:** **número não confirmado.** Nesta sessão não há acesso a shell, então não foi possível rodar `gh pr view`. Confirmar o número e o estado do PR antes de publicar este documento.
- **Deploy em dev:** dry-run e deploy real retornaram `Succeeded`. O Deploy ID não consta nos artefatos e não foi inventado.
- **Deploy em QA:** nenhum. Não existe Deploy ID de QA.
- **Gates (`gates.md`):** análise aprovada por Carlos Sordi em 2026-10-21; design por Carlos Sordi em 2026-10-22; build por Carlos Sordi em 2026-10-23; homologação por Juliana Mendes em 2026-10-28, sobre `05-testes.md`.
- **Estimativa:** 10 h, aprovada pelo cliente em 2026-10-22 (comentários do card).

---

# Parte técnica do release (agente `release`, 2026-10-28)

**Cliente:** somos-agility · **Agente:** `release` · **Data desta sessão:** 2026-10-28
**Entradas:** `04-plano-build.md`, `05-testes.md`, `gates.md` (homologação aprovada por
Juliana Mendes em 2026-10-28T22:50:16Z, sobre `05-testes.md`).

---

## 0. Estado do ambiente confirmado nesta sessão

```
sf org list
```

retornou **apenas**:

| Type | Alias | Status |
|---|---|---|
| Sandbox | `sbx-somos-agility-dev` | Connected |

`sbx-somos-agility-qa` **não aparece conectada**. Nenhum alias presente contém `prod`,
`prd` ou `production` — não há risco de produção nesta sessão, mas também não há como
cumprir a regra da esteira de que o release entrega na sandbox onde a homologação
aconteceu (`sbx-somos-agility-qa`).

Pela regra de ambientes do squad (`src/salesforce_agents/ambientes.py` e a instrução desta
tarefa): o alvo do release é `sbx-somos-agility-qa`, não `sbx-somos-agility-dev`. Deployar em
dev "fingindo" ser o release do QA não é uma opção — seria entregar num ambiente diferente
daquele em que `05-testes.md`/a homologação de Juliana Mendes se basearam (e que, registrado
em `05-testes.md` §0, nem sequer rodou lá: a matriz de testes virou roteiro escrito por falta
de `sbx-somos-agility-qa` conectada naquela sessão também).

## 1. Resultado desta etapa: BLOQUEADO (ambiente)

- **Dry-run:** **não executado.** Não há org `sbx-somos-agility-qa` conectada contra a qual
  rodar `sf project deploy start --dry-run --target-org sbx-somos-agility-qa`.
- **Deploy real:** **não executado**, pelo mesmo motivo. Nenhum comando `sf project deploy
  start` foi rodado nesta sessão contra organização nenhuma.
- **Deploy ID:** não existe — não houve deploy.
- Isto é um bloqueio real de ambiente, registrado como tal, não contornado. Não tentei
  adivinhar outro alias nem usar `sbx-somos-agility-dev` como substituto do QA.

## 2. Pacote preparado para quando `sbx-somos-agility-qa` conectar

Componente único alterado por esta demanda (confirmado em `04-plano-build.md` §1 e §4,
v5 `Active`/v4 `Obsolete` em dev via Tooling API):

| Componente | Tipo | API name | Arquivo |
|---|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow (record-triggered, Update, after-save) | `Atualiza_o_status_final_de_aprovacao_do_LAT` | `force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml` |

`manifest/package.xml` criado nesta sessão, só com esse componente:

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

Nenhum outro componente (objeto, campo, permission set, layout, flowDefinition) faz parte
deste pacote — consistente com `04-plano-build.md` §5 e §8 (FlowDefinition explicitamente
não tocado, para não arriscar reativar a v4 por cima da v5).

### Comandos prontos para rodar assim que `sbx-somos-agility-qa` conectar

```
sf project deploy start --dry-run --target-org sbx-somos-agility-qa --manifest manifest/package.xml
# se Succeeded:
sf project deploy start --target-org sbx-somos-agility-qa --manifest manifest/package.xml
# confirmação pós-deploy (Tooling API):
sf data query --target-org sbx-somos-agility-qa --use-tooling-api \
  --query "SELECT Id, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'Atualiza_o_status_final_de_aprovacao_do_LAT'"
```

Resultado esperado no último comando: a nova versão (previsivelmente v5, mas confirme o
número real — QA pode ter histórico de versões diferente de dev) em `Active`, a versão
anteriormente ativa em `Obsolete`. Isso reproduz o que já foi observado em dev
(`04-plano-build.md` §4) — não presuma o número da versão sem consultar.

## 3. Plano de rollback

O release ainda não aconteceu, então não há nada para reverter em QA agora. Este plano fica
registrado para quando o deploy real rodar:

1. **O que reverter:** a ativação da nova versão do Flow `Atualiza_o_status_final_de_aprovacao_do_LAT`
   em `sbx-somos-agility-qa` (e, depois, em produção — fora do escopo deste agente).
2. **Como reverter:** Flow não tem "undeploy" — a versão anterior (a que estava `Active`
   antes deste release) não é apagada, ela só vira `Obsolete` automaticamente quando a nova
   é ativada. Para reverter:
   - Setup → Flows → abrir `Atualiza_o_status_final_de_aprovacao_do_LAT` → aba de versões →
     selecionar a versão anterior (a que estava ativa antes deste deploy) → **Activate**.
     Isso reativa a versão anterior e torna a nova versão `Obsolete` — sem precisar de
     deploy de metadata nenhum, é uma ação de clique na UI (ou via Tooling API
     `PATCH /services/data/vXX.0/tooling/sobjects/Flow/<Id da versão anterior>` com
     `{"Metadata": {"status": "Active"}}`, se preferir via API).
   - Alternativa via deploy de metadata: re-deployar o XML da versão anterior (disponível no
     histórico do git, commit anterior a `e3721ce1` na branch `feature/SOMOSAGILITY-7`, ou na
     branch `baseline/somos-agility`) com `<status>Active</status>`, criando uma nova versão
     com o conteúdo antigo. Mais lento e cria uma versão extra no histórico — preferir a
     reativação direta pela UI/Tooling API acima.
   - **Confirmar após reverter** (mesma query do passo anterior): a versão desejada deve
     aparecer `Active`, a v5 (ou a que foi desativada) deve aparecer `Obsolete`.
3. **Não há dado a reverter**: este deploy não grava, altera nem migra dados — é só uma nova
   versão de lógica de automação. Registros que já tiverem sido recalculados pela v5 antes do
   rollback **não são desfeitos automaticamente**; se algum `Status__c` tiver sido alterado
   de forma indesejada, a correção de dados é uma ação manual separada (fora de escopo deste
   release) — seria necessário identificar os registros afetados via `CreatedDate`/
   `LastModifiedDate` do Flow e corrigir campo a campo ou com um job de correção pontual.
4. **Risco a reavaliar antes do rollback**: se o motivo do rollback for o comportamento de
   R4 (regra L1, ainda não confirmada pelo negócio conforme `05-testes.md` §2), considere se
   o problema é a lógica em si (reverter) ou só a regra L1 (nesse caso, talvez seja melhor
   uma nova versão corrigindo R4 em vez de reverter para a v4, que tinha o bug original que
   esta demanda corrige).

## 4. Passos manuais pós-deploy

Nenhum passo manual é necessário **para o deploy do Flow em si** — `04-plano-build.md` §7
confirma que `<status>Active</status>` no XML já ativa a nova versão e obsoleta a anterior
no mesmo deploy, sem FlowDefinition, permission set, layout ou perfil envolvidos nesta
demanda.

Porém, antes que o roteiro de QA (`05-testes.md` §3, CT-03 a CT-13) possa de fato rodar em
`sbx-somos-agility-qa`, os seguintes passos manuais — já sinalizados em `04-plano-build.md`
§9 e `05-testes.md` — continuam pendentes e são decisão/execução do humano, não deste agente:

1. Conectar `sbx-somos-agility-qa` ao ambiente de CI/agentes (pré-requisito para este próprio
   release rodar).
2. Atribuir o permission set `Lancamento_de_atividades_admin` (ou equivalente com FLS nos
   campos do modelo de 3 executores: `Qtd_de_executores__c`, `Status_de_aprovacao_N__c`,
   `Executor_da_atividade_N__c`) a um usuário de teste em QA que também seja
   submissor/aprovador dos approval processes `Fluxo_de_aprovacao_1/2/3_executor`.
3. Criar massa sintética (Projeto → Marco → LAT, sem dado real de cliente) para exercitar a
   matriz de testes CT-03 a CT-13.
4. Depois do deploy em QA, rodar de fato a matriz de `05-testes.md` §3 — ela foi homologada
   como roteiro, não como resultado executado; os riscos T1 (ordem entre flows, sem
   `triggerOrder`) e T3 (disparo do flow pelo field update do approval) seguem sem
   confirmação prática até isso acontecer.
5. Promoção para produção (fora do escopo deste agente, e da sandbox QA): decisão humana
   separada, com janela própria, depois que o roteiro acima for confirmado em QA.

## 5. Resumo

- **Componente:** `Atualiza_o_status_final_de_aprovacao_do_LAT` (Flow), pacote isolado em
  `manifest/package.xml`.
- **Org alvo da esteira:** `sbx-somos-agility-qa`.
- **Resultado desta sessão:** release **bloqueado** — `sbx-somos-agility-qa` não está
  conectada nesta sessão (`sf org list` mostrou só `sbx-somos-agility-dev`). Nenhum deploy
  (dry-run ou real) foi executado. Nenhum alias de produção apareceu ou foi tocado.
- **Pronto para quando o ambiente for liberado:** pacote (`manifest/package.xml`), comandos
  de dry-run/deploy/verificação, plano de rollback e lista de passos manuais pós-deploy,
  todos acima.
- Esta sessão termina aqui — não há continuação em background. O próximo passo depende de
  um humano conectar `sbx-somos-agility-qa` e rodar (ou acionar o agente `release`
  novamente) os comandos da seção 2.
