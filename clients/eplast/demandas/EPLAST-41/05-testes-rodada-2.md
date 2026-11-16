**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox QAS da Eplast, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`)

# EPLAST-41 · Testes na QA (rodada 2)

Deploy da QA: `0AfHa00000EI9rBKAT` (commit `f8004b81`). A FALHA 1 da rodada 1 foi corrigida. A FALHA 2 continua: o Flow corrigido entrou na QA como versão Draft e quem responde é a versão 1, ativa, sem botão de avanço.

## Falhas

### FALHA 1 (crítica) — Tela "Rascunho com IA" continua sem botão para avançar (persiste da rodada 1)
- **Reproduzir:** na QA, com `PS_Comercial_RascunhoRelacionamento` atribuído, abrir a conta `TESTE EPLAST-41 Conta A`, "Mostrar mais ações", "Rascunho com IA", marcar "Mensagem de relacionamento".
- **Obtido:** modal com "Tipo de texto" e rodapé vazio (screenshot desta sessão). Sem "Próximo" ou qualquer botão. Não se chega à tela de objetivo, ao texto, nem a "Salvar como tarefa".
- **Esperado:** botão para seguir até o texto gerado e ao salvamento.
- **Causa provável:** na QA, `Task_Screen_RascunhoRelacionamento` tem v1 Active e v2 Draft (consulta Tooling em `Flow`). A correção da rodada 1 (telas com `allowFinish=true`, conforme `04-verificacao.md`) está na v2, que não está ativa; a quick action abre a versão ativa, a v1 defeituosa. Mesmo quadro em `Opportunity_Screen_RascunhoComercial`: v3 Active, v4 Draft. Corrigir: a v1 não pode ser a ativa com o defeito. Ou o pacote entrega a correção como versão ativa (passo de ativação registrado no build), ou a v1 é corrigida pela via de versão nova ativada. Eu não ativei Flow: ativação é passo separado.

## Falha da rodada 1 retestada
| Falha | Situação |
|---|---|
| FALHA 1 rodada 1 (`No active template version`) | Corrigida. Apex com `generateMessagesForPromptTemplate('Rascunho_Relacionamento')`, 3 entradas sintéticas `TESTE EPLAST-41`: texto de 528 caracteres em 2,6 s. |
| FALHA 2 rodada 1 (sem botão de avanço) | Não corrigida na QA (ver FALHA 1 acima). |

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes na QA | Deploy listado; query Tooling em `Flow` | Itens existem | Flows: Task_Screen_RascunhoRelacionamento v1 Active, v2 Draft; Opportunity_Screen_RascunhoComercial v3 Active, v4 Draft. Templates, quick actions e permission sets confirmados na rodada 1 e não mudaram | passou |
| C1 Gerar rascunho da conta, até 30 s | Template por Apex (2,6 s, 528 caracteres); tela | Texto na tela, copiável | Template gera. Tela não avança (FALHA 1) | reprovado |
| C2 Salvar como Task | Depende de C1 | Task com `WhatId`, `TaskSubtype=Task`, `Description` | `SELECT COUNT() FROM Task WHERE Subject LIKE '%(IA)%'` = 0 | não executado |
| C3 Nada gravado antes de salvar | Contagem de Task `(IA)` após geração por Apex | 0 | 0 | passou (só template) |
| C4 Nenhum envio pelo CRM | `EmailMessage` antes e depois | 805 e 805 | 805 e 805 | passou (sem tela completa) |
| C5 Prompt sem dado pessoal | Entradas do template | Só conta, oportunidade e objetivo | Confere (3 entradas) | passou (metadata) |
| C6 Textos comerciais sem duplicata | Metadata | Um de cada | Uma ocorrência de cada (rodada 1, deploy sem mudança de nomes) | passou |
| C7 Falha do modelo | Tela | Erro sem texto, 0 Task | Tela não avança | não executado |
| C8 Conta sem oportunidade avisa | Tela | Aviso | Tela não avança | não executado |
| C9 SFAgent2 único | `COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou |
| C10 `et4ae5` intacto | Lista do deploy | Nenhum | Nenhum | passou (inspeção) |
| C11 Ação visível na Conta | Tela | "Rascunho com IA" no menu | Aparece em "Mostrar mais ações" | passou |
| C12 Oportunidade e comercial | PSG exige licença CPQ (Cotação), não atribuível ao meu usuário | Ação e texto comercial | Não exercitado | não executado |

Evidência de tela: screenshot da sessão na conta `TESTE EPLAST-41 Conta A` (registro sintético), modal com "Tipo de texto" e rodapé vazio.

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`) e dados
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
| `PS_Comercial_RascunhoRelacionamento` | não atribuído | atribuído | removido (0 atribuições, conferido) |
Contas A e B e Oportunidade `TESTE EPLAST-41` criadas pelo fixture e apagadas (contagem final 0). Usuário de serviço da Konecta (`005bJ00000hBJmYQAW`, inativo) não usado.

## O que pode ter saído da org
Nenhum `EmailMessage` novo (805 antes e depois); nenhuma chamada ao Marketing Cloud. Uma chamada ao modelo (Apex, texto sintético). A criação das contas disparou a tarefa "Conta Nova Cadastrada" (automação existente), apagada com a conta.
