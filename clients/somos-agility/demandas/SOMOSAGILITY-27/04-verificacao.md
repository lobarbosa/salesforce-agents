**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# Verificação - SOMOSAGILITY-27

Org conferida com `sf org list`: só `sbx-somos-agility-dev` (sandbox, Connected). Todos os comandos usaram `--target-org sbx-somos-agility-dev`. QA e produção não foram tocadas.

## Resumo
O que o build entregou (o permission set `PS_Relatorios_ExtrairSalvar`) existe na dev com exatamente as permissões do design, e nada além disso. O efeito para o usuário (A1 salvar, A2 exportar, A6 uso pela colaboradora) **não foi exercitado**: depende do perfil e da pasta da colaboradora, de uma atribuição e de acesso de pasta que são passos humanos, e os critérios foram escritos para a QA. Por isso `inconclusiva`, não `reprovada`: nenhum caso executado falhou.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Design seção 2 / A3 | `sf data query` em `PermissionSet` onde `Name='PS_Relatorios_ExtrairSalvar'` | Existe, com `RunReports`, `CreateCustomizeReports` e `ExportReport` ligadas | 1 registro; as três = true | passou |
| C2 | A3 (sem ampliação) | Mesma consulta, outras permissões de sistema | `ManageReportsInPubFolders`, `CreateReportFolders`, `ViewAllData`, `ModifyAllData` e `CreateReportInLightning` desligadas | Todas false | passou |
| C3 | A3 / design (sem objeto, sem campo) | `COUNT` em `ObjectPermissions` e `FieldPermissions` do permission set | 0 e 0 | 0 e 0 | passou |
| C4 | Design (descrição obrigatória, DoD) | Leitura do campo `Description` na consulta C1 | Descrição preenchida | "Executar, criar/salvar e exportar relatorios. Nao inclui gestao de pastas publicas. SOMOSAGILITY-27." | passou |
| C5 | A3 ("nenhum usuário ganha acesso novo") | `COUNT` em `PermissionSetAssignment` do permission set | 0 (atribuição é passo humano) | 0 | passou |
| C6 | A4 (permission set reutilizável, sem exceção no perfil) | Leitura do XML em `force-app/main/default/permissionsets/` e do design seção 2 | Permissão em permission set, sem alteração de perfil | Só o permission set foi criado; o plano de build diz que nenhum perfil foi alterado. Não comparei perfis antes e depois | passou (parcial: perfis não comparados) |
| C7 | A1 - salvar relatório | Não executado | Salvar sem erro de privilégio e relatório na pasta | - | não executado |
| C8 | A2 - exportar com contagem de linhas igual à tela | Não executado | Arquivo gerado, linhas batem com a tela | - | não executado |
| C9 | A6 - roteiro concluído pela colaboradora | Não executado | Passos OK | - | não executado |
| C10 | A5 - "criar modelo" | Bloqueado pela pergunta 1 da análise; não construído | Fora do escopo | - | não executado |

## Alterações feitas na org
Nenhuma. Nenhum dado de teste criado, nenhum DML, nenhuma atribuição ao usuário de execução, nenhum Apex anônimo. Nada a desfazer. Nenhum dado pessoal consultado (só metadata e contagens).

## O que pode ter saído da org
Nada. A demanda não tem automação, integração nem callout.

## O que ficou sem prova e o que uma pessoa precisa fazer
1. **A1 e A2 (efeito real).** Não consegui provar que a colaboradora passa a salvar e exportar. Falta: confirmar o perfil e a licença dela e a mensagem de erro exata (R1 do design). Se o perfil já tem as três permissões, a causa é outra e o design volta. Depois, atribuir o permission set a ela (ou a um usuário de teste com o mesmo perfil na QA), definir a pasta (pergunta 7) com acesso Editor, e rodar salvar e exportar, comparando as linhas do arquivo com as da tela.
2. **R4 do design.** Se o A1 falhar mesmo com o permission set, avaliar `CreateReportInLightning`, que ficou de fora de propósito e está false.
3. **A3 (outros usuários).** C5 prova que hoje ninguém tem o permission set na dev. A verificação de que nenhum perfil ou usuário além da colaboradora ganhou acesso depende da atribuição real na QA.
4. **Reverter a permissão** já adicionada pela equipe ao perfil individual (pergunta 3), se ela existir. É passo humano.
5. **A6** depende da colaboradora ou do consultor executando o roteiro na QA.
