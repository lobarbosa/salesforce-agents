# Recon da Org — SOMOSAGILITY-10

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0). Sandbox confirmada
via `sf org list` (`isSandbox: true`) e `sf org display` — org de dev da esteira, não produção.
**Data da coleta:** 2026-10-21.
**Cobertura:** metadata (objetos, campos, Flow, Apex) e `COUNT()` agregados apenas —
nenhuma consulta trouxe registro real (guardrail #2).

## 0. O que o anexo acrescentou à análise

O anexo liberado (e-mail do cliente) confirma a regra de negócio que `01-analise.md` listava
como RN-04 em aberto, sem precisar reproduzir nome, e-mail ou telefone de quem escreveu (todos
presentes no PDF, nenhum transcrito aqui — guardrail #2):

> Todas as SRs vinculadas ao PRJ devem ser aprovadas pelo GP (Gerente de Projetos); **a partir
> dessa aprovação (1 aprovação)** a soma deve ser feita e aparecer no campo "total de despesas
> realizadas". Hoje não há mais despesa lançada manualmente — o campo deve estar 100%
> automatizado.

O e-mail também trazia dois links para registros de **produção** (domínio
`agilitynetworks.lightning.force.com`, sem o sufixo `--sbxdev` da sandbox) — mesma situação já
registrada em outras demandas deste cliente: são exemplos do problema reportado, fora do
alcance deste agente (guardrail #1), e esta recon não tentou acessá-los.

## 1. "PRJ" e "SR" identificados na org

| Termo da demanda | Objeto confirmado | Como foi confirmado |
|---|---|---|
| PRJ | `PPM_Project__c` | URL do anexo aponta pra esse objeto; `sf sobject describe` confirma |
| SR | `Solicitacao_de_Reembolso__c` | nome bate com "Solicitação de Reembolso"; picklist de status bate com o fluxo de aprovação do GP descrito no anexo |

O campo citado no título da demanda existe exatamente como descrito:

- `PPM_Project__c.Total_de_despesas_realizadas__c` — label **"Total de despesas realizadas"**,
  tipo `currency`, **`calculated: false`, `updateable: true`**. Não é fórmula nem roll-up
  summary — é um campo comum, hoje preenchido só por automação (RN-06 da análise: resolvida).

Isso já responde RN-01/RN-02/RN-05/RN-06 da análise. RN-03 (como SR se relaciona ao PRJ) **não
é direta** — ver seção 2.

## 2. SR não se liga ao PRJ diretamente — há um objeto de lançamento no meio

`Solicitacao_de_Reembolso__c` **não tem nenhum campo de referência para `PPM_Project__c`**
(confirmado nos dois sentidos: nenhum lookup de SR aponta pra PPM_Project__c, e
`PPM_Project__c` não lista `Solicitacao_de_Reembolso__c` entre seus 90 relacionamentos filhos).

Quem faz a ponte é **`Lancamento_de_Despesas__c`** (linha de despesa), que referencia os dois:

- `Lancamento_de_Despesas__c.Solicitacao_de_Reembolso__c` → lookup para `Solicitacao_de_Reembolso__c`
- `Lancamento_de_Despesas__c.Relacionado_ao_Projeto__c` → lookup para `PPM_Project__c`
- `Lancamento_de_Despesas__c.Status_da_SR__c` → **campo fórmula entre objetos**:
  `TEXT(Solicitacao_de_Reembolso__r.Status_de_Aprovacao_e_Etapas__c)` — lê ao vivo o status de
  aprovação da SR pai. Este campo é o fio condutor do achado principal (seção 4).
- `Lancamento_de_Despesas__c.Valor_da_Despesa__c` / `Valor_da_Kilometragem__c` — valores somados.

Cadeia real: **PPM_Project__c ← Lancamento_de_Despesas__c → Solicitacao_de_Reembolso__c**
(RN-03 respondida: nem lookup direto nem master-detail entre PRJ e SR — a soma depende de um
terceiro objeto).

`Solicitacao_de_Reembolso__c` tem dois campos de status, usados por automações diferentes (ver
seção 4) — isso importa para o design:

- `Status__c` (picklist simples): `Rascunho`, `Pendente`, `Aprovado`, `Rejeitado`, `Recall`.
- `Status_de_Aprovacao_e_Etapas__c` (picklist com as etapas): `Rascunho`,
  **`Pendente - Gerente de Projetos`**, `Pendente - Gestor`, `Pendente - Diretor`,
  `Pendente - Operações`, `Aprovado`, `Rejeitado`, `Recall`.

A ordem do segundo picklist bate com a regra do anexo: uma vez que o GP aprova, o registro sai
de `Pendente - Gerente de Projetos` e passa para `Pendente - Gestor` (ou adiante) — ou seja,
"aprovado pelo GP" na prática é "`Status_de_Aprovacao_e_Etapas__c` em qualquer valor a partir
de `Pendente - Gestor`, incluindo `Aprovado`".

## 3. Mecanismo hoje: há DOIS campos de "total de despesas" e DUAS automações, não uma

Achado que a análise não tinha como prever sem ver a org: `PPM_Project__c` tem dois campos de
rótulo quase idêntico, mantidos por caminhos de automação **independentes**:

| Campo | Label | Quem mantém | Filtro de inclusão aplicado |
|---|---|---|---|
| `Total_de_despesas_realizadas__c` | "Total de despesas realizadas" (o da demanda) | **Flow** `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | `Status_da_SR__c` em `Pendente - Gestor`, `Pendente - Diretor`, `Pendente - Operações` ou `Aprovado` (ou seja, a partir da aprovação do GP — **bate com a regra do anexo**) |
| `Despesas_Realizadas__c` (via `DespesasRealizadasAtividades__c`) | "Total de Despesas Realizadas" | **Apex** (`LancamentoDespesasBO.atualizarValorProjeto`, chamado pelo trigger de `Lancamento_de_Despesas__c`) | `Status_da_SR__c != 'Rejeitado'` — **inclui Rascunho e Pendente, não só aprovado** |

Os dois leem o mesmo campo fórmula `Status_da_SR__c`, mas com regras de inclusão diferentes, e
escrevem em campos diferentes. Não são a mesma soma com nomes parecidos — são dois cálculos
paralelos, e só um deles (`Total_de_despesas_realizadas__c`, via Flow) implementa a regra que o
cliente descreveu. Isso é relevante pro arquiteto decidir **qual campo é o oficial** antes de
desenhar a correção — tocar no caminho errado "resolve" sem corrigir o campo que o cliente olha.

### 3.1 O Flow (`Total_de_despesas_realizadas__c`) — lido na íntegra

- `AutoLaunchedFlow`, record-triggered em **`Lancamento_de_Despesas__c`**, `RecordAfterSave`,
  `CreateAndUpdate`.
- Condição de entrada: `Status_da_SR__c` em (`Pendente - Gestor`, `Pendente - Diretor`,
  `Pendente - Operações`, `Aprovado`) — **correta frente à regra do anexo**.
- Ao rodar: zera `Total_de_despesas_realizadas__c` do projeto relacionado, busca **todos** os
  `Lancamento_de_Despesas__c` do mesmo projeto que atendem à mesma condição de status, soma
  `Valor_da_Kilometragem__c` (para despesas de quilometragem) ou `Valor_da_Despesa__c` (demais
  tipos) e grava o total.
- **O problema não está na regra de soma nem no filtro — está em quando o Flow roda.** Ele só
  dispara quando um registro de `Lancamento_de_Despesas__c` é **salvo** (criado ou editado).
  `Status_da_SR__c` é um campo fórmula entre objetos: seu valor muda sozinho quando a SR pai
  muda de status, **sem que isso grave (`DML`) o `Lancamento_de_Despesas__c`** — é
  comportamento de plataforma, não hipótese: campo fórmula entre objetos é recalculado na
  leitura, não dispara trigger/Flow no registro que o contém. Então, **quando o GP aprova a SR
  (ou a aprovação avança de etapa), nenhum `Lancamento_de_Despesas__c` é salvo de novo**, e o
  Flow não roda — a menos que algo mais explicitamente volte a salvar aqueles registros. A
  seção 3.2 é exatamente sobre esse "algo".

### 3.2 O que deveria "tocar" o Lançamento de Despesas quando a SR aprova — e não toca

Existe automação para isso, mas tem dois defeitos, confirmados lendo o Apex:

```apex
// SolicitacaoReembolsoTriggerHandler.afterUpdate()
public override void afterUpdate() {
    if(Trigger.isExecuting && Trigger.oldMap.keySet().equals(Trigger.newMap.keySet())) {
        return;
    }
    SolicitacaoReembolsoBO.updateLancamentosDespesas((List<Solicitacao_de_Reembolso__c>)Trigger.new);
}
```

**Defeito 1 (trava o método inteiro):** em qualquer `afterUpdate`, `Trigger.oldMap` e
`Trigger.newMap` contêm exatamente os mesmos Ids (são os mesmos registros, antes e depois da
edição) — `.keySet().equals(...)` é **sempre verdadeiro**. O `return` sempre executa primeiro.
`SolicitacaoReembolsoBO.updateLancamentosDespesas(...)` **nunca roda a partir de uma edição de
SR** — só rodaria em `afterInsert` (SR criada já com o status final, cenário raro). Isto não é
uma leitura de intenção torta: é uma condição que não pode logicamente ser falsa num
`afterUpdate`, então o branch que ela guarda está morto em produção hoje.

**Defeito 2 (mesmo se o Defeito 1 não existisse):** o método só age quando
`Status__c == 'Rejeitado'`:

```apex
// SolicitacaoReembolsoBO.updateLancamentosDespesas
for(Solicitacao_de_Reembolso__c s : solicitacoes) {
    if(s.Status__c == 'Rejeitado')
        idsSolicitacoesReembolsos.add(s.Id);
}
// ...busca os Lancamento_de_Despesas__c dessas SRs e faz `update lancamentos;` (touch, sem
// mudar campo) — é isso que faria o Flow/Apex de recálculo do projeto rodar de novo.
```

Ou seja: mesmo corrigindo o Defeito 1, esse "touch" só existe para **remover** despesas de SR
rejeitada do total — não existe o equivalente para **incluir** quando a SR é aprovada pelo GP
(`Status_de_Aprovacao_e_Etapas__c` avança de `Pendente - Gerente de Projetos` para
`Pendente - Gestor`/`Aprovado`). Esse é o caminho que falta, e é exatamente o que a demanda
reporta.

Note também que esse método lê `Status__c` (o picklist simples), enquanto o Flow e o Apex de
soma leem `Status_da_SR__c`/`Status_de_Aprovacao_e_Etapas__c` (o picklist de etapas) — mais um
sinal de que a automação existente não foi desenhada como uma peça só.

### 3.3 Cadeia Apex de `Despesas_Realizadas__c` (o outro campo) — lida na íntegra

`Lancamento_de_Despesas__c` (afterInsert/afterUpdate) → `LancamentoDespesasBO.atualizarValorProjeto`
soma `Valor_Total_da_Despesa__c` de todo `Lancamento_de_Despesas__c` do projeto com
`Status_da_SR__c != 'Rejeitado'` → grava em `DespesasRealizadasAtividades__c` →
`PPMProjectTriggerHandler.beforeUpdate` (`PPMProjectBO.calculateDespesasRealizadas`) soma
`DespesasRealizadasAtividades__c + DespesasRealizadasCoffeeBreaks__c + DespesasRealizadasPassagens__c`
em `Despesas_Realizadas__c`. Mesma dependência de "o Lançamento de Despesas precisa ser salvo
de novo" da seção 3.1 — e o filtro (`!= Rejeitado`, não `>= aprovado pelo GP`) não implementa a
regra do anexo. Também existe uma integração de saída: `PPMProjectBO.updateInProject` dispara
um `@future(callout=true)` pro MS Project quando `Despesas_Realizadas__c` muda — ou seja, esse
campo (não o da demanda) já alimenta uma integração externa; vale o arquiteto saber antes de
decidir mexer nele.

## 4. Diagnóstico — causa provável, não corrigida ainda

Nenhuma automação na org, hoje, re-salva (ou de outra forma força o recálculo de)
`Lancamento_de_Despesas__c` quando a `Solicitacao_de_Reembolso__c` pai avança de status —
nem no caminho do Flow (campo da demanda), nem no caminho do Apex (campo irmão). A aprovação
do GP muda `Status_de_Aprovacao_e_Etapas__c` só na SR; o campo fórmula no Lançamento de
Despesas reflete isso na leitura, mas isso sozinho não dispara o Flow nem o trigger de Apex
que fazem a soma. O total só fica correto se, por coincidência, alguém editar o próprio
`Lancamento_de_Despesas__c` depois da aprovação — e o anexo diz que isso não acontece mais
("não possuímos mais despesa lançada manualmente").

**Isto é leitura de metadata e comportamento documentado de plataforma (fórmula entre objetos
não dispara trigger/Flow no registro que a contém), não suposição sobre dado de registro real**
— nenhuma SR, Lançamento ou Projeto real foi consultado (contagens abaixo são todas zero nesta
sandbox). Recomendo ao arquiteto validar com uma reprodução controlada (SR + Lançamento +
Projeto de teste, sem dado de cliente) antes do build, não só confiar nesta leitura de código.

## 5. Volume de dados nesta sandbox

```
SELECT COUNT() FROM PPM_Project__c               → 0
SELECT COUNT() FROM Lancamento_de_Despesas__c    → 0
SELECT COUNT() FROM Solicitacao_de_Reembolso__c  → 0
```

`sbx-somos-agility-dev` está sem massa de dados nestes três objetos (mesmo achado já registrado
no assessment e em recons anteriores deste cliente). Qualquer teste/reprodução do build vai
precisar criar os três registros de teste do zero — nenhum dado real disponível aqui para
validar hoje (consistente com guardrail #2: nem haveria o que consultar).

## 6. Automação correlata que não foi aberta (fora do orçamento desta recon)

- Flow `atualizaAprovadorReembolso` (nome sugere troca de aprovador, não valor) — não lido.
- As dezenas de `ApprovalProcess` em `Solicitacao_de_Reembolso__c` (mais de 30 versões
  nomeadas, ex. `Solicitacao_de_Novo_Reembolso_v8` … `v28`) — não abertas uma a uma; o que
  importa para esta demanda é que **alguma** delas move
  `Status_de_Aprovacao_e_Etapas__c` pelas etapas confirmadas na seção 2, não qual delas está
  ativa agora. Se o design precisar adicionar uma ação de aprovação (em vez de um
  Flow/trigger independente), vale identificar qual versão está ativa antes do build.
- `Valor_Total_da_Despesa__c` (fórmula em `Lancamento_de_Despesas__c`, usada pelo caminho Apex)
  — fórmula não lida; só confirmado que é `calculated: true`.

## Metadata retida neste workspace

`sf project retrieve` trouxe pra `clients/somos-agility/force-app/main/default/` (primeira vez
que este cliente ganha um projeto SFDX local — `sfdx-project.json` criado agora):

- `flows/Atualiza_valor_total_de_despesas_realizadas_no_projeto.flow-meta.xml`
- `classes/SolicitacaoReembolsoBO.cls`, `classes/SolicitacaoReembolsoTriggerHandler.cls`,
  `triggers/TrgSolicitacaoReembolso.trigger`
- `classes/LancamentoDespesasBO.cls`, `classes/LancamentoDespesasTriggerHandler.cls`,
  `triggers/TrgLancamentoDeDespesas.trigger`
- `classes/PPMProjectBO.cls`, `classes/PPMProjectTriggerHandler.cls`,
  `triggers/PPMProjectTrigger.trigger`

Fica no branch `feature/SOMOSAGILITY-10` para o arquiteto e, depois, o build reaproveitarem sem
precisar baixar de novo.

## Perguntas em aberto para o design (arquiteto)

1. **Qual dos dois campos é o oficial?** A demanda e o anexo citam literalmente "total de
   despesas realizadas" → aponta para `Total_de_despesas_realizadas__c` (o do Flow). Mas
   `Despesas_Realizadas__c` tem o mesmo problema de base e ainda alimenta a integração com MS
   Project — corrigir um sem considerar o outro deixa uma inconsistência visível entre os dois
   campos (e possivelmente entre Salesforce e MS Project).
2. **Onde entra o recálculo que falta?** Três caminhos possíveis, cada um com trade-off
   diferente (declarativo vs. código, decisão de design propriamente dita):
   - Corrigir o Defeito 1 do Apex (`afterUpdate`) e estender o Defeito 2 para também "tocar"
     os Lançamentos quando `Status_de_Aprovacao_e_Etapas__c` avança para
     `Pendente - Gestor` (ou além) — reaproveita a cadeia que já existe.
   - Mover a origem do recálculo para um Flow/trigger em `Solicitacao_de_Reembolso__c` que,
     na mudança de etapa, já some os Lançamentos relacionados e grave direto no projeto —
     sem depender de "tocar" o Lançamento de Despesas.
   - Tratar como roll-up/fórmula nativa se a regra permitir (reavaliar RN-04: a regra de
     filtro — "a partir da aprovação do GP" — não é algo que um roll-up summary nativo
     resolve sozinho sem campo auxiliar, porque roll-up não filtra por campo de objeto avô).
3. **Histórico (RN-07, ainda em aberto):** projetos com SR já aprovadas antes da correção
   precisam de um recálculo único (dado que nada vai "tocar" os Lançamentos deles
   retroativamente)? Como não há dado nesta sandbox, não dá para estimar o volume de produção
   afetado — perguntar ao cliente ou tratar como etapa de release (reprocessamento único) a
   combinar com o humano.
4. **A integração com MS Project** (`PPMProjectBO.updateProjectInMSProject`, disparada quando
   `Despesas_Realizadas__c` muda) deve ser considerada no design se a correção tocar nesse
   campo — mudar a frequência/volume de updates em `PPM_Project__c` muda a frequência de
   callouts `@future`.
