# EPLAST-42 — Roteiro de teste: públicos de marketing

Foram ajustados os relatórios da pasta "MARKETING CLOUD" para que não incluam quem pediu para não receber mensagem de celular nem leads já convertidos, e foi criado o relatório "LEADS - PROSPECÇÃO PRIORIZADA". Quem monta público no Marketing Cloud passa a receber listas mais limpas. Nada é enviado pelo Salesforce.

**Situação do teste automático:** o time executou os testes na sandbox de QA com dados de teste (nomes com "EPLAST42 TESTE") e todos passaram; os dados foram apagados. Este roteiro serve para a conferência manual na homologação. Parte dos casos precisa de dados que você cria, pois os de teste foram removidos.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (QAS). Perfil: usuário com acesso aos relatórios de marketing.
- Dados de teste (crie com nome começando por "TESTE EPLAST-42", e-mail terminando em `@example.invalid`):
  - Lead A: estado SP, setor Alimentos, sem marcações de opt-out.
  - Lead B: igual ao A, com "Opt-out de celular" marcado.
  - Lead C: estado SP, sem setor e sem origem.
  - Contato com "Cancelou recebimento de e-mail" marcado, em uma conta Recorrente de teste.
  - Conta de teste com último pedido ganho há 100 dias e outra há 400 dias.

## Teste 1 — Lead com opt-out de celular não aparece
1. Abra Relatórios e a pasta "MARKETING CLOUD".
2. Abra "LEADS - SP".
3. Procure por "TESTE EPLAST-42".
Resultado esperado: o Lead A aparece; o Lead B não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead convertido não aparece
1. Converta o Lead A em conta e contato.
2. Abra de novo "LEADS - SP".
Resultado esperado: o Lead A convertido não aparece mais.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Contato que cancelou e-mail não aparece
1. Abra "RECORRENTES (ATIVOS) - GERAL" na pasta "MARKETING CLOUD".
2. Procure o contato de teste com cancelamento de e-mail.
Resultado esperado: o contato com cancelamento não aparece; os demais contatos de teste da conta aparecem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Janelas de reativação
1. Abra "SEM COMPRA - 91 A 180 DIAS" e procure a conta de 100 dias.
2. Abra "SEM COMPRA - 181 A 365 DIAS" e procure a mesma conta.
3. Abra "SEM COMPRA - MAIS DE 365 DIAS" e procure a conta de 400 dias.
Resultado esperado: a conta de 100 dias aparece só no primeiro relatório; a de 400 dias aparece só no terceiro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Relatório "LEADS - PROSPECÇÃO PRIORIZADA"
1. Abra o relatório na pasta "MARKETING CLOUD".
2. Procure os leads de teste.
Resultado esperado: o relatório agrupa os leads por Prioridade; leads com prioridade "Sem dados suficientes" (Lead C), com opt-out de celular (Lead B) ou convertidos não aparecem. Colunas: nome, empresa, estado, setor, origem, pontuação, status e e-mail (sem telefone nem documento).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Origem do lead
1. Abra um lead de teste com origem "Evento" e veja o campo de origem agrupada.
2. Abra o Lead C (sem origem).
Resultado esperado: o primeiro mostra "Evento"; o Lead C mostra "Sem origem".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Os públicos são os relatórios que já existem na pasta "MARKETING CLOUD"; não há segmento gravado no cadastro. Se preferirem outra lista, o ajuste é de filtro.
- A campanha de envio fica no Marketing Cloud; aqui não foi criada campanha. O retorno de envios continua sendo gravado pelo conector em Membro da Campanha.
- Quem pediu para não receber e-mail ou celular fica fora de todos os públicos. Não foi criado novo registro de consentimento.
- Prospecção usa origem e prioridade; "Sem dados suficientes" fica de fora.
- Reativação usa as faixas 91 a 180, 181 a 365 e mais de 365 dias sem compra.
- Quem opera o Marketing Cloud monta públicos, jornadas e frequência de envio lá; isso não foi feito.

## O que não dá para conferir pela tela
- Que nenhum fluxo, código ou componente de envio foi criado, e que nada do conector do Marketing Cloud foi alterado: comprovado pelo time, em `05-testes.md` (casos T11 a T13).
- As permissões de leitura dos campos de prioridade e origem no perfil de marketing: `05-testes.md`, caso T10.
