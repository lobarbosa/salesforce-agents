**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# Testes — SOMOSAGILITY-27 (rodada 2)

Org conferida com `sf org list`: só `sbx-somos-agility-qa` (sandbox, Connected). Todos os comandos usaram `--target-org sbx-somos-agility-qa`. Deploy da esteira `0AfHa00000EM6BZKA1` (Succeeded), um componente: o permission set `PS_Relatorios_ExtrairSalvar`. Não há Flow, agente nem modelo de prompt, então não houve ativação de versão.

## Retesta da falha da rodada 1
- **FALHA 1 (A1/A2 não exercitados): NÃO corrigida.** A rodada 2 tinha autorização (decisão de 2026-11-21 no `03-design.md`) para criar na QA um usuário sintético sem as permissões. Não foi possível criá-lo: ver FALHA 1 abaixo. O build não tem defeito conhecido; o impedimento é de licença da sandbox.

## Falhas

### FALHA 1 (crítica) — sem licença livre na QA para o usuário de teste sintético; A1 e A2 sem execução
- **Reproduzir:** `sf data query --target-org sbx-somos-agility-qa -q "SELECT Name,TotalLicenses,UsedLicenses FROM UserLicense WHERE TotalLicenses>0"`.
- **Obtido:** a licença `Salesforce` está em 30 de 30. É a licença que permite relatórios, e está cheia. As licenças com saldo são `Identity` (0/100), `Salesforce Integration` (0/5), `Chatter Free` (0/5000) e `Chatter External` (0/500). Nenhuma delas suporta Report Builder e exportação. `Salesforce Platform` tem 0 licenças. Perfil adequado existe (`Minimum Access - Salesforce`, sem `CreateCustomizeReports` nem `ExportReport`), mas pertence à licença cheia.
- **Esperado:** usuário sintético criado, teste "antes e depois" do permission set (A1, A2).
- **Conduta:** o design manda registrar e parar quando não há licença livre, sem desativar ninguém para liberar vaga. Nada foi criado nem alterado.
- **O que falta para a próxima rodada (decisão humana):** uma das opções: (a) liberar 1 licença `Salesforce` na QA (o responsável desativa um usuário que ele escolher); (b) indicar um usuário já existente na QA, sem as permissões, que possa ser usado como teste; (c) aceitar A1/A2 só pelo roteiro do cliente na homologação, com usuário que o cliente indicar. Também não há perfil de teste no `CLAUDE.md` do cliente.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Componente do deploy existe na QA | `sf data query` em `PermissionSet` com `Name='PS_Relatorios_ExtrairSalvar'` | 1 registro | 1 registro (`0PSHa000002Dk2HOAS`) | passou |
| T2 | A3: permissões mínimas | Leitura do XML implantado (`05-deploy-qa.md`, commit `23975b8c`) | `RunReports`, `CreateCustomizeReports`, `ExportReport` = true e mais nada | As três e nenhuma outra `userPermissions` | passou |
| T3 | A3: sem ampliação | Mesmo XML | Sem `ViewAllData`, `ModifyAllData`, gestão de pastas | Ausentes | passou |
| T4 | A3: ninguém ganha acesso | `SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name='PS_Relatorios_ExtrairSalvar'` | 0 | 0 | passou |
| T5 | A4: permission set reutilizável, perfil intacto | Leitura de `05-deploy-qa.md` | Só PermissionSet | Um único componente | passou |
| T6 | Pré-requisito do teste A1/A2: licença livre | Consulta a `UserLicense` | Licença com relatórios e saldo | `Salesforce` 30/30; as livres não suportam relatórios | falhou |
| T7 | A1 salvar relatório | Não executado (T6) | Salva sem erro | — | não executado |
| T8 | A2 exportar, linhas = tela | Não executado (T6) | Arquivo gerado, contagem bate | — | não executado |
| T9 | A6 uso pela colaboradora | Não executado; é da homologação | Roteiro OK | — | não executado |
| T10 | A5 criar modelo | Fora do escopo (pergunta 1 da análise) | — | — | não executado |

Sobre a evidência por permissão efetiva prevista no design (item 4): ela exige o usuário sintético "antes e depois", que não existe. Usar o usuário de execução não distingue os cenários (o perfil dele já tem as permissões, rodada 1). Por isso não foi aceita como execução de A1/A2.

## Alterações feitas na org
Nenhuma. Nenhum usuário criado, nenhuma atribuição de permission set, nenhum dado, pasta ou relatório de teste, nenhum Apex anônimo, nenhum screenshot, nenhuma sessão de navegador. Nada a desfazer. Só metadata e contagens consultadas; nenhum dado pessoal.

## O que pode ter saído da org
Nada. Sem automação, integração ou callout.
