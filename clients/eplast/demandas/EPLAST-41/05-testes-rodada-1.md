**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox QAS da Eplast, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`)

# EPLAST-41 · Testes na QA (rodada 1)

Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EI7qzKAD`). O critério principal (gerar o rascunho, salvar como Task) não foi exercitado e há uma causa provável de defeito do build. Reprovado.

## Falhas

### FALHA 1 (crítica) — Template `Rascunho_Relacionamento` sem versão ativa: a geração do texto não funciona
- **Reproduzir:** na QA, rodar por Apex anônimo `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Rascunho_Relacionamento', input)` com as três entradas (`Input:DadosConta`, `Input:DadosOportunidade`, `Input:ObjetivoMensagem`) com texto sintético `TESTE EPLAST-41`.
- **Obtido:** exceção `No active template version`.
- **Esperado:** texto gerado, que o Flow `Task_Screen_RascunhoRelacionamento` mostra na tela.
- **Causa provável:** no repositório, `Rascunho_Relacionamento.genAiPromptTemplate-meta.xml` tem `<status>Published</status>`, mas não tem `<activeVersionIdentifier>`; os outros templates (ex.: `Rascunho_Proposta_Comercial`) têm. Na dev o mesmo template falhou com erro genérico (`04-verificacao.md`, C1), que provavelmente era esta causa. Não confirmei o XML na QA (o retrieve estourou o tempo). Corrigir: publicar a versão e garantir que a versão ativa entre no pacote.

### FALHA 2 (crítica) — Tela "Rascunho com IA" não avança: sem botão de navegação (a confirmar)
- **Reproduzir:** como usuário com `PS_Comercial_RascunhoRelacionamento`, abrir a Conta de teste, menu "Mostrar mais ações", "Rascunho com IA". A tela abre com "Tipo de texto" (duas opções). Marcar "Mensagem de relacionamento".
- **Obtido:** rodapé do modal vazio, sem "Próximo". Procurei na página os textos "Próximo", "Next" e "Avançar": nenhum existe (esperei mais de 20 s). Sem avançar, não se chega à tela de objetivo, ao texto, nem ao "Salvar como tarefa".
- **Esperado:** botão para seguir para a tela "Mensagem de relacionamento".
- **Causa provável:** não determinada. O XML do Flow tem `showFooter=true` e `allowFinish=false` com conector. Pode ser renderização do Flow em Quick Action no modal, ou permissão do usuário de teste (só o PS de relacionamento, sem o PSG: ver limite abaixo). Quem corrigir deve abrir a ação na dev com um usuário real e confirmar.

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes na QA | `sf org list metadata` por tipo; query em `Flow` | Itens de `05-deploy-qa.md` existem | 4 GenAiPromptTemplate (1 de cada), QuickAction Account e Opportunity `Rascunho_Texto_IA`, PS `PS_Comercial_RascunhoIA`, `PS_Comercial_RascunhoRelacionamento`, PSG `PSG_Comercial_RascunhoIA`, CustomPermission `IA_Rascunho_Comercial` presentes. Flows: `Task_Screen_RascunhoRelacionamento` v1 Active; `Opportunity_Screen_RascunhoComercial` v1 Obsolete, v2 Active, v3 Draft | passou |
| C1 Gerar rascunho a partir de conta | Tela (ver FALHA 2) e Apex (ver FALHA 1) | Texto em até 30 s, copiável, nada gravado | Tela não avança; geração falha por `No active template version` | reprovado |
| C2 Salvar como Task | Depende de C1 | 1 Task com `WhatId`, `TaskSubtype=Task`, `Description` | `SELECT COUNT() FROM Task WHERE Subject LIKE '%(IA)%'` = 0 | não executado |
| C3 Nenhum envio pelo CRM | `EmailMessage` antes e depois | Sem aumento | 805 antes, 805 depois (a tela nunca chegou a gerar nada; só leitura estática do Flow: sem envio, um único Create Records de Task) | não executado (só leitura estática) |
| C4 Prompt sem dado pessoal | Entradas do template (repositório) | Só `DadosConta`, `DadosOportunidade`, `ObjetivoMensagem` | Confere; na chamada Apex usei só essas três | passou (leitura de metadata) |
| C5 Textos comerciais sem duplicata | `sf org list metadata -m GenAiPromptTemplate` | Um de cada nome | Uma ocorrência de cada um dos 4 | passou |
| C6 Falha do modelo sem texto parcial nem Task | Não chegou à tela | Tela de erro, 0 Task | Task (IA) = 0; Flow não percorrido | não executado |
| C7 Conta sem oportunidade avisa | Não chegou à tela (Conta B criada e depois apagada) | Aviso | Não exercitado | não executado |
| C8 SFAgent2 intacto | `SELECT COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou (contagem; ações não comparadas) |
| C9 `et4ae5` intacto | Lista de componentes do deploy | Nenhum `et4ae5` | Nenhum na lista de `05-deploy-qa.md` | passou (por inspeção da lista) |
| C10 Ação visível na Conta | UI (screenshot da Conta de teste, menu de ações) | Ação "Rascunho com IA" no menu | Aparece no menu "Mostrar mais ações" | passou |
| C11 Ação na Oportunidade | Não abri a Oportunidade pela UI | Ação presente | Metadata existe; não verificado em tela | não executado |

Evidência de tela: sessão de navegador na Conta `TESTE EPLAST-41 Conta A` (registro sintético): modal "Rascunho com IA" com "Tipo de texto" e rodapé vazio.

## Limites e ressalvas
- O PSG `PSG_Comercial_RascunhoIA` não pôde ser atribuído ao usuário de execução: "o grupo contém objetos personalizados 'Cotação' que requerem uma licença". Testei só com `PS_Comercial_RascunhoRelacionamento`. Caso de oportunidade/comercial fica para quem tem a licença CPQ.
- Pré-existente, não é da entrega: a QA já tinha `Opportunity_Screen_RascunhoComercial` v2 Active e v3 Draft (a dev tinha v1 Active, v2 Draft). Outras demandas do preflight (EPLAST-30, 40, 26) mexem nos mesmos componentes; não alterei nada deles.
- Conta A: a regra de duplicidade da QA (dado real copiado) barrou a criação. Ajustei o fixture `fixtures/eplast41_dados_teste.apex` para gravar com `allowSave` só as contas `TESTE EPLAST-41`. Sem leitura de registros reais.
- Cobertura Apex: o build não tocou Apex.

## Mudanças no meu usuário de execução (`005bJ00000piKAaQAM`) e dados
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
| Atribuição de `PS_Comercial_RascunhoRelacionamento` | não atribuído | atribuído | removida (conferido, 0) |
Contas, Oportunidade e Tasks `TESTE EPLAST-41` criadas e apagadas (contagem final 0). Usuário de teste da Konecta e perfis intocados.

## O que pode ter saído da org
Nada de envio: nenhum `EmailMessage` novo (805 antes e depois), nenhuma chamada ao Marketing Cloud. A chamada ao modelo falhou antes de gerar texto. Criação das contas disparou automações já existentes da org (por ex. uma tarefa "Conta Nova Cadastrada"); apaguei com as contas.
