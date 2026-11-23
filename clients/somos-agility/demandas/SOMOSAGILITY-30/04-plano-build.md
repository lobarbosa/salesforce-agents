**Resultado do build:** bloqueado

**Motivo do bloqueio:** a verificação 1 (`04-verificacao-rodada-1.md`, reprovada) mediu CPU de 10521 ms contra o limite de 10000 ms no caso de volume (uma SR com 150 Lançamentos indo para `Aprovado`). O design (seção 6) manda devolver ao gate de design nesse caso, e a seção 10 proíbe trocar o algoritmo do Flow sem decisão do arquiteto humano. O gate foi aprovado de novo em 2026-11-23 22:15 (Carlos Sordi, commit `b7064d02`), mas o `03-design.md` segue com o mesmo sha256 (`1d1437582827d178`, 18652 bytes) de todos os aceites anteriores, e `comentarios-do-card.md` só registra os aceites. Não há decisão nova sobre o CPU. Reaprovar o mesmo design não é aceite do risco nem autorização para mudar o algoritmo; ler assim seria inventar a resposta.

**Pergunta sem resposta (quem responde: arquiteto humano, Carlos Sordi):** aceitar o limite documentado (a v11 não piora o caso do SOMOSAGILITY-10; a medição foi única) ou aprovar mudança de algoritmo? Para destravar, registrar no `03-design.md` (seção 6 ou 10) uma das opções e aprovar:
- (a) aceitar o limite, com a v11 seguindo para a QA e o caso de volume medido de novo lá;
- (b) agregação no Flow;
- (c) somatório em Apex;
- (d) limite de Lançamentos por SR.

Em (b) a (d) o design precisa descrever o novo componente. Editar o design é do arquiteto; o builder não altera `03-design.md`.

# 04 — Plano de build: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

**Org de build:** `sbx-somos-agility-dev` (Sandbox, Connected, conferida com `sf org list` nesta sessão). QA e produção não tocadas.
**Branch:** `feature/SOMOSAGILITY-30`. **Design:** `03-design.md`, seções 1, 3.1 e 3.2.
**Último commit de build com metadata:** `ac45a561` (`SOMOSAGILITY-30: criar v11 do Flow de total de despesas e ajustar testes`).

## Componentes (construídos em sessões anteriores, sem alteração nesta)

| Componente | Tipo | Ação | Descrição / resultado |
|---|---|---|---|
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Flow (record-triggered, after-save, `Lancamento_de_Despesas__c`) | **Nova versão v11, implantada como Draft** a partir da v10 | No Get Records `Captura_lancamentos_de_despesas`, as condições `Pendente - Gestor`, `Pendente - Diretor` e `Pendente - Operações` foram removidas. Ficam `Relacionado_ao_Projeto__c` = projeto do registro e `Status_da_SR__c` EqualTo `Aprovado`, `filterLogic` = `and`. Descrição com data e SOMOSAGILITY-30. Critério de entrada, loop, quilometragem, somatório e Update Records sem mudança. |
| `SolicitacaoReembolsoBOTest` | Apex (teste) | Ajustada, sem mudar classe de produção | `testInclusaoAoAprovarPeloGP` (0 em pendentes, 180 só em `Aprovado`); `testExclusaoAoRejeitar` (pré-condição em `Aprovado`); `testVariosLancamentosMesmoProjeto` (SR em `Aprovado`); `testBulk200SolicitacoesMudandoDeEtapa` (0 na transição pendente, soma em `Aprovado`); novos `testLancamentoSemProjetoNaoAlteraProjeto` e `testQuilometragemAprovadaSomaValorDaKilometragem`. |
| `SolicitacaoReembolsoTriggerHandlerTest` | Apex (teste) | Ajustada | `testMudarEtapaReSalvaLancamento` e `testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao` levam a SR a `Aprovado`; os outros dois métodos sem mudança. |

Nenhuma classe, trigger, campo, perfil ou permission set de produção foi alterado. Massa sintética, sem dado real.

## Versões e ativação

- v11 foi implantada como Draft; a verificação 1 a ativou na dev para exercitar (v10 ficou Obsolete). Estado atual da dev: v11 ativa (segundo a verificação 1; não conferi de novo nesta sessão).
- Pendente (passo separado): na QA, a v11 chega como Draft pela esteira; o `qa` ativa para testar e registra qual versão entrou e qual saiu. Entra v11, sai v10.
- Desfazer: reativar a v10.
- Ordem de deploy para a QA: Flow v11, ativação, depois as classes de teste (com a v10 ativa os testes ajustados falham, risco R1).

## Como o verificador testa quando o design for liberado

Com a v11 ativa na dev: rodar `SolicitacaoReembolsoBOTest` e `SolicitacaoReembolsoTriggerHandlerTest` com cobertura por classe (meta 85%), e repetir o caso de volume de 150 Lançamentos (script em `fixtures/lancamento-volume-setup.apex`), medindo CPU.

## Nesta sessão

Nada foi alterado no metadata, na org nem nos testes. Reconferi de novo em 2026-11-23 (aceite das 22:49, commit `2713a42d`): `03-design.md` segue com sha256 `1d1437582827d178` (18652 bytes), igual a todos os aceites, e o card só registra aprovações do gate, sem decisão sobre o CPU. Bloqueio mantido. Este plano foi restaurado do commit anterior (o arquivo estava apagado na árvore de trabalho). Resultado da verificação 1 fora o CPU: 12 de 12 testes Apex passaram, V1 passou, cobertura acima de 85% nas classes de produção tocadas.

## Correções da verificação 1

- **FALHA 1 (CPU 10521/10000 ms): não corrigida, devolvida ao gate de design.** Qualquer correção (agregação no Flow, somatório em Apex, limite por SR) é solução diferente da aprovada. A pergunta e as opções estão no topo deste arquivo. A verificação não mediu a v10 com a mesma massa, então não há comparação direta; medir exige reativar a v10 na dev, o que é passo de ativação, fora do build.

## Pendências de negócio

P5, P7 e P8 seguem como no design (não bloqueiam o build). Backfill fora desta entrega (P8).
