# EPLAST-26 — Roteiro de teste: prioridade de Leads e Oportunidades

**O que foi entregue.** Cada Lead e cada Oportunidade passa a mostrar um **Score de prioridade** (0 a 100) e uma **Faixa de prioridade** (AA, A, B, C ou D, ou "Não classificado"). O valor se recalcula sozinho a cada vez que o registro é aberto; ninguém digita. Os pesos e os cortes das faixas ficam num cadastro de parâmetros que o administrador pode ajustar sem desenvolvimento.

**Situação do teste automático:** comprovado na sandbox de QA: Lead sem engajamento (0 e "Não classificado"), saída dos critérios antigos, as cinco situações de Oportunidade (45 C; 0 D; 35 D; 45 C; encerrada 0 "Não classificado"), campos bloqueados para edição e parâmetros iniciais. **Não comprovado:** Leads com engajamento Alto, Médio, Baixo ou "Sem engajamento", porque o usuário do teste automático não vê o campo "Engajamento Marketing Cloud" na QA. Esses (Testes 1 a 3) e a conferência visual dos campos na tela ficam para quem segue este roteiro. Os valores também passaram na sandbox de desenvolvimento.

## Antes de começar
- **Ambiente:** a sandbox que a Eplast chama de QAS.
- **Perfil:** um usuário comercial com o conjunto de permissões "Comercial - Score de prioridade" (leitura dos campos novos). Para os Testes 1 a 3, o usuário também precisa ver o campo "Engajamento Marketing Cloud" no Lead (permissão de marketing).
- **Dado de teste:** crie os registros abaixo com o nome começando por "TESTE EPLAST-26" e apague-os ao final. Não use registros reais.
  - Leads: com Empresa "TESTE EPLAST-26", Status "Contatado".
  - Oportunidades: tipo de registro Indústria, numa Conta de teste.

## Teste 1 — Lead com engajamento Alto
1. Abra Leads e clique em Novo.
2. Preencha Sobrenome "TESTE EPLAST-26 A", Empresa "TESTE EPLAST-26", Status "Contatado" e campo "Engajamento Marketing Cloud" = Alto. Salve.
3. Na tela do Lead, procure o Score de prioridade e a Faixa de prioridade.

**Resultado esperado:** Score **15** e Faixa **D**. (Hoje nenhum lead passa de D, ver "O que assumimos".)
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead com engajamento Médio, Baixo e "Sem engajamento"
1. Crie três leads iguais ao do Teste 1, mudando só o "Engajamento Marketing Cloud" para Médio, Baixo e "Sem engajamento".
2. Abra cada um e leia Score e Faixa.

**Resultado esperado:** Médio: **10** e **D**. Baixo: **5** e **D**. Sem engajamento: **0** e **D**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem informação de engajamento e saída dos critérios antigos
1. Crie um lead com Status "Contatado", Setor "Alimentos", Origem do lead "Campanha" e o campo de engajamento vazio.
2. Abra o lead.

**Resultado esperado:** Score **0** e Faixa **Não classificado**. Status, setor e origem não somam mais pontos.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade com boas evidências
1. Crie uma Oportunidade Indústria com Fase "Negociação Comercial", marcada "Descoberta concluída" e "Orçamento confirmado", campo "Próximo passo" preenchido e Data de fechamento daqui a 30 dias.
2. Na aba Atividade, registre uma tarefa **concluída** com data de 5 dias atrás.
3. Reabra a Oportunidade.

**Resultado esperado:** Score **45** e Faixa **C**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Oportunidade sem nada
1. Crie uma Oportunidade Indústria na Fase "Qualificação", sem marcações, sem próximo passo e sem tarefas.
2. Abra a Oportunidade.

**Resultado esperado:** Score **0** e Faixa **D**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Limite de 30 dias da interação
1. Crie duas Oportunidades iguais à do Teste 4.
2. Na primeira, registre uma tarefa concluída de 30 dias atrás. Na segunda, de 31 dias atrás.
3. Abra as duas.

**Resultado esperado:** a primeira com **45** e **C**; a segunda com **35** e **D**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Oportunidade encerrada
1. Abra uma Oportunidade de teste e mude a Fase para "Fechado/Perdido". Salve.
2. Reabra.

**Resultado esperado:** Score **0** e Faixa **Não classificado**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Campos bloqueados para edição
1. Abra uma Oportunidade de teste e clique em Editar.
2. Procure Score de prioridade e Faixa de prioridade.

**Resultado esperado:** os dois campos aparecem só para leitura (não dá para digitar). Repita num Lead de teste.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Visão por faixa e colunas das listas
1. Abra Oportunidades e escolha a lista "Oportunidades de prioridade AA e A".
2. Escolha a lista de Oportunidades abertas por prioridade e veja as colunas.
3. Escolha a lista de Leads abertos por prioridade e veja as colunas.

**Resultado esperado:** a primeira lista mostra só oportunidades abertas de faixa AA ou A (hoje deve ficar **vazia**, porque com os campos atuais ninguém chega a A). A lista de Oportunidades tem as colunas "Próximo passo" e "Data da última atividade". A de Leads tem a coluna "Engajamento Marketing Cloud". Ordene pela coluna de score: a ordem deve ser decrescente ao clicar duas vezes.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Oportunidade continua funcionando como antes
1. Crie uma Oportunidade de teste, depois altere Valor, Próximo passo e Data de fechamento.
2. Salve a cada alteração.

**Resultado esperado:** salva sem erro novo, e o Score muda ao preencher o próximo passo. (Mudar a Fase para "Cotação" sem Catálogo de preços é barrado por uma regra que já existia: escolha um catálogo.)
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
Decisões tomadas por falta de resposta, para confirmar na homologação:
- **Quase nada passa de D hoje.** Pelos critérios que você enviou, o máximo hoje é **15 de 100 no Lead** e **45 de 100 na Oportunidade**: as faixas AA, A e B ficam fora de alcance até existirem os campos que faltam (tabela abaixo). Isso vale também para o aviso "Pronto para abordagem" da nutrição de leads, que depende das faixas AA ou A e hoje ficará sempre desmarcado. Confirma que quer criar esses campos?
- **Pesos que escolhemos:** Engajamento Alto 15, Médio 10, Baixo 5. Oportunidade: descoberta concluída 10, orçamento confirmado 10, fase a partir de "Cotação" 5, interação nos últimos 30 dias 10, próximo passo preenchido 10. Faixas: AA a partir de 90, A 75, B 60, C 40, abaixo disso D. Confirma?
- **"Próximo passo confirmado"** é lido como campo "Próximo passo" preenchido (o sistema não registra confirmação).
- **Faixa "Não classificado":** Lead sem nenhuma informação de critério e Oportunidade encerrada.
- **Rótulos AA a D** são iguais aos do campo "Classificação" já existente, mas a faixa nova não escreve nele nem o lê.
- **Risco e inadimplência** ficam fora do score.
- O score não sai do Salesforce e não dispara mensagem. Tudo de marketing continua com o Marketing Cloud.

Critérios que dependem de campo a criar ou preencher (valem 0 hoje):

| Objeto | Critério (peso) | O que falta |
|---|---|---|
| Lead | Potencial de compra mensal (30) | Campo novo |
| Lead | Aderência ao portfólio (25) | Campo novo |
| Lead | Prazo da primeira compra (20) | Campo novo |
| Lead | Cadastro qualificado e contato com decisor (10) | Regra e campo novo |
| Oportunidade | Prazo de compra confirmado (20) | Campo "Prazo confirmado pelo cliente" |
| Oportunidade | Margem (20) | Margem na Oportunidade e política de margem |
| Oportunidade | Viabilidade de atendimento (15) | Campo novo |

## O que não dá para conferir pela tela
- A prova do cálculo com registros sintéticos, a limpeza dos dados e a inexistência de automação nova de e-mail, integração ou código estão em `05-testes.md`.
- A taxa de ganho por faixa só pode ser medida meses depois da entrada em uso.
