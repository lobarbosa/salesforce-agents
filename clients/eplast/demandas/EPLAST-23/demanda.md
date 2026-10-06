# Agentforce: Resumo inteligente de cliente: contatos, negociações, pedidos e ocorrências consolidados sob demanda

Objetivo

Implementar um agente no Agentforce que permita ao usuário solicitar um resumo consolidado de um cliente, reunindo informações do Salesforce para apoiar a preparação de reuniões, o acompanhamento comercial e o atendimento.

História de usuário

Como usuário comercial ou de atendimento, quero solicitar um resumo do cliente em linguagem natural para entender seu relacionamento com a empresa sem consultar cada registro individualmente.

Escopo funcional

Ao receber uma solicitação como “Resuma o cliente [nome do cliente]”, o agente deverá identificar a conta e apresentar:

Visão geral: identificação do cliente e principais informações cadastrais relevantes.

Contatos: contatos vinculados, cargos e informações de contato disponíveis.

Negociações: oportunidades em andamento, etapas, valores, previsão de fechamento e negociações recentes.

Pedidos: pedidos recentes, datas, valores e respectivos status.

Ocorrências: casos de atendimento em aberto e ocorrências recentes, destacando assunto, prioridade e status.

Síntese: principais pontos de atenção identificados nos registros, como negociações próximas do fechamento ou ocorrências pendentes.

O resumo deverá ser objetivo, organizado por assunto e incluir referências aos registros consultados para permitir o aprofundamento pelo usuário.

Regras de funcionamento

Gerar o resumo sob demanda, utilizando os dados disponíveis no momento da consulta.

Respeitar as permissões de acesso do usuário aos registros e campos.

Solicitar a identificação correta quando houver mais de um cliente correspondente.

Informar quando não houver dados disponíveis em determinada categoria.

Basear as conclusões nos registros consultados, sem inventar informações.

Realizar apenas consultas, sem alterar registros durante a geração do resumo.

Critérios de aceite

O usuário consegue solicitar o resumo de um cliente em linguagem natural.

O agente identifica a conta correta ou solicita esclarecimento quando houver ambiguidade.

A resposta consolida contatos, negociações, pedidos e ocorrências vinculados ao cliente.

As informações são apresentadas por categoria, com uma síntese dos principais pontos de atenção.

O resumo permite acessar os registros utilizados como fonte.

Categorias sem dados são sinalizadas claramente.

Informações sem permissão de acesso não são expostas.

Nenhum registro é criado ou alterado pela solicitação.
