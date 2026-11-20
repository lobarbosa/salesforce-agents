**Veredito:** aprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-26 — Testes na QA (rodada 3)

Org confirmada com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected). Deploy da esteira `0AfHa00000EM4PtKAL` (Succeeded, commit `d36dd65f`) em `05-deploy-qa.md`, que agora lista os 16 layouts. Critérios do `01-analise.md` aplicados ao design aceito (9 campos novos, G1-b, 32.768). Dados só sintéticos `TESTE SOMOSAGILITY-26`; nenhum registro existente da QA foi lido ou alterado.

## Falhas
Nenhuma que bloqueie o aceite.

## Retestes da rodada 2 (`05-testes-rodada-2.md`)
- FALHA 1 (9 de 16 layouts sem os campos novos): **corrigida**. Retrieve dos layouts na QA: 16 de 16 com os 3 campos `PFP_N_Texto__c` (3 ocorrências em cada arquivo).
- Observação da fórmula do FVP (`PFP1UNCPath__c` = `'a'` na QA): **continua igual**, ver C9.
- Observação de FLS: agora 573 linhas na QA (igual à dev), antes 459.

## Versão de Flow (regra de ativação)
`Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`. Antes desta rodada: v3 Active (ativada na rodada 2; nesta rodada o deploy da esteira não alterou o status). Consulta Tooling `Flow`: `3 Active`, única versão na QA. Fica ativa ao final. Nada mudou no conteúdo do Flow.

## Casos

| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| C1 | Tooling/`FieldDefinition` dos 9 campos nos 3 objetos | 9 LongTextArea 32768 | 9 linhas "Área de texto longo(32768)", 32768 | passou |
| C2 | `COUNT()` de `FieldPermissions` com `Field IN` dos 9 campos | Permissão espelhada | 573 | passou |
| C3 | FVP: inserir com `PFP_1_Texto__c` de 32768 caracteres e ler; BluePrint com 32768 | Salva e lê completo | `RES6 len=32768`; BluePrint update de 32768 sem erro | passou |
| C4 | BluePrint: gravar 32769 caracteres em `PFP_3_Texto__c` | Recusa de tamanho | `STRING_TOO_LONG, PFP 3: valor de dados grande demais ... (max length=32768)` | passou |
| C7 | Flow v3 ativo: criar PSL (execução separada) numa Oportunidade ligada a BluePrint de teste com textos 603/303/53 | PSL recebe os 3 textos completos | `RES4 t=603/303/53 ... ok=true` (conteúdo idêntico no 1) | passou |
| C8 | Antigo copiado; valor digitado não sobrescrito; novo vazio recopiado | `PFP_N__c` = UNC do BluePrint; manual preservado | Criação: `old=\\srv\a1\|\\srv\a2\|\\srv\a3`. Após update com novo nulo e `PFP_1__c='MANUAL-TESTE'`: `t=603/303/53 old=MANUAL-TESTE\|\\srv\a2\|\\srv\a3` | passou |
| C9 | FVP: fórmula `PFP1UNCPath__c` segue mostrando o antigo | Valor do antigo da PSL | FVP lê `'a'`: a fórmula na QA é a constante `'a'` (campo fora desta entrega, não alterado) | não comprovável na QA; passou na dev (V7 de `04-verificacao.md`) |
| C10 | Dados existentes íntegros | Sem mudança | Contagens antes e depois: BluePrint 322, PSL 1.475, FVP 0 | passou |
| C11 | VRs e automações sem erro com Flow ativo | Sem exceção | Criação de Conta, Contato, Oportunidade, BluePrint, PSL, FVP e updates concluídos sem erro (as VRs exigiram dados válidos: Orçamentista, Autor, telefone; sem VR disparando indevidamente) | passou |
| C12 | Layouts mostram os campos novos (retrieve dos 3 objetos na QA + tela) | 16 layouts com os campos | Retrieve: 16 de 16 com 3 campos cada. Tela: `evidencias/02-c12-psl-de-teste-na-qa-aba-detalhes-com-.jpg` mostra a PSL de teste só no topo da aba Detalhes (a ferramenta não rola a página, os campos PFP ficam abaixo); `evidencias/01-...jpg` é o quadro de carregamento, sem valor de prova | passou (prova pelo retrieve; tela fica para o roteiro do cliente) |
| C13 | Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP) | Verificar na homologação | Não testável na sandbox | não executado (segue para homologação) |

Critérios do `01-analise.md` cobertos: tamanho alvo (C1, C3), recusa acima do limite (C4), dados existentes íntegros (C10), automações e validações (C7, C8, C11), permissões mantidas (C2). Permissão por perfil: só o usuário de execução (Administrador) foi usado; a cobertura de perfis é a contagem 573 de C2.

## Observações (não bloqueiam)
- **Fórmula do FVP na QA diverge da dev/repo:** `'a'` em vez de `PropostaSolucao__r.PFP_1__c`. O campo não é desta demanda. O time deve conferir se é rascunho de sandbox antes da produção.
- Assessment (24 automações no mesmo evento, 31 em Oportunidade): a cadeia de criação de Oportunidade, BluePrint e PSL rodou sem erro com o Flow ativo, sem efeito colateral visível nos campos testados.

## O que pode ter saído da org
Criados e depois apagados: 1 Conta, 1 Contato, 1 Oportunidade, 1 BluePrint, 1 PSL, 1 FVP (todos `TESTE SOMOSAGILITY-26`). Nenhuma chamada externa identificada; automações de Oportunidade rodaram sobre esses registros (e-mail ou tarefas, se houver, não foram inspecionados). Contagens finais: BluePrint 322, PSL 1.475, FVP 0; registros `TESTE SOMOSAGILITY-26` restantes: 0 em Conta, Contato e Oportunidade.

## Mudanças no meu usuário de execução
Nenhuma. A única mudança de configuração na org foi a ativação da v3 do Flow (rodada 2).
