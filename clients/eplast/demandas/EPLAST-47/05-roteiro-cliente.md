# EPLAST-47 — Roteiro de teste: classificação da conta ao salvar a oportunidade

Ao salvar uma oportunidade como **Fechado/Ganho**, o sistema soma as compras ganhas do ano da conta e atualiza sozinho dois campos da conta: **Valor de compras do último mês** e **Classificação**. Vale a nova tabela de faixas, com sete classificações (MP, PP, P, M, G, GG, 3G). A rotina antiga que rodava todo dia 14 deixa de ser usada.

**Situação do teste automático:** na sandbox de QA, a rodada anterior comprovou as faixas (12 valores de borda), a soma, o histórico, o relatório e a ausência de erro de limite. Nesta rodada o time **não** conseguiu comprovar que a rotina antiga do dia 14 foi desligada (ela seguia ativa) e por isso a entrega voltou para correção. O teste 6 (falha forçada) não é exercitável pelo time e fica para quem segue este roteiro. Os demais testes abaixo ficam para a conferência manual.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a "QAS").
- Perfil: usuário comercial que consegue criar conta e oportunidade.
- Dado de teste: crie uma conta chamada **TESTE EPLAST-47 A** (preencha o que a tela exigir) e uma oportunidade nela. Use só dados de teste, nunca uma conta real. Se precisar de outra conta, crie **TESTE EPLAST-47 B**.
- Para cada teste, abra a conta e olhe os campos **Classificação** e **Valor de compras do último mês**.

## Teste 1 — Faixas de classificação (valores de borda)
1. Na conta TESTE EPLAST-47 A, crie uma oportunidade com valor 10.000 e fase **Fechado/Ganho**. Salve.
2. Abra a conta e anote a **Classificação**.
3. Repita com outra conta de teste (uma conta por valor) para: 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000; 1.000.000,01.

**Resultado esperado:** MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G, nessa ordem (valor 10.000 = MP; 10.000,01 = PP; 1.000.000,01 = 3G).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Valor pequeno
1. Crie uma conta de teste e uma oportunidade ganha de 3.000. Salve.

**Resultado esperado:** Classificação **MP** e Valor de compras do último mês **3.000**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Soma só das ganhas
1. Na mesma conta, oportunidade ganha de 3.000. Salve.
2. Crie outra ganha de 2.000. Salve.
3. Crie uma oportunidade **Fechado/Perdido** de 9.000. Salve.

**Resultado esperado:** Valor de compras do último mês **5.000** (a perdida não entra).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Ganha que vira perdida
1. Conta com uma única ganha de 10.000. Altere essa oportunidade para **Fechado/Perdido**. Salve.

**Resultado esperado:** Valor de compras do último mês **0**; a Classificação **não** muda para GG, continua a que estava (MP).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Uma atualização por salvamento e histórico
1. Salve uma oportunidade ganha em conta de teste.
2. Na conta, abra o histórico do campo Classificação.

**Resultado esperado:** uma linha de histórico por mudança, sem mensagem de erro de limite ao salvar.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Falha na classificação não impede a venda (precisa da homologação)
O time não conseguiu provocar esta falha sem mexer em usuário real. Se for possível provocar na sua sandbox (por exemplo, conta cujo proprietário gera erro na gravação), siga:
1. Salve uma oportunidade ganha nessa condição.

**Resultado esperado:** a oportunidade é salva. A falha fica registrada no log de integração (ação da classificação). E-mail só sai se houver destinatário de falha configurado; sem destinatário, não sai e-mail.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:
- [ ] Não foi possível provocar a falha

## Teste 7 — Lista de classificações
1. Na conta, abra a lista do campo **Classificação**.

**Resultado esperado:** exatamente MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Relatório de mudanças de classificação
1. Abra o relatório **Mudanças de classificação da conta** (pasta EPLAST47).
2. Procure as contas de teste usadas acima.

**Resultado esperado:** cada conta de teste aparece com a classificação anterior e a nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Rotina do dia 14 desligada
1. Em Configuração, abra **Fluxos** e procure **Fluxo Agendado - Oportunidade**.
2. Veja se há versão ativa.

**Resultado esperado:** nenhuma versão ativa, e nenhuma execução agendada. (O time encontrou esta rotina ainda ativa na QA e a entrega voltou para correção.)
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só conta como compra a oportunidade **Fechado/Ganho** criada **neste ano** (a regra atual não mudou).
- Conta sem nenhuma ganha fica com valor **0**. Se a média de compras estiver vazia, a classificação **se mantém** (nunca vira GG). Média 0 vira MP.
- O faixa termina "até" o limite: 10.000 é MP; 10.000,01 é PP.
- O aviso de falha é operacional (e-mail simples interno, sem dado de cliente), só para o destinatário configurado. **Sem destinatário informado, só fica o registro.** Qual endereço usar?
- Se a oportunidade muda de conta, só a conta nova é reclassificada. Excluir ou restaurar oportunidade não recalcula.
- Oportunidade de ano anterior não dispara a classificação.
- A classificação usa o campo de média de compras como já gravado hoje.
- Falha na classificação não impede salvar a oportunidade.
- A rotina do dia 14 fica desligada (não apagada), podendo ser religada.
- O relatório fica na pasta provisória atual; o Protheus não recebe mudança nesta entrega e a classificação (inclusive MP e 3G) não foi enviada a ele.
- Não há teste de volume nesta entrega.

## O que não dá para conferir pela tela
- Ausência de erro de limite de filas em muitas contas e o estado do agendamento no sistema: evidência em `05-testes.md` desta demanda (consultas na sandbox) e na rodada anterior.
