# Recon — SOMOSAGILITY-31

- **Data da coleta:** 2026-11-26
- **Org:** `sbx-somos-agility-dev` (Org ID 00DHa0000070wxfMAA), Sandbox, Connected. Confirmada com `sf org list`. Esta é a única org conectada na sessão: **a QA não está conectada** (ver "O que não consegui confirmar").
- **Pedido:** alterar para Área de texto longo (32768) nove campos de `Propostas_de_Solucao__c` (`demanda.md`; objeto confirmado no comentário do card de 2026-11-26 12:15).
- **Retrieve de recon:** feito num projeto temporário fora do repo (`/tmp/reconproj`); nada foi para `force-app/`. Só leitura.
- **Preflight:** sem bloqueio, sem outra demanda nos mesmos componentes.

## 1. O que já cobre o pedido

Os 9 campos **já existem** na dev, como Área de texto (255). O pedido diz "criar", mas o que a org mostra é campo existente com tipo menor. Não há campo longo equivalente já pronto para este uso.

| Campo (API name) | Tipo na dev | Descrição preenchida | Comando |
|---|---|---|---|
| `Cotacao__c` | Área de texto(255) | sim | `sf data query` em `FieldDefinition` (`EntityDefinition.QualifiedApiName='Propostas_de_Solucao__c'`) |
| `Cotacao_2__c` | Área de texto(255) | não | idem |
| `Cotacao_3__c` | Área de texto(255) | não | idem |
| `Proposta_Acabada__c` | Área de texto(255) | sim | idem |
| `Proposta_Acabada_2__c` | Área de texto(255) | não | idem |
| `Proposta_Acabada_3__c` | Área de texto(255) | não | idem |
| `Informa_es_T_cnicas_Complementares__c` | Área de texto(255) | não | idem |
| `Informa_es_T_cnicas_Complementares_2__c` | Área de texto(255) | não | idem |
| `Informa_es_T_cnicas_Complementares_3__c` | Área de texto(255) | não | idem |

Os 9 aceitam nulo (`IsNillable=true` na mesma consulta), isto é, não são obrigatórios no nível do campo (responde P7 só para a camada de campo; layout e validation rule tratadas abaixo).

Relacionado, mas **fora do pedido**: o objeto já tem outros campos textarea (`PFP_1__c`, `PFP_2__c`, `PFP_3__c`, `Cenario1__c`, etc.), vistos em `sf sobject describe`. Não os toquei nem confirmei o tipo longo de cada um.

## 2. O que será tocado

| Item | Situação | Comando |
|---|---|---|
| 9 campos acima | alteração de tipo 255 para texto longo | `FieldDefinition` |
| Layouts de `Propostas_de_Solucao__c` | 5 no repo referenciam os campos: Especificação Técnica, Margens e Condições Especiais, Proposta Enviada ao Cliente, Proposta Finalizada, Retorno do Cliente. Cada layout traz um subconjunto dos 9 | Grep em `force-app/` (snapshot do repo; **não conferido contra a org**) |
| Permission sets | `Acesso_completo_Esteira_de_vendas_e_renovacoes` e `DiretorComercial` trazem os 9 campos no repo (Grep) | Grep em `force-app/` |
| Report types | `Oportunidade_PSL_PFV`, `Oportunidades_FVP_e_PSL`, `Oportunidades_PSL_s_e_PFV_s`, `Oportunidades_e_PSL` listam campos do grupo (nem todos os 9 em cada) | Grep em `force-app/reportTypes` |

Os campos já existem no repo em `force-app/main/default/objects/Propostas_de_Solucao__c/fields/` (os 9 arquivos `.field-meta.xml`), então o build altera o XML existente, não cria arquivo novo. Não li o conteúdo desses XML.

## 3. Automação concorrente em `Propostas_de_Solucao__c`

| Item | Evento | Lê ou grava algum dos 9 campos? | Prova |
|---|---|---|---|
| Trigger `TrgPropostasSolucao` (chama `PropostasSolucaoTriggerHandler.run()`) | before/after insert, update, delete, undelete | Handler: **nenhuma referência** aos 9 campos no repo | retrieve do trigger em `/tmp/reconproj/out`; Grep em `classes/PropostasSolucaoTriggerHandler.cls` |
| Flow `Atualiza_Quando_Proposta_de_Solucao_da_Oportunidade_Aprovada` (ativo, RecordAfterSave) | after save | não | `FlowDefinitionView` + retrieve + Grep dos 9 nomes |
| Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` (ativo, RecordAfterSave) | after save | não | idem |
| Flow `Cria_o_da_Proposta` (ativo, RecordAfterSave) | after save | não | idem |
| Flow `Margens_e_Condi_es_Especiais` (ativo, RecordAfterSave) | after save | não | idem |
| Flow `Nova_Proposta_de_Solu_o_SOW_CCS` (ativo, RecordAfterSave) | after save | não | idem |
| Flow `Propostas_de_Solu_o` (ativo, RecordAfterSave) | after save | não | idem |
| Validation rules: 16 no total, 13 ativas. Inativas: `M03_Obrigatorio_preenchimento_campos_PFP`, `Permitir_apenas_1_PSL_Fech_Cliente`, `Comissao_obrigatoria` | before save | **nenhuma fórmula referencia os 9 campos** | `sf data query --use-tooling-api` em `ValidationRule` (16 nomes e `Active`), retrieve por nome dos 16 e Grep dos 9 nomes: 0 ocorrências |

Observações:
- A lista de Flows ativos vem de `FlowDefinitionView` com `TriggerObjectOrEvent` = o objeto, só os acionados por registro. Flows de tela, agendados ou chamados por subflow que leiam esses campos **não entram nessa consulta** (ver "O que não consegui confirmar"). No repo, o Grep em `flows/` pelos 9 nomes não achou nada.
- Não li processos de aprovação nem regras de duplicidade/atribuição deste objeto.
- Objeto pai: `Oportunidade__c` referencia `Opportunity` (`sf sobject describe`). **Não levantei** o que dispara na Oportunidade (o assessment cita 31 automações lá). Como a demanda altera só tipo de campo e não grava a Oportunidade, o risco é baixo, mas fica registrado como não levantado.

## 4. Volume e dados de teste

| Consulta | Resultado | Comando |
|---|---|---|
| Registros de `Propostas_de_Solucao__c` na dev | **0** | `SELECT COUNT() FROM Propostas_de_Solucao__c` |
| Registros com `Cotacao__c` preenchido | 0 | `SELECT COUNT() ... WHERE Cotacao__c != null` |

A dev **não tem dado** para testar. O teste (valor preservado, 32768 aceitos, 32769 recusados) exige criar registro de teste na dev, e isso esbarra nas validation rules ativas e nos Flows acima (ex.: `M01_Proibido_PFP_sem_PSL`, `M02_Proibido_PSL_sem_PFP`, `PslSemOrcamentista`, `CNPJ_obrigatorio_se_PFP_fechada*`). Não li as fórmulas dessas regras para dizer o que o registro precisa ter.

Como não há registro, o CA-02 (valor de 255 caracteres preservado) só se prova criando o registro **antes** da alteração do tipo. O arquiteto deve prever essa ordem.

Fixtures em `clients/somos-agility/fixtures/`: não verifiquei.

## 5. Permissões

| Item | Resultado | Comando |
|---|---|---|
| Registros de `FieldPermissions` por campo | `Cotacao__c` 63, `Proposta_Acabada__c` 66, `Informa_es_T_cnicas_Complementares__c` 63 (perfis e permission sets somados, só contagem) | `SELECT Field, COUNT(Id) FROM FieldPermissions ... GROUP BY Field` |
| Permission sets com os 9 campos no repo | `Acesso_completo_Esteira_de_vendas_e_renovacoes`, `DiretorComercial` | Grep em `force-app/` |
| OWD do objeto | não levantado (a demanda não altera compartilhamento) | n/a |

Só consultei os 3 campos sem sufixo; os campos `_2` e `_3` não foram contados. Mudar tipo de campo não remove FLS existente; isso é comportamento da plataforma, não confirmado nesta org.

## 6. Impacto cruzado

### 6.1 Quem referencia os 9 campos

| Onde | Resultado | Prova |
|---|---|---|
| Validation rules (16) | nenhuma | retrieve e Grep (seção 3) |
| Flows acionados por registro (6 ativos) | nenhum | retrieve e Grep |
| Trigger e handler | nenhum | retrieve e Grep |
| Classes Apex no repo | nenhuma referência (`SincronizaNewAge` casou só com `Valor_da_Cotacao__c`, `Cotacao_Compra__c`, `Cotacao_do_Dolar__c`, que são outros campos, em outros objetos) | Grep em `force-app/main/default/classes` |
| Layouts | 5 (seção 2) | Grep |
| Permission sets | 2 (seção 2) | Grep |
| Report types | 4 (seção 2) | Grep |
| Relatórios, painéis e templates de documento (Conga, SDocs) | **não levantado** | n/a |
| `MetadataComponentDependency` | **consulta falhou**: `INVALID_TYPE`, o tipo não é suportado nesta org pelo caminho de consulta usado. Não vale como "sem referência" | `sf data query` |
| Busca em corpo de classe pela org | **falhou**: `ApexClass.Body` não é filtrável. Só vale o Grep do repo | `sf data query --use-tooling-api` |

### 6.2 Efeito do tipo longo sobre o que referencia o campo (conhecimento da plataforma, não testado na org)
- Campo de texto longo não pode ser filtrado nem agrupado em relatório, e não entra em critério de lista. Se algum relatório ou list view filtra por esses campos, o deploy ou o relatório quebra. Não levantei relatórios nem list views. O objeto tem `listViews/` no repo e não verifiquei os filtros.
- Os report types acima listam os campos como coluna, o que costuma ser aceito, mas não foi provado.

### 6.3 Dev × QA

Não foi possível comparar: só a dev está conectada. Nenhuma diferença registrada porque nenhuma foi medida.

### 6.4 Outras demandas
`00-preflight.md`: nenhuma. A SOMOSAGILITY-26 (entregue) tratou campos `PFP_*_Texto__c` com 32768 em outros objetos; a análise registra a relação como P4. Não reabri o histórico além da análise.

### 6.5 Pré-requisitos de teste
- Licença livre para usuário de teste: não levantado.
- Registro de teste: precisa ser criado (seção 4).

## O que não consegui confirmar

1. **QA:** a sandbox de QA não está conectada nesta sessão. Não sei se os 9 campos existem lá, com qual tipo, nem se as validation rules e Flows são os mesmos da dev (P2 da análise segue aberta).
2. **Produção:** nada consultado (guardrail #1). O estado do tipo dos campos lá depende de relato do cliente.
3. **Consumidores fora do repo:** relatórios, painéis, list views, templates de proposta (Conga, SDocs) e a integração SnapERP. P3 da análise segue aberta. `MetadataComponentDependency` não funcionou, e o Grep só cobre o repo, que é um snapshot e pode estar defasado em relação à dev.
4. **Layouts, permission sets e report types:** a lista veio do repo, não da org. Não conferi se a org tem o mesmo conjunto, nem quais layouts estão atribuídos a quais perfis ou record types.
5. **Flows não acionados por registro** (de tela, agendados, subflows) que leiam os campos: não levantados na org.
6. **Apex que lê os campos por SOQL dinâmico ou string:** o Grep não pega. Cobertura de teste das classes do objeto: não medida.
7. **FLS dos campos `_2` e `_3`** e quais perfis têm leitura e edição: contei só 3 campos e só registros, não listei perfis (P5 da análise segue aberta).
8. **Fórmula das validation rules:** li só para buscar os 9 nomes; não sei o que um registro de teste precisa ter para ser gravado.
9. **Automação na Oportunidade (pai) e processos de aprovação** de `Propostas_de_Solucao__c`: não levantados.
10. **Relação com SOMOSAGILITY-26 (P4):** não confirmei se algum dos 9 campos está no pacote entregue por ela.
