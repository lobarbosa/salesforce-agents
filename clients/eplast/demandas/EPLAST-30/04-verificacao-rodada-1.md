**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-30 · Verificação (dev), rodada pós-QA 1

Org conectada (`sf org list`): `sbx-eplast-dev`, Sandbox, Org Id `00DHa000006vfMLMAY`, status Connected. Nada feito na QA nem em produção. Usuário de execução: `005bJ00000piKAaQAM` (ativo). Nenhuma mudança nele: não atribuí permission set nem alterei opção. O usuário de teste da conta de serviço (`005bJ00000hBJmYQAW`) está inativo na dev, não foi usado.
Não criei registro algum na org (0 DML). Nada a apagar. Nada pode ter saído da org além de 4 chamadas de geração de texto com dado sintético (ver fim).

## Foco: o que a rodada 1 de QA pediu do lado do build

### FALHA 1 — A correção da regra 5 do template de follow-up não está efetiva na dev
- **Reproduzir:** POST em `/services/data/v65.0/einstein/prompt-templates/Rascunho_Followup_Comercial/generations` na dev, com `Input:DadosOportunidade` = "Oportunidade: TESTE EPLAST-30 Op; Conta: TESTE EPLAST-30 Conta; Etapa: Qualificação; Data de fechamento: 31/12/2026; Valor: 1000,00 BRL" e `Input:DadosCotacao` = "sem cotação". Repeti 3 vezes (uma delas com a data como `[dado ausente: Data de fechamento]`).
- **Obtido:** em 3 de 3 chamadas o texto **não** cita `31/12/2026` (nem a data em outro formato, na leitura de uma das respostas) e não traz o marcador de dado ausente. Cita conta e etapa. O plano diz "2 de 2 chamadas citaram 31/12/2026"; não reproduzi.
- **Evidência da causa:** `sf project retrieve` do template da dev (só leitura, descartado depois) devolve a regra 5 antiga: "Cite o nome da conta e a etapa atual da oportunidade no corpo do texto." O arquivo da branch (commit 962e1f9a) tem a regra nova ("... a etapa atual e a data de fechamento ..."). Na dev há uma única versão do template, `Published`, com `versionIdentifier` `…_1`, o mesmo do arquivo. O deploy `0AfHa00000EI5R0KAL` aparece como Succeeded, mas não mudou o texto da versão publicada.
- **Esperado:** critério "Follow-up gerado" (`01-analise.md`): texto com nome da conta e data de fechamento.
- **Causa provável:** versão `Published` de template Flex é imutável; editar o texto no mesmo `versionIdentifier` é ignorado. Precisa de nova versão do template (novo `templateVersions` com novo identificador, publicada e ativa), não edição no lugar. A branch também ficará com o mesmo problema no deploy da QA/produção se só o texto mudar na mesma versão. Fora o que o builder precisa corrigir, não há bloqueio.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | Follow-up cita conta e data de fechamento (correção da FALHA 2 da QA) | 3 chamadas ao template na dev, texto sintético | Conta e `31/12/2026` (ou marcador de ausente) no texto | Conta em 1 das 3 (nas outras o nome sintético não aparece literalmente); data em 0 de 3; regra 5 da dev é a antiga | **falhou** (FALHA 1 acima) |
| V-02 | Arquivo da branch tem a regra 5 corrigida | Grep no arquivo do template | Regra 5 cita data de fechamento | Linha 15 cita data e marcador de ausente | passou (só na branch, não na dev) |
| V-03 | CA-14: PromptFlows depreciados | `SELECT COUNT(Id) FROM Flow WHERE ProcessType='PromptFlow'` (Tooling) | 0 | 0 | passou |
| V-04 | Screen Flow ativo | Tooling `FlowDefinition` `Opportunity_Screen_RascunhoComercial` | Versão 1 ativa | Versão 1, status Active | passou |
| V-05 | CA-11/12: Flow sem DML | Grep de `recordCreates/Updates/Deletes` no Flow da branch | 0 | 0 | passou (estático) |
| V-06 | PSG existe e está atualizado | `PermissionSetGroup` `PSG_Comercial_RascunhoIA` | Status Updated | Updated | passou |
| V-07 | Dev sem Opportunity (massa) | `SELECT COUNT(Id) FROM Opportunity` | contagem | 0 | informativo |
| V-08 | CA-01 a 03, 04/05, 06, 07, 08, 09, 10, 13: Flow de ponta a ponta (abas, 3 tipos, tempo, negativa, erro, 50 linhas) | Não executado | Conforme `01-analise.md` | Screen Flow só roda pela interface; a CLI não o executa. A dev não tem registros e não há fixture em `clients/eplast/fixtures/` (a pasta não existe) | não executado |
| V-09 | CA-14 da página: `PriorityScore__c`/`PriorityBand__c` da EPLAST-26 preservados | Não reconferido nesta rodada | Campos intactos | Não medido | não executado |

## O que ficou sem prova e por quê
- Execução do Screen Flow pela página (V-08): limitação do ambiente. Quem prova: pessoa com login e o PSG `PSG_Comercial_RascunhoIA` atribuído, seguindo `05-roteiro-cliente.md`. Isso não é defeito do build e, por si só, seria inconclusiva; o veredito é reprovada porque o caso V-01 executou e falhou por defeito de construção.
- A FALHA 1 da QA (nenhum login com o PSG) continua fora do build, como o plano já registrou.

## O que pode ter saído da org
- 4 chamadas ao serviço de geração de texto do template de follow-up (3 para a verificação e 1 para ler o texto), todas com texto sintético `TESTE EPLAST-30`. Nenhum registro criado, nenhuma chamada a ERP, e-mail, Task, Event ou Marketing Cloud.

## Para o builder
Publicar nova versão do template `Rascunho_Followup_Comercial` com a regra 5 corrigida (e ativá-la), reimplantar na dev e repetir o teste: a data deve aparecer em chamadas repetidas. Conferir também que o deploy da esteira para a QA leve a nova versão.
