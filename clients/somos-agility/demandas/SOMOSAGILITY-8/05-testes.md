**Veredito:** aprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-8 — Testes na QA (DEPV: ajuste no fluxo de aprovação)

Org conectada confirmada com `sf org list`: só `sbx-somos-agility-qa` (Sandbox, Connected). Todos os comandos com `--target-org`. Dados de teste sintéticos, marcados `TESTE SOMOSAGILITY-8` na Justificativa. Nenhum dado real lido. Não houve fixture do cliente (`fixtures/` não existe).

## Falhas

Nenhuma falha encontrada. Limite declarado: o envio real dos e-mails das 3 notificações **não foi exercitado** (casos C13 e C14), porque o processo novo `Qualificacao_DEPV_v7_7` chega à QA inativo e ativá-lo desativaria a v7_6 em uso; a regra do QA só autoriza ativar a versão de Flow, não de processo de aprovação. Essa prova fica no roteiro do cliente (Testes 4 a 6), depois da ativação, que é passo separado. Não é falha de construção; é prova que depende de uma decisão de ativação.

## Pacote e ativação

- `05-deploy-qa.md` existe (deploy `0AfHa00000EN95lKAD`, Succeeded). Conferido na QA: 3 alerts `DEPV_Notificacao_1a_2a_Aprovacao`, `DEPV_Notificacao_3a_Aprovacao`, `DEPV_Notificacao_Final_Aprovada` (cada um com template próprio); Flow existe; v7_7 existe; regra do Soto existe.
- **Flow `DEPV_BeforeSave_ClassificacaoGerencialObrigatoria`:** antes do teste, v1 `Draft` (sem versão ativa). Implantado só esse Flow com `<status>Active</status>`, a partir de cópia temporária fora do repositório (deploy `0AfHa00000EN94AKAT`, Succeeded), sem alterar o conteúdo. Depois: v1 `Active` (Tooling `Flow`). **Fica ativo ao final.**
- Nenhuma alteração no meu usuário (sem permission set, sem campo, sem Marketing User): nada a devolver.

## Casos

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | RN1 negativo | DEPV de teste em `Pendente - Operações`, sem Classificação; update para `Aprovado` | Bloqueia com a mensagem | Erro "Preencha a Classificação Gerencial antes de aprovar." | passou |
| C2 | RN1 feliz | Outra DEPV em `Pendente - Operações`; update para `Aprovado` com Classificação "Despesas Agility" | Passa | Update com sucesso | passou |
| C3 | RN1 rejeição não bloqueada | DEPV em `Pendente - Operações` sem Classificação; update para `Rejeitado` | Passa | Update com sucesso | passou |
| C4 | RN1 etapa 1 e 2 não bloqueadas | DEPV em `Pendente - Sales Op.` sem Classificação avança para `Pendente - CEO`; outra em `Pendente - CEO` avança para `Pendente - Operações` | Passam | Updates com sucesso (a 2ª DEPV avançou com o campo vazio) | passou |
| C5 | RN1 pelo botão de aprovação real | DEPV de teste submetida ao processo ativo (v7_6) via `Approval.process`; aprovadas as etapas 1 e 2; na etapa 3, `Approve` sem Classificação | Aprovação bloqueada, DEPV continua pendente | `DmlException ... FIELD_CUSTOM_VALIDATION_EXCEPTION, Preencha a Classificação Gerencial antes de aprovar.: [Classificacao_Gerencial__c]`; ainda 1 item de aprovação pendente | passou |
| C6 | RN1 feliz pelo processo real | Mesma DEPV; preenchida Classificação "Despesas Agility"; `Approve` da etapa 3 | Aprova | `Approved`; `ProcessInstance.Status` = Approved | passou |
| C7 | Regra antiga desativada | Retrieve da `Checa_Classificacao_Gerencial_se_Soto` da QA | `active=false` | `<active>false</active>` | passou |
| C8 | Processo v7_6 intacta, v7_7 inativa | Retrieve dos 2 processos da QA | v7_6 `active=true`; v7_7 `active=false` | v7_6 true; v7_7 false | passou |
| C9 | RN2/RN3/RN4 ligações do processo | Retrieve da v7_7 na QA | Alert 1ª/2ª na submissão e aprovação da etapa 1; alert 3ª na aprovação da etapa 2; alert final nas ações finais | `DEPV_Notificacao_1a_2a_Aprovacao` (2 ações), `DEPV_Notificacao_3a_Aprovacao`, `DEPV_Notificacao_Final_Aprovada` presentes | passou |
| C10 | RN2/RN3/RN4 conteúdo | `renderStoredEmailTemplate` dos 3 templates contra DEPV de teste (sem enviar) | Renderiza, sem merge field pendente, com link | 1ª/2ª: 4281 caracteres, 3ª: 4799, final: 3046; nenhum `{!` sobrando; assuntos "Solicitação de Nova Despesa..." / "...Aprovada"; link do registro presente (`/a2C...`) no corpo da 3ª. 3ª contém "Coment", aviso a Operações e "Classifica"; final contém "Coment" | passou |
| C11 | Volume | Não executado em lote | n/a | O Flow é before-save, sem SOQL/DML (design, seção 5); aprovação é registro a registro | não executado (sem risco identificado) |
| C12 | Interação com as 24 automações de Oportunidade (assessment) | Fora do escopo: o Flow é só em DEPV e não toca Oportunidade; o objeto não tinha outra automação ativa (design, seção 4) | n/a | Não exercitado | não aplicável |
| C13 | Envio real dos e-mails (RN2, RN3, RN4) e `{!ApprovalRequest.Comments}` na 3ª | Exigiria ativar a v7_7 e desativar a v7_6 | E-mails saem com o template certo e Comentários preenchido | `EmailMessage` na QA: 0 antes e 0 depois. Nada enviado | não executado |
| C14 | Mensagem na tela do Lightning | `qa_browser` não usado: a DEPV de teste exigiria percorrer as etapas pela UI com aprovadores de outros usuários | Erro no campo | O erro com campo e texto foi provado por API (C1, C5) | não executado |

## O que pode ter saído da org

- 6 DEPVs de teste criadas (5 de gravação direta, C1 a C4, e 1 submetida ao processo, C5 e C6). Todas apagadas; contagem de DEPVs na QA: 51 antes, 51 depois. Nenhum registro real foi lido ou alterado.
- A submissão usou o processo ativo v7_6, que dispara o alert de aprovação final. `EmailMessage` na QA permaneceu em 0 (alerts de workflow não geram `EmailMessage`, e os usuários da sandbox têm e-mail `.invalid`). Não há resultado de entrega para registrar.
- Nenhum job agendado, nenhum permission set, nenhum outro usuário alterado. Arquivos temporários só em `/tmp`.
- Fica ativa na QA a v1 do Flow da demanda (decisão de regra da esteira).

## Pendências para a homologação

1. Ativar a v7_7 (e desativar a v7_6) na QA ou em produção é passo separado; só então os Testes 4 a 6 do roteiro podem ser feitos.
2. Etapa financeira = etapa 3 continua premissa do design (D1) sem resposta no card; o texto da mensagem de erro é do cliente aprovar.
3. A lista Agility GOV está com e-mail de teste na QA; o endereço real entra só em produção, à mão.
