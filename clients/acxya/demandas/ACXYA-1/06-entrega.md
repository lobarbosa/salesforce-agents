# ACXYA-1 — Entrega

**Demanda:** Criação de campo de data de aniversário do prospect no objeto Lead  
**Cliente:** Konecta (workspace acxya)  
**Org de implantação:** `sbx-acxya` (Sandbox)  
**Org Id:** `00DHa000006bRsDMAU`  
**API:** v67.0  
**Data de implantação:** 2026-09-07  
**Deploy ID:** `0AfHa00000DWpzBKAT`  
**Branch:** `feature/ACXYA-1`  
**Status:** Homologação aprovada (Leonardo, 2026-09-07)

---

## 1. Resumo executivo

**O que foi pedido:** Um campo para permitir que usuários insiram e registrem a data de nascimento (aniversário) do prospect diretamente no objeto Lead, conforme solicitação registrada pela operação comercial.

**O que foi entregue:** Um campo custom `Data_Aniversario__c` (tipo Date) no objeto Lead, com Validation Rule bloqueando datas futuras, mapeamento automático para `Contact.Birthdate` na conversão de Lead, visibilidade controlada por Field-Level Security (FLS) limitada a 4 perfis de negócio, e posicionamento no layout de Lead.

**Resultado dos testes:** 16 de 16 casos de teste executados com sucesso. Zero falhas. Nenhuma regressão identificada.

**Implantação:** Metadata implantada em sandbox `sbx-acxya`. **Produção não foi configurada e não foi tocada — está fora do escopo de qualquer agente deste squad.**

---

## 2. Componentes entregues

| # | Tipo | API name | Objeto | O que faz | Localização no repo |
|---|---|---|---|---|---|
| 1 | CustomField | `Data_Aniversario__c` | Lead | Campo para registrar data de nascimento do prospect. Tipo Date, opcional, sem rastreamento de histórico (decisão de LGPD — minimização de cópias de dado pessoal). | `force-app/main/default/objects/Lead/fields/Data_Aniversario__c.field-meta.xml` |
| 2 | ValidationRule | `Valida_Data_Aniversario_Nao_Futura` | Lead | Valida que a data não é futura. Ativa desde o deploy. Escopo restrito a `ISNEW() OR ISCHANGED()` para não travar updates reentrantes de integração em registros antigos. | `force-app/main/default/objects/Lead/validationRules/Valida_Data_Aniversario_Nao_Futura.validationRule-meta.xml` |
| 3 | Layout | `Lead-Lead Layout` | Lead | Inclui o campo novo na seção "Lead Information", coluna 2, imediatamente após "Email". Comportamento: Edit. | `force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml` |
| 4 | Profile | `Admin` | — | Field-Level Security: Read+Edit no campo novo. | `force-app/main/default/profiles/Admin.profile-meta.xml` |
| 5 | Profile | `System Administrator (non-API user)` | — | Field-Level Security: Read+Edit no campo novo. | `force-app/main/default/profiles/System Administrator %28non-API user%29.profile-meta.xml` |
| 6 | Profile | `Standard` | — | Field-Level Security: Read+Edit no campo novo. | `force-app/main/default/profiles/Standard.profile-meta.xml` |
| 7 | Profile | `MarketingProfile` | — | Field-Level Security: Read+Edit no campo novo. | `force-app/main/default/profiles/MarketingProfile.profile-meta.xml` |
| 8 | Flow | `Lead_AfterSave_MapeiaAniversarioNaConversao` | Lead | Flow autolaunched, record-triggered after-save. Dispara quando: Lead é convertido (`IsConverted=true`), Contact vinculado preenchido, e o campo `Data_Aniversario__c` tem valor. Ação: atualiza `Contact.Birthdate` com o valor do campo do Lead (comportamento de sobrescrita confirmado como intencional). | `force-app/main/default/flows/Lead_AfterSave_MapeiaAniversarioNaConversao.flow-meta.xml` |

**Total:** 8 componentes criados/alterados. Nenhum componente foi removido ou deprecado.

---

## 3. Como a solução funciona — fluxo do processo

### 3.1 Criação e edição do Lead (campo)

1. Usuário acessa um registro de Lead (existente ou novo).
2. Campo `Data de Aniversário` aparece no layout, na seção "Lead Information" (se o perfil tiver FLS).
3. Usuário preenche a data (formato de data, conforme org settings).
4. Ao salvar o Lead:
   - **Validation Rule `Valida_Data_Aniversario_Nao_Futura` avalia:** 
     - Se o Lead é novo (`ISNEW()`) OU o campo foi alterado (`ISCHANGED(Data_Aniversario__c)`), E
     - O campo tem valor (não está em branco), E
     - A data é futura (maior que `TODAY()`)
     - → Então: save é bloqueado com mensagem "A data de aniversário não pode ser uma data futura", ancorada no campo.
   - Se a regra não dispara, o valor é gravado normalmente.

### 3.2 Conversão de Lead → Contact

1. Usuário ou processo de integração converte o Lead.
2. **Flow `Lead_AfterSave_MapeiaAniversarioNaConversao` dispara:**
   - Critério: Lead agora tem `IsConverted=true` E `ConvertedContactId` preenchido E `Data_Aniversario__c` tem valor.
   - Ação: atualiza o Contact gerado/vinculado, gravando `Contact.Birthdate = Lead.Data_Aniversario__c`.
3. **Comportamento de sobrescrita:** se o Contact já tinha um `Birthdate` de outra fonte, ele é sobrescrito. Este é o comportamento pretendido (confirmado pelo consultor no gate de homologação).
4. Conversão conclui normalmente.

### 3.3 Integração com Marketing Cloud e WhatsApp

- O campo é **novo** — nenhuma integração o conhece ainda.
- **Proteção declarada:** o guard `ISNEW()/ISCHANGED()` na Validation Rule garante que ela só dispara quando o campo é efetivamente tocado. Um registro que, por qualquer caminho, já tenha ficado com data futura gravada **continua podendo ser atualizado em outros campos** — a VR não trava o registro inteiro; ela só volta a bloquear se alguém alterar a própria `Data_Aniversario__c` para um valor futuro. Isso é exatamente o que T-09 provou empiricamente (§6).
- FLS sob B-4 P-2 (minimização) garante que perfis de integração não veem o campo — não conseguem sujá-lo.

---

## 4. Decisões de design e suas justificativas

### B-1: Mapeamento na conversão — Opção 2 (Flow after-save)

**Decisão:** O campo `Lead.Data_Aniversario__c` é mapeado para `Contact.Birthdate` via Flow record-triggered after-save no Lead, não via `LeadConvertSettings` nativa.

**Por quê:** A configuração nativa `LeadConvertSettings` só aceita mapeamento **custom → custom**. O `Contact.Birthdate` é campo padrão (não custom). A API Metadata confirmou a rejeição explícita: `"The field needs to be a custom"`. Logo, o mapeamento nativo não é executável. A Opção 2 (Flow) resolve o requisito de forma declarativa (nível 2 da doutrina — aceitável porque o nível 1 não oferece a ferramenta).

**Trade-off aceito:** Flow after-save adiciona um terceiro automação after-save no objeto Lead (os outros dois são `Leads_do_Marketing_Cloud` e `Count_de_Tasks_Pendentes`). Sem `<triggerOrder>` versionado (rejeitado pela API v67.0), a ordem de execução entre os 3 não é garantida por metadata. Mitigação: os 3 flows **não escrevem em campos sobrepostos**, logo a ordem relativa não afeta o resultado. Confirmado empiricamente em T-16 (3 repetições, resultado idêntico).

### B-2: Validation Rule — ativa desde o deploy, com guarda `ISNEW()/ISCHANGED()`

**Decisão:** Validation Rule `Valida_Data_Aniversario_Nao_Futura` nasce `<active>true</active>` e a fórmula inclui `OR(ISNEW(), ISCHANGED(Data_Aniversario__c))`.

**Por quê:** O CA-04 (bloquear data futura) deve ser atendido no deploy, não em passo manual depois. Ativar a VR desde o deploy é a escolha de menor risco operacional.

**O guard `ISNEW()/ISCHANGED()`:** garante que a regra só dispara quando o campo é efetivamente tocado. Se um valor inválido (data futura) entrar por um caminho que ignore a VR (improvável, mas possível), e ficasse gravado, a regra `ISNEW()/ISCHANGED()` permitiria que outros campos do registro fossem atualizados sem travar em erro. Sem o guard, a regra dispararia a cada save de um registro "envenenado", criando uma condição permanente de não-salvabilidade. Cenário improvável hoje (campo é novo), mas mitigação pura e simples.

### B-3: Campo é opcional, não obrigatório

**Decisão:** `<required>false</required>` no CustomField e `behavior=Edit` (não `Required`) no layout.

**Por quê:** Nenhuma regra de negócio da demanda exige que o campo seja preenchido sempre. Criação de Lead por integração (Marketing Cloud, WhatsApp) continua funcionando sem quebras. Obrigatoriedade pode ser ativada depois se o negócio pedir, sem custo de retrabalho — é reversível.

**Risco evitado:** Field obrigatório + Validation Rule bloqueando data futura = risco de o Marketing Cloud (que cria Leads) passar a tentar preencher este campo com um valor sujo (data futura), levando a erro de integração. Mantê-lo opcional hoje mitiga esse cenário.

### B-4: Field-Level Security — minimização (P-2)

**Decisão:** `Data_Aniversario__c` tem Read+Edit nos seguintes 4 perfis apenas:
- `Administrador do sistema`
- `System Administrator (non-API user)`
- `Usuário Padrão`
- `Usuário do Marketing`

**Nenhum perfil de integração recebe FLS no campo novo.**

**Por quê:** Data de nascimento é dado pessoal (LGPD art. 5º, I). Conformidade exige minimização de acesso — só quem opera Lead com humano (usuários de negócio) precisa ver o dado. Perfis de integração (API-only, Analytics Cloud, etc.) não precisam e não devem ter acesso. Reversível — se no futuro um processo precisar escrever no campo, FLS pode ser expandida para ele, com nova decisão documentada.

---

## 5. Visibilidade / Permissões

### Object Permissions
O campo fica dentro do objeto Lead, que já tem suas Object Permissions definidas:
- Perfis com **Edit** em Lead (7 perfis): os 4 acima + `Gerente de soluções`, `Gerente do contrato`, `Sales Insights Integration User`.
- Perfis com **Read Only** em Lead: `Read Only`, `surveys2 Perfil`, `Analytics Cloud Security User`, `Analytics Cloud Integration User`.
- Perfis com **No Access** em Lead: não enumerados, acesso bloqueado no nível de objeto.

### Field-Level Security
Restrição **adicional** ao nível de campo:
- **Read+Edit:** exatamente 4 perfis de negócio (acima).
- **Nenhuma permissão:** todos os outros perfis, incluindo perfis de integração com Edit em Lead (ex.: `Sales Insights Integration User` tem Edit em Lead, mas **não** tem FLS em `Data_Aniversario__c`).

**Resultado:** apenas os 4 perfis de negócio enxergam e podem editar o campo. Um perfil de integração com Edit em Lead não conseguirá acessar este campo via API (nem via query SOQL, nem via update/insert).

---

## 6. Evidência de teste

**Execução:** 16 casos de teste, T-01 a T-16, executados contra metadata real pós-deploy em `sbx-acxya`.

**Resultado:** 16/16 PASSOU, 0 FALHOU.

**Ressalvas declaradas (não são falhas):**
- **T-01, T-03, T-12:** Casos de FLS e layout. Confirmados por API/metadata (XML do layout, query de `FieldPermissions`, query de `ObjectPermissions`) — o que a doutrina permite para comprovar permissão sem dado pessoal. **Verificação visual de tela (um usuário de fato logado vendo o campo no layout) não foi possível** neste ambiente sem UI/"Login As" — recomendação pós-deploy: um "Login As" por perfil (2-3 min) antes da homologação visual final, já sinalizado em `06-release.md` §6.3.
- **T-04:** Casos negativos (perfis que NÃO devem ter FLS). Confirmado por API: 0 registros retornados para os 4 perfis de integração/API — prova conclusiva de ausência de FLS.

**Casos mais críticos — passaram:**
- **T-09** (regressão do guard `ISNEW()/ISCHANGED()`):** um Lead "envenenado" (com data futura no campo) foi criado com a VR desativada. Após reativar a VR, o campo `Company` desse mesmo Lead foi alterado sem tocar a data. **O update passou sem erro** — a VR não disparou porque `ISCHANGED(Data_Aniversario__c)` era `false`. **VR foi reconfirmada ativa ao final** (verificação independente pelo orquestrador). Este é o cenário de regressão mais importante: prova que registros antigos com valor inválido não ficam permanentemente presos.
- **T-16** (risco D-2 — 3 Flows after-save simultâneos): criação e conversão de 3 Leads em loop, disparando os 3 flows ao mesmo tempo. Confirmado que os 3 flows escrevem em campos **completamente diferentes** (`OwnerId` / `Atividades_Pendentes__c` e `Quantidade_de_Atividades_Pendentes__c` / `Contact.Birthdate` em objeto diferente). **Resultado idêntico em todas as 3 iterações** — nenhum comportamento inconsistente, nenhum erro de integração entre os flows, nenhum rollback por VR.

**Conversão — comportamento de sobrescrita confirmado:**
- Lead com `Data_Aniversario__c` é convertido para Contact.
- Se o Contact pré-existente já tinha `Birthdate` com outro valor, ele é **sobrescrito** com o do Lead.
- **Comportamento pretendido, conforme gate de negócio.** Não é uma falha, é a decisão que o consultor confirmou.

**Massa de teste:**
- 42 Leads criados, 100% fictícios (`Company='QA Teste Aniversario'`, `LastName` contendo `Aniversario`, e-mails `@example.invalid`).
- 36 Accounts criadas (automáticas pela conversão).
- 37 Contacts criados (resultantes da conversão).
- **Todos os registros foram removidos e purgados ao final** (`COUNT(Id)` agregado confirmado = 0 para cada tipo).
- **Nenhum SOQL retornou valor do campo em conjunto com dado identificável** — guardrail LGPD #2 respeitado.

---

## 7. Onde foi implantado

| Item | Valor |
|---|---|
| Org | `sbx-acxya` (Sandbox) |
| Org Id | `00DHa000006bRsDMAU` |
| URL | `https://acxya--sbxacxya.sandbox.my.salesforce.com` |
| API | v67.0 |
| Deploy ID | `0AfHa00000DWpzBKAT` |
| Data/Hora | 2026-09-07T22:19:03.000Z |
| Status | `Succeeded` — 8 componentes implantados, 10 testes Apex da org executados, 0 falhas |

**Produção:** Nenhuma. Produção não está configurada nesta máquina e não foi tocada em nenhum momento. Qualquer promoção para produção está fora do escopo de qualquer agente deste squad (guardrail #1 da doutrina).

---

## 8. LGPD — Conformidade

### Classificação do dado
Data de nascimento é dado pessoal (LGPD art. 5º, I — "informação relacionada a pessoa natural identificada ou identificável"). **Não é dado pessoal sensível** (art. 5º, II — não abrange origem racial, convicção religiosa, opinião política, saúde, vida sexual, genética ou biometria).

### Finalidade de coleta — CONFIRMADA
**Finalidade:** uso interno de relacionamento comercial (ex.: campanhas de contato em data comemorativa, lembretes de aniversário, personalização de interação comercial).

**Sem compartilhamento com terceiros.**

**Consultor responsável:** Leonardo (confirmado em gate de homologação, 2026-09-07).

### Base legal — CONFIRMADA
**Base legal:** Legítimo interesse (LGPD art. 7º, IX). A operação comercial necessita este dado para execução adequada do relacionamento comercial já estabelecido com o prospect/lead.

### Minimização implementada nesta entrega

1. **FLS por perfil (B-4):** Apenas 4 perfis de negócio veem o campo. Nenhum perfil de integração tem acesso — reduz superfície de exposição.
2. **Sem rastreamento de histórico:** `<trackHistory>false</trackHistory>` no CustomField garante que mudanças no campo não são replicadas em `LeadHistory` — evita proliferação de cópias do dado pessoal.
3. **Sem duplicação de modelo de dados:** Opção 2 de mapeamento usa o `Contact.Birthdate` nativo (já existente) como destino — não cria um clone adicional (o que seria Opção 3, rejeitada).

### Gatilho de revisão
**Se o uso migrar para campanha de marketing direcionado/publicidade** (ex.: ofertas personalizadas com base em mês de aniversário), a **base legal deve ser revista para consentimento (art. 7º, I)**, com coleta de consentimento explícito do prospect. Hoje não é o caso.

---

## 9. Notas de manutenção / Riscos residuais

### D-2: Ordem de execução entre 3 Flows — residual, mitigado por design

**Achado:** Na primeira tentativa de build, a recomendação de §6.2 do design era adicionar `<triggerOrder>` explícito no Flow novo para garantir ordem entre os 3 Flows after-save do Lead. **O elemento `<triggerOrder>` foi rejeitado pela API v67.0** — não é aceito nesta org/versão na posição testada.

**Estado atual:** Ordem de execução entre `Leads_do_Marketing_Cloud`, `Count_de_Tasks_Pendentes` e `Lead_AfterSave_MapeiaAniversarioNaConversao` **não é garantida por metadata versionado**. Cada execução pode dispará-los em ordem diferente.

**Mitigação:** Os 3 flows **não escrevem em campos sobrepostos** — confirmado por leitura de XML:
- `Leads_do_Marketing_Cloud` escreve: `OwnerId` (Lead).
- `Count_de_Tasks_Pendentes` escreve: `Atividades_Pendentes__c` e `Quantidade_de_Atividades_Pendentes__c` (Lead).
- `Lead_AfterSave_MapeiaAniversarioNaConversao` escreve: `Contact.Birthdate` (Contact, objeto diferente).

Logo, a ordem relativa entre eles não afeta o resultado final — o único cenário onde ordem importa é quando um flow **lê** um valor que outro **escreve**, o que não é o caso.

**Teste:** T-16 validou empiricamente em 3 repetições — resultado idêntico, nenhuma inconsistência detectada.

**Condição de invalidação:** Se no futuro qualquer um desses 3 flows passar a escrever em um campo **hoje exclusivo de outro**, este risco volta a ser real e T-16 precisaria ser re-executado. Vale registrar esse pré-requisito em documentação de manutenção.

**Ação para o futuro:** Antes de alterar qualquer um desses 3 flows, confirmar que não vai sobrepor campos com os outros. Se precisar sobrepor, abrir decisão de `<triggerOrder>` em novo gate (ou adotar Flow Trigger Explorer setup manual, que não é versionado mas funciona).

### D-3: Erros pré-existentes no `force-app` — sugestão de demanda separada

**Achado durante build:** Validação do `force-app` completo falhou com 4 erros pré-existentes, não relacionados a esta demanda:
- `standard__EnvironmentHub` — `defaultLandingTab must be included in tab list`
- `Case-Case Layout` — `Invalid field: SOLUTION.ISSUE in related list: RelatedSolutionList`
- `GuestCommunityCase` e `NewCommunityCase` — Inválido `QuickActionLabel`

**Impacto:** Nenhum nesta demanda (nenhum desses componentes foi alterado). Mas o `force-app` desta org **não passa em `sf project deploy validate` da árvore inteira** — relevante se o CI algum dia rejeitar baseado em validação do `force-app` completo.

**Recomendação:** Abrir demanda de sustentação separada para investigar/corrigir os 4 componentes. Não faz parte desta entrega.

### Verificação de FLS por UI recomendada

T-01, T-03, T-12 foram confirmados por API (`FieldPermissions`, `ObjectPermissions`, layout XML) — validação que guardrail LGPD permite. Mas a renderização real da tela por um usuário logado de fato — campo aparecendo no lugar certo, editável ou read-only conforme o perfil — **não foi verificada** neste ambiente sem "Login As".

**Recomendação pós-deploy (não bloqueante):** Um "Login As" rápido (2-3 min) por perfil antes da homologação visual final, com checklist simples: campo aparece, está no lugar certo, comportamento de edit/read conforme esperado para o perfil.

---

## 10. Procedimento de rollback

Caso seja necessário reverter a entrega, em ordem de alavanca imediata:

| Componente | Ação | Tempo | Comando/Detalhe |
|---|---|---|---|
| **1. ValidationRule** | Redeploy com `<active>false</active>` | ~30 seg | Desligar a VR sem apagar. Esta é a primeira alavanca se qualquer integração começar a falhar. |
| 2. Flow | Desativar via Setup ou redeploy com `<status>Draft</status>` | ~1 min | `Lead_AfterSave_MapeiaAniversarioNaConversao` — desativar a versão ativa. |
| 3. Layout | Redeploy de `demandas/ACXYA-1/layout-lead-original-backup.xml` | ~1 min | Restaurar o layout original (confirmado byte-idêntico ao pré-deploy, §2 de `06-release.md`). |
| 4. Field-Level Security | Redeploy dos 4 Profiles com `readable=false`/`editable=false` no bloco `fieldPermissions` | ~1 min | Revoga FLS sem apagar dados. Preserva os outros `userPermissions` já versionados. |
| 5. CustomField | **Não apagar.** Remover do layout + revogar FLS (passos 3-4 acima). | — | `destructiveChanges` destruiria o campo e qualquer dado nele — só em caso de abandono total da demanda, nunca como rollback de rotina. |

**Regra:** O rollback padrão desta entrega é **desligar a VR e revogar FLS**, não apagar metadata. Só remove o campo se o humano decidir explicitamente abandonar a demanda de vez.

**Layout:** O arquivo de backup em `demandas/ACXYA-1/layout-lead-original-backup.xml` é pré-condição de rollback seguro. Sem ele, não há como restaurar o layout original — este arquivo **deve ser anexado ao PR**.

---

## 11. Rastreabilidade

### Critérios de aceite vs. Casos de teste vs. Componentes

| Critério de aceite | Caso(s) de teste | Componentes envolvidos | Status |
|---|---|---|---|
| CA-01 — campo existe e é editável no layout | T-01, T-02 | CustomField, Layout, Profile (FLS) | PASSOU |
| CA-02 — campo aceita datas passadas válidas | T-11 | CustomField, Validation Rule | PASSOU |
| CA-03 — tipo é Date, não Date/Time | T-02 | CustomField | PASSOU |
| CA-04 — validação de data futura | T-07, T-08, T-09 (regressão), T-10 | CustomField, ValidationRule | PASSOU |
| CA-05 / B-1 — conversão mapeia para `Contact.Birthdate` | T-13, T-14, T-15 (volume), T-16 (3 flows) | Flow, `Contact.Birthdate` | PASSOU |
| B-3 — campo é opcional | T-06 | CustomField | PASSOU |
| B-4 — FLS restrita a 4 perfis, nenhum de integração | T-03, T-04, T-12 (negativo) | Profile (4 arquivos), FieldPermissions | PASSOU |
| Pré-condição de release — backup de layout permite rollback | T-05 | Layout, `layout-lead-original-backup.xml` | PASSOU |

**Nota:** CA-04 e CA-05 foram registrados em `01-analise.md` como "pendentes de definição" e fechados no gate de análise (2026-09-06): validação de data futura obrigatória, e mapeamento para `Contact.Birthdate` na conversão. Os 16 casos cobrem os 5 critérios de aceite mais as 4 decisões de design B-1..B-4.

### Referência de artefatos

- **Demanda original:** `demanda.md`
- **Análise BA:** `01-analise.md` (decisões de negócio, critérios de aceite refinados)
- **Recon:** `02-recon.md` (o que existia na org, riscos identificados)
- **Design:** `03-design.md` (arquitetura, decisões B-1 a B-4, trade-offs)
- **Plano de build:** `04-plano-build.md` (o que foi construído, desvios D-1 a D-6)
- **Testes:** `05-testes.md` (16 casos, resultados, execução pós-deploy)
- **Release:** `06-release.md` (deploy real, verificação pós-deploy, rollback)
- **Este documento:** `06-entrega.md` (síntese final, para o cliente/manutenção)
- **Gates:** `gates.md` (log de aprovações humanas, decisões, observações)

### Identificadores de rastreamento

| Item | Identificador |
|---|---|
| Demanda | ACXYA-1 |
| Branch | `feature/ACXYA-1` |
| PR | #6 (aberto manualmente) |
| Deploy ID (sandbox) | `0AfHa00000DWpzBKAT` |
| Data de entrega | 2026-09-07 |
| Org de destino | `sbx-acxya` |
| Homologação | Aprovada por Leonardo, 2026-09-07 |

---

## 12. Para dar manutenção nisto daqui a um ano

1. **O campo é dado pessoal.** Qualquer alteração (ex.: adicionar rastreamento de histórico, expor em formulário Web-to-Lead, duplicar em outro objeto) exige revisão de LGPD. Finalidade e base legal estão confirmadas em `gates.md` linha 15 — se mudar, refazer essa confirmação.

2. **A Validation Rule depende de um guarda `ISNEW()/ISCHANGED()`.** Se alguém tiver vontade de alterar a fórmula para remover o `OR(ISNEW(), ...)`, entender antes os riscos R1 e R2 em `03-design.md` §5.

3. **Os 3 Flows after-save do Lead não sobrepõem campos hoje.** Se for alterar qualquer um deles para escrever em `Data_Aniversario__c`, `Contact.Birthdate`, `OwnerId`, `Atividades_Pendentes__c` ou `Quantidade_de_Atividades_Pendentes__c`, revisar ordem de execução (D-2 em `04-plano-build.md`).

4. **Layout está versionado no `force-app`.** Deploy de Layout substitui o inteiro — sempre fazer `sf project retrieve start --metadata "Layout:Lead-Lead Layout"` imediatamente antes de editar (§3.4 de `03-design.md`), e o PR deve mostrar só o campo novo adicionado, nada mais. Se o diff mostrar mudanças em outro ponto, parar e escalar.

5. **Verificação visual por UI recomendada.** Um "Login As" por perfil (Admin, Standard, Marketing, Sys Admin) antes de deixar homologação visual padrão passar — a API já confirma FLS, mas a tela às vezes surpreende.

6. **Os 4 erros pré-existentes do `force-app`** (EnvironmentHub, Case-Case Layout, GuestCommunityCase, NewCommunityCase) não são desta demanda, mas continuam ali impedindo validação do pacote inteiro. Vale conferir com o squad se há plano de sustentação para resolvê-los.

---

**Entrega concluída. Repositório limpo, todos os artefatos versionados, homologação aprovada, sandbox pronta para o próximo ciclo.**
