# 02 — Recon da org: SOMOSAGILITY-20

**Demanda:** SOMOSAGILITY-20 · **Cliente:** somos-agility · **Org:** `sbx-somos-agility-dev`
(sandbox, confirmado via `SELECT IsSandbox FROM Organization` = `true`; Org Id
`00DHa0000070wxfMAA`; instância `agilitynetworks--sbxdev`) · **Data da coleta:** 2026-10-21.

Todos os achados abaixo vêm de `sf` CLI contra esta org (guardrail #3). Nenhuma query
retornou dado pessoal ou de negócio do cliente — só metadata e `COUNT()` (guardrail #2).
Este recon **não responde** às perguntas de negócio 6.1–6.6 da análise (`01-analise.md`):
ele só confirma o que a org tem hoje. As respostas continuam pendentes.

---

## 1. Objetos envolvidos

### Opportunity (objeto padrão)
Já tem estrutura dedicada a renovação, confirmada via `sf sobject describe --sobject Opportunity`:

| Campo | Tipo | Observação |
|---|---|---|
| `Renova_o__c` | boolean | Flag "é renovação" — nome de label real é "Renovação" |
| `Tipo_de_Renovacao__c` | picklist | Tipo de renovação |
| `Renova_ao_ano_anterior__c` | multipicklist | Renovação ao ano anterior |
| `N_Contrato_a_ser_Renovado_1__c` / `_2__c` | reference → Contract | Até 2 contratos associados à renovação |
| `RenovacaoRealizado__c` | currency | Valor realizado de renovação |
| `Contrato_Agility__c` / `Contrato__c` | reference → Contract | Contrato padrão, relabelado "Contrato Agility" |
| `E_Renovacoes__c` | string (picklist-like) | — não confirmado o propósito exato, não inferir |
| `Id_do_Owner_se_Renovacoes__c` | string | Guarda um Id de owner — sugere regra de owner já existente |
| `snap_finan__*` (Contrato_emitido__c, Data_Inicio_Contrato__c, Duracao_Contrato__c, Primeiro_Vencimento__c, data_emissao_contrato__c) | — | Campos do pacote gerenciado `snap_finan` (ver seção 3) |

**RecordTypes ativos:** Ação DIA, CVS/RVS, Encerrada, Encerramento PSL e PFC, FPR, NEC, OQF,
PFC (default), PSL, Parceiros, Mestre. ("Encerramento NEC" e "OEG" existem mas estão
**inativos**.) Não existe RecordType literalmente chamado "Renovação" — a flag
`Renova_o__c` é quem marca uma oportunidade como renovação, não o RecordType.

**Stages ativos:** Qualificação, Desenvolvimento, Fechamento, NEC, FPR,
0 - Fechado/Perdido, Registro da Oportunidade, Engajamento, Negociação e Proposta,
Proposta Comercial, Fechado Ganho, Fechado Perdido, Ação DIA.

### Hist_rico_de_Venda_e_Renova_o__c ("Histórico de Venda e Renovação" / HVR)
Custom object que já modela o ciclo de renovação por ativo. Campos relevantes
(`sf sobject describe`):

- `Patrim_nio__c` (obrigatório, reference → Asset) — o ativo de origem.
- `Pr_ximo_Vencimento__c` (date) — candidato natural a gatilho de data para 6.1/6.2.
- `Oportunidade_cadastrada_de_Renova_o__c` (reference → Opportunity) — **já existe um
  campo para linkar a oportunidade de renovação criada** a este histórico.
- `Oportunidade_Referente_ao_Evento__c` (reference → Opportunity) — segundo link a
  Opportunity, propósito diferente do anterior, não confirmado.
- `E_o_mais_recente__c` (boolean), `Classe_de_renovacao__c` (picklist),
  `Tipo_do_Evento__c` (picklist), `Rentabilidade_da_Renova_o__c` (currency),
  `Multiano__c`, `Account_ID__c` (reference → Account), `DsaHistorico__c` (reference →
  `DSA__c`).
- Em dev, a tabela está **vazia** (`COUNT()` = 0) — não dá para inferir volume real aqui;
  qualquer estimativa de volume (pergunta 6.8) precisa vir do cliente, não da sandbox.

### Aviso_de_Renovacao__c ("Aviso de Renovação")
Objeto custom existe, mas **sem nenhum campo customizado** — só os campos padrão de
objeto (Owner, Name, datas de sistema). Hoje é uma casca vazia; se vai ser usado para
notificação (pergunta 6.7), ainda não tem estrutura para isso.

### Realizacao_Financeira_de_Renovacoes__c
Campos próprios de resultado financeiro (`Rentabilidade_Renovacao_Fabricante__c`,
`Sales_Out__c`, `Perfil_da_Renovacao__c`, `Linha_de_Negocios__c`) — parece alimentado
depois do fechamento, não antes. Sem relação direta com a criação da oportunidade.

## 2. Automação já existente (nenhuma cria Opportunity automaticamente)

Consultado via `FlowDefinitionView` (320 Flows ativos no total). Os que tocam
Opportunity, HVR ou Contrato Agility e têm relação com renovação:

| Flow | Dispara em | O que parece fazer (pelo nome — não confirmado o corpo) |
|---|---|---|
| `Atualiza_oportunidade_no_HVR` | HVR (create/update) | Atualiza o HVR com dados da oportunidade |
| `Atualiza_ultimo_evento_do_ativo` | HVR (create/update) | Mantém o "último evento" no Asset |
| `Captura_a_conta_atrelada_ao_ativo_e_atualiza_no_historico_de_venda_e_renovacao` | HVR (create/update) | Preenche `Account_ID__c` no HVR a partir do Asset |
| `Verifica_qual_o_hist_rico_de_venda_e_renova_o_mais_recente` | HVR (create/update) | Mantém `E_o_mais_recente__c` |
| `Atualiza_oportunidade_mais_recente_da_Tamires_na_capa_do_contrato` | Opportunity (create/update) | Atualiza referência de oportunidade mais recente no contrato |
| `Atualiza_Owner_da_Oportunidade_se_Renova_es_ou_Shirlei` (3 versões ativas: original, `_v2_1`, `_v2_3`, triggers em Opportunity create/update e em Account update) | Opportunity / Account | Reatribui owner da oportunidade por regra de renovação |
| `Remove_Fase_CVS_RVS_para_Oportunidades_de_Renovacoes` | Opportunity (update) | Ajusta Stage para oportunidades de renovação |
| `Notifica_se_Oportunidade_de_Renovacao_tem_Contrato_Encerrado` | Opportunity (**Scheduled**) | Notifica quando a renovação referencia contrato já encerrado |
| `Contrato_Notificacao_de_Data_Prevista_de_Ativacao`, `Notifica_o_de_Vencimento_do_Contrato_Contratada_Tecnologia`, `Alerta_de_cancelamento_encerramento_de_contrato`, `Contrato_com_Risco_de_Perda` | Contrato Agility | Notificações de ciclo de vida de contrato, não criam Opportunity |

**Nenhum destes Flows cria uma Opportunity.** Todos atuam **depois** que a oportunidade
já existe — atualizando owner, stage, ou campos relacionados. Isso é consistente com a
observação 6.9 da análise ("hoje alguém cria manualmente"): a criação é o único elo que
falta, e é exatamente o que esta demanda pede.

Há 3 versões ativas do mesmo Flow de owner (`_v2_1`, `_v2_3` e o original, sem sufixo),
cada uma com gatilho em objeto diferente (Opportunity create/update, Opportunity update,
Account update) — indício de manutenção incremental sem desativar a versão anterior.
Qualquer automação nova de criação de oportunidade de renovação **vai rodar nesse
ecossistema** e pode dar bounce com esses Flows de owner (ver seção 3).

## 3. O que pode travar ou interferir numa automação de criação

### Apex trigger `InserirOportunidade` em Opportunity
Existe e está **ativo**, mas pertence ao pacote gerenciado **`snap_finan`**
(`NamespacePrefix = snap_finan`, API version 25 — pacote antigo). Corpo não visível
(`sf project retrieve` recusa: "Entity ... cannot be found" para metadata gerenciada; a
Tooling API devolve o `Body` oculto). **Não dá para saber o que esse trigger faz** sem
documentação do fornecedor do pacote — só que ele roda em toda inserção de Opportunity.
Qualquer Flow/automação nova de criação de Opportunity precisa considerar que este
trigger já intercepta o insert, e testar com ele ativo em qa antes de declarar pronto.

### Validation Rule `M25_Oportunidade_criada_somente_em_OQF` (ativa)
```
AND(
  $Profile.Name <> "Administração",
  $Profile.Name <> "Gerente de renovações",
  $Profile.Name <> "Renovações",
  ISNEW(), TEXT(StageName) <> "Qualificação", RecordType.Name = "OQF"
)
```
Lida como: **bloqueia a criação** de uma Opportunity com RecordType "OQF" fora do Stage
"Qualificação" — **exceto** se o perfil de quem está criando for "Administração",
"Gerente de renovações" ou "Renovações". Isso é decisão de arquitetura direta: uma
automação (Flow autolançado, por exemplo) que crie a Opportunity vai rodar sob o perfil
do usuário automatizado configurado para ela (ou do contexto de execução do Flow) — se
esse perfil não estiver na lista de exceção, a criação só passa com RecordType "OQF" e
Stage "Qualificação". O arquiteto precisa decidir explicitamente RecordType/Stage/perfil
de execução à luz desta regra, não assumir.

### Validation Rule `Alteracao_do_Owner_se_Renovacoes` (ativa)
```
AND(ISCHANGED(OwnerId), OwnerId='0050z00000791PmAAI', Renova_o__c=true)
```
Trava a troca do Owner **para fora** do usuário de Id `0050z00000791PmAAI` quando
`Renova_o__c__c = true` — ou seja, já existe uma regra de owner fixo para oportunidades
de renovação. Isso é sinal forte para a pergunta 6.4 (owner): o owner "correto" de uma
renovação já é esse usuário específico (não confirmado o nome — não consultado por
guardrail #2, é User, não Group/Queue). Qualquer Flow novo que crie a Opportunity com
`Renova_o__c__c = true` deveria usar este mesmo Owner para não colidir com a regra.

### Validation Rule `M35_Somente_pode_existir_um_SOW_atual` (ativa, padrão análogo)
Não se aplica a Opportunity de renovação diretamente, mas mostra que o org **já tem**
o padrão "só um registro ativo por vez, verificado por validation rule com exceção de
perfil" em outro contexto (SOW). É um precedente reaproveitável para a regra de
duplicidade (6.6) se o design optar por Flow + validation rule em vez de checar
duplicidade dentro do próprio Flow.

### Perfis confirmados que existem na org
`Administração`, `Administração para Alta Gestão`, `Gerente de renovações`,
`Renovações` (via `force-app/main/default/profiles`, perfis citados nas validation
rules acima existem de fato na org).

## 4. Volume

Em `sbx-somos-agility-dev`, hoje: `Opportunity` com `Renova_o__c=true` → 0;
`Hist_rico_de_Venda_e_Renova_o__c` → 0; `Aviso_de_Renovacao__c` → 0. Sandbox sem dado —
**não serve de proxy para o volume real de produção** (pergunta 6.8 continua sem
resposta; precisa vir do cliente).

## 5. O que isso muda para o design

- A pergunta 6.1 (gatilho) tem um candidato técnico concreto para investigar com o
  cliente: `Hist_rico_de_Venda_e_Renova_o__c.Pr_ximo_Vencimento__c`, já modelado por
  ativo. Não é confirmação de que é esse o gatilho de negócio — é o campo que mais se
  parece com ele.
- A pergunta 6.4 (owner) tem evidência de uma regra já existente (Owner fixo
  `0050z00000791PmAAI` quando `Renova_o__c__c = true`), reforçada por validation rule.
- A pergunta 6.6 (relação/duplicidade) tem dois candidatos de "link" já modelados no HVR
  (`Oportunidade_cadastrada_de_Renova_o__c`, para registrar que já existe oportunidade
  cadastrada para aquele histórico — útil exatamente para checar duplicidade antes de
  criar uma nova).
- A pergunta 6.5 (RecordType/Stage) esbarra direto na M25: RecordType "OQF" + Stage
  "Qualificação" é o único caminho de criação fora dos 3 perfis de exceção.
- Nada disso substitui as respostas de negócio pendentes (6.1–6.6) — são pistas técnicas
  prontas para o arquiteto confirmar com o cliente/consultor, não decisões tomadas.
- O trigger gerenciado `InserirOportunidade` (`snap_finan`) e as 3 versões vivas do Flow
  de owner são risco de efeito colateral que o design precisa endereçar explicitamente
  (ao menos nomeando o risco e o plano de teste em qa), mesmo em escopo de sustentação.

Recon pronto. Nenhuma pergunta de negócio (6.1–6.6) foi respondida aqui — isso segue
pendente para o arquiteto resolver com o humano antes de fechar o design.
