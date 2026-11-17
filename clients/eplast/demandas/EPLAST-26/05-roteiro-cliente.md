# EPLAST-26 — Roteiro de teste: prioridade de leads e oportunidades

**O que foi entregue.** Leads e oportunidades passam a mostrar, numa seção chamada "Prioridade", um **Score de prioridade** (de 0 a 100) e uma **Faixa de prioridade** (AA, A, B, C ou D, ou "Não classificado"). O score indica a prioridade comercial, não a chance de fechar o negócio. Os pesos e os cortes das faixas ficam num cadastro que o administrador ajusta sem desenvolvimento. Há também listas prontas para ordenar e filtrar.

**Situação do teste automático:** o time comprovou na sandbox de testes (QAS), com registros de teste, os valores dos Testes 1 a 5 (consulta e, para o Lead com engajamento Alto e a oportunidade com score 45, também na tela), e que os campos de score e faixa não aceitam edição por código (Teste 6). Ficam para quem segue este roteiro: a conferência pela tela dos Testes 6 e 7 (as listas na QAS mostram dados reais, que o time não abre), o Teste 8 e a confirmação das premissas do fim do documento.

## Antes de começar

- **Ambiente:** a sandbox QAS da Eplast (Partial Copy).
- **Perfil:** usuário comercial com permissão de ver e editar Leads e Oportunidades e com o conjunto de permissões "Score de prioridade" (PS_Comercial_ScorePrioridade). Para os Testes 1 a 3 (Lead com engajamento), é preciso também ter acesso ao campo de engajamento do Marketing Cloud (perfil de marketing ou o conjunto de permissões "Retorno Marketing Cloud", PS_Marketing_RetornoMC). Sem esse acesso, o campo de engajamento não aparece para você.
- **Dados de teste (não use registros reais).** Crie, com o nome começando por "TESTE EPLAST-26":
  - 4 Leads com Empresa "TESTE EPLAST-26", Status "Contatado", Setor "Alimentos" e Origem do lead "Campanha". Preencha o campo de engajamento do Marketing Cloud assim: Lead 1 = Alto; Lead 2 = Médio; Lead 3 = Baixo; Lead 4 = deixe vazio. Se o campo não puder ser editado à mão, peça ao time para preencher.
  - 2 Oportunidades do tipo "Indústria", numa Conta de teste: A) fase "Negociação Comercial", marcada como descoberta concluída e orçamento confirmado, com Próximo passo preenchido e uma tarefa concluída com data de 5 dias atrás; B) fase "Qualificação", sem mais nada preenchido.

## Teste 1 — Lead com engajamento Alto
1. Abra o Lead 1 e vá à aba Detalhes.
2. Role até a seção "Prioridade".

**Resultado esperado:** Score de prioridade **15** e Faixa de prioridade **D**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead com engajamento Médio e Baixo
1. Abra o Lead 2 e veja a seção "Prioridade".
2. Abra o Lead 3 e veja a seção "Prioridade".

**Resultado esperado:** Lead 2: Score **10**, Faixa **D**. Lead 3: Score **5**, Faixa **D**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem informação de engajamento
1. Abra o Lead 4 (engajamento vazio) e veja a seção "Prioridade".

**Resultado esperado:** Score **0** e Faixa **Não classificado**. Setor, Origem e Status "Contatado" não dão pontos (esses critérios saíram do cálculo).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade com evidências de avanço
1. Abra a Oportunidade A, aba Detalhes, seção "Prioridade".

**Resultado esperado:** Score **45** e Faixa **C** (10 descoberta + 10 orçamento + 5 fase avançada + 10 atividade nos últimos 30 dias + 10 próximo passo).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Oportunidade sem evidências e oportunidade encerrada
1. Abra a Oportunidade B e veja a seção "Prioridade".
2. Altere a fase da Oportunidade B para "Fechado/Perdido", salve e reabra a seção "Prioridade".

**Resultado esperado:** passo 1: Score **0**, Faixa **D**. Passo 2: Score **0**, Faixa **Não classificado**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Campos não podem ser editados
1. Abra a Oportunidade A e clique em "Editar".
2. Procure os campos "Score de prioridade" e "Faixa de prioridade".

**Resultado esperado:** os dois campos aparecem só para leitura (sem caixa para digitar) ou não aparecem no formulário de edição. Repita no Lead 1 com o mesmo resultado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Listas de prioridade
1. Em Leads, abra a lista "Leads abertos por prioridade" e clique no título da coluna "Score de prioridade" para ordenar.
2. Em Oportunidades, abra a lista "Oportunidades abertas por prioridade" e confira as colunas.
3. Abra a lista "Oportunidades de prioridade AA e A".

**Resultado esperado:** passo 1: os leads ordenam pelo score, e a coluna de engajamento aparece. Passo 2: aparecem as colunas "Próximo passo" e "Última atividade", além de score e faixa. Passo 3: a lista mostra só oportunidades das faixas AA ou A. **Hoje ela deve estar vazia**, porque com os campos existentes o score máximo é 45 e nenhuma oportunidade chega a A.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — O Marketing Cloud não é acionado pelo cálculo
1. Em um dos Leads de teste, confira a aba Atividade e a seção "Envios de email".

**Resultado esperado:** nenhum e-mail ou mensagem foi enviado por causa do score ou da faixa.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar

Decisões tomadas sem resposta direta da Eplast. Se discordar, o ajuste é de configuração, na maioria dos casos.

- **Pontos do engajamento no Lead:** Alto 15, Médio 10, Baixo 5, "Sem engajamento" 0. Vocês definiram só o máximo (15); a escala é proporcional. Mudança: cadastro de parâmetros do score.
- **Oportunidade, "estágio com evidências de avanço" (25):** descoberta concluída 10, orçamento confirmado 10, fase a partir de "Cotação" 5. A evidência pesa mais que a fase porque a fase é declarada pelo vendedor. Mudança: pesos no cadastro; a lista de fases avançadas exige ajuste feito pelo administrador na fórmula.
- **Interação e próximo passo (20):** atividade nos últimos 30 dias vale 10; Próximo passo preenchido vale 10 (o sistema não registra se o passo foi "confirmado"). Mudança: pontos e número de dias no cadastro.
- **Prazo de compra confirmado, margem e viabilidade:** valem 0 por enquanto. A data de fechamento é previsão do vendedor, e não existem campos para margem e viabilidade.
- **"Não classificado":** Lead sem nenhuma informação de critério (hoje, engajamento vazio) e oportunidade encerrada.
- **Faixas AA, A, B, C e D** têm os mesmos rótulos do campo "Classificação" já existente, mas o score não grava nele nem o lê. Se a classificação atual deve ser alimentada pelo score, é uma demanda à parte.
- **Risco e inadimplência** ficam fora do score, e o score não libera venda bloqueada por crédito. O campo "Previsão Einstein" não foi alterado.
- **Lista de Leads prontos para abordagem** (demanda de nutrição): passou a depender das faixas AA ou A. **Hoje ela ficará vazia**, pelo mesmo motivo do Teste 7.
- **Quem altera os parâmetros:** o administrador com "Personalizar aplicativo", pelo cadastro "Score de prioridade - parâmetros".

**Atenção: hoje nenhum lead e nenhuma oportunidade passa da faixa D e C, respectivamente.** Máximo atual: Lead 15 de 100; Oportunidade 45 de 100. Para pontuar potencial de compra, aderência ao portfólio, prazo da primeira compra, contato com o decisor (Lead) e prazo confirmado, margem e viabilidade (Oportunidade), é preciso **criar ou preencher campos que não existem hoje**. Essa criação depende de decisão da Eplast e não faz parte desta entrega.

## O que não dá para conferir pela tela
- As faixas AA, A e B na prática: só alcançáveis quando existirem os campos acima. A leitura dos cortes pelo cálculo foi comprovada pelo time na sandbox de desenvolvimento (`04-verificacao.md`, caso 15).
- Cálculo para um usuário sem permissão de administrador: comprovado pelo time na sandbox de desenvolvimento (`04-verificacao.md`, caso 16).
- Taxa de ganho por faixa: só se mede depois de meses de uso.
- Evidências da execução do time, com consultas e capturas: `05-testes.md`.
