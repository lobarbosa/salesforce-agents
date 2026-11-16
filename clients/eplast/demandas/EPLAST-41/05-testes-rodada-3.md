**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox QAS da Eplast, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`)

# EPLAST-41 · Testes na QA (rodada 3)

Deploy da QA: `0AfHa00000EIAorKAH` (commit `5f721cf4`). Preflight lido: sem bloqueios; EPLAST-26, 30 e 40 mexem em componentes vizinhos (layout de Opportunity, Flow comercial, templates e PSG da 30), mas nenhum deles afetou os casos executados.

**Resumo.** A FALHA da rodada 2 (tela sem botão de avanço) está corrigida: com a versão da demanda ativa, a tela mostra "Avançar" e chega à tela de objetivo. Mas os dois critérios principais, o texto aparecer na tela em até 30 s (C1) e "Salvar como tarefa" gravar a Task (C2), **não foram executados**, e pelo método isso é reprovação. Não encontrei defeito novo no Flow: a causa é limite da minha ferramenta de tela (ela não digita no campo "Tipo e objetivo da mensagem" nem escolhe item de lista suspensa) somado a uma chamada de teste ao modelo por Apex que falhou nesta sessão. Os dois pontos precisam de prova (build/QA humano), ver "Falhas".

## Ativação feita nesta sessão (regra de 2026-11-16, EPLAST-41)
Deploy `0AfHa00000EIAqTKAX` só dos dois Flows, com `status` Active (conteúdo idêntico ao do repositório), `--target-org sbx-eplast-qa`:
| Flow | Antes (Tooling `Flow`) | Depois |
|---|---|---|
| `Task_Screen_RascunhoRelacionamento` | v1 Active, v2 Draft | v1 Obsolete, **v2 Active** (`FlowDefinitionView.ActiveVersionId` = `301Ha000016VIRkIAO`) |
| `Opportunity_Screen_RascunhoComercial` | v1 e v2 Obsolete, v3 Active, v4 Draft | v3 Obsolete, **v4 Active** (`ActiveVersionId` = `301Ha000016VIRjIAO`) |
Ficam ativas ao final. Não foram commitadas (o repositório segue com `status` Draft).

## Falhas

### FALHA 1 (crítica) — Critérios C1 e C2 sem prova: texto na tela e "Salvar como tarefa" não exercitados
- **Reproduzir:** na QA, conta `TESTE EPLAST-41 Conta A`, "Mostrar mais ações", "Rascunho com IA", "Mensagem de relacionamento", "Avançar", preencher "Tipo e objetivo da mensagem", "Avançar", conferir o texto, "Texto (edite e copie)", escolher "Salvar como tarefa".
- **Obtido:** a tela de objetivo abre (screenshot desta sessão, com "Anterior" e "Avançar"). O campo de objetivo não pôde ser preenchido pela ferramenta de teste (`qa_browser_fill` resolveu o rótulo para o botão de ajuda do campo). Sem objetivo, não se chega à geração, ao texto nem à Task. `Task` com assunto `(IA)`: 0 antes e 0 depois.
- **Prova alternativa que falhou:** Apex anônimo com `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Rascunho_Relacionamento', ...)` e as 3 entradas sintéticas deu `ConnectApiException: Failed to generate Einstein LLM generations response` em 4 tentativas (formatos de entrada variados, com intervalo de 20 s). Na rodada 2 a mesma chamada devolveu 528 caracteres. Pode ser meu formato de entrada ou instabilidade do modelo na QA; não deu para distinguir. **Se for regressão do template na QA, é defeito.**
- **Esperado:** texto na tela em até 30 s, copiável; Task com `WhatId`, `TaskSubtype=Task`, `Description`; nada gravado antes do clique.
- **Para o próximo passo:** quem reteste precisa percorrer essa tela com digitação real (roteiro do cliente, Teste 2 a 4) e confirmar por consulta a Task criada. Se o modelo continuar falhando por Apex com as entradas do Flow (`fDadosConta`, `fDadosOportunidade`, objetivo), investigar a versão ativa do template `Rascunho_Relacionamento` na QA (ver o `activeVersionIdentifier` no XML do repositório, que é o da dev).

## Falhas da rodada anterior, retestadas
| Falha (rodada 2) | Situação |
|---|---|
| FALHA 1: tela "Rascunho com IA" sem botão para avançar | **Corrigida.** Com a v2 ativa, a primeira tela mostra "Avançar"; a de objetivo mostra "Anterior" e "Avançar"; a de conta sem oportunidade mostra "Concluir". |

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes na QA | Tooling em `Flow`; `FlowDefinitionView`; lista do `05-deploy-qa.md` | Existem; versão da demanda ativa | Flows ativados (ver acima). Templates, quick actions, permission sets confirmados nas rodadas anteriores e sem mudança | passou |
| C1 Gerar rascunho da conta em até 30 s, copiável | Tela até objetivo; Apex no template | Texto na tela | Tela avança até objetivo; objetivo não preenchível; Apex falhou (FALHA 1) | **não executado** |
| C2 Salvar como Task | Depende de C1 | Task com `WhatId`, `TaskSubtype=Task`, `Description` | `COUNT()` de Task `(IA)` = 0 | **não executado** |
| C3 Nada gravado antes de salvar | Contagem de Task `(IA)` ao abrir e avançar as telas | 0 | 0 | passou (parcial: só até a tela de objetivo) |
| C4 Nenhum envio pelo CRM | `COUNT() FROM EmailMessage` antes e depois | 805 e 805 | 805 e 805 | passou (parcial, sem a cadeia completa) |
| C5 Prompt sem dado pessoal | Entradas do template e fórmulas do Flow (`fDadosConta`, `fDadosOportunidade`) | Só conta, oportunidade, objetivo | Fórmulas usam nome, setor, tipo, cidade, estado da conta e nome, etapa, tipo, datas da oportunidade; sem e-mail, telefone, CPF, contato | passou (metadata) |
| C6 Textos comerciais sem duplicata | Metadata do deploy | Um de cada | Uma ocorrência de cada template, sem criar nome repetido | passou |
| C7 Falha do modelo: erro, sem texto, 0 Task | Não provocável (exigiria derrubar o modelo) | Tela de erro | Não executado; a tela de erro existe no Flow (metadata) | não executado |
| C8 Conta sem oportunidade avisa | Conta B, "Rascunho com IA", "Texto comercial", "Avançar" | Aviso | "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." e botão "Concluir" (screenshot) | passou |
| C9 SFAgent2 único | `COUNT() FROM BotDefinition WHERE DeveloperName='SFAgent2'` | 1 | 1 (rodada 2, deploy desta rodada não toca agente) | passou |
| C10 `et4ae5` intacto | Lista do deploy | Nenhum componente | Nenhum | passou (inspeção) |
| C11 Ação visível na Conta | Conta A e B, "Mostrar mais ações" | "Rascunho com IA" | Aparece, e abre o fluxo | passou |
| C12 Caminho comercial a partir da Conta/Oportunidade | Conta A, "Texto comercial", "Avançar" | Lista de oportunidades abertas | Chega à tela "Oportunidade aberta da conta" (lista suspensa, "-- Nenhum --"). A ferramenta não escolhe item de lista; PSG comercial exige licença CPQ, não atribuível ao meu usuário | não executado (parcial: tela abre) |

Evidência de tela: screenshots desta sessão, só em registros sintéticos `TESTE EPLAST-41 Conta A` e `Conta B sem oportunidade` (primeira tela com "Avançar"; objetivo com "Anterior/Avançar"; aviso da Conta B).

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`) e dados
| O quê | Antes | Depois | Desfeito |
|---|---|---|---|
| `ProtheusSellerId__c` | vazio | `TESTE41` | voltou a vazio (conferido) |
| `PS_Comercial_RascunhoRelacionamento` | não atribuído | atribuído (`0PaHa00000EJn0EKAT`) | removido (0 atribuições, conferido) |
Fixture `fixtures/eplast41_dados_teste.apex` na QA: Contas A e B e Oportunidade aberta criadas; a ganha falhou (exige Filial com Código ERP, já documentado no `fixtures/README.md`). Tudo apagado ao final (0 contas, 0 oportunidades `TESTE EPLAST-41`). Usuário de serviço da Konecta não usado.

## O que pode ter saído da org
Nenhum `EmailMessage` novo (805 antes e depois); nenhuma chamada ao Marketing Cloud. Quatro chamadas de teste ao modelo por Apex, todas com erro (texto sintético, nada gravado). A criação das contas disparou a tarefa "Conta Nova Cadastrada" (automação existente), apagada com a conta. Nenhuma Task `(IA)` criada.
