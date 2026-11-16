**Resultado do build:** concluído

# Plano de build - SOMOSAGILITY-27

- **Branch:** `feature/SOMOSAGILITY-27`
- **Org:** `sbx-somos-agility-dev` (sandbox, unica conectada em `sf org list`)
- **Escopo:** parte de relatorio (A1-A4, A6) do `03-design.md`, secao 2. A5 ("criar modelo") segue bloqueado pela pergunta 1 da analise e nao foi construido, conforme design secao 6.
- **Gate de design:** aprovado em `gates.md` (2026-11-16).

## Componentes criados

| Tipo | API name | Descricao |
|---|---|---|
| PermissionSet | `PS_Relatorios_ExtrairSalvar` | Sem licenca. Permissoes de sistema: `RunReports`, `CreateCustomizeReports`, `ExportReport`. Sem permissao de objeto, campo, app ou pasta. Descricao preenchida. Arquivo: `force-app/main/default/permissionsets/PS_Relatorios_ExtrairSalvar.permissionset-meta.xml` |

Confirmado via `sf` que o nome nao existia na dev antes do deploy. Deploy na dev: Succeeded (Deploy ID 0AfHa00000EIh4rKAD).

## Nao alterado
Nenhum perfil, Flow, Apex ou permission set existente. `CreateReportInLightning` ficou de fora de proposito (R4 do design; so entra se o teste A1 falhar).
Assessment: sem automacao, sem Apex e sem objeto de negocio tocado; Oportunidade nao envolvida.

## Versoes e ativacao
Nao se aplica (sem Flow, agente ou classe). Permission set nao exige ativacao.

## Pendencias humanas (nao sao metadata; vao ao `06-entrega.md`)
1. Atribuir o permission set a colaboradora (dado, passo humano; nenhuma atribuicao feita pelo agente).
2. Dar acesso Editor na pasta de relatorio onde ela salva (pasta ainda nao definida, pergunta 7).
3. Reverter a permissao ja adicionada pela equipe, se foi no perfil individual (pergunta 3).
4. R1: confirmar perfil/erro exato da colaboradora; se o perfil ja tem as permissoes, a causa e outra e o design volta.

## Correções da rodada 1
Fonte: `05-testes-rodada-1.md` (reprovado so por falta de evidencia de A1/A2; T1-T6 passaram, o permission set esta correto na QA).

| Falha | Tratamento |
|---|---|
| FALHA 1 (critica) - A1 e A2 nao exercitados por falta de usuario de teste na QA sem as permissoes, e de pasta com acesso Editor | **Nao corrigivel no build.** O que falta nao e metadata: e usuario de teste com o perfil da colaboradora (dado, `PermissionSetAssignment` e criacao de usuario, passo humano, guardrail #2; builder nao toca a QA) e pasta de relatorio (pergunta 7 da analise, sem resposta). Nenhuma mudanca no permission set: nao ha defeito a corrigir e `CreateReportInLightning` so entra se A1 falhar de fato (R4). |

Encaminhamento ao humano: indicar/criar na QA um usuario de teste com o perfil da colaboradora e responder as perguntas 3, 5 e 7 da analise, ou executar o `05-roteiro-cliente.md` a mao na homologacao. Metadata do build inalterado nesta rodada.
