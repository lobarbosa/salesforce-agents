# EPLAST-47 — Roteiro de teste: classificação da conta ao fechar uma venda

Foi entregue um ajuste para que, toda vez que uma oportunidade é **ganha** (Fechado/Ganho), a conta dela passe a mostrar a Classificação certa (MP, PP, P, M, G, GG ou 3G) e o valor de compras, calculados na hora, sem esperar a rotina mensal. O histórico de mudanças e um relatório mostram o que mudou.

**Situação do teste automático:** o time executou na QAS (`eplast--qas`) os testes 1 a 5 e o 7 e eles passaram (12 faixas, soma, conta sem compra, lista de valores e relatório). **Ficaram para você:** o teste 6 (aviso de falha), que não deu para forçar sem mexer em cadastro de outra pessoa, e a conferência visual de cada tela. Antes da homologação, o time ainda precisa decidir o que fazer com a rotina mensal antiga (ver o fim deste roteiro).

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`).
- Perfil: usuário que cria oportunidades e lê Contas, com o campo "ID Usuário Protheus" preenchido no cadastro do dono da conta (sem isso o sistema nem deixa salvar a venda).
- Dados de teste: crie contas chamadas "TESTE EPLAST-47 ..." do tipo Indústria, cada uma com **uma** oportunidade nova. Não use contas reais. Se preferir, peça ao time técnico para criá-las.

## Teste 1 — Classificação conforme a faixa
1. Abra uma conta de teste e crie uma oportunidade com valor 10.000.
2. Altere a fase para "Fechado/Ganho" e salve.
3. Abra a conta e veja o campo Classificação.
4. Repita em outras contas com os valores 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000 e 1.000.000,01.

**Resultado esperado:** MP, PP, PP, P, P, M, M, G, G, GG, GG e 3G, nessa ordem (10.000 = MP; 10.000,01 = PP; 1.000.000 = GG; 1.000.000,01 = 3G).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Valor de compras soma só oportunidades ganhas
1. Na mesma conta, crie e ganhe uma oportunidade de 3.000 e outra de 2.000.
2. Crie uma terceira, de 9.000, na fase "Fechado/Perdido".
3. Veja o campo "Valor de compras do mês anterior" na conta.

**Resultado esperado:** 5.000 (a perdida não entra).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conta que deixa de ter compra
1. Numa conta com uma única oportunidade ganha, mude essa oportunidade para "Fechado/Perdido" e salve.
2. Veja o campo "Valor de compras do mês anterior" e a Classificação.

**Resultado esperado:** valor de compras 0; a Classificação não muda e não vira GG.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Uma mudança por conta no histórico
1. Abra a conta de um dos testes e, em "Histórico de campos", veja o campo Classificação.

**Resultado esperado:** uma única linha de mudança por venda ganha (anterior vazio e novo igual à faixa).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Lista de valores do campo Classificação
1. Abra uma conta de teste e edite o campo Classificação.

**Resultado esperado:** só aparecem MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Relatório de mudanças
1. Abra Relatórios, a pasta EPLAST47, e o relatório "Mudanças de Classificação".

**Resultado esperado:** uma linha por conta que mudou, com a classificação anterior e a nova, e só mudanças do campo Classificação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Aviso de falha (ainda não comprovado pelo time)
1. Com o time técnico, provoque uma conta que o sistema não consiga atualizar (por exemplo, com telefone fora do formato) e ganhe uma oportunidade dela.

**Resultado esperado:** a venda é salva normalmente; a falha fica registrada no log de integração; nenhum e-mail sai enquanto não houver destinatário configurado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só contam oportunidades ganhas **no ano atual** (pela data de criação). Está certo?
- Conta sem compra fica com valor 0; se a média estiver vazia, a Classificação **não muda** (não vira GG); média 0 vira MP.
- A Classificação é calculada pela "média de compras do ano" que já existe na conta, como já era.
- O aviso de falha só vai para um e-mail configurado; enquanto ele estiver vazio, só se registra a falha. Informe o destinatário.
- Se a oportunidade mudar de conta, só a conta nova é recalculada; apagar ou restaurar oportunidade não recalcula.
- A rotina mensal antiga não é mais o caminho principal, mas **ainda está ativa na QAS**; falta decidir se ela é desativada.
- O sistema Protheus não recebe a Classificação nesta entrega; confirme com quem cuida da integração se MP e 3G precisarão ser aceitos.

## O que não dá para conferir pela tela
Limites de processamento (erro de "muitos jobs"), ausência de erros de bloqueio de registro e o estado da rotina mensal antiga só o time técnico comprova. A evidência está em `05-testes.md`.
