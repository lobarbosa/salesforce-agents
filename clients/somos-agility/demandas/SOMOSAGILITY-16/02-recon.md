# SOMOSAGILITY-16 — Recon da org (org-recon)

**Cliente:** Somos Agility
**Org consultada:** `sbx-somos-agility-dev` (única org conectada nesta sessão — não há
`sbx-somos-agility-qa` nem produção conectadas; confirmado via `sf org list`)
**Data da coleta:** 2026-10-27
**Validade:** 7 dias a partir da data acima (recon vencido depois disso — refazer)

## 0. Confirmação de ambiente (guardrail #1)

```
sf org display --target-org sbx-somos-agility-dev
sf data query --query "SELECT IsSandbox, OrganizationType, InstanceName FROM Organization" --target-org sbx-somos-agility-dev
```

- `IsSandbox = true`, `Instance Url` contém `--sbxdev.sandbox.my.salesforce.com`. Confirmado
  via consulta direta à org (não por nome de alias) — é sandbox de verdade, não só um alias
  que parece sandbox.

## 1. Achado inesperado: o Id do relatório existe nesta sandbox

A demanda cita o relatório pelo link
`https://agilitynetworks.lightning.force.com/lightning/r/Report/00O4z0000057ssKEAQ/view`,
num domínio que não é o desta sandbox. A premissa P6 da análise era confirmar se esse Id
corresponde a "Leads Semanais" — a pergunta não dizia em qual org.

```
sf data query --query "SELECT Id, Name, DeveloperName, FolderName FROM Report WHERE Id = '00O4z0000057ssKEAQ'" --target-org sbx-somos-agility-dev
```

Resultado: **o mesmo Id existe nesta sandbox**, com `Name = Leads Semanais`,
`DeveloperName = Leads_Semanais_fu2`, pasta `Leads`. Isso confirma P6 (relatório existe,
nome bate) **nesta sandbox**, mas não confirma nada sobre a org de produção citada no link —
Ids de metadata costumam ser preservados quando uma sandbox é criada por refresh a partir de
produção, o que é consistente com o Id bater, mas não prova que o estado atual do relatório
(destinatários, agendamento) em produção é o mesmo que está aqui hoje.

**Isso não muda o guardrail #1.** Mesmo que esta cópia na sandbox pareça originária de
produção, a alteração pedida pela demanda (remover destinatário de um agendamento) e o
mapeamento de destinatários **reais** só têm valor se feitos contra a org onde o relatório
de fato está em uso — e essa é a de produção, fora do alcance deste agente. O que segue
abaixo é o que dá pra confirmar na sandbox; não substitui conferir o estado em produção.

## 2. Mecanismo de destinatários de relatório agendado — não é exposto por SOQL

```
sf sobject describe --sobject Report --target-org sbx-somos-agility-dev
```

Campos disponíveis no sObject `Report` via API: `Id, OwnerId, FolderName, CreatedDate,
CreatedById, LastModifiedDate, LastModifiedById, IsDeleted, Name, Description,
DeveloperName, NamespacePrefix, LastRunDate, SystemModstamp, Format, LastViewedDate,
LastReferencedDate, ReportTypeApiName`. **Não há campo de agendamento nem de lista de
destinatários/assinantes.**

```
sf org list metadata-types --target-org sbx-somos-agility-dev
```

Entre os tipos de metadata disponíveis não existe `ReportSubscription` nem equivalente
(`ReportType` e `Report` existem, mas cobrem definição do relatório, não quem está
inscrito). Tentativa direta confirmou:

```
sf org list metadata --target-org sbx-somos-agility-dev --metadata-type ReportSubscription
→ Error (1): INVALID_TYPE: Unknown type:ReportSubscription
```

**Conclusão confirmada (P4):** a lista de destinatários de um relatório agendado
("Agendar atualização" / assinatura) não é um objeto queryável por SOQL nem um tipo de
metadata retornável pelas ferramentas desta esteira (`sf data query`,
`sf project retrieve`). Ela vive na Analytics REST API
(`/services/data/vNN.0/analytics/reports/{id}/subscriptions`), fora do alcance das
ferramentas disponíveis nesta sessão. Isso é uma limitação de ferramenta, não uma
suposição — confirmada pelos dois comandos acima.

**Nota sobre comportamento de plataforma (não confirmada nesta org, é documentação pública
da Salesforce, citada com a devida ressalva):** assinaturas de relatório/dashboard
normalmente não são copiadas num refresh de sandbox. Se for esse o caso aqui, a lista de
destinatários desta cópia — mesmo que existisse e fosse consultável — não refletiria a de
produção de qualquer forma. Não tentei confirmar isso via `sf` porque não há como consultar
assinatura nenhuma com as ferramentas disponíveis (ver acima).

## 3. Usuário "Fabio Soto"

```
sf data query --query "SELECT IsActive, COUNT(Id) qtd FROM User WHERE Name = 'Fabio Soto' GROUP BY IsActive" --target-org sbx-somos-agility-dev
```

Resultado: **1 usuário ativo** com esse nome nesta sandbox, nenhum inativo. Resolve P3
*para esta org*: não há homônimo nem duplicidade aqui. Não é possível afirmar o mesmo para
produção sem consultá-la — e esse acesso não é deste agente.

(Id interno do usuário foi obtido para uso técnico, mas não é reproduzido aqui por não ser
necessário ao artefato — RN4/guardrail #2: o artefato não guarda identificador que amarre a
uma pessoa além do que já está em `demanda.md`.)

## 4. Quem administra o relatório

```
sf data query --query "SELECT OwnerId FROM Report WHERE Id = '00O4z0000057ssKEAQ'" --target-org sbx-somos-agility-dev
sf data query --query "SELECT Name, Type, DeveloperName FROM Folder WHERE Id = '<OwnerId retornado>'" --target-org sbx-somos-agility-dev
```

O `OwnerId` do relatório é um Id de **pasta** (prefixo `00l`), não de usuário: o relatório
é de propriedade da pasta pública **"Leads"** (`Type = Report`), não de uma pessoa
específica. Resolve parte de P4/pergunta 7 da análise: a administração de quem pode editar
a assinatura/agendamento deste relatório depende de **quem tem acesso de edição à pasta
"Leads"** (admin do sistema e quem tiver papel de compartilhamento de pasta concedido), não
de um dono individual. Não consultei o compartilhamento da pasta em si (fora do escopo
necessário para a análise — a ação em si será humana, em produção, ver seção 1).

## 5. O que fica pendente (não é possível confirmar com as ferramentas desta sessão)

- Lista real de destinatários do agendamento em produção (mecanismo fora do alcance —
  seção 2 — e org fora do alcance — guardrail #1).
- Se o usuário "Fabio Soto" em produção é o mesmo desta sandbox e se ele está mesmo entre os
  destinatários hoje.
- Se o refresh desta sandbox preservou ou não assinaturas (comportamento de plataforma,
  seção 2) — não verificável sem acesso de consulta à própria assinatura.

## 6. Resposta às premissas da análise (01-analise.md, seção 6)

| Premissa | Status |
|---|---|
| P1 — ambiente é produção | Não confirmável por este agente (sem acesso a produção); mantida como hipótese de trabalho para o design. |
| P2 — leitura do pedido (remover 1 destinatário, não desabilitar o relatório) | Não respondida nos comentários do card; segue pendente para o arquiteto decidir o tratamento. |
| P3 — identidade do usuário | Confirmada **nesta sandbox**: 1 usuário ativo "Fabio Soto", sem homônimo. Não confirmável em produção. |
| P4 — mecanismo de destinatários | Confirmado: não é SOQL nem Metadata API; é Analytics REST API / UI do relatório. Fora do alcance das ferramentas desta esteira. |
| P5 — estado atual (quem recebe hoje) | Não obtido — depende de P4 e de acesso a produção. |
| P6 — relatório existe e Id bate | Confirmado **nesta sandbox**. Não confirmável quanto ao estado de agendamento em produção. |

## 7. Implicação para o design

O recon não encontrou um caminho, dentro do guardrail #1 e das ferramentas disponíveis,
para o agente ler ou alterar os destinatários reais do relatório em produção — nem por
SOQL, nem por Metadata API, nem (mesmo que fosse permitido) pela Analytics REST API, que
não está entre as ferramentas desta esteira. O design precisa decidir o tratamento dado
isso: ação humana direta em produção, com o papel do agente limitado a instruir/documentar
o passo a passo, não a executar.
