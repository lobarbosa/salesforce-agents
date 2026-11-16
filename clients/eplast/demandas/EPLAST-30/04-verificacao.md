**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, Sandbox, Connected, conferido com `sf org list`; usuário de execução identificado só pelo alias)

# EPLAST-30 · Verificação do build (dev)

Escopo testado: o build após a decisão do responsável de 2026-11-16 (rascunho sem cotação), conforme `04-plano-build.md`. Nada feito fora da dev. Não ativei versão de Flow. Não criei registro algum (a dev tem 0 Opportunity e a cadeia de Account/Opportunity dispara automação, R6); não houve dado de teste a apagar. Não existe `clients/eplast/fixtures/` neste checkout. Não alterei usuário, perfil nem permission set. Nada do Marketing Cloud foi tocado.

## Por que inconclusiva

O critério principal é o Screen Flow na aba "Rascunho IA", e ele **não foi executado de ponta a ponta**:
- Screen Flow não roda por `sf`/API/Apex anônimo (só pela interface, com usuário logado com o PSG).
- Estado real do Flow na dev: v1 **Active** (ainda lê SBQQ e passa `DadosCotacao`, que os templates novos não têm mais) e v2 **Draft** (a versão sem cotação). Exercitar exigiria ativar a v2, passo separado que não me cabe. Mesmo ativada, falta login interativo com o PSG.
- Os casos de acesso (CA-08 negativa de acesso, CA-09 aba oculta e Flow negado), erro do serviço de IA na tela (CA-10) e debug log sem trigger/Flow (CA-11/12) dependem da execução do Flow e ficaram sem prova.

Não há falha de caso executado: o que rodou passou.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | Estado do Flow | Tooling `SELECT VersionNumber, Status FROM Flow WHERE Definition.DeveloperName='Opportunity_Screen_RascunhoComercial'` | v2 Draft, v1 ativa (plano) | v1 Active (`301Ha000016TlxgIAC`), v2 Draft (`301Ha000016VKS0IAO`) | passou (estado conferido; v1 não utilizável até a v2 ser ativada, como o plano avisa) |
| V-02 | Sem cotação na v2 | Grep no arquivo do Flow (branch) | Sem SBQQ, sem DML | 1 ocorrência de "SBQQ", só na descrição; 0 `recordCreates/Updates/Deletes`; `status` Draft | passou (estático, no arquivo; não é a versão salva lida da org) |
| V-03 | CA-14 | Tooling `COUNT()` de Flow `ProcessType='PromptFlow'` | 0 | 0 | passou |
| V-04 | PS sem SBQQ, só leitura | `ObjectPermissions` e `FieldPermissions` de `PS_Comercial_RascunhoIA` na org | Só Opportunity e Account, sem edição | Account e Opportunity: leitura true, edição/criação/exclusão false; 6 campos (Account.Industry, Account.Type, Opportunity.Amount, LeadSource, Probability, Type), todos sem edição; 0 campo SBQQ; 0 objeto SBQQ | passou |
| V-05 | PSG | Consulta `PermissionSetGroup` e atribuições | Existe, status Updated, sem atribuição | `PSG_Comercial_RascunhoIA` Updated; 0 atribuições (nada atribuído por mim) | passou |
| V-06 | CA-01/02/03 (texto) | API de geração de cada template com texto sintético só em `Input:DadosOportunidade` (nome TESTE EPLAST-30, etapa, data 31/12/2026, valor `BRL 1000,50`, conta) | Cita conta, etapa, data de fechamento e valor; sem cotação | Proposta, follow-up e argumentos citaram conta, etapa, `31/12/2026` e `BRL 1000,50` (valor igual ao entregue, sem arredondar); argumentos citam fonte (`Oportunidade.(Etapa)` etc.); lista de campos usados/vazios presente; nenhum bloco de cotação. Tempo 4 a 5 s por chamada | passou (só o template; não o Flow) |
| V-07 | CA-04 | Idem com data e valor como `[dado ausente: ...]` | Marcador no lugar, sem data inventada, lista de vazios | Marcadores mantidos, nada inventado, "Campos vazios" lista data e valor; desconto/prazo/condição ficaram `[a preencher]` | passou (template) |
| V-08 | CA-07 | Contato sintético com e-mail e telefone injetado no texto de entrada | Texto usa `[nome do contato]`, sem e-mail/telefone | Saudação `[nome do contato]`; e-mail e telefone não aparecem nas 3 saídas | passou (template; no Flow o Contact nem é lido, pelo desenho, não executado) |
| V-09 | CA-10 (parcial) | Chamada a template inexistente pela API | Erro claro | `INVALID_ARGUMENT_TYPE: Template Not found` | passou como erro de API; tela de erro do Flow não exercitada |
| V-10 | CA-01 a 04 no Flow | Abrir aba "Rascunho IA" e gerar | Texto na tela em até 15 s | Não executado | não executado |
| V-11 | CA-08 | Usuário sem acesso à oportunidade | Negativa, modelo não chamado | Não executado | não executado |
| V-12 | CA-09 | Usuário sem o PSG | Aba oculta, Flow negado | Não executado | não executado |
| V-13 | CA-10 (tela) | Template desativado, Flow executado | Tela de erro, registro livre | Não executado | não executado |
| V-14 | CA-11/12 | Debug log e contagem de Task/Event | Sem trigger/Flow de gravação; nada criado | Não executado (sem execução do Flow; a dev tem 0 Opportunity) | não executado |
| V-15 | CA-05/06/13 | Preço com cotação, linha da cotação, 50 linhas | Deixam de valer pela decisão de 2026-11-16 (PE-01, PE-04) | Sem cotação no desenho; V-06 confirma o valor da oportunidade | não se aplica |
| V-16 | Página (item 11 do plano) | Grep no arquivo `Opportunity_Record_Page` da branch por `PriorityScore__c` e `PriorityBand__c` | Mantidos | 2 ocorrências no arquivo; a página salva na org não foi relida | passou (arquivo), não conferido na org |

## Observações

- Os textos gerados trazem `[Seu Nome]`, `[Seu Cargo]` e `Eplast` na assinatura. Está dentro da PB-01 do plano (marcadores de remetente) e não reprova.
- O modelo respondeu só ao texto sintético passado; o que o Flow monta nesse texto (fórmula `fDadosOportunidade`) não foi observado em execução.

## O que fica sem prova e o que uma pessoa precisa fazer

1. Quem aprova o PR/release ativa a v2 do Flow na dev (hoje a v1, com cotação, está ativa e não funciona com os templates novos).
2. Atribuir `PSG_Comercial_RascunhoIA` a um usuário de teste com login (o PS não exige mais licença CPQ) e rodar o roteiro `05-roteiro-cliente.md` (C-09 a C-12) numa oportunidade sintética: gerar os 3 rascunhos, ver tempo, tela de negativa para quem não tem acesso, aba oculta sem o PSG, tela de erro e conferência de Task/Event e debug log.
3. Na QA, a v2 chega como Draft e a ativação é manual, junto com os templates e o PS (ordem no plano de build).

## O que pode ter saído da org

Nada. Nenhum registro criado nem automação disparada. Houve 5 chamadas à API de geração de IA da própria org (modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini`) com texto 100% sintético (`TESTE EPLAST-30`, e-mail e telefone fictícios); sem integração externa da cadeia de Account/Opportunity.

## Restauração

Usuário de execução não foi alterado (nenhum campo, permission set ou opção). Nada a devolver.
