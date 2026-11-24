**Veredito:** aprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes: SOMOSAGILITY-22 (QA, rodada 3)

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-qa` (Sandbox, Connected, orgId `00DHa000006WcTcMAK`). Todos os comandos com `--target-org` explícito. Deploy da esteira em `05-deploy-qa.md`: `0AfHa00000EN8pdKAD` (Succeeded, commit `eab52aca`). Não implantei nada.

## Base do veredito (exceção registrada)
As rodadas 1 e 2 reprovaram porque o envio real do Job para aprovação não é exercitável pelo agente (critérios de entrada comparam o "Criado por" com pessoas e grupos do cliente). Decisão do responsável de 2026-11-23, registrada em `03-design.md` e no card: o envio (enviar, aprovar, rejeitar, reenviar) é testado pelo financeiro na homologação, com usuário real, pelo roteiro `05-roteiro-cliente.md`. Esses casos ficam **não executados por exceção do responsável** e não reprovam a rodada. O pedido de 30/10 (obrigatoriedade de "Classificação gerencial" e "Denominação") está fora desta demanda.

Sem prova de execução (declarado, não arredondado): que o envio grava `Pendente` na prática, as transições para Aprovado e Rejeitado, o reenvio, o recall, e que o status de previsão de gastos não muda. O que se provou é a configuração implantada, não o comportamento.

## Retestes da rodada anterior
- FALHA 1 (envio não exercitável): não corrigida por construção; tratada pela exceção acima (vai ao financeiro).
- FALHA 2 (pedido de 30/10): fora do escopo por decisão do responsável.

## Falhas
Nenhuma falha encontrada nos casos executados.

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | Componentes do deploy existem na QA | Retrieve do ApprovalProcess e do Workflow; `COUNT` em Report e Dashboard | Todos presentes | Processo e workflow existem; Report `JOBs_de_Investimento_HsY`: 1; Dashboard `sFQeqnPANgKWxQuaSnWRYtxzKhCxCL`: 1 | passou |
| C1 | Processo da QA igual ao versionado | Retrieve da QA para pasta temporária (apagada) e `diff` com o repositório | Sem diferença | Processo de aprovação e workflow idênticos (`AP_IGUAL`, `WF_IGUAL`) | passou |
| C2 | Processo ativo com ação de envio inicial | Leitura do XML retornado da QA | `active=true`, `initialSubmissionActions` = `Status_Qualificacao` | `active=true`, `processOrder=2`, ação `Status_Qualificacao` (FieldUpdate) em `initialSubmissionActions`; 4 `approvalStep` | passou |
| C3 | Ações gravam o valor certo | Leitura das FieldUpdate no workflow | Envio=Pendente, Aprovação=Aprovado, Rejeição=Rejeitado, Recall=Recall | `Status_Qualificacao`=Pendente; `_Aprovacao`=Aprovado; `_Rejeicao`=Rejeitado; `_Recall`=Recall, todos no campo `Status_da_Qualificaco__c` | passou |
| C4 | Ação de envio não toca previsão de gastos | Busca de `Status_Previs_o_de_Gastos` no XML do processo | Nenhuma referência | 0 ocorrências | passou (por configuração) |
| C5 | Filtro do relatório cobre todos os status | Leitura do XML do relatório | Todos os valores cobertos | Filtro lista: vazio, Não Enviado, Pendente, Aprovado, Rejeitado, Recall (todos os valores existentes na QA) | passou |
| C6 | Nenhum Job some do relatório; rosca = linhas | `COUNT` agregado de Jobs na janela do relatório (`Data__c` de 2024-01-01 a 2026-12-31, intervalo `INTERVAL_PREVCUR2FY`) e por status | Soma por status = total da janela | Total 265 = Aprovado 242 + Rejeitado 11 + Não Enviado 11 + Pendente 1. Fora da janela: 1009 (de 1274 Jobs no objeto); a janela não foi alterada (decisão G2 sem resposta, relatório igual ao original) | passou (contagem; tela não aberta) |
| C7 | Dashboard usa o relatório | Leitura do XML do dashboard | Componente aponta para o relatório | Componente com `Financeiro/JOBs_de_Investimento_HsY` (linha 63) | passou (por configuração) |
| C8 | Envio grava Pendente; aprovar/rejeitar/reenviar; recall | Exige envio real por usuário que entre nos critérios | Pendente / Aprovado / Rejeitado / Pendente | Não executado por exceção do responsável; passo a passo no roteiro do cliente | não executado (exceção) |
| C9 | Dashboard = relatório na tela | Exige abrir tela com dado real copiado (guardrail LGPD) | Contagens iguais | Não aberto; vai ao roteiro do cliente | não executado |
| C10 | Nenhum dado de cliente nos testes | Só contagens agregadas e leitura de metadata; sem DML | Nenhum dado real | Atendido; `COUNT` de Jobs `TESTE SOMOSAGILITY-22%`: 0 (nada criado) | passou |

## Distribuição geral na QA (referência, contagem agregada)
1274 Jobs: Aprovado 977, Rejeitado 82, Não Enviado 34, Pendente 13, Recall 1, sem valor 167.

## Riscos do assessment e demanda vizinha
- Oportunidade (31 automações) e cobertura Apex (40%): não tocados; a entrega é só processo de aprovação, workflow, relatório e dashboard, sem Apex nem Flow.
- Perfil por pessoa: é o que torna o envio dependente de usuário real (ver exceção).
- SOMOSAGILITY-17 (aguardando_homologacao) também mexe em `approvalProcesses/JOB_de_Solicita_o_de_Investimento__c`. A QA já traz o processo igual ao versionado nesta demanda. Não avaliei o conteúdo da outra demanda; na homologação, conferir que o envio continua igual ao esperado nos dois, e o time deve decidir a ordem de entrega para um não sobrescrever o outro.
- Outros 44 relatórios de Job: os números de "Pendente" vão subir e os de "Não Enviado" cair para envios novos; o financeiro deve ser avisado (R3 do design). Jobs já em aprovação não são corrigidos (G3).

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma automação disparada, nenhum e-mail ou chamada externa, nenhum job agendado. Nenhuma alteração de usuário, permission set ou perfil. Pasta temporária do retrieve apagada.

## Tela
`qa_browser_*` não usado: relatório e dashboard só existem com dado real copiado na QA. Sem capturas.
