---
name: marketing-cloud-doutrina
description: Regras do agente de Marketing Cloud na esteira — o que ele entrega (o pacote mc/), o que nunca faz (envio, dado real, conta de produção), como o pacote é validado e implantado por uma pessoa, e quais skills de Marketing Cloud ler para cada peça. Use antes de desenhar ou construir qualquer coisa para o Salesforce Marketing Cloud.
---

# Marketing Cloud na esteira (versão 1)

Começou em 2026-11-28 com o que a esteira já tem: repositório, Python e skills. **O agente
não se conecta ao Marketing Cloud nesta versão.** Ele produz um pacote revisável, que um
validador confere e uma pessoa implanta. A conexão com a conta (API) é a versão 2, depois de
existir uma unidade de negócio de teste (ver "O que vem depois").

## Por que o Marketing Cloud é diferente do Sales Cloud

- **Não há sandbox.** A conta do cliente é produção. O guardrail #1 (produção é proibida) vale
  inteiro: o agente não implanta, não altera e não dispara nada na conta do cliente.
- **Um erro sai para fora.** Um envio errado chega à caixa de entrada de clientes reais e não
  se desfaz. Por isso nenhuma peça do pacote dispara envio sozinha: jornada e automação vão
  descritas e **inativas**, e quem ativa é uma pessoa, depois de testar.
- **O dado é pessoal por natureza** (e-mail, telefone, comportamento). Guardrail #2: o agente
  nunca lê nem escreve dado de contato real. Exemplos e massa de teste são fictícios, com
  domínio reservado (`@example.com`).

## Antes da primeira demanda de um cliente

Rode a revisão da conta (skill `mc-arquitetura-da-conta`): sem saber o fuso, o Subscriber Key,
o domínio de envio e o consentimento da conta, nenhuma peça do pacote é confiável.

## Regras do cliente vêm primeiro

Leia o `CLAUDE.md` do cliente antes de tudo. A Eplast, por exemplo, proíbe a esteira de fazer
qualquer coisa no Marketing Cloud (regra 2): lá o agente entrega só a preparação do Sales
Cloud (skill `mc-preparar-sales-cloud`) e a especificação do que quem opera o Marketing Cloud
fará, nunca o pacote `mc/` de conteúdo, SQL ou jornada.

## O que o agente entrega

Uma pasta `mc/` dentro da demanda (`clients/<cliente>/demandas/<ID>/mc/`):

```
mc/
  README.md                  # ordem de implantação manual, dono de cada passo, rollback
  data-extensions/<Nome>.json   # skill mc-modelo-de-dados
  segmentos/<Nome>.md        # skill mc-segmentacao (quem recebe, antes de tudo)
  sql/<Nome>.sql             # skill mc-sql (uma Query Activity por arquivo)
  automacoes/<Nome>.md       # skill mc-automacao (inativa)
  conteudo/<Nome>.html       # skill mc-email (e-mail com AMPscript, skill mc-ampscript)
  jornadas/<Nome>.md         # skill mc-jornada
  massa-de-teste/<DE>.csv    # só dado fictício
```

O `README.md` tem três seções, nesta ordem, com o dono de cada passo: `## Ordem de
implantação`, `## Como testar` e `## Como desfazer`.

Rode `python3 scripts/mc_validar_pacote.py clients/<cliente>/demandas/<ID>/mc` antes de dar
a construção por concluída. Erro do validador é defeito de construção; não entregue com erro.

## Qual skill para qual peça

| Peça | Skill |
| --- | --- |
| Quem recebe: critério, consentimento, exclusões, controle, tamanho | `mc-segmentacao` |
| Data Extension, chave, relação com o contato, retenção | `mc-modelo-de-dados` |
| Consulta de segmentação ou preparo de dado (Automation Studio) | `mc-sql` |
| Rotina: gatilho, passos, verificação antes do envio, notificação | `mc-automacao` |
| Revisão da conta: estrutura, acesso, domínio de envio, conformidade, dados, operação | `mc-arquitetura-da-conta` |
| Personalização no e-mail | `mc-ampscript` |
| E-mail (HTML, rodapé, descadastro, acessibilidade) | `mc-email` |
| Jornada (entrada, reentrada, esperas, divisões, saída) | `mc-jornada` |
| O que o Sales Cloud precisa ter para o Marketing Cloud usar | `mc-preparar-sales-cloud` |

## Nunca

- Endereço, nome, telefone ou documento real em qualquer arquivo do pacote.
- Jornada ou automação marcada para ativar ou agendar sozinha.
- Automação que envia sem uma Verificação do tamanho do público antes do envio.
- Envio, mesmo de teste, a lista que não seja de endereços do time (lista semente).
- Credencial (client id, secret, token) em arquivo do repositório.
- Inventar Data Extension, campo ou pasta que existe na conta: o que já existe vem do
  cliente ou de uma exportação dele, citado com a fonte; sem isso, declare como premissa.

## O que vem depois (versão 2 em diante)

1. Unidade de negócio de **teste** na conta do cliente, isolada da de produção, com um
   pacote instalado (Installed Package, integração servidor a servidor) com escopo mínimo.
2. Credencial guardada como secret do GitHub Environment `<cliente>-mc-teste`, nunca no repo.
3. O agente cria as peças **na unidade de teste** pela API, roda as consultas lá e faz envio
   de teste só para a lista semente. A implantação na unidade de produção continua com gente.
