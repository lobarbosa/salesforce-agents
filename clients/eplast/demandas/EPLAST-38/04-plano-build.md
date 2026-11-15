**Resultado do build:** concluído

# EPLAST-38 · Plano de build: roteamento regional do lead

**Org conferida:** `sbx-eplast-dev` (projetos@konectabr.com.eplast2.qa, Org ID 00DHa000006vfMLMAY), única conectada, via `sf org list`. Branch `feature/EPLAST-38`. Rota: opção (a) do design, configuração sobre o que já existe. Nada foi implantado na org: o build só versiona (retrieve) e cria fixtures. Nenhum componente novo de metadata, nenhuma versão nova de Flow, classe ou agente. `SFAgent2` e Marketing Cloud não tocados.

## Componentes registrados

| Componente | Tipo | Ação | Descrição / caminho |
|---|---|---|---|
| `LeadAssignmentService`, `LeadAssignmentServiceTest` | ApexClass | Versionado por retrieve, sem alteração | `force-app/main/default/classes/` (grupo 1) |
| `Lead_DistribuicaoAutomaticaViaApi` | CustomPermission | Versionado | `customPermissions/` (grupo 1) |
| `PS_Integracao_DistribuicaoLead` | PermissionSet | Versionado | `permissionsets/` (grupo 1) |
| `Leads_SP`, `_RJ`, `_MG`, `_ES`, `_Sul`, `_CO`, `_NO_NE`, `_Triagem` | Queue | Versionado; o retrieve não traz `queueMembers` nem usuário (conferido) | `queues/` (grupo 2) |
| `Lead` (regra `Distribuicao_Regional_Leads`, ativa, 8 entradas, sem `template`) | AssignmentRules | Versionado; o arquivo do repositório era um stub vazio e passou a refletir a dev | `assignmentRules/Lead.assignmentRules-meta.xml` (grupo 2) |
| `Lead-Lead Layout` | Layout | Versionado; diferença única: `runAssignmentRulesDefault` false para true, igual à dev | `layouts/` (grupo 2) |
| `Lead_AfterInsert_AplicaRegraAtribuicao` | Flow (v1 ativa) | Versionado, sem versão nova | `flows/` (grupo 2) |
| `manifest/EPLAST-38-package.xml` | Manifesto | Criado, API 68.0, dois grupos | `manifest/` |
| `fixtures/lead_roteamento_regional.apex`, `fixtures/README.md` | Fixtures | Criados (seção 6 do design) | `fixtures/` |

## Fixture: prova de que funciona
Modo `REGRA` rodado na dev: 30 de 30 inseridos, sem falha de validation rule. Distribuição por fila conforme a tabela 3.1 (SP e "sp" em Leads SP: 2; Sul: 3; Centro-Oeste: 5; Norte e Nordeste: 15; Triagem, com vazio e "São Paulo": 2; RJ, MG e ES: 1 cada). Limpeza executada: 0 registros restantes com o prefixo. Só contagens agregadas foram consultadas.

## Validation rules de telefone
`Celular` e `Telefone` estão ativas (mensagens `(xx)xxxxxxxx`). O design manda a fixture deixar telefone vazio, e isso funcionou. **Nenhuma validation rule foi alterada.** Valores de picklist lidos da org: `Status = 'Aberto - Não contatado'`, `LeadSource = 'Evento'`, `Sector__c = 'Alimentos'`. `PriorityScore__c` relida: setor 30 + origem 30 + (Contatado ou convertido) 40, coerente com 60 e 100 do CA-05.

## Versões e ativação
Nenhuma versão nova criada e nenhuma ativação: o Flow v1 segue ativo, a classe segue como está.

## Condição para o deploy em QA (R1 e R2 do design)
- **Grupo 1** (classes, custom permission, permission set): pode ir.
- **Grupo 2** (filas, regra de atribuição, layout, Flow): só se ausente ou idêntico na `sbx-eplast-qa`. Antes do deploy, retrieve só-leitura desses tipos na QA e comparação; o que diverge ou tem membros sai do deploy e é registrado em `05-deploy-qa.md`. Implantar `AssignmentRules:Lead` troca a regra ativa da QAS e o layout a substitui. O Flow só entra se não existir lá.

## Para o verificador
Provar CA-01 a CA-07 na dev com a fixture (modos REGRA, SIMPLES com o PS atribuído ao usuário de execução e removido ao fim, MASSA_*, MANTER_DONO); reexecutar `LeadAssignmentServiceTest` e confirmar cobertura de pelo menos 85%. Usuário de teste da regra 6 (`005bJ00000hBJmYQAW`) está inativo na dev e não foi alterado; CA-04 usa o usuário de execução.

## Passos do operador (fora do build)
Incluir membros nas 8 filas em Setup > Filas (Triagem com pelo menos um); atribuir `PS_Integracao_DistribuicaoLead` às integrações que criam Lead.

## Premissas assumidas
PA-07 a PA-10 do design seguidas sem mudança (dono sobrescrito pela regra quando a caixa está marcada; membros por passo do operador; UF fora do padrão vai à Triagem; roteamento só na criação).
