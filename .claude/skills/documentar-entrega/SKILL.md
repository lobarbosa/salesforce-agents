---
name: documentar-entrega
description: Como o agente de documentação escreve o 06-entrega.md para três leitores — o cliente que vai usar, o consultor que vai subir em produção e quem vai dar manutenção depois. Use na etapa de documentação, ao final do ciclo.
---

# Documentar a entrega

O `06-entrega.md` é o que sobra da demanda quando todo mundo já esqueceu o contexto. Ele é
lido por três pessoas diferentes, com perguntas diferentes. O formato das linhas que o
Squad OS lê está na skill `padrao-entrega`; aqui está o conteúdo.

## De onde vem cada coisa

Não escreva de memória nem do que a demanda pedia. Escreva do que foi feito:

| Informação | Fonte |
|---|---|
| O que foi pedido e os critérios | `01-analise.md` |
| O que foi decidido e por quê | `03-design.md`, incluindo decisões do responsável |
| O que foi construído | `04-plano-build.md` e a branch |
| O que foi provado | `04-verificacao.md` e `05-testes.md` |
| O que foi implantado e o rollback | o registro do release |

Se o design diz uma coisa e o build fez outra, vale o que foi construído e provado, e a
diferença entra em "O que mudou em relação ao desenho". Se uma informação não está em
nenhum artefato, pergunte ou escreva "não registrado"; não complete.

## Para o cliente: o que mudou no dia a dia

Primeira seção, em linguagem de usuário, sem nome de API:

- o que a pessoa passa a ver ou a poder fazer, e onde na tela;
- o que passa a acontecer sozinho, e quando;
- quem é afetado (por perfil ou área, nunca por nome de pessoa);
- o que **não** mudou, quando a dúvida é provável;
- as limitações: o que a entrega não faz e o cliente poderia esperar que fizesse.

Uma pessoa do negócio precisa entender esta seção sem ler o resto.

## Para o consultor: subir em produção

- a lista de componentes, a sequência e os passos manuais, com dono;
- o que ativar e o que desativar, com as versões;
- pré-requisitos em produção que as sandboxes não mostram (licença, usuário, fila com
  membro, credencial de integração);
- o que conferir logo depois de subir, e o sinal de que é preciso voltar;
- o plano de rollback.

Isto complementa a skill `subir-producao`; não repita o procedimento dela, só o que é
específico desta demanda.

## Para a manutenção: como funciona

- os componentes, com nome de API e tipo, e o papel de cada um em uma linha;
- o caminho do processo em passos: o que dispara, o que cada etapa decide, o que grava;
- onde estão os parâmetros que alguém pode precisar mudar (Custom Metadata, rótulo,
  valor de picklist) e o efeito de mudar;
- as decisões que não são óbvias e o motivo, com a alternativa descartada;
- o que mais roda no mesmo objeto e pode interferir;
- como testar de novo: a fixture usada e os casos do QA.

## Dívida e pendência

Separe o que ficou aberto, para não se perder:

- limitação conhecida e aceita, com quem aceitou;
- dívida técnica encontrada no caminho e não tratada (fora do escopo);
- falha branda do QA que não impediu a aprovação;
- sugestão de demanda futura.

Cada item em uma linha, de modo que possa virar um card.

## Rastreabilidade

Identificador da demanda, branch, PR, identificador do deploy, org e data. Demandas
anteriores relacionadas, quando esta corrige ou estende outra.

## Regras de escrita

- Português, frases completas, sem enfeite e sem jargão na seção do cliente.
- Nenhum nome de usuário da org, endereço de e-mail, telefone ou documento: formato de
  e-mail bloqueia o push, e o dado não tem por que estar aqui. Cite a org pelo alias.
- Nenhum exemplo com dado real de cliente. Exemplo usa o dado de teste.
- Nome de componente exatamente como está na org, para ser achado por busca.
- Não copie os artefatos inteiros: resuma e aponte para o arquivo.

## Antes de encerrar

- [ ] A seção do cliente se entende sozinha.
- [ ] Todo componente do pacote aparece na lista, e nenhum a mais.
- [ ] Passos manuais para produção têm dono.
- [ ] Limitações e dívida estão separadas e viram card com facilidade.
- [ ] O arquivo foi gravado e conferido no disco.
