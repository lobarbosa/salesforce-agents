# SOMOSAGILITY-9 — Análise (etapa 1, ba-discovery)

- **Cliente:** somos-agility
- **Demanda:** SOMOSAGILITY-9 — "Erro na ECT - Exceção Comercial p/ Atendimento Técnico"
- **Tipo:** sustentação (bug/melhoria em fluxo de aprovação existente)
- **Entrada:** `demandas/SOMOSAGILITY-9/demanda.md`, enviada por Juliana Mendes em 2026-10-14 (não editada)
- **Insumos lidos:** `demanda.md`, `status.yaml`, `CLAUDE.md` raiz do squad, `clients/somos-agility/CLAUDE.md` (campos de conta em branco), `clients/somos-agility/assessment.md` (org de dev, 2026-09-30)
- **Anexo referenciado na demanda:** **indisponível.** Não existe `demandas/SOMOSAGILITY-9/anexos/` neste checkout, ou seja, nenhum anexo foi liberado para esta sessão. O conteúdo do documento anexado não foi visto e nada desta análise depende dele. Ver pendência Q7.

---

## 1. Contexto de negócio

A demanda descreve um erro no processo "Exceção Comercial p/ Atendimento Técnico" e pede três coisas no corpo:

1. "atualização do fluxo de aprovação" (escrito no pretérito: já foi feita, sem dizer por quem, onde ou quando);
2. "ajustar campo obrigatório de preenchimento";
3. "ajustar um lançamento".

O que está explícito: há um erro reportado, há uma mudança de fluxo de aprovação já realizada e há dois ajustes pedidos. O que **não** está explícito: qual é o erro, em que momento ele ocorre, qual objeto e qual campo estão envolvidos, o que é o "lançamento" e se os três pontos são correções do mesmo problema ou pedidos independentes. A sigla "ECT" não está definida em nenhum material disponível e não será expandida aqui.

## 2. Objetivo

Proposta, a validar: o fluxo de exceção comercial para atendimento técnico deixa de apresentar o erro reportado, passa a exigir o campo correto no momento correto e gera o lançamento conforme a regra de negócio vigente.

Pendente: a definição de "funcionar" não vem da demanda. Ela depende de Q1, Q4 e Q5.

## 3. Regras de negócio

A demanda não declara nenhuma regra de negócio explícita. As regras abaixo precisam ser confirmadas pelo negócio antes do design. Nenhuma está aceita.

- **RN-A (aprovação):** quem submete a exceção, quem aprova, em que ordem, com qual alçada ou condição de valor. **Pendente.**
- **RN-B (campo obrigatório):** qual campo, em qual objeto, em qual status ou etapa e sob qual condição fica obrigatório. **Pendente.**
- **RN-C (lançamento):** o que é o "lançamento" (registro criado, registro atualizado, lançamento financeiro, histórico), quando é gerado e com quais valores. **Pendente.**
- **RN-D (transição):** o que acontece com exceções que já estavam em aprovação quando o fluxo mudou. **Pendente.** Em sustentação esse ponto costuma ser o que mais gera retrabalho.

## 4. Critérios de aceite (Gherkin)

**Ressalva:** os cenários abaixo são **provisórios**. Os trechos entre `<>` dependem das respostas da seção 5 e não podem ser fechados antes delas. Cenário que depende de valor ainda não definido está marcado como **BLOQUEADO** e não é testável hoje. Não preenchi nenhum valor por suposição.

```gherkin
Funcionalidade: Exceção Comercial p/ Atendimento Técnico - fluxo de aprovação

  # BLOQUEADO: depende de Q1 (passos de reprodução do erro)
  Cenário: o erro reportado não ocorre mais
    Dado que o usuário <perfil> está no registro <objeto> em <status>
    Quando executa <ação que hoje gera o erro>
    Então nenhuma mensagem de erro é exibida
    E o registro segue para <próximo status esperado>

  # BLOQUEADO: depende de Q4 (campo, objeto, etapa e condição)
  Cenário: campo obrigatório bloqueia o avanço sem preenchimento
    Dado que o registro <objeto> está em <status> e <condição de obrigatoriedade>
    Quando o usuário tenta avançar sem preencher <campo API name>
    Então o sistema impede o avanço
    E exibe a mensagem "<texto exato da mensagem>"

  # BLOQUEADO: depende de Q4 e Q9 (campo e quem aprova)
  Cenário: campo obrigatório aceita valor válido
    Dado que o registro <objeto> está em <status> e <condição de obrigatoriedade>
    Quando o usuário preenche <campo API name> com <valor válido>
    E avança o registro
    Então o avanço é permitido

  # BLOQUEADO: depende de Q2 e Q9 (regra de alçada e papel do aprovador)
  Cenário: aprovação segue a alçada definida
    Dado uma exceção submetida com <condição de valor ou alçada>
    Quando o aprovador de <papel> aprova
    Então o status passa para <status de aprovação>
    E o próximo aprovador é <papel seguinte>

  # BLOQUEADO: depende de Q2 e Q9 (rejeição e papel de rejeição)
  Cenário: rejeição encerra o fluxo sem gerar lançamento
    Dado uma exceção submetida com <condição>
    Quando o aprovador de <papel> rejeita
    Então o status passa para <status de rejeição>
    E nenhum lançamento é gerado

  # BLOQUEADO: depende de Q5 (o que é o lançamento e qual o ajuste)
  Cenário: lançamento é gerado com os valores corretos na aprovação
    Dado uma exceção aprovada com <condição>
    Quando o fluxo conclui a etapa final
    Então é gerado <lançamento> com <campo = valor esperado> para cada campo listado em <regra>
    E nenhum lançamento duplicado é criado

  # BLOQUEADO: depende de Q10 (regra de transição, RN-D)
  Cenário: exceção já em aprovação antes da mudança segue a regra de transição
    Dado uma exceção submetida antes da atualização do fluxo, com status <status>
    Quando a atualização do fluxo entra em vigor
    Então a exceção <segue a regra definida em RN-D>

  # Testável a partir de já, após Q2 identificar os processos de aprovação fora do escopo
  Cenário: outros processos de aprovação não são alterados
    Dado o conjunto de processos de aprovação fora do escopo, listado em <lista a confirmar>
    Quando a atualização desta demanda é implantada em QA
    Então o comportamento desses processos é idêntico ao da linha de base registrada antes da mudança
```

Critério não funcional (vale para todas as etapas, já testável): evidências de QA (prints, roteiro com dados) não contêm dado pessoal de cliente. Print de registro real não entra em QA. Isso segue o guardrail #2 do squad.

## 5. O que a demanda NÃO diz (precisa de resposta antes do design)

Ordenado por impacto na arquitetura. Os itens marcados **[BLOQUEANTE]** impedem o arquiteto de decidir declarativo vs. código e impedem fechar os critérios acima.

- **Q1 [BLOQUEANTE] — Qual é o erro?** Passos de reprodução, perfil do usuário, objeto e status, mensagem exata exibida, e se ocorre sempre ou só em certas condições.
- **Q2 [BLOQUEANTE] — Qual tecnologia de aprovação está em uso?** Flow de aprovação, Approval Process clássico, Process Builder, Apex ou combinação. A resposta muda completamente o desenho e o tipo de risco. Vale notar que o assessment de 2026-09-30 registra 2 Flows de tipo `ApprovalWorkflow` ativos na org de dev, sem dizer se algum deles é este processo. Não assumi.
- **Q3 [BLOQUEANTE] — Onde e por quem a "atualização do fluxo de aprovação" foi feita?** Em qual org (dev, QA ou produção), por quem, em qual data, e se está versionada em algum branch ou PR. Se a alteração foi feita direto em produção, isso está fora da esteira e precisa de tratamento humano; o agente não age sobre isso. Se foi feita em dev, precisa ser reconciliada com o repositório antes de qualquer novo build.
- **Q4 [BLOQUEANTE] — Qual é o campo obrigatório?** API name, objeto, status ou etapa em que ele se torna obrigatório, condição exata e texto da mensagem de validação.
- **Q5 [BLOQUEANTE] — O que é "o lançamento" e qual é o ajuste?** Objeto ou registro envolvido, o que é criado ou alterado, quais campos, quais valores esperados e em qual evento.
- **Q6 [BLOQUEANTE] — Os três pontos são um só problema ou três pedidos?** Se forem correções do mesmo erro, o escopo é menor. Se forem independentes, cada um precisa de critério e pode ter etapa de build própria. Pedido de escopo mínimo e prioridade.
- **Q7 — Documento anexado.** Foi referenciado e não está disponível. Para entrar na sessão, precisa ser liberado no card por alguém de delivery, com declaração de que não contém dado pessoal. Alternativa: o detalhamento relevante (Q1 a Q6) é reescrito em texto na própria demanda.
- **Q8 — Nome exato e sigla.** Confirmar se "Exceção Comercial p/ Atendimento Técnico" é o nome do processo na org ou um nome de negócio, e o significado de "ECT".
- **Q9 — Quem aprova hoje e com quais permissões.** Perfis, permission sets ou filas envolvidos. Mudança de quem aprova afeta acesso e precisa de aprovação explícita do negócio.
- **Q10 — Exceções em andamento (RN-D).** Quantas existem e em que status. Se a transição não for definida, o fluxo novo pode deixar registros presos.
- **Q11 — Critério de pronto e homologação.** Quem homologa em QA, com qual roteiro, e quem aprova a passagem para release.
- **Q12 — Integrações.** Algum sistema consome o status de aprovação ou o lançamento? A seção "Integrações existentes" do briefing do cliente está em branco, então o impacto é desconhecido e não foi suposto.
- **Q13 — Janela de deploy e regras específicas da conta.** Os campos "Regras específicas desta conta" e "Convenção de nomenclatura" do briefing estão vazios. Não há convenção de campo, prefixo ou restrição de horário a aplicar. Se houver, precisa ser informada.

## 6. Premissas a validar

Nenhuma destas premissas está aceita. Cada uma precisa de confirmação humana antes de virar base de design.

- **P1 — Escopo do erro.** O erro está no fluxo de "Exceção Comercial p/ Atendimento Técnico" e não em outro processo de aprovação. **Pendente (Q1, Q2).**
- **P2 — Estado da alteração.** A atualização mencionada na demanda já existe em alguma org sandbox ou é apenas intenção. **Pendente (Q3).**
- **P3 — Mínimo de mudança.** Os três pontos da demanda são o escopo total, e nenhuma mudança de permissão ou de acesso é necessária além da estritamente exigida. **Pendente (Q6, Q9).**
- **P4 — Org de trabalho.** A sandbox de dev `sbx-somos-agility-dev` é a org de build desta demanda. O assessment de 2026-09-30 confirmou `IsSandbox=true` nessa org, mas esse dado tem mais de duas semanas. **Reconfirmar com `sf org list` antes da etapa de build**, não aqui, porque esta etapa não toca em org.
- **P5 — Risco de acoplamento (hipótese de risco, não fato).** O assessment registra 31 automações ativas em Oportunidade, 24 delas no mesmo evento, e 59 Process Builders ativos na org. Não sabemos se este fluxo toca Oportunidade ou usa Process Builder. Se tocar, a etapa de recon (org-recon) deve mapear a ordem de execução antes de qualquer alteração, porque o assessment aponta colisão silenciosa como risco concreto. **Pendente (Q2).**
- **P6 — Tipo sustentação.** Por ser sustentação, o design deve ser enxuto e não deve propor reescrita do fluxo. Vale apenas se Q6 confirmar escopo pontual. **Pendente (Q6).**

## 7. Estimativa de complexidade

**M.** Três frentes (fluxo de aprovação, campo obrigatório e lançamento) sobre um processo de aprovação que ainda não foi descrito, em uma org com alto acoplamento de automação segundo o assessment. Sobe para **G** se a causa do erro estiver na ordem de execução de automações no mesmo evento, ou se o lançamento tiver efeito financeiro ou integração externa (Q5, Q12). Sem o detalhamento do erro (Q1), não dá para descartar G.

## 8. Encerramento

Esta análise não fecha os critérios de aceite nem libera o arquiteto. As perguntas Q1 a Q6 são bloqueantes e precisam de resposta do consultor ou do negócio. A pedido da validação, peço também a liberação do anexo (Q7) ou o detalhamento em texto.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.

## Estimativa de esforço

**Estimativa de esforço:** 10–20 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). M com risco de G: três frentes (aprovação, campo obrigatório, lançamento) num processo ainda não descrito e com automação acoplada.

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
