---
name: salesforce-doutrina
description: Critérios de decisão da plataforma Salesforce — quando usar configuração, Flow ou Apex, limites de governador, ordem de execução e armadilhas comuns. Use em todo desenho de solução e code review.
---

# Doutrina de plataforma

## Ordem de preferência
1. **Configuração nativa** (campo fórmula, roll-up, validation rule, aprovação padrão)
2. **Declarativo** (Flow)
3. **Código** (Apex, LWC)

Só desça de nível com justificativa escrita. Descer sem motivo é a principal fonte de
custo de manutenção em projeto Salesforce.

## Quando Flow não resolve e vira Apex
- Lógica que precisa de rollback transacional complexo
- Callout com tratamento de erro elaborado / integração assíncrona
- Volume alto com risco de limite de elementos por transação
- Recursão que exige controle de estado
- Necessidade de teste unitário determinístico sobre a regra

## Armadilhas frequentes
- Flow record-triggered sem critério de entrada → roda em todo update, mata performance
- Múltiplas automações no mesmo objeto/evento → ordem de execução imprevisível
- SOQL/DML em loop → estoura governador com 200 registros
- Trigger sem framework → lógica duplicada e recursão
- `SeeAllData=true` em teste → quebra em outra org
- Roll-up summary só existe em relacionamento master-detail; lookup exige Flow ou Apex
- Formula field tem limite de caracteres compilados — cheque antes de prometer

## Ordem de execução (resumo operacional)
Validation rules → before triggers/before-save Flows → after triggers → assignment rules →
auto-response → workflow → escalation → record-triggered Flows (after) → roll-up → sharing.
Se a solução depende dessa ordem, isso é um risco: documente explicitamente no design.

## Governador (números que importam)
- 100 SOQL síncronos por transação
- 150 DML por transação
- 50.000 registros retornados
- 10.000 registros por DML
- 6 MB heap síncrono / 12 MB assíncrono
- 10s CPU síncrono

Ao desenhar, estime contra esses números com o volume real do cliente (do recon).

## Complemento
Esta skill é doutrina, não referência completa. Para detalhe de API ou release recente,
consulte a documentação oficial via WebFetch e cite a fonte — não responda de memória.
