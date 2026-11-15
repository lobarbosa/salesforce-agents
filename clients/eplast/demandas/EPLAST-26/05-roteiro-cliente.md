# Roteiro de teste — Score e faixa de prioridade (EPLAST-26)

Foram criados, em Lead (Lead) e Oportunidade, o campo **Pontuação de prioridade** (número de 0 a 100) e o campo **Faixa de prioridade** (Alta, Média, Baixa e, para casos especiais, "Sem dados suficientes" ou "Encerrada"). Também foram criadas três listas: **Leads Abertos por Prioridade**, **Oportunidades Abertas por Prioridade** e **Oportunidades Prioridade Alta**. Para quem usa, muda que o time vê quais registros têm mais chance de avançar e pode ordenar as listas por isso.

**Situação do teste automático:** comprovado pelo time, só com contagens, na sandbox de teste (QAS): a pontuação e a faixa de Leads em todos os cenários (incluindo lead convertido), a pontuação de Oportunidades abertas nas combinações que existem na base, a faixa "Encerrada", os campos somente leitura e o conteúdo da fórmula. **Ficou para quem segue este roteiro:** oportunidade com faixa Alta (pontuação 96), as bordas de prazo (60 e 61 dias), o arredondamento de 55%, as telas e a ordenação por clique. Motivo: criar oportunidade nesta sandbox dispara automações de cotação e integração, e não houve autorização por escrito para isso; e as telas só abrem com registros que contêm dados reais.

## Antes de começar
- Ambiente: sandbox **QAS** (a "eplast--qas"). Nunca em produção.
- Perfil: usuário Comercial. Peça ao administrador para atribuir o conjunto de permissões **PS_Comercial_ScorePrioridade** a você; sem ele os campos novos não aparecem.
- Dados de teste: crie você os registros, com "TESTE EPLAST-26" no nome. Para Lead: use Empresa "TESTE EPLAST-26". Para oportunidade: crie sobre uma conta de teste, preenchendo os campos obrigatórios da sua operação, e apague os registros de teste ao final. Não use registros reais.
- Registre a data de hoje: os testes de prazo contam a partir dela.

## Teste 1 — Lead completo recebe faixa Alta
1. Crie um Lead de teste com **Setor** preenchido, **Origem do lead** preenchida e **Status** "Contatado".
2. Salve e abra o registro; na seção **Prioridade**, leia os dois campos.

**Resultado esperado:** Pontuação 100 e Faixa "Alta".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead só com setor recebe faixa Baixa
1. Crie um Lead de teste com **Setor** preenchido, sem Origem e Status "Aberto - Não contatado".
2. Abra o registro.

**Resultado esperado:** Pontuação 30 e Faixa "Baixa".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem setor e sem origem
1. Crie um Lead de teste sem Setor e sem Origem, com Status "Contatado".
2. Abra o registro.

**Resultado esperado:** Pontuação 0 e Faixa "Sem dados suficientes".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Mudar o status atualiza a pontuação
1. Crie um Lead de teste com Setor e Origem preenchidos e Status "Aberto - Não contatado". Abra e confirme Pontuação 60 e Faixa "Média".
2. Edite o Status para "Contatado" e salve.
3. Reabra o registro.

**Resultado esperado:** Pontuação 100 e Faixa "Alta".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Oportunidade com chance alta
1. Crie uma oportunidade de teste com **Probabilidade** 90%, **Valor** maior que zero, **Data de fechamento** daqui a 30 dias e **Origem do lead** preenchida.
2. Abra o registro.

**Resultado esperado:** Pontuação 96 e Faixa "Alta".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Prazo de 61 dias não pontua
1. Crie uma oportunidade de teste com Probabilidade 50%, Valor maior que zero, Data de fechamento daqui a 61 dias e sem Origem.
2. Abra o registro.
3. Altere a Data de fechamento para daqui a 60 dias e salve.

**Resultado esperado:** com 61 dias, Pontuação 40 e Faixa "Média". Com 60 dias, Pontuação 60 e Faixa "Média".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Oportunidade com chance baixa e prazo vencido
1. Crie uma oportunidade de teste com Probabilidade 10%, Valor zero ou vazio, Data de fechamento daqui a 200 dias e sem Origem.
2. Abra e confira.
3. Altere a Data de fechamento para ontem e confira de novo.

**Resultado esperado:** nos dois casos, Pontuação 4 e Faixa "Baixa" (data vencida não ganha ponto de prazo).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Arredondamento
1. Crie uma oportunidade de teste com Probabilidade 55%, sem Valor, sem Origem e fechamento daqui a 200 dias.

**Resultado esperado:** Pontuação 22 (55% vale 22 pontos, arredondado).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Oportunidade encerrada
1. Mude uma oportunidade de teste para a fase "Fechado/Ganho" e abra.
2. Repita com outra oportunidade de teste em "Fechado/Perdido" (informe o motivo de perda).

**Resultado esperado:** Faixa "Encerrada" e Pontuação 0 nas duas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Campos não são editáveis
1. Abra um Lead de teste e tente editar a Pontuação ou a Faixa (lápis do campo ou "Editar").
2. Repita em uma oportunidade de teste.

**Resultado esperado:** os dois campos aparecem sem opção de edição.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 11 — Lista de Leads ordena pela pontuação
1. Em **Leads**, abra a lista **Leads Abertos por Prioridade**.
2. Clique no título da coluna **Pontuação de prioridade** (uma vez e outra, para alternar).
3. Olhe só os leads de teste (use a busca "TESTE EPLAST-26").

**Resultado esperado:** na ordem decrescente, os leads de teste aparecem 100, 60 ou 30, depois 0.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 12 — Lista de oportunidades por faixa Alta
1. Em **Oportunidades**, abra **Oportunidades Prioridade Alta**.
2. Procure a oportunidade do Teste 5.

**Resultado esperado:** aparece só oportunidade aberta com Faixa "Alta"; a do Teste 7 e as encerradas não aparecem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 13 — A seção "Prioridade" aparece na página
1. Abra uma oportunidade de teste e um lead de teste na tela padrão.
2. Localize a seção **Prioridade** na aba de detalhes.

**Resultado esperado:** a seção mostra os dois campos nos dois objetos. Se você usa a versão de página com três colunas de Oportunidade e a seção não aparece, anote abaixo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 14 — Nada mudou no resto da oportunidade
1. Crie e altere uma oportunidade de teste (valor, fase, data) como no dia a dia.

**Resultado esperado:** as telas, cotação e validações se comportam como antes, sem erro novo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Pontos:** Lead soma Setor preenchido (30), Origem preenchida (30) e Status "Contatado" (40). Oportunidade soma Probabilidade x 0,4 (até 40), Valor maior que zero (20), fechamento em até 60 dias (20) e Origem preenchida (20). Estes pesos são nossa proposta; é o ponto que mais deve mudar.
- **Faixas:** Alta a partir de 70, Média de 40 a 69, Baixa abaixo de 40. Lead sem Setor e sem Origem fica em "Sem dados suficientes"; oportunidade encerrada fica em "Encerrada".
- **Cálculo:** a pontuação é recalculada sempre que o registro é aberto; não é gravada nem dispara nada. Não há aviso, e-mail ou fila.
- **Campo "Previsão Einstein"** que já existe em Oportunidade não foi usado nem alterado. Confirmem se é a mesma coisa; se for, podemos usá-lo no lugar dos pontos de probabilidade.
- **Fechamento vencido:** oportunidade aberta com data de fechamento no passado não ganha o ponto de prazo.
- **Arredondamento:** os pontos de probabilidade são arredondados (55% vale 22).
- **Lead convertido** conta como "contatado" e mantém pontuação. Lead "Fechado - Não convertido" não tem faixa especial e fica fora da lista de abertos.
- **Quem vê:** quem receber o conjunto de permissões PS_Comercial_ScorePrioridade (propomos os perfis Comercial, Comercial Padrão, Comercial - Analista(s), Marketing, Usuário do Marketing e administradores). As três listas ficam visíveis a todos os usuários internos.
- **Só Lead e Oportunidade** (Conta e Pedido ficam de fora). O score não sai do Salesforce, não vai ao Protheus nem ao Marketing Cloud.
- **Definição de ganho:** oportunidade ganha é a que está em fase marcada como ganha ("Fechado/Ganho"); o score não depende disso.
- **Pesos mudam por administrador** (alteração de configuração), não pelo usuário.

## O que não dá para conferir pela tela
- Contagens e conferência das fórmulas contra registros existentes, a regra de somente leitura e a existência dos componentes: evidência em `05-testes.md`.
- Taxa de ganho por faixa: só medida depois da entrada em uso, com relatório.
