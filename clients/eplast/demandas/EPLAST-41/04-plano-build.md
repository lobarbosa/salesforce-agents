**Resultado do build:** concluído

# EPLAST-41 · Plano de build

**Org:** `sbx-eplast-dev` (usuário `projetos@konectabr.com.eplast2.qa`, conferido com `sf org list`; sandbox "QA" da Eplast, regra 5 da conta). Nada em produção nem na `sbx-eplast-qa`. Branch `feature/EPLAST-41`. API 67.0. Último deploy: `0AfHa00000EI1yVKAT` (Succeeded).
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
