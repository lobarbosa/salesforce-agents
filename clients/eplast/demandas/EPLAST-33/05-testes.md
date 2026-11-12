# EPLAST-33 — Testes

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** 5 (testes, qa)

---

## 0. Por que o veredito é reprovado antes de qualquer caso de teste

A demanda chegou ao estágio `qa` (gate de build aprovado por Carlos Sordi em
2026-11-12T13:30:01, `gates.md`) **sem nenhuma construção ter acontecido**. Isto não é
opinião desta etapa — é o que o próprio `04-plano-build.md` registra no título: "NÃO
EXECUTADO". Conferido de novo aqui, de forma independente, antes de aceitar essa alegação:

1. **Histórico de commits da branch `feature/EPLAST-33`** (`git log`, `git show --stat`):
   o commit de build (`3332f4f0`) só altera `04-plano-build.md`, `gates.md`, `status.yaml`
   e um CSV de telemetria de custo. **Nenhum arquivo em `force-app/` foi tocado.** O commit
   de design (`802d30c1`) também não toca `force-app/` — só `status.yaml`, telemetria e,
   por acidente de outra mudança no repositório, `CLAUDE.md`/`cli.py` da raiz (não
   relacionados a esta demanda).
2. **Metadata na org real** (`sf org list metadata`, `sf data query`, contra
   `sbx-eplast-qa`, confirmado abaixo): nenhum dos componentes que `03-design.md` §4.1
   propõe para a Fase 1 existe —
   - Pasta de relatório `EPLAST_Oportunidades_Comerciais`: **não existe** (29 pastas de
     relatório na org, nenhuma com esse nome ou variação de "Oportunidades"/"Comercia").
   - Relatórios `Recuperacao_Contas_Sem_Compra` e `Volume_Variacao_Por_Conta`: **não
     existem** (busca por `fullName` sem resultado; confirmado também via UI — ver
     evidência §2).
   - Classe Apex `CrossSellOpportunityBatch`/`CrossSellOpportunityBatchTest` (opção C,
     escalada, não aprovada): **não existe** — consistente com a escalação nunca ter sido
     decidida.
3. **`04-plano-build.md` já documenta a causa:** o design (`03-design.md` §10) condiciona
   100% do build a quatro decisões humanas (G1–G4: autorização de contrato da Onda 3,
   demanda própria vs. extensão de `eplast-ent-11`/`SFAgent2`, canal de entrega, definição
   única de "compra"/"sem compra"). `comentarios-do-card.md` só tem três linhas, todas
   notificações automáticas de aprovação de gate — **nenhuma resposta a G1–G4** está
   registrada em disco em lugar nenhum da demanda.

Conclusão: o gate de build foi aprovado **mecanicamente** (o hash em `gates.md` bate com
`04-plano-build.md`, então a aprovação é válida *sobre aquele artefato* — o artefato só
não é um plano de build, é a ata de que o build não aconteceu). A demanda avançou de
estágio sem que o conteúdo da aprovação correspondesse ao que o nome do estágio ("build")
implica. Isso é, em si, a falha a reportar — não um defeito de funcionalidade, porque não
há funcionalidade construída para ter defeito.

Os casos abaixo foram derivados dos critérios de aceite de `01-analise.md` (conforme
método desta etapa), não do que foi construído — porque nada foi construído. Todos saem
como **bloqueado/não executável**, não como "passou".

## 1. Org de teste — confirmação

Por guardrail #3 (nunca assumir alias sem confirmar), rodei `sf org list` antes de
escolher a org:

```
Type     Alias          Org Id              Status
Sandbox  sbx-eplast-qa  00DHa000006vZtmMAE  Connected
```

Só `sbx-eplast-qa` está conectada nesta sessão — `sbx-eplast-dev` não aparece na lista
(diferente do que o briefing desta etapa presumia como "esperado"). Segui a instrução
explícita para esse caso: testei na org que de fato conectou e declaro isso aqui, sem
assumir a outra.

`sf org display --target-org sbx-eplast-qa` mostra `instanceUrl` =
`https://eplast--qas.sandbox.my.salesforce.com`, com sufixo de host `qas`. O assessment
(achado 6) registrou `sbx-eplast-dev` apontando para host `eplast--qa` (sem o `s` final).
O host desta sandbox de qa tem sufixo `qas`, diferente do `qa` registrado para a de dev —
é um indício de que são instâncias distintas, mas **não é a confirmação completa que o
achado 6/G9 pede** (não testei `sbx-eplast-dev` nesta sessão porque ela não conectou; a
dúvida sobre separação real dev/qa segue em aberto para quem tiver as duas conectadas ao
mesmo tempo).

## 2. Evidência de ausência dos componentes propostos

Screenshot da tela "Relatórios → Recentes" em `sbx-eplast-qa` (dados de teste já
existentes na org de outras demandas, nenhum dado pessoal de cliente): os 5 relatórios
recentes são todos de `EPLAST-39` (Marketing/Campanhas). Nenhum relatório ou pasta de
`EPLAST-33` aparece — nem nos recentes, nem na contagem de 29 pastas totais levantada via
metadata API.

Consultas executadas (metadata e contagem, nenhuma com dado pessoal):
- `sf org list metadata --metadata-type ReportFolder` → 29 pastas, nenhuma compatível com
  `EPLAST_Oportunidades_Comerciais`.
- `sf org list metadata --metadata-type Report` → 0 relatórios retornados pela API de
  metadata para este usuário (limitação de visibilidade da API para este perfil, não
  necessariamente ausência total de relatórios na org — mas de qualquer forma, zero
  resultado é consistente com "nada desta demanda existe").
- `sf data query ... FROM ApexClass WHERE Name LIKE '%CrossSell%' OR Name LIKE
  '%Oportunidade%'` → 0 registros.

## 3. Casos de teste derivados de `01-analise.md` (critérios de aceite)

Todos os cenários do Gherkin em `01-analise.md` §4 já nasceram marcados
`[PENDENTE: Qn]` — a própria análise diz que só viram critério testável depois das
respostas de negócio, que nunca chegaram (G1–G9/Q1–Q19 seguem sem resposta em
`comentarios-do-card.md`). Ainda assim, tentei executar o que fosse mecanicamente
verificável.

| Caso | Passos | Esperado (critério de aceite) | Obtido | Status |
|---|---|---|---|---|
| Recuperação — conta sem compra há N meses aparece na lista | Rodar `Recuperacao_Contas_Sem_Compra` com fixture de conta sem Order há N meses | Conta aparece com motivo "sem compra desde \<data\>" | Relatório não existe na org. Nada para rodar | **BLOQUEADO** — build não executado |
| Aumento de volume — conta sem histórico não entra | Rodar `Volume_Variacao_Por_Conta` com conta de histórico curto | Conta não aparece como oportunidade de volume | Relatório não existe. N também nunca foi definido (G4/G5 pendentes) | **BLOQUEADO** |
| Aumento de volume — conta acima do limiar entra | Rodar o mesmo relatório com conta de variação alta | Conta aparece com variação calculada | Relatório não existe; limiar nunca foi definido (G5) | **BLOQUEADO** |
| Venda cruzada — produto aparece para conta que não comprou | Executar identificação de cruzada (opção B ou C) | Produto P aparece com motivo | Nenhum componente de B ou C existe — ambos ficaram no design como opções futuras, C explicitamente escalada e não aprovada (G7) | **BLOQUEADO** |
| Permissão — responsável vê só a própria carteira | Logar com usuário de carteira A, abrir a lista | Só oportunidades da carteira A aparecem | Não há lista nem filtro de carteira implementados; RN-4/G10 (definição de carteira) nunca foi respondida | **BLOQUEADO** |
| Não escrita — identificação não altera Account/Opportunity/Order/OrderItem | Contar registros antes/depois de rodar a identificação | Contagem e conteúdo idênticos; nenhum trigger/Flow disparado | Não há nada para "rodar" — nenhuma automação ou processo foi criado. Tecnicamente nenhuma escrita ocorreu, mas por ausência de construção, não por desenho verificado em execução real | **NÃO TESTÁVEL DA FORMA PRETENDIDA** (trivialmente verdadeiro por não existir, não porque foi comprovado em uso) |
| Saída sem campo fora da lista aprovada / sem dado pessoal | Inspecionar colunas da saída | Só campos aprovados; sem CPF/e-mail/telefone sem aprovação explícita | Não há saída nenhuma para inspecionar — lista de campos aprovada (Q11) nunca foi definida | **BLOQUEADO** |
| Apex novo com `<Classe>Test` e cobertura ≥ 85%, sem baixar cobertura org-wide | Rodar `sf apex run test` sobre classe(s) novas desta demanda | Classe de teste dedicada, cobertura ≥85%, org-wide não cai abaixo de 10% | Nenhuma classe Apex foi criada por esta demanda (opção C ficou escalada, nunca aprovada). Não há o que rodar | **NÃO APLICÁVEL** — critério só valeria se a opção C tivesse sido construída |

### Verificação automatizada que rodou de fato

```
sf org list                                            → confirma qual org conectou
sf org display --target-org sbx-eplast-qa --json       → confirma instância e tipo sandbox
sf org list metadata --metadata-type ReportFolder      → 29 pastas, nenhuma de EPLAST-33
sf org list metadata --metadata-type Report            → 0 relatórios retornados
sf data query ... FROM ApexClass WHERE Name LIKE ...   → 0 classes de cruzada/oportunidade
qa_browser_open/screenshot em sbx-eplast-qa             → Relatórios recentes, nenhum de EPLAST-33
```

Nenhuma dessas consultas retornou dado pessoal de cliente (guardrail #2): são contagens e
nomes de metadata, nunca registro de Account/Contact/Order com CPF, e-mail, telefone ou
valor.

## 4. Falhas

### FALHA 1 (crítica) — Demanda avançou ao estágio de QA sem nenhuma construção, com decisões bloqueantes do próprio design ainda sem resposta

**Resumo:** `03-design.md` §10 lista G1–G4 como pré-requisito explícito ("O build **não
começa** sem G1 a G4"). `04-plano-build.md` registra, de forma honesta e explícita, que o
build foi interrompido antes de começar por falta dessas respostas. Mesmo assim, o gate de
build foi aprovado (`gates.md`, Carlos Sordi, 2026-11-12T13:30:01) e a demanda avançou para
`qa`. Esta etapa confirmou de forma independente, contra a org real e contra o histórico de
commits, que **nenhum componente proposto no design existe** — nem na Fase 1 (relatórios,
pasta), nem na Fase 2 (agente ou Apex, que ficaram como opções condicionadas/escaladas, não
decididas).

**Impacto:** não há artefato nenhum para homologar. Qualquer homologação do estágio atual
seria homologar a ausência de solução, não a solução.

**O que destrava:** as respostas humanas a G1–G4 (e, se a Fase 2 for necessária, G5–G9),
registradas por escrito — idealmente no card ou em aditivo a `03-design.md`, como o próprio
`04-plano-build.md` já recomenda. Depois disso, a demanda precisa **voltar ao estágio de
build** (não simplesmente seguir em frente a partir do qa) para que o plano de build vire,
de fato, um plano — e metadata real seja criada em `sbx-eplast-dev` antes de qualquer novo
ciclo de QA.

### FALHA 2 (branda) — Achado 6/G9 do assessment (separação dev/qa) segue não confirmado nesta sessão

**Resumo:** `sbx-eplast-dev` não conectou nesta sessão (só `sbx-eplast-qa` apareceu em
`sf org list`). O indício coletado aqui (sufixo de host/usuário `qas` na org de qa, contra
`qa` registrado para a de dev no assessment) sugere que são instâncias distintas, mas não é
uma confirmação lado a lado — precisaria das duas conectadas na mesma sessão para comparar
Org Id diretamente.

**Impacto:** baixo para esta rodada específica, porque não houve build para rodar na sandbox
errada. Fica registrado para não represar a próxima rodada: antes de o build real acontecer,
vale confirmar as duas orgs lado a lado (G9, como o próprio design já pedia).

**O que destrava:** garantir que `sbx-eplast-dev` esteja autenticada na mesma execução em
que `sbx-eplast-qa` está, e comparar `Org Id` das duas via `sf org display` em cada uma.

## 5. O que não foi testável nesta sandbox (e por quê)

Todos os critérios de aceite de negócio (RN-1 a RN-4, Q1–Q19) são, ao mesmo tempo, não
testáveis **e** não aplicáveis nesta rodada: não testáveis porque as regras de negócio que
os cenários pedem (N meses, limiar de volume, grupo de referência, definição de carteira)
nunca foram respondidas por escrito (`comentarios-do-card.md` só tem aprovações genéricas de
gate); não aplicáveis porque, mesmo que fossem respondidas agora, não haveria componente
construído para testar contra elas. O único critério puramente técnico (cobertura Apex
≥85%) não se aplica porque nenhuma classe Apex foi criada.

---

Testes executados. Preciso da sua homologação para liberar o release.
