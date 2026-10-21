# Comentários do card

Conversa registrada no card da demanda, em ordem cronológica. Dados pessoais
foram omitidos antes de chegar aqui. Trate como complemento de `demanda.md`:
respostas a dúvidas da análise costumam estar aqui.

## Equipe — 2026-10-20 12:51

D-01	Em qual objeto Salesforce ficam Classificação gerencial e Denominação?
JOB de Solicitação de Treinamentos (JOB_de_Solicitacao_de_Treinamentos__c)
D-02	Qual é o processo de aprovação ("aprovação da diretoria") e qual é o gatilho exato de "seguir com a aprovação": clicar em enviar, passar de uma etapa de status, ou a aprovação automática do processo?	Muda a solução: regra de validação, campo obrigatório no layout, Flow ou alteração do processo de aprovação são caminhos diferentes.
Job de ST Geral - v2, pode ser uma regra de validação
D-03	A obrigatoriedade vale só na submissão para aprovação ou também em qualquer salvamento do registro?	Determina se a regra é condicional ao status (mais simples) ou incondicional (afeta toda edição, inclusive de quem não aprova).
só na submissão
D-04	A regra vale para todos os usuários, ou há perfis/papéis isentos?	Afeta a escolha entre validação global e validação por perfil.
todos os usuários
D-05	Registros já existentes sem o campo preenchido: devem ser corrigidos em lote, ficam como estão, ou só bloqueiam na próxima edição?	Afeta se há necessidade de script de saneamento. Também define o escopo de CA-06.
ficam como estão
D-07	"Walmor" é o aprovador final ou representa um grupo/papel? Quem é o público que vai receber a mensagem de bloqueio?	Define quem valida a aceitação e onde o texto da mensagem deve aparecer (tela, e-mail, etc.).
Todos vão ver a mensagem em tela
D-08	Qual é o texto esperado para a mensagem de erro?	Necessário para o critério de aceite ser verificável por texto exato. Pode ser definido pelo consultor.
Favor preencher os campos antes de enviar para aprovação

## Equipe — 2026-10-20 12:51

Aprovou o gate "aguardando_gate_analise". A próxima etapa foi disparada.
