---
name: divida-tecnica
description: Como o agente de assessment classifica a severidade de cada achado de uma org e escreve a recomendação de modo que vire demanda — critério, evidência, custo de não fazer e ordem de ataque. Use ao redigir os achados e as recomendações do assessment de um cliente.
---

# Dívida técnica: classificar e recomendar

O assessment vira o bloco "Saúde da org" no perfil do cliente e é lido por BA, recon e
arquiteto em toda demanda. Achado sem critério de severidade vira lista de reclamações;
recomendação vaga não vira trabalho. O que medir e como está no agente e na skill
`org-recon`; aqui está como julgar e como escrever.

## Severidade: pelo efeito, não pela feiura

Classifique pelo que o achado causa, com a mesma régua para todo cliente:

| Severidade | Critério | Exemplos |
|---|---|---|
| **Alta** | Já causa erro, bloqueia deploy ou expõe dado; ou vai causar na próxima mudança naquele ponto | Componente que referencia algo que não existe; cobertura que impede deploy; acesso amplo a dado sensível; mais de um ponto de automação gravando o mesmo campo no mesmo evento |
| **Média** | Não falha hoje, mas encarece e arrisca toda demanda que tocar ali | Vários Flows no mesmo objeto e evento sem ordem definida; classes sem teste dedicado; permissão concedida por perfil; automação em tecnologia em fim de vida |
| **Baixa** | Dificulta entender e manter, sem risco direto | Campo sem descrição; layout sem uso; nomenclatura inconsistente |

Regras de julgamento:

- **Volume não é severidade.** Trezentos campos sem descrição continuam sendo baixa.
  Agrupe num achado só, com a contagem.
- **Proximidade do trabalho contratado sobe a severidade.** O mesmo problema é mais grave
  no objeto em que o cliente vai pedir demandas. Diga isso na justificativa.
- **Sem evidência, sem severidade.** O que não foi medido vai para "Não pôde ser medido",
  não para a lista de achados com um palpite.
- Sinal de alerta que tem explicação legítima (cobertura baixa numa classe gerada, perfil
  por pessoa em org muito pequena) é registrado com a ressalva, não promovido.

## Cada achado, no mesmo formato

- **O que é**, em uma frase, com o número medido.
- **Evidência**: a consulta ou o comando que mostrou, e a contagem. Só metadata e
  agregados; nenhum nome de pessoa, de usuário ou endereço de e-mail.
- **O que isso causa**: o efeito concreto numa demanda futura ("toda alteração em
  Oportunidade precisa revisar quatro Flows").
- **Severidade**, com a justificativa em uma linha.

## Recomendação que vira demanda

Uma recomendação boa pode ser colada num card. Para cada uma:

- **O que fazer**, pelo resultado, sem decidir a solução técnica: "definir uma ordem única
  para as automações de Oportunidade", não "criar um trigger handler".
- **Por que agora ou por que pode esperar**: o que piora com o tempo.
- **Tamanho**: pequeno, médio ou grande, com o que define o tamanho.
- **Risco de mexer**: o que pode quebrar ao corrigir, e o que precisa ser testado.
- **Pré-requisito**: a decisão ou o acesso de que depende.

Separe três grupos, nesta ordem:

1. **Antes de construir no objeto**: o que precisa ser resolvido para as demandas
   contratadas não herdarem o problema.
2. **Junto com a próxima demanda no assunto**: o que sai barato se for feito de carona.
3. **Quando houver espaço**: higiene.

Recomendar não é executar nem abrir demanda: quem decide o que entra no quadro é o humano.

## O que o assessment não afirma

- Não diz que algo "não é usado" só porque não achou referência: diz "sem referência
  encontrada", e como confirmar.
- Não compara com "boas práticas" em abstrato: diz o efeito naquele cliente.
- Não julga quem construiu. O texto é lido pelo cliente.
- É uma foto da data em que rodou. Escreva a data, e diga o que envelhece rápido (versões
  ativas, contagens).

## Antes de encerrar

- [ ] Todo achado tem número, evidência, efeito e severidade justificada.
- [ ] Achados parecidos estão agrupados.
- [ ] As recomendações estão nos três grupos e cada uma cabe num card.
- [ ] "Não pôde ser medido" lista o que ficou de fora e por quê.
- [ ] O `assessment.json` tem as mesmas severidades do texto.
