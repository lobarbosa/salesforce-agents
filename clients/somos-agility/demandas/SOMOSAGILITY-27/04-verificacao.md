**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# Verificação do build - SOMOSAGILITY-27

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected), pelo alias. Usuário de execução: o da sessão de build (identificador omitido). Nenhuma outra org tocada. Nenhum dado criado, nenhum DML, nenhuma alteração no usuário de execução (nada a reverter).

Construído (04-plano-build.md): só o permission set `PS_Relatorios_ExtrairSalvar`. Sem Flow, sem Apex.

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | A3 | SOQL em PermissionSet por Name, com campos de sistema | `RunReports`, `CreateCustomizeReports`, `ExportReport` = true; sem gestão de dashboards | As três = true; `PermissionsCreateCustomizeDashboards` = false; descrição preenchida | passou |
| V2 | A3 | COUNT em ObjectPermissions e FieldPermissions do PS | 0 (sem acesso a objeto ou campo) | 0 e 0 | passou |
| V3 | A3 | Consulta da licença do PS | Sem licença | `License.Name` vazio | passou |
| V4 | A3 | COUNT em PermissionSetAssignment do PS | 0 (ninguém ganha acesso novo) | 0 | passou |
| V5 | A3 | `git diff --name-only main...HEAD` fora de `demandas/`, filtrando por `clients/somos-agility` | Só o PS novo alterado no projeto do cliente | Único arquivo do cliente: `force-app/.../PS_Relatorios_ExtrairSalvar.permissionset-meta.xml`. Nenhum perfil, Flow, Apex ou outro PS | passou |
| V6 | A1 | Não executado | Usuário de teste com o perfil da colaboradora, sem as permissões, salva relatório sem erro | Ver abaixo | não executado |
| V7 | A2 | Não executado | Mesmo usuário exporta relatório; linhas do arquivo batem com a tela | Ver abaixo | não executado |
| V8 | A4 | Não aplicável a esta verificação (revisão do arquiteto) | Permissão em PS reutilizável por função | Está em PS por função, confirmado em V1 a V5; a decisão é do arquiteto | não executado |

Observação sobre A3: a primeira parte (diferença de permissão de relatório limitada ao previsto) foi provada pela metadata e pelo diff. O inventário "antes e depois" de perfis não foi montado por consulta; a prova é que nenhum perfil mudou no repositório e o PS não tem atribuição.

## O que ficou sem prova (A1 e A2)

- Prova de A1 e A2 exige um usuário de teste sem as permissões, com o perfil da colaboradora. Eu só posso alterar o meu próprio usuário de execução, e ele não representa a colaboradora. Se eu criasse o relatório com ele, o resultado não provaria nada sobre o permission set (o perfil dele provavelmente já tem as permissões). Por isso não executei.
- Criar usuário de teste ou atribuir o PS a outro usuário está fora do que a esteira autoriza ao verificador.
- Falta também pasta de relatório com acesso Editor (pergunta 7 da análise, sem resposta).
- Isto bate com a FALHA 1 da rodada 1 de QA: não é defeito de metadata.

O que uma pessoa precisa fazer: indicar ou criar um usuário de teste com o perfil da colaboradora (na dev ou na QA), atribuir `PS_Relatorios_ExtrairSalvar`, dar acesso Editor a uma pasta de relatório e executar o `05-roteiro-cliente.md` (salvar e exportar). Se A1 falhar com o PS atribuído, entra `CreateReportInLightning` (R4 do design).

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma automação disparada, nenhuma chamada externa.

## Limpeza
Sem dados de teste. Sem job agendado. Usuário de execução inalterado.
