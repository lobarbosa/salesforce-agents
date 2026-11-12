# EPLAST-26 — Testes: Scoring de leads e oportunidades

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

---

## Por que reprovado, em uma frase

Não há o que homologar: o estágio `build` nunca construiu nada, e isso continua verdade
hoje, confirmado de novo nesta sessão diretamente contra a sandbox de QA. O gate de build
foi aprovado mesmo assim, e a causa raiz do que bloqueou o build (P12 — Onda 3/Comercial
não contratada) **não foi resolvida** por essa aprovação. Este não é um relatório de "testei
e falhou" — é um relatório de "não existe artefato para testar".

### FALHA 1 (crítica) — Build nunca aconteceu; gate de build foi aprovado sobre um artefato que registra bloqueio, não construção

**O que confirmei nesta sessão, contra `sbx-eplast-qa`:**

| Verificação | Comando | Resultado |
|---|---|---|
| Campo `Lead.ScoreConversao__c` | `sf sobject describe -s Lead -o sbx-eplast-qa` | não encontrado |
| Campo `Lead.PrioridadeConversao__c` | idem | não encontrado |
| Campo `Opportunity.ScoreConversao__c` | `sf sobject describe -s Opportunity -o sbx-eplast-qa` | não encontrado |
| Campo `Opportunity.PrioridadeConversao__c` | idem | não encontrado |
| Permission set `PS_Comercial_ScoreConversao` | `sf data query -o sbx-eplast-qa -q "SELECT Id, Name, Label FROM PermissionSet WHERE Name = 'PS_Comercial_ScoreConversao'"` | 0 registros |
| List views `Leads_PorPrioridade` / `Oportunidades_PorPrioridade` | `sf data query -o sbx-eplast-qa -q "SELECT Id, Name, SobjectType FROM ListView WHERE SobjectType IN ('Lead','Opportunity') AND (Name LIKE '%Prioridade%' OR Name LIKE '%PorPrioridade%')"` | 0 registros |
| Histórico de metadata da demanda no git | `git log --all --oneline --grep="EPLAST-26"` e `git show --stat` dos commits encontrados | só commits de artefato (`.md`, `status.yaml`, `gates.md`); nenhum `force-app/**` tocado em nenhum commit da demanda |
| PR aberto em `feature/EPLAST-26` | `gh pr list --head feature/EPLAST-26` | não foi possível consultar nesta sessão (token do `gh` não configurado no runner de QA); o histórico de commits acima já é suficiente para confirmar que não há metadata para revisar em PR nenhum |

Nenhum dos sete componentes que o design (`03-design.md`, seção 3) manda construir existe
na org de QA: 4 campos fórmula, 1 permission set, 2 list views. Também não há layout
alterado para conferir (`Lead-Lead Layout`, `Opportunity-Opportunity Layout`,
`Opportunity-CPQ Opportunity Layout`) — sem o campo existir, não há o que incluir em
layout.

**Por que isso não é uma falha técnica de implementação — é a ausência total dela:**

`04-plano-build.md` e `BLOQUEIO-build.md` já documentavam, na sessão de build anterior, que
nada foi construído de propósito, porque dois bloqueios que o próprio design (seção 1, item
4, e "Bloqueios em aberto") colocou como condição para iniciar seguiam abertos:

1. **P12 — Onda 3 (Comercial) não contratada.** Reconfirmado nesta sessão via
   `clients/eplast/contrato.md`: *"Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e
   treinamento) ainda não contratadas"*. Só Ondas 1–2 (120h) estão no escopo pago, projeto
   termina em 2026-11-30. EPLAST-26 é entregável da Onda 3. Nada mudou neste ponto desde que
   o build parou.
2. **P14 — distinção dev/qa.** Este ponto teve progresso: diferente do que `BLOQUEIO-build.md`
   registrou (uma única org `sbx-eplast-dev`), este job de QA autentica numa org própria,
   alias `sbx-eplast-qa`, instância `eplast--qas.sandbox.my.salesforce.com` — formato
   diferente do que o recon via em dev. Não investiguei mais fundo se dev e qa são de fato
   sandboxes distintas (não tenho `sbx-eplast-dev` autenticada neste job para comparar), mas
   isso é irrelevante para o resultado deste teste: mesmo que P14 estivesse totalmente
   resolvido, P12 sozinho já impede qualquer entrega, e o campo/permission set/list view
   continuam não existindo em QA por qualquer motivo que seja.

**O que aconteceu entre o build bloqueado e eu ser acionado:** o gate `aguardando_gate_build`
foi aprovado por Carlos Sordi em 2026-11-12, sobre o artefato `04-plano-build.md` que diz
textualmente "BLOQUEADO antes de iniciar" e "Nenhuma branch, commit, metadata ou PR foi
criado". `gates.md` registra a aprovação com o hash desse arquivo — ou seja, o que foi
aprovado foi explicitamente "não construí nada, aqui está por quê", não um plano de
construção. `comentarios-do-card.md` não acrescenta contexto novo sobre a decisão (só
registra que o gate foi aprovado, sem justificativa). Aprovar esse gate moveu a demanda para
`qa`, mas não resolveu P12 — o bloqueio comercial que impediu o build continua de pé, só que
agora uma etapa adiante no fluxo.

**Decisão que não me cabe tomar:** não decido se isso foi (a) aprovação por engano do gate
errado, (b) decisão consciente de considerar a Fase 1 "aceita sem build real" por algum
motivo que não está registrado em nenhum artefato, ou (c) instrução de tratar EPLAST-26 como
exceção de escopo dentro do atual contrato — o próprio design já previa essa possibilidade
em P12 ("decisão explícita do cliente/Konecta de tratar EPLAST-26 como exceção dentro do
escopo atual") mas não há registro de que isso tenha sido comunicado. Qualquer uma dessas
três precisa de decisão humana explícita, documentada — não de um agente de QA inferindo a
intenção por trás de um clique de aprovação.

---

## O que eu NÃO fiz, de propósito

- Não fabriquei um roteiro "executado" nem evidência de passagem para os cenários de
  `01-analise.md`. Com os quatro campos fórmula, o permission set e as list views
  inexistentes na org, não há tela para abrir, campo para preencher ou list view para
  ordenar — qualquer "print" ou "passou" aqui seria invenção.
- Não usei `qa_browser_*` para capturar evidência de UI: não há nada na Lightning para
  verificar que seja específico desta demanda (os layouts de Lead/Opportunity existem, mas
  sem os campos novos incluídos, abrir o registro só mostraria o estado atual da org, que
  não prova nem reprova este design).
- Não alterei `status.yaml` nem `gates.md` — mecânico, fora do escopo deste agente.

## Roteiro de teste que SERIA executado, quando houver o que testar

Derivado dos critérios de aceite de `01-analise.md` (seção 4) e dos ajustes que o design
propôs na seção 9 (retirar "data do último cálculo" e "recálculo em prazo", que não se
aplicam a fórmula). Fica registrado aqui para a próxima sessão de QA não começar do zero
depois que o build real acontecer.

| # | Caso | Passos previstos | Esperado | Pré-requisito hoje ausente |
|---|---|---|---|---|
| 1 | Score preenchido com dados mínimos (Lead) | Criar Lead de teste com os campos de entrada da regra preenchidos (regra ainda não definida — P1/P3/P13) e abrir o registro | `ScoreConversao__c` e `PrioridadeConversao__c` com valor dentro da escala definida | Campo não existe; regra de pontuação (pesos, faixas, corte) não definida com o cliente |
| 2 | "Sem dados suficientes" não aparenta score baixo | Criar Lead sem um campo mínimo da regra e abrir o registro | Score em branco/faixa própria, nunca zero | Campo não existe; mesma dependência do caso 1 |
| 3 | List view ordenada por prioridade | Abrir `Leads_PorPrioridade` com leads de score variado | Ordem decrescente por score; critério de desempate conforme P5 | List view não existe; campo não existe |
| 4 | Permissão: Comercial - Analista vê e não edita | Atribuir `PS_Comercial_ScoreConversao` a um usuário de teste com esse perfil, abrir Lead/Opportunity | Campo visível, não editável (fórmula, somente leitura por natureza) | Permission set não existe |
| 5 | Regressão de automação de Opportunity (obrigatório, independente de mecanismo) | Com debug log ativo, salvar uma Opportunity de teste depois do deploy | CPQ, `OpportunityTrigger`, `OpportunityFlow` e `Oportunidade_Industria` disparam exatamente como antes; leitura do score não aciona nada novo | Nada foi deployado — não há "depois do deploy" para comparar com o "antes" |
| 6 | Tamanho compilado da fórmula dentro do limite (R11 do design) | Inspecionar a fórmula salva via Setup/metadata | Abaixo de ~70% do limite da plataforma | Fórmula não escrita |
| 7 | Qualidade do score medida contra amostra (depende de P10) | Aplicar o score a uma amostra histórica cedida pelo cliente | Métrica acordada em P10 atingida | P10 não definido; sandbox vazia (0 Lead, 0 Opportunity confirmado no recon); e campo não existe |

Casos 1, 2 e 3 também dependem de P1/P3/P5/P13 (mecanismo, dados de entrada, desempate,
definição de conversão) — mesmo que o build aconteça, esses critérios de aceite continuam
marcados como "provisórios" em `01-analise.md` até o cliente responder.

## Critérios de aceite não testáveis nesta sandbox, mesmo em tese

- **Cenário "automação existente não regride"**: testável só depois do deploy real (caso 5
  acima). Nada a objetar ao design — a Fase 1 por fórmula foi desenhada exatamente para não
  precisar disso em teoria (sem DML, sem gatilho), mas o próprio design marca o cenário como
  obrigatório mesmo assim, e eu concordo que confirmar empiricamente é mais seguro do que
  confiar só no argumento "fórmula não dispara automação".
- **Cenário de dado saindo da Salesforce / P2 (LGPD)**: não se aplica à Fase 1 (sem serviço
  externo). Nada a testar aqui enquanto P1 permanecer (a).
- **Qualidade do score contra amostra (P10)**: sandbox tem 0 Lead e 0 Opportunity
  (reconfirmado no recon, não eu). Mesmo com o build pronto, não há dado de produção para
  validar — depende de amostra agregada/anonimizada cedida pelo cliente (PA-5). Não vou
  rodar SOQL buscando dado real de cliente em nenhuma hipótese (guardrail #2).

## O que precisa de decisão humana, não de mais teste

1. **P12 continua aberto.** A Onda 3 (Comercial) não está contratada. Aprovar o gate de
   build não contratou a onda — só moveu a demanda de estágio. Alguém precisa decidir, e
   registrar a decisão:
   - reverter `status.yaml` para `build` (ou mais atrás) até P12 se resolver; ou
   - confirmar explicitamente que o comercial/Konecta já fechou a contratação da Onda 3 (e
     atualizar `contrato.md` e o status report, que hoje dizem o contrário); ou
   - instruir explicitamente que esta demanda prossegue como exceção de escopo, com quem
     assume essa decisão registrado em algum lugar auditável (gate ou comentário do card).
2. Enquanto P12 não estiver resolvido, qualquer nova tentativa de build deve voltar a parar
   no mesmo lugar que a sessão anterior parou — isto é o comportamento correto, não um
   defeito do pipeline.
3. Depois que o build acontecer de verdade, esta sessão de QA (ou a próxima) deve reexecutar
   o roteiro acima contra os componentes reais, com evidência de verdade — incluindo
   `qa_browser_*` para os cenários de permissão e list view, com usuários e registros de
   teste criados para isso, nunca dado real de cliente.

---

Testes executados. Preciso da sua homologação para liberar o release.
