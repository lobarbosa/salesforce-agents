**Resultado do build:** concluído

# EPLAST-46 — Plano de build: sugestão de campanhas pelo comportamento dos clientes

**Org:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected, Org Id `00DHa000006vfMLMAY`; é a `eplast--qa` da Eplast, dev da esteira pela regra 5). Nenhum deploy, DML ou Apex anônimo em outra org. Nenhum dado de registro lido (só metadata e `COUNT`). Nada feito no Marketing Cloud.
**Branch:** `feature/EPLAST-46`. **Design:** `03-design.md`, aceite em `gates.md` (2026-11-16, commit `6acb40c9`). **Nível:** declarativo, sem Apex (CA-10 não se aplica).

## Componentes criados (todos implantados na dev)

| # | Componente | API name | Observação |
|---|---|---|---|
| 1 | Custom permission | `SugestaoCampanha_EPLAST46` | Testada no início do Flow |
| 2 | Custom metadata type | `CampaignSuggestionSetting__mdt` | Decisão da seção 9 do design aceita no gate (recomendação: criar). Campos `Priority__c` (Número 2,0), `AudienceReport__c` (Texto 120), `Active__c` (Checkbox, padrão verdadeiro). Visibilidade Public |
| 3 | Registros do catálogo | `CampaignSuggestionSetting.REATIVACAO` (prioridade 1), `CampaignSuggestionSetting.AMPLIACAO_MIX` (prioridade 2, público `AMPLIACAO MIX - CONTATOS`) | Não protegidos. O texto de `AudienceReport__c` de `REATIVACAO` é informativo: a faixa do relatório é calculada no Flow |
| 4 | Flow autolançado | `Account_Agente_SugestaoCampanha` v1, **Active** | Sem gatilho, sem DML, sem e-mail. `runInMode = SystemModeWithSharing`. Entrada `recordId`; saídas `suggestionCode`, `message`. Descrição preenchida. Flow novo, não substitui nada (ativo na criação, conforme o design) |
| 5 | Permission set | `PS_Marketing_SugestaoCampanha` | Custom permission, acesso ao Flow, leitura de `CommercialSignal__c` (`Product__c`, `CalculationDate__c`; `Type__c` é obrigatório e vem junto) e leitura de `Account` (dependência do master-detail). Sem escrita. Não atribuído a nenhum usuário |
| 6 | Relatório | `AMPLIACAO_MIX_CONTATOS` ("AMPLIACAO MIX - CONTATOS"), pasta `MARKETINGCLOUD` (rótulo `MARKETING CLOUD`), Tabular, tipo `ContactList` | Filtro cruzado "com `CommercialSignal__c`" `Type__c = Cruzada` (junção `Account__c`); `HasOptedOutOfEmail = false`; e-mail preenchido. Colunas: Id do contato, nome, e-mail, Id da conta, nome da conta, `Industry` |
| 7 | Versão do agente | `SFAgent2` `BotVersion` v9 + `GenAiPlannerBundle` `SFAgent2_v9`, **Inativa** | Cópia da v8 **baixada da org** (não do repositório), sufixo `_v8` → `_v9`. Acrescenta a ação `SugestaoCampanha_EPLAST46_v9` (alvo `flow` `Account_Agente_SugestaoCampanha`, schemas de entrada e saída) e a instrução `instruction1_EPLAST46_v9` no tópico `insights_comerciais_1790e90ae9fbdc8_v9`. Demais tópicos e ações copiados sem mudança de conteúdo |

## Regra implementada no Flow

1. Sem a custom permission: `NO_ACCESS`, sem ler a conta.
2. Lê `Account` (`Name`, `Inactive__c`, `LastPurchase__c`, `Industry`). Não encontrada ou sem acesso: `NODATA`. Falha de leitura em qualquer consulta: `ERRO`.
3. Lê as duas linhas do catálogo, conta contatos elegíveis (e-mail: `HasOptedOutOfEmail = false` e `Email` preenchido; mensagem: `et4ae5__HasOptedOutOfMobile__c = false` e `MobilePhone` preenchido; só contagem, sem loop sobre contatos) e lê os sinais `CommercialSignal__c` `Type__c = Cruzada` da conta.
4. Com sinais, lê `Product2.Group__c` dos produtos (sem repetir grupo; vazio vira "sem grupo") e a data de cálculo mais recente.
5. `REATIVACAO` = catálogo ativo e `Inactive__c = true`; público pela faixa de dias (91–180, 181–365, acima de 365). `AMPLIACAO_MIX` = catálogo ativo e ao menos um sinal. Ordem pela `Priority__c`. Sem compra e sem sinal: `SEM_HISTORICO`. Demais: `NONE`.
6. Mensagem com motivo, público, contagem por canal ("sem contato elegível para <canal>" quando zero) e a frase de que nada foi enviado. Sem valores de compra, CPF/CNPJ, e-mail ou telefone.

## Conferências feitas na org antes de construir

- Campos confirmados por `FieldDefinition`: `CommercialSignal__c.Type__c/Product__c/CalculationDate__c/Account__c`, `Contact.HasOptedOutOfEmail/et4ae5__HasOptedOutOfMobile__c/Email/MobilePhone`, `Account.Inactive__c/LastPurchase__c/Industry`, `Product2.Group__c`.
- **R7 (design) resolvido:** os três relatórios `SEM COMPRA` filtram `Account.LastPurchase__c` em 91–180, 181–365 e acima de 365 dias, as mesmas faixas que o Flow usa. Nenhum relatório existente foi alterado.
- **R5/I-04 (design) resolvido:** o tipo `ContactList` aceita o filtro cruzado com `CommercialSignal__c` (implantou e foi relido da org com o filtro). Plano B não necessário. Observação de formato: no XML de relatório as tags são `relatedTable` e `relatedTableJoinColumn`.

## Versões e ativação

| Item | Estado agora | Ativação (passo separado) | Desfazer |
|---|---|---|---|
| `SFAgent2` | v9 **Inactive**; v8 segue **Active** (`BotVersion`: 9 Inactive, 8 Active, 7 Inactive) | Dev: o `verificador` ativa a v9 para testar e registra em `04-verificacao.md`. QA: o `qa` ativa a v9 e registra qual entrou e qual saiu em `05-testes.md` | Ativar a v8 |
| `Account_Agente_SugestaoCampanha` | v1 Active (versão ativa = última) | Nenhuma | Desativar o Flow; sem a v9 ativa ninguém o chama |
| `Account_Agente_ProximaAcao` | v2 Active, **não tocado** (ativa = última antes e depois) | — | — |

## Desvios do design (todos pequenos, sem mudar a decisão)

- **SOQL por chamada: 7, não 5.** O design contou 5 (conta, catálogo, sinais, 2 contatos). O build usa 2 leituras de catálogo (uma por `DeveloperName`, para ordenar e ativar cada campanha separadamente) e 1 leitura de `Product2` (só quando há sinais) para obter `Group__c`. Limite 100; folga grande. Linhas: sinais ≤ 10, catálogo 1 por leitura, `Product2` ≤ 10.
- **Permission set:** inclui leitura de `Account`, exigida pela plataforma como dependência da leitura de `CommercialSignal__c` (master-detail). `Type__c` fora da lista de campos porque é obrigatório (a plataforma recusa).
- **Fixture não construída aqui.** O design (seção 7) lista a fixture em `fixtures/`, mas o `fixtures/README.md` a atribui ao `verificador`/`qa` e só aceita script que uma verificação já provou na org. Escrever sem executar seria entregar script não validado (I-07, bypass não validado). O `verificador` monta e grava em `fixtures/` ao testar. Cenários A–E e regras de dado estão na seção 7 do design.

## Premissas do design usadas (nenhuma nova, nenhuma bloqueia)

PA-46-01 (cruzada da EPLAST-33, grupo `Industry`), PA-46-02 (ação nova no mesmo tópico), PA-46-03 (`Group__c` como família), PA-46-04 (fonte de compra por regra), PA-46-05 (lead fora da ação), PA-46-06 (mensagem só com contagens e códigos).

## Preparação do Sales Cloud para o Marketing Cloud (lado do CRM entregue)

- Público de reativação: relatórios `SEM COMPRA - *` já existentes (reaproveitados, sem alteração).
- Público de ampliação de mix: relatório novo `AMPLIACAO MIX - CONTATOS` (já exclui opt-out de e-mail).
- Nutrição de lead: `LEADS - PROSPECÇÃO PRIORIZADA`, existente.
- Nenhum campo novo em objeto de cliente; nenhuma gravação. Nada criado ou configurado no Marketing Cloud.
- Fica para quem opera o Marketing Cloud: importar `AMPLIACAO MIX - CONTATOS` como público; reaplicar opt-out de mensagem no envio (o relatório novo é de e-mail; mensagem segue em `MSG - CONTATOS - CELULAR APTOS`); criar jornada, conteúdo e envio; decidir se o retorno de envio alimenta a sugestão no futuro.

## Pendências para a verificação (o que ainda não foi exercitado)

- O Flow foi implantado e está ativo, mas **não foi executado**: dev vazia de Account/Contact/Opportunity e fixture a montar. A verificação deve cobrir CA-01 a CA-09, CA-11 e CA-12 (CA-05 reescrito no design), com atenção a: `AssignCount` sobre coleção vazia dar 0; formatação de `TEXT()` da data; `Contains` com `GroupsText` inicialmente nulo; `$Permission` negativo (usuário de teste `005bJ00000piKAaQAM` é administrador: atribuir o PS novo ao usuário de execução e remover para provar `NO_ACCESS`, ou registrar o negativo como inconclusivo).
- v9 inativa: a ação só é exercida pelo agente depois da ativação (passo do `verificador`). O Flow pode ser testado direto, sem agente.
- R1 do design segue de pé para a QA: `CommercialSignal__c` e `SFAgent2` v8 precisam existir na QA antes do deploy (só a dev foi conferida).
- Itens da lista de risco do design não tocados: R2 (batch de sinais não agendado), R3, R4, R6, R8.

## Git

Branch `feature/EPLAST-46`. Arquivos em `force-app/main/default/`: `customPermissions/`, `objects/CampaignSuggestionSetting__mdt/`, `customMetadata/CampaignSuggestionSetting.*`, `flows/Account_Agente_SugestaoCampanha.flow-meta.xml`, `permissionsets/PS_Marketing_SugestaoCampanha.permissionset-meta.xml`, `reports/MARKETINGCLOUD/AMPLIACAO_MIX_CONTATOS.report-meta.xml`, `bots/SFAgent2/` (`SFAgent2.bot-meta.xml`, `v9.botVersion-meta.xml`), `genAiPlannerBundles/SFAgent2_v9/`. A v8 baixada serviu só de base e não foi versionada.
