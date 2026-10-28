# SOMOSAGILITY-6 — Testes (QA)

**Cliente:** Somos Agility. **Tipo:** sustentação.
**Ambiente alvo pela doutrina:** `sbx-somos-agility-qa`.
**Status da sandbox de QA nesta sessão:** **não conectada.** `sf org list` só mostra
`sbx-somos-agility-dev` (`Status: Connected`). Tentativa de abrir sessão de navegador contra
`sbx-somos-agility-qa` via `qa_browser_open` foi recusada pelo próprio guardrail de sandbox
(org não encontrada / não confirmável como sandbox) — ver seção "Bloqueios" abaixo.

Isso **não é reprovação do teste**: é o caminho normal documentado para quando a sandbox de
QA do cliente ainda não existe/conecta na esteira. O que segue é: (a) os bloqueios e o que
ficou como roteiro pendente para execução humana assim que a QA existir; (b) verificações de
metadata feitas contra a **dev** (onde a mudança já foi deployada), deixadas explicitamente
marcadas como **não substitutas** da homologação em QA.

---

## Bloqueios (listados primeiro)

| # | Bloqueio | Detalhe | Impacto |
|---|---|---|---|
| B-1 | **Sandbox de QA indisponível** | `sf org list` não lista `sbx-somos-agility-qa`; `qa_browser_open("sbx-somos-agility-qa", ...)` foi recusado pelo guardrail de sandbox com `NamedOrgNotFoundError` (org não encontrada/sem autorização). | Nenhum cenário do Gherkin pôde ser homologado no ambiente que a doutrina exige (etapa `qa` roda na sandbox de QA, não na dev). Todos os cenários funcionais viram **roteiro pendente** para humano, na QA. |
| B-2 | **R-5 confirmado: FLS em `Status__c` também impede teste funcional na dev** | O recon (`02-recon.md`, seção 6) já havia identificado que o usuário de integração da esteira não enxerga `Status__c` em `FluxoVendaProdutos__c`, campo usado no `entryCriteria` do processo (`Status__c = "Validação de Pricing"`). Isso não é específico da QA — é o mesmo usuário/credencial que a esteira usaria em qualquer ambiente. | Mesmo que a sandbox de QA estivesse conectada, submeter um FVP de teste pelas ferramentas `sf`/`qa_browser_*` desta sessão provavelmente esbarraria na mesma limitação. Confirmar isso requer um usuário de teste com leitura+edição em `Status__c` e `StatusAprovacoes__c` (ação do humano/release), não é algo que este agente pode contornar (guardrail: não alterar perfil de integração nesta demanda). |
| B-3 | **P-5 (itens pendentes da Kelly) é decisão de negócio, não testável tecnicamente** | Confirmado de novo nesta etapa: não há massa de dados em nenhuma sandbox (`FluxoVendaProdutos__c` com 0 registros na dev, conforme recon) e produção está fora do alcance do agente. | Cenário 6 do Gherkin fica como pendência de decisão humana antes do deploy em produção, não como falha de teste. |

---

## Verificação de metadata feita contra a dev (não substitui homologação em QA)

Para não desperdiçar o que é verificável sem sandbox de QA, confirmei por `sf` CLI (retrieve
read-only, sem alterar nada) o estado atual do approval process na **dev**, onde a mudança já
foi deployada (commits `1b48c6c6`/`11c8b979`, PR #78):

- `sf project retrieve start --metadata "ApprovalProcess:FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1"` — etapa `Diretor_a_Comercial_Validacao_Fiscal` (label "Diretor(a) Comercial - Validação de Pricing") tem **um único aprovador**, `type = user`, apontando para o mesmo username já usado na etapa `GrupoOperacoesValidacaoFiscal` (o usuário "Sales Operation" — username não reproduzido aqui, guardrail #2/achado SOMOSAGILITY-18). Nenhum username de Kelly aparece neste arquivo.
- `sf project retrieve start --metadata "ApprovalProcess:FluxoVendaProdutos__c.ValidacaoCotacao"` — outro processo ativo do mesmo objeto. Busca por "kelly" (case-insensitive) nos dois arquivos retornou **zero ocorrências**.
- Comparei `entryCriteria`, `finalApprovalActions`, `finalRejectionActions`, `initialSubmissionActions`, `rejectBehavior`, `allowDelegate`, `whenMultipleApprovers` da etapa alterada e do processo contra o que o recon (`02-recon.md`) e o design (`03-design.md`) descreviam como estado anterior: nenhuma diferença além do nó `assignedApprover/approver/name` da etapa `Diretor_a_Comercial_Validacao_Fiscal`.

Isso é **leitura de metadata na dev**, não execução do roteiro funcional na sandbox de QA que
a doutrina exige. Fica registrado como evidência parcial, não como homologação.

---

## Casos de teste (derivados dos critérios de aceite de `01-analise.md`)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| **CT-1** — Kelly não é mais aprovadora do processo ativo (cenário 1 do Gherkin) | Na sandbox de QA: Setup → Approval Processes → `FluxoVendaProdutos__c` → `ValidacaoFiscal_v_1_1` → inspecionar aprovador de cada etapa. | Nenhuma etapa ativa tem Kelly como aprovador; nenhuma regra de atribuição resolve para ela. | **Não executado na QA** (B-1). Verificação equivalente feita na **dev** via metadata (`sf project retrieve`): confirmado — nenhum username de Kelly nos dois processos ativos do objeto. | **BLOQUEADO (QA) / confirmado na dev como evidência parcial** |
| **CT-2** — Sales Operation é o aprovador da etapa alterada (cenário 2) | Na QA: inspecionar etapa "Diretor(a) Comercial - Validação de Pricing" do processo `ValidacaoFiscal_v_1_1`. | Aprovador único = usuário "Sales Operation", `type = user`. | **Não executado na QA** (B-1). Confirmado na dev: etapa tem aprovador único, `type = user`, mesmo username do aprovador já usado na etapa anterior do mesmo processo. | **BLOQUEADO (QA) / confirmado na dev como evidência parcial** |
| **CT-3** — FVP submetido após a mudança cai para Sales Op, não para Kelly (cenário 3) | Criar um registro de teste de FVP (sem dado real de cliente) com `Tem_servico__c = Verdadeiro`, `Status__c` e `StatusAprovacoes__c` nos valores de entrada do processo; submeter à aprovação; conferir fila/itens de aprovação do usuário "Sales Operation" e ausência de item para Kelly. | Item de aprovação aparece para "Sales Operation" e não aparece para Kelly. | **Não executado.** Além da QA indisponível (B-1), o usuário de integração da esteira não tem FLS de leitura em `Status__c` (B-2/R-5) — nem na dev este agente consegue montar/submeter o registro de teste sem um usuário de teste dedicado. | **BLOQUEADO — roteiro pendente para humano, com usuário de teste com FLS em `Status__c`/`StatusAprovacoes__c`** |
| **CT-4** — Regra de negócio da aprovação permanece inalterada (cenário 4) | Comparar `entryCriteria`, ações de aprovação/rejeição e campos do processo antes/depois da mudança. | Nenhuma diferença além do aprovador da etapa `Diretor_a_Comercial_Validacao_Fiscal`. | Confirmado na dev via retrieve + comparação com o que `02-recon.md`/`03-design.md` registraram do estado anterior: `entryCriteria`, `finalApprovalActions`, `finalRejectionActions`, `initialSubmissionActions`, `rejectBehavior`, `allowDelegate`, `whenMultipleApprovers` idênticos; único nó alterado é o aprovador. | **PASSOU (verificado na dev; QA ainda pendente de confirmação equivalente)** |
| **CT-5** — Alteração não atinge produção (cenário 5) | Conferir que todo deploy desta demanda (histórico de `04-plano-build.md`, comandos `sf project deploy validate`/`deploy start`) foi direcionado só a `sbx-somos-agility-dev`; nenhum comando contra produção. | Nenhum deploy/DML/Apex anônimo contra org de produção em nenhum momento da esteira. | Confirmado: todos os comandos `sf` do build (`04-plano-build.md`) e desta sessão de QA tiveram `--target-org sbx-somos-agility-dev` ou recusaram antes de tocar qualquer alvo não-sandbox (guardrails `ambientes.alias_permitido`, `guard-prod.sh`, `guarda.py` — este último bloqueou inclusive a tentativa de abrir `sbx-somos-agility-qa` por não conseguir confirmar `IsSandbox`). | **PASSOU** |
| **CT-6** — Itens de aprovação pendentes da Kelly têm destino definido (cenário 6) | Verificar se existe decisão registrada sobre o destino de itens pendentes com Kelly no momento da mudança. | Decisão de negócio registrada (redistribuir, manter ou rejeitar). | Não é tecnicamente mensurável em nenhuma sandbox (0 registros de FVP em dev e QA fora do alcance); produção — onde o volume real existiria — está fora do alcance do agente. `03-design.md` seção 6 já registra a premissa adotada (build não mexe em itens pendentes; decisão cabe ao cliente antes do deploy em produção, com 3 opções descritas). | **NÃO TESTÁVEL NESTA SANDBOX — decisão de negócio pendente (P-5), não é falha técnica** |
| **CT-7 (borda)** — FVP com `Tem_servico__c = Falso` não entra na etapa alterada | Submeter um FVP de teste com `Tem_servico__c = Falso` e demais critérios de entrada atendidos; conferir que o processo entra só na 1ª etapa ("Grupo Operações") e nunca chega à etapa do aprovador alterado. | Etapa "Diretor(a) Comercial - Validação de Pricing" não é avaliada; processo segue/finaliza sem passar por ela. | **Não executado** — mesmos bloqueios de CT-3 (B-1, B-2). `entryCriteria` da etapa (`Tem_servico__c = Verdadeiro`) não foi alterado por esta demanda, então o comportamento de borda é herdado do processo já existente, não é novo risco introduzido — mas não foi confirmado na prática. | **BLOQUEADO — roteiro pendente** |
| **CT-8 (negativo)** — Kelly não consegue mais agir sobre item da etapa alterada | Com um item de aprovação já na etapa "Diretor(a) Comercial - Validação de Pricing" (criado antes ou depois da mudança), confirmar que Kelly não vê/não consegue aprovar ou rejeitar esse item específico. | Kelly sem acesso a ações de aprovar/rejeitar sobre o item dessa etapa. | **Não executado** — mesmos bloqueios de CT-3. | **BLOQUEADO — roteiro pendente** |
| **CT-9 (permissão por perfil / R-1)** — Sales Operation consegue agir sobre o item da etapa alterada, inclusive quando já aprovou a 1ª etapa do mesmo FVP | Com um FVP de teste cujas duas etapas estão ativas (`Tem_servico__c = Verdadeiro`), ter "Sales Operation" aprovar a 1ª etapa e depois conferir que o item da 2ª etapa também aparece para ele e que ele consegue agir (visibilidade de registro + ação de aprovação). | Item da 2ª etapa visível e acionável por "Sales Operation", confirmando na prática o cenário aceito explicitamente pelo humano no gate de design (R-1 — mesma conta pode aprovar as duas etapas). | **Não executado** — mesmos bloqueios de CT-3. Este é o cenário que o próprio design (`03-design.md`, seção 3) e o briefing desta etapa marcam como o mais importante de confirmar na prática, exatamente por depender de visibilidade de registro que o recon não auditou perfil a perfil. | **BLOQUEADO — roteiro pendente, prioridade alta** |
| **CT-10 (volume)** | — | — | Não aplicável: a mudança é de metadata (troca de um único aprovador declarativo), sem lógica condicionada a volume de registros, lote ou concorrência. Não há caso de volume relevante para esta demanda. | **N/A — justificado** |

---

## Roteiro pendente para execução humana na sandbox de QA (quando conectar)

Para CT-3, CT-7, CT-8 e CT-9 (todos dependem de submeter FVP de teste):

1. Confirmar que `sbx-somos-agility-qa` está `Connected` (`sf org list`).
2. **Pré-requisito (R-5):** garantir um usuário de teste (perfil ou permission set) com
   leitura e edição de `FluxoVendaProdutos__c.Status__c` e `StatusAprovacoes__c`. Sem isso,
   não dá para montar/submeter um FVP de teste pela UI.
3. **Pré-requisito (R-3):** confirmar, por contagem/existência (nunca reproduzindo
   username), que os 4 usuários citados no XML do approval process (Kelly, "Sales
   Operation", "Grupo Operações", o submitter) existem e estão ativos em
   `sbx-somos-agility-qa`. Se o deploy do approval process ainda não aconteceu nesta QA,
   isso é pré-requisito do **release**, antes mesmo do roteiro de QA poder rodar.
4. Criar um registro de teste de `FluxoVendaProdutos__c` **sem dado real de cliente**
   (nome fictício, sem CPF/e-mail/telefone/valor real), com `Status__c = "Validação de
   Pricing"`, `StatusAprovacoes__c` num dos valores aceitos pelo `entryCriteria`, e
   `Tem_servico__c = Verdadeiro`.
5. Submeter à aprovação. Conferir no item de aprovação da 1ª etapa que "Sales Operation"
   consegue ver e aprovar (CT-9, parte 1).
6. Aprovar a 1ª etapa. Conferir que o item da 2ª etapa ("Diretor(a) Comercial - Validação
   de Pricing") aparece para "Sales Operation" e **não** aparece para Kelly (CT-3, CT-8,
   CT-9 parte 2).
7. Repetir com `Tem_servico__c = Falso` para confirmar que a 2ª etapa não é avaliada (CT-7).
8. Capturar evidência (screenshot) só do registro de teste criado neste passo a passo —
   nunca de um FVP real de cliente (guardrail #2/LGPD).

---

## Resumo

- **Nenhum cenário funcional do Gherkin foi homologado na sandbox de QA**, porque ela não
  está conectada à esteira nesta sessão (B-1) — condição documentada como esperada, não
  como reprovação.
- O que foi possível verificar hoje (metadata na dev, guardrails de ambiente) **passou**:
  Kelly não é mais aprovadora dos processos ativos, Sales Operation é o aprovador único da
  etapa alterada, a regra de negócio da aprovação não mudou além do aprovador, e nenhum
  comando desta demanda tocou produção.
- O que depende de submeter um FVP de teste (CT-3, CT-7, CT-8, CT-9) está bloqueado tanto
  pela ausência da sandbox de QA quanto por uma limitação de FLS (R-5) que existe
  independente do ambiente, e virou roteiro escrito para execução humana assim que ambos
  forem resolvidos.
- P-5 (itens pendentes da Kelly) segue como decisão de negócio pendente, não como falha de
  teste — fora do alcance técnico desta esteira.

Testes executados (parcialmente, pelos bloqueios documentados acima). Preciso da sua
homologação para liberar o release — com a ressalva de que os cenários 3, 6, 7, 8 e 9 ainda
não têm evidência funcional de QA e precisam do roteiro pendente executado assim que a
sandbox de QA estiver disponível e o usuário de teste com FLS em `Status__c` existir.
