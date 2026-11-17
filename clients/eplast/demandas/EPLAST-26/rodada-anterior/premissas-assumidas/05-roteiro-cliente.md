# EPLAST-26 — Roteiro de teste: pontuação e faixa de prioridade

**O que foi entregue.** Cada Lead e cada Oportunidade passa a ter uma **pontuação de 0 a 100** e uma **faixa de prioridade** (Alta, Média, Baixa, e casos especiais). Os dois valores aparecem na seção **Prioridade** da página do registro e podem ser usados em colunas e filtros de listas. Quem vende vê onde agir primeiro. Ninguém digita a pontuação: ela é calculada sozinha.

**Situação do teste automático:** o time já comprovou na sandbox de testes, com registros de teste, os Testes 1 a 7 e 9 (valores de pontuação e faixa, campos bloqueados para edição, listas de oportunidade) e viu a seção Prioridade nas páginas de Lead e de Oportunidade. **Ficou para quem segue este roteiro:** o Teste 8 (ordenar a lista de Leads clicando na coluna), porque a lista só tem leads reais copiados e não foi aberta pelo time.

## Antes de começar
- **Ambiente:** sandbox QAS (`eplast--qas`). Nunca em produção.
- **Perfil:** um usuário de vendas (Administrador também serve). O administrador precisa ter atribuído a ele o conjunto de permissões **PS_Comercial_ScorePrioridade**; sem isso a seção Prioridade aparece vazia.
- **Dados de teste** (crie e apague ao final; use nomes com "TESTE"):
  - Lead A: Sobrenome "TESTE 26 A", Empresa "TESTE 26", Setor preenchido, Origem do lead preenchida, Status "Contatado".
  - Lead B: Sobrenome "TESTE 26 B", Empresa "TESTE 26", Setor preenchido, Origem do lead vazia, Status "Aberto - Não contatado".
  - Lead C: Sobrenome "TESTE 26 C", Empresa "TESTE 26", Setor e Origem vazios, Status "Contatado".
  - Oportunidades (numa conta de teste): veja o quadro de cada teste.
- Na página do registro, a seção **Prioridade** vem recolhida: clique no nome dela para abrir.

## Teste 1 — Lead com setor, origem e status Contatado
1. Abra o Lead A.
2. Role até a seção **Prioridade** e clique para abrir.

**Resultado esperado:** Score de prioridade **100**; Faixa de prioridade **Alta**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead só com setor
1. Abra o Lead B e abra a seção **Prioridade**.

**Resultado esperado:** Score **30**; Faixa **Baixa**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem setor e sem origem
1. Abra o Lead C e abra a seção **Prioridade**.

**Resultado esperado:** Score **0**; Faixa **Sem dados suficientes** (nunca Alta).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Mudar o status atualiza a pontuação
1. Crie o Lead D igual ao Lead A, mas com Origem e Setor preenchidos e Status "Aberto - Não contatado". Abra a seção **Prioridade**: deve mostrar **60 / Média**.
2. Altere o Status para "Contatado" e salve.
3. Atualize a página e abra a seção **Prioridade**.

**Resultado esperado:** Score **100**; Faixa **Alta**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Oportunidade com alta chance
1. Crie uma oportunidade de teste com Probabilidade **90%**, Valor maior que zero (ex.: 1.000), Data de fechamento **daqui a 30 dias** e Origem do lead preenchida.
2. Abra a seção **Prioridade**.

**Resultado esperado:** Score **96**; Faixa **Alta**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Prazo longo não ganha o ponto de prazo
1. Crie outra oportunidade com Probabilidade **50%**, Valor maior que zero, Data de fechamento **daqui a 61 dias** e Origem do lead vazia.
2. Abra a seção **Prioridade**.

**Resultado esperado:** Score **40**; Faixa **Média**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Oportunidade fraca e oportunidade encerrada
1. Crie uma oportunidade com Probabilidade **10%**, Valor 0, fechamento daqui a 200 dias, sem origem. Abra **Prioridade**: **Score 4, faixa Baixa**.
2. Crie outra oportunidade já encerrada (Fase "Fechado/Perdido"). Abra **Prioridade**.

**Resultado esperado:** a encerrada mostra Score **0** e Faixa **Encerrada**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Lista de Leads ordena pela pontuação
1. Em Leads, abra a lista **Leads Abertos por Prioridade**.
2. Clique no título da coluna de score até ficar do maior para o menor.

**Resultado esperado:** os leads aparecem do maior score para o menor (os seus Leads A, B e C na ordem 100, 30, 0) e a faixa aparece na linha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Lista de oportunidades por faixa, e campos bloqueados
1. Em Oportunidades, abra a lista **Oportunidades Prioridade Alta**.
2. Abra a oportunidade do Teste 5 e tente editar o Score ou a Faixa de prioridade (clique no campo).

**Resultado esperado:** a lista mostra só oportunidades com faixa **Alta** (a do Teste 5 aparece, a do Teste 6 e a encerrada não); Score e Faixa **não permitem edição** (sem lápis).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Pesos e faixas.** Lead: Setor 30 pontos, Origem 30, Status "Contatado" 40. Oportunidade: Probabilidade x 0,4 (até 40), Valor maior que zero 20, fechamento em até 60 dias 20, Origem 20. Faixas: Alta a partir de 70, Média de 40 a 69, Baixa abaixo de 40. Nada disso tem base histórica da Eplast. Se discordar, o administrador ajusta.
- **Regra, não modelo de IA.** A pontuação é uma conta fixa e explicável, calculada na hora; não grava histórico. Se precisar de histórico ou de previsão por IA, é outra entrega.
- **Campo "Previsão Einstein" já existente** em Oportunidade não foi usado nem alterado. Confirme se ele mede a mesma coisa.
- **Lead sem setor e sem origem** nunca é Alta. **Oportunidade encerrada** (ganha ou perdida) fica "Encerrada", nota 0. **Fechamento já vencido** não ganha o ponto de prazo. **Lead convertido** mantém a nota que tinha.
- **Só Lead e Oportunidade** (não Conta nem Pedido). Nada é enviado para fora do Salesforce, nem e-mail.
- **Acesso:** o conjunto de permissões deve ser atribuído pelo administrador aos usuários de vendas e gestores.

## O que não dá para conferir pela tela
- Que a entrega não criou automação, e-mail ou integração, e que as automações existentes de oportunidade continuam funcionando: comprovado pelo time em `05-testes.md` (revisão do pacote e alteração de oportunidade sem erro). Os testes automáticos do sistema para oportunidade não foram rodados.
- Taxa de ganho por faixa: só se mede depois de meses de uso, com relatório existente.
