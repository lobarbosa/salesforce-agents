**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox QAS da Eplast, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`)

# EPLAST-41 · Testes na QA (rodada 5)

Deploy da esteira: `0AfHa00000EIC7VKAX` (commit `26ef641b`). Preflight lido: sem bloqueios; EPLAST-26, 30 e 40 mexem em componentes vizinhos, sem efeito nos casos executados.

**Resumo.** O critério que faltava na rodada 4 (C2, salvar como Task) foi executado em tela e provado por consulta: uma Task com `WhatId` da conta de teste, `TaskSubtype` = Task, `Status` Open e `Description` com o texto gerado (832 caracteres, começa por "Prezado [nome do contato]"). Os critérios C1 a C5 passaram nesta rodada; C6 a C11 passaram ou foram conferidos como indicado. Dois casos secundários seguem não executados (C7 e C12, ver tabela) e não bloqueiam o aceite. Nenhuma falha aberta.

## Falhas
Nenhuma.

## Falhas da rodada anterior, retestadas
| Falha (rodada 4) | Situação |
|---|---|
| FALHA 1 (crítica): C2 sem prova, "Salvar como tarefa" não marcável | **Corrigida/provada.** Nesta rodada o clique marcou a opção (ferramenta respondeu `radio 'Salvar como tarefa': marcado`) e a Task foi criada. Era instabilidade da ferramenta de tela, não defeito do produto. |

## Ativação feita nesta sessão (regra de 2026-11-16, EPLAST-41)
O deploy `0AfHa00000EIC7VKAX` trouxe versões novas inativas dos dois Flows. Ativei só a versão da demanda: deploy `0AfHa00000EICCLKA5`, só os dois Flows, `status` Active, conteúdo idêntico ao repositório (cópia temporária fora do repo), `--target-org sbx-eplast-qa`. Não commitado.
| Flow | Antes (Tooling `Flow`) | Depois (conferido) |
|---|---|---|
| `Task_Screen_RascunhoRelacionamento` | v3 Active, v4 Draft | **v4 Active** |
| `Opportunity_Screen_RascunhoComercial` | v7 Active, v8 Draft | **v8 Active** |
Ficam ativas ao final. Os três modelos de prompt e `Rascunho_Relacionamento` vieram do deploy; esta rodada não alterou o conteúdo de nenhum.

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Versões ativas | Tooling `Flow` após a ativação | Versões da demanda ativas | Task v4 Active, Opportunity v8 Active | passou |
| C1 Gerar rascunho da conta, em até 30 s, editável/copiável | Conta A de teste, "Rascunho com IA", "Mensagem de relacionamento", Avançar, objetivo sintético, Avançar, espera de 20 s | Texto na caixa editável | Texto "Prezado [nome do contato], Espero que esta mensagem o encontre bem..." na caixa "Texto (edite e copie como precisar)", com o aviso "Rascunho gerado por IA. Revise antes de usar. O envio é feito pelo Marketing Cloud, não por aqui." Screenshot `evidencias/01-ca-01-ca-02-texto-gerado-na-tela-com-sal.jpg` | passou |
| C2 Salvar como Task | Na tela do texto, marcar "Salvar como tarefa", Avançar | Task com `WhatId` = conta, `TaskSubtype` = Task, `Description` = texto, sem `EmailMessage` | `SELECT Subject, WhatId, TaskSubtype, Status FROM Task WHERE Subject LIKE '%(IA)%'` devolveu 1 linha: `Rascunho de relacionamento (IA)`, `WhatId` = Conta A (`001Ha000016ViEXIA0`), `Task`, `Open`. `Description` com 832 caracteres iniciando por "Prezado". `EmailMessage`: 805 antes e 805 depois | passou |
| C3 Nada gravado antes de salvar | `COUNT()` de Task `(IA)` antes de abrir a ação | 0 antes de salvar | 0 antes de iniciar; 1 só depois do "Avançar" com "Salvar como tarefa". Rodada 4 já provou 0 com o texto na tela e "Fechar sem salvar" gravando nada | passou |
| C4 Nenhum envio pelo CRM | `COUNT() FROM EmailMessage` antes e depois da cadeia completa (gerar e salvar) | Sem variação | 805 e 805 | passou |
| C5 Prompt sem dado pessoal | Entradas do prompt no Flow (`fDadosConta`, `fDadosOportunidade`, `Objetivo_Mensagem`) | Sem e-mail, telefone, CPF, nome de contato | Só nome, setor, tipo, cidade e estado da conta; nome, etapa, tipo e datas da oportunidade | passou (metadata, rodada 4, componente inalterado) |
| C6 Textos comerciais sem duplicata | Lista do `05-deploy-qa.md` | Um de cada template | Uma ocorrência de cada | passou |
| C7 Falha do modelo: erro, sem texto, 0 Task | Não provocável na QA | Tela de erro | Tela `Tela_Erro_Geracao` existe no Flow; não exercitada | não executado (secundário) |
| C8 Conta sem oportunidade avisa | Conta B de teste, "Rascunho com IA", "Texto comercial", Avançar | Aviso, sem texto | "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." Screenshot `evidencias/02-c8-conta-sem-oportunidade-caminho-comerc.jpg` | passou |
| C9 SFAgent2 único | `COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou |
| C10 `et4ae5` intacto | Lista do `05-deploy-qa.md` | Nenhum componente | Nenhum | passou (inspeção) |
| C11 Ação visível na Conta | "Mostrar mais ações" nas Contas A e B | "Rascunho com IA" | Aparece | passou |
| C12 Texto comercial com oportunidade, e salvar como Task comercial | Exige PSG comercial (licença CPQ, não atribuível a mim) | Texto e Task | Não exercitado | não executado (secundário; vai ao roteiro do cliente, Teste 4) |

C7 e C12 são secundários: os critérios de aceite principais (gerar, salvar como Task, nenhum envio, prompt sem dado pessoal, sem duplicata) estão provados.

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`) e dados
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
| `PS_Comercial_RascunhoRelacionamento` | não atribuído | atribuído (`0PaHa00000EKB46KAH`) | removido (0 atribuições, conferido) |
Fixture `fixtures/eplast41_dados_teste.apex` rodado: Contas A e B e Oportunidade aberta criadas (a ganha falha por validações de Filial e pagamento, como documentado no README das fixtures). Apagados ao final: 0 contas `TESTE EPLAST-41`, 0 Task `(IA)`; as tarefas "Conta Nova Cadastrada" das contas foram apagadas junto. Usuário de serviço da Konecta não usado. Nenhum registro existente foi lido ou alterado.

## O que pode ter saído da org
Nenhum `EmailMessage` novo (805 antes e depois); nenhuma chamada ao Marketing Cloud; Task `(IA)` criada uma vez e apagada. Uma chamada ao modelo de prompt (texto sintético). A criação das contas disparou a tarefa "Conta Nova Cadastrada" (automação existente), apagada com a conta.
