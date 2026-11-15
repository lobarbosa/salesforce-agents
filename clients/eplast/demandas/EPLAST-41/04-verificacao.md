**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (alias conferido com `sf org list`; única org conectada; Org Id `00DHa000006vfMLMAY`)

# EPLAST-41 · Verificação

## Resumo
O critério principal (gerar o rascunho em tela, salvar como Task e provar que a Account não muda) **não pôde ser exercitado**. Dois motivos, nenhum resolvido pelo builder:
1. Screen Flow não roda sem interface. `Flow.Interview.start()` recusa: "O Start não pode ser chamado em um fluxo com o tipo de processo Fluxo de tela". Não há comando `sf` nem API que execute tela.
2. A geração pelo prompt template falhou na dev quando chamada via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Rascunho_Relacionamento')`: "Failed to generate Einstein LLM generations response". Não sei se a causa é o template ou a org (modelo/Einstein Generative AI na dev). Não consegui separar as duas, então não classifico como falha do build.

Não houve falha comprovada de caso executado, portanto não é `reprovada`.

## Ajustes no usuário de execução (dev) e dados
| O que | Antes | Depois | Devolvido |
|---|---|---|---|
| `User.ProtheusSellerId__c` do usuário de execução (`005bJ00000piKAaQAM`) | vazio | valor sintético `TESTE41` (exigido pela regra `CheckAccountOwnerHasProtheusSellerId`) | Sim, voltou a vazio (conferido) |
Permission set e Marketing User não foram alterados. Perfil, papel e usuário da Konecta intocados.

Fixture rodado de novo com `fixtures/eplast41_dados_teste.apex`: Contas A e B ok, `TESTE EPLAST-41 Opp aberta` criada com sucesso (`006Ha00000QWnmbIAD`, conta `001Ha000016UjHVIA0`). `Opp ganha` continua falhando (exige Filial com `CodeERP__c` e forma de pagamento; objetos de apoio não existem). Cotação CPQ não criada.
Limpeza: oportunidade e contas `TESTE EPLAST-41%` apagadas; contagem final de contas de teste 0. Nada ficou.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Gerar rascunho a partir de conta (30 s, copiável, sem gravação) | Tentei iniciar o Screen Flow por Apex; tentei gerar pelo template via ConnectApi | Texto devolvido | Flow não inicia sem UI; geração retornou erro genérico | não executado |
| C2 | Salvar como Task (WhatId, TaskSubtype=Task, Description, sem EmailMessage) | Depende de C1 | 1 Task | `SELECT COUNT() FROM Task WHERE Subject LIKE '%(IA)%'` = 0 (nada gravado; nada exercitado) | não executado |
| C3 | Nenhum envio pelo CRM / Marketing Cloud | Leitura do Flow (XML do repositório): sem Send Email, `EmailMessage`, agendamento nem escrita `et4ae5`; um único `recordCreates` (a Task); ação de IA `generatePromptResponse` | Sem elementos de envio | Confere por leitura. Sem execução, não prova o comportamento | não executado (só leitura estática) |
| C4 | Prompt sem dado pessoal de contato | Entradas do template `Rascunho_Relacionamento` no repositório e org (metadata list) | Só `DadosConta`, `DadosOportunidade`, `ObjetivoMensagem`; sem e-mail, telefone, CPF, nome de contato | Entradas são essas três; instrução do template proíbe e-mail, telefone, documento e nome de pessoa (usa "[nome do contato]"). Template existe na dev (`0hfHa000000dBhxIAE`) | passou |
| C5 | Textos comerciais reaproveitados, sem duplicata | `sf org list metadata -m GenAiPromptTemplate` | Um de cada nome | `Argumentos_Comerciais_Oportunidade`, `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial` e `Rascunho_Relacionamento`: uma ocorrência cada | passou |
| C6 | Falha do modelo: erro sem texto parcial e sem Task | Foi provocada indiretamente (a geração falhou via ConnectApi), mas não passei pela tela | Tela de erro, 0 Task | Fault do Flow aponta para `Tela_Erro_Geracao` (leitura). Nenhuma Task existe. Sem execução do Flow | não executado |
| C7 | Conta sem oportunidade avisa e não gera texto | Conta B existia sem oportunidade; Flow não roda sem UI | Aviso, sem texto | Não exercitado | não executado |
| C8 | SFAgent2 intacto | `SELECT COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou (contagem; a não-alteração das 3 ações não foi comparada na org) |
| C9 | Marketing Cloud (`et4ae5`) intacto | Nenhum componente `et4ae5` entre os arquivos do plano de build | Sem alteração | Conforme o plano; sem comparação na org | não executado (só leitura do plano) |
| C10 | Estado das versões | Query em `Flow` por versão/status | v2 comercial Draft, Task Flow v1 Active, nada ativado por mim | `Opportunity_Screen_RascunhoComercial` v1 Active, v2 Draft; `Task_Screen_RascunhoRelacionamento` v1 Active | passou |
| C11 | Ação na Account (limite declarado) | Não testada pela UI | Ação nos layouts de Account e Opportunity | Ação não está na `Account_Record_Page_Three_Column` (erro pré-existente em `CampaignInfluences`, como o builder declarou). Registro como limite, não falha | não executado |

## O que pode ter saído da org
Nada pela cadeia de verificação: nenhum Task, EmailMessage ou registro de integração foi criado por mim, nenhuma chamada ao Marketing Cloud. A chamada de geração via ConnectApi usou só texto sintético `TESTE EPLAST-41` e falhou, sem resposta gravada.

## O que ficou sem prova e o que uma pessoa precisa fazer
Na dev, com a org e um usuário com `PSG_Comercial_RascunhoIA` (ou `PS_Comercial_RascunhoRelacionamento`), pela interface:
1. Verificar se Einstein Generative AI e o modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini` estão ativos na dev e testar o template `Rascunho_Relacionamento` no Prompt Builder (isso separa causa do erro de geração).
2. Criar a oportunidade aberta de teste (precisa de `User.ProtheusSellerId__c` no proprietário; o fixture cria) e abrir "Rascunho com IA" a partir da conta e da oportunidade: relacionamento e comercial (a v2 do Flow comercial só devolve texto depois de ativada; hoje v1 Active, v2 Draft, não ativei).
3. Conferir: texto em até 30 s, nada gravado antes de "Salvar como tarefa", depois exatamente 1 Task (`WhatId`, `TaskSubtype=Task`, `Description` igual ao texto), 0 `EmailMessage`, Account sem alteração; conta sem oportunidade mostra o aviso; falha do modelo mostra erro sem Task.
