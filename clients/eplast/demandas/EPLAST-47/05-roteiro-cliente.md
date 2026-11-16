# EPLAST-47 — Roteiro de teste: classificação mensal das contas

Foi entregue o ajuste da rotina que, uma vez por mês, calcula o valor de compras de cada conta e atualiza o campo Classificação (MP, PP, P, M, G, GG, 3G) conforme as novas faixas de valor. Quem usa passa a ver cada conta classificada pela média de compras do ano, com o histórico de mudanças e um relatório das alterações.

**Situação do teste automático:** a rotina rodou na QAS em 15/11 e **não concluiu a atualização das contas** (erro de limite de processamento). Por isso os testes abaixo ainda não foram comprovados e servem para conferir depois da correção. Não faça a homologação até o time avisar que a nova versão foi para a QAS.

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`).
- Perfil: usuário com acesso de leitura a Contas e ao histórico do campo Classificação.
- Dado de teste: use uma conta de teste (nome "TESTE EPLAST-47 ...") com oportunidades ganhas neste ano. Peça ao time técnico para criá-la se não existir. Não use contas reais.

## Teste 1 — Valor de compras soma só oportunidades ganhas
1. Abra a conta de teste com duas oportunidades ganhas (3.000 e 2.000) e uma perdida (9.000).
2. Depois da execução mensal, veja o campo "Valor de compras do mês anterior".

**Resultado esperado:** 5.000 (a oportunidade perdida não entra).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Classificação conforme a faixa
1. Abra contas de teste com média de compras 10.000; 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000; 1.000.000,01.
2. Veja o campo Classificação de cada uma depois da execução.

**Resultado esperado:** MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G, nessa ordem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conta sem média de compras
1. Abra uma conta de teste sem média de compras e com Classificação já preenchida.
2. Veja o campo depois da execução.

**Resultado esperado:** a Classificação não muda (não vira GG).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Uma atualização por conta
1. Abra a conta de teste com 3 oportunidades ganhas e, em "Histórico de campos", veja Classificação.

**Resultado esperado:** no máximo uma linha de mudança de Classificação por execução.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Lista de valores do campo Classificação
1. Abra uma conta de teste e edite o campo Classificação.

**Resultado esperado:** só aparecem MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Relatório de mudanças
1. Abra Relatórios e a pasta EPLAST47; abra "Mudanças de Classificação".

**Resultado esperado:** uma linha por conta que mudou, com a classificação anterior e a nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só contam oportunidades ganhas no ano atual (regra que já existia). Confirme se está certo.
- Conta com média de compras vazia mantém a classificação que tem hoje, em vez de virar GG.
- O alerta de falha só vai para o e-mail configurado; enquanto não houver e-mail definido, a falha é só registrada. Informe o destinatário.
- A rotina roda uma vez por mês, no dia configurado (hoje 14), não diariamente. Confirme.
- Se o sistema Protheus não aceitar os novos valores MP e 3G, a atualização feita por ele falhará: confirme com quem cuida da integração.

## O que não dá para conferir pela tela
Teste de volume (muitas contas), erro de limite de processamento e execução agendada só o time técnico comprova. Evidência em `05-testes.md`.
