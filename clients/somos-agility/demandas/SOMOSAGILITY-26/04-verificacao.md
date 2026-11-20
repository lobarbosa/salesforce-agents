**Verificação:** aprovada
**Org de teste:** sbx-somos-agility-dev

# SOMOSAGILITY-26 — Verificação do build (dev)

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected). Usuário de execução: perfil Administrador do sistema. Todos os comandos com `--target-org sbx-somos-agility-dev`. QA e produção não tocadas. Nada foi implantado.

Estado da dev no início: 0 registros em BluePrint__c, Propostas_de_Solucao__c e FluxoVendaProdutos__c. Nenhum dado real lido; só metadata, contagens e registros `TESTE SOMOSAGILITY-26`.

Nota de escopo: o critério original do `01-analise.md` fala em "Cenário SF" e cinco campos; o design/build trocou isso por 9 campos novos `PFP_{1,2,3}_Texto__c` em 3 objetos. Os casos abaixo derivam dos critérios de aceite (tamanho alvo, recusa de N+1, dados íntegros, automações e VRs, permissões mantidas) aplicados ao que o design entregou.

## Falhas da rodada de QA anterior (05-testes-rodada-1.md)
- FALHA 1 (cópia BluePrint para PSL não executada porque o Flow estava Draft sem versão ativa na QA): não é defeito de build. Na dev o Flow v3 está **Active** e foi exercitado (V1 a V3 abaixo). A ativação na QA continua dependendo de decisão humana/esteira.
- C2 (contagem de FLS): obtida na dev com lista explícita em `Field`: 573 linhas, igual ao esperado.
- C12 (layouts pela tela): na dev, conferido por retrieve da metadata (V6); a conferência visual fica no roteiro do cliente.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Campos existem com tamanho alvo | `FieldDefinition` (Tooling) dos 3 objetos, `QualifiedApiName LIKE 'PFP_%_Texto__c'` | 9 LongTextArea 32768 | 9 linhas, todas "Área de texto longo(32768)" (BluePrint, PSL, FVP, 3 cada) | passou |
| V2 | Versão do Flow | `SELECT VersionNumber, Status FROM Flow` (Tooling) pelo DeveloperName `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` | v3 existe | v1 Obsolete, v2 Obsolete, **v3 Active**. O plano do builder dizia v2 Active / v3 Draft; a v3 foi ativada depois (passo autorizado no gate). A v2 não foi editada. | passou |
| V3 | Permissões de campo mantidas/espelhadas (FLS) | `COUNT(Id)` em `FieldPermissions` com `Field IN (9 campos)`, e agrupado por campo | 573 linhas | 573. Por campo: BluePrint 58 cada; PSL 67 cada; FVP 66 cada (58x3 + 67x3 + 66x3 = 573). Confere depois do enxugamento dos 68 arquivos. | passou |
| V4 | Tamanho alvo e recusa de N+1 (BluePrint) | Apex anônimo: gravar `PFP_2_Texto__c` com 32.768 caracteres e ler; depois 32.769 | Grava 32768; N+1 recusado, nada gravado | `RES ok 32768`; N+1: `STRING_TOO_LONG ... (max length=32768): [PFP_2_Texto__c]`; depois da recusa o valor continua com 32768 | passou |
| V5 | Flow copia texto longo BluePrint para PSL (G1-b) | Massa em uma execução (Conta, Contato, Oportunidade, BluePrint com `PFP_1/2/3_Texto__c` de 603/303/53 caracteres e `PFP_N_UNC_Path__c` preenchidos). PSL criada em **outra** execução. Leitura em terceira execução | Campos novos da PSL com o texto completo (inclusive acima de 255); `PFP_N__c` recebe o UNC antigo | Textos novos 603/303/53 (completo, idêntico em tamanho); `PFP_2__c` = `\\srv\a2` (UNC antigo copiado) | passou |
| V5b | Valor antigo já digitado não é sobrescrito; campo novo vazio é recopiado | Em PSL existente: `PFP_1_Texto__c`=null e `PFP_1__c`='MANUAL-TESTE', update; leitura | Texto novo recopiado (603); `PFP_1__c` continua 'MANUAL-TESTE'; `PFP_2__c` intacto | `t1=603 p1=MANUAL-TESTE p2=\\srv\a2` | passou |
| V6 | Campos nos layouts (16 layouts, 48 itens) | `sf project retrieve` dos layouts dos 3 objetos para diretório temporário, contagem de `PFP_N_Texto__c` por arquivo | 16 layouts, 48 itens | 16 arquivos, todos com os campos, soma 48 | passou |
| V7 | Aceita tamanho e editável no FVP; fórmulas do FVP seguem mostrando o antigo | FVP de teste ligado à PSL de teste com `PFP_1_Texto__c` de 401 caracteres; leitura de `PFP1UNCPath__c` | Grava 401; fórmula mostra UNC antigo | `RES fvp 401 formula=\\srv\a1` | passou |
| V8 | VRs e automações sem erro ao salvar | Criação de Oportunidade, BluePrint, PSL e FVP de teste com campos novos preenchidos, e updates, passando pelas VRs e automações da dev (Flow v3 ativo) | Sem exceção | Todas as operações concluíram sem erro depois de satisfazer as regras de obrigatoriedade da massa (telefone do Contato, filtro de lookup do Autor, Orçamentista na Oportunidade) | passou |
| V9 | Dados existentes íntegros / limpeza | Contagens antes: 0 nos três objetos. Depois da limpeza: 0 | Nada ficou | BluePrint, PSL, FVP: 0; Account/Opportunity/Contact `TESTE SOMOSAGILITY-26%`: 0 | passou |

## Dados de teste
Criados e apagados (todos `TESTE SOMOSAGILITY-26`): 1 Conta, 1 Contato, 1 Oportunidade, 1 BluePrint, 1 PSL, 1 FVP (duas rodadas de massa; a segunda só com Conta/Contato/Oportunidade/BluePrint). Telefone do contato sintético `(00) 00000-0000`. Nada ficou na dev. Nenhuma alteração no usuário de execução (sem mudança de campo, permission set ou Marketing User).

## O que pode ter saído da org
Nada identificado. O Flow só faz `recordUpdate` na PSL (sem callout, sem e-mail, sem integração); nenhum log de integração ou pedido foi criado pela cadeia nos registros de teste.

## O que ficou sem prova
- Ativação do Flow v3 na QA e comportamento na QA (322 BluePrints, 1.475 PSLs reais lá): depende de autorização humana; não é escopo da dev.
- Paridade do deploy de perfis/PS contra a QA (check-only na QA): fica para a esteira/CI.
- Exibição dos campos nos layouts pela tela (conferido pela metadata, não por navegador).
- Premissas P1-P5 e G5 (relatórios, Conga/SDocs, SnapERP): seguem para homologação.
- Limitação herdada, declarada pelo builder e não exercitada: PSL com campo novo preenchido e antigo vazio não recebe a cópia do antigo.
