**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-34 — Verificação do build (dev)

Org confirmada com `sf org list`: única org `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`). Todos os comandos com `-o sbx-eplast-dev`. Nada em QA, produção ou Marketing Cloud.

## O que ficou sem prova (vai ao gate humano)

1. **Roteamento ponta a ponta e R4 (texto sem número reescrito).** `sf agent preview` é interface interativa (Ink/raw mode) e falha em job de CI: `Raw mode is not supported on the current process.stdin`. Não há outro canal não interativo disponível (Agent API exige connected app). Logo não foi provado que as frases dos 4 tipos vão para `ResumoReuniao` e não para `AgregacaoPedidos`, nem que o agente mostra o texto como veio. Pessoa precisa abrir o SFAgent2 (v8 ativa) no Agent Builder ou no preview da dev e testar as 4 frases.
2. **Regressão das ações de EPLAST-27 e EPLAST-29** (agregação, consulta, identificação, próxima ação, tarefa): mesmo motivo, não executada. Evidência indireta: a v8 é cópia da v7 só com a ação nova, segundo o plano; não verifiquei o diff.
3. **Caso "lê Opportunity e não lê Order"** (PARCIAL): sem prova (licença `Salesforce` 14/14, R5).
4. **Dados de negócio:** a dev tem 0 Account, 0 Opportunity e 0 Order, e `fixtures/` não existe neste workspace. Não criei dado de teste; os critérios de números (CA-02, CA-04 conteúdo, CA-07) só têm a prova do teste Apex do builder (10 testes, 93% de cobertura, dado TESTE-EPLAST34 criado e revertido dentro do teste), que não reexecutei.

## Mudanças na dev

| Mudança | Antes | Depois | Estado final |
|---|---|---|---|
| `sf agent activate --api-name SFAgent2 --version 8` | v7 Active, v8 Inactive | v8 Active, v7 Inactive (consulta a `BotVersion`) | **v8 deixada ativa** (é o que o plano pede). Reverter: `sf agent activate -o sbx-eplast-dev --api-name SFAgent2 --version 7` |
| Permission set `PS_Comercial_ResumoReuniao` atribuído ao usuário de execução (conta de serviço da Konecta, na org `sbx-eplast-dev`, Id `005bJ00000piKAaQAM`) | sem atribuição | atribuído durante o teste | **Removido**; contagem de atribuições do PS = 0 |

Perfil, papel, outros permission sets e `UserPermissionsMarketingUser` (false) do usuário não foram tocados. Nenhum dado de teste criado, então nada a apagar. Nenhum job agendado criado.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Ativação | `sf agent activate` v8 e consulta `BotVersion` | v8 ativa, v7 sai | v8 Active, v7 Inactive | passou |
| V2 | CA-04 / CA-03 (ação, 4 tipos) | Apex anônimo (somente leitura, usuário com o PS) chamando `MeetingSummaryService.resumir` para COMERCIAL, GDD, SOP, BOARD | status OK e data/hora de corte | 4x `OK`, textos de 341/324/284/422 caracteres, `dataHoraCorte` preenchida. Base vazia, então só prova que a ação executa; conteúdo das seções e números não conferidos | passou (parcial: sem dado de negócio) |
| V3 | CA-08 (tipo inválido) | Mesmo Apex com tipo `xyz` | mensagem de erro, sem resumo | status `ERRO`, texto de 59 caracteres | passou |
| V4 | CA-05 sem gravação | Contagem de Account, Opportunity, Order antes e depois das chamadas | sem mudança | 0/0/0 antes e depois (MAX LastModifiedDate nulo). Prova fraca: base vazia | passou (fraca) |
| V5 | CA-06 sem envio | Contagem de `EmailMessage` antes e depois | sem mudança | 0 antes e depois | passou |
| V6 | CA-09 sem agente novo | `SELECT COUNT(Id) FROM BotDefinition` | Bot existente apenas | consulta devolveu 0 linhas legíveis na saída (formato truncado); não confirmado. Plano do builder diz que só `SFAgent2` existe; não verifiquei planners | não executado |
| V7 | CA-01 acesso negado | não há usuário de perfil sem leitura de Opportunity; o teste Apex do builder cobre com `System.runAs` (`SEM_ACESSO`), não reexecutado | `SEM_ACESSO` | sem evidência minha | não executado |
| V8 | CA-02 números vs. base de 5 oportunidades | sem dado e sem fixture | contagem 5 e total S | sem evidência | não executado |
| V9 | CA-07 dado pessoal | sem dado | sem e-mail, telefone ou CPF | sem evidência | não executado |
| V10 | Roteamento e R4 | `sf agent preview` com `--use-live-actions` | roteamento correto | erro de raw mode, não rodou | não executado |
| V11 | Regressão EPLAST-27/29 | idem | ações respondem | não rodou | não executado |
| V12 | Caso PARCIAL (sem Order) | sem usuário/licença | PARCIAL | sem evidência | não executado |

## O que pode ter saído da org

Nada. Nenhum registro criado, nenhuma integração ou e-mail disparado (EmailMessage = 0).

## Para provar o que falta

Uma pessoa abre a v8 do SFAgent2 na dev (Agent Builder/preview), com `PS_Comercial_ResumoReuniao` atribuído, e executa as 4 frases de resumo e uma de cada ação existente. Para números (CA-02), é preciso um fixture de Account/Opportunity/Order `TESTE EPLAST-34`, que não existe no workspace.
