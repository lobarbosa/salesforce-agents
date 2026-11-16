# EPLAST-30 · Análise — Apoio a propostas, follow-ups e argumentos comerciais

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** analise (refeita em 2026-11-15, pela regra 4 da conta) · **Autor:** ba-discovery
**Fonte:** `demandas/EPLAST-30/demanda.md` (texto do consultor, não reescrito aqui)
**Fontes consultadas:** `comentarios-do-card.md` (2026-11-11 a 2026-11-15), `rodada-anterior/01-analise.md`, `02-recon.md` (seções 4, 5 e 7), `03-design.md` (seções 2, 3 e 12), `05-testes-rodada-1.md` (seções 0 e 1), `assessment.md` (via RAG), histórico RAG de EPLAST-26, 27 e 33.
**Org conectada nesta sessão:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, Sandbox, Connected). Nenhuma operação em produção.

**Confirmado por `sf` nesta sessão (só metadata e contagens agregadas):**
- Organization: `DefaultOpportunityAccess` = Read; `DefaultAccountAccess` = Edit.
- Contagem: 0 Opportunity e 0 Account na dev.
- Bot `SFAgent2` existe (criado em 2026-11-10); planner `SFAgent2_v1` a `SFAgent2_v4` existem.
- Nenhum `GenAiPromptTemplate` na dev (metadata sem resultado).

---

## 0. O que mudou nesta rodada

- **Escopo:** autorizado (card de 2026-11-13 e orientação do responsável pela conta). Não é pendência.
- **Regra 4 aplicada:** as perguntas de regra de negócio que estavam em aberto foram decididas pela org ou pelo padrão e viraram premissas assumidas, marcadas como resolvidas (`[x]`). Nenhuma pergunta caiu no caso (c), então **nenhum item está pendente e nada bloqueia o gate**.
- **O que não é pergunta de negócio:** a rodada anterior mostrou que a peça central (template Flex lendo a cotação do CPQ por PromptFlow) não fechou no build (`05-testes-rodada-1.md`, seção 0; `03-design.md`, seção 12.1). Isso é capacidade técnica da plataforma, não decisão de negócio. Fica como risco R1 e como POC para o arquiteto (seção 7). Não foi decidido aqui.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para implantar IA no Salesforce em Sales e Marketing. Esta demanda pede apoio à **escrita comercial do vendedor**: rascunhos de proposta, de follow-up e de argumentos comerciais, gerados a partir do registro da oportunidade. O vendedor revisa e edita antes de usar.

Overlap com outras demandas (RAG):
- EPLAST-26 (score de leads e oportunidades) e EPLAST-27 (próxima melhor ação): objetos parecidos, mas entregas diferentes. Esta demanda não calcula score nem recomendação.
- EPLAST-29 (ações por linguagem natural no assistente): é a que estende o `SFAgent2`. Esta demanda não o altera (PA-02).
- EPLAST-33 (carteira por vendedor): não depende desta.

A Solicitação de Proposta Konecta de origem não está no workspace (PA-14).

## 2. Objetivo

Reduzir o tempo que o vendedor gasta redigindo proposta, follow-up e argumento, com um rascunho editável gerado a partir de dados que já estão no Salesforce.

Métrica: a demanda não define. Decisão (PA-09): não entra na medição do piloto nesta versão. O aceite é pelos critérios testáveis da seção 4.

## 3. Regra de negócio

1. O texto usa só dado existente em Opportunity, Account e, quando houver, na cotação do CPQ (`SBQQ__Quote__c` e linhas). Nada fora disso entra no texto.
2. O rascunho é **sugestão**. Nenhum registro é gravado, nenhum e-mail é enviado e nenhuma Task é criada pela feature nesta versão (somente leitura, PA-07).
3. O usuário vê só o que já vê no Salesforce. O rascunho não amplia acesso.
4. Preço, desconto, prazo e condição comercial só aparecem se vierem de campo ou da cotação. Sem fonte, aparecem como marcador `[a preencher]`.
5. Dado pessoal de contato (nome, e-mail, telefone) não entra no texto nesta versão (PA-10).
6. O CRM não dispara e-mail de marketing nem de follow-up. Se um follow-up precisar sair por e-mail, isso é passo do Marketing Cloud, fora desta entrega (regra 2 da conta).

## 4. Critérios de aceite (Gherkin)

Todos os cenários são testáveis em `sbx-eplast-dev`, com dados sintéticos (PA-12). O tempo de resposta usa o valor de PA-09 (15 segundos).

```gherkin
Funcionalidade: Rascunho comercial a partir da oportunidade

  Cenário: Proposta gerada a partir de oportunidade acessível
    Dado que sou um vendedor com acesso de leitura à oportunidade sintética "X"
    Quando peço o rascunho de proposta para "X" na aba "Rascunho IA"
    Então vejo um texto editável que cita o nome da conta e a etapa atual de "X"
    E o texto aparece em até 15 segundos
    E o debug log da execução não registra nenhum DML em Opportunity, Account, Contact ou Task

  Cenário: Follow-up gerado a partir da oportunidade
    Dado que sou um vendedor com acesso à oportunidade sintética "X"
    Quando peço o rascunho de follow-up para "X"
    Então vejo um texto editável com o nome da conta e a data de fechamento de "X"
    E o texto não contém e-mail, telefone nem nome de contato

  Cenário: Argumentos com fonte
    Dado que peço argumentos comerciais para a oportunidade sintética "X"
    Quando os argumentos são gerados
    Então cada argumento indica o campo ou a linha de cotação de onde veio

  Cenário: Dado ausente não vira invenção
    Dado que a oportunidade sintética "X" não tem data de fechamento preenchida
    Quando peço o rascunho de proposta para "X"
    Então o trecho da data aparece como "[dado ausente: data de fechamento]"
    E nenhuma data é inventada no texto
    E vejo a lista dos campos usados e a dos campos vazios

  Cenário: Preço sem cotação não é inventado
    Dado que a oportunidade sintética "X" não tem cotação do CPQ
    Quando peço o rascunho de proposta para "X"
    Então preço, desconto, prazo e condição de pagamento aparecem como "[a preencher]"
    E o texto não contém valor numérico que não venha de campo de Opportunity

  Cenário: Preço com cotação vem do registro
    Dado que a oportunidade sintética "X" tem cotação primária com valor preenchido
    Quando peço o rascunho de proposta para "X"
    Então o valor citado é igual ao campo da cotação
    E o modelo não calcula nem arredonda nenhum valor

  Cenário: Sem dado pessoal do contato no texto
    Dado que a oportunidade sintética "X" tem contato com e-mail e telefone sintéticos
    Quando peço qualquer um dos três rascunhos para "X"
    Então o texto usa "[nome do contato]" no lugar do nome
    E o texto não contém os dados sintéticos de e-mail ou telefone

  Cenário: Respeito ao compartilhamento
    Dado que um usuário sintético não tem acesso à oportunidade sintética "Y"
    Quando ele tenta gerar o rascunho para "Y", pela tela ou informando o Id
    Então recebe a mesma negativa de acesso que o Salesforce já devolve
    E nenhum dado de "Y" é enviado ao modelo

  Cenário: Acesso restrito por permission set
    Dado que um usuário sintético não tem o permission set de rascunho comercial
    Quando abre a página da oportunidade
    Então a aba "Rascunho IA" não aparece
    E uma chamada direta ao Flow de tela é negada

  Cenário: Falha do serviço de IA não trava o registro
    Dado que o serviço de IA está indisponível ou devolve erro
    Quando peço um rascunho
    Então vejo mensagem de falha
    E continuo editando o registro normalmente

  Cenário: Nenhuma automação do registro é disparada
    Dado a oportunidade sintética "X" com as automações atuais (trigger custom, triggers do CPQ e Flows)
    Quando um rascunho é gerado
    Então o debug log não registra execução de trigger nem de Flow de gravação de Opportunity, Account ou Order

  Cenário: Nada é enviado
    Dado que um rascunho foi gerado
    Quando confiro a oportunidade, a conta e as atividades
    Então não existe e-mail, Task ou Event criado pela feature
```

---

## 5. O que a demanda NÃO diz (e como foi resolvido)

| Pergunta que faltava | Resolvido em | Origem da decisão |
|---|---|---|
| Motor de IA: nativo, Agentforce ou LLM externo | PA-01 | Org (Einstein generativo habilitado, sem Named Credential) e padrão do squad |
| É ação do `SFAgent2` ou componente separado | PA-02 | Regra 3 da conta e org (agente existe) |
| O que é "proposta" e "follow-up" (PDF, e-mail, texto) | PA-03 | Texto da demanda e regra 2 da conta |
| Quais campos alimentam o texto | PA-04 | Recon (describe) e achado 4 do assessment |
| Quem revisa e quem vê | PA-05 | Padrão (sem envio) e compartilhamento da org |
| Público: quais perfis | PA-06 | Achados 7 e 8 do assessment |
| Ação após gerar (grava, envia, só mostra) | PA-07 | Achado 1 do assessment |
| Ponto de entrada | PA-08 | Página de Opportunity existente |
| Tempo de resposta aceitável (card, item 3) e métrica | PA-09 | Padrão de UX, sem medição na org |
| Dado pessoal no texto e retenção | PA-10 | LGPD e guardrail 2 |
| Tom, marca e modelo de texto | PA-11 | Sem template na org |
| Dados para teste | PA-12 | Contagem da dev |
| Custo de IA | PA-13 | Padrão da conta; licença não confirmada |
| Documento de origem | PA-14 | A demanda do card é a fonte |
| Escopo contratual | PA-15 | Card e regra 1 da conta |
| Sobreposição com EPLAST-26, 27, 29 e 33 | PA-16 | RAG e regra 3 |

---

## 6. Premissas assumidas (validar na homologação)

Cada item traz a pergunta, a decisão, a evidência e como mudar se a Eplast discordar.

- [x] **PA-01 · Motor de IA.** Pergunta: qual motor (nativo, Agentforce ou LLM externo)?
  **Decisão:** recursos nativos do Salesforce. Templates do Prompt Builder (Flex) acionados por Flow de tela. Sem LLM externo, sem callout, sem Named Credential e sem Apex nesta versão.
  **Evidência:** Einstein generativo habilitado na dev (recon, seção 7). Não há Named Credential na org (recon). LLM externo criaria um novo processador de dado pessoal (LGPD). É a opção mais simples de desfazer.
  **Como mudar:** trocar o motor do template, mantendo o contrato de entrada (Id da oportunidade) e de saída (texto).

- [x] **PA-02 · Relação com o `SFAgent2`.** Pergunta: o rascunho é ação do agente ou componente separado?
  **Decisão:** não cria agente novo e não altera o `SFAgent2` nesta versão. Os templates ficam reaproveitáveis como ação do agente depois.
  **Evidência:** o `SFAgent2` existe na dev (Bot criado em 2026-11-10; planners v1 a v4). A demanda gera texto a partir de um registro, não é conversa. Alterar o agente agora colocaria EPLAST-29 e 30 no mesmo `GenAiPlannerBundle` (R10 do desenho anterior). Regra 3 da conta.
  **Como mudar:** se o Comercial quiser o rascunho dentro do chat, abre-se extensão do `SFAgent2` depois da EPLAST-29 (demanda separada).

- [x] **PA-03 · Saídas.** Pergunta: o que é proposta, follow-up e argumento?
  **Decisão:** três saídas de texto, mostradas na tela e copiáveis: proposta, follow-up e argumentos. Sem PDF e sem envio. Argumentos são texto com a fonte de cada item, não recomendação de produto.
  **Evidência:** a demanda lista exatamente esses três itens. Regra 2 da conta: e-mail sai pelo Marketing Cloud.
  **Como mudar:** PDF de cotação é demanda separada. E-mail de follow-up vai para o Marketing Cloud.

- [x] **PA-04 · Fontes de dados.** Pergunta: quais campos alimentam o texto?
  **Decisão:** Opportunity (nome, etapa, data de fechamento, valor, descrição padrão), Account (nome e campos padrão) e cotação do CPQ (`SBQQ__Quote__c` e linhas) quando houver. Campos custom só entram se o Comercial aprovar, com descrição preenchida. Campos de texto livre (ex.: Description) ficam fora até curadoria, porque podem conter dado pessoal.
  **Evidência:** recon, seção 5 (describe). Achado 4 do assessment: 68,6% dos campos custom sem descrição, 19 de 28 em Opportunity e 78 de 90 em Account. Campo sem descrição vira frase errada para o cliente.
  **Como mudar:** a lista fica na configuração do template e pode ser ampliada por curadoria.

- [x] **PA-05 · Quem revisa e quem vê.** Pergunta: gestor aprova? Gestor vê o rascunho?
  **Decisão:** o rascunho é para o vendedor que tem acesso à oportunidade. Sem aprovação de gestor nesta versão. Nada sai do sistema.
  **Evidência:** sem envio (PA-03). O compartilhamento da org (Opportunity Read, Account Edit) já limita quem vê.
  **Como mudar:** acesso de gestor por permission set, em demanda separada.

- [x] **PA-06 · Público.** Pergunta: quais perfis usam?
  **Decisão:** acesso por permission set de rascunho comercial, atribuído aos perfis comerciais. Não cria perfil novo.
  **Evidência:** o assessment mostra quatro perfis comerciais duplicados (achados 7 e 8). Recomendação do squad: definir público por permission set.
  **Como mudar:** trocar a lista de atribuição do permission set.

- [x] **PA-07 · Ação após gerar.** Pergunta: grava em campo, cria Task ou envia?
  **Decisão:** somente leitura. Nada é gravado em Opportunity, Account, Contact, Task ou Order. O vendedor copia o texto.
  **Evidência:** achado 1 do assessment (`OpportunityTrigger`, triggers do CPQ e dois Flows `RecordAfterSave` em Opportunity). Sem DML, a feature não entra na cadeia de automação (recon, seção 4).
  **Como mudar:** gravar em campo exige mapear a ordem de execução antes. Vira demanda separada.

- [x] **PA-08 · Ponto de entrada.** Pergunta: onde o rascunho aparece?
  **Decisão:** aba "Rascunho IA" na página de Opportunity, com Screen Flow de tela. Nenhuma chamada ao modelo ao carregar a página.
  **Evidência:** a página de Opportunity existe (recon, seção 8). Um template Flex sem Flow ou agente não tem ponto de entrada no registro.
  **Como mudar:** botão de ação no lugar da aba.

- [x] **PA-09 · Tempo de resposta e métrica.** Pergunta: qual tempo é aceitável (card de 2026-11-13, item 3) e como medir?
  **Decisão:** 15 segundos para o texto aparecer, medido em dev com dados sintéticos. Sem métrica de piloto nesta versão.
  **Evidência:** fraca, declarada. Não há medição na org nem baseline no workspace (`eplast-ent-12` não está aqui). Os 15 segundos são convenção de UX para geração de texto, não um número medido.
  **Como mudar:** o cliente define o N; só o cenário e o teste mudam.

- [x] **PA-10 · Dado pessoal e retenção.** Pergunta: o texto pode citar nome, e-mail ou telefone? Por quanto tempo fica guardado?
  **Decisão:** nenhum dado pessoal de Contact entra no texto; usa-se o placeholder. Nada é gravado pela feature (texto e prompt não ficam em objeto), então não há prazo de retenção a definir nesta versão.
  **Evidência:** guardrail 2 e LGPD. O `CLAUDE.md` da Eplast não traz regra de dado sensível, então o padrão mais restrito se aplica.
  **Como mudar:** incluir contato exige revisão de LGPD e decisão de retenção, em demanda separada.

- [x] **PA-11 · Tom, marca e modelo.** Pergunta: há template de proposta ou guia de tom?
  **Decisão:** o squad escreve instruções neutras de tom comercial. A Eplast ajusta o texto dos templates na homologação.
  **Evidência:** nenhum `GenAiPromptTemplate` existe na dev (confirmado hoje). Não há material de tom no workspace.
  **Como mudar:** edição direta dos templates.

- [x] **PA-12 · Dados para teste.** Pergunta: como validar qualidade sem dado real?
  **Decisão:** validação com dados sintéticos criados na `sbx-eplast-dev`. Build e QA não leem registros de negócio.
  **Evidência:** a dev tem 0 Opportunity e 0 Account (confirmado hoje). A QA tem volume de registros de negócio (contagem do `05-testes-rodada-1.md`, não lida aqui). Dado sintético não deve ser criado na QA sem cuidado.
  **Como mudar:** se o cliente quiser dado real, a LGPD é avaliada à parte.

- [x] **PA-13 · Custo de IA.** Pergunta: quem paga o consumo de IA?
  **Decisão:** o consumo fica com a Eplast, conforme a licença dela. A esteira não contrata nem altera licença.
  **Evidência:** Einstein generativo habilitado na dev, mas licença e créditos não confirmados. O resultado de `eplast-ent-04` não está no workspace.
  **Como mudar:** confirmar com `eplast-ent-04` antes da homologação. Se faltar licença, a feature não vai para produção.

- [x] **PA-14 · Documento de origem.** Pergunta: a Solicitação de Proposta precisa ser anexada?
  **Decisão:** não. O texto do card é a fonte.
  **Evidência:** a demanda tem o item do documento, mas o documento não está no workspace.
  **Como mudar:** se o documento trouxer item de escopo diferente, a análise é revista.

- [x] **PA-15 · Escopo contratual.** Pergunta: a demanda está autorizada, sendo da Onda 3?
  **Decisão:** autorizada. Segue análise, design e build.
  **Evidência:** card de 2026-11-13 e regra 1 da conta.
  **Como mudar:** não se aplica.

- [x] **PA-16 · Sobreposição.** Pergunta: é a mesma solução de EPLAST-26, 27, 29 ou 33?
  **Decisão:** entrega independente. Não compartilha score, próxima ação nem carteira. O único ponto comum é o `SFAgent2`, que esta versão não toca (PA-02).
  **Evidência:** RAG de EPLAST-26, 27 e 33; regra 3 da conta.
  **Como mudar:** se a EPLAST-29 passar a usar os templates, a integração entra no desenho.

---

## 7. Riscos

| # | Risco | Nível | Tratamento |
|---|---|---|---|
| R1 | Capacidade técnica não verificada: template Flex lendo a cotação do CPQ por PromptFlow. A rodada anterior falhou (erro de parâmetro de saída). | **Alta** | Não é decisão de análise. O arquiteto decide a POC com teto de 4 h antes do build (`03-design.md`, seção 12). |
| R2 | Automação concorrente em Opportunity, Account e Order (achado 1). | Baixa (somente leitura) | Cenário de debug log obrigatório (seção 4). |
| R3 | Cobertura Apex de 10% (achado 2). | Baixa (sem Apex na v1) | Se o fallback com Apex for acionado, a cobertura de 85% por classe entra no escopo. |
| R4 | Campos sem descrição (achado 4). | Média | Lista permitida (PA-04). |
| R5 | Dev e QA distintas, mas com nome de usuário que indica "qa" (achado 6). | Baixa | Org Id diferente confirmado (dev `00DHa000006vfMLMAY`, QA `00DHa000006vZtmMAE`). A nomenclatura continua sendo ruído. |
| R6 | Quatro perfis comerciais duplicados (achados 7 e 8). | Baixa | Público por permission set (PA-06). |
| R7 | Campo de texto livre com dado pessoal entrar no texto. | Média | Description fica fora (PA-04). |
| R8 | Cliente esperar IA conversacional e receber rascunho. | Média | Expectativa registrada na demanda e na homologação. |
| R9 | `SFAgent2` em mudança fora da esteira (4 versões em 2026-11-10). | Baixa para esta versão | Esta versão não o altera (PA-02). |

Achado 9 (API das classes Apex) e achado 10 (nome de `OrderTrigger`) não se aplicam, porque a v1 não cria nem altera Apex nem Order.

---

## 8. Complexidade

**M.** A versão é somente leitura, sem Apex, sem DML e sem integração externa. O que pesa é a capacidade do template com grounding ainda não verificada (R1).

---

## 9. Estimativa de esforço

**Estimativa de esforço:** 30–60 h

Premissas que mais pesam na faixa:
- **POC de capacidade (2–4 h).** Se a POC resolver o grounding sem Apex, a faixa baixa vale. Se cair no fallback com Apex, a faixa sobe 14–24 h.
- **Templates e iteração com dados sintéticos (12–24 h).** Três templates e a lista de campos permitidos.
- **Flow de tela, permission set e aba (6–12 h)**, mais retrabalho de 2–6 h se a POC mudar o contrato dos PromptFlows.
- **Validação e homologação com o Comercial (6–12 h)**, com dados sintéticos.
- **Fora da faixa:** curadoria dos campos custom, alteração no `SFAgent2`, envio de e-mail (Marketing Cloud) e licença de IA.

Não inclui o tempo do agente. O arquiteto refina no design.

---

## 10. Próximo passo

O arquiteto decide a POC de capacidade (R1) e a relação de PA-02 no desenho. O gate humano aprova ou ajusta as premissas PA-01 a PA-16 antes do design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
