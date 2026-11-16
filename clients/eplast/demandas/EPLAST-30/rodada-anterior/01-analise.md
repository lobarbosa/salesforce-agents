# EPLAST-30 · Análise — Apoio a propostas, follow-ups e argumentos comerciais

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** analise · **Autor:** ba-discovery (rascunho para validação humana)
**Fonte:** `demandas/EPLAST-30/demanda.md` (texto do consultor, não reescrito aqui)
**Fontes consultadas:** `CLAUDE.md` da conta (briefing quase todo em branco), `assessment.md` (2026-09-30), `contrato.md` (materializado pelo Squad OS), histórico RAG de EPLAST-26, 27 e 29.

**Atenção:** não consultei a org via `sf` nesta análise. Os fatos de metadata citados abaixo vêm do `assessment.md` de 2026-09-30 e precisam ser reconfirmados na etapa de recon (guardrail #3). A sandbox de dev não tem registros de negócio (0 Account, Contact, Opportunity), então nada aqui sobre volume ou qualidade de dados é fato, é hipótese.

---

## 0. Pendência de escopo contratual (antes de qualquer design)

O `contrato.md` diz que a Onda 3 (Comercial) está "ainda não contratada". Ondas 1 e 2 somam 120 h, com fim previsto em 2026-11-30. Este item pertence à Onda 3. A demanda em si não diz se há aditivo ou autorização comercial para entrar em esteira.

**Pergunta ao consultor / gestor de conta:** esta demanda está autorizada para entrar em esteira (aditivo ou autorização por escrito), ou está registrada em backlog como antecipação de escopo futuro? A resposta não muda o conteúdo desta análise, mas precisa existir antes do gate de design. O mesmo ponto foi levantado em EPLAST-27 e EPLAST-29 [demandas/EPLAST-29/01-analise.md, seção 0].

A estimativa de esforço abaixo não cria escopo contratado. Ela só mede o tamanho do que foi pedido.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para implantar IA no Salesforce em Sales e Marketing, em seis ondas. Hoje o piloto (Onda 2) está construindo agentes de consulta ao CRM (`contrato.md`, entregáveis eplast-ent-07 a 11). Esta demanda pede um apoio à **escrita comercial**: rascunhos de propostas, follow-ups e argumentos gerados a partir dos dados do cliente e da oportunidade.

A origem é a Solicitação de Proposta Konecta. O documento de origem não está no workspace, então o texto "Item do documento" da demanda não pode ser conferido contra ele. O mesmo problema apareceu em EPLAST-26 [demandas/EPLAST-26/01-analise.md, seção 1].

Há três demandas com o mesmo objeto de negócio e possivelmente a mesma plataforma:
- EPLAST-26 (scoring de leads e oportunidades)
- EPLAST-27 (próxima melhor ação por cliente)
- EPLAST-29 (ações por linguagem natural no assistente de IA)

Também há sobreposição com o entregável `eplast-ent-08` ("Consulta rápida ao CRM via assistente de IA") e com `eplast-ent-07` (Agentforce no perímetro do piloto). Se o rascunho for uma ação do assistente, a solução é uma só. Se for um componente separado, são duas. Isso precisa ser decidido antes do design.

## 2. Objetivo

Reduzir o tempo que o vendedor gasta redigindo proposta, follow-up e argumento comercial, com um rascunho gerado a partir de dados do próprio registro, que ele revisa e edita antes de usar.

Métrica de sucesso: **não definida na demanda** (ver seção 4).

## 3. Regra de negócio

Regras que a demanda permite afirmar, sem inventar:

1. O rascunho é gerado **a partir de dados existentes** do cliente e da oportunidade. Nada que não esteja no Salesforce (ou em fonte declarada) entra no texto.
2. O rascunho é **sugestão**. Nenhum texto gerado é enviado ao cliente sem revisão humana. (Inferido do tipo de uso; a demanda não diz isso explicitamente. Ver premissa P-5.)
3. O usuário só vê dados que já vê no Salesforce. O rascunho não amplia acesso (ver achado de compartilhamento na seção 6).
4. Preço, desconto, prazo e condição comercial **não podem ser inventados** pelo modelo. (Regra proposta por esta análise; a demanda não trata do assunto. Ver premissa P-6.)

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo são testáveis. Os trechos entre `<…>` dependem de decisão pendente listada em "O que a demanda não diz" e não devem ser tratados como aceitos até essa decisão existir.

```gherkin
Funcionalidade: Rascunho comercial a partir da oportunidade

  Cenário: Follow-up gerado a partir de uma oportunidade acessível
    Dado que sou um usuário com acesso de leitura à oportunidade "X"
    Quando peço um rascunho de follow-up para "X"
    Então recebo um texto editável que cita o nome da conta e a etapa atual da oportunidade
    E o texto aparece em até <N> segundos (N a definir, ver P-9)
    E nenhum campo de Opportunity, Account ou Task é gravado sem minha ação explícita

  Cenário: Dado ausente não vira invenção
    Dado que a oportunidade "X" não tem data de fechamento preenchida
    Quando peço um rascunho de proposta para "X"
    Então o trecho da data aparece como "[dado ausente: data de fechamento]"
    E nenhuma data é inventada no texto
    E vejo a lista dos campos usados e dos campos vazios

  Cenário: Respeito ao compartilhamento do Salesforce
    Dado que um usuário não tem acesso à oportunidade "Y"
    Quando ele tenta gerar rascunho para "Y", pela tela ou informando o Id
    Então recebe a mesma resposta de acesso negado que o Salesforce já devolve
    E nenhum dado de "Y" é enviado ao modelo de IA

  Cenário: Preço e condição comercial não são inventados
    Dado que peço um rascunho de proposta para uma oportunidade sem cotação (Quote) no CPQ
    Quando o rascunho é gerado
    Então preço, desconto, prazo e condição de pagamento aparecem apenas como marcador "[a preencher]"
    E o texto não contém nenhum valor numérico que não venha de um campo indicado nas premissas

  Cenário: Argumento comercial rastreável
    Dado que peço argumentos comerciais para uma oportunidade
    Quando os argumentos são gerados
    Então cada argumento indica de qual fonte veio (campo, produto ou caso) <fontes a definir, ver P-4>

  Cenário: Trilha de uso sem dado pessoal
    Dado que um rascunho foi gerado
    Quando consulto o registro de uso
    Então vejo usuário, registro, tipo de rascunho, data e modelo usado
    E o texto completo e o prompt completo não ficam gravados <retenção a definir, ver P-10>

  Cenário: Acesso restrito por permissão
    Dado que um usuário não tem o permission set de IA comercial
    Quando abre a página da oportunidade
    Então a ação de rascunho não aparece
    E uma chamada direta ao componente ou controller é negada

  Cenário: Falha do provedor de IA não trava o registro
    Dado que o serviço de IA está indisponível ou devolve erro
    Quando peço um rascunho
    Então vejo mensagem de falha
    E continuo editando o registro normalmente

  Cenário: Não dispara automação existente do registro
    Dado a oportunidade "X" com as automações atuais (trigger custom, triggers do CPQ e Flows)
    Quando um rascunho é gerado
    Então nenhum trigger nem Flow de Opportunity, Account ou Order executa (verificado no debug log do ambiente dev)
```

Os cenários de "não grava" e "não dispara automação" valem só para a opção de **somente leitura**. Se o consultor escolher gravar o rascunho em campo ou enviar e-mail, eles mudam, e o achado 1 do assessment passa a bloquear (ver seção 6).

---

## 5. O que a demanda NÃO diz

Estas perguntas precisam de resposta antes do design. Algumas mudam a arquitetura.

1. **Escopo contratado.** Autorizada para esteira ou backlog como antecipação? (seção 0)
2. **Plataforma de IA.** Qual motor?
   - Recursos nativos do Salesforce (Prompt Builder / Einstein generativo)?
   - Agentforce, já usado no piloto?
   - LLM externo, por callout, com Named Credential?

   A escolha muda a arquitetura inteira (declarativo ou código) e, no caso externo, cria um processador de dados pessoais novo para o cliente (LGPD). Não escolho por conta própria.
3. **Os três tipos de saída.** O que é uma "proposta" para a Eplast: documento (PDF, Quote do CPQ), texto de e-mail ou ambos? Follow-up é e-mail, tarefa, atividade ou mensagem? Argumento é lista, texto ou ambos?
4. **Fontes de dados.** Quais objetos e campos alimentam o texto? Opportunity, Account, Contact, cotação do CPQ (Quote e QuoteLine), Product2, histórico de Task e Event, Order vindo do Protheus? Para argumentos, de onde vêm os diferenciais: catálogo de produto, casos de sucesso, material de marketing? Hoje isso não existe na demanda.
5. **Quem revisa antes de enviar.** O texto sai só para o vendedor, ou passa por gestor? A demanda não fala em envio, mas "proposta" e "follow-up" costumam ir ao cliente final.
6. **Ação após gerar.** Só mostra o texto na tela? Grava em campo ou em Task? Envia e-mail? Cada opção muda o risco (seção 6, achado 1).
7. **Ponto de entrada.** Botão na página de Opportunity, componente Lightning, dentro do assistente de IA, ou relatório? Quem aciona, e com que frequência?
8. **Público.** Quais perfis usam? O assessment mostra quatro variações de perfil comercial (`Comercial`, `Comercial - Analista`, `Comercial - Analistas`, `Comercial Padrão`). Gestor vê o rascunho dos vendedores?
9. **Critério de qualidade e medição.** Como se sabe que o rascunho é bom? Taxa de aceitação sem edição, tempo economizado, nota do vendedor? Esta demanda entra na medição do piloto contra o baseline (`eplast-ent-12`) ou fica fora?
10. **Dados pessoais no texto e retenção.** O rascunho pode citar nome, e-mail ou telefone do contato? Por quanto tempo o texto e o prompt ficam guardados? O `CLAUDE.md` da Eplast não define dados sensíveis do setor (seção "Regras específicas" em branco). Sem isso, não há como cumprir o guardrail #2 com segurança no desenho.
11. **Tom, marca e modelo.** Existe template de proposta, assinatura ou guia de tom que o rascunho deva seguir?
12. **Custo de IA.** Quem paga o consumo de créditos ou licenças de IA? O entregável `eplast-ent-04` avaliou licenças e créditos, mas o resultado não está no workspace. O assessment mediu licença Salesforce só na sandbox (14 de 14), não de produção.
13. **Dados para teste.** A dev está vazia. Como validar qualidade do texto? Proposta: dados sintéticos criados no ambiente dev. Nenhum dado real da Eplast entra na sessão (guardrail #2). Confirmar que o consultor aceita essa forma de validação.
14. **Documento de origem.** A Solicitação de Proposta Konecta pode ser anexada ao card (com liberação de dado pessoal) para conferir o escopo deste item?
15. **Sobreposição.** EPLAST-26, 27, 29 e a Onda 2 (`eplast-ent-08`) são uma solução só ou separadas? Afeta quem faz o design.

---

## 6. Riscos do assessment que tocam este pedido

Riscos do `assessment.md` (2026-09-30) que se aplicam ao que foi pedido:

- **Achado 1 (alta): automação concorrente em Account, Opportunity e Order.** Opportunity tem `OpportunityTrigger`, `OpportunityAfter`/`OpportunityBefore` do CPQ e dois Flows `RecordAfterSave`. Se o rascunho só lê, o risco é baixo. Se grava em campo, cria Task ou envia e-mail por Flow, entra direto nessa concorrência. Antes do design, mapear a ordem de execução real nesses objetos. Esta é a condição mais forte para a análise.
- **Achado 2 (alta): cobertura de teste Apex de 10%.** Se a solução tiver Apex (controller de Lightning, callout ao modelo), vale `<Classe>Test` com 85% por classe. Se o rascunho ler dados de Order, a dependência com a integração Protheus (sem teste) vira risco de dado.
- **Achado 4 (média): 68,6% dos campos custom sem descrição, incluindo 78 de 90 em Account e 19 de 28 em Opportunity.** Para o modelo gerar texto a partir de campos, é preciso saber o que cada um significa. Campo mal entendido vira frase errada para o cliente. Mitigação: lista de campos permitidos, curada com o Comercial, antes do design.
- **Achado 6 (média): alias `sbx-eplast-dev` aponta para sandbox cujo usuário e URL indicam "qa".** Antes de validar qualquer comportamento de IA, confirmar que dev e qa são distintas. Se não forem, a homologação pode contaminar o build.
- **Achados 7 e 8 (baixa): perfis comerciais duplicados.** Definir o público por permission set, não por perfil novo.
- **Achado 9 (baixa): classes Apex em v58 a v64, org em v67.** Só se a solução editar classe existente. Subir a versão antes de mexer.
- **Achado 5 (média): convenção `<Classe>Test` não seguida.** Só se a solução criar ou tocar Apex.
- **Não medido: OWD e regras de compartilhamento.** Este é o ponto mais sensível para o pedido. O rascunho não pode gerar texto sobre registro que o usuário não vê. O assessment não mediu o OWD; isso precisa estar no recon (02) antes do design.

Não se aplicam diretamente:
- **Achado 3 (validation rules de Order):** só se a solução gravar em Order.
- **Achado 7 (perfil "Financeiro"):** sem relação com comercial.
- **Achado 10 (nome duplicado de `OrderTrigger`):** sem relação, salvo se a solução tocar Order.

---

## 7. Premissas a validar

Nenhuma destas está confirmada. Todas precisam de resposta antes do gate de design.

- **P-1 (pendente):** a demanda está autorizada a entrar em esteira (seção 0).
- **P-2 (pendente):** a solução é somente leitura na primeira versão. Não grava em Opportunity, Account, Order nem Task, e não envia e-mail.
- **P-3 (pendente):** a primeira versão cobre três tipos de saída (proposta, follow-up, argumento) e um único ponto de entrada na página de Opportunity.
- **P-4 (pendente):** fontes de dados limitadas aos campos de Opportunity, Account e Contact que forem aprovados pelo Comercial, mais cotação do CPQ quando existir. Argumentos vêm só de fonte declarada.
- **P-5 (pendente):** nenhum texto é enviado ao cliente sem revisão humana.
- **P-6 (pendente):** preço, desconto e condição comercial só aparecem se vierem de registro do CPQ ou de campo indicado. Caso contrário, marcador.
- **P-7 (pendente):** a plataforma de IA é decidida pelo arquiteto, com base na resposta da pergunta 2. Esta análise não assume nenhuma delas.
- **P-8 (pendente):** a validação é feita com dados sintéticos no ambiente dev, sem copiar dado real da Eplast para a sessão.
- **P-9 (pendente):** o limite de tempo de resposta será definido pelo cliente. O `<N>` nos cenários fica em aberto até lá.
- **P-10 (pendente):** o texto gerado e o prompt não ficam guardados além do necessário para auditoria mínima. Retenção a definir com o cliente e o DPO.
- **P-11 (pendente):** o custo de consumo de IA é responsabilidade do cliente, a confirmar.

---

## 8. Complexidade

**G.** A demanda envolve decisão de plataforma de IA (nativa ou externa, que muda a arquitetura), dado pessoal de cliente com obrigação de LGPD, objetos de negócio com automação concorrente e cobertura de teste de 10%. Mesmo a versão mínima exige decisões que ainda não foram tomadas.

---

## 9. Estimativa de esforço

**Estimativa de esforço:** 50–140 h

Premissas que mais pesam na faixa:
- **Plataforma (maior peso).** Recursos nativos com template e sem Apex ficam na faixa baixa. LLM externo com Named Credential, Apex de controller, testes com 85% e revisão de LGPD ficam na faixa alta.
- **Escrita.** Somente leitura (P-2) fica na faixa baixa. Gravar em campo, criar Task ou enviar e-mail adiciona o trabalho de mapear e testar a automação concorrente (achado 1), o que puxa para a faixa alta.
- **Quantidade de saídas e fontes.** Três tipos e fontes limitadas (P-3, P-4) assumidos. Mais tipos ou fontes externas (catálogo, Protheus) elevam o teto.
- **Curadoria de campos.** A descrição dos campos (achado 4) e a lista de campos permitidos com o Comercial não estão incluídas no número. Podem somar esforço próprio.
- **Validação sem dado real.** O número assume testes com dados sintéticos (P-8). Se o cliente exigir validação com dado real, o esforço sobe.

Não inclui o tempo do agente nem o design, que o arquiteto refina. Faixa larga porque a demanda ainda não define plataforma, saídas, fontes nem escrita. Se o escopo for reduzido para somente leitura com um tipo de saída e Prompt Builder nativo, a faixa baixa é a referência.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
