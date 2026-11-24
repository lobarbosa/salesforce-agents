**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-8 — Verificação do build

Org confirmada com `sf org list` (só `sbx-somos-agility-dev`, conectada). Todos os comandos com `--target-org`. Dados de teste sintéticos, marcados `TESTE SOMOSAGILITY-8` na Justificativa (o Name da DEPV é autonumeração e não gravável). Nenhum dado real lido. Não houve fixture do cliente (`fixtures/` não existe); não foi gravada nenhuma porque a criação mínima passou direto (só `Status_da_Qualificacao__c` é obrigatório).

## Resumo

- RN1 (Flow): exercitado e passou nos 5 casos. O erro, o campo e o texto bateram com o design.
- RN2/RN3/RN4 (metadata): processo `Qualificacao_DEPV_v7_7` inativo, ações apontam para os alerts certos, v7_6 ativa e intacta. Passou.
- Sem prova: envio real dos e-mails (exige ativar a v7_7, o que está fora do meu escopo), `{!ApprovalRequest.Comments}` na 3ª notificação, a mensagem na tela do Lightning e a aprovação pelo botão do processo (só a gravação de campo foi exercitada). Por isso `inconclusiva`. Não há falha encontrada.

## Casos

Cada caso de Flow rodou em uma execução de Apex anônimo própria (criação do registro em uma execução, atualização em outra, uma por vez).

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | RN1 negativo | DEPV de teste em `Pendente - Operações`, sem Classificação; update para `Status_da_Qualificacao__c = Aprovado` | Bloqueia com a mensagem do design | `FIELD_CUSTOM_VALIDATION_EXCEPTION`, mensagem "Preencha a Classificação Gerencial antes de aprovar.", campo `Classificacao_Gerencial__c` | passou |
| C2 | RN1 feliz | Outra DEPV em `Pendente - Operações`; update para `Aprovado` com `Classificacao_Gerencial__c = Despesas Agility` | Passa | Update OK | passou |
| C3 | RN1 rejeição não bloqueada | DEPV em `Pendente - Operações` sem Classificação; update para `Rejeitado` | Passa | Update OK | passou |
| C4 | RN1 etapa 1 não bloqueada | DEPV em `Pendente - Sales Op.` sem Classificação; avança para `Pendente - CEO` | Passa | Update OK | passou |
| C5 | RN1 etapa 2 não bloqueada | DEPV em `Pendente - CEO` sem Classificação; avança para `Pendente - Operações` | Passa | Update OK | passou |
| C6 | RN1 estado do Flow | Consulta Tooling `Flow` | Versão ativa | v1, `Active` (o arquivo do repositório está `Draft`, como o build avisou) | passou |
| C7 | RN2/RN3/RN4 processo | `sf project retrieve` do `Qualificacao_DEPV_v7_7` e da v7_6 direto da dev, comparação das ações | v7_7 inativa; alert 1ª/2ª na submissão e na aprovação da etapa 1; alert 3ª na aprovação da etapa 2; alert final nas ações finais | `active=false`; ações conforme esperado (`DEPV_Notificacao_1a_2a_Aprovacao` x2, `DEPV_Notificacao_3a_Aprovacao`, `DEPV_Notificacao_Final_Aprovada`); `emailTemplate` da v7_7 aponta para a 1ª/2ª | passou |
| C8 | v7_6 intacta | Diff v7_6 x v7_7 na org e `git diff main` na pasta `force-app` | v7_6 ativa e sem alteração | v7_6 `active=true`; nenhum arquivo da v7_6 no diff do branch; diferenças da v7_7 são só os alerts novos, o template e a ordem das ações | passou |
| C9 | RN2/RN3/RN4 alerts e templates | Consulta Tooling `WorkflowAlert` e retrieve do workflow | 3 alerts apontando para os 3 templates; destinatários conforme o build | 3 alerts presentes, cada um com `TemplateId` próprio; 1ª/2ª: Wanderley + cc de teste `.invalid`; 3ª: Operações, Kelly, Walmor, Wanderley + cc de teste; final: owner, Operações, Sales Operations, Walmor (igual ao alert antigo) | passou |
| C10 | RN2/RN3/RN4 conteúdo | `Messaging.renderStoredEmailTemplate` dos 3 templates contra uma DEPV de teste (sem enviar) | Renderiza sem erro e sem merge field pendente | Os 3 renderizam (HTML de 4286, 4804 e 3046 caracteres), sem `{!` sobrando, com link | passou |
| C11 | Regra do Soto desativada | Consulta Tooling `ValidationRule` | `Active=false` | `false` | passou |
| C12 | Envio real dos e-mails | Não executado | e-mails saem com o template certo | Exigiria ativar a v7_7 e desativar a v7_6 na dev; ativação é passo separado e fica fora desta etapa | não executado |
| C13 | `{!ApprovalRequest.Comments}` na 3ª | Não executado | Comentário aparece | A renderização fora de um pedido de aprovação não resolve esse campo, então C10 não prova isto | não executado |
| C14 | Mensagem do Flow na tela do Lightning | Não executado (qa_browser não usado: exigiria sessão de UI e a regra de dados) | Erro aparece no campo | Só provado o erro de DML com o campo `Classificacao_Gerencial__c` (C1) | não executado |
| C15 | Aprovação real pelo processo (botão Aprovar) | Não executado | Flow dispara na aprovação | O Flow foi exercitado por gravação direta dos campos que o processo grava (`Status_da_Qualificacao__c`); o spike do builder cobriu o `approve` | não executado |

## Pendências do builder

- **Etapa financeira = etapa 3** (`Qualificacao_Operacoes_Financeiro`, aprovador funcional de Operações): consistente com a metadata (C7). Que seja a etapa do Diretor Financeiro continua premissa do design, sem resposta no card. Trocar só mexe na `filterFormula` do Flow.
- **Texto do erro:** confirmado como está no Flow (C1); a aprovação do texto é do cliente.
- **Destinatários por nome:** confirmado que os usuários existem e estão nos alerts (C9); se os nomes do anexo são esses mesmos continua dependendo do cliente.
- **Lista do anexo na notificação final:** o alert final mantém os destinatários de hoje (C9) e a lista Kelly/Walmor/Wanderley/Operações/Agility GOV está na 3ª notificação, conforme D2. A divergência com o anexo segue aberta com o cliente.

## Riscos do design

- R1 a R4 não foram reavaliados além do que está acima. O endereço da lista Agility GOV é de teste (`.invalid`), então nenhum e-mail saiu para a lista real; confirmado no alert (C9).

## O que pode ter saído da org

Nada. Nenhuma DEPV foi submetida a aprovação, a v7_7 não foi ativada e `EmailMessage` de hoje tem 0 registros. Os alerts do processo ativo (v7_6) só disparam por submissão ou aprovação, que não aconteceram.

## Limpeza

- Criei 5 DEPVs de teste (C1 a C5) e apaguei as 5. Contagem final de DEPVs na dev: 0 (era 0 antes).
- Nenhuma alteração de usuário, permission set ou opção de usuário; nada a devolver.
- Nenhum job agendado criado por mim. Nada de Flow ou processo foi ativado ou desativado.
- Arquivos temporários só em `/tmp`.

## O que uma pessoa precisa fazer para fechar a prova

1. Na dev (ou na QA, depois do deploy da esteira), ativar a `Qualificacao_DEPV_v7_7` e desativar a v7_6, submeter uma DEPV de teste e conferir o log de e-mail das três notificações e o conteúdo de `{!ApprovalRequest.Comments}` na 3ª.
2. Aprovar a etapa 3 pela tela do Lightning sem Classificação Gerencial e confirmar que o erro aparece no campo.
3. Lembrar que o Flow chega à QA como Draft e precisa de ativação própria.
