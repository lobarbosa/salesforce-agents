# 05 — Testes — SOMOSAGILITY-21: Campo origem do Lead

**Esta é a rodada de QA formal**, executada contra `sbx-somos-agility-qa`. Substitui
integralmente a rodada anterior (que havia rodado, por necessidade, contra
`sbx-somos-agility-dev` porque `sbx-somos-agility-qa` ainda não estava conectada à
esteira — tratada como entrega inválida, ver `status.yaml`/`gates.md`: a demanda voltou
duas vezes por isso). O defeito de `run-demand.yml` que permitia isso já foi corrigido
(PR #121).

## Ambiente

Checado via `sf org list` e `sf org display --target-org sbx-somos-agility-qa` nesta
sessão, em 2026-10-30, antes de qualquer execução:

- `sbx-somos-agility-qa` — **Connected**, `isSandbox: true`, orgId `00DHa000006WcTcMAK`,
  `https://agilitynetworks--aw.sandbox.my.salesforce.com`, API 68.0, alias confirmado
  (guardrail #1, camada 3 — não bastou o nome do alias, a própria org foi consultada).

Describe de `Lead.LeadSource` conferido nesta sandbox (guardrail #3 — nada presumido a
partir do describe de dev):

- `restrictedPicklist = false`, `nillable = true`, `defaultValue = "Prospecção - Gerente
  de Contas"`.
- Valor `Web Site Agility Networks` com `label = "Web Site Agility"` — mesma configuração
  documentada em `03-design.md` para dev. 18 valores ativos no total, incluindo também
  `Web Site Agility – E-mail` (D-1 continua em aberto — ver seção de cobertura abaixo).

Confirmado: esta é a config de plataforma relevante para os 3 casos de CA-04, e ela é
igual em dev e em QA (como o design já previa), mas agora **verificada na sandbox
correta**, não presumida.

Conforme `04-plano-build.md`, **nenhum metadata foi criado ou alterado no Salesforce**
nesta demanda (Opção F — Custom Permission/Permission Set/Flow — não foi construída
porque a condição P-2 não foi confirmada no gate). Não há, portanto, componente de
`force-app` para implantar em QA ou para testar aqui. O que este roteiro valida é o
**comportamento de plataforma** do campo `LeadSource` (picklist não restrito com default
de org), que é a evidência que sustenta a causa-raiz e a correção real — fora desta
esteira, no middleware externo (Opção A do design).

## Dados usados

Todos fictícios, criados e apagados nesta sessão, direto em `sbx-somos-agility-qa`:
`LastName` prefixado `QA-SOMOSAGILITY-21 CasoN`, `Company = 'QA Teste SOMOSAGILITY-21'`,
`Status = 'Novo'` (exigido pela validation rule `Lead_Novo` no insert). Nenhuma query
retornou dado de Lead real — as únicas leituras foram dos 3 registros de teste recém-
criados por este agente e uma contagem agregada de confirmação pós-limpeza (guardrail
#2).

## Falhas

Nenhuma. Os três casos tiveram exatamente o resultado que o design previa.

## Casos executados (roteiro formal CA-04, `sbx-somos-agility-qa`)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1 — Payload com API name correto | `sf data create record --sobject Lead --target-org sbx-somos-agility-qa` com `LastName='QA-SOMOSAGILITY-21 Caso1'`, `Company='QA Teste SOMOSAGILITY-21'`, `Status='Novo'`, `LeadSource='Web Site Agility Networks'` | `LeadSource` gravado como `Web Site Agility Networks` (valor mantido) | `LeadSource = 'Web Site Agility Networks'` (confirmado por query) | PASSOU |
| 2 — Payload sem `LeadSource` (H1) | Idem, sem o campo `LeadSource` no payload | `LeadSource` assume o default de org `Prospecção - Gerente de Contas` | `LeadSource = 'Prospecção - Gerente de Contas'` (confirmado por query) | PASSOU — comprova H1 (causa-raiz "campo vem com o default", não "vazio") |
| 3 — Payload com label em vez de API name (H2) | Idem, com `LeadSource='Web Site Agility'` (label exibido na UI, não o API name `Web Site Agility Networks`) | Por o picklist não ser `restrictedPicklist`, a API aceita e grava o texto solto, fora da lista oficial | `LeadSource = 'Web Site Agility'` gravado como texto solto (confirmado por query; não corresponde a nenhum dos 18 valores ativos do picklist) | PASSOU — comprova H2 (se o middleware mandar o label em vez do API name, o valor "parece certo" na tela mas não agrupa com `Web Site Agility Networks` em relatório nem ativa o Flow de Opportunity `Atualizar_Descri_o_com_Informa_es_do_Lead`, conforme `03-design.md`) |

IDs criados nesta sessão (apagados ao final, listados só para rastreabilidade do teste,
sem dado pessoal): `00QHa00000STKZaMAP` (Caso 1), `00QHa00000STP4dMAH` (Caso 2),
`00QHa00000STMRgMAP` (Caso 3).

Limpeza: os 3 Leads de teste foram apagados (`sf data delete record`) ao final da
verificação. Confirmado por `SELECT COUNT(Id) FROM Lead WHERE LastName LIKE
'QA-SOMOSAGILITY-21%'` retornando 0 — não ficou registro de teste na sandbox.

## Caso 4/5 (Permission Set) — não aplicável

Não há caso 4/5 para rodar. Esses casos só existiriam se a Opção F (Flow before-save
condicionado a Custom Permission/Permission Set) tivesse sido construída, e
`04-plano-build.md` registra explicitamente que ela **não foi** — a condição P-2 não foi
confirmada no gate de design. Inventar esse caso aqui violaria o guardrail #3 (não
confirmar metadata que não existe) e o próprio design. Se a Opção F vier a ser aprovada
no futuro, os casos (iv) e (v) descritos em `03-design.md`/`04-plano-build.md` entram
numa nova rodada de QA.

## Cobertura dos critérios de aceite (de `01-analise.md`)

| CA | Cobertura nesta rodada | Observação |
|---|---|---|
| **CA-01** — Lead do site recebe o valor correto | **Comprovado o mecanismo de plataforma, em QA**: quando o payload manda o API name certo (Caso 1), o valor é mantido corretamente. A correção efetiva de CA-01 em produção segue dependendo do ajuste do middleware externo (P-4, fora do Salesforce) — esta esteira não controla nem pode validar esse ajuste de ponta a ponta (guardrail #1: produção fora de alcance). |
| **CA-02** — outros canais não mudam | **Não aplicável** — nenhum metadata foi criado ou alterado nesta demanda (`04-plano-build.md`), não existe regra nova no Salesforce que possa interferir em outro canal para testar. Se a Opção F vier a ser construída no futuro, este critério passa a ser testável comparando um usuário com o Permission Set (Lead corrigido) contra um usuário sem ele (Lead inalterado). |
| **CA-03** — valor do site sobrepõe o default | **Comprovado pelos Casos 1 e 2, em QA.** Um valor explícito no payload (Caso 1) sempre vence o default do picklist; sem valor explícito (Caso 2), o default `Prospecção - Gerente de Contas` prevalece. Confirma o mecanismo do qual a Opção A depende: basta o middleware mandar o valor explícito certo. |
| **CA-04** — teste em QA com payload simulado | **Executado formalmente nesta rodada, contra `sbx-somos-agility-qa`** — os 3 casos acima, com dados fictícios, limpos ao final. PASSOU. |

## Validação fora do alcance desta esteira (segue em aberto)

- **Middleware real apontado para QA/produção** — depende de TI Agility (P-4 do design).
  Este agente não tem acesso ao middleware nem a produção (guardrail #1). Fica registrado
  como pendência do cliente, não como falha de teste.
- **Evidência de causa-raiz em produção (P-3)** — print do campo `LeadSource` de um Lead
  real afetado, ou agregado `SELECT LeadSource, COUNT(Id) FROM Lead ... GROUP BY
  LeadSource` rodado por alguém com acesso a produção. Fora do alcance deste agente.
- **P-1** (Marketing/Guilherme confirmar que o valor-alvo é "Web Site Agility" /
  `Web Site Agility Networks`, não `Web Site Agility – E-mail`) e **P-2** (usuário de
  integração exclusivo do site Agility, que decide se a Opção F chega a ser construída)
  continuam sem confirmação registrada em `comentarios-do-card.md` até esta rodada.
- **P-5** (Marketing aceitar a quebra na série histórica de relatórios sem correção
  retroativa dos Leads antigos) também segue em aberto.

Nenhuma dessas pendências é uma falha de teste desta esteira — são decisões/evidências
que dependem de pessoas fora do escopo deste agente (Marketing, TI Agility, acesso a
produção), conforme já registrado em `03-design.md` (seção 8) e `04-plano-build.md`.

---

Testes executados. Preciso da sua homologação para liberar o release.
