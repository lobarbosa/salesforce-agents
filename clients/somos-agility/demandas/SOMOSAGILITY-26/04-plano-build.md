**Resultado do build:** concluído

# SOMOSAGILITY-26 — Plano de build (builder-declarativo)

**Org de build:** `sbx-somos-agility-dev` (sandbox, confirmada com `sf org list`, pelo alias). QA e produção não foram tocadas.
**Branch:** `feature/SOMOSAGILITY-26`. **Design:** `03-design.md` com aceite do gate (G1-b, G2, G3 32.768, G4, G5). Sem Apex.

## O que foi construído

### 1. Nove campos `LongTextArea` (CustomField)
`PFP_1_Texto__c`, `PFP_2_Texto__c`, `PFP_3_Texto__c`, rótulos "PFP 1/2/3", tamanho **32.768 nos 3 objetos**, 3 linhas visíveis, sem obrigatório/histórico. Descrição e texto de ajuda preenchidos em todos. Deploy na dev: Succeeded (9 criados).
- `force-app/main/default/objects/BluePrint__c/fields/PFP_{1,2,3}_Texto__c.field-meta.xml`
- `force-app/main/default/objects/Propostas_de_Solucao__c/fields/PFP_{1,2,3}_Texto__c.field-meta.xml`
- `force-app/main/default/objects/FluxoVendaProdutos__c/fields/PFP_{1,2,3}_Texto__c.field-meta.xml`

Campos antigos não foram alterados nem removidos.

### 2. Layouts (16, 48 itens)
Cada campo novo entra logo abaixo do antigo, mesma seção/coluna. BluePrint 1, PSL 10, FVP 5 (lista da seção 2.7 do design).
- Comportamento: `Edit`/`Readonly` replicado do antigo. **Desvio pequeno:** no "Layout de BluePrint" o antigo `PFP_1_UNC_Path__c` é `Required`; o novo entrou como `Edit` (o design define campo sem obrigatório). No FVP o antigo é fórmula (Readonly) e o novo entra `Edit` (P2).
- Arquivos: `force-app/main/default/layouts/{BluePrint__c,Propostas_de_Solucao__c,FluxoVendaProdutos__c}-*.layout-meta.xml` (16 alterados). Deploy dev: Succeeded.

### 3. FLS (66 perfis + 2 permission sets = 68 arquivos, 573 grants)
Espelho do FLS dos campos antigos, lido por `FieldPermissions` na dev (só metadata, sem dados). BluePrint/PSL: mesmo nível do antigo (leitura+edição). **FVP:** leitura para quem lia o antigo, edição só para quem tem edição no objeto FVP (23 perfis/PS; antigo é fórmula).
- Edição aditiva (só blocos `fieldPermissions` novos) em `force-app/main/default/profiles/*.profile-meta.xml` e `permissionsets/{DiretorComercial,Acesso_completo_Esteira_de_vendas_e_renovacoes}.permissionset-meta.xml`.
- Nomes de perfil padrão mapeados: Administrador do sistema=`Admin`, Gerente de soluções=`SolutionManager`, Gerente do contrato agility=`ContractManager`, Usuário de plataforma padrão=`StandardAul`, Usuário do Marketing=`MarketingProfile`.
- O deploy na dev foi feito com arquivos mínimos (só os blocos novos), para não empurrar o resto do perfil do repositório (que pode estar defasado). O que está commitado são os perfis completos do repo com os blocos acrescentados.

### 4. Flow — versão nova em Draft
`Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`, arquivo `force-app/main/default/flows/Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada.flow-meta.xml` (`status Draft`, critério de entrada e estrutura inalterados, sem DML nova).
- Decisões: testam `$Record.PFP_N_Texto__c` vazio.
- Cada `recordUpdate` grava (G1-b) `PFP_N_Texto__c` ← `$Record.Oportunidade__r.BluePrint__r.PFP_N_Texto__c` (referência direta, sem fórmula, incerteza I3) **e** `PFP_N__c` ← fórmula `PFP_N_Antigo_Preservado` (`IF(ISBLANK(PFP_N__c), BluePrint.PFP_N_UNC_Path__c, PFP_N__c)`): continua copiando antigo→antigo, sem sobrescrever valor já digitado.
- Descrição da versão preenchida.
- **Achado:** o design dizia "v1 ativa, única". Na dev há 3 versões: v1 Obsolete, **v2 Active (a que estava em uso, não foi editada)**, **v3 Draft (a minha)**. O repo tinha o conteúdo da versão ativa e foi sobrescrito pelo da nova.
- **Limitação da lógica (herdada):** a decisão testa só o campo novo vazio. PSL com novo preenchido e antigo vazio não recebe a cópia do antigo. Caso raro (PSL nova com os dois vazios é o fluxo normal).

## Versões e ativação
| Componente | Versão em uso | Versão nova | Estado |
|---|---|---|---|
| Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` (dev) | v2 Active | v3 Draft | **Ativação pendente** (autorizada no gate, passo da verificação) |

Ativar v3 só depois dos passos 1-4 abaixo. Desfazer: reativar a v2. Na QA a esteira leva a v3 em Draft e a ativação é registrada à parte.

## Passos de verificação (dev, massa sintética, 0 registros nos 3 objetos)
1. Conferir os 9 campos (`sf data query --use-tooling-api` em `CustomField`/`EntityParticle`: tipo, tamanho 32768, descrição).
2. Conferir os campos nos 16 layouts e FLS (contagem agregada de `FieldPermissions` dos 9 campos = 573 linhas).
3. Criar massa sintética: Opportunity com `BluePrint__c`, BluePrint com `PFP_N_Texto__c` e `PFP_N_UNC_Path__c` preenchidos (inclusive texto > 255), PSL ligada à Oportunidade, FVP ligado à PSL. Massa deve satisfazer as 15 VRs ativas e esperar efeito das automações de Oportunidade (assessment).
4. Com a v2 ainda ativa: salvar a PSL e registrar o comportamento atual (referência).
5. **Ativar a v3 na dev**, salvar PSL nova e PSL existente: `PFP_N_Texto__c` da PSL recebe o do BluePrint (inclusive > 255); `PFP_N__c` continua recebendo o antigo; valor antigo já digitado na PSL não é sobrescrito; fórmulas do FVP (`PFP{N}UNCPath__c`) continuam mostrando o valor.
6. Editar `PFP_N_Texto__c` no FVP (editável) e nos layouts.
7. Se reprovar: reativar a v2.

## Pendências e observações
- Paridade com QA não comparada (R6): `deploy validate` contra QA fica para o CI do PR.
- Descrição de campo sem acento de propósito (evitar problema de encoding).
- Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP) seguem para a homologação.

## Correção depois do deploy em QA (enxugar permission sets e perfis)

Motivo: deploy em QA `0AfHa00000EM3aHKAT` falhou só em `PermissionSet DiretorComercial: no CustomApplication named standard__AdvancedTherapyManagement found`. O arquivo da `main` já trazia esse app (o diff contra a `main` era só aditivo); ele entrava no pacote junto com a permissão dos campos.

- **O que mudou:** os 68 arquivos (66 perfis em `force-app/main/default/profiles/` + `permissionsets/DiretorComercial` e `permissionsets/Acesso_completo_Esteira_de_vendas_e_renovacoes`) passaram a conter **somente** as `fieldPermissions` dos 9 campos `PFP_{1,2,3}_Texto__c`. Saíram `applicationVisibilities`, `tabSettings`, `objectPermissions`, `userPermissions`, `classAccesses`, etc.
- **Permission sets:** mantidos `description`, `label` (e `license` no DiretorComercial), exigidos pelo deploy (a primeira tentativa falhou com "Required field is missing: label"). O resto fica como está na org.
- **Conferência:** 573 `fieldPermissions` em 68 arquivos (igual ao build anterior), 0 `<field>` que não seja dos 9 campos novos. Perfis sem permissão dos campos antigos continuam fora do pacote.
- **Validação na dev:** `sf project deploy start --dry-run` (check-only) de 66 perfis + 2 permission sets, via manifest: **Succeeded** (`Dry-run complete`), sem erro de componente.
- **Validação contra a QA: não feita.** Esta sessão só tem a sandbox de dev conectada e a regra do build é não tocar a QA. O check-only contra `sbx-somos-agility-qa` fica para o passo da esteira / CI do PR. O erro conhecido (app inexistente na QA) deixou de existir no pacote (0 ocorrências de `applicationVisibilities`).
- **Efeito no repositório:** esses 68 arquivos agora são parciais (não espelham o perfil/PS inteiro da org). Servem para deploy aditivo da permissão; não usar como backup do perfil. Não houve mudança em campos, layouts nem Flow, nem reabertura da verificação de comportamento.
- **Para o verificador:** confirmar que os 9 campos seguem com a permissão espelhada (573 linhas em `FieldPermissions` na dev) depois do enxugamento.

## Correções da rodada 1 (QA reprovou: 05-testes-rodada-1.md)

Org de build confirmada com `sf org list`: `sbx-somos-agility-dev` (única conectada). QA e produção não foram tocadas. Nenhum componente foi alterado nesta rodada.

- **FALHA 1 (crítica), cópia BluePrint para PSL não exercitada na QA:** não corrigível no build. O QA registrou que não é defeito de construção: na QA o Flow chegou como v3 Draft e não há versão ativa, então nada rodou. O design (3.3) e a regra de versões fazem da ativação um passo separado, e o builder não toca a QA. O artefato do build (Flow v3 Draft, estrutura e critério de entrada inalterados) segue igual ao que passou na verificação em dev (cópia de 618 caracteres para os campos novos, antigos preservados, G1-b).
  - **Decisão pendente, de humano/esteira:** autorizar a ativação da v3 na QA e reexecutar C7 a C9. Atenção do QA: a QA tem registros reais (322 BluePrints, 1.475 PSLs); ativar vale para qualquer PSL salva lá. Desfazer: reativar a versão anterior; na QA não há versão ativa anterior, então desfazer significa desativar a v3.
- **C2 (contagem de FLS na QA não obtida):** erro da consulta do QA (`LIKE` em campo de Id), não do build. Usar lista explícita em `Field`. Esperado: 573 linhas, igual à dev.
- **C12 (layouts pela tela):** fica no roteiro do cliente; não é corrigível aqui.
- **Não reescrito:** C1, C3 a C6, C10 e C11 foram aprovados pelo QA.

### Versões e ativação (atualização)
| Componente | Dev | QA | Estado |
|---|---|---|---|
| Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` | v3 Draft (v2 Active em uso) | v3 Draft, sem versão ativa | Ativação na QA pendente de autorização |

## Correções da rodada 2 (QA reprovou: 05-testes-rodada-2.md)

Org de build confirmada com `sf org list`: `sbx-somos-agility-dev` (única conectada). QA e produção não foram tocadas. Nenhum componente foi alterado nesta rodada.

- **FALHA 1 (crítica), 9 de 16 layouts sem os campos novos na QA:** não é defeito do build; o pacote do repositório está completo. Conferido nesta sessão: os 16 arquivos de layout da branch têm os 3 campos `PFP_N_Texto__c` (3 ocorrências em cada) e os 16 diferem da `main` (192 linhas adicionadas, 12 por layout). O `05-deploy-qa.md` (deploy `0AfHa00000EM4CzKAL`) lista só 7 layouts: faltam PSL "Criação da Proposta", "Especificação Técnica", "Layout da Proposta de Solução Mestre", "Layout da Proposta de Solução", "Margens e Condições Especiais", "Z_Ações de Pré fechamento" e FVP "Solicitação de Preços", "Validar Cotação", "Validação Fiscal". A montagem do pacote de QA é passo fixo da esteira e o builder não toca a QA, então a correção é da esteira: incluir esses 9 arquivos no próximo deploy em QA (ou fazer o deploy de todos os 16 layouts, sem diff contra baseline anterior).
  - **Decisão pendente, de humano/esteira:** reexecutar o deploy em QA com os 16 layouts e o QA repetir C12 (tela e retrieve dos 16).
- **Observação, fórmula `FVP.PFP1UNCPath__c` = `'a'` na QA:** fora desta entrega (campo antigo, não alterado pela demanda). Na dev a fórmula é `PropostaSolucao__r.PFP_1__c`. Cabe ao time conferir se é rascunho de sandbox; C9 só é comprovável na QA depois de alinhada. Não corrigi: seria alterar campo antigo, vetado pelo design (seção 9).
- **Observação, FLS 459 na QA contra 573 na dev:** diferença de perfis existentes por org, sem defeito comprovado.
- **Não reescrito:** C1 a C4, C7, C8, C10 e C11 foram aprovados pelo QA.

### Versões e ativação (atualização)
| Componente | Dev | QA | Estado |
|---|---|---|---|
| Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` | v3 Draft (v2 Active em uso) | v3 Active (ativada pelo QA, autorizada em `03-design.md`) | Sem mudança nesta rodada |
