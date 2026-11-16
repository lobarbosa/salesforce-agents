**Resultado do build:** concluído

# EPLAST-30 · Plano de build (rodada 2, opção E do design)

**Org usada:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, `sf org list` conferido antes de tocar em algo). Nada foi feito na QA nem em produção.
**Branch:** `feature/EPLAST-30`. **Design seguido:** `03-design.md` (seções 0, 2, 3), com aceite em `gates.md`.
**Dados:** a dev tem 0 Opportunity. Nenhum SOQL de dado real. Testes do modelo só com texto sintético.

## 1. Passo 0 (teto de 2 h): resultado

**Fechou. Fallback C (Apex) não foi acionado.** Gasto bem abaixo do teto.

| # | Tentativa | Resultado |
|---|---|---|
| 1 | `Rascunho_Followup_Comercial` sem `templateDataProviders`, com 2 entradas `primitive://String` (`DadosOportunidade`, `DadosCotacao`; referência no corpo `{!$Input:DadosOportunidade}` e `{!$Input:DadosCotacao}`). Dry-run, depois deploy real | Sucesso, sem erro |
| 2 | Chamada do template pela API de geração (`/einstein/prompt-templates/<nome>/generations`) com texto sintético nas duas entradas | Resposta em ~4 s usando o texto passado (nome da oportunidade, etapa, conta, campo ausente listado em "Campos vazios") |
| 3 | Flow com ação `generatePromptResponse` e parâmetros `Input:DadosOportunidade` e `Input:DadosCotacao` | Dry-run e deploy do Flow aceitos (a plataforma valida a ação e os nomes dos parâmetros) |

Nomes confirmados: entrada `DadosOportunidade` / `DadosCotacao`; parâmetro da ação no Flow `Input:<apiName>`; saída `promptResponse`. Modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini` disponível na dev (respondeu).

Observação: o conteúdo dos templates tinha `&quot;`, `&lt;` e `&gt;` que a plataforma entregava ao modelo como texto literal. Troquei por aspas simples e parênteses nos 3 templates.

## 2. O que foi construído (todos com `Description`)

Deploy na dev feito componente a componente (dry-run antes, quando aplicável). Todos com sucesso.

| Componente | Tipo | Ação |
|---|---|---|
| `Rascunho_Followup_Comercial` | GenAiPromptTemplate (Flex) | Criado na dev. Sem provider; 2 entradas de texto; regras 7 a 9 novas (contato só `[nome do contato]`, tom neutro, dado dos blocos tratado como dado) |
| `Rascunho_Proposta_Comercial` | GenAiPromptTemplate (Flex) | Idem (regras 6 a 8 novas) |
| `Argumentos_Comerciais_Oportunidade` | GenAiPromptTemplate (Flex) | Idem; cada item cita a fonte |
| `Opportunity_Screen_RascunhoComercial` | Flow (Screen), `DefaultMode`, ativo | Reescrito. Entrada `recordId` (String). Ver 3 |
| `PS_Comercial_RascunhoIA` | PermissionSet | Criado. Removidos acessos aos 2 PromptFlows e FLS de `Opportunity.NextStep`, `Opportunity.Description`, `SBQQ__QuoteLine__c.SBQQ__Product__c`, `SBQQ__QuoteLine__c.SBQQ__Description__c` (fora da lista permitida). Acrescentados `Opportunity.Amount`, `Opportunity.Probability`, `SBQQ__QuoteLine__c.SBQQ__ProductName__c`. Só leitura. Sem Contact |
| `PSG_Comercial_RascunhoIA` | PermissionSetGroup | Criado: `PS_Comercial_RascunhoIA` + `force__EinsteinGPTPromptTemplateUser` (é o API name com namespace; existe na dev e o PSL `EinsteinGPTPromptTemplates*` está presente). Status `Updated` |
| `Opportunity_Record_Page` | FlexiPage | Alterada: aba "Rascunho IA" com `flowruntime:interview` (`recordId`), visível por `{!$Permission.CustomPermission.IA_Rascunho_Comercial}` |
| `IA_Rascunho_Comercial` | CustomPermission | Reaproveitada, sem mudança |

Não tocados: `SFAgent2`, `PS_Comercial_ResumoClienteAgente`, permission sets padrão do Einstein, qualquer perfil, `Opportunity_Record_Page_Three_Column`.

## 3. Screen Flow: como ficou (design 3.2)

- Tela de escolha (proposta, follow-up, argumentos), nenhuma chamada ao modelo ao carregar.
- Get Records em ordem, sem SOQL em loop, todos com `faultConnector` para a tela de erro: Opportunity (lista permitida) → decisão "acessível?" (sem registro: tela de negativa, **modelo não é chamado**) → Account (se `AccountId`) → `SBQQ__Quote__c` (se `SBQQ__PrimaryQuote__c`) → `SBQQ__QuoteLine__c` ordenadas por `SBQQ__NetTotal__c` desc.
- Loop só com Assignment, para em 50 linhas. Fórmulas `fDadosOportunidade`, `fDadosCotacao`, `fLinhaAtual` montam o texto; campo vazio vira `[dado ausente: <rótulo>]`; sem cotação, o bloco diz `sem cotação`; acima de 50, `e mais N itens (ver cotação)` com `SBQQ__LineItemCount__c`.
- Ação de Prompt Template do tipo escolhido, com fault path. Tela de resultado com área de texto editável.
- **Zero** `recordCreates`, `recordUpdates`, `recordDeletes`, e-mail ou aprovação. Acesso adicional exigido para rodar (`isAdditionalPermissionRequiredToRun`).

## 4. O que foi deprecado (CA-14)

`Opportunity_PromptFlow_DadosOportunidade` e `Opportunity_PromptFlow_CotacaoPrimaria`: removidos da dev e apagados do `force-app/`. Confirmado por consulta: 0 PromptFlow na dev. Rollback: histórico do Git.

Como foi feito, por haver desvio do plano: o deploy com `status Obsolete` só criou uma versão Draft (a v1 seguiu ativa) e o `destructiveChanges` falhou com "insufficient access rights on cross-reference id". Resolvi só na dev: desativei os 2 `FlowDefinition` pela Tooling API (`activeVersionNumber` 0) e apaguei as 4 versões (2 Draft, 2 Obsolete) pela Tooling API. O manifesto de destructive não foi mantido no repositório (não deve rodar na QA, onde os flows não existem). Release: nada a remover na QA nem em produção.

## 5. Desvios do design (todos pequenos, para o verificador e o revisor do PR)

1. **Limite de 50 linhas no loop, não no Get Records** (o Get Records do Flow não tem LIMIT). A consulta traz todas as linhas da cotação primária (teto de plataforma 2.000 registros) e o loop corta em 50. Para cotação com muitas linhas há custo de leitura; aceitável para v1 (PD-01 continua valendo e o limite é um número na decisão `Decision_Limite`).
2. **Ordenação:** o Flow não permite "nulos por último"; linha com `SBQQ__NetTotal__c` vazio pode vir primeiro.
3. **Formato de valor (PD-04):** valor passado como está, sem arredondar, com a moeda (`CurrencyIsoCode`) para oportunidade e cotação e vírgula decimal (`SUBSTITUTE`). **Sem separador de milhar.** A moeda da linha da cotação não é mostrada (não está na lista permitida; é a da cotação). Data em `dd/mm/aaaa`.
4. **`Opportunity_Record_Page` local estava defasada em relação à org** (faltavam campos de outra demanda, `PriorityScore__c` e `PriorityBand__c`). Para não sobrescrever, parti da versão da org (retrieve) e acrescentei só a aba e a região do Flow. Quem for ao release deve implantar este arquivo, não a versão antiga do `main`.
5. **`Opportunity_Record_Page_Three_Column`** não foi alterada. PD-05: a página padrão da org para Opportunity (Large e Small) é `Opportunity_Record_Page` (pelo `actionOverrides` do objeto). Atribuições por app ou perfil não são visíveis por API e não foram medidas; se algum público comercial usar a Three_Column, a aba não aparece para ele.
6. A sintaxe de visibilidade que a plataforma aceitou é `$Permission.CustomPermission.<nome>`; a forma `$Permission.<nome>` do arquivo antigo falhava no deploy.
7. Nos campos de endereço da conta (`BillingCity`, `BillingState`) e em `IsClosed`/`IsWon`, não há FLS configurável; a leitura vem da permissão de objeto.

## 6. Premissas assumidas (validar na homologação)

As PA-01 a PA-16 e PD-01 a PD-07 do design seguem como estão. Novas, deste build:

- **PB-01 · Marcador `[a preencher]` e saudação.** Pergunta: como o rascunho trata preço sem cotação e os dados do remetente? **Decisão:** instrução para usar `[a preencher]`, mas o modelo às vezes escreve "a preencher" sem colchetes e inclui `[Seu nome]`/`[Data atual]` na proposta. **Evidência:** teste com texto sintético, 3 templates. **Como mudar:** ajustar a regra 2 do template ou pedir que o vendedor complete os marcadores; texto é rascunho editável.
- **PB-02 · Oportunidade sem conta.** **Decisão:** gera mesmo assim, com `[dado ausente: ...]` nos campos da conta. **Evidência:** padrão (opção mais simples). **Como mudar:** decisão `Decision_Conta`.
- **PB-03 · Aba só na página padrão.** Ver desvio 5. **Como mudar:** repetir a inserção da aba na Three_Column.

Pendências em aberto: nenhuma (nenhum caso 3 da regra 4).

## 7. Pontos a verificar pelo verificador (dev)

Limite do que já foi provado: o **Screen Flow não foi executado de ponta a ponta** (não há como rodar Screen Flow pela CLI, e a dev não tem registros). Provado: deploy e ativação do Flow, template aceitando as entradas e respondendo, comportamento do modelo com texto sintético (injeção ignorada, e-mail não escrito, sem cotação tratado). O verificador deve exercitar o Flow pela página, com massa sintética criada por ele (a cadeia de automação de Account/Opportunity dispara na criação, R6; preencher validation rules; nada de dado real):

1. CA-01 a 03: abrir aba "Rascunho IA" numa oportunidade sintética com conta e cotação primária; gerar os 3 tipos; tempo medido (alvo 15 s); argumentos citam fonte.
2. CA-04/05: oportunidade sem `CloseDate`; oportunidade sem cotação primária (bloco `sem cotação`, nenhum preço inventado).
3. CA-06: valor do texto igual ao `SBQQ__NetAmount__c` (conferir vírgula decimal e moeda).
4. CA-07: contato sintético com e-mail e telefone; nada disso no texto (Contact não é lido).
5. CA-08: usuário sintético sem acesso à oportunidade: tela de negativa, modelo não chamado.
6. CA-09: usuário sem o PSG não vê a aba nem roda o Flow. Atribuir o PSG só ao usuário de teste.
7. CA-10: forçar erro (template desativado) e ver a tela de erro sem travar o registro.
8. CA-11/12: debug log sem trigger nem Flow record-triggered; contagem de Task/Event antes e depois igual.
9. CA-13: cotação sintética com mais de 50 linhas: 50 no texto e "e mais N itens".
10. CA-14: 0 PromptFlow na dev (já conferido por consulta).
11. Conferir que `Opportunity_Record_Page` na dev mantém `PriorityScore__c` e `PriorityBand__c` (a aba foi inserida sobre a versão da org).

Riscos que seguem do design: R2 (dado de cliente a provedor de modelo; só sintético na sandbox), R5 (licença/créditos em produção, PA-13), R6 (massa sintética).

## 8. Git

Branch `feature/EPLAST-30`; commits na ordem de entrega e PR aberto sem merge (ver resposta da sessão). `gates.md`, `status.yaml`, `CLAUDE.md` e `src/` não foram incluídos nos commits do build.

## Correções da rodada 1
Org: `sbx-eplast-dev` (conferida com `sf org list`). Roteiro lido: `05-testes-rodada-1.md` (rodada de QA numerada 2 no texto).

- **FALHA 2 (follow-up não cita data de fechamento): corrigida.** Regra 5 do prompt de `Rascunho_Followup_Comercial` passou a mandar citar conta, etapa e data de fechamento, com `[dado ausente: data de fechamento]` se vazia. Deploy na dev `0AfHa00000EI5R0KAL` (Succeeded). Ajuste feito no mesmo template, sem versão nova: ele foi criado por esta demanda e ainda não foi a produção; a EPLAST-41 usa o mesmo arquivo, e a mudança é só a regra 5. Teste na dev com texto sintético, 2 de 2 chamadas citaram `31/12/2026`. A QA ainda precisa receber o template pelo deploy da esteira.
- **FALHA 1 (caminho do Flow não exercitado por falta de login com o PSG): não corrigível no build.** É limitação do ambiente de teste: o único login é a conta de serviço, e a regra da conta proíbe alterar a permissão dela. Nada no metadata muda. Encaminhamento: delivery atribui `PSG_Comercial_RascunhoIA` a um usuário de teste com login, ou o time executa `05-roteiro-cliente.md` (C-09 a C-12).

## Correções da verificação 1
Org: `sbx-eplast-dev` (conferida com `sf org list`). Verificação lida: `04-verificacao-rodada-1.md`.

- **FALHA 1 (regra 5 do follow-up não efetiva na dev): corrigida.** Causa confirmada: versão `Published` de template Flex é imutável e a correção da rodada 1 de QA foi editada no mesmo `versionIdentifier` (`..._1`), ignorada pela plataforma. A correção anterior do plano ("sem versão nova") estava errada. Agora `Rascunho_Followup_Comercial` tem `templateVersions` com `_1` (texto antigo, preservado como está na org) e `_2` (regra 5 nova: conta, etapa e data de fechamento, com `[dado ausente: data de fechamento]` se vazia), e `activeVersionIdentifier` aponta para `_2`. Deploy na dev com sucesso (duas vezes, a segunda após restaurar o texto antigo em `_1` no arquivo). Teste na dev com texto sintético: 5 de 5 chamadas citaram `31/12/2026`; conta e etapa também citadas. O arquivo da branch leva as duas versões, então o deploy da esteira para a QA entrega a `_2` ativa. O retrieve de conferência na dev não completou (timeout); a prova é o comportamento da geração. Os outros 2 templates não mudaram.
- **V-08/V-09 (Flow de ponta a ponta e página da EPLAST-26): sem mudança de metadata.** Limitação do ambiente (sem login com o PSG, Screen Flow não roda pela CLI); seguem para quem tem o PSG, via `05-roteiro-cliente.md`.

## Correções da rodada 2
Org: `sbx-eplast-dev` (conferida com `sf org list`; Org Id `00DHa000006vfMLMAY`). Roteiro lido: `05-testes-rodada-2.md` (rodada 3 no texto). Nenhuma alteração de metadata nesta sessão.

- **FALHA 1 (Screen Flow não exercitado na QA: atribuição do PS recusada por falta de licença CPQ): não corrigível no build.** É limitação do ambiente de teste, não defeito do pacote. O PS leva leitura de `SBQQ__Quote__c` e `SBQQ__QuoteLine__c`, exigidas pelo design (seções 3.4 e 6: cotação primária e linhas), e a plataforma só atribui o PS a quem tem a licença `SalesforceCPQ_CPQStandardPerm`. Tirar essas permissões para contornar o teste quebraria o critério de preço com cotação e divergiria do design aprovado, então não foi feito. O caso C-08 (follow-up com data de fechamento) já passou; C-01 a C-07 passaram.
- **Encaminhamento (delivery):** atribuir a licença CPQ ao usuário do job na QA, ou usar usuário de teste que já tenha a licença e login, e dar a ele o `PSG_Comercial_RascunhoIA`; ou o time executar `05-roteiro-cliente.md` (C-09 a C-12).
- **Ponto de rollout para o design e o PR:** `PSG_Comercial_RascunhoIA` só pode ser atribuído a usuários com licença CPQ (a org tem 4 de 5 em uso). Registrar na lista de atribuição pós-deploy (PA-06).

## Mudança da decisão do responsável (2026-11-16): sem cotação
Org: `sbx-eplast-dev` (conferida com `sf org list`; Org Id `00DHa000006vfMLMAY`). Design lido: seção "Decisão do responsável (2026-11-16): tirar a cotação", que vale acima do que o design diz sobre cotação. Sem Apex, sem classe nova. Deploy na dev com sucesso (`0AfHa00000EIAgnKAH`; o Flow foi reimplantado depois, ver abaixo).

| Componente | O que mudou |
|---|---|
| `Opportunity_Screen_RascunhoComercial` | **Versão 2, Draft** (a v1 segue ativa, não foi editada). Saíram `Get_Quote`, `Get_Linhas`, o loop de linhas, `Decision_Cotacao`, `Decision_Limite`, `Assign_Linha`, as fórmulas `fDadosCotacao`/`fLinhaAtual`, as variáveis de cotação e o campo `SBQQ__PrimaryQuote__c` da leitura da Opportunity. As 3 ações passam só `Input:DadosOportunidade`. Zero referência a `SBQQ` no Flow (só a frase da descrição). Segue só leitura, com fault paths e tela de negativa |
| `Rascunho_Followup_Comercial` | Versão `_3` (a `_1` e a `_2` ficam como estão: versão publicada é imutável). Sem a entrada `DadosCotacao` nem o bloco de cotação. Regra 2 reescrita (ver PE-01). `activeVersionIdentifier` aponta para a `_3` |
| `Rascunho_Proposta_Comercial` | Versão `_2`, mesmas mudanças. Ativa |
| `Argumentos_Comerciais_Oportunidade` | Versão `_2`. A fonte do argumento passa a ser só `Oportunidade.<campo>` ou `Conta.<campo>`. Ativa |
| `PS_Comercial_RascunhoIA` | Saíram as permissões de objeto de `SBQQ__Quote__c` e `SBQQ__QuoteLine__c` e os 11 campos `SBQQ__*`. Ficam Opportunity e Account (leitura), `IA_Rascunho_Comercial` e o acesso ao Flow. Descrição encurtada (limite de 255) |
| `PSG_Comercial_RascunhoIA` | Sem mudança de arquivo: só traz o PS e `force__EinsteinGPTPromptTemplateUser`, sem licença CPQ (0 ocorrência de `SBQQ`) |
| `Opportunity_Record_Page` | Sem mudança. O diff contra a `main` não traz nenhuma linha com `SBQQ`; os `SBQQ` que existem na página (campo de cotação primária, lista de cotações) já eram da org, não desta demanda |

**Prova na dev:** os 3 templates, chamados pela API de geração com texto sintético só em `DadosOportunidade`, responderam usando os dados (nome, etapa, data de fechamento, valor, conta); campo vazio entrou em "Campos vazios"; nenhum bloco de cotação, nenhum preço inventado. O Flow v2 passou na validação como Active (dry-run) e está salvo como Draft. Primeiro deploy do Flow deixou a v2 como `InvalidDraft` (foi enviado junto com os templates, antes de a versão nova deles valer); reenviado sozinho, a v2 ficou `Draft` válida. O Screen Flow segue sem execução de ponta a ponta (limite de ambiente já registrado nas rodadas anteriores).

### Versões e ativação
- **Flow `Opportunity_Screen_RascunhoComercial`: v1 Active (com cotação), v2 Draft (sem cotação).** A v2 **não foi ativada**: a ativação é passo separado, de quem aprova o PR/release.
- **Atenção à ordem:** os templates já estão na versão nova (sem `DadosCotacao`) e o PS sem `SBQQ`. A v1 ativa ainda envia `Input:DadosCotacao` e lê `SBQQ`, então **na dev a v1 deixou de ser utilizável até a v2 ser ativada**. Ativar a v2 junto com a implantação dos templates e do PS em qualquer org (QA inclusive). Na QA, o deploy da esteira leva o Flow como Draft (o arquivo está Draft); a ativação lá é passo manual.
- Templates: ativação já vai no `activeVersionIdentifier` do arquivo; a versão antiga fica preservada na org.
- Rollback: reativar a v1 do Flow e voltar o `activeVersionIdentifier` dos templates para a versão anterior (`_1` ou `_2` no followup); o PS volta pelo Git (a v1 do Flow precisa de `SBQQ` e de licença CPQ).

### Premissas assumidas (validar na homologação)
- **PE-01 · O rascunho não cita a cotação (decisão do responsável, 2026-11-16).** Se a Eplast quiser, entra em demanda própria, com licença de CPQ para quem usa.
- **PE-02 · Valor e condições sem cotação.** Pergunta: de onde vem o preço agora? **Decisão:** só `Opportunity.Amount` ("Valor da oportunidade", com moeda), como está; desconto, prazo de pagamento, condição comercial e quantidade de itens ficam `[a preencher]` (proposta e follow-up) ou sem argumento (argumentos). **Evidência:** são os únicos dados que restam depois da decisão; opção mais simples. **Como mudar:** regra 2 de cada template (nova versão de template).
- **PE-03 · "Produtos".** A decisão diz que oportunidade, conta, produtos e o resto seguem. No design aprovado, produto só entrava pelas linhas da cotação; não há leitura de `OpportunityLineItem` no desenho. **Decisão:** não criei leitura de produto da oportunidade (seria desenho novo, com permissão e campos novos). **Como mudar:** demanda própria ou ajuste de design que liste os campos de `OpportunityLineItem`/`Product2`, leitura no Flow e FLS no PS.
- **PE-04 · Limite de 50 linhas (PD-01) e CA-13 deixam de se aplicar**, por não haver mais linhas. A massa sintética de cotação com mais de 50 linhas não é necessária.

### Para o verificador (muda em relação à seção 7)
Os itens 1 a 3 (preço da cotação, `SBQQ__NetAmount__c`) e 9 (50 linhas) deixam de valer: conferir que o texto traz o valor da oportunidade e não cita cotação. Item 6/CA-09 e o login com o PSG ficam mais simples: o PS não exige mais licença CPQ, então a atribuição do PSG a um usuário de teste deixa de falhar por isso (a falha da rodada 2 de QA). Conferir na dev que o PS não tem objeto `SBQQ`. A v2 do Flow está Draft: para exercitar, ativar a v2 na dev (passo à parte).
