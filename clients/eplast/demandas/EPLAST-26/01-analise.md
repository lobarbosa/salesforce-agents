# EPLAST-26 — Scoring de leads e oportunidades

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), não contratada no projeto atual (Ondas 1–2)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing
**Status:** análise para validação humana. Não pronta para design: ver seção "O que a demanda não diz".

Fontes usadas: `demandas/EPLAST-26/demanda.md` (história do consultor), `assessment.md` (onboarding, 2026-09-30),
`contrato.md` (materializado pelo Squad OS). O documento de origem (Solicitação de Proposta) não está no workspace;
esta análise só tem o resumo de três linhas da demanda.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para implantar IA no Salesforce em Sales e Marketing, em seis ondas. As Ondas 1
(diagnóstico e desenho) e 2 (projeto-piloto) estão no contrato atual, com 120 h contratadas e fim previsto em
2026-11-30 (`contrato.md`). A Onda 3 é o bloco Comercial, e este item é o primeiro dele. Hoje a demanda não
tem orçamento de horas nem aceite comercial no projeto vigente.

Itens relacionados já registrados no RAG, todos da mesma Solicitação de Proposta e também Onda 3 ou 4:
- `[demandas/EPLAST-28/demanda.md]` — alertas para oportunidade parada ou sem acompanhamento.
- `[demandas/EPLAST-30/demanda.md]` — apoio a propostas, follow-ups e argumentos comerciais com IA.
- `[demandas/EPLAST-39/demanda.md]` — origem dos leads e retorno de campanhas (Onda 4).

Os três usariam a mesma base de Lead e Opportunity. Vale decidir no gate se são uma solução ou três, porque
isso muda o desenho e a estimativa.

## 2. Objetivo

Classificar automaticamente leads e oportunidades pela chance de conversão, e priorizar os registros com maior
probabilidade de fechar para que o time comercial atue primeiro neles.

O objetivo está claro. O mecanismo, os dados, o lugar onde o resultado aparece e o significado de "priorizar"
não estão definidos (ver seção 6).

## 3. Regra de negócio

A demanda não define regra de negócio. O que está escrito é o objetivo acima, e a frase "classificar
automaticamente" pode significar pelo menos três coisas diferentes:

- **(a)** pontuação por regras explícitas definidas pelo time comercial (ex.: critérios com pesos, sem IA);
- **(b)** modelo preditivo treinado com histórico de conversão (nativo da plataforma ou externo);
- **(c)** combinação das duas.

Cada opção leva a um desenho, a uma dependência de licença e de dados e a um custo de validação diferentes.
Não escolhi nenhuma (ver pergunta P1).

Regras que a análise precisa ter respondidas antes do design, sem propor valor:
- Qual é a escala do score e como ele vira classificação (faixas, ranking, percentil)?
- O que conta como "conversão" (estágio de Opportunity, Closed Won, Lead convertido)? Os nomes dos estágios
  da Eplast ainda não foram confirmados via `sf`.
- Lead sem dado suficiente recebe score vazio, zero ou faixa própria?

## 4. Critérios de aceite (Gherkin)

Os cenários abaixo são **provisórios**. Os que dependem de decisão pendente trazem a referência à pergunta
(P#) e não devem ser tratados como aceitos até a resposta. Os demais já são testáveis e valem independente
do mecanismo.

```gherkin
Funcionalidade: Score de conversão em Lead e Opportunity (EPLAST-26)

  Cenário: score é preenchido ao salvar um registro com dados mínimos   [depende de P1, P3]
    Dado um Lead com os campos de entrada da regra preenchidos
    Quando o registro é salvo
    Então o campo de score tem valor dentro da escala definida em P1
    E a data do último cálculo é preenchida

  Cenário: registro sem dado mínimo não recebe score enganoso   [depende de P1]
    Dado um Lead sem um dos campos obrigatórios da regra
    Quando o registro é salvo
    Então o score fica no valor definido para "sem dados suficientes"
    E nenhuma faixa de prioridade alta é atribuída

  Cenário: alteração de campo de entrada atualiza o score   [depende de P6]
    Dado uma Opportunity com score calculado
    Quando um campo de entrada da regra é alterado
    Então o score é recalculado até o prazo definido em P6

  Cenário: lista ordenada por prioridade   [depende de P5]
    Dado que existem leads com scores diferentes na lista "Leads do meu time"
    Quando a lista é ordenada por prioridade
    Então os registros aparecem do maior para o menor score
    E empates seguem o critério definido em P5

  Cenário: permissão de leitura e edição do score   [depende de P9]
    Dado um usuário do perfil Comercial - Analista
    Quando abre um Lead ou uma Opportunity
    Então vê o campo de score
    E não consegue editar o campo de score manualmente

  Cenário: automação existente não regride (obrigatório)
    Dado uma Opportunity em um estágio qualquer, com as automações atuais ativas
    Quando a Opportunity é criada ou alterada depois da entrega
    Então os triggers e Flows que já existiam em Opportunity executam como antes
    E a ordem de execução observada está documentada no design
    E o teste de regressão passa em sandbox de QA

  Cenário: cálculo não expõe dado pessoal fora do Salesforce   [depende de P2]
    Dado que o cálculo usa algum serviço externo
    Então apenas os campos listados em P3 são enviados
    E o contrato com o provedor e a base legal estão registrados antes do build

  Cenário: qualidade do score é medida antes do aceite final   [depende de P10]
    Dado uma amostra de histórico aprovada pelo cliente, com resultado conhecido
    Quando o score é aplicado à amostra
    Então a métrica acordada em P10 atinge o valor combinado
```

Observação sobre o último cenário: "atinge o valor combinado" só é testável depois que P10 definir a métrica e
o número. Hoje ele não é critério de aceite, é um lembrete de que a qualidade precisa de número.

## 5. Riscos do assessment que tocam esta demanda

O assessment (`assessment.md`, saúde **vermelho**) não cobre Lead. O que se segue é o que ele diz sobre
Opportunity e Account, e o que falta.

| Achado do assessment | Como toca EPLAST-26 | Tratamento esperado no design |
|---|---|---|
| **1 (alta)** — automação concorrente em Opportunity: `OpportunityTrigger` custom + `OpportunityAfter`/`OpportunityBefore` do SBQQ + Flows `Oportunidade_Industria` e `OpportunityFlow` (RecordAfterSave) | Qualquer campo de score gravado em Opportunity dispara esses automatismos. Risco de recursão e de quebrar o CPQ | Mapear a ordem de execução real antes do design. Preferir um único ponto de entrada no objeto, documentado com a interação do CPQ |
| **1 (alta)** — Account com `AccountTrigger`, `SBQQ AccountBefore` e Flows `AccountTriggered` e `UpdateParentAccountUsedLimit` | Só entra se o score for agregado em Account (ex.: score da conta a partir das oportunidades) | Fora do escopo inicial por padrão. Confirmar em P7 |
| **1 (alta)** — Order com triggers e Flows | Não tocado diretamente. Entra se o score alimentar fluxo de Pedido | Checar em P7 se há leitura do score por processo de Pedido |
| **2 (alta)** — cobertura Apex org-wide de 10%; 2 de 39 classes de produção seguem `<Classe>Test` | Qualquer Apex novo ou alterado precisa de classe de teste própria. Não há rede de teste para Opportunity hoje | Construir a cobertura junto com a classe, não depois. O assessment não confirmou a cobertura dos próprios triggers (`OpportunityTrigger`), então é preciso medir. O design deve dizer como o pipeline de deploy trata 10% em sandbox e produção |
| **2 (alta)** — cadeia Protheus (Account/Order → ERP) sem teste | Só relevante se o score for enviado ao ERP | Confirmar em P8 |
| **4 (média)** — 68,6% dos campos custom sem `Description`; em Opportunity, 19 de 28 | Risco de escolher campo errado como entrada do score sem saber o que ele significa | Validar cada campo de entrada com o cliente antes de usá-lo. Descrição de campo novo é obrigatória |
| **6 (média)** — alias `sbx-eplast-dev` aponta para sandbox cujo usuário e instância se identificam como qa (`eplast--qa`) | Não dá para confiar que dev e qa estão separados. Build e homologação podem colidir | **Bloqueante para o build.** Confirmar antes de qualquer deploy de demanda |
| **Não medido** — OWD por objeto, layouts órfãos, uso real dos campos | Define quem vê o score e onde ele aparece. Hoje não há dado | Medir OWD e layouts de Lead e Opportunity no design (`sf`) |
| **Sandbox vazia** — 0 Account/Contact/Opportunity | Não há dado para testar o score. Qualquer validação de qualidade depende de dado cedido pelo cliente | Ver P10 e a premissa PA-5 |

Outros achados (validation rules de Order, nomes de perfil, API version das classes, nome duplicado de trigger)
não tocam esta demanda diretamente. Se o design editar classe existente, subir a API version antes de mexer
(achado 9).

## 6. O que a demanda NÃO diz (perguntas a responder antes do design)

Ordem de prioridade: P1 a P4 mudam a arquitetura e precisam estar respondidas no gate. As demais mudam escopo,
estimativa ou validação.

**P1 — Mecanismo.** "Classificar" é (a) regras declarativas com pesos definidos pelo time, (b) modelo preditivo
com histórico, ou (c) combinação? Se houver modelo, é o motor nativo da Salesforce (depende de licença e
edição) ou serviço externo? A avaliação de licenças e créditos de IA da Onda 1 (`eplast-ent-04`, concluída) não
está no workspace. Pedir o resultado.

**P2 — Dado saindo da Salesforce.** Se houver serviço externo, quais dados saem, para qual provedor, onde são
processados e sob qual contrato? Lead e Opportunity são dado pessoal. Isso é um novo processador de dados e
precisa de decisão do cliente (e de quem responde por LGPD na Eplast) antes do design.

**P3 — Dados de entrada.** Quais campos entram no score? Só campos de Lead/Opportunity, ou também atividades,
histórico de estágio e engajamento de Marketing Cloud (pacote `et4ae5` está na org)? Quais campos são confiáveis
e preenchidos de fato? Cada um precisa de descrição e validação com o cliente.

**P4 — Onde o resultado aparece.** Campo em Lead e/ou Opportunity, lista, dashboard, Kanban ou componente na
página do registro? Quem é o usuário-alvo (vendedor, SDR, gerente)?

**P5 — "Priorizar" na prática.** Ordenação de lista, campo de prioridade, fila de atribuição, alerta ou
notificação? Qual o critério de desempate?

**P6 — Frequência.** O score é atualizado em tempo real (a cada save, o que agrava a automação concorrente) ou em
lote diário? Qual o prazo aceitável para refletir mudança de dado?

**P7 — Escopo de objetos.** Lead e Opportunity são obrigatórios? Account entra? Como fica o score do Lead
quando ele converte em Account e Opportunity? O score de Opportunity é lido por algum processo de Pedido?

**P8 — Integração.** O score precisa ir ao Protheus (ERP) ou a outro sistema? Hoje existe integração de Account
e Order com o Protheus (`SendAccountToProtheus`, `SendOrderToProtheus`); não há indicação de integração de
Lead ou Opportunity.

**P9 — Governança e permissão.** Quem pode ver o score, quem pode ajustar pesos ou regras, e como o vendedor
entende por que um lead tem determinado score (explicabilidade)? Quem é o dono do modelo ou da regra depois do
go-live?

**P10 — Validação de qualidade.** Como medir se o score funciona? Qual métrica (ex.: taxa de conversão do topo
da lista comparada ao restante), qual baseline e qual valor mínimo? Quem fornece a amostra histórica anonimizada
ou agregada para validar, já que a sandbox está vazia e o agente não pode consultar dado real (guardrail #2)?

**P11 — Relação com EPLAST-28, -30 e -39.** São a mesma solução, soluções separadas ou dependentes? Compartilham
o campo de score?

**P12 — Contrato e prazo.** A Onda 3 não está contratada, e o contrato atual termina em 2026-11-30 (hoje é
2026-11-10). Há aditivo, nova proposta ou banco de horas? Quem aprova a contratação antes do gate de design?

**P13 — Definição de conversão.** Quais estágios e campos definem "conversão" para a Eplast? Os valores de
estágio ainda não foram confirmados via `sf`.

**P14 — Confirmação do alias dev/qa** (achado 6 do assessment). Precisa estar resolvido antes do build.

## 7. Premissas a validar (todas pendentes)

- **PA-1 (pendente).** Escopo inicial é Lead e Opportunity. Account e Order ficam fora até P7.
- **PA-2 (pendente).** Nenhum serviço externo de IA entra nesta demanda até P1 e P2 serem respondidos.
- **PA-3 (pendente).** Sem integração com Protheus nesta demanda (P8).
- **PA-4 (pendente).** Os cenários de regressão de Opportunity são obrigatórios, independente do mecanismo.
- **PA-5 (pendente).** A validação de qualidade usa amostra cedida pelo cliente (agregada ou anonimizada). Se não
  houver, a validação fica limitada a teste funcional, e o aceite de qualidade vira risco aceito pelo cliente.
- **PA-6 (pendente).** A cobertura de teste do Apex novo segue o padrão do squad (85% por classe), e a classe de
  teste segue `<Classe>Test`.
- **PA-7 (pendente).** As horas da remediação do assessment (mapear ordem de execução, consolidar triggers) não
  estão na estimativa abaixo. Entram se o design exigir.

## 8. Complexidade

**G (provisório).** A decisão de mecanismo e de dados ainda está aberta, a demanda toca Opportunity com
automação concorrente, e a validação de qualidade não tem dado de amostra. Pode cair para M se P1 resultar em
regras declarativas sobre campos já confiáveis.

## 9. Estimativa de esforço humano

**Estimativa de esforço:** 40–120 h

Premissas que mais pesam na faixa (esforço do consultor e do dev para configurar, revisar, testar e homologar):
1. **Mecanismo (P1).** Regras declarativas sobre campos existentes ficam na faixa baixa. Modelo com serviço
   externo e integração ficam na faixa alta.
2. **Apex novo em Opportunity (P7, PA-6).** Código novo em objeto com automação concorrente, com cobertura
   construída do zero, puxa para cima.
3. **Validação de qualidade (P10, PA-5).** Sem amostra cedida pelo cliente, a validação é mais curta e o risco
   fica aceito. Com amostra, soma o tempo de preparação e análise.
4. **Escopo de objetos e relação com EPLAST-28/-30/-39 (P7, P11).** Cada objeto ou solução a mais soma.
5. **Remediação do assessment (PA-7).** Não incluída.

A faixa é larga porque a demanda não define o mecanismo. O arquiteto refina no design, e a faixa só deve ser
reduzida depois de P1 e P10.

---

## Próximos passos

1. Consultor leva as perguntas P1 a P14 ao cliente, com prioridade em P1 a P4 e P12.
2. Confirmar o alias `sbx-eplast-dev` (P14) antes de qualquer etapa que escreva em org.
3. Pedir ao cliente o documento de origem (Solicitação de Proposta) e o resultado da avaliação de licenças da
   Onda 1.
4. Mapear, com `sf`, OWD, layouts e ordem de execução em Opportunity, Lead e Account. Isso é recon (etapa 2) e
   não é feito nesta análise.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
