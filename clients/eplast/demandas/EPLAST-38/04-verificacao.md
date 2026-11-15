**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY; alias da esteira), conferida com `sf org list`; única org conectada.

# EPLAST-38 · Verificação do build: roteamento regional do lead

Método: fixture `fixtures/lead_roteamento_regional.apex` (modos REGRA, MANTER_DONO, SIMPLES, MASSA_REGRA, MASSA_SIMPLES, LIMPAR), copiada para /tmp com o `MODO` trocado, sem editar o arquivo do repositório. Duas inserções avulsas em Apex anônimo, também com prefixo `EPLAST38-TESTE-` (CA-05 com Status Contatado; dono informado com regra). Consultas só por agregação ou por Leads do prefixo (State, fila, score), sem campo pessoal. Nada foi alterado no builder, nenhum commit.

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | CA-01 | REGRA: Lead State=SP | Fila Leads SP | SP e "sp" em Leads SP (2) | passou |
| 2 | CA-02 | REGRA: State vazio, "São Paulo", "sp" | Triagem; "sp" em SP | Vazio e "São Paulo" em Leads Triagem (2); "sp" em Leads SP | passou |
| 3 | CA-03 | REGRA: 30 Leads (27 UFs + 3 especiais) | Tabela 3.1 | SP 2, RJ 1, MG 1, ES 1, Sul 3, Centro-Oeste 5, Norte e Nordeste 15, Triagem 2. Total 30 de 30 inseridos | passou |
| 4a | CA-03 (caminho C) | SIMPLES com `PS_Integracao_DistribuicaoLead` no usuário de execução; espera de 45 s | Mesma distribuição, via Flow assíncrono | Distribuição idêntica (2/1/1/1/3/5/15/2); nenhum Lead com dono usuário | passou |
| 5 | CA-04 (ramo sem regra) | MANTER_DONO: dono = usuário de execução, sem cabeçalho, sem PS (SP) | Dono continua o informado | Dono = usuário informado, não foi para fila | passou |
| 6 | CA-04 (ramo com regra, PA-07) | Dono informado = usuário, cabeçalho de regra, State=SP | Regra define a fila | Dono = Leads SP | passou |
| 7 | CA-05 | REGRA, Status "Aberto - Não contatado", setor e origem preenchidos | Score 60, "Média" | 60 / Média em todos os Leads consultados | passou |
| 8 | CA-05 | Lead com Status "Contatado" (SP, regra) | Score 100, "Alta" | 100 / Alta; dono Leads SP | passou |
| 9 | CA-06 (caminho A/D) | MASSA_REGRA: 200 Leads numa operação | 200 inseridos, nenhum sem dono, distribuição da tabela | 200 de 200; Sul 24, RJ 8, CO 39, SP 8, ES 8, MG 8, NO/NE 105 (soma 200, igual ao esperado por UF; 200 mod 27) | passou |
| 10 | CA-06 (caminho C) | MASSA_SIMPLES com PS; espera de 90 s | Idem, sem erro de governador | 200 de 200; mesma distribuição; 0 Leads com OwnerId nulo; 0 ainda com dono usuário | passou |
| 11 | CA-07 | Conferência do metadata versionado | Sem e-mail, template ou envio | Regra sem `template`; 8 filas com `doesSendEmailToMembers=false`; Flow e classe sem emailSimple, e-mail alert, Messaging ou Http (os únicos "http" achados são o namespace XML); sem trigger de Lead. Nenhum e-mail saiu em nenhum caso | passou |
| 12 | Cobertura | `sf apex run test -n LeadAssignmentServiceTest -c` | Mínimo 85% | 7 de 7 passaram; `LeadAssignmentService` 100% | passou |

Observações: o caso do Flow concorrer com a regra (design, seção 3.2) não gerou conflito. Nos modos com regra (REGRA, MASSA_REGRA) todos os Leads foram para a fila certa sem erro. Não foi possível ler o `AsyncApexJob` da classe (a consulta não devolveu linhas), mas a atribuição de fila nos casos 4a e 10 prova que o caminho assíncrono executou.

## Alterações no usuário de execução (dev) e reversão
- Usuário de execução: `005bJ00000piKAaQAM` (ativo, Administrador do sistema). Sem validation rule que exigisse ajuste de campo; nenhum campo foi alterado.
- Permission set `PS_Integracao_DistribuicaoLead` (criado pela demanda): antes, não atribuído; durante os casos 4a e 10, atribuído (`PermissionSetAssignment` 0PaHa00000EJOrOKAX); depois, removido. Conferido: 0 atribuições.
- `UserPermissionsMarketingUser`: não foi mexido (false).
- Usuário de teste da regra 6 (`005bJ00000hBJmYQAW`): inativo na dev, não usado nem alterado. O CA-04 usou o usuário de execução, como o design previa.

## Limpeza
Todos os Leads `EPLAST38-TESTE-` foram apagados com o modo LIMPAR (resíduos 0 conferido por contagem). Nada ficou na dev. Nenhum job agendado criado.

## O que pode ter saído da org
Nada. Não há ação de e-mail, template, integração ou callout na cadeia (caso 11). Nenhum registro externo, pedido, cotação ou log de integração foi criado. Marketing Cloud não foi tocado.

## Pendências fora da verificação (passos do operador, do plano de build)
Os membros das 8 filas e a atribuição do permission set às integrações reais não foram verificados: dependem de quem opera a org. Antes do deploy em QA valem as condições R1 e R2 do plano (grupo 2 só se ausente ou idêntico na QA).
