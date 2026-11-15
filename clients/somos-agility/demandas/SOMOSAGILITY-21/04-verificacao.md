**Verificação:** inconclusiva
**Org de teste:** sbx-somos-agility-dev

## Org e escopo
- `sf org list`: única org conectada é `sbx-somos-agility-dev` (Sandbox, Connected). Todos os comandos usaram `--target-org`/`-o` com esse alias.
- Nenhum dado de teste foi criado, nenhum DML nem Apex anônimo executado. Nenhum dado real lido.

## Discrepância com o preflight
O preflight dizia "nada a conferir: sem componentes no repositório". Isso está correto, e não conflita com o build: `04-plano-build.md` declara que **nada foi criado em `force-app`** (a Opção F, rede de segurança, depende da P-2, não confirmada; a Opção A é correção de payload no middleware, fora do Salesforce). Confirmado:
- `clients/somos-agility/force-app` só contém `main` e o último commit que o tocou é o baseline/limpeza do recon (nada da demanda).
- Na dev, consulta retornou 0 registros para: Flow `%OrigemSite%` (FlowDefinition), CustomPermission `Lead_Origem%`, PermissionSet `PS_Integracao_Lead%`.
- `Lead` com Company `TESTE SOMOSAGILITY-21%`: 0.
- Observação: `04-plano-build.md` não traz a linha `**Resultado do build:** concluido|bloqueado` exigida pelo fluxo.

## Critérios de aceite
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | CA-01 Lead do site recebe LeadSource correto | Consulta de metadata na dev por componente da demanda | Haver automação a exercitar | Não existe componente; a correção é no middleware externo | não executado |
| 2 | CA-02 Outros canais inalterados | Idem | Regra restrita ao canal do site | Sem regra construída; nada a testar. Fragilidade da org (24 automações no mesmo evento de Lead/Oportunidade) não foi exercitada | não executado |
| 3 | CA-03 Valor do site sobrepõe default | Idem | Sobrescrita do default | Sem componente | não executado |
| 4 | CA-04 Teste com carga simulando payload | Não aplicável na dev sem componente; depende do middleware e da QA | Lead de teste com LeadSource correto | Não executado | não executado |

## O que ficou sem prova
Todos os critérios. A correção (Opção A) acontece fora do Salesforce e a Opção F não foi construída.
Para provar: (1) TI Agility confirma P-2 e, se houver usuário exclusivo, constrói-se a Opção F e reverifica-se; ou (2) o dono do middleware ajusta o payload para `LeadSource = "Web Site Agility Networks"` (API name) e alguém testa na QA/ambiente do middleware com carga sintética.

## Riscos e incertezas
- P-1 (valor-alvo), P-2 (usuário exclusivo), P-3 (causa-raiz em produção) e P-4 (dono do ajuste) continuam em aberto, segundo o plano de build.
- Não confirmei via `sf` o picklist de `LeadSource` nem o default da org nesta rodada; as afirmações vêm de `03-design.md`/`04-plano-build.md`.
- Sem dados de teste criados: nada a limpar nem a desfazer; nenhuma saída da org.
