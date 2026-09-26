---
name: conferir-gate
description: Checklist do que revisar em cada um dos 4 gates humanos bloqueantes da esteira (análise, design, PR, homologação) antes de aprovar. Use sempre que for aprovar um gate no Squad OS, nunca aprove só porque o botão está disponível.
---

# Conferir um gate antes de aprovar

Aprovar é mecânico — `sfagents`/`gates.py` escreve `gates.md` sozinho, com o sha256 de cada
artefato que estava na mesa. **Revisar não é mecânico.** Esta skill é o que olhar antes de
clicar em aprovar, por tipo de gate.

Regra que vale para todos os quatro: leia o artefato de verdade, não confie no resumo do
card. O artefato que este gate está julgando é sempre o que a etapa anterior produziu
(`REQUIRED_ARTIFACTS` em `demands.py`):

| Gate | Artefato em julgamento | Quem aprova |
|---|---|---|
| `aguardando_gate_analise` | `01-analise.md` | consultor |
| `aguardando_gate_design` (**bloqueante**) | `02-recon.md` + `03-design.md` | arquiteto humano |
| `aguardando_gate_build` | `04-plano-build.md` (mais o PR aberto) | revisor do PR |
| `aguardando_homologacao` | `05-testes.md` | cliente |

## Gate de análise (`aguardando_gate_analise`)

- Os critérios de aceite em `01-analise.md` refletem o que o consultor pediu na demanda
  original, ou o `ba-discovery` interpretou algo diferente?
- Toda pergunta/pendência que o agente marcou como "premissa a validar" tem resposta —
  ou pelo menos está visível para quem vai desenhar a solução depois? O modal já recusa
  aprovar com pergunta em aberto sem resposta; não contorne isso respondendo qualquer coisa
  só para destravar.
- Faltou algum critério óbvio que o pedido original menciona e a análise não cobriu?

## Gate de design (`aguardando_gate_design`) — o mais caro de errar

Este é o único gate **bloqueante** da doutrina — erro aqui compõe nos 6 clientes.

- A decisão declarativo vs. código em `03-design.md` está justificada, não só afirmada?
  Config/Flow deveria ser a primeira pergunta — código só quando o arquiteto explica por que
  declarativo não atende (limite de governador, lógica que Flow não expressa bem, etc.).
- `02-recon.md` mostra que o que já existe na org foi de fato consultado — objetos, campos,
  automações e permission sets impactados aparecem nomeados, não genéricos.
- O design considera o que acontece com dados/registros existentes, não só o caso novo?
- Se a demanda é de sustentação (não projeto), o design está proporcional ao tamanho do
  problema — "design enxuto" não significa pular a decisão, significa não super-desenhar.

## Gate de PR (`aguardando_gate_build`)

- O PR abre contra `feature/<DEMAND-ID>` (nunca direto em `main`) e os checks de CI estão
  verdes: `ci-python.yml`/`ci-squad-os.yml` conforme o que mudou, e
  `ci-salesforce-validate.yml` (deploy validate, check-only) se `force-app` mudou.
  Todo build Apex tem classe de teste dedicada e cobertura mínima de 85% por classe.
- `04-plano-build.md` bate com o que o PR de fato contém — sobrou algo do plano que não foi
  implementado, ou o PR tem mais coisa do que o plano previa?
- Nomenclatura de campo/Flow/classe segue a skill `padrao-entrega` (ou a convenção do
  `CLAUDE.md` do cliente, que tem prioridade).

## Gate de homologação (`aguardando_homologacao`) — o único do cliente

- `05-testes.md` cobre os critérios de aceite do gate de análise um a um, com evidência
  (print, log, ou resultado de query agregada) — não só "testado e funcionando".
- O teste rodou na sandbox de **qa**, nunca em dev nem em produção (`ambientes.py` já
  recusaria um comando fora disso, mas confira que o roteiro relatado é da org certa).
- Se você é o cliente aprovando: o resultado bate com o que você pediu, não só com o que foi
  entregue? Recusar com uma observação concreta é sempre uma opção — a demanda volta para
  correção, não é penalidade.

## Depois de aprovar

Se corrigir algo manualmente depois de um gate já aprovado (código, design, o artefato em
si), rode:

```bash
sfagents demanda conferir-gates --client <cliente> <DEMAND-ID>
```

Isso diz se o que está em disco hoje ainda é o que foi aprovado — sai diferente de zero
quando divergiu. Divergir não é erro (corrigir depois às vezes é o certo), mas ninguém pode
descobrir isso por acidente.
