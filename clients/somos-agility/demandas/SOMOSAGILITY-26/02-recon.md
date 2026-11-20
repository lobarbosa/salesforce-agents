# SOMOSAGILITY-26 — Recon da org

**Coleta:** 2026-11-20 (refeito após a especificação de 17/11 no card). **Org:** `sbx-somos-agility-dev` (sandbox, Org ID 00DHa0000070wxfMAA), confirmada com `sf org list` (única org conectada, status Connected).
**Escopo lido:** `comentarios-do-card.md` (especificação de 17/11: criar 3 campos Long Text Area "PFP 1", "PFP 2", "PFP 3" em `BluePrint__c`, `Propostas_de_Solucao__c` e `FluxoVendaProdutos__c`; ajustar o Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`, lógica inalterada), `01-analise.md`, `00-preflight.md`.
Só leitura. Retrieve em `/tmp/recon-proj` (fora de `force-app/`). Nenhum registro lido, só metadata e contagens.

## 1. O que já cobre o pedido

| Item | Estado confirmado | Comando |
|---|---|---|
| Campo longo com nome "PFP 1/2/3" nos 3 objetos | **Não existe.** Nenhum campo com rótulo exato "PFP 1/2/3" nos 3 objetos | `sf sobject describe` dos 3 objetos, filtro por nome/rótulo contendo "pfp" |
| Flow que copia PFP do BluePrint para a PSL | Existe e está ativo (versão ativa = última), ver seção 2 | `sf data query --use-tooling-api ... FlowDefinition` |
| Relatório, painel, agente Agentforce, processo de aprovação sobre o tema | **Não verifiquei** (ver incertezas) | — |

## 2. O que será tocado

Campos "PFP" existentes (todos confirmados por describe):

| Objeto | API name | Rótulo | Tipo / tamanho |
|---|---|---|---|
| `BluePrint__c` ("Previsão de Investimento") | `PFP_1_UNC_Path__c`, `PFP_2_UNC_Path__c`, `PFP_3_UNC_Path__c` | PFP N (UNC Path) | url, 255 |
| `Propostas_de_Solucao__c` | `PFP_1__c`, `PFP_2__c`, `PFP_3__c` | *PFP N (UNC Path) | textarea, 255 |
| `Propostas_de_Solucao__c` | `PFP_1_UNC_Path__c`, `PFP_2_UNC_Path__c`, `PFP_3_UNC_Path__c` | PFP N (UNC Path) | fórmula string (exibe 1300) |
| `Propostas_de_Solucao__c` | `Nome_PFP_N__c`, `PFP_N_Fechada__c`, `Valida_PFP_existente__c` (+ `_formula__c`) | Descrição / Fechada / Valida | textarea 255 / boolean / double |
| `FluxoVendaProdutos__c` | `PFP1UNCPath__c`, `PFP2UNCPath__c`, `PFP3UNCPath__c` | *PFP N (UNC Path) | fórmula string (exibe 1300) |

Pontos para o arquiteto:
- **Colisão de API name:** o campo novo com rótulo "PFP 1" geraria por padrão o API name `PFP_1__c`, que **já existe** em `Propostas_de_Solucao__c` (textarea 255). Em `BluePrint__c` e `FluxoVendaProdutos__c` não há `PFP_N__c` (describe). O API name dos novos campos não está definido na especificação.
- A especificação cita os 3 objetos e 3 campos por objeto (9 campos); não diz a que campo antigo cada novo corresponde nem se os antigos saem.
- Descrição (campo `description`) dos campos existentes: não verifiquei nesta rodada.

Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` (retrieve para `/tmp/recon-proj/out`, 323 linhas):

| Atributo | Valor | Comando |
|---|---|---|
| Status / versões | Active; ActiveVersionId = LatestVersionId (uma só versão ativa, sem rascunho mais novo) | Tooling `FlowDefinition` |
| Tipo / gatilho | AutoLaunchedFlow, `RecordAfterSave`, `CreateAndUpdate` em `Propostas_de_Solucao__c`, API 61.0 | retrieve + leitura do XML |
| Entrada do gatilho | só `Oportunidade__c` não nulo | XML `<start>` |
| Fontes (fórmulas) | `{!$Record.Oportunidade__r.BluePrint__r.PFP_N_UNC_Path__c}` (N=1..3) | XML |
| Lógica | cadeia de 7 decisões: se `$Record.PFP_N__c` está vazio, atualiza `$Record` com a fonte N; encadeia 1, 2 e 3 | XML |
| Campos gravados | `PFP_1__c`, `PFP_2__c`, `PFP_3__c` (via `inputReference $Record`) | XML |

## 3. Automação concorrente

| Componente | Observação | Comando |
|---|---|---|
| Flows ativos em `Propostas_de_Solucao__c`, `BluePrint__c` e `FluxoVendaProdutos__c` (consulta junta, não separa por objeto): 12 | `Atualiza_Campo_Blueprint_da_Oportunidade`, `Atualiza_Quando_Bluprint_da_Oportunidade_Aprovado`, `Atualiza_Quando_Proposta_de_Solucao_da_Oportunidade_Aprovada`, `Atualiza_os_Campos_PFP_X...` (o da demanda), `Cria_o_da_Proposta`, `Definir_BOM`, `EmailOrcamentista` (RecordBeforeSave), `Margens_e_Condi_es_Especiais`, `Nova_Proposta_de_Solu_o_SOW_CCS`, `Propostas_de_Solu_o`, `Replica_o_status_da_FVP_para_PSL`, `SolicitacaoPrecos`. Os demais 11 são RecordAfterSave | `sf data query ... FlowDefinitionView` por `TriggerObjectOrEventLabel` |
| Trigger Apex | `TrgPropostasSolucao` ativo em `Propostas_de_Solucao__c`; nenhum trigger em `BluePrint__c` nem `FluxoVendaProdutos__c` | Tooling `ApexTrigger` |
| Validation rules | 19 nos 3 objetos (15 ativas na lista retornada que inclui `M01`, `M02`, `M04`, `M05`, `CNPJ_obrigatorio_se_PFP_fechada` (e `_2`, `_3`), entre outras; `M03_Obrigatorio_preenchimento_campos_PFP` está **inativa**). Lidas: `M01`, `M02`, `M05`, `CNPJ_obrigatorio_se_PFP_fechada` — **nenhuma referencia `PFP_N__c` nem `PFP_N_UNC`** (usam `PFP_N_Fechada__c`) | Tooling `ValidationRule`; retrieve + grep |

Risco de ordem de execução: o Flow é after-save na PSL e atualiza o próprio registro (`$Record`), o que dispara de novo as automações after-save e o trigger da PSL. Isso já ocorre hoje; a mudança não deveria alterar, mas o arquiteto deve decidir se os novos campos entram nessa atualização.

## 4. Riscos do assessment que tocam o pedido

| Risco | Relação com a demanda | Fonte |
|---|---|---|
| 24 automações no mesmo evento em Oportunidade; 31 ativas | O Flow da demanda é na PSL, não em Oportunidade, mas lê `Oportunidade__r.BluePrint__r`. Contagem por objeto da PSL só do conjunto de 12 acima | `assessment.md` (resumo do prompt) |
| Cobertura Apex 40% | `TrgPropostasSolucao` roda quando o Flow atualiza a PSL; se o design não tocar Apex, não bloqueia | resumo do prompt |
| 20 de 26 perfis com 1 usuário | Cada campo novo precisa de FLS por perfil/permission set (ver seção 6) | resumo do prompt |

## 5. Volume e dados de teste

| Objeto | COUNT() | Comando |
|---|---|---|
| `Propostas_de_Solucao__c` | 0 | `sf data query "SELECT COUNT() FROM Propostas_de_Solucao__c"` |
| `BluePrint__c` | 0 | idem |
| `FluxoVendaProdutos__c` | 0 | idem |

A sandbox de dev não tem dado nesses objetos: o teste do Flow exige massa sintética (BluePrint, Oportunidade vinculada e PSL), criada pelo build/QA.

## 6. Permissões

| Objeto | Linhas de `ObjectPermissions` (perfis + permission sets) | Comando |
|---|---|---|
| `Propostas_de_Solucao__c` | 52 (6 permission sets não-perfil: `Perfil_SA_GC`, `DiretorComercial`, `Acesso_completo_Esteira_de_vendas_e_renovacoes` com edição; `Read_Only_Setup_Interface_Access`, `Admin_Access_View_Only`, `PFV_View` só leitura) | `ObjectPermissions` |
| `BluePrint__c` | 46 | idem |
| `FluxoVendaProdutos__c` | 27 | idem |
| `FieldPermissions` de `Propostas_de_Solucao__c.PFP_1__c` | 69 linhas | `FieldPermissions` |

OWD não consultado (ver incertezas).

## O que não consegui confirmar

1. **Dependências dos campos PFP existentes** (layouts, fórmulas, relatórios): `MetadataComponentDependency` não está disponível nesta API/consulta (erro `RefMetadataComponentName is unknown` e `sObject type ... not supported`). Não repito aqui a lista de fórmulas/layouts do `03-design.md` anterior porque não a reconfirmei nesta coleta; a única fórmula confirmada agora é que `PFP_N_UNC_Path__c` e `PFP1UNCPath__c` são do tipo fórmula (describe `calculated`), sem a expressão.
2. **Quais dos 12 Flows ativos são de qual objeto**, e se algum lê ou grava `PFP_N__c` ou os campos `PFP_N_UNC_Path__c`: não retrieve dos 11 restantes.
3. **As 15 validation rules restantes** (de 19) não foram lidas; só 4 foram lidas.
4. **Descrição, layouts e FlexiPages** em que os campos entrariam: não verificados.
5. **Relatórios, painéis, agente Agentforce, processo de aprovação, Conga/SDocs/SnapERP** lendo os campos PFP: não verificado.
6. **OWD** dos 3 objetos e as permissões do usuário de integração: não consultado.
7. **Diferença dev x QA**: `sbx-somos-agility-qa` não está conectada nesta sessão; não comparei metadata.
8. **Os 6 permission sets listados com `ObjectPermissions` em PSL** são só os não-perfil; os perfis não foram detalhados por nome.
9. Como a COUNT() devolveu 0, tratei como "sandbox sem dados"; não confirmei por outra consulta.
