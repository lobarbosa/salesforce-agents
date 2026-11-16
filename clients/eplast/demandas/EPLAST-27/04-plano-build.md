**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (a ação aceita o nome da conta, v15)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado. Fonte: `03-design.md`, seção "Decisão do responsável (2026-11-16, rodada 4): a ação aceita o nome da conta". Corrige as falhas 1 e 2 de `05-testes-rodada-4.md`.

## Estado encontrado
- `SFAgent2` na dev: v1 a v14; **v13 ativa**, v14 inativa. A v15 não existia.
- Flow `Account_Agente_ProximaAcao`: v1 Obsoleta, **v2 Ativa**. Versão ativa não editada.
- Outras demandas no agente (EPLAST-29, 34, 46): nada removido nem editado; a v15 parte da v14 (que parte da v13).
- Nenhum DML de dados; nenhum registro de teste criado neste build.

## Componentes criados
| Componente | Detalhe | Caminho |
|---|---|---|
| Flow `Account_Agente_ProximaAcao` **v3 (Draft)** | Nova entrada opcional `accountName` (texto). Sem Id e com nome: busca `Account` com `Name` contendo o texto (ordenado por nome, no contexto do usuário). **Uma** conta: usa o Id dela e segue o fluxo de sempre (carteira, A1, A2, A3, NONE, NODATA). **Várias**: `actionCode = AMBIGUOUS` e `message` com até 5 nomes pedindo qual ("e outras" se passar de 5), sem recomendar nada. **Nenhuma** (ou sem Id e sem nome): `NOT_FOUND` e "Não encontrei conta com esse nome que você possa ver." Com Id, o comportamento é o da v2. Sem DML, e-mail ou ação de mensagem. Loop sai no 6º item (no máximo 6 iterações). | `force-app/main/default/flows/Account_Agente_ProximaAcao.flow-meta.xml` |
| `GenAiPlannerBundle` `SFAgent2_v15` (inativo) | Cópia da v14 renomeada. Muda só a ação `ProximaAcaoCliente` e a instrução da EPLAST-27 (abaixo). | `force-app/main/default/genAiPlannerBundles/SFAgent2_v15/` |
| `BotVersion` `SFAgent2.v15` (inativa) | v14 renomeada, ligada ao planner `SFAgent2_v15`. | `force-app/main/default/bots/SFAgent2/v15.botVersion-meta.xml` |

Deploy na `sbx-eplast-dev`: Flow `0AfHa00000EIBg5KAH` Succeeded (consulta: v3 Draft, v2 Active); v15 Succeeded (consulta: v13 Active, v14 e v15 Inactive).

## Mudanças na v15 (tópico `insights_comerciais_1790e90ae9fbdc8`)
1. Ação `ProximaAcaoCliente`: entrada nova `accountName` (descrição manda passar o nome quando não há Id, sem chamar `IdentificarConta` antes); `recordId` só se o Id estiver no contexto; saída `actionCode` passa a citar `NOT_FOUND` e `AMBIGUOUS`.
2. Instrução `instruction2_EPLAST27_v15`: chamar a ação direto (Id do contexto ou nome dito); mostrar a `message` na íntegra, inclusive a lista de contas; em pergunta de continuação, **chamar a ação de novo** com a mesma conta; nunca recomendar fora do devolvido; mantém `NOT_OWNER` sem consulta por outra ação.

## Pacote da branch
Só a v15 e o Flow. A v14 (`SFAgent2_v14` e `v14.botVersion`) foi removida da branch (já está na QA).

## Versões e ativação
- Ativação **não feita**. Agente: v15 inativa, v13 segue ativa na dev. Flow: v3 em Draft, v2 segue ativa.
- **Ordem obrigatória para a verificação e o QA:** a ação do agente chama a versão **ativa** do Flow. Enquanto a v3 não for ativada, a v15 só funciona pelo Id (comportamento da v2). Passo a registrar: 1) ativar o Flow v3; 2) ativar `SFAgent2` v15. Por nome, só vale depois do passo 1. Ativação é passo separado (esteira/QA), não feito aqui.

## Premissas assumidas (validar na homologação)
- Busca por nome é "contém" (design). Nome curto e comum (por exemplo uma letra) devolve a lista dos 5 primeiros em ordem alfabética, com aviso de que há mais. Mudar: ajustar o filtro do Flow para "começa com" ou exigir tamanho mínimo.
- A lista de nomes ambíguos mostra as contas que o usuário enxerga, inclusive de outro dono (só o nome; dado da conta e recomendação só depois de escolher, e a carteira é checada nesse passo). Mudar: filtrar por dono na busca quando `RestrictToOwner__c` for verdadeiro.
- Versão da API do Flow mantida em 67.0 (a da v2); o design citava 68.0, sem efeito funcional.

## Para a verificação
- Ativar primeiro o Flow v3 na dev (ou testar antes só por Id), depois a v15. Conversa sem tela (`sf agent preview start` / `send` / `end`), por nome e por Id, 3 tentativas por cenário em sessões novas: A1, A2, A3, NONE, NODATA, nome ambíguo, nome inexistente, conta de outro dono e pergunta de continuação. Massa: `fixtures/conta-oportunidade-proxima-acao.apex`.
- Não testado neste build (sem ativação, sem massa): o comportamento por nome em conversa.
