# 03 — Design: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

**Cliente:** somos-agility · **Etapa:** design (arquiteto) · **Tipo:** sustentação, design enxuto
**Org consultada:** `sbx-somos-agility-dev` (Sandbox, Connected, conferida com `sf org list`). Só leitura: queries de metadata com LIMIT, `COUNT()`, retrieve em diretório temporário apagado no fim. Nenhum registro lido, nada alterado.
**Insumos:** `01-analise.md` (aprovado no gate de análise em 2026-11-22), `02-recon.md`, `00-preflight.md` (sem bloqueios, sem outra demanda nos mesmos componentes), `comentarios-do-card.md` (só a aprovação do gate; **nenhuma das perguntas P1 a P9 foi respondida**).
**Status:** aguardando aceite do arquiteto humano. Nenhum gate aprovado aqui.

---

## 1. Decisão

**Declarativo: nova versão do Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`, trocando só o filtro do Get Records para contar apenas `Status_da_SR__c = 'Aprovado'`.** Nenhuma mudança em Apex de produção (BO, handler, trigger). As classes de teste do SOMOSAGILITY-10 precisam ser ajustadas, porque hoje afirmam total maior que zero em etapas pendentes (seção 3.2).

Por que este nível:
- **Configuração pura não resolve.** O campo é moeda gravado por automação, não fórmula nem roll-up summary. O Lançamento não é filho master-detail do Projeto (`Relacionado_ao_Projeto__c` é lookup), e roll-up nativo com filtro em fórmula entre objetos (`Status_da_SR__c`) não é suportado. Trocar o motor de cálculo também seria mudança de modelo e de mecanismo, fora do pedido.
- **Flow já é o ponto único de cálculo e resolve com uma mudança de critério.** Entre os 25 Flows ativos dos três objetos (Projeto Agility, SR, Lançamento) e as classes `SolicitacaoReembolsoBO`, `SolicitacaoReembolsoTriggerHandler`, `LancamentoDespesasTriggerHandler`, `LancamentoDespesasBO`, `PPMProjectBO`, `PPMProjectTriggerHandler`, só o Flow alvo cita `Total_de_despesas_realizadas__c` (retrieve + grep nesta sessão).
- **Código não é necessário.** O gatilho das transições já existe e cobre Rejeição e Recall: confirmei que `SolicitacaoReembolsoTriggerHandler.afterUpdate` chama `SolicitacaoReembolsoBO.updateLancamentosDespesas` sempre que `Status_de_Aprovacao_e_Etapas__c` **ou** `Status__c` mudam (e também no `afterInsert`). A BO regrava os Lançamentos da SR que têm projeto, e o Flow recalcula o total completo do projeto. Isso fecha a incerteza 4 do recon e confirma PV-3 e PV-4 da análise.

Fonte histórica: a cascata SR → BO → Lançamento → Flow → Projeto e a trava de recursão vêm do SOMOSAGILITY-10 (`[demandas/SOMOSAGILITY-10/03-design.md]`, `[demandas/SOMOSAGILITY-10/04-plano-build.md]`, via RAG), e foram reconfirmadas no código da org nesta sessão.

## 2. Estado atual confirmado (só o que é novo em relação ao recon)

| Item | Estado | Prova |
|---|---|---|
| Versões do Flow alvo | v10 `Active` (última); v9 a v6 `Obsolete` | Tooling `Flow` por `Definition.DeveloperName` |
| Get Records `Captura_lancamentos_de_despesas` | `filterLogic` = `1 AND (2 OR 3 OR 4 OR 5)`: projeto = `$Record.Relacionado_ao_Projeto__r.Id` e `Status_da_SR__c` em `Pendente - Gestor`, `Pendente - Diretor`, `Pendente - Operações`, `Aprovado` | retrieve do Flow |
| Critério de entrada | `Relacionado_ao_Projeto__c` IsNull = false; `CreateAndUpdate`, `RecordAfterSave`; sem `triggerOrder`; `runInMode` não definido (contexto de sistema, padrão de record-triggered) | idem |
| Somatório | `somatorio_das_despesas` com padrão 0 (projeto sem Lançamento elegível fica 0, já desde o SOMOSAGILITY-10); quilometragem soma `Valor_da_Kilometragem__c` | idem |
| Caminhos de falha | Nenhum `faultConnector` no Flow | idem |
| Handler da SR | `afterInsert` e `afterUpdate` (mudança em `Status_de_Aprovacao_e_Etapas__c` ou `Status__c`) chamam a BO | retrieve de `SolicitacaoReembolsoTriggerHandler` |
| Erro do `Database.update(lancamentos, false)` na BO | vai só para `System.debug` (LoggingLevel.ERROR). Não há registro persistente | retrieve de `SolicitacaoReembolsoBO` |
| Cobertura atual | `SolicitacaoReembolsoTriggerHandler` 11/11, `SolicitacaoReembolsoBO` 18/19, `TrgSolicitacaoReembolso` 1/1 | `ApexCodeCoverageAggregate` |
| FLS do Total | 65 entradas de permissão só leitura, 3 com edição (perfis e permission sets) | `FieldPermissions` agrupado |
| DLRS no Projeto | 1 rollup ativo (`ProgressoDoProjeto`, campo `Percentual_de_Conclusao_v2__c`); nenhum no Total | `dlrs__LookupRollupSummary2__mdt` |
| Rollup Helper | Configuração (`rh2__PS_Describe__c`) tem 0 registros na dev: é dado, não metadata, e não foi copiado. **Não dá para afirmar na dev se há rollup do Rollup Helper gravando o Total** | `COUNT()` |
| Relatórios | 52 relatórios com "despesa" no nome. Não verifiquei quais usam o Total | `COUNT()` em Report |

## 3. Componentes

### 3.1 Flow (alterar por versão nova)

| Componente | Ação |
|---|---|
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Nova versão (será a **v11**) implantada com `<status>Draft</status>`, a partir da v10. Mudanças: (a) no Get Records `Captura_lancamentos_de_despesas`, substituir as quatro condições de `Status_da_SR__c` por uma só, `Status_da_SR__c` EqualTo `Aprovado`, e `filterLogic` = `and`; (b) atualizar a descrição com data e `SOMOSAGILITY-30`. Critério de entrada, loop, decisão de quilometragem, somatório e Update Records **sem mudança**. |

**Ativação (passo separado, skill `salesforce-doutrina`, "Alterar o que já existe"):**
1. Build implanta a v11 como Draft na dev. A v10 continua ativa.
2. Depois da verificação na dev com a v11 (ativação na dev só para exercitar, registrada em `04-verificacao.md`), a ativação fica no plano: **entra v11, sai v10**.
3. Na QA, a v11 chega como Draft pelo passo da esteira; o `qa` ativa para testar e registra em `05-testes.md` qual versão entrou e qual saiu.
4. Desfazer: reativar a v10.

**Atenção de deploy:** se a v11 ficar Draft enquanto as classes de teste já esperam a regra nova, os testes falham na org de destino. Por isso a validação dos testes (3.2) deve rodar com a v11 ativa na mesma org, e a ordem do plano de build deve ser: Flow Draft, ativação, depois testes.

### 3.2 Classes de teste (ajustar no branch, sem mudar classe de produção)

Os testes do SOMOSAGILITY-10 afirmam a regra antiga e vão falhar com a v11 ativa. Confirmado no código:

| Classe | Método | O que afirma hoje | Ajuste |
|---|---|---|---|
| `SolicitacaoReembolsoBOTest` | `testInclusaoAoAprovarPeloGP` | total 180 ao passar para `Pendente - Gestor` | total 0 em `Pendente - Gestor`; novo passo até `Aprovado` com total 180 (CA-01, CA-02) |
| `SolicitacaoReembolsoBOTest` | `testExclusaoAoRejeitar` | pré-condição total 200 com SR em `Pendente - Gestor` | pré-condição com SR em `Aprovado`, depois rejeição; ou pendente → rejeitado com total 0 o tempo todo (CA-04) |
| `SolicitacaoReembolsoBOTest` | `testVariosLancamentosMesmoProjeto` | 50 com SR em `Pendente - Gestor` | SR em `Aprovado` (CA-09) |
| `SolicitacaoReembolsoBOTest` | `testBulk200SolicitacoesMudandoDeEtapa` | soma esperada ao ir para `Pendente - Gestor` | esperar 0 nessa transição e acrescentar transição para `Aprovado` com a soma |
| `SolicitacaoReembolsoTriggerHandlerTest` | `testMudarEtapaReSalvaLancamento` | total 42 em `Pendente - Gestor` | levar a SR a `Aprovado` para provar o re-save, ou afirmar 0 em `Pendente - Gestor` |

Acrescentar casos: `Pendente - Operações` não soma (CA-03); `Aprovado` → `Recall` zera (CA-05, já existe `testExclusaoAoRecolher`, manter); Lançamento sem projeto não altera projeto (CA-08); um Lançamento de quilometragem aprovado soma `Valor_da_Kilometragem__c` (CA-10, regra atual mantida, ver P4).
Cobertura: as classes de produção não mudam; manter a medição por classe (meta do squad 85%) na verificação. Hoje: handler 100%, BO 95% pela leitura de `ApexCodeCoverageAggregate`.
Usar massa sintética, como o SOMOSAGILITY-10 já faz (CPF gerado por algoritmo, sem dado real).

### 3.3 Não muda

`SolicitacaoReembolsoBO`, `SolicitacaoReembolsoTriggerHandler`, `TrgSolicitacaoReembolso`, `TrgLancamentoDeDespesas`, `PPMProjectBO`, os outros Flows de SR, Lançamento e Projeto, campos e picklists.

### 3.4 Depreciar

Nada.

## 4. Comportamento resultante (para os cenários de teste refeitos)

- Qualquer mudança de etapa ou status da SR recalcula o total do projeto de forma completa. Com a v11, só Lançamentos de SR em `Aprovado` (via `Status_da_SR__c`, que lê `Status_de_Aprovacao_e_Etapas__c`) entram.
- `Pendente - Gerente de Projetos`, `Pendente - Gestor`, `Pendente - Diretor`, `Pendente - Operações`, `Rascunho`, `Rejeitado`, `Recall`: não somam.
- **Aprovado volta atrás:** qualquer transição a partir de `Aprovado` tira a despesa do total na hora, porque o recálculo é completo. É o que a v11 entrega sem mudança extra; precisa de confirmação de negócio (P5).
- Projeto sem Lançamento aprovado: total 0 (padrão do somatório). Precisa de confirmação com o cliente (P7).
- Se um Lançamento falhar na regravação (validation rule de KM, por exemplo), o total do projeto ainda fica certo **desde que outro Lançamento do mesmo projeto seja regravado na mesma transação**, porque cada execução do Flow consulta todos os Lançamentos do projeto. Se todos os Lançamentos do projeto naquela SR falharem, o total fica desatualizado sem aviso (risco R3).

## 5. Conflito de automação e ordem de execução

**Mesmo objeto e evento do Flow alvo (`Lancamento_de_Despesas__c`, after-save create/update): os Flows `atualizaAprovadorReembolso` e `sincroniza_campos`, o trigger `TrgLancamentoDeDespesas` e o trigger `RHX_Lancamento_de_Despesas` do Rollup Helper. Nenhum tem `triggerOrder` definido no Flow alvo, então a ordem entre os Flows after-save não é garantida, e os triggers Apex rodam antes dos Flows after-save.** Nenhum dos Flows e classes lidos grava o Total, então a ordem não altera o resultado, com uma exceção não confirmável na dev: um rollup do Rollup Helper gravando o mesmo campo (R2).

No Projeto, o Update Records do Flow dispara `PPMProjectTrigger` (`PPMProjectBO` não lê nem grava o Total), os Flows after-save do Projeto (nenhum cita o Total) e as validation rules do Projeto (R4). Esta demanda não muda o que é gravado nem quando; só muda o valor. A concorrência no Projeto é a mesma de hoje.

## 6. Limites de governador e escala

- **CPU (achado SOMOSAGILITY-10, estouro com uma SR de muitos Lançamentos).** O custo do Flow é proporcional a (Lançamentos regravados) × (Lançamentos do projeto que passam no filtro), porque cada execução percorre o loop da lista do projeto. A v11 **reduz** a lista do loop: nas transições pendentes, zero Lançamentos passam no filtro; na transição para `Aprovado`, o custo é igual ao da v10 para a mesma SR. Ou seja, a v11 não piora o pior caso, mas também não o resolve. **O caso de volume é obrigatório na verificação e na QA:** uma SR com 150 Lançamentos no mesmo projeto passando para `Aprovado`, em projeto que já tenha outras SRs aprovadas, medindo CPU no log. Se estourar, o build volta ao gate de design. Não é para trocar o algoritmo nesta demanda sem decisão do arquiteto humano.
- SOQL e DML: o Get Records e o Update Records são agregados pelo runtime de Flow entre as execuções da mesma transação. A v11 não acrescenta elementos.
- Carga em massa: o teste `testBulk200SolicitacoesMudandoDeEtapa` continua cobrindo 200 SRs mudando de etapa; ajustar para incluir a transição para `Aprovado`.

## 7. Permissões

Nenhuma mudança. O Flow roda em contexto de sistema, então FLS e compartilhamento do usuário que aprova a SR não bloqueiam a gravação do Total. Quem vê o campo continua o mesmo (65 entradas só leitura, 3 com edição). Para a massa de QA, P9 segue aberta: o roteiro do cliente deve usar o perfil que de fato aprova SR e o que consulta o projeto.

## 8. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Testes Apex do SOMOSAGILITY-10 falham com a v11 ativa (5 métodos afirmam a regra antiga). Sem ajuste, qualquer deploy com RunLocalTests na QA (ou depois) quebra | **Alta** | Ajuste das classes de teste no escopo (3.2), rodando com a v11 ativa |
| R2 | Rollup do Rollup Helper gravando o Total na QA ou em produção, concorrendo com o Flow. Na dev a configuração está vazia | Média | Antes de ativar na QA, o `qa` confere na tela do Rollup Helper (ou com `COUNT()` em `rh2__PS_Describe__c` filtrado pelo objeto Lançamento/Projeto) se há rollup no Total. Se houver, volta ao gate de design |
| R3 | Falha silenciosa: `Database.update(..., false)` na BO só registra em `System.debug`; se todos os Lançamentos do projeto falharem na regravação (validation rule de KM ou de Projeto), o total fica velho | Média, já existe | Não muda nesta demanda (fora do pedido). Registrado para sustentação futura. A QA inclui um caso de quilometragem válido para não confundir falha de massa com falha de regra |
| R4 | Validation rules do Projeto (36 ativas pelo recon, query cortada) podem recusar o Update do Flow quando o projeto está em certos status (congelado, encerrado). Sem fault path, a regravação daquele Lançamento falha e cai em R3 | Média, já existe | Massa de QA com projeto em status ativo; um caso com projeto em status restritivo vira observação no `05-testes.md` |
| R5 | CPU com SR de muitos Lançamentos no mesmo projeto | Média | Caso de volume obrigatório (seção 6) |
| R6 | Dados existentes: projetos com total somado em etapas pendentes ficam errados até uma SR do projeto mudar de etapa | Alta para o negócio, fora do build | Backfill não entra (P8). Na dev não há dados para medir (recon). Escala ao humano |
| R7 | Relatórios e painéis (52 com "despesa" no nome) passam a mostrar valores menores; agentes Agentforce não verificados | Baixa | Comunicação ao cliente na homologação. Uso do campo em relatório não confirmado |
| R8 | Exclusão de Lançamento ou SR, e troca de projeto de um Lançamento, não recalculam o projeto antigo (Flow é só create/update) | Baixa, já existe | Fora do escopo; registrado |

### Riscos do assessment que tocam a demanda

| Achado | Toca? | Como o design lida |
|---|---|---|
| 1. Concentração de automações (31 em Oportunidade, 24 no mesmo evento) | Não. Oportunidade não é tocada. Confirmado: o Flow alvo grava só `PPM_Project__c` | A concorrência real é a de Lançamento e Projeto, tratada na seção 5 |
| 2. Process Builder ativo (59) | Não nos três objetos, pela análise (não reconsultei). Os 25 Flows ativos dos três objetos são todos Flow Builder | Nada a fazer |
| 3. Cobertura Apex 40% org-wide | Sim, indiretamente. As classes da cascata estão com 95% a 100% (medido) | Nenhuma classe de produção muda; testes ajustados (R1) e cobertura por classe medida na verificação, meta 85% |
| 4. 30 classes sem `<Classe>Test` | Não. As classes tocadas têm teste dedicado (`SolicitacaoReembolsoBOTest`, `SolicitacaoReembolsoTriggerHandlerTest`) | Nada a fazer |
| 5. 27 classes pré-v33 | Não. Classes envolvidas em v48; Flow em API 63.0 | Não subir versão de API nesta demanda |
| 6. Perfil por pessoa (20 perfis com 1 usuário) | Só para QA | Massa e roteiro com usuários dos perfis que aprovam SR e veem o projeto (P9) |
| 7. Rollup Helper e DLRS ao mesmo tempo | Sim | DLRS confirmado sem rollup no Total; Rollup Helper não confirmável na dev (R2) |

## 9. Pendências para o gate humano

Nenhuma pergunta do card foi respondida. O design segue o texto da demanda onde ele é explícito. **O arquiteto humano, ao aceitar, aceita estas premissas; se alguma for recusada, o design volta.**

| # | Pergunta | Premissa do design | Bloqueia o build? |
|---|---|---|---|
| P1 | Campo que define a aprovação final | `Status_de_Aprovacao_e_Etapas__c` = `Aprovado` (via `Status_da_SR__c`), o mesmo de hoje. O handler recalcula também quando `Status__c` muda | Não, se aceita no gate |
| P2 | `Pendente - Operações` é antes da aprovação final? | Sim; não soma. A demanda pede "só Aprovado" | Não, se aceita no gate |
| P3 | Nenhuma etapa pendente soma | Sim | Não |
| P4 | Quilometragem: `Valor_da_Kilometragem__c` ou `Valor_da_Despesa__c` | Mantém `Valor_da_Kilometragem__c` (regra atual, não alterada) | Não. Mudar seria outra decisão de negócio |
| P5 | Aprovado volta atrás | Sai do total na hora, em qualquer transição a partir de `Aprovado` | Não para construir; sim para homologar CA-06 |
| P6 | Revisão do SOMOSAGILITY-10 | Fora desta demanda. Os testes Apex do 10 são ajustados aqui porque quebram com a v11 (R1); o design do 10 não é alterado | Precisa de dono |
| P7 | Projeto sem despesa aprovada fica 0 | Sim (comportamento atual do somatório) | Não para construir; sim para homologar CA-07 |
| P8 | Backfill e se a regra atual já está em produção | Não há backfill nesta demanda | **Escala ao humano**: define o plano de implantação em produção, fora da esteira |
| P9 | Perfis que veem o campo | Ver seção 7 | Só para QA |

## 10. O que NÃO será feito

- Backfill ou recálculo de projetos existentes (P8).
- Mudança no design ou nos artefatos do SOMOSAGILITY-10, além dos testes Apex que quebram com a regra nova.
- Tratamento de exclusão, undelete e troca de projeto do Lançamento (R8).
- Log persistente das falhas da BO (R3) e fault path no Flow.
- Otimização do algoritmo do Flow para CPU (só se o caso de volume estourar, com nova decisão no gate).
- Consolidação de Rollup Helper e DLRS (assessment, recomendação 8).
- Mudança de modelo de dados: nenhuma é proposta.

## 11. Esforço

**Estimativa de esforço:** 4–8 h
Mudou em relação à análise (5–10 h):
- caiu: o handler já recalcula em toda mudança de etapa e status, então Rejeição e Recall não exigem mudança na BO (a análise previa subir para M se fosse preciso);
- caiu: DLRS sem rollup no Total e nenhuma outra automação lida grava o campo;
- subiu um pouco: ajuste de 5 métodos de teste Apex do SOMOSAGILITY-10 e casos novos (1–2 h);
- mantido: nova versão do Flow e ativação (0,5–1 h), verificação na dev com caso de volume (1–2 h), regressão na QA CA-01 a CA-10 (1–2 h), homologação (0,5–1 h);
- não inclui backfill (P8). Se o caso de volume estourar CPU, o limite superior não vale e o design volta ao gate.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

---

## Decisão do responsável (2026-11-23, Leonardo Barbosa): limite de CPU no caso de volume — opção (a)

A verificação 1 (`04-verificacao-rodada-1.md`) mediu 10521 ms de CPU contra o limite de 10000 ms no caso de volume da seção 6 (uma SR com 150 Lançamentos no mesmo projeto passando para `Aprovado`). O build voltou ao gate de design sete vezes com a mesma pergunta.

**Decisão: opção (a), aceitar o limite documentado.** Substitui, só para este caso, a regra da seção 6 de voltar ao gate de design quando o caso de volume estourar:

1. A v11 segue como construída, sem trocar o algoritmo do Flow (nada de agregação no Flow, Apex ou limite de Lançamentos por SR nesta demanda).
2. Motivo: a v11 não piora o pior caso em relação à v10 (seção 6) e a medição foi única, 5% acima do limite.
3. O builder não reabre a pergunta: com este registro, o build segue para a verificação e o gate de build.
4. O verificador e o QA medem o caso de volume de novo (dev e QA) e **registram** o resultado, sem reprovar só por ele. Os demais critérios continuam valendo normalmente.
5. O limite fica documentado no `06-entrega.md` e para o cliente: SR com muitos Lançamentos no mesmo projeto pode se aproximar do limite de processamento do Salesforce na aprovação final. Se acontecer em produção, a correção estrutural (opção b, c ou d) vira demanda nova.
