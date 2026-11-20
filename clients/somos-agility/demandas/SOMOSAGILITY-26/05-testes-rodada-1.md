**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-26 — Testes na QA (rodada 1)

Org confirmada com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected, instância `agilitynetworks--aw.sandbox`). Deploy `0AfHa00000EM3vFKAT` (Succeeded) conferido em `05-deploy-qa.md`. Os critérios vêm do `01-analise.md` (tamanho alvo, recusa de N+1, dado antigo íntegro, automações sem erro, FLS mantida) aplicados ao design aceito no gate (9 campos novos, G1-b, 32.768).

## Motivo do reprovado

O comportamento central da demanda, o Flow copiando o texto longo do BluePrint para a PSL, **não foi exercitado**. Na QA o Flow existe só como versão 3 em rascunho e não há versão ativa. Pela orientação recebida nesta sessão (não ativar Flow nem mexer em versão ativa), não ativei a v3. Não é defeito do build: falta o passo de ativação na QA, que o design (3.3) prevê como passo separado. Veja a FALHA 1.

## Falhas

### FALHA 1 (crítica) — Cópia BluePrint para PSL (campos novos e antigos) não executada na QA
- Reproduzir: ativar a v3 do Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` na QA, criar BluePrint de teste com `PFP_N_Texto__c` de mais de 255 caracteres e `PFP_N_UNC_Path__c` preenchido, criar PSL na mesma Oportunidade e ler `PFP_N_Texto__c` e `PFP_N__c` da PSL.
- Obtido: nada a comparar. Consulta `Flow` por `Definition.DeveloperName` na QA devolve uma única linha: versão 3, `Draft` (Id 301Ha000016vKY3IAM). Sem versão ativa, nenhum Flow roda ao criar a PSL (PSL de teste criada com 3 campos de 32.768 e sem cópia nenhuma, como esperado para Flow inativo).
- Esperado: PSL recebe o valor do BluePrint nos campos novos (mesmo tamanho) e continua recebendo o antigo (G1-b).
- Causa provável: não há defeito de construção. A ativação na QA não foi feita. O preflight já avisava (Flow sem versão ativa na QA). Para fechar: a esteira ou um humano autoriza ativar a v3 na QA e o QA reexecuta os casos C6 a C9 abaixo. Atenção: a QA tem registros reais (322 BluePrints, 1.475 PSLs); ativar o Flow passa a valer para qualquer PSL salva lá.

## Tabela de casos

| Caso | Critério / passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| C1 | Os 9 campos existem na QA com o tamanho alvo. `FieldDefinition` dos 3 objetos, `QualifiedApiName LIKE 'PFP_%_Texto__c'` | 9 campos LongTextArea 32768 | 9 linhas, todas "Área de texto longo(32768)" (BluePrint, PSL, FVP, 3 cada) | passou |
| C2 | FLS dos 9 campos (agregado). Contagem em `FieldPermissions` para `PFP_%_Texto__c` | linhas de permissão existem para perfis e PS | A consulta com `LIKE` em campo de Id foi rejeitada ("invalid operator on id field"); contagem não obtida. Indiretamente: o usuário de execução (perfil Administrador do sistema) gravou e leu os 9 campos nos 3 objetos (C3, C5, C6) | não executado (contagem); gravação por admin passou |
| C3 | Aceita o tamanho alvo, BluePrint. Apex anônimo: BluePrint de teste com `PFP_1/2/3_Texto__c` de 32.768 caracteres cada | salva e lê 32768 | `RES ok len=32768/32768/32768` | passou |
| C4 | Recusa N+1, BluePrint. Atualiza `PFP_1_Texto__c` com 32.769 caracteres | `STRING_TOO_LONG`, nada gravado | `STRING_TOO_LONG, PFP 1: valor de dados grande demais` | passou |
| C5 | Aceita o tamanho alvo, PSL. PSL de teste com os 3 campos de 32.768 | salva e lê 32768 | `RES ok len=32768/32768` (campos 1 e 3 lidos) | passou |
| C6 | Aceita o tamanho alvo, FVP. FVP de teste ligado à PSL de teste, 3 campos de 32.768 | salva e lê 32768 | `RES ok len=32768/32768` (campos 1 e 3 lidos) | passou |
| C7 | Flow v3 copia texto longo BluePrint para PSL | PSL recebe o texto completo | Flow sem versão ativa na QA | não executado (FALHA 1) |
| C8 | Flow continua copiando UNC antigo para `PFP_N__c` (G1-b) e não sobrescreve valor antigo | Antigo copiado, manual preservado | idem | não executado (FALHA 1) |
| C9 | Fórmulas do FVP (`PFPNUNCPath__c`) seguem mostrando o antigo | Valor antigo visível | depende da cópia do C8 | não executado (FALHA 1) |
| C10 | Dados existentes íntegros. Contagens antes e depois do teste nos objetos | Sem alteração nos registros existentes | PSL 1.475 e BluePrint 322 antes e depois; FVP 0 antes e depois. Os campos novos nascem vazios; o Flow não rodou. Não li nem alterei registro existente | passou (por contagem) |
| C11 | VRs e automações sem erro ao salvar | Sem exceção | Criar Oportunidade, BluePrint, PSL e FVP de teste, com os campos novos preenchidos, passou pelas VRs e automações da QA sem erro (depois de satisfazer as regras de obrigatoriedade da massa). Sem Flow da demanda ativo, a cadeia do Flow não foi coberta | passou, parcial |
| C12 | Layouts mostram os campos novos (16 layouts, 8 deles no deploy) | Campos visíveis abaixo dos antigos | Não verificado pela tela: a abertura do navegador não foi tentada nesta rodada; fica no roteiro do cliente | não executado |

## Dado de teste e limpeza
Criados com `TESTE SOMOSAGILITY-26` no nome (ou ligados a ele): 2 Contas, 2 Contatos, 1 Oportunidade, 1 BluePrint, 1 PSL, 1 FVP. Todos apagados no fim; contagens finais: FVP 0, PSL 1.475, BluePrint 322 (iguais ao início); Contas, Contatos e Oportunidades com prefixo TESTE: 0. Para criar a massa foi preciso preencher na Oportunidade de teste o campo Orçamentista (Contato de teste) e Conversão de Lead = "Não", e usar uma conta com "Agility" no nome para o Autor do BluePrint (filtro de lookup).

## O que pode ter saído da org
Nenhuma chamada externa foi identificada. As automações de Oportunidade da QA rodaram nos registros de teste apagados depois (e-mail ou tarefas, se houver, não foram inspecionados).

## Mudanças no meu usuário de execução
Nenhuma (perfil Administrador do sistema, sem permission set atribuído, sem alteração de campo do usuário).

## Versão de Flow (regra de ativação)
Versão antes: v3 Draft, sem versão ativa. Versão depois: igual (não ativada, por instrução da sessão). Isso é a FALHA 1.

## Sem prova
- Cópia pelo Flow (C7 a C9) e fórmulas do FVP.
- Layouts pela tela (C12) e FLS para usuário não admin.
- Contagem de `FieldPermissions` na QA (consulta precisa filtrar por `Field` com lista explícita, não `LIKE`).
- Premissas P1 a P5 e G5 (relatórios, Conga/SDocs, SnapERP) seguem para a homologação.
