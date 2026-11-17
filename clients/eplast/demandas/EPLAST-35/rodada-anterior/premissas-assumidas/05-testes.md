**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-35 — Testes na sandbox de QA

Org conferida com `sf org list`: só `sbx-eplast-qa` (Sandbox, Org Id 00DHa000006vZtmMAE, a "QAS" da Eplast, `eplast--qas`, Partial Copy). Pacote já implantado pela esteira (`05-deploy-qa.md`: deploy `0AfHa00000EI1ATKA1`, Succeeded, commit `34fd1c82`, 21 componentes). Premissas PA-01 a PA-19 do design tratadas como decididas (regra 4 da conta). Dados de teste só sintéticos (`TESTE EPLAST-35`, sem telefone, e-mail ou CPF), criados e apagados por mim; nenhum registro existente foi lido ou alterado (só contagens).

## Falhas
Nenhuma falha encontrada nos casos executados. Lacunas de prova (não são falhas): casos Q6, Q10 e Q11 abaixo, listados em "O que ficou sem prova".

## Componentes na org
Conferidos por consulta: 8 filas `Leads_*` (CO, ES, MG, NO_NE, RJ, SP, Sul, Triagem); Flow `Lead_AfterInsert_AplicaRegraAtribuicao` versão 1 `Active` (versão ativa = última); custom permission `Lead_DistribuicaoAutomaticaViaApi`; permission set `PS_Integracao_DistribuicaoLead`; classes `LeadAssignmentService` e `LeadAssignmentServiceTest`; relatório `Aprovacoes_Pendentes_Por_Processo`. Nenhum ausente.

## Casos (derivados de 01-analise.md seção 7 e dos critérios ajustados em 03-design.md seção 11)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Q1 componentes | Consultas `sf data query` (acima) | Todos os itens de `05-deploy-qa.md` existem | Todos presentes; Flow Active | passou |
| Q2 régua por região (cenário "Lead novo recebe responsável pela régua") | Apex anônimo: 7 Leads com a regra de atribuição ativa (`useDefaultRule`), UF = SP, RJ, MG, ES, PR, GO, BA | Dono = fila da região | SP→Leads SP, RJ→Leads RJ, MG→Leads MG, ES→Leads ES, PR→Leads Sul (PR, SC, RS), GO→Leads Centro-Oeste, BA→Leads Norte e Nordeste (consulta de `Owner.Name`, 7 de 7) | passou |
| Q3 fallback (cenário "sem critério cai na fila de fallback") | Mesmo script, UF vazia e UF "Sao Paulo" | `Leads_Triagem`, nunca sem dono | Os dois em Leads Triagem | passou |
| Q4 Lead sem a regra e sem o PS fica com o criador | `Database.insert` sem opção de regra, UF=SP, usuário sem o PS | Flow não age; dono = criador | Dono = o usuário criador (Konecta2), sem reatribuição | passou |
| Q5 encaminhamento com histórico | Transferência do Lead de teste do criador para `Leads_RJ` (update de OwnerId) | Dono muda; histórico do campo Proprietário gravado | Dono = Leads RJ; `LeadHistory` Field=Owner: 2 linhas para os Leads de teste (antes: 0 na org inteira) | passou |
| Q6 Lead por API/lote com o PS vai para a fila (via Flow assíncrono) | Exigiria atribuir o PS a um usuário e criar Lead por esse usuário | Dono = fila | Não executado na QAS: atribuir permission set ao usuário `005bJ00000piKAaQAM` é proibido pela regra 6 da conta e criar usuário de integração na Partial Copy foge ao escopo. Provado na dev (`04-verificacao.md`: C1 12/12 UFs, C2, C3 200 de 200, C4) e no teste unitário | não executado |
| Q7 Apex | Testes `LeadAssignmentServiceTest` na QAS (`ApexTestResult`) | Verdes, >= 85% | 7 de 7 passam (execução do deploy e execução minha, 20:27); `LeadAssignmentService` 13 linhas cobertas, 0 descobertas (100%) | passou |
| Q8 não duplicar aprovações | `SELECT ... FROM ProcessDefinition WHERE State='Active'` | Os 3 processos existentes ativos, nenhum novo | Atribuir ao Pricing, Análise financeira, Liberação Financeiro; só 3, e nenhum faz parte do deploy | passou |
| Q9 relatório de pendentes | Consulta ao Report `Aprovacoes_Pendentes_Por_Processo` | Existe | Existe na pasta Geral. Execução não repetida na QAS (dev: executou, `allData=true`, 0 linhas) | passou (existência) |
| Q10 tela: caixa "Atribuir usando regra ativa" marcada | Abrir novo Lead pela interface | Caixa vem marcada | UI não carregou na sessão automatizada (só o esqueleto da página, screenshot sem conteúdo). No metadado implantado: `runAssignmentRulesDefault = true` | não executado (ver roteiro) |
| Q11 sem efeito em Account/Opportunity/Order e na conversão | Conversão de Lead | Nenhuma automação extra | Não exercitado. Conferência por metadata na dev (Lead com 0 triggers e 1 Flow; Account/Opportunity/Order/Quote não tocados) | não executado |
| Q12 campos novos com descrição | Design: nenhum campo custom novo | n/a | Nenhum objeto ou campo custom novo no pacote | n/a |

## Conflitos do preflight (EPLAST-26 e EPLAST-38)
`00-preflight.md` avisa que EPLAST-38 (aguardando gate de build) mexe nos mesmos componentes de Lead (regra de atribuição, Flow, classe e teste, custom permission, permission set, filas, layout) e EPLAST-26 no layout `Lead-Lead Layout`. Os dois estão fora da QAS: o que foi testado é só o build da EPLAST-35. Risco para o gate: ao levar os três para a mesma org, quem entrar depois precisa partir da versão atual (Flow versão 1 ativo, regra de atribuição e layout já implantados), senão sobrescreve. Não testei combinação entre as demandas.

## Achado da org de teste (ordem de execução / assessment)
Lead tem 0 triggers e um Flow só de criação (conforme build). Account, Opportunity e Order não são tocados, então o risco do assessment sobre automação concorrente nesses objetos não é exercido aqui. Cobertura Apex da org segue baixa (pré-existente); a classe da demanda tem 100%.

## O que pode ter saído da org
Nada fora da sandbox. Os 10 Leads `TESTE EPLAST-35` foram criados só por Apex anônimo (sem e-mail, sem integração; a regra não envia notificação, PA-18) e apagados no fim: consulta final, 0 Leads com a empresa `TESTE EPLAST-35`; total de Leads da org 712, igual ao do início. Nenhuma chamada externa e nada no Marketing Cloud. Os registros de histórico dos Leads apagados vão para a lixeira.

## O que ficou sem prova
- Q6: Lead criado por usuário de integração com o PS (Flow assíncrono) na QAS. Provado só na dev e por teste unitário; confirmar na homologação criando Lead por um usuário de integração real.
- Q10: caixa da tela. Só metadado.
- Q11: conversão de Lead.
- Vendedores nas filas e atribuição do PS às integrações são passos manuais do admin (`04-plano-build.md` seção 6); sem isso, Lead fica na fila e Lead de API sem o PS não é redistribuído.
- Veredito aprovado considera que o critério principal (régua por região, fallback, histórico, cobertura, não duplicar aprovações) foi executado na QAS, e que Q6 tem prova equivalente na dev; se o cliente exigir Q6 na QAS, é teste de homologação.
