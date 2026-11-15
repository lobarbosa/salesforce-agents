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
   de build bloqueado, e não devolva pergunta sobre isso ao cliente. Pergunta de **regra
   de negócio** sem resposta segue a regra 4.
2. **Tudo que é de marketing é disparado pelo Marketing Cloud, e o Sales Cloud tem de
   estar preparado para ele.** E-mail, mensagem, campanha, jornada e nutrição de leads
   saem pelo Marketing Cloud — não desenhe envio por Flow com e-mail alert, Apex de e-mail
   ou outra ferramenta de disparo dentro do CRM.
   - **Não faça nada no Marketing Cloud** (reforço de 2026-11-15): a esteira não conecta,
     não configura, não cria jornada, público ou envio lá, e não altera a conexão entre os
     dois. O que for do Marketing Cloud é passo de quem o opera, declarado no desenho, não
     contornado.
   - **Preveja o Marketing Cloud em toda demanda que toca marketing** (leads, origem,
     campanha, segmentação, público, nutrição, comunicação, relacionamento, reativação). A
     análise e o desenho trazem uma seção "Preparação do Sales Cloud para o Marketing
     Cloud" dizendo: quais dados o Marketing Cloud vai precisar ler e onde eles ficam no
     CRM (objeto e campo); como o público ou o segmento fica identificável do lado do CRM
     (campo, status, campanha e membro de campanha, relatório ou lista); o que o Marketing
     Cloud devolve e onde isso é gravado; consentimento e opt-out; e o que fica para quem
     opera o Marketing Cloud fazer com isso.
   - O build entrega só o lado do CRM dessa preparação: dado, segmento, público, status.
   - A linha de base da org tem componentes do conector Marketing Cloud Connect (namespace
     `et4ae5`). O recon confirma na org o que está instalado e quais objetos e campos já
     são usados por ele antes de propor campo ou objeto novo (regra 3).
3. **Não sobreponha o que já existe.** Antes de propor qualquer componente, o recon confere
   na org o que já cobre o pedido, e o design diz, item a item, o que reaproveita e o que
   cria. Em especial, o agente Agentforce `SFAgent2` já existe na DEV e na QA, com 4
   tópicos e 3 ações — `ConsultarPedidos`, `AgregacaoPedidos` e `IdentificarConta`
   (conferido em 2026-11-10 pela comparação QA × DEV). Demanda que fala em assistente,
   resumo, recomendação ou linguagem natural parte dele: estende tópico ou ação, não cria
   agente novo. O mesmo vale para relatórios, painéis, campos de score e automações: se
   já há um que atende, ajuste-o.
4. **Pergunta de negócio sem resposta do cliente não trava a demanda** (decisão de
   2026-11-15). O cliente não está respondendo, e o projeto precisa andar. Quando faltar
   uma resposta de regra de negócio, resolva nesta ordem, e diga de onde veio:
   1. **O que a org já mostra.** Campo, picklist, validation rule, Flow, relatório ou
      processo existente que revela como a Eplast trabalha hoje. Confirme por `sf`, só
      metadata e contagens agregadas.
   2. **O padrão.** O comportamento padrão da plataforma Salesforce ou a prática
      consolidada do squad (skills `salesforce-doutrina` e `padrao-entrega`), na opção mais
      simples e mais fácil de mudar depois.
   3. Só se nem a org nem o padrão indicam um caminho, e errar é caro ou difícil de
      desfazer, a pergunta continua aberta e bloqueia.

   Isso não é inventar: é decidir com evidência e deixar escrito. Cada decisão assim entra
   como **premissa assumida**, numa seção "Premissas assumidas (validar na homologação)",
   com a pergunta, a decisão, a evidência (o que na org ou qual padrão) e como mudar se o
   cliente discordar. Prefira deixar o ponto configurável.

   Por etapa:
   - `ba-discovery`: levante na org antes de perguntar. Escreva a premissa assumida como
     item resolvido (`- [x]`), nunca como pendência (`- [ ]`): pendência em aberto impede a
     aprovação do gate no Squad OS. Use `- [ ]` só para o caso 3.
   - `arquiteto`: discuta no design as alternativas que a análise deixou e escolha a
     melhor para o que a org tem, com o porquê. Leve as premissas assumidas adiante e
     acrescente as suas. A demanda só fica bloqueada pelo caso 3.
   - builders, `verificador` e `qa`: construam e testem conforme as premissas do design.
     Pergunta já decidida como premissa não é motivo de build bloqueado nem de reprovação.
   - `qa`: repita as premissas assumidas no roteiro do cliente, numa seção "O que
     assumimos e você precisa confirmar", em linguagem de usuário. É na homologação que o
     cliente valida.
