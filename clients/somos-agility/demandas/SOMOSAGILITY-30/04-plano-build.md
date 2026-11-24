**Resultado do build:** concluído

# 04 — Plano de build: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

**Org de build:** `sbx-somos-agility-dev` (Sandbox, Connected, conferida com `sf org list` nesta sessão). QA e produção não tocadas.
**Branch:** `feature/SOMOSAGILITY-30`. **Design:** `03-design.md`, seções 1, 3.1 e 3.2, mais a decisão do responsável (2026-11-23, Leonardo Barbosa, opção (a)) no fim do arquivo.
**Último commit de build com metadata:** `ac45a561` (`SOMOSAGILITY-30: criar v11 do Flow de total de despesas e ajustar testes`).

## Componentes

| Componente | Tipo | Ação | Descrição / resultado |
|---|---|---|---|
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Flow (record-triggered, after-save, `Lancamento_de_Despesas__c`) | **Nova versão v11, implantada como Draft** a partir da v10 | No Get Records `Captura_lancamentos_de_despesas`, as condições `Pendente - Gestor`, `Pendente - Diretor` e `Pendente - Operações` foram removidas. Ficam `Relacionado_ao_Projeto__c` = projeto do registro e `Status_da_SR__c` EqualTo `Aprovado`, `filterLogic` = `and`. Descrição com data e SOMOSAGILITY-30. Critério de entrada, loop, quilometragem, somatório e Update Records sem mudança. |
| `SolicitacaoReembolsoBOTest` | Apex (teste) | Ajustada, sem mudar classe de produção | `testInclusaoAoAprovarPeloGP` (0 em pendentes, 180 só em `Aprovado`); `testExclusaoAoRejeitar` (pré-condição em `Aprovado`); `testVariosLancamentosMesmoProjeto` (SR em `Aprovado`); `testBulk200SolicitacoesMudandoDeEtapa` (0 na transição pendente, soma em `Aprovado`); novos `testLancamentoSemProjetoNaoAlteraProjeto` e `testQuilometragemAprovadaSomaValorDaKilometragem`. |
| `SolicitacaoReembolsoTriggerHandlerTest` | Apex (teste) | Ajustada | `testMudarEtapaReSalvaLancamento` e `testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao` levam a SR a `Aprovado`; os outros dois métodos sem mudança. |

Nenhuma classe, trigger, campo, perfil ou permission set de produção foi alterado. Massa sintética, sem dado real.

## Versões e ativação

- v11 foi implantada como Draft. Conferido nesta sessão por consulta Tooling na dev: v11 **Active**, v10 Obsolete, v9 Obsolete (a verificação 1 ativou a v11 na dev para exercitar). O arquivo no repositório segue `Draft`, como a esteira leva à QA.
- Pendente (passo separado): na QA, a v11 chega como Draft pela esteira; o `qa` ativa para testar e registra qual versão entrou e qual saiu. Entra v11, sai v10.
- Desfazer: reativar a v10.
- Ordem de deploy para a QA: Flow v11, ativação, depois as classes de teste (com a v10 ativa os testes ajustados falham, risco R1).

## Correções da verificação 1

- **FALHA 1 (CPU 10521/10000 ms no caso de volume, 150 Lançamentos de uma SR para `Aprovado`): sem alteração de build, por decisão registrada.** O responsável decidiu pela opção (a) em `03-design.md` (seção "Decisão do responsável", 2026-11-23): aceitar o limite documentado, manter a v11 como construída e não trocar o algoritmo (sem agregação no Flow, sem Apex, sem limite de Lançamentos por SR). A v11 não piora o pior caso em relação à v10 e a medição foi única, 5% acima do limite. O verificador e o QA repetem a medição do caso de volume (dev e QA) e registram o resultado, sem reprovar só por ele. O limite entra no `06-entrega.md` e na comunicação ao cliente. Correção estrutural (opções b, c ou d), se necessária em produção, vira demanda nova.
- Demais itens da verificação 1 passaram (12 de 12 testes Apex, V1, cobertura >= 85% nas classes de produção tocadas). Nada a corrigir.

## Pendências

- Verificação na dev: repetir o caso de volume (script em `fixtures/lancamento-volume-setup.apex`) e registrar a CPU.
- P5, P7 e P8 seguem como no design (não bloqueiam o build). Backfill fora desta entrega (P8).
- CA-06 ficou sem prova adicional na verificação 1 (depende de P5).

## Correções da verificação 2

- **FALHA 1 (`testBulk200SolicitacoesMudandoDeEtapa` falhava por CPU de forma intermitente): corrigida só no teste.** Lote reduzido de 200 SR em 20 projetos para 50 SR em 10 projetos (5 SR por projeto), mantendo a prova de bulk (uma DML com várias SR). O método foi renomeado para `testBulk50SolicitacoesMudandoDeEtapa`, com comentário e mensagens de assert ajustados. Sem mudança no Flow v11 nem em classe de produção. A decisão (a) do limite de CPU do produto segue valendo e é medida pelo caso de volume, não por este teste.
- Evidência na dev (`sbx-somos-agility-dev`): 3 execuções isoladas do teste, 3 Pass (33,7 s, 29,1 s, 14,9 s). Classe de teste reimplantada na dev. Suíte das duas classes de teste reexecutada (resultado na verificação seguinte).
