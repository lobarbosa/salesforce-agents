**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# Testes — SOMOSAGILITY-27

Org conferida com `sf org list`: só `sbx-somos-agility-qa` (sandbox, Connected). Todos os comandos usaram `--target-org sbx-somos-agility-qa`. Deploy da esteira `0AfHa00000EIu25KAD` (Succeeded) com um componente: o permission set `PS_Relatorios_ExtrairSalvar`.

## Falhas

### FALHA 1 (crítica) — A1 (salvar relatório) e A2 (exportar) não puderam ser exercitados
- **Reproduzir:** tentar provar que um usuário SEM as permissões passa a salvar/exportar relatório depois de receber o permission set.
- **Obtido:** não executado. O único usuário que posso usar (o de execução do job) tem perfil que já traz `CreateCustomizeReports=true` e `ExportReport=true`. Atribuir o permission set a ele não distingue "antes" de "depois", então o teste não provaria nada. Não há na QA usuário de teste indicado no `CLAUDE.md` do cliente, e a colaboradora, o perfil/licença dela e a pasta de relatórios (perguntas 3, 5 e 7 da análise) seguem sem resposta.
- **Esperado:** A1 e A2 executados com evidência (relatório salvo na pasta; arquivo exportado com linhas iguais às da tela). Critério de aceite principal sem execução reprova a rodada.
- **Causa provável / o que falta:** usuário de teste em QA com o perfil da colaboradora, sem as três permissões, mais pasta com acesso Editor. Com isso o roteiro `05-roteiro-cliente.md` cobre A1, A2 e A6.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Componente do deploy existe na QA | `sf data query` em `PermissionSet` com `Name='PS_Relatorios_ExtrairSalvar'` | 1 registro | 1 registro | passou |
| T2 | A3/design: permissões mínimas | Mesma consulta, campos `Permissions*` | `RunReports`, `CreateCustomizeReports`, `ExportReport` = true | As três = true | passou |
| T3 | A3: sem ampliação | Mesma consulta | `ManageReportsInPubFolders`, `CreateReportFolders`, `ViewAllData`, `ModifyAllData`, `CreateReportInLightning` = false | Todas false | passou |
| T4 | A3: sem objeto/campo | `COUNT()` em `ObjectPermissions` e `FieldPermissions` do PS | 0 e 0 | 0 e 0 | passou |
| T5 | A3: ninguém ganha acesso | `COUNT()` em `PermissionSetAssignment` do PS | 0 | 0 | passou |
| T6 | A4: permission set reutilizável, sem perfil alterado | Leitura do XML e do `05-deploy-qa.md` | Só permission set no deploy | Um único componente (PermissionSet); descrição preenchida | passou |
| T7 | A1 salvar relatório | Não executado (ver FALHA 1) | Salva sem erro, na pasta | — | não executado |
| T8 | A2 exportar, linhas = tela | Não executado (ver FALHA 1) | Arquivo gerado, contagem bate | — | não executado |
| T9 | A6 uso pela colaboradora | Não executado | Roteiro OK | — | não executado |
| T10 | A5 criar modelo | Bloqueado pela pergunta 1 da análise; fora do escopo construído | — | — | não executado |

## Alterações feitas na org
Nenhuma. Nenhuma atribuição de permission set a mim, nenhum dado criado, nenhum Apex anônimo, nenhum screenshot. Nada a desfazer. Nenhum dado pessoal consultado (só metadata e contagens; a consulta ao próprio usuário de execução retornou apenas flags de perfil).

## O que pode ter saído da org
Nada. Sem automação, integração ou callout.

## Observação
A configuração (permission set) está correta na QA; o veredito é reprovado só porque o efeito para o usuário (A1/A2) não tem evidência. Se o time preferir, o roteiro do cliente pode ser executado à mão na homologação com um usuário de teste sem as permissões.
