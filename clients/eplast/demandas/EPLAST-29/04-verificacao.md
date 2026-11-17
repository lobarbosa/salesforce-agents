**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-29 · Verificação do build (dev), rodada 5

`sf org list` mostrou só `sbx-eplast-dev` (sandbox, 00DHa000006vfMLMAY, Connected). Nada tocado em QA, produção ou Marketing Cloud. Nenhum dado real lido; só metadata e contagens. Nenhuma versão de agente ou de Flow foi ativada nesta sessão (instrução do orquestrador), nenhum registro criado, nenhuma metadata alterada.

## Estado confirmado na dev (por query)
| Item | Obtido | Confere com o relato do builder |
|---|---|---|
| `SFAgent2` | v13 Active; v14, v15, v16, v17 Inactive (v1 a v17 existem) | sim |
| Flow `Task_Agente_CriarTarefa` | v1 Active; v2 Obsolete | sim |
| Task `TESTE EPLAST-29%` | 0 | sem resíduo |
| Leads `REG-TESTE%` | 4 (fixture `lead.apex`, mantidos para reuso) | sim |

Mudança no build desde a verificação anterior (`04-verificacao-rodada-1.md`): nenhuma. O último commit em `force-app` é o da v17 (724ddf6b); a sessão de build só conciliou versões. A base v17 é a correta, sem versão acima criada por outra demanda.

## Por que é inconclusiva
Com Flow v1 e agente v13 ativos, a solução desta demanda (Flow v2 com lead e custom metadata, tópico `acoes_comerciais_EPLAST29_v17`) não roda: a plataforma só executa versão ativa, e eu não posso ativar. Exercitar agora testaria a v1 e a v13, que não são o que foi construído. Não há evidência nova a registrar.

## Resultado das casos (sem execução nesta sessão)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| Flow v2: lead, conta, convertido, prefixo, assunto, `Check In @`, data, lead inexistente (F1 a F8) | AC-1, AC-5, AC-7 | nada nesta sessão | recusas e gravação corretas | passaram na verificação anterior (rodada 1), Flow v2 não mudou desde então; sem reexecução | não executado |
| Busca `Lead` por `identifyRecordByName` (R3) e resumo completo (A1, A2) | AC-1 | nada nesta sessão | achar o lead e resumir | passaram na rodada anterior (A1 instável); sem reexecução | não executado |
| Ambiguidade de nome (A4) | AC-3 | nada nesta sessão | lista com nome, tipo e identificador | **falhou na rodada anterior** (2 de 2 execuções: 3 chamadas da busca e saudação genérica, sem lista); o build não mudou desde então | não executado |
| Confirmação em 2 turnos, descrição gravada, "criado" sem ação (FALHAS 1 e 2 da QA) | AC-1, AC-2 | nada | não afirmar criação sem a ação; "sem descrição" só no resumo | nunca exercitado (`sf agent test` é de 1 turno) | não executado |
| Usuário não administrador (R4, AC-4) | AC-4 | nada | recusa sem vazar dado | sem usuário comum e a regra 6 proíbe mudar perfil | não executado |
| Ações de EPLAST-27, 34 e 46 na v17 (Q-13, AC-9) | AC-9 | só conferência de versões | intactas | não exercitadas | não executado |

## O que ficou sem prova e o que fazer
1. Reexecutar F1 a F8 e A1 a A4 com Flow v2 e `SFAgent2` v17 ativos na dev. Quem tiver autorização para ativar (passo separado do plano, "Versões e ativação"): ativar o Flow v2 (Obsolete hoje, rollback: reativar v1) e `sf agent activate` da v17 (rollback: reativar v13); depois devolver ao estado atual.
2. **Falha conhecida em aberto (A4, ambiguidade):** a verificação anterior a registrou como reprovação e a construção não foi alterada depois. Se a reexecução repetir, é reprovada e volta ao builder para revisar a instrução de ambiguidade (causa provável: loop da busca ou instrução do tópico). Não declaro corrigida.
3. AC-4 e R4: testar com usuário comum com e sem `PS_Comercial_AssistenteAcoes` na homologação.
4. FALHAS 1 e 2 da QA (confirmação em dois turnos): só pela tela do chat.

## O que pode ter saído da org
Nada: nesta sessão nenhum registro foi criado nem automação disparada.

## Resíduos
- Definição de teste `TESTE_EPLAST29_Verif` (AiEvaluationDefinition) pode continuar na dev (relatado na rodada anterior); apagar pelo Testing Center.
- Leads e conta da fixture continuam na dev; apagar com o comando do cabeçalho de `fixtures/lead.apex`.
- Pendência da esteira, sem efeito sobre o que testei: a v17 não está na QA (FALHA 5 do passo de deploy).
