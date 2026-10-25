# SOMOSAGILITY-14 — Testes (QA)

- Cliente: somos-agility
- Demanda: Erro fluxo de reembolso - Usuario Simone (sustentação / bug)
- Executado por: agente `qa`
- Data: 2026-10-25
- Base dos casos: critérios de aceite de `01-analise.md` (seção 4) e `03-design.md` (seção 8) —
  não o que foi construído, porque **nada foi construído** (ver seção "Achados" abaixo).

---

## ATENÇÃO — leia antes da tabela de casos

**A homologação desta demanda não pôde ser executada.** Dois motivos independentes, cada um
suficiente sozinho para bloquear este gate, e os dois se confirmaram:

1. **Não existe build para homologar.** `04-plano-build.md` registra explicitamente: "Nada foi
   alterado na sandbox. Nenhum commit de metadata foi feito. Nenhum PR foi aberto." — porque a
   pergunta P5 (qual dos 4 Approval Process deve incluir a usuária reportante) nunca foi
   respondida. Confirmei isso eu mesmo, de forma independente do que o artefato diz:
   - Não existe diretório `force-app/` para `somos-agility` em lugar nenhum do repositório
     (`find . -iname "force-app" -maxdepth 4` a partir da raiz do repo só encontra
     `clients/acxya/force-app`).
   - `git log` da branch `feature/SOMOSAGILITY-14` não tem nenhum commit de metadata — só commits
     de artefato de etapa (`analise via CI`, `design via CI`, `sessão via CI`, `build via CI`, este
     último é a *gravação do artefato* `04-plano-build.md`, não um deploy).
   - Retrievei eu mesmo (leitura, nada escrito na org) o Approval Process
     `Reembolso_Comercial_pre_vendas_e_CS` de `sbx-somos-agility-dev` e contei os `criteriaItems`
     do `entryCriteria` de nível de processo (o que decide quem entra no processo, não o de cada
     etapa): **13**, campo `CreatedBy`, exatamente o mesmo número que `02-recon.md` já registrava em
     2026-10-19. Nenhum critério novo foi adicionado desde o recon. Não copiei nenhum nome de
     usuário para este artefato (guardrail #2) — só a contagem.
   - Conclusão: a correção descrita em `03-design.md` (seção 3 — acrescentar 1 `criteriaItems`
     `CreatedBy equals <nome da usuária>`) **não existe em nenhuma org acessível nesta sessão**.

2. **A sandbox de QA do cliente não está conectada.** `sf org list` nesta sessão mostra:

   | Tipo | Alias | Org Id | Status |
   |------|-------|--------|--------|
   | Sandbox | `sbx-somos-agility-dev` | `00DHa0000070wxfMAA` | Connected |

   Só `sbx-somos-agility-dev` aparece. `sbx-somos-agility-qa` não está conectada. O
   `clients/somos-agility/CLAUDE.md` confirma isso de forma independente: a seção de sandboxes da
   esteira ainda tem os dois ambientes como placeholder (`<instance url>`), ou seja, a QA deste
   cliente nunca chegou a ser configurada de fato. Pelo guardrail #1 desta etapa, o roteiro abaixo
   tem que rodar contra `sbx-somos-agility-qa`, nunca contra `sbx-somos-agility-dev` — então, mesmo
   que a correção existisse, eu não substituiria o ambiente. Por isso **não usei nenhuma ferramenta
   `qa_browser_*`** (elas abrem navegador contra uma org real) e não fiz login em nenhuma org além
   da leitura read-only já conectada.

**Os dois motivos se confirmam ao mesmo tempo: não há o quê testar, e não há onde testar.**

### Recomendação para o humano que for homologar este gate

O histórico (`status.yaml`/`gates.md`) mostra que Leonardo Barbosa aprovou o gate
`aguardando_gate_build` em 2026-10-25T01:12:47Z, movendo a demanda para `qa` — mas
`04-plano-build.md`, aprovado nesse mesmo momento (hash do gate bate com o artefato atual), já
dizia explicitamente "A demanda não deve avançar para o próximo gate (QA) enquanto P5 não for
respondida." Minha leitura é que o gate foi aprovado sem que o conteúdo do artefato bloqueante
fosse levado em conta — o artefato que foi "aprovado" é, ele mesmo, um registro de bloqueio, não
um plano de build concluído.

Recomendo que esta demanda **volte para a etapa `build`** assim que P5 for respondida (ou para
`design`, se a resposta mudar a decisão declarativo tomada em `03-design.md` seção 2 — o que não
parece ser o caso, já que a mudança continua sendo "configuração de Approval Process"). QA não tem
nada de real para homologar enquanto isso não acontecer. A decisão de reverter o estágio, porém, é
sua — não do agente.

Vale notar também, só para visibilidade e não para decisão do QA: `04-plano-build.md` seção 5
registra dois comentários do cliente (15/10 e 20/10, com fluxograma anexo) pedindo revisão de todo
o fluxo de reembolso dos usuários "gerente de contas" e uma correção estrutural do processo — algo
que `03-design.md` seção 6 já havia escopado como fora desta demanda pontual. Se esse pedido mais
amplo prosseguir, pode ser necessário abrir uma demanda nova em vez de ampliar esta.

---

## O que os dois anexos liberados confirmam (sem dado pessoal)

- **`qz10kg-Fluxo-de-solicitacao-e-aprovacao-de-reembolso.jpg`**: fluxograma do processo de
  reembolso em termos de papéis (Solicitante, Gerente de Projeto/Grupo GP, Gestor/Aprovador de
  Reembolso, Financeiro/Grupo Operações) e regras gerais (PIN obrigatório, exigência de ao menos 1
  Lançamento de Despesa, campos obrigatórios de projeto quando "Relacionado à Entrega" = Projeto,
  campos "Pago"/"Data do Pagamento" obrigatórios para a aprovação do Financeiro). **Não cita nenhum
  dos 4 Approval Process pelo nome** — não resolve P5.
- **`ouwmym-Fluxo-reembolso.docx`**: versão simplificada do mesmo fluxograma, em texto/ASCII, sem
  informação adicional relevante para os critérios de aceite ou para P5.

Nenhum dos dois traz nome, e-mail, CPF, telefone ou valor de cliente — nada foi omitido no
resumo acima por precisar.

---

## Roteiro de teste (para rodar quando o build existir de verdade, em `sbx-somos-agility-qa`)

Derivado dos critérios de aceite de `01-analise.md` (seção 4) e da versão com metadata confirmada
de `03-design.md` (seção 8). Pré-requisito de todos os casos: P5 respondida (AP correto escolhido)
e a mudança (1 `criteriaItems` novo no `entryCriteria` de nível de processo do AP escolhido)
implantada em `sbx-somos-agility-qa`.

| # | Caso | Passos | Esperado |
|---|------|--------|----------|
| 1 | Envio bem-sucedido para aprovação (caminho feliz) | 1. Logar como a usuária reportante (ou usuário de teste com o mesmo perfil/papel dela). 2. Criar uma Solicitação de Reembolso em rascunho com pelo menos 1 Lançamento de Despesa. 3. Acionar "Enviar para aprovação". | `Status__c` = Pendente; `Status_de_Aprovacao_e_Etapas__c` = "Pendente - Gerente de Projetos" ou "Pendente - Gestor" (depende de haver Lançamento relacionado a Projeto); é criado um `ProcessInstance` para a SR; nenhuma mensagem de erro é exibida. |
| 2 | Regressão do defeito original | Reproduzir o mesmo cenário relatado por Simone (criar SR como usuária antes fora de todos os critérios de entrada, enviar para aprovação). | O erro "Nenhum processo de aprovação aplicável foi encontrado" (hipótese H1 de `03-design.md`) não ocorre mais para essa usuária. |
| 3 | Solicitantes já cobertos continuam funcionando | Enviar uma SR criada por um dos usuários que já estava no critério de entrada do AP alterado antes da mudança (sem usar dado pessoal — só confirmar pelo comportamento). | Mesmo resultado de antes da mudança: SR segue para a mesma cadeia de aprovação, sem regressão. Serve para confirmar que o diff (1 critério novo + `booleanFilter` estendido) não quebrou nada para quem já estava coberto. |
| 4 | Dado obrigatório ausente continua bloqueado | Tentar enviar uma SR sem Lançamento de Despesa, ou sem PIN, ou (se "Relacionado à Entrega" = Projeto) sem Projeto Relacionado preenchido. | Envio recusado; mensagem indica o campo a corrigir (regra geral 2/3/validação importante do fluxograma); SR continua em Rascunho. |
| 5 | Permissão — não enviar SR de outro usuário | Com um usuário diferente do owner, tentar acionar "Enviar para aprovação" numa SR que não é dele. | Ação indisponível ou recusada com mensagem de permissão (`allowedSubmitters = owner`, confirmado no recon); nenhum dado da SR é alterado. |
| 6 | Conflito de automação (R1 do design) | Repetir o caso 1 e conferir especificamente se o trigger `TrgSolicitacaoReembolso`, os Flows `Email_Gestor_4`, `Status_Etapa_Aprova_o_Gestor` e `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` (todos no mesmo objeto/evento) não geram erro ao rodar em cadeia durante o envio. | `Status__c` e `Status_de_Aprovacao_e_Etapas__c` ficam preenchidos sem erro; nenhuma validation rule (`PIN`, `Aprovar_Vencido_Gestor`, `Reembolso_Vencido`) dispara indevidamente. |
| 7 | H2 — aprovador dinâmico vazio (se aplicável) | Se a etapa seguinte usa `aprovadorCordGerente__c` (relatedUserField) e o `Contact.AprovadorReembolso__c` do solicitante estiver vazio, enviar a SR. | Documentar se ocorre erro de "próximo aprovador vazio" — isso indicaria H2 do design como causa adicional, fora do escopo desta correção pontual (é ação cadastral do admin do cliente, registrada como P7 em `03-design.md`). |
| 8 | Volume / limite de critérios | Conferir, no XML do AP alterado, que o número de `criteriaItems` no `entryCriteria` de nível de processo ficou em N+1 (o maior hoje, antes da mudança, é 13 em `Reembolso_Comercial_pre_vendas_e_CS`) e segue abaixo do limite de 25 citado em `03-design.md` seção 3. | `criteriaItems` = N+1, dentro do limite; `booleanFilter` estendido corretamente para incluir o novo índice com OR. |

Observação de volume: o escopo desta correção é um único critério adicional em um único Approval
Process — não há cenário de carga/volume de dados a testar além do item 8 (limite estrutural do
AP).

---

## O que foi de fato verificado nesta sessão (tudo read-only)

| Verificação | Método | Resultado |
|---|---|---|
| Orgs conectadas nesta sessão | `sf org list` | Só `sbx-somos-agility-dev`. `sbx-somos-agility-qa` não conectada. |
| Existência de `force-app/` para somos-agility | `find` a partir da raiz do repositório | Não existe (só existe para `clients/acxya`). |
| Commits de metadata na branch `feature/SOMOSAGILITY-14` | `git log --oneline` | Nenhum — só commits de artefato de etapa (análise, design, sessão, build-como-registro-de-bloqueio). |
| Estado atual do Approval Process `Reembolso_Comercial_pre_vendas_e_CS` em `sbx-somos-agility-dev` | `sf project retrieve start` (metadata, para diretório temporário fora do repo, removido depois) + contagem de `criteriaItems` no `entryCriteria` de nível de processo | 13 critérios `CreatedBy`, igual ao número registrado em `02-recon.md` (2026-10-19). Nenhum critério novo. Nenhum nome de usuário foi lido para este relatório — só a contagem. |
| Anexos liberados (`anexos/`) | `Read` (imagem) e extração de texto do XML interno do `.docx` (sem copiar o arquivo para fora da pasta) | Confirmam o fluxo por papéis, não resolvem P5. Sem dado pessoal. |

Nenhuma consulta trouxe CPF, e-mail, telefone ou valor de cliente. Nenhuma escrita foi feita em
nenhuma org. Nenhuma ferramenta `qa_browser_*` foi usada, porque a sandbox de QA não está
conectada (guardrail #1 desta etapa — não substituir por dev).

---

## Tabela de casos — status

| Caso | Passos | Esperado | Obtido | Status |
|------|--------|----------|--------|--------|
| 1. Envio bem-sucedido | ver roteiro acima | ver roteiro acima | Não executado — não há correção implantada em nenhuma org, e a sandbox de QA não está conectada | **Não testado** |
| 2. Regressão do defeito original | ver roteiro acima | ver roteiro acima | Não executado, pelo mesmo motivo. Indício indireto: confirmei que o `entryCriteria` do AP candidato segue com 13 critérios, sem o nome da usuária — ou seja, o defeito, se for H1, continua reproduzível hoje, mas não acionei a UI para confirmar a mensagem de erro | **Não testado** |
| 3. Solicitantes já cobertos continuam | ver roteiro acima | ver roteiro acima | Não executado | **Não testado** |
| 4. Dado obrigatório ausente | ver roteiro acima | ver roteiro acima | Não executado | **Não testado** |
| 5. Permissão — outro usuário | ver roteiro acima | ver roteiro acima | Não executado | **Não testado** |
| 6. Conflito de automação (R1) | ver roteiro acima | ver roteiro acima | Não executado | **Não testado** |
| 7. H2 — aprovador dinâmico vazio | ver roteiro acima | ver roteiro acima | Não executado | **Não testado** |
| 8. Limite de critérios no AP | Conferir XML do AP alterado | `criteriaItems` = N+1, abaixo de 25 | Não há AP alterado para conferir; o AP candidato (`Reembolso_Comercial_pre_vendas_e_CS`) está hoje em 13, inalterado desde o recon | **Não testado** |

Nenhum caso foi marcado como "passou" ou "falhou" porque nenhum foi executado de verdade contra
uma correção implantada. Marcar diferente disso seria inventar resultado — o mesmo princípio do
guardrail #3, estendido a resultado de teste.

---

## Critérios de aceite não testáveis nesta sandbox, e por quê

Todos os critérios de `01-analise.md` seção 4 e `03-design.md` seção 8 caem nesta categoria pelos
dois motivos já expostos: (a) a correção nunca foi construída/implantada em nenhuma org
(`04-plano-build.md` é explícito sobre isso, e eu confirmei de forma independente) e (b) a sandbox
de QA do cliente não está conectada nesta sessão, nem configurada no `CLAUDE.md` do cliente.

---

Testes executados. Preciso da sua homologação para liberar o release.
