# EPLAST-30 · Testes — Apoio a propostas, follow-ups e argumentos comerciais

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** qa · **Autor:** qa
**Entradas:** `01-analise.md` (seção 4, Gherkin — fonte dos casos), `02-recon.md`, `03-design.md` (seções 2.4, 12), `04-plano-build.md` (seções 3.6 e 4), `gates.md`, `comentarios-do-card.md`, `assessment.md`, `status.yaml`.

---

## 0. Contexto necessário antes da tabela de casos

O primeiro build (`04-plano-build.md`) terminou **bloqueado de propósito**: dos 10 componentes previstos no design, só 2 foram deployados de verdade em `sbx-eplast-dev` (`IA_Rascunho_Comercial` e os dois `PromptFlow` de grounding). Os 3 `GenAiPromptTemplate` (Flex), o Screen Flow, o `PermissionSet`, o `PermissionSetGroup` e a aba na FlexiPage existem só em `force-app/` do repositório — nunca deployaram em nenhuma org, porque o vínculo Flex↔PromptFlow não fecha (`04-plano-build.md`, seção 3.6).

Depois disso, o design foi revisado (`03-design.md`, seção 12) propondo uma POC de correção. O `status.yaml` mostra que a demanda passou de `build` → `design` → `aguardando_gate_design` → `aguardando_gate_build` → aprovada por Carlos Sordi → `qa`, tudo em menos de 1 hora (19:09 a 19:58 de 2026-11-12). **Não há nenhum commit novo em `force-app/` nem atualização em `04-plano-build.md` nesse intervalo** — o hash em `gates.md` para o gate de build (`23ce00ee3b2c02cf`) bate com o `04-plano-build.md` que ainda diz, textualmente, "Build não fechou". Ou seja: o gate de build foi aprovado sabendo que o build não tinha fechado, e nenhuma nova tentativa de build aconteceu entre a revisão do design e a aprovação. Esta sessão de QA **não reabre essa decisão** (não é papel do QA questionar um gate já registrado), mas o resultado é mecânico: não há nada novo para testar além do que já existia quando o `04-plano-build.md` foi escrito.

A doutrina (CLAUDE.md raiz) não tem um passo de deploy explícito para QA antes desta etapa — o deploy para sandbox/UAT documentado é o da etapa `release`, posterior à homologação. Por isso o primeiro passo desta sessão foi confirmar, por `sf` CLI contra `sbx-eplast-qa`, o que de fato existe lá, sem assumir nada.

### 0.1 Confirmação de ambiente (R4 do design / achado 6 do assessment)

| Item | `sbx-eplast-dev` (04-plano-build.md) | `sbx-eplast-qa` (medido agora) |
|---|---|---|
| Org Id | `00DHa000006vfMLMAY` | `00DHa000006vZtmMAE` |
| Username (sufixo, mascarado — guardrail #2) | `[usuário técnico]...eplast2.qa` | `[usuário técnico]...eplast2.qas` |
| Instance URL | `eplast--qa.sandbox...` | `eplast--qas.sandbox...` |
| Opportunity (COUNT) | 0 | 9.326 |
| Account (COUNT) | 0 | 1.217 |
| Contact (COUNT) | 0 | 914 |
| SBQQ__Quote__c (COUNT) | 0 | 8.558 |
| DefaultAccountAccess / DefaultOpportunityAccess / DefaultContactAccess | Edit / Read / ControlledByParent | Edit / Read / ControlledByParent (igual) |

**Conclusão:** Org Ids diferentes → **confirmado que dev e qa são sandboxes distintas**, não a mesma org (resolve a dúvida binária do achado 6/R4). Mas o achado de nomenclatura do assessment não desaparece: os dois usernames seguem indicando "qa" (`.qa` e `.qas`), e agora há um dado novo que o assessment não tinha: **`sbx-eplast-qa` tem volume de dados real (milhares de Opportunity/Account/Contact/Quote), enquanto `sbx-eplast-dev` está vazia.** Isso é relevante para qualquer sessão futura de build ou QA nesta conta: `sbx-eplast-qa` não é um ambiente limpo para criar dado sintético sem cuidado — há dado de negócio (possivelmente originado de refresh) e nenhuma query além de `COUNT()` foi rodada aqui (guardrail #2). Nenhum registro individual foi lido nem exibido.

### 0.2 Inventário dos componentes da demanda em `sbx-eplast-qa`

Verificado via `sf org list metadata` para cada tipo relevante, sem suposição:

| Componente | Tipo | Existe em `sbx-eplast-dev` (04-plano-build.md) | Existe em `sbx-eplast-qa` (medido agora) |
|---|---|---|---|
| `IA_Rascunho_Comercial` | CustomPermission | Sim | **Não** |
| `Opportunity_PromptFlow_CotacaoPrimaria` | Flow (PromptFlow) | Sim | **Não** |
| `Opportunity_PromptFlow_DadosOportunidade` | Flow (PromptFlow) | Sim | **Não** |
| `Opportunity_Screen_RascunhoComercial` | Flow (Screen) | Não (só repositório) | **Não** |
| `Rascunho_Proposta_Comercial` | GenAiPromptTemplate | Não (só repositório) | **Não** |
| `Rascunho_Followup_Comercial` | GenAiPromptTemplate | Não (só repositório) | **Não** |
| `Argumentos_Comerciais_Oportunidade` | GenAiPromptTemplate | Não (só repositório) | **Não** |
| `PS_Comercial_RascunhoIA` | PermissionSet | Não (só repositório) | **Não** |
| `PSG_Comercial_RascunhoIA` | PermissionSetGroup | Não (só repositório) | **Não** |
| Aba "Rascunho IA" em `Opportunity_Record_Page` | FlexiPage (alteração) | Não (só repositório) | **Não** |

**Nenhum dos 10 componentes da demanda existe em `sbx-eplast-qa`.** `GenAiPromptTemplate` retorna vazio (tipo válido, 0 registros); nenhum `Flow` ou `PermissionSet`/`PermissionSetGroup` com "Rascunho" ou "RascunhoIA" no nome aparece entre os existentes; `CustomPermission` tem só 8 registros, todos de pacote gerenciado (`maps`, `SBQQ`).

### 0.3 Revisão estática dos 3 Flows em `force-app/` (automação, achado 1 do assessment)

Como nenhum componente está deployado em org nenhuma acessível a esta sessão (`sbx-eplast-dev` não está autenticada aqui), a única verificação possível do cenário "não dispara automação existente" é **revisão estática do XML em `force-app/`**, que é automatizável e não exige deploy:

```
grep -c -E "recordCreates|recordUpdates|recordDeletes" \
  Opportunity_PromptFlow_CotacaoPrimaria.flow-meta.xml \
  Opportunity_PromptFlow_DadosOportunidade.flow-meta.xml \
  Opportunity_Screen_RascunhoComercial.flow-meta.xml
→ 0 / 0 / 0

grep -i -E "actionType>submit|SendEmail|approvalSubmit" Opportunity_Screen_RascunhoComercial.flow-meta.xml
→ nenhuma ocorrência
```

Confirma, por inspeção própria (não só citando `04-plano-build.md`), que os 3 Flows definidos no repositório não têm elemento de DML nem envio de e-mail ou submissão de aprovação. **Isto não prova comportamento em execução** (nenhum debug log pôde ser gerado, porque nada roda em org nenhuma hoje) — é evidência estática, não dinâmica.

---

## 1. Casos de teste (derivados da seção 4 de `01-analise.md`)

Todos os 9 cenários Gherkin dependem de pelo menos um componente que não existe em `sbx-eplast-qa` (seção 0.2). Por isso, a tabela abaixo marca cada um como não testável nesta sessão, pela mesma causa raiz, e não como 9 falhas independentes.

| Caso (cenário Gherkin) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Follow-up gerado a partir de oportunidade acessível | Abrir uma Opportunity em `sbx-eplast-qa`, localizar o ponto de entrada do rascunho, pedir follow-up | Texto editável citando conta/etapa, em até `<N>` s (N não definido, P-9), nada gravado | Não há ponto de entrada: `Opportunity_Screen_RascunhoComercial` e os 3 templates não existem na org | **Não testável** — bloqueado por ausência de componente |
| Dado ausente não vira invenção | Pedir proposta para oportunidade sem data de fechamento | Trecho aparece como `[dado ausente: data de fechamento]`, com lista de campos usados/vazios | Mesmo bloqueio acima | **Não testável** |
| Respeito ao compartilhamento do Salesforce | Usuário sem acesso à oportunidade Y tenta gerar rascunho, pela tela ou por Id | Mesma resposta de acesso negado do Salesforce; nada enviado ao modelo | Mesmo bloqueio acima. OWD de Opportunity em `sbx-eplast-qa` é `Read` (Public Read Only), igual ao de dev — não muda a conclusão, só documenta o ambiente | **Não testável** |
| Preço e condição comercial não são inventados | Pedir proposta para oportunidade sem Quote no CPQ | Preço/desconto/prazo só como `[a preencher]`; nenhum número fora do grounding | Mesmo bloqueio acima | **Não testável** |
| Argumento comercial rastreável | Pedir argumentos para uma oportunidade | Cada argumento cita a fonte | Mesmo bloqueio acima. Além disso, as fontes em si são `<fontes a definir>` (P-4 parcialmente aberta) | **Não testável** (dupla causa: componente ausente + critério pendente) |
| Trilha de uso sem dado pessoal | Consultar registro de uso depois de um rascunho gerado | Ver usuário, registro, tipo, data, modelo; texto/prompt completos não ficam gravados (retenção a definir, P-10) | O próprio design (`03-design.md`, seção 8, R9) **retirou este cenário da v1**: não existe objeto de log, por decisão já registrada, não por bug. P-10 segue sem resposta do cliente/DPO | **Não testável — fora do escopo da v1 por decisão de design**, não é falha do build |
| Acesso restrito por permissão | Usuário sem o permission set abre a Opportunity; chamada direta ao componente | Ação não aparece; chamada direta é negada | `IA_Rascunho_Comercial`, `PS_Comercial_RascunhoIA` e `PSG_Comercial_RascunhoIA` não existem em `sbx-eplast-qa` — não há como testar negação de acesso a um componente que não existe para ninguém | **Não testável** |
| Falha do provedor de IA não trava o registro | Simular indisponibilidade do provedor ao pedir rascunho | Mensagem de falha; edição do registro continua normal | Mesmo bloqueio acima | **Não testável** |
| Não dispara automação existente do registro | Gerar um rascunho e verificar debug log de Opportunity/Account/Order | Nenhum trigger nem Flow desses objetos executa | Nada roda em `sbx-eplast-qa` (feature ausente), então não há execução nenhuma para gerar debug log. **Revisão estática do XML em `force-app/`** (seção 0.3) confirma 0 elementos de DML e nenhuma ação de e-mail/aprovação nos 3 Flows definidos — evidência indireta a favor do design, mas não é a verificação dinâmica que o cenário pede | **Parcial** — revisão estática ok; execução real não verificável nesta sessão |

---

## 2. Falhas

### FALHA 1 (crítica) — Nenhum dos 10 componentes da demanda existe em `sbx-eplast-qa`

A demanda chegou à etapa `qa` sem que nenhuma parte do que o design aprovou (seção 3 e seção 12.5 de `03-design.md`) esteja deployada em org nenhuma alcançável por esta sessão como solução completa: em `sbx-eplast-dev` só 2 dos 10 componentes existem (ambos de leitura/grounding, sem ponto de entrada de usuário), e em `sbx-eplast-qa`, a org desta etapa, **0 dos 10** existem (seção 0.2, confirmado por `sf org list metadata` para `CustomPermission`, `GenAiPromptTemplate`, `Flow`, `PermissionSet` e `PermissionSetGroup`). Isso bloqueia 8 dos 9 cenários de aceite por completo e deixa o 9º só parcialmente verificável. Não há o que homologar: a funcionalidade pedida pela demanda não existe, do ponto de vista do usuário final, em nenhum ambiente testável hoje.

### FALHA 2 (crítica) — O bloqueio técnico central (seção 3.6 do build) segue sem resolução, apesar do gate de build aprovado

O `04-plano-build.md` registra, com evidência de deploy real repetido, que o vínculo entre `GenAiPromptTemplate` (Flex) e um `PromptFlow` customizado como fonte de grounding não funciona nesta org/release (`"O parâmetro de saída da ação ... não corresponde"`). O design foi revisado (`03-design.md`, seção 12) propondo uma POC de até 4h para corrigir isso, com duas técnicas e um fallback (Apex) condicionado à autorização do humano (seção 12.8). **Entre a revisão do design e a aprovação do gate de build (menos de 1 hora, 19:09–19:58 de 2026-11-12) não há nenhum commit novo em `force-app/` nem atualização em `04-plano-build.md`** — o hash do gate (`23ce00ee3b2c02cf`) bate com o plano que ainda diz "Build não fechou". Isto é, a POC não foi executada, ou foi executada sem deixar rastro em disco, o que viola o guardrail #5 (estado em disco) e a doutrina de que o artefato de uma etapa prova que ela aconteceu. Sem essa correção, nenhum deploy a `sbx-eplast-qa` é possível, e esta é a causa raiz da FALHA 1.

---

## 3. O que não foi testado e por quê (critérios não testáveis nesta sandbox)

- **Tempo de resposta (`<N>` segundos, P-9):** sem decisão do cliente e sem a feature deployada, não há como medir nem definir critério de reprovação. Fica para quando houver build fechado e N definido.
- **Fontes dos argumentos comerciais (`<fontes a definir>`, P-4):** parcialmente aberto mesmo no design (campo, produto ou caso), então não dá para validar texto contra um critério que ainda não existe por completo.
- **Retenção do texto/prompt (`<retenção a definir>`, P-10) e trilha de uso:** cenário explicitamente fora da v1 por decisão do próprio design (seção 8, R9). Não é "não testável por falta de ambiente", é "não vai existir nesta versão" até o cliente/DPO decidirem.
- **Qualquer teste de UI via `qa_browser_*`:** não foi tentado. `sbx-eplast-qa` conecta normalmente (guardrail de sandbox passaria), mas não há nada deployado para clicar — abrir a página de Opportunity mostraria só o layout padrão, sem a aba "Rascunho IA" (porque a FlexiPage não foi alterada em nenhuma org). Abrir uma Opportunity de verdade nesta org exigiria usar um dos 9.326 registros reais (ou criar um novo, disparando a cadeia de 16 validation rules e o `OpportunityFlow` com até 22 DMLs e possível submissão de aprovação, documentada em `02-recon.md`/`03-design.md`), sem nenhum ganho de evidência sobre o que o inventário de metadata já prova de forma conclusiva. Por isso não foi executado.
- **Debug log de execução (cenário "não dispara automação"):** não verificável dinamicamente, só estaticamente (seção 0.3), pelos motivos da FALHA 1.
- **Apex / `sf apex run test`:** não se aplica — a solução não tem Apex (decisão do design, seção 2), e nenhuma classe foi criada ou alterada por esta demanda.

---

## 4. Encerramento

Testes executados. Preciso da sua homologação para liberar o release.
