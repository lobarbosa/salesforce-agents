**Resultado do build:** concluído

# EPLAST-41 · Plano de build

**Org:** `sbx-eplast-dev` (alias conferido com `sf org list`; sandbox "QA" da Eplast, regra 5 da conta). Nada em produção nem na `sbx-eplast-qa`. Branch `feature/EPLAST-41`. API 67.0. Último deploy: `0AfHa00000EI1yVKAT` (Succeeded).
Design seguido item a item (`03-design.md`). Nada de Apex, campo, objeto, envio ou Marketing Cloud.

## Componentes criados e alterados

| # | Componente | Ação | Arquivo | Estado na dev |
|---|---|---|---|---|
| 1 | Flow `Task_Screen_RascunhoRelacionamento` (Screen Flow) | Criado | `flows/Task_Screen_RascunhoRelacionamento.flow-meta.xml` | v1 **Active** (nasce ativo, não substitui nada) |
| 2 | Flow `Opportunity_Screen_RascunhoComercial` | **v2 Draft**: só `varTextoGerado` com `isOutput=true` + descrição | `flows/Opportunity_Screen_RascunhoComercial.flow-meta.xml` | v1 Active, v2 Draft |
| 3 | GenAiPromptTemplate `Rascunho_Relacionamento` | Criado (flex, Published, entradas `DadosConta`, `DadosOportunidade`, `ObjetivoMensagem`) | `genAiPromptTemplates/Rascunho_Relacionamento...` | Criado |
| 4 | PermissionSet `PS_Comercial_RascunhoRelacionamento` | Criado (2 Flows + custom permission `IA_Rascunho_Comercial`; sem permissão de objeto) | `permissionsets/...` | Criado |
| 5 | PermissionSetGroup `PSG_Comercial_RascunhoIA` | Inclui o PS novo (0 atribuições, nada muda para usuários) | `permissionsetgroups/PSG_Comercial_RascunhoIA...` | Atualizado |
| 6 | QuickAction `Account.Rascunho_Texto_IA` e `Opportunity.Rascunho_Texto_IA` (tipo Flow, "Rascunho com IA") | Criadas | `quickActions/` | Criadas |
| 7 | Layouts `Account-Account Layout`, `Opportunity-Opportunity Layout` | Só acrescentada a ação (partiu do que a dev tem) | `layouts/` | Atualizados |
| 8 | FlexiPage `Opportunity_Record_Page_Three_Column` (ações dinâmicas) | Só acrescentada a ação no painel de destaque | `flexipages/` | Atualizada |
| 9 | Fixture de dados de teste | Criado | `fixtures/eplast41_dados_teste.apex`, `fixtures/README.md` | Parcial, ver abaixo |
| 10 | Dependências recuperadas da dev **sem alteração**, para o pacote da QA (R1): 3 templates (`Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade`), `PS_Comercial_RascunhoIA`, `IA_Rascunho_Comercial` | Só versionadas no repositório | `genAiPromptTemplates/`, `permissionsets/`, `customPermissions/` | Não redeployadas |

Todos os componentes novos têm descrição (≤255 caracteres nos PS/PSG/template) citando EPLAST-41.

### Flow `Task_Screen_RascunhoRelacionamento`, como foi montado
Guarda de prefixo `001`/`006`; leituras (oportunidade, conta, última ganha e próxima aberta, só o primeiro registro); escolha relacionamento/comercial; relacionamento chama `Rascunho_Relacionamento` (fault: tela de erro, sem texto, sem Task); comercial: de Opportunity, subflow com o Id; de Account, sem aberta mostra o aviso e termina, com aberta o choice set dinâmico (`IsClosed=false`, limite 50). Tela de resultado com texto editável e o aviso "O envio é feito pelo Marketing Cloud". "Salvar como tarefa" cria 1 Task: `WhatId` = origem (ou a oportunidade escolhida), `Subject` constante (`Rascunho de relacionamento (IA)` / `Rascunho comercial (IA)`, nunca `Check In @`), `Description` = texto da tela, `TaskSubtype=Task`, `Status=Open`, `Priority=Normal`, sem `ActivityDate`, `OwnerId` = usuário corrente. Texto vazio não grava; fault não grava. `isAdditionalPermissionRequiredToRun=true`. Sem Send Email, `EmailMessage`, agendamento ou escrita em `et4ae5`. Sem valores monetários no bloco de relacionamento (PA-41-14).
Se o subflow não devolver texto (v1 do comercial ativa), a tela diz que o texto está na tela anterior e não oferece salvar (PA-41-13).

## Versões e ativação

**Nada foi ativado nesta etapa.** Estado na dev: `Opportunity_Screen_RascunhoComercial` v1 Active e v2 Draft; `Task_Screen_RascunhoRelacionamento` v1 Active (novo).
1. **Verificador (dev):** provar a v2 do comercial (abrir como Draft/depurar) e o fluxo completo. A ativação da v2 só depois dessa prova.
2. **Ativar v2 de `Opportunity_Screen_RascunhoComercial`** (passo separado, humano ou etapa de ativação): a v1 sai. Desfazer: reativar a v1. Até lá o Flow novo funciona, mas só oferece salvar o texto de relacionamento.
3. **QA:** a esteira leva o pacote (inclui as dependências do item 10); se a QA não tiver versão ativa do Flow comercial, a v2 precisa ser ativada lá para o caminho comercial.
4. **Admin da Eplast:** atribuir `PSG_Comercial_RascunhoIA` aos usuários (0 atribuições hoje); o build não atribui a ninguém.

## Pontos a saber (não bloqueiam)
- **Flexipage `Account_Record_Page_Three_Column` não recebeu a ação.** O redeploy da página recuperada da dev falha por problema que já existia nela (`Could not find related list [CampaignInfluences] for entity [Account]`), fora do escopo. Mudança revertida. A ação já está no layout de Account (páginas sem ações dinâmicas) e nas páginas de Opportunity. Se a conta usar essa página de três colunas, o admin acrescenta "Rascunho com IA" nas ações do painel de destaque, ou corrige a lista relacionada da página.
- **Layout `CPQ Opportunity Layout`** (atribuído aos perfis comerciais) é de pacote gerenciado (SBQQ) e não pode ser alterado; o `Opportunity Layout` e a página Lightning recebem a ação. Confirmar na homologação onde o vendedor vê o botão.
- **Fixture parcial.** Contas A e B criadas na dev. Oportunidade aberta falha só porque o usuário de execução não tem `User.ProtheusSellerId__c` (regra `CheckAccountOwnerHasProtheusSellerId`); o builder não mexe no usuário. O verificador pode ajustar o próprio usuário e rodar o script de novo. Oportunidade ganha exige Filial com `CodeERP__c`, forma e condição de pagamento (opcional). Cotação CPQ não criada: comercial testado "sem cotação". Detalhe em `fixtures/README.md`.
- O deploy com a v1 do comercial ainda ativa aceitou a atribuição da saída `varTextoGerado` no subflow; só o valor só chega ao Flow novo depois da ativação da v2.
- Premissas PA-41-x seguidas como no design; nenhuma pergunta de negócio ficou aberta.

## Correções da rodada 1

Org: `sbx-eplast-dev` (alias conferido). Nada tocado na QA.

| Falha | Correção | Prova |
|---|---|---|
| FALHA 1: `No active template version` | Confirmado na dev: o template `Rascunho_Relacionamento` não tinha `activeVersionIdentifier` (só `versionIdentifier`, gerado pela org). Acrescentados `activeVersionIdentifier` e `versionIdentifier` (`XoWlw1En...XjlU=_1`, o da versão que a dev gerou) ao XML do repositório e redeploy na dev. | Retrieve da dev depois do deploy traz os dois campos. Apex anônimo com `generateMessagesForPromptTemplate('Rascunho_Relacionamento')` e as 3 entradas sintéticas (`TESTE EPLAST-41`) devolveu texto (422 caracteres). Resolve também o erro genérico visto na verificação (C1). |
| FALHA 2: tela sem botão "Próximo" | Causa não confirmada (não há UI aqui). Hipótese mais forte: as 5 telas intermediárias estavam com `allowFinish=false`, diferente do Flow comercial existente e do que o Flow Builder grava (`allowFinish=true` em toda tela; o Próximo vem do conector). Todas as 13 telas passaram a `allowFinish=true`. Nada mais mudou na lógica. | Deploy ok na dev. **Não provado em tela**: o verificador/QA precisa abrir a ação com usuário real e confirmar o botão. Se persistir, o próximo suspeito é renderização do Flow em Quick Action no modal ou permissão do PS. |

Premissa de versionamento: a mudança do Flow entrou como **v2 Draft** (v1 segue Active), sem editar a versão em uso.

### Versões e ativação (atualização)
- Dev: `Task_Screen_RascunhoRelacionamento` v1 Active, v2 Draft. **Ativar a v2** (passo separado) é necessário para a ação mostrar o botão; antes disso só a v1 roda. Testar a v2 como Draft por depuração na dev, depois ativar. Desfazer: reativar a v1.
- QA: levar o template com as duas identificações de versão e a v2 do Flow; ativar a v2 lá. O `activeVersionIdentifier` é o da dev: se a QA gerar identificador próprio na publicação, conferir com Apex sintético que a versão ativa existe (a falha 1 só se resolve na QA se a versão ficar ativa).
- Limite: `PSG_Comercial_RascunhoIA` não atribui sem licença CPQ (nota da QA); caminho comercial fica para quem tem a licença.

## Correções da rodada 2

Org: `sbx-eplast-dev` (alias conferido com `sf org list`; Org Id `00DHa000006vfMLMAY`). Nada tocado na QA. **Nenhum metadata foi alterado nesta rodada**, e o motivo está abaixo.

| Falha | Correção | Prova |
|---|---|---|
| FALHA 1 (crítica): tela "Rascunho com IA" sem botão para avançar, persiste da rodada 1 | **Não corrigível por metadata nesta etapa; é passo de ativação.** A correção (13 telas com `allowFinish=true`) já está no repositório e na v2 de `Task_Screen_RascunhoRelacionamento` (`status` Draft no XML). A causa que a QA apontou procede: a quick action abre a versão **ativa**, e a ativa é a v1 defeituosa (dev: v1 Active, v2 Draft; QA: v1 Active, v2 Draft). Corrigir a v1 no lugar é proibido (versão ativa não se edita) e ativar a v2 é passo separado, que não faço. Mesma situação em `Opportunity_Screen_RascunhoComercial` (dev: v1 Active, v2 Draft; QA: v3 Active, v4 Draft). | Conferido por Tooling em `Flow` na dev (`Task_Screen_RascunhoRelacionamento` v1 Active e v2 Draft; `Opportunity_Screen_RascunhoComercial` v1 Active e v2 Draft). XML do repositório: 13 de 13 telas com `allowFinish=true`. **Ainda não provado em tela**: a correção só vale depois que a v2 estiver ativa. |

### Versões e ativação (atualização da rodada 2)
Sem a ativação abaixo, a próxima rodada de QA reprova de novo pelo mesmo motivo. Os dois passos são de quem ativa Flow (humano ou etapa de ativação da esteira), e nenhum foi feito aqui:
1. **Dev:** depurar a v2 de `Task_Screen_RascunhoRelacionamento` e confirmar o botão de avanço; depois ativar a v2 (a v1 sai). Desfazer: reativar a v1. A v1 nunca foi usada por vendedor (PSG com 0 atribuições), então a troca não afeta ninguém.
2. **QA:** ativar a v2 de `Task_Screen_RascunhoRelacionamento` antes de a QA retestar. Em `Opportunity_Screen_RascunhoComercial` a v4 (só expõe `varTextoGerado` como saída) pode ficar Draft: sem ela o Flow novo funciona e só não oferece salvar o texto comercial (PA-41-13).
3. Alternativa se a esteira preferir entregar já ativo: trocar `status` para `Active` no XML de `Task_Screen_RascunhoRelacionamento` (flow novo, que o design previu nascer ativo, item 13). Não fiz porque é ativação e ficou fora do que me foi autorizado; decisão de quem opera a esteira.
- FALHA 2 da rodada 1 (`No active template version`) segue corrigida na QA, conforme a rodada 2 (528 caracteres em 2,6 s). Nada mudou no template.
- C12 (oportunidade e comercial) depende de licença CPQ para atribuir o PSG; não é corrigível no build.

## Alinhamento com a EPLAST-30 (decisão do responsável, 2026-11-16)

Org: `sbx-eplast-dev` (alias conferido com `sf org list`). Nada tocado na QA. Deploy na dev: `0AfHa00000EIAP4KAP` (Succeeded, 9 componentes).

Os 7 componentes da EPLAST-30 foram sobrescritos com `git show origin/feature/EPLAST-30:<caminho>` (sem cotação; modelos de prompt sem `Input:DadosCotacao` na versão ativa; PS sem `SBQQ`):

| Componente | Estado |
|---|---|
| `customPermissions/IA_Rascunho_Comercial` | idêntico ao da EPLAST-30 |
| `genAiPromptTemplates/Argumentos_Comerciais_Oportunidade`, `Rascunho_Followup_Comercial`, `Rascunho_Proposta_Comercial` | idênticos ao da EPLAST-30 |
| `permissionsets/PS_Comercial_RascunhoIA` | idêntico ao da EPLAST-30 |
| `flows/Opportunity_Screen_RascunhoComercial` | EPLAST-30 + **só a mudança da 41** (abaixo) |
| `permissionsetgroups/PSG_Comercial_RascunhoIA` | EPLAST-30 + **só a mudança da 41** (abaixo) |

Mudanças da EPLAST-41 reaplicadas em cima da versão da EPLAST-30:
1. Flow comercial: `varTextoGerado` com `isOutput=true` e frase de EPLAST-41 no fim da descrição. Mais nada (status segue Draft, como na EPLAST-30).
2. PSG: `PS_Comercial_RascunhoRelacionamento` incluído como componente e frase na descrição.

Intocado (só da 41): `Task_Screen_RascunhoRelacionamento` (13 telas com `allowFinish=true`), `Rascunho_Relacionamento`, `PS_Comercial_RascunhoRelacionamento`, quick actions, layouts, flexipage.

Observação: os XML dos três modelos mantêm, como na EPLAST-30, uma versão antiga no histórico (`templateVersions`) que cita `DadosCotacao`; a versão ativa de cada um não tem a entrada. Não regride a QA, pois é o mesmo arquivo da EPLAST-30.

### Versões e ativação (atualização)
- Nada foi ativado. O deploy na dev criou nova versão Draft do Flow comercial a partir do XML da EPLAST-30 mais a saída; a ativação continua passo separado (v2 do `Task_Screen_RascunhoRelacionamento` e a versão do comercial com a saída, conforme seções anteriores).
- Não ativar na QA nada que faça os componentes da EPLAST-30 voltarem a ter cotação.
