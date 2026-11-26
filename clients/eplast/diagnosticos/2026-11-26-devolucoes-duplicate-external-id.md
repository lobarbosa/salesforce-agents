# Devoluções do Protheus recusadas com DUPLICATE_EXTERNAL_ID

**Data:** 2026-11-26 · **Org analisada:** metadata do repositório (`clients/eplast/force-app`); dados da `sbx-eplast-qa` pendentes do diagnóstico (abaixo) · **Origem:** proposta "Konecta + Eplast" (16 h, R$ 4.160)

## Resumo

A integração de devoluções grava `SalesReturn__c` apontando a conta pelo `Account.ProtheusId__c`.
Esse campo é chave externa, mas **não é único**, e guarda só o **código** do cliente no
Protheus. No Protheus o cliente é **código + loja**: lojas diferentes do mesmo cliente
compartilham o código. Quando mais de uma conta tem o código enviado, a plataforma não sabe
qual usar e recusa o registro (`DUPLICATE_EXTERNAL_ID`, HTTP 400).

A proposta trata o caso como duplicidade de cadastro e corrige apagando o código de uma das
contas. **Se as contas forem lojas diferentes, isso quebra a loja que perder o código**: os
pedidos dela deixam de ir ao ERP. A correção certa depende de uma resposta que só os dados
dão, e o diagnóstico abaixo a obtém sem expor dado de cliente.

## O que a metadata mostra

| Fato | Onde |
| --- | --- |
| `Account.ProtheusId__c`: texto 255, chave externa, **não único** | `objects/Account/fields/ProtheusId__c` |
| A integração grava o código em `ProtheusId__c` e a **loja em `Account.Store__c`** (texto 3) | `UpdateAccountWithProtheusInfo.cls`, linhas 15 e 16 |
| Pedidos vão ao ERP com `cliVen` = `ProtheusId__c` e `LojaVen` = `Store__c` | `OrderAdapter.cls`, linhas 15 e 16 |
| `SalesReturn__c` tem a loja (`Store__c`, texto 2) separada da conta (`AccountId__c`) | `objects/SalesReturn__c/fields` |
| `SalesReturn__c.ClientCode__c` é fórmula de `AccountId__r.ProtheusId__c` | idem |
| Há um segundo campo "Loja" na conta, `Loja__c` (texto 50), que nenhum código usa | `objects/Account/fields/Loja__c` |

Ou seja: o modelo de dados já distingue lojas na conta e na devolução, mas a chave que liga
uma à outra ignora a loja.

### O que um registro de devolução mostra (tela enviada em 2026-11-26)

Uma devolução gravada com sucesso pela "Integração Protheus" (sem transcrever dado do
cliente): ela tem **três vínculos**, conta, filial e pedido, além da loja (`01`) em campo
próprio, e o `ProtheusId__c` da devolução é o número do documento no ERP (prefixo +
número), repetido em cada item. Daí:

| Achado | Consequência |
| --- | --- |
| A devolução procura também a **filial** por `Branch__c.CodeERP__c`, chave externa **não única** (texto 4) | `DUPLICATE_EXTERNAL_ID` pode vir da filial, não só da conta. A mensagem de erro do Salesforce diz o objeto e o campo: conferir no `Devolucao_badrequest.json` ou na resposta da API antes de sanear conta |
| O **pedido** também é procurado; os campos de `Order` não estão na linha de base do repositório | A chave do pedido não foi conferida; o diagnóstico na org cobre conta e filial |
| `SalesReturn__c.ProtheusId__c` **não é chave externa**, e a integração usa POST | Reenviar uma devolução que já entrou cria outra igual. O reprocessamento da proposta (Fase 3) pode duplicar devoluções. A chave de uma linha de devolução é número do documento + item |
| `Account.CompanyDocument__c` (CNPJ) também é chave externa, não única | Alternativa de chave por loja que já existe, sem campo novo, se o CNPJ estiver limpo |
| O nome da conta segue o padrão `<código> - <razão social>` | O código aparece no nome; não serve de chave, mas ajuda a conferir |

## O que falta confirmar nos dados (diagnóstico)

Workflow **Diagnóstico de chave externa repetida** (`diagnostico-chave-externa.yml`), só
leitura e só contagens, com `client=eplast`, `ambiente=qa`, `codigo=000922` e
`ids=001bJ000005fzsXQAA,001bJ000005eYOqQAM`. Ele responde:

1. Quantas contas têm `ProtheusId__c` e quantos códigos se repetem.
2. Dos códigos repetidos, quantos são **lojas diferentes** (cadastro legítimo), quantos são
   **mesmo código e mesma loja** (duplicata de verdade) e quantos têm conta **sem loja**.
3. Para o 000922 e os dois Ids da proposta: a loja de cada conta e quantos pedidos,
   oportunidades, devoluções e contas filhas cada uma tem.
4. Quantas devoluções existem e quantas estão sem conta.
5. Se a filial (`Branch__c.CodeERP__c`) e o CNPJ da conta também repetem, e se já há
   devolução gravada duas vezes (mesmo número e item).

A `sbx-eplast-qa` é a QAS da Eplast, **Partial Copy**: tem uma amostra da produção, copiada
numa data passada. O diagnóstico mostra a natureza do problema (lojas diferentes ou
duplicata), não o número de hoje em produção, e os dois Ids da proposta podem não estar na
amostra. O número de produção quem levanta é o consultor, com o mesmo critério. Como a QAS
tem dado real, o diagnóstico lê só contagens e, por conta, apenas Id, loja e quantidades
(nada de nome, documento, contato ou valor) e não grava nada.

## Solução recomendada

### 1. Chave composta código + loja na conta

- Campo novo `Account.ProtheusKey__c` (texto 20, chave externa, **único**, sem diferenciar
  maiúsculas) = `ProtheusId__c` + `-` + `Store__c` com 2 dígitos (ex.: `000922-01`).
- Preenchido por um Flow antes de salvar, quando `ProtheusId__c` ou `Store__c` mudam. Fórmula
  não serve: campo fórmula não pode ser chave externa.
- Carga inicial nas contas que já têm código, em lotes, **com o desvio oficial da
  `AccountTrigger`** (`TriggerUtility.bypassTrigger`): sem ele, cada conta atualizada vai ao
  Protheus e lotes acima de 50 falham (achado EPLAST-47).
- Enquanto existir duplicata de verdade, o campo não aceita o valor repetido: a carga lista as
  contas recusadas, e elas são o insumo do passo 3.

### 2. Devoluções passam a usar a chave composta

- O Protheus envia a conta da devolução como `AccountId__r: { ProtheusKey__c: "000922-01" }`.
  É mudança no lado do ERP (Eplast ou consultoria Protheus).
- Se o ERP não puder mudar agora: o Protheus envia código e loja em campos de texto da
  devolução, e um Flow antes de salvar em `SalesReturn__c` resolve `AccountId__c` pela chave
  composta. Precisa do JSON real (`Devolucao_badrequest.json`) para saber quais campos ele
  já manda.
- O mesmo vale, por prevenção, para qualquer outra integração que procure conta só pelo
  código.

### 3. Saneamento só das duplicatas de verdade

- Contas com **mesmo código e mesma loja**: mesclar (merge de conta preserva pedidos,
  oportunidades e devoluções na conta que fica), escolhendo a que fica com a área de negócio
  da Eplast. Não apagar o código de uma conta que tem pedidos.
- Contas com **lojas diferentes**: nada a sanear; a chave composta resolve.
- Contas **sem loja**: preencher `Store__c` a partir do Protheus antes da carga do passo 1.
- `Loja__c` (sem uso): propor desuso, depois de confirmar com a Eplast que nada externo o lê.

### 4. Reprocessamento sem duplicar devolução

- Chave externa nova e única em `SalesReturn__c` = número do documento + item (ex.:
  `ProtheusId__c` + `-` + `Item__c`), e a integração passa de POST para upsert por ela. Assim
  reenviar a mesma devolução atualiza em vez de criar outra.
- Antes de reprocessar, conferir quais devoluções da janela do erro já entraram (o
  diagnóstico conta as que já estão repetidas).
- Se a filial também repete `CodeERP__c`, o mesmo tratamento do passo 1 vale para
  `Branch__c` (uma filial por código, ou chave composta).

### 5. Contingência para as devoluções paradas

Enquanto 1 e 2 não estão no ar, as devoluções recusadas podem ser reprocessadas com o Id
Salesforce da conta (`AccountId__c` direto), escolhido pela loja que veio na devolução.

## Impacto na proposta enviada

- A Fase 2 ("o registro incorreto terá seu ID Externo removido") só vale para duplicata de
  verdade. Para lojas diferentes ela quebra a integração de pedidos da loja afetada.
- A Fase 3 (reprocessar por POST) pode criar devolução repetida para o que já entrou: a
  devolução não tem chave externa. Reprocessar só depois do upsert, ou só o que comprovadamente
  não entrou.
- A Fase 1 olha só a conta; o erro pode vir da filial (`CodeERP__c` também não é único).
- O escopo cresce: campo, Flow e carga da chave composta, mais a mudança no ERP ou o Flow da
  devolução. Estimativa a refazer depois do diagnóstico (skill `estimar-esforco`).
- A premissa "o erro está restrito a duplicidade de dados" precisa virar "o erro vem da chave
  de integração não considerar a loja", se o diagnóstico confirmar lojas diferentes.

## Como entra na esteira

Como demanda de sustentação da Eplast: análise com a classe "defeito" e o diagnóstico como
evidência (skill `triagem-sustentacao`), design com a chave composta (skills
`modelo-de-dados-e-acesso`, `integracao`, `carga-e-migracao`), build e QA como qualquer
outra. A carga e o merge em produção são do consultor, fora da esteira.
