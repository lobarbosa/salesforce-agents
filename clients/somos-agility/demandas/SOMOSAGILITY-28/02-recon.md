# Recon SOMOSAGILITY-28 — acesso ao objeto "Solicitação de Treinamento"

**Data da coleta:** 2026-11-16
**Org:** `sbx-somos-agility-dev` (sandbox, Org ID 00DHa0000070wxfMAA, status Connected em `sf org list`). Só leitura. Retrieves em `/tmp/recon` (projeto DX descartável), nada em `force-app/`.
**Escopo:** só metadata e contagens agregadas. Nenhum registro consultado.

## 1. O que já cobre o pedido

| Achado | Evidência (comando) |
|---|---|
| Candidato mais provável ao objeto do pedido: `JOB_de_Solicitacao_de_Treinamentos__c`, label "JOB de Solicitação de Treinamentos", custom, createable, 1 record type (`Mestre`, ativo), prefixo de chave `a1b`. **Não é igual ao nome do card; a correspondência é por nome, não confirmada pelo solicitante (ver "Não consegui confirmar").** | `sf sobject list --sobject custom` filtrado por "trein/solic"; `sf sobject describe --sobject JOB_de_Solicitacao_de_Treinamentos__c --json` |
| Outros objetos custom com "Treinamento" no nome (podem ser o objeto do pedido): `Previsao_de_Gastos_do_Treinamento__c`, `Previsao_Gastos_Treinamento_Realizado__c`, `Treinamento_Interno_SUATC__c`, `Treinamento_Publico_SUATC__c` (a API name `__c` dos dois últimos não foi checada, só o DeveloperName). Não foram analisados. | `sf data query --use-tooling-api -q "SELECT DeveloperName, NamespacePrefix FROM CustomObject WHERE DeveloperName LIKE '%Trein%'"` |
| Sem namespace de pacote gerenciado nos 5 objetos acima. | mesma query (NamespacePrefix = null) |
| Permission sets não ligados a perfil que já dão acesso ao objeto: `jobsAprovacao` (R/C/E/D + ViewAll; 8 atribuições), `Gastos_treinamento` (só Read; 10 atribuições). Os sets `Read_Only_Setup_Interface_Access` e `Admin_Access_View_Only` também têm Read + ViewAll. | `sf data query -q "SELECT Parent.Name, Parent.IsOwnedByProfile, Parent.Profile.Name, PermissionsRead, ... FROM ObjectPermissions WHERE SobjectType='JOB_de_Solicitacao_de_Treinamentos__c'"`; `SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name='<nome>'` |
| Aba (CustomTab) com "Trein" no DeveloperName: 0 resultados. A aba do objeto não foi localizada por essa consulta. | `sf data query --use-tooling-api -q "SELECT DeveloperName FROM CustomTab WHERE DeveloperName LIKE '%Trein%'"` |
| Relatórios, painéis e agente Agentforce: não pesquisados nesta coleta. | n/a |

## 2. O que será tocado (objeto candidato)

| Item | Valor | Evidência |
|---|---|---|
| API name | `JOB_de_Solicitacao_de_Treinamentos__c` | describe |
| OWD interno / externo | Private / Private | `SELECT InternalSharingModel, ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName='JOB_de_Solicitacao_de_Treinamentos__c'` |
| Campos | 44 no total; 32 custom, incluindo 6 picklists, 4 lookups de aluno (`Nome_do_Aluno_1..4__c`, tipo reference), vários currency (`Valor_Total_*`), `Data__c`, `Nome_completo_do_solicitante__c`. Descrição dos campos não conferida. | describe (tipos); retrieve `CustomObject` em `/tmp/recon/obj` |
| Regras de compartilhamento (criteria/owner) | 3, todas Read: `Coordenador_de_DC`, `Coordenador_de_EA`, `Coordenador_de_SEG` | retrieve `SharingRules:JOB_de_Solicitacao_de_Treinamentos__c` |
| List views | `My_Job_s`, `Todos_os_Jobs` | retrieve `CustomObject` |

## 3. Automação concorrente no objeto candidato

| Tipo | Resultado | Evidência |
|---|---|---|
| ApexTrigger | 0 | `SELECT Name, Status FROM ApexTrigger WHERE TableEnumOrId='JOB_de_Solicitacao_de_Treinamentos__c'` (tooling) |
| Validation rules | 0 | `SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='JOB_de_Solicitacao_de_Treinamentos__c'` (tooling) |
| Flows / Process Builders | 0 referências ao objeto em 335 arquivos de Flow (todas as versões baixadas) | `sf project retrieve start --metadata Flow --output-dir /tmp/recon/out`; `grep -rl "JOB_de_Solicitacao_de_Treinamentos" /tmp/recon/out` |
| Workflow rules | 0 (retrieve devolveu "cannot be found") | `sf project retrieve start -m WorkflowRule:JOB_de_Solicitacao_de_Treinamentos__c` |
| Processos de aprovação | 14 versões; **2 ativas**: `Aprovacao_do_JOB_de_Treinamentos_v7` (2 critérios de entrada) e `JobSTGeral_v2` (2 critérios de entrada). Essas aprovações disparam na submissão, não no acesso de leitura. | retrieve `ApprovalProcess`; leitura da tag `<active>` e contagem de `<entryCriteria>` por arquivo |
| Classes Apex que referenciam o objeto | **Não confirmado.** Body não é filtrável via SOQL; as 96 classes não-gerenciadas não foram baixadas. | `SELECT COUNT() FROM ApexClass WHERE NamespacePrefix=null` = 96 |

Conclusão parcial: nenhuma automação de gravação (trigger, flow, VR, workflow) incide no objeto. O risco de ordem de execução é baixo para uma correção só de permissão. Os riscos do assessment (31 automações em Oportunidade, 59 Process Builders ativos) não tocam este objeto, porque nenhum Flow o referencia.

## 4. Volume e dados de teste

| Objeto | Registros | Evidência |
|---|---|---|
| `JOB_de_Solicitacao_de_Treinamentos__c` | 0 | `SELECT COUNT() FROM JOB_de_Solicitacao_de_Treinamentos__c` |

A sandbox de dev não tem dado para testar visualização. O teste de leitura vai exigir criar registro de teste (sem dado pessoal). Com OWD Private, só enxerga o que o usuário cria ou o que tem ViewAll.

## 5. Permissões que alcançam o objeto candidato

Total de 35 entradas em ObjectPermissions (perfis, via permission set de perfil, mais permission sets avulsos).

| Grupo | Acesso | Evidência |
|---|---|---|
| Sem Create/Edit (só Read, ViewAll quase sempre): Professional Services, Analytics Cloud Integration User, Sales Insights Integration User, `Diretor Comercial` (Read sem ViewAll) | Read | `ObjectPermissions` (mesma query da seção 1) |
| R/C/E sem Delete: Contratos Agility, Sales Operations ADM, Renovações, PO DT, Marketing, Diretor DT, PMO, Diretor de Marketing, Diretor Financeiro, Gerente de Suporte DC/SEG/EA, Service Delivery, Service Manager, PO EA | R/C/E | idem |
| R/C/E/D: Financeiro Agility, adminPMO, Diretor de Projetos, Compras Financeiro, Sales Operations, Grupo Operações, Alta Gestão, Estagiário Comercial, Administração, Administração para Alta Gestão, Admin, Administrador do sistema | R/C/E/D; vários com ModifyAll | idem |

Os perfis sem nenhuma linha em ObjectPermissions não têm acesso ao objeto. Não foi calculada a lista completa de perfis ausentes.
Licença, perfil, permission sets e estado do usuário-alvo: **não verificados**, porque o colaborador não está identificado na demanda (ver abaixo).

## Causa do bloqueio (critério de aceite 4)

**Não determinada.** Sem identificar o usuário e o objeto, a causa não pode ser provada na dev. O que a org mostra:
- Com OWD Private e 35 entradas de permissão, o objeto é restrito: quem não tem perfil ou permission set da tabela acima não vê a aba nem os registros.
- Não há trigger, flow, VR nem workflow que explique bloqueio por automação.
- Os candidatos a causa que sobram são permissão de objeto ausente, aba fora do app/perfil, compartilhamento (Private + 3 regras só para coordenadores), licença ou usuário inativo.

## O que não consegui confirmar

1. **Qual é o objeto do pedido.** O card diz "Solicitação de Treinamento"; achei `JOB_de_Solicitacao_de_Treinamentos__c` por semelhança de nome. Há outros 4 candidatos com "Treinamento" (`Treinamento_Interno_SUATC`, `Treinamento_Publico_SUATC`, `Previsao_de_Gastos_do_Treinamento__c`, `Previsao_Gastos_Treinamento_Realizado__c`). O arquiteto precisa que o solicitante confirme (P4).
2. **Quem é o usuário-alvo** e seu perfil, permission sets, licença e estado ativo. A demanda não o identifica, e não há consulta agregada que o revele sem tocar dado pessoal (P5, P6).
3. **Em qual org o "acesso realizado" foi feito** (P1). Esta coleta é da dev e pode divergir de produção. Não consultei a QA, então a divergência dev x QA não foi medida.
4. **Visibilidade da aba** (perfil ou permission set; `CustomTab` não achou nada com "Trein") e se a aba está num app.
5. **Field-level security** nos campos do objeto, e record type `Mestre` por perfil. Não foi coletado.
6. **Classes Apex que referenciam o objeto.** Só confirmei ausência de trigger, flow, workflow e VR. As 96 classes não foram varridas.
7. **Critérios de entrada e aprovadores** dos 2 processos de aprovação ativos, e se usam grupo ou fila que dependa do acesso do usuário.
8. **Relatórios, painéis e agentes Agentforce** ligados ao objeto, e perfis/licenças dos 38 usuários do assessment (não medidos aqui).
9. **Os números do assessment** (31 automações em Oportunidade, 59 PB, 40% de cobertura, 20 perfis com 1 usuário, 261 VR e 91 flows desativados) não foram reconferidos, pois não tocam o objeto candidato.

## Complemento do arquiteto (2026-11-16, etapa de design)

| Achado | Evidência (comando) |
|---|---|
| A aba do objeto existe: CustomTab `JOB_de_Solicitacao_de_Treinamentos__c` (unmanaged, criada em 2015). A busca da seção 1 não achou porque filtrou o DeveloperName da tooling. | `sf org list metadata -m CustomTab` filtrado por "JOB/Trein" |
| Visibilidade da aba: 36 entradas em PermissionSetTabSetting (22 `DefaultOn`, 14 `DefaultOff`); quem não tem entrada fica com a aba oculta. | `SELECT Visibility, COUNT(Id) FROM PermissionSetTabSetting WHERE Name='JOB_de_Solicitacao_de_Treinamentos__c' GROUP BY Visibility` |
| Escopo dos permission sets existentes: `jobsAprovacao` dá R/C/E/D + ViewAll no JOB de Treinamentos **e** em `JOB_de_Solicita_o_de_Investimento__c`, com 31 FieldPermissions no objeto; `Gastos_treinamento` dá só Read no JOB (0 FieldPermissions nele) e R/C/E/D + ViewAll em `Previsao_de_Gastos_do_Treinamento__c` e `Previsao_Gastos_Treinamento_Realizado__c`. Licença de ambos: Salesforce. | `SELECT Parent.Name, SobjectType, Permissions* FROM ObjectPermissions WHERE Parent.Name IN (...)`; `SELECT Parent.Name, COUNT(Id) FROM FieldPermissions ... GROUP BY Parent.Name` |
| Nenhum PermissionSet `PS_Treinamento%` nem PermissionSetGroup com "Trein" existe. | `SELECT COUNT() FROM PermissionSet WHERE Name LIKE 'PS_Treinamento%'`; idem PermissionSetGroup |
| Label dos candidatos confirmados: nenhum objeto se chama exatamente "Solicitação de Treinamento"; o mais próximo é "JOB de Solicitação de Treinamentos". | `SELECT QualifiedApiName, Label, PluralLabel FROM EntityDefinition WHERE Label LIKE '%Treinamento%'` |
