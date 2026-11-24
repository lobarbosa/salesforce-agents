**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 8, correção do caminho por código no Flow v8)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy da esteira: `0AfHa00000ENIqcKAH` (Succeeded, commit `76ee4faa`). Só registros criados por mim (`TESTE EPLAST-27`), todos apagados. Nenhum registro existente lido ou alterado (só contagens agregadas).

**Retorno da rodada anterior (`05-testes-rodada-6.md`):** a FALHA 1 (código que casa uma ou mais contas devolvia `AMBIGUOUS` com lista vazia) **foi corrigida**. Código de uma conta devolve a ação da conta, código de duas contas devolve a lista, código de conta de outro dono devolve `NOT_OWNER`. Nenhuma falha nesta rodada.

## Falhas
Nenhuma.

## Estado antes e depois (ativação)
- Flow `Account_Agente_ProximaAcao`: antes, v7 Ativa (rodada anterior) e v8 Rascunho (a da demanda). Para testar, implantei de novo só esse Flow com `<status>Active</status>` (conteúdo idêntico ao repositório; arquivo local restaurado, sem commit). Depois: **v8 Ativa**, v7 Obsoleta (consulta em `Flow`). Fica ativa.
- Agente `SFAgent2`: ativa **v17** (de outra demanda, que já contém a ação `ProximaAcaoCliente_EPLAST27_v17` apontando para o mesmo Flow) antes e depois; v15 (a deste build) segue Inativa. Não ativei a v15 porque ela desligaria a v17, mais nova, com o trabalho das outras demandas (EPLAST-29, 34 e 46 usam o mesmo agente). A assinatura da ação não mudou, então a conversa foi testada na v17 ativa, que chama o Flow v8.

## Casos (critérios do design de 24/11: casos da decisão de 23/11 mais conta de outro dono e conversa)
Massa: fixtures `conta-oportunidade-proxima-acao.apex` e `conta-codigo-protheus.apex`. Códigos conferidos por contagem: 927001 (1 conta), 927002 (2 contas), 927004 e 927006 (1 cada); total 5 contas na org com esses códigos, todas minhas, então não há colisão com contas reais. Cada chamada em Apex anônimo separado (`Flow.Interview.Account_Agente_ProximaAcao`), como Administrador com `PS_Comercial_ProximaAcao`.

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1. Id válido 18 caracteres (regressão) | `recordId` = Id da C1 | `A1` | `A1` "Tratar risco da conta: o cadastro está com risco E..." | passou |
| 1b. Id de 15 caracteres | `recordId` = 15 caracteres da C4 | `NONE` | `NONE` "Nenhuma ação prioritária no momento." | passou |
| 2. Código de uma conta | `recordId`='927001' | `A1` da C1 | `A1` mesma mensagem da C1 | passou |
| 3. Código de duas contas | `recordId`='927002' | `AMBIGUOUS` com as 2 contas | `AMBIGUOUS` "Encontrei mais de uma conta com esse código: TESTE EPLAST-27 C2 A2 parada (loja 001); TESTE EPLAST-27 C3 A3 inativo (loja 002); Diga qual delas você quer." | passou |
| 4. Código inexistente | `recordId`='927999' | `NOT_FOUND` | `NOT_FOUND` "Não encontrei conta com esse código que você possa ver." | passou |
| 5. Texto que não é Id nem código | `recordId`='abc-xyz' | sem erro, não encontrada | `NOT_FOUND`, mesma mensagem, sem falha do Flow | passou |
| 6. Só nome da conta (regressão) | `accountName`='TESTE EPLAST-27 C2' | caminho por nome | `A2` "Retomar oportunidade parada: ... 31 dias." | passou |
| 7. Código de conta de outro dono | `recordId`='927006' (C6) | `NOT_OWNER` | `NOT_OWNER` "Esta conta não está na sua carteira." | passou |
| 8. Regressão A3 | Id da C3 | `A3` | `A3` "Reativar cliente sem compra recente..." | passou |
| 9. Regressão NODATA | Id da C5 | `NODATA` | `NODATA` "Dados insuficientes: ..." | passou |
| 10. Risco fora da lista (C7) | Id da C7 | não A1; cai em A2 | `A2` "...sem atividade há 45 dias." | passou |
| 11. Não grava | `LastModifiedDate` da conta lido antes e depois da chamada (C3, C5, C7) | igual | `mesmaData=true` nas 3 | passou |
| 12. Conversa com o agente passando o código | `sf agent preview start/send/end` (SFAgent2 v17 ativa): "Qual a próxima melhor ação para a conta com código 927001?" e "E para o código 927002?" | ação da C1; lista das duas contas | 1ª: "A próxima melhor ação ... é: Tratar risco da conta: o cadastro está com risco E..."; 2ª: "Encontrei mais de uma conta com esse código: TESTE EPLAST-27 C2 A2 parada (loja 001); TESTE EPLAST-27 C3 A3 inativo (loja 002). Diga qual delas você quer." | passou |
| 13. Formato do código (premissa da decisão de 23/11) | contagem na rodada anterior | 6 dígitos | 1209 de 1210 preenchidas em 6 dígitos (rodada 6); não repetido | passou (rodada anterior) |
| Retestes não repetidos: A2 por limiar do CMDT em 60, 150 oportunidades numa conta, carteira por perfil, sem chamada externa | — | — | não reexecutados: a mudança desta versão é só o ramo do código. Constam como aprovados na rodada anterior; o Flow segue sem e-mail nem DML (leitura estática) e o caso 11 confirma que não grava | não reexecutado |
| Limitação conhecida da continuação (decisão de 16/11) | — | — | não reexecutada; aceita por decisão. Observação: na conversa 2, o agente listou as duas contas e pediu a escolha, sem erro | aceito |
| Teste Apex | — | — | demanda sem classe Apex nova | não aplicável |

Telas: nenhuma captura; casos executados por Apex e pré-visualização do agente, sem tela.

## Premissas assumidas
Nenhuma nova. A decisão de 23/11 (código da conta = `ProtheusId__c`, igualdade) segue válida e é repetida no roteiro do cliente.

## Mudanças feitas e desfeitas
- `PS_Comercial_ProximaAcao`: 0 atribuições antes, 1 (a mim, usuário `005bJ00000piKAaQAM`) durante, 0 depois (consulta).
- Mesmo usuário, `ProtheusSellerId__c`: antes `null`, durante `TESTE27`, depois `null`; 0 usuários com `TESTE27`.
- Marketing User: não liguei.
- Usuário de teste da Konecta (`005bJ00000hBJmYQAW`) inativo; não usado.

## O que pode ter saído da org
- A automação existente criou Cases de pós-vendas nas oportunidades ganhas da massa; apagados antes das contas, junto com Tasks, oportunidades, Branch e PaymentTerms de teste. Nenhum e-mail, mensagem ou campanha disparados por mim. Marketing Cloud: nada feito.
- A massa foi criada com `TriggerUtility.bypassTrigger`, sem envio ao Protheus. Não medi `IntegrationLog__c` por contagem de antes e depois nesta rodada (a QAS recebe tráfego de outros usuários), então a ausência de chamada externa se apoia na leitura estática do Flow e no desvio da trigger.
- Limpeza conferida por consulta: 0 Account, 0 Task, 0 Branch__c `TESTE EPLAST-27%`.
- Sessão de pré-visualização do agente encerrada (`preview end`).
