# EPLAST-28 — Design: alertas de oportunidade parada (redesenho com as respostas do cliente de 2026-11-17)

**Cliente:** Eplast · **Etapa:** 3 (desenho, arquiteto) · **Rodada:** redesenho de 2026-11-17, sobre o que já foi construído e passou no QA
**Org confirmada (`sf org list`):** `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`; sandbox "QA" da Eplast, `eplast--qa`, dev da esteira pela regra 5). Só leitura de metadata e contagens; nenhum deploy, DML ou anonymous Apex nesta etapa.
**Entradas:** `02-recon.md` (2026-11-17), `01-analise.md` (aprovada em 2026-11-15), `comentarios-do-card.md`, respostas do cliente de 17/11 (fim do desenho anterior, reproduzidas na seção 0), `rodada-anterior/03-design.md` e `rodada-anterior/premissas-assumidas/` (build e QA anteriores), `assessment.md` (achado 1, por trecho).

**Bloqueio por pergunta de negócio (regra 4, caso 3):** nenhum.
**Ponto para o arquiteto humano decidir no gate (não é bloqueio):** acrescentar **um campo** (`DiasEscalarGestor__c`) ao Custom Metadata Type `AlertaOportunidadeParadaSetting__mdt`, que esta demanda criou e o gate de 2026-11-15 aceitou. É configuração, não objeto de negócio; nenhum campo é criado em Opportunity, Account, Order ou Task. Pela regra do squad, mudança de modelo de dados é aceite humano.

**Estimativa de esforço:** 8–12 h
O que mudou em relação à análise (14–22 h) e ao design anterior (16–24 h): o alerta já existe, foi implantado e aprovado no QA (rodada 3, `rodada-anterior/premissas-assumidas/05-testes.md`). O redesenho é ajuste: 1 campo novo no CMDT, valores do registro `Default`, uma versão nova do Flow com o ramo do gestor e o texto reduzido, e reteste em duas sessões de QA (automação agendada) com carga sintética que inclui Tasks abertas e concluídas. Não há Apex.

---

## 0. Respostas do cliente (2026-11-17) e o que cada uma muda

A Eplast respondeu por escrito em 17/11 (registrado pelo responsável pela conta). Onde a resposta diverge de premissa anterior, vale a resposta.

| Resposta do cliente | Antes (premissa) | Agora |
|---|---|---|
| Parada = aberta sem atividade comercial relevante; alteração administrativa e notificação automática não reiniciam; sem atividade, conta da criação | P2: atividade **e** mudança de estágio | Só atividade (`LastActivityDate`), sem atividade conta de `CreatedDate`. Mudança de estágio deixa de reiniciar. Tratamento da "atividade automática" na seção 3 |
| Prazo: 7 dias corridos, único, configurável | P4: 14 dias | `DiasSemAcompanhamento__c` = 7 |
| Dono aos 7 dias; gestor a partir de 14; hierarquia não cadastrada, cadastrar ou definir alternativa antes de ativar o gestor | P6: gestor junto com o dono, mesmo prazo, desligado | Limiar próprio do gestor (`DiasEscalarGestor__c` = 14), desligado (`NotificarGestor__c` = false). Nenhum encaminhamento alternativo inventado |
| Só notificar, sem tarefa; sem repetição diária | P5, P7, P10 | Mantido |
| Texto: nome da oportunidade, dias sem atividade e link; sem valor | P9: nome, conta, estágio, dias, link | Sai conta e estágio |
| Canal: sino e app; sem e-mail | P5 | Mantido |
| Volume em produção: a validar fora da esteira | P13 | Mantido como premissa |

## 1. Decisão

**Manter a solução declarativa já construída (Flow agendado diário `Opportunity_Scheduled_AlertaParada` + Custom Notification `Oportunidade_Parada` + parâmetros em `AlertaOportunidadeParadaSetting__mdt` + rastro em `IntegrationLog__c`) e ajustá-la às respostas: prazo 7 por configuração, regra de parada só por atividade por configuração, ramo próprio do gestor aos 14 dias (desligado) e texto reduzido, numa versão nova do Flow.** Nenhum Apex.

Nível: **declarativo (2)**, com parte das mudanças em **configuração (1)** (valores do CMDT).

### 1.1 Por que não só configuração
Duas das cinco mudanças são configuração pura e não tocam o Flow:
- Prazo 14 → 7: valor de `DiasSemAcompanhamento__c` no registro `Default`.
- Estágio deixa de reiniciar: valor de `RegraParada__c` = `SoAtividade` no registro `Default`. A fórmula `Referencia` da versão atual já trata esse valor (`CASE(... "SoAtividade", RefAtividade ...)`, conferido no XML do repositório) e `RefAtividade` já cai para `CreatedDate` quando não há atividade.

As outras três exigem lógica no Flow: o gestor com limiar próprio (hoje o gestor entra no mesmo aviso do dono, no mesmo dia), o texto sem conta e estágio (fórmula `CorpoAviso`) e o registro de "sem gestor" quando o ramo do gestor estiver ligado. Por isso há versão nova do Flow.

### 1.2 Por que não Apex
Continua valendo a justificativa do design anterior (filtro, conta de datas, comparação e notificação; sem callout, rollback complexo ou recursão; org com cobertura de 10%, achado 2 do assessment). A única coisa que poderia empurrar para código é distinguir tarefa automática de tarefa do vendedor (seção 3). O cliente mandou: se só código resolve, **não construir código** e declarar como limitação. Seção 3 mostra que a solução declarativa cobre o caso que importa e declara o que sobra.

## 2. Como funciona (versão nova do Flow)

```
[Agendamento diário 07:00, horário da org — mantido; job atual Opportunity_Scheduled_AlertaParada-1]
 start: Opportunity, IsClosed = false
 Get_Cfg (AlertaOportunidadeParadaSetting__mdt, 'Default'); Get_Tipo_Notificacao ('Oportunidade_Parada')
 Ativo__c = false -> fim
 fórmulas (inalteradas): RefAtividade = LastActivityDate, ou DATEVALUE(CreatedDate) se vazio
                         Referencia   = conforme RegraParada__c (Default passa a SoAtividade)
                         DiasParado   = TODAY() - Referencia
 fórmula AlertarDono   = DiasParado = DiasSemAcompanhamento__c
                         OU (TODAY() = DataCargaInicial__c E DiasParado >= DiasSemAcompanhamento__c)
 fórmula AlertarGestor = NotificarGestor__c
                         E DiasEscalarGestor__c preenchido E DiasEscalarGestor__c > DiasSemAcompanhamento__c
                         E ( DiasParado = DiasEscalarGestor__c
                             OU (TODAY() = DataCargaInicial__c E DiasParado >= DiasEscalarGestor__c) )

 Ramo DONO (se AlertarDono):
   dono inativo -> IntegrationLog__c DONO_INATIVO (como hoje)
   dono ativo   -> Send Custom Notification ao OwnerId -> IntegrationLog__c ALERTA_ENVIADO
                   fault -> IntegrationLog__c FALHA_NOTIFICACAO
 Ramo GESTOR (se AlertarGestor; independente do ramo DONO):
   Owner.ManagerId vazio, gestor inativo ou gestor = dono -> IntegrationLog__c SEM_GESTOR
   senão -> Send Custom Notification ao Owner.ManagerId -> IntegrationLog__c ALERTA_GESTOR_ENVIADO
            fault -> IntegrationLog__c FALHA_NOTIFICACAO
 nenhum Update / Delete; nenhum Create fora de IntegrationLog__c
```

Texto do aviso (dono e gestor, resposta do cliente): título **"Oportunidade sem atividade há {DiasParado} dias"**; corpo **"{Nome da oportunidade}"**; alvo = Id da oportunidade (o toque no aviso abre o registro, é o "link"). Sem conta, estágio, valor, e-mail ou contato.

`IntegrationLog__c` (mesmos campos de hoje): `IntegrationAction__c` = `Opportunity_Scheduled_AlertaParada`; `ResponseStatus__c` ∈ {`ALERTA_ENVIADO`, `ALERTA_GESTOR_ENVIADO`, `DONO_INATIVO`, `SEM_GESTOR`, `FALHA_NOTIFICACAO`}; `RequestBody__c` = `<Id da oportunidade> | DiasParado=<n>`; na falha, Id e mensagem do fault. Nunca nome, e-mail ou valor.

### 2.1 Sem repetição (resposta do cliente: "sem repetição diária")
Mantida a deduplicação sem estado do design anterior: o dono recebe no dia em que `DiasParado` é **igual** a 7; o gestor, no dia em que é **igual** a 14. São dois avisos por episódio no máximo (um a cada pessoa), nunca diário. Atividade nova move a `Referencia` e o ciclo recomeça. Custo conhecido: um dia sem execução do job perde os avisos daquele dia (R4).

### 2.2 Dono e gestor no mesmo dia
`AlertarGestor` exige `DiasEscalarGestor__c > DiasSemAcompanhamento__c`; se alguém configurar o gestor com prazo menor ou igual ao do dono, o ramo do gestor não roda (evita aviso duplicado sem sentido). No dia da carga inicial, uma oportunidade com 20 dias gera os dois avisos, uma vez cada.

### 2.3 Gestor desligado e sem hierarquia
Recon de hoje: 0 usuários ativos com `ManagerId`; 2 papéis, nenhum com `ParentRoleId`. O ramo do gestor nasce **desligado** (`NotificarGestor__c = false`). Ligar é passo de quem administra a org, **depois** de cadastrar o campo "Gestor" (`ManagerId`) dos vendedores, conforme o cliente pediu. Se for ligado sem hierarquia, nada é enviado a ninguém no lugar do gestor: grava `SEM_GESTOR` por oportunidade, para dar visibilidade. O design **não** cria encaminhamento alternativo (fila, grupo, papel), por instrução do cliente.

## 3. "Notificações automáticas não reiniciam": o que dá para fazer sem código

Achados (recon de 2026-11-17): Task não tem `Type` nem campo custom de origem (só 3 do pacote `maps__`); os Flows `Oportunidade_Industria` (5 Tasks, assuntos fixos `Amostra`, `Cotação/Negociação`, `Execução técnica do projeto`, `Precificação`) e `OpportunityFlow` (1 Task, assunto por variável, não extraído) criam Tasks **sem informar `Status`** (nasce no padrão `Open`) e sem `ActivityDate` na lista de campos gravados. O alerta em si é Custom Notification e não cria Task nem Event.

| Alternativa | Como | Cobre | Custo / fragilidade | Decisão |
|---|---|---|---|---|
| **A. `LastActivityDate` (atual)** | Campo padrão agregado. Pela documentação do Salesforce, considera **tarefa concluída** e evento passado; tarefa aberta não conta | Tarefa automática **aberta** não reinicia. Notificação (sino, e-mail alert) não é atividade, não reinicia. Alteração administrativa no registro (dono, valor, estágio) não reinicia: `LastModifiedDate` e `LastStageChangeDate` não entram na conta | Tarefa automática só reinicia quando alguém a conclui. Comportamento "aberta não conta" **não provado nesta org** (0 Tasks na dev); medir em QA | **Escolhida** |
| B. Get Records em Task/Event por oportunidade, excluindo os assuntos dos Flows conhecidos | Flow declarativo, ordenado pela data, 1 registro | Exclui tarefas com assunto igual aos 4 conhecidos | Assunto é texto livre (vendedor pode usar o mesmo); assunto do `OpportunityFlow` não conhecido; quebra quando alguém muda o Flow de origem; uma consulta a mais por oportunidade em toda execução diária, com agrupamento por lote não provado para consulta ordenada com limite; `CreatedById` **não** distingue, porque Flow disparado por gravação roda como o usuário que gravou (o vendedor) | Descartada |
| C. Marcar a origem na Task (campo novo, ou `Status`/`TaskSubtype` gravado pelos Flows) e filtrar | Alterar `Oportunidade_Industria` e `OpportunityFlow` e ler Tasks | Distingue de forma confiável | Campo novo em Task é modelo de dados; altera dois Flows de outra frente (cadeia de Opportunity/Account, achado 1); leitura de filhos por oportunidade (CPU com muitas Tasks, SOMOSAGILITY-10) e, em volume, Apex | Fora desta demanda; evolução se o cliente pedir |

**Por que A atende o pedido:** a tarefa automática é um lembrete criado para o vendedor ("Amostra", "Precificação"...). Enquanto está aberta, ninguém fez nada, e ela não reinicia o prazo. Quando o vendedor a conclui, ele registrou que fez a atividade, o que é atividade comercial. Isso cobre "notificações automáticas não reiniciam" sem código e sem ler Tasks.

**Limitação declarada (validar na homologação):** (1) tarefa automática concluída sem que a atividade tenha acontecido (por exemplo, conclusão em massa por um administrador) reinicia o prazo; (2) qualquer outra automação que crie tarefa **já concluída** ou evento reiniciaria o prazo; não conheço nenhuma na org (recon leu 3 Flows; não verifiquei se o Marketing Cloud Connect registra atividade como Task); (3) qual data o Salesforce põe em `LastActivityDate` quando a tarefa concluída não tem data de vencimento não foi provado nesta org. Os três pontos são medidos em QA (seção 9). Se o cliente quiser distinguir a origem da tarefa de forma confiável, é a alternativa C, em demanda própria.

## 4. Item a item: o que reaproveita e o que cria (regra 3)

| Item | Estado na dev (recon / conferido hoje) | Nesta demanda |
|---|---|---|
| Flow `Opportunity_Scheduled_AlertaParada` | v1 **Active**, v2 **Draft** (rastro `ALERTA_ENVIADO`, conferido hoje por Tooling) | **Reaproveita.** Versão nova a partir do XML do repositório (que é a v2), com as mudanças da seção 5. Não se edita a v1 ativa |
| Job agendado `Opportunity_Scheduled_AlertaParada-1` (07:00, WAITING) | Existe | Reaproveita; horário mantido (P14) |
| CMDT `AlertaOportunidadeParadaSetting__mdt` | Existe; registro `Default` lido hoje na org: `Ativo__c` true, `DiasSemAcompanhamento__c` 14, `RegraParada__c` `AtividadeEEstagio`, `NotificarGestor__c` false, `DataCargaInicial__c` vazio | **Reaproveita** + **cria 1 campo** `DiasEscalarGestor__c`; altera valores do `Default` |
| `CustomNotificationType` `Oportunidade_Parada` | Existe | Reaproveita sem mudança |
| `IntegrationLog__c` | Existe; sem trigger nem Flow de gravação (recon anterior) | Reaproveita; dois status novos (`ALERTA_GESTOR_ENVIADO`, `SEM_GESTOR`) como texto, sem mudar o objeto |
| Campos padrão `Opportunity.LastActivityDate`, `CreatedDate`, `IsClosed`, `OwnerId`, `Name`; `User.ManagerId`, `IsActive` | Existem | Reaproveita. `LastStageChangeDate` deixa de pesar (por configuração) |
| Agente `SFAgent2`, tópico "Insights Comerciais e Acompanhamento" | Existe (recon anterior, não relido hoje) | Nada. Não se cria agente, tópico nem ação (CA-10) |
| Relatório `Neglected Open Opportunities` | Existe (recon anterior) | Nada (não notifica, não lê prazo configurável; design anterior 1.1) |
| Flows `agentic_feed` | 0 na dev | Nada |

## 5. Componentes

### 5.1 Criar
| Tipo | API name | Conteúdo |
|---|---|---|
| Campo de CMDT | `AlertaOportunidadeParadaSetting__mdt.DiasEscalarGestor__c` | Number(3,0). Descrição: "Dias sem atividade para avisar o gestor direto do dono (ManagerId). Só vale com NotificarGestor__c ligado e se maior que DiasSemAcompanhamento__c. EPLAST-28" |

### 5.2 Alterar
| Tipo | API name | Mudança |
|---|---|---|
| Registro de CMDT | `AlertaOportunidadeParadaSetting.Default` | `DiasSemAcompanhamento__c` 14 → **7**; `RegraParada__c` `AtividadeEEstagio` → **`SoAtividade`**; `DiasEscalarGestor__c` = **14**; `NotificarGestor__c` **false** (mantido); `Ativo__c` true e `DataCargaInicial__c` vazio (mantidos) |
| Flow | `Opportunity_Scheduled_AlertaParada` | **Versão nova** (na dev, a próxima depois da v2 Draft; o número exato é o que a plataforma atribuir, e o build registra), implantada com `<status>Draft</status>`. Mudanças sobre o XML atual: (a) `Alertar` vira `AlertarDono`; (b) nova fórmula `AlertarGestor` (seção 2); (c) `GestorElegivel` deixa de depender só de `NotificarGestor__c` e o gestor sai da coleção de destinatários do dono, passando a ter ramo e envio próprios; (d) `TituloAviso` = "Oportunidade sem atividade há N dias"; `CorpoAviso` = nome da oportunidade; (e) novos registros `Log_Alerta_Gestor_Enviado` e `Log_Sem_Gestor` em `IntegrationLog__c`; (f) descrição do Flow atualizada citando EPLAST-28 e a regra nova. API 68.0. Sem `recordUpdates`/`recordDeletes` |
| Descrição dos campos de CMDT `DiasSemAcompanhamento__c`, `NotificarGestor__c`, `RegraParada__c` | idem | Ajustar texto de ajuda ao novo uso (gestor com prazo próprio; padrão SoAtividade). Sem mudar tipo nem valores da picklist |

**Ativação (passo separado, skill `salesforce-doutrina`):** depois da verificação na dev, ativar a versão nova e deixar a v1 inativa; a v2 Draft fica obsoleta (nunca ativada). Para desfazer: reativar a versão anterior e restaurar os valores do `Default` (14 / `AtividadeEEstagio`). Na QA (QAS), quem implanta é a esteira (`05-deploy-qa.md`); lá a versão ativa da rodada anterior era a 7, e a nova entra como versão seguinte. O CMDT é implantado junto; valores do `Default` e Flow têm de subir no mesmo deploy, porque a versão nova com `RegraParada__c` antigo voltaria a contar estágio.

### 5.3 Depreciar
Nenhum. O valor de picklist `AtividadeEEstagio` e a fórmula `RefEstagio` continuam no Flow (deixam a regra antiga recuperável sem deploy).

### 5.4 Não alterados
`OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter`, `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity`, `TaskCreatedOrUpdated`, `AccountTrigger`, `IntegrationLog__c` (estrutura), `Oportunidade_Parada`, relatórios, `SFAgent2`, `TriggerUtility__mdt`.

## 6. Ordem de execução, governador e escala

### 6.1 Conflito de automação (achado 1 do assessment, saúde vermelha)
**Opportunity tem `OpportunityTrigger` (custom), `OpportunityBefore` e `OpportunityAfter` (SBQQ), todos Active e, hoje, `IsValid=true` (recon), e os Flows de gravação `OpportunityFlow` e `Oportunidade_Industria`. A ordem relativa entre eles não está mapeada.**

Como a solução lida: **não entra nessa ordem**, como no design anterior. O Flow é agendado (não disparado por gravação) e o único DML é `Create` em `IntegrationLog__c`, que não tem trigger nem Flow de gravação. Não grava em Opportunity, Account, Order, OrderItem, Task ou Event, então não aciona trigger, CPQ, validation rule, `TaskCreatedOrUpdated` nem a cadeia `AccountTrigger` → Protheus (nenhuma gravação em Account, em massa ou não). O mapa da ordem de execução não é pré-requisito; passa a ser se alguém propuser gravar marcador na oportunidade ou criar Task (fora, seção 11).

**Onde a cadeia aparece: na carga de teste.** Criar Opportunity e Task sintéticas passa pelos triggers, 16 validation rules, `OpportunityFlow`/`Oportunidade_Industria` (que criam Tasks) e `TaskCreatedOrUpdated` (que grava Account e, pela `AccountTrigger`, enfileira o envio ao Protheus). Mesmo tratamento da rodada anterior, que já funcionou na QA: scripts de `fixtures/`, Conta com `TriggerUtility.bypassTrigger` e CNPJ fictício, poucos registros, apagados ao fim.

Convivência com outros agendados: 07:00 não coincide com 02:00, 06:00, 15:47 e 17:36 (recon). `ScheduledFlowOpportunity` foi alterado hoje por outro motivo (recon, não investigado); não é tocado nem lido por este Flow.

### 6.2 Governador
- **Muitos registros:** uma interview por oportunidade aberta por dia, como hoje. O ramo do gestor não acrescenta consulta (lê `$Record.Owner.ManagerId` e `$Record.Owner.Manager.IsActive`, já usados na versão atual). Envio e `Create` são agrupados por lote. Dois avisos possíveis por oportunidade, só nos dias 7 e 14 (ou na carga inicial).
- **Um pai com muitos filhos (SOMOSAGILITY-10):** não se aplica. A solução lê o campo agregado `LastActivityDate`, não as Tasks; custo constante por oportunidade, sem cascata. É um motivo a mais para descartar a alternativa B/C da seção 3.
- **Limites de notificação personalizada por hora e de interviews diárias de Flow agendado:** **não conferidos** (o build anterior também não conferiu, por falta de acesso à documentação). Não cito de memória. Ponto crítico é o dia da carga inicial. Fica para o build/QA conferir na documentação oficial; limiar de volta ao design: medição acima de 70% de qualquer limite (skill `salesforce-doutrina`).

### 6.3 Contexto de execução
Flow agendado; a versão atual funcionou na QA com notificação ao dono (rodada 3). Não confirmei por consulta o contexto de execução nem se o destinatário precisa de acesso ao tipo de notificação; a QA anterior entregou ao dono sem permission set novo.

## 7. Permissões
- Nenhum perfil ou permission set novo ou alterado.
- Ao abrir o aviso, vale o compartilhamento: OWD interno de Opportunity é `Read` (recon), então dono e gestor, com perfil que lê Opportunity, abrem o registro.
- Manutenção do CMDT (prazo, gestor, carga inicial): administrador (Customize Application).
- Usuário de teste da regra 6: na dev há dois usuários que casam com o filtro; o ativo é `005bJ00000piKAaQAM` (perfil Administrador do sistema), o outro (`005bJ00000hBJmYQAW`) está inativo. O ativo foi o dono das oportunidades de teste na QA anterior. Não se altera perfil, permissão, papel nem `ManagerId` dele. Para exercitar o ramo do gestor ligado (CA-08), precisa de um par dono/gestor de teste com `ManagerId`; não há na org e o design não cria nem altera usuário: fica como caso não exercitado, declarado no roteiro (ver CA-08).

## 8. Preparação do Sales Cloud para o Marketing Cloud
**Não se aplica.** O alerta é aviso interno a usuário do Salesforce sobre a própria carteira, sem cliente, lead, campanha, público ou nutrição. O cliente confirmou canal sino/app e sem e-mail nesta etapa. Não se lê nem se grava nada do `et4ae5`, e nada é feito no Marketing Cloud. Se o cliente pedir aviso por e-mail no futuro, volta ao design pela regra 2 da conta.

## 9. Critérios de aceite que build, verificação e QA vão testar

Dados: dev e QA com carga sintética pelos `fixtures/` (dev tem 0 Opportunity, 0 Task, 0 Event). Datas no passado por "Definir campos de auditoria na criação" (como na QA anterior) ou, se indisponível, prazos reduzidos no CMDT só na sessão de teste e restaurados ao fim (ex.: dono 3, gestor 5). Automação agendada: duas sessões de QA (arma e confere).

| # | Critério | Como provar |
|---|---|---|
| CA-01 | Fechada (ganha e perdida) não alerta; aberta é avaliada | Sem `IntegrationLog__c` para as fechadas |
| CA-02 | Aberta sem atividade, criada há exatamente N (7) dias, alerta o dono uma vez | 1 `ALERTA_ENVIADO` com o Id; aviso no sino do dono |
| CA-03 | Texto: título "Oportunidade sem atividade há N dias", corpo só com o nome da oportunidade; toque abre o registro; sem conta, estágio, valor | Captura do sino de registro de teste; XML da fórmula |
| CA-04 | Mudança de estágio **não** reinicia: oportunidade com estágio alterado recentemente e sem atividade há N dias alerta | `ALERTA_ENVIADO` para ela |
| CA-05 | Sem repetição: na execução seguinte não há novo aviso ao dono; tarefa concluída nova reinicia a contagem | Nenhum log novo no 2º disparo |
| CA-06 | Tarefa automática **aberta** não reinicia (oportunidade com Task aberta de assunto `Amostra` e sem tarefa concluída alerta no dia N); tarefa concluída reinicia. Registrar também o valor de `LastActivityDate` quando a Task concluída não tem data de vencimento | `LastActivityDate` antes/depois; log do alerta |
| CA-07 | Alteração administrativa (trocar dono ou valor) não reinicia | `ALERTA_ENVIADO` mesmo após a alteração |
| CA-08 | Gestor: com `NotificarGestor__c` false, nenhum aviso ao gestor nem `SEM_GESTOR` no dia 14; com true e dono sem `ManagerId`, `SEM_GESTOR` uma vez no dia 14 e ninguém mais recebe. Com gestor cadastrado: `ALERTA_GESTOR_ENVIADO` ao gestor no dia 14, não ao dono | Os dois primeiros casos em QA (só CMDT, restaurado ao fim). O terceiro só se houver par dono/gestor de teste; senão, não exercitado e declarado |
| CA-09 | Dono inativo não recebe; `DONO_INATIVO` no dia N; dono não muda | Log; como na rodada anterior |
| CA-10 | Nenhum agente, tópico ou ação novo; nenhum e-mail enviado; nada no Marketing Cloud | `GenAiPluginDefinition`/`GenAiFunctionDefinition` antes e depois; log de e-mail |
| CA-11 | Não grava em objetos de negócio: contagens e `LastModifiedDate` de Opportunity, Account, Order, OrderItem, Task e Event iguais antes e depois do disparo; só `IntegrationLog__c` cresce | Contagens agregadas; revisão estática do XML (sem `recordUpdates`/`recordDeletes`, `recordCreates` só em `IntegrationLog__c`) |
| CA-12 | Configurável sem deploy: mudar `DiasSemAcompanhamento__c` e `DiasEscalarGestor__c` no Setup muda o dia do aviso; `Ativo__c` false não alerta nada; `DataCargaInicial__c` = hoje alerta uma vez as já paradas (dono ≥ 7; gestor ≥ 14, se ligado) | Logs por cenário |
| — | Versão: a nova versão do Flow sobe como Draft na dev; ativação registrada no plano com a versão que entra e a que sai | `SELECT VersionNumber, Status FROM Flow` (Tooling) |
| — | Volume (CA-11 da análise): várias oportunidades e donos, sem erro de limite; medir percentual dos limites | Debug/log da execução |
| — | Apex: não se aplica | — |

## 10. Premissas assumidas (validar na homologação)

Resolvidas pelo cliente em 17/11 e **retiradas** de premissa: P2 (parada), P4 (prazo), P5 (canal e frequência), P6 (gestor, agora com limiar e cadastro), P7 (sem tarefa), P9 (texto), P10 (sem repetição). Continuam ou são novas:

- [x] **P1 — Escopo.** Mantida (regra 1 da conta).
- [x] **P3' — Tarefa automática.** Pergunta: como ignorar "notificações automáticas"? Decisão: `LastActivityDate`; tarefa aberta não reinicia, tarefa concluída reinicia, venha de onde vier. Evidência: (a) org: Task sem campo de origem, Flows criam Tasks abertas (recon); (b) padrão: definição do campo na plataforma. Como mudar: alternativa C da seção 3, em demanda própria (exige campo em Task e mudança nos Flows de origem).
- [x] **P8 — Elegíveis: todas as abertas**, todos os tipos de registro. Mantida. Como mudar: filtro de entrada do Flow.
- [x] **P11 — Complementa o `SFAgent2`.** Mantida: o alerta não cria agente; alinhar a instrução do tópico ao critério de 7 dias é ajuste de demanda própria.
- [x] **P12 — Score fora.** Mantida.
- [x] **P13 — Volume de produção não consultado.** O cliente vai levantar fora da esteira. Se passar de algumas dezenas de milhares de oportunidades abertas, conferir o limite diário de interviews antes de ativar em produção.
- [x] **P14 — Horário 07:00, diário.** Mantida. Como mudar: reagendar no Setup.
- [x] **P15 — Log em `IntegrationLog__c`.** Mantida. Não confirmei se `Logs_Delete_Records` apaga esse objeto (se apagar, o log dura 30 dias).
- [x] **P16 — Carga inicial configurável.** Mantida, agora com os dois limiares.
- [x] **P17 — Dono inativo não redireciona** ao dono; o ramo do gestor (se ligado) segue independente, porque é a escalada que o cliente pediu, não encaminhamento alternativo. Como mudar: condicionar o ramo do gestor a dono ativo.
- [x] **P18 — Gestor recebe só se ativo e diferente do dono.** Mantida.
- [x] **P19 — Rastro de aviso enviado em `IntegrationLog__c`.** Mantida da rodada anterior (aprovada no QA) e estendida ao gestor.
- [x] **P20 (nova) — No dia 14 o aviso vai só ao gestor, não repete ao dono.** Pergunta: "gestor a partir de 14 dias" inclui novo aviso ao dono? Decisão: não, porque o cliente pediu sem repetição. Evidência: (b) resposta do cliente e opção mais simples. Como mudar: acrescentar o dono aos destinatários do ramo do gestor.
- [x] **P21 (nova) — Gestor ligado sem hierarquia grava `SEM_GESTOR` e não avisa ninguém.** Evidência: (a) 0 usuários com `ManagerId`, 0 papéis com pai (recon); cliente proibiu alternativa. Como mudar: cadastrar o gestor dos vendedores, ou demanda nova para fila ou papel.
- [x] **P22 (nova) — Mesmo texto para dono e gestor.** Evidência: resposta do cliente (nome, dias, link). Como mudar: fórmula do título no ramo do gestor.

Nenhum item `- [ ]`: não há caso 3 da regra 4.

## 11. O que NÃO será feito nesta demanda
- Apex, campo novo em Task, alteração de `Oportunidade_Industria` ou `OpportunityFlow` para marcar origem (alternativa C).
- Cadastrar `ManagerId` ou papéis, criar fila, grupo ou outro encaminhamento ao gestor.
- E-mail, SMS, WhatsApp, Chatter ou qualquer coisa no Marketing Cloud.
- Criar Task, reatribuir dono ou gravar em Opportunity, Account, Order, OrderItem, Task ou Event.
- Agente, tópico ou ação novos; ajuste do `SFAgent2`.
- Prazo por estágio; resumo diário por dono; mapeamento da ordem de execução de Opportunity.
- Corrigir o defeito conhecido de `UpdateAccountCompanyInfo` (Protheus).

## 12. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Ordem de execução de Opportunity não mapeada (achado 1)** | Alta para a org, baixa para a solução | Não grava nesses objetos (6.1); aparece só na carga de teste |
| R2 | `LastActivityDate` pode não se comportar como a documentação nesta org (tarefa aberta, tarefa sem vencimento) | Média | CA-06 mede em QA; se divergir, volta ao gate de design antes da homologação |
| R3 | Tarefa automática concluída sem a atividade ter acontecido reinicia o prazo (limitação declarada, seção 3) | Média | Roteiro do cliente; alternativa C como evolução |
| R4 | Dia sem execução perde os avisos (dedup sem estado) | Média | `FALHA_NOTIFICACAO` no log; reexecução por `DataCargaInicial__c` |
| R5 | Ramo do gestor não exercitado com gestor real (0 `ManagerId`) | Média | Desligado por padrão; CA-08 prova desligado e `SEM_GESTOR`; o aviso real ao gestor fica declarado como não provado até haver hierarquia ou par de teste |
| R6 | Limites de notificação e de interviews não conferidos | Média | Build/QA conferem na documentação oficial; crítico no dia da carga inicial |
| R7 | Deploy do Flow sem o `Default` atualizado volta a contar estágio e 14 dias | Média | Mesmo pacote; CA-04 e CA-02 provam |
| R8 | Cobertura Apex 10% (achado 2), API antiga (achado 9), `OrderTrigger` (achado 10) | Não se aplica | Sem Apex; API 68.0; Order não tocado |

## 13. Para o arquiteto humano conferir no gate
1. Aceitar o campo novo `DiasEscalarGestor__c` no CMDT (mudança de modelo de dados de configuração).
2. Aceitar a alternativa A da seção 3 e a limitação declarada sobre tarefa automática concluída.
3. Conferir P17, P20 e P21 (comportamento do ramo do gestor).

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
