# SOMOSAGILITY-14 — Design (sustentação, design enxuto)

- Cliente: somos-agility
- Org do recon: `sbx-somos-agility-dev` (Sandbox, Org Id `00DHa0000070wxfMAA`)
- Base: `01-analise.md` (aprovada em 2026-10-19 por Carlos Sordi) e `02-recon.md`
- Status: **aguardando gate bloqueante do arquiteto humano**

> O gate da análise foi aprovado mesmo com P1–P6 em aberto, e o design segue nessa condição.
> A **causa raiz é uma hipótese, não um fato**: ela se apoia na metadata da dev, e a SR afetada,
> o print e a org onde o erro aconteceu não chegaram até aqui. Na seção 1, hipótese e
> confirmação aparecem separadas.

---

## 1. Diagnóstico

### Confirmado via `sf` CLI (dev)

1. `Solicitacao_de_Reembolso__c` tem 4 Approval Processes ativos: `SolicitacaoReembolsoBackofficeRHGov4`,
   `ReembolsoMarketing4`, `ReembolsoPosVenda5` e `Reembolso_Comercial_pre_vendas_e_CS`.
2. Nos quatro, o critério de entrada é **apenas** uma lista de `CreatedBy equals <nome do usuário>`.
   São 32 nomes no total e não existe processo catch-all.
3. O único usuário ativo "Simone*" da dev **não está** em nenhuma dessas listas.
4. O perfil dela (`Gerente de Contas`) tem Create/Edit no objeto. Isso explica por que ela consegue
   criar a SR e mostra que o bloqueio não é de CRUD.

### Hipótese principal (H1, alta probabilidade, não confirmada)

O usuário cria a SR e, ao clicar em "Enviar para aprovação", o Salesforce não encontra AP cujo
critério de entrada ele satisfaça. O erro padrão nesse caso é *"Nenhum processo de aprovação
aplicável foi encontrado"* / *"No applicable approval process was found"*. Isso combina com o
relato ("abre, mas não envia"). A causa estrutural é que **cada novo solicitante precisa ser
incluído pelo nome em um AP**: quem nunca foi incluído (pessoa nova ou que mudou de área) cai
nesse erro.

O que confirmaria H1: o texto do print (P1). Também dá para reproduzir na dev: basta enviar uma
SR criada por qualquer usuário que não esteja nas listas. Esse é o primeiro passo do build.

### Hipóteses secundárias (só valem se H1 for descartada, ou aparecem depois de corrigir H1)

- **H2 (média).** Corrigido H1, a SR cai numa etapa com aprovador `aprovadorCordGerente__c`
  (relatedUserField). Esse campo vem de `Contact.AprovadorReembolso__c` do solicitante, pelo Flow
  `atualizaAprovadorReembolso`. Se o Contact da Simone não tiver aprovador, o envio falha com erro
  de "próximo aprovador vazio". Isso não foi verificado, porque exigiria ler dado de registro.
- **H3 (baixa).** O update feito pelo Flow after-save `Atualiza_o_status_de_aprovacao_e_etapas_da_SR`
  dispara a VR `Aprovar_Vencido_Gestor` (se `Aprovado_Reembolso_Vencido__c` = TRUE e o `$User` não
  é o gestor) ou a VR `PIN`. Probabilidade baixa: as mesmas VRs já teriam barrado o save inicial
  da usuária.
- **H4 (baixa).** A SR não pertence à Simone. O AP só permite envio pelo `owner`, e aí o erro
  seria de permissão para enviar.

## 2. Decisão

**Nível: configuração.** O build ajusta o critério de entrada do Approval Process ativo que
corresponde à área da usuária, incluindo-a. Não há Flow novo nem código.

Justificativa:

- O defeito, se H1 se confirmar, está na configuração do AP. A correção de menor risco e menor
  superfície é incluir a usuária no critério do processo certo, que é exatamente o que o cliente
  já faz para os outros 32 solicitantes.
- Flow e código ficam descartados: nada no diagnóstico pede lógica nova. Trocar o AP por um
  Flow/Orchestrator mudaria a regra de aprovação, o que é escopo de projeto e não de sustentação.
- Não há mudança de modelo de dados. Nenhum campo ou objeto novo, então não é preciso escalar
  decisão de arquitetura sênior por esse motivo.

**Escolha do AP: não está decidida.** A metadata não diz a que área a usuária pertence, e o
perfil `Gerente de Contas` sozinho não basta. O candidato mais provável pelo perfil é
`Reembolso_Comercial_pre_vendas_e_CS`, mas isso é palpite e não vale como base de build.
**O consultor ou o dono do processo precisa dizer qual AP e qual cadeia de aprovação valem para
ela (P5)**, porque isso decide quem aprova o dinheiro dela, e essa decisão é de negócio.

## 3. Componentes

| Ação | Tipo | API name | Detalhe |
|------|------|----------|---------|
| Alterar | ApprovalProcess | `Solicitacao_de_Reembolso__c.<AP definido em P5>`, um destes: `SolicitacaoReembolsoBackofficeRHGov4`, `ReembolsoMarketing4`, `ReembolsoPosVenda5`, `Reembolso_Comercial_pre_vendas_e_CS` | Acrescentar 1 `criteriaItems` `CreatedBy equals <nome da usuária>` no `entryCriteria` do processo e estender o `booleanFilter` com `OR n+1`. Etapas, aprovadores e ações não mudam. Limite de 25 critérios: o maior hoje tem 13, então há folga |
| Criar | — | — | Nada |
| Depreciar | — | — | Nada nesta demanda |

Se H2 se confirmar, a correção é **cadastral**: preencher `Contact.AprovadorReembolso__c` do
solicitante. É dado, não metadata. Quem faz é o admin do cliente, na org do erro, e o agente não
toca. Fica registrado como pré-requisito de homologação.

Processo de entrega: retrieve do AP escolhido para `force-app` do cliente em
`feature/SOMOSAGILITY-14`, edição do XML, `ci-salesforce-validate` (check-only), deploy em dev e
depois em QA pela esteira.

## 4. Impacto em permissões

- Nenhum perfil ou permission set muda. O perfil `Gerente de Contas` já tem Read/Create/Edit em
  `Solicitacao_de_Reembolso__c`.
- `allowedSubmitters = owner` fica como está. Se H4 se confirmar, a solução é a SR ter o owner
  correto, não mudar quem pode enviar.

## 5. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|-------|-----------|-----------|
| R1 | **Conflito de automação no mesmo objeto/evento.** O envio dispara o field update `Status_Pendente`, que faz rodar de novo `TrgSolicitacaoReembolso` (Apex, before/after update) **e** os Flows `Email_Gestor_4` e `Status_Etapa_Aprova_o_Gestor` (before-save) e `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` (after-save, que faz outro update no `$Record`, sem fault connector). A ordem entre Flow before-save e trigger é determinística, mas entre Flows do mesmo evento não há `triggerOrder` visível. Uma falha em qualquer um deles aparece para o usuário como "erro ao enviar". | **Alta** (por isso H1 pode não ser a única causa) | A correção não mexe nessas automações. Na QA, enviar a SR com a usuária incluída e conferir se `Status__c` e `Status_de_Aprovacao_e_Etapas__c` foram preenchidos sem erro. Se falhar, a causa está aqui ou em H2/H3 e volta para design |
| R2 | A metadata da dev pode não ser igual à da org onde o erro ocorreu (P3). A dev tem 0 SR, o que sugere sandbox sem refresh recente | Alta | Antes do build, confirmar P3. Se o erro foi em produção, o consultor precisa confirmar que os 4 APs ativos de lá batem com os da dev (nome e versão), ou que vale fazer refresh da dev. O agente não lê produção |
| R3 | O deploy por Metadata API de um AP **ativo** pode ser recusado quando a mudança afeta etapas. Entrada de critério normalmente passa, mas isso não foi testado nesta org | Média | `ci-salesforce-validate` (check-only) antes do deploy. Plano B: clonar uma versão nova do AP (padrão que o cliente já usa, `_v1_1`, `_v1_2`…), ativar e desativar a anterior, preservando o `processOrder` |
| R4 | `CreatedBy equals <nome>` compara por nome exibido. Homônimos ou mudança de nome do usuário quebram o critério em silêncio | Média (estrutural) | Fora do escopo (seção 6). Registrar como dívida |
| R5 | Inclusão no AP errado faz a SR seguir para os aprovadores errados (risco financeiro e de controle) | Média | P5 é obrigatório antes do build e o gate humano revisa o diff |
| R6 | Limites de governador e escala | Baixa | Nenhuma lógica nova. `SolicitacaoReembolsoBO` está bulkificado (1 SOQL e 1 DML fora de loop). Envio de aprovação é por registro |

## 6. O que NÃO será feito nesta demanda

- Trocar o critério nominal (`CreatedBy equals <nome>`) por critério de perfil, papel, área ou
  campo. É a correção estrutural que evitaria a próxima "Simone", mas muda a regra de aprovação
  de todos os solicitantes. **Recomendo abrir uma demanda própria (melhoria)** para isso.
- Consolidar as 49 versões de AP, remover obsoletos ou migrar o AP para Flow.
- Corrigir a condição de retorno precoce em `SolicitacaoReembolsoTriggerHandler.afterUpdate`
  (observação lateral do recon, sem relação com o sintoma). Fica registrada para triagem.
- Adicionar fault path ao Flow `Atualiza_o_status_de_aprovacao_e_etapas_da_SR`.
- Alterar dados (Contact, owner da SR, aprovador). Se H2 ou H4 se confirmarem, é ação do admin
  do cliente.
- Qualquer ação em produção (guardrail #1).

## 7. Pendências que bloqueiam certeza (antes do build ser considerado completo)

| # | Pergunta | Por que bloqueia | Quem |
|---|----------|------------------|------|
| P1 | Texto exato do erro no print | Confirma ou descarta H1 de uma vez. Se o texto for outro, o design volta | Consultor |
| P3 | Em qual org ocorreu (produção, QA ou dev) | Se foi produção, é preciso garantir que a configuração de AP de lá bate com a da dev (R2) | Consultor |
| P5 | A qual área ou processo de aprovação a usuária pertence, e quem deve aprovar o reembolso dela | Define **qual** dos 4 APs alterar. Sem isso o build não começa | Dono do processo de reembolso / admin do cliente |
| P2 | ID da SR e confirmação de que a usuária é a owner (sem dados pessoais) | Descarta H4 | Consultor |
| P4 | Confirmar que o usuário "Simone*" ativo é a usuária do relato | A comparação do recon pressupõe isso | Consultor / admin |
| P6 | Desde quando acontece e se a usuária é nova ou mudou de área | Reforça H1 (pessoa nunca incluída nos APs) | Consultor |
| P7 (nova) | O Contact da usuária tem `AprovadorReembolso__c` preenchido? | Descarta H2. Sem isso, a correção de H1 pode só trocar um erro por outro | Admin do cliente |

Pré-condição mínima para liberar o build: **P1 + P5**, e P3 se o erro foi em produção.

## 8. Critérios de aceite (versão com metadata confirmada)

- Dado um usuário incluído no critério de entrada do AP `<P5>`, quando ele envia uma SR própria,
  então `Status__c` = Pendente, `Status_de_Aprovacao_e_Etapas__c` = "Pendente - Gerente de
  Projetos" ou "Pendente - Gestor", e é criado um `ProcessInstance` sem erro.
- Regressão: um usuário fora de todos os critérios reproduz o erro na dev antes da correção. Isso
  documenta o mecanismo, que segue valendo para outros usuários até a demanda estrutural da seção 6.
- Os solicitantes já cobertos pelo AP alterado continuam entrando nele com as mesmas etapas
  (diff do XML mostra só 1 critério novo e o `booleanFilter` estendido).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
