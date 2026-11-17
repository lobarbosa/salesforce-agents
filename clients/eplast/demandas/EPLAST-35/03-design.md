# EPLAST-35 — Design (rodada 2): distribuição de Leads com dono da conta e rodízio

**Sem bloqueio.** Nenhuma pergunta de caso 3. Há uma decisão para o arquiteto humano no gate (seção 1.3) e uma condição de sequência com a EPLAST-38 (seção 5). Nenhuma das duas é pendência aberta.

**Cliente:** Eplast · **Tipo:** projeto · Onda 3, segue pela regra 1 da conta.
**Org conferida:** `sbx-eplast-dev` (única org em `sf org list` nesta sessão, Sandbox, Connected; é a `eplast--qa` da Eplast, DEV da esteira pela regra 5). **Data:** 2026-11-17. Só leitura: nenhum deploy, DML ou alteração de metadata.
**Entradas:** `01-analise.md` (gate aprovado em 15/11), `02-recon.md` (rodada 2, 17/11), `comentarios-do-card.md`, respostas da Eplast de 17/11 (registradas no fim do design anterior e copiadas na seção 11), design e plano da rodada 1 (`rodada-anterior/premissas-assumidas/` e histórico git), design da EPLAST-38 (branch `feature/EPLAST-38`), `assessment.md` (trechos), skill `salesforce-doutrina`.

**O que mudou desde a rodada 1:** a Eplast respondeu em 17/11. Valem as respostas dela sobre as premissas antigas. Esta rodada muda **só a distribuição de Leads**: RJ e ES numa regional só, o dono da conta tem precedência e há rodízio dentro da região. Aprovação e encaminhamento a áreas internas **não são construídos**: dependem da matriz de alçadas que a Eplast ainda vai aprovar. O que passou no QA da rodada 1 é reaproveitado sem alteração.

---

## 1. Decisão

| Frente | Decisão | Nível |
|---|---|---|
| Região (6 regionais + Triagem) | **Versão nova da regra de atribuição nativa** (`Distribuicao_Regional_Leads_v2`), com RJ e ES numa entrada só e a fila nova `Leads_RJ_ES`. Implantada **inativa**. A ativação é um passo separado (seção 5) | 1 — configuração |
| Dono da conta e rodízio | **Flow record-triggered novo** em Lead, que chama **uma classe invocável nova** (`LeadRodizioService`). A classe decide o dono final: primeiro o dono da conta com o mesmo CNPJ, senão o próximo elegível da fila regional | 2 + 3 |
| Parâmetros | **Custom Metadata Type novo** `DistribuicaoLeadSetting__mdt`, com um registro `Padrao` (liga/desliga, filas sem rodízio, janela). O administrador muda em Setup, sem deploy | 1 — configuração |
| Elegíveis por região | **Membros da fila regional** (Setup > Filas). Recurso nativo, mantido pelo administrador, sem deploy | 1 — configuração |
| Aprovação | **Não construída.** Os 3 processos ficam como estão. O mapeamento deles fica na seção 9 para a conversa com a Eplast | — |
| Encaminhamento | **Não construído** o encaminhamento a áreas internas. A transferência comercial continua sendo a transferência nativa de dono, com o histórico de `OwnerId` já ligado | 1 (já existe) |

### 1.1 Por que a região continua na regra nativa
A régua por UF já roda na regra ativa e passou no QA. Mudar RJ e ES é editar entradas. Uma versão nova da regra mantém um só lugar para a régua, editável em Setup. Não se cria um segundo motor em Flow ou Apex.

### 1.2 Por que o rodízio e o dono da conta descem para Apex
- **A plataforma não tem rodízio nativo de Lead.** A regra de atribuição só entrega para fila ou usuário fixo. Recon, seção 1: Territory Management não está habilitado, `maps__AssignmentRule__c` tem 0 registros, Omni-Channel não foi confirmado. Omni-Channel e Salesforce Maps exigiriam licença, presença ou territórios que a org não mostra. Ficam como evolução.
- **Flow sozinho não faz rodízio correto em lote.** Num lote de 200 Leads da mesma região, cada interview do Flow lê o mesmo estado ("quem recebeu por último"), e todos iriam para o mesmo vendedor. O rodízio precisa ser sequencial em memória dentro do lote. Doutrina, "volume alto" e "teste unitário determinístico sobre a regra": isso pede Apex.
- **Casar Lead e conta por CNPJ** exige normalizar o formato, que é desconhecido (com ou sem máscara, recon, seção 6, item 3), e tratar ambiguidade (mais de uma conta com o mesmo CNPJ, `unique = false`). Num Flow isso seria uma fórmula frágil e consultas em loop.
- **O Flow continua sendo o gatilho, na forma declarativa.** Ele decide *quando* rodar (Lead criado ou dono alterado). A classe decide *quem* é o dono. É o mesmo padrão que a org já usa no par `Lead_AfterInsert_AplicaRegraAtribuicao` e `LeadAssignmentService`.
- **Por que uma classe nova em vez de estender `LeadAssignmentService`:** ela é Active, é chamada por um Flow ativo e é o que a EPLAST-38 está homologando. A doutrina, em "Alterar o que já existe", manda criar classe nova quando o comportamento muda. A responsabilidade também é outra: aquela pede a regra, esta escolhe o vendedor.

### 1.3 Decisão para o arquiteto humano no gate
`DistribuicaoLeadSetting__mdt` é um **Custom Metadata Type novo**. É configuração, não dado de negócio: não guarda registro de cliente e não cria campo em Lead, Account ou outro objeto de negócio. A org já usa esse padrão em 7 tipos `*Setting__mdt` (recon, seção 1). Mesmo assim, ele aparece como objeto novo no pacote. Por isso fica destacado aqui para o aceite.
- **Se o arquiteto aceitar:** o build segue como está.
- **Se recusar:** os parâmetros vão para Custom Labels (`Lead_Rodizio_Ativo`, `Lead_Rodizio_FilasExcluidas`, `Lead_Rodizio_JanelaDias`), também editáveis em Setup. O esforço é o mesmo.

**Não há campo novo em objeto de negócio.** O rodízio foi desenhado sem estado gravado (seção 2.3) justamente para não exigir campo em Lead ou User. Um rodízio estrito com marcador gravado (por exemplo `Lead.DistribuidoPorRodizioEm__c`) seria mudança de modelo de dados. Fica como alternativa B (seção 10) e só entra com decisão sênior.

---

## 2. Comportamento

### 2.1 Regra `Distribuicao_Regional_Leads_v2` (entradas em ordem)
Critério: `Lead.State` igual a (lista separada por vírgula, mesma sintaxe da v1).

| Ordem | `State` igual a | Fila |
|---|---|---|
| 1 | SP | `Leads_SP` |
| 2 | RJ,ES | `Leads_RJ_ES` (**nova**) |
| 3 | MG | `Leads_MG` |
| 4 | PR,SC,RS | `Leads_Sul` |
| 5 | DF,GO,MT,MS,TO | `Leads_CO` |
| 6 | AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE | `Leads_NO_NE` |
| 7 | sem critério | `Leads_Triagem` |

Nenhuma entrada tem template de e-mail (regra 2 da conta), igual à v1.

### 2.2 Dono final (`LeadRodizioService.distribuir(List<Id>)`)
Para cada Lead recebido, a classe relê o Lead com `FOR UPDATE` e só age se ele ainda estiver em uma fila tratada. Fila tratada é toda fila cujo DeveloperName começa com o prefixo configurado (`Leads_`).

1. **Dono da conta.** Isso vale se `RespeitarDonoConta__c` estiver ligado e o Lead tiver `CompanyDocument__c`.
   - O CNPJ é normalizado para só dígitos. A busca em `Account.CompanyDocument__c` (externalId, indexado) usa as duas formas: só dígitos e com a máscara `00.000.000/0000-00`.
   - Se todas as contas encontradas têm o **mesmo** dono, e ele é usuário ativo do tipo Standard, o Lead vai para esse dono. Isso vale também fora da região e também na Triagem.
   - Se as contas têm donos diferentes, ou o dono está inativo, ou não há conta, segue para o passo 2.
2. **Rodízio.** Isso vale se `RodizioAtivo__c` estiver ligado e a fila não estiver em `FilasSemRodizio__c` (padrão: `Leads_Triagem`).
   - Elegíveis: membros **diretos** da fila que são usuários ativos do tipo Standard, ordenados por Id. Grupo ou papel dentro da fila não conta (PA-23).
   - Referência: o elegível com o Lead criado mais recentemente nos últimos `JanelaDiasReferencia__c` dias (padrão 30). A consulta é agregada: `SELECT OwnerId, MAX(CreatedDate) ... GROUP BY OwnerId`, sem campo pessoal.
   - O Lead vai para o próximo elegível depois da referência, em ciclo. No lote, o ponteiro avança em memória.
   - Sem referência na janela, começa pelo primeiro elegível.
3. **Sem elegível**: o Lead fica na fila. É o comportamento da rodada 1, e por isso a org de hoje, com 0 membros, continua funcionando.
4. **Gravação.** Um `Database.update(leads, false)`, sem `useDefaultRule` (a regra não roda de novo) e sem e-mail ao novo dono.
   - Erro por registro vai para o log, sem dado pessoal na mensagem. A classe **nunca lança exceção**, para não desfazer a criação do Lead pela tela.
   - A classe é `without sharing`, com a justificativa no cabeçalho: ela lê contas e membros de fila independentemente de quem criou o Lead. Ela **só lê** `Account` e nunca grava nela, então a `AccountTrigger` e o Protheus não são acionados.

### 2.3 Por que o rodízio sem estado gravado
A referência vem dos próprios Leads: quem recebeu por último entre os elegíveis. Não precisa de campo nem de contador.
- **Ganho:** nenhum modelo de dados novo, e quem entra na fila recebe na vez dele, sem fila de compensação.
- **Custo:** um Lead que o próprio vendedor cria com dono dele conta como a vez desse vendedor. O desvio é pequeno e se corrige no ciclo seguinte. Fica registrado como premissa PA-24.

### 2.4 Gatilho: Flow `Lead_AfterSave_DistribuiDonoRodizio` (novo)
- Record-triggered em Lead, **after save**, em criação **e** atualização, **caminho imediato**.
- Condição de entrada (fórmula): `ISNEW() || ISCHANGED({!$Record.OwnerId})`.
- A condição de entrada não filtra pelo dono, porque não é certo que `$Record` mostre o dono que a regra de atribuição gravou no mesmo salvamento. Por isso a classe relê o Lead, e o SOQL na mesma transação vê o dono atual.
- Ação: `LeadRodizioService.distribuir` com os Ids do lote.
- Se `AplicarEmTransferencia__c` estiver desligado, a classe ignora as alterações de dono que não vieram de criação nem da regra. Na prática, ignora a transferência manual para fila.
- Flow novo, que não substitui nada: pode nascer Active (doutrina).
- **Antes de ativar na QA**, a classe precisa estar provada na DEV (seção 5).

---

## 3. Mapa item a item

| # | Componente (API name) | Ação | Prova |
|---|---|---|---|
| 1 | Regra `Distribuicao_Regional_Leads` (v1, ativa, RJ e ES separados) | **Não edita.** Fica no arquivo `AssignmentRules/Lead` como está. É desativada **automaticamente** quando a v2 é ativada (a plataforma só tem uma regra de Lead ativa) | recon, seção 1 |
| 2 | Regra `Distribuicao_Regional_Leads_v2` | **Cria, inativa.** Entradas da seção 2.1 | não existe |
| 3 | Fila `Leads_RJ_ES` (rótulo "Leads RJ/ES", objeto Lead, sem membros, `DoesSendEmailToMembers=false`, descrição "EPLAST-35. …") | **Cria** | recon: não existe |
| 4 | Filas `Leads_SP`, `Leads_MG`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem` | **Reaproveita, sem alteração** | recon |
| 5 | Filas `Leads_RJ`, `Leads_ES` | **Não toca.** Saem da régua quando a v2 é ativada. Não são apagadas: podem ser donas de Leads na QAS, e a exclusão fica para uma limpeza futura, depois de contar 0 Leads nelas (PA-22) | recon |
| 6 | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (ativo) | **Reaproveita, sem versão nova** | recon |
| 7 | Classe `LeadAssignmentService` + `LeadAssignmentServiceTest` | **Reaproveita, sem alteração** | recon |
| 8 | Custom permission `Lead_DistribuicaoAutomaticaViaApi`, PS `PS_Integracao_DistribuicaoLead` | **Reaproveita, sem alteração** | recon |
| 9 | Layout `Lead-Lead Layout` (`runAssignmentRulesDefault=true`) | **Não toca** (é compartilhado com a EPLAST-26 e a EPLAST-38) | recon |
| 10 | Histórico de campo de Lead (`OwnerId`, `Status`) | **Reaproveita** (já ligado) | recon |
| 11 | Relatório `Aprovacoes_Pendentes_Por_Processo` | **Reaproveita, sem alteração** | recon |
| 12 | 3 Approval Processes | **Não toca** | recon |
| 13 | CMDT `DistribuicaoLeadSetting__mdt`, com os campos `RodizioAtivo__c` (checkbox, true), `RespeitarDonoConta__c` (checkbox, true), `AplicarEmTransferencia__c` (checkbox, true), `PrefixoFilas__c` (texto 40, "Leads_"), `FilasSemRodizio__c` (texto 255, "Leads_Triagem"), `JanelaDiasReferencia__c` (número, 30), e o registro `Padrao` | **Cria** (seção 1.3). Todo campo com descrição "EPLAST-35. …" | recon: nenhum `__mdt` de região |
| 14 | Classe `LeadRodizioService` (`@InvocableMethod distribuir`, API 68.0, `without sharing` justificado) + `LeadRodizioServiceTest` | **Cria** | recon: nenhuma classe de rodízio |
| 15 | Flow `Lead_AfterSave_DistribuiDonoRodizio` | **Cria** (Active na DEV, depois da classe) | recon: só um Flow de Lead encontrado por nome |
| 16 | Campos `Lead.CompanyDocument__c`, `Account.CompanyDocument__c`, `Account.OwnerId`, `Lead.State` | **Reaproveita, só leitura** | recon, seção 2 |
| 17 | `fixtures/lead_roteamento_regional.apex` (criado pela EPLAST-38, no branch dela) | **Estende** com Leads com CNPJ, contas com dono e membros de fila de teste, depois que o branch da 38 entrar na `main`. Se não tiver entrado, o build cria `fixtures/lead_rodizio_dono_conta.apex` próprio | branch `feature/EPLAST-38` |
| 18 | Agente `SFAgent2` | **Não se aplica** (a demanda não pede assistente) | regra 3 |

**Permissões:**
- Nenhum perfil é alterado.
- Flow record-triggered roda em contexto de sistema, e por isso o usuário comercial não deveria precisar de acesso à classe. **O verificador confirma isso** criando um Lead com um usuário de perfil não administrador (R5). Se a plataforma exigir o acesso, o build cria `PS_Comercial_DistribuicaoLead` só com essa classe. Não altera o PS existente.
- Os membros de fila são passo do administrador, como na rodada 1.

---

## 4. Ordem de execução

### Lead
Inventário (recon, seção 3): nenhum trigger, 1 Flow ativo (`Lead_AfterInsert_AplicaRegraAtribuicao`, só criação, só com a custom permission, assíncrono), 2 VRs (`Celular`, `Telefone`) e a regra de atribuição. Outros Flows de Lead com nome diferente não foram descartados (recon, seção 6, item 2). **O verificador lista os Flows ativos com gatilho em Lead (`FlowDefinitionView`) antes de ativar o novo.**

1. **Tela, com a caixa marcada:**
   - VRs → gravação → regra v2 (dono = fila regional) → after-save: o Flow novo entra (ISNEW).
   - A classe relê o Lead, vê a fila e aplica o dono da conta ou o rodízio, com um update na mesma transação.
   - Esse update dispara o Flow novo de novo (ISCHANGED do dono). A classe relê, vê que o dono é usuário e sai, com 1 SOQL. Sem laço.
   - O Flow antigo não entra, porque o usuário de tela não tem a permissão.
2. **Tela, com a caixa desmarcada:** o dono fica sendo o criador. O Flow novo entra, a classe vê que o dono é usuário e sai. **O dono da conta não sobrepõe uma escolha explícita do vendedor** (PA-27).
3. **API, por usuário com o PS, sem cabeçalho:**
   - Na criação, o dono é o integrador. O Flow novo entra e sai sem ação.
   - O Flow antigo, no caminho assíncrono, faz o update com a regra padrão. Nessa transação a regra v2 grava a fila e o Flow novo entra (ISCHANGED), e aplica o dono da conta ou o rodízio.
   - Tudo acontece na transação assíncrona. O `FOR UPDATE` serializa uma eventual corrida.
4. **API com cabeçalho:** como o item 1.
5. **Transferência manual para uma fila `Leads_*`:** com `AplicarEmTransferencia__c` ligado, a classe redistribui. Transferência para usuário: a classe sai sem ação.
6. **Conversão:** não é alterada. A classe ignora `IsConverted = true`.

**Dependência de ordem (risco R1, documentado):** a regra de atribuição roda depois das after triggers e antes dos after-save Flows (doutrina). O desenho depende só de o SOQL da classe ver o dono gravado pela regra na mesma transação. É o comportamento padrão de leitura dentro da própria transação. O QA prova isso no caso T1.

### Account
**Só leitura** (SOQL por `CompanyDocument__c`). Nada é gravado em Account, então a `AccountTrigger` (Protheus, um job por conta), a `AccountBefore` do SBQQ e os Flows de Account não são acionados. O defeito de `UpdateAccountCompanyInfo` não é tocado.

### Opportunity, Order, Quote, `SBQQ__Quote__c`
Não são tocados. A ordem relativa deles continua sem mapeamento. É pré-requisito de quem for construir as alçadas de aprovação.

### Governador e escala
- **Lote de 200 Leads:** cerca de 6 SOQL (Leads, filas, membros e usuários, referência agregada, contas) + 1 DML. A reentrada soma 1 SOQL. CPU desprezível: Lead sem trigger e com 2 VRs, e o laço é em memória sobre no máximo 200 × membros.
- **Muitos filhos num pai:** não se aplica, porque Lead não tem filho em cascata e Account só é lida.
- **Uma conta com muitos Leads no mesmo lote:** 1 consulta só, sem efeito em CPU.
- **Volume:** 4 Leads e 2 contas na DEV. O dado de teste é sintético.
- **O teste unitário cobre:** 200 Leads em 3 regiões, rodízio com 3 elegíveis (a distribuição sai 67/67/66), e o CNPJ nas duas formas.

---

## 5. Convivência com EPLAST-38 e EPLAST-26

**De quem são os componentes.**
- A rodada 1 da EPLAST-35 **criou** a regra, as 8 filas, o Flow, a classe, a custom permission e o PS, e alterou o layout (plano de build da rodada 1, seção 1).
- A EPLAST-38 **versionou esses mesmos componentes sem alterá-los** e homologa o roteamento com eles (design da 38, seção 0 e seção 2, "Reaproveita, sem alteração").
- Decisão: **a EPLAST-35 continua dona do motor de distribuição; a EPLAST-38 é consumidora.** Esta rodada **não edita nenhum componente da lista da 38**. Ela só acrescenta a regra v2 inativa, a fila nova, o CMDT, a classe e o Flow novos.

**Onde ainda há colisão, e como sequenciar:**
1. **`AssignmentRules/Lead` é um arquivo só para todas as regras de Lead.** O arquivo da EPLAST-35 terá a v1 (byte a byte como na org) e a v2. Se o pacote da 38 for implantado **depois** do da 35 com a v1 marcada como ativa, ele reativa a v1 e desliga a v2. **Ordem de release: a EPLAST-38 primeiro, depois a EPLAST-35.** O branch da 35 parte da `main` já com a 38 (rebase antes do PR) e o build refaz o retrieve do arquivo antes de acrescentar a v2.
2. **Ativar a v2 e o Flow novo na QAS muda o que a EPLAST-38 homologa:** RJ e ES passam a uma fila só, e o Lead vai a um vendedor, não fica na fila. A tabela UF → fila do design da 38 (seção 3.1) e o roteiro dela ficam desatualizados nesses pontos. **A ativação na QAS só acontece depois de a homologação da 38 fechar**, ou com aceite do responsável pela conta para homologar as duas juntas. Na DEV, a ativação para verificação está liberada, porque a 38 já saiu da DEV. Registrado como PA-30. **Não é caso 3:** desfazer é reativar a v1 e desativar o Flow novo, sem perda de dado.
3. **EPLAST-26:** só o layout, que esta rodada não toca. Sem colisão.

**Versões e ativação (para o plano de build):**

| Item | Entra | Sai | Passo de ativação | Desfazer |
|---|---|---|---|---|
| Regra de Lead | `Distribuicao_Regional_Leads_v2` (deploy inativa) | `Distribuicao_Regional_Leads` (v1) | Depois de a classe e o Flow passarem na verificação da DEV: marcar a v2 como ativa (Setup ou deploy só do `active`). Na QAS, pela condição do item 2 | Reativar a v1 |
| Flow | `Lead_AfterSave_DistribuiDonoRodizio` (novo) | — | Nasce Active na DEV depois da classe | Desativar o Flow |
| Classe | `LeadRodizioService` (nova) | — | Entra com o Flow | Desativar o Flow |

---

## 6. Riscos

### Do assessment
| Achado | Como o design lida |
|---|---|
| #1 Automação concorrente em Account/Opportunity/Order | Account só é lida. Nenhum deles é gravado. Lead não tem trigger |
| #2 Cobertura Apex de 10% | Classe nova com `LeadRodizioServiceTest` ≥ 85%. Não piora a cobertura, e também não resolve o bloqueio para produção, que fica fora da esteira |
| #3 Nome de classe ambíguo e testes sem sufixo `Test` | Nome inequívoco e teste `<Classe>Test` |
| #4 Campos sem descrição | Os campos do CMDT, a fila, a classe e o Flow saem com descrição "EPLAST-35. …" |
| API version desatualizada | O código novo nasce em 68.0 |
| Perfis comerciais duplicados | Nada é atribuído por perfil |
| #6 Alias e sandbox "qa" | Resolvido pela regra 5 da conta. Não é risco |

### Técnicos
| # | Risco | Sev. | Mitigação |
|---|---|---|---|
| R1 | O desenho depende de a regra ter gravado a fila antes do Flow after-save (ordem de execução) | Média | A classe relê o Lead em vez de confiar em `$Record`. Caso de QA T1 |
| R2 | A EPLAST-38 implantada depois reativa a v1 (arquivo único de regras) | **Alta** | Ordem de release 38 → 35, rebase e retrieve fresco (seção 5) |
| R3 | Ativar na QAS muda o comportamento homologado pela 38 | Média | Ativação condicionada (seção 5, item 2, PA-30) |
| R4 | O formato do CNPJ não é conhecido (0 registros com CNPJ na DEV e na amostra do recon) | Média | Busca pelas duas formas (só dígitos e com máscara). Outro formato não casa e o Lead segue para o rodízio. Teste unitário com as duas formas. O QA confirma na QAS **por contagem agregada** (`COUNT()` de contas com CNPJ de 14 ou de 18 caracteres), sem ler valor |
| R5 | O usuário de tela pode precisar de acesso à classe | Baixa | O verificador testa com um perfil não administrador. Se precisar, cria o PS novo (seção 3) |
| R6 | Conta de propriedade de usuário de integração (por exemplo, criada pelo Protheus) faria Leads irem para esse usuário | Média | O filtro "ativo e Standard" não exclui o integrador. O QA conta, na QAS, as contas com CNPJ agrupadas por perfil do dono (agregado). Se o integrador dominar, o administrador ajusta o dono das contas, ou a PA-26 muda para "só donos que são membros de alguma fila `Leads_*`" (opção já prevista na classe, que vira um campo do CMDT) |
| R7 | Rodízio sem estado: um Lead criado pelo próprio vendedor conta como a vez dele | Baixa | PA-24. Alternativa B na seção 10 |
| R8 | Fila sem membro: o Lead fica parado na fila | Baixa | Comportamento da rodada 1. Passo do administrador. O relatório e a list view da fila mostram o volume |
| R9 | `Lead.State` é texto livre: por extenso ou minúsculo cai na Triagem | Média (pré-existente) | Mantido da rodada 1. Na Triagem, o dono da conta ainda é aplicado |
| R10 | Outros Flows de Lead com nome diferente não foram descartados | Baixa | O verificador lista os Flows ativos com gatilho em Lead antes de ativar |

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca Lead e distribuição. Nada é feito no Marketing Cloud, e nada é enviado pelo CRM.

| Ponto | Onde fica no CRM |
|---|---|
| Dados que o Marketing Cloud lê | Lead: `FirstName`, `LastName`, `Email`, `Company`, `State`, `LeadSource`, `Status`, `OwnerId`. Nenhum campo novo |
| Como o público fica identificável | **Mudou:** depois do rodízio, o Lead está com um vendedor e não na fila regional. Segmentar por região passa a ser **pela UF (`State`)**, não pelo dono. Os relatórios existentes `LEADS - SP/RJ/MG/ES/SUL/CO/GERAL` (pasta MARKETING CLOUD) já filtram por `State`. Segmentar por vendedor: `OwnerId` |
| O que o Marketing Cloud devolve | Continua onde o conector `et4ae5` já grava. Leads criados pelo Marketing Cloud no CRM entram pelo caminho 3 da seção 4 se o usuário do conector tiver `PS_Integracao_DistribuicaoLead` |
| Consentimento e opt-out | `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c`. A troca de dono não mexe neles |
| O que é do operador do Marketing Cloud | 1) Gravar `State` com a sigla da UF e, quando houver, `CompanyDocument__c` com o CNPJ, para o Lead cair na região certa e encontrar a conta. 2) Ajustar segmentações regionais que usavam a fila como critério para usar a UF. 3) Excluir opt-out dos públicos |

---

## 8. O que NÃO será feito

- Gatilhos de aprovação, alçadas (desconto, margem, prazo, frete, pedido mínimo, crédito), filas de aprovadores por área e qualquer mudança nos 3 processos. Dependem da matriz da Eplast.
- Encaminhamento de demandas internas a áreas, com responsável, prazo e status. É escopo a combinar, porque depende de definir o objeto e as áreas.
- Encaminhamento específico de demandas técnicas ou de projetos especiais. Continua sendo a transferência manual.
- Casar Lead e conta por nome, razão social ou domínio de e-mail (não é confiável). Só por CNPJ.
- Redistribuir os Leads já existentes. Só eventos novos.
- Excluir as filas `Leads_RJ` e `Leads_ES`. Mudar layout, `LeadAssignmentService`, o Flow antigo ou o PS.
- Omni-Channel, Salesforce Maps, Territory Management, picklists de estado e país.
- Qualquer coisa no Marketing Cloud, e e-mail de notificação pelo CRM.
- Mexer no `SFAgent2`.

---

## 9. Mapeamento dos 3 processos de aprovação (para a conversa com a Eplast)

Estão ativos (recon da rodada 2) e não são alterados. O detalhe vem do retrieve da rodada 1 (`02-recon.md` do commit `56a2dd98`). Os aprovadores são citados por tipo, não por nome.

| Processo | Entrada | Etapas e aprovador | Ações | Onde complementar (quando houver matriz) |
|---|---|---|---|---|
| `Opportunity.FinancialAnalysis` | `StageName = Análise Financeira` | 1 etapa, 2 usuários nomeados | Alertas. Field updates `Atualizar_Fase_Fechado_Perdido`, `Atualizar_Motivo_de_Perda`. `allowRecall=false` | Limite de crédito e prazo fora da política |
| `Quote.AssignPricing` | Sem critério (toda cotação submetida) | 1 etapa, 1 usuário (Pricing) | Field updates `SubmittedApproval`, `SubmittedApproval2` | Desconto e margem. Exige mapear antes a ordem de execução Quote ↔ CPQ |
| `Order.LiberationFinancial` | Sem critério (todo pedido submetido) | 1 etapa, os mesmos 2 usuários do financeiro | Task `FinancialBlock`. Field updates `ChangeStatusStock`, `ChangeStatusReview` | Pedido mínimo, frete e crédito |

Pontos comuns: `recordEditability = AdminOrCurrentApprover` nos três. 0 de 19 usuários ativos têm gestor, então aprovação por gestor não é possível hoje. Não há Advanced Approvals (`sbaa`).

---

## 10. Alternativas discutidas

**Rodízio**
- **A (escolhida):** a classe invocável sem estado gravado, com os elegíveis = membros da fila e os parâmetros no CMDT.
- **B:** rodízio estrito com marcador gravado (`Lead.DistribuidoPorRodizioEm__c`, ou um contador por fila numa custom setting). É mais exato e não sofre o desvio da PA-24. **É mudança de modelo de dados e exige decisão sênior.** Custo: +4–6 h.
- **C:** Flow puro. Descartada: não faz rodízio correto em lote (seção 1.2).
- **D:** Omni-Channel ou Salesforce Maps. Descartada na v1: exigem licença, presença ou territórios não confirmados.

**Região RJ/ES**
- **A (escolhida):** regra v2 e fila nova `Leads_RJ_ES`.
- **B:** reaproveitar `Leads_RJ` com rótulo "RJ/ES". Descartada: o API name ficaria enganoso, e mudaria uma fila da EPLAST-38.

**Dono da conta**
- **A (escolhida):** CNPJ normalizado.
- **B:** Duplicate/Matching Rule de Lead × Account. Descartada: não atribui dono e não resolve a ambiguidade.

---

## 11. Respostas do cliente (17/11) e premissas assumidas (validar na homologação)

### Decidido pela Eplast em 17/11 (não é premissa)
- [x] Regionais: SP; RJ/ES; MG; SUL (PR, SC, RS); CO (DF, GO, MT, MS, TO); NO/NE (AC, AP, AM, PA, RO, RR, AL, BA, CE, MA, PB, PE, PI, RN, SE). Substitui a PA-03.
- [x] Região como regra principal, respeitando a conta com dono definido. Rodízio dentro da região. Substitui a PA-04.
- [x] Aprovação: manter e mapear os 3 processos. Gatilhos e alçadas esperam a matriz. Substitui a PA-01.
- [x] Encaminhamento a áreas internas: escopo a combinar, não construído. Substitui a PA-06.
- [x] Parâmetros configuráveis sem deploy.

### Mantidas da rodada 1 (sem mudança)
- [x] PA-02, PA-05, PA-07 a PA-14, PA-15 (caixa marcada por padrão), PA-16 (integração só com o PS), PA-17 (UF fora do padrão vai para a Triagem), PA-18 (sem e-mail), PA-19 (relatório de pendentes).

### Novas desta rodada
- [x] **PA-20 — Como casar Lead e conta?** *Decisão:* só pelo CNPJ (`CompanyDocument__c` nos dois objetos), comparado em só dígitos e com máscara. *Evidência:* os dois campos existem. Em Account o campo é externalId (indexado). Nome e razão social não são confiáveis. *Como mudar:* desligar `RespeitarDonoConta__c` no CMDT.
- [x] **PA-21 — Mais de uma conta com o mesmo CNPJ?** *Decisão:* se todas têm o mesmo dono, o Lead vai para ele. Se os donos são diferentes, segue para o rodízio. *Evidência:* `unique = false` no campo (recon). Opção mais segura. *Como mudar:* regra na classe, ajuste pequeno.
- [x] **PA-22 — O que fazer com `Leads_RJ` e `Leads_ES`?** *Decisão:* saem da régua e não são apagadas. *Evidência:* podem ser donas de Leads na QAS, e excluir uma fila com registros falha. *Como mudar:* o administrador as exclui depois de contar 0 Leads nelas.
- [x] **PA-23 — Quem é elegível?** *Decisão:* membros diretos da fila regional, usuário ativo e Standard. *Evidência:* fila é o recurso nativo que o administrador já mantém (PA-08 da EPLAST-38). *Como mudar:* incluir ou retirar o membro em Setup.
- [x] **PA-24 — Como é a vez no rodízio?** *Decisão:* o próximo elegível depois de quem recebeu o Lead mais recente nos últimos 30 dias, em ordem fixa. O Lead criado pelo próprio vendedor conta como a vez dele. *Evidência:* o padrão sem campo novo (seção 2.3). *Como mudar:* `JanelaDiasReferencia__c`, ou a alternativa B (decisão sênior).
- [x] **PA-25 — Rodízio na Triagem?** *Decisão:* não. A Triagem é trabalhada pelos membros dela, e o dono da conta vale também lá. *Como mudar:* tirar `Leads_Triagem` de `FilasSemRodizio__c`.
- [x] **PA-26 — Dono da conta inativo ou integrador?** *Decisão:* dono inativo ou não Standard é ignorado e o Lead segue para o rodízio. O integrador ativo e Standard é aceito (R6). *Como mudar:* restringir a membros de filas `Leads_*`.
- [x] **PA-27 — O vendedor cria o Lead com a caixa desmarcada.** *Decisão:* o dono continua sendo o vendedor. A conta não sobrepõe a escolha explícita. *Evidência:* comportamento padrão da caixa (PA-15). *Como mudar:* ampliar a classe para tratar dono usuário (demanda própria).
- [x] **PA-28 — A transferência manual para uma fila regional redistribui?** *Decisão:* sim. *Como mudar:* `AplicarEmTransferencia__c = false`.
- [x] **PA-29 — Notificação ao vendedor sorteado?** *Decisão:* sem e-mail pelo CRM (regra 2). O vendedor vê em "Meus leads". *Como mudar:* o administrador liga a notificação padrão, se quiser.
- [x] **PA-30 — Sequência com a EPLAST-38.** *Decisão:* release da 38 antes da 35. A ativação da v2 e do Flow na QAS só depois de a homologação da 38 fechar, ou com aceite do responsável pela conta para homologar as duas juntas. *Evidência:* arquivo único de regras de Lead, e a 38 em `aguardando_homologacao`. *Como mudar:* reativar a v1.

### Pendências que bloqueiam (caso 3)
Nenhuma. Toda decisão é reversível sem perda de dado e configurável. A única questão de modelo é o CMDT (seção 1.3). É decisão do gate, com alternativa equivalente, e não pergunta ao cliente.

---

## 12. Testes que o QA deve exercitar

Dados sintéticos ("TESTE EPLAST-35"). Usuário de teste `005bJ00000piKAaQAM` (ativo na DEV, recon) como membro de fila ou dono de conta de teste, **sem alterar o perfil nem o PS dele**. Contas de teste criadas com `TriggerUtility.bypassTrigger` (sem Protheus). Telefones vazios ou em formato válido (VRs `Celular` e `Telefone`). Cada fixture apaga o que criou.

| # | Caso | Esperado |
|---|---|---|
| T1 | Tela/API com cabeçalho, UF SP, `Leads_SP` com 2 membros | Dono = membro, não a fila |
| T2 | 4 Leads seguidos na mesma região, 2 membros | Alterna A, B, A, B |
| T3 | Lote de 200 pela API (com o PS), 3 regiões, 3 membros numa delas | Todos com dono. Diferença de no máximo 1 entre os membros. Sem erro de limite |
| T4 | UF RJ e UF ES | Os dois na região RJ/ES (dono de `Leads_RJ_ES` ou a fila, se vazia). Nenhum vai para `Leads_RJ` ou `Leads_ES` |
| T5 | Lead com CNPJ de uma conta de teste com dono X, UF de outra região | Dono = X |
| T6 | O mesmo CNPJ com máscara no Lead e só dígitos na conta (e o inverso) | Dono = X nos dois casos |
| T7 | CNPJ em 2 contas com donos diferentes | Segue para o rodízio |
| T8 | UF vazia, com conta casada | Dono = X. Sem conta: fica em `Leads_Triagem` (sem rodízio) |
| T9 | Fila regional sem membro | Fica na fila |
| T10 | Tela com a caixa desmarcada | Dono = criador |
| T11 | Transferência manual para `Leads_MG` com membros | Redistribui. Com `AplicarEmTransferencia__c = false`: fica na fila |
| T12 | `RodizioAtivo__c = false` | Fica na fila (comportamento da rodada 1) |
| T13 | Isolamento | `COUNT()` de Account, Opportunity e Order igual antes e depois. Nenhum job novo de `SendAccountToProtheus` ou `UpdateAccountCompanyInfo` (`AsyncApexJob` agregado) |
| T14 | Versões | Os 3 `ApprovalProcess` idênticos antes e depois. `LeadAssignmentService` e o Flow antigo sem mudança. A regra v2 ativa e a v1 inativa só depois do passo de ativação |
| T15 | Usuário não administrador cria o Lead | Distribui sem erro de acesso (R5) |
| T16 | `LeadRodizioServiceTest` | ≥ 85%. Casos T2, T3, T6, T7, T9 e lista vazia |

Na QAS (dado real), o QA não lê nem altera registro que não criou. Só faz as contagens agregadas de R4 e R6.

---

## 13. Estimativa

**Estimativa de esforço:** 34–56 h

O que mudou em relação à análise (120–260 h) e à rodada 1 (40–70 h):
- Esta faixa é só desta rodada. A rodada 1 já entregou e testou a regra, as filas, a ponte para a API, o histórico e o relatório, que são reaproveitados.
- **Entra:** regra v2 e fila 2–3 h. CMDT e registro 2–4 h. Classe com o dono da conta e o rodízio, e o teste de 200 registros, 12–18 h. Flow 2–4 h. Verificação na DEV com membros de fila e contas de teste 6–10 h. QA, roteiro novo e homologação 7–12 h. PR, rebase sobre a 38 e documentação 3–5 h.
- **Sai:** aprovação e encaminhamento a áreas internas, por decisão da Eplast.
- **Não inclui:** a alternativa B do rodízio (+4–6 h, decisão sênior), as alçadas de aprovação (dependem da matriz) e o encaminhamento interno.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
