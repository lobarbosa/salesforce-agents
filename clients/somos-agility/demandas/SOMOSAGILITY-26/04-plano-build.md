**Resultado do build:** concluído

# SOMOSAGILITY-26 — Plano de build (builder-declarativo)

**Org de build:** `sbx-somos-agility-dev` (sandbox, confirmada com `sf org list`; username `konectabr@somosagility.com.br.sbxdev`). QA e produção não foram tocadas.
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
