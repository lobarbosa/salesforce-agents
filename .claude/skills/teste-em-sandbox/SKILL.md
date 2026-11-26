---
name: teste-em-sandbox
description: Guias do agente de QA para as duas situações que nem toda demanda tem — testar pela tela com qa_browser e testar automação agendada em duas fases. Use na etapa de QA quando um critério se confere pela tela ou quando a demanda entrega Flow ou job agendado.
---

# Teste em sandbox: guias de situação

O método de teste (casos a partir dos critérios de aceite, dados sintéticos, evidência por
caso, veredito) fica no prompt do agente (`.claude/agents/qa.md`), porque vale em toda
demanda. Aqui ficam os dois procedimentos longos que só algumas demandas precisam. Estavam
no prompt do agente, relidos a cada turno de toda sessão; saíram de lá em 2026-11-25.

| Situação | Leia |
|---|---|
| Um critério de aceite se confere pela tela | `navegador.md` (nesta pasta) |
| A demanda entrega Flow agendado, job Apex agendado ou outra automação que não dispara à mão | `agendada.md` (nesta pasta) |
| `05-testes.md` já existe com `**Veredito:** aguardando execução` | `agendada.md`, fase 2 |

Leia o arquivo inteiro antes de agir: cada passo ali vem de um achado real (QA que segurou a
sandbox por 50 minutos, agendamento apagado por reimplantação, captura de tela com dado de
cliente). Não resuma de memória.

O que não muda em nenhuma das duas:
- só a sandbox de QA do cliente, com `--target-org` explícito;
- só dado de teste que você criou; nenhuma tela ou consulta com registro real;
- não reprove por "não exercitado" o que o guia ensina a exercitar.
