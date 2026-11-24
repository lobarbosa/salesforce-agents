**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (a ação aceita o código da conta no lugar do Id)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado. Fonte: `03-design.md`, seção "Decisão do responsável (2026-11-23): a ação aceita o código da conta no lugar do Id". As decisões das rodadas 4 e 5 (nome da conta, limitação da pergunta de continuação) continuam valendo e não foram alteradas.

## Estado encontrado
- Flow `Account_Agente_ProximaAcao` na dev: v1 Obsoleta, **v2 Ativa**, v3 Draft (nome da conta, ainda não ativada). A v2 ativa não foi editada.
- `SFAgent2` na dev: v1 a v18, **v13 ativa**. Nenhuma versão nova do agente: a assinatura da ação `ProximaAcaoCliente` (entradas `recordId` e `accountName`) não mudou, como manda o design. Pacote do agente da branch intocado.
- Conferência do campo do código (exigida pelo design): `Account.ProtheusId__c` ("ID da Conta no Protheus", Text 255, External Id, não único) existe na dev. Na dev há 2 contas e **0 com `ProtheusId__c` preenchido**, então o formato de 6 dígitos **não pôde ser confirmado por contagem agregada na dev**. Evidência na metadata e no código: `OrderUtility` envia `Account.ProtheusId__c` com `Account.Store__c` ao Protheus como identificação do cliente, e os testes Apex da org usam valores de 6 dígitos (`'123457'`). Nenhum outro campo de Account se apresenta como código do cliente (busca por rótulo e nome entre os custom de texto e número: só `ProtheusId__c`, `Store__c` e `Loja__c`). Decisão pela regra 4 da conta (org, depois padrão): segue com `ProtheusId__c`, é campo único de troca no Flow se a Eplast disser outro. Ver premissas.

## Componentes alterados
| Componente | Detalhe | Caminho |
|---|---|---|
| Flow `Account_Agente_ProximaAcao` (Draft) | Antes de `GetAccount`, nova decisão `IsIdShape` (fórmula `IsAccountIdShape`: 15 ou 18 caracteres e começa por `001`). Forma de Id: caminho de antes (`GetAccount` por Id). Qualquer outro `recordId` preenchido: marca `byCode` e busca `Account` por `ProtheusId__c` igual ao texto (`GetAccountsByCode`, todas as contas, ordem por nome). Resultado: nenhuma conta, `NOT_FOUND` com "Não encontrei conta com esse código que você possa ver."; uma, usa o Id dela e segue por `GetAccount` (inclui a regra de dono `RestrictToOwner__c`); várias, reaproveita o laço da busca por nome e devolve `AMBIGUOUS` com até 5 itens, **com a loja** (`Store__c`) ao lado do nome, pedindo para escolher. `GetAccountsByCode` tem `faultConnector` para `NOT_FOUND`. Caminho por nome e por Id não mudou (a lista por nome só ganha a loja se for busca por código). Sem DML, sem e-mail. | `force-app/main/default/flows/Account_Agente_ProximaAcao.flow-meta.xml` |
| Permission set `PS_Comercial_ProximaAcao` | Edição aditiva: leitura (sem edição) de `Account.ProtheusId__c` e `Account.Store__c`. Nada removido; descrição atualizada. | `force-app/main/default/permissionsets/PS_Comercial_ProximaAcao.permissionset-meta.xml` |

Deploy na `sbx-eplast-dev` (ID `0AfHa00000ENGaHKAX`): Succeeded, 2 componentes. Consulta de versões do Flow depois do deploy: v1 Obsoleta, v2 Ativa, v3 Draft.

## Versões e ativação
- **Atenção sobre a numeração:** o design chama a correção de "v4", mas na dev a v3 era Draft nunca ativada e o deploy sobre uma versão Draft a atualiza em vez de criar outra. Resultado: na dev a correção está na **v3 Draft** (que reúne nome da conta e código). A v2 ativa, a única em uso, não foi tocada. Na QA, onde a esteira implanta sobre a versão ativa, o deploy gera a versão seguinte.
- Ativação **não feita**. Flow: v2 segue ativa; v3 Draft. Agente: v13 segue ativa; v15 (build anterior) segue inativa e sem mudança.
- **Ordem para verificação e QA:** a ação do agente chama a versão **ativa** do Flow. Para exercitar nome e código é preciso ativar o Flow (passo à parte, da esteira/QA), depois a v15 do agente. Sem a ativação, o Flow ativo é a v2 e o código cai no caminho do Id.

## Interação com EPLAST-29, 34 e 46
Todas mexem no agente `SFAgent2`. Este build **não toca em nenhum arquivo do agente** (`genAiPlannerBundles`, `bots`): só o Flow da própria demanda e o permission set `PS_Comercial_ProximaAcao`, que nenhuma delas usa. Portanto nada delas foi removido, editado nem sobreposto. Como a assinatura da ação não mudou, não há nova versão do agente a conciliar com v16 a v18.

## Premissas assumidas (validar na homologação)
- **Campo do código = `Account.ProtheusId__c`.** Evidência: metadata, uso no envio ao Protheus e testes com 6 dígitos; a dev não tem conta com o campo preenchido, então o formato não foi medido nela. Mudar: trocar o campo no filtro de `GetAccountsByCode`.
- **Comparação por igualdade exata.** Código com zeros à esquerda (`000682`) casa só com o mesmo texto. Se a Eplast guardar sem zeros, não casa; ajustar o campo ou completar com zeros no Flow.
- **Mesmo código em lojas diferentes** devolve a lista com a loja (`Store__c`) para escolha; o Flow não escolhe sozinho.
- `recordId` não vazio e sem forma de Id vale como código mesmo se vier um nome; o resultado é `NOT_FOUND` com mensagem de código. Nome só pelo `accountName`.
- Id malformado com forma de Id (começa por `001`, 15 ou 18 caracteres, mas inválido) ainda cai na falha tratada do `GetAccount` (resposta "não está na sua carteira"), como na v2; não alterado.

## Para a verificação
Massa sintética: contas `TESTE EPLAST-27` com `ProtheusId__c` preenchido por script de `fixtures/` (as 2 contas da dev não têm). Criar uma conta com código único de 6 dígitos, duas contas com o mesmo código e lojas diferentes, e usar o Id de uma delas. Com `TriggerUtility.bypassTrigger` (regra da conta: Protheus/AccountTrigger). Em todos os casos o Flow termina sem erro e com a mensagem certa:
1. `recordId` com Id válido (regressão).
2. `recordId` com código que casa uma conta: devolve a ação da conta (A1, A2, A3, NONE ou NODATA); testar também conta de outro dono (`NOT_OWNER` com `RestrictToOwner__c`).
3. Código que casa duas contas: `AMBIGUOUS` com nome e loja.
4. Código inexistente: `NOT_FOUND` de código.
5. Texto qualquer que não é Id nem código: `NOT_FOUND`.
6. `recordId` vazio com `accountName` (regressão do nome, uma, várias, nenhuma).
O Flow v3 Draft precisa estar ativo na dev para testar pela conversa; sem ativar, testar o Flow direto.

## Não testado neste build
Execução do Flow (sem ativação e sem massa com `ProtheusId__c`); só o deploy validado. Nenhum DML de dados foi feito.
