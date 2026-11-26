# SOMOSAGILITY-26 — Entrega (release)

**Org:** `sbx-somos-agility-qa` (Sandbox, Connected; confirmada com `sf org list`, única conectada). Produção não foi tocada.
**Pré-requisito:** `gates.md` registra homologação (Carlos Sordi, 2026-11-26T11:58Z, commit `06ddf202`) sobre `05-testes.md` aprovado (rodada 3, QA).
**Branch/commit:** `feature/SOMOSAGILITY-26`, `06ddf202`.

## Validação e deploy
| Passo | Deploy ID | Resultado |
|---|---|---|
| `--dry-run` contra QA | `0AfHa00000EPEPVKA5` | Succeeded, 94/94 componentes, 0 erros |
| Deploy real na QA, 2026-11-26T12:00Z | `0AfHa00000EPER7KAP` | Succeeded, 94/94, 0 erros |
| Deploy anterior da esteira (QA, 2026-11-20T23:36Z, `d36dd65f`) | `0AfHa00000EM4PtKAL` | Succeeded (ver `05-deploy-qa.md`) |

Sem Apex, então não há testes Apex a rodar. Pacote montado com a mesma lista da esteira (`pacote_da_demanda.py`, componentes nomeados, sem curinga). Perfis e permission sets foram reduzidos na cópia de trabalho ao que a demanda acrescenta (`permissoes_so_o_diff.py`: só as `fieldPermissions` dos 9 campos) e a cópia voltou ao conteúdo commitado depois do deploy (`git status` limpo em `force-app/`). Nada foi removido (sem `destructiveChanges`).

## Componentes implantados
- CustomField (9), LongTextArea 32.768: `PFP_1_Texto__c`, `PFP_2_Texto__c`, `PFP_3_Texto__c` em cada um de `BluePrint__c`, `Propostas_de_Solucao__c`, `FluxoVendaProdutos__c`
- Layout (16): BluePrint 1, Propostas_de_Solucao 10, FluxoVendaProdutos 5 (lista completa em `05-deploy-qa.md`)
- Flow (1): `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`
- Profile (66) e PermissionSet (2: `DiretorComercial`, `Acesso_completo_Esteira_de_vendas_e_renovacoes`): só as `fieldPermissions` dos 9 campos (573 linhas na dev e na QA, conferidas pelo QA)

## Versões e ativação
| Item | Antes | Depois (QA) |
|---|---|---|
| Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` | v3 Active (ativada pelo QA na rodada 2, autorizada no design) | v3 Active, única versão (Tooling `Flow`, consultado depois do deploy real). Conteúdo inalterado; o deploy não criou versão nova. |

Nesta etapa não ativei nem desativei nada. Na dev: v2 Active, v3 Draft (v1 Obsolete). **Em produção** a v2 provavelmente é a que está em uso: confirmar a versão ativa lá antes de ativar a v3 (o design dizia "v1 ativa, única" e estava errado na dev).

## Passos manuais
Feitos na QA: ativação da v3 do Flow (pelo QA, rodada 2).
Ficam para produção (dono: consultor responsável, com janela e aprovação registrada):
1. Antes do deploy, registrar a versão ativa do Flow em produção (para rollback).
2. Deploy do pacote (campos, layouts, FLS, Flow em Draft), na ordem: campos, depois layouts/FLS/Flow (o deploy resolve dentro do pacote).
3. Ativar a nova versão do Flow só depois do deploy e de conferir os campos nos layouts.
4. Conferir o FLS dos 9 campos nos perfis que o cliente usa (perfis existentes diferem entre orgs; 459 linhas na QA na rodada 2 contra 573 na dev antes do deploy dos 16 layouts, hoje 573).
5. Pontos abertos da homologação, fora desta entrega: fórmula `FVP.PFP1UNCPath__c` = `'a'` na QA (na dev é `PropostaSolucao__r.PFP_1__c`), cabe ao time conferir se é rascunho de sandbox; premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP) do design.
6. Desvio conhecido: no "Layout de BluePrint" o campo antigo é `Required`; o novo entra `Edit`.

## Plano de rollback
Sinal para voltar: PSL salva sem `PFP_N_Texto__c` preenchido a partir do BluePrint, ou erro no Flow nas primeiras PSLs salvas (observar na primeira hora e no primeiro dia útil), ou o usuário perder acesso a campo antigo.
Ordem inversa do deploy:
1. **Flow:** reativar a versão anterior (em QA/dev, a v2 na dev; na QA não há versão anterior ativa, então desfazer é desativar a v3). Em produção, a versão registrada no passo manual 1.
2. **FLS:** reimplantar o permission set/perfil anterior ou tirar a permissão dos 9 campos (não use os arquivos do repo como backup de perfil; commit anterior na `main` é a referência: `f67beb09`).
3. **Layouts:** reimplantar os 16 layouts da `main` (`f67beb09`), tirando os campos novos da tela.
4. **Campos:** não apagar. Ficam sem layout e sem permissão. Remoção só por `destructiveChanges` com aprovação nominal e backup.

Sem volta: texto gravado em `PFP_N_Texto__c` e valores copiados para `PFP_N__c` pelo Flow enquanto a v3 esteve ativa (rollback de metadata não desfaz dado; na QA há 1.475 PSLs reais sujeitas a isso). Estado de antes registrado: Flow v3 Active na QA (tabela acima), v2 Active na dev.

## Material para produção
Pacote, sequência e passos manuais acima. Produção é ato humano (skill `subir-producao`), com janela, rollback e aprovação registrada. Não deixei comando de deploy de produção pronto.
