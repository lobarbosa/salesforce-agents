# SOMOSAGILITY-13 — Design: Esteira de venda para Renovação

- **Org consultada:** `sbx-somos-agility-dev` (Org ID `00DHa0000070wxfMAA`, `IsSandbox = true`). Recon de 2026-10-30, em `02-recon.md`.
- **Insumos:** `demanda.md`, `01-analise.md` (aprovado no gate de análise, ver `gates.md`), `comentarios-do-card.md` (sem respostas às lacunas) e `02-recon.md`.
- **Tipo:** projeto.

> **Este design é condicional.** A análise foi aprovada com as lacunas L0–L10 em aberto, e o recon resolveu só parte delas. O desenho abaixo fixa **a arquitetura** (onde a esteira mora, como ela se isola da venda e o que não pode colidir). Ele **não fixa o conteúdo de negócio** (nomes dos estágios, regras de transição, aprovadores). O build só pode começar depois que o arquiteto humano decidir D1 e D2 (§0) e o consultor responder L1 e L2 (§7).

---

## 0. Decisões que escalo ao arquiteto humano (não decido sozinho)

### D1 — Modelo da esteira: replicar o padrão atual ou seguir o padrão `Parceiros`?

O recon mostrou que a **premissa P2 da análise ("copiar a estrutura atual e ajustar") não se sustenta ao pé da letra**. Na esteira de venda atual, a fase é representada por um **Record Type por fase** (OQF → CVS → PSL → PFC → NEC → FPR → Encerrada). Quem troca esse Record Type é o Process Builder `Fase_da_Oportunidade_Alterada`, com 8 IDs fixos, sem filtro de RT, numa tecnologia em fim de vida. Some-se um layout e um Path por fase, e cerca de 15 VRs com bypass por perfil. Copiar isso para renovação significaria:

- criar 6–7 Record Types novos, 6–7 layouts e 6–7 Paths;
- criar um segundo motor de troca de RT, ou alterar o Process Builder, que é a peça mais acoplada da org;
- duplicar o anti-padrão que o assessment já marcou como risco alto (achados #1 e #2).

| Opção | Descrição | Prós | Contras |
|---|---|---|---|
| **A (recomendada)** | Um RT `Renovacao` + BP `Renovacao` com estágios exclusivos + um Path + um layout. Mesmo padrão da esteira `Parceiros`, que já existe na org | Só configuração. Não toca o Process Builder. Fica isolada da venda por construção | Não é "igual" visualmente: a fase aparece no Path/`StageName`, não no Record Type. Relatórios que agrupam por RT de fase não enxergam a renovação |
| B | Replicar o padrão atual (RT por fase + automação de troca de RT) | Visual idêntico à venda | 3–4× o esforço. Exige Flow novo ou alteração do PB. Multiplica o acoplamento e a dívida técnica |

**Recomendo A.** Mas "semelhante ao que temos hoje" é palavra do cliente, e o anexo que explicaria isso nunca foi lido. **A escolha é do arquiteto humano.**

### D2 — Fonte de verdade de "é renovação"

Hoje convivem quatro sinais (ver `02-recon.md` §2): `Renova_o__c`, `Categoria__c`, `E_Renovacoes__c` (por owner, com IDs fixos) e o perfil do usuário. A opção A acrescenta um quinto, o Record Type. Proposta:

- **Record Type `Renovacao` = fonte de verdade da esteira** (é o que decide BP, Path e layout).
- **`Renova_o__c` fica coerente com o RT:** `true` sempre que RT = `Renovacao`. Motivo: 4 automações e 1 VR existentes já usam esse campo (notificação de contrato encerrado, capa do contrato, bloqueio de owner). Se o campo ficar desalinhado, a renovação nova perde essas regras sem ninguém perceber.
- `Categoria__c` e `E_Renovacoes__c` **não são alterados** nesta demanda.

**Isto é decisão de modelo de dados de Oportunidade** (como a org classifica um negócio) e afeta SOMOSAGILITY-20, que vai criar oportunidades de renovação automaticamente. Por isso **escalo ao humano**. Nenhum campo ou objeto novo é proposto.

### D3 — Oportunidades de renovação que já existem em produção na esteira `OQF`

Essas oportunidades têm `Renova_o__c = true` e estão em RT de fase. Elas migram para o RT novo, ficam onde estão até fechar, ou só as novas entram na esteira nova? **O padrão deste design é: só as novas, sem migração** (ver §5). Isso precisa de confirmação humana, porque muda a leitura de indicadores durante a transição.

---

## 1. Decisão técnica (assumindo D1 = A)

**Nível: configuração, com no máximo um Flow before-save opcional. Sem Apex, sem LWC, sem objeto ou campo novo.**

A esteira de renovação vive em **Opportunity**, num **Record Type e Business Process próprios**, com **estágios (`StageName`) exclusivos da renovação**.

### Por que não ficar só em configuração pura

A única peça declarativa proposta é manter `Renova_o__c = true` quando RT = `Renovacao` (D2). Há duas formas:

- **Validation Rule** (configuração pura): exige que o usuário marque o checkbox. Preferida se o humano aceitar o atrito de UX.
- **Flow before-save** `Opportunity_BeforeSave_ClassificaRenovacao` (declarativo): marca o campo sozinho. Atualiza só o próprio registro, sem DML extra, sem SOQL, e é bulk-safe por natureza.

Proponho a **VR como padrão** (fica um nível acima). O Flow fica como alternativa se o humano preferir não depender do usuário. **Nos dois casos, nada de código.**

### Por que não código

Não há lógica que a configuração não resolva: estágios, Path, layout e visibilidade por RT são todos nativos. Também não há volume ou integração que justifique Apex.

### Por que os estágios precisam ser exclusivos (ponto técnico decisivo)

**Conflito de automação, risco alto:** o Process Builder `Fase_da_Oportunidade_Alterada` roda em todo create/edit de Opportunity e reescreve o `RecordTypeId` com base **apenas** no `StageName`, para `Qualificação`, `Desenvolvimento`, `Fechamento`, `NEC`, `FPR` e `Ação DIA`, **sem olhar o Record Type**. Se o BP `Renovacao` reutilizar qualquer um desses valores, a oportunidade de renovação é **arrancada da esteira** e jogada para OQF/CVS/PSL/NEC/FPR no primeiro save.

Além disso, `Remove_Fase_CVS_RVS_para_Oportunidades_de_Renovacoes` grava RT = `PSL` quando `StageName = Desenvolvimento` e `Renova_o__c = true`. Ele também ejetaria a oportunidade.

**Mitigação sem tocar no PB:** todos os estágios do BP `Renovacao` são valores **novos** de `OpportunityStage`, com prefixo próprio (ex.: `REN - ...`). Nenhum deles casa com as condições do PB nem do Flow. Esta é a razão de não reaproveitar os estágios da venda, mesmo que a demanda diga "semelhante".

---

## 2. Componentes

Os nomes seguem a skill `padrao-entrega`, porque o `CLAUDE.md` do cliente não define convenção própria. Tudo marcado "criar" foi checado como **inexistente** na org em 2026-10-30.

### 2.1 Criar

| # | Tipo | API name | Detalhe |
|---|---|---|---|
| C1 | `OpportunityStage` (valores de `StageName`) | `REN - <estágio>` ×N | **Lista pendente (L1).** Proposta provisória, baseada na única regra de renovação que já existe (renovação pula CVS/RVS): `REN - Qualificação`, `REN - Proposta`, `REN - Negociação`, `REN - Processamento Financeiro`, mais um ou dois fechados (`REN - Renovado` ganho, `REN - Não Renovado` perdido). Cada valor exige ForecastCategory, Probabilidade e IsClosed/IsWon definidos (L2/L6). O BP `OQF` atual não tem estágio fechado e fecha por `Status__c`; **decidir se a renovação segue igual ou tem estágio fechado** (pergunta P-4, §7) |
| C2 | `BusinessProcess` | `Opportunity.Renovacao` | Só os valores C1 |
| C3 | `RecordType` | `Opportunity.Renovacao` | Ligado ao BP C2. Herda os valores de `Categoria__c` e `Tipo_de_Renovacao__c` restritos ao que faz sentido para renovação (ex.: `Categoria__c` só com os valores "(Renovação)" e "Subscrição ou Renovação"), **a confirmar (L3)** |
| C4 | `PathAssistant` | `Fase_Renovacao` | Path do RT C3 sobre `StageName`, com texto de orientação por estágio (conteúdo vem de L1/L2) e campos-chave por estágio |
| C5 | `Layout` | `Opportunity-Renovacao` | Clonado de `Opportunity-Opportunity Renew Layout` (já existe e já foi pensado para renovação), com os campos de renovação de `02-recon.md` §2 em destaque. Seções finais dependem de L3 |
| C6 | `PermissionSet` | `PS_Comercial_Renovacao` | Só a visibilidade do RT C3, sem ampliar acesso a objeto. Ver §3 sobre não reaproveitar `Acesso_completo_Esteira_de_vendas_e_renovacoes` |
| C7 | `ValidationRule` | `Opportunity.REN_Classificacao_Renovacao` | `RecordType.DeveloperName = 'Renovacao' && NOT(Renova_o__c)`, que bloqueia o save (padrão de D2). **Alternativa (C7'):** Flow `Opportunity_BeforeSave_ClassificaRenovacao`, record-triggered before-save, entrada `RecordType.DeveloperName = 'Renovacao'`, atribui `Renova_o__c = true`. **Escolher um dos dois, não os dois** |
| C8 (opcional) | `FlexiPage` | `Oportunidade_Renovacao` | Só se o humano quiser página Lightning dedicada (o precedente `Parceiros` tem). Sem ela, usa a página padrão + layout C5 |

### 2.2 Alterar

| # | Componente | Alteração |
|---|---|---|
| A1 | Picklist `Opportunity.StageName` | Incluir os valores C1. Mudança global de picklist, ver R4 |
| A2 | Perfis `Renovações` e `Gerente de renovações` (+ outros que L8 indicar) | Atribuição de layout C5 para o RT C3. **Layout por RT só se atribui via perfil**, não há como fazer só com PS |
| A3 | Perfis/usuários de venda que **não** devem criar renovação | Nada a fazer: o RT C3 só aparece para quem recebe C6 |

### 2.3 Depreciar

**Nada.** O Process Builder `Fase_da_Oportunidade_Alterada`, o Flow `Remove_Fase_CVS_RVS_para_Oportunidades_de_Renovacoes`, as VRs com bypass de perfil e os Flows de owner com IDs fixos **continuam como estão**. O desenho foi feito para não depender de alterá-los. A limpeza deles é recomendação separada (§6).

---

## 3. Permissões

- **RT `Renovacao`:** concedido por `PS_Comercial_Renovacao`. Os titulares são L8. Candidatos óbvios: perfis `Renovações` e `Gerente de renovações`, e Administração.
- **Por que PS novo, e não `Acesso_completo_Esteira_de_vendas_e_renovacoes`:** aquele PS já concede CRUD em ~17 objetos e tem 0 atribuições na dev. Não sabemos quem o tem em produção, então ampliá-lo daria RT de renovação a gente desconhecida. Um PS só com o RT é aditivo e auditável. Se o humano preferir consolidar, é troca simples.
- **Layout:** via perfil (A2). Isso reforça o achado #6 do assessment (perfil por pessoa), mas é limitação da plataforma para page layout. Com C8 + atribuição de FlexiPage por app/RT, dá para reduzir essa dependência.
- **FLS:** todos os campos do layout C5 já existem. Conferir no build se os perfis/PS de renovação têm leitura e edição em `Tipo_de_Renovacao__c`, `N_Contrato_a_ser_Renovado_1__c/_2__c`, `Contrato_Agility__c` e `Renova_ao_ano_anterior__c`. Essa checagem **não foi feita** no recon.
- **Licença:** nenhum usuário novo previsto. A licença `Salesforce` está em 97% (assessment #9).

---

## 4. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| **R1** | **Conflito de ordem de execução: o PB `Fase_da_Oportunidade_Alterada` reescreve `RecordTypeId` por `StageName` em todo save, sem filtro de RT. Estágio compartilhado tira a oportunidade da esteira de renovação** | **Alta** | Estágios exclusivos (C1). Teste explícito no QA: percorrer todos os estágios REN e conferir que o RT continua `Renovacao` |
| **R2** | **Há 31 Flows ativos em Opportunity, 24 after-save no mesmo evento, mais PBs. A oportunidade de renovação vai disparar todos os que não filtram RT (alertas Digital/Security/Large Accounts, notificações de arquiteto/blueprint/plano de teste, os cinco "Preenche ... anterior", owner com IDs fixos)** | **Alta** | No build, montar a matriz "Flow × dispara para RT Renovacao? × efeito desejado?" e levar ao humano. Se algum precisar ser excluído, isso **é alteração de Flow existente fora deste escopo**: vira decisão humana e possivelmente outra demanda |
| R3 | `Remove_Fase_CVS_RVS_para_Oportunidades_de_Renovacoes` ejeta para PSL se `StageName = Desenvolvimento` e `Renova_o__c = true` | Média | Coberto por C1 (nenhum estágio REN é `Desenvolvimento`) |
| R4 | `StageName` é picklist global. Valores novos aparecem em relatórios, list views e no forecast. Relatórios e dashboards que filtram por estágio ou RT de fase **não vão mostrar a renovação**, e os que listam todos os estágios vão mostrá-la misturada | Média | Inventário de relatórios não foi feito (recon §7). Validar com o cliente quais indicadores precisam incluir ou excluir renovação (L6). Definir ForecastCategory de cada estágio REN com o cliente |
| R5 | Classificação de renovação fragmentada (D2): passa a haver 5 sinais. Oportunidades criadas com RT `Renovacao` sem `Renova_o__c` perdem 4 automações existentes | Média | C7/C7'. Decisão D2 |
| R6 | Coexistência: renovações antigas seguem no BP `OQF` com bypass de perfil e as novas vão no BP `Renovacao`. Durante a transição, o indicador "renovação" tem duas fontes | Média | D3. Documentar em `06-entrega.md` como filtrar as duas |
| R7 | SOMOSAGILITY-20 (criação automática de renovações) depende do RT/estágio inicial definidos aqui. Se andar antes, nasce na esteira errada | Média | Sequenciar: SOMOSAGILITY-20 só entra em design depois do gate deste design. Registrar a dependência no card |
| R8 | O PB `Fase_da_Oportunidade_Alterada` não filtra RT, o que **provavelmente** também afeta a esteira `Parceiros`, que reutiliza Qualificação/Desenvolvimento/Fechamento. Hipótese, não testada | Média (fora do escopo) | Só registrado. Não corrigir nesta demanda |
| R9 | Erro de digitação `"Renvoações"` em `M40_Ha_Budget_disponivel_CVS` e `M41_Qualificacao_de_fase_NEC_para_FPR`: o bypass falha para o perfil `Renovações` | Baixa (fora do escopo, não afeta a esteira nova porque os estágios REN não casam com essas regras) | Só registrado |
| R10 | A sandbox de dev tem 0 oportunidades e 0 contratos. O QA precisa criar massa de teste própria, e o volume de produção é desconhecido | Baixa | A solução é só configuração e before-save sem SOQL. Não há risco de limite de governador. Massa sintética no QA |
| **R11** | **Conteúdo de negócio desconhecido (L0–L3): estágios, transições, campos obrigatórios por estágio e diferenças em relação à venda. Construir agora seria inventar regra** | **Alta (processo)** | Build bloqueado até L1/L2 respondidas (§7). A arquitetura não muda com as respostas, só o conteúdo de C1/C4/C5 |

**Limites de governador:** nada novo consome SOQL ou DML. C7' (se escolhido) é before-save com atribuição no `$Record`, que é bulk-safe. O custo marginal por save vem das automações já existentes (R2), não deste desenho.

---

## 5. O que NÃO será feito nesta demanda

- Alterar, desativar ou migrar o Process Builder `Fase_da_Oportunidade_Alterada` ou qualquer outro PB/Flow existente.
- Excluir Flows existentes da oportunidade de renovação (R2). Se a matriz do build mostrar necessidade, vira decisão humana ou outra demanda.
- Migrar oportunidades de renovação existentes para o RT novo (D3). Carga de dados não é escopo; também não é SOMOSAGILITY-19, que trata `Hist_rico_de_Venda_e_Renova_o__c`.
- Criar oportunidades de renovação automaticamente (é SOMOSAGILITY-20).
- Criar objeto ou campo novo. Unificar ou remover `E_Renovacoes__c`, `Categoria__c` ou os IDs de usuário fixos.
- Corrigir o erro de digitação `"Renvoações"` (R9), os Flows e VRs com estágios inexistentes (`02-recon.md` §3.3 e §4) e o comportamento do PB sobre `Parceiros` (R8).
- Processos de aprovação, integração externa (SnapERP/`snap_finan` incluído) e relatórios/dashboards novos. Entram só se L7/L8/L6 pedirem, via revisão deste design.
- Qualquer coisa em `sbx-somos-agility-qa` ou produção nesta etapa.

---

## 6. Recomendações fora do escopo (para o backlog)

1. Fazer o PB `Fase_da_Oportunidade_Alterada` respeitar Record Type, ou migrá-lo para Flow (assessment #1 e #2; R8).
2. Limpar Flows e VRs que comparam `StageName` com valores inexistentes.
3. Corrigir `"Renvoações"` em M40/M41.
4. Substituir os IDs de usuário fixos (fórmula `E_Renovacoes__c`, Flows de owner, VR `Alteracao_do_Owner_se_Renovacoes`, Flow da capa do contrato) por grupo/fila ou Custom Metadata.

---

## 7. Pendências para liberar o build

Perguntas ao consultor, no card. Bloqueiam o build, não a aprovação da arquitetura:

- **P-1 (L1):** lista e ordem dos estágios da renovação. A proposta provisória está em C1.
- **P-2 (L2):** campos obrigatórios e condições para avançar em cada estágio. Vão virar VRs novas com filtro `RecordType.DeveloperName = 'Renovacao'`, o que pode subir a estimativa.
- **P-3 (L3):** quais campos e valores de `Categoria__c`/`Tipo_de_Renovacao__c` a renovação usa e quais seções o layout precisa.
- **P-4:** a renovação fecha por estágio (Renovado/Não Renovado) ou por `Status__c`, como a venda?
- **P-5 (L8):** quem opera (recebe `PS_Comercial_Renovacao`) e quais perfis recebem o layout.
- **P-6 (L6/L7):** quais indicadores e relatórios precisam enxergar a renovação. Há integração (SnapERP/`snap_finan`) disparada por estágio?
- **P-7 (L0):** liberar o anexo no card, com a declaração de ausência de dado pessoal. Se ele contradisser este desenho (ex.: exigir objeto próprio), o design volta para revisão.

Decisões do arquiteto humano: **D1, D2, D3** (§0) e a escolha **C7 (VR) ou C7' (Flow)**.

---

## 8. Estimativa de esforço humano

**Estimativa de esforço:** 16–30 h

Considera a opção A (D1), C7 ou C7', estágios entre 4 e 6, até 3 VRs de transição novas, sem integração e sem FlexiPage dedicada.

- Configuração (C1–C7, A1–A2): 5–8 h
- Matriz de regressão das ~31 automações de Opportunity e dos PBs (R2), com revisão humana dos resultados: 4–8 h
- Teste em dev, roteiro de QA, homologação e massa sintética: 5–9 h
- Revisão das respostas P-1 a P-7 e ajustes: 2–5 h

**O que mudou em relação à análise (12–40 h) e por quê:**

- **O teto caiu de 40 para 30 h.** O recon confirmou que não é preciso objeto novo nem campo novo de classificação (`Renova_o__c`, `Tipo_de_Renovacao__c` e os lookups de contrato já existem). Também confirmou que a org já tem precedente de esteira paralela (`Parceiros`). Os principais motores do teto da análise saíram.
- **O piso subiu de 12 para 16 h.** O acoplamento PB × `StageName` × RecordType obriga a usar estágios exclusivos e a validar o RT em cada transição. A concentração de 31 automações em Opportunity torna a matriz de regressão obrigatória. Uma "cópia com poucos ajustes" não fica mais em 12 h.
- **Fora da faixa:** se D1 = B (replicar RT por fase com motor de troca de RT), a estimativa vai para **40–60 h**. Se o anexo exigir processo de aprovação, integração ou exclusão de Flows existentes, o design volta para revisão antes de reestimar.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
