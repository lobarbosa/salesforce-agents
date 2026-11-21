**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy, Org Id 00DHa000006vZtmMAE, Connected; única org em `sf org list`)

# EPLAST-35: Testes na QA, rodada 2

Rodada 1 reprovou porque a QAS chegou com Flow em Draft, regra v2 inativa e interruptor desligado (FALHA 1). **Corrigida**: o deploy `0AfHa00000EM4o6KAD` (Succeeded, commit `061718df`) entregou o estado combinado. Conferido na org antes de testar:
- Flow `Lead_AfterSave_DistribuiDonoRodizio` v1 **Active**. Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao` v3 Active (v1 e v2 Obsolete; sem versão nova da 35).
- Regras de Lead: `Distribuicao_Regional_Leads_v2` ativa, `Distribuicao_Regional_Leads` inativa.
- CMDT `DistribuicaoLeadSetting.Padrao`: `DistribuicaoAtiva__c`, `RodizioAtivo__c`, `RespeitarDonoConta__c` = true; prefixo `Leads_`; `FilasSemRodizio__c` = `Leads_Triagem`.
- Nenhuma ativação feita por mim (já vinha ativo). Filas `Leads_*`: 9, incluindo `Leads_RJ_ES`. Membros diretos de usuário em filas `Leads_*` antes: 0.
- Usuário de teste (conta de serviço Konecta, ativo, Administrador do sistema): `005bJ00000piKAaQAM`. Segundo membro de teste (Comercial - Analista, ativo, Standard): `005bJ000004gGVxQAM`. O inativo `005bJ00000hBJmYQAW` existe e não foi usado.
- Mudanças no meu usuário de execução: nenhuma (sem permission set, sem Marketing User, sem campo de Protheus).

Todos os dados são sintéticos (`TESTE EPLAST-35`), um Lead por execução de Apex anônimo (exceto os lotes). Os dois membros de teste entraram só em `Leads_RJ_ES` (fila nova, não é da EPLAST-38); as demais filas ficaram sem membro, o que serve de controle (sem elegível, o Lead fica na fila). Nada de Marketing Cloud tocado.

## Falhas
Nenhuma falha nos casos executados. A FALHA 1 da rodada 1 está corrigida (acima).

## Casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C0 Componentes do deploy existem na QAS | Tooling `Flow`, `AssignmentRule`, `Group`, CMDT | Itens de `05-deploy-qa.md` presentes e ativos | Flow ativo, regra v2 ativa, CMDT `Padrao` ligado, 9 filas | Aprovado |
| T1/T2/T4 RJ e ES vão para a fila nova e há rodízio | 4 Leads, um por execução: RJ, ES, RJ, ES (`useDefaultRule = true`), `Leads_RJ_ES` com 2 membros | Dono = membro, não a fila; nenhum em `Leads_RJ` ou `Leads_ES`; alterna | Donos: `…piKAaQAM`, `…4gGVxQAM`, `…piKAaQAM`, `…4gGVxQAM`. Por Lead: SOQL 7, DML 2, CPU 80 a 98 ms | Aprovado |
| T5 CNPJ de conta de teste, UF de outra região | Conta E (CNPJ só dígitos, dono teste); Lead UF RS com o CNPJ mascarado. `Leads_RS`/`Leads_Sul` sem membro, logo sem a conta ficaria na fila | Dono = dono da conta | Dono `…piKAaQAM`. Captura `evidencias/02-t5-lead-de-teste-teste-eplast-35-t5-uf-r.jpg` (aba Detalhes: proprietário é o usuário, não a fila) | Aprovado |
| T6 Máscara x dígitos nos dois sentidos | Conta F (CNPJ mascarado, dono Comercial): Lead só dígitos e Lead mascarado; Conta E (só dígitos): Lead só dígitos. Todos UF RS | Dono = dono da conta | F: `…4gGVxQAM` nos dois Leads; E: `…piKAaQAM` | Aprovado |
| T6b Formato do CNPJ nas contas (só contagem) | `COUNT()` em Account | 3 contagens | Com CNPJ 1221; máscara `__.___.___/____-__` 453; sem ponto 768; outros (1221-453-768) = 0. A busca por 14 dígitos ou máscara cobre 100% | Aprovado |
| T8 CNPJ em 2 contas com donos diferentes | Contas C (dono teste) e D (dono Comercial), mesmo CNPJ; Lead UF RS | Não usa dono de conta; vai ao rodízio (RS sem membro: fica na fila) | Dono = fila `Leads_Sul` (`00GHa000006bNv9MAE`) | Aprovado |
| T10 UF vazia | (a) sem UF com CNPJ da conta E; (b) sem UF e sem CNPJ; (c) sem UF com CNPJ da conta F | Com conta: dono da conta. Sem conta: `Leads_Triagem` | (a) `…piKAaQAM`; (b) fila `Leads_Triagem` (`00GHa000006bNvAMAU`); (c) `…4gGVxQAM` | Aprovado |
| T11 Fila regional sem elegível | Lead UF SP e Lead UF GO (filas sem membro) | Fica na fila | Dono = `Leads_SP` e `Leads_CO` | Aprovado |
| T12 Caixa desmarcada | 1 Lead UF RJ com `useDefaultRule = false` | Dono = criador | Dono `…piKAaQAM` (criador) | Aprovado |
| T13 (transferência) Transferência manual redistribui | Lead de T12 passa para `Leads_RJ_ES` (com membros) e depois para `Leads_MG` (sem membros) | Para fila com elegíveis: vira vendedor; sem elegível: fica na fila | RJ_ES: dono `…piKAaQAM`; MG: dono = fila `Leads_MG` | Aprovado |
| T3 Lote de 200 Leads, uma inserção (70 RJ, 70 ES, 60 SP) | `Database.insert` com `useDefaultRule = true` | Todos com dono, sem erro de limite, CPU abaixo de 70% | 0 erros. RJ 35/35 e ES 35/35 entre os 2 membros; SP 60 na fila `Leads_SP` (sem membro). **SOQL 6/100, DML 2/150, linhas DML 340, CPU 1370 ms/10000 (14%), heap 29 KB** | Aprovado |
| T7 Lote alternando SP, RJ (40) | 40 Leads em uma inserção | Registrar a distribuição (evidência de R5, não é reprovação) | RJ: **20 de 20 para um só vendedor** (`…piKAaQAM`, 0 para o outro); SP 20 na fila. Mostra a concentração de `MOD(n, k)` quando a chegada alterna regiões com período múltiplo de k. SOQL 6, DML 2, CPU 310 ms | Aprovado (evidência para o cliente) |
| T16 Isolamento | Contagens antes e depois da limpeza | Account, Opportunity e Order iguais; sem job novo de Protheus pela cadeia do Flow | Opportunity 9347/9347, Order 10327/10327, Account 1223/1223 (4 de teste criadas e apagadas), Lead 716/716. `AsyncApexJob` de `SendAccountToProtheus`/`UpdateAccountCompanyInfo`: 562 antes, 563 depois, ver "O que pode ter saído da org". O job novo é do T18 (conversão), não da distribuição: os Leads de T1 a T13 e os lotes não geraram job | Aprovado, com ressalva documentada abaixo |
| T17 Versões | Tooling `Flow`, `AssignmentRule`, `sf apex run test` | Flow antigo sem versão nova da 35; classe da 38 passa; nenhuma classe nova da 35 | Flow antigo v3 Active (v1, v2 Obsolete, estado da 38); `05-deploy-qa.md` só tem `LeadAssignmentService*` de classes. `LeadAssignmentServiceTest` 7 de 7, 100%, depois de remover os membros de teste. Os 3 processos de aprovação: não conferidos (metadado não listável nesta sessão) | Aprovado (parcial; aprovações não conferidas) |
| T18 Lead convertido com troca de dono | `convertLead` de 1 Lead de teste para a conta de teste F, sem oportunidade, dono convertido diferente | Flow entra e sai sem erro | Conversão com sucesso, sem erro | Aprovado |
| T3b Lote pelo usuário de integração, assíncrono | Exige usuário com `PS_Integracao_DistribuicaoLead`. Atribuí-lo a mim não está autorizado (é da EPLAST-38) | Medições | Não executado. A parte da classe passa na suíte (7 de 7, inclui lote de 200) | Não executado |
| T13 (interruptor e `RodizioAtivo=false`) | Trocar o CMDT `Padrao` só por deploy, que não faço | Nada acontece | Não executado. Fica no roteiro do cliente (Teste 8) | Não executado |
| T9 Dono da conta inativo | A plataforma recusa conta com dono inativo (`INACTIVE_OWNER_OR_USER`) | Vai ao rodízio | Não montável por insert | Não executado |
| T14 Falha na gravação | Sem perfil de teste sem leitura de Lead | Lead fica na fila | Não executado | Não executado |
| T15 `Comercial - Analista` cria Lead pela tela | Não há login desse usuário para o QA | Distribui sem erro de acesso | Não executado. Indício: o membro Comercial recebeu Leads em T1/T2/T4/T6/T10, e o Flow roda em contexto de sistema | Não executado |

Resumo: critérios principais (região regra v2, dono da conta por CNPJ com exatamente uma conta, rodízio, fila sem elegível, caixa desmarcada, transferência, lote de 200 com folga) exercitados e aprovados na QAS. Sem prova: T3b, T9, T14, T15 e os dois interruptores de T13. Estão no roteiro do cliente quando dá para conferir pela tela.

## Decisão para o cliente (R5)
Com a fórmula `MOD(n, k)`, a distribuição é equilibrada em volume com mistura de regiões (T3: 35/35), mas concentra em um vendedor quando a chegada alterna regiões com período múltiplo de `k` (T7: 20 de 20). É o que o design aceitou; a fórmula alternativa é uma troca de fórmula no Flow. Fica para o cliente na homologação.

## Mudanças que fiz e o que ficou
- Inseri 2 `GroupMember` em `Leads_RJ_ES`. **Removidos** ao final (0 membros diretos de usuário em filas `Leads_*`, conferido por contagem).
- Dados de teste: 4 contas, 1 contato (da conversão) e 220+ Leads `TESTE EPLAST-35`, **todos apagados**. Conferido: Lead `TESTE EPLAST-35` 0, Lead total 716 (igual ao início), Account 1223 (igual ao início), Contact de contas de teste 0.
- Nenhuma ativação, nenhum deploy, nenhum job agendado, nenhum permission set alterado.
- A única captura mantida mostra o registro de teste T5.

## O que pode ter saído da org
- Um job `SendAccountToProtheus` (Completed, `ExtendedStatus` nulo) criado no momento do T18: a conversão do Lead para a conta de teste F atualizou a conta e passou pela `AccountTrigger` (o desvio `bypassTrigger` só vale na minha transação de criação). Pode ter enviado ao Protheus a conta sintética de teste F (identificada na org pelo nome `TESTE EPLAST-35 F`, sem CNPJ nem contato no artefato). Não vem da solução da EPLAST-35: é comportamento já existente da conta. A Eplast pode querer excluir essa conta no ERP.
- Nenhum e-mail enviado pela cadeia (a regra v2 não tem template; o Flow não envia).
- Os 4 Leads de teste distribuídos a usuários reais (`…4gGVxQAM`) foram apagados com o resto; esse usuário apareceu como dono de Leads sintéticos por alguns minutos.
