# ACXYA-2 — Desenho da solução (design enxuto de sustentação)

**Etapa:** 3 (arquitetura) · **Autor:** agente `arquiteto` · **Data:** 2026-09-14
**Tipo da demanda:** sustentação (melhoria simples) → design enxuto, **gate bloqueante mantido**
**Org usada para confirmação:** `sbx-acxya-dev` — sandbox
`https://acxya--sbxacxya.sandbox.my.salesforce.com` · Org Id `00DHa000006bRsDMAU` · API v67.0
(`isSandbox: true`, confirmado em `sf org list` antes de qualquer comando). Produção não está
conectada nesta máquina e nenhum comando desta etapa a tocou.
**Base:** `01-analise.md` (aprovado no gate por Leonardo em 2026-09-14) e `02-recon.md`
(coletado 2026-09-14, mesma sessão).
**Comandos desta etapa:** somente leitura (`sf org list`, `sf sobject describe`,
`sf org list metadata`, `sf data query` de contagens/permissões — nenhum dado pessoal) e
leitura do `force-app/` já retrieved. **Nada foi escrito na org e nada foi criado em `force-app/`.**

---

## 0. Resumo executivo — as 8 decisões

| # | Ponto aberto na análise | Decisão |
|---|---|---|
| 1 | Tipo de campo | **Long Text Area** (não Text, não Rich Text) — §3.1 |
| 2 | Nome/label | **`Descobertas_da_Reuniao__c`** · label **"Descobertas da Reunião"** — §3.2 |
| 3 | Campo novo vs. reaproveitar | **Campo novo.** Não reaproveita `Need_Contexto__c` nem `Description` — §2 |
| 4 | Tamanho / obrigatoriedade | **32.768 caracteres**, `visibleLines` 5, **não obrigatório** (nem no campo, nem no layout) — §3.3 |
| 5 | Onde aparece | Seção **"Informações de classificação"** do `Lead Layout`. **FlexiPage não é alterada** — §4 |
| 6 | FLS | Read+Edit para os **6 perfis humanos com Edit em Lead**; nenhum perfil de integração — §5 |
| 7 | Conversão Lead→Account/Contact/Opportunity | **Não mapeia nesta demanda.** Mapear exige campo novo em outro objeto = mudança de modelo de dados → **escalado ao humano** — §6 |
| 8 | Riscos residuais do recon | Nenhum Flow ativo, nenhuma Validation Rule ativa e nenhuma automação em conflito. Riscos remanescentes são de FLS e de PII em texto livre — §8 |

**Nenhuma pendência bloqueia o build.** As 3 perguntas de §10 são confirmações de preferência,
não impedimentos — se o humano aprovar sem responder, o build segue com o desenhado aqui.

---

## 1. Decisão: declarativo vs. código

**Configuração nativa — nível 1 da ordem de preferência da plataforma. Sem Flow, sem Apex, sem LWC.**

Aqui **não há ambiguidade real a resolver**: a demanda é a criação de um `CustomField` em um
sObject padrão, mais a inclusão dele num page layout e a concessão de FLS. Não existe regra de
negócio, cálculo, condição, integração ou efeito colateral. Registro a justificativa por
disciplina, não porque a escolha estivesse em disputa:

| Nível | Cabe? | Justificativa |
|---|---|---|
| 1 — Configuração nativa | **Sim** | `CustomField` + `Layout` + `fieldPermissions` atendem integralmente os dois cenários Gherkin de `01-analise.md`. |
| 2 — Flow | Não | Não há nada a automatizar: ninguém calcula, deriva ou propaga o valor. Um Flow só entraria em cena se o item §6 (mapeamento na conversão) fosse aprovado — e, mesmo assim, só depois de uma decisão de modelo de dados que não é minha. |
| 3 — Apex/LWC | Não | Nenhum gatilho de código presente: sem callout, sem transação complexa, sem volume, sem lógica que exija teste unitário. Código aqui seria custo de manutenção puro. |

**Não há conflito de ordem de execução a sinalizar.** Um campo não dispara automação nenhuma;
esta demanda não adiciona nem altera nenhum ponto de automação no Lead.

---

## 2. Campo novo, e não reaproveitamento — a decisão que o recon pediu explicitamente

O `02-recon.md` levantou (corretamente) a sobreposição de propósito com o bloco BANT já
existente e pediu decisão registrada. **Decisão: criar campo novo.** Avaliei os dois candidatos
a reaproveitamento:

### 2.1 `Need_Contexto__c` — rejeitado

Confirmado no describe e no `force-app`:

```xml
<label>Need / Contexto</label>  <length>200</length>  <type>Text</type>
```

- É **Text(200), uma linha**. "Descobertas de reunião" é texto corrido, potencialmente com
  várias frases — 200 caracteres é uma restrição que o usuário vai contornar escrevendo mal.
- Reaproveitar exigiria **converter o tipo Text → Long Text Area**. Conversão de tipo em campo
  já em uso é operação com efeito em dados existentes; a sandbox de dev tem **0 Leads**
  (confirmado), mas produção **não foi inspecionada e não pode ser** (guardrail #1 e #2). Assumir
  que a conversão é inofensiva seria assumir o estado de uma org que não vi.
- Semanticamente, `Need_Contexto__c` é o "N" de um conjunto BANT (`Budget__c`, `Authority__c`,
  `Need_Contexto__c`, `Timeline__c`) que vive junto na seção "Informações de classificação".
  Transformá-lo num campo de notas livres **destrói a leitura BANT** para quem já usa os quatro
  campos como bloco.
- A demanda pede um campo; o custo de um campo novo é praticamente zero. Não há economia real
  em reaproveitar.

### 2.2 Standard `Lead.Description` — rejeitado

Confirmado no describe: `Description` existe, é `textarea plaintextarea` de **32.000 caracteres**,
e já está no layout, sozinho na seção "Description Information".

- É um campo **genérico e de escrita compartilhada**: qualquer ponto de entrada (import,
  Web-to-Lead, integração) pode gravar nele. Misturar descobertas curadas de reunião com
  conteúdo de outra origem torna impossível isolar/relatar o dado que a demanda quer.
- **Incerteza declarada:** *não confirmei* quais integrações escrevem em `Description` hoje —
  a sandbox tem 0 Leads e inspecionar dado de produção é proibido. A rejeição se apoia na
  natureza do campo, não numa contagem que eu não tenho.
- Um campo dedicado é reportável e auditável por si; `Description` não é.

---

## 3. Especificação do campo

### 3.1 Tipo: **Long Text Area**

| Tipo | Veredito | Por quê |
|---|---|---|
| `Text` (máx. 255) | Rejeitado | Notas de reunião estouram 255 caracteres com facilidade. Truncar informação de descoberta é perder exatamente o que a demanda quer guardar. |
| `TextArea` (255, multilinha) | Rejeitado | Mesmo teto de 255. Ganha quebra de linha e nada mais. |
| **`LongTextArea`** | **Escolhido** | Multilinha, até 131.072 caracteres, armazenamento fora da linha do registro (não consome o limite de 8 KB por registro), e é exatamente o que a org já usa para texto corrido de negócio — `Opportunity.Escopo_de_Projeto__c` é `LongTextArea(32768)`, confirmado no `force-app`. |
| `RichTextArea` | Rejeitado | Nenhum requisito de formatação foi levantado. Rich Text grava HTML, que suja export/relatório/integração, e imagens coladas consomem armazenamento de arquivo. Custo sem benefício declarado. |

**Limitações do Long Text Area que aceito conscientemente** (e que o humano precisa saber antes
de aprovar): não é filtrável em list view, não pode ser critério de filtro de relatório, não
entra em fórmula nem em roll-up, e o histórico de campo, se ligado, registra que mudou mas não
guarda o valor anterior. Nada disso foi pedido pela demanda. **Se o negócio quiser filtrar ou
segmentar por descoberta, o tipo está errado e a demanda precisa voltar para a análise** — é o
único cenário que reabriria esta decisão.

### 3.2 Nome de API e label

| | Valor |
|---|---|
| **API name** | `Descobertas_da_Reuniao__c` |
| **Label** | `Descobertas da Reunião` |

Justificativa da forma:

- **Sem prefixo de origem**, conforme o `CLAUDE.md` deste cliente (decidido em ACXYA-1).
- **Português, `Palavra_Palavra__c`, conectivos em minúscula** — é o padrão observado nos campos
  custom existentes do Lead: `Numero_de_Funcionarios__c`, `Data_Aniversario__c`,
  `Possui_Fluxo_de_Atendimento__c`, `Ferramenta_que_utilizam_hoje__c`.
- **Sem acento no API name** (restrição da plataforma), **com acento no label** — mesmo padrão de
  `Data_Aniversario__c` / "Data de Aniversário".
- **Plural "Descobertas"**, e não o `Nova_Descoberta__c` cogitado na análise: o campo é um
  repositório acumulado de achados, não o registro de um evento único. `Nova_...` envelhece mal
  (na segunda reunião a "nova" descoberta já não é nova).
- **`_da_Reuniao`** é o qualificador que separa este campo de qualquer outro tipo de descoberta
  e amarra o campo ao caso de uso da demanda.
- **Confirmado:** nenhum campo padrão ou custom do Lead usa "Descoberta", "Discovery", "Insight",
  "Meeting" ou "Reunião" — sem colisão de nome nem de label (recon §1).

### 3.3 Tamanho, obrigatoriedade e metadata proposta

- **Tamanho: 32.768 caracteres.** Espelha o precedente da própria org
  (`Opportunity.Escopo_de_Projeto__c`, `LongTextArea(32768)`). É ~16x o necessário para notas de
  reunião; subir para o máximo de 131.072 não compraria nada e divergiria do padrão local.
- **`visibleLines`: 5.** Maior que os 3 do precedente porque aqui o texto é o conteúdo principal
  do campo, não um complemento — o usuário precisa ver o que já escreveu sem rolar.
- **Obrigatoriedade: NÃO obrigatório**, em nenhum dos dois níveis:
  - *Nível de campo:* a plataforma **não permite** marcar Long Text Area como obrigatório. Não é
    escolha, é limite — e é mais um argumento a favor deste tipo: obrigar notas de reunião em um
    objeto que recebe lead de marketing seria errado de qualquer forma.
  - *Nível de layout:* também não. O Lead desta org é alimentado por automação de marketing
    (Flow `Leads_do_Marketing_Cloud` ativo, confirmado no recon) e por entrada externa. Um campo
    obrigatório no layout quebraria a criação de Lead que nunca teve reunião. O layout já usa
    `behavior: Required` em `Budget__c`; **não repetimos o padrão aqui**, de propósito.
- **`trackHistory` / `trackFeedHistory`: false** — consistente com `Data_Aniversario__c` (ACXYA-1)
  e com `Escopo_de_Projeto__c`. Além disso, histórico em Long Text Area não guarda o valor
  anterior, então ligaria custo sem entregar rastro útil.

Metadata alvo (referência para o `04-plano-build.md`; **este arquivo ainda não existe no
repositório** — criá-lo é trabalho da etapa 4):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Descobertas_da_Reuniao__c</fullName>
    <description>ACXYA-2 — Descobertas e insights coletados em reunião com o potencial cliente.</description>
    <externalId>false</externalId>
    <label>Descobertas da Reunião</label>
    <length>32768</length>
    <trackFeedHistory>false</trackFeedHistory>
    <trackHistory>false</trackHistory>
    <type>LongTextArea</type>
    <visibleLines>5</visibleLines>
</CustomField>
```

---

## 4. Onde o campo aparece

### 4.1 Page Layout — `Lead-Lead Layout`, seção "Informações de classificação"

O `Lead Layout` é o **único layout ativo** do Lead (recon confirmado). Retrieve local confirma
as seções e seu conteúdo. Decisão: **último item da seção "Informações de classificação"**,
com `<behavior>Edit</behavior>`.

| Seção candidata | Conteúdo atual (confirmado no retrieve) | Veredito |
|---|---|---|
| **Informações de classificação** | `Authority__c`, `Cargo__c`, `Need_Contexto__c`, `Possui_Fluxo_de_Atendimento__c`, `Volume_de_Dados__c`, `Ferramenta_que_utilizam_hoje__c`, `Budget__c`, `Canais_de_Atendimento__c`, `Numero_de_Agentes__c`, `Timeline__c`, `Qualified_Lead__c` | **Escolhida.** É onde já mora tudo que o vendedor preenche *depois de falar com o lead*. A descoberta é lida junto com o BANT, não separada dele. |
| Description Information | só o `Description` padrão | Rejeitada. Agruparia o campo novo com o campo genérico do qual acabamos de separá-lo (§2.2) — sinal errado para o usuário. |
| Additional Information | `NumberOfEmployees`, `AnnualRevenue`, `LeadSource`, `Industry` | Rejeitada. É firmográfico/origem, não conteúdo de reunião. |

Por ser um campo de texto alto, o lugar natural é o **fim** da seção, abaixo dos campos curtos —
inserir no meio empurraria o pareamento de colunas e deixaria um buraco visual ao lado.

### 4.2 Lightning Record Page — **nenhuma alteração**

Confirmado lendo `flexipages/Lead_P_gina_de_registro.flexipage-meta.xml`: a página usa
`force:detailPanel` e tem **zero elementos `<fieldItem>`** — ou seja, ela renderiza os campos do
page layout atribuído, não uma lista própria de campos.

**Consequência: adicionar o campo ao `Lead Layout` é suficiente para ele aparecer na record page.**
O builder **não deve** tocar na FlexiPage — alterá-la sem necessidade é risco gratuito num
componente compartilhado por toda a org.

---

## 5. FLS / visibilidade por perfil

### 5.1 O que está confirmado na org (não presumido)

`SELECT Parent.Profile.Name, PermissionsEdit FROM ObjectPermissions WHERE SobjectType='Lead'` —
**11 perfis leem Lead, 7 editam.** Dos que editam, 6 são perfis operados por humano e 1 é de
integração (`Sales Insights Integration User`). O perfil próprio do cliente
**`Atendimento Konecta Perfil` não tem sequer leitura em Lead** — logo não é candidato a FLS aqui.

### 5.2 Decisão

**Read + Edit para os 6 perfis humanos com Edit em Lead. Nenhum perfil de integração, nenhum
perfil somente-leitura, nenhum Permission Set novo.**

| API name (metadata) | Label pt-BR na org | Concessão |
|---|---|---|
| `Admin` | Administrador do sistema | Read + Edit |
| `System Administrator %28non-API user%29` | System Administrator (non-API user) | Read + Edit |
| `Standard` | Usuário Padrão | Read + Edit |
| `MarketingProfile` | Usuário do Marketing | Read + Edit |
| `SolutionManager` | Gerente de soluções | Read + Edit |
| `ContractManager` | Gerente do contrato | Read + Edit |

Justificativa:

- **Quem preenche é quem participa da reunião.** O critério "perfil edita Lead e é operado por
  gente" cobre exatamente esse público, sem precisar descobrir organograma.
- **Integração fica de fora de propósito.** Campo de texto livre é o vetor clássico de PII não
  estruturada (o usuário digita nome, telefone ou situação pessoal do contato sem que ninguém
  tenha pedido). Não há razão declarada para `Sales Insights Integration User` ler notas de
  reunião — e conceder depois é trivial; revogar depois de o dado ter trafegado, não.
- **Delta consciente em relação a ACXYA-1.** Lá o humano aprovou um conjunto de **4** perfis
  (Admin, SysAdmin non-API, Standard, Marketing) para `Data_Aniversario__c`. Aqui incluo também
  `SolutionManager` e `ContractManager` porque este campo é insumo de gestão comercial: gerente
  que não enxerga a descoberta não consegue revisar a qualificação. **Se o humano preferir
  consistência estrita com ACXYA-1, cortar esses 2 é aceitável** — é ajuste de uma linha por
  perfil, sem impacto no resto do desenho (pergunta Q1 em §10).
- **Não crio Permission Set dedicado.** Nenhum campo do Lead nesta org usa esse modelo hoje;
  introduzir o padrão numa demanda de sustentação P é escopo além da demanda (§9).

### 5.3 Armadilha confirmada, que o `04-plano-build.md` precisa herdar

Os arquivos de `Profile` em `force-app/main/default/profiles/` **não são fonte de verdade de FLS**:
verifiquei que nenhum deles carrega `objectPermissions` de Lead, e os únicos `fieldPermissions`
presentes são os 4 deltas que ACXYA-1 deixou para `Data_Aniversario__c`. O caminho correto é
entregar **arquivos de perfil delta**, contendo apenas o bloco `fieldPermissions` do campo novo —
deploy de Profile pela Metadata API é aditivo para os membros incluídos no pacote.

> **Sem FLS explícita, o campo não aparece para ninguém.** É o modo de falha mais comum desta
> entrega: "o deploy passou, mas o campo sumiu". Verificação de FLS por perfil é item obrigatório
> do roteiro de QA (etapa 5).

**Incerteza declarada:** o mapeamento label pt-BR → API name acima é inferência a partir do
conjunto padrão de perfis do Salesforce, cruzada com os `fullName` retornados por
`sf org list metadata --metadata-type Profile` (os 25 nomes batem). **Não confirmei par a par.**
O builder deve confirmar cada par antes de escrever os deltas — mesma cautela registrada em
ACXYA-1 §4.

---

## 6. Conversão de Lead → Account / Contact / Opportunity

**Decisão: o campo NÃO é mapeado na conversão nesta demanda.** O dado permanece legível no Lead
convertido, que não é apagado.

Por quê — e por que a alternativa é decisão do humano, não minha:

1. **Limite da plataforma, já provado nesta org.** ACXYA-1 confirmou empiricamente (com a
   mensagem literal de erro da Metadata API, registrada em `ACXYA-1/03-design.md` §2) que
   `LeadConvertSettings` só aceita mapeamento **custom → custom**. Mapear para um campo padrão
   está fora de questão.
2. **Não existe campo custom de destino compatível.** Confirmei por describe:
   - **Account** — 20 campos custom, **nenhum** do tipo textarea.
   - **Contact** — 7 custom; os únicos textarea são `Tier__c` e `Safra__c`, ambos Text Area(255)
     e de propósito completamente diferente.
   - **Opportunity** — tem `Escopo_de_Projeto__c`, `LongTextArea(32768)`. É o único tecnicamente
     plausível — e **mapear nele seria um erro**: escopo de projeto é conteúdo contratual curado,
     e sobrescrevê-lo a cada conversão com notas de reunião corromperia um campo em uso.
3. **Portanto, mapear exige criar campo novo em outro objeto.** Isso é **mudança de modelo de
   dados fora do objeto da demanda** e, por regra deste squad, é decisão de arquitetura sênior:
   **escalo ao humano, não decido sozinho.** Não está no escopo aprovado em `01-analise.md`,
   que listou a jornada pós-conversão como pendência em aberto — e a resposta honesta a uma
   pendência não respondida é não inventá-la.
4. **Se o humano quiser o mapeamento**, o caminho já tem precedente nesta org: o Flow
   `Lead_AfterSave_MapeiaAniversarioNaConversao` (ativo, `RecordAfterSave`, criado em ACXYA-1)
   faz exatamente isso para o aniversário. Mas isso vira **demanda separada**, porque: (a) exige
   o campo de destino primeiro; (b) sobe a solução para o nível 2 da doutrina (Flow); e (c) se
   o destino for custom→custom, ainda é preciso validar com `deploy validate` (check-only) se
   `LeadConvertSettings` aceita par **LongTextArea → LongTextArea** — ACXYA-1 só provou que
   custom→**padrão** falha; o caso LTA→LTA **não está confirmado nesta org** e eu não o confirmei.

---

## 7. Componentes — criar / alterar / depreciar

| Ação | Tipo | API name | Observação |
|---|---|---|---|
| **Criar** | `CustomField` | `Lead.Descobertas_da_Reuniao__c` | §3.3 |
| **Alterar** | `Layout` | `Lead-Lead Layout` | 1 `layoutItems` no fim da seção "Informações de classificação" (§4.1) |
| **Alterar** | `Profile` (deltas de `fieldPermissions`) | `Admin`, `System Administrator %28non-API user%29`, `Standard`, `MarketingProfile`, `SolutionManager`, `ContractManager` | §5.2 e §5.3 |
| **Não tocar** | `FlexiPage` | `Lead_P_gina_de_registro` | Usa `force:detailPanel`; herda do layout (§4.2) |
| **Depreciar** | — | nenhum | Nada é removido ou desativado por esta demanda |

Branch: `feature/ACXYA-2` (já existe). Build em `sbx-acxya-dev`. **`sbx-acxya-qa` ainda não
existe** — a demanda vai parar na etapa 5 até que exista, e isso é o comportamento correto
(registrado no `CLAUDE.md` do cliente); não force o alias de dev para "destravar".

---

## 8. Riscos

| # | Risco | Sev. | Tratamento |
|---|---|---|---|
| R1 | **Campo invisível após deploy por falta de FLS.** Metadata API não concede visibilidade automaticamente. | **Alta** (probabilidade alta, impacto total: a entrega parece ok e não é) | Deltas de perfil no mesmo pacote (§5.3) + verificação por perfil obrigatória no roteiro de QA. |
| R2 | **Mapeamento label→API name de perfil errado**, concedendo FLS ao perfil errado ou a nenhum. | Média | Builder confirma cada par contra a org antes de escrever o delta (§5.3). |
| R3 | **PII não estruturada em texto livre** — usuário digita dado pessoal/sensível do contato nas notas. LGPD. | Média | Mitigado por design: FLS restrita a 6 perfis humanos, sem integração (§5.2), e `description` do campo declara a finalidade. Não há como impedir tecnicamente o que o usuário digita; o controle é de acesso e de finalidade. |
| R4 | **Tipo escolhido impede filtrar/segmentar** por conteúdo da descoberta (limitação do Long Text Area). | Baixa | Nenhum requisito de filtro foi levantado. Se aparecer, o desenho muda e a demanda volta à análise (§3.1). |
| R5 | **Sobreposição percebida com o bloco BANT** — usuário não saber se escreve em `Need_Contexto__c` ou no campo novo. | Baixa | Label explícito ("Descobertas da Reunião") + posição no fim da mesma seção + `description` do campo. Adoção é assunto da documentação de entrega (etapa 7). |
| R6 | Flow ativo afetado | **Nenhum** | Os 4 Flows ativos em Lead (`Count_de_Tasks_Pendentes`, `Lead_AfterSave_MapeiaAniversarioNaConversao`, `Leads_do_Marketing_Cloud`, `Update_Atividades_Pendentes`) operam sobre tarefas, aniversário e Marketing Cloud. Um campo novo e isolado não entra no caminho de nenhum, e esta demanda **não cria nem altera automação** — não há disputa de ordem de execução a sinalizar. |
| R7 | Validation Rule em conflito | **Nenhum** | Única VR ativa é `Valida_Data_Aniversario_Nao_Futura`, sobre `Data_Aniversario__c`. Sem interseção. |
| R8 | Conflito de nome | **Nenhum** | Describe confirma: nenhum campo padrão ou custom do Lead com nome ou label parecido. |

---

## 9. O que **NÃO** será feito nesta demanda

- **Não** haverá mapeamento do campo na conversão de Lead, nem campo correspondente em Account,
  Contact ou Opportunity (§6 — escalado).
- **Não** haverá Flow, Apex, LWC, Validation Rule, Quick Action nem obrigatoriedade de qualquer
  natureza.
- **Não** haverá migração/backfill de Leads históricos: o campo nasce vazio. A pendência
  "dados históricos" de `01-analise.md` fica **respondida como fora de escopo** — não há origem
  de onde extrair descobertas de reuniões passadas.
- **Não** haverá alteração na `FlexiPage` `Lead_P_gina_de_registro` (§4.2).
- **Não** haverá alteração em `Need_Contexto__c` nem em `Description` — ambos ficam exatamente
  como estão (§2).
- **Não** haverá Permission Set novo nem mudança do modelo de permissionamento da org (§5.2).
- **Não** haverá exposição a integração (Marketing Cloud, WhatsApp, Slack, Anypoint) — nenhum
  perfil de integração recebe FLS.
- **Não** haverá deploy em produção por agente, em nenhuma etapa. Build em `sbx-acxya-dev`;
  a partir da etapa 5, `sbx-acxya-qa`, que **ainda não existe**.

---

## 10. Perguntas ao arquiteto humano (não bloqueiam o build)

| # | Pergunta | Default se não houver resposta |
|---|---|---|
| Q1 | FLS: 6 perfis (§5.2) ou os mesmos 4 de ACXYA-1, cortando `SolutionManager` e `ContractManager`? | Segue com **6**. |
| Q2 | O label "Descobertas da Reunião" é o vocabulário que o time comercial usa, ou existe termo interno preferido? | Segue com **"Descobertas da Reunião"**. |
| Q3 | Confirma que a descoberta **não** precisa viajar para a Opportunity na conversão (§6)? Se precisar, isso vira demanda separada com decisão de modelo de dados. | Segue **sem mapeamento**. |

---

## 11. Rastro de confirmação

Tudo que este design afirma sobre a org foi confirmado nesta sessão, contra `sbx-acxya-dev`, ou
lido do `force-app/` já retrieved no repositório:

- `sf org list` → org única, `isSandbox: true`, alias `sbx-acxya-dev`.
- `sf sobject describe --sobject Lead|Contact|Account|Opportunity` → tipos, tamanhos e labels de
  `Need_Contexto__c` (Text 200), `Description` (textarea 32000), `Escopo_de_Projeto__c`
  (LongTextArea 32768), `Tier__c`/`Safra__c` (textarea 255), contagens de campos custom.
- `force-app/main/default/layouts/Lead-Lead Layout.layout-meta.xml` → seções e campos por seção.
- `force-app/main/default/flexipages/Lead_P_gina_de_registro.flexipage-meta.xml` →
  `force:detailPanel`, zero `<fieldItem>`.
- `force-app/main/default/flows/Lead_AfterSave_MapeiaAniversarioNaConversao.flow-meta.xml` →
  precedente de mapeamento na conversão via Flow e a razão registrada (custom→custom).
- `SELECT ... FROM ObjectPermissions WHERE SobjectType='Lead'` e
  `FROM FieldPermissions WHERE Field='Lead.Need_Contexto__c'` → perfis com Read/Edit.
  **Só metadata de permissão e contagens agregadas; nenhum dado de cliente entrou no contexto
  (guardrail #2).**
- `sf org list metadata --metadata-type Profile` → os 25 `fullName` de perfil da org.

**O que NÃO foi confirmado, e está declarado como incerteza no corpo do documento:** o
mapeamento par a par label→API name dos perfis (§5.3), quais integrações escrevem em
`Lead.Description` hoje (§2.2), e se `LeadConvertSettings` aceita par LongTextArea→LongTextArea
nesta org (§6).

---

**Design pronto. Gate bloqueante — aguardando aceite do arquiteto humano.**
