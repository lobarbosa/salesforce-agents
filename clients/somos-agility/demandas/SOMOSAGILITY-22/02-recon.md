# Recon da Org — SOMOSAGILITY-22

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0, `isSandbox: true`
confirmado via `sf org list`). É a única org conectada nesta máquina.
**Data da coleta:** 2026-10-21.
**Cobertura:** apenas metadata, retrieve de componentes declarativos e `COUNT()` agregado
(guardrail #2) — nenhuma consulta trouxe dado de registro real (nome, valor, data de pessoa
ou fornecedor).

## 1. Objeto e campo confirmados

- Objeto: **`JOB_de_Solicita_o_de_Investimento__c`** (label "JOB de Solicitação de
  Investimento") — confirmado via `sf sobject list` e `sf sobject describe`.
- Campo de qualificação: **`Status_da_Qualificaco__c`** (label "Status da Qualificação"),
  picklist **não obrigatório** (`required: false`), com histórico de campo ativado
  (`trackHistory: true`). Valores cadastrados, confirmados via describe e via o
  `.field-meta.xml` recuperado:

  | Valor | Default |
  |---|---|
  | Não Enviado | sim |
  | Pendente | não |
  | Aprovado | não |
  | Rejeitado | não |
  | Recall | não |

  Isto responde **Q1 da análise**: a lista completa de status é a acima — 5 valores, não 3
  como a leitura do anexo sugeria (o anexo mostrava só "Não Enviado", "Pendente" e "Aprovado",
  mas isso é o que aparecia na captura, não a lista completa do campo).

  Há um objeto homônimo em outro processo (`JOB_de_Solicitacao_de_Treinamentos__c`, Job de
  Solicitação de **Treinamento**) com um campo de mesmo propósito
  (`Status_da_Qualifica_o__c`, nome de API ligeiramente diferente). É um processo diferente,
  usado em outro componente do mesmo Dashboard (seção 3) — não confundir os dois ao desenhar
  a correção.

## 2. Relatório confirmado — o filtro de picklist NÃO está incompleto

Relatório da demanda (`00OU400000XSSudMAH`) = **`Financeiro/JOBs_de_Investimento_HsY`**
("JOBs de Investimento", pasta "Financeiro"). Metadata recuperado via
`sf project retrieve start --metadata "Report:Financeiro/JOBs_de_Investimento_HsY"`.

Achados do `.report-meta.xml`:

- **Formato:** Summary, agrupado por `Status_da_Qualificaco__c` (`groupingsDown`), com
  gráfico de rosca (`chart`) cujo `groupingColumn` é o mesmo campo. Consistente entre si.
- **Filtro de qualificação** (`filter > criteriaItems`):
  ```
  column:   JOB_de_Solicita_o_de_Investimento__c.Status_da_Qualificaco__c
  operator: equals
  value:    ,Não Enviado,Pendente,Aprovado,Rejeitado,Recall
  ```
  A vírgula inicial antes de "Não Enviado" inclui o valor **em branco** como um dos valores
  aceitos (consistente com o campo não ser obrigatório). **Este filtro já contempla os 5
  valores do picklist mais o branco — nenhum valor está de fora.** Isso **refuta a hipótese
  H1** da análise ("o filtro não contempla todos os valores de status") pelo menos no nível
  do filtro de critério do relatório: não há valor de qualificação excluído aqui.
- **Filtro de período** (`timeFrameFilter`), que a análise anterior não tinha mapeado:
  ```
  dateColumn: JOB_de_Solicita_o_de_Investimento__c.Data__c
  interval:   INTERVAL_PREVCUR2FY   (2 anos fiscais anteriores + o atual)
  ```
  `Data__c` é um **campo fórmula** (`calculatedFormula: "CreatedDate"`, tipo `date`,
  `createable: false`, `updateable: false`) — confirmado via `sf sobject describe`. Ou seja,
  o relatório não filtra por uma data de negócio (data do evento, data de aprovação etc.):
  filtra pela **data de criação do registro**, numa janela rolante de ~3 anos fiscais.

  **Isto é a causa mais provável e confirmável do problema relatado.** Um Job criado fora
  dessa janela (por exemplo, um Job antigo que ficou "Pendente" ou "Não Enviado" sem nunca
  ser resolvido) **desaparece inteiramente do relatório e do gráfico** — não porque o status
  dele está no grupo errado, mas porque o registro inteiro é excluído pelo filtro de data
  antes de chegar ao agrupamento por status. Do ponto de vista de quem olha o painel, isso
  aparenta exatamente a queixa do card: "o filtro de qualificação não está puxando
  corretamente os status" — jobs pendentes/não enviados que deveriam aparecer no
  acompanhamento somem sem explicação aparente, porque a causa real não é o campo de
  qualificação, é o filtro de data por trás do relatório.

  Isto também responde parte de **Q3**: o filtro problemático (se esta hipótese se
  confirmar) é do **Relatório**, é de **configuração declarativa** (Report metadata), não
  exige Flow nem Apex.

## 3. Dashboard confirmado — não introduz filtro próprio

Dashboard da demanda (`01ZU4000000TSqXMAW`) = **"Controle Financeiro"**
(`ProjetosAtuais2024/sFQeqnPANgKWxQuaSnWRYtxzKhCxCL`), pasta "Projetos - Atuais 2024".
Metadata recuperado via `sf project retrieve start --metadata "Dashboard:..."`.

O componente relevante ("Job Solicitação de Investimento", gráfico de barras) está
configurado com `useReportChart: true` e `autoselectColumnsFromReport: true` — ou seja, ele
**herda diretamente** o gráfico e o filtro já definidos no Relatório (seção 2), sem filtro
próprio no nível do Dashboard. **Isto refuta a hipótese H3** quanto a "o problema está no
Dashboard e não no Relatório": se a causa é o `timeFrameFilter`, ela está no Relatório e se
propaga para o Dashboard por herança, não é um problema duplicado ou independente no
Dashboard.

Nota à parte (não é bug, é só para não confundir ao editar): o mesmo Dashboard tem outro
componente, "Job Solicitação de Treinamento - JST", que usa um relatório e objeto
diferentes (`Financeiro/Job_Solicitao_de_Treinamento_JST_1u9`,
`JOB_de_Solicitacao_de_Treinamentos__c`) — fora do escopo desta demanda.

## 4. O que não deu para confirmar nesta org

- **Contagens e janela real de dados:** a sandbox `sbx-somos-agility-dev` está **com 0
  registros** em `JOB_de_Solicita_o_de_Investimento__c` (`SELECT COUNT(Id)` = 0). Não há
  como, nesta org, confirmar quantos Jobs existem fora da janela `INTERVAL_PREVCUR2FY`, nem
  reproduzir os 281 registros / 3 grupos vistos no anexo. A validação quantitativa da
  hipótese do filtro de data (quantos Jobs pendentes/não enviados têm `CreatedDate` fora da
  janela) só é possível em QA ou com uma contagem agregada pedida à produção pelo próprio
  cliente (nunca por consulta direta do agente a produção — guardrail #1).
- **Mecanismo que define `Status_da_Qualificaco__c`:** o campo é um picklist simples (sem
  fórmula, sem rollup) — confirmado que **algo** o define (Flow, Processo de Aprovação ou
  atualização manual), mas não confirmei o quê: a tentativa de recuperar `ApprovalProcess`
  por nome específico falhou (exige o `fullName` exato, que eu não tinha) e a tentativa de
  recuperar todos os `ApprovalProcess` da org por wildcard não retornou dentro do tempo
  desta sessão. **Não é bloqueante para o design** se a causa for o `timeFrameFilter` (ajuste
  de configuração do Relatório não depende de saber quem escreve o status). Fica como
  pergunta em aberto caso o arquiteto ou o humano queira descartar H2 (campo errado sendo
  lido) com mais confiança.
- Não investidado: permission sets e layouts que referenciam o objeto (`jobsAprovacao` etc.)
  — não parecem relevantes para um problema de filtro de relatório, e não há indício em
  contrário no card.

## 5. Como isto se conecta com as perguntas da análise (01-analise.md)

| Pergunta | Resposta do recon |
|---|---|
| Q1 — lista de valores de qualificação | Confirmada: 5 valores (seção 1). |
| Q2 — um Job concreto em grupo errado | Não confirmável nesta org (0 registros) — ver seção 4. |
| Q3 — filtro é do Relatório, do Dashboard, ou ambos; config ou código | Relatório; herdado pelo Dashboard (seção 3); se a causa for o `timeFrameFilter`, é configuração declarativa (seção 2). |
| Q4 — regra de qualificação por campo, etapa ou status do job | Por campo simples (`Status_da_Qualificaco__c`), mas quem escreve nele não foi confirmado (seção 4). |
| H1 (filtro de picklist incompleto) | **Refutada** pela metadata do Relatório (seção 2). |
| H2 (campo errado sendo lido) | Não refutada nem confirmada — campo existe e é consistente entre Relatório/gráfico/Dashboard; falta confirmar quem o escreve. |
| H3 (problema é do Dashboard) | **Refutada** — Dashboard herda do Relatório, não tem filtro próprio (seção 3). |
| **H4 (nova, desta recon):** filtro de período (`timeFrameFilter` por `CreatedDate`) exclui Jobs pendentes antigos do relatório inteiro | Levantada e tecnicamente plausível (seção 2); não validável com dado nesta org (seção 4). Candidata mais forte hoje. |

Recon pronto. Segue para o design (`arquiteto`), que decide se H4 é a causa a corrigir e
se a correção fica só na configuração do Relatório (remover/ajustar `timeFrameFilter`) ou
se precisa de mais confirmação do humano antes de mexer.
