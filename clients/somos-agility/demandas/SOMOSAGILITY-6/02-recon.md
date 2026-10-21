# Recon da Org — SOMOSAGILITY-6

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0, `isSandbox: true`
confirmado via `sf org display`/`sf org list`).
**Data da coleta:** 2026-10-21.
**Cobertura:** apenas metadata e contagens agregadas (guardrail #2). Nenhum username ou
e-mail de usuário é reproduzido neste arquivo (achado SOMOSAGILITY-18) — usuários são
identificados pelo campo `Name` (nome de exibição) quando é um usuário funcional/genérico,
e por "Kelly" (já usado pelo próprio consultor em `demanda.md`) no caso da aprovadora atual.

## 1. O objeto FVP existe e tem 4 processos de aprovação, 2 ativos (P-1)

`sf sobject list` confirma o objeto: **`FluxoVendaProdutos__c`** (label "Fluxo de Venda de
Produtos", bate com a sigla "FVP" / "Fluxo de Venda de Produtos e Serviços" da demanda).

`sf org list metadata --metadata-type ApprovalProcess` devolve 4 processos de aprovação
cadastrados neste objeto:

| Nome da API | Label | `processOrder` | `active` |
|---|---|---|---|
| `ValidacaoCotacao` | Validação Cotação | 1 | **true** |
| `ValidacaoFiscal` | Validação Fiscal | 2 | false |
| `ValidacaoFiscal_v_1_1` | Validação de Pricing - v1.1 | 2 | **true** |
| `ValidacaoCotacao_v_1_1` | Validação Cotação - v1.1 | 3 | false |

Só os dois marcados **true** estão ativos hoje. Os outros dois são versões anteriores
("v1.1" é, pelo nome, confusamente a versão **mais nova** de `ValidacaoFiscal`, e a mais
**antiga** teria ficado inativa — conferido pelo conteúdo, não só pelo nome, ver abaixo).

## 2. Em qual etapa a Kelly aparece — e em qual não (P-4)

Conteúdo retido via Metadata API (`sf project retrieve start --metadata ApprovalProcess:...`
contra um workspace temporário fora deste repositório, só para leitura — nenhum arquivo de
metadata foi commitado por esta recon).

- **`ValidacaoCotacao` (ativo, ordem 1):** uma única etapa ("Orçamentista - Validar
  Cotação"), aprovadores = usuário funcional **"Grupo Renovações"**, o usuário **"Sales
  Operation"** e o usuário funcional **"SE"** (todos com `whenMultipleApprovers:
  FirstResponse`). **A Kelly não aparece neste processo.**
- **`ValidacaoFiscal_v_1_1` (ativo, ordem 2, label "Validação de Pricing - v1.1"):** duas
  etapas:
  1. "Grupo Operações - Validação de Pricing" — aprovadores = usuário funcional **"Grupo
     Operações"** e o usuário **"Sales Operation"**.
  2. **"Diretor(a) Comercial - Validação de Pricing"** — aprovador único = **Kelly**
     (atribuição direta de usuário, não fila/grupo/hierarquia — resolve P-4). Só entra se
     `FluxoVendaProdutos__c.Tem_servico__c` (fórmula checkbox, "Tem serviço?") for
     verdadeiro. `rejectBehavior = RejectRequest`: se Kelly rejeitar, a solicitação inteira
     é reprovada (não volta uma etapa) — esse comportamento não muda só por trocar o
     aprovador, fica registrado para o arquiteto confirmar que é o esperado também para
     Sales Op.
- **`ValidacaoFiscal` (inativo, ordem 2):** uma única etapa, aprovadores = "Grupo
  Operações", **Kelly** e "Sales Operation" juntos (FirstResponse). Kelly aparece aqui
  também, mas o processo está **inativo** — não afeta nenhum FVP enquanto continuar assim.
- **`ValidacaoCotacao_v_1_1` (inativo, ordem 3):** duas etapas; a segunda ("Diretor(a)
  Comercial - Validação da Cotação") tem **Kelly** como aprovadora única, igual ao padrão do
  processo ativo acima. Também inativo — não afeta FVPs hoje.

**Conclusão para o design:** o único lugar onde a troca precisa acontecer **para valer
hoje** é a etapa "Diretor(a) Comercial - Validação de Pricing" do processo ativo
`ValidacaoFiscal_v_1_1`. Os dois processos inativos (`ValidacaoFiscal`,
`ValidacaoCotacao_v_1_1`) também citam a Kelly; ficam como pendência de limpeza a decidir
com o arquiteto/humano — editá-los é baixo risco (não estão em uso), mas não é
estritamente necessário para a demanda funcionar, e mexer neles murchece o diff do PR.

Busca por "kelly" (case-insensitive) em todo o metadata retido do objeto (approval
processes, workflow rules/field updates, campos, record types) não encontrou nenhuma outra
ocorrência — ela não aparece em Flow, Apex, regra de atribuição de fila, campo de
responsável ou notificação deste objeto além dos processos de aprovação acima.

## 3. "Sales Op" já existe na org, como usuário — mas há também um grupo com nome parecido (P-2)

`SELECT Id, Username, Name, IsActive, UserType FROM User` confirma um usuário **ativo**,
tipo `Standard`, com `Name = "Sales Operation"` — é esse usuário que já aparece como
aprovador em **ambos** os processos ativos hoje (seção 2). Ele já participa do fluxo de
aprovação do FVP; a demanda pede para ele passar a aprovar também a etapa que hoje é só da
Kelly.

**Achado que muda o desenho:** existe também um **Grupo Público** (`Group`, `Type =
Regular`) chamado **"Sales operations"** (com espaço, minúsculo), distinto do usuário
acima. Nenhum dos dois processos de aprovação ativos usa esse grupo — os dois usam o
usuário "Sales Operation" diretamente. Para manter consistência com o que a org já faz
(e não introduzir um segundo padrão de atribuição no mesmo processo), a recomendação é
usar o **usuário** "Sales Operation" na etapa da Kelly também, a menos que o arquiteto/
humano tenha razão para preferir o grupo (ex.: redundância entre várias pessoas). Fica
como decisão explícita de design, não escolha da recon.

Todos os usuários citados nesta seção e na seção 2 (Grupo Operações, Grupo Renovações, SE,
Sales Operation) são usuários **funcionais/genéricos** (nome de exibição não é nome de
pessoa), ativos, tipo `Standard` — confirmei isso para não confundir com hierarquia ou
fila, mas não reproduzo username/e-mail aqui (proibido pela skill `org-recon`).

## 4. Regra de negócio da aprovação (P-3) — critérios de entrada não mudam com a troca de aprovador

Os `entryCriteria`, `finalApprovalActions`, `finalRejectionActions`,
`initialSubmissionActions` e `recordEditability` (`AdminOnly`) do processo
`ValidacaoFiscal_v_1_1` não referenciam o aprovador em nenhum lugar — trocar só o
`assignedApprover` da etapa "Diretor(a) Comercial - Validação de Pricing" não exige tocar
em critério de entrada, ação de aprovação/rejeição ou campo algum. P-3 confirmada: a
alteração pedida é isolada ao aprovador desta etapa.

## 5. Itens pendentes da Kelly (P-5) — não mensurável nesta sandbox

`SELECT COUNT() FROM FluxoVendaProdutos__c` e `SELECT COUNT() FROM
ProcessInstanceWorkitem WHERE ActorId = '<Id da Kelly>'` retornam **0** nesta sandbox de
dev — consistente com o assessment (sandbox sem massa de dados). **Não há como medir,
nesta org, quantos itens de aprovação estão hoje pendentes com a Kelly em produção** — essa
pergunta só produção responde, e produção está fora do alcance do agente (guardrail #1).
P-5 continua sendo decisão de negócio pendente, agora confirmada como *não verificável
tecnicamente* pela esteira; precisa de resposta humana antes do build, ou o build assume
"nenhum item pendente hoje" como premissa explícita a validar com o cliente antes do
deploy em produção (fora do escopo desta esteira de qualquer forma).

## 6. Achado à parte: `Status__c` não aparece no describe do usuário de integração

`sf sobject describe --sobject FluxoVendaProdutos__c` (rodado com a credencial da esteira)
lista 22 campos e **não inclui `Status__c`**, embora o processo de aprovação ative
referencie esse campo em `entryCriteria` e ele exista de fato (confirmado via Tooling API
`FieldDefinition`, que não filtra por FLS: campo `Status__c`, picklist restrito, 5 valores
ativos, incluindo "Validação de Pricing" — o valor que a etapa da Kelly espera). A leitura
mais provável é FLS: o perfil da credencial de integração não tem "Read" em `Status__c`
para este objeto. Isso não bloqueia a troca de aprovador em si (metadata de
`ApprovalProcess` não depende de FLS do campo), mas é relevante para a etapa de QA: montar
e submeter um registro de teste de FVP vai precisar de um perfil com leitura/edição de
`Status__c`, ou o roteiro de teste esbarra na mesma limitação.

## Perguntas em aberto para o design (arquiteto)

1. **Confirmado:** a troca técnica é no `assignedApprover` da etapa "Diretor(a) Comercial -
   Validação de Pricing" do processo ativo `ValidacaoFiscal_v_1_1` — trocar o aprovador
   único de Kelly para o usuário "Sales Operation" (ou o grupo "Sales operations" — decisão
   do arquiteto, seção 3).
2. **Processos inativos que citam a Kelly** (`ValidacaoFiscal`, `ValidacaoCotacao_v_1_1`):
   incluir na mesma demanda (limpeza preventiva) ou deixar de fora por não estarem em uso?
3. **P-5 (destino dos itens pendentes em produção) segue sem resposta técnica** — precisa
   de decisão humana antes do deploy em produção; não bloqueia o build em sandbox.
4. **Escopo "todos os FVPs ou só os novos"** — não se aplica tecnicamente: trocar o
   aprovador de uma etapa de processo de aprovação vale para toda submissão **futura** a
   partir do deploy; não existe mecanismo de "aplicar só a FVPs novos" num processo de
   aprovação clássico sem reconstruir a lógica de atribuição por data. Se a intenção era
   outra, é desalinhamento de expectativa a esclarecer com o cliente, não escopo técnico
   em aberto.

## Não pôde ser medido

- Quantos itens de aprovação estão pendentes com a Kelly **em produção** — fora do alcance
  do agente (guardrail #1); a sandbox de dev está com 0 registros de FVP.
- Se o perfil/profile da Kelly ou do usuário "Sales Operation" tem alguma permissão
  condicionada ao papel de aprovador (ex.: visibility adicional por estar listado num
  processo de aprovação) — não identificado nenhum vínculo desse tipo nos metadados lidos,
  mas não foi auditado perfil a perfil.
