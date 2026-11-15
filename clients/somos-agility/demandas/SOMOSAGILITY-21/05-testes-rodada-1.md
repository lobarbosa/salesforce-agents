**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes — SOMOSAGILITY-21: Campo origem do Lead

`sf org list`: a única org conectada é `sbx-somos-agility-qa` (Sandbox, Connected). Todos os comandos usaram esse alias. Não existe `05-deploy-qa.md`, o que é coerente com o build: nada foi criado em `force-app`.

## Falhas

### FALHA 1 (crítica) — Nenhuma correção entregue no Salesforce: CA-01, CA-02 e CA-03 não são demonstráveis
- **Reproduzir:** criar um Lead sem `LeadSource` na QA, que é o payload que o site envia segundo as hipóteses do design, e ler o campo.
- **Obtido:** o Lead fica com `Prospecção - Gerente de Contas`, o default da org. Se o payload enviar o texto "Web Site Agility" (o label), o valor é gravado solto, fora da lista de opções (o picklist não é restrito).
- **Esperado:** Lead do site com Origem do lead = `Web Site Agility Networks` (CA-01), sem afetar outros canais (CA-02) e sobrepondo o default (CA-03).
- **Causa provável:** o `04-plano-build.md` decidiu não construir nada. A Opção A (ajuste do payload no middleware externo) fica fora do Salesforce. A Opção F (Flow before-save, Custom Permission e Permission Set) não foi construída porque a P-2 (usuário de integração exclusivo do site) não foi confirmada. Também ficam sem resposta P-1, P-3 e P-4.
- **Para fechar:** uma de duas saídas. (a) Alguém confirma a P-2 no gate de design e constrói-se a Opção F. (b) O dono do middleware ajusta o payload e a prova é refeita com a carga real do site, na QA ou no ambiente do middleware.

### FALHA 2 (média) — CA-04 só foi exercitado de forma parcial
- O teste com carga simulando o payload do site pelo middleware real não pôde ser feito, porque o middleware está fora do alcance da esteira. Só foi simulado o comportamento da plataforma, pela criação direta de Lead.

## Pré-checagem de componentes (QA)
| Verificação | Obtido |
|---|---|
| Custom Permission `Lead_Origem%` | 0 registros |
| Permission Set `PS_Integracao_Lead%` | 0 registros |
| Flow `%OrigemSite%` | a consulta em FlowDefinitionView não retornou resultado (erro do `sf`). Sem prova nesta rodada, mas o build declara que não há Flow |
| Lead `TESTE SOMOSAGILITY-21%` antes dos testes | 0 |

Coerente com o build, nada da demanda está na QA e nada consta como faltando.

## Casos executados (comportamento da plataforma, conforme `04-plano-build.md`)
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1 | `sf data create record -s Lead` com `LeadSource='Web Site Agility Networks'` (Lead `TESTE SOMOSAGILITY-21 A`), seguido de query | Valor mantido | `Web Site Agility Networks` | passou (só prova a plataforma; não é correção) |
| 2 | Criar Lead sem `LeadSource` (`TESTE SOMOSAGILITY-21 B`) | H1: assume o default | `Prospecção - Gerente de Contas` | H1 confirmada na plataforma; é o comportamento a corrigir |
| 3 | Criar Lead com `LeadSource='Web Site Agility'` (`TESTE SOMOSAGILITY-21 C`) | H2: valor solto aceito | `Web Site Agility`, fora da lista de opções ativas | H2 confirmada; é o comportamento a corrigir |
| CA-01 | Lead vindo do site com origem correta pela correção | Origem = `Web Site Agility Networks` | Sem correção construída | **não executado / reprovado** |
| CA-02 | Outros canais inalterados | Sem regra afetando outros canais | Sem componente, nada a exercitar. O risco da org (24 automações no mesmo evento) não foi exercitado | não executado |
| CA-03 | Valor do site sobrepõe o default | Sobrescrita | Sem componente | não executado |
| CA-04 | Carga simulando o payload real do site | Lead com origem correta | Só simulação direta pela plataforma (casos 1 a 3) | parcial |

Outros fatos confirmados via `sf` na QA: o picklist de `LeadSource` não é restrito. Os valores ativos incluem `Web Site Agility Networks` e `Web Site Agility – E-mail`. O default é `Prospecção - Gerente de Contas`. Não existe a opção "Web Site Agility" sem sufixo.

## O que pode ter saído da org
Criei 3 Leads sintéticos (`TESTE SOMOSAGILITY-21 A/B/C`) e os apaguei em seguida. A contagem final de `TESTE SOMOSAGILITY-21%` é 0. As automações de Lead da org podem ter rodado na criação (a QA tem dado real copiado). Nenhuma chamada externa foi observada nem registrada. Nenhum registro existente foi lido individualmente ou alterado. Só houve contagens agregadas.

## Sem prova
Todos os critérios de aceite sobre a correção, porque ela não está no Salesforce. As dúvidas P-1 a P-4 continuam abertas.
