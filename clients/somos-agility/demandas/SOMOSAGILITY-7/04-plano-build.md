# SOMOSAGILITY-7 — Plano de build (executado)

**Cliente:** somos-agility · **Org:** `sbx-somos-agility-dev` (confirmado `Connected`, único alias
na allowlist `sbx-<cliente>-dev|qa`) · **Data:** 2026-10-22
**Entradas:** `03-design.md` (aprovado em `gates.md`), `02-recon.md`, `comentarios-do-card.md`.

---

## 1. Componente alterado

| Componente | Tipo | API name | Mudança |
|---|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow record-triggered (Update, after-save) | `Atualiza_o_status_final_de_aprovacao_do_LAT` | Nova versão **v5** (v4 vira Obsolete automaticamente) |

Arquivo: `clients/somos-agility/force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml`.

Trazido para a working tree a partir de `origin/baseline/somos-agility` (v4) e editado conforme
`03-design.md` §4. Também foi trazido `clients/somos-agility/sfdx-project.json` (não existia ainda
nesta branch; necessário para `sf project deploy start` reconhecer o `force-app` como diretório de
pacote). O `flowDefinition-meta.xml` correspondente **não** foi trazido nem deployado — ver §5.

## 2. O que foi implementado

- **Entrada do flow (start):** inalterada — `Status__c` ∈ {Rascunho, Pendente - Preenchimento
  do(s) executor(es), Pendente - Gerente de projeto}, Update, after-save, objeto
  `Lancamento_de_Atividades__c`, exatamente como no design (a).
- **Formula resource `fxStatusGeralCalculado`** (String), implementando a tabela §2 do design por
  `IF(ISPICKVAL(Qtd_de_executores__c, "N"), ...)` aninhado, cobrindo Qtd 1/2/3 com os secundários
  em uso (1..N):
  - R1: algum secundário em uso = `Pendente - Gerente de projetos` → `Pendente - Gerente de projeto`
  - R2: todos os secundários em uso = `Aprovado` → `Aprovado`
  - R3: algum secundário em uso = `Pendente - Preenchimento do executor` → `Pendente - Preenchimento do(s) executor(es)`
  - R4: algum secundário em uso = `Rejeitado` (nenhum dos casos acima) → `Pendente - Preenchimento do(s) executor(es)`
  - R5: nenhum dos casos → `""` (vazio = sinal de "não mexer")
  - Avaliação por `IF` em cascata na ordem R1→R2→R3→R4, igual à tabela (a primeira que bate
    decide). Validado em Python fora da org, simulando a fórmula para os 9 cenários-chave
    (Qtd 1/2/3 × Aprovado-total/Pendente-GP parcial/Rejeitado parcial) — todos bateram com o
    esperado antes do deploy.
  - Valores dos secundários conferidos contra
    `objects/Lancamento_de_Atividades__c/fields/Status_de_aprovacao_1__c.field-meta.xml` (trazido
    da baseline) antes de escrever a fórmula — rótulos confirmados: `Pendente - Gerente de
    projetos` (plural, diferente do geral), `Pendente - Preenchimento do executor` (singular,
    diferente do geral), `Aprovado`, `Rejeitado`. Nenhum valor inventado.
- **Decision `Status_calculado_e_diferente`:** só segue para o Update quando
  `fxStatusGeralCalculado` não é vazio **e** é diferente de `$Record.Status__c` (idempotente, sem
  save à toa) — opção (c) do design.
- **Record Update `Atualiza_Status_Geral_do_LAT`:** um único Update Records em `$Record`, gravando
  `Status__c` = `fxStatusGeralCalculado` — opção (d).
- **Descrição da versão** (campo `<description>` do Flow) cita SOMOSAGILITY-7 e resume o
  comportamento novo — opção (f).

## 3. Desvio do design: `triggerOrder` não é deployável nesta org

O design (§4, item e) pedia `triggerOrder` alto (ex.: 900) para rodar depois de
`Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` no mesmo save. Tentei isso
primeiro (`<triggerOrder>900</triggerOrder>` dentro de `<start>`, em duas posições diferentes na
sequência) e o `sf project deploy start --dry-run` rejeitou nas duas vezes com:

```
Error parsing file: Element {http://soap.sforce.com/2006/04/metadata}triggerOrder invalid at this
location in type FlowStart
```

Com `--api-version 68.0` (a máxima da org) o erro persistiu — não é questão de versão do arquivo.
Conclusão: `triggerOrder` não é um campo aceito pelo schema `FlowStart` que esta org/CLI valida no
deploy de metadata (a ordenação via Flow Trigger Explorer, quando existe, não é exposta assim aqui).
**Não é uma decisão minha reabrir o design** — é uma restrição técnica de deploy descoberta durante
o build. Removi o `triggerOrder` do XML (o flow ficou sem ele) e sigo com a mitigação primária que
o próprio design já descrevia como suficiente: o cálculo é feito inteiramente sobre o estado final
de `$Record` (sem depender de quem gravou antes) e só grava quando o valor muda — se
`Atualiza_o_status_final_...` rodar antes de `Fluxo_de_auto_aprovacao_...` no mesmo save, o save
recursivo disparado por este último dispara `Atualiza_o_status_final_...` de novo e o valor se
corrige. O risco T1 do design (ordem indeterminada entre os 4 flows) continua registrado como
**Alta severidade**, agora sem a mitigação secundária do `triggerOrder` — fica para o QA confirmar
na prática (roteiro de GP aprova 1 de 2/3 executores) que a recursão realmente corrige o valor.
Reporto isso explicitamente aqui em vez de improvisar um mecanismo alternativo não aprovado (ex.:
Process Builder de ordenação, pausa, etc.).

## 4. Deploy

Comando: `sf project deploy start --target-org sbx-somos-agility-dev --source-dir
force-app/main/default/flows/Atualiza_o_status_final_de_aprovacao_do_LAT.flow-meta.xml`

- Alias confirmado antes do deploy: `sf org list` mostrou **apenas**
  `sbx-somos-agility-dev` (Sandbox, Connected) — nenhuma outra org conectada neste ambiente.
- `--dry-run` (check-only) rodou primeiro e retornou `"status": "Succeeded"`.
- Deploy real rodou em seguida: `"status": "Succeeded"`, `numberComponentErrors: 0`,
  `Atualiza_o_status_final_de_aprovacao_do_LAT` como `Flow` / `state: Changed`.
- Confirmação pós-deploy via Tooling API (`SELECT Id, VersionNumber, Status FROM Flow WHERE
  Definition.DeveloperName = 'Atualiza_o_status_final_de_aprovacao_do_LAT'`): versão **5** ficou
  `Active` e a versão 4 (antes ativa) virou `Obsolete` automaticamente — **nenhum passo manual de
  ativação foi necessário**; `<status>Active</status>` no XML já é suficiente nesta org para
  ativar a nova versão e obsoletar a anterior no mesmo deploy.

## 5. Sobre o `FlowDefinition`

Decidi **não** trazer nem deployar
`force-app/main/default/flowDefinitions/Atualiza_o_status_final_de_aprovacao_do_LAT.flowDefinition-meta.xml`
nesta rodada. A versão trazida da baseline tinha `<activeVersionNumber>4</activeVersionNumber>`
hardcoded; se esse arquivo fosse deployado junto, ele arriscava reativar a v4 por cima da v5 que
acabou de ser criada (o número da nova versão só existe depois do deploy do Flow em si). Deployar
só o Flow, deixando a plataforma criar e ativar a versão nova a partir do `<status>Active</status>`
do próprio componente, evitou esse risco. Nenhum arquivo `flowDefinition-meta.xml` foi criado,
editado nem commitado nesta demanda.

## 6. Validação funcional — o que foi possível e o que não foi (T3)

Tentei reproduzir o cenário completo (GP aprova 1 de N executores, GP rejeita) criando massa de
teste sintética em `sbx-somos-agility-dev`, começando por um registro mínimo de
`Lancamento_de_Atividades__c`:

```
sf data create record --target-org sbx-somos-agility-dev --sobject Lancamento_de_Atividades__c \
  --values "Status__c='Rascunho' Qtd_de_executores__c='1' Status_de_aprovacao_1__c='Aprovado'"
```

Resultado: `INVALID_FIELD — No such column 'Qtd_de_executores__c' on sobject of type
Lancamento_de_Atividades__c`. Isso **confirma exatamente o achado de FLS já registrado em
`02-recon.md` §1**: o usuário autenticado no alias (`Konecta Consultoria`) não tem FLS nos campos
do modelo de 3 executores (`Qtd_de_executores__c`, `Status_de_aprovacao_N__c`,
`Executor_da_atividade_N__c`), então a API nem reconhece o campo para esse usuário — não é possível
criar ou atualizar esses campos via `sf data` com a sessão atual.

Por isso:
- **Não consegui** reproduzir o bug nem validar a fórmula com dados de verdade (nem via approval
  process de verdade, nem via `sf data update record` simulando o field update do approval), porque
  a barreira é anterior a isso: nem dá para popular os campos de entrada.
- **Não atribuí** o permission set `Lancamento_de_atividades_admin` a esse usuário — o design (§7)
  é explícito que isso é decisão do humano, não do agente, e não é minha decisão reabrir isso.
- **Validei a lógica fora da plataforma**: simulação da fórmula em Python com os 9 cenários-chave
  (R1 a R5, Qtd 1/2/3) reproduzindo a cascata de `IF`/`ISPICKVAL` linha a linha — todos bateram com
  a tabela do design (§2 do `03-design.md`). Isso cobre a corretude da fórmula, **não** cobre se o
  flow dispara corretamente quando o approval process grava o secundário (T3 do design segue sem
  confirmação).
- O deploy em si (dry-run + real) confirma que o XML é sintaticamente válido e aceito pela
  plataforma, e que a nova versão ficou ativa.

**Isto é input direto para a etapa de QA**: o roteiro de teste em `sbx-somos-agility-dev` precisa
rodar com um usuário que tenha `Lancamento_de_atividades_admin` (ou outro papel com FLS nesses
campos) atribuído — decisão/execução do humano — para exercitar a matriz completa: Qtd 1/2/3 ×
(todos aprovados / aprovação parcial / rejeição parcial) × GP aprovando via approval process real
(para confirmar T3: que o field update do approval dispara o flow) e também GP via
`Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` (fluxo de auto aprovação, que
grava o secundário sem approval process).

## 7. Passos manuais pós-deploy

Nenhum. `<status>Active</status>` já ativou a v5 e obsoletou a v4 no mesmo deploy (confirmado via
Tooling API, §4). Não há FlowDefinition para ajustar (não foi tocado, §5). Não há permission set,
layout ou perfil alterado nesta demanda (confirmado no design §7 — fora de escopo).

## 8. O que NÃO foi feito (reforçando `03-design.md` §9)

Nenhum approval process, field update, Process Builder, campo, objeto ou permission set foi
criado/alterado. Nenhuma massa de teste foi commitada (a tentativa de criação em §6 falhou antes de
gravar qualquer registro, então não há dado sintético nem no pacote nem na org). Nenhum ambiente
além de `sbx-somos-agility-dev` foi tocado.

## 9. Resumo para o QA (próxima etapa)

1. Confirmar com o humano a atribuição do permission set `Lancamento_de_atividades_admin` (ou
   equivalente) a um usuário de teste em `sbx-somos-agility-dev`, e garantir que esse usuário é
   submissor/aprovador dos 3 approval processes (`Fluxo_de_aprovacao_1/2/3_executor`).
2. Criar massa sintética (Projeto → Marco → LAT) com Qtd 1, 2 e 3.
3. Rodar a matriz: todos aprovados (R2), aprovação parcial com restante pendente (R1), rejeição de
   um executor (R4), e confirmar que `Status__c` muda exatamente como a tabela do design prevê —
   isso valida T3 (disparo do flow pelo approval) que ficou sem confirmação nesta etapa.
4. Confirmar que o caminho de auto aprovação do GP (`Fluxo_de_auto_aprovacao_...`) também resulta no
   `Status__c` correto, inclusive quando roda no mesmo save que `Atualiza_o_status_final_...`
   (valida a mitigação de T1 descrita em §3 acima, já que `triggerOrder` não pôde ser aplicado).
5. Validar o caso T5 (validation rule `Checa_preenchimento_unitario_do_executor`) não bloqueia o
   update do flow (ele roda em contexto de sistema, mas vale confirmar na prática).
