---
name: padrao-entrega
description: Padrões internos de entrega — nomenclatura, definition of done, code review e formato de documentação. Use em todo build, PR e entrega, exceto quando o CLAUDE.md do cliente definir convenção própria (essa tem prioridade).
---

# Padrão de delivery

Estas são as convenções **padrão**, usadas quando o cliente não define as suas próprias no
`CLAUDE.md` do workspace (`clients/<cliente>/CLAUDE.md`). Sempre confira o CLAUDE.md do
cliente primeiro — convenção de conta sobrepõe convenção padrão.

## Nomenclatura padrão
| Item | Padrão | Exemplo |
|---|---|---|
| Branch | `feature/<DEMAND-ID>` (a esteira cria assim; sufixo só em branch manual) | `feature/ACME-12` |
| Commit | `<DEMAND-ID>: imperativo` | `ACME-12: adiciona validação de desconto` |
| Campo custom | `<Prefixo>_<Contexto>__c` | defina `<Prefixo>` por cliente no CLAUDE.md dele |
| Flow | `<Objeto>_<Gatilho>_<Proposito>` | `Opportunity_BeforeSave_ValidaDesconto` |
| Classe Apex | `<Dominio><Papel>` | `OpportunityDiscountService` |
| Permission Set | `PS_<Area>_<Funcao>` | `PS_Comercial_Desconto` |

## Definition of Done
- [ ] Critérios de aceite atendidos e evidenciados
- [ ] Cobertura ≥ 85% com asserts reais (padrão interno, acima do mínimo da plataforma)
- [ ] Descrição preenchida em todo componente de metadata
- [ ] PR revisado por humano
- [ ] Deploy validado com `--dry-run` antes do real
- [ ] Plano de rollback escrito
- [ ] Passos manuais pós-deploy documentados
- [ ] `06-entrega.md` completo
- [ ] Gates registrados em `gates.md`

## Linhas que o Squad OS lê
Escreva exatamente neste formato — o portal extrai daqui o que mostra no card:

| Onde | Linha | Quem escreve |
|---|---|---|
| `01-analise.md`, `03-design.md` | `**Estimativa de esforço:** <min>–<max> h` (a do design vence) | ba-discovery, arquiteto |
| `05-testes.md`, no topo | `**Veredito:** aprovado` ou `**Veredito:** reprovado` | qa |
| `05-testes.md`, no topo | ``**Org de teste:** `sbx-<cliente>-qa` `` — a org em que rodou de verdade | qa |
| `05-testes.md` | um título `### FALHA <n> (crítica\|média\|branda) — <resumo>` por falha | qa |

Sem a linha, o card não mostra o dado — e não se inventa número para preencher.

## O que nunca entra no PR
- Retrieve de recon (vai para `/tmp/recon`, ver `org-recon`). Em `force-app/` só o que a
  demanda cria ou altera — o PR de diagnóstico da SOMOSAGILITY-23 chegou com 244 processos
  de aprovação copiados da org.
- `demandas/<ID>/anexos/` e `comentarios-do-card.md` — existem só no runner (`.gitignore`).
- Username, e-mail ou saída crua de `sf org display` — o scan de PII bloqueia o push.

## Code review — reprovação automática
- SOQL ou DML dentro de loop
- Trigger com regra de negócio embutida
- Teste sem assert ou com `SeeAllData=true`
- Hardcode de ID de registro, perfil ou usuário
- Componente sem descrição
- Escopo além da demanda (refatoração não pedida)
- Componente em `force-app/` que não está no plano de build
- Fixture de teste que não preenche campo exigido por validation rule ativa no objeto

## Registro de gate (`gates.md`)

**Não escreva neste arquivo.** Quem escreve é `sfagents`, em
`src/salesforce_agents/gates.py`, no momento em que o humano aprova — e cada
bloco carrega o sha256 de cada artefato que estava na mesa naquele momento:

```
## aguardando_gate_design

- **Aprovado por:** Leonardo
- **Quando:** 2026-09-11T14:02:11+00:00
- **Commit:** `357b791`
- **Artefatos revisados:**
  - `02-recon.md` — sha256 `9f2b1c4a7e5d0836` (2140 bytes)
  - `03-design.md` — sha256 `1a7c9e02b4f6d381` (8812 bytes)
```

Era tabela escrita à mão pelo agente até 2026-09-11. O problema não era o
formato: "Leo aprovou a análise em 01/09" não diz nada se `01-analise.md` mudou
depois, e o único rastro do gate bloqueante da doutrina dependia de o modelo
lembrar de escrever. Agora `sfagents demanda conferir-gates` responde se o que
está em disco ainda é o que foi aprovado.

**Leia** o arquivo antes de começar sua etapa — é lá que está o aceite da etapa
anterior, e vários agentes são instruídos a parar se ele não existir.
