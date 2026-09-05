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
| Branch | `feature/<DEMAND-ID>-slug` | `feature/ACME-12-valida-desconto` |
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

## Code review — reprovação automática
- SOQL ou DML dentro de loop
- Trigger com regra de negócio embutida
- Teste sem assert ou com `SeeAllData=true`
- Hardcode de ID de registro, perfil ou usuário
- Componente sem descrição
- Escopo além da demanda (refatoração não pedida)

## Registro de gate (`gates.md`)
```
| Gate | Artefato | Aprovador | Data | Observação |
|------|----------|-----------|------|------------|
| Análise | 01-analise.md | Leo | 2026-09-01 | ok com ressalva no CA-03 |
```
