# 03 — Design: Automatização de criação de oportunidades de renovações

**Demanda:** SOMOSAGILITY-20 · **Cliente:** somos-agility · **Tipo:** sustentação (design enxuto)
**Org consultada:** `sbx-somos-agility-dev` (sandbox, `IsSandbox = true`) · **Data:** 2026-10-21
**Entradas:** `01-analise.md` (aprovada em `gates.md`, bloco `aguardando_gate_analise`), `02-recon.md`,
`comentarios-do-card.md`, e confirmações complementares feitas nesta sessão via `sf` CLI (listadas na seção 9).

> **Situação do design: aprovável na abordagem, bloqueado para build em 2 pontos.**
> A abordagem técnica (Flow agendado que cria a Opportunity e grava o vínculo de volta) fecha
> com o que a org já tem. Duas perguntas da análise, porém, mudam **em qual objeto** o Flow
> roda e **quem entra**: 6.1 (gatilho/objeto de origem) e 6.3 (elegibilidade). Sem elas o
> build não arranca. As demais (6.2, 6.4, 6.5, 6.6) seguem como **premissas explícitas** que
> o arquiteto humano aceita ou corrige neste gate. Nada aqui foi tratado como confirmado sem fonte.

---

## 1. Decisão

**Schedule-triggered Flow (declarativo), sem Apex, sem campo novo** — desde que a origem seja
`Hist_rico_de_Venda_e_Renova_o__c` (HVR) ou `Contract` (ver 6.1).

Desenho proposto (objeto de origem HVR, premissa P-6.1):

1. Flow agendado, diário, sobre `Hist_rico_de_Venda_e_Renova_o__c`, com filtro de entrada:
   `Pr_ximo_Vencimento__c` = HOJE + N dias **e** `Oportunidade_cadastrada_de_Renova_o__c` vazio
   **e** `E_o_mais_recente__c = true` **e** critérios de elegibilidade (6.3, pendentes).
2. Cria a `Opportunity`: RecordType `OQF` (resolvido por DeveloperName, não por Id), Stage
   `Qualificação`, `Renova_o__c = true`, `AccountId` = `Account_ID__c` do HVR, `OwnerId` =
   usuário de Renovações (via Custom Label, ver seção 2), `CloseDate` = `Pr_ximo_Vencimento__c`,
   `Conversao_de_Lead__c` = `Não`, `Name` por padrão a definir (6.5).
3. Atualiza o HVR de origem gravando `Oportunidade_cadastrada_de_Renova_o__c` = Id da nova
   oportunidade. É isso que impede duplicidade: o registro sai do filtro de entrada no dia seguinte.
4. Fault path em cada elemento de DML: falha de um registro não derruba os demais; o erro
   segue pelo e-mail de erro de Flow já configurado na org (premissa P-6.7, a confirmar).

### Por que não o nível acima (configuração)
- A org não tem recurso nativo de renovação instalado: os pacotes presentes
  (`sf package installed list`) não incluem CPQ/Revenue Cloud nem nada que gere oportunidade de
  renovação. Não existe configuração pura (sem Flow) que crie registro em data agendada.
- Nenhum Flow ativo hoje cria Opportunity (recon, seção 2, e reconfirmado nesta sessão em
  `FlowDefinitionView`): não há automação existente para só "ligar".

### Por que não descer para código (Apex)
- Criar 1 oportunidade por registro de origem e gravar o vínculo de volta é exatamente o caso
  que Flow agendado resolve com bulkificação da plataforma (lotes de 200 entrevistas).
- O único cenário que justificaria Apex (Batch/Schedulable) é **agrupar vários ativos/HVRs em
  uma única oportunidade** por conta ou contrato, com regra de agrupamento não trivial — isso
  depende de 6.6. Se a resposta for "uma oportunidade por contrato", a saída preferida ainda é
  Flow, só que rodando sobre `Contract` em vez de HVR (ver 6.1). Apex fica reservado para
  agrupamento por conta com múltiplos contratos/ativos — e, se for esse o caso, o design volta
  para este gate.

## 2. Componentes

### Criar
| Tipo | API name proposto | Descrição |
|---|---|---|
| Flow (Schedule-Triggered) | `Hist_rico_de_Venda_e_Renova_o_Scheduled_CriaOportunidadeRenovacao` | Cria a Opportunity de renovação e grava o vínculo no HVR. Nome segue `<Objeto>_<Gatilho>_<Proposito>` (skill `padrao-entrega`; o CLAUDE.md do cliente não define convenção própria). Se a origem virar `Contract`: `Contract_Scheduled_CriaOportunidadeRenovacao`. |
| Custom Label | `Renovacao_OwnerId` | Id do usuário dono das renovações. Evita hardcode de Id de usuário dentro do Flow (reprovação automática no code review do `padrao-entrega`). Valor proposto: o mesmo usuário que a org já usa como dono de renovação (ver 6.4). |
| Custom Label | `Renovacao_DiasAntecedencia` | Número de dias de antecedência (6.2). Editável em Setup sem deploy de Flow. |

### Alterar
**Nada.** Nenhum Flow, validation rule, layout ou perfil existente é alterado nesta demanda.

### Depreciar
**Nada.**

### Existente e reaproveitado (confirmado na org)
- `Opportunity`: `Renova_o__c` (checkbox, label "Renovação base Agility?"), `Tipo_de_Renovacao__c`
  (default `Nenhuma`), `Status__c` (default `Aberto`), `Conversao_de_Lead__c` (picklist
  **obrigatória na criação**, valores `Sim`/`Não`), `N_Contrato_a_ser_Renovado_1__c` (→ Contract).
- RecordType `OQF` (ativo, business process `OQF`, que inclui o Stage `Qualificação`).
- `Hist_rico_de_Venda_e_Renova_o__c`: `Pr_ximo_Vencimento__c`, `Oportunidade_cadastrada_de_Renova_o__c`
  (lookup → Opportunity, label "Oportunidade ref. a Próxima Renovação"; lookup filter **inativo**),
  `E_o_mais_recente__c`, `Account_ID__c`, `Classe_de_renovacao__c`, `Tipo_do_Evento__c`.

**Mudança de modelo de dados: nenhuma, na premissa HVR ou Contract.** Se a resposta de 6.1
for "a partir do Asset" (`Vencimento_Subscri_o__c`), a Opportunity **não tem lookup para Asset**
(confirmado no describe: só há referências para Contract) e a checagem de duplicidade exigiria
campo novo ou passar pelo HVR. **Isso seria mudança de modelo de dados — decisão de arquitetura
sênior, escalada ao humano, não decidida aqui.**

## 3. Perguntas bloqueantes da análise (6.1–6.6) — tratamento de cada uma

| # | Pergunta | Tratamento | Base |
|---|---|---|---|
| **6.1** | Gatilho / objeto de origem | **BLOQUEIO para o build.** Há três candidatos reais na org, cada um muda o objeto do Flow: (a) `Hist_rico_de_Venda_e_Renova_o__c.Pr_ximo_Vencimento__c`; (b) `Asset.Vencimento_Subscri_o__c` — a org já tem Flows ativos de aviso de vencimento de subscrição a 90/30/15/0 dias sobre Asset; (c) data de fim de `Contract`. O design é escrito na premissa (a) porque é o único com campo de vínculo pronto para duplicidade. **O cliente precisa escolher.** | Recon §1; `FlowDefinitionView` (Flows `Subscri_o_*` em Asset); describe de Asset |
| 6.2 | Antecedência | **Premissa a validar:** valor parametrizável em `Renovacao_DiasAntecedencia`, valor inicial **90 dias** — escolhido por ser a maior janela que a org já usa nos avisos de vencimento de subscrição. Não bloqueia o build: é um número em label. | Flow `Subscri_o_vence_em_90_dias` (filtro `Vencimento_Subscri_o__c = Today()+90`) |
| **6.3** | Elegibilidade | **BLOQUEIO para o build.** Nada na org define quem entra. Candidatos para o cliente escolher (não assumidos): `Classe_de_renovacao__c` (ex.: excluir "Perda conhecida"), `Tipo_do_Evento__c`, `E_o_mais_recente__c = true` (este último entra no filtro de qualquer forma, para não gerar renovação de histórico antigo). | Describe do HVR |
| 6.4 | Owner | **Premissa forte, a validar:** usuário de Renovações, o mesmo Id já referenciado pela org em `Alteracao_do_Owner_se_Renovacoes`, `Atualiza_Owner_da_Oportunidade_se_Renovacoes_ou_Shirlei` e na fórmula `E_Renovacoes__c`. Usuário confirmado **ativo** em dev (`COUNT()` = 1). Vai para Custom Label, não hardcoded no Flow. | XML da VR, do Flow e do campo; query agregada em User |
| 6.5 | Estrutura do registro | **Premissa a validar:** RecordType `OQF` + Stage `Qualificação` (é a única combinação que passa por `M25_Oportunidade_criada_somente_em_OQF` qualquer que seja o usuário de execução do Flow); `CloseDate` = data de vencimento; `Conversao_de_Lead__c` = `Não`; `Tipo_de_Renovacao__c` = default `Nenhuma`; `Name` = padrão a definir com o cliente (proposta: `Renovação - <Conta> - <MM/AAAA do vencimento>`). Sem produtos/line items e sem `Amount` nesta demanda. | XML da VR M25; describe de Opportunity; business process `OQF` |
| 6.6 | Relação e duplicidade | **Premissa a validar:** 1 oportunidade por HVR elegível; "mesmo ciclo" = mesmo HVR; duplicidade bloqueada pelo `Oportunidade_cadastrada_de_Renova_o__c` preenchido. Se o cliente quiser **1 oportunidade por contrato ou por conta** agrupando vários ativos, o objeto de origem muda (6.1) e, no caso de agrupamento por conta, o design volta a este gate (possível Apex). | Campo de vínculo no HVR |

Escopo/validação (6.7–6.12) — premissas enxutas: **6.7** sem notificação nova na criação; erro
vai pelo e-mail de erro de Flow da org (confirmar destinatário configurado). **6.8** volume
desconhecido (sandbox vazia: HVR, Asset e renovações = 0); sem carga retroativa — o filtro
`= HOJE + N` só pega o que vence exatamente no dia-alvo, então o que já passou da janela não
é criado. **6.9** a automação substitui a criação manual, mas o time continua podendo criar à
mão (nada é bloqueado). **6.10** nenhuma integração externa identificada para o campo de
vencimento — não confirmado de onde o dado de `Pr_ximo_Vencimento__c` vem em produção.
**6.11/6.12** homologação em `sbx-somos-agility-qa` pelo departamento de Renovações; sem data-alvo informada.

## 4. Conflito de automação e ordem de execução

**RISCO DE ORDEM DE EXECUÇÃO: a inserção da nova Opportunity passa por um trigger gerenciado e
por vários Flows ativos de Opportunity (create/CreateAndUpdate), e o update do HVR dispara uma
cascata HVR → Asset.** Detalhe:

- **Trigger gerenciado `InserirOportunidade` (`snap_finan` / SnapERP), before insert, ativo, corpo
  oculto.** Roda em toda inserção de Opportunity. Comportamento desconhecido — pode exigir campo,
  falhar ou gravar algo. Só teste em sandbox revela.
- **Flows de Opportunity que vão disparar na criação** (filtro bate com o registro criado):
  `Atualiza_Owner_da_Oportunidade_se_Renova_es_ou_Shirlei_v2_1` (after save; como o Owner será o
  usuário de Renovações, `E_Renovacoes__c = Yes` e `Status__c = Aberto` → grava
  `Id_do_Owner_se_Renovacoes__c` e provoca um segundo save, que reavalia os Flows
  CreateAndUpdate). Esperado e inofensivo pela leitura do XML, mas **precisa de teste**.
- Flows de Opportunity que **não** devem disparar pelos filtros (sem Amount, sem orçamentista,
  Stage diferente de `Ação DIA`/`CVS/RVS`/`PSL`): `Email_Gerente`, `Alerta_de_cria_o_de_Oportunidade_Large_Accounts`,
  `Atualiza_a_oportunidade_mais_recente_da_Tamires_na_capa_do_contrato`,
  `Notifica_para_Realizacao_da_Cerimonia_2_dias`, `Atualiza_os_Campos_de_Emails_do_SE_GC_e_BDR`.
  Leitura de filtro, não teste — entram no roteiro de regressão.
- **Cascata no update do HVR:** gravar `Oportunidade_cadastrada_de_Renova_o__c` dispara os 4 Flows
  ativos de HVR (`Atualiza_oportunidade_no_HVR`, `Atualiza_ultimo_evento_do_ativo`,
  `Captura_a_conta_atrelada_ao_ativo_e_atualiza_no_historico_de_venda_e_renovacao`,
  `Verifica_qual_o_hist_rico_de_venda_e_renova_o_mais_recente`). **`Atualiza_ultimo_evento_do_ativo`
  atualiza o Asset, e os Flows `Subscri_o_Vence_em_30_dias` / `Subscri_o_vence_em_90_dias` são
  CreateAndUpdate em Asset — se a data do Asset bater com a janela no dia, um aviso de vencimento
  pode sair como efeito colateral.** O roteiro de teste precisa cobrir isso explicitamente.
- **Validation rule `Alteracao_do_Owner_se_Renovacoes` — correção ao recon:** a fórmula usa o valor
  **novo** do Owner (`ISCHANGED(OwnerId) && OwnerId = <usuário de Renovações> && Renova_o__c`), ou seja,
  ela barra a troca **para** o usuário de Renovações, não **a partir** dele, ao contrário do que a
  descrição dela diz. Ela **não dispara no insert** (`ISCHANGED` é falso na criação), então criar já
  com o Owner certo é seguro. Consequência de desenho: **o Flow novo nunca deve atualizar o Owner
  depois de criar** — só definir na criação. (Também no recon: o campo é `Renova_o__c`, não
  `Renova_o__c__c`.) A inconsistência entre a VR e o Flow `Atualiza_Owner_da_Oportunidade_se_Renovacoes_ou_Shirlei`
  é pré-existente e fica fora do escopo (seção 7).
- Há 3 versões ativas do Flow de owner (`..._Shirlei`, `..._v2_1`, `..._v2_3` em Account). Não são
  tocadas; entram na regressão.

## 5. Limites de governador e escala

- Flow agendado processa em lotes de 200 entrevistas, com Create/Update bulkificados pela
  plataforma. **Nenhum Get Records dentro de loop** — o RecordType `OQF` é buscado uma vez por
  entrevista via Get Records simples (fora de loop; a plataforma consolida em lote) ou por fórmula
  de DeveloperName.
- Cada lote de 200 dispara, por oportunidade criada, o trigger gerenciado + os Flows de
  Opportunity + segundo save do `_v2_1` + update do HVR com 4 Flows + update de Asset. **Esse
  efeito multiplicador é o ponto de atenção para CPU/SOQL por transação**, não o Flow novo em si.
  Volume real é desconhecido (6.8); o teste em qa deve incluir um lote de pelo menos 200 HVRs
  elegíveis no mesmo dia.
- Limite de entrevistas agendadas por 24h (o maior entre 250.000 e 200 × licenças) não é risco
  plausível para volume de renovação diário.
- Filtro `= HOJE + N` (igualdade, não `<=`) evita reprocessar e evita carga retroativa acidental;
  o contraponto é que um dia sem execução (falha do job) perde aquele dia — mitigação: a falha é
  visível no e-mail de erro e o registro pode ser criado manualmente; se o cliente quiser
  tolerância, troca-se por `<=` mantendo a trava de vínculo vazio (decidir no build, sem impacto
  de arquitetura).

## 6. Impacto em permissões

- **Nenhum perfil ou permission set alterado.** Flow agendado roda em contexto de sistema; não há
  campo novo, então não há FLS a conceder.
- `M25_Oportunidade_criada_somente_em_OQF` avalia `$Profile.Name` do usuário de execução do Flow
  agendado, que não é um dos 3 perfis de exceção. Por isso o design cria em `OQF` + `Qualificação`,
  combinação que passa para qualquer perfil. **Confirmar em qa qual usuário de execução a org usa
  para Flows agendados** (o desenho não depende disso, mas o teste deve registrar).
- Visibilidade: a oportunidade nasce com Owner = usuário de Renovações; quem já vê as renovações
  hoje continua vendo, pelas regras de compartilhamento existentes (não alteradas).

## 7. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | Trigger gerenciado `InserirOportunidade` (SnapERP) com corpo oculto falha ou exige campo na inserção automática | **Alta** | Teste em dev antes de qualquer outra coisa (smoke de 1 registro); se falhar, parar e escalar — não há como contornar pacote gerenciado sem o fornecedor |
| R2 | Cascata HVR → Asset dispara aviso de vencimento de subscrição indevido | **Média** | Cenário explícito no roteiro de teste; se ocorrer, avaliar com o humano (fora do escopo mexer nos Flows de Asset sem decisão) |
| R3 | Gatilho/objeto de origem diferente da premissa (6.1) | **Alta** (para o plano) | Bloqueio declarado; build não arranca sem resposta |
| R4 | Origem = Asset exige campo novo (modelo de dados) | **Alta** | Escalado ao arquiteto humano; não decidido aqui |
| R5 | Owner definido em label diverge entre sandbox e produção | Baixa | Usuário já existe e está ativo em dev; release confere o valor da label em qa |
| R6 | CPU/SOQL por transação com lote de 200 por causa do efeito multiplicador | Média | Teste de lote de 200 em qa; se estourar, reduzir batch size do Flow agendado |
| R7 | Dia sem execução do job perde as renovações daquele dia (filtro de igualdade) | Baixa | Ver seção 5 |
| R8 | Inconsistência pré-existente entre `Alteracao_do_Owner_se_Renovacoes` e o Flow de owner original (reverter owner esbarra na VR) | Baixa (não causada por esta demanda) | Registrar, não corrigir; o Flow novo não atualiza Owner |

## 8. O que NÃO será feito nesta demanda

- Carga retroativa de renovações já vencidas ou dentro da janela.
- Produtos/line items, `Amount` ou cálculo de valor da renovação.
- Notificação nova (e-mail, Chatter, tarefa, uso de `Aviso_de_Renovacao__c`, que hoje está sem campos).
- Agrupamento de vários ativos/contratos numa oportunidade por conta.
- Qualquer alteração nos Flows de owner, nos Flows de HVR/Asset, nas validation rules existentes
  ou na correção da inconsistência R8.
- Tratamento de "a condição deixou de valer" (cancelamento/encerramento de contrato depois de
  criada a oportunidade) — o Flow `Notifica_se_Oportunidade_de_Renovacao_tem_Contrato_Encerrado`
  já cobre parte disso e não é alterado.
- Qualquer coisa em produção (guardrail #1).

## 9. Confirmações feitas nesta sessão (além do recon)

Todas contra `sbx-somos-agility-dev`, só metadata e `COUNT()`:
`FlowDefinitionView` dos Flows ativos em Opportunity/Asset/HVR/Account; XML local dos Flows de owner,
das VRs M25 e `Alteracao_do_Owner_se_Renovacoes`, do campo `E_Renovacoes__c`, do lookup
`Oportunidade_cadastrada_de_Renova_o__c` e do business process `OQF`; `sf sobject describe` de
Opportunity (Stages, campos obrigatórios na criação, RecordTypes, referências), Asset e HVR;
Tooling `ApexTrigger` em Opportunity/Asset/Contract/HVR (só o `InserirOportunidade`, before insert);
`sf package installed list`; `COUNT()` em User (usuário de Renovações ativo) e Asset (0).

## 10. Estimativa refinada

**Estimativa de esforço:** 14–26 h

O que mudou em relação à análise (10–28 h; estimativa oficial aprovada pelo cliente: 19 h, que
continua dentro da faixa):
- **Piso subiu (10 → 14 h):** a org tem mais automação no caminho do que a análise supunha —
  trigger gerenciado de corpo oculto no insert, ~15 Flows de Opportunity CreateAndUpdate, cascata
  HVR → Asset com avisos de vencimento. O teste de regressão e o smoke do trigger não são opcionais.
- **Teto caiu (28 → 26 h):** a estrutura de dados já existe (flag de renovação, RecordType/Stage
  compatíveis com a VR, usuário dono de renovação, campo de vínculo no HVR para duplicidade). Não há
  campo novo, nem perfil/permission set, nem Apex na premissa HVR/Contract.
- Distribuição aproximada: Flow + labels 4–6 h; testes em dev (smoke do trigger, lote, duplicidade,
  cascata) 4–8 h; homologação em qa com Renovações 3–6 h; documentação e alinhamento das premissas
  3–6 h.
- **Fora da faixa:** se 6.1 = Asset (campo novo, escalado) soma ~4–6 h; se 6.6 = agrupamento por
  conta (Apex Batch + classe de teste ≥ 85%) soma ~10–16 h e o design volta a este gate; carga
  retroativa é demanda à parte.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
