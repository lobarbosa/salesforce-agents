# Testar a tela de verdade (`qa_browser_*`)

Guia do agente `qa`. Leia quando algum critério de aceite se confere pela tela.

Ferramentas pra clicar na Lightning de verdade em vez de só escrever roteiro pra alguém
seguir depois:

1. `qa_browser_open(target_org, path)` abre a sessão — recusa sozinho se `target_org` não
   passar no guardrail de sandbox, então não precisa checar isso antes. Se a sandbox de QA
   do cliente ainda não conecta (ou a ferramenta recusar por qualquer outro motivo), não
   insista: caia pro roteiro escrito pra humano, como sempre foi feito. Isso não é reprovação
   do teste, é o caminho normal enquanto a sandbox não existe.
2. `qa_browser_click`/`qa_browser_fill` interagem com a página da sessão aberta — não aceitam
   URL, só texto/rótulo visível na tela atual. Em opção de rádio e caixa de seleção, o clique
   diz se a opção ficou marcada: se disser que não ficou, registre isso como limite da
   ferramenta, não como defeito da tela.
3. `qa_browser_screenshot(session_id, legenda)` guarda a captura em
   `demandas/<DEMAND-ID>/evidencias/` e devolve o nome do arquivo: cite-o no caso
   correspondente de `05-testes.md`. A `legenda` diz o que a tela prova ("CA-03: rascunho
   gerado para a conta de teste"). O Squad OS junta `05-testes.md` e as capturas no anexo
   **"Evidências de teste"** do card, em PDF, ao lado do roteiro do cliente: tire uma
   captura por critério que se confere pela tela, sem repetir (no máximo 12 por rodada).
   **Nunca screenshote um registro
   real de cliente** (guardrail #2, LGPD) — só dados de teste que você mesmo criou para o
   roteiro. Se a tela que precisa testar só existe com dado real, documente isso como "não
   pôde ser testado via UI" em vez de abrir o registro.
4. `qa_browser_close` sempre no fim, mesmo depois de um erro — não deixe sessão aberta.
