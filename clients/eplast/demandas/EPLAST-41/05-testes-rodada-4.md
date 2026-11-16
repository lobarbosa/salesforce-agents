**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox QAS da Eplast, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`)

# EPLAST-41 · Testes na QA (rodada 4)

Deploy da QA: `0AfHa00000EIBUnKAP` (commit `3cb1c135`). Preflight lido: sem bloqueios; EPLAST-26, 30 e 40 mexem em componentes vizinhos, sem efeito nos casos executados.

**Resumo.** Pela primeira vez o caminho feliz de tela rodou de ponta a ponta até o texto: a ação "Rascunho com IA" na conta abriu, aceitou o objetivo digitado e mostrou o texto gerado, e "Fechar sem salvar" não gravou nada. O critério C2 (**Salvar como tarefa gera a Task**) **não foi executado**: a ferramenta de tela não consegue marcar a opção "Salvar como tarefa" (botão de rádio do Flow). Pelo método, critério principal não executado é reprovação. Não há defeito de produto identificado; é limite da automação de tela, então a prova precisa ser feita por uma pessoa (roteiro do cliente, Teste 3) ou por outra via.

## Ativação feita nesta sessão (regra de 2026-11-16, EPLAST-41)
Deploy `0AfHa00000EIBWPKA5`, só os dois Flows, `status` Active (conteúdo idêntico ao repositório), `--target-org sbx-eplast-qa`:
| Flow | Antes (Tooling `Flow`) | Depois |
|---|---|---|
| `Task_Screen_RascunhoRelacionamento` | v2 Active, v3 Draft | v2 Obsolete, **v3 Active** |
| `Opportunity_Screen_RascunhoComercial` | v6 Active, v7 Draft | v6 Obsolete, **v7 Active** (v7 = EPLAST-30 mais a saída `varTextoGerado`) |
Ficam ativas ao final; não foram commitadas.

## Falhas

### FALHA 1 (crítica) — Critério C2 sem prova: "Salvar como tarefa" não exercitado
- **Reproduzir:** QA, `TESTE EPLAST-41 Conta A`, "Mostrar mais ações", "Rascunho com IA", "Mensagem de relacionamento", "Avançar", objetivo, "Avançar", na tela do texto marcar "Salvar como tarefa", "Avançar".
- **Obtido:** `qa_browser_click` em "Salvar como tarefa" devolveu "Clicking the checkbox did not change its state" (duas tentativas); a opção ficou em "Fechar sem salvar" e a tela final foi "Nada foi gravado." Task `(IA)`: 0 antes e 0 depois. Na segunda sessão o mesmo erro apareceu até no rádio "Mensagem de relacionamento" (que na primeira funcionou), ou seja, o clique em rádio do Flow é instável na ferramenta.
- **Esperado:** Task com `WhatId` = conta, `TaskSubtype` = Task, `Description` = texto, sem `EmailMessage`.
- **Evidência indireta (não substitui a execução):** no XML do Flow, `Criar_Task` grava `WhatId=varWhatId` (recordId), `TaskSubtype=Task`, `Description=TextoFinal`, `Status=Open`, `Subject` constante `Rascunho de relacionamento (IA)`; único `recordCreates` é Task.
- **Para o próximo passo:** execução humana do Teste 3 do roteiro e consulta da Task criada; ou teste em tela com ferramenta que marque rádio por rótulo. Se a pessoa que executar o roteiro confirmar a Task, não há correção de build a fazer.

## Falhas da rodada anterior, retestadas
| Falha (rodada 3) | Situação |
|---|---|
| FALHA 1: C1 e C2 sem prova (objetivo não preenchível; modelo falhando por Apex) | **C1 corrigida/provada**: o objetivo foi preenchido em tela e o texto apareceu ("Prezado [nome do contato], Espero que esta mensagem o encontre bem..."), em menos de 20 s entre o "Avançar" e a conferência. **C2 continua sem prova** (FALHA 1 acima). |

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes e versões | Tooling `Flow`, deploy `0AfHa00000EIBWPKA5` | Versões da demanda ativas | Task v3 Active, Opportunity v7 Active | passou |
| C1 Gerar rascunho da conta, texto na tela em até 30 s, editável/copiável | Conta A, ação "Rascunho com IA", "Mensagem de relacionamento", objetivo sintético, "Avançar", screenshot após ~15 s | Texto na caixa "Texto (edite e copie como precisar)" | Texto exibido, caixa editável, aviso "Rascunho gerado por IA. Revise antes de usar. O envio é feito pelo Marketing Cloud, não por aqui." (screenshot) | passou |
| C2 Salvar como Task | Ver FALHA 1 | Task com `WhatId`, `TaskSubtype=Task`, `Description` | 0 Task `(IA)`; opção não marcável pela ferramenta | **não executado** |
| C3 Nada gravado antes de salvar | `COUNT()` Task `(IA)` com o texto na tela; depois "Avançar" em "Fechar sem salvar" | 0 e tela "Nada foi gravado." | 0 com o texto na tela; 0 ao fim; tela "Nada foi gravado." | passou |
| C4 Nenhum envio pelo CRM | `COUNT() FROM EmailMessage` antes e depois | 805 e 805 | 805 e 805 | passou (sem a cadeia de salvar) |
| C5 Prompt sem dado pessoal | Fórmulas `fDadosConta`, `fDadosOportunidade` no XML | Só dados de conta e oportunidade | Nome, setor, tipo, cidade, estado da conta; nome, etapa, tipo, datas da oportunidade; sem e-mail, telefone, CPF, contato | passou (metadata) |
| C6 Textos comerciais sem duplicata | Lista do deploy | Um de cada | Uma ocorrência de cada template | passou |
| C7 Falha do modelo: erro, sem texto, 0 Task | Não provocável | Tela de erro | A tela `Tela_Erro_Geracao` existe no Flow ("Não foi possível gerar o texto agora...") | não executado |
| C8 Conta sem oportunidade avisa | Aprovado na rodada 3 com a mesma versão do Flow de conta; nesta rodada não reexecutado | Aviso | Não reexecutado (Flow v3 mudou só de versão) | não executado nesta rodada (passou na 3) |
| C9 SFAgent2 único | `COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 | passou |
| C10 `et4ae5` intacto | Lista do `05-deploy-qa.md` | Nenhum componente | Nenhum | passou (inspeção) |
| C11 Ação visível na Conta | "Mostrar mais ações" na Conta A | "Rascunho com IA" | Aparece | passou |
| C12 Caminho comercial pela Conta/Oportunidade | Exige PSG comercial (licença CPQ, não atribuível a mim) | Lista de oportunidades abertas | Não exercitado | não executado |

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`) e dados
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
| `PS_Comercial_RascunhoRelacionamento` | não atribuído | atribuído (`0PaHa00000EK6xHKAT`) | removido (0 atribuições, conferido) |
Fixture `fixtures/eplast41_dados_teste.apex`: Contas A e B e Oportunidade aberta criadas; apagadas ao final (0 contas `TESTE EPLAST-41`, conferido), junto com as tarefas "Conta Nova Cadastrada" delas. Usuário de serviço da Konecta não usado.

## O que pode ter saído da org
Nenhum `EmailMessage` novo (805 antes e depois); nenhuma chamada ao Marketing Cloud; nenhuma Task `(IA)`. Uma chamada ao modelo de prompt (texto sintético, não gravado). A criação das contas disparou a tarefa "Conta Nova Cadastrada" (automação existente), apagada com a conta.
