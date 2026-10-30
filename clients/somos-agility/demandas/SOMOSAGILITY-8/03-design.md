# SOMOSAGILITY-8 — Design: DEPV, ajuste no fluxo de aprovação

- **Cliente:** somos-agility · **Tipo:** sustentação (design enxuto)
- **Base:** `01-analise.md` (aprovado), `02-recon.md` (coleta de 2026-10-30 em `sbx-somos-agility-dev`), anexo do card (estrutura dos templates; nenhum nome, e-mail ou telefone transcrito)
- **Mudança de modelo de dados:** **nenhuma**. O campo `Classificacao_Gerencial__c` e todos os campos dos templates já existem. Não há campo, objeto ou valor de picklist novo.

---

## 1. Leitura do problema depois do recon

O recon mudou três coisas em relação à análise:

1. **Não existe etapa "Diretor Financeiro" no processo ativo.** `Qualificacao_DEPV_v7_6` tem três etapas: Sales Op. → Diretor(a) comercial → **Operações (Financeiro)**. A etapa financeira é a 3ª, `Qualificacao_Operacoes_Financeiro`. O aprovador dela tem perfil `Compras Financeiro`, que é um dos quatro perfis que veem a seção "Exclusivo CEO" onde está o campo. O template do anexo para a 3ª etapa também avisa o grupo Operações: "Não deixe de preencher o campo Classificação Gerencial". Daqui vem a **premissa D1**: "Diretor financeiro no ato da aprovação" = aprovação da etapa 3. É premissa, não fato confirmado (ver seção 7).
2. **A notificação de aprovação usa o e-mail padrão da Salesforce.** A v7_6 não declara `emailTemplate`; as versões anteriores declaravam. Por isso o layout "sumiu".
3. **Já houve uma tentativa de forçar o campo e ela não funciona.** A validation rule `Checa_Classificacao_Gerencial_se_Soto` depende de um status (`Pendente`) que não existe mais. Além disso, validation rule não roda em field update de approval process.

## 2. Decisão e justificativa

### 2.1 RN1: Classificação Gerencial obrigatória na aprovação da etapa financeira

**Decisão: Flow record-triggered before-save com elemento Custom Error. Antes de construir, um spike de no máximo 2 h prova que o Flow bloqueia a aprovação. Se o spike falhar, o fallback é um trigger Apex.**

| Nível | Opção | Por que sim ou não |
|---|---|---|
| Configuração | Validation rule | **Descartada.** Aprovar não salva o registro pela UI. A gravação vem do field update do approval process, e validation rule custom não é reavaliada nesse caminho. É exatamente por isso que a VR atual nunca protegeu nada. |
| Configuração | Critério de entrada da etapa / required no layout | **Descartada.** Critério de entrada decide se a etapa roda, não bloqueia quem aprova. O required da página (Dynamic Forms) só vale quando alguém edita e salva, e o botão Aprovar não passa por ele. |
| **Declarativo** | **Flow before-save + Custom Error** | **Escolhida.** Dispara na transição de saída da etapa 3. Se `Classificacao_Gerencial__c` estiver vazio, levanta erro: a transação do approve sofre rollback e a DEPV continua pendente na etapa 3. Fica no nível declarativo e não exige classe de teste. |
| Código | Trigger before update + handler Apex com `addError` | **Fallback.** Trigger roda em field update de approval process, então o comportamento é garantido. Só desce para cá se o spike mostrar que o Flow não dispara nessa gravação ou que o erro não chega ao aprovador. Custo extra na seção 9. |

**Por que o spike:** o comportamento de Flow record-triggered em gravação vinda de approval process é o único ponto que eu não consigo confirmar por leitura de metadata. Prefiro medir na dev a afirmar. O spike responde três perguntas:
- (a) o Flow dispara no approve da etapa 3?
- (b) o Custom Error impede a aprovação e a DEPV continua em `Pendente - Operações`?
- (c) o aprovador vê a mensagem na tela de aprovação do Lightning?

Se as três forem "sim", fica o Flow. Se qualquer uma for "não", o builder para e volta ao arquiteto humano com o resultado antes de escrever Apex. Descer de nível não acontece em silêncio.

**Condição do Flow (candidata, o spike fixa a versão final):** em update, `PRIOR(Status_da_Qualificacao__c) = 'Pendente - Operações'` e o novo valor é `Aprovado`, **ou** `Status__c` muda para `Fechado` com `Status_da_Qualificacao__c = 'Pendente - Operações'`; em ambos os casos com `Classificacao_Gerencial__c` vazio. As duas formas existem porque a etapa 3 grava `Status__c = Fechado` como ação do step e só depois a aprovação final grava `Aprovado`. O spike mostra qual gravação o Flow enxerga. Rejeição (`Rejeitado`) e as etapas 1 e 2 nunca são bloqueadas.

**Como o aprovador preenche:** a etapa 3 já permite edição pelo aprovador da vez (`recordEditability = AdminOrCurrentApprover`). O perfil dele (`Compras Financeiro`) vê a seção "Exclusivo CEO" e tem FLS de edição. O fluxo do aprovador fica: abre a DEPV, preenche o campo, salva e aprova. Se tentar aprovar sem preencher, recebe a mensagem e nada avança.

### 2.2 RN2, RN3 e RN4: notificações

**Decisão: 100% configuração.** Templates Classic HTML na pasta existente, Email Alerts no workflow do objeto e ações no approval process ativo. Não precisa de Flow nem de código.

Os templates continuam **Classic**, não Lightning, por dois motivos:
- os templates existentes já são Classic;
- os merge fields `{!ApprovalRequest.Comments}`, necessários para "Comentários", só existem nos templates Classic usados por approval process.

Mapeamento proposto (**premissa D2**, ver seção 7):

| Bloco do anexo | Quando dispara | Mecanismo | Para quem |
|---|---|---|---|
| "Notificação de aprovações – 1ª e 2ª" | entrada nas etapas 1 e 2 | (i) template de atribuição do processo, que vai para o aprovador da vez, e (ii) Email Alert novo nas ações de submissão inicial e de aprovação da etapa 1 | aprovador da vez + 1 destinatário nomeado + Agility GOV |
| "Notificação de aprovações – 3ª" | aprovação da etapa 2 (entrada na etapa 3) | Email Alert novo nas ações de aprovação de `Qualificacao_CEO` | Operações (usuário aprovador da etapa 3) + 3 destinatários nomeados + Agility GOV |
| "Notificação final / Aprovada" | aprovação final | Email Alert existente, só com o template ajustado | destinatários de hoje, sem mudança (owner + 3 usuários) |

Por que a 3ª notificação dispara **na entrada da etapa 3** e não depois da aprovação final: o texto pede ao grupo Operações que preencha a Classificação Gerencial. Depois da aprovação final o registro fica travado (`finalApprovalRecordLock = true`) e Operações não conseguiria preencher. Na entrada da etapa 3, Operações é justamente quem vai aprovar e preencher, o que fecha com o RN1. Se o cliente quiser a outra leitura (disparo na aprovação final), basta mover o alert de "ações da etapa 2" para "ações finais". O custo é o mesmo.

## 3. Componentes

Todos os API names abaixo foram confirmados na dev, exceto os marcados **[novo]**.

### Criar

| Tipo | API name | Conteúdo |
|---|---|---|
| Flow (record-triggered, before-save, update) **[novo]** | `DEPV_BeforeSave_ClassificacaoGerencialObrigatoria` | Condição da seção 2.1 + Custom Error no campo `Classificacao_Gerencial__c`. Mensagem sugerida: "Preencha a Classificação Gerencial antes de aprovar." Texto final a confirmar (pergunta 1 da seção 7). O prefixo `DEPV_` segue o precedente da própria org (`Submete_DEPV_para_aprovacao`, `Atualiza_o_status_da_DEPV`) em vez do nome completo do objeto. |
| EmailTemplate Classic HTML **[novo]** | `Despesa_Extraordinaria_de_Pre_Venda/DEPV_Notificacao_3a_Aprovacao` | Layout "3ª Aprovação" do anexo: "Prezados", "foi Aprovada!", os campos do template 1ª/2ª, `Comentários: {!ApprovalRequest.Comments}`, bloco em destaque "Atenção Grupo Operações / Seguir com as devidas tratativas operacionais / Não deixe de preencher o campo Classificação Gerencial" e `{!Despesa_Extraordinaria_para_Pre_Venda__c.Link}`. Assunto no padrão dos existentes. |
| WorkflowAlert **[novo]** | `DEPV_Notificacao_1a_2a_Aprovacao` | Template `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda`. Destinatários: 1 usuário nomeado + Agility GOV como e-mail adicional (ver R4). Remetente: o mesmo Org-Wide Address do alert `..._Aprovada`. |
| WorkflowAlert **[novo]** | `DEPV_Notificacao_3a_Aprovacao` | Template `DEPV_Notificacao_3a_Aprovacao`. Destinatários: usuário de Operações (aprovador da etapa 3) + 3 usuários nomeados + Agility GOV como e-mail adicional. Mesmo remetente Org-Wide. |

### Alterar

| Tipo | API name | Alteração |
|---|---|---|
| EmailTemplate | `Despesa_Extraordinaria_de_Pre_Venda/Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda` | Layout "1ª e 2ª Aprovação" do anexo. **Inclui:** `Name` (ID), `OwnerFullName` (Proprietário) e `Oportunidade__c` (Oportunidade). **Mantém:** Justificativa, Recuperação, `Valor_Total__c` (Nominal Terceiros), `Valor_Efetivo_Agility__c` (Nominal Agility), `Valor_Total_Integral__c` (Valor Total) e Link. **Remove** o bloco "Atenção CEO", que o anexo não tem. Hoje só versões inativas usam este template, então alterá-lo não muda nada em produção até a v7_6 apontar para ele. |
| EmailTemplate | `Despesa_Extraordinaria_de_Pre_Venda/Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda_Aprovada` | Ajuste de layout ao bloco "Notificação final / Aprovada" do anexo, que já é quase idêntico. A diferença é a saudação: hoje "Olá `{!CreatedBy}`", e o anexo pede "Olá, <nome>,". Manter `CreatedBy` ou trocar por `OwnerFullName` depende da pergunta 5. |
| ApprovalProcess | `Despesa_Extraordinaria_para_Pre_Venda__c.Qualificacao_DEPV_v7_6` | (1) `emailTemplate` = `Despesa_Extraordinaria_de_Pre_Venda/Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda`; (2) `initialSubmissionActions` + alert `DEPV_Notificacao_1a_2a_Aprovacao`; (3) `approvalActions` do step `Qualifica_o_Sales_Op` + alert `DEPV_Notificacao_1a_2a_Aprovacao`; (4) `approvalActions` do step `Qualificacao_CEO` + alert `DEPV_Notificacao_3a_Aprovacao`. **Steps, aprovadores, critérios e field updates não mudam.** |
| Workflow (container) | `Despesa_Extraordinaria_para_Pre_Venda__c` | Recebe os 2 alerts novos. Alerts e field updates existentes ficam intactos. |

### Depreciar

| Tipo | API name | Ação |
|---|---|---|
| ValidationRule | `Despesa_Extraordinaria_para_Pre_Venda__c.Checa_Classificacao_Gerencial_se_Soto` | **Desativar** (`active=false`), sem excluir. Ela nunca dispara (seção 5 do recon) e é a regra que o Flow novo substitui. Mantê-la ativa só confunde quem for dar manutenção. O comportamento não muda e a reversão é trivial. |

### Não tocar (registrado para não regressão)

Os alerts `..._Rejeitada`, os field updates de status, as 12 versões inativas do processo, os dois Flows DEPV sem versão ativa, o layout clássico e a record page.

## 4. Conflito de automação e ordem de execução

- **Hoje não há trigger nem Flow ativo em `Despesa_Extraordinaria_para_Pre_Venda__c`.** O Flow novo é a primeira automação record-triggered do objeto, então não há disputa de ordem com outro Flow ou trigger.
- **O ponto sensível é a interação Flow × field update do approval process.** O Flow novo vai rodar dentro da gravação que o approve gera (step 3 grava `Status__c`; final grava `Status_da_Qualificacao__c` e `Status__c`). É exatamente isso que o spike valida. Se o Flow não rodar nessa gravação, a regra não protege nada, igual à VR atual. Por isso o build **não segue** sem o spike verde.
- O Flow é before-save e só lê e erra: não faz DML nem SOQL, então não dispara recursão nem cascata.
- `SolicitacaoMudancaTriggerHandlerTest` insere uma DEPV. O Flow é só de update e não afeta o teste.

## 5. Limites e escala

- Approval é registro a registro. O Flow before-save não consome SOQL nem DML, e em lote (por exemplo, aprovação em massa pela lista "Itens a aprovar") cada registro é avaliado isoladamente, sem risco de limite.
- Cada aprovação gera até 2 e-mails a mais (assinatura + alert). Isso está muito abaixo do limite diário de e-mails da org pelo volume esperado. O volume de produção não foi medido (recon, seção 7) e o risco é baixo.
- No fallback Apex, o handler terá de ser bulkificado (sem SOQL) e testado com 200 registros.

## 6. Impacto em permissões

- **Nenhum permission set ou perfil novo.** A FLS de `Classificacao_Gerencial__c` já é leitura e edição em todos os perfis. O Flow roda no contexto de sistema.
- **Visibilidade na UI é o risco:** só os perfis `Administração`, `Admin`, `adminPMO` e `Compras Financeiro` veem a seção "Exclusivo CEO". O aprovador da etapa 3 na dev tem `Compras Financeiro`, então funciona. **Se em produção quem aprova a etapa financeira tiver outro perfil** (existe um perfil `Diretor Financeiro`, sem usuário ativo na dev), ele será bloqueado pelo Flow e não verá o campo para preencher. Nesse caso o perfil entra no filtro de visibilidade da seção na `Despesa_Extraordin_ria_de_Venda_Record_Page`. Isso é 1 alteração de configuração (~0,5 h) e só entra com confirmação (pergunta 2).

## 7. Perguntas da análise: o que o recon respondeu e o que vira premissa

| # | Pergunta | Situação |
|---|---|---|
| 1 | Etapa do Diretor Financeiro | **Premissa D1:** é a etapa 3, `Qualificacao_Operacoes_Financeiro` (evidência na seção 1). **Fechar antes do build**, junto com o texto da mensagem de erro. |
| 2 | Campo existe? | **Respondida:** `Classificacao_Gerencial__c`, picklist com 2 valores, já em layout e record page. Não precisa criar. Perfil de quem aprova em produção: pendente (seção 6). |
| 3 | API name do objeto | **Respondida:** `Despesa_Extraordinaria_para_Pre_Venda__c`, prefixo `a2C`. |
| 4 | Mecanismo das notificações | **Respondida:** Approval Process nativo + Email Alerts + templates Classic HTML. A atribuição usa o e-mail padrão (sem template). Não há Apex nem Flow. |
| 5 | Aprovador seguinte continua recebendo? Soma ou substitui? | **Premissa D3:** continua recebendo (e-mail de atribuição) e os novos destinatários **somam**. No alert final, os destinatários de hoje ficam. Ajuste da saudação (criador ou owner) a confirmar. |
| 6 | Destinatários nomeados: usuários ou externos? | **Parcial:** das pessoas nomeadas, 2 batem com usuários ativos e 1 já está no alert final (recon, seção 4). **Agility GOV é externo.** A identificação definitiva de cada usuário vem do consultor pelo card, sem e-mail no artefato. **Fechar antes do build.** |
| 7 | Grupos são Public Groups? | **Respondida:** não. Operações = usuário funcional (aprovador da etapa 3). Agility GOV = lista externa, que entra como e-mail adicional do alert. |
| 8 | Template "final / Aprovada" é distinto? | **Respondida pelo recon:** é o template `..._Aprovada` existente, disparado na aprovação final ao owner. Convive com a 3ª notificação. Momento de disparo da 3ª = **premissa D2** (seção 2.2). |
| 9 | Origem de "Comentários" | **Respondida:** `{!ApprovalRequest.Comments}`, o comentário do aprovador que acabou de aprovar. Não é campo novo. Validar no build que o merge resolve dentro de alert de ação de step (R5). |
| 10 | Link e URL base | **Respondida:** `{!Despesa_Extraordinaria_para_Pre_Venda__c.Link}` resolve para a URL da própria org (dev, qa ou produção), sem URL fixa. |
| 11 | DEPVs em andamento | **Premissa D4:** a regra vale para qualquer aprovação da etapa 3 a partir do deploy, inclusive DEPVs que já estiverem nela. O novo layout vale para os próximos disparos. Antes do deploy em produção, alguém com acesso conta as DEPVs pendentes na etapa 3 (só `COUNT()`). |
| 12 | Campos de valor existem? Formato | **Respondida:** os 3 campos de valor existem como fórmulas Currency (atenção à troca de rótulo × API name, recon seção 1). O formato vem da moeda e da localidade da org no merge Classic. |
| 13 | Aviso a Operações: texto ou tarefa? | **Premissa D5:** só texto no corpo da 3ª notificação, como no anexo. Não cria Task. |
| 14 | Layout de referência | **Respondida:** o anexo traz os três blocos com ordem e rótulos. Destaques (negrito, vermelho) serão reproduzidos em HTML simples. |
| 15 | Quem homologa | **Aberta:** o consultor define pelo card. Não bloqueia o build, bloqueia o gate de QA. |
| 16 | Prazo | **Aberta:** o anexo veio com prioridade alta e sem data. Não bloqueia o design. |

**Para fechar antes de começar o build:** 1 (D1 + mensagem de erro) e 6 (quem é cada destinatário). As demais seguem como premissas declaradas e são corrigíveis durante o build sem refazer o design.

## 8. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **Flow não dispara ou não bloqueia na gravação gerada pelo approve.** Nesse caso o RN1 não fica protegido, como acontece com a VR atual. | **Alta** | Spike obrigatório antes do build (seção 2.1). Se falhar, o fallback Apex volta ao arquiteto humano antes de ser escrito. |
| R2 | **D1 errada:** o "Diretor financeiro" não é a etapa 3. | **Alta** | Confirmar antes do build (pergunta 1). Trocar de etapa muda só a condição do Flow. |
| R3 | **Teste em sandbox dispara e-mail real para a lista Agility GOV.** E-mail adicional de alert não recebe o sufixo `.invalid` como os usuários. | **Alta** | Na dev e na qa, o e-mail adicional do alert aponta para uma caixa de teste do squad. O endereço real da lista entra **só** no deploy de produção, feito por humano, como passo manual pós-deploy documentado em `06-entrega.md`. |
| R4 | O endereço da lista externa fica dentro do XML de workflow em `force-app/`. Não é `.md`, então o scan de PII não pega, mas é um e-mail no repositório. | Média | Consequência de R3: no repositório só fica o endereço de teste. O real é configurado à mão em produção. Se o humano preferir versionar o real, a decisão é dele. |
| R5 | `{!ApprovalRequest.Comments}` pode vir vazio num alert de ação de step (hoje só é usado na ação final). | Média | Validar no spike. Se vier vazio, a alternativa declarada vai ao humano: omitir "Comentários" na 3ª notificação ou movê-la para a aprovação final (leitura D2 alternativa). |
| R6 | Deploy de approval process **ativo** pode ser recusado pela Metadata API. | Média | Os steps não mudam, só ações e template, o que normalmente é aceito. Se for recusado, clonar como `Qualificacao_DEPV_v7_7`, ativar e desativar a v7_6, seguindo o padrão de versões que a org já usa. DEPVs em andamento seguem na v7_6. |
| R7 | O aprovador da etapa 3 recebe 2 e-mails ao entrar na etapa: a atribuição (layout 1ª/2ª, porque o template de atribuição é único por processo) e a 3ª notificação. | Baixa | Aceitar e comunicar. Template de atribuição condicional por etapa exigiria Visualforce template, fora do escopo. |
| R8 | A dev pode divergir de produção (processo ativo, usuários aprovadores, perfis). | Média | Conferir na qa antes da homologação. O deploy de produção é humano. |
| R9 | Na dev e na qa, os usuários estão com e-mail `.invalid`, então o QA não vê a notificação na caixa do destinatário. | Baixa | O QA usa usuário de teste com caixa do squad ou confere no log de e-mail. Nunca screenshot de registro real (guardrail #2). |

## 9. O que NÃO será feito nesta demanda

- Mudar quem aprova cada etapa, a ordem das etapas, os critérios de entrada ou recall.
- Criar campo, valor de picklist ou Public Group, ou cadastrar a lista Agility GOV como usuário ou contato.
- Template de atribuição diferente por etapa (Visualforce).
- Migrar o approval process para Flow Approvals / Orchestration.
- Limpar as 12 versões inativas do processo, os Flows DEPV sem versão ativa e os field updates legados com nomes fixos (dívida registrada; ver também o item 9 do `assessment.md`).
- Alterar a notificação de rejeição.
- Rastrear histórico de `Classificacao_Gerencial__c` (não foi pedido).
- Qualquer coisa em produção (guardrail #1).

## 10. Estimativa refinada

**Estimativa de esforço:** 10–18 h

| Bloco | h |
|---|---|
| Spike Flow × approve na dev | 1–2 |
| Flow + desativar VR | 1–2 |
| 2 templates ajustados + 1 novo | 2–4 |
| 2 alerts + 4 ajustes no approval process (inclui eventual clone v7_7) | 1,5–3 |
| Teste na dev e na qa (3 etapas × aprovar/rejeitar/sem campo, com caixa de teste) | 3–4,5 |
| Pacote, PR, passo manual de produção, documentação | 1,5–2,5 |

**O que mudou em relação à análise (6–14 h):**
- **Caiu:** o campo já existe com valores definidos, não há modelo de dados novo, os grupos não precisam ser criados e o mecanismo é 100% declarativo hoje.
- **Subiu:**
  - O RN1 não se resolve com validation rule (seção 2.1). Exige Flow com spike, e o spike pode empurrar para Apex.
  - A 1ª/2ª notificação precisa de alert extra em duas ações, porque o template de atribuição só vai ao aprovador.
  - Há um template novo (3ª aprovação).
  - O teste de e-mail em sandbox precisa de caixa de teste para não atingir a lista real.
- **Se o spike falhar e cair no fallback Apex** (trigger + handler + teste ≥ 85%): +4–6 h, faixa de 14–24 h. Esse cenário volta ao arquiteto humano antes de ser executado.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
