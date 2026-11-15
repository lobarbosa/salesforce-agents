# EPLAST-47 — Roteiro de teste: classificação mensal das contas

O processo que calcula, uma vez por mês (dia 14), o valor de compras de cada conta e a sua Classificação foi corrigido. Agora ele atualiza cada conta uma única vez, usa sete classificações (MP, PP, P, M, G, GG, 3G) com as novas faixas de valor e tem um aviso configurável em caso de falha. Existe também um relatório de mudanças de classificação.

**Situação do teste automático:** comprovado pelo time técnico na QA: as 7 classificações existem, as faixas estão cadastradas com os valores combinados, o processo novo está ativo, o relatório existe e o histórico de mudanças está ligado. **Não comprovado:** o cálculo de fato (uma atualização por conta, soma só das oportunidades ganhas, faixas nos limites, aviso de falha, relatório com dados), porque o processo só roda sozinho às 15h47 UTC no dia configurado e criar oportunidade ganha de teste exige uma base de dados (filial, condição de pagamento etc.) que o time ainda não montou. Os testes 3 a 7 ficam para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de QA da Eplast.
- Perfil: administrador ou usuário com acesso a Contas, Oportunidades e Relatórios.
- Dados de teste: contas com "TESTE EPLAST-47" no nome, cada uma com oportunidades "Fechado/Ganho" criadas neste ano. Para os testes de faixa, o total das oportunidades ganhas da conta deve ser o valor indicado em cada teste. Peça ao time técnico para ajustar o dia de execução para o dia do teste e voltar para 14 depois.
- Atenção: criar oportunidade ganha pode gerar pedido e envio ao sistema Protheus. Use poucas contas.

## Teste 1 — As sete classificações existem
1. Abra qualquer conta de teste e clique em editar.
2. Abra a lista do campo Classificação.

**Resultado esperado:** aparecem exatamente MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — O relatório de mudanças existe
1. Vá em Relatórios e abra a pasta "EPLAST-47 Relatorios (provisorio, P12)".
2. Abra "Mudancas de Classificacao de Contas".

**Resultado esperado:** o relatório abre com as colunas conta, data, campo, valor anterior e valor novo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Valor e classificação por faixa
Crie uma conta de teste por linha, com as oportunidades ganhas somando o valor, e rode o processo (dia combinado).
1. Total 10.000 → abra a conta e veja Classificação.
2. Repita com os totais 10.000,01, 35.000, 35.000,01, 80.000, 160.000,01, 500.000,01 e 1.000.000,01, cada um em uma conta de teste.

**Resultado esperado:** conforme a tabela: até 10.000 = MP; até 35.000 = PP; até 80.000 = P; até 160.000 = M; até 500.000 = G; até 1.000.000 = GG; acima = 3G. Assim: 10.000 MP; 10.000,01 PP; 35.000 PP; 35.000,01 P; 80.000 P; 160.000,01 G; 500.000,01 GG; 1.000.000,01 3G. O campo de valor das compras da conta mostra o total da soma.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade perdida não entra na soma
1. Conta de teste com duas oportunidades ganhas (3.000 e 2.000) e uma perdida (9.000).
2. Rode o processo e abra a conta.

**Resultado esperado:** valor de compras 5.000; Classificação MP.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta sem compra
1. Conta de teste sem oportunidade ganha neste ano.
2. Rode o processo e abra a conta.

**Resultado esperado:** o valor fica como o combinado para conta sem compra e a Classificação não vira GG automaticamente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Uma atualização por conta
1. Conta A com 3 oportunidades ganhas e conta B com 1.
2. Rode o processo e, em cada conta, abra Histórico de Classificação (aba Relacionado).

**Resultado esperado:** cada conta mostra uma única mudança de Classificação, não três nem quatro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Relatório de mudanças
1. Depois do Teste 3, abra "Mudancas de Classificacao de Contas".

**Resultado esperado:** uma linha por conta de teste que mudou, com classificação anterior e nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Ausência de erro de bloqueio com 50 contas, a ausência de consulta sem filtro e a ausência do endereço do ex-parceiro: conferidos no desenho do processo pelo time técnico (`05-testes.md`, casos 4 a 6). O aviso de falha com destinatário depende do endereço que a Eplast ainda vai informar.
