**Resultado do build:** bloqueado

**Motivo do bloqueio:** a verificação 1 reprovou por CPU (10521 ms contra 10000 ms) no caso de volume, e o design (seções 6 e 10) manda devolver ao gate de design nesse caso. Ver "Correções da verificação 1" no fim deste arquivo. Reconfirmado na sessão de 2026-11-23 (após novo aceite do gate de design): o `03-design.md` segue com o mesmo hash (`1d1437582827d178`) do aceite anterior, ou seja, não traz decisão nova sobre o CPU. Reaprovar o mesmo design não autoriza trocar o algoritmo (seções 6 e 10).

# 04 — Plano de build: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

**Org de build:** `sbx-somos-agility-dev` (Sandbox, Connected, conferida com `sf org list`). QA não tocada, produção não tocada.
**Branch:** `feature/SOMOSAGILITY-30`. **Design:** `03-design.md`, seções 1, 3.1 e 3.2 (aceite no gate de design).

## Componentes

| Componente | Tipo | Ação | Descrição / resultado |
|---|---|---|---|
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Flow (record-triggered, after-save, `Lancamento_de_Despesas__c`) | **Nova versão v11, Draft**, a partir da v10 (baixada da dev antes de editar; o arquivo do repositório estava defasado em relação à dev e foi substituído pelo retrieve) | No Get Records `Captura_lancamentos_de_despesas`: removidas as condições `Pendente - Gestor`, `Pendente - Diretor` e `Pendente - Operações`; ficam `Relacionado_ao_Projeto__c` = projeto do registro e `Status_da_SR__c` EqualTo `Aprovado`, `filterLogic` = `and`. Descrição atualizada com data e SOMOSAGILITY-30. Critério de entrada (projeto preenchido), loop, quilometragem, somatório e Update Records sem mudança. Deploy confirmado: v11 `Draft`, v10 `Active`, v9 `Obsolete` (Tooling `Flow`). |
| `SolicitacaoReembolsoBOTest` | Apex (teste) | Ajustada (sem mudar classe de produção) | Ver abaixo. |
| `SolicitacaoReembolsoTriggerHandlerTest` | Apex (teste) | Ajustada; passou a existir no repositório (não estava versionada, foi baixada da dev) | Ver abaixo. |

Nenhuma classe, trigger, campo, perfil ou permission set de produção foi alterado.

### Ajustes de teste (design 3.2, risco R1)

`SolicitacaoReembolsoBOTest`:
- `testInclusaoAoAprovarPeloGP`: total 0 em `Pendente - Gestor` (CA-01) e em `Pendente - Operações` (CA-03); total 180 só depois de `Aprovado` (CA-02, CA-10).
- `testExclusaoAoRejeitar`: pré-condição com SR em `Aprovado` (200), depois `Rejeitado` zera (CA-04).
- `testVariosLancamentosMesmoProjeto`: SR em `Aprovado`, total 50 (CA-09).
- `testBulk200SolicitacoesMudandoDeEtapa`: transição para `Pendente - Gestor` mede limites e confere total 0; depois transição de 200 SR para `Aprovado` e a conferência da soma por projeto.
- Novos: `testLancamentoSemProjetoNaoAlteraProjeto` (CA-08), `testQuilometragemAprovadaSomaValorDaKilometragem` (CA-10).
- Mantidos sem mudança: `testExclusaoAoRecolher` (CA-05, Aprovado para Recall), `testProjetoSemLancamentoElegivelTotalZero`.

`SolicitacaoReembolsoTriggerHandlerTest`:
- `testMudarEtapaReSalvaLancamento`: leva a SR a `Aprovado` para provar o re-save pelo marcador (42).
- `testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao`: SR em `Aprovado` (o design não listou este método; ele esperava 15 com SR em `Pendente - Gestor` e quebraria com a v11).
- `testUpdateSemMudarEtapaNaoReSalvaLancamento` e `testTransicaoRealNaoCausaRecursaoDescontrolada`: sem mudança (não dependem do valor somado).

Massa sintética, como no SOMOSAGILITY-10; nenhum dado real.

## Versões e ativação

1. **Feito:** v11 implantada na dev como Draft. A v10 continua ativa. Ninguém ativou a v11 neste build.
2. **Pendente (passo separado):** na dev, o `verificador` ativa a v11 só para exercitar e registra em `04-verificacao.md`. Ativação: **entra v11, sai v10**.
3. Na QA, a v11 chega como Draft pelo passo da esteira; o `qa` ativa para testar e registra qual versão entrou e qual saiu.
4. Desfazer: reativar a v10.

## O que não foi provado neste build

- **Os testes Apex ajustados foram implantados (compilam) mas não foram executados.** Com a v10 ainda ativa, as afirmações novas falhariam, e o design (3.1, "Atenção de deploy") exige a ordem Flow Draft, ativação, depois testes. A execução, a medição de cobertura por classe (meta 85%; classes de produção não mudaram) e o caso de volume de CPU (uma SR com 150 Lançamentos para `Aprovado`, design seção 6) ficam para a verificação, com a v11 ativa na dev.
- A pendência de que o handler tenha passado a existir só agora no repositório foi tratada: a classe vem do retrieve da dev.
- Ordem de deploy para a QA: Flow v11, ativação, depois classes de teste. Um deploy com RunLocalTests com a v10 ativa quebra (R1).
- Pendências de negócio P5, P7, P8 e premissas de P1 a P4 seguem como no design (não bloqueiam o build). Backfill de projetos existentes não faz parte desta entrega (P8).

## Correções da verificação 1

Lida: `04-verificacao-rodada-1.md` (reprovada). Dos 12 testes Apex, V1 e N1, tudo passou com a v11 ativa na dev. Só a FALHA 1 reprovou, e ela não é corrigível neste build.

- **FALHA 1 (CPU 10521/10000 ms, SR com 150 Lançamentos indo para `Aprovado`): não corrigida, devolvida ao gate de design.**
  - Por que não corrijo aqui: o design (seção 6) diz que a v11 não piora o pior caso e também não o resolve, e que, se o caso de volume estourar, "o build volta ao gate de design". A seção 10 proíbe otimizar o algoritmo do Flow sem nova decisão do arquiteto humano. Qualquer correção (trocar o loop do Flow por agregação, mover o somatório para Apex, limitar Lançamentos por SR) é mudança de solução diferente da aprovada, e eu não improviso.
  - Nada foi alterado no metadata nesta sessão: v11 do Flow e testes ajustados continuam como no build original. A v11 está ativa na dev por causa da verificação (v10 Obsolete); reativar a v10 só se a demanda for descartada.
  - **Pergunta que falta responder (arquiteto humano):** aceitar o limite documentado (a v11 não piora o caso do SOMOSAGILITY-10, e a medição foi única, com variação possível) ou aprovar uma mudança de algoritmo (agregação no Flow, somatório em Apex ou limite de Lançamentos por SR)? Se for mudança, o design precisa de revisão e novo aceite.
  - Dado útil para a decisão: a verificação não mediu a v10 com a mesma massa, então não há comparação direta. Medir antes de decidir exige reativar a v10 na dev, o que é passo de ativação, fora do build.

## Reconfirmação após novo aceite do gate de design (2026-11-23)

- O gate foi aprovado de novo (Carlos Sordi, commit `ea5516b5`), mas os artefatos revisados são idênticos aos do aceite anterior (`03-design.md` sha256 `1d1437582827d178`). O design não foi revisado: continua sem dizer se o estouro de CPU é aceito nem qual algoritmo usar.
- Não li isso como aceite do risco nem como autorização de mudar o algoritmo; seria inventar a decisão. Nada foi alterado no metadata nesta sessão (v11 e testes como no build original, sem nova implantação).
- **O que falta para destravar (quem responde: arquiteto humano):** registrar no `03-design.md` uma destas opções e aprovar de novo: (a) aceitar o limite documentado, com a v11 seguindo para a QA e o caso de volume medido de novo lá; (b) agregação no Flow; (c) somatório em Apex; (d) limite de Lançamentos por SR. Em (b) a (d), o design precisa descrever o novo componente.
