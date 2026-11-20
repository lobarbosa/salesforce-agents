**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-26 — Testes na QA (rodada 2)

Org confirmada com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected). Deploy da esteira `0AfHa00000EM4CzKAL` (Succeeded) em `05-deploy-qa.md`. Critérios do `01-analise.md` aplicados ao design aceito (9 campos novos, G1-b, 32.768). Dados só sintéticos `TESTE SOMOSAGILITY-26`; nenhum registro existente da QA foi lido ou alterado.

## Falhas

### FALHA 1 (crítica) — Campos novos não aparecem em 9 dos 16 layouts na QA
- Reproduzir: abrir na QA a PSL de teste (Propostas de Solução, detalhe) com o usuário de execução (Administrador do sistema); ou `sf project retrieve start -m "Layout:Propostas_de_Solucao__c-*" -m "Layout:FluxoVendaProdutos__c-*" -m "Layout:BluePrint__c-*"` na QA e contar `PFP_N_Texto__c` por arquivo.
- Obtido: a página da PSL mostra "*PFP 1/2/3 (UNC Path)" e nenhum campo novo "PFP 1/2/3" (screenshot `evidencias/02-c12-psl-de-teste-na-qa-detalhes-mostram-.jpg`). Retrieve dos layouts na QA: com os 3 campos: BluePrint "Layout de BluePrint"; PSL "PFP Base", "Proposta Enviada ao Cliente", "Proposta Finalizada", "Retorno do Cliente"; FVP "Layout de Fluxo de Venda de Produto", "Produtos na PFP" (7 layouts). **Sem os campos (0): PSL "Criação da Proposta", "Especificação Técnica", "Layout da Proposta de Solução Mestre", "Layout da Proposta de Solução", "Margens e Condições Especiais", "Z_Ações de Pré fechamento"; FVP "Solicitação de Preços", "Validar Cotação", "Validação Fiscal"** (9 layouts).
- Esperado: os 16 layouts do design (3.2) com os campos novos. No repositório, os 16 arquivos têm os 3 campos (grep: 3 em cada).
- Causa provável: o pacote levado à QA (`05-deploy-qa.md`) lista só 7 layouts; os 9 restantes estão no repo mas não foram incluídos no deploy da esteira (provável diff contra um baseline que já os continha, de deploy anterior que falhou). Corrigir incluindo os 9 layouts no deploy da QA. Sem isso o usuário que usa o layout principal da PSL não vê os campos.

## Observações (não bloqueiam sozinhas)
- **Fórmula do FVP na QA diverge do repo/dev:** `FluxoVendaProdutos__c.PFP1UNCPath__c` na QA tem a fórmula literal `'a'` (describe), não `PropostaSolucao__r.PFP_1__c`. O campo não faz parte desta entrega. Por isso C9 não pôde ser provado na QA (lê "a" com ou sem a demanda). Na dev passou (V7 de `04-verificacao.md`). Sugestão: o time conferir se isso é rascunho de sandbox ou desvio a corrigir antes da produção.
- **FLS na QA:** contagem agregada por `Field IN (...)` = 459 (BluePrint 47 por campo, PSL 54, FVP 52), contra 573 na dev. A diferença é de perfis presentes por org (a QA tem menos perfis); o pacote só concede a quem existe. Não é defeito comprovado.

## Retestes da rodada 1 (`05-testes-rodada-1.md`)
- FALHA 1 (Flow sem versão ativa): **corrigida**. Ativação autorizada em `03-design.md` (decisão de 2026-11-20). Cópia BluePrint para PSL exercitada (C7, C8).
- C2 (contagem de FLS com lista explícita): **executado**, ver tabela.
- C12 (layouts pela tela): **executado**, e reprovou (FALHA 1 desta rodada).

## Versão de Flow (regra de ativação)
`Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`. Antes: v3 Draft, nenhuma ativa (Tooling `Flow`). Ativação por deploy só desse Flow com `<status>Active</status>` (deploy `0AfHa00000EM4EbKAL`, Succeeded; conteúdo do Flow não alterado, só o status). Depois: **v3 Active** (Tooling `Flow`: `3 Active`). Fica ativa ao final.

## Casos

| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| C1 | 9 campos existem com tamanho alvo (rodada 1, mesma org, nada mudou nos campos) | 9 LongTextArea 32768 | Rodada 1: 9 linhas "Área de texto longo(32768)". Esta rodada: PFP_N_Texto__c gravado em BluePrint (603/303/53) e FVP (401 e 32768 caracteres) | passou |
| C2 | `FieldPermissions` com `Field IN` dos 9 campos, agrupado | Linhas de permissão para os 9 campos | 9 linhas de grupo, 459 no total (BP 47, PSL 54, FVP 52 por campo) | passou (ver observação de contagem) |
| C3 | Tamanho alvo: BluePrint e FVP | Salva e lê completo | FVP `PFP_3_Texto__c` 32768 lido: `RES6 401/32768`; BluePrint 603/303/53 (rodada 1: 32768 nos 3) | passou |
| C4 | Recusa de N+1 | `STRING_TOO_LONG` | Rodada 1: `STRING_TOO_LONG ... valor de dados grande demais`; sem mudança de campo desde então | passou (rodada 1) |
| C7 | Flow v3 ativo: criar PSL na Oportunidade com BluePrint de teste (textos 603/303/53) | PSL recebe os 3 textos completos | Apex anônimo separado: `RES3 t=603/303/53` | passou |
| C8 | Flow copia o antigo (UNC) e não sobrescreve valor digitado | `PFP_N__c` = UNC do BluePrint; manual preservado; campo novo vazio recopiado | Criação: `old=\\srv\a1|\\srv\a2|\\srv\a3`. Após update com texto novo nulo e `PFP_1__c='MANUAL-TESTE'`: `t=603/303/53 old=MANUAL-TESTE|\\srv\a2|\\srv\a3` | passou |
| C9 | Fórmula do FVP segue mostrando o antigo | Valor do antigo | FVP lê `PFP1UNCPath__c = 'a'`: fórmula da QA é a constante `'a'` (describe), fora desta entrega | não comprovável na QA (ver observação); passou na dev |
| C10 | Dados existentes íntegros | Sem mudança nos existentes | Contagens antes e depois: BluePrint 322, PSL 1.475, FVP 0; só foram criados e removidos registros de teste | passou |
| C11 | VRs e automações sem erro, agora com o Flow ativo | Sem exceção | Criação de Conta, Contato, Oportunidade, BluePrint, PSL, FVP e updates concluídos sem erro com o Flow v3 ativo | passou |
| C12 | Layouts mostram os campos novos (tela e retrieve) | 16 layouts com os campos | 7 de 16 com os campos; PSL de teste na tela sem os campos novos | **reprovado** (FALHA 1) |
| C13 | Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP) | Verificar na homologação | Não testável na sandbox | não executado (segue para homologação) |

## O que pode ter saído da org
Criados e depois apagados: 1 Conta, 1 Contato, 1 Oportunidade, 1 BluePrint, 1 PSL, 1 FVP (todos `TESTE SOMOSAGILITY-26`). Nenhuma chamada externa identificada; automações de Oportunidade rodaram sobre esses registros (e-mail ou tarefas, se houver, não foram inspecionados). Contagens finais: BluePrint 322, PSL 1.475, FVP 0; testes com prefixo TESTE: 0 em Conta, Contato e Oportunidade.

## Mudanças no meu usuário de execução
Nenhuma (Administrador do sistema, sem permission set atribuído). A única mudança na org foi a ativação da v3 do Flow, acima.
