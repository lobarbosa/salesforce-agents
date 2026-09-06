# Conhecimento do cliente — Konecta (workspace "acxya")

Briefing operacional para os agentes atuando nesta conta. É a fonte de verdade de
"quem é o cliente e como trabalhar por ele". Diagnósticos detalhados e materiais extensos
ficam em anexos separados; afirmações não óbvias aqui devem ter fonte — o que não foi
confirmado é hipótese a validar, nunca é inventado.

**TODO (preencher antes da primeira demanda real):** este arquivo ainda está no esqueleto
do template — só o que veio do próprio processo de conexão está confirmado abaixo.

## Quem é o cliente
- Segmento / indústria: a confirmar (domínio do usuário de integração é `konectabr.com`)
- Marcas atendidas: a confirmar
- Contatos principais (nome, papel, como prefere ser acionado): a confirmar

## Ambiente Salesforce
- Clouds em uso (Sales/Service/Marketing/Commerce/etc.): a confirmar
- Org: produção — **não configurada, agente nunca deve tocar**; sandbox de trabalho `sbx-acxya`
  (`https://acxya--sbxacxya.sandbox.my.salesforce.com`, API v67.0)
- Convenção de nomenclatura própria do cliente (se houver — sobrepõe a skill `padrao-entrega`):
  - Prefixo de campo custom: **nenhum** — nomear direto, sem marcador de origem (decidido em
    ACXYA-1, ex.: `Data_Aniversario__c`, não `KTA_Data_Aniversario__c`)
  - Padrão de branch/commit, se diferente do padrão do squad: nenhum registrado — usa o padrão

## Concorrentes / contexto de mercado
A confirmar.

## Integrações existentes
A confirmar — rodar recon (`sf project retrieve` de `NamedCredential`/`RemoteSiteSetting`,
já incluído na fase 4 do baseline) antes de desenhar qualquer automação nova.

## Regras específicas desta conta
Nenhuma registrada além dos guardrails do `CLAUDE.md` raiz do squad.
