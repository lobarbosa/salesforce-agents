# EPLAST-35 — Design (rodada 3): distribuição de Leads sem Apex, com dono da conta e rodízio por Flow

**Sem bloqueio.** Nenhuma pergunta de caso 3. O desenho declarativo foi validado para compilar na DEV (seção 1.4). O que só a execução prova (lote de 200, ordem de execução) fica com o verificador, e há uma saída declarativa para cada falha possível. Nenhuma dessas saídas usa Apex. Há **uma escolha para o arquiteto humano no gate** (seção 1.5, fórmula do índice do rodízio).

**Cliente:** Eplast · **Tipo:** projeto · Onda 3, segue pela regra 1 da conta.
**Org conferida:** `sbx-eplast-dev` (única org em `sf org list` nesta sessão, Sandbox, Connected; é a `eplast--qa` da Eplast, DEV da esteira pela regra 5). **Data:** 2026-11-17. Nada foi implantado. A única ação além de consulta foi uma validação `--dry-run` (`checkOnly`), registrada no `02-recon.md`.
**Entradas:** `01-analise.md` (gate aprovado em 15/11), `02-recon.md` (rodada 2, com adendo e confirmações do arquiteto de 17/11), `00-preflight.md`, `comentarios-do-card.md`, as respostas da Eplast de 17/11 e a decisão do responsável no gate de 17/11 (as duas transcritas na seção 14), skill `salesforce-doutrina` e RAG do cliente (EPLAST-38 e EPLAST-45).

**O que muda em relação à rodada 2:** sai a classe `LeadRodizioService`, por decisão do gate. O rodízio e o dono da conta passam a um Flow record-triggered. O Flow usa um campo Auto Number novo em Lead, aprovado pelo responsável. A região na regra nativa, a fila `Leads_RJ_ES` e o CMDT `DistribuicaoLeadSetting__mdt` continuam como estavam. Aprovação e encaminhamento interno continuam fora.

---

## 1. Decisão

| Frente | Decisão | Nível |
|---|---|---|
| Região (6 regionais e Triagem) | **Versão nova da regra de atribuição nativa** `Distribuicao_Regional_Leads_v2`, com RJ e ES numa entrada só e a fila nova `Leads_RJ_ES`. É implantada **inativa**, e a ativação é passo separado | 1 — configuração |
| Sequência do rodízio | **Campo Auto Number novo** `Lead.DIST_SequenciaRodizio__c` (técnico, aprovado no gate) | 1 — configuração |
| Dono da conta e rodízio | **Flow record-triggered novo** `Lead_AfterSave_DistribuiDonoRodizio`, after save, sem nenhuma classe | 2 — declarativo |
| Parâmetros e liga/desliga | **CMDT novo** `DistribuicaoLeadSetting__mdt`, registro `Padrao` (aprovado no gate) | 1 — configuração |
| Elegíveis por região | **Membros diretos da fila regional**, mantidos pelo administrador em Setup | 1 — configuração |
| Aprovação | **Não construída.** Os 3 processos ficam como estão (seção 10) | — |
| Encaminhamento a áreas internas | **Não construído.** A transferência comercial continua sendo a troca nativa de dono, com histórico de `OwnerId` já ligado | 1 (já existe) |

### 1.1 Por que a região continua na regra nativa
A régua por UF já roda na regra ativa e passou no QA da rodada 1. Juntar RJ e ES é editar uma entrada. Com uma versão nova da regra, a régua fica num lugar só, editável em Setup. Não se cria um segundo motor de região no Flow.

### 1.2 Por que Flow e não configuração pura
A plataforma não tem rodízio nativo de Lead. A regra de atribuição entrega só para fila ou usuário fixo. Territory Management não está habilitado, `maps__AssignmentRule__c` tem 0 registros e Omni-Channel não foi confirmado (recon, seções 1 e 6). Casar o Lead com a conta pelo CNPJ também não é configuração. Por isso o nível 2 (Flow) é o mais alto que resolve.

### 1.3 Por que não Apex
- **Decisão do responsável no gate** (seção 14): nada de classe nova. A cobertura da org é de 10% (assessment, achado 2), e cada classe nova é mais um item preso na ida à produção.
- **O motivo técnico da rodada 2 deixou de valer.** Em lote, um rodízio por estado gravado ("quem recebeu por último") repete o mesmo vendedor. Com o Auto Number, cada Lead já nasce com um número diferente. O vendedor sai de `MOD(número, quantidade de elegíveis)`, sem estado compartilhado entre os Leads do lote. Os critérios da doutrina para descer a Apex (volume com risco de limite, recursão com estado) não se aplicam (contas na seção 4).
- **Custo aceito:** o rodízio é **aproximado** (seção 2.3), o que o responsável aceitou. A regra não tem teste unitário determinístico. A prova vem da verificação e do QA, com casos objetivos (seção 12).

### 1.4 Viabilidade conferida na org (pedido do gate, item 6)
Validação `--dry-run` na DEV de um Flow mínimo com os mesmos elementos deste desenho, mais o campo Auto Number (`02-recon.md`, "Confirmações do arquiteto"). **Compila:**
- `RecordAfterSave` `CreateAndUpdate` com entrada `OR(ISNEW(), ISCHANGED({!$Record.OwnerId}))` e `triggerOrder`.
- Get Records em `GroupMember`, filtrando por `GroupId` e por `UserOrGroupId` começando com `005`, ordenado. Isso responde ao item 3 do adendo do recon: o Flow lê os membros da fila.
- Get Records em `User`, com `Id In` coleção, `IsActive` e `UserType`, ordenado por Id.
- Get Records em `Account` com `CompanyDocument__c = a OR = b`.
- Fórmula `MOD(VALUE({!Lead.DIST_SequenciaRodizio__c}), n)`. Isso responde ao item 7: o Auto Number é texto, e `VALUE` converte.
- Update de `$Record.OwnerId`.

**Não provado (só a execução prova):** a quantidade de SOQL num lote de 200, o tempo de CPU, e se `$Record` vê o dono gravado pela regra. O desenho não depende do último ponto, porque relê o Lead. A verificação mede cada um (seção 12), e a seção 4 traz a saída declarativa se algum falhar.

### 1.5 Escolha para o arquiteto humano no gate: fórmula do índice
A diretriz do gate é o resto da divisão: `MOD(n, k)`, com `n` o número do Lead e `k` a quantidade de elegíveis da fila. Ela tem um caso ruim. Se os Leads de duas regiões chegam **alternados** (SP, RJ, SP, RJ…) e cada fila tem 2 vendedores, todos os Leads de SP pegam números pares e vão para o mesmo vendedor. Isso acontece em qualquer chegada com período múltiplo de `k`.
- **Padrão deste design (segue a diretriz):** `MOD(n, k)`. Com Leads seguidos da mesma região, ou num lote ordenado por região, alterna perfeitamente.
- **Alternativa pronta, mesma estrutura, troca de uma fórmula (cerca de 1 h):** `FLOOR(k * MOD(n * 0.6180339887, 1))`, a sequência de Weyl pela razão áurea. Ela distribui por igual em qualquer padrão periódico de chegada. Em troca, Leads seguidos da mesma região deixam de alternar exatamente (com 2 vendedores, sai algo como A, B, A, A, B, A, B).
- O QA roda o caso T7 (seção 12) com o padrão escolhido, para o cliente ver o efeito. **Sem decisão no gate, vale `MOD(n, k)`.**

**Mudança de modelo de dados:** o campo `DIST_SequenciaRodizio__c` e o CMDT foram **aprovados pelo responsável no gate de 17/11** (seção 14, itens 2 e 5). Não há outro campo novo em objeto de negócio.

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

Nenhuma entrada tem template de e-mail, como na v1 (regra 2 da conta).

### 2.2 Flow `Lead_AfterSave_DistribuiDonoRodizio` (novo)
- **Gatilho:** Lead, after save, criação e atualização, caminho imediato (síncrono). Entrada por fórmula: `OR(ISNEW(), ISCHANGED({!$Record.OwnerId}))`.
- **Execução:** contexto de sistema, sem compartilhamento (padrão de Flow record-triggered). `triggerOrder` = 500, só para documentar a ordem. O desenho não depende dele (seção 4).
- **Descrição do Flow:** "EPLAST-35. Dono da conta pelo CNPJ ou rodízio entre membros da fila regional `Leads_*`."

Passos, em ordem. "Sai" quer dizer que o Lead fica como está.

1. **Configuração.** Get Records `DistribuicaoLeadSetting__mdt` com `DeveloperName = 'Padrao'`. Se não achar o registro, ou se `DistribuicaoAtiva__c` for falso: sai.
2. **Releitura do Lead.** Get Records `Lead` com `Id = $Record.Id` (campos `OwnerId`, `IsConverted`, `CompanyDocument__c`, `DIST_SequenciaRodizio__c`).
   - Não confia em `$Record`, porque não é certo que ele traga o dono gravado pela regra no mesmo salvamento (R1).
   - Se `IsConverted` for verdadeiro, ou o dono não for fila (`OwnerId` não começa com `00G`): sai.
   - Com isso, um Lead que o vendedor criou para si mesmo, com a caixa desmarcada, **não é mexido** (PA-27).
3. **Fila.** Get Records `Group` com `Id` = dono e `Type = 'Queue'`. Se o `DeveloperName` não começar com `PrefixoFilas__c` (padrão `Leads_`): sai. Filas de outros processos, como `PosVendas`, ficam intocadas.
4. **Dono da conta**, se `RespeitarDonoConta__c` for verdadeiro e o CNPJ do Lead não estiver vazio:
   - Fórmulas do Flow:
     - `fxCnpjDigitos`: o CNPJ do Lead sem ponto, barra, hífen e espaço.
     - `fxCnpjMascara`: com 14 dígitos, monta `00.000.000/0000-00`; com outro tamanho, repete os dígitos.
   - Get Records `Account` com `CompanyDocument__c = fxCnpjDigitos OR = fxCnpjMascara`. O campo é externalId, então a busca é indexada. Guarda todos os registros encontrados (`Id`, `OwnerId`).
   - **Exatamente uma conta** (diretriz do gate): Get Records `User` com `Id` = dono da conta, `IsActive = true` e `UserType = 'Standard'`.
     - Achou: o dono final é esse usuário. Vai ao passo 6. Isso vale também fora da região e na Triagem.
     - Não achou (dono inativo ou não Standard, PA-26): segue para o passo 5.
   - **Zero ou mais de uma conta:** segue para o passo 5.
5. **Rodízio.** Só roda se as três condições abaixo valerem; senão, sai.
   - `RodizioAtivo__c` é verdadeiro.
   - A fila não está em `FilasSemRodizio__c` (lista separada por `;`, padrão `Leads_Triagem`; teste por fórmula `CONTAINS(";" & lista & ";", ";" & DeveloperName & ";")`).
   - `DIST_SequenciaRodizio__c` não está vazio. Lead anterior ao campo não tem número (PA-31).

   Com as condições atendidas:
   1. Get Records `GroupMember` com `GroupId` = fila e `UserOrGroupId` começando com `005` (só membros diretos que são usuários, PA-23), ordenado por `UserOrGroupId`. Sem membro: sai.
   2. Loop: junta os Ids numa coleção de texto.
   3. Get Records `User` com `Id In` coleção, `IsActive = true` e `UserType = 'Standard'`, ordenado por `Id` crescente. Sem elegível: sai.
   4. Atribuição: `k` = quantidade de elegíveis, e `idx` = fórmula do índice (seção 1.5) sobre `n = VALUE(DIST_SequenciaRodizio__c)`.
   5. Loop com contador sobre os elegíveis: o de posição `idx` (a contagem começa em 0) é o dono final.
6. **Gravação.** Update Records em `$Record`, com `OwnerId` = dono final.
   - Não reaplica a regra e não manda e-mail (PA-29).
   - **Caminho de falha** ligado em todos os Get e no Update, terminando sem ação. Se a gravação falhar (por exemplo, quando o vendedor não pode ler Lead), o Lead fica na fila e a criação pela tela não é desfeita (PA-32). A plataforma registra a falha do Flow no log padrão (e-mail de erro de Flow ao administrador, configuração já existente). Nenhum e-mail novo é desenhado.
7. **Reentrada.** A gravação do passo 6 muda `OwnerId` e dispara o Flow de novo (`ISCHANGED`). Na reentrada, o passo 2 vê dono usuário e sai, com 2 Get Records (CMDT e Lead). Não há laço.

### 2.3 Rodízio aproximado (aceito pelo responsável)
- A sequência do Auto Number é **global**, não por região. Num volume razoável, cada vendedor da fila recebe uma parte parecida, mas dois Leads seguidos da mesma região podem cair no mesmo vendedor.
- Vantagens: sem contador, sem disputa de bloqueio entre transações simultâneas (a plataforma numera de forma atômica) e sem estado a corrigir.
- Um vendedor que entra ou sai da fila muda `k`, e a partir dali o resto da divisão se reorganiza. Não existe "vez" guardada a perder.
- Um Lead que volta à mesma fila com os mesmos membros cai no mesmo vendedor, porque o número dele é fixo (PA-28).

---

## 3. Mapa item a item: reaproveita, cria, não toca

| # | Componente (API name) | Ação | Prova |
|---|---|---|---|
| 1 | Regra `Distribuicao_Regional_Leads` (v1, ativa) | **Não edita.** Fica no arquivo `AssignmentRules/Lead` como está na org, e é desativada pela plataforma quando a v2 é ativada | recon, seção 1 |
| 2 | Regra `Distribuicao_Regional_Leads_v2` | **Cria, inativa.** Entradas da seção 2.1 | não existe |
| 3 | Fila `Leads_RJ_ES` (rótulo "Leads RJ/ES", objeto Lead, sem membros, sem e-mail aos membros, descrição "EPLAST-35. Regional RJ e ES.") | **Cria** | recon: não existe |
| 4 | Filas `Leads_SP`, `Leads_MG`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem` | **Reaproveita, sem alteração.** O build não muda membros | recon |
| 5 | Filas `Leads_RJ`, `Leads_ES` | **Não toca.** Saem da régua quando a v2 é ativada e não são apagadas (PA-22) | recon |
| 6 | Campo `Lead.DIST_SequenciaRodizio__c` (Auto Number, formato `{0}`, início 1, descrição "EPLAST-35. Número técnico sequencial usado pelo rodízio de Leads. Não editar nem usar em relatório de negócio.") | **Cria.** Fora do layout. Sem acesso de campo dado a perfil ou PS | recon adendo A: não existe Auto Number em Lead; `dry-run` aceitou |
| 7 | CMDT `DistribuicaoLeadSetting__mdt` com `DistribuicaoAtiva__c` (checkbox), `RodizioAtivo__c` (checkbox), `RespeitarDonoConta__c` (checkbox), `PrefixoFilas__c` (texto 40), `FilasSemRodizio__c` (texto 255) e o registro `Padrao` (`DistribuicaoAtiva__c = false`, `RodizioAtivo__c = true`, `RespeitarDonoConta__c = true`, `Leads_`, `Leads_Triagem`). Todo campo com descrição "EPLAST-35. …" | **Cria.** Em relação à rodada 2, sai `JanelaDiasReferencia__c` (não há mais referência por data), sai `AplicarEmTransferencia__c` (o Flow não distingue transferência manual de redistribuição pela API, PA-28) e entra o interruptor geral `DistribuicaoAtiva__c` | recon adendo A: não existe |
| 8 | Flow `Lead_AfterSave_DistribuiDonoRodizio` | **Cria**, Active (Flow novo, doutrina). Inerte até `DistribuicaoAtiva__c` ser ligado | recon adendo B: único Flow de Lead é o da linha 9 |
| 9 | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (v1, ativo) | **Reaproveita, sem versão nova** | confirmado nesta sessão (Tooling) |
| 10 | Classes `LeadAssignmentService` e `LeadAssignmentServiceTest` | **Reaproveita, sem alteração** | recon |
| 11 | Custom permission `Lead_DistribuicaoAutomaticaViaApi` e PS `PS_Integracao_DistribuicaoLead` | **Reaproveita, sem alteração** | recon |
| 12 | Layout `Lead-Lead Layout` (`runAssignmentRulesDefault = true`) | **Não toca** (EPLAST-26 e EPLAST-38) | recon |
| 13 | Histórico de campo de Lead (`OwnerId`, `Status`) | **Reaproveita** (já ligado). Mostra cada troca de dono feita pelo Flow | recon |
| 14 | Campos `Lead.CompanyDocument__c`, `Lead.State`, `Account.CompanyDocument__c`, `Account.OwnerId` | **Reaproveita, só leitura** | recon, seção 2 e adendo A |
| 15 | 3 Approval Processes e relatórios `Aprovacoes_Pendentes_Por_Processo` e `Histrico_de_Aprovao_XNR` | **Não toca** | recon |
| 16 | Classe `LeadRodizioService` e `LeadRodizioServiceTest` (rodada 2) | **Não cria** (decisão do gate) | recon adendo A: não existem |
| 17 | `fixtures/lead_rodizio_dono_conta.apex` | **Cria** o script de dado de teste (Leads com UF e CNPJ nos dois formatos, contas de teste com `TriggerUtility.bypassTrigger`, membros de fila de teste), com a limpeza no fim. É script de dado, não metadata implantada. Se o branch da EPLAST-38 já tiver entrado na `main` com `fixtures/lead_roteamento_regional.apex`, reaproveita as rotinas de Lead dele | recon, seção 4: `fixtures/` não existe na `main` |
| 18 | Agente `SFAgent2` | **Não se aplica** (a demanda não pede assistente) | regra 3 |

**Permissões:** nenhum perfil e nenhum permission set é criado ou alterado.
- O Flow roda em contexto de sistema, e por isso o usuário comercial não precisa ler `GroupMember`, `Account` alheia nem o campo Auto Number. O caso T15 prova isso com um usuário de perfil `Comercial - Analista`.
- Membros das filas são passo do administrador.
- O vendedor que entra como membro precisa ler Lead para poder ser dono. É o perfil comercial que ele já tem (R7).

---

## 4. Ordem de execução e limites

### Lead: inventário (recon e confirmação desta sessão)
- Nenhum trigger Apex.
- **0 Workflow Rules** (as 17 da org são de objetos `et4ae5__*`).
- 2 VRs (`Celular`, `Telefone`).
- A regra de atribuição ativa.
- Um Flow ativo: `Lead_AfterInsert_AplicaRegraAtribuicao`. Só criação, entrada `$Permission.Lead_DistribuicaoAutomaticaViaApi` e dono `005`, parte síncrona vazia, ação só no caminho `AsyncAfterCommit`, sem `triggerOrder`.
- Flows de pacote em Lead não foram inspecionados (R10).

Ordem da plataforma (doutrina): before-save → before triggers → VRs → gravação → after triggers → **regra de atribuição** → workflow → **after-save Flows** → commit → assíncrono.

1. **Tela, com a caixa marcada** (padrão do layout):
   - A regra v2 grava a fila regional.
   - O Flow novo entra (ISNEW), relê o Lead, vê a fila e grava o dono final na mesma transação.
   - A reentrada sai no passo 2.
   - O Flow antigo não entra, porque o usuário de tela não tem a custom permission.
2. **Tela, com a caixa desmarcada:** o dono é o criador. O Flow novo entra, vê dono usuário e sai (PA-27).
3. **API, por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho de regra:**
   - Na criação, o dono é o integrador. O Flow novo entra e sai.
   - Depois do commit, o Flow antigo chama `LeadAssignmentService`, que faz update com a regra padrão: a regra v2 grava a fila.
   - Nesse update, o Flow novo entra (ISCHANGED) e distribui. Tudo acontece na transação assíncrona, com limites assíncronos.
4. **API com o cabeçalho de regra:** como o item 1.
5. **Transferência manual para uma fila `Leads_*`:** o Flow redistribui (PA-28). Transferência para usuário: sai sem ação.
6. **Conversão:** se o dono mudar, o Flow entra e sai por `IsConverted`. A conta criada na conversão passa pela `AccountTrigger` como hoje. Não é efeito desta demanda.

**Dependência de ordem (R1, documentada):** a solução depende de a regra gravar a fila **antes** do after-save Flow. Isso é a ordem padrão da plataforma, e a releitura do Lead (passo 2) vê o valor gravado na própria transação. **A ordem entre os dois Flows after-save de Lead não importa:** o antigo não faz nada no síncrono, e o novo é idempotente. Só age se o dono atual, relido, for fila `Leads_*`.

### Account, Opportunity, Order, Quote
- **Account é só lida** (Get Records por `CompanyDocument__c`). Nada é gravado em Account. Por isso a `AccountTrigger` (Protheus, um job por conta), a trigger do SBQQ e os Flows de Account não são acionados.
- O defeito de `UpdateAccountCompanyInfo` não está nesse caminho e não é tocado.
- Opportunity, Order e Quote não são tocados.

### Governador e escala
| Cenário | Estimativa | Limite | Como prova |
|---|---|---|---|
| Lote de 200 Leads na criação (tela/API com cabeçalho) | Cerca de 6 consultas no primeiro passe (Lead, Group, Account, User do dono, GroupMember, User elegíveis; o CMDT pode não contar) + 2 na reentrada, e 2 DML (update, reentrada sem DML) | 100 SOQL / 150 DML síncronos | T3 mede SOQL e CPU no log de depuração |
| O mesmo lote pelo caminho da API sem cabeçalho | O mesmo, dentro da transação assíncrona do `LeadAssignmentService` | 200 SOQL assíncronos | T3b |
| CPU | O custo vem dos dois loops por interview (membros e elegíveis). Com 200 Leads e filas de até 30 membros, são uns 12 mil elementos executados, estimados em 1 a 3 s | 10 s síncrono | T3, com a maior fila de teste. **Acima de 70% do limite, volta ao design** (doutrina) |
| Pai com muitos filhos (achado SOMOSAGILITY-10) | Não se aplica: Lead não tem filho em cascata, Account é só lida e o update de Lead não dispara automação em outro objeto | — | — |
| Volume seguro declarado | Lote de até 200 Leads e filas de até 30 membros diretos. Acima disso, a carga é feita em lotes menores (o Data Loader faz isso por padrão) | — | — |

**Se a execução reprovar, a saída é declarativa (sem Apex, diretriz do gate):**
- Se o Get Records com `Id In` não for agrupado entre interviews e passar do limite de SOQL, sai o passo 5.3. Os elegíveis passam a ser os membros diretos da fila, e a premissa vira "o administrador remove da fila quem ficou inativo".
- Se a CPU passar de 70%, o volume seguro baixa para 100 Leads por lote, declarado no roteiro.
- Se nada disso fechar, o build para no gate dizendo o que não fecha. Ninguém desce a Apex.

---

## 5. Convivência com EPLAST-38 e EPLAST-26

**De quem são os componentes.** A rodada 1 da EPLAST-35 criou a regra, as 8 filas, o Flow antigo, a classe, a custom permission e o PS, e alterou o layout. A EPLAST-38 (em `aguardando_homologacao`) usa esses mesmos componentes sem alterá-los. **Esta rodada não edita nenhum componente da lista da 38.** Ela só acrescenta a regra v2 inativa, a fila nova, o campo, o CMDT e o Flow novo.

| Componente do preflight | Demanda | Como este design lida |
|---|---|---|
| `assignmentRules/Lead` | 38 | **Colisão de arquivo:** é um arquivo só para todas as regras de Lead. O arquivo da 35 leva a v1 como está na org e acrescenta a v2. Se o pacote da 38 for implantado depois, com a v1 ativa, ele reativa a v1 e desliga a v2 (R2). **Release da 38 antes da 35.** Antes do PR, o branch da 35 é rebaseado sobre a `main` com a 38, e o build refaz o retrieve do arquivo antes de acrescentar a v2 |
| `queues/Leads_*` | 38 | Não altera a definição nem os membros. O Flow novo **lê** os membros. Ligado, ele muda o resultado que a 38 homologa: o Lead sai da fila para um vendedor quando a fila tem membro. Ver a condição de ativação abaixo |
| `flows/Lead_AfterInsert_AplicaRegraAtribuicao` | 38 | Não toca e não cria versão. O Flow novo convive com ele (seção 4, item 3) |
| `classes/LeadAssignmentService`, `LeadAssignmentServiceTest` | 38 | Não toca |
| `customPermissions/Lead_DistribuicaoAutomaticaViaApi`, `permissionsets/PS_Integracao_DistribuicaoLead` | 38 | Não toca |
| `layouts/Lead-Lead Layout` | 26 e 38 | Não toca. O campo Auto Number é técnico e fica fora do layout |

**Condição de ativação na QAS (PA-30):** a v2 e o interruptor `DistribuicaoAtiva__c` só são ligados na QAS depois de fechar a homologação da EPLAST-38, ou com aceite do responsável pela conta para homologar as duas juntas. O Flow chega à QAS ativo, mas inerte, porque o CMDT vai com o interruptor desligado. Não há passo de deploy para ligar: é uma troca em Setup. Na DEV, a ativação para verificação está liberada.

**Versões e ativação (para o `04-plano-build.md`):**

| Item | Entra | Sai | Passo de ativação | Desfazer |
|---|---|---|---|---|
| Regra de Lead | `Distribuicao_Regional_Leads_v2` (deploy inativa) | `Distribuicao_Regional_Leads` (v1) | Depois da verificação na DEV, marcar a v2 como ativa em Setup. Na QAS, pela condição PA-30 | Reativar a v1 |
| Flow | `Lead_AfterSave_DistribuiDonoRodizio` (novo, Active) | — | Nasce ativo e inerte | Desativar o Flow ou desligar o interruptor |
| Interruptor | `DistribuicaoLeadSetting__mdt.Padrao.DistribuicaoAtiva__c` (deploy com `false`) | — | Ligar em Setup: na DEV para verificar, na QAS pela PA-30 | Desligar |

A ordem dos dois passos na mesma org: **primeiro a v2, depois o interruptor.** Com o interruptor ligado e a v1 ativa, o Flow distribuiria dentro de `Leads_RJ` e `Leads_ES`, que são filas válidas pelo prefixo. Não quebra nada, mas não é o desenho final.

---

## 6. Riscos

### Do assessment
| Achado | Toca? | Como o design lida |
|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order (alta) | Só leitura de Account | Nada é gravado nesses objetos. Em Lead, a ordem foi mapeada (seção 4) |
| #2 Cobertura Apex de 10% (alta) | Sim, é o motivo da decisão | Nenhum Apex novo. A cobertura não piora, e o bloqueio para produção, que é anterior, fica fora da esteira |
| #3 Nomes ambíguos e testes sem sufixo `Test` | Não | Não há classe |
| #4 Campos custom sem descrição | Sim | O campo, os campos do CMDT, a fila e o Flow saem com descrição "EPLAST-35. …" |
| API version desatualizada | Sim | Flow, campo e CMDT novos na API da org (68.0, a mesma do Flow ativo) |
| Perfis comerciais duplicados | Sim | Nada é atribuído por perfil. Elegível é membro de fila |
| #6 Alias e sandbox com "qa" | Não | Resolvido pela regra 5 da conta |

### Técnicos
| # | Risco | Sev. | Mitigação |
|---|---|---|---|
| R1 | A solução depende de a regra gravar a fila antes do after-save Flow | Média | Ordem padrão da plataforma, e o Flow relê o Lead em vez de confiar em `$Record`. Casos T1 e T3b |
| R2 | A EPLAST-38 implantada depois reativa a v1 (arquivo único de regras) | **Alta** | Release 38 → 35, rebase e retrieve fresco (seção 5) |
| R3 | Ligar na QAS muda o que a 38 homologa | Média | Interruptor desligado no deploy e condição PA-30 |
| R4 | Formato do CNPJ desconhecido: 0 registros com CNPJ na DEV, e nada impõe máscara | Média | O Lead é normalizado no Flow, e a conta é buscada nas duas formas (14 dígitos e máscara padrão). Conta gravada em outro formato não casa, e o Lead vai para o rodízio, que é falha segura. O QA mede na QAS **por contagem agregada** (seção 12, T6b), sem ler valor |
| R5 | `MOD(n, k)` concentra Leads num vendedor quando a chegada é periódica (seção 1.5) | Média | Escolha no gate. Caso T7. Fórmula alternativa pronta |
| R6 | Conta de propriedade de usuário de integração (por exemplo, criada pelo Protheus) leva Leads para esse usuário | Média | O filtro "ativo e Standard" não exclui o integrador. O QA conta na QAS as contas com CNPJ por perfil do dono (agregado). Se o integrador dominar, a PA-26 muda (ver PA-26) |
| R7 | Vendedor sem leitura de Lead na fila faz o update falhar | Baixa | Caminho de falha: o Lead fica na fila, e o salvamento não é desfeito (PA-32). Caso T14 |
| R8 | Fila sem membro: o Lead fica na fila | Baixa | Comportamento da rodada 1. Passo do administrador |
| R9 | `Lead.State` é texto livre: UF por extenso ou em minúsculas cai na Triagem | Média (já existia) | Mantido. Na Triagem, o dono da conta ainda é aplicado |
| R10 | Flows de pacote em Lead não foram inspecionados | Baixa | O verificador lista os Flows ativos com gatilho em Lead antes de ligar o interruptor |
| R11 | O Get Records com `Id In` não é agrupado no lote e estoura o limite de SOQL | Média | T3 mede. Saída declarativa na seção 4 |
| R12 | Leads anteriores ao campo ficam sem número: o deploy por metadata não preenche registros existentes | Baixa | PA-31: Lead sem número transferido para fila fica na fila. Dono da conta ainda vale |

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca Lead e distribuição. Nada é feito no Marketing Cloud, e nada é enviado pelo CRM. Esta rodada não cria campo para o Marketing Cloud: o Auto Number é técnico.

| Ponto | Onde fica no CRM |
|---|---|
| Dados que o Marketing Cloud lê | Lead: `FirstName`, `LastName`, `Email`, `Company`, `State`, `LeadSource`, `Status`, `OwnerId` e `CompanyDocument__c`. Nenhum campo novo é exposto |
| Como o público fica identificável | Depois da distribuição, o Lead está com um vendedor, não com a fila regional. **Segmentar por região é pela UF (`State`), não pelo dono.** Os relatórios `LEADS - SP/RJ/MG/ES/SUL/CO/GERAL` da pasta MARKETING CLOUD já filtram por `State` (rodada 1). RJ e ES continuam distinguíveis pela UF. Segmentar por vendedor: `OwnerId` |
| O que o Marketing Cloud devolve | Continua onde o conector `et4ae5` já grava. Leads que o conector cria no CRM entram pelo item 3 da seção 4 se o usuário do conector tiver `PS_Integracao_DistribuicaoLead`; senão, pelo item 1 ou 2, conforme o cabeçalho |
| Consentimento e opt-out | `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c`. A troca de dono não mexe neles |
| O que fica com quem opera o Marketing Cloud | 1) Gravar `State` com a sigla da UF e, quando houver, `CompanyDocument__c` com o CNPJ (14 dígitos ou com máscara), para o Lead cair na região certa e achar a conta. 2) Trocar segmentações regionais que usavam a fila como critério pela UF. 3) Excluir opt-out dos públicos |

---

## 8. O que NÃO será feito

- Classe Apex de qualquer tipo (decisão do gate).
- Gatilhos de aprovação, alçadas (desconto, margem, prazo, frete, pedido mínimo, crédito), filas de aprovadores e qualquer mudança nos 3 processos. Dependem da matriz da Eplast.
- Encaminhamento de demandas internas a áreas, com responsável, prazo e status.
- Rodízio exato por região, com contador ou "vez" gravada. O aproximado foi aceito.
- Casar Lead e conta por nome, razão social ou domínio de e-mail. Só por CNPJ.
- Normalizar ou regravar o CNPJ das contas existentes. Gravar em Account aciona o Protheus.
- Redistribuir os Leads já existentes ou preencher o número deles.
- Excluir `Leads_RJ` e `Leads_ES`. Mudar layout, `LeadAssignmentService`, o Flow antigo, a custom permission ou o PS.
- Incluir membros nas filas da QAS além do usuário de teste (é passo do administrador da Eplast).
- Omni-Channel, Salesforce Maps, Territory Management, picklists de estado e país.
- Qualquer coisa no Marketing Cloud, ou e-mail de notificação pelo CRM.
- Mexer no `SFAgent2`.

---

## 9. Alternativas discutidas

**Rodízio**
- **A (escolhida): Flow com Auto Number e `MOD`.** Sem código e sem estado, funciona em lote. É aproximado.
- **A' (opção do gate, seção 1.5):** a mesma estrutura, com o índice pela razão áurea.
- **B: contador por fila numa custom setting, que o Flow lê e incrementa.** Descartada. Em lote, todas as interviews leem o mesmo valor antes de qualquer gravação, e o rodízio sai errado (o motivo da rodada 2). Em transações simultâneas, há disputa de bloqueio no mesmo registro.
- **C: "vez" pela data do último Lead de cada vendedor.** Descartada. Mesmo problema em lote, e é uma consulta agregada que o Flow não faz.
- **D: classe Apex `LeadRodizioService` (rodada 2).** Recusada no gate.
- **E: Omni-Channel ou Salesforce Maps.** Exigem licença, presença ou territórios não confirmados.

**CNPJ**
- **A (escolhida): normalizar o lado do Lead no Flow e buscar a conta nas duas formas, no campo indexado.** Custo zero de modelo de dados.
- **B: fórmula `Account.DIST_CnpjDigitos__c` e busca por ela.** Descartada. Fórmula não é indexada. Em produção, com muitas contas, a busca vira consulta não seletiva, e a plataforma recusa consulta não seletiva em objeto grande dentro de gatilho. Custaria cerca de 1 h a mais e traria esse risco.
- **C: fórmula de dígitos também no Lead.** Desnecessária: a fórmula do Flow faz o mesmo sem campo novo.
- **D: Duplicate/Matching Rule de Lead × Account.** Não atribui dono.

**Região RJ/ES**
- **A (escolhida):** regra v2 e fila nova `Leads_RJ_ES`.
- **B:** reaproveitar `Leads_RJ` com o rótulo "RJ/ES". Descartada: o API name ficaria enganoso, e a fila é usada pela EPLAST-38.

---

## 10. Mapeamento dos 3 processos de aprovação (para a conversa com a Eplast)

Estão ativos (recon da rodada 2) e não são alterados. O detalhe vem do retrieve da rodada 1. Os aprovadores são citados por tipo, não por nome.

| Processo | Entrada | Etapas e aprovador | Ações | Onde complementar (quando houver matriz) |
|---|---|---|---|---|
| `Opportunity.FinancialAnalysis` | `StageName = Análise Financeira` | 1 etapa, 2 usuários nomeados | Alertas. Field updates `Atualizar_Fase_Fechado_Perdido` e `Atualizar_Motivo_de_Perda`. `allowRecall = false` | Limite de crédito e prazo fora da política |
| `Quote.AssignPricing` | Sem critério (toda cotação submetida) | 1 etapa, 1 usuário (Pricing) | Field updates `SubmittedApproval` e `SubmittedApproval2` | Desconto e margem. Exige mapear antes a ordem de execução entre Quote e CPQ |
| `Order.LiberationFinancial` | Sem critério (todo pedido submetido) | 1 etapa, os mesmos 2 usuários do financeiro | Task `FinancialBlock`. Field updates `ChangeStatusStock` e `ChangeStatusReview` | Pedido mínimo, frete e crédito |

---

## 11. Premissas assumidas (validar na homologação)

### Decidido pela Eplast em 17/11 e pelo responsável no gate de 17/11 (não é premissa)
- [x] Regionais: SP; RJ/ES; MG; SUL (PR, SC, RS); CO (DF, GO, MT, MS, TO); NO/NE (demais UFs listadas). Substitui a PA-03.
- [x] A região é a regra principal, a conta com dono definido tem precedência, e há rodízio dentro da região. Substitui a PA-04.
- [x] Aprovação: manter e mapear os 3 processos. Substitui a PA-01. Encaminhamento interno não é construído. Substitui a PA-06.
- [x] Parâmetros configuráveis sem deploy. CMDT `DistribuicaoLeadSetting__mdt` aprovado.
- [x] Sem Apex. O rodízio é por Flow com um campo Auto Number em Lead (aprovado). Dono da conta só com **exatamente uma** conta pelo CNPJ. Substitui a PA-21 da rodada 2.

### Mantidas
- [x] PA-02, PA-05, PA-07 a PA-14, PA-15 (caixa marcada por padrão), PA-16 (integração só com o PS), PA-17 (UF fora do padrão vai para a Triagem), PA-18 (sem e-mail), PA-19 (relatório de pendentes), PA-22 (`Leads_RJ` e `Leads_ES` saem da régua e não são apagadas), PA-23 (elegível é membro direto da fila, usuário ativo e Standard), PA-25 (sem rodízio na Triagem, mas o dono da conta vale lá; para mudar, tirar `Leads_Triagem` de `FilasSemRodizio__c`), PA-27 (o Lead que o vendedor cria para si com a caixa desmarcada continua dele), PA-29 (sem e-mail ao vendedor sorteado; ele vê em "Meus leads").

### Revistas ou novas nesta rodada
- [x] **PA-20 — Como casar o Lead com a conta?** *Decisão:* só pelo CNPJ. O do Lead é normalizado no Flow, e a conta é buscada como 14 dígitos ou como `00.000.000/0000-00`. *Evidência:* os dois campos existem. Em Account o campo é externalId (indexado). Nada na org impõe formato (sem máscara e sem VR de CNPJ; recon, adendo A). *Como mudar:* desligar `RespeitarDonoConta__c`. Se a contagem da QAS mostrar outro formato de gravação, acrescentar uma terceira forma à fórmula do Flow.
- [x] **PA-24 — Como é a vez no rodízio?** (substitui a da rodada 2) *Decisão:* o vendedor é escolhido pelo número sequencial do Lead, dividido pela quantidade de vendedores da fila, em ordem fixa. É aproximado: dois Leads seguidos da mesma região podem cair no mesmo vendedor. Em volume, equilibra. *Evidência:* decisão do responsável no gate. *Como mudar:* trocar a fórmula do índice (seção 1.5), sem mudar o modelo.
- [x] **PA-26 — Dono da conta inativo ou de integração?** *Decisão:* dono inativo ou não Standard é ignorado, e o Lead vai para o rodízio. Integrador ativo e Standard é aceito (R6). *Como mudar:* acrescentar ao passo 4 do Flow o filtro "dono é membro de alguma fila `Leads_*`" (cerca de 2 h).
- [x] **PA-28 — A transferência manual para uma fila regional redistribui?** *Decisão:* sim, sempre. O mesmo Lead, de volta à mesma fila com os mesmos membros, cai no mesmo vendedor. *Evidência:* o Flow não distingue a transferência manual da redistribuição pela API, e a chave da rodada 2 (`AplicarEmTransferencia__c`) não tem como funcionar sem código. *Como mudar:* para deixar um Lead parado numa fila, use `Leads_Triagem`, que não tem rodízio.
- [x] **PA-30 — Sequência com a EPLAST-38.** *Decisão:* release da 38 antes da 35. A v2 e o interruptor só são ligados na QAS depois de fechar a homologação da 38, ou com aceite do responsável para homologar as duas juntas. *Evidência:* arquivo único de regras de Lead, e a 38 em homologação. *Como mudar:* desligar o interruptor e reativar a v1.
- [x] **PA-31 — Lead criado antes do campo (sem número) volta para uma fila.** *Decisão:* o dono da conta ainda vale. Sem conta, fica na fila. *Evidência:* deploy de Auto Number por metadata não numera registros existentes. Ficar na fila é o comportamento da rodada 1, a opção mais segura. *Como mudar:* o administrador numera os existentes, se quiser (opção de Setup ao recriar o campo; fora desta demanda).
- [x] **PA-32 — A distribuição falha, por exemplo quando o vendedor não pode ler Lead.** *Decisão:* o Lead fica na fila, e o salvamento não é desfeito. *Evidência:* padrão de caminho de falha em Flow. Não derrubar a criação do Lead é a opção menos danosa. *Como mudar:* remover o caminho de falha, e então o erro aparece ao usuário.
- [x] **PA-33 — Nome do campo técnico.** *Decisão:* `DIST_SequenciaRodizio__c`. *Evidência:* a conta não tem prefixo próprio (CLAUDE.md do cliente). O padrão do squad é `<Prefixo>_<Contexto>__c`, e Lead já usa `MKT_` para o contexto de marketing. `DIST_` marca a distribuição. *Como mudar:* só antes do primeiro deploy na QAS. Renomear depois exige recriar o campo.
- [x] **PA-34 — Interruptor geral.** *Decisão:* o pacote chega com `DistribuicaoAtiva__c = false`. Ligar é um passo de Setup, primeiro na DEV, depois na QAS pela PA-30. *Evidência:* doutrina "ativação é passo separado". *Como mudar:* desmarcar desliga tudo, sem deploy.

### Pendências que bloqueiam (caso 3)
Nenhuma. Toda decisão pode ser desfeita sem perda de dado. Tudo é configurável em Setup ou por troca de uma fórmula no Flow.

---

## 12. Testes que o verificador e o QA devem exercitar

Dados sintéticos ("TESTE EPLAST-35"), pelo script `fixtures/lead_rodizio_dono_conta.apex`.
- Contas de teste criadas com `TriggerUtility.bypassTrigger`, sem Protheus.
- Telefones vazios ou em formato válido (VRs `Celular` e `Telefone`).
- Cada execução apaga o que criou.

**Usuários.** O usuário de teste `005bJ00000piKAaQAM` (ativo, conferido pelo recon) entra como membro de fila e como dono de conta de teste, **sem alteração de perfil, permissão ou papel**.
- **DEV:** o segundo elegível dos casos de 2 ou mais membros é outro usuário ativo Standard da sandbox, que sai da fila no fim. O usuário inativo `005bJ00000hBJmYQAW` entra como membro para provar que inativo é ignorado.
- **QAS:** os membros de teste vão só para `Leads_RJ_ES`, que é nova e não está na 38. Usuários reais não são incluídos em filas da 38. Na QAS (dado real), não se lê nem altera registro que o agente não criou.

| # | Caso | Esperado |
|---|---|---|
| T1 | Tela, caixa marcada, UF SP, `Leads_SP` com 2 elegíveis | Dono = um membro, não a fila. Histórico de dono: fila → vendedor |
| T2 | 4 Leads seguidos, todos UF MG, 2 elegíveis, sem outro Lead no meio | Alterna A, B, A, B com `MOD`. Com a fórmula alternativa: os 2 recebem |
| T3 | Lote de 200 com o cabeçalho de regra, 3 regiões, 3 elegíveis numa delas | Todos com dono. Cada elegível recebe Leads. Sem erro de limite. **Registrar SOQL, DML e CPU do log** (acima de 70% de qualquer limite, volta ao design) |
| T3b | O mesmo lote por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho | Depois do caminho assíncrono, todos com dono. Mesmas medições |
| T4 | UF RJ e UF ES | Os dois em `Leads_RJ_ES`, ou com um membro dela. Nenhum em `Leads_RJ` ou `Leads_ES` |
| T5 | Lead com CNPJ de uma conta de teste com dono X, UF de outra região | Dono = X |
| T6 | CNPJ com máscara no Lead e só dígitos na conta, e o inverso | Dono = X nos dois |
| T6b | Só na QAS, só contagem agregada: total de contas com CNPJ, as que seguem a máscara (`LIKE '__.___.___/____-__'`) e as sem ponto | Registrar as três contagens. Se houver muitas fora das duas formas, informar no roteiro (R4) |
| T7 | Lote alternando SP, MG, SP, MG… (40 Leads), 2 elegíveis em cada | Registrar a distribuição por vendedor com a fórmula escolhida no gate. Com `MOD`, mostra a concentração (R5). É evidência para o cliente, não reprovação |
| T8 | CNPJ em 2 contas de teste com donos diferentes | Vai para o rodízio |
| T9 | Conta casada cujo dono é o usuário inativo | Vai para o rodízio |
| T10 | UF vazia: com conta casada e sem conta | Com conta: dono = X. Sem conta: fica em `Leads_Triagem` |
| T11 | Fila regional sem elegível (só o membro inativo) | Fica na fila |
| T12 | Tela, caixa desmarcada | Dono = criador |
| T13 | Transferência manual para `Leads_MG` com elegíveis; `RodizioAtivo__c = false`; `DistribuicaoAtiva__c = false` | Redistribui; fica na fila; nada acontece (nem dono da conta) |
| T14 | Falha na gravação: elegível sem leitura de Lead, se houver perfil assim na DEV | O Lead fica na fila e é salvo sem erro na tela. Se não houver perfil assim, declarar como não exercitado |
| T15 | Um usuário `Comercial - Analista` cria o Lead pela tela | Distribui sem erro de acesso |
| T16 | Isolamento | `COUNT()` de Account, Opportunity e Order igual antes e depois. Nenhum job novo de `SendAccountToProtheus` ou `UpdateAccountCompanyInfo` (`AsyncApexJob` agregado) |
| T17 | Versões | Os 3 `ApprovalProcess`, `LeadAssignmentService` e o Flow antigo sem mudança. A v2 ativa e a v1 inativa só depois do passo de ativação. Nenhuma classe nova na org |
| T18 | Lead convertido com troca de dono | O Flow entra e sai, sem erro |

O QA repete as premissas PA-20, 24, 26, 28, 31, 32 e 34 no roteiro do cliente, na seção "O que assumimos e você precisa confirmar", em linguagem de usuário. A PA-24 entra com o exemplo do T7.

---

## 13. Ordem do build, e o que fica com quem opera o Marketing Cloud

**Build** (branch `feature/EPLAST-35`, commits `EPLAST-35: <verbo no imperativo>`, só `sbx-eplast-dev`):
1. Rebasear sobre a `main` (com a EPLAST-38, se já tiver entrado) e refazer o retrieve de `AssignmentRules:Lead`.
2. Criar o campo `Lead.DIST_SequenciaRodizio__c`.
3. Criar o CMDT `DistribuicaoLeadSetting__mdt`, os campos e o registro `Padrao` com o interruptor desligado.
4. Criar a fila `Leads_RJ_ES`.
5. Acrescentar `Distribuicao_Regional_Leads_v2`, inativa, ao arquivo de regras, sem alterar a v1.
6. Criar o Flow `Lead_AfterSave_DistribuiDonoRodizio` (Active), com a fórmula do índice escolhida no gate (`MOD` se não houver escolha) e caminho de falha em todo Get e no Update.
7. Implantar na DEV. Escrever `fixtures/lead_rodizio_dono_conta.apex`.
8. Ativação na DEV para verificação: ativar a v2, depois ligar `DistribuicaoAtiva__c`. Registrar em "Versões e ativação" do plano.
9. Entregar ao verificador, com T1 a T18 (o T6b é só da QAS).

**Quem opera o Marketing Cloud:** os itens 1 a 3 da seção 7. Nada é configurado lá pela esteira.

---

## 14. Estimativa

**Estimativa de esforço:** 28–46 h

O que mudou em relação à análise (120–260 h) e à rodada 2 (34–56 h):
- Sai a classe Apex com o teste (12–18 h na rodada 2). Entra o Flow declarativo, mais longo por causa dos loops, das fórmulas e dos caminhos de falha (8–12 h).
- **Entra:** campo Auto Number 0,5–1 h. CMDT e registro 2–3 h. Regra v2 e fila 2–3 h. Flow 8–12 h. Verificação na DEV com lote de 200, medição de limites e membros de teste 6–10 h. QA, roteiro novo e homologação 7–12 h. PR, rebase sobre a 38 e documentação 2,5–5 h.
- **Sai:** aprovação e encaminhamento interno, por decisão da Eplast, e a classe Apex, por decisão do gate.
- **Não inclui:** a mudança da PA-26 (cerca de 2 h), rodízio exato por região, alçadas de aprovação, encaminhamento interno.

---

## 15. Registro: respostas da Eplast (17/11) e decisão do responsável no gate (17/11)

**Respostas da Eplast de 17/11:**
- Regionais com RJ e ES juntos.
- Região como regra principal, respeitando a conta com dono, com rodízio dentro da região.
- Aprovação: manter e mapear os 3 processos. Gatilhos e alçadas esperam a matriz.
- Encaminhamento a áreas internas é escopo a combinar.
- Parâmetros configuráveis sem deploy.

**Decisão do responsável no gate de design da rodada 2 (2026-11-17), transcrita:**
1. Nenhuma classe Apex nova. `LeadRodizioService` e `LeadRodizioServiceTest` não serão construídas: a cobertura de 10% prende qualquer Apex na ida à produção, e o responsável não quer mais uma classe para manter.
2. Rodízio por Flow, com um campo de numeração automática no Lead. O vendedor é escolhido pelo resto da divisão do número pela quantidade de membros elegíveis da fila, em ordem fixa. O campo novo em Lead está aprovado: é técnico e não guarda dado de negócio.
3. O rodízio aproximado está aceito (sequência global). Registrar como premissa a validar na homologação.
4. Dono da conta com precedência, pelo Flow: exatamente uma conta pelo CNPJ dá o dono; zero ou mais de uma vai para o rodízio. Conferir o formato do CNPJ, propor normalização declarativa se preciso, ou declarar a limitação, sem voltar ao Apex.
5. Continuam: regra v2, fila `Leads_RJ_ES`, `DistribuicaoLeadSetting__mdt` (aprovado), aprovação e encaminhamento fora.
6. Confirmar a viabilidade declarativa (membros da fila no Flow, lote de 200, ordem com o Flow antigo e com a EPLAST-38) e a estimativa nova. O que não for viável sem código para no gate.

Resposta deste design ao item 6: seção 1.4 (compila na org), seção 4 (ordem, limites e saídas declarativas) e seção 5 (EPLAST-38). Ao item 4: seção 2.2, passo 4, PA-20 e R4.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
