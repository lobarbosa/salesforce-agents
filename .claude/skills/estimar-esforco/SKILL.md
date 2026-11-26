---
name: estimar-esforco
description: Como o BA e o arquiteto chegam à faixa de horas de uma demanda — por comparação com entregas parecidas do mesmo cliente, por componente, e dizendo o que faria a estimativa estourar. Use na análise e no design, antes de escrever a linha "Estimativa de esforço".
---

# Estimar esforço

A linha `**Estimativa de esforço:** <min>–<max> h` é lida pelo Squad OS e, em contrato de
sustentação, é o que o cliente aprova antes do build. Número tirado do nada vira briga
depois. A estimativa é de trabalho **humano**: configurar, revisar, testar, homologar e
subir. Não é o tempo do agente.

## 1. Compare antes de calcular

Procure no histórico do cliente (`rag_consultar`, com o objeto e o tipo de solução) duas ou
três demandas parecidas já entregues, e leia a estimativa do design e, quando houver, o
tempo registrado na entrega.

- Achou parecida: parta dela e ajuste pelo que é diferente. Cite a demanda na justificativa.
- Não achou: diga que a estimativa é por componente, sem referência no histórico, e alargue
  a faixa.

## 2. Some por componente

Liste o que será criado ou alterado e o que cada item pede de trabalho humano. O que mais
pesa, em ordem:

| O que pesa | Por quê |
|---|---|
| Automação concorrente no mesmo objeto | Cada Flow ou trigger vizinho é teste a mais e risco de ordem de execução |
| Regra com exceções | Cada exceção é um ramo, um caso de teste e uma pergunta ao cliente |
| Perfis afetados | Layout, permissão e teste se repetem por perfil e por tipo de registro |
| Código | Classe de teste, cobertura e revisão de código |
| Integração | Ambiente do outro lado, credencial, tratamento de erro |
| Agente Agentforce | Comportamento do modelo exige mais rodadas de teste |
| Dado a carregar ou corrigir | Preparar, validar e conferir a carga |
| Homologação | Quantas pessoas do cliente precisam aceitar, e se é ao vivo |
| Subida para produção | Passos manuais, ativações, janela |

Não esqueça o que não é construção: reunião para fechar regra, revisão do PR, roteiro de
teste, acompanhamento da homologação, subida e conferência em produção.

## 3. A faixa

- O mínimo é o caso em que as premissas se confirmam e não há volta do QA.
- O máximo inclui uma volta do QA e o esclarecimento das perguntas abertas.
- Pergunta de negócio aberta alarga a faixa. Não feche a faixa para parecer preciso.
- Se o máximo passa do dobro do mínimo, a demanda ainda está vaga: diga qual resposta
  estreitaria a faixa.

## 4. Diga o que faz estourar

Logo abaixo da linha da estimativa, as premissas que mais pesam, uma por linha, do tipo
"vale se a regra tiver só os dois casos descritos" ou "não inclui corrigir os registros já
gravados". É o que permite conversar com o cliente quando o escopo muda.

## 5. No design: refine e explique a diferença

O arquiteto já sabe o que existe na org. A estimativa do design substitui a da análise e
diz o que mudou e por quê: "subiu porque há três Flows no mesmo objeto" ou "caiu porque o
relatório já existe".

Se a estimativa do design passa do máximo da análise, destaque no topo do design. Em
contrato com horas aprovadas pelo cliente, isso precisa voltar a ele antes do build.

## Nunca

- Número sem faixa.
- Estimar só o build e esquecer teste, homologação e subida.
- Reduzir a estimativa para caber no saldo de horas do contrato. O saldo é problema de
  quem gere a conta, não da estimativa.
