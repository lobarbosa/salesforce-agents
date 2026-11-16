# 01 — Análise funcional — SOMOSAGILITY-21: Campo origem do Lead

## Contexto

Demanda de sustentação registrada pelo consultor (Juliana Mendes) em 2026-10-19:

> Quando os dados do site é carregado para Salesforce o campo origem do lead não esta
> vindo preenchido com a opção web site Agility

Complemento do card (comentário do cliente, 2026-10-19):

- Chamado interno Agility: `20250918-032`
- Demandante: Guilherme — Departamento Marketing

Não há mais comentários no card além deste registro de chamado — nenhuma resposta
adicional às dúvidas desta análise foi encontrada em `comentarios-do-card.md` até o
momento da escrita deste artefato.

## Confirmado via `sf` CLI contra `sbx-somos-agility-dev` (guardrail #3)

- O campo é o padrão **`LeadSource`** (label "Origem do lead"), tipo picklist, no objeto
  `Lead` (`sf sobject describe --sobject Lead`).
- Valores ativos do picklist hoje na org: `Campanha Marketing`, `Customer Success`,
  `Email Marketing`, `Evento`, `Indicação de Cliente`, `Indicação de Distribuidor`,
  `Indicação de Fabricante`, `Indicação de Parceiro`, `Indicação Interna`, `Indicação
  Linha de Negócio`, `PABX`, `Prospecção - Gerente de Contas` (**valor default do
  campo**), `Sales Ops`, `Solicitação de Orçamento via E-mail`, `Treinamento`, **`Web
  Site Agility Networks`**, **`Web Site Agility – E-mail`**, `Whatsapp`.
- Ou seja: não existe hoje uma opção chamada literalmente **"Web Site Agility"** —
  existem duas variantes próximas (`Web Site Agility Networks` e `Web Site Agility –
  E-mail`). Isso é uma dúvida em aberto (ver abaixo), não uma suposição resolvida.
- `LeadSource` tem um valor **default** configurado no describe (`Prospecção - Gerente
  de Contas`). Isso é relevante para a causa-raiz: se a carga do site não setar
  `LeadSource` explicitamente, o campo não ficaria em branco — ficaria com o default
  "Prospecção - Gerente de Contas". Se o relato do consultor for "o campo vem vazio",
  precisa ser confirmado se é isso mesmo que acontece, ou se na verdade vem com esse
  valor default errado (duas causas-raiz diferentes, soluções diferentes).
- Tentativa de contagem agregada (`SELECT LeadSource, COUNT(Id) ... GROUP BY
  LeadSource`) contra `sbx-somos-agility-dev`: **0 registros de Lead na sandbox** hoje.
  Não há dado para inspecionar o padrão real de preenchimento nesta org — qualquer
  conclusão sobre "o que está vindo hoje" precisa vir de evidência trazida pelo
  consultor/cliente (print do registro afetado, ou a mesma pergunta respondida em
  produção, que este agente não acessa) ou de uma nova carga de teste feita em dev.
- Não investiguei neste artefato *qual* automação ou integração escreve o Lead vindo do
  site (Web-to-Lead nativo, Flow, Apex, ou middleware externo) — isso é recon de causa
  e pertence à etapa 2 (`org-recon`), não à análise funcional. Fica registrado aqui só
  para não se perder: a etapa seguinte precisa localizar o ponto de entrada do Lead do
  site antes do desenho da correção.

## Interpretação funcional

Leads originados pelo formulário/integração do site institucional da Agility deveriam
chegar no Salesforce com `LeadSource` preenchido identificando essa origem, para permitir
relatórios de marketing por canal. Hoje isso não está acontecendo (segundo o relato do
demandante) — o valor correto da origem "site" não está sendo aplicado.

## Critérios de aceite (propostos — pendentes de confirmação no gate)

1. **CA-01** — Dado um Lead criado pela carga/integração vinda do site institucional da
   Agility, o campo `LeadSource` (Origem do lead) é preenchido automaticamente com o
   valor que a equipe de Marketing confirmar como correto (ver dúvida D-1).
2. **CA-02** — A correção não altera o comportamento de `LeadSource` para Leads criados
   por qualquer outro canal (Web-to-Lead manual, importação, outras integrações,
   criação manual por usuário) — nenhum desses deve passar a herdar o valor de origem
   "site" por engano.
3. **CA-03** — Se a causa-raiz for ausência de valor (campo assume o default
   "Prospecção - Gerente de Contas" em vez de ficar vazio ou do valor esperado), a
   correção garante que o valor "site" sobrepõe o default nesse fluxo específico.
4. **CA-04** — Teste em sandbox de QA demonstra, com uma carga de teste simulando o
   payload real do site (sem dado pessoal real — guardrail #2), que o Lead resultante
   tem `LeadSource` correto.

## Dúvidas em aberto

- **D-1 (bloqueante para o design):** qual dos dois valores existentes deve ser usado —
  `Web Site Agility Networks` ou `Web Site Agility – E-mail` — ou é preciso criar um
  terceiro valor de picklist ("Web Site Agility", sem sufixo)? O texto da demanda diz
  "web site Agility" solto, o que não bate exatamente com nenhum dos dois valores
  ativos hoje. Precisa confirmação do demandante (Guilherme/Marketing) ou de quem
  aprovar este gate.
- **D-2:** qual é o mecanismo técnico que cria esses Leads vindos do site hoje —
  Web-to-Lead nativo, Flow/Process automatizado, Apex (trigger/REST), ou um middleware
  externo que faz callout para a API do Salesforce? Sem isso identificado, não dá para
  saber se a correção é um ajuste de mapeamento de campo declarativo (ex.: valor padrão
  de um Web-to-Lead) ou uma mudança em integração/Apex do lado de fora. Fica para a
  etapa de recon (etapa 2), mas o gate de análise deveria estar ciente de que essa
  informação ainda não existe.
- **D-3:** o comportamento relatado é "campo vem vazio" ou "campo vem com valor errado
  (o default `Prospecção - Gerente de Contas`)"? O relato do consultor diz "não está
  vindo preenchido com a opção web site Agility", o que é compatível com as duas
  leituras. Não há registro de Lead na sandbox de dev para inspecionar (ver acima);
  depende de evidência trazida por quem abriu o chamado interno `20250918-032`, ou de
  acesso ao chamado em si (fora do escopo desta sessão — não tenho acesso a sistemas
  do cliente fora do Salesforce e dos comentários do card).
- **D-4:** existe algum relatório/dashboard de Marketing que já dependa dos valores
  atuais de `LeadSource` para Leads do site? Se sim, mudar o valor usado tem impacto
  retroativo a considerar no desenho (não teria como corrigir histórico sem uma
  atualização em massa, que é fora do escopo de uma sustentação simples a menos que
  seja pedido explicitamente).

## Observações sobre o que não foi possível medir

- Não foi possível observar nenhum Lead real (nem de forma agregada além da contagem
  zero) na sandbox de dev para validar o comportamento relatado, porque a sandbox está
  sem dados de Lead no momento desta análise. Isso não bloqueia a análise funcional,
  mas bloqueia confirmar a causa-raiz exata antes do design — fica registrado como D-2/
  D-3 acima, a resolver na etapa de recon/design.
- Não tentei nenhuma consulta que retornasse dado de Lead individual (nome, e-mail,
  telefone) — guardrail #2. A única consulta feita foi agregada (`COUNT(Id) GROUP BY
  LeadSource`), que voltou vazia.

## Estimativa de esforço: 2–4 h

Sustentação pontual: ajuste de automação/mapeamento de origem de Lead em um único
ponto de entrada, sem construção de objeto novo. A faixa considera a necessidade de
confirmar D-1/D-2 antes do design (pode subir se a causa-raiz estiver num middleware
externo fora do controle direto do Salesforce, fora do alcance desta esteira).
