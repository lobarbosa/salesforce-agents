**Resultado do build:** concluído

# Plano de build — SOMOSAGILITY-17

Org de build: `sbx-somos-agility-dev`. Branch `feature/SOMOSAGILITY-17`. Só configuração (Approval Process); sem Flow, Apex ou mudança de modelo de dados.

## Componentes

| Ação | Tipo | API name | Descrição |
|---|---|---|---|
| Criado | ApprovalProcess | `JOB_de_Solicita_o_de_Investimento__c.JOB_Investimento_Cyber` (label "JOB de Investimento - Cyber") | Entrada `CreatedBy = Grupo Cyber Salesforce` AND `Status_da_Qualificaco__c != Aprovado`, `processOrder` 2. Passos: `Aprovacao_Gustavo` (rejeição final, padrão do 1º passo), `Aprovacao_Wanderley` e `Aprovacao_Walmor` (`RejectRequest`). Demais atributos, ações e template iguais ao processo geral. |
| Alterado | ApprovalProcess | `JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento` | Só `processOrder` 2 para 3. Passos, critérios e ações intactos. |
| Reaproveitados sem alteração | WorkflowFieldUpdate / WorkflowAlert / EmailTemplate | conforme design | Referenciados pelo novo processo. |

Arquivos: `force-app/main/default/approvalProcesses/` (o do processo geral foi recuperado da dev antes de editar).

## Versões e ativação

- O processo geral já existia e está ativo; o único atributo alterado é `processOrder` (não há versão paralela de Approval Process, e o design aprovou essa mudança).
- Primeiro deploy do novo processo na dev com `active=false` (validação da definição antes da primeira ativação, R6); depois `active=true` na dev. O arquivo no repositório está `active=true`, para a QA receber o processo já ativo.
- A ativação trava os passos e o `rejectBehavior` (R4). Se a homologação mudar a regra de rejeição, é preciso criar processo novo, não editar este.

## Evidências na dev

- Deploy com `-l NoTestRun` (sandbox). `deploy validate` com testes locais da org falhou só por testes Apex preexistentes e sem relação (cobertura 21%, testes quebrados por validações); o componente em si passou depois do ajuste do aprovador.
- Releitura da org após o deploy: `Aprova_o_JOB` ordem 1; `JOB_Investimento_Cyber` ordem 2 e ativo; `JOB_de_solicitacoes_de_investimento` ordem 3 e ativo.

## Achados do build (atenção de release e verificação)

1. **R1 se confirmou em parte.** O deploy do novo processo junto com a mudança de ordem do geral, ainda com o novo inativo, deixou o Cyber em 3 e o geral em 2. Só depois de ambos ativos, num segundo deploy dos dois arquivos juntos, a ordem ficou 2 e 3. Na QA: implantar os dois arquivos no mesmo deploy e reler `processOrder` depois; se divergir, redeploy dos dois ou Setup › Approval Processes › Reorder (passo manual no release).
2. **Aprovador Gustavo, username ambíguo.** Há dois usuários com o nome "Gustavo Fernandes Eduardo" na dev: um ativo (papel `Coordenador_de_Suporte_DC_C_SEG_MS`, o mesmo do usuário Cyber) com username terminando em `.com.br1` antes do sufixo de sandbox, e um inativo com username sem o `1`. O XML usa o username do ativo (`...com.br1`). O deploy de `.com.br` simples foi recusado por apontar o inativo. **Confirmar com o cliente/consultor que em produção o username ativo também termina em `br1`**; senão o `deploy validate` na QA e o release vão falhar nesse passo (R3).
3. **Wanderley e Walmor**: um usuário ativo cada, sem ambiguidade.
4. O retrieve remove o sufixo de sandbox dos usernames; o XML do repositório guarda o username sem sufixo, e a Metadata API converte. Nenhum username está neste `.md`.

## Pendências herdadas do design (não são do build)

- R2: aprovações já pendentes de JOBs do Cyber seguem o caminho antigo; decisão do cliente antes do release.
- R4: regra de rejeição assumida, a confirmar na homologação.
- R5: documentar na entrega que desativar o novo processo devolve o Cyber ao caminho antigo.
- QA: conferir `Status_da_Qualificaco__c` e `Status_Previs_o_de_Gastos__c` após cada aprovação (Flow before-save no mesmo objeto); a dev tem 0 registros do objeto.

## Correções da rodada 1

- **FALHA 1 (processOrder invertido na QA): não corrigível pelo repositório; exige passo manual na QA.** Reconferi a dev (retrieve em projeto temporário): `Aprova_o_JOB`=1, `JOB_Investimento_Cyber`=2, `JOB_de_solicitacoes_de_investimento`=3, os dois últimos ativos. O `force-app` também traz 2 e 3. O XML está certo; a divergência é de como a Metadata API aplica `processOrder` em processo já ativo (R1, achado 1 acima). O builder não toca a QA nem muda a ordem do arquivo-fonte para contornar o deploy.
  - **Ação necessária (esteira/release, fora do build):** na `sbx-somos-agility-qa`, ou redeployar os dois arquivos de approvalProcesses juntos e reler `processOrder`, ou reordenar em Setup › Approval Processes › Reorder (Cyber antes do geral). Reler `processOrder` na QA até dar 1, 2, 3 antes de retestar T1 e T6.
  - **Release/produção:** mesmo passo manual, com conferência de `processOrder` depois do deploy.
- Nenhuma outra falha na rodada. T7 a T11 seguem como exceção do responsável (03-design.md, decisão de 2026-11-23) para o cliente na homologação.
- Pendência de usuário duplicado (Gustavo): conferir o username do aprovador do passo 1 na QA antes do release (achado 2 acima).
