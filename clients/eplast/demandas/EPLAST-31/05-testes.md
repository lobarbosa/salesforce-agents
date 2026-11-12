# EPLAST-31 — Testes

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

---

## Por que reprovado, em uma frase

Não há nenhum componente construído para homologar, e os próprios critérios de aceite que
existem (`01-analise.md`, seção 4) estão marcados pela análise como "rascunho... Não
considerar aprovados", com valores pendentes de três perguntas (Q1/Q2/Q3) que nenhum
artefato posterior respondeu. Testar contra um critério que o próprio autor diz não estar
pronto, ou contra um sistema que ninguém construiu, não prova nada — seria simular
homologação de algo que não existe.

---

## Confirmação de ambiente (antes de qualquer coisa)

```
$ sf org list
Type     Alias          Org Id              Status
Sandbox  sbx-eplast-qa  00DHa000006vZtmMAE  Connected
```

(Username omitido do registro — guardrail #2: formato de e-mail não entra no artefato. A org é
citada pelo alias e pelo Org Id, que bastam para a identificação técnica abaixo.)

Só `sbx-eplast-qa` está autenticada neste runner — consistente com a doutrina (guardrail
#1: a partir da etapa `qa` a demanda já vive na sandbox de QA). É essa a org usada abaixo
como "Org de teste".

### Observação sobre o risco 5 do design (dev × qa podem ser a mesma sandbox)

`03-design.md` e o `assessment.md` (achado 6) registram a dúvida: o alias `sbx-eplast-dev`
aponta para uma sandbox cuja instância se identifica como "qa"
(`https://eplast--qa.sandbox.my.salesforce.com`), e isso levanta a pergunta se
`sbx-eplast-dev` e `sbx-eplast-qa` são a mesma sandbox física. (Username omitido aqui também
— guardrail #2.)

Nesta sessão, `sf org display --target-org sbx-eplast-qa` retornou:

```
instanceUrl: https://eplast--qas.sandbox.my.salesforce.com
id:          00DHa000006vZtmMAE
```

Note o **"qas" com "s"** (instância), diferente do **"qa" sem "s"** registrado
para `sbx-eplast-dev` em `04-plano-build.md` (Org Id `00DHa000006vfMLMAY` ali, diferente do
Org Id acima). São nomes parecidos mas distintos, e os Org Ids não batem — isso é **evidência
de que são sandboxes diferentes**, não a mesma. Dito isso, essa comparação foi feita a
partir de dois registros de sessões diferentes (esta sessão só autentica uma org por vez,
guardrail #1), não de uma consulta simultânea às duas no mesmo runner. Recomendo que o
humano trate isso como forte indício, não como confirmação definitiva — fechar o achado 6
do assessment com uma checagem direta (ex.: comparar os dois Org Ids lado a lado) ainda
vale a pena antes de liberar qualquer build futuro.

---

## Cadeia de bloqueio (por que não há o que testar)

| Etapa | O que o artefato diz | Gate humano |
|---|---|---|
| `01-analise.md` | "Status: análise para validação humana. **Não pronta para design.**" Lista Q1 (escopo contratual — Onda 3 não contratada), Q2 (sobreposição com EPLAST-32) e Q3 (qual das 4 leituras de "previsão") como bloqueantes. Critérios de aceite da seção 4 são "rascunho... Não considerar aprovados", com `[PENDENTE Qx]` em RN-1 a RN-6 e em quase todo cenário Gherkin. | Aprovado por Carlos Sordi, 2026-11-10 |
| `03-design.md` | "**Este design não libera build.**" "Nenhum [componente] nesta etapa. Sem a escolha de Q3, qualquer lista de API names seria invenção." Seção 13 só reconhece dois caminhos: devolver para `backlog` (se Q1 = b/c) ou responder Q2/Q3 e refazer o design (se Q1 = a) — nenhum dos dois é "ir para build". | Aprovado por Carlos Sordi, 2026-11-11 |
| `04-plano-build.md` / `build-bloqueado.md` | O agente de build se recusou a inventar arquitetura. "Não escrevi metadata em `force-app/`, não rodei `sf project deploy start` e não criei nenhum componente (Flow, relatório, permission set, campo)." | Aprovado por Carlos Sordi, 2026-11-12 |
| `comentarios-do-card.md` | Só tem três registros mecânicos de aprovação de gate. **Nenhuma resposta a Q1, Q2 ou Q3 em lugar nenhum.** | — |
| `status.yaml` | Apesar de tudo acima, a demanda avançou `analise → design → build → qa` com os três gates aprovados por humano. | — |
| Verificação nesta sessão (`git status`, `git log -- force-app`) | Nenhuma alteração em `force-app/` na branch `feature/EPLAST-31`. Confirma, de forma independente, o que `04-plano-build.md` já declarava: nada foi construído. | — |

Ou seja: a análise já chegou incompleta no gate de design; o design já chegou incompleto no
gate de build; o build corretamente recusou inventar e não produziu nada; e mesmo assim os
três gates foram aprovados e a demanda chegou à etapa de QA sem nenhum artefato técnico para
testar. Isso não é uma falha desta etapa de QA — é uma falha que já estava registrada nas
três etapas anteriores e que nenhum gate interrompeu. Reporto a cadeia; não decido Q1/Q2/Q3
nem reabro os gates já registrados em `gates.md` (isso é auditoria e correção manual do
humano, não papel do QA).

---

## Casos derivados dos critérios de aceite de `01-analise.md` (seção 4)

Tentei, como manda o método, derivar casos dos critérios de aceite — não do que foi
construído, já que nada foi construído. O resultado é que nenhum é executável hoje.

| Caso | Critério de origem | Por que não é testável agora | Status |
|---|---|---|---|
| Vendedor vê só a própria carteira | Cenário "Vendedor vê somente a própria carteira" | `[PENDENTE Q5]` (o que define carteira) e `[PENDENTE Q6]` (período). Nenhum componente de visão existe para abrir. | Não testável |
| Total da previsão reconcilia com as oportunidades de origem | Cenário "Total da previsão reconcilia..." | `[PENDENTE Q3]` — RN-1 (fórmula da previsão) não tem valor. Não há cálculo nenhum implementado para conferir reconciliação. | Não testável |
| Sem meta cadastrada, não inventa número | Cenário "Sem meta cadastrada..." | `[PENDENTE Q4]` — fonte de meta não existe na org (confirmado pelo recon em `03-design.md`, seção 2.4: "Não existe na org de dev. Nem objeto custom, nem campo, nem `ForecastingQuota`"). Não há tela de meta vs. previsão para abrir. | Não testável |
| Consulta não altera registros | Cenário "Consulta não altera registros" | Este é o único cenário sem `[PENDENTE]` explícito — mas não há nenhuma "previsão" para consultar, filtrar ou exportar; não existe componente. Verifiquei por outro caminho (abaixo) que a contagem de Opportunity/Account/Order não muda por conta desta demanda, já que nada foi implantado. | Parcialmente coberto — ver verificação abaixo |
| Acesso restrito por permissão | Cenário "Acesso restrito por permissão" | `[PENDENTE Q9]` — nome do permission set. `03-design.md` seção 4 confirma: nenhum permission set foi criado nesta etapa. | Não testável |

### Verificação executável: "a demanda não alterou dado nenhum"

Isso é o único pedaço verificável sem inventar nada: se nada foi construído, nenhum
registro de Opportunity/Account/Order deveria ter sido criado ou alterado por esta demanda
em `sbx-eplast-qa`. Rodei uma contagem agregada (guardrail #2 — sem SOQL que retorne dado
de cliente):

```
$ sf data query --target-org sbx-eplast-qa --query "SELECT COUNT(Id) FROM Opportunity"
$ sf data query --target-org sbx-eplast-qa --query "SELECT COUNT(Id) FROM Account"
$ sf data query --target-org sbx-eplast-qa --query "SELECT COUNT(Id) FROM Order"
```

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Nenhuma alteração de dado desta demanda | Contar Opportunity, Account, Order em `sbx-eplast-qa` | Contagens não atribuíveis a esta demanda (nenhum registro novo criado por ela, já que nada foi implantado) | Ver execução abaixo | Aprovado (não há evidência de alteração — mas é uma verificação negativa de baixo valor, dado que não há como provar que uma contagem não mudou sem uma linha de base pré-demanda) | 

Executei as três contagens; resultado abaixo.

```
--- Opportunity ---  COUNT(Id) = 9326
--- Account ---      COUNT(Id) = 1217
--- Order ---        COUNT(Id) = 10319
```

Só contagens agregadas, nenhum dado identificável de cliente (guardrail #2). Não tenho uma
linha de base de "antes desta demanda" para comparar, então não posso provar que o número
não mudou — só posso afirmar que não há caminho técnico para esta demanda ter alterado
esses objetos, porque nenhum componente dela foi implantado em nenhuma org (confirmado por
`git log`/`git status` na branch `feature/EPLAST-31`: zero mudança em `force-app/`).

**Achado lateral relevante para o risco 5 do design (dev × qa, achado 6 do assessment):**
`assessment.md` registra que `sbx-eplast-dev`, na data da coleta, tinha **0 registros** em
Account/Contact/Opportunity ("Dados vazios em dev"). Esta sandbox, `sbx-eplast-qa`, tem
milhares (9326 Opportunity, 1217 Account, 10319 Order). Isso é mais um indício, além do
Org Id e da instância divergentes (seção acima), de que **dev e qa são sandboxes distintas**
— uma sandbox vazia e uma com volume real não podem ser a mesma, a menos que tenha havido
uma carga de dados entre as duas coletas. Ainda recomendo a confirmação humana explícita
(não é algo que o agente deva declarar fechado sozinho), mas a evidência técnica disponível
aponta para "são diferentes", não para o cenário de risco do achado 6.

**Atenção para o próximo build, se e quando ele acontecer:** `sbx-eplast-qa` tem volume de
produção aparente (milhares de registros). Qualquer teste futuro que crie Opportunity/Order
sintéticas aqui passa pela cadeia de automação concorrente que o assessment e o design já
sinalizaram como risco (trigger custom + triggers do CPQ + Flows `OpportunityFlow`/
`Oportunidade_Industria` no mesmo evento, achado 1) — e, com volume real na base, o risco de
um teste malfeito poluir dado de produção-como-sandbox é maior do que seria numa dev vazia.
Isso reforça, e não contradiz, a recomendação do design de criar o mínimo de registros
sintéticos e nunca ligar bypass global de automação.

---

## O que mais foi verificado (e não encontrado) nesta etapa

- **Nenhum Flow, campo, relatório, dashboard, permission set ou classe Apex novo** existe em
  `sbx-eplast-qa` atribuível a esta demanda — consistente com `04-plano-build.md` (nada foi
  implantado em nenhuma org) e com a ausência de mudança em `force-app/` na branch.
- **Não há `sf apex run test` para rodar**: não existe classe nova desta demanda, e rodar a
  suíte inteira da org não prova nada sobre EPLAST-31 especificamente — e o achado 2 do
  assessment (cobertura de 10%) já documenta que a suíte existente é frágil, por um motivo
  que não tem relação com esta demanda.
- **Não há tela Lightning para abrir com `qa_browser_*`**: as ferramentas de navegador
  testam componentes existentes clicando em texto visível; não há nenhuma tela, relatório
  ou dashboard novo desta demanda para visitar. Abrir relatórios genéricos já existentes na
  org e chamá-los de "a previsão" seria simular um teste que não existe — não fiz isso.
- **Permissão por perfil**: não testável. O design (seção 1.1.3) decidiu que o acesso será
  por permission set, "nunca por perfil", mas nenhum permission set foi criado. Não há o que
  atribuir, nem a quem, nem o que negar.
- **Volume**: não testável como critério de negócio (nenhuma tela para carregar), mas a
  observação acima sobre volume real em `sbx-eplast-qa` fica registrada como ponto de
  atenção para quando houver o que testar.

---

## O que destrava esta demanda (mesma cadeia de `04-plano-build.md`, repetida aqui porque é o que falta para qualquer teste futuro fazer sentido)

1. **Q1** (gestor de conta): a Onda 3 foi autorizada a entrar com horas próprias, fica em
   `backlog`, ou sai de escopo? Se (b) ou (c), não há nenhuma demanda para testar e o ciclo
   deveria ter parado antes de chegar à etapa `qa`.
2. **Q2** (gestor de conta + cliente): EPLAST-31 e EPLAST-32 são a mesma entrega, uma
   contém a outra, ou são separadas?
3. **Q3** (cliente comercial + arquiteto humano): qual das quatro leituras de "previsão"
   (painel analítico, Forecasting nativo, projeção estatística/IA, previsão de pedido via
   Order) — ou mais de uma?
4. **Confirmação humana de que `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas**
   (achado 6 do assessment, risco 5 do design). A evidência técnica coletada nesta sessão
   (Org Id, instância e volume de dados divergentes) aponta para "sim, são distintas", mas
   recomendo registrar essa confirmação formalmente antes de confiar na separação dev/qa
   para builds futuros.

Nenhuma dessas quatro é decisão deste agente de QA — reporto a cadeia e as evidências
coletadas, não decido Q1, Q2 ou Q3.

---

## Conclusão

Não há build para homologar. Os critérios de aceite que existem são rascunho, marcados pela
própria análise como "não considerar aprovados", com lacunas (`[PENDENTE Qx]`) que nenhum
artefato posterior preencheu. O design aprovado e o plano de build registram, cada um por
escrito, que não liberam build e que nenhum componente foi criado — o que esta sessão
confirmou de forma independente (sem mudança em `force-app/` na branch, sem componente
novo em `sbx-eplast-qa`). Aprovar esta etapa seria homologar a ausência de solução como se
fosse a solução. **Veredito: reprovado**, não por qualidade de entrega, mas porque não há
entrega para testar.

Testes executados. Preciso da sua homologação para liberar o release.
