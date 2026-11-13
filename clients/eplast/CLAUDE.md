# Conhecimento do cliente — Eplast

Briefing operacional para os agentes atuando nesta conta. É a fonte de verdade de
"quem é o cliente e como trabalhar por ele". Diagnósticos detalhados e materiais extensos
ficam em anexos separados; afirmações não óbvias aqui devem ter fonte — o que não foi
confirmado é hipótese a validar, nunca é inventado.

## Quem é o cliente
- Segmento / indústria:
- Contatos principais (nome, papel, como prefere ser acionado):

## Ambiente Salesforce
- Clouds em uso (Sales/Service/Marketing/Commerce/etc.):
- Org: produção — **não configurada aqui, agente nunca deve tocar** (guardrail #1)
- Sandboxes da esteira (aliases `sbx-eplast-dev` e `sbx-eplast-qa`, Environments
  `eplast-dev` e `eplast-qa`):
  - **dev** — `<instance url>` (API v<NN>). Onde os agentes constroem.
  - **qa** — `<instance url>` (API v<NN>). Onde o roteiro de teste roda, o humano homologa
    e o release entrega. A esteira para aqui.
- Convenção de nomenclatura própria do cliente (se houver — sobrepõe a skill `padrao-entrega`):
  - Prefixo de campo custom:
  - Padrão de branch/commit, se diferente do padrão do squad:

## Saúde da org
O diagnóstico roda sozinho quando a org de dev conecta pela primeira vez e fica em
`assessment.md` nesta pasta, com o resumo no perfil do cliente no Squad OS. Enquanto não
existir, não desenhe solução assumindo o que a org tem — confirme via `sf` CLI.

## Integrações existentes
(sistemas conectados ao Salesforce que uma automação pode impactar sem querer)

## Regras específicas desta conta

Decisões do responsável pela conta (Leonardo Barbosa, 2026-11-13). Valem para toda demanda
da Eplast, em qualquer etapa.

1. **Escopo não bloqueia.** O foco é entregar o projeto da Eplast. Demanda da Onda 3
   (Comercial) ou de outra onda ainda não listada em `contrato.md` está autorizada a seguir
   análise, design e build. Não trate "onda não contratada" como pendência nem como motivo
   de build bloqueado, e não devolva pergunta sobre isso ao cliente. Perguntas de **regra
   de negócio** sem resposta continuam bloqueando: escopo liberado não autoriza inventar
   regra.
2. **Tudo que é de marketing é disparado pelo Marketing Cloud.** E-mail, mensagem,
   campanha, jornada e nutrição de leads saem pelo Marketing Cloud — não desenhe envio por
   Flow com e-mail alert, Apex de e-mail ou outra ferramenta de disparo dentro do CRM. No
   CRM fica o que alimenta o Marketing Cloud: dado, segmento, público, status. Se o desenho
   depender de algo do Marketing Cloud que a esteira não alcança (ela só conecta as
   sandboxes do CRM), declare isso como passo de quem opera o Marketing Cloud, não
   contorne.
3. **Não sobreponha o que já existe.** Antes de propor qualquer componente, o recon confere
   na org o que já cobre o pedido, e o design diz, item a item, o que reaproveita e o que
   cria. Em especial, o agente Agentforce `SFAgent2` já existe na DEV e na QA, com 4
   tópicos e 3 ações — `ConsultarPedidos`, `AgregacaoPedidos` e `IdentificarConta`
   (conferido em 2026-11-10 pela comparação QA × DEV). Demanda que fala em assistente,
   resumo, recomendação ou linguagem natural parte dele: estende tópico ou ação, não cria
   agente novo. O mesmo vale para relatórios, painéis, campos de score e automações: se
   já há um que atende, ajuste-o.
