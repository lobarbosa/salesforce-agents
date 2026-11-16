**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, conferida com `sf org list`; nada tocado na QA nem em produção)

# EPLAST-41 · Verificação do build (commit c82a11a6)

## Por que inconclusiva
O critério principal é o fluxo de tela (gerar o texto, copiar, salvar como Task). Ele não pôde ser exercitado na dev por duas razões que o builder não resolve:
1. Screen Flow não roda por Apex (`Flow.Interview.start()` recusa: "O Start não pode ser chamado em um fluxo com o tipo de processo Fluxo de tela"), e a sessão não tem interface.
2. A v2 de `Task_Screen_RascunhoRelacionamento` (a que tem os botões corrigidos) segue Draft. A ativação é passo separado, que o verificador não faz.

Nenhum caso executado falhou, então não é reprovação.

**Sem prova nesta rodada:** salvar como Task (Task com `WhatId`, `TaskSubtype=Task`, `Description` igual ao texto, sem `EmailMessage`), tela de erro quando o modelo falha, caminho comercial a partir da conta, botão de avançar na v2.
**O que uma pessoa precisa fazer:** na dev, depurar a v2 de `Task_Screen_RascunhoRelacionamento` (ou ativá-la) com a `TESTE EPLAST-41 Conta A`, gerar, salvar e consultar a Task. Na QA a rodada 3 já provou a tela com a v2 ativa (avanço, aviso da Conta B). Falta lá só o salvamento, que ficou travado pelo erro do modelo, corrigido depois.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Gerar rascunho em até 30 s | Apex anônimo com `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Rascunho_Relacionamento')`, 3 entradas sintéticas `TESTE EPLAST-41` | Texto em até 30 s | Texto de 622 caracteres em 2.464 ms | passou (só o modelo; a tela não foi exercitada) |
| V2 | Nada gravado antes de salvar | `COUNT()` de Task com `(IA)` no assunto, depois do teste do modelo | 0 | 0 | passou |
| V3 | Salvar como Task | Não exercitável (Screen Flow) | Task com `WhatId` = conta | não rodou | não executado |
| V4 | Nenhum envio pelo CRM | `grep` de sendEmail, emailSimple, emailAlert, EmailMessage, et4ae5 no Flow novo; `COUNT() EmailMessage` | Nenhuma ocorrência; 0 novo | Nenhuma ocorrência. Único `recordCreates` é Task. `EmailMessage` = 0 (dev) antes e depois | passou (metadata) |
| V5 | Prompt sem dado pessoal | Entradas do template `Rascunho_Relacionamento` no repositório | Só conta, oportunidade, objetivo | `DadosConta`, `DadosOportunidade`, `ObjetivoMensagem`; sem e-mail, telefone, CPF ou contato | passou (metadata) |
| V6 | Textos comerciais sem duplicata e sem regredir a EPLAST-30 | `git diff origin/feature/EPLAST-30` nos 3 templates, `PS_Comercial_RascunhoIA` e `IA_Rascunho_Comercial` | Idênticos | Idênticos nos 5 arquivos. Nenhum template com nome repetido no repositório | passou |
| V7 | Falha do modelo: erro, sem texto, 0 Task | Não provocável na dev | Tela de erro | não rodou | não executado |
| V8 | Conta sem oportunidade avisa | Fixture criou a Conta B sem oportunidade; fluxo não exercitável aqui | Aviso | Não rodou na dev. Na QA, rodada 3, o aviso passou | não executado |
| V9 | SFAgent2 único | `COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou |
| V10 | `et4ae5` intacto | Conteúdo do build (plano) e `git diff --stat` de `force-app` | Nenhum componente | Nenhum componente `et4ae5` no plano nem no flow | passou (inspeção) |
| V11 | Versões novas existem e as ativas não foram editadas no lugar | Tooling em `Flow` | v1 Active sem mudança; versão nova Draft | `Task_Screen_RascunhoRelacionamento`: v1 Active (modificada 2026-11-15) e v2 Draft (2026-11-16). `Opportunity_Screen_RascunhoComercial`: v1 Active (2026-11-15 10:20, anterior ao build) e v2 Draft. Na v2 do Task, 13 de 13 telas com `allowFinish=true` | passou |
| V12 | Fixture na dev | `fixtures/eplast41_dados_teste.apex` com o usuário ajustado | Contas A e B e oportunidade aberta | Contas A e B e `Opp aberta` criadas. A ganha falhou, como o README documenta (exige Filial com `CodeERP__c`) | passou (ganha, não necessária) |

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`)
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
Permission set e Marketing User: não tocados. Usuário de serviço da Konecta: não usado.

## Limpeza
Apagadas oportunidade, tarefas de `Conta Nova Cadastrada` e as duas contas `TESTE EPLAST-41`; `COUNT()` das contas = 0. Nenhum job agendado. Nada ficou.

## O que pode ter saído da org
Uma chamada ao modelo (Einstein/prompt template) com texto sintético, nada gravado. Nenhum `EmailMessage`, nenhuma chamada ao Marketing Cloud. A criação das contas pode ter disparado automação existente da org (tarefa "Conta Nova Cadastrada"), apagada com a conta.
