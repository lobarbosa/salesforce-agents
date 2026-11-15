**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente

**Org de build:** `sbx-eplast-dev` (`sf org list` em 2026-11-15: Sandbox, Connected). Nada foi enviado à QA nem à produção.
**Branch:** `feature/EPLAST-27`. **Decisão:** declarativo, conforme `03-design.md` seção 1. Sem classe Apex, trigger ou DML.
**Nota (R3 do design):** o alias dev (`sbx-eplast-dev`) aponta para uma sandbox cujo nome de instância sugere o ambiente de QA. O alias é o permitido, mas a esteira deve confirmar antes do deploy de QA que dev e QA são orgs distintas.

## Componentes criados (deploy na dev: Succeeded)

| Componente | Tipo | Caminho |
|---|---|---|
| `NextBestActionSetting__mdt` (campos `StaleOpportunityDays__c`, `RiskValues__c`, `RestrictToOwner__c`) | Custom Metadata Type | `force-app/main/default/objects/NextBestActionSetting__mdt/` |
| `NextBestActionSetting.Default` (30; `E`; verdadeiro) | Registro de CMDT | `force-app/main/default/customMetadata/NextBestActionSetting.Default.md-meta.xml` |
| `Account_Agente_ProximaAcao` | Flow autolançado, sem gatilho, v67.0, Ativo, sem DML | `force-app/main/default/flows/` |
| `ProximaAcaoCliente_EPLAST27` (ação do tópico `insights_comerciais_1790e90ae9fbdc8`, alvo o Flow) | Alteração no `GenAiPlannerBundle` `SFAgent2_v4` | `force-app/main/default/genAiPlannerBundles/SFAgent2_v4/` |
| `PS_Comercial_ProximaAcao` | Permission set | `force-app/main/default/permissionsets/` |

Todos têm descrição preenchida. Nenhum componente novo em Account, Opportunity, Order ou Task: não há trigger, Flow acionado por registro nem campo novo nesses objetos (achado 1 do assessment não é piorado). Marketing Cloud e e-mail não foram tocados.

## Como o Flow segue o design (seção 3.2)
Ordem: CMDT `Default`; conta por `recordId` (falha ou ausência vira `NOT_OWNER` com mensagem neutra); carteira (`RestrictToOwner__c` e `OwnerId` diferente de `$User.Id` vira `NOT_OWNER`, sem dado da conta); oportunidade aberta parada (primeiro registro, `LastActivityInDays` maior que o limiar, ou sem atividade e criada antes de agora menos o limiar, P12); existe alguma oportunidade; decisão `NODATA`, A1, A2, A3, `NONE`. São 4 consultas com 1 registro cada e nenhum laço. `runInMode` = `DefaultMode` (I2).

## Alteração no `SFAgent2_v4` (P11, I1)
- O planner foi retrieved antes de editar. As instruções existentes do tópico foram preservadas; foram só acrescentados: trecho na descrição do tópico, uma instrução "PRÓXIMA AÇÃO POR CLIENTE" logo após a primeira (usa `IdentificarConta`, chama `ProximaAcaoCliente`, apresenta a mensagem sem acrescentar ação, `NOT_OWNER` não consulta a conta por outras ações), o alias da ação e sua definição (`flow://Account_Agente_ProximaAcao`).
- O retrieve do bundle trouxe `.agent` e `agentGraph` codificados em base64; o `.agent` foi decodificado, editado e recodificado. O grafo não foi editado à mão. O deploy aceitou e a re-recuperação da dev confirma `ProximaAcaoCliente` no bundle e no `.agent`. Não confirmei que o grafo foi regenerado com a ação.
- As instruções antigas do tópico (STEP 7, CENÁRIOS) continuam mandando o LLM montar consulta para "oportunidades paradas". A nova instrução declara prioridade só para o pedido de próxima ação de um cliente. O verificador deve testar se perguntas variadas não caem no caminho antigo (R6).

## Premissas do design aplicadas (P1 a P12)
Seguidas sem alteração. Valor de risco `E` e 30 dias ficam no CMDT. Limiar de A3 (90 dias) vem da fórmula `Account.Inactive__c` (P2).

## Pendências para o verificador e passos manuais (R1, R2, I3, I4)
1. **Permission set sem concessão ao agente.** Não há elemento de metadata confirmado para conceder o `SFAgent2` ao permission set; a concessão (e a licença de Agentforce, I3) é passo manual. `Inactive__c` é fórmula e não recebe FLS. As 4 versões do agente estão `Inactive` na dev; ativar a v4 e atribuir `PS_Comercial_ProximaAcao` aos usuários de teste é passo manual. Sem isso, a verificação do agente sai `inconclusiva` e o Flow é verificado sozinho.
2. **Flow sem teste declarativo** (I4). Evidência vem de execução com massa fictícia e dos cenários da seção 10 do design.
3. **Massa de teste (R2/I5): não criada neste build.** Antes de criar Account ou Opportunity fictícia, conferir `TriggerUtility__mdt` e conter o envio ao Protheus (`IntegrationLog__c` por contagem). Sem contenção, sem DML.
4. Não foi executada nenhuma consulta a dado de negócio. Só metadata e confirmação de campos.
