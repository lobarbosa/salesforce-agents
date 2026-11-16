**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (sandbox "QA" da Eplast, regra 5; org 00DHa000006vfMLMAY, conferida com `sf org list`)

# EPLAST-41 · Verificação (após correções da rodada 1)

Motivo: o critério principal (tela do Screen Flow, texto, salvar Task) só roda por interface. `Flow.Interview.start()` recusa Screen Flow ("O Start não pode ser chamado em um fluxo com o tipo de processo Fluxo de tela") e não há sessão de usuário com UI. Provei por Apex e metadata o que dá; o resto fica sem prova.

## Dados e ajustes de usuário (dev)
- Fixture `fixtures/eplast41_dados_teste.apex`: Conta A (`001Ha000016Ux2DIAS`), Conta B (`001Ha000016Ux2EIAS`), Opp aberta (`006Ha00000QWv93IAD`) criadas. Opp ganha falhou (exige Filial com `CodeERP__c`; fixture já documenta, opcional).
- Usuário de execução `005bJ00000piKAaQAM`: `ProtheusSellerId__c` de null para `TESTE41` (exigido pela regra `CheckAccountOwnerHasProtheusSellerId`) e devolvido a null ao final (conferido). Não atribuí o PS novo nem mexi em Marketing User.
- Limpeza: Opp e Contas `TESTE EPLAST-41` apagadas; contagem final 0. Task `Rascunho%`: 0 antes e depois.
- Usuário de serviço da Konecta: o Id citado é o próprio usuário de execução; o outro (`005bJ00000hBJmYQAW`) está inativo. Não usado.

## Falhas da rodada anterior
| Falha | Situação |
|---|---|
| FALHA 1: `No active template version` | **Corrigida (provada).** Apex com `generateMessagesForPromptTemplate('Rascunho_Relacionamento')` e 3 entradas sintéticas devolveu texto de 440 caracteres em ~1,5 s. |
| FALHA 2: sem botão "Próximo" | **Não provada em tela.** Metadata da v2 na dev (Tooling): 13 telas, todas `allowFinish=true`. Só um usuário com UI confirma o botão. v2 segue Draft. |

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Gerar rascunho da conta, ≤30 s | Apex chamou o template com entradas sintéticas, medindo o tempo | Texto gerado em até 30 s | 440 caracteres, 1,5 s (só o template, não a tela) | passou (parcial: tela não exercitada) |
| 2 | Texto editável, nada criado antes de salvar | Contagem de Task `Rascunho%` após a geração | 0 | 0 | passou para o template; tela não exercitada |
| 3 | Salvar como Task (WhatId, Subtype, Description) | Tooling na v2: 1 recordCreate; Flow não executável sem UI | Task com os campos do design | Só leitura da metadata (1 `recordCreate`); nenhuma Task criada | não executado |
| 4 | Account não muda ao salvar | Exigia salvar via tela | `AccountHasCheckInTask__c`/`LastModifiedDate` iguais | Sem execução | não executado |
| 5 | Opp aberta: relacionamento e comercial (v2) | Exigia tela e v2 ativa | Task na oportunidade | Opp de teste criada, fluxo não rodado; v2 Draft | não executado |
| 6 | Conta B sem opp: aviso | Exigia tela | Aviso, sem texto | Sem execução | não executado |
| 7 | Falha do modelo: erro sem texto, 0 Task | Exigia tela | Tela de erro, 0 Task | Metadata: `Gerar_Relacionamento` é a única action call, com fault para tela de erro; não executado | não executado |
| 8 | Nenhum envio / Marketing Cloud | grep no XML do Flow por emailSimple, emailAlert, EmailMessage, et4ae5, Send; query de EmailMessage `TESTE EPLAST-41%` | Nenhum | 0 ocorrências no XML; 0 EmailMessage | passou (estático) |
| 9 | Prompt sem dado pessoal | Leitura do template no repositório | Só `DadosConta`, `DadosOportunidade`, `ObjetivoMensagem` | Exatamente essas 3 entradas | passou |
| 10 | Textos comerciais reaproveitados, sem duplicata | git diff vs. main e metadata | 3 templates existentes, sem novos de mesmo nome | Os 3 só versionados (recuperados da dev, sem alteração de conteúdo conferida no build); nenhum template comercial novo | passou (estático) |
| 11 | SFAgent2 único e intacto | Query de `BotDefinition` | 1 | 1 (ações não comparadas) | passou (contagem) |
| 12 | Acesso negado sem o PS novo | Query de atribuições do `PS_Comercial_RascunhoRelacionamento` | 0 atribuições; sem UI para tentar abrir | 0 atribuições; execução negada não testada | não executado |
| 13 | Versões do Flow | Query de `Flow` na dev | Comercial v1 Active, v2 Draft; Relacionamento v1 Active, v2 Draft | Confere | passou |

## O que ficou sem prova
- O fluxo completo na tela: botão "Próximo" (FALHA 2), texto editável, salvar Task, Conta A não alterada, Conta B com aviso, caminho comercial na v2, tela de erro na falha do modelo, acesso negado. Um usuário com UI na dev deve:
  1. Ativar ou depurar a v2 de `Task_Screen_RascunhoRelacionamento`.
  2. Atribuir `PSG_Comercial_RascunhoIA` (a nota da QA diz que exige licença CPQ).
  3. Abrir "Rascunho com IA" na Conta A e na Opp aberta, e percorrer os casos 2 a 7.
- Conta A, Conta B e a Opp aberta podem ser recriadas com o fixture.

## O que pode ter saído da org
Nada saiu pelo CRM. Houve 1 chamada ao modelo (Einstein/Prompt Builder) com texto sintético, sem dado real. Nenhum EmailMessage, nada no Marketing Cloud.
