**Resultado do build:** concluído

# EPLAST-35 — Plano de build (rodada 3: distribuição de Leads sem Apex)

**Org conectada:** `sbx-eplast-dev` (alias; usuário de conexão omitido, Sandbox, Connected; é a `eplast--qa` da Eplast, DEV da esteira pela regra 5). Única org em `sf org list`. Nada tocado em QA, QAS, produção ou Marketing Cloud.
**Branch:** `feature/EPLAST-35`. **Commit do build:** `47fe6348`. **Design seguido:** `03-design.md` (aceite do gate de 17/11 em `gates.md`), seções 1, 2, 3, 5, 13 e 15.
**Deploy:** `--dry-run` aprovado e depois deploy real, ambos com sucesso (Deploy ID do real: `0AfHa00000EJO09KAH`). Os 14 componentes foram na mesma implantação.

## 1. O que foi construído

| # | Componente | Caminho | Observação |
|---|---|---|---|
| 1 | Campo `Lead.DIST_SequenciaRodizio__c` (Auto Number `{0}`, início 1) | `force-app/main/default/objects/Lead/fields/DIST_SequenciaRodizio__c.field-meta.xml` | Com descrição. Fora de layout, sem permissão de campo dada |
| 2 | CMDT `DistribuicaoLeadSetting__mdt` | `.../objects/DistribuicaoLeadSetting__mdt/` | Objeto com descrição. Campos `DistribuicaoAtiva__c`, `RodizioAtivo__c`, `RespeitarDonoConta__c` (checkbox), `PrefixoFilas__c` (texto 40), `FilasSemRodizio__c` (texto 255), todos com descrição |
| 3 | Registro `DistribuicaoLeadSetting.Padrao` | `.../customMetadata/DistribuicaoLeadSetting.Padrao.md-meta.xml` | `DistribuicaoAtiva__c = false`, `RodizioAtivo__c = true`, `RespeitarDonoConta__c = true`, `Leads_`, `Leads_Triagem` (conferido na org por query) |
| 4 | Fila `Leads_RJ_ES` (rótulo "Leads RJ/ES", Lead, sem membros, sem e-mail aos membros) | `.../queues/Leads_RJ_ES.queue-meta.xml` | O tipo `Queue` não tem campo de descrição na API; a descrição do design não tem onde entrar |
| 5 | Regra `Distribuicao_Regional_Leads_v2`, **inativa**, 7 entradas da seção 2.1 do design | `.../assignmentRules/Lead.assignmentRules-meta.xml` | A v1 ficou como estava na org (conferi por retrieve: arquivo idêntico) e continua ativa. Sem template de e-mail |
| 6 | Flow `Lead_AfterSave_DistribuiDonoRodizio` (Active, versão 1) | `.../flows/Lead_AfterSave_DistribuiDonoRodizio.flow-meta.xml` | Detalhe na seção 2 |
| 7 | Script de dado de teste | `fixtures/lead_rodizio_dono_conta.apex` | **Não executado.** Ver seção 5 |

### 1.1 Flow, o que ele faz (conforme a seção 2.2 do design)
- After save, Lead, criação e atualização, entrada `OR(ISNEW(), ISCHANGED({!$Record.OwnerId}))`, `triggerOrder` 500.
- Sequência: Get `DistribuicaoLeadSetting__mdt` `Padrao` (sai se não achar ou se `DistribuicaoAtiva__c` for falso) → releitura do Lead (sai se convertido ou se o dono não for `00G`) → Get `Group` tipo Queue (sai se `DeveloperName` não começa por `PrefixoFilas__c`).
- Dono da conta, se `RespeitarDonoConta__c` e CNPJ preenchido: fórmulas `fxCnpjDigitos` e `fxCnpjMascara`, Get `Account` com `CompanyDocument__c` igual a uma das duas formas, contagem com `AssignCount`, e só com **exatamente 1** conta lê o dono em `User` (ativo, `UserType = Standard`). Valendo, vai ao Update. Qualquer outro caso cai no rodízio.
- Rodízio, se `RodizioAtivo__c`, fila fora de `FilasSemRodizio__c` e `DIST_SequenciaRodizio__c` preenchido: Get `GroupMember` (`UserOrGroupId` começando por `005`, ordem por `UserOrGroupId`) → loop montando coleção de Ids → Get `User` com `Id In`, ativo e Standard, ordem por Id → `k` = contagem → `fxIdx = MOD(VALUE(DIST_SequenciaRodizio__c), k)` → loop com contador até a posição `idx`.
- Update Records filtrado por `Id = $Record.Id`, só `OwnerId`. Caminho de falha em **todo** Get e no Update, terminando em atribuição sem ação (`Fim_Falha`), então o salvamento não é desfeito (PA-32).
- Fórmula do índice: `MOD(n, k)` (padrão do design, seção 1.5; **não houve escolha diferente registrada no gate**). A alternativa de Weyl é a troca da fórmula `fxIdx`.
- Nenhuma classe Apex criada nem chamada.

## 2. Versões e ativação

| Item | Entrou | Estado agora na DEV | Passo de ativação (separado, **não feito**) | Desfazer |
|---|---|---|---|---|
| Regra de Lead | `Distribuicao_Regional_Leads_v2` | **Inativa** (conferido por retrieve: v1 `active=true`, v2 `active=false`) | Setup > Regras de atribuição de Lead: ativar a v2. Na QAS, só pela condição PA-30 (depois da homologação da EPLAST-38) | Reativar a v1 |
| Flow | `Lead_AfterSave_DistribuiDonoRodizio` v1 | Active (conferido por Tooling), inerte | Nasce ativo; só age com o interruptor ligado | Desativar o Flow ou desligar o interruptor |
| Interruptor | `DistribuicaoLeadSetting.Padrao.DistribuicaoAtiva__c` | `false` (conferido por query) | Setup > Custom Metadata > Configuração de distribuição de Leads > Padrao: marcar. **Primeiro a v2, depois o interruptor** | Desmarcar |
| Flow antigo | `Lead_AfterInsert_AplicaRegraAtribuicao` v1 | Ativo, **sem alteração**, sem versão nova | — | — |

O design (seção 13, passo 8) prevê a ativação na DEV para a verificação, mas a instrução desta sessão foi não ativar nada. Fica para o verificador (ou quem a esteira indicar) executar os dois passos na ordem acima na DEV e registrar.

## 3. O que ficou de fora e por quê
- **Rebase sobre a `main`:** não feito. A árvore de trabalho tem mudanças da esteira não commitadas (`00-preflight.md`, `gates.md`, `status.yaml`, `scripts/`). A `main` está 41 commits à frente, mas só traz `fixtures/` novas (README e scripts) e arquivos da esteira. **O pacote da EPLAST-38 não está na `main`** (nenhum commit citando a demanda, nenhuma diferença em `assignmentRules` ou `queues`). Como o arquivo de regras foi refeito a partir do retrieve da org (idêntico ao do branch), não há perda. O rebase fica para antes do PR; o `fixtures/README.md` da `main` não lista o script novo, e quem rebasear deve acrescentar a linha.
- **Ativação da v2 e do interruptor:** ver seção 2.
- **Aprovação, encaminhamento interno, mudança de `Leads_RJ`/`Leads_ES`, membros de filas, perfis e permission sets:** fora do escopo do design (seções 3 e 8). Nada disso foi tocado.
- **Descrição na fila:** limitação da API (item 4 da seção 1).
- Nada feito no Marketing Cloud. O Flow não grava nada que o Marketing Cloud leia e não dispara e-mail. A preparação do lado CRM (seção 7 do design) não exigiu componente novo neste build.

## 4. Como o verificador deve testar
Casos T1 a T18 da seção 12 do `03-design.md` (T6b é só da QAS). Componentes e nomes exatos:
- Flow `Lead_AfterSave_DistribuiDonoRodizio`; campo `Lead.DIST_SequenciaRodizio__c`; CMDT `DistribuicaoLeadSetting__mdt.Padrao`; fila `Leads_RJ_ES`; regra `Distribuicao_Regional_Leads_v2`.
- **Antes de T1:** ativar a v2 e depois marcar `DistribuicaoAtiva__c` (seção 2). Pôr membros diretos nas filas de teste (`Leads_MG`, `Leads_SP`, `Leads_RJ_ES`). O usuário de teste é a conta de serviço da Konecta (resolver o Id na org pela query da regra 6; citar só `005…`).
- Medir SOQL, DML e CPU do lote de 200 (T3 e T3b) e registrar; acima de 70% de qualquer limite, volta ao design (seção 4 do design traz a saída declarativa).
- T13 prova o interruptor: com `DistribuicaoAtiva__c = false`, nada acontece.
- T16 e T17 provam isolamento e versões: `COUNT()` agregado de Account, Opportunity e Order, `AsyncApexJob` agregado, e que os 3 `ApprovalProcess`, `LeadAssignmentService` e o Flow antigo não mudaram.
- Script `fixtures/lead_rodizio_dono_conta.apex`, `acao` = `preparar`, `leads` ou `limpar`. Rodar com `sf apex run --target-org sbx-eplast-dev`. Se a org recusar algum campo obrigatório, o verificador corrige o script e o registra no `fixtures/README.md`.

## 5. O que não foi confirmado
Só a execução prova; nada abaixo foi exercitado nesta sessão (não houve teste funcional, só deploy):
1. **Comportamento em runtime** do Flow: se a releitura vê o dono gravado pela regra no mesmo salvamento (R1), a contagem de SOQL e a CPU em lote de 200, e se `AssignCount` sobre coleção vazia devolve 0 e o `Get` com `In` de coleção funciona como esperado.
2. **Update de dono pelo Flow não reaplica a regra de atribuição** (PA-29): é a expectativa do design; o verificador confere pelo resultado de T1 (se a regra reaplicasse, o Lead voltaria à fila).
3. **`triggerOrder`:** é elemento do nível do Flow (a plataforma recusa dentro de `start`); gravado como 500. O design diz que a correção não depende dele.
4. **Script de fixture:** não executado. Os campos obrigatórios da conta foram copiados da fixture da EPLAST-36 (provada) e a seleção de um segundo usuário usa `Profile.Name LIKE 'Comercial%'`, que não foi conferida na org.
5. **Flows de pacote em Lead** não foram inspecionados (R10 do design).
6. **Rebase sobre a `main`**: pendente (seção 3).
7. O Id do usuário de teste não foi resolvido nesta sessão (não foi preciso para o build).

## Correções da verificação 1

**Org:** `sbx-eplast-dev` (única conectada em `sf org list`). Nada tocado em QA, QAS, produção ou Marketing Cloud.

| Falha | Correção | Estado |
|---|---|---|
| FALHA 1: `Get_Membros` cai no caminho de falha, Lead fica na fila | Removido o filtro `UserOrGroupId StartsWith '005'` do `Get_Membros` (a plataforma recusa operador de texto em campo Id). O Get agora filtra só por `GroupId`. Id de grupo na coleção é descartado em `Get_Elegiveis`, cujo `Id In` só casa com usuário (ativo e Standard). Ordem, `k`, `MOD` e o restante do Flow não mudaram. | Corrigido no XML; deploy real com sucesso (Deploy ID `0AfHa00000EJJXhKAP`, antes `--dry-run` aprovado) |

### Versões e ativação (desta correção)
- A correção entrou como **versão nova** do Flow `Lead_AfterSave_DistribuiDonoRodizio`: **v2 em Draft**. A v1 (com defeito) continua Active e não foi editada (conferido por Tooling: v1 Active, v2 Draft).
- **Passo de ativação, separado e não feito:** ativar a v2 na DEV antes de repetir T1 a T18 (a ativação da v2 desativa a v1). Estado do interruptor `DistribuicaoAtiva__c` e da regra v2: como o verificador os deixou (regra v2 ativa e interruptor false, segundo a verificação 1). Desfazer: reativar a v1.
- Coexistência com EPLAST-38: nenhum componente dela foi tocado nesta correção.

### Pontos a observar no reteste (não provados por este build)
- A fixa `Get_Membros` ordena por `UserOrGroupId` (campo Id); o erro da verificação foi no filtro, não na ordenação, mas só a execução confirma. Se falhar, ordenar só em `Get_Elegiveis` (já ordena por `Id`) basta, pois a posição usa essa lista.
- Medição de CPU do lote de 200 pelo caminho completo (limite 70% = 7.000 ms) segue pendente; a da verificação 1 não vale (só caminho de falha).
- T3b, T7, T8, T9, T11, T14, T15, T18 e `RodizioAtivo=false` seguem sem prova até o reteste.

## Correções da rodada 1

**Org:** `sbx-eplast-dev` (única conectada em `sf org list`). Nada tocado em QA, QAS, produção ou Marketing Cloud. Nenhum metadata alterado nesta sessão: não há falha de construção a corrigir.

| Falha | Correção | Estado |
|---|---|---|
| FALHA 1 (crítica): cadeia inalcançável na QAS (Flow em Draft, regra v2 inativa, interruptor `false`, `Leads_RJ_ES` sem membros) | **Não corrigível no build.** O QA confirmou que o pacote chegou como o design manda (C0, C4, C5 aprovados). O que falta é estado de Setup, não metadata: ativar o Flow, ativar a regra v2, ligar `DistribuicaoAtiva__c` e pôr membros em `Leads_RJ_ES`. Ligar v2 e interruptor na QAS depende da condição PA-30 do design (seção 11): homologação da EPLAST-38 fechada, ou aceite do responsável para homologar as duas juntas. Esse aceite não existe nos artefatos, e o builder não decide nem ativa. | Devolvido ao gate com a decisão abaixo |

### Correção de uma afirmação deste plano
A seção 2 diz que o Flow "nasce ativo". O XML do pacote tem `<status>Draft</status>` (linha 791), por doutrina (versão nova nunca nasce ativa; ativação é passo separado), e foi assim que chegou à QAS (v1 Draft, confirmado pelo QA). O design (seção 5, PA-30) previa "Flow ativo e inerte"; isso exige uma ativação em Setup, não vem do deploy. Não mudei o status no XML: um deploy com `Active` na DEV desativaria a v1 e ativaria o Flow sem passo separado, contra a regra desta etapa.

### Decisão que o responsável precisa tomar (PA-30)
- Opção (a): aceitar a ativação conjunta com a EPLAST-38. Depois do aceite, quem opera a QAS executa, nesta ordem: ativar o Flow `Lead_AfterSave_DistribuiDonoRodizio`; ativar `Distribuicao_Regional_Leads_v2`; marcar `DistribuicaoAtiva__c` no CMDT `Padrao`; pôr pelo menos 2 membros de teste em `Leads_RJ_ES` (usuários ativos e do tipo Standard). Desfazer: desmarcar o interruptor e reativar a v1 da regra.
- Opção (b): fechar antes a homologação da 38 e reenviar a 35.
- Sem uma das duas, o QA seguirá sem poder exercitar T1 a T18.

### Ainda sem prova em runtime
O rodízio nunca rodou com sucesso em nenhuma org (verificação 1 reprovou; o reteste na DEV ficou inconclusivo por Flow em Draft). A correção do `Get_Membros` (seção "Correções da verificação 1") segue sem confirmação. T17 (3 processos de aprovação sem mudança) ficou inconclusivo no QA porque `ProcessDefinition` não é consultável por `sf data query`; o verificador pode conferir por Tooling ou retrieve de `approvalProcesses`.

## Correções da rodada 1 (ajuste de metadata pela decisão do responsável, 2026-11-17)

**Org:** `sbx-eplast-dev` (única conectada em `sf org list`). Nada tocado em QA, QAS, produção ou Marketing Cloud. A decisão de Leonardo Barbosa (`03-design.md`, final) vale acima da PA-30 e substitui a opção do bloco anterior: a EPLAST-35 é homologada junto com a EPLAST-38 e o pacote vai ligado.

| Falha | Correção | Estado |
|---|---|---|
| FALHA 1 (crítica): cadeia inalcançável na QAS | Três ajustes de metadata, sem mexer na lógica do Flow: (1) Flow `Lead_AfterSave_DistribuiDonoRodizio` com `<status>Active</status>` (era Draft); (2) `Lead.assignmentRules`: `Distribuicao_Regional_Leads` (v1 da 38) `active=false` e `Distribuicao_Regional_Leads_v2` `active=true`; (3) `DistribuicaoLeadSetting.Padrao.DistribuicaoAtiva__c = true`. Fila `Leads_RJ_ES` segue sem membros no pacote: pela decisão (item 4), quem testa inclui usuários ativos existentes pelo tempo do teste e remove ao fim. | Corrigido no XML. DEV: `--dry-run` aprovado e deploy real Succeeded (`0AfHa00000EJUiIKAX`). |

### Estado conferido na DEV depois do deploy
- Flow: v1 Obsolete, v2 Obsolete, **v3 Active** (o deploy criou a versão nova com a lógica corrigida do `Get_Membros`; nenhuma versão editada no lugar).
- Regra de Lead: v1 `false`, **v2 `true`**.
- CMDT `Padrao`: `DistribuicaoAtiva__c = true`.

### Versões e ativação
| Item | Antes | Depois | Desfazer |
|---|---|---|---|
| Flow `Lead_AfterSave_DistribuiDonoRodizio` | pacote em Draft | Active (ativação vem no deploy, autorizada pelo item 2 da decisão) | Desativar o Flow ou desmarcar o interruptor |
| Regra de Lead ativa | v1 `Distribuicao_Regional_Leads` (EPLAST-38) | **v2 `Distribuicao_Regional_Leads_v2`** (v1 deixa de ser a ativa; continua no org) | Setup > Regras de atribuição de Lead: reativar a v1 |
| `DistribuicaoAtiva__c` | false | true | Desmarcar no CMDT `Padrao` (basta para o Flow não agir) |

Impacto na QAS quando o esteira levar o pacote: todo Lead novo passa a ser distribuído pela v2 (região, RJ e ES juntos em `Leads_RJ_ES`) e pelo Flow (dono da conta, rodízio). Quem homologa a EPLAST-38 passa a ver esta distribuição (aceito pelo responsável). O Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao` e `LeadAssignmentService` (38) não foram tocados.

### Ainda sem prova em runtime
O rodízio não foi exercitado com sucesso em nenhuma org; a correção do `Get_Membros` e a medição do lote de 200 dependem do verificador (casos T1 a T18, seção 12 do design). T17 (3 processos de aprovação) deve ser conferido por Tooling ou retrieve de `approvalProcesses`. `Leads_RJ_ES` precisa de membros de teste antes de T1 (decisão, item 4).
