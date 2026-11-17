**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (sandbox, Org ID 00DHa000006vfMLMAY, única conectada em `sf org list`)

# EPLAST-29 · Verificação do build (dev)

## Resumo
Os critérios AC-1 a AC-9 exigem executar o Flow `Task_Agente_CriarTarefa` v2 e o agente `SFAgent2` v16/v17. Nenhum dos dois pode ser executado na dev sem ativá-los, e ativação é passo separado, fora desta etapa. Só foi possível conferir o que está implantado. Nenhum caso funcional foi executado; nenhum falhou.

## Estado encontrado na dev (consultas, sem DML)
- Flow `Task_Agente_CriarTarefa`: v1 **Active**; v2 **Obsolete** (descrição da v2 presente, versão mais nova). O plano de build diz v2 em Draft. Está Obsolete, não Draft, e a plataforma só executa a versão ativa (v1: só conta e oportunidade, sem lead). O build testado não é o que roda hoje.
- Agente `SFAgent2`: v13 Active; v14 a v17 Inactive. A v16/v17 não responde a conversa na dev.
- `AssistenteTarefaSetting__mdt.Padrao` existe: Ativo=true, prefixos `001;006;00Q`, prioridade `Normal`, descrição obrigatória=false, marca `Origem: assistente de IA` (confere com o plano).
- Fixture de lead presente na dev: 4 leads `REG-TESTE%`, 1 convertido (confere com o plano).
- Usuário de teste da conta (CLAUDE.md, regra 6): consulta devolve dois, `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo, Administrador do sistema). Nenhum é usuário comum, logo AC-4 não é exercitável como pede o critério.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-0 | Build implantado | Query de Flow, BotVersion, mdt e Lead | Componentes do plano presentes | Presentes; Flow v2 Obsolete, agente v16/v17 Inactive | passou (só presença) |
| V-1 | AC-1 criar com confirmação | não executado | Task criada só após confirmar, com WhatId, OwnerId, data | sem prova: Flow v2 e agente v16/v17 não executáveis sem ativar | não executado |
| V-2 | AC-2 recusa não grava | não executado | contagem de Task inalterada | sem prova (mesmo motivo) | não executado |
| V-3 | AC-3 registro ambíguo | não executado | lista candidatos com tipo e Id, nada gravado | sem prova (mesmo motivo); fixture `REG-TESTE-DUP` pronta | não executado |
| V-4 | AC-4 usuário sem permissão | não executado | recusa sem vazar dado | sem prova: não há usuário não administrador e a regra 6 proíbe alterar perfil | não executado |
| V-5 | AC-5 campo obrigatório faltando | não executado | pergunta o campo, nada gravado | sem prova (mesmo motivo de V-1) | não executado |
| V-6 | AC-6 e-mail não enviado, rascunho na descrição | não executado | EmailMessage inalterado | sem prova | não executado |
| V-7 | AC-7 fora do escopo | não executado | recusa criar Opportunity | sem prova | não executado |
| V-8 | AC-8 rastreabilidade | não executado | marca "Origem: assistente de IA", OwnerId = usuário | sem prova na Task; só o valor do mdt foi conferido (V-0) | não executado |
| V-9 | AC-9 não regressão | não executado | respostas e 3 ações do `insights_comerciais` iguais | sem prova; v13 ativa não traz a mudança | não executado |
| V-10 | R3 busca com `objectApiName = Lead` | não executado | busca aceita Lead | sem prova (agente inativo) | não executado |
| V-11 | Ramo lead convertido recusado | não executado | recusa orientada | sem prova; fixture `REG-TESTE-LEAD-CONV` pronta | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer
1. Ativar na dev, em passo separado e autorizado, o Flow `Task_Agente_CriarTarefa` v2 (hoje Obsolete: precisa ser reativada; rollback: reativar a v1) e depois o `SFAgent2` v17 (a v17 inclui as correções das rodadas 1 e 2; rollback: reativar a v13). Rodar então a verificação de novo, com a massa de `fixtures/lead.apex` (já na dev).
2. Para AC-4, um usuário comum com e sem `PS_Comercial_AssistenteAcoes` (homologação, como já registrado no plano).
3. O comportamento do modelo (FALHAS 1 a 3 da QA: dizer "criado" sem chamar a ação, gravar "sem descrição", resumo antes do "sim") só se prova numa conversa real com a v17 ativa.
4. Atenção ao estado do Flow: v2 Obsolete contradiz o plano (Draft). Confirmar com o builder ou a esteira como ele chegou a esse estado e se o conteúdo é o do plano.

## Mudanças em usuário, dados e org
Nenhuma. Nenhum dado de teste novo foi criado, nenhum usuário alterado, nada ativado, e não há job agendado. Os dados `REG-TESTE%` na dev são do build e foram mantidos para o reteste.

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhuma chamada externa foi feita.
