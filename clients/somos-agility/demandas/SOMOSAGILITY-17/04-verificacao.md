**Verificação:** inconclusiva

**Org de teste:** `sbx-somos-agility-dev`

# Verificação — SOMOSAGILITY-17

Org confirmada com `sf org list`: só `sbx-somos-agility-dev` conectada (Sandbox, Connected). Nada foi feito na QA nem em produção. Nenhuma alteração em usuário, permission set ou dado. Nenhum registro de teste foi criado, então não há o que apagar. O retrieve foi feito em projeto temporário em `/tmp`, fora do repositório.

## Resumo
A configuração do Approval Process está correta na dev e na ordem certa. O comportamento (sequência Gustavo, Wanderley, Walmor na prática) **não foi exercitado**. Por isso o veredito é inconclusiva.

## Por que não deu para exercitar
- O critério de entrada é `CreatedBy = Grupo Cyber Salesforce`. Só um registro criado por esse usuário entra no processo. O verificador não pode criar registros em nome dele: gravar `CreatedById` exigiria permissão "Set Audit Fields" ou mudar perfil/permissão do usuário de execução, e isso não está entre as exceções autorizadas.
- Não é possível agir como Gustavo, Wanderley ou Walmor para aprovar etapa por etapa, nem como o usuário Cyber.
- O objeto `JOB_de_Solicita_o_de_Investimento__c` tem 0 registros na dev (COUNT agregado). Não há massa existente, e não se usa dado real.

## Evidência de configuração (metadata lida da dev)
Comando: `sf project retrieve start --target-org sbx-somos-agility-dev -m "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.*"`, em projeto temporário, com leitura de campos específicos do XML.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Cenário 3 (outro criador não afetado): ordem | Leitura de `processOrder` de cada processo | `Aprova_o_JOB`=1, Cyber=2, geral=3 | `Aprova_o_JOB`=1, `JOB_Investimento_Cyber`=2, `JOB_de_solicitacoes_de_investimento`=3 | passou (configuração) |
| C2 | Cenário 1: processo Cyber ativo e com entrada correta | Leitura de `active` e `entryCriteria` | ativo; `CreatedBy equals Grupo Cyber Salesforce` e `Status_da_Qualificaco__c notEqual Aprovado` | `active=true`; os dois critérios exatamente assim | passou (configuração) |
| C3 | Cenário 1: sequência dos aprovadores | Leitura dos passos em ordem | Gustavo, Wanderley, Walmor | `Aprovacao_Gustavo`, `Aprovacao_Wanderley`, `Aprovacao_Walmor`, nessa ordem, um aprovador user cada. Wanderley e Walmor com `RejectRequest` | passou (configuração) |
| C4 | Cenário 1: aprovação final só após Walmor | Leitura das ações finais | Ações de aprovação final depois do último passo | Ações `Aprova_o_de_JOB`, `Status_Qualificacao_Aprovacao`, `Status_Qualificacao_Rejeicao`, `Rejei_o_de_JOB`, `Status_Qualificacao` e `Status_Qualificacao_Recall` presentes no processo. Efeito real não executado | não executado |
| C5 | Cenário 1: submissão pelo usuário Cyber, primeiro aprovador Gustavo | Submeter registro criado pelo usuário Cyber | Aprovador pendente = Gustavo | Não há como criar registro como usuário Cyber | não executado |
| C6 | Cenário 2: aprovador fora de ordem | Wanderley ou Walmor agirem antes de Gustavo | Ação bloqueada ou não pendente para eles | Não há como agir como esses usuários. Pelo desenho de passos sequenciais, só o aprovador do passo atual recebe a tarefa, mas isso não foi testado | não executado |
| C7 | Cenário 3: criador diferente segue o caminho vigente | Submeter registro de outro criador | Processo vigente inalterado | Não executado. Por metadata, `Aprova_o_JOB` (ordem 1) tem entrada por `CreatedBy = Fabio Soto` e o geral não foi alterado além de `processOrder` | não executado |

## Pendência dos dois "Gustavo Fernandes Eduardo"
Conferido só por contagem agregada: 2 usuários com esse nome (1 ativo, 1 inativo). O passo de aprovação usa o username que termina em `br1`. Consulta por contagem: 0 usuários ativos com o username sem o `1` e 1 usuário ativo com o username com `1`. Ou seja, o passo aponta para o usuário ativo. Isso não impede o teste. Na QA e em produção a ambiguidade de nome pode existir; o username precisa ser conferido ali antes do release (o plano já registra o ajuste).

## Observações que não são falha
- O processo geral `JOB_de_solicitacoes_de_investimento` mantém "Grupo Cyber Salesforce" na entrada do passo 1 (Diretor Pós-vendas). Com o novo processo ativo e na frente (ordem 2), Cyber com status diferente de Aprovado cai no novo processo. O geral fica como alternativa se o novo for desativado (R5 do design).
- Outros processos inativos na dev (`JOBSolicitacaoInvestimento*`, `JOB_de_solicitacoes_de_investimentos`) mostram `processOrder` 1 ou 2, mas estão inativos e não competem na ordenação.
- Risco R1 (ordem pode divergir após deploy conjunto) continua valendo para a QA: reler `processOrder` depois do deploy.

## O que ficou sem prova e o que uma pessoa precisa fazer
Uma pessoa autenticada como o usuário "Grupo Cyber Salesforce" (ou com "Set Audit Fields" na dev, decisão do time) deve:
1. Criar um registro de teste `TESTE SOMOSAGILITY-17` do objeto `JOB_de_Solicita_o_de_Investimento__c` e submetê-lo.
2. Conferir que o primeiro aprovador pendente é Gustavo, e depois Wanderley e Walmor, e que o status só vira Aprovado após Walmor.
3. Conferir que Wanderley e Walmor não têm tarefa pendente antes da vez deles.
4. Submeter um registro criado por outro usuário (por exemplo, o de entrada do `Aprova_o_JOB`) e conferir que o caminho não mudou.
5. Conferir `Status_da_Qualificaco__c` e `Status_Previs_o_de_Gastos__c` depois de cada aprovação (Flow before-save no mesmo objeto).
