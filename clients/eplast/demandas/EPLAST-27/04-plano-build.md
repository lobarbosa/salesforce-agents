**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected, username `usuário de teste da Konecta (username omitido)`; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado. Fonte de decisão: `03-design.md` atual; os planos e roteiros de ciclos anteriores não foram usados para decidir.

## Estado encontrado (pré-checagem e org)
- `SFAgent2`: v1 a v10 depois deste build; **v8 ativa** (não editada, não reimplantada). v9 inativa (EPLAST-46).
- O design fala em "v4" (P11); a org já passou disso. A ação `ProximaAcaoCliente` (`ProximaAcaoCliente_EPLAST27_vN`) **já está presente** nas v7, v8 e v9 (herdada da cadeia de versões). O que **não** está nas v7, v8 e v9 é a instrução de tópico do design 3.3 (`instruction2_EPLAST27`), que existia na v6 e se perdeu quando EPLAST-29, 34 e 46 criaram suas versões. Sem ela o assistente não sabe quando chamar a ação nem que deve apresentar a `message` sem alterar (P5, R6).
- Flow `Account_Agente_ProximaAcao`: comparado o retrieve da org com o do repositório; só difere em ordem de elementos. Versão ativa mantida, **nenhuma versão nova**: a regra do design (seção 3.2) não mudou, então não há o que implementar.
- CMDT `NextBestActionSetting__mdt` + registro `Default` e `PS_Comercial_ProximaAcao`: já existem no repositório e na org de ciclos anteriores; sem mudança no design, não foram reescritos.

## Componentes criados neste build
| Componente | Detalhe | Caminho |
|---|---|---|
| `GenAiPlannerBundle` `SFAgent2_v10` (inativo) | Base: **retrieve da v9 da org** (preserva ações e instruções de EPLAST-29, 34 e 46 e a ação `ProximaAcaoCliente`), renomeada para v10. Único acréscimo: `instruction2_EPLAST27_v10` no tópico `insights_comerciais_1790e90ae9fbdc8` (design 3.3: identificar a conta com `IdentificarConta`, chamar `ProximaAcaoCliente`, apresentar a `message` sem acrescentar, e se `NOT_OWNER` não consultar a conta por outras ações). | `force-app/main/default/genAiPlannerBundles/SFAgent2_v10/` |
| `BotVersion` `SFAgent2.v10` (inativa) | Mesma estrutura das versões anteriores, ligada ao planner `SFAgent2_v10`. | `force-app/main/default/bots/SFAgent2/v10.botVersion-meta.xml` |

Deploy na `sbx-eplast-dev`: Succeeded (Bot pai, BotVersion v10, planner v10). O deploy reportou BotVersion v6 e Bot como "Changed" por serem arquivos de apoio com o conteúdo da própria org. Conferido por query: v8 Active, v9 Inactive, v10 Inactive.

## Interferência com outras demandas (EPLAST-29, 34 e 46)
- A v10 parte da v9, a mais recente, e mantém: ações `CriarTarefa` e `IdentificarRegistro` (29), `ResumoReuniao` (34), `SugestaoCampanha` (46) e as instruções delas. Nada delas foi removido ou editado.
- A instrução da 27 entra com `sortOrder` 3 no tópico de insights, depois das da 34 e 46. Se as demandas 29, 34 ou 46 criarem versão nova a partir da v8 ou de versão sem a instrução da 27, a instrução se perde de novo: quem criar a versão seguinte deve partir da v10.
- Ao ativar a v10 deixa de valer a v8. A v8 não tem `SugestaoCampanha` (46) e a v10 tem; quem ativar decide isso junto com as demandas 29, 34 e 46.

## Ligação com o design
- 3.3 (ação e tópico): ação já presente; instrução restaurada na v10. P11 atualizada: a base não é mais a v4, é a v9.
- 3.2 (Flow), 3.1 (CMDT), seção 5 (permission set): inalterados.
- Nada em Account, Opportunity, Order, Task, Apex, trigger, e-mail ou Marketing Cloud. Nenhum DML nesta sessão.

## Premissas assumidas (do design, aplicadas sem mudança)
P1 a P12 do `03-design.md`. Nova nota de P11: a versão do agente a editar passou de v4 para "versão seguinte à mais recente" (v10), porque a v8 está ativa e não aceita deploy.

## Versões e ativação
- Criadas: planner `SFAgent2_v10` e BotVersion `v10`, inativas. **Ativação é passo separado e não foi feita.** A v8 segue ativa.
- Ativar a v10 desativa a v8 (uma ativa por vez). Na QA exige autorização no card.
- Flow: versão ativa mantida, sem versão nova.

## Fica para o verificador
- BotVersion v10 existe, Inactive; v8 Active; v9 Inactive.
- Conferir no planner v10 que o tópico de insights tem a ação `ProximaAcaoCliente_EPLAST27_v10` e `instruction2_EPLAST27_v10`, e que as ações de 29, 34 e 46 seguem presentes.
- Regra do Flow já exercitada em ciclos anteriores (A1, A2, A3, NONE, NODATA, NOT_OWNER, sem gravação); massa por `fixtures/conta-oportunidade-proxima-acao.apex`. Usuário de teste (conta de serviço): Id `005bJ00000piKAaQAM`, conferir na org.
- Resposta real do assistente só com a v10 ativada, licença Agentforce (I3) e concessão do agente ao permission set (não confirmada como metadata); sem isso a verificação do assistente fica inconclusiva e o Flow é verificado sozinho.

## Branch e commit
Branch `feature/EPLAST-27`; commit `EPLAST-27: criar SFAgent2 v10 com a instrução da próxima ação`.
