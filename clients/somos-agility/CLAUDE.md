# Conhecimento do cliente — Somos Agility

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
- Sandboxes da esteira (aliases `sbx-somos-agility-dev` e `sbx-somos-agility-qa`, Environments
  `somos-agility-dev` e `somos-agility-qa`):
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
(qualquer guardrail além dos definidos no CLAUDE.md raiz do squad — ex.: horário de
deploy permitido, aprovador obrigatório, dados sensíveis específicos do setor)
