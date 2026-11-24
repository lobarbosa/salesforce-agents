**Resultado do build:** concluído

# SOMOSAGILITY-8 — Plano de build (DEPV, ajuste no fluxo de aprovação)

- **Org de build:** `sbx-somos-agility-dev` (confirmada com `sf org list`). Branch `feature/SOMOSAGILITY-8`.
- **Decisão do design:** declarativo. Nenhum Apex foi escrito.

## Spike do RN1 (Flow x approve): verde

Rodado na dev com um registro de teste criado e desfeito (rollback) por anonymous Apex, aprovando como o usuário da sessão. Nenhum dado real.

| Pergunta | Cenário | Resultado |
|---|---|---|
| (a) O Flow dispara no approve da etapa 3? | Aprovar etapa 3 sem Classificação Gerencial | Sim |
| (b) Impede a aprovação? | idem | Sim: `FIELD_CUSTOM_VALIDATION_EXCEPTION, Preencha a Classificação Gerencial antes de aprovar.`; a DEPV continua em `Pendente - Operações` |
| Caminho feliz | Preencher o campo e aprovar a etapa 3 | Aprovada, `Status_da_Qualificacao__c = Aprovado` |
| Não regressão | Rejeitar a etapa 3 sem o campo | Rejeitada, não bloqueia |
| Não regressão | Aprovar etapas 1 e 2 sem o campo | Passam |
| (c) O aprovador vê a mensagem na tela do Lightning? | não exercitado: Apex não renderiza a UI | **Fica para a verificação/QA** (erro de campo em `Classificacao_Gerencial__c`) |

Condição final do Flow: saída da etapa `Pendente - Operações` com campo vazio, quando `Status_da_Qualificacao__c` vira `Aprovado` ou `Status__c` vira `Fechado` sem ser rejeição. Cobre as duas gravações do design.

## Componentes criados

| Tipo | API name | Descrição |
|---|---|---|
| Flow record-triggered before-save (update) | `DEPV_BeforeSave_ClassificacaoGerencialObrigatoria` | RN1. Critério de entrada na própria `filterFormula`. Custom Error no campo. Sem DML nem SOQL. |
| EmailTemplate Classic HTML | `Despesa_Extraordinaria_de_Pre_Venda/DEPV_Notificacao_1a_2a_Aprovacao` | Layout 1ª/2ª do anexo (ID, Proprietário, Oportunidade, justificativa, recuperação, 3 valores, link). Sem o bloco "Atenção CEO". |
| EmailTemplate Classic HTML | `Despesa_Extraordinaria_de_Pre_Venda/DEPV_Notificacao_3a_Aprovacao` | Layout 3ª do anexo, com `{!ApprovalRequest.Comments}` e bloco "Atenção Grupo Operações". |
| EmailTemplate Classic HTML | `Despesa_Extraordinaria_de_Pre_Venda/DEPV_Notificacao_Final_Aprovada` | Layout final, saudação "Olá, <criador>,". |
| WorkflowAlert | `DEPV_Notificacao_1a_2a_Aprovacao` | Wanderley + Agility GOV (e-mail de teste). Remetente: o mesmo Org-Wide do alert `..._Aprovada`. |
| WorkflowAlert | `DEPV_Notificacao_3a_Aprovacao` | Operações (aprovador da etapa 3), Kelly, Walmor, Wanderley + Agility GOV (e-mail de teste). |
| WorkflowAlert | `DEPV_Notificacao_Final_Aprovada` | Mesmos destinatários do alert final de hoje (owner + 3 usuários), template novo. |
| ApprovalProcess | `Despesa_Extraordinaria_para_Pre_Venda__c.Qualificacao_DEPV_v7_7` | Cópia da v7_6 **inativa** + `emailTemplate`, alert 1ª/2ª na submissão e na aprovação da etapa 1, alert 3ª na aprovação da etapa 2 (entrada na etapa 3), alert final novo nas ações finais. Steps, aprovadores, critérios e field updates iguais à v7_6. |

Arquivos em `force-app/main/default/`: `flows/`, `email/Despesa_Extraordinaria_de_Pre_Venda/`, `workflows/Despesa_Extraordinaria_para_Pre_Venda__c.workflow-meta.xml` (só os 3 alerts novos, deploy aditivo), `approvalProcesses/`.

## Componente alterado

| Tipo | API name | Alteração |
|---|---|---|
| ValidationRule | `Despesa_Extraordinaria_para_Pre_Venda__c.Checa_Classificacao_Gerencial_se_Soto` | `active=false`. Nunca disparava (recon, seção 5). Reversão: voltar para `true`. |

## Desvios do design (por regra do squad: não editar no lugar o que existe)

- O design previa **alterar** os templates `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda` e `..._Aprovada` e **editar** o processo ativo `v7_6`. Em vez disso, foram criados templates novos e o processo `v7_7` inativo. Os originais, os alerts antigos e a v7_6 ficam intactos, e é a ativação da v7_7 que troca o comportamento. Isso também resolve o risco R6 (deploy em processo ativo) sem precisar de clone depois.
- O alert final antigo (`..._Aprovada`) não foi editado. A v7_7 aponta para o alert novo `DEPV_Notificacao_Final_Aprovada`.

## Versões e ativação (passo separado, não executado)

| Componente | Estado na dev | Para ativar |
|---|---|---|
| Flow `DEPV_BeforeSave_ClassificacaoGerencialObrigatoria` | **Versão 1 ativa na dev**: foi preciso ativar para o spike, é Flow novo e sem versão anterior. O arquivo no repositório está em `Draft`, então o deploy na QA entra como Draft. | Ativar na QA e na produção como passo próprio. |
| ApprovalProcess `Qualificacao_DEPV_v7_7` | Inativo. A v7_6 continua ativa. | Ativar a v7_7 e desativar a v7_6 como passo próprio. DEPVs em andamento seguem na v7_6. Só depois de ativar a v7_7 os e-mails novos passam a sair. |
| ValidationRule do Soto | Desativada na dev (config simples, reversível). | Deploy normal. |

Para testar os e-mails na dev, o verificador precisa ativar a v7_7 (e desativar a v7_6) na dev, ou submeter uma DEPV de teste só depois disso.

## Pontos que dependem de confirmação humana (não impediram o build)

1. **D1** (etapa financeira = etapa 3, `Qualificacao_Operacoes_Financeiro`) e **texto da mensagem de erro** ("Preencha a Classificação Gerencial antes de aprovar.") seguem como premissa do design; não houve resposta no card. Trocar a etapa muda só a `filterFormula` do Flow.
2. **Destinatários (pergunta 6).** Foram resolvidos por nome do anexo contra os usuários ativos da dev: Kelly, Walmor e Wanderley têm um usuário cada; "Operações" é o usuário funcional aprovador da etapa 3. Confirmar que é isso mesmo.
3. **Divergência a validar com o cliente:** no anexo, a lista "Kelly, Walmor, Wanderley, Operações, Agility GOV" está escrita para a **notificação final/aprovada**. O design (D2) a atribuiu à **3ª notificação** (entrada na etapa 3) e manteve o alert final com os destinatários de hoje. Foi seguido o design. Se o cliente quiser a leitura literal do anexo, basta adicionar esses destinatários ao alert `DEPV_Notificacao_Final_Aprovada`.
4. **Pergunta 5:** saudação do e-mail final mantida como `CreatedBy` (como hoje, com vírgula). Trocar por `OwnerFullName` é uma linha.
5. **R5:** `{!ApprovalRequest.Comments}` na 3ª notificação (alert disparado em ação de step) **não foi exercitado**; pode vir vazio. A verificação deve conferir.

## Riscos e pendências para verificação, QA e produção

- **R3/R4: e-mail da lista Agility GOV.** No repositório está um endereço de teste reservado (`agility.gov.teste@example.invalid`), nunca o real, para nenhum e-mail sair para a lista de verdade. O endereço real é passo manual de produção, documentado em `06-entrega.md`. Substituir pela caixa de teste do squad se o QA precisar receber o e-mail.
- **R9:** na dev e na QA, os usernames dos usuários têm sufixo de sandbox e e-mail `.invalid`. Conferir envio pelo log de e-mail, sem captura de registro real.
- **Não exercitado no build:** mensagem do Flow na tela do Lightning (c), envio efetivo dos e-mails e o layout renderizado.
- **Dado de teste:** o spike usou registro temporário revertido por rollback; a dev continua com 0 DEPVs.
- **Deploy do Flow na QA** entra como Draft; sem ativação o RN1 não protege nada lá.
- O usuário da sessão não enxerga `Status__c` por FLS no Apex da dev; o Flow roda em contexto de sistema e não é afetado. Registrado como observação, não como defeito.
