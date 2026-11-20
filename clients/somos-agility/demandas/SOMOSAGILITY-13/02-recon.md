# SOMOSAGILITY-13 — Recon da org

- **Org:** `sbx-somos-agility-dev`, Org ID `00DHa0000070wxfMAA`. `Organization.IsSandbox = true`, Enterprise Edition, API 68.0 no CLI.
- **Data da coleta:** 2026-10-30. Recon vence em 7 dias.
- **Método:** `sf sobject describe`, SOQL de metadata (`RecordType`, `BusinessProcess`, `OpportunityStage`, `FlowDefinitionView`, `ApexTrigger`, `ProfileLayout`, `PermissionSet`, `ObjectPermissions`), contagens com `COUNT()` e retrieve só de leitura para `/tmp/recon` (nada foi gravado em `force-app/`).
- **Guardrail #2:** nenhum registro de negócio foi lido. Dois Flows citados abaixo têm e-mail e ID de usuário fixos no XML. Eles **não** foram copiados para cá.
- **Volume:** `SELECT COUNT() FROM Opportunity` = 0 e `SELECT COUNT() FROM Contract` = 0 nesta sandbox. A dev não tem massa de dados, então o volume de produção **não foi medido** (guardrail #1).

---

## 1. A esteira de venda atual (lacuna L5): resolvida pelo recon

A esteira de venda atual é a **Oportunidade (`Opportunity`) no Business Process `OQF`**. O que chama atenção é que a fase do funil é representada pelo **Record Type**, e não só pelo `StageName`. Um Process Builder troca o Record Type sempre que o `StageName` muda.

### 1.1 Business Processes de Opportunity

| Business Process | Ativo | Valores de `StageName` |
|---|---|---|
| `OQF` ("Oportunidade Qualificada") | sim | Qualificação, Desenvolvimento, Fechamento, NEC, FPR |
| `Agility Way` ("Processo de Vendas spin Agility Way") | sim | Qualificação, Desenvolvimento, NEC, FPR |
| `Parceiros` | sim | Registro da Oportunidade, Qualificação, Engajamento, Desenvolvimento, Negociação e Proposta, Proposta Comercial, Fechamento, Fechado Ganho, Fechado Perdido |
| `Deploy_Teste` | não | FPR |

O BP `OQF` **não tem nenhum estágio fechado** (IsClosed). O encerramento é feito pelo campo `Status__c`: Aberto, Desengajada, Encerrado Loss, Encerrado Win, Encerrado Win - Processada Financeiro.

### 1.2 Record Types de Opportunity

Todos os ativos abaixo, exceto `Parceiros`, estão no BP `OQF`.

| DeveloperName | Label | Ativo | Business Process | Descrição |
|---|---|---|---|---|
| `OQF` | OQF | sim | OQF | Oportunidade Qualificada |
| `CVS` | CVS/RVS | sim | OQF | Criar Visão da Solução |
| `PSL` | PSL | sim | OQF | Proposta da Solução |
| `PFC` | PFC | sim | OQF | Ações do Pré Fechamento (default) |
| `NEC` | NEC | sim | OQF | Negociação e Compras |
| `FPR` | FPR | sim | OQF | Fechamento em Processamento |
| `Encerrada` | Encerrada | sim | OQF | Oportunidade Encerrada |
| `Encerramento_PSL_e_PFC` | Encerramento PSL e PFC | sim | OQF | Encerrar nas fases PSL e PFC |
| `Acao_DIA` | Ação DIA | sim | OQF | — |
| `Parceiros` | Parceiros | sim | **Parceiros** | — |
| `OEG` | OEG | não | OQF | Oportunidade Engajada |
| `Encerramento_NEC` | Encerramento NEC | não | Agility Way | — |

**Não existe Record Type de renovação.** Também não existe BP de renovação.

### 1.3 `OpportunityStage` ativos, com mapeamento de forecast

| ApiName | Fechado | Ganho | Forecast | Prob. |
|---|---|---|---|---|
| Qualificação | não | não | Improvavel | 20 |
| Desenvolvimento | não | não | Possível | 30 |
| Fechamento | não | não | Possível | 60 |
| NEC | não | não | Commit | 90 |
| FPR | não | não | Commit | 100 |
| 0 - Fechado/Perdido | sim | não | Perdido | 0 |
| Registro da Oportunidade, Engajamento | não | não | Possível | 20/30 |
| Negociação e Proposta, Proposta Comercial | não | não | Commit | 40 |
| Fechado Ganho | sim | sim | Ganho | 100 |
| Fechado Perdido | sim | não | Perdido | 0 |
| Ação DIA | não | não | Improvavel | 0 |

Há também 13 valores **inativos**: `1 - Prospecção`, `PFC`, `6 - Fechado/Ganho`, `7 - Processado ERP`, `MigracaoAW` e outros.

**Achado:** os valores `PSL`, `CVS/RVS`, `OQF`, `OEG` e `Encerrada` **não existem como `OpportunityStage`**, nem ativos nem inativos. Mesmo assim, vários Flows e Validation Rules comparam `StageName` com eles (ver §3 e §4). Esses ramos não disparam hoje, na prática são código morto.

### 1.4 Path (PathAssistant) e Layouts

- Há um Path ativo por Record Type de fase: `Novo_Compromisso_de_fechamento` (OQF), `Fase_CVS_RVS`, `Fase_PSL`, `Fase_PFC`, `Fase_NEC`, `Fase_FPR` e `Fase_OEG`. Também existe `Parceiros` (RT Parceiros). `Compromisso_de_Fechamento` (Master) está inativo.
- Há um layout por fase: `Opportunity-OQF`, `-CVS`, `-PSL`, `-PFC`, `-NEC`, `-FPR`, `-Encerrada`, `-Encerrada PSL/PFC`, `-Encerrada NEC`, `-Ação DIA`, `-Parceiros`.
- **`Opportunity-Opportunity Renew Layout` já existe.** Ele está atribuído a 5 perfis (`Renovações`, `Sales Operations ADM`, `Sales Operations`, `Alta Gestão`, `Estagiário Comercial`), mas **só no Record Type Master**. Como toda oportunidade da esteira vive num RT de fase, esse layout praticamente não aparece.
- Lightning Record Page de Opportunity: existe só `Oportunidade_P_gina_de_registro` ("Oportunidade Parceiros"). As outras fases usam a página padrão.

### 1.5 Precedente de "esteira paralela": `Parceiros`

Já existe uma esteira separada na mesma Opportunity, com BP próprio (`Parceiros`), RT próprio, Path próprio, layouts próprios e Lightning page própria. É o padrão mais próximo do que a demanda pede.

**Achado de risco:** o BP `Parceiros` reutiliza `Qualificação`, `Desenvolvimento` e `Fechamento`. O Process Builder do §3.1 não filtra por Record Type. Uma oportunidade Parceiros que entrar nesses estágios teria o RT trocado para OQF/CVS/PSL. Não foi testado aqui porque a sandbox não tem dados e o recon não grava nada. Fica como hipótese a confirmar.

---

## 2. Como a renovação é representada hoje (lacuna L4): existe, mas fragmentada

A renovação **já roda dentro da esteira de venda `OQF`**. Não há esteira própria, e ela é identificada por **quatro mecanismos que convivem**:

| Mecanismo | Componente | Tipo | Observação |
|---|---|---|---|
| Flag | `Opportunity.Renova_o__c` ("Renovação base Agility?") | checkbox | Usado como critério por 3 Flows (§3) e 1 VR |
| Categoria | `Opportunity.Categoria__c` | picklist | Valores `Contrato de Locação (Renovação)`, `Contrato de Suporte (Renovação)`, `Subscrição ou Renovação` (entre outros). Controla `Contrato_de_Suporte__c` e `Renova_ao_ano_anterior__c` |
| Proprietário | `Opportunity.E_Renovacoes__c` ("É Renovações?") | fórmula texto | `'Yes'` se o `OwnerId` for um de **dois IDs de usuário fixos na fórmula** |
| Perfil | Perfis `Renovações` e `Gerente de renovações` | Profile | Usados como bypass em ~15 Validation Rules da esteira (§4) |

Outros campos de renovação que **já existem** em Opportunity, confirmados por describe:

- `Tipo_de_Renovacao__c` (picklist): Renovação com Índice de Reajuste / sem Índice de Reajuste / com Redução de Valor/Cobertura / com Ampliação de Valor/Cobertura / Nenhuma.
- `Renova_ao_ano_anterior__c` (multipicklist, dependente de `Categoria__c`): Renovado pela Agility Networks / Renovado por outra Revenda / Primeira Renovação.
- `N_Contrato_a_ser_Renovado_1__c` e `N_Contrato_a_ser_Renovado_2__c` (lookup Contract).
- `Contrato__c`, `Contrato_Agility__c` (lookup Contract).
- `RenovacaoRealizado__c` (currency, fórmula). `Id_do_Owner_se_Renovacoes__c` (texto).
- `Data_de_termino_Pos_Aditivo__c`, `Prazo_contratado__c`.

Do lado de `Contract`: `Tipo_de_Renova_o__c` (Automática/Negociada), `Indice_de_Reajuste_para_Renovacao__c`, `indice_Apliavel_para_Renovacao__c` (lookup `Indice__c`), `Contato_do_cliente_para_Renova_o__c`, `EndDate`, `Data_de_T_rmino_P_s_Aditivo__c`, `Mes_do_Vencimento_do_Contrato__c` e `snap_finan__Oportunidade__c`. Os Record Types de Contract são `Cliente` e `Parceiro`.

Objetos custom ligados a renovação que já existem:

- `Hist_rico_de_Venda_e_Renova_o__c`: 42 campos, com lookups para Opportunity (`Oportunidade_cadastrada_de_Renova_o__c`, `Oportunidade_Referente_ao_Evento__c`), Asset, Account, Contact e `DSA__c`. Tem 2 Flows ativos próprios. É o alvo da demanda SOMOSAGILITY-19.
- `Aviso_de_Renovacao__c` (12 campos, sem lookup custom).
- `Realizacao_Financeira_de_Renovacoes__c` (16 campos, sem lookup custom).

---

## 3. Automações em Opportunity

`FlowDefinitionView` mostra **31 Flows ativos** com gatilho em Oportunidade: 24 `RecordAfterSave`, 3 `RecordBeforeSave` (`Atualizar_Descri_o_com_Informa_es_do_Lead`, `Email_Gerente`, `Preenche_Certezas`), 3 `Scheduled` e 1 `RecordBeforeDelete`. Somam-se os Process Builders (ProcessType `Workflow`) com objeto Opportunity, entre eles os do §3.1 e `Atualiza_o_status_da_Oportunidade`.

Apex Trigger em Opportunity: só `InserirOportunidade`, do pacote gerenciado **`snap_finan`** (before insert, API 25). Não dá para editar.

### 3.1 Componente central da esteira: `Fase_da_Oportunidade_Alterada`

Process Builder ativo, label "Estágio da Oportunidade Alterado v1.1". A cada create/edit ele avalia **somente** o `StageName` e reescreve o `RecordTypeId` com ID fixo. **Não há nenhuma condição de Record Type.**

| `StageName` = | Record Type gravado |
|---|---|
| Qualificação | `OQF` (01238000000EAul) |
| Desenvolvimento | `CVS` (01238000000EAuh) |
| Fechamento | `PSL` (01238000000EAum) |
| NEC | `NEC` (01238000000EAuj) |
| FPR | `FPR` (012380000005gZY) |
| Ação DIA | `Acao_DIA` (012U40000029UqX) |
| Encerrada *(estágio inexistente)* | `Encerrada` |
| OEG *(estágio inexistente)* | `OEG` |

Nenhum ramo grava `PFC`. Ninguém neste recon foi visto atribuindo esse RT, embora ele seja o default. Fica em aberto.

### 3.2 Flows que já tratam renovação

| Flow | Gatilho | Critério de entrada | O que faz |
|---|---|---|---|
| `Remove_Fase_CVS_RVS_para_Oportunidades_de_Renovacoes` | AfterSave, Update | `StageName = Desenvolvimento` E `Renova_o__c = true` | Grava `RecordTypeId = PSL` e `StageName = Fechamento`, ou seja, **a renovação pula a fase CVS/RVS**. É a única "regra de esteira de renovação" que existe hoje |
| `Atualiza_Owner_da_Oportunidade_se_Renova_es_ou_Shirlei_v2_1` | AfterSave, Create/Update | `E_Renovacoes__c = Yes` E `Status__c = Aberto` | Preenche `Id_do_Owner_se_Renovacoes__c` |
| `Atualiza_Owner_da_Oportunidade_se_Renovacoes_ou_Shirlei` | AfterSave, Update | `OwnerId` mudou | Reatribui `OwnerId` comparando com usuários fixos no XML (não reproduzidos aqui) |
| `Atualiza_Owner_da_Oportunidade_se_Renovacoes_ou_Shirlei_v2_3` | em Conta | — | Variante na Account, não foi lida |
| `Notifica_se_Oportunidade_de_Renovacao_tem_Contrato_Encerrado` | Scheduled | `Renova_o__c = true`, `Contrato_Agility__c` preenchido, `Status__c = Encerrado Loss` | Notificação |
| `Atualiza_a_oportunidade_mais_recente_da_Tamires_na_capa_do_contrato` | AfterSave, Create/Update | orçamentista com ID fixo E `Renova_o__c = true` | Atualiza a capa do contrato |

### 3.3 Flows com critério de estágio inexistente (código morto)

`Atualiza_Data_de_Alteracao_para_CVS_RVS` e `Atualiza_Data_de_Alteracao_para_PSL` filtram `StageName = 'CVS/RVS'` / `'PSL'` e `StageName <> 'Encerrada'`. Nenhum desses valores existe em `OpportunityStage`.

### 3.4 Flows de tela da esteira (não são record-triggered)

`KN_EngajamentoOportunidade` (grava `Negociação e Proposta`), `NegociacaoProposta` (grava `Aguardando PSL`, que **não existe** como estágio), `Fechamento` (Fechado Ganho/Perdido), `Encerramento_Oportunidade_PSL`, `Desengajamento_Oportunidade` e `Encerramento_Oportunidade_NEC` (Draft).

---

## 4. Validation Rules de Opportunity

São 110 no total, **26 ativas**. Das ativas, 18 referenciam `StageName` e 1 referencia `RecordType` (`M25_Oportunidade_criada_somente_em_OQF`, que restringe por `RecordType.Name = "OQF"`).

Padrão observado: quase todas as regras de sequência de fase dispensam os perfis `Administração`, `Gerente de renovações` e `Renovações`. Exemplos: `M02`, `M07`, `M09`, `M11`, `M12`, `M21`, `M22`, `M25`, `M30`, `M31`, `M36` e `M48`. Ou seja, **a renovação hoje passa pela mesma esteira por bypass de perfil**.

Achados:

- **Erro de digitação em `M40_Ha_Budget_disponivel_CVS` e `M41_Qualificacao_de_fase_NEC_para_FPR`**: as duas comparam com `"Renvoações"`. O bypass não funciona para o perfil `Renovações` nessas duas regras. Não é tratado nesta demanda (§6 do design).
- `Alteracao_do_Owner_se_Renovacoes` bloqueia a troca de owner para um ID de usuário fixo quando `Renova_o__c = true`.
- `Atualizar_Estagio_se_PSL_Aprovada`, `Atualizar_Estagio_se_Blueprint_Aprovado`, `Atualizar_Estagio_se_Cerimonia_Realizada` e `M49_NaoAtualizaOppPsl` comparam `PRIORVALUE(StageName)` com `OQF`/`CVS/RVS`/`PSL`, valores que não existem. Esses ramos estão mortos.

---

## 5. Segurança

- Perfis `Renovações` e `Gerente de renovações` existem e têm Edit em Opportunity. Usuários ativos: `Gerente de renovações` = 1, `Renovações` = 0 (contagem agregada nesta sandbox).
- Atribuição de layout desses dois perfis: um layout por RT de fase (OQF, CVS, PSL, PFC, NEC, FPR, Encerrada, Encerrada PSL/PFC, OEG, Ação DIA, Parceiros). No Master ficam `Opportunity Renew Layout` (Renovações) e `Opportunity Layout` (Gerente de renovações).
- Permission Sets ligados a renovação, já existentes:
  - `Acesso_completo_Esteira_de_vendas_e_renovacoes`: CRUD sem Delete em Opportunity, `Hist_rico_de_Venda_e_Renova_o__c`, `Realizacao_Financeira_de_Renovacoes__c`, `Propostas_de_Solucao__c`, `DSA__c` e `Mapeamento__c`, entre outros. **0 atribuições ativas nesta sandbox.**
  - `Grupo_Renova_es_acessa_edi_o_Contrato`: 0 atribuições ativas nesta sandbox.
- Não existe Flow com prefixo `Opportunity_` nem Permission Set `PS_Comercial_*`, então não há colisão com os nomes propostos no design.

---

## 6. Demandas relacionadas no mesmo cliente

- **SOMOSAGILITY-20**, "Automatização de criação de oportunidades de renovações" (backlog). Vai criar oportunidades de renovação, e o tipo de registro em que elas nascem depende do desenho desta demanda.
- **SOMOSAGILITY-19**, "carga em massa de dados para Históricos de Vendas e Renovações" (backlog). Toca `Hist_rico_de_Venda_e_Renova_o__c`.

---

## 7. O que não foi possível verificar

- O conteúdo do anexo da demanda (L0). Nunca foi liberado.
- Relatórios e dashboards que filtram por `StageName` ou Record Type. Não foram inventariados, e o impacto em forecast e indicadores é desconhecido.
- O comportamento real do Process Builder sobre RT `Parceiros`. Seria preciso criar dados, e o recon não escreve.
- A ordem efetiva de execução entre os 24 after-save. A ordem do Flow Trigger Explorer não foi lida.
- O critério de entrada detalhado dos ~18 after-save não ligados a renovação (alertas Digital/Security/Large Accounts, notificações de arquiteto/blueprint etc.). Fica para o build, com a matriz de regressão.
- O volume de produção e as atribuições de perfil/PS em produção.
- Quem atribui o RT `PFC`.
