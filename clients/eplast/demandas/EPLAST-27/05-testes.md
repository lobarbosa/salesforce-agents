# Testes — EPLAST-27: Próxima melhor ação por cliente

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (Org Id `00DHa000006vZtmMAE`,
`Organization.IsSandbox = true` confirmado via SOQL nesta sessão, API v68.0, instância
`BRA8S`). `sbx-eplast-dev` **não** está conectada neste runner (`sf org list` só lista
`sbx-eplast-qa`) — não foi possível, nem seria o ambiente certo, comparar com dev nesta
sessão.

---

## Por que o veredito é reprovado, não "não testável — pendente"

Não há regressão nem bug: **não existe funcionalidade construída para esta demanda.**
`04-plano-build.md` (gate `aguardando_gate_build`, aprovado por Carlos Sordi em
2026-11-12T19:49:32Z) registra, na própria seção 0, que nenhuma das opções A/B/C/D foi
escolhida e que nenhum metadata foi criado. Confirmei isso de novo nesta sessão contra
`sbx-eplast-qa` (seção "O que confirmei" abaixo) em vez de confiar só no que o plano diz.
`01-analise.md` declara os próprios critérios de aceite como **esqueleto, não testável**
("Qualquer critério escrito agora seria suposição disfarçada de critério"). Rodar um QA
que desse "aprovado" aqui, ou "aprovado com ressalva", exigiria eu inventar um resultado de
teste que não existe — o mesmo padrão de invenção que `03-design.md` e `04-plano-build.md`
recusaram fazer com a regra de negócio. Reprovo porque **não há o que homologar**, não
porque algo quebrou.

### FALHA 1 (crítica) — Nenhum componente construído para EPLAST-27

Não existe campo, Flow, classe Apex, LWC, tópico ou ação de agente, nem permission set
novo relacionado a "próxima melhor ação" em `sbx-eplast-qa`. Testar qualquer um dos
cenários-esqueleto de `01-analise.md` exigiria simular uma regra de negócio que ninguém
definiu. Ver seção "O que confirmei" para a checagem negativa feita via `sf`.

### FALHA 2 (crítica) — Critérios de aceite não existem de fato

`01-analise.md` é explícito: os dois cenários Gherkin são esqueletos com lacunas
(`<objeto a definir>`, `<gatilho a definir>`, `<fontes a definir>`, `<comportamento a
definir>`). Não há caminho feliz, borda ou negativo a derivar deles sem inventar a parte
que falta — o que a instrução deste agente proíbe explicitamente.

### FALHA 3 (bloqueante, não técnica) — Gate de build aprovado sem as perguntas abertas respondidas

`comentarios-do-card.md` só registra três aprovações de gate (análise, design, build),
sem nenhuma resposta a B0 (autorização contratual da Onda 3), B1 (sobreposição com
`SFAgent2`/`insights_comerciais` e com `eplast-ent-09/10/11`) ou Q1–Q5 (regra, fonte,
canal, IA×regra, público). `contrato.md` não foi reaberto nesta sessão (não é escopo do
QA alterar contrato), mas o addendum de `03-design.md` (2026-11-12) já havia revisado isso
antes do build e recomendado explicitamente que o próximo gate **não repita a aprovação
genérica**. O gate de build foi aprovado do mesmo jeito, sem registro novo. Isso não é uma
falha de QA no sentido técnico — é o motivo de não haver nada para testar.

---

## O que confirmi nesta sessão via `sf` (checagem da negativa, não só leitura do plano)

| Verificação | Comando (resumo) | Resultado |
|---|---|---|
| Org conectada e é sandbox | `sf org list`, `sf org display`, `SELECT IsSandbox FROM Organization` | Só `sbx-eplast-qa` conectada; `IsSandbox = true` |
| Campo custom novo em Account com nome plausível (`Proxima`, `NextBest`, `Acao`, `Action`, `Sugest`) | `SELECT DeveloperName FROM CustomField WHERE TableEnumOrId='Account' AND (...)` (Tooling) | 0 registros |
| Flow custom novo com nome/label plausível | `SELECT ApiName, Label, ProcessType, IsActive FROM FlowDefinitionView WHERE NamespacePrefix = null` (lista completa, 26 Flows) | Nenhum Flow novo; os 26 batem com o inventário já descrito em `02-recon.md` (Account, Opportunity, Order, CPQ, Task) |
| Apex class nova | `SELECT Name, CreatedDate FROM ApexClass WHERE NamespacePrefix=null ORDER BY CreatedDate DESC LIMIT 15` | Classe mais recente é `AgentforceCreateOpportunityAction` (2026-10-18), anterior e sem relação com esta demanda |
| Permission set novo | `sf org list metadata --metadata-type PermissionSet`, filtrado por nome plausível | 0 resultados |
| Estado do `SFAgent2` / tópico `insights_comerciais` (B1) | `sf org list metadata --metadata-type Bot/GenAiPlannerBundle` + `sf project retrieve start` de `Bot:SFAgent2` e `GenAiPlannerBundle:SFAgent2_v4` | `SFAgent2` e `SFAgent2_v4` existem nesta sandbox também (não só em dev). Tópico `insights_comerciais` com a mesma descrição do recon ("gera insights para negociação... sinais de risco na carteira do vendedor") e **só as 3 ações padrão** (`IdentifyRecordByName`, `QueryRecords`, `QueryRecordsWithAggregate`, com rótulos em PT). Nenhuma ação/tópico novo específico de "próxima melhor ação". Confirma que B1 segue aberto e sem sobreposição nova criada |
| Volume real (QA, agregado, sem dado pessoal) | `SELECT COUNT() FROM <objeto>` | Account 1217, Opportunity 9326, Order 10319, OrderItem 10007, Task 8689. **Diferente da dev (vazia)** — ou seja, esta sandbox de QA tem volume real seria possível medir CPU/SOQL aqui quando houver algo a medir, mas não há regra implementada para rodar contra esse volume |

Todos os retrieves foram feitos em pasta temporária local (`.qa_tmp_recon/`) e removidos ao
final da sessão — não geraram commit nem ficaram em `force-app/`. Nenhuma query trouxe
campo de dado pessoal de cliente (CPF, e-mail, telefone, valor); os `COUNT()` acima são a
única leitura de volume, agregada.

## Tabela de casos

| Caso | Passos | Esperado (dos critérios-esqueleto de `01-analise.md`) | Obtido | Status |
|---|---|---|---|---|
| Caminho feliz — vendedor vê sugestão de próxima ação numa Account | Abrir um registro de Account em `sbx-eplast-qa` e procurar componente/campo/ação de IA com a sugestão | Indefinido no critério (`<objeto a definir>`, `<gatilho a definir>`) | Não existe campo, componente, Flow ou tópico de agente para esta funcionalidade nesta org | **Não testável — nada construído** |
| Borda — cliente sem histórico suficiente | N/A | Indefinido (`<comportamento a definir>`) | N/A | **Não testável — critério não existe** |
| Negativo — vendedor sem acesso ao registro não vê a sugestão | N/A | Nenhuma regra de permissão definida (nenhum permission set criado) | N/A | **Não testável — nada construído** |
| Permissão por perfil (Comercial × Comercial - Analista × outros) | N/A | Nenhum objeto/componente novo para restringir por perfil | N/A | **Não testável — nada construído** |
| Volume — carga sintética de uma conta com muitos pedidos/itens (`03-design.md` §3, CPU/SOQL) | N/A | `03-design.md` pede carga sintética para dimensionar CPU **antes** de aceitar a opção D | Esta sandbox de QA já tem volume real (Account 1217, Order 10319, OrderItem 10007) que serviria de base para esse teste **quando** houver uma regra/consulta para medir — hoje não há consulta nenhuma a medir | **Não testável — nada construído** |
| B1 — checar sobreposição com `SFAgent2`/`insights_comerciais` | `sf org list metadata` + retrieve de `Bot:SFAgent2` e `GenAiPlannerBundle:SFAgent2_v4` | — (não é critério de aceite, é checagem de risco pedida pela tarefa) | Tópico `insights_comerciais` existe, com descrição muito próxima do objetivo desta demanda, mas sem ação nova de "próxima melhor ação" — confirma que B1 segue sem resposta e sem sobreposição concreta ainda construída | Confirmado (informativo, não é caso de aceite) |
| Separação dev/qa (achado 6 do assessment, R8 do design) | `sf org list` nesta sessão | Esperado poder comparar dev × qa | Só `sbx-eplast-qa` conectada neste runner; não foi possível confirmar a separação física dev/qa nesta sessão (seguimos sem dado novo sobre o achado 6) | **Não testável nesta sessão** |

## O que é genuinamente automatizável aqui, e por que não rodei

- `sf apex run test` — não há classe nova para rodar; rodar a suíte completa existente não
  tem relação com critério de aceite desta demanda e poderia ser mal-interpretado como
  "testei a demanda" quando na verdade testaria só código legado não tocado por ela.
- Query de verificação declarativa (ex.: fórmula calculada, resultado de Flow) — não existe
  componente para consultar.
- `qa_browser_*` — não usei. Não há tela, componente de página ou tópico de agente
  novo para abrir; abrir a `Account_Record_Page` como está hoje só mostraria metadata já
  existente antes desta demanda, sem relação com o que foi pedido, e exigiria abrir um
  registro de Account real (risco de LGPD, guardrail #2) para nenhum ganho de evidência.

## Conclusão

Nenhum critério de aceite de `01-analise.md` é testável nesta sandbox hoje, pelo motivo
registrado desde a análise: a demanda não tem regra de negócio, fonte de dado, canal nem
definição de "próxima melhor ação" fechados, e nada foi construído em consequência disso
(confirmado de novo nesta sessão via `sf`, não só por leitura do plano). O veredito é
**reprovado** — não há o que homologar. Para desbloquear, é necessário, antes de qualquer
nova tentativa de build: (1) resposta registrada a B0 (autorização contratual da Onda 3),
(2) resposta a B1 (relação com `SFAgent2`/`insights_comerciais` e `eplast-ent-09/10/11`),
e (3) resposta a Q1–Q5 (regra de negócio, fonte de dado, canal, IA×regra, público) — nenhum
dos três está registrado em `comentarios-do-card.md` ou `contrato.md` até o momento deste
teste.

---

Testes executados. Preciso da sua homologação para liberar o release.
