# SOMOSAGILITY-9 — Recon da org (etapa 2)

- **Data da coleta:** 2026-10-30
- **Org:** `sbx-somos-agility-dev` (Org ID `00DHa0000070wxfMAA`, API v68.0). `Organization.IsSandbox = true` e `OrganizationType = Enterprise Edition`, confirmados por query nesta sessão.
- **Método:** `sf sobject describe`, `sf project retrieve start` para `/tmp/recon` (nada foi gravado em `force-app/`), queries de metadata na Tooling API e queries de **contagem** na Data API. Nenhum registro de cliente foi lido.
- **Insumo novo desde a análise:** o anexo do card, um e-mail com dois prints de tela da **produção**, foi liberado para esta sessão. Abaixo só entra o conteúdo funcional dele: mensagens de erro, campos e regras. Nomes, e-mail, telefone e assinatura foram omitidos.
- **Sobre nomes de pessoa:** dois primeiros nomes aparecem dentro de **API names de validation rules que já existem na org**. Eles são citados aqui só porque o build precisa do identificador exato (guardrail #3). No texto, as pessoas são tratadas pelo papel: "diretor financeiro atual" e "antigo diretor comercial".

---

## 1. O que o anexo diz (filtrado)

1. O erro acontece quando o **diretor financeiro atual** preenche os campos "Responsável pelo custo" e "Ressalvas do diretor financeiro".
2. Regra de negócio: esses dois campos **precisam ser preenchidos pelo diretor financeiro antes da aprovação da Exceção**.
3. As mensagens de erro citam pelo nome o **antigo diretor comercial**, que não faz mais parte do fluxo de aprovação.
4. É pedido um ajuste de dados em um registro de produção (`ECT-000080`): preencher "Responsável pelo custo" = `Cliente` e um texto de ressalvas.
5. Print 1 (produção): o registro está com `Status de Aprovação = Pendente - Diretor comercial`. Ao salvar, aparece *"Opa, você não possui os privilégios necessários para editar esse registro"*.
6. Print 2 (produção): no mesmo registro aparecem as duas mensagens de validation rule abaixo:
   - *"<diretor financeiro>, o campo "responsável pelo custo" é de preenchimento exclusivo do <antigo diretor comercial>."*
   - *"Preencha o campo "ressalvas do diretor financeiro"."*

## 2. Objeto: confirmado

| Item | Valor confirmado |
|---|---|
| API name | `Excecao_Comercial_p_Atendimento_Tecnico__c` (key prefix `a2P`) |
| Label | Exceção Comercial p/ Atendimento Técnico |
| Name | Auto Number `ECT-{000000}`. "ECT" é o prefixo do número do registro (responde a Q8 da análise). |
| OWD | `sharingModel = Read` (externo `Read`) |
| Histórico | `enableHistory = true`, mas nenhum dos campos abaixo tem `trackHistory` |
| Volume na dev | **0 registros** (`GROUP BY Status_de_Aprovacao__c` voltou vazio) e 0 `ProcessInstance` pendente. A dev não tem massa, então volume de produção não pode ser inferido daqui. |

### Campos relevantes (describe + retrieve)

| API name | Label | Tipo | Observação |
|---|---|---|---|
| `Responsavel_pelo_Custo__c` | Responsável pelo Custo | Picklist restrita: `Cliente`, `Agility Networks` | `required=false` |
| `Ressalvas_do_Diretor_Financeiro__c` | Ressalvas do Diretor Financeiro | TextArea | `required=false` |
| `Status_de_Aprovacao__c` | Status de Aprovação | Picklist restrita: `Rascunho` (default), `Pendente`, `Pendente - Diretor financeiro`, `Pendente - Diretor comercial`, `Pendente - Gerente de serviço`, `Aprovado`, `Rejeitado`, `Recall` | Atualizado pelas field updates do approval process |
| `Status_da_Solicitacao__c`, `Status_da_Qualificacao_Comercial__c`, `Status_da_Qualificacao_PS__c` | — | Picklist | Usados só pelas versões inativas do approval process |
| `Custo__c` | Custo | Currency | Não citado na demanda |
| `SLA_para_Qualificacao__c` / `Data_Hora_do_SLA_Solicitado__c` | — | Picklist / Fórmula datetime | Alimentam o Flow de SLA |
| `Conta__c`, `Descricao_do_Atendimento__c`, `Justificativa__c` | — | Lookup(Account) / TextArea | Fora do escopo |

Nos dois campos-alvo, o layout `Excecao_Comercial_p_Atendimento_Tecnico__c-Layout de Exceção Comercial p/ Atendimento Técnico` tem `behavior = Edit`.

## 3. Mecanismo de aprovação: Approval Process clássico (responde a Q2)

Existem 5 versões. **Só a `Qualificacao_v2_3` está ativa.**

| Approval Process | Ativo | Etapas |
|---|---|---|
| `Excecao_Comercial_p_Atendimento_Tecnico__c.Qualificacao` | não | Diretor Comercial → Diretor Professional Services |
| `...Qualificacao_v2_0` | não | Diretor Comercial |
| `...Qualificacao_v2_1` | não | Gerente de serviço → Diretor Comercial |
| `...Qualificacao_v2_2` | não | Diretor Financeiro → Diretor Comercial → Gerente de serviço |
| **`...Qualificacao_v2_3`** | **sim** | **Diretor Financeiro → Diretor(a) Comercial** |

Detalhe da `Qualificacao_v2_3`, a versão ativa:
- Entrada: `Status_de_Aprovacao__c` igual a `Rascunho` ou `Rejeitado`. Quem submete: owner.
- `recordEditability = AdminOrCurrentApprover`. Durante a aprovação, o registro fica travado para todos, menos admins (Modify All) e o aprovador da etapa atual.
- Submissão: `Status_e_Etapa_Financeiro` grava `Status_de_Aprovacao__c = Pendente - Diretor financeiro`.
- Etapa 1, `Qualifica_o_Diretor_Financeiro`: aprovador é usuário fixo, o diretor financeiro atual. Na aprovação, `Status_e_Etapa_Diretor_comercial` grava `Pendente - Diretor comercial`.
- Etapa 2, `Qualificacao_Diretor_Comercial_1`: aprovador é usuário fixo, o(a) diretor(a) comercial atual, que é diferente do antigo. `rejectBehavior = RejectRequest`.
- Aprovação final: alerta `Solicitacao_de_Excecao_Comercial_para_Atendimento_Tecnico_Aprovada` e field update `Status_e_Etapa_Aprovado`. Rejeição final: alerta `..._Rejeitada` e `Status_e_Etapa_Rejeitado`. Recall: `Status_e_Etapa_Recall`.
- `approvalPageFields` inclui `Responsavel_pelo_Custo__c`, mas **não** inclui `Ressalvas_do_Diretor_Financeiro__c`.

**Conclusão sobre a "atualização do fluxo de aprovação" (Q3):** na dev, ela **já está feita**. A versão ativa não tem o antigo diretor comercial como aprovador, que só aparece nas 4 versões inativas. O que ainda cita o antigo diretor são as **validation rules** (seção 4), não o approval process. Não consigo confirmar daqui se a produção está na mesma versão: produção está fora do alcance do agente.

**Usuários aprovadores na dev** (consultados só `Profile.Name` e `IsActive`, sem nenhum dado pessoal):
| Papel | Perfil na dev | Ativo |
|---|---|---|
| Diretor financeiro atual (etapa 1 da v2_3) | `Admin` | sim |
| Diretor(a) comercial atual (etapa 2 da v2_3) | `Diretor Comercial` | sim |
| Antigo diretor comercial (só nas versões inativas) | `Admin` | sim |

## 4. Validation rules no objeto (4, todas ativas)

O retrieve trouxe 4 regras e a Tooling API (`ValidationRule`) confirmou as mesmas 4, todas `Active = true`.

| API name | Fórmula (resumo) | Mensagem | Quem atinge |
|---|---|---|---|
| `Checa_Responsavel_pelo_Custo_se_Walmor` | `NOT(ISPICKVAL(Responsavel_pelo_Custo__c,''))` **E** `$Profile.Name = 'Administração'` | "<diretor financeiro>, o campo "responsável pelo custo" é de preenchimento exclusivo do <antigo diretor comercial>." | Perfil `Administração`. **Impede esse perfil de preencher o campo, que é o contrário da regra de negócio atual.** É a primeira mensagem do print 2. |
| `Checa_Ressalvas_se_Walmor` | `$Profile.Name = 'Administração'` **E** `Ressalvas_do_Diretor_Financeiro__c = ''` | "Preencha o campo "ressalvas do diretor financeiro"." | Perfil `Administração`, em **qualquer** edição e em qualquer status. É a segunda mensagem do print 2. |
| `Checa_Ressalvas_se_Soto` | `$Profile.Name = 'Admin'` **E** `ISCHANGED(Ressalvas_do_Diretor_Financeiro__c)` | "O campo "ressalvas do diretor financeiro" é de preenchimento exclusivo do diretor financeiro." | Perfil `Admin`. **Na dev, o diretor financeiro atual tem perfil `Admin`, então esta regra bloqueia exatamente ele.** |
| `Checa_Responsavel_pelo_Custo_se_Soto` | `ISPICKVAL(Responsavel,'')` **E** (`$Profile.Name = 'Admin'` **OU** `Status_de_Aprovacao__c` em {`Aprovado`, `Pendente - Diretor comercial`}) | "O campo "responsável pelo custo" não pode estar vazio." | Perfil `Admin` em qualquer edição, e qualquer usuário que edite um registro já passado da etapa financeira com o campo vazio |

**Diagnóstico:**
- As quatro regras identificam **pessoas pelo nome do perfil** (`$Profile.Name`). O padrão de entrega reprova esse hardcode. Quando a pessoa saiu do fluxo, a regra continuou apontando para o perfil dela.
- O mesmo perfil `Admin` tem 2 usuários ativos na dev e o `Administração` tem outros 2 (só contagem). Por isso as regras atingem também quem não tem relação com a aprovação.
- **Validation rule não roda em field update de approval process.** Nenhuma das 4 regras impede o diretor financeiro de **aprovar** a etapa 1 com os campos vazios. Elas só disparam quando alguém salva o registro. Foi assim que `ECT-000080` chegou a `Pendente - Diretor comercial` sem os dois campos.

## 5. Explicação do erro do print 1

`ECT-000080` estava em `Pendente - Diretor comercial`, ou seja, a etapa 1 já tinha sido aprovada. Com `recordEditability = AdminOrCurrentApprover`, o diretor financeiro já não era o aprovador da etapa atual. Na dev, o perfil dele (`Admin`) **não** tem Modify All no objeto (`ObjectPermissions`: `PermissionsEdit=true`, `PermissionsModifyAllRecords=false`; `Profile.PermissionsModifyAllData=false`), então ele não edita registro travado, e a mensagem é a padrão de privilégio. Isso confirma a regra de negócio do e-mail: o preenchimento precisa acontecer **durante** a etapa 1, enquanto ele é o aprovador atual. Falta à configuração atual um mecanismo que impeça a aprovação sem os campos.

## 6. Permissões de campo (FLS): divergência dev × produção

`FieldPermissions` com `PermissionsEdit = true`:

| Campo | Quem edita na dev |
|---|---|
| `Responsavel_pelo_Custo__c` | perfil `Admin` e permission set `DiretorComercial` (1 atribuição ativa, que não é de nenhum dos aprovadores da v2_3) |
| `Ressalvas_do_Diretor_Financeiro__c` | só o perfil `Administração` (que tem `PermissionsModifyAllData = true`). Nem `Administrador do sistema` tem edit. |

**Divergência.** Na dev, o diretor financeiro tem perfil `Admin`: **edita "Responsável pelo custo", mas não tem FLS para editar "Ressalvas"**. No print 2 da produção, porém, as regras `_se_Walmor` (perfil `Administração`) disparam para ele e ele consegue alterar "Responsável pelo custo". **Na produção, o perfil dele e/ou o FLS são diferentes da dev.** Não dá para afirmar qual é o estado da produção. A consequência confirmada é que **a dev não reproduz a produção em perfil, atribuição e FLS**, e uma solução baseada em perfil se comportaria de forma diferente em cada org.

Outros dados de permissão:
- Perfil `Diretor Comercial`: **sem** Edit no objeto.
- Permission sets do objeto que já existem: `Excecao_Comercial_Criacao` (7 atribuições ativas), `Viewing_permission_Excecao_comercial_para_atendimento_tecnico` (6), `DiretorComercial` (1). Nenhum deles é atribuído aos aprovadores da v2_3 na dev.
- Custom permissions na org: só 2, ambas de pacote gerenciado (Conga). **Não existe custom permission para este processo.**

## 7. Automação no mesmo objeto (risco de ordem de execução)

| Tipo | Componente | Estado | Evento |
|---|---|---|---|
| Record-triggered Flow | `SLA_2` (label `SLA_v1.3`, API 55.0) | **Ativo** | **After-save, Update**. Entra quando `Status_de_Aprovacao__c` muda para `Pendente - Gerente de serviço`, `Pendente - Diretor comercial` ou `Pendente - Diretor financeiro`. Tem 13 scheduled paths relativos a `Data_Hora_do_SLA_Solicitado__c` e só dispara email alerts (`SLA_vencendo_*`, `SLA_vencido_*`). Não altera o registro. Sem `triggerOrder` definido. |
| Record-triggered Flow | `SLA_3`, `SLA_4`, `SLA_5` | inativos | After-save Create/Update |
| Workflow rule | `SLA` | inativa | — |
| Field updates / email alerts | 17 field updates e 8 alerts em `Workflow:Excecao_Comercial_p_Atendimento_Tecnico__c` | usados pelo approval process e pelos Flows de SLA | — |
| Apex trigger | — | **nenhum** (`ApexTrigger WHERE TableEnumOrId = ...` voltou 0) | — |
| Apex class | — | nenhuma dependência (`MetadataComponentDependency` lista só os 5 email templates e os Flows de SLA) | — |
| Process Builder | — | nenhum encontrado (não aparece em `FlowDefinitionView` por objeto nem em `MetadataComponentDependency`) | — |

Email templates da pasta `Excecao_Comercial_p_Atendimento_Tecnico` (5): nenhum cita o antigo nem o atual diretor pelo nome (busca textual nos arquivos do retrieve).

O assessment da org (2026-09-30) aponta alto acoplamento em **Oportunidade** e 59 Process Builders. **Este objeto não está nesse quadro.** Aqui a automação é pequena: um Flow ativo, um approval process ativo e 4 validation rules.

## 8. O que não foi possível confirmar

- **Estado da produção:** versão ativa do approval process, perfil do diretor financeiro, FLS dos dois campos, quantas ECT estão hoje em `Pendente - Diretor comercial`/`Aprovado` com os campos vazios, e se `ECT-000080` já foi corrigido desde o e-mail de setembro. Produção é proibida ao agente (guardrail #1).
- **Sandbox de QA:** não está conectada nesta sessão, então não foi inspecionada.
- **Disparo de Flow em field update de approval:** se um record-triggered Flow after-save dispara na field update `Status_e_Etapa_Diretor_comercial` e se o Custom Error desfaz a aprovação. É comportamento de plataforma, ainda não provado nesta org. Vira a primeira tarefa do build (ver design).
- **Observação lateral, não investigada:** a fórmula `Data_Hora_do_SLA_Solicitado__c` compara com `"8 horas"`, `"12 horas"` e `"24 horas"` em minúsculas, enquanto a picklist tem `8 Horas`, `12 Horas` e `24 Horas`. O print de produção mostra o SLA de 24 h calculado certo, então pode não haver efeito. Fica fora desta demanda.
