# SOMOSAGILITY-10 — Design da solução (enxuto, sustentação)

**Org consultada:** `sbx-somos-agility-dev` (`isSandbox: true`, `https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`).
**Base:** `01-analise.md` (aprovado em `gates.md`, 2026-10-21) + `02-recon.md` + verificações
complementares feitas nesta etapa (seção 2). Só metadata e `COUNT()` foram consultados; nenhum
registro de cliente (guardrail #2).

---

## 1. Resumo da decisão

**O que está quebrado:** o campo `PPM_Project__c.Total_de_despesas_realizadas__c` é recalculado pelo
Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto` só quando um
`Lancamento_de_Despesas__c` é salvo. A aprovação do GP muda a SR (`Solicitacao_de_Reembolso__c`), não o
Lançamento. O campo `Status_da_SR__c` do Lançamento é uma fórmula entre objetos e muda sozinho, sem
disparar Flow nem trigger. A peça que deveria re-salvar os Lançamentos quando a SR muda de etapa
(`SolicitacaoReembolsoTriggerHandler.afterUpdate` → `SolicitacaoReembolsoBO.updateLancamentosDespesas`)
está morta: o guard `Trigger.oldMap.keySet().equals(Trigger.newMap.keySet())` é sempre verdadeiro num
`afterUpdate`. E mesmo que rodasse, ela só agiria em `Status__c == 'Rejeitado'`. Confirmei os dois
pontos lendo o código.

**Correção (opção A, cadeia existente corrigida):**

1. **Apex (alterar):** em `SolicitacaoReembolsoTriggerHandler.afterUpdate`, trocar o guard morto por
   uma detecção de mudança real em `Status_de_Aprovacao_e_Etapas__c` ou em `Status__c`. Em
   `SolicitacaoReembolsoBO.updateLancamentosDespesas`, re-salvar os Lançamentos **com projeto** das SR
   que mudaram (inclusão e exclusão, não só rejeição), com trava de recursão.
2. **Flow (nova versão do existente):** abrir o critério de entrada para "Lançamento tem projeto"
   (hoje é "status já aprovado pelo GP"). Assim o total também **cai** quando a SR é rejeitada ou
   recolhida depois da aprovação do GP. A regra de soma (o filtro do Get Records) não muda.

Nenhum campo novo, nenhum objeto novo, nenhuma mudança de modelo de dados.

---

## 2. Verificações complementares feitas nesta etapa (além do `02-recon.md`)

Tudo abaixo foi confirmado na org. Os arquivos foram retidos para inspeção em diretório temporário,
fora do `force-app` do cliente.

| Item | Achado | Impacto no design |
|---|---|---|
| Etapas da SR | Os 4 processos de aprovação **ativos** (`ReembolsoMarketing4`, `ReembolsoPosVenda5`, `Reembolso_Comercial_pre_vendas_e_CS`, `SolicitacaoReembolsoBackofficeRHGov4`) gravam `Status_de_Aprovacao_e_Etapas__c` por field update em cada passo. O passo do GP leva a etapa a `Pendente - Gestor` ou `Pendente - Diretor`. A aprovação final grava `Aprovado`; a rejeição grava `Rejeitado`; o recall grava `Recall`. Nenhum desses field updates tem `reevaluateOnChange`. | Field update de aprovação dispara de novo o `before/after update` da SR, então o trigger da SR **vê** a mudança de etapa. Todos os valores pós-GP estão na lista do Flow. A regra do anexo está coberta. |
| Etapa inicial | O Flow `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` (SR, after-save, `Update`) grava a primeira etapa (`Pendente - Gerente de Projetos` ou direto `Pendente - Gestor`, conforme `TotalDespesaProjeto__c`). | É mais uma mudança de etapa que o handler vai detectar. Fica inofensiva: o Flow de soma não inclui `Pendente - Gerente de Projetos`. |
| Outras automações em `Lancamento_de_Despesas__c` (after-save) | Flows `atualizaAprovadorReembolso` e `sincroniza_campos` (este **sem critério de entrada**). **Os dois gravam na SR pai** a cada save de Lançamento. Trigger `RHX_Lancamento_de_Despesas` (Rollup Helper, pacote `rh2` instalado). | **Re-salvar Lançamento a partir da SR faz a SR ser gravada de novo → trigger da SR roda de novo.** Isso é risco de recursão, tratado na seção 4 (R1). |
| Rollup Helper / DLRS | `rh2` e `dlrs` instalados. DLRS: única regra relacionada é em `PPM_Project__c` ← `Hist_rico_de_Status_do_Projeto__c`, sem relação com despesas. Rollup Helper: **0 definições nesta sandbox**. Só que as definições do `rh2` são registros de dados, e esta sandbox não tem dados copiados. | **Não confirmado** se produção tem um rollup `rh2` gravando em algum campo de despesa de `PPM_Project__c`. Ver R7. |
| Validation rules em `Lancamento_de_Despesas__c` | 68 ativas, nenhuma usa `ISNEW`/`ISCHANGED`/`PRIORVALUE` e nenhuma usa `TODAY()`/`NOW()` (`Reembolso_Menor_30_dias` está **inativa**). Todas são de consistência do próprio registro (tipo × valor × km, vínculo projeto/contrato, e uma série por solicitante). | Re-salvar um registro que era válido quando foi gravado tende a passar. Registro legado gravado antes de alguma regra nova pode falhar → ver R5. |
| `TriggerHandler` (classe base) | Existe, com `bypass()` e `setMaxLoopCount()`. | Dá para usar sem framework novo. |
| Testes existentes | `SolicitacaoReembolsoBOTest` e `LancamentoDespesasBOTest` existem, **sem nenhum assert**. Não existe `SolicitacaoReembolsoTriggerHandlerTest`. Cobertura atual: `SolicitacaoReembolsoBO` 7/8, `SolicitacaoReembolsoTriggerHandler` 5/6. | Os testes precisam ser reescritos com assert (DoD) e a classe de teste dedicada precisa ser criada (convenção). |
| Volume | `COUNT()` = 0 em `PPM_Project__c`, `Lancamento_de_Despesas__c` e `Solicitacao_de_Reembolso__c` nesta sandbox. | Reprodução e testes manuais exigem massa sintética criada do zero, inclusive aprovadores para o processo de aprovação. |

---

## 3. Decisão e justificativa (configuração → declarativo → código)

### 3.1 Por que não configuração nativa
- **Roll-up summary nativo:** não existe aqui. A relação `Lancamento_de_Despesas__c → PPM_Project__c` é
  lookup, não master-detail, e o filtro depende de um campo do objeto "avô" (a SR).
- **DLRS / Rollup Helper (já instalados):** em modo real-time eles disparam na DML do filho, então têm
  **a mesma causa-raiz** (a fórmula entre objetos muda sem DML no Lançamento). Em modo agendado
  resolveriam com atraso, mas criariam um terceiro mecanismo escrevendo em despesas do projeto e
  exigiriam desligar o Flow atual. Isso é mais mudança e mais risco do que o bug pede.
- **Fórmula no projeto:** fórmula não agrega filhos.

### 3.2 Por que não um Flow novo (declarativo) no lugar do ajuste no Apex
Considerei duas variantes declarativas:

- **(B1) Flow after-save em `Solicitacao_de_Reembolso__c` que busca e re-salva os Lançamentos.**
  Funciona, mas a SR **já tem** um trigger Apex com exatamente essa responsabilidade, só que defeituoso.
  Criar o Flow deixaria dois mecanismos no mesmo objeto e evento (trigger + Flow, além do
  `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` que já existe), um código morto que alguém
  "consertaria" depois duplicando o efeito, e a recursão SR → Lançamento → SR, que em Flow não tem
  controle de estado por transação. A doutrina lista "recursão que exige controle de estado" como
  motivo para Apex.
- **(B2) Flow em SR que recalcula e grava direto no projeto, sem re-salvar o Lançamento.** Duplica a
  regra de soma em dois Flows: dois lugares para manter o mesmo filtro de status, que divergiriam com
  o tempo. Além disso exige Get Records por projeto dentro de loop. E não corrige o caminho de
  rejeição de `Despesas_Realizadas__c`, que é o mesmo defeito.

**A "descida" para código aqui é corrigir código que já existe e é a parte quebrada, não criar
código novo.** São ~15 linhas em duas classes existentes, com teste determinístico. O que já é
declarativo continua declarativo (o Flow de soma recebe só ajuste de critério).

### 3.3 Por que mexer no Flow também
Só corrigir o Apex resolve a **inclusão** (GP aprova → Lançamentos re-salvos → Flow roda, porque o
status agora está na lista). Mas não resolve a **exclusão**: se a SR for rejeitada ou recolhida
depois da aprovação do GP, os Lançamentos são re-salvos com status `Rejeitado`/`Recall`, o critério
de entrada atual barra o Flow, e o total fica com a despesa rejeitada. Isso fere o critério de
aceite "SR fora do critério de inclusão não entra na soma".

---

## 4. Componentes

### 4.1 Alterar

| Componente | Tipo | Alteração |
|---|---|---|
| `SolicitacaoReembolsoTriggerHandler` | ApexClass | `afterUpdate`: remover o guard `oldMap.keySet().equals(newMap.keySet())`. Montar a lista de SR em que `Status_de_Aprovacao_e_Etapas__c` **ou** `Status__c` mudou (comparando com `Trigger.oldMap`) e chamar o BO só com elas. Lista vazia → não chama. `afterInsert` sem mudança. |
| `SolicitacaoReembolsoBO` | ApexClass | `updateLancamentosDespesas`: (a) remover o filtro `Status__c == 'Rejeitado'` (quem filtra agora é o handler, por mudança); (b) trava de recursão estática por transação, chaveada em `Id da SR + valor de Status_de_Aprovacao_e_Etapas__c` (uma SR já processada naquela etapa não é processada de novo; se mudar de etapa de novo na mesma transação, processa); (c) SOQL buscando só Lançamentos com `Relacionado_ao_Projeto__c != null` (os demais não alimentam total de projeto, então re-salvá-los é só custo); (d) `Database.update(lancamentos, false)` com log de falhas por registro, em vez de `update` tudo-ou-nada (ver R5, ponto de decisão D3). Uma SOQL e uma DML, fora de loop. |
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Flow (nova versão, a atual vira inativa) | (a) Critério de entrada: trocar o "OU" de 4 status por `Relacionado_ao_Projeto__c` **IsNull = false**. Continua havendo critério de entrada, e ele impede o caso de hoje em que um Lançamento sem projeto faria o Get Records filtrar `Relacionado_ao_Projeto__c = null` (todos os Lançamentos sem projeto da org). (b) Variável `somatorio_das_despesas` com valor padrão `0`: sem isso, projeto sem nenhum Lançamento elegível ficaria com o total **nulo** (RN-08 → 0). (c) Remover o elemento `Atualiza_com_o_valor_0`: com o padrão 0 ele vira uma segunda DML redundante em `PPM_Project__c` por execução, e cada DML em `PPM_Project__c` dispara ~20 Flows after-save de "Projeto Agility" mais o `PPMProjectTrigger`. (d) Atualizar a descrição com data e demanda. Filtro do Get Records, loop, decisão de quilometragem e regra de soma **sem mudança**. |
| `SolicitacaoReembolsoBOTest` | ApexClass (teste) | Reescrever com asserts sobre `Total_de_despesas_realizadas__c` e `DespesasRealizadasAtividades__c` (cenários na 4.4). Não reaproveitar o CPF fixo usado hoje no fixture; usar valor sintético gerado. |

### 4.2 Criar

| Componente | Tipo | Motivo |
|---|---|---|
| `SolicitacaoReembolsoTriggerHandlerTest` | ApexClass (teste) | Convenção `<Classe>Test`. Cobre detecção de mudança (muda etapa → re-salva; update sem mudança de etapa → não re-salva) e a recursão via `sincroniza_campos`/`atualizaAprovadorReembolso`. |

### 4.3 Depreciar
Nada.

### 4.4 Cenários de teste unitário (mínimo, para o `dev-apex`)
Projeto + SR + Lançamentos sintéticos, `IdMSProject__c` nulo (evita o callout), sem `SeeAllData`.
O Flow roda dentro do teste, então o assert em `Total_de_despesas_realizadas__c` valida Apex + Flow
juntos.

1. SR `Pendente - Gerente de Projetos` → `Pendente - Gestor`: total passa a incluir os Lançamentos (com e sem quilometragem).
2. SR `Pendente - Gestor` → `Rejeitado`: total volta a excluir.
3. SR `Aprovado` → `Recall`: total exclui.
4. Projeto sem Lançamento elegível: total = 0 (não nulo).
5. Update na SR sem mudar etapa: nenhum Lançamento re-salvo (assert via `LastModifiedDate`/contador, ou Limits).
6. Bulk: 200 SR mudando de etapa numa DML, com Lançamentos em vários projetos, sem estourar limite; registrar `Limits.getQueries()`/`getDmlStatements()`.
7. Vários Lançamentos de uma SR no **mesmo** projeto: total correto (cobre R8).
8. Recursão: confirmar que o update da SR feito por `sincroniza_campos` não re-dispara o re-save (contagem de execuções).

Cobertura ≥ 85% por classe, com asserts reais (DoD).

### 4.5 Esboço da detecção de mudança (orientação ao build, não é código final)

```apex
// SolicitacaoReembolsoTriggerHandler.afterUpdate
Map<Id, Solicitacao_de_Reembolso__c> oldMap = (Map<Id, Solicitacao_de_Reembolso__c>) Trigger.oldMap;
List<Solicitacao_de_Reembolso__c> mudaram = new List<Solicitacao_de_Reembolso__c>();
for (Solicitacao_de_Reembolso__c s : (List<Solicitacao_de_Reembolso__c>) Trigger.new) {
    Solicitacao_de_Reembolso__c o = oldMap.get(s.Id);
    if (s.Status_de_Aprovacao_e_Etapas__c != o.Status_de_Aprovacao_e_Etapas__c || s.Status__c != o.Status__c) {
        mudaram.add(s);
    }
}
if (!mudaram.isEmpty()) SolicitacaoReembolsoBO.updateLancamentosDespesas(mudaram);
```

---

## 5. Conflito de automação e ordem de execução

**RISCO DE ORDEM DE EXECUÇÃO: `Lancamento_de_Despesas__c` (after update) tem 2 triggers Apex
(`TrgLancamentoDeDespesas`, `RHX_Lancamento_de_Despesas`) e 3 Flows after-save
(`Atualiza_valor_total_de_despesas_realizadas_no_projeto`, `atualizaAprovadorReembolso`,
`sincroniza_campos`). A ordem entre os dois triggers não é garantida pela plataforma, e a ordem
entre os 3 Flows também não, a menos que haja Trigger Order configurado.** Hoje esses mecanismos
escrevem em **campos diferentes**: o Flow de soma grava `Total_de_despesas_realizadas__c`; o Apex
grava `DespesasRealizadasAtividades__c` (e, via `PPMProjectTrigger`, `Despesas_Realizadas__c`); os
outros dois Flows gravam na SR. Por isso a ordem não muda o resultado do campo desta demanda,
**desde que nenhum rollup `rh2` de produção grave no mesmo campo** (R7, não confirmável nesta
sandbox).

**RISCO DE RECURSÃO: SR (after update) → re-save de Lançamentos → `sincroniza_campos` e
`atualizaAprovadorReembolso` gravam na SR → trigger da SR roda de novo → …** Sem trava, isso é
loop até estourar o limite. Mitigação em duas camadas: (1) o handler só age quando a etapa ou o
status **mudou** em relação a `Trigger.oldMap`, e na DML aninhada feita por esses Flows a etapa
não muda; (2) trava estática por `SR + etapa` no BO, para o caso de re-disparo por field update de
aprovação, em que `Trigger.old` ainda carrega o valor anterior à DML original. Teste 8 da 4.4 cobre isso.

**SR (after update) também tem 2 mecanismos:** o trigger `TrgSolicitacaoReembolso` e o Flow
`Atualiza_o_status_de_aprovacao_e_etapas_da_SR`. Pela ordem de execução, o trigger roda antes do
Flow after-save. A gravação de etapa feita pelo Flow é uma DML separada, que o trigger vê como
mudança e trata normalmente (re-save inofensivo para o total, porque `Pendente - Gerente de
Projetos` não entra na soma). A correção não depende dessa ordem, só de o trigger rodar em toda
mudança de etapa.

---

## 6. Limites de governador e escala

Cascata por mudança de etapa de uma SR (caso típico, aprovação na tela, 1 SR, 1 projeto, N Lançamentos):

| Passo | SOQL | DML |
|---|---|---|
| BO da SR: busca Lançamentos com projeto | 1 | 1 (N registros) |
| `LancamentoDespesasBO.atualizarValorProjeto` | 1 | 1 (`PPM_Project__c`) → `PPMProjectTrigger` + ~20 Flows after-save de projeto |
| Flow de soma (bulkificado entre interviews) | 1 | 1 (`PPM_Project__c`, de novo a cascata do projeto). Hoje são 2 DML; a correção remove 1 |
| `atualizaAprovadorReembolso` (Get SR, Get User) + `sincroniza_campos` | ~2–3 | 2 (SR) → before-save Flows da SR + trigger da SR (não age, sem mudança) |

- **Sem SOQL/DML em loop** no código novo. O loop do Flow é sobre coleção em memória.
- **Ponto de atenção real:** os ~20 Flows after-save de `PPM_Project__c` rodam a cada DML no projeto (2× por mudança de etapa depois da correção, 3× antes). Não os abri nesta etapa. O limite de 100 SOQL fica **a medir**, não estimado: o roteiro de QA precisa registrar `Limits` do log de debug para N = 1, 50 e 200 Lançamentos numa SR.
- **`@future`:** quando `Despesas_Realizadas__c` muda e o projeto tem `IdMSProject__c`, `PPMProjectBO.updateInProject` enfileira 1 `@future(callout=true)` **por projeto** (limite de 50 por transação). Na aprovação pela tela é 1 SR → poucos projetos → ok. Carga em massa de SR (data loader) com mais de 50 projetos integrados mudando de valor estouraria. Esse risco já existia no código (R4).
- **Volume de produção:** desconhecido (sandbox vazia). Ver D2.

---

## 7. Impacto em permissões
**Nenhum.** Sem campo, objeto ou classe chamada por usuário. Classes de trigger sem declaração de
sharing rodam em contexto de sistema; o Flow record-triggered roda em contexto de sistema. Nenhum
perfil ou permission set muda.

---

## 8. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | Recursão SR → Lançamento → SR (seção 5) | **Alta** se não tratado | Detecção de mudança + trava estática; teste 8 |
| R2 | Cascata de automação de `PPM_Project__c` (~20 Flows) somada à do Lançamento consome SOQL/CPU na aprovação | Média | Remover a DML redundante do Flow; medir `Limits` em QA com N=1/50/200; se passar de ~70% do limite, voltar ao design antes do release |
| R3 | **Mudança de comportamento em `Despesas_Realizadas__c` e na integração MS Project:** com o re-save funcionando, rejeição de SR passa a **subtrair** de `Despesas_Realizadas__c` (que é a regra que o próprio código sempre quis aplicar e nunca aplicou) e dispara callout para o MS Project | Média (negócio) | Decisão D1 no gate. Avisar o cliente que valores no MS Project vão mudar em projetos com SR rejeitada a partir do go-live |
| R4 | Limite de 50 `@future` / chamada de `@future` a partir de contexto assíncrono (batch/future que atualize SR) | Baixa | Já existia. Documentar em `06-entrega.md`; não é corrigido aqui |
| R5 | Lançamento legado que viola uma validation rule criada depois dele falha no re-save. Com `update` tudo-ou-nada isso **bloquearia a aprovação da SR** | Média | `Database.update(..., false)` + log de falha (D3). Resíduo: o total daquele projeto fica sem esse Lançamento até alguém corrigir o registro |
| R6 | SR travada pelo processo de aprovação sendo gravada por `sincroniza_campos`/`atualizaAprovadorReembolso` durante a cascata | Média | Esses Flows já gravam na SR hoje, em todo save de Lançamento. Validar com submissão real de aprovação em sandbox (massa sintética) antes do PR. Se falhar, o build para e volta ao design |
| R7 | Rollup Helper (`rh2`) com definição em produção gravando em campo de despesa do projeto: **não confirmável** nesta sandbox (definições são dados, sandbox sem dados) | Baixa/Média | Pergunta ao cliente ou conferência na sandbox de QA, se ela tiver cópia de dados. Se existir, voltar ao design |
| R8 | Várias interviews do Flow atualizando o **mesmo** projeto no mesmo lote | Baixa | Teste 7 e cenário manual com vários Lançamentos de um projeto |
| R9 | Metadata desta sandbox de dev divergente de produção (a descrição do Flow de etapa diz "atualizado em 28/05/2026"; há edição recorrente pelo time do cliente) | Média | Antes do deploy em QA, o `release` compara as versões de Flow e classes em QA com as de dev. Divergência → parar e alinhar com o humano. O agente não acessa produção |
| R10 | Sandbox sem massa: reprodução exige criar conta, contato, projeto, SR, Lançamentos e aprovadores sintéticos | Baixa (esforço) | Já está na estimativa. Nunca usar dado real |

---

## 9. Pontos de decisão para o gate (humano)

- **D1 — `Despesas_Realizadas__c` (o segundo campo).** Recomendação: **fora do escopo de regra** nesta
  demanda (não trocar o filtro `!= 'Rejeitado'` pela regra "após aprovação do GP"). Motivos: a demanda
  e o anexo citam o campo "Total de despesas realizadas" (`Total_de_despesas_realizadas__c`); o outro
  campo alimenta o MS Project, e mudar a regra dele é mudança de regra de negócio, não correção de
  defeito (P-04 da análise). **Mas é preciso aceitar explicitamente o efeito colateral R3:** como os
  dois campos dependem do mesmo re-save, corrigir o bug faz `Despesas_Realizadas__c` passar a
  descontar SR rejeitadas, como o código original pretendia. Se o cliente quiser que os dois campos
  sigam a mesma regra, isso vira demanda própria de melhoria.
- **D2 — Recálculo retroativo (RN-07).** Recomendação: **não faz parte desta demanda; vira demanda
  separada.** A correção só age dali em diante: projetos com SR aprovadas pelo GP antes do go-live
  continuam com o total errado até algum Lançamento deles ser salvo. Um recálculo em massa (a) é
  escrita em produção, proibida ao agente, e (b) se feito por re-save de Lançamentos, dispara a
  integração MS Project para todo projeto cujo `Despesas_Realizadas__c` mudar, e por Batch Apex
  quebraria com `@future` chamado de contexto assíncrono. O desenho certo depende de volume
  (contagem agregada de projetos afetados em produção, fornecida pelo cliente) e de decidir se o
  recálculo deve tocar só `Total_de_despesas_realizadas__c`. É decisão do humano, não minha.
- **D3 — Re-save parcial (`allOrNone=false`).** Recomendação: aceitar, porque é melhor não bloquear
  a aprovação do GP por um Lançamento legado inválido. O custo é que a falha fica silenciosa para o
  usuário (só no log).
- **RN-08 — sem Lançamento elegível → total `0`.** Assumido no design. Baixo risco, mas confirmar
  com o cliente no gate.

---

## 10. O que NÃO será feito nesta demanda
- Mudar a regra de inclusão de `Despesas_Realizadas__c` / `DespesasRealizadasAtividades__c` (D1).
- Recálculo retroativo de projetos existentes (D2).
- Recalcular o projeto quando um Lançamento é **excluído** ou **trocado de projeto**: nem o Flow nem o
  Apex tratam isso hoje, e o cliente informou que não há mais lançamento manual. Registrado como
  limitação conhecida.
- Corrigir o limite de `@future` por projeto em `PPMProjectBO.updateInProject` (R4).
- Mexer nos processos de aprovação, nos Flows `atualizaAprovadorReembolso`/`sincroniza_campos` ou nos
  ~20 Flows de `PPM_Project__c`.
- Revisar a regra do `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` que manda algumas SR direto para
  `Pendente - Gestor` sem passar pelo GP (é regra do cliente, não faz parte deste bug).
- Qualquer ação em produção.

---

## 11. Perguntas da análise: situação

| Pergunta | Situação |
|---|---|
| RN-01, RN-02, RN-03, RN-05, RN-06 | Respondidas pelo recon (objetos, ponte via `Lancamento_de_Despesas__c`, campo comum preenchido por Flow) |
| RN-04 | Respondida pelo anexo: a partir da aprovação do GP |
| RN-07 | **Aberta → D2** |
| RN-08 | Assumida `0` → confirmar no gate |
| Q6 (valor errado observado) | Explicado pelo diagnóstico; não reproduzido (sandbox sem dados). A reprodução sintética é o 1º passo do build |
| Q7/Q8 (desde quando / quais projetos) | Abertas, não bloqueiam o build. Pela leitura do código, afeta todo projeto cujas SR foram aprovadas sem edição posterior do Lançamento |

---

## 12. Estimativa

**Estimativa de esforço:** 10–16 h

Esforço humano (consultor revisando PR, montando massa sintética, homologando em QA), não o tempo do
agente. Composição: Apex + Flow, 2–3 h; testes Apex com asserts e bulk (o fixture é trabalhoso:
contato com campos obrigatórios, PIN, projeto, SR, Lançamentos válidos frente a 68 validation
rules), 3–5 h; reprodução sintética com processo de aprovação real em sandbox (aprovadores de
teste), medição de `Limits` e homologação, 4–6 h; PR e documentação, 1–2 h.

**O que mudou em relação à análise (6–16 h):** o piso subiu de 6 para 10 h. A análise considerava a
possibilidade de um ajuste de roll-up ou filtro (ponta P), e o recon descartou isso: é um defeito de
disparo que exige Apex + Flow + testes de recursão, numa sandbox sem massa de dados. O teto se
manteve em 16 h porque a mudança é pequena, não há modelo de dados novo e **o recálculo retroativo
saiu do escopo (D2)**. Se D2 for puxado para dentro desta demanda, a estimativa precisa ser refeita.
