---
name: mc-preparar-sales-cloud
description: O lado Sales Cloud de uma demanda de marketing — quais dados o Marketing Cloud precisa ler e onde ficam, como o público fica identificável no CRM, consentimento e descadastro, o que volta do Marketing Cloud e onde é gravado. Use na análise, no design e no build de toda demanda que toca marketing, inclusive quando o cliente proíbe a esteira de mexer no Marketing Cloud.
---

# Preparar o Sales Cloud para o Marketing Cloud

Este é o pedaço que a esteira constrói com as mesmas regras de sempre (sandbox de dev,
branch, verificação, QA): é Sales Cloud. Vale para todo cliente, e é o **único** pedaço para
cliente que proíbe a esteira no Marketing Cloud (ex.: Eplast, regra 2 do `CLAUDE.md`).

## A seção que a análise e o design trazem

"Preparação do Sales Cloud para o Marketing Cloud", com cinco respostas:

1. **Dados que o Marketing Cloud lê.** Objeto e campo no CRM, confirmados na org (guardrail
   #3). Com o Marketing Cloud Connect, os objetos chegam como DEs sincronizadas; diga quais
   objetos e campos precisam entrar na sincronização.
2. **Como o público fica identificável no CRM.** Campo de status, campanha e membro de
   campanha, lista ou relatório. Prefira campanha e membro de campanha quando o público é de
   uma ação: é o que o Marketing Cloud Connect usa como entrada de envio e de jornada.
3. **Consentimento e descadastro.** Onde fica o opt-in (campo padrão `HasOptedOutOfEmail` no
   Contato e no Lead, ou campo próprio do cliente), quem grava e como o descadastro feito no
   Marketing Cloud volta ao CRM.
4. **O que o Marketing Cloud devolve.** Resultado de envio e de engajamento (o Marketing Cloud
   Connect grava em objetos próprios do pacote gerenciado, namespace `et4ae5`), e o que a
   demanda precisa disso no CRM (campo, relatório, automação).
5. **O que fica com quem opera o Marketing Cloud.** Lista de passos, cada um com o dono.

## Regras

- O recon confere na org o que o Marketing Cloud Connect já usa (objetos `et4ae5__*`) antes de
  propor campo novo. Não duplique campo que o conector já mantém.
- Nenhuma automação do CRM envia e-mail de marketing (Flow com alerta de e-mail, Apex de
  envio): marketing sai do Marketing Cloud.
- Subscriber Key = Id do Contato ou do Lead. Não use o e-mail como chave.
