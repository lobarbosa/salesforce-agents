# 05 — Testes: Automatização de criação de oportunidades de renovações

**Demanda:** SOMOSAGILITY-20 · **Cliente:** somos-agility · **Agente:** `qa`
**Data:** 2026-10-30 · **Org usada:** `sbx-somos-agility-qa` (única org conectada nesta
sessão; confirmado via `sf org list`)

> **Não há o que testar. Nada foi construído.** Este arquivo documenta a confirmação
> independente disso e o que precisa acontecer antes de qualquer execução real de teste —
> não é um roteiro de teste executado com sucesso, nem um roteiro para o humano seguir
> contra algo que não existe.

---

## 1. O que a etapa anterior já declarava

`04-plano-build.md` (agente `builder-declarativo`, 2026-10-28) é explícito: *"Nenhum
metadata foi escrito. Nenhuma branch foi criada. Nenhum deploy foi feito."* O motivo
registrado ali é que `03-design.md` ficou bloqueado em duas perguntas de negócio que
`01-analise.md` já havia marcado como bloqueantes desde a análise:

- **6.1** — qual objeto de origem do Flow: HVR (`Hist_rico_de_Venda_e_Renova_o__c`),
  Asset ou Contract.
- **6.3** — critério exato de elegibilidade (quais valores de `Classe_de_renovacao__c`
  e/ou `Tipo_do_Evento__c` entram ou saem).

`comentarios-do-card.md` tem 5 entradas até 2026-10-30: abertura do chamado (Vanessa
Ranieri, Departamento Renovações), aprovação da estimativa de 19h, e as aprovações dos
gates `aguardando_gate_analise`, `aguardando_gate_design` e `aguardando_gate_build`.
**Nenhuma delas responde 6.1 ou 6.3** — são só movimentação de fluxo, não decisão de
negócio. Os critérios de aceite em `01-analise.md` (seção 4) seguem como "ESQUELETO
BLOQUEADO", com placeholders `< >` não preenchidos (ex.: `RecordType "<definido em 6.5>"`,
`<evento de disparo definido em 6.1>`, `<critério de elegibilidade 6.3>`) — não é possível
derivar um caso de teste concreto de um critério que não tem valor.

`gates.md` confirma que o gate `aguardando_gate_build` foi aprovado por Leonardo Barbosa
em 2026-10-30T04:20:00Z tendo como único artefato revisado o próprio `04-plano-build.md`
(hash `d0e4ef4ebcd05753`) — ou seja, o que foi aprovado para passar para `qa` foi
explicitamente o documento que declara o bloqueio, não um build.

## 2. Confirmação independente feita nesta sessão (não assumi o texto do artefato)

Todos os comandos abaixo rodaram contra `sbx-somos-agility-qa` — a única org conectada
nesta sessão (`sf org list` lista só essa, status `Connected`, confirmada `IsSandbox =
true` via `SELECT IsSandbox, Name FROM Organization`). Nenhuma query abaixo retorna dado
pessoal — só metadata e `COUNT()` (guardrail #2).

| Verificação | Comando | Resultado |
|---|---|---|
| Flow novo por nome proposto no design (`*CriaOportunidade*`) | `SELECT ApiName, Label FROM FlowDefinitionView WHERE ApiName LIKE '%CriaOportunidade%'` | **0 registros** |
| Flow relacionado a "Renova" (para pegar qualquer nome alternativo) | `SELECT ApiName, Label FROM FlowDefinitionView WHERE Label LIKE '%Renova%'` | 7 registros — **todos os mesmos Flows já catalogados em `02-recon.md`** (`Atualiza_Owner_da_Oportunidade_se_Renova..._v2_1/v2_3`, `Captura_a_conta_atrelada...`, `Notifica_se_Oportunidade_de_Renovacao_tem_Contrato_Encerrado`, `Remove_Fase_CVS_RVS...`, `Verifica_qual_o_hist_rico...`). Nenhum novo. |
| Total de Flows ativos na org | `SELECT COUNT() FROM FlowDefinitionView WHERE IsActive = true` | 322 (recon em dev registrava 320 — diferença não investigada a fundo, mas nenhum dos 4 Flows modificados nos últimos 14 dias, ver abaixo, tem relação com esta demanda) |
| Flows modificados nos últimos 14 dias (pega qualquer coisa recém-tocada, mesmo sem nome esperado) | `SELECT ApiName, Label, LastModifiedDate FROM FlowDefinitionView WHERE LastModifiedDate = LAST_N_DAYS:14` | 4 registros, nenhum relacionado a renovação/oportunidade: `Atualiza_o_status_final_de_aprovacao_do_LAT`, `Atualiza_valor_total_de_despesas_realizadas_no_projeto`, `JOBSolicitacaoTreinamento_Valida_preenchimento_campos_aprovacao`, `SolicitacaoReembolso_Valida_campos_pag` |
| Custom Label `Renovacao_OwnerId` (proposta no design) | `SELECT Name, MasterLabel FROM ExternalString WHERE Name LIKE 'Renovacao%'` (Tooling API) | **0 registros** |
| Custom Label `Renovacao_DiasAntecedencia` (proposta no design) | mesma query acima, mesmo filtro de prefixo | **0 registros** |
| Repositório local (`force-app`) | `ls force-app`, `git log --oneline -- force-app`, `git diff main --stat -- force-app` | Diretório `force-app` **não existe neste checkout** e não há histórico de commit tocando metadata para esta demanda |
| Branch de feature com metadata | `git log --oneline --all -- force-app` | nenhum resultado |

**Conclusão da confirmação:** não existe, em `sbx-somos-agility-qa`, nenhum Flow, Custom
Label ou outro metadata novo atribuível a SOMOSAGILITY-20. O estado da org bate
exatamente com o que `04-plano-build.md` declarava — confirmado por mim, não assumido.

Como dado complementar (não usado para nenhum teste, só registro): a org de QA tem dado
real, diferente da sandbox de dev usada no recon (`02-recon.md` registrava volume 0 em
dev). Contagens agregadas apenas: `Opportunity` com `Renova_o__c = true` → 445;
`Hist_rico_de_Venda_e_Renova_o__c` → 10000+ (limite do agregador, não investigado — não é
necessário para esta conclusão). Nenhum Id, nome ou valor de registro foi consultado.

## 3. Por que não monto roteiro de teste nem o executo

Os critérios de aceite de `01-analise.md` (seção 4) são, pela própria descrição do
`ba-discovery`, um "esqueleto bloqueado": toda condição-chave de cada cenário Gherkin é um
placeholder `<...>` que depende de 6.1–6.6. Testar contra isso significaria uma de duas
coisas erradas:

1. **Inventar valores** para os placeholders (ex.: assumir que o gatilho é o HVR e que
   `E_o_mais_recente__c = true` é o único critério de elegibilidade) e testar contra a
   minha própria suposição — isso violaria o guardrail #3 ("não invente metadata/regra") e
   produziria um "passou" que não significa nada, porque testaria uma regra que ninguém
   aprovou.
2. **Testar contra metadata que não existe** — não há Flow, Custom Label ou campo novo em
   `sbx-somos-agility-qa` para executar. Não há UI nova para abrir com `qa_browser_*` (não
   há tela, botão, Flow Screen ou registro novo criado por automação para visualizar) nem
   comportamento novo para disparar. Qualquer "resultado obtido" que eu escrevesse aqui
   seria fabricado.

Os únicos elementos hoje em `sbx-somos-agility-qa` relacionados ao tema são os mesmos que
já existiam antes desta demanda (Flows de owner, de notificação de contrato, trigger
gerenciado `InserirOportunidade`, validation rules M25 e `Alteracao_do_Owner_se_Renovacoes`
— todos catalogados em `02-recon.md`/`03-design.md`). Nenhum deles foi alterado por esta
demanda; testá-los agora seria testar comportamento pré-existente do cliente, não o que
SOMOSAGILITY-20 deveria entregar.

## 4. O que precisa acontecer antes de qualquer execução real de teste

Mesmo caminho que `04-plano-build.md` já apontava, porque nada mudou desde então:

1. **Resposta a 6.1** (objeto de origem: HVR, Asset ou Contract) registrada no card —
   se Asset, está em aberto que isso é mudança de modelo de dados (`03-design.md`, linhas
   77–81) e escala para decisão de arquitetura sênior antes de qualquer build.
2. **Resposta a 6.3** (critério exato de elegibilidade — valores de campo, não descrição)
   registrada no card.
3. Build de verdade em `sbx-somos-agility-dev`: Flow + Custom Labels implantados, smoke
   test do trigger gerenciado `InserirOportunidade` (R1 em `03-design.md`, risco "Alta"),
   antes de qualquer promoção para `sbx-somos-agility-qa`.
4. Só então este arquivo pode ser reescrito com um roteiro real, derivado dos critérios de
   aceite de `01-analise.md` **depois** de preenchidos (não mais `<...>`), cobrindo pelo
   menos: caminho feliz (oportunidade criada com os campos certos), elegibilidade negativa
   (registro fora do critério não gera oportunidade), duplicidade (não recria se já
   existe), volume (lote de ≥200 HVRs elegíveis, ponto que `03-design.md` seção 5 já marca
   como necessário pelo efeito multiplicador de automações existentes), e os riscos R1/R2
   do design (trigger gerenciado e cascata HVR → Asset) em sandbox de QA antes de
   homologação.

## 5. Critérios de aceite — testabilidade, um a um

| Cenário (`01-analise.md` §4) | Testável hoje? | Por quê |
|---|---|---|
| Oportunidade criada quando a condição de renovação é atingida | **Não** | Objeto de origem (6.1), RecordType/Stage/Owner e campos (6.5, depende de 6.1/6.3) não definidos; nenhum Flow existe |
| Conta fora da regra não gera oportunidade | **Não** | Critério de elegibilidade (6.3) não definido |
| Não duplica renovação já existente | **Não** | Depende do mesmo Flow inexistente; "mesmo ciclo" (6.6) é premissa não validada |
| Carga em lote não quebra a operação | **Não** | Não há processo para rodar em lote |
| Falha de criação não passa despercebida | **Não** | Mecanismo de erro (6.7) é premissa não validada e não há Flow para falhar |

Nenhum critério de aceite desta demanda é testável na sandbox atual. Nenhum é ignorado —
todos estão listados acima com o motivo específico.

## 6. Permissão por perfil, borda, negativo, volume

Não aplicável nesta rodada pelo mesmo motivo: essas dimensões de teste pressupõem um
artefato para testar. Ficam registradas no item 4.4 acima como parte do roteiro a produzir
quando o build existir — incluindo o ponto já levantado pelo design (`03-design.md` §6)
de confirmar qual usuário de execução a org usa para Flows agendados, por causa da
validation rule `M25_Oportunidade_criada_somente_em_OQF`.

---

## Encerramento

Testes executados — no sentido de que confirmei, de forma independente e contra a org real
de QA, que não há nada implantado para esta demanda, e documentei por quê. **Não há,
porém, nenhum critério de aceite validado, nenhuma tela testada e nenhum comportamento
confirmado funcionando.** Não há o que homologar ainda. Preciso da sua decisão: o caminho
mais provável, dado o que está registrado aqui e em `04-plano-build.md`, é reverter esta
demanda para o estágio de build (ou para o design, se a resposta a 6.1 for Asset) assim
que 6.1 e 6.3 forem respondidas no card — mas essa decisão é sua, não minha.
