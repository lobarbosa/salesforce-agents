**Resultado do build:** concluído

# EPLAST-35 — Plano de build (rodada 3: distribuição de Leads sem Apex)

**Org conectada:** `sbx-eplast-dev` (`projetos@konectabr.com.eplast2.qa`, Sandbox, Connected; é a `eplast--qa` da Eplast, DEV da esteira pela regra 5). Única org em `sf org list`. Nada tocado em QA, QAS, produção ou Marketing Cloud.
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
- **Antes de T1:** ativar a v2 e depois marcar `DistribuicaoAtiva__c` (seção 2). Pôr membros diretos nas filas de teste (`Leads_MG`, `Leads_SP`, `Leads_RJ_ES`). O usuário de teste é a conta `projetos@konectabr.com%` (resolver o Id na org; citar só `005…`).
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
