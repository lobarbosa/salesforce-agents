**Verificação:** aprovada
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-26 — Verificação do build

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected, pelo alias). QA e produção não foram tocadas. Nada foi implantado; nenhum arquivo do build foi alterado.

Nota sobre os critérios: o `01-analise.md` descreve o problema original (campos do "Cenário SF", Gherkin com `<N>` pendentes). O design aceito no gate (G1-b, G3 = 32.768) redefiniu a solução para 9 campos novos `PFP_N_Texto__c`. Derivei os casos do espírito dos critérios (aceita o tamanho alvo, recusa N+1, dado antigo íntegro, automações/VRs sem erro, FLS mantida) aplicados ao que o plano construiu.

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Campos existem com tamanho alvo | Tooling `CustomField` (`DeveloperName LIKE 'PFP_%_Texto'`) | 9 campos (3 em BluePrint__c, Propostas_de_Solucao__c, FluxoVendaProdutos__c), Length 32768, descrição preenchida | 9 registros, todos Length 32768, descrição preenchida | passou |
| C2 | Layouts | Retrieve dos layouts dos 3 objetos da dev, contagem de `<field>PFP_N_Texto__c` | 16 layouts, 48 itens (BP 1x3, PSL 10x3, FVP 5x3) | BP 1 layout/3 itens, PSL 10/30, FVP 5/15 = 16 layouts, 48 itens | passou |
| C3 | FLS mantida / espelhada | `FieldPermissions` com `Field IN (9 campos)` | 573 linhas; FVP com edição só para quem edita o objeto | 573 linhas. Edição: PSL 201, BluePrint 174, FVP 66 (FVP menor que leitura, coerente com o plano) | passou |
| C4 | Flow v3 existe e aponta para os campos novos | Tooling `Flow` + `Metadata` da v3 (Id 301Ha000016vCwQIAU) | v3 Draft; decisões testam `$Record.PFP_N_Texto__c` vazio; recordUpdates gravam `PFP_N_Texto__c` e `PFP_N__c` | v1 Obsolete, v2 Active, v3 Draft; 11 decisões testam `PFP_N_Texto__c` IsNull; 7 recordUpdates gravam `PFP_N_Texto__c` e `PFP_N__c` | passou |
| C5 | Referência com v2 ativa | Massa sintética; inserir PSL com v2 ativa | Copia só os campos antigos | `PFP_N__c` preenchidos (8 caracteres), `PFP_N_Texto__c` nulos | passou (baseline) |
| C6 | Texto > 255 copiado BluePrint → PSL | Ativei a v3 (autorizado no plano), atualizei a PSL existente; BluePrint com `PFP_1_Texto__c` de 618 caracteres | PSL recebe 618 caracteres | `PFP_1_Texto__c` da PSL = 618; `PFP_2/3_Texto__c` = 15 (iguais ao BluePrint) | passou |
| C7 | Dado antigo continua copiado | Mesma PSL | `PFP_N__c` continua recebendo o UNC antigo | `PFP_1/2/3__c` = valor antigo do BluePrint (8 caracteres) | passou |
| C8 | Não sobrescreve valor antigo já digitado; PSL nova | Inserir PSL nova com `PFP_1__c='MANUAL'` com v3 ativa | `PFP_1__c` permanece `MANUAL`; textos novos copiados | `PFP_1__c='MANUAL'`; `PFP_1_Texto__c`=618, `PFP_2_Texto__c`=15; `PFP_2__c` copiado (8) | passou |
| C9 | Aceita o tamanho alvo (FVP, editável) | Inserir FVP com `PFP_1_Texto__c` de 32.768 caracteres | Salva sem erro, lido de volta com 32.768 | Salvou; leitura = 32768 | passou |
| C10 | Recusa N+1 | Atualizar FVP com `PFP_2_Texto__c` de 32.769 caracteres | `STRING_TOO_LONG`, nada gravado | `STRING_TOO_LONG, PFP 2: valor de dados muito grande` | passou |
| C11 | Fórmulas do FVP continuam funcionando | Leitura de `PFP1UNCPath__c` no FVP | Continua mostrando o valor | 8 caracteres (valor antigo) | passou |
| C12 | VRs/automações sem erro | Inserts/updates de Opportunity, BluePrint, PSL, FVP com v3 ativa | Sem exceção das VRs ou do Flow | Nenhuma exceção nas operações acima | passou |
| C13 | Dados existentes íntegros | Contagem prévia nos 3 objetos | n/a | Os 3 objetos tinham 0 registros na dev; não há dado antigo para comparar | não executado (sem massa pré-existente) |

## Dados de teste (todos sintéticos, `TESTE SOMOSAGILITY-26`)
- Criei: Account (nome com "Agility", exigido pelo filtro do lookup Autor__c do BluePrint), Contact (telefone sintético `(00) 00000-0000`, exigido por VR), Opportunity, BluePrint, 2 PSL, 1 FVP. Campo Orçamentista da Oportunidade preenchido após a criação (VR PslSemOrcamentista).
- Limpeza: tudo apagado; contagens finais de `TESTE SOMOSAGILITY-26` em Opportunity e Account = 0 e os 3 objetos da demanda voltaram a 0 registros.
- Usuário de execução, perfil e permission sets: nada alterado.
- Fixture: não havia `fixtures/` do cliente. O script que funcionou não foi gravado como fixture; os passos acima o descrevem.

## O que pode ter saído da org
Não identifiquei chamada externa; não inspecionei o log das automações das 3 entidades. Nenhum registro de integração foi consultado. Os registros de teste foram todos apagados.

## Estado deixado na dev
- **Flow v3 está Active** (ativei via Tooling API `FlowDefinition.activeVersionNumber=3`, autorizado no plano). A v2 passou a Obsolete. Para desfazer: reativar a v2. Mantive a v3 ativa porque é a versão que o PR leva; se a esteira preferir a dev como estava, reative a v2.

## Observações para o revisor (não são falha)
1. O plano diz que o Layout de BluePrint tem o antigo `PFP_1_UNC_Path__c` como Required e o novo entrou como Edit (desvio declarado no plano). Não testei o comportamento da obrigatoriedade.
2. A descrição dos campos novos cita "Flow ... (v2)", enquanto a versão nova é a v3. Detalhe de texto.
3. Limitação herdada do Flow, declarada no plano: PSL com Texto novo preenchido e antigo vazio não recebe a cópia do antigo. Não exercitei.

## Sem prova
- C13: sem registro anterior na dev; integridade de dados existentes só dá para provar na QA/homologação.
- Paridade com a QA (R6): `deploy validate` contra a QA fica para o CI do PR.
- Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP): seguem para a homologação.
- Comportamento por perfil (FLS efetiva para um usuário não-admin): conferi apenas as linhas de `FieldPermissions`, sem login como outro usuário.
