# Análise da Demanda SOMOSAGILITY-28
Acesso de colaborador ao objeto "Solicitação de Treinamento" (sustentação)

## Contexto de Negócio

Um colaborador da Somos Agility não consegue acessar o objeto "Solicitação de Treinamento" no Salesforce. A demanda não traz a mensagem de erro, a org nem o que o colaborador tentou fazer.

No card, a equipe registrou em 2026-11-11 18:19: "Realizado o acesso para o perfil do usuário." Esse comentário diz que alguém mexeu no acesso, mas não diz:
- em qual org a mudança foi feita (dev, QA ou produção);
- o que foi alterado (perfil, permission set, licença ou outra coisa);
- se o colaborador confirmou que resolveu.

Portanto, o status atual é "possivelmente resolvido por ajuste manual, não validado". Não é um problema resolvido de forma sustentável.

Tipo: sustentação (bug/acesso). Escopo do fluxo: etapas 1, 2, 3 (design enxuto), 4, 5 e 7.

Fonte: `demandas/SOMOSAGILITY-28/demanda.md` e `demandas/SOMOSAGILITY-28/comentarios-do-card.md`.

## Objetivo

Garantir que o colaborador consiga usar o objeto "Solicitação de Treinamento" com o nível de acesso que o solicitante definir. A correção precisa ser reproduzível e não pode depender de edição manual de um perfil de uso individual.

## Histórico do cliente (RAG)

A consulta ao RAG de delivery funcionou. Ela não encontrou nada específico sobre SOMOSAGILITY-28 ou sobre "Solicitação de Treinamento". Achados relacionados:

- `[demandas/SOMOSAGILITY-4/demanda.md]`: pedido de criação de acesso no padrão "usuário espelho" (novo usuário com o mesmo acesso de um usuário existente). Hipótese a validar: o "acesso realizado" pode ter copiado o perfil de outro usuário. Isso ainda não foi confirmado.
- `[demandas/SOMOSAGILITY-2/01-analise.md]`: pedido de criação de usuários que parou porque produção está fora do escopo do agente (guardrail #1) e porque o ambiente citado ("HML (AW)") não estava mapeado no briefing do cliente. Consequência para esta demanda: se a org real for produção, a execução e a validação final ficam com o humano; e o `CLAUDE.md` do cliente ainda tem placeholders de URL e versão de API nas sandboxes.

## Riscos do assessment que tocam este pedido

Fonte: `clients/somos-agility/assessment.md`, saúde geral vermelho, data 2026-09-30, medido na sandbox `sbx-somos-agility-dev`.

- **Perfil por pessoa (achado #6, severidade média):** 26 perfis estão em uso por 38 usuários ativos, e 20 desses perfis têm exatamente 1 usuário ativo. Este pedido cai exatamente nesse padrão: "acesso para o perfil do usuário" muito provavelmente significa editar um perfil de uso individual.
  - **Ajuste pontual:** cria ou mantém mais um perfil de uso único com permissão diferente. Aumenta a superfície de manutenção (perfil + permission set) e torna "quem pode ver este objeto" mais difícil de responder.
  - **Correção sustentável:** conceder o acesso por permission set atribuído ao usuário, sem alterar o perfil dele. Essa é a direção recomendada pelo assessment.
  - **Fora do escopo desta demanda:** migrar os 20 perfis de um usuário para perfil-base + permission set. Deve virar demanda própria, se o cliente quiser.
- **Dados do assessment:** a medição é da sandbox de dev, com 0 registros e sem massa de dados. Os números de usuários e perfis podem não bater com produção. Não usar o achado #6 como prova do que existe em produção.
- **Cobertura de teste Apex em 40% (achado #3) e 30 classes sem teste dedicado (achado #4):** se a correção for só metadata (permission set, sem código), o risco é baixo. Se a recon encontrar trigger ou Apex no objeto, a correção passa a exigir teste dedicado, e isso precisa ser dito no design.
- **Licenças em 29 de 30 usadas (achado #9, snapshot de dev):** se o colaborador tiver licença diferente da necessária para o objeto, o ajuste de perfil não resolve. Verificar na recon.
- **Automação concentrada em Oportunidade (achado #1):** não há evidência de que "Solicitação de Treinamento" tenha automação. O assessment não mediu objetos custom um a um. A recon precisa confirmar isso antes do design.

## Regra de Negócio

Regra inferida da demanda (a confirmar):
- Um colaborador ativo deve conseguir acessar os registros de "Solicitação de Treinamento" conforme o nível de acesso definido pelo solicitante.
- O acesso deve seguir o princípio do menor privilégio: sem permissão além da necessária para o colaborador.

Nenhuma regra de negócio específica foi enunciada pelo consultor. Qualquer detalhe, como quem pode criar, editar ou excluir, é premissa pendente.

## Critérios de Aceite

```gherkin
Cenário: Colaborador acessa o objeto no nível acordado
  Dado o usuário do colaborador ativo na org de destino
  E o nível de acesso acordado com o solicitante (premissa P2 em aberto)
  Quando o usuário abre a aba ou a lista de "Solicitação de Treinamento"
  E cria ou visualiza um registro, conforme o nível acordado
  Então nenhuma mensagem de "Insufficient privileges" ou de aba indisponível aparece
  E o teste é feito em sandbox com o usuário de teste, sem screenshot de registro real (guardrail #2)
  E o resultado é registrado em 05-testes.md

Cenário: Acesso concedido sem editar o perfil do usuário
  Dado a correção aplicada em sandbox
  Quando o metadata do perfil do usuário é comparado com a baseline
  Então o perfil não ganha nenhuma permissão nova de objeto
  E o acesso vem de um permission set atribuído ao usuário, com nome que descreve o acesso
  (esta regra depende da decisão de design; se o gate do arquiteto escolher outro caminho, reescrever antes do build)

Cenário: Nenhum outro usuário ganha acesso por causa da mudança
  Dado o snapshot da lista de usuários ativos com acesso ao objeto, tirado antes da mudança
  Quando a correção é aplicada
  Então a diferença entre antes e depois contém apenas o usuário-alvo

Cenário: Causa do bloqueio registrada com evidência
  Dado a investigação em sandbox com comandos somente leitura
  Então 02-recon.md registra a causa (permissão de objeto, de campo, aba, compartilhamento, licença, usuário inativo ou outra), com a evidência de metadata
  E nenhum dado de registro aparece no documento

Cenário: Encerramento depende de confirmação do solicitante
  Dado a correção validada em QA
  Quando o solicitante confirma no card que o colaborador consegue usar o objeto
  Então a demanda pode ser encerrada
  E sem essa confirmação, o comentário "Realizado o acesso" não fecha a demanda
```

## O Que a Demanda NÃO Diz (Premissas a Validar)

Tudo abaixo está pendente. Nenhum item foi assumido como verdade.

### Crítico para o design

**P1. Em qual org o "acesso realizado" foi feito?**
- O comentário não diz se foi em produção, QA ou dev. O colaborador é um usuário real do cliente, então o mais provável é produção.
- Implicação: se for produção, a mudança já existe fora da esteira, e não há PR nem registro de metadata. O agente não pode inspecionar nem alterar produção (guardrail #1). A inspeção de produção fica com o humano responsável, com metadata exportada, sem dados de registro.

**P2. Qual é o nível de acesso esperado?**
- Ler, criar, editar, excluir? Para todos os registros ou só para os próprios? A demanda não diz.
- Implicação: sem isso, não há critério de aceite testável além de "não aparece erro".

**P3. Qual é a mensagem ou sintoma exato?**
- "Insufficient privileges" ao abrir a aba? Aba ausente no menu? Registros não aparecem na lista? Erro ao criar? A causa muda completamente conforme o sintoma.

**P4. O objeto "Solicitação de Treinamento" existe com que nome de API?**
- Não confirmado. Não sei se é objeto standard, custom (`__c`) ou de pacote gerenciado. Não confirmei via `sf` nesta etapa (sem acesso à org nesta sessão).
- Implicação: o recon (etapa 2) precisa confirmar via `sf sobject describe` antes de qualquer referência a campo ou permissão.

**P5. Qual é o perfil e o conjunto de permission sets do colaborador hoje?**
- Não sabemos o estado atual nem o que foi alterado no "acesso realizado".
- Hipótese (RAG, SOMOSAGILITY-4): o ajuste pode ter copiado o perfil de outro usuário. Não confirmado.

**P6. O que exatamente o comentário "Realizado o acesso para o perfil do usuário" fez?**
- Quem fez, quando, em qual org, o que mudou (perfil, permission set, licença, grupo) e se foi revertido depois. Sem isso, não há como validar nem reproduzir.

**P7. A causa é só de permissão de objeto?**
- Pode ser também: permissão de campo, aba fora do app, regra de compartilhamento (OWD ou regra de compartilhamento), licença incompatível, usuário inativo, perfil de login fora do horário ou da faixa de IP, ou record type sem acesso. O assessment não mediu OWD por objeto (ver "Não pôde ser medido" no assessment).

**P8. O problema é isolado ou afeta outros colaboradores?**
- Se for recorrente, a causa provavelmente é o modelo "perfil por pessoa" e a conversa muda de escopo (ver riscos do assessment).

**P9. Existe trigger, Flow ou Apex no objeto?**
- Não confirmado. O assessment não cobre objetos custom individualmente. Se houver, o design precisa tratar a parte de código e o teste dedicado.

**P10. A correção deve ser em permission set ou o solicitante aceita o ajuste pontual de perfil?**
- Esta é uma decisão de arquitetura e de governança. Não escolho por conta própria: a recomendação é permission set (ver riscos), mas o humano decide.

### Contexto do cliente

**P11. Quem aprova concessão de acesso no cliente?**
- Existe fluxo de aprovação de acesso (gestor, RH, segurança da informação)? A demanda não diz quem autorizou o acesso que foi "realizado".

**P12. Qual é a severidade e o prazo?**
- Sem isso, não há como usar o SLA por severidade do contrato AMS.

**P13. Os dados do registro de treinamento têm dado pessoal?**
- Se sim, o recon e os testes só trabalham com metadata e contagens agregadas (guardrail #2). Confirmar com o consultor que nenhum print com dado real será anexado sem a liberação de delivery.

**P14. O `CLAUDE.md` do cliente tem placeholders.**
- Os campos de URL e versão de API das sandboxes ainda estão em branco no briefing. Precisa estar preenchido antes do build (mesma lacuna do SOMOSAGILITY-2).

## Estimativa de Complexidade

**Pequena (P)** — o pedido é de um usuário e um objeto; a correção esperada é conceder acesso por permission set, sem código. Escala para **Média (M)** se a recon achar trigger ou Apex no objeto, ou se a causa for compartilhamento ou licença, ou se P8 mostrar que o problema é recorrente (aí entra a migração de perfis).

## Estimativa de esforço humano

**Estimativa de esforço:** 1–5 h

Premissas que mais pesam na faixa:
- Limite inferior (~1 h): a correção já está feita em produção e o trabalho é validar com o colaborador, registrar a causa e documentar o que foi feito.
- Limite superior (~5 h): a correção precisa ser refeita como permission set, validada em dev e QA, e promovida pelo release, com recon completa de compartilhamento e licença.
- Não inclui tempo do agente. Se P8 indicar problema recorrente, a faixa não vale mais e precisa de nova análise.

## Próximos Passos Bloqueantes

O humano responsável precisa responder antes do gate desta análise:

1. Confirmar a org onde o "acesso realizado" foi feito (P1) e quem fez, o que mudou e se o colaborador confirmou (P6).
2. Informar o sintoma exato, com a mensagem de erro em texto (sem dado de registro) (P3), e o nível de acesso esperado (P2).
3. Dizer se o problema é isolado ou recorrente (P8), e quem autoriza o acesso (P11).
4. Escolher o caminho:
   - **Opção A:** validar o acesso já concedido, registrar a causa e fechar com documentação. Não há correção sustentável nesse caso, só o registro.
   - **Opção B:** refazer a correção como permission set, em dev, promover para QA e homologar com o solicitante. Esta é a recomendação, mas a escolha é do humano.
5. Depois do gate desta análise: recon (etapa 2, read-only, só em `sbx-somos-agility-dev`) para confirmar P4, P7 e P9 via `sf`, e design enxuto (etapa 3) com a decisão do arquiteto.

---

**Análise pronta. Preciso da sua validação antes de acionar o arquiteto.**
