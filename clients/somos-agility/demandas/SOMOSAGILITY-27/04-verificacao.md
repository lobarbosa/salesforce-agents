**Verificação:** inconclusiva
**Org de teste:** sbx-somos-agility-dev

# Verificação do build — SOMOSAGILITY-27

- Org confirmada com `sf org list`: `sbx-somos-agility-dev` (sandbox, Connected). Todos os comandos usaram `--target-org`.
- Build verificado: permission set `PS_Relatorios_ExtrairSalvar` (branch `feature/SOMOSAGILITY-27`, commit 71da1a14). Sem Flow nem Apex. `00-preflight.md`: sem bloqueios e sem outra demanda nos mesmos componentes.
- Só metadata e contagens agregadas. Nenhum dado de cliente lido. Nenhum registro criado, nenhum dado alterado, nenhuma atribuição feita. Nada a desfazer.

## Resultado em uma frase
O permission set existe na dev com exatamente as 3 permissões declaradas e nada além (A3 e A4 verificados). A1 e A2 exigem um usuário sem as permissões, e a dev não oferece um sem consumir a última licença livre, o que está fora do que posso decidir. Por isso A1 e A2 ficam sem prova de execução.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Build (existência e permissões) | `sf data query` em `PermissionSet` com `Name='PS_Relatorios_ExtrairSalvar'`, campos `Permissions*` específicos | Existe; `RunReports`, `CreateCustomizeReports` e `ExportReport` = true | 1 registro. As três = true. Descrição preenchida ("...Não inclui gestão de pastas públicas. SOMOSAGILITY-27.") | passou |
| V2 | A3 (sem ampliação) | Mesma consulta com `CreateReportInLightning`, `ViewAllData`, `ModifyAllData`, `ApiEnabled`, `ManageReportsInPubFolders`, `CreateReportFolders`, `ViewSetup`, `ManageUsers`, `DataExport` | Todas false | Todas false | passou |
| V3 | A3 (sem acesso a dados) | `COUNT` em `ObjectPermissions` e em `FieldPermissions` com `Parent.Name` = o permission set | 0 e 0 | 0 e 0 | passou |
| V4 | A3 (ninguém ganhou acesso) | `COUNT` em `PermissionSetAssignment` do permission set | 0 | 0 | passou |
| V5 | A4 (forma da correção) | Consulta de `LicenseId` e contagem de PS com prefixo `PS_Relatorios` | Permission set reutilizável, sem licença, sem exceção de perfil | `LicenseId` = null. 1 permission set com esse prefixo. O build não alterou perfil (`04-plano-build.md`). Não fiz diff de perfis contra o estado anterior | passou, com a ressalva do diff de perfis |
| V6 | A1 (salvar relatório) | Não executado. Ver "O que ficou sem prova" | Usuário sem as permissões, com o permission set, salva relatório em pasta sem erro de privilégio | Sem execução | não executado |
| V7 | A2 (exportar relatório) | Não executado. Ver "O que ficou sem prova" | Exporta sem erro, com linhas do arquivo = linhas da tela | Sem execução | não executado |
| V8 | A5 | Fora do escopo (bloqueado, design seção 6) | n/a | n/a | não executado |
| V9 | A6 (colaboradora) | Etapa humana na homologação | n/a | n/a | não executado |

## O que ficou sem prova (A1 e A2)

Por que não executei:
- O usuário de execução (`<usuario-de-teste-omitido>`) já tem `CreateCustomizeReports` e `ExportReport` pelo perfil, como na QA. Se ele salvasse e exportasse com o permission set, não provaria nada sobre o permission set.
- A dev tem um único perfil na licença `Salesforce` sem as duas permissões: `Minimum Access - Salesforce`. Os outros perfis sem as permissões são de licenças que não suportam relatório (Community, Guest, Chatter, Integration, Identity). Não achei na dev um usuário existente que sirva sem eu alterar usuário real, e não toquei em nenhum usuário que eu não criei.
- Licença `Salesforce` na dev: 30 total, 29 em uso, 1 livre. Criar um usuário sintético consumiria a última licença da dev. A autorização de usuário sintético dada em 2026-11-21 vale para a QA, só para o `qa` (`03-design.md`, última seção). Não a estendi para a dev por conta própria.
- A licença `Salesforce` na QA está em 30/30 (`05-testes-rodada-2.md`), então o mesmo teste também não rodou lá.
- Mesmo com um usuário na dev, o teste de tela (Report Builder, exportação, contagem de linhas) depende de pasta de relatório com acesso Editor. Essa pasta não está definida (pergunta 7 da análise).

O que uma pessoa precisa fazer para provar, uma das opções:
1. Autorizar na dev um usuário sintético `TESTE SOMOSAGILITY-27` no perfil `Minimum Access - Salesforce`, usando a última licença livre. A evidência seria a permissão efetiva (perfil mais permission set) e, se possível, o teste em tela. Ao final, o usuário é desativado.
2. Liberar 1 licença `Salesforce` na QA, ou indicar um usuário existente sem as permissões em dev ou QA.
3. Aceitar A1 e A2 pelo `05-roteiro-cliente.md` na homologação com a colaboradora, junto com as perguntas 3, 5 e 7 da análise. O risco R1 do design continua aberto: se o perfil dela já tem as permissões, o permission set não resolve e a causa é outra.

## O que pode ter saído da org
Nada. Nenhum registro de teste criado, nenhuma automação disparada, nenhuma chamada externa.

## Estado final
Nada criado. Nada atribuído. Nenhuma alteração no usuário de execução. Nenhum job agendado.
