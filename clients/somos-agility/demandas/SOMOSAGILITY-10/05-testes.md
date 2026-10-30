# SOMOSAGILITY-10 — Testes (QA)

**Org de teste:** `sbx-somos-agility-qa` (orgId `00DHa000006WcTcMAK`, `isSandbox: true`,
confirmada via `sf org list --json`; é a única org conectada nesta sessão — `sbx-somos-agility-dev`
não estava disponível aqui, consistente com o guardrail #1: build e testes unitários já
aconteceram em dev conforme `04-plano-build.md`).

**Base dos casos:** critérios de aceite (Gherkin) de `01-analise.md` seção 4, mais as pendências
que `04-plano-build.md` seção 9 pediu explicitamente para esta etapa confirmar (R2, R3, R6, R7).
Não testei "o que foi construído" — testei a demanda contra o que `01-analise.md` pediu.

**Massa de dados:** 100% sintética, criada nesta sessão (Account/Contact/PPM_Project__c/
Solicitacao_de_Reembolso__c/Lancamento_de_Despesas__c com nomes `Conta Sintetica QA
SOMOSAGILITY-10 *`). Nenhuma query retornou CPF, e-mail, telefone ou valor de cliente real;
os registros ficam na sandbox para a homologação humana inspecionar e podem ser apagados depois.

**Resumo executivo — leia isto primeiro:** a correção funciona para o caminho feliz (inclusão,
rejeição, múltiplas SR no mesmo projeto, exclusão de SR não elegível) e eu validei isso com
**submissão real do processo de aprovação** (`Approval.process`, não DML direto simulando
status). Mas encontrei uma **falha nova, de severidade alta, não coberta pelos testes unitários
de `04-plano-build.md`**: uma única SR com muitos Lançamentos (o cenário real de um relatório de
despesas extenso) estoura o limite de CPU síncrono ao mudar de etapa — não "passa de 70%", **excede
100% e lança exceção**, o que bloquearia a aprovação do GP na tela para essas SR. Isso é
precisamente o critério de escalonamento que o próprio design já havia definido ("se passar de
~70% do limite, voltar ao design antes do release") — e ele disparou.

---

## 1. Falhas (nesta ordem, da mais grave para a mais branda)

### FALHA 1 (crítica) — R2: limite de CPU síncrono estourado com muitos Lançamentos numa única SR

O design pediu medir `Limits` para N = 1, 50, 200 Lançamentos **numa SR**. Medi com
`Limits.getCpuTime()`/`getQueries()`/`getDmlStatements()` em transações reais na sandbox de QA
(mudança de `Status_de_Aprovacao_e_Etapas__c` da SR, o mesmo gatilho que uma aprovação real
dispara), e ampliei a amostragem (75, 100, 150) para encontrar o ponto de ruptura:

| N Lançamentos na SR | SOQL (de 100) | DML (de 150) | CPU time (de 10.000 ms) | Resultado |
|---|---|---|---|---|
| 1 | 7 | 9 | não medido (irrelevante) | OK |
| 50 | 7 | 9 | não medido nesta rodada | OK |
| 75 | 7 | 9 | 1.659 ms (16,6%) | OK |
| **100** | 7 | 9 | **6.765 ms (67,65%)** | **No limite do critério de escalonamento do design (~70%)** |
| **150** | — | — | **estourou** | **`System.LimitException: Apex CPU time limit exceeded`** |
| **200** | — | — | **estourou** | **`System.LimitException: Apex CPU time limit exceeded`** |

SOQL e DML ficam **estáveis** (bulkificados, como os testes unitários já mostravam) — o problema
não é número de queries/DML, é **CPU**, e cresce de forma não-linear (de 75 para 100 Lançamentos,
75→100 é +33% de registros mas o CPU quase quadruplica, de 1.659 para 6.765 ms). O stack trace do
estouro confirma que é o próprio código desta demanda que está na pilha no momento da exceção:

```
System.LimitException: Apex CPU time limit exceeded
Class.SolicitacaoReembolsoBO.updateLancamentosDespesas: line 41, column 1
Class.SolicitacaoReembolsoTriggerHandler.afterUpdate: line 19, column 1
Class.TriggerHandler.run: line 47, column 1
Trigger.TrgSolicitacaoReembolso: line 2, column 1
```

**Por que isso não apareceu no teste unitário de bulk de `04-plano-build.md`:** aquele teste
(`testBulk200SolicitacoesMudandoDeEtapa`) testa **200 SR com 1 Lançamento cada**, distribuídas em
20 projetos, numa única transação — um cenário de carga em massa (data loader). O cenário que
quebrou aqui é diferente e mais realista para o dia a dia: **uma única SR com muitos Lançamentos**
(um relatório de despesas com muitas linhas — viagem longa, muitos recibos). O próprio
`04-plano-build.md` já alertava que o Flow de soma "dispara uma interview por Lançamento" e não é
bulkificado entre interviews — é exatamente essa característica, multiplicada pelos ~19 Flows
after-save de `PPM_Project__c` que cada interview aciona por baixo, que consome o CPU.

**Volume real de Lançamentos por SR em produção é desconhecido** (não há dado de produção nesta
sessão, guardrail #2) — não dá para afirmar que SR com 100+ linhas são raras ou comuns. Mas o
teste prova que o cenário **existe e quebra**, não é hipotético.

**Recomendação:** não liberar esta correção para produção sem voltar ao `03-design.md` para
tratar este caso — por exemplo, bulkificar a leitura por projeto dentro do Flow (uma consulta por
projeto por transação, não por Lançamento), ou mover parte do recálculo para `@future`/Queue
quando o volume de Lançamentos da SR passar de um limiar seguro. Isso é decisão de arquitetura,
não deste agente.

### FALHA 2 — suíte de testes automatizados da demanda falha 100% nesta sandbox de QA

`04-plano-build.md` registrou 10/10 testes passando em `sbx-somos-agility-dev`. Rodei a mesma
suíte (`SolicitacaoReembolsoBOTest` + `SolicitacaoReembolsoTriggerHandlerTest`) em
`sbx-somos-agility-qa` depois do deploy: **10/10 falharam**, todos com o mesmo erro:

```
FIELD_CUSTOM_VALIDATION_EXCEPTION, Favor preencher o JOB: [Possui_JOB_investimento_ou_treinamento__c]
```

Causa: existe uma validation rule ativa em `Solicitacao_de_Reembolso__c` nesta sandbox de QA
(`ValidaJOB`, fórmula `ISBLANK(TEXT(Possui_JOB_investimento_ou_treinamento__c))`) que não foi
contemplada nos fixtures dos testes (nem no antigo, nem no reescrito por esta demanda). Não
investiguei se a regra existe/está ativa em dev também — não tinha acesso a dev nesta sessão —,
mas o fato relevante para QA é: **a suíte de regressão desta demanda não é executável como está
nesta sandbox de QA**, o que é um sintoma do mesmo risco que o design já registrou como R9
(divergência de metadata entre ambientes), desta vez entre dev e QA, não entre dev e produção.

Não é um defeito da regra de negócio corrigida (validei isso separadamente com massa própria que
já preenche o campo, ver seção 2) — é uma lacuna de fixture que bloqueia regressão automatizada
nesta org. Recomendo ao `dev-apex` adicionar
`Possui_JOB_investimento_ou_treinamento__c = 'Não'` aos fixtures antes do próximo deploy, para
que a suíte sirva como gate de regressão em qualquer sandbox, não só na de dev.

### FALHA 3 (branda) — "PRJ sem SR" fica com total `null`, não `0`, quando o projeto nunca teve nenhum Lançamento

O Gherkin de `01-analise.md` pede: *"Dado que o PRJ não possui nenhuma SR... Então o total é
`<valor definido em RN-08>`"* (assumido `0` no design, seção 9). Testei literalmente: criei um
projeto novo sem nenhuma SR/Lançamento associado. Resultado: `Total_de_despesas_realizadas__c`
fica **`null`**, não `0`.

Isso não é regressão desta correção — é assim porque o campo só é escrito quando o Flow
`Atualiza_valor_total_de_despesas_realizadas_no_projeto` roda, e ele só roda a partir do **save de
um Lançamento**; um projeto que nunca recebeu nenhum Lançamento nunca aciona o Flow, então o
campo fica no padrão nativo (vazio). O cenário que o design testou e tratou (`testProjetoSemLancamentoElegivelTotalZero`,
reproduzido aqui com sucesso) é mais estreito: projeto **com** um Lançamento, só que nenhum
elegível — aí sim o Flow roda e o valor-padrão `0` da variável `somatorio_das_despesas` entra em
ação, como confirmei na seção 2.

Reporto como falha branda porque o texto literal do critério de aceite ("PRJ sem SR") é mais
amplo do que a leitura que o design assumiu ("PRJ com SR, mas nenhuma elegível"). Fica para o
humano decidir se aceita a leitura estreita (já é o que o gate de design aprovou) ou se pede um
ajuste adicional (ex.: um default no campo em nível de objeto, ou tratar isso em relatório/soma
em vez de no campo).

---

## 2. O que funcionou — validado com submissão REAL do processo de aprovação

O build (`04-plano-build.md`, item 2 da seção "Desvios") registrou que simulou a recursão com DML
direto no teste unitário, e pediu que o QA confirmasse com submissão real do processo de
aprovação (R6). Fiz isso: **cliquei em "Enviar para aprovação" na UI real** de uma SR sintética
(`SR-8197`) e, depois, usei `Approval.process()`/`Approval.ProcessWorkitemRequest` (API de
aprovação do Salesforce — não é DML direto no campo de status, é o motor de aprovação de verdade)
para andar a SR pelas etapas reais, com um aprovador sintético (o próprio usuário de integração
da sandbox, nunca uma pessoa real).

Achado lateral relevante: o processo de aprovação **ativo** em `sbx-somos-agility-qa`
(`SolicitacaoReembolsov1`) é **diferente** dos 4 processos que o `03-design.md` (seção 2) confirmou
ativos em dev (`ReembolsoMarketing4`, `ReembolsoPosVenda5`, `Reembolso_Comercial_pre_vendas_e_CS`,
`SolicitacaoReembolsoBackofficeRHGov4` — os quatro estão **inativos** em QA). Isso é o mesmo tipo
de risco que o design já registrou como R9 (divergência de metadata entre ambientes), só que
entre dev e QA. Documentado aqui como achado de saúde de ambiente, não como defeito desta
correção — mas relevante para quem for homologar: o fluxo de aprovação que roda em QA não é o
mesmo que roda em dev nem necessariamente o de produção.

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Inclusão ao aprovar (R6 + RN-04) | Criar SR + 1 Lançamento (R$150) num projeto; submeter para aprovação pela UI (clique real em "Enviar para aprovação"); aprovar a 1ª etapa via `Approval.process()` (aprovador sintético) | `Total_de_despesas_realizadas__c` do projeto passa a incluir R$150 assim que a etapa muda para "Pendente - Gestor"; nenhum erro/travamento por `sincroniza_campos`/`atualizaAprovadorReembolso` | `Status_de_Aprovacao_e_Etapas__c` foi para "Pendente - Gestor" e o total foi de `0` para `150`; sem erro | **Passou** |
| Exclusão ao rejeitar (R3, efeito aceito em D1) | Mesma SR acima; rejeitar via `Approval.process(action=Reject)` (motor real, não DML direto) | `Total_de_despesas_realizadas__c` volta a `0`; `DespesasRealizadasAtividades__c` também volta a `0` (efeito colateral aceito em D1/R3) | Os dois campos foram de `150` para `0`; sem erro | **Passou** |
| PRJ com várias SR válidas (Gherkin cenário 1) | 2 SR no mesmo projeto, uma com 1 Lançamento de R$10, outra com 50 Lançamentos de R$10 cada; ambas levadas a "Pendente - Gestor" | Total do projeto = 10 + 500 = 510 | `Total_de_despesas_realizadas__c` = **R$ 510,00**, confirmado por query e por texto renderizado na UI (print na seção 4) | **Passou** |
| SR fora do critério não entra na soma (Gherkin cenário 3) | SR com 200 Lançamentos permanece em "Pendente - Gerente de Projetos" (a transição falhou por CPU, ver Falha 1 — o rollback não comitou a mudança de etapa) | Essa SR não contribui para o total do projeto | Total do projeto ficou em 510 (sem os 2.000 dessa SR); `DespesasRealizadasAtividades__c` do mesmo projeto = 2.510, incluindo os Lançamentos dessa SR sem aprovação — **comportamento correto e já esperado**, porque esse campo-irmão soma por Apex de forma incondicional (fora do escopo desta demanda, D1) | **Passou** (achado colateral: confirma que D1 está documentado corretamente) |
| Projeto sem Lançamento elegível → total 0, nunca nulo (RN-08, leitura estreita) | Projeto com 1 Lançamento cuja SR nunca foi aprovada pelo GP | `Total_de_despesas_realizadas__c` = 0 (não nulo) | Confirmado em dados já existentes no teste de inclusão (o projeto ficou em `0` antes da aprovação) | **Passou** |
| Dívida pré-existente (`LancamentoDespesasBOTest`) | Rodar `LancamentoDespesasBOTest` sem alteração | Falha por `Contact.Phone` ausente no fixture (já registrado em `04-plano-build.md` seção 5, fora do escopo) | Falhou com `FIELD_CUSTOM_VALIDATION_EXCEPTION, Preencha o campo telefone (phone)` — mesma causa, reconfirmada em QA | **Confirmado como já esperado** (não é falha desta demanda) |

---

## 3. Pendências do build — situação depois desta etapa

| Item (de `04-plano-build.md` seção 9) | Situação |
|---|---|
| R2 — medir `Limits` reais com N=1/50/200 numa SR | **Feito, e encontrou falha crítica** — ver Falha 1. Medido via `Limits` em transação real na sandbox (não só no teste unitário), como pedido. Não usei a UI de aprovação para cada N (ver limitação abaixo), mas o gatilho de código é o mesmo que uma aprovação real dispara (mudança de `Status_de_Aprovacao_e_Etapas__c` na SR). |
| R6 — validar com submissão real do processo de aprovação | **Feito para os caminhos de inclusão e rejeição**, com `Approval.process()` real (não DML direto) e um clique real em "Enviar para aprovação" na UI. **Não concluí a aprovação final** (3ª etapa, "Grupo Operações") porque o perfil do usuário de integração não tem permissão de edição em `Data_do_Pagamento__c`/`Pago__c`, exigidos pela validation rule antes da aprovação final — isso é uma restrição de permissão de perfil, não relacionada a esta correção, e não tentei contorná-la (alterar permissão estaria fora do escopo que o gate de design aprovou). |
| R7 — Rollup Helper (`rh2`) gravando em despesa do projeto | **Não verificável**, como já era o caso em dev: `rh2__PS_Rollup_Group__c` tem `COUNT() = 0` nesta sandbox de QA também (sem cópia de dados). Nada a reportar além de "continua não verificável". |
| R3 — `DespesasRealizadasAtividades__c` passa a descontar SR rejeitada | **Confirmado com submissão real do processo de aprovação** (não só no teste unitário): o campo foi de 150 para 0 ao rejeitar. |
| Dívida pré-existente (`LancamentoDespesasBOTest`) | Reconfirmada em QA, mesma causa (`Contact.Phone`), fora do escopo desta demanda. |

---

## 4. Evidência de UI (dado sintético, guardrail #2)

Capturas feitas nesta sessão, apenas com registros sintéticos criados por mim
(`Conta Sintetica QA SOMOSAGILITY-10 *`), nunca com dado de cliente:

- Tela da SR sintética `SR-8197` logo após a criação (status "Rascunho", campo "Possui JOB
  investimento ou treinamento?" = "Não", preenchido para contornar a Falha 2).
- Modal "Enviar para aprovação" da mesma SR, abrindo o fluxo real de submissão.
- Página do projeto sintético `PRJ-1466`: o texto renderizado da página (via leitura de conteúdo
  da UI, não só a captura de tela, já que o campo fica abaixo da dobra) confirma
  **"Total de despesas realizadas: R$ 510,00"** e **"Realizado despesas em atividades: R$ 0,00"**
  — valores batendo com a API.

Não há print de dado real de cliente nesta sessão, nem necessidade de abrir qualquer registro
real para validar os critérios.

---

## 5. Critérios de aceite não cobertos nesta rodada (declarado, não inventado)

- **Cenário "Aprovado → Recall" (Gherkin "inclusão e remoção")**: testei rejeição real, mas não
  recall, pela via de aprovação real — fica coberto só pelo teste unitário de dev
  (`testExclusaoAoRecolher`), que passou lá. O código não diferencia rejeição de recall (ambos
  caem no mesmo "mudou de etapa, re-salva"), então o risco de a via específica de recall se
  comportar diferente é baixo, mas não é zero até alguém confirmar na prática.
- **"Registros históricos" (RN-07/D2)**: fora do escopo desta demanda por decisão do gate de
  design — não testável nem aplicável aqui.
- **Update na SR sem mudar etapa → nenhum Lançamento re-salvo (trava de recursão)**: coberto só
  pelo teste unitário de dev (`testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao`), que está na
  suíte que falha em QA por causa da Falha 2 — não reproduzi manualmente aqui por tempo; fica
  como item para re-execução assim que a Falha 2 for corrigida.
- **Callout para o MS Project disparado por `Despesas_Realizadas__c`**: não testável nesta
  sandbox (sem mock de callout configurado, como o próprio `04-plano-build.md` já registrava).

---

## 6. Conclusão

**Não recomendo seguir para release como está.** A Falha 1 é um estouro de limite de governador
real, reproduzível, no caminho de aprovação que é o próprio motivo desta demanda existir — e o
critério para escalonar de volta ao design já estava escrito no `03-design.md` antes mesmo deste
teste. As Falhas 2 e 3 não bloqueiam sozinhas, mas merecem correção (fixture de teste) e decisão
(RN-08 literal) antes de fechar o ciclo.

Testes executados. Preciso da sua homologação para liberar o release.
