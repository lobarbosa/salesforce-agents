**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-30 · Testes (rodada 3) — Rascunho comercial pelo Screen Flow, sem cotação

**Org:** `sf org list` mostrou só `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy, Connected). Usuário do job: `005bJ00000piKAaQAM` (Administrador do sistema). Nada em produção, nada no Marketing Cloud. Pacote: `05-deploy-qa.md` (deploy `0AfHa00000EIAs5KAH`, commit `14d07488`).

## Rodada anterior (reteste)
- FALHA 1 da rodada 2 (PS exigia licença CPQ; Flow de tela não exercitado): **corrigida**. A atribuição do `PS_Comercial_RascunhoIA` ao usuário do job passou (sem SBQQ no PS) e o Flow rodou na tela.
- FALHA 2 da rodada 2 (follow-up sem data): corrigida na rodada 2 (C-08 anterior); nesta rodada não reexecutada pelo Flow (ver FALHA 1 abaixo).

## Ativação da versão do Flow (regra de 2026-11-16)
- Antes: v4 **Active** (versão com cotação/EPLAST-41, `301Ha000016VIRjIAO`) e v5 **InvalidDraft** (a versão da demanda, `301Ha000016VPXyIAO`).
- Ação: reimplantei só o Flow `Opportunity_Screen_RascunhoComercial` com `<status>Active</status>` (deploy `0AfHa00000EIAthKAH`, Succeeded). Arquivo da branch restaurado, nada commitado.
- Depois (consulta `Flow` e `FlowDefinition.ActiveVersionId`): v5 `301Ha000016VOn3IAG` **Active**; v4 Obsolete. Fica ativa.

## Falhas

### FALHA 1 (crítica) — Follow-up e argumentos não exercitados pelo Flow; conteúdo do texto da proposta não verificado na tela
- **Reproduzir:** na QA, com o PS atribuído, abrir a Opportunity de teste `006Ha00000QWnWTIA1` > aba "Rascunho IA", escolher "Follow-up" ou "Argumentos comerciais" e Avançar.
- **Obtido:** a ferramenta de navegador (`qa_browser_click`) não alterou a seleção do rádio (permaneceu "Proposta comercial"; tentei "Follow-up" e "Argumentos comerciais", screenshot confirma). Duas execuções geraram só a proposta. Além disso, a caixa de texto gerado só mostra as primeiras linhas no screenshot e a ferramenta não devolve o valor do campo: vi "Proposta Comercial - Rascunho Interno / Oportunidade: TESTE EPLAST-30 Opp" e, na 2ª execução, "Rascunho de Proposta Comercial / Para: [nome do contato]". Conta, etapa, data de fechamento, `[a preencher]` e lista de campos usados/vazios não foram lidos no Flow.
- **Esperado:** CA-02 (follow-up), CA-03 (argumentos com fonte) e os textos de CA-01/04/05/07 provados pelo Flow.
- **Causa provável:** limitação da ferramenta de UI, não defeito do build. Fica para o roteiro manual (`05-roteiro-cliente.md`). Pelas regras, critério de aceite principal não executado é `reprovado`.

### FALHA 2 (crítica) — CA-08 (compartilhamento), CA-10 (falha da IA) e CA-11 (debug log sem trigger/Flow) sem prova
- Sem usuário de teste com login e o PSG, sem acesso ao registro "Y" (o usuário de teste da conta de serviço, Id `005bJ00000hBJmYQAW`, está inativo; `005bJ00000piKAaQAM` é o do job). Sem desativar o template e sem debug log não consegui provar. Só há prova indireta de CA-12 (ver C-11).

### Observação de interferência (EPLAST-41), não é falha deste caso
Antes da ativação, a v4 ativa do Flow expunha `varTextoGerado` para o Flow `Task_Screen_RascunhoRelacionamento` (ativo na QA, `301Ha000016VIRkIAO`, da EPLAST-41). A v5 desta demanda não tem essa saída. Não verifiquei se o Task_Screen a usa em execução. Se usar, quebra na QA: vale conferir antes de liberar as duas demandas juntas.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C-01 | Pacote presente | Query Tooling em `Flow`, `PermissionSetGroup`, `PermissionSet`; abrir a página | Componentes de `05-deploy-qa.md` existem | Flow v5 Active após ativação; PS `0PSHa000002DN45OAG`; PSG `0PGHa000000J0AnOAK` Updated; aba "Rascunho IA" aparece na Opportunity com o PS | passou |
| C-02 | Sem PS, aba não aparece | Rodada anterior (PS ainda sem atribuição), screenshot | Aba ausente | Abas só "Detalhes" e "Histórico Da Oportunidade" (evidência da rodada 2) | passou (evidência anterior) |
| C-03 | Flow direto sem PS negado | `qa_browser_open` em `/flow/Opportunity_Screen_RascunhoComercial?recordId=006Ha00000QWnWTIA1` com PS removido (0 atribuições, conferido) | Negado | Tela "Privilégios insuficientes" | passou |
| C-04 | PS atribuível sem licença CPQ | `sf data create record PermissionSetAssignment` | Cria | `0PaHa00000EK0rpKAD` criada (removida ao fim) | passou |
| C-05 | Proposta pelo Flow, tempo | Aba "Rascunho IA", "Proposta comercial", Avançar; screenshots seguidos | Texto na tela em até 15 s | Texto apareceu após alguns segundos (2 execuções; tempo exato não cronometrado, na ordem de 5 a 10 s pelos screenshots); título "Rascunho gerado por IA: revise antes de usar. Nenhum campo deste registro foi alterado." | passou (texto parcial) |
| C-06 | Proposta cita conta/etapa | Ler o texto | Conta e etapa | Início do texto cita "TESTE EPLAST-30 Opp" e `[nome do contato]`; conta e etapa não lidas | não conferido (FALHA 1) |
| C-07 | Follow-up pelo Flow | Selecionar Follow-up | Conta e data de fechamento; sem dado pessoal | Seleção não mudou | não executado (FALHA 1) |
| C-08 | Argumentos com fonte | Selecionar Argumentos | Fonte por item | Seleção não mudou | não executado (FALHA 1) |
| C-09 | Dado ausente / preço sem cotação | Opp de teste sem Valor | `[a preencher]` e marcador de ausente | A oportunidade de teste tem Valor vazio e data 31/12/2026; texto não lido na tela. Prova de template isolado nas rodadas 1 e 2 (`R$ 1.234,56` idêntico etc.) | não conferido no Flow |
| C-10 | Respeito ao compartilhamento | — | Negativa | Sem usuário de teste | não executado (FALHA 2) |
| C-11 | Nada é gravado / enviado | `COUNT(Task)` e `COUNT(Event)` com `WhatId`=Opp de teste; `LastModifiedDate` da Opp; Task criadas hoje pelo usuário do job | 0 / 0 / inalterada / 0 | 0 Task, 0 Event; Opp `LastModifiedDate` 2026-11-15T22:44:22Z (igual à criação); 0 Task criadas hoje pelo job. Debug log não capturado | passou (parcial; log não executado) |
| C-12 | Falha da IA não trava | — | Mensagem de falha | Não executado | não executado (FALHA 2) |
| C-13 | Limite de 50 linhas / cotação | — | — | Fora do escopo pela decisão de 2026-11-16 (PE-01, PE-04) | não se aplica |
| C-14 | Página de Opportunity (EPLAST-26) | Screenshot da Opp de teste | Regiões da EPLAST-26 preservadas | Página mostra Caminho, "Condições de Pagamento Oportunidade", Papéis do contato, Cotações CPQ, Cotações, Pedidos, Produtos e a aba "Rascunho IA"; Priority Score/Band não identificados na tela da Opp de teste (não dá para afirmar) | não conferido |
| C-15 | Apex | Sem Apex na solução | — | — | n/a |

## Premissas usadas
PE-01 a PE-04 e PB-01 a PB-03 do plano de build e PD-01 a PD-07 do design foram seguidas: sem cotação (PE-01), valor só de `Opportunity.Amount` (PE-02), sem leitura de produto (PE-03). Nenhuma delas foi motivo de reprovação. PB-01 (marcadores `[Seu nome]`) não foi reprovada.

## Mudanças no usuário do job (desfeitas)
- Atribuí `PS_Comercial_RascunhoIA` (`0PaHa00000EK0rpKAD`, depois `0PaHa00000EK0n1KAD`); ambas removidas. Conferido: 0 atribuições do PS. Nada mais alterado.

## O que pode ter saído da org
- Registros de teste das rodadas anteriores (nenhum criado agora): Account `001Ha000016UimLIAS`, Opportunity `006Ha00000QWnWTIA1` ("TESTE EPLAST-30").
- 2 gerações de proposta pelo Flow (serviço de IA da própria org, texto sintético). Sem e-mail, Task, Event, ERP ou Marketing Cloud.
- Deploy do Flow v5 Active na QA (permanece; regra da versão nova).
