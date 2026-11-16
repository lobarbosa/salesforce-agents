# EPLAST-43 - Roteiro de teste: públicos de marketing no CRM

Foi entregue o lado do Salesforce para o Marketing Cloud personalizar e-mails e mensagens: públicos prontos na pasta "MARKETINGCLOUD" de Relatórios, que deixam de fora quem pediu para não receber comunicação e quem já foi convertido. Para quem usa: abrir o relatório e ver a lista de quem pode receber cada tipo de comunicação. O Salesforce não envia e-mail nem mensagem.

**Situação do teste automático:** o time executou na QAS, com dados fictícios, os públicos de prospecção, de segmento Alimentos e de celular (leads e contatos): a exclusão de opt-out e de convertidos funcionou. Ficou para quem segue este roteiro conferir pela tela, com um usuário da Eplast, a visibilidade da pasta e dos campos, e a contagem dos demais públicos.

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`). Não use produção.
- Perfil: um usuário da Eplast que o time tenha incluído no grupo "Públicos de Marketing" e que tenha recebido o conjunto de permissões "PS Marketing Públicos". Peça isso ao time se não tiver acesso à pasta.
- Dados de teste (crie você mesmo): 
  - Lead A: sobrenome "TESTE EPLAST-43 A", empresa "TESTE EPLAST-43", origem "Web", Estado SP, um celular fictício preenchido (qualquer número inventado), sem opt-out.
  - Lead B: igual ao A, sobrenome "B", com "E-mail: optou por não receber" marcado.
  - Lead C: igual ao A, sobrenome "C", com "Optou por não receber mensagem (celular)" marcado.
  - Lead D: igual ao A, sobrenome "D", sem celular.
  - Lead E: igual ao A, sobrenome "E", convertido em conta e contato (botão Converter).
  - Em todos, o setor "Alimentos" e o status "Aberto - Não contatado" (exceto o E).
- Para ver só os seus leads no relatório, use "Adicionar filtro" > Empresa começa com "TESTE EPLAST-43" (sem salvar o relatório).
- Apague os registros de teste ao terminar.

## Teste 1 — Público de prospecção por origem e prioridade
1. Abra Relatórios e a pasta "MARKETINGCLOUD".
2. Abra "LEADS PROSPECCAO ORIGEM PRIORIDADE".
3. Adicione o filtro de empresa descrito acima e execute.

**Resultado esperado:** só aparecem leads abertos e sem opt-out de e-mail, agrupados por origem e prioridade. O Lead B (opt-out de e-mail) e o Lead E (convertido) não aparecem. Leads sem prioridade calculada ("Sem dados suficientes") ficam fora.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Opt-out de e-mail fora dos públicos de segmento
1. Na pasta "MARKETINGCLOUD", abra "LEADS SEGMENTO ALIMENTOS".
2. Adicione o filtro de empresa e execute.

**Resultado esperado:** aparecem os Leads A, C e D. Não aparecem o B (opt-out de e-mail) nem o E (convertido). O C aparece, porque o opt-out de celular só vale para mensagens.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Público de mensagem para leads
1. Na pasta, abra "MSG LEADS CELULAR APTOS".
2. Adicione o filtro de empresa e execute.

**Resultado esperado:** aparecem os Leads A e B (o B só pediu para não receber e-mail). Não aparecem o C (opt-out de celular), o D (sem celular) nem o E (convertido).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Público de mensagem para contatos
1. Crie dois contatos de teste: "TESTE EPLAST-43 Contato 1" com celular e sem opt-out; "TESTE EPLAST-43 Contato 2" com celular e "Optou por não receber mensagem (celular)" marcado.
2. Abra "MSG CONTATOS CELULAR APTOS" e filtre o nome do contato começando com "TESTE EPLAST-43".

**Resultado esperado:** aparece o Contato 1 (e o contato gerado na conversão do Lead E, que tem celular). O Contato 2 não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Campos legíveis, sem erro
1. Com o usuário que recebeu "PS Marketing Públicos", abra cada relatório dos testes 1 a 4.

**Resultado esperado:** nenhuma mensagem de campo sem acesso; aparecem origem, celular, opt-out de e-mail e código do país do celular.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Contagem dos públicos existentes
1. Abra 3 relatórios de lead da pasta (por exemplo, por UF ou por setor) e anote a contagem.
2. Compare com a contagem de leads convertidos que atendem ao mesmo filtro.

**Resultado esperado:** nenhum lead convertido aparece nesses relatórios.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Conteúdo de e-mail e mensagem:** é montado no Marketing Cloud, não no Salesforce.
- **Segmentos:** os relatórios que já existiam na pasta valem como segmentos de e-mail; foram somados dois públicos de celular (leads e contatos) e um de prospecção por origem e prioridade. Confirme se falta algum segmento ou se algum pode sair.
- **Opt-out:** e-mail usa "optou por não receber e-mail"; mensagem usa "optou por não receber mensagem (celular)".
- **WhatsApp:** sem público nem campo de opt-out. Se usar, vai para a demanda de LGPD (EPLAST-34).
- **Retorno de envio:** continua gravado onde o conector do Marketing Cloud já grava; nenhum campo novo.
- **Sem campanhas do Salesforce na primeira versão:** o público é relatório, não campanha.
- **Assistente (SFAgent2):** não faz parte desta entrega.
- **Lead convertido:** sai de todos os públicos de lead (passa a ser comunicado como contato). Lead "Fechado - Não convertido" continua nos públicos, pois a Eplast mantém um público próprio para ele. Confirme se ele deve receber comunicação.
- **Público de mensagem é único por objeto:** um para leads e um para contatos, recortados pelas colunas, não um por segmento.
- **Origem:** o agrupamento do público de prospecção usa o campo "Origem do lead".
- **Quem vê os públicos:** só quem a Eplast incluir no grupo "Públicos de Marketing" e no conjunto "PS Marketing Públicos"; nada foi atribuído a ninguém.
- **Relatórios com nome técnico estranho ("Cpia de…") e duplicados** não foram corrigidos.
- Aviso: o relatório "LEADS ES" não exclui opt-out de celular na QAS; vale para e-mail.

## Passos de quem opera o Marketing Cloud (fora desta entrega)
- Conectar e configurar o Marketing Cloud Connect e criar os públicos lá a partir dos relatórios.
- Compor conteúdo, personalização, jornada e envio.
- Aplicar a regra de consentimento do Marketing Cloud, se houver.
- Avisar-se de que os relatórios de lead agora excluem convertidos (as contagens caem).
- Incluir usuários no grupo "Públicos de Marketing" e no conjunto de permissões.

## O que não dá para conferir pela tela
Ausência de envio de e-mail/mensagem no CRM e de automação nova em Conta, Oportunidade e Pedido: comprovada pelo time em `05-testes.md` (casos Q7 e Q8).
