**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-30 · Testes (rodada 3) — Rascunho comercial pelo Screen Flow

**Org:** `sf org list` mostrou só `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy, conectada). Usuário do job: `005bJ00000piKAaQAM` (Administrador do sistema, ativo). Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EI981KAD`, commit `f59333e3`). Nada em produção, nada no Marketing Cloud.

## Rodada anterior (reteste)
- FALHA 2 da rodada anterior (follow-up sem data de fechamento): **corrigida**. Ver C-08.
- FALHA 1 da rodada anterior (Flow de tela não exercitado): **não corrigida**, ver FALHA 1 abaixo. A causa mudou: agora há como atribuir o PS ao usuário do job, mas a atribuição é recusada por falta de licença.

## Falhas

### FALHA 1 (crítica) — Caminho principal (Screen Flow, aba "Rascunho IA") não pôde ser exercitado de ponta a ponta
- **Reproduzir:** `sf data create record -s PermissionSetAssignment -v "AssigneeId=005bJ00000piKAaQAM PermissionSetId=0PSHa000002DN45OAG"` (mesmo erro com o grupo `PSG_Comercial_RascunhoIA`, `0PGHa000000J0AnOAK`) na QA.
- **Obtido:** erro "Este conjunto de permissões contém objetos personalizados 'Cotação' que requerem uma licença. Antes de continuar, atribua o usuário à licença do conjunto de permissões relacionada." O usuário do job tem 0 atribuições da licença `SalesforceCPQ_CPQStandardPerm` (a org tem 4 de 5 em uso). Atribuir licença não está entre as mudanças que a QA pode fazer no próprio usuário (só o PS da demanda, campo sintético e Marketing User), então não fiz. Sem o PS, o Flow é negado (C-03), logo não há prova de: tempo de 15 s no Flow, valor da cotação no Flow, limite de 50 linhas, compartilhamento (negativa por Id), mensagem de falha da IA sem travar o registro, ausência de trigger/Flow de gravação no debug log, e ausência de Task/Event criados pelo uso.
- **Esperado:** critérios de aceite da seção 4 de `01-analise.md` executados pelo Flow.
- **Causa provável:** limitação do ambiente, não defeito do build. Também indica que o PS da demanda exige licença CPQ de quem o recebe (ponto para o desenho/rollout: o PSG só pode ser dado a usuários com a licença CPQ). Para destravar: delivery atribui a licença CPQ ao usuário do job ou um usuário de teste com licença e login e o PSG; ou o time executa `05-roteiro-cliente.md`. Critério de aceite principal não executado = reprovado.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C-01 | Pacote presente na QA | `sf data query -t` em `Flow` (Definition `Opportunity_Screen_RascunhoComercial`); query de `PermissionSet` e `PermissionSetGroup` | Componentes de `05-deploy-qa.md` existem | Flow versão 3 `301Ha000016V4hyIAC` Ativa (v1, v2 obsoletas; nenhuma alteração minha); PS `0PSHa000002DN45OAG`; PSG `0PGHa000000J0AnOAK` (Updated). Templates: ver C-04 a C-08 (3 respondem). Custom permission e flexipage não reconferidas nesta rodada (conferidas na rodada anterior) | passou |
| C-02 | Acesso restrito por PS: aba não aparece | Rodada anterior, oportunidade `006Ha00000QWnWTIA1`, usuário sem PS, screenshot | Aba ausente | Abas só "Detalhes" e "Histórico Da Oportunidade" (evidência da rodada anterior; estado inalterado: 0 atribuições do PS) | passou (evidência anterior) |
| C-03 | Chamada direta ao Flow negada | Rodada anterior, `/flow/Opportunity_Screen_RascunhoComercial?recordId=006Ha00000QWnWTIA1` sem PS | Negado | "Privilégios insuficientes" (evidência anterior) | passou (evidência anterior) |
| C-04 | Proposta: dado ausente e preço sem cotação (template isolado) | POST `/einstein/prompt-templates/Rascunho_Proposta_Comercial/generations` (rodada anterior) | `[dado ausente: data de fechamento]`; `[a preencher]` | Conforme (evidência anterior; template não mudou em relação ao pacote) | passou (template, fora do Flow) |
| C-05 | Preço com cotação vem do registro (template) | Rodada anterior | Valor idêntico | `R$ 1.234,56` idêntico | passou (template) |
| C-06 | Sem dado pessoal | Rodada anterior e C-08 | Sem e-mail/telefone, `[nome do contato]` | Conforme; C-08 mostra `[nome do contato]` | passou (template) |
| C-07 | Argumentos com fonte | Rodada anterior | Fonte por argumento | 6 argumentos com "(fonte: ...)" | passou (template) |
| C-08 | Follow-up cita conta e data de fechamento (reteste da FALHA 2) | 3 POST em `Rascunho_Followup_Comercial`, entrada: conta "TESTE EPLAST-30 Conta", etapa Qualificação, data 31/12/2026, cotação "sem cotação" | Conta e data no texto; sem e-mail/telefone/nome | 3 de 3 respostas citam "TESTE EPLAST-30 Conta", "Qualificação" e "31/12/2026"; contato `[nome do contato]`; sem e-mail/telefone; lista de campos usados/vazios presente | passou (template) |
| C-09 | Proposta pelo Flow, 15 s, sem DML no log | Não executado | Texto em 15 s | PS não atribuível (FALHA 1) | não executado |
| C-10 | Respeito ao compartilhamento | Não executado | Negativa | Sem usuário com login e licença | não executado |
| C-11 | Falha da IA não trava; sem automação no log; nada enviado | Estático da verificação de dev (0 recordCreates/Updates/Deletes). `COUNT(Task) WHERE WhatId=006Ha00000QWnWTIA1` = 0 | Mensagem de falha; sem trigger/Flow no log | Não executado dinamicamente | não executado |
| C-12 | Limite de 50 linhas | Não executado | 50 linhas + "e mais N itens" | Exige Flow e cotação CPQ grande | não executado |
| C-13 | Regressão: criação de Opportunity | Rodada anterior, `006Ha00000QWnWTIA1` criada sem erro ligado ao pacote | Sem erro novo | Conforme | passou (evidência anterior) |
| C-14 | Página de Opportunity (EPLAST-26 preservada; preflight indica EPLAST-26 e EPLAST-41 em componentes comuns) | Não reconferido na tela | Regiões da EPLAST-26 intactas | Conferido só estaticamente na dev; não reconferido na QA | não conferido |
| C-15 | Apex | Sem Apex na solução | — | — | n/a |

## Mudanças no usuário do job
Nenhuma. A tentativa de atribuir o PS/PSG falhou e não criou atribuição (0 atribuições, conferido). Nada a desfazer.

## O que pode ter saído da org
- Dados de teste da rodada anterior, ainda existentes: Account `001Ha000016UimLIAS`, Pricebook2 `01sHa000002QbVpIAK`, Opportunity `006Ha00000QWnWTIA1` (todos "TESTE EPLAST-30"). Nesta rodada não criei registros.
- 3 chamadas ao serviço de geração do template de follow-up, com texto sintético. Sem ERP, e-mail, Task ou Event; nada no Marketing Cloud. Sem DML meu em registros existentes.
- Observação: o Flow ativo (v3) não foi alterado. `05-testes-rodada-<n>.md` é arquivado pela esteira.
