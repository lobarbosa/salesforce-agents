# Design — SOMOSAGILITY-3
Alteração de Status de Oportunidade para Aberta (Urgente) — **sustentação, design enxuto**

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, `Organization.IsSandbox = true`,
API v67.0) — confirmado via `sf org list` / `sf org display` em 2026-10-07.
**Insumos:** `01-analise.md` (aprovado no gate de análise por Carlos Sordi, 2026-10-07), `02-recon.md`,
e verificações complementares feitas nesta etapa (seção 2). Só metadata e contagens; nenhum dado de
registro foi consultado (guardrail #2).

---

## 1. Decisão

**Não construir nada. Nenhum deploy de metadata.** A demanda é uma **correção pontual de dado em um
único registro de produção** (`006U400000YnxGHIAZ`), e deve ser executada **por um humano autorizado
do cliente, via UI do Salesforce, em produção**, alterando:

| Campo | De | Para |
|---|---|---|
| `Opportunity.Status__c` (label "Status") | `Encerrado Win` | **`Aberto`** (não "Aberta" — ver risco R2) |

`StageName` (label "Fase") **não é alterado** por esta demanda, salvo confirmação explícita em
contrário (pergunta P1).

A execução é **condicionada** às respostas das perguntas P1–P3 (seção 6). A pergunta P2 (financeiro/ERP)
é bloqueante para a execução, não para a aprovação deste design.

### Por que não subir de nível (ordem configuração → declarativo → código)

A opção mais alta da escada já resolve: **configuração/operação na UI**, sem metadata nova.

- **Não é configuração de metadata:** nada na org impede a edição hoje. `Status__c` já é editável
  (FLS de edição confirmada para os perfis `Administrador do sistema`, `Admin`, `Administração`,
  `Administração para Alta Gestão`, `adminPMO`, `Compras Financeiro`, `Diretor Financeiro`,
  `Grupo Operações` e os permission sets `PMO acessa OPT`, `Projeto-DSA-Oportunidade`); o valor
  `Aberto` está disponível em **todos** os Record Types, inclusive `Encerrada`; nenhuma validation
  rule ativa referencia `Status__c` (seção 2). Não há o que configurar.
- **Não é Flow / Screen Flow / Quick Action:** a análise não apontou recorrência — é um registro, citado
  pelo Id. Criar uma ação de "reabrir oportunidade" seria transformar um incidente em capacidade
  permanente, num objeto que já tem **31 Flows ativos e 26 validation rules ativas** (a maior
  concentração da org, achado do assessment). Cada automação a mais em Opportunity aumenta o risco de
  ordem de execução para todas as outras. Se a reabertura for recorrente, isso é outra demanda (seção 5).
- **Não é Apex / script de dados / Data Loader pelo agente:** o registro só existe em **produção**.
  Guardrail #1 proíbe qualquer DML de agente em produção, e a esteira (dev/qa) não tem o registro —
  a sandbox de dev tem `COUNT() = 0` em Opportunity. Não existe build nem teste que o agente possa
  fazer que toque o objeto real.
- **Por que UI e não Data Loader pelo humano:** um registro, um campo. A UI respeita as mesmas
  validation rules e dispara as mesmas automações que o Data Loader, mas dá ao executor a mensagem de
  erro em tela e o contexto visual do registro (Record Type, Fase, valores de certeza) antes de salvar.

### Consequência para o fluxo da demanda

Como não há metadata, as etapas seguintes encolhem:

- **Etapa 4 (build):** não há build. `04-plano-build.md` deve ser apenas o **runbook** de execução
  manual (seção 4 abaixo, detalhado), sem branch de código em `force-app/`.
- **Etapa 5 (qa):** não há o que testar em sandbox — QA vira **conferência pós-execução** feita pelo
  humano em produção, com o checklist da seção 4. O agente `qa` não tem como verificar (produção).
- **Etapa 7 (doc):** registra quem executou, quando, e o que foi observado no checklist.

---

## 2. O que foi verificado nesta etapa (além do `02-recon.md`)

A recon deixou como "não pôde ser medido" o conteúdo das 31 automações e 23 das 26 validation rules.
Como isso é decisivo para afirmar "edição manual não é bloqueada nem revertida", fiz um retrieve
**read-only** em diretório temporário (descartado ao final; nada commitado):

### 2.1 Validation rules
Retrieve de `CustomObject:Opportunity` → 110 validation rules no objeto. **Nenhuma ativa referencia
`Status__c`, `IsClosed` ou `IsWon`.** A edição só de `Status__c` não é bloqueada por VR para nenhum
perfil. Confirma e amplia a conclusão da recon (que tinha lido 3 de 26).

### 2.2 Apex trigger
Um único trigger ativo em Opportunity: `InserirOportunidade` — **gerenciado** (namespace `snap_finan`,
pacote SnapERP), evento **somente `before insert`**. Não roda em update; não afeta esta demanda.
(A recon não havia listado triggers.)

### 2.3 Flows — a recon subestimou o envolvimento de `Status__c`
A recon dizia que nenhum Flow tinha *nome* sugerindo uso de `Status__c`. Lendo o XML dos 31 Flows
ativos de Opportunity: **10 referenciam `Status__c`**, todos como **critério de entrada / condição**.
**Nenhum Flow atribui valor a `Status__c`** — portanto nenhum reverte a mudança. Mas a mudança
para `Aberto` **dispara ou deixa de disparar** automações:

| Flow (API name) | Gatilho | Uso de `Status__c` | Efeito ao reabrir para `Aberto` |
|---|---|---|---|
| `Atualiza_Owner_da_Oportunidade_se_Renova_es_ou_Shirlei_v2_1` | After save, create/update, **sem** "só quando mudar" | `= Aberto` e `E_Renovacoes__c = Yes` | Se o registro for de renovações, grava `Id_do_Owner_se_Renovacoes__c = OwnerId`. Benigno, mas é escrita colateral. |
| `Preenche_OT_anterior` | After save | `= Aberto` e `Rentabilidade_prevista__c` mudou | Não dispara (rentabilidade não muda nesta edição). Volta a valer em edições futuras. |
| `Atualiza_Data_de_Alteracao_para_CVS_RVS` / `..._para_PSL` | After save, só quando passa a atender | `= Aberto` e `StageName` = CVS/RVS ou PSL | Dispara só se a Fase atual do registro for CVS/RVS ou PSL (desconhecida — produção). |
| `Atualiza_os_Campos_de_Emails_do_SE_GC_e_BDR` | After save | `= Aberto` e `StageName = Ação DIA` | Idem — depende da Fase atual. |
| `Preenche_Certezas` | **Before save** | `= Encerrado Win` | Quando fechou, gravou `Certeza_de_Conclus_o__c = 100`, `Certeza_de_Vit_ria__c = 100` e `Fechado__c = true`. **Reabrir não desfaz isso** (ver R4). |
| `Oportunidade_Encerrada` | After save, só quando passa a atender | `IN (Encerrado Loss, Encerrado Win, Encerrado Win - Processada Financeiro)` | Não dispara ao reabrir. **Dispara de novo** (e-mail a Sales Operation) quando o registro for reencerrado. Esperado. |
| `Notifica_altera_o_do_meu_compromisso_de_fechamento` | After save, só quando passa a atender | Fórmula com `ISPICKVAL(Status__c,'Encerrado Win')` | Envia e-mail em condições ligadas a `Encerrado Win`; ao sair de Win, não dispara. |
| `Deleta_proximos_passos_relacionados_a_uma_oportunidade_excluida` | Before delete | `<>` valores de encerramento | Irrelevante (não há exclusão). |
| `Notifica_se_Oportunidade_de_Renovacao_tem_Contrato_Encerrado` | Scheduled | `= Encerrado Loss` | Irrelevante. |

**Conflito de automação:** **não há automação nova sendo adicionada, então não há risco novo de ordem
de execução introduzido por esta demanda.** O risco que existe é o dos efeitos colaterais da tabela
acima, que acontecem com qualquer edição manual — e estão mapeados.

Nota de incerteza: `Fechado__c` é gravado por `Preenche_Certezas`, mas **não aparece no describe de
Opportunity para o usuário de integração da sandbox** (provável falta de FLS para esse usuário). Não
confirmei o campo além da referência no XML do Flow.

### 2.4 Não medido
- Código do pacote gerenciado SnapERP (`snap_finan`) — oculto por ser managed. Não há como saber,
  por metadata, se ele lê `Status__c` ou reage à reabertura. Isso reforça P2.
- Qualquer valor do registro real (Fase, Record Type, se é renovação, se já foi processado no
  financeiro) — está em produção.

---

## 3. Componentes

| Ação | Componentes |
|---|---|
| Criar | **Nenhum** |
| Alterar (metadata) | **Nenhum** |
| Depreciar | **Nenhum** |
| Alterar (dado, por humano em produção) | `Opportunity.Status__c` do registro `006U400000YnxGHIAZ`: `Encerrado Win` → `Aberto` |

**Modelo de dados:** não há mudança. Nada a escalar como decisão de arquitetura sênior.

## 4. Runbook de execução (vira o `04-plano-build.md`)

Executor: usuário do cliente com perfil que tenha edição em `Status__c` (lista na seção 1).
Preferência: perfil `Administração` — além da FLS, ele é isento de `M21_Fase_Encerrada` caso P1 conclua
que a Fase também precisa mudar.

1. **Antes de editar**, anotar (no ticket do cliente, não no repositório — guardrail #2) os valores
   atuais de: `Status__c`, `StageName`, Record Type, `Certeza_de_Conclus_o__c`,
   `Certeza_de_Vit_ria__c`, `CloseDate`. **Importante:** `Status__c` tem `trackHistory = false` —
   a plataforma **não** guarda histórico dessa mudança. A anotação manual é o único rastro.
2. Confirmar que o valor atual é `Encerrado Win` e **não** `Encerrado Win - Processada Financeiro`.
   Se for o segundo, **parar** e devolver para P2.
3. Editar `Status__c` para `Aberto`. Não alterar nenhum outro campo na mesma edição.
4. Salvar. Se der erro de validação, **não contornar**: registrar a mensagem e devolver ao arquiteto
   (a análise de VR diz que não deveria ocorrer).
5. Conferência pós-execução (substitui a etapa de QA):
   - `Status__c = Aberto` persistiu após recarregar a página (nenhuma automação reverteu).
   - `StageName` e `CloseDate` não mudaram.
   - Avaliar com o solicitante se `Certeza_de_Conclus_o__c` / `Certeza_de_Vit_ria__c` (que ficaram em
     100) devem ser ajustadas — decisão de negócio, não do agente (R4).

## 5. Impacto em permissões

**Nenhum.** Nenhum perfil ou permission set é criado ou alterado. Não se deve conceder FLS de edição de
`Status__c` a ninguém novo para esta demanda — se o solicitante não tem acesso, quem executa é um usuário
que já tem.

## 6. Perguntas em aberto (condicionam a execução, não o design)

- **P1 — Qual campo?** O vocabulário da demanda bate com `Status__c`. Confirmar com o solicitante que a
  Fase (`StageName`) não precisa voltar a um estágio aberto. Se precisar, `IsClosed/IsWon` mudam,
  `M21_Fase_Encerrada`, `M36_Trava_avanco_nao_sequencial` e `M49_NaoAtualizaOppPsl` entram em jogo e
  vários Flows de fase disparam — **esse caso volta ao arquiteto para revisão do design** antes da execução.
- **P2 — O financeiro/ERP já processou?** (bloqueante para executar) Confirmar com o financeiro do
  cliente se o fechamento desta oportunidade já gerou algo no SnapERP/ERP (pedido, faturamento, contrato).
  Se sim, reabrir só no Salesforce cria divergência Salesforce × ERP; a reversão do lado financeiro é
  responsabilidade do cliente e tem que ser combinada antes.
- **P3 — Por que reabrir?** Erro de digitação (fechou por engano) ou negócio voltou à negociação? Se for
  padrão recorrente, abrir **demanda nova** para desenhar um processo de reabertura (aí sim avaliar
  Screen Flow / Quick Action com permission set dedicado) — não nesta.

## 7. Riscos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | Reabrir uma oportunidade já processada pelo financeiro/ERP gera divergência entre Salesforce e ERP (pacote SnapERP com código oculto) | **Alta** | P2 bloqueante; passo 2 do runbook para se o valor for `Encerrado Win - Processada Financeiro`. |
| R2 | Usar o valor "Aberta" (do texto da demanda) em vez de `Aberto` | Baixa | Picklist restrito rejeita "Aberta" na hora; runbook cita o valor exato. |
| R3 | Sem histórico de campo (`trackHistory = false` em `Status__c`) — mudança sem rastro na plataforma | Média | Anotação antes/depois no ticket do cliente (runbook passo 1) e registro em `06-entrega`/doc. |
| R4 | `Preenche_Certezas` deixou `Certeza_de_Conclus_o__c`/`Certeza_de_Vit_ria__c` = 100 e `Fechado__c = true`; reabrir não desfaz → relatórios de pipeline/forecast podem tratar a oportunidade como certa/fechada | Média | Decisão de negócio no passo 5; não automatizar a reversão nesta demanda. |
| R5 | Efeitos colaterais de Flows ao salvar (`Id_do_Owner_se_Renovacoes__c` gravado se for renovação; Flows de data/e-mail se a Fase for CVS/RVS, PSL ou Ação DIA) | Baixa | Mapeados na seção 2.3; benignos; nenhum reverte o status. |
| R6 | Reencerrar depois dispara de novo o e-mail de `Oportunidade_Encerrada` para Sales Operation | Baixa | Comportamento esperado; avisar o solicitante. |
| R7 | Se P1 indicar mudança de `StageName`, o design atual não cobre | Média | Volta ao arquiteto (seção 6). |
| R8 | Pressão de urgência levar alguém a pedir que o agente execute em produção | Alta (de processo) | Guardrail #1: agente nunca executa. Execução é sempre do humano do cliente. |

## 8. O que NÃO será feito nesta demanda

- Nenhum deploy de metadata, em nenhum ambiente (sem Flow, Quick Action, Apex, VR, permission set).
- Nenhuma alteração em produção pelo agente — nem DML, nem anonymous Apex, nem Data Loader (guardrail #1).
- Nenhuma alteração de `StageName`, `CloseDate`, Record Type ou campos de certeza (salvo nova decisão via P1/R4).
- Nenhuma reversão do lado financeiro/ERP (SnapERP) — responsabilidade do cliente.
- Nenhum processo reutilizável de "reabrir oportunidade" — se for recorrente, nova demanda (P3).
- Nenhuma correção da `M21_Fase_Encerrada` (que checa a Fase `"Encerrada"`, hoje ausente dos valores
  ativos de `StageName`) nem consolidação das 31 automações de Opportunity — dívida técnica real,
  registrada no assessment, fora do escopo.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
