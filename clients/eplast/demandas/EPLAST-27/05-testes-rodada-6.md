**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 7, correção do código da conta no Flow v4)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy da esteira: `0AfHa00000ENHZaKAP` (Succeeded, commit `d4357f2e`). Só registros criados por mim (`TESTE EPLAST-27`), todos apagados. Nenhum registro existente lido ou alterado (só contagens agregadas).

**Resumo:** a correção pedida (aceitar o código da conta no lugar do Id) **não funciona**: qualquer código que case com uma ou mais contas devolve `AMBIGUOUS` com lista vazia. Os casos de Id, nome, código inexistente e texto qualquer passaram.

## Falhas

### FALHA 1 (crítica) — Código que casa uma conta devolve "mais de uma conta" com lista vazia
- **Reproduzir** (QA, Apex anônimo, uma chamada por execução, como Administrador com `PS_Comercial_ProximaAcao`): massa de `fixtures/conta-oportunidade-proxima-acao.apex` + `fixtures/conta-codigo-protheus.apex` (C1 = código 927001, só uma conta com esse código, conferido por contagem agregada: 1). `new Flow.Interview.Account_Agente_ProximaAcao(new Map<String,Object>{'recordId'=>'927001'}).start()`, ler `actionCode` e `message`.
- **Obtido:** `AMBIGUOUS` e "Encontrei mais de uma conta com esse código: Diga qual delas você quer." sem nenhuma conta listada. O log mostra 2 linhas lidas no total (1 do parâmetro `NextBestActionSetting` e 1 da conta), então a conta foi encontrada. Idem para 927002 (2 contas, lista vazia) e 927006 (conta de outro dono, devia ser `NOT_OWNER`, veio `AMBIGUOUS`).
- **Esperado (03-design, decisão de 23/11):** uma conta → segue com ela, mesma regra de dono (C1 → `A1`); várias → lista das contas para escolher; nenhuma → não encontrada.
- **Causa provável (lida em `Account_Agente_ProximaAcao.flow-meta.xml`):** `HasCodeMatches` envia o resultado de `GetAccountsByCode` para o loop `LoopNames`, e esse loop percorre `collectionReference = GetAccountsByName` (vazio no caminho por código). Nenhuma iteração acontece, `matchCount` fica 0 e `AfterNames` cai no padrão "Várias" (`SetAmbiguous`). Falta um loop (ou ligar o loop a uma coleção que sirva aos dois caminhos) que percorra `GetAccountsByCode`, conte, guarde o último Id e monte a lista com a loja (`Store__c`). A verificação da dev não exercitou isso (versão inativa na dev).

## Estado antes e depois (ativação)
- Flow `Account_Agente_ProximaAcao`: antes, v6 Ativa e v7 Rascunho (a da demanda); para testar, implantei de novo só esse Flow com `<status>Active</status>` (deploy `0AfHa00000ENJ1tKAH`, conteúdo idêntico ao do repositório). Depois: **v7 Ativa**, v6 Obsoleta (consulta em `Flow`). Fica ativa, como manda a regra.
- Agente `SFAgent2`: ativa v17 (outra demanda) antes e depois; v15 Inativa. Não alterei: a correção é só no Flow e a assinatura da ação não mudou.

## Casos (critérios do design: 6 casos da correção)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Formato do código em `ProtheusId__c` ("ID da Conta no Protheus") | Apex anônimo, só contagens | campo guarda 6 dígitos | 1223 contas, 1210 preenchidas, 1209 com exatamente 6 dígitos, 1 em outro formato | passou |
| 1. Id válido (18 e 15 caracteres), regressão | Flow com `recordId` = Id da C1 e Id de 15 caracteres da C4 | caminho do Id, regra normal | C1 → `A1` "Tratar risco da conta..."; C4 (15 caracteres) → `NONE` "Nenhuma ação prioritária no momento." | passou |
| 2. Código de uma conta | `recordId`='927001' (C1) | `A1` da C1 | `AMBIGUOUS`, lista vazia | **FALHOU (FALHA 1)** |
| 3. Código de duas contas | `recordId`='927002' (C2 e C3, lojas 001 e 002) | lista com as 2 contas, `AMBIGUOUS` | `AMBIGUOUS`, mas lista vazia (mensagem termina em "código: Diga qual delas você quer.") | **FALHOU (FALHA 1)**, lista não montada |
| 4. Código inexistente | `recordId`='927999' | não encontrada | `NOT_FOUND` "Não encontrei conta com esse código que você possa ver." | passou |
| 5. Texto que não é Id nem código | `recordId`='abc-xyz' | sem erro, não encontrada | `NOT_FOUND`, mesma mensagem, sem falha do Flow | passou |
| 6. Só nome da conta, regressão | `accountName`='TESTE EPLAST-27 C2' | caminho por nome | `A2` "Retomar oportunidade parada: ... 31 dias." | passou |
| Código de conta de outro dono | `recordId`='927006' (C6, dono outro vendedor) | `NOT_OWNER` | `AMBIGUOUS` (mesma causa da FALHA 1) | **FALHOU (FALHA 1)** |
| Conversa com o agente passando o código | — | — | não executado: com a ação do Flow quebrada para código, a conversa só repetiria a falha | não executado |
| Retestes dos demais critérios (A1 a A3, NODATA, NONE, não grava, sem chamada externa) | — | — | não reexecutados nesta rodada: a mudança é só o ramo novo do código; ficam como na rodada 6 (aprovada) | não reexecutado |
| Limitação conhecida da continuação (decisão de 16/11) | — | — | não reexecutada; segue aceita por decisão | não executado (aceito) |
| Chamada externa | `COUNT(IntegrationLog__c)` | sem aumento causado pelo teste | só medi 1052 ao final (sem contagem de antes); a QAS é Partial Copy e recebe tráfego de outros usuários. O Flow não tem e-mail nem DML (estático) | não conclusivo |
| Teste Apex | — | — | demanda sem classe Apex nova | não aplicável |

## Premissas assumidas
Nenhuma nova nesta rodada. Premissa da decisão de 23/11: o código da conta é `ProtheusId__c`, igualdade; confirmada pela contagem acima (1209 de 1210 em 6 dígitos).

## Mudanças feitas e desfeitas
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim, usuário `005bJ00000piKAaQAM`) durante, 0 depois (consulta).
- Mesmo usuário, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null`; 0 usuários com `TESTE27`.
- Marketing User: não liguei.
- Usuário de teste da Konecta com Id `005bJ00000hBJmYQAW` está inativo; não usado.

## O que pode ter saído da org
- A automação existente criou Cases de pós-vendas nas oportunidades ganhas da massa e Tasks; todos apagados (Cases antes das contas). Nenhum e-mail, mensagem ou campanha disparados por mim. Marketing Cloud: nada feito.
- Limpeza conferida por consulta: 0 Account, 0 Task, 0 Branch__c `TESTE EPLAST-27%`.
- Capturas de tela: nenhuma (casos executados por Apex, sem tela).
