**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy, Org Id 00DHa000006vZtmMAE, Connected; única org em `sf org list`)

# EPLAST-35: Testes na QA, rodada 1

Deploy conferido: `05-deploy-qa.md` (deploy `0AfHa00000EJCzxKAH`, Succeeded, commit `6885509d`). Nada foi alterado na org nesta sessão: nenhum DML, Apex anônimo, deploy, ativação, permission set ou dado de teste. Nada a desfazer. Marketing Cloud não tocado.

## Por que reprovado
O comportamento da entrega (dono da conta, rodízio, regra regional v2) **não foi exercitado**, e todos esses são critérios de aceite principais. Não é defeito de código achado: é que a QAS não está no estado em que o design permite testar, e eu não tenho autorização para colocá-la nesse estado.

### FALHA 1 (crítica) — Cadeia de distribuição inalcançável na QAS: Flow em Draft, regra v2 inativa, interruptor desligado
- **Reproduzir / obtido** (consultas na `sbx-eplast-qa`):
  - Flow `Lead_AfterSave_DistribuiDonoRodizio`: versão 1 com status **Draft** (Tooling `Flow`). O plano de build diz "Active"; a QAS recebeu rascunho. Sem versão ativa, não dispara.
  - Regra de Lead: `Distribuicao_Regional_Leads` (v1) **ativa**; `Distribuicao_Regional_Leads_v2` **inativa**.
  - `DistribuicaoLeadSetting.Padrao`: `DistribuicaoAtiva__c = false` (`RodizioAtivo__c` true, `RespeitarDonoConta__c` true, prefixo `Leads_`, sem rodízio em `Leads_Triagem`).
  - Fila `Leads_RJ_ES` existe, com 0 membros. Não há elegível para o rodízio.
- **Esperado:** para provar T1 a T15 e T18 é preciso (1) ativar o Flow, (2) ativar a v2 da regra, (3) ligar o interruptor, (4) pôr membros de teste em `Leads_RJ_ES`.
- **Por que não fiz:** (2) e (3) mudam a distribuição de todo Lead novo numa org com dado real, e o design (PA-30) condiciona isso a fechar a homologação da EPLAST-38 (hoje `aguardando_homologacao`) ou a aceite do responsável para homologar as duas juntas. Não há esse aceite em lugar nenhum que eu leia. O registro `Padrao` e a regra só mudam por deploy, que não é meu. Ativar só o Flow (item 1) não prova nada com o interruptor desligado.
- **Para o próximo passo:** o responsável decide uma das saídas: (a) aceitar a ativação conjunta com a EPLAST-38 e a esteira entregar à QA o Flow ativo, a v2 ativa e o interruptor ligado (e pelo menos 2 membros de teste em `Leads_RJ_ES`, que não é da 38; o usuário de teste `005bJ00000piKAaQAM` está ativo, o `005bJ00000hBJmYQAW` está inativo, ambos conferidos); ou (b) fechar a homologação da 38 antes e reenviar. Quando o estado existir, o QA roda T1 a T18 do `03-design.md` seção 12.
- Observação: o `04-verificacao.md` da DEV também ficou inconclusiva pelo mesmo motivo (Flow em Draft); o rodízio **nunca foi exercitado em runtime em nenhuma org**. FALHA 1 da rodada de verificação (`Get_Membros`) segue sem confirmação de correção.

## Casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes do deploy existem na QAS | Consultas: Tooling `Flow`, `CustomField`, `AssignmentRule`, `Group`, CMDT | Itens do `05-deploy-qa.md` presentes | Flow (Draft), campo `Lead.DIST_SequenciaRodizio__c` com descrição, CMDT `Padrao`, regras v1 e v2, 9 filas `Leads_*` incluindo `Leads_RJ_ES`. Nenhum ausente | Aprovado |
| C1 Apex da EPLAST-38 tocado no mesmo pacote | `sf apex run test -n LeadAssignmentServiceTest` | Passa | 7 testes, 100%, run `707Ha00001EGk6u` | Aprovado |
| C2 Nenhuma classe nova da EPLAST-35 (design: sem Apex) | `05-deploy-qa.md` | Só `LeadAssignmentService*` (EPLAST-38) | Confere: nenhuma classe da 35 | Aprovado |
| C3 Campo novo com descrição | Tooling `CustomField` | Description preenchida | Preenchida | Aprovado |
| C4 Interruptor entra desligado (PA-34) | Query no CMDT | `DistribuicaoAtiva__c = false` | `false` | Aprovado |
| C5 v2 entra inativa, v1 ativa | Query `AssignmentRule` | v1 ativa, v2 inativa | Confere | Aprovado |
| T6b Formato do CNPJ nas contas (só contagem) | `COUNT()` em Account | Registrar 3 contagens | Com CNPJ: 1221. Máscara `__.___.___/____-__`: 453. Sem ponto: 768. Outros formatos (1221 − 453 − 768): 0 | Aprovado (evidência) |
| T1, T2, T3, T3b, T4 | Lead por tela/lote, UFs SP, MG, RJ, ES | Dono é vendedor da fila; alternância; RJ/ES na fila nova | Não executado (FALHA 1) | Não executado |
| T5, T6, T8, T9, T10 | Lead com CNPJ de conta de teste | Dono da conta com exatamente 1 conta ativa | Não executado (FALHA 1). Pré-requisito atendido: máscara e dígitos cobrem 100% das contas com CNPJ | Não executado |
| T7, T11, T12, T13, T14, T15, T18 | Ver design seção 12 | Ver design | Não executado (FALHA 1) | Não executado |
| T16 Isolamento Account/Opportunity/Order | Contagens antes/depois | Iguais | Sem execução da cadeia, não há "depois" | Não executado |
| T17 Aprovações e Flow antigo sem mudança | Comparar | Sem mudança | Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao`: v2 ativa, v1 obsoleta (estado da EPLAST-38, sem versão nova da 35). Os 3 processos de aprovação: `ProcessDefinition` não consultável por `sf data query` nesta versão; não conferido | Inconclusivo |

Resumo: 6 aprovados + 1 evidência, 1 inconclusivo, demais não executados. Capturas de tela: nenhuma (nada exercitável pela tela).

## Interferência de outras demandas
EPLAST-38 (mesma regra, mesmo Flow antigo, filas `Leads_*`) e EPLAST-26 (layout de Lead) estão em homologação na QAS. Flow antigo está na v2 ativa da 38. Sem interferência observada, pois nada foi exercitado. Ponto de atenção para a ativação conjunta (PA-30).

## O que pode ter saído da org
Nada. Só consultas (contagens agregadas, metadata) e a execução da classe de teste `LeadAssignmentServiceTest`, que não deixa dado.
